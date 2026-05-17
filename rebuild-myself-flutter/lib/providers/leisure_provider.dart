import 'package:flutter/material.dart';
import '../models/leisure.dart';
import '../services/database_helper.dart';

class LeisureProvider extends ChangeNotifier {
  List<LifeLeisureRecord> _records = [];
  bool _loading = false;

  List<LifeLeisureRecord> get records => _records;
  bool get loading => _loading;

  int get todayHappiness {
    final today = _today();
    final todayRecords = _records.where((r) => r.recordDate == today).toList();
    if (todayRecords.isEmpty) return 0;
    return (todayRecords.fold(0, (sum, r) => sum + (r.happyScore ?? 0)) / todayRecords.length).round();
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
    final rows = await db.query('life_leisure_record', orderBy: 'create_time DESC');
    _records = rows.map((r) => LifeLeisureRecord.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(LifeLeisureRecord record) async {
    final db = await DatabaseHelper().db;
    await db.insert('life_leisure_record', record.toJson());
    await loadAll();
  }

  Future<void> update(LifeLeisureRecord record) async {
    final db = await DatabaseHelper().db;
    await db.update('life_leisure_record', record.toJson(), where: 'id = ?', whereArgs: [record.id]);
    await loadAll();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('life_leisure_record', where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }
}
