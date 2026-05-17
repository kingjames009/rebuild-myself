import 'package:flutter/material.dart';
import '../models/elite_habit.dart';
import '../models/daily_plan.dart';
import '../models/daily_check.dart';
import '../models/task.dart';
import '../models/time_block.dart';
import '../models/custom_priority.dart';
import '../models/goal.dart';
import '../config/holiday_config.dart';
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

  List<EliteHabit> get habits => _habits;
  List<DailyModelPlan> get plans => _plans;
  List<DailyCompareCheck> get checks => _checks;
  List<TimeBlockConfig> get workdayBlocks => _workdayBlocks;
  List<TimeBlockConfig> get weekendBlocks => _weekendBlocks;
  WorkSchedule get workSchedule => _workSchedule;
  List<CustomPriorityItem> get customItems => _customItems;
  bool get loading => _loading;
  bool get generating => _generating;

  List<EliteHabit> habitsByCategory(int cat) =>
      _habits.where((h) => h.habitCategory == cat).toList();

  /// MCT (Metacognitive Therapy) based anti-rumination protocol.
  /// Core insight: rumination is maintained by the CAS (Cognitive Attentional Syndrome) —
  /// a learned pattern of responding to intrusive thoughts with extended thinking,
  /// threat monitoring, and thought suppression. All three backfire.
  ///
  /// Treatment target: break the CAS loop. Not by challenging thought content,
  /// but by changing the metacognitive relationship to thoughts.
  /// Skill requires repetition — the same small set of practices repeats daily.
  ///
  /// Reference: Wells (2009, 2020); Normann & Morina (2018, meta-analysis).
  static const _mctProtocol = [
    // === Attention Training Technique (micro version, 2-3 min) ===
    // Wells' ATT is the first-line MCT intervention. It rebuilds executive
    // attentional control independent of thought content. The full protocol
    // is 12 min; this is a desk-friendly micro version.
    'ATT注意训练：闭眼，依次专注你听到的第1种声音(5s)→第2种(5s)→第3种(5s)，'
        '然后快速在这3种声音间切换(10次)，最后同时关注所有声音(15s)。'
        '目的不是放松，是训练你把注意力从内部念头拉回外部现实的执行控制力。',

    // === Detached Mindfulness ===
    // The core MCT stance. Key: the goal is NOT to reduce the thought,
    // NOT to challenge its content, NOT to replace it with a positive thought.
    // The goal is to change your RELATIONSHIP to the thought — from fusion
    // (believing and engaging) to detached awareness.
    '分离觉察：当你注意到自己在反刍，暂停。对自己说"这是一个正在出现的想法"。'
        '不分析它为什么来，不判断它是对是错，不试图推开它。'
        '就像你在公交站等车——各种车来了又走，你不是必须上去。',

    // === Situational Attentional Refocusing (SAR) ===
    // The 3-step in-the-moment procedure when rumination is detected.
    '反刍中断3步法：(1)标记——"这是反刍，不是解决问题"；'
        '(2)外移——将注意力转向一个外部刺激（屏幕上的一个字、键盘的触感、窗外的声音）；'
        '(3)行为启动——立即开始一个具体的动作（打一个字、拿水杯、站起来）。',

    // === Concrete Processing Switch ===
    // Based on Watkins' RFCBT. Rumination operates in abstract/analytical mode
    // ("why am I like this"). The antidote is concrete/experiential processing
    // ("what exactly happened, moment by moment"). This is a cognitive mode switch.
    '具体化切换：反刍的认知特征是抽象分析——"为什么我总这样"、"这说明了什么"。'
        '强制切换到具体层面：当前房间里有什么？你正在做的任务下一步具体动作是什么？'
        '你能用手碰到的最近一样东西是什么材质？用感官信息替代概念化思考。',

    // === Behavioral Experiment ===
    // MCT challenges the metacognitive belief "I need to think this through / I can't
    // control these thoughts" through experimentation rather than argument.
    '行为实验：如果你相信"不想清楚这件事就没法工作"，做个测试——'
        '给自己30分钟完全不想它，只做具体任务。30分钟后检查：你完成了什么？'
        '你完成的工作量是否超过你边反刍边工作的产出？用数据而非感觉来验证信念。',
  ];

  /// Reminder: the first item in the protocol is ATT, which works best as a
  /// dedicated morning session. The remaining items cycle through work hours.
  /// Repeating the same 5 items daily is intentional — skill consolidation
  /// requires repetition, not novelty.

  /// Anti-short-video behavioral nudges for after-work hours.
  /// Each is a proven clinical psychology technique applied to the
  /// specific cue→craving→scroll→regret loop of short-video addiction.
  static const _antiDoomscrollNudges = [
    // === Implementation Intention (Gollwitzer 1999) ===
    // The most replicated behavioral-science finding: specifying a concrete
    // "if X, then Y" plan doubles follow-through vs. vague intentions.
    '🧠 执行意图：如果手伸向短视频→立即站起来喝一口水，用身体动作打断自动化反应。'
        '预先决定比临场抵抗有效2倍。',

    // === Urge Surfing (Marlatt 1985, Bowen 2019) ===
    // RCTs show cravings follow a predictable wave: peak at ~20 min, subside
    // regardless of whether you give in. The skill is riding the wave, not
    // suppressing it.
    '🏄 冲动冲浪：刷短视频的渴望像海浪，会在20分钟内自然消退。'
        '不用对抗它——观察它上升、停留、退去。你现在正处于波浪的哪一段？',

    // === MCT Detached Mindfulness (Wells 2009) ===
    '🧘 分离觉察："我有一个想刷短视频的冲动"——看见它，不评判，不追随。'
        '念头只是大脑的天气预报，你不是必须带伞。',

    // === Environmental Design (Thaler & Sunstein 2008 nudge theory) ===
    '🚪 环境重构：给手机设灰度模式、把短视频APP移到第二屏的文件夹里、'
        '在沙发上放一本摊开的书。让好选择比坏选择更省力。',

    // === 5-Minute Delay (Rachlin 2000, discounting curve) ===
    '⏳ 5分钟延迟：想刷的时候对自己说"先做5分钟正事，想刷再刷"。'
        '5分钟后多巴胺峰值已过，你会发现自己根本没开始刷。',

    // === Cost Visualization (Epstein 2014, episodic future thinking) ===
    '🔮 未来投射：想象今晚9点——你为自己完成了计划而满足，还是为刷了2小时而自责？'
        '用具体画面判断。你选哪个版本的今晚？',

    // === Attention Refocus (Wells 1990 ATT) ===
    '👁 注意力外移：当刷屏冲动出现时，立即关注一件外部事物——窗外树叶的纹理、'
        '键盘的触感、呼吸时胸腔的起伏。把注意力从"内部渴求"拉回"外部现实"。',

    // === Temptation Bundling (Milkman 2014) ===
    '🤝 诱惑捆绑：把想做的事和该做的事绑定。"只有在做完20分钟副业后，才能刷10分钟"。'
        '既不完全剥夺，也不完全放纵——给冲动一个受限的出口。',

    // === Habit Loop Interruption (Duhigg 2012) ===
    '🔄 习惯回路切断：刷视频的回路是 信号(无聊)→行为(打开APP)→奖励(新奇刺激)。'
        '这次试试换个行为——无聊时做10个俯卧撑，奖励自己一句肯定的话。',

    // === Progressive Delay (Stitzer 1977, behavioral economics) ===
    '📉 渐进延迟：如果现在就想刷，设一个10分钟倒计时。10分钟后还想刷就再延10分钟。'
        '每一次延迟都是在重训大脑的等待能力，不要小看。',
  ];

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final db = await DatabaseHelper().db;
    final habitRows = await db.query('elite_habit_lib');
    final planRows =
        await db.query('daily_model_plan', orderBy: 'time_period');
    final checkRows =
        await db.query('daily_compare_check', orderBy: 'create_time DESC');
    _habits = habitRows.map((r) => EliteHabit.fromJson(r)).toList();
    _plans = planRows.map((r) => DailyModelPlan.fromJson(r)).toList();
    _checks = checkRows.map((r) => DailyCompareCheck.fromJson(r)).toList();
    await _loadTimeBlocks(db);
    await _loadWorkSchedule(db);
    await _loadCustomItems(db);
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
    await loadAll();
  }

  Future<void> addPlan(DailyModelPlan plan) async {
    final db = await DatabaseHelper().db;
    await db.insert('daily_model_plan', plan.toJson());
    await loadAll();
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
    await loadAll();
  }

  /// Shift time periods when user drags a plan to a new position.
  /// Instead of swapping two items, all items between old and new index
  /// shift their time periods one slot to make room.
  Future<void> reorderPlan(String date, int oldIndex, int newIndex) async {
    final todayPlans = _plans
        .where((p) => p.planDate == date)
        .toList()
      ..sort((a, b) => (a.timePeriod ?? '').compareTo(b.timePeriod ?? ''));
    if (oldIndex < 0 || oldIndex >= todayPlans.length) return;
    if (newIndex < 0 || newIndex >= todayPlans.length) return;
    if (oldIndex == newIndex) return;

    // Collect all time periods in sorted order
    final periods = todayPlans.map((p) => p.timePeriod ?? '').toList();
    // Remove the dragged item's period from its old position
    final draggedPeriod = periods.removeAt(oldIndex);
    // Insert it at the new position — all items in between shift one slot
    periods.insert(newIndex, draggedPeriod);

    final db = await DatabaseHelper().db;
    for (int i = 0; i < todayPlans.length; i++) {
      final plan = todayPlans[i];
      final newPeriod = periods[i];
      if (plan.timePeriod != newPeriod) {
        await db.update('daily_model_plan',
            {'timePeriod': newPeriod, 'time_period': newPeriod},
            where: 'planId = ?', whereArgs: [plan.planId]);
      }
    }

    await loadAll();
  }

  /// Update the planContent of an existing plan item.
  Future<void> updatePlanContent(String planDate, String timePeriod, String newContent) async {
    final db = await DatabaseHelper().db;
    await db.update('daily_model_plan', {
      'planContent': newContent,
    }, where: 'planDate = ? AND timePeriod = ?', whereArgs: [planDate, timePeriod]);

    final api = ApiClient();
    if (api.hasToken) {
      await api.put('/plan/content', data: {
        'planDate': planDate,
        'timePeriod': timePeriod,
        'planContent': newContent,
      });
    }
    await loadAll();
  }

  /// Update the time period of an existing plan item (user drag-adjusts time).
  Future<void> updatePlanTime(String planDate, String oldTimePeriod, String newTimePeriod) async {
    if (oldTimePeriod == newTimePeriod) return;
    final db = await DatabaseHelper().db;
    await db.update('daily_model_plan', {
      'timePeriod': newTimePeriod,
      'time_period': newTimePeriod,
    }, where: 'planDate = ? AND timePeriod = ?', whereArgs: [planDate, oldTimePeriod]);

    final api = ApiClient();
    if (api.hasToken) {
      await api.put('/plan/time', data: {
        'planDate': planDate,
        'oldTimePeriod': oldTimePeriod,
        'newTimePeriod': newTimePeriod,
      });
    }
    await loadAll();
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

  Future<void> clearPlansForDate(String date) async {
    final db = await DatabaseHelper().db;
    await db.delete('daily_model_plan', where: 'planDate = ?', whereArgs: [date]);
    await db.delete('daily_model_plan', where: 'plan_date = ?', whereArgs: [date]);
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

            // Insert all plans
            for (final p in plans) {
              await db.insert('daily_model_plan', p.toJson());
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

    // Batch insert all plans in a single write
    await db.insertBatch('daily_model_plan',
        generated.map((p) => p.toJson()).toList());

    // Single reload at the end
    await loadAll();
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

  // ---- Weekday: 1-hour block plan (builds list, no DB) ----

  List<DailyModelPlan> _buildWeekdayPlans(String date, List<TaskTodo> todayTasks) {
    final tasks = List<TaskTodo>.from(todayTasks)
      ..sort((a, b) => (a.taskLevel ?? 4).compareTo(b.taskLevel ?? 4));

    final ws = _workSchedule;
    final blocks = ws.buildDayBlocks(); // 1-hour blocks

    // Partition custom items by preferred segment
    final beforeWorkItems = _customItems
        .where((c) => c.preferredSegment == '上班前').toList();
    final lunchItems =
        _customItems.where((c) => c.preferredSegment == '午休').toList();
    final afterWorkItems = _customItems
        .where((c) => c.preferredSegment == '下班后').toList();

    final morningHabits = _habits.where((h) => h.habitCategory == 1).toList();
    final allDayHabits = _habits.where((h) => h.habitCategory == 2).toList();
    // Day habits that are lunch-specific — keep them out of work-hour blocks
    final lunchHabits = allDayHabits
        .where((h) => (h.habitContent ?? '').contains('午休') || (h.habitContent ?? '').contains('午间'))
        .toList();
    final workDayHabits = allDayHabits
        .where((h) => !(h.habitContent ?? '').contains('午休') && !(h.habitContent ?? '').contains('午间'))
        .toList();
    final eveningHabits = _habits.where((h) => h.habitCategory == 3).toList();
    final nightHabits = _habits.where((h) => h.habitCategory == 4).toList();

    // Indexes for cycling through items when more blocks than items
    int customBeforeIdx = 0, customLunchIdx = 0, customAfterIdx = 0;
    int morningIdx = 0, workDayIdx = 0, lunchDayIdx = 0, eveningIdx = 0, nightIdx = 0;
    int taskIdx = 0;
    int afterWorkNudgeIdx = 0;
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
          if (workDayHabits.isNotEmpty) {
            final h = workDayHabits[workDayIdx % workDayHabits.length];
            content = '🧘 ${h.habitContent}';
            planType = 5;
            difficulty = h.intensityLevel ?? 1;
            workDayIdx++;
          } else {
            content = _mctProtocol[workDayIdx % _mctProtocol.length];
            planType = 5;
            difficulty = 2;
            workDayIdx++;
          }
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
          final nudge = _antiDoomscrollNudges[afterWorkNudgeIdx % _antiDoomscrollNudges.length];
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
