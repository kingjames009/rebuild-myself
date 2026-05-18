import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _serverUrl = 'http://47.92.98.182:8080/api';
  static const String _localUrl = 'http://localhost:8080/api';

  static String get baseUrl => kReleaseMode ? _serverUrl : _localUrl;
  static String get serverOrigin => kReleaseMode ? 'http://47.92.98.182:8080' : 'http://localhost:8080';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 30);
  static const Duration aiReportTimeout = Duration(seconds: 150);
}
