import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._();
  factory LocalStorage() => _instance;
  LocalStorage._();

  String? _basePath;
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  Future<String> get basePath async {
    if (_basePath != null) return _basePath!;
    final dir = await getApplicationDocumentsDirectory();
    _basePath = '${dir.path}/db';
    await Directory(_basePath!).create(recursive: true);
    return _basePath!;
  }

  String _filePath(String base, String table) => '$base/$table.json';

  Future<List<Map<String, dynamic>>> loadTable(String table) async {
    if (_cache.containsKey(table)) return _cache[table]!;
    final bp = await basePath;
    final file = File(_filePath(bp, table));
    if (!await file.exists()) {
      _cache[table] = [];
      return [];
    }
    try {
      final content = await file.readAsString();
      final list = json.decode(content) as List;
      _cache[table] = list.cast<Map<String, dynamic>>();
      return _cache[table]!;
    } catch (_) {
      _cache[table] = [];
      return [];
    }
  }

  Future<void> _saveTable(String table) async {
    final bp = await basePath;
    final file = File(_filePath(bp, table));
    await file.writeAsString(json.encode(_cache[table] ?? []));
  }

  int _nextId(List<Map<String, dynamic>> rows, String idCol) {
    if (rows.isEmpty) return 1;
    int max = 0;
    for (final r in rows) {
      final v = r[idCol];
      if (v is int && v > max) max = v;
    }
    return max + 1;
  }

  String _idColumnForTable(String table) {
    const map = {
      'user': 'user_id', 'user_goal': 'goal_id', 'task_todo': 'task_id',
      'daily_record': 'record_id', 'behavior_intervene': 'intervene_id',
      'finance_mental_log': 'id', 'study_track_record': 'id', 'sideline_plan': 'id',
      'empty_mood_log': 'id', 'book_read_record': 'id', 'life_leisure_record': 'id',
      'elite_habit_lib': 'id', 'daily_model_plan': 'plan_id',
      'daily_compare_check': 'check_id', 'ai_psychological_report': 'report_id',
      'morning_check_in': 'id',
    };
    return map[table] ?? 'id';
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    final rows = await loadTable(table);
    List<Map<String, dynamic>> result = List.from(rows);
    if (where != null) {
      result = result.where((row) => _matchWhere(row, where, whereArgs ?? [])).toList();
    }
    if (orderBy != null) {
      final parts = orderBy.split(' ');
      final col = parts[0];
      final desc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';
      result.sort((a, b) {
        final va = a[col]; final vb = b[col];
        if (va == null && vb == null) return 0;
        if (va == null) return 1;
        if (vb == null) return -1;
        final cmp = Comparable.compare(va as Comparable, vb as Comparable);
        return desc ? -cmp : cmp;
      });
    }
    if (limit != null && result.length > limit) {
      result = result.sublist(0, limit);
    }
    return result;
  }

  bool _matchWhere(Map<String, dynamic> row, String where, List<dynamic> whereArgs) {
    // Split by AND to support compound conditions
    final parts = where.split(RegExp(r'\s+AND\s+', caseSensitive: false));
    int argIdx = 0;
    for (final part in parts) {
      final eqMatch = RegExp(r"^(\w+)\s*=\s*\?$").firstMatch(part.trim());
      if (eqMatch != null) {
        if (argIdx >= whereArgs.length) return false;
        if (row[eqMatch.group(1)!] != whereArgs[argIdx]) return false;
        argIdx++;
        continue;
      }
      final litMatch = RegExp(r"^(\w+)\s*=\s*(\S+)$").firstMatch(part.trim());
      if (litMatch != null) {
        final col = litMatch.group(1)!;
        final val = litMatch.group(2)!;
        dynamic parsed = val;
        if (int.tryParse(val) != null) parsed = int.parse(val);
        if (row[col] != parsed) return false;
      }
    }
    return true;
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final rows = await loadTable(table);
    final idCol = _idColumnForTable(table);
    final existingId = data[idCol];
    if (existingId == null || (existingId is int && existingId <= 0)) {
      data[idCol] = _nextId(rows, idCol);
    }
    rows.add(Map<String, dynamic>.from(data));
    await _saveTable(table);
    return data[idCol] as int;
  }

  Future<void> insertBatch(String table, List<Map<String, dynamic>> dataList) async {
    if (dataList.isEmpty) return;
    final rows = await loadTable(table);
    final idCol = _idColumnForTable(table);
    int nextId = _nextId(rows, idCol);
    for (final data in dataList) {
      final existingId = data[idCol];
      if (existingId == null || (existingId is int && existingId <= 0)) {
        data[idCol] = nextId++;
      }
      rows.add(Map<String, dynamic>.from(data));
    }
    await _saveTable(table);
  }

  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs}) async {
    final rows = await loadTable(table);
    int count = 0;
    for (int i = 0; i < rows.length; i++) {
      if (where == null || _matchWhere(rows[i], where, whereArgs ?? [])) {
        rows[i] = Map<String, dynamic>.from(rows[i])..addAll(data);
        count++;
      }
    }
    if (count > 0) await _saveTable(table);
    return count;
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final rows = await loadTable(table);
    if (where == null) {
      final count = rows.length;
      rows.clear();
      await _saveTable(table);
      return count;
    }
    final before = rows.length;
    rows.removeWhere((row) => _matchWhere(row, where, whereArgs ?? []));
    await _saveTable(table);
    return before - rows.length;
  }

  void clearCache() { _cache.clear(); }
}
