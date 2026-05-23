import 'package:flutter/material.dart';
import '../models/aspiration.dart';
import '../models/essential_config.dart';
import '../services/api_client.dart';

class AspirationProvider extends ChangeNotifier {
  List<UserAspiration> _aspirations = [];
  List<LifeEssentialConfig> _essentials = [];
  bool _loading = false;

  List<UserAspiration> get aspirations => _aspirations;
  List<LifeEssentialConfig> get essentials => _essentials;
  bool get loading => _loading;

  List<UserAspiration> get pendingAspirations =>
      _aspirations.where((a) => a.status == 0).toList();

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    await Future.wait([loadAspirations(), loadEssentials()]);
    _loading = false;
    notifyListeners();
  }

  Future<void> loadAspirations() async {
    final api = ApiClient();
    if (!api.hasToken) return;
    final resp = await api.get('/aspiration/list');
    if (resp.ok && resp.data is List) {
      _aspirations = (resp.data as List)
          .map((e) => UserAspiration.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<void> loadEssentials() async {
    final api = ApiClient();
    if (!api.hasToken) return;
    final resp = await api.get('/essential/list');
    if (resp.ok && resp.data is List) {
      _essentials = (resp.data as List)
          .map((e) => LifeEssentialConfig.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<bool> addAspiration(UserAspiration a) async {
    final api = ApiClient();
    if (!api.hasToken) return false;
    final resp = await api.post('/aspiration', data: a.toJson());
    if (resp.ok) {
      if (resp.data is Map) {
        _aspirations.insert(0, UserAspiration.fromJson(resp.data as Map<String, dynamic>));
      } else {
        await loadAspirations();
        return true;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteAspiration(int id) async {
    final api = ApiClient();
    if (!api.hasToken) return false;
    final resp = await api.delete('/aspiration/$id');
    if (resp.ok) {
      _aspirations.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> toggleEssential(int id, int enabled) async {
    final api = ApiClient();
    if (!api.hasToken) return false;
    final resp = await api.put('/essential/$id/toggle', data: {'enabled': enabled});
    if (resp.ok) {
      for (int i = 0; i < _essentials.length; i++) {
        if (_essentials[i].id == id) {
          _essentials[i] = _essentials[i].copyWith(enabled: enabled);
          break;
        }
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> resetEssentials() async {
    final api = ApiClient();
    if (!api.hasToken) return false;
    final resp = await api.post('/essential/reset');
    if (resp.ok && resp.data is List) {
      _essentials = (resp.data as List)
          .map((e) => LifeEssentialConfig.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
      return true;
    }
    return false;
  }
}
