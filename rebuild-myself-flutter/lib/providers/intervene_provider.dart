import 'package:flutter/material.dart';
import '../models/behavior.dart';
import '../services/database_helper.dart';

class InterveneProvider extends ChangeNotifier {
  List<BehaviorIntervene> _intervenes = [];
  bool _loading = false;

  List<BehaviorIntervene> get intervenes => _intervenes;
  bool get loading => _loading;

  double get successRate {
    if (_intervenes.isEmpty) return 0;
    final successes = _intervenes.where((i) => i.isSuccess == 1).length;
    return successes / _intervenes.length;
  }

  List<BehaviorIntervene> getByType(int type) => _intervenes.where((i) => i.interveneType == type).toList();

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('behavior_intervene', orderBy: 'create_time DESC');
    _intervenes = rows.map((r) => BehaviorIntervene.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(BehaviorIntervene i) async {
    final db = await DatabaseHelper().db;
    final newId = await db.insert('behavior_intervene', i.toJson());
    _intervenes.insert(0, i.copyWith(interveneId: newId));
    notifyListeners();
  }

  Future<void> update(BehaviorIntervene i) async {
    final db = await DatabaseHelper().db;
    await db.update('behavior_intervene', i.toJson(), where: 'intervene_id = ?', whereArgs: [i.interveneId]);
    for (int j = 0; j < _intervenes.length; j++) {
      if (_intervenes[j].interveneId == i.interveneId) { _intervenes[j] = i; break; }
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('behavior_intervene', where: 'intervene_id = ?', whereArgs: [id]);
    _intervenes.removeWhere((x) => x.interveneId == id);
    notifyListeners();
  }
}
