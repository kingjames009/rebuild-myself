import 'package:flutter/material.dart';
import '../models/daily_summary_entry.dart';
import '../services/database_helper.dart';

class DailySummaryProvider extends ChangeNotifier {
  List<DailySummaryEntry> _entries = [];
  bool _loading = false;

  List<DailySummaryEntry> get entries => _entries;
  bool get loading => _loading;

  DailySummaryEntry? get todayEntry {
    final today = _todayStr();
    final matches = _entries.where((e) => e.recordDate == today);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('daily_summary_log', orderBy: 'create_time DESC');
    _entries = rows.map((r) => DailySummaryEntry.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> saveForDate(String date, String content) async {
    final db = await DatabaseHelper().db;
    final existing = await db.query('daily_summary_log',
        where: 'record_date = ?', whereArgs: [date]);
    final now = DateTime.now().toIso8601String();

    if (existing.isNotEmpty) {
      await db.update('daily_summary_log', {'content': content},
          where: 'record_date = ?', whereArgs: [date]);
      for (int i = 0; i < _entries.length; i++) {
        if (_entries[i].recordDate == date) {
          _entries[i] = _entries[i].copyWith(content: content);
          break;
        }
      }
    } else {
      final newId = await db.insert('daily_summary_log', {
        'recordDate': date,
        'content': content,
        'createTime': now,
      });
      _entries.insert(0, DailySummaryEntry(
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
    await db.delete('daily_summary_log', where: 'id = ?', whereArgs: [id]);
    _entries.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
