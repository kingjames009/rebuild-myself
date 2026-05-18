import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/ai_report.dart';
import '../services/database_helper.dart';
import '../services/api_client.dart';

class ReportProvider extends ChangeNotifier {
  List<AiReport> _reports = [];
  bool _loading = false;
  bool _generating = false;

  List<AiReport> get reports => _reports;
  bool get loading => _loading;
  bool get generating => _generating;

  List<AiReport> getByCycle(int cycle) => _reports.where((r) => r.cycleType == cycle).toList();

  /// Load from local DB. Pull server data in background for initial sync
  /// but never wipe local — server data is merged (insert-only, no delete).
  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();

    // Try to pull server data in background and merge (insert new, skip existing)
    final api = ApiClient();
    if (api.hasToken) {
      try {
        final resp = await api.get('/report/page', params: {'page': '1', 'size': '100'});
        if (resp.ok && resp.data != null) {
          final data = resp.data as Map<String, dynamic>;
          final records = data['records'] as List<dynamic>? ?? [];
          final db = await DatabaseHelper().db;
          for (final r in records) {
            final m = r as Map<String, dynamic>;
            final serverId = m['reportId'] ?? m['report_id'];
            // Only insert if this server report doesn't exist locally yet
            final existing = await db.query('ai_psychological_report',
                where: 'report_id = ?', whereArgs: [serverId]);
            if (existing.isEmpty) {
              await db.insert('ai_psychological_report', {
                'report_id': serverId,
                'user_id': m['userId'] ?? m['user_id'],
                'cycle_type': m['cycleType'] ?? m['cycle_type'],
                'cycle_range': m['cycleRange'] ?? m['cycle_range'] ?? '',
                'original_data': m['originalData'] ?? m['original_data'] ?? '',
                'report_content': m['reportContent'] ?? m['report_content'] ?? '',
                'create_time': m['createTime'] ?? m['create_time'] ?? DateTime.now().toIso8601String(),
              });
            }
          }
        }
      } catch (_) {}
    }

    // Load from local DB
    final db = await DatabaseHelper().db;
    final rows = await db.query('ai_psychological_report', orderBy: 'create_time DESC');
    _reports = rows.map((r) => AiReport.fromJson(r)).toList();
    _loading = false;
    notifyListeners();
  }

  Future<String?> generateReport(int cycleType, {String? date}) async {
    final api = ApiClient();
    if (!api.hasToken) return '请先登录';
    _generating = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{'cycleType': cycleType};
      if (date != null && date.isNotEmpty) body['date'] = date;
      final resp = await api.post('/report/generate', data: body,
          timeout: ApiConfig.aiReportTimeout);
      if (resp.ok && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        final db = await DatabaseHelper().db;
        final reportId = data['reportId'] ?? data['report_id'];
        // Insert locally
        await db.insert('ai_psychological_report', {
          'report_id': reportId,
          'user_id': data['userId'] ?? data['user_id'],
          'cycle_type': data['cycleType'] ?? data['cycle_type'],
          'cycle_range': data['cycleRange'] ?? data['cycle_range'],
          'original_data': data['originalData'] ?? data['original_data'] ?? '',
          'report_content': data['reportContent'] ?? data['report_content'] ?? '',
          'create_time': data['createTime'] ?? data['create_time'] ?? DateTime.now().toIso8601String(),
        });
        // Reload from local DB (not server) to pick up the new row with correct id
        final rows = await db.query('ai_psychological_report', orderBy: 'create_time DESC');
        _reports = rows.map((r) => AiReport.fromJson(r)).toList();
        _generating = false;
        notifyListeners();
        return null;
      }
      _generating = false;
      notifyListeners();
      return resp.msg ?? '生成失败';
    } catch (e) {
      _generating = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> delete(int reportId) async {
    // Delete from server (fire-and-forget)
    final api = ApiClient();
    if (api.hasToken) {
      try { await api.delete('/report/$reportId'); } catch (_) {}
    }
    // Delete from local DB
    final db = await DatabaseHelper().db;
    await db.delete('ai_psychological_report', where: 'report_id = ?', whereArgs: [reportId]);
    // Remove from in-memory list immediately
    _reports.removeWhere((r) => r.reportId == reportId);
    notifyListeners();
  }

  /// Find an existing report for the given cycleType and date.
  AiReport? findExisting(int cycleType, String dateStr) {
    for (final r in _reports) {
      if (r.cycleType != cycleType) continue;
      final range = r.cycleRange;
      if (range == null) continue;
      final parts = range.split(' ~ ');
      if (parts.length != 2) continue;
      final start = parts[0].trim();
      final end = parts[1].trim();
      if (dateStr.compareTo(start) >= 0 && dateStr.compareTo(end) <= 0) {
        return r;
      }
    }
    return null;
  }
}
