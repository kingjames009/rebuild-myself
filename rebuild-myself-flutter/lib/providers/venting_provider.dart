import 'package:flutter/material.dart';
import '../models/venting_entry.dart';
import '../services/database_helper.dart';

class VentingProvider extends ChangeNotifier {
  List<VentingEntry> _entries = [];
  bool _loading = false;

  List<VentingEntry> get entries => _entries;
  bool get loading => _loading;

  VentingEntry? get todayEntry {
    final today = _todayStr();
    final matches = _entries.where((e) => e.recordDate == today);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('venting_log', orderBy: 'create_time DESC');
    _entries = rows.map((r) => VentingEntry.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> saveForDate(String date, String content) async {
    final db = await DatabaseHelper().db;
    final existing = await db.query('venting_log',
        where: 'record_date = ?', whereArgs: [date]);
    final now = DateTime.now().toIso8601String();

    if (existing.isNotEmpty) {
      await db.update('venting_log', {'content': content},
          where: 'record_date = ?', whereArgs: [date]);
      for (int i = 0; i < _entries.length; i++) {
        if (_entries[i].recordDate == date) {
          _entries[i] = _entries[i].copyWith(content: content);
          break;
        }
      }
    } else {
      final newId = await db.insert('venting_log', {
        'recordDate': date,
        'content': content,
        'createTime': now,
      });
      _entries.insert(0, VentingEntry(
        id: newId,
        recordDate: date,
        content: content,
        createTime: now,
      ));
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('venting_log', where: 'id = ?', whereArgs: [id]);
    _entries.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
