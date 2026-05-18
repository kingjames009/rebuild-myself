import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_store.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  String? _token;
  void Function()? onUnauthorized;

  ApiClient._internal();

  Uri _uri(String path, [Map<String, dynamic>? params]) {
    final url = '${ApiConfig.baseUrl}$path';
    final uri = Uri.parse(url);
    if (params != null) {
      return uri.replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));
    }
    return uri;
  }

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<void> loadToken() async {
    _token = await TokenStore().load();
  }

  Future<void> setToken(String token) async {
    _token = token;
    await TokenStore().save(token);
  }

  Future<void> clearToken() async {
    _token = null;
    await TokenStore().clear();
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<ApiResponse> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final resp = await http.get(_uri(path, params), headers: _headers).timeout(ApiConfig.connectTimeout);
      return _handleResponse(resp);
    } catch (e) {
      return ApiResponse(code: -1, msg: e.toString(), data: null);
    }
  }

  Future<ApiResponse> post(String path, {dynamic data, Duration? timeout}) async {
    try {
      final body = data != null ? json.encode(data) : null;
      final resp = await http.post(_uri(path), headers: _headers, body: body)
          .timeout(timeout ?? ApiConfig.connectTimeout);
      return _handleResponse(resp);
    } catch (e) {
      return ApiResponse(code: -1, msg: e.toString(), data: null);
    }
  }

  Future<ApiResponse> put(String path, {dynamic data}) async {
    try {
      final body = data != null ? json.encode(data) : null;
      final resp = await http.put(_uri(path), headers: _headers, body: body).timeout(ApiConfig.connectTimeout);
      return _handleResponse(resp);
    } catch (e) {
      return ApiResponse(code: -1, msg: e.toString(), data: null);
    }
  }

  Future<ApiResponse> uploadFile(String path, String filePath, {String field = 'file'}) async {
    try {
      final uri = _uri(path);
      final request = http.MultipartRequest('POST', uri);
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(await http.MultipartFile.fromPath(field, filePath));
      final streamed = await request.send().timeout(ApiConfig.uploadTimeout);
      final resp = await http.Response.fromStream(streamed);
      return _handleResponse(resp);
    } catch (e) {
      return ApiResponse(code: -1, msg: e.toString(), data: null);
    }
  }

  Future<ApiResponse> delete(String path) async {
    try {
      final resp = await http.delete(_uri(path), headers: _headers).timeout(ApiConfig.connectTimeout);
      return _handleResponse(resp);
    } catch (e) {
      return ApiResponse(code: -1, msg: e.toString(), data: null);
    }
  }

  ApiResponse _handleResponse(http.Response resp) {
    try {
      final body = json.decode(resp.body);
      if (body is Map && body['code'] != null) {
        if (body['code'] == 200) {
          return ApiResponse(code: 200, msg: 'ok', data: body['data']);
        }
        if (body['code'] == 401) {
          _token = null;
          onUnauthorized?.call();
        }
        return ApiResponse(code: body['code'], msg: body['msg'] ?? '', data: body['data']);
      }
      return ApiResponse(code: resp.statusCode, msg: '', data: body);
    } catch (_) {
      return ApiResponse(code: resp.statusCode, msg: resp.body, data: null);
    }
  }
}

class ApiResponse {
  final int code;
  final String? msg;
  final dynamic data;
  ApiResponse({required this.code, this.msg, this.data});

  bool get ok => code == 200;
}
