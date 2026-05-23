import 'package:flutter/material.dart';
import '../models/empty_mood.dart';
import '../services/database_helper.dart';

class EmptyMoodProvider extends ChangeNotifier {
  List<EmptyMoodLog> _logs = [];
  bool _loading = false;

  List<EmptyMoodLog> get logs => _logs;
  bool get loading => _loading;

  double get avgEmptyLevel {
    if (_logs.isEmpty) return 0;
    return _logs.fold(0.0, (sum, l) => sum + (l.emptyLevel ?? 0)) / _logs.length;
  }

  double get totalWasteHours {
    return _logs.fold(0.0, (sum, l) => sum + (l.wasteHours ?? 0));
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('empty_mood_log', orderBy: 'create_time DESC');
    _logs = rows.map((r) => EmptyMoodLog.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(EmptyMoodLog log) async {
    final db = await DatabaseHelper().db;
    final newId = await db.insert('empty_mood_log', log.toJson());
    _logs.insert(0, log.copyWith(id: newId));
    notifyListeners();
  }

  Future<void> update(EmptyMoodLog log) async {
    final db = await DatabaseHelper().db;
    await db.update('empty_mood_log', log.toJson(), where: 'id = ?', whereArgs: [log.id]);
    for (int i = 0; i < _logs.length; i++) {
      if (_logs[i].id == log.id) { _logs[i] = log; break; }
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('empty_mood_log', where: 'id = ?', whereArgs: [id]);
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
  }
}
