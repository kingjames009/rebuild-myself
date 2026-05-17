import 'dart:html' as html;

class TokenStore {
  static final TokenStore _instance = TokenStore._();
  factory TokenStore() => _instance;
  TokenStore._();

  static const _key = 'auth_token';

  Future<String?> load() async {
    return html.window.localStorage[_key];
  }

  Future<void> save(String token) async {
    html.window.localStorage[_key] = token;
  }

  Future<void> clear() async {
    html.window.localStorage.remove(_key);
  }

  bool get hasToken {
    final t = html.window.localStorage[_key];
    return t != null && t.isNotEmpty;
  }

  static const _credsKey = 'auth_creds';

  Future<Map<String, String>?> loadCreds() async {
    try {
      final raw = html.window.localStorage[_credsKey];
      if (raw != null && raw.isNotEmpty) {
        return {'pwd': raw};
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCreds(String pwd) async {
    html.window.localStorage[_credsKey] = pwd;
  }
}
