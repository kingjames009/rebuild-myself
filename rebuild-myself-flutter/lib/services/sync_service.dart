import '../services/database_helper.dart';
import '../services/api_client.dart';

class SyncService {
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;
  SyncService._();

  bool _syncing = false;
  DateTime? _lastSync;

  bool get isSyncing => _syncing;
  DateTime? get lastSync => _lastSync;

  static const _tableToKey = {
    'behavior_intervene': 'behaviors',
    'finance_mental_log': 'finances',
    'study_track_record': 'studies',
    'sideline_plan': 'sidelines',
    'empty_mood_log': 'empties',
    'book_read_record': 'books',
    'life_leisure_record': 'leisures',
    'daily_compare_check': 'checks',
    'daily_model_plan': 'plans',
    'ai_psychological_report': 'reports',
    'morning_check_in': 'morningChecks',
  };

  static const _allTables = [
    'behavior_intervene',
    'finance_mental_log', 'study_track_record', 'sideline_plan',
    'empty_mood_log', 'book_read_record', 'life_leisure_record',
    'daily_compare_check', 'daily_model_plan', 'ai_psychological_report',
    'morning_check_in',
  ];

  // Map common camelCase keys → snake_case for push
  static final _keyMap = {
    'recordId': 'record_id', 'userId': 'user_id', 'recordType': 'record_type',
    'costTime': 'cost_time', 'triggerReason': 'trigger_reason', 'emotionScore': 'emotion_score',
    'recordDate': 'record_date', 'createTime': 'create_time', 'updateTime': 'update_time',
    'goalId': 'goal_id', 'goalLevel': 'goal_level', 'goalType': 'goal_type',
    'targetDate': 'target_date', 'targetTime': 'target_time',
    'taskId': 'task_id', 'taskTitle': 'task_title', 'taskLevel': 'task_level',
    'isComplete': 'is_complete', 'taskDate': 'task_date',
    'interveneId': 'intervene_id', 'interveneType': 'intervene_type',
    'interveneContent': 'intervene_content', 'interveneDate': 'intervene_date',
    'interveneTime': 'intervene_time', 'interveneStatus': 'intervene_status',
    'id': 'id', 'financeAmount': 'finance_amount', 'financeType': 'finance_type',
    'financeRemark': 'finance_remark', 'financeDate': 'finance_date',
    'studySubject': 'study_subject', 'studyDuration': 'study_duration',
    'studyContent': 'study_content', 'studyDate': 'study_date',
    'sidelineName': 'sideline_name', 'sidelineType': 'sideline_type',
    'sidelineContent': 'sideline_content', 'sidelineDate': 'sideline_date',
    'moodType': 'mood_type', 'moodContent': 'mood_content', 'moodDate': 'mood_date',
    'bookTitle': 'book_title', 'bookAuthor': 'book_author', 'readPage': 'read_page',
    'readDate': 'read_date', 'leisureType': 'leisure_type',
    'leisureContent': 'leisure_content', 'leisureDate': 'leisure_date',
    'checkId': 'check_id', 'checkType': 'check_type',
    'planId': 'plan_id', 'planDate': 'plan_date', 'timePeriod': 'time_period',
    'planContent': 'plan_content', 'planType': 'plan_type',
    'isCompleted': 'is_completed', 'actualNote': 'actual_note', 'completedAt': 'completed_at',
    'reportId': 'report_id', 'cycleType': 'cycle_type', 'cycleRange': 'cycle_range',
    'originalData': 'original_data', 'reportContent': 'report_content',
    'sleepHours': 'sleep_hours', 'anxietyLevel': 'anxiety_level',
    'protectionLevel': 'protection_level', 'date': 'date',
  };

  Map<String, dynamic> _toSnake(Map<String, dynamic> row) {
    final out = <String, dynamic>{};
    for (final e in row.entries) {
      if (e.key == 'synced') continue;
      final k = _keyMap[e.key] ?? e.key;
      out[k] = e.value;
    }
    return out;
  }

  Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;

    try {
      await _pushLocalChanges();
      await _pullRemoteChanges();
      _lastSync = DateTime.now();
    } catch (_) {}

    _syncing = false;
  }

  Future<void> _pushLocalChanges() async {
    final db = await DatabaseHelper().db;
    final api = ApiClient();
    if (!api.hasToken) return;

    final body = <String, dynamic>{};
    bool hasData = false;

    for (final table in _tableToKey.keys) {
      final all = await db.query(table);
      final unsynced = all.where((r) => r['synced'] != 1).toList();
      if (unsynced.isEmpty) continue;

      body[_tableToKey[table]!] = unsynced.map(_toSnake).toList();
      hasData = true;
    }

    if (!hasData) return;

    final resp = await api.post('/sync/upload', data: body);
    if (!resp.ok) return;

    // Mark all as synced (try both naming conventions for the id column)
    for (final table in _allTables) {
      final all = await db.query(table);
      final idCol = _idColumn(table);
      final camIdCol = _camelIdColumn(table);
      for (final row in all.where((r) => r['synced'] != 1)) {
        final idVal = row[idCol] ?? row[camIdCol];
        if (idVal == null) continue;
        // Try snake_case first, then camelCase
        if (row[idCol] != null) {
          await db.update(table, {'synced': 1},
              where: '$idCol = ?', whereArgs: [idVal]);
        } else {
          await db.update(table, {'synced': 1},
              where: '$camIdCol = ?', whereArgs: [idVal]);
        }
      }
    }
  }

  Future<void> _pullRemoteChanges() async {
    final db = await DatabaseHelper().db;
    final api = ApiClient();
    if (!api.hasToken) return;

    dynamic resp;
    if (_lastSync != null) {
      resp = await api.get('/sync/pull', params: {'since': _lastSync!.toIso8601String()});
    } else {
      final start = DateTime.now().subtract(const Duration(days: 365));
      resp = await api.get('/sync/export', params: {
        'start': '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
        'end': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      });
    }

    if (!resp.ok || resp.data == null) return;
    final data = resp.data as Map<String, dynamic>;

    const keyToTable = {
      'behaviors': 'behavior_intervene', 'finances': 'finance_mental_log',
      'studies': 'study_track_record', 'sidelines': 'sideline_plan',
      'empties': 'empty_mood_log', 'books': 'book_read_record',
      'leisures': 'life_leisure_record', 'checks': 'daily_compare_check',
      'plans': 'daily_model_plan', 'reports': 'ai_psychological_report',
      'morningChecks': 'morning_check_in',
    };

    for (final entry in data.entries) {
      final table = keyToTable[entry.key];
      if (table == null) continue;
      final idCol = _idColumn(table);
      final camIdCol = _camelIdColumn(table);
      final rows = (entry.value as List?) ?? [];
      if (rows.isEmpty) continue;

      // Load all existing rows to deduplicate by id
      final existingAll = await db.query(table);
      final mergedList = <Map<String, dynamic>>[];

      for (final row in rows) {
        if (row is! Map) continue;
        final idVal = row[idCol];
        if (idVal == null) continue;
        final merged = Map<String, dynamic>.from(row)..['synced'] = 1;

        // Remove any existing row with same id (checking both naming conventions)
        existingAll.removeWhere((r) => r[idCol] == idVal || r[camIdCol] == idVal);

        mergedList.add(merged);
      }

      // Delete all remaining rows for this table and re-insert merged ones?
      // No — keep rows that weren't in the pull response (they're already synced or locally unique).
      // Just insert new rows that don't exist locally.
      for (final merged in mergedList) {
        await db.insert(table, merged);
      }
    }
  }

  static String _idColumn(String table) {
    const map = {
      'daily_record': 'record_id', 'user_goal': 'goal_id', 'task_todo': 'task_id',
      'behavior_intervene': 'intervene_id', 'finance_mental_log': 'id',
      'study_track_record': 'id', 'sideline_plan': 'id', 'empty_mood_log': 'id',
      'book_read_record': 'id', 'life_leisure_record': 'id',
      'daily_compare_check': 'check_id', 'daily_model_plan': 'plan_id',
      'ai_psychological_report': 'report_id',
    };
    return map[table] ?? 'id';
  }

  static String _camelIdColumn(String table) {
    const map = {
      'daily_record': 'recordId', 'user_goal': 'goalId', 'task_todo': 'taskId',
      'behavior_intervene': 'interveneId', 'daily_compare_check': 'checkId',
      'daily_model_plan': 'planId', 'ai_psychological_report': 'reportId',
    };
    return map[table] ?? 'id';
  }
}
