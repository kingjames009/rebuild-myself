import 'package:flutter/material.dart';
import '../models/sideline.dart';
import '../services/database_helper.dart';

class SidelineProvider extends ChangeNotifier {
  List<SidelinePlan> _plans = [];
  bool _loading = false;

  List<SidelinePlan> get plans => _plans;
  bool get loading => _loading;

  List<SidelinePlan> get englishPlans => _plans.where((p) => p.sideType == 'english' || p.sideType == '1').toList();
  List<SidelinePlan> get aiPlans => _plans.where((p) => p.sideType == 'ai' || p.sideType == '2').toList();
  List<SidelinePlan> get devPlans => _plans.where((p) => p.sideType == 'dev' || p.sideType == '3').toList();

  int progressFor(String type) {
    final list = _plans.where((p) => p.sideType == type).toList();
    if (list.isEmpty) return 0;
    return (list.fold(0, (sum, p) => sum + (p.progress ?? 0)) / list.length).round();
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('sideline_plan', orderBy: 'create_time DESC');
    _plans = rows.map((r) => SidelinePlan.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(SidelinePlan plan) async {
    final db = await DatabaseHelper().db;
    final newId = await db.insert('sideline_plan', plan.toJson());
    _plans.insert(0, plan.copyWith(id: newId));
    notifyListeners();
  }

  Future<void> update(SidelinePlan plan) async {
    final db = await DatabaseHelper().db;
    await db.update('sideline_plan', plan.toJson(), where: 'id = ?', whereArgs: [plan.id]);
    for (int i = 0; i < _plans.length; i++) {
      if (_plans[i].id == plan.id) { _plans[i] = plan; break; }
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('sideline_plan', where: 'id = ?', whereArgs: [id]);
    _plans.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
