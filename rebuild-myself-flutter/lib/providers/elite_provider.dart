import 'package:flutter/material.dart';
import '../models/elite_habit.dart';
import '../models/daily_plan.dart';
import '../models/daily_check.dart';
import '../models/task.dart';
import '../models/time_block.dart';
import '../models/custom_priority.dart';
import '../models/goal.dart';
import '../models/morning_check_in.dart';
import '../config/holiday_config.dart';
import '../config/reminders.dart';
import '../services/api_client.dart';
import '../services/database_helper.dart';

class EliteProvider extends ChangeNotifier {
  List<EliteHabit> _habits = [];
  List<DailyModelPlan> _plans = [];
  List<DailyCompareCheck> _checks = [];
  List<TimeBlockConfig> _workdayBlocks = [];
  List<TimeBlockConfig> _weekendBlocks = [];
  WorkSchedule _workSchedule = WorkSchedule.defaultSchedule();
  List<CustomPriorityItem> _customItems = [];
  bool _loading = false;
  bool _generating = false;
  MorningCheckIn? _todayCheckIn;
  int _protectionLevel = 1; // 1=Green, 2=Yellow, 3=Red

  List<EliteHabit> get habits => _habits;
  List<DailyModelPlan> get plans => _plans;
  List<DailyCompareCheck> get checks => _checks;
  List<TimeBlockConfig> get workdayBlocks => _workdayBlocks;
  List<TimeBlockConfig> get weekendBlocks => _weekendBlocks;
  WorkSchedule get workSchedule => _workSchedule;
  List<CustomPriorityItem> get customItems => _customItems;
  bool get loading => _loading;
  bool get generating => _generating;
  MorningCheckIn? get todayCheckIn => _todayCheckIn;
  int get protectionLevel => _protectionLevel;

  /// Returns the appropriate reminder set for today's protection level.
  List<String> get _currentWorkReminders {
    switch (_protectionLevel) {
      case 3:
        return RemindersStore.current.physicalInterrupt;
      case 2:
        return RemindersStore.current.bodyAnchor;
      default:
        return RemindersStore.current.focus;
    }
  }

  /// Work-segment block duration in minutes based on protection level.
  int get _workBlockMinutes {
    switch (_protectionLevel) {
      case 3:
        return 15;
      case 2:
        return 20;
      default:
        return 30;
    }
  }

  List<EliteHabit> habitsByCategory(int cat) =>
      _habits.where((h) => h.habitCategory == cat).toList();


  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final habitRows = await db.query('elite_habit_lib');
    // Only load today's plans — loading all historical rows causes O(n)
    // slowdown after weeks of use (each day adds 15–25 rows).
    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    // Only load today's plans — server is source of truth for history.
    // WHERE clause limits the in-memory filter; full fix requires SQLite migration.
    final planRows = await db.query('daily_model_plan',
        where: 'planDate = ?', whereArgs: [todayStr], orderBy: 'time_period');
    final checkRows =
        await db.query('daily_compare_check', orderBy: 'create_time DESC');
    _habits = habitRows.map((r) => EliteHabit.fromJson(r)).toList();
    _checks = checkRows.map((r) => DailyCompareCheck.fromJson(r)).toList();

    // Deduplicate today's plans: same planDate + timePeriod → keep the one with actualNote
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in planRows) {
      final pDate = (r['planDate'] ?? r['plan_date'] ?? '').toString();
      final tPeriod = (r['timePeriod'] ?? r['time_period'] ?? '').toString();
      groups.putIfAbsent('$pDate|$tPeriod', () => []).add(r);
    }
    final deduped = <Map<String, dynamic>>[];
    for (final entry in groups.entries) {
      if (entry.value.length == 1) {
        deduped.add(entry.value.first);
      } else {
        entry.value.sort((a, b) {
          final noteA = (a['actualNote'] ?? a['actual_note'] ?? '').toString();
          final noteB = (b['actualNote'] ?? b['actual_note'] ?? '').toString();
          return noteB.length.compareTo(noteA.length);
        });
        final best = entry.value.first;
        final parts = entry.key.split('|');
        await db.delete('daily_model_plan',
            where: 'planDate = ? AND timePeriod = ?', whereArgs: [parts[0], parts[1]]);
        await db.insert('daily_model_plan', best);
        deduped.add(best);
      }
    }
    _plans = deduped.map((r) => DailyModelPlan.fromJson(r)).toList();
    await _loadTimeBlocks(db);
    await _loadWorkSchedule(db);
    await _loadCustomItems(db);
    await loadTodayCheckIn();
    _loading = false;
    notifyListeners();
  }

  // ---- Time blocks ----

  Future<void> _loadTimeBlocks(dynamic db) async {
    final rows = await db.query('time_block_config');
    final workday = <TimeBlockConfig>[];
    final weekend = <TimeBlockConfig>[];
    for (final r in rows) {
      final block = TimeBlockConfig.fromJson(r);
      if (r['day_type'] == 'weekend') {
        weekend.add(block);
      } else {
        workday.add(block);
      }
    }
    _workdayBlocks = workday.isEmpty ? TimeBlockConfig.defaultWorkday() : workday;
    _weekendBlocks = weekend.isEmpty ? TimeBlockConfig.defaultWeekend() : weekend;
  }

  Future<void> saveTimeBlocks(
      String dayType, List<TimeBlockConfig> blocks) async {
    final db = await DatabaseHelper().db;
    await db.delete('time_block_config', where: 'day_type = ?', whereArgs: [dayType]);
    for (final b in blocks) {
      await db.insert('time_block_config', {
        ...b.toJson(),
        'day_type': dayType,
      });
    }
    if (dayType == 'workday') {
      _workdayBlocks = blocks;
    } else {
      _weekendBlocks = blocks;
    }
    notifyListeners();
  }

  Future<void> resetTimeBlocks(String dayType) async {
    final defaults = dayType == 'workday'
        ? TimeBlockConfig.defaultWorkday()
        : TimeBlockConfig.defaultWeekend();
    await saveTimeBlocks(dayType, defaults);
  }

  List<TimeBlockConfig> blocksForToday() {
    return HolidayConfig.isWorkday(DateTime.now()) ? _workdayBlocks : _weekendBlocks;
  }

  // ---- Work schedule ----

  Future<void> _loadWorkSchedule(dynamic db) async {
    final rows = await db.query('work_schedule', limit: 1);
    if (rows.isNotEmpty) {
      _workSchedule = WorkSchedule.fromJson(rows.first);
    }
  }

  Future<void> saveWorkSchedule(WorkSchedule schedule) async {
    final db = await DatabaseHelper().db;
    await db.delete('work_schedule');
    await db.insert('work_schedule', schedule.toJson());
    _workSchedule = schedule;
    notifyListeners();
  }

  // ---- Morning check-in / protection level ----

  Future<void> loadTodayCheckIn() async {
    final db = await DatabaseHelper().db;
    final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    final rows = await db.query('morning_check_in', where: 'date = ?', whereArgs: [today]);
    if (rows.isNotEmpty) {
      _todayCheckIn = MorningCheckIn.fromJson(rows.first);
      _protectionLevel = _todayCheckIn!.protectionLevel;
    }
  }

  Future<void> saveCheckIn(MorningCheckIn checkIn) async {
    final db = await DatabaseHelper().db;
    await db.insert('morning_check_in', checkIn.toJson());
    _todayCheckIn = checkIn;
    _protectionLevel = checkIn.protectionLevel;
    notifyListeners();
  }

  // ---- Custom priority items ----

  Future<void> _loadCustomItems(dynamic db) async {
    final rows =
        await db.query('custom_priority_item', orderBy: 'create_time');
    final typed = List<Map<String, dynamic>>.from(rows);
    _customItems = typed.map((r) => CustomPriorityItem.fromJson(r)).toList();
  }

  Future<void> addCustomItem(String content, String segment) async {
    final db = await DatabaseHelper().db;
    final now = DateTime.now().toIso8601String();
    await db.insert('custom_priority_item', {
      'content': content,
      'preferredSegment': segment,
      'create_time': now,
    });
    await _loadCustomItems(db);
    notifyListeners();
  }

  Future<void> deleteCustomItem(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('custom_priority_item', where: 'id = ?', whereArgs: [id]);
    await _loadCustomItems(db);
    notifyListeners();
  }

  /// Call AI to generate elite habits based on world-class performers' real routines.
  /// Replaces all existing habits in local storage with AI-generated ones.
  /// Returns true on success.
  Future<bool> generateAiHabits() async {
    final api = ApiClient();
    if (!api.hasToken) return false;

    final resp = await api.post('/elite-habit/generate');
    if (!resp.ok || resp.data == null) return false;

    final List<dynamic> list = resp.data is List ? resp.data : [];
    if (list.isEmpty) return false;

    final db = await DatabaseHelper().db;
    await db.delete('elite_habit_lib');
    for (final item in list) {
      if (item is! Map) continue;
      await db.insert('elite_habit_lib', {
        'habit_category': item['habitCategory'] ?? item['habit_category'],
        'habit_content': item['habitContent'] ?? item['habit_content'],
        'intensity_level': item['intensityLevel'] ?? item['intensity_level'] ?? 2,
        'suit_body_type': 0,
      });
    }
    await loadAll();
    return true;
  }

  // ---- Daily plan / check ----

  Future<void> addCheck(DailyCompareCheck check) async {
    final db = await DatabaseHelper().db;
    await db.insert('daily_compare_check', check.toJson());
    _checks.insert(0, check);
    notifyListeners();
  }

  Future<void> addPlan(DailyModelPlan plan) async {
    final db = await DatabaseHelper().db;
    await db.insert('daily_model_plan', plan.toJson());
    _plans.add(plan);
    notifyListeners();
  }

  /// Record what actually happened during a planned time block.
  /// Looks up the plan by planDate + timePeriod, which is unique per user per day.
  Future<void> updatePlanNote(String planDate, String timePeriod, String actualNote) async {
    final db = await DatabaseHelper().db;
    await db.update('daily_model_plan', {
      'actualNote': actualNote,
    }, where: 'planDate = ? AND timePeriod = ?', whereArgs: [planDate, timePeriod]);

    // Push note to server
    final api = ApiClient();
    if (api.hasToken) {
      await api.put('/plan/note', data: {
        'planDate': planDate,
        'timePeriod': timePeriod,
        'actualNote': actualNote,
      });
    }
    // Update in-memory — no need for full reload
    for (int i = 0; i < _plans.length; i++) {
      if (_plans[i].planDate == planDate && _plans[i].timePeriod == timePeriod) {
        _plans[i] = _plans[i].copyWith(actualNote: actualNote);
        break;
      }
    }
    notifyListeners();
  }

  /// Toggle the completion status of a plan item.
  Future<void> updatePlanCompletion(String planDate, String timePeriod, int isCompleted) async {
    final db = await DatabaseHelper().db;
    final completedAt = isCompleted == 1 ? DateTime.now().toIso8601String() : null;
    await db.update('daily_model_plan', {
      'isCompleted': isCompleted,
      'completedAt': completedAt,
    }, where: 'planDate = ? AND timePeriod = ?', whereArgs: [planDate, timePeriod]);

    // Push to server
    final api = ApiClient();
    if (api.hasToken) {
      try {
        await api.put('/plan/toggle', data: {
          'planDate': planDate,
          'timePeriod': timePeriod,
          'isCompleted': isCompleted,
        });
      } catch (_) {}
    }

    // Update in-memory list
    for (int i = 0; i < _plans.length; i++) {
      if (_plans[i].planDate == planDate && _plans[i].timePeriod == timePeriod) {
        _plans[i] = _plans[i].copyWith(isCompleted: isCompleted, completedAt: completedAt);
      }
    }
    notifyListeners();
  }

  /// Shift time periods when user drags a plan to a new position.
  /// Items between oldIndex and newIndex shift one slot toward the dragged item's
  /// original position; the dragged item takes the far end's time period.
  ///
  /// Example — drag item 0 to position 3:
  ///   P0→P3 (dragged), P1→P0, P2→P1, P3→P2 (items 1-3 shift up)
  /// Example — drag item 3 to position 0:
  ///   P3→P0 (dragged), P2→P3, P1→P2, P0→P1 (items 0-2 shift down)
  Future<void> reorderPlan(String date, int oldIndex, int newIndex) async {
    final todayPlans = _plans
        .where((p) => p.planDate == date)
        .toList()
      ..sort((a, b) => (a.timePeriod ?? '').compareTo(b.timePeriod ?? ''));
    if (oldIndex < 0 || oldIndex >= todayPlans.length) return;
    if (newIndex < 0 || newIndex >= todayPlans.length) return;
    if (oldIndex == newIndex) return;

    final periods = todayPlans.map((p) => p.timePeriod ?? '').toList();

    // Build oldPeriod → newPeriod mapping
    final changes = <String, String>{};

    if (oldIndex < newIndex) {
      // Drag down: items oldIndex+1..newIndex shift UP by one slot each
      for (int i = oldIndex + 1; i <= newIndex; i++) {
        changes[periods[i]] = periods[i - 1];
      }
      // Dragged item takes the target position's period
      changes[periods[oldIndex]] = periods[newIndex];
    } else {
      // Drag up: items newIndex..oldIndex-1 shift DOWN by one slot each
      for (int i = newIndex; i < oldIndex; i++) {
        changes[periods[i]] = periods[i + 1];
      }
      // Dragged item takes the target position's period
      changes[periods[oldIndex]] = periods[newIndex];
    }

    if (changes.isEmpty) return;

    final db = await DatabaseHelper().db;

    // Phase 1: move all affected rows to temp values (avoid key collision)
    int idx = 0;
    for (final oldPeriod in changes.keys) {
      await db.update('daily_model_plan',
          {'timePeriod': '__reorder_$idx', 'time_period': '__reorder_$idx'},
          where: 'planDate = ? AND timePeriod = ?', whereArgs: [date, oldPeriod]);
      idx++;
    }

    // Phase 2: move from temp to final
    idx = 0;
    for (final entry in changes.entries) {
      await db.update('daily_model_plan',
          {'timePeriod': entry.value, 'time_period': entry.value},
          where: 'planDate = ? AND timePeriod = ?', whereArgs: [date, '__reorder_$idx']);
      idx++;
    }

    // Update in-memory
    for (int i = 0; i < _plans.length; i++) {
      final oldPeriod = _plans[i].timePeriod ?? '';
      final newPeriod = changes[oldPeriod];
      if (newPeriod != null) {
        _plans[i] = _plans[i].copyWith(timePeriod: newPeriod);
      }
    }
    _plans.sort((a, b) => (a.timePeriod ?? '').compareTo(b.timePeriod ?? ''));

    Future.microtask(() => notifyListeners());
    await _syncPlansForDate(date);
  }

  /// Update the planContent of an existing plan item.
  Future<void> updatePlanContent(String planDate, String timePeriod, String newContent) async {
    final db = await DatabaseHelper().db;
    await db.update('daily_model_plan', {
      'planContent': newContent,
    }, where: 'planDate = ? AND timePeriod = ?', whereArgs: [planDate, timePeriod]);
    // Update in-memory
    for (int i = 0; i < _plans.length; i++) {
      if (_plans[i].planDate == planDate && _plans[i].timePeriod == timePeriod) {
        _plans[i] = _plans[i].copyWith(planContent: newContent);
        break;
      }
    }
    notifyListeners();
    await _syncPlansForDate(planDate);
  }

  /// Update the time period of an existing plan item (user drag-adjusts time).
  Future<void> updatePlanTime(String planDate, String oldTimePeriod, String newTimePeriod) async {
    if (oldTimePeriod == newTimePeriod) return;
    final db = await DatabaseHelper().db;
    await db.update('daily_model_plan', {
      'timePeriod': newTimePeriod,
      'time_period': newTimePeriod,
    }, where: 'planDate = ? AND timePeriod = ?', whereArgs: [planDate, oldTimePeriod]);
    // Update in-memory
    for (int i = 0; i < _plans.length; i++) {
      if (_plans[i].planDate == planDate && _plans[i].timePeriod == oldTimePeriod) {
        _plans[i] = _plans[i].copyWith(timePeriod: newTimePeriod);
        break;
      }
    }
    _plans.sort((a, b) => (a.timePeriod ?? '').compareTo(b.timePeriod ?? ''));
    notifyListeners();
    await _syncPlansForDate(planDate);
  }

  /// Push today's generated plans to server immediately.
  Future<void> syncPlansToServer() async {
    final api = ApiClient();
    if (!api.hasToken) return;
    final db = await DatabaseHelper().db;
    final allPlans = await db.query('daily_model_plan');
    final unsynced = allPlans.where((r) => r['synced'] != 1).toList();
    if (unsynced.isEmpty) return;
    await api.post('/sync/upload', data: {'plans': unsynced});
    // Mark as synced
    for (final p in unsynced) {
      final id = p['planId'] ?? p['plan_id'];
      if (id != null) {
        await db.update('daily_model_plan', {'synced': 1}, where: 'planId = ?', whereArgs: [id]);
      }
    }
  }

  /// Sync all local plans for a given date to server (batch replace).
  Future<void> _syncPlansForDate(String date) async {
    final api = ApiClient();
    if (!api.hasToken) return;
    final db = await DatabaseHelper().db;
    final allRows = await db.query('daily_model_plan');
    final datePlans = allRows.where((r) {
      final d = r['planDate'] ?? r['plan_date'] ?? '';
      return d.toString() == date;
    }).toList();
    if (datePlans.isEmpty) return;
    // Convert to server format
    final body = datePlans.map((r) {
      final out = <String, dynamic>{};
      out['timePeriod'] = r['timePeriod'] ?? r['time_period'] ?? '';
      out['planContent'] = r['planContent'] ?? r['plan_content'] ?? '';
      out['planType'] = r['planType'] ?? r['plan_type'] ?? 0;
      out['difficulty'] = r['difficulty'] ?? 2;
      out['actualNote'] = r['actualNote'] ?? r['actual_note'] ?? '';
      out['isCompleted'] = r['isCompleted'] ?? r['is_completed'] ?? 0;
      return out;
    }).toList();
    final resp = await api.put('/plan/date/$date', data: body);
    if (resp.ok) {
      for (final r in datePlans) {
        final id = r['planId'] ?? r['plan_id'];
        if (id != null) {
          await db.update('daily_model_plan', {'synced': 1}, where: 'planId = ?', whereArgs: [id]);
        }
      }
    }
  }

  Future<void> clearPlansForDate(String date) async {
    // Delete from local DB
    final db = await DatabaseHelper().db;
    await db.delete('daily_model_plan', where: 'planDate = ?', whereArgs: [date]);
    await db.delete('daily_model_plan', where: 'plan_date = ?', whereArgs: [date]);
    // Delete from server
    final api = ApiClient();
    if (api.hasToken) {
      try {
        await api.delete('/plan/date/$date');
      } catch (_) {}
    }
    await loadAll();
  }

  /// AI-first plan generation via server. Falls back to local rule engine.
  /// Returns the number of plans generated.
  Future<int> generateTodayPlanWithAI(String date, List<TaskTodo> todayTasks,
      {List<TimeBlockConfig>? blocks, List<Goal>? goals}) async {
    _generating = true;
    notifyListeners();
    final api = ApiClient();
    if (api.hasToken) {
      try {
        final db = await DatabaseHelper().db;

        // Collect goal titles from the passed-in goals (not local DB)
        final goalTitles = (goals ?? [])
            .where((g) => g.status != 2)
            .map((g) => g.title)
            .where((t) => t != null && t.isNotEmpty)
            .cast<String>()
            .toList();

        final resp = await api.post('/plan/generate', data: {
          'date': date,
          'goalTitles': goalTitles,
        });
        if (resp.ok && resp.data is List) {
          final List<dynamic> list = resp.data;
          if (list.isNotEmpty) {
            await db.delete('daily_model_plan', where: 'planDate = ?', whereArgs: [date]);
            await db.delete('daily_model_plan', where: 'plan_date = ?', whereArgs: [date]);

            // Convert to DailyModelPlan objects and tag with goal titles
            final plans = <DailyModelPlan>[];
            for (final item in list) {
              if (item is! Map) continue;
              plans.add(DailyModelPlan(
                planDate: date,
                timePeriod: (item['timePeriod'] ?? item['time_period'] ?? '').toString(),
                planContent: (item['planContent'] ?? item['plan_content'] ?? '').toString(),
                planType: int.tryParse((item['planType'] ?? item['plan_type'] ?? '0').toString()) ?? 0,
                difficulty: int.tryParse((item['difficulty'] ?? '2').toString()) ?? 2,
              ));
            }

            // Ensure every goal gets at least one plan item
            _tagPlanWithGoalTitles(plans, goals ?? []);
            // Move voice/speaking content to evening slots
            _moveVoiceContentToEvening(plans);
            // Only sanitize work-hour plans on workdays
            if (HolidayConfig.isWorkday(DateTime.now())) {
              _sanitizeWorkHourPlans(plans);
            }

            // Insert all plans — already saved on server, mark synced
            for (final p in plans) {
              final data = p.toJson();
              data['synced'] = 1;
              await db.insert('daily_model_plan', data);
            }

            await loadAll();
            _generating = false;
            notifyListeners();
            return plans.length;
          }
        }
      } catch (_) {
        // Fall through to local generation
      }
    }
    // Fallback to local rule engine
    final result = await generateTodayPlan(date, todayTasks, blocks: blocks, goals: goals);
    _generating = false;
    notifyListeners();
    return result;
  }

  /// Generate today's full-day plan (local rule engine).
  /// Weekdays: 5 segments from WorkSchedule + habits + custom items + tasks.
  /// Weekends: original time-block logic.
  /// Returns the number of plans generated.
  Future<int> generateTodayPlan(String date, List<TaskTodo> todayTasks,
      {List<TimeBlockConfig>? blocks, List<Goal>? goals}) async {
    final db = await DatabaseHelper().db;

    // Clear existing plans for this date (both naming conventions)
    await db.delete('daily_model_plan', where: 'planDate = ?', whereArgs: [date]);
    await db.delete('daily_model_plan', where: 'plan_date = ?', whereArgs: [date]);

    final isWeekend = !HolidayConfig.isWorkday(DateTime.now());

    final generated = isWeekend
        ? _buildWeekendPlans(date, todayTasks, blocks)
        : _buildWeekdayPlans(date, todayTasks);

    // Post-process: tag plans with matching goal titles
    _tagPlanWithGoalTitles(generated, goals ?? []);
    // Move voice/speaking content to evening slots
    _moveVoiceContentToEvening(generated);
    // Safety net: strip any non-meditation content from work-hour slots
    // Only on workdays — weekends keep learning/task content during the day.
    if (!isWeekend) _sanitizeWorkHourPlans(generated);

    // Batch insert all plans in a single write
    await db.insertBatch('daily_model_plan',
        generated.map((p) => p.toJson()).toList());

    // Single reload at the end
    await loadAll();
    await _syncPlansForDate(date);
    return generated.length;
  }

  /// Post-process plans to prepend matching goal titles.
  /// Ensures every active goal appears in at least one plan item.
  /// Post-process plans to prepend matching goal titles.
  /// Ensures every active goal appears in at least one plan item.
  void _tagPlanWithGoalTitles(List<DailyModelPlan> plans, List<Goal> goals) {
    if (goals.isEmpty) return;

    // Filter to active goals only
    final active = goals
        .where((g) => g.status != 2 && g.title != null && g.title!.isNotEmpty)
        .toList();
    if (active.isEmpty) return;

    // Track which goals have been matched
    final matched = <int, bool>{};
    for (int i = 0; i < active.length; i++) {
      matched[i] = false;
    }

    // Pass 1: tag existing plans with matching goal titles
    for (int i = 0; i < plans.length; i++) {
      final plan = plans[i];
      final planContent = plan.planContent ?? '';
      if (planContent.isEmpty || planContent.startsWith('【')) continue;
      // Never tag work-hour plans — they are meditation reminders only
      final period = plan.timePeriod ?? '';
      if (period.contains('-') && _isWorkSegment(period.split('-')[0])) continue;

      for (int j = 0; j < active.length; j++) {
        if (matched[j] == true) continue;
        final title = active[j].title!;
        if (_contentMatchesGoal(planContent, title)) {
          plans[i] = plan.copyWith(planContent: '【$title】$planContent');
          matched[j] = true;
          break;
        }
      }
    }

    // Pass 2: for unmatched goals, create dedicated plan items
    final now = DateTime.now();
    final isWeekend = !HolidayConfig.isWorkday(now);
    int unmatchedCount = 0;

    for (int j = 0; j < active.length; j++) {
      if (matched[j] == true) continue;
      final goal = active[j];
      final title = goal.title!;
      final type = goal.goalType ?? 0;
      final goalContent = goal.content ?? '';

      // Pick appropriate time slot by goal type
      String period;
      int planType;
      switch (type) {
        case 3: // health → morning
          period = isWeekend ? '07:00-07:30' : '06:30-07:00';
          planType = 4;
          break;
        case 2: // finance → evening
          period = isWeekend ? '20:00-20:30' : '20:00-20:30';
          planType = 2;
          break;
        case 1: // study → evening deep focus
        default:
          period = unmatchedCount == 0
              ? (isWeekend ? '19:00-19:30' : '19:00-19:30')
              : (isWeekend ? '19:30-20:00' : '19:30-20:00');
          planType = 1;
          break;
      }
      unmatchedCount++;
      // Offset each unmatched goal by 30 minutes
      if (unmatchedCount > 1) {
        final base = _parseTimeToMinutes(period.split('-')[0]);
        final shifted = base + (unmatchedCount - 1) * 30;
        final h = shifted ~/ 60;
        final m = shifted % 60;
        period = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}-'
            '${(h + (m + 30) ~/ 60).toString().padLeft(2, '0')}:${((m + 30) % 60).toString().padLeft(2, '0')}';
      }

      final execContent = goalContent.isNotEmpty
          ? '【$title】今天执行：$goalContent'
          : '【$title】今天推进：$title';
      plans.add(DailyModelPlan(
        planDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        timePeriod: period,
        planContent: execContent,
        planType: planType,
        difficulty: 3,
      ));
    }
  }

  int _parseTimeToMinutes(String t) {
    final parts = t.split(':');
    return int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
  }

  /// Simple heuristic: check if plan content relates to a goal title.
  bool _contentMatchesGoal(String content, String goalTitle) {
    // Extract significant keywords from goal title (2+ char words)
    final goalWords = goalTitle
        .split(RegExp(r'[\s，,、。；;：:（()）]'))
        .where((w) => w.length >= 2)
        .toList();
    if (goalWords.isEmpty) return false;
    // If any significant keyword from the goal appears in the plan content, it's a match
    return goalWords.any((w) => content.contains(w));
  }

  /// Returns true if the given time string falls within a work segment.
  /// Handles both "HH:MM" and "HH:MM-HH:MM" formats.
  /// Returns false for non-standard formats (e.g. "晨间", "上午" from server fallback).
  bool _isWorkSegment(String timeStr) {
    final hhmm = timeStr.contains('-') ? timeStr.split('-')[0] : timeStr;
    if (!hhmm.contains(':')) return false;
    final seg = _workSchedule.segmentFor(hhmm);
    return seg == '上班时·上午' || seg == '上班时·下午';
  }

  /// Safety net: replaces any non-meditation content in work-hour slots
  /// with rotating focus reminders. This guards against AI-generated plans
  /// or goal-tagging that may have leaked into work segments.
  void _sanitizeWorkHourPlans(List<DailyModelPlan> plans) {
    int workFocusIdx = 0;
    for (int i = 0; i < plans.length; i++) {
      final plan = plans[i];
      final period = plan.timePeriod ?? '';
      if (!_isWorkSegment(period)) continue;
      // Already a work-time reminder? Check by type and known reminder content
      if (plan.planType == 5) {
        final content = plan.planContent ?? '';
        final knownEmojis = ['🧘', '🌍', '👣', '🫁', '🤲', '🪑', '👃', '🫀', '✋', '👂', '🚶', '💧', '🙆', '📦', '👁', '🤝', '🪟', '🙌', '🖐', '🚰'];
        if (knownEmojis.any((e) => content.contains(e))) continue;
      }
      // Replace with a fresh focus reminder
      final reminder = _currentWorkReminders[workFocusIdx % _currentWorkReminders.length];
      plans[i] = plan.copyWith(
        planContent: reminder,
        planType: 5,
        difficulty: 1,
      );
      workFocusIdx++;
    }
  }

  /// Move plans that require speaking aloud (English/speech practice)
  /// to evening slots so the user doesn't disturb others during the day.
  void _moveVoiceContentToEvening(List<DailyModelPlan> plans) {
    const voiceKeywords = ['英语', '演讲', '口语', '发音', '朗读', '背诵', 'speech', 'talk', 'speak'];
    bool isVoice(String? s) =>
        s != null && voiceKeywords.any((k) => s.contains(k));

    // Collect indices of voice-content plans (not already in evening)
    final voiceIndices = <int>[];
    final eveningIndices = <int>[];
    for (int i = 0; i < plans.length; i++) {
      final period = plans[i].timePeriod ?? '';
      final content = plans[i].planContent ?? '';
      final startHour = int.tryParse(period.split(':').first) ?? -1;
      if (startHour >= 18) {
        eveningIndices.add(i);
      } else if (isVoice(content)) {
        voiceIndices.add(i);
      }
    }
    if (voiceIndices.isEmpty || eveningIndices.isEmpty) return;

    // Swap voice plans into evening slots (from the last evening slot backward)
    for (int vi = 0; vi < voiceIndices.length; vi++) {
      final ei = eveningIndices.length - 1 - vi;
      if (ei < 0) break;
      final vIdx = voiceIndices[vi];
      final eIdx = eveningIndices[ei];
      // Only swap if the evening plan isn't voice content itself
      if (!isVoice(plans[eIdx].planContent)) {
        final tmp = plans[vIdx];
        plans[vIdx] = plans[eIdx];
        plans[eIdx] = tmp;
      }
    }
  }

  // ---- Weekday: segment-based plan (builds list, no DB) ----

  List<DailyModelPlan> _buildWeekdayPlans(String date, List<TaskTodo> todayTasks) {
    final tasks = List<TaskTodo>.from(todayTasks)
      ..sort((a, b) => (a.taskLevel ?? 4).compareTo(b.taskLevel ?? 4));

    final ws = _workSchedule;
    final blocks = ws.buildDayBlocks(workBlockMinutes: _workBlockMinutes);

    // Partition custom items by preferred segment
    final beforeWorkItems = _customItems
        .where((c) => c.preferredSegment == '上班前').toList();
    final lunchItems =
        _customItems.where((c) => c.preferredSegment == '午休').toList();
    final afterWorkItems = _customItems
        .where((c) => c.preferredSegment == '下班后').toList();

    final morningHabits = _habits.where((h) => h.habitCategory == 1).toList();
    final allDayHabits = _habits.where((h) => h.habitCategory == 2).toList();
    final lunchHabits = allDayHabits
        .where((h) => (h.habitContent ?? '').contains('午休') || (h.habitContent ?? '').contains('午间'))
        .toList();
    final eveningHabits = _habits.where((h) => h.habitCategory == 3).toList();
    final nightHabits = _habits.where((h) => h.habitCategory == 4).toList();

    // Indexes for cycling through items when more blocks than items
    int customBeforeIdx = 0, customLunchIdx = 0, customAfterIdx = 0;
    int morningIdx = 0, lunchDayIdx = 0, eveningIdx = 0, nightIdx = 0;
    int taskIdx = 0;
    int afterWorkNudgeIdx = 0;
    int workFocusIdx = 0; // cycles through work-time mindfulness reminders
    final generated = <DailyModelPlan>[];

    for (final block in blocks) {
      final period = block.periodLabel;
      final seg = ws.segmentFor(block.start);
      String? content;
      int planType = 0;
      int difficulty = 2;

      switch (seg) {
        case '上班前':
          if (customBeforeIdx < beforeWorkItems.length) {
            content = '⭐ ${beforeWorkItems[customBeforeIdx].content}';
            planType = 1;
            difficulty = 4;
            customBeforeIdx++;
          } else if (morningIdx < morningHabits.length) {
            final h = morningHabits[morningIdx];
            content = '🌅 ${h.habitContent}';
            planType = _habitToPlanType(h.habitCategory);
            difficulty = h.intensityLevel ?? 1;
            morningIdx++;
          } else if (taskIdx < tasks.length &&
              (tasks[taskIdx].taskLevel == 1 || tasks[taskIdx].taskLevel == 2)) {
            final t = tasks[taskIdx];
            content = '📌 ${t.taskTitle ?? "待办"}';
            planType = _taskToPlanType(t.taskLevel);
            difficulty = t.taskLevel == 1 ? 4 : 3;
            taskIdx++;
          } else {
            content = '早起仪式：洗漱、喝水、晨间拉伸';
            planType = 5;
            difficulty = 1;
          }
          break;

        case '上班时·上午':
        case '上班时·下午':
          content = _currentWorkReminders[workFocusIdx % _currentWorkReminders.length];
          planType = 5;
          difficulty = 1;
          workFocusIdx++;
          break;

        case '午休':
          if (customLunchIdx < lunchItems.length) {
            content = '⭐ ${lunchItems[customLunchIdx].content}';
            planType = 4;
            difficulty = 2;
            customLunchIdx++;
          } else if (lunchDayIdx < lunchHabits.length) {
            final h = lunchHabits[lunchDayIdx];
            content = '🍱 ${h.habitContent}';
            planType = 5;
            difficulty = h.intensityLevel ?? 1;
            lunchDayIdx++;
          } else {
            content = '午餐 + 闭眼放松15分钟，恢复精力';
            planType = 4;
            difficulty = 1;
          }
          break;

        case '下班后':
          if (customAfterIdx < afterWorkItems.length) {
            content = '⭐ ${afterWorkItems[customAfterIdx].content}';
            planType = 1;
            difficulty = 4;
            customAfterIdx++;
          } else if (taskIdx < tasks.length) {
            final t = tasks[taskIdx];
            content = '📌 ${t.taskTitle ?? "待办"}';
            planType = _taskToPlanType(t.taskLevel);
            difficulty = t.taskLevel == 1 ? 4 : (t.taskLevel == 2 ? 3 : 2);
            taskIdx++;
          } else if (eveningIdx < eveningHabits.length) {
            final h = eveningHabits[eveningIdx];
            content = '🌆 ${h.habitContent}';
            planType = _habitToPlanType(h.habitCategory);
            difficulty = h.intensityLevel ?? 2;
            eveningIdx++;
          } else if (nightIdx < nightHabits.length) {
            final h = nightHabits[nightIdx];
            content = '🌙 ${h.habitContent}';
            planType = 5;
            difficulty = h.intensityLevel ?? 1;
            nightIdx++;
          } else {
            content = '自由安排 — 学习/阅读/副业';
            planType = 0;
            difficulty = 2;
          }
          break;
      }

      if (content != null) {
        // Inject rotating anti-short-video psychology nudge to after-work plans
        if (seg == '下班后') {
          final nudge = RemindersStore.current.antiDoomscroll[afterWorkNudgeIdx % RemindersStore.current.antiDoomscroll.length];
          content = '$content\n$nudge';
          afterWorkNudgeIdx++;
        }
        generated.add(DailyModelPlan(
            planDate: date,
            timePeriod: period,
            planContent: content,
            planType: planType,
            difficulty: difficulty));
      }
    }

    return generated;
  }

  // ---- Weekend: original logic (builds list, no DB) ----

  List<DailyModelPlan> _buildWeekendPlans(String date, List<TaskTodo> todayTasks,
      List<TimeBlockConfig>? blocks) {
    final tasks = List<TaskTodo>.from(todayTasks)
      ..sort((a, b) => (a.taskLevel ?? 4).compareTo(b.taskLevel ?? 4));

    final useBlocks = blocks ?? _weekendBlocks;
    final generated = <DailyModelPlan>[];
    int taskIdx = 0;

    for (final block in useBlocks) {
      final period = block.periodLabel;
      if (block.type == 0) {
        generated.add(DailyModelPlan(
            planDate: date,
            timePeriod: period,
            planContent: block.label.isNotEmpty ? block.label : '固定安排',
            planType: 5,
            difficulty: 2));
      } else if (block.type == 1) {
        if (taskIdx < tasks.length) {
          final task = tasks[taskIdx];
          generated.add(DailyModelPlan(
              planDate: date,
              timePeriod: period,
              planContent: '📌 ${task.taskTitle ?? "待办"}',
              planType: _taskToPlanType(task.taskLevel),
              difficulty:
                  task.taskLevel == 1 ? 4 : (task.taskLevel == 2 ? 3 : 2)));
          taskIdx++;
        } else {
          generated.add(DailyModelPlan(
              planDate: date,
              timePeriod: period,
              planContent:
                  block.label.isNotEmpty ? block.label : '自由安排 — 学习/阅读/副业',
              planType: 0,
              difficulty: 2));
        }
      } else {
        generated.add(DailyModelPlan(
            planDate: date,
            timePeriod: period,
            planContent: block.label.isNotEmpty ? block.label : '自由安排',
            planType: block.label.contains('运动')
                ? 3
                : (block.label.contains('学习') ? 1 : 4),
            difficulty: 2));
      }
    }

    if (taskIdx < tasks.length) {
      final overflow = tasks.sublist(taskIdx);
      final last = generated.removeLast();
      generated.add(DailyModelPlan(
        planDate: last.planDate,
        timePeriod: last.timePeriod,
        planContent: '${last.planContent} + ${overflow.length}项待办',
        planType: last.planType,
        difficulty: (last.difficulty ?? 2) + 1,
      ));
    }

    return generated;
  }

  // ---- Helpers ----

  int _taskToPlanType(int? level) {
    return switch (level) {
      1 => 1,
      2 => 2,
      3 => 5,
      4 => 1,
      _ => 0,
    };
  }

  int _habitToPlanType(int? category) {
    return switch (category) {
      1 => 3, // 晨间 → 阅读/运动
      2 => 5, // 日间 → 心理
      3 => 1, // 下班后 → 学习
      4 => 5, // 睡前 → 心理
      _ => 0,
    };
  }

}
