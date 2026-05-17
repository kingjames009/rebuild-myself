import 'package:flutter/material.dart';
import '../models/daily_record.dart';
import '../services/api_client.dart';

class RecordProvider extends ChangeNotifier {
  List<DailyRecord> _records = [];
  bool _loading = false;
  String _selectedDate = _today();

  List<DailyRecord> get records => _records;
  bool get loading => _loading;
  String get selectedDate => _selectedDate;

  List<DailyRecord> recordsByType(int type) => _records.where((r) => r.recordType == type).toList();

  final _api = ApiClient();

  Future<void> loadByDate(String date) async {
    _selectedDate = date;
    _loading = true;
    notifyListeners();
    try {
      final resp = await _api.get('/record/date/$date');
      if (resp.ok && resp.data is List) {
        _records = (resp.data as List).map((r) => DailyRecord.fromJson(r)).toList();
      } else {
        _records = [];
      }
    } catch (_) {
      _records = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add(DailyRecord record) async {
    final resp = await _api.post('/record', data: record.toJson());
    if (resp.ok) await loadByDate(_selectedDate);
  }

  Future<void> update(DailyRecord record) async {
    final resp = await _api.put('/record', data: record.toJson());
    if (resp.ok) await loadByDate(_selectedDate);
  }

  Future<void> delete(int recordId) async {
    final resp = await _api.delete('/record/$recordId');
    if (resp.ok) await loadByDate(_selectedDate);
  }

  int get todayCount {
    final today = _today();
    return _records.where((r) => r.recordDate == today).length;
  }

  int get totalMinutes {
    return _records.fold(0, (sum, r) => sum + (r.costTime ?? 0));
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
