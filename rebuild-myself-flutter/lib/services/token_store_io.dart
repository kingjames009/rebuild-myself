import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TokenStore {
  static final TokenStore _instance = TokenStore._();
  factory TokenStore() => _instance;
  TokenStore._();

  String? _token;

  Future<String> get _path async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/auth_token.json';
  }

  Future<String?> load() async {
    if (_token != null) return _token;
    try {
      final file = File(await _path);
      if (await file.exists()) {
        final data = json.decode(await file.readAsString());
        _token = data['token'];
        return _token;
      }
    } catch (_) {}
    return null;
  }

  Future<void> save(String token) async {
    _token = token;
    try {
      final file = File(await _path);
      await file.writeAsString(json.encode({'token': token}));
    } catch (_) {}
  }

  Future<void> clear() async {
    _token = null;
    try {
      final file = File(await _path);
      if (await file.exists()) {
        final data = json.decode(await file.readAsString());
        data.remove('token');
        await file.writeAsString(json.encode(data));
      }
    } catch (_) {}
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<Map<String, String>?> loadCreds() async {
    try {
      final file = File(await _path);
      if (await file.exists()) {
        final data = json.decode(await file.readAsString());
        final pwd = data['pwd'] as String?;
        if (pwd != null) return {'pwd': pwd};
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCreds(String pwd) async {
    try {
      final file = File(await _path);
      Map<String, dynamic> data = {};
      if (await file.exists()) {
        data = json.decode(await file.readAsString());
      }
      data['pwd'] = pwd;
      await file.writeAsString(json.encode(data));
    } catch (_) {}
  }
}
