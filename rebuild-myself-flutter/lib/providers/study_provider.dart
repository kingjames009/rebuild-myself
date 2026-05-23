import 'package:flutter/material.dart';
import '../models/study.dart';
import '../services/database_helper.dart';

class StudyProvider extends ChangeNotifier {
  List<StudyTrackRecord> _records = [];
  bool _loading = false;

  /// Cached today-total. Incremented immediately on timer stop so the
  /// MiniStat never dips, then reconciled with DB on loadAll().
  int _todayMinutes = 0;
  String _todayDate = '';

  List<StudyTrackRecord> get records => _records;
  bool get loading => _loading;

  List<StudyTrackRecord> get englishRecords =>
      _records.where((r) => r.trackType == '1' || r.trackType == 'speech').toList();
  List<StudyTrackRecord> get aiRecords =>
      _records.where((r) => r.trackType == '2' || r.trackType == 'ai').toList();
  List<StudyTrackRecord> get devRecords =>
      _records.where((r) => r.trackType == '3' || r.trackType == 'app').toList();

  int get escapeRate {
    if (_records.isEmpty) return 0;
    final escapes = _records.where((r) => r.escapeStatus == 1).length;
    return _records.isNotEmpty ? (escapes * 100 / _records.length).round() : 0;
  }

  int trackMinutes(String type) {
    return _records
        .where((r) => r.trackType == type)
        .fold(0, (sum, r) => sum + (r.studyMinutes ?? 0));
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Today's total minutes from persisted records.
  /// Reset to 0 on date change; otherwise only goes up.
  int get todayMinutes {
    final t = _today();
    if (_todayDate != t) {
      _todayDate = t;
      _todayMinutes = 0;
    }
    return _todayMinutes;
  }

  /// Called immediately when a timer session is saved, before loadAll().
  /// Bridges the gap so the MiniStat never shows a drop.
  void addTodayMinutes(int mins) {
    final t = _today();
    if (_todayDate != t) {
      _todayDate = t;
      _todayMinutes = 0;
    }
    _todayMinutes += mins;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('study_track_record', orderBy: 'create_time DESC');
    _records = rows.map((r) => StudyTrackRecord.fromJson(r)).toList();

    // Reconcile today's total from DB
    final t = _today();
    _todayDate = t;
    _todayMinutes = _records
        .where((r) => r.recordDate == t)
        .fold<int>(0, (s, r) => s + (r.studyMinutes ?? 0));

    _loading = false;
    notifyListeners();
  }

  Future<void> add(StudyTrackRecord record) async {
    final db = await DatabaseHelper().db;
    final newId = await db.insert('study_track_record', record.toJson());
    final saved = record.copyWith(id: newId);
    _records.insert(0, saved);
    final t = _today();
    if (saved.recordDate == t) {
      _todayMinutes += (saved.studyMinutes ?? 0);
    }
    notifyListeners();
  }

  Future<void> update(StudyTrackRecord record) async {
    final db = await DatabaseHelper().db;
    await db.update('study_track_record', record.toJson(),
        where: 'id = ?', whereArgs: [record.id]);
    final t = _today();
    for (int i = 0; i < _records.length; i++) {
      if (_records[i].id == record.id) {
        if (_records[i].recordDate == t) {
          _todayMinutes -= (_records[i].studyMinutes ?? 0);
        }
        if (record.recordDate == t) {
          _todayMinutes += (record.studyMinutes ?? 0);
        }
        _records[i] = record;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('study_track_record', where: 'id = ?', whereArgs: [id]);
    final t = _today();
    _records.removeWhere((r) {
      if (r.id == id) {
        if (r.recordDate == t) {
          _todayMinutes -= (r.studyMinutes ?? 0);
        }
        return true;
      }
      return false;
    });
    notifyListeners();
  }
}
