import 'package:flutter/material.dart';
import '../models/finance.dart';
import '../services/database_helper.dart';

class FinanceProvider extends ChangeNotifier {
  List<FinanceMentalLog> _logs = [];
  bool _loading = false;

  List<FinanceMentalLog> get logs => _logs;
  bool get loading => _loading;

  int get todayPressure {
    final today = _today();
    final todayLog = _logs.where((l) => l.recordDate == today).toList();
    return todayLog.isEmpty ? 0 : todayLog.first.moneyPressure ?? 0;
  }

  int get avgPressure {
    if (_logs.isEmpty) return 0;
    return (_logs.fold(0, (s, l) => s + (l.moneyPressure ?? 0)) / _logs.length).round();
  }

  int get totalActionMinutes => _logs.fold(0, (s, l) => s + (l.actionMinutes ?? 0));

  String get escapeLabel {
    if (_logs.isEmpty) return '无记录';
    final latest = _logs.first;
    return (latest.escapeState ?? 0) >= 3 ? '高逃避' : (latest.escapeState ?? 0) >= 1 ? '轻度逃避' : '正常';
  }

  bool get escaping {
    if (_logs.isEmpty) return false;
    return (_logs.first.escapeState ?? 0) >= 1;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('finance_mental_log', orderBy: 'create_time DESC');
    _logs = rows.map((r) => FinanceMentalLog.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(FinanceMentalLog log) async {
    final db = await DatabaseHelper().db;
    await db.insert('finance_mental_log', log.toJson());
    await loadAll();
  }

  Future<void> update(FinanceMentalLog log) async {
    final db = await DatabaseHelper().db;
    await db.update('finance_mental_log', log.toJson(), where: 'id = ?', whereArgs: [log.id]);
    await loadAll();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('finance_mental_log', where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }
}
