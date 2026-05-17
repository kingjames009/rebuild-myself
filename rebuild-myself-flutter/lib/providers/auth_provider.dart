import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _loading = false;
  String? _error;
  bool _privacyLocked = false;
  String _privacyPwd = '';
  User? _user;

  bool get isLoggedIn => _isLoggedIn;
  bool get loading => _loading;
  String? get error => _error;
  bool get privacyLocked => _privacyLocked;
  User? get user => _user;

  Future<void> init() async {
    await ApiClient().loadToken();
    if (!ApiClient().hasToken) {
      _isLoggedIn = false;
      await _loadUserFromLocal();
      notifyListeners();
      return;
    }
    final resp = await ApiClient().get('/user/profile');
    if (resp.ok && resp.data != null) {
      _isLoggedIn = true;
      _user = User.fromJson(resp.data);
      await _saveUserToLocal(_user!);
    } else {
      await ApiClient().clearToken();
      _isLoggedIn = false;
      await _loadUserFromLocal();
    }
    notifyListeners();
  }

  Future<void> _loadUserFromLocal() async {
    final db = await DatabaseHelper().db;
    final rows = await db.query('user', limit: 1);
    if (rows.isNotEmpty) {
      _user = User.fromJson(rows.first);
    }
  }

  Future<void> _saveUserToLocal(User u) async {
    final db = await DatabaseHelper().db;
    await db.delete('user');
    await db.insert('user', u.toJson());
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (ApiClient().hasToken) {
      await ApiClient().put('/user/profile', data: data);
    }
    // Update local
    if (_user != null) {
      final current = _user!.toJson();
      current.addAll(data);
      _user = User.fromJson(current);
    } else {
      _user = User.fromJson(data);
    }
    await _saveUserToLocal(_user!);
    notifyListeners();
  }

  Future<bool> login(String phone, String pwd) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final resp = await ApiClient().post('/user/login', data: {
      'phone': phone,
      'password': pwd,
    });

    _loading = false;
    if (resp.ok) {
      await ApiClient().setToken(resp.data as String);
      _isLoggedIn = true;
      await _fetchProfile();
      return true;
    } else {
      _error = resp.msg ?? '登录失败';
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String phone, String pwd) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final resp = await ApiClient().post('/user/register', data: {
      'phone': phone,
      'password': pwd,
    });

    _loading = false;
    if (resp.ok) {
      notifyListeners();
      return true;
    } else {
      _error = resp.msg ?? '注册失败';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _fetchProfile() async {
    final resp = await ApiClient().get('/user/profile');
    if (resp.ok && resp.data != null) {
      _user = User.fromJson(resp.data);
      await _saveUserToLocal(_user!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiClient().clearToken();
    _isLoggedIn = false;
    notifyListeners();
  }

  void setPrivacyPwd(String pwd) {
    _privacyPwd = pwd;
    _privacyLocked = true;
    notifyListeners();
  }

  bool verifyPrivacyPwd(String pwd) {
    final ok = _privacyPwd == pwd;
    if (ok) {
      _privacyLocked = false;
      notifyListeners();
    }
    return ok;
  }

  void disablePrivacy() {
    _privacyPwd = '';
    _privacyLocked = false;
    notifyListeners();
  }

  Future<String?> changePassword(String oldPwd, String newPwd) async {
    final resp = await ApiClient().post('/user/change-password', data: {
      'oldPassword': oldPwd,
      'newPassword': newPwd,
    });
    if (resp.ok) return null;
    return resp.msg ?? '修改失败';
  }
}
