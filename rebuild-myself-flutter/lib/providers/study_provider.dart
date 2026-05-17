import 'package:flutter/material.dart';
import '../models/study.dart';
import '../services/database_helper.dart';

class StudyProvider extends ChangeNotifier {
  List<StudyTrackRecord> _records = [];
  bool _loading = false;

  List<StudyTrackRecord> get records => _records;
  bool get loading => _loading;

  List<StudyTrackRecord> get englishRecords => _records.where((r) => r.trackType == '1' || r.trackType == 'speech').toList();
  List<StudyTrackRecord> get aiRecords => _records.where((r) => r.trackType == '2' || r.trackType == 'ai').toList();
  List<StudyTrackRecord> get devRecords => _records.where((r) => r.trackType == '3' || r.trackType == 'app').toList();

  int get escapeRate {
    if (_records.isEmpty) return 0;
    final escapes = _records.where((r) => r.escapeStatus == 1).length;
    return (_records.isNotEmpty) ? (escapes * 100 / _records.length).round() : 0;
  }

  int trackMinutes(String type) {
    return _records.where((r) => r.trackType == type).fold(0, (sum, r) => sum + (r.studyMinutes ?? 0));
  }

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('study_track_record', orderBy: 'create_time DESC');
    _records = rows.map((r) => StudyTrackRecord.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(StudyTrackRecord record) async {
    final db = await DatabaseHelper().db;
    await db.insert('study_track_record', record.toJson());
    await loadAll();
  }

  Future<void> update(StudyTrackRecord record) async {
    final db = await DatabaseHelper().db;
    await db.update('study_track_record', record.toJson(), where: 'id = ?', whereArgs: [record.id]);
    await loadAll();
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('study_track_record', where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }
}
