import 'package:flutter/material.dart';
import '../models/ai_report.dart';
import '../services/database_helper.dart';
import '../services/api_client.dart';

class ReportProvider extends ChangeNotifier {
  List<AiReport> _reports = [];
  bool _loading = false;

  List<AiReport> get reports => _reports;
  bool get loading => _loading;

  List<AiReport> getByCycle(int cycle) => _reports.where((r) => r.cycleType == cycle).toList();

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final rows = await db.query('ai_psychological_report', orderBy: 'create_time DESC');
    _reports = rows.map((r) => AiReport.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<String?> generateReport(int cycleType) async {
    final api = ApiClient();
    if (!api.hasToken) return '请先登录';
    try {
      final resp = await api.post('/report/generate', data: {'cycleType': cycleType});
      if (resp.ok && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        // Save to local DB
        final db = await DatabaseHelper().db;
        await db.insert('ai_psychological_report', {
          'report_id': data['reportId'] ?? data['report_id'],
          'user_id': data['userId'] ?? data['user_id'],
          'cycle_type': data['cycleType'] ?? data['cycle_type'],
          'cycle_range': data['cycleRange'] ?? data['cycle_range'],
          'original_data': data['originalData'] ?? data['original_data'] ?? '',
          'report_content': data['reportContent'] ?? data['report_content'] ?? '',
          'create_time': data['createTime'] ?? data['create_time'] ?? DateTime.now().toIso8601String(),
        });
        await loadAll();
        return null; // success
      }
      return resp.msg ?? '生成失败';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> delete(int reportId) async {
    final db = await DatabaseHelper().db;
    await db.delete('ai_psychological_report', where: 'report_id = ?', whereArgs: [reportId]);
    await loadAll();
  }
}
