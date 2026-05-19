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
        return _physicalInterruptReminders;
      case 2:
        return _bodyAnchorReminders;
      default:
        return _workFocusReminders;
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

  /// Work-time focus reminders — one every 30 minutes.
  /// Simple, actionable prompts to bring attention back to the present moment.
  /// No tasks, no goals, no habits — just a gentle nudge to re-center.
  static const _workFocusReminders = [
    '🧘 暂停30秒：做一次深呼吸，感受气息从鼻子进入、经过胸腔、到达腹部，然后缓缓呼出。回到当下。',
    '🧘 身体扫描：注意你此刻的坐姿。肩膀是否紧张？下颌是否紧咬？放松它们，然后继续手头的工作。',
    '🧘 五感锚定：快速注意——你此刻看到的一种颜色、听到的一个声音、感受到的一种触感。你在这里。',
    '🧘 停顿练习：停止思考30秒。只关注你的呼吸。如果念头冒出来，轻轻放它走，回到呼吸。',
    '🧘 当下确认：对自己说"此刻我在这里，我正在工作"。不需要思考下一步，不需要回忆刚才。就在此刻。',
    '🧘 放松双肩：大多数人工作时双肩微微耸起。现在刻意放下肩膀，做3次自然呼吸，然后继续。',
    '🧘 喝水 + 起身：站起来，走到饮水机或窗边，喝一杯水，看一眼窗外，再回到座位。',
    '🧘 注意力重置：闭上眼睛数10次呼吸。每数一次，感觉注意力回到一个更清晰的起点。',
    '🧘 正念眨眼：有意识地眨5次眼，感受眼皮接触的微细感觉。然后放松眼周肌肉，继续工作。',
    '🧘 手掌温暖：双手快速搓热，轻轻盖在闭着的眼睛上。感受掌心的温度和黑暗中的宁静。30秒后放下。',
  ];

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

  /// Body-anchoring reminders for Yellow protection level (20-min intervals).
  /// Evidence base: DBT grounding techniques (Linehan 1993), 5-4-3-2-1 sensory
  /// exercise, somatic experiencing (Levine 1997). When one vulnerability factor
  /// is present (poor sleep OR high anxiety), use body sensations to re-anchor
  /// attention — the body is always in the present moment even when the mind drifts.
  static const _bodyAnchorReminders = [
    '🌍 5-4-3-2-1 接地练习：说出你看到的5样东西 → 触摸到的4样 → 听到的3个声音 → 闻到的2种气味 → 1种身体感受。回到此时此地。',
    '👣 脚底觉察：感受脚掌与地面的接触。脚趾、足弓、脚跟——每一个点的压力。往下扎根，让注意力从脑中降落到脚底。',
    '🫁 4-7-8 呼吸：吸气4秒 → 屏息7秒 → 缓慢呼气8秒。延长呼出激活副交感神经，心率会自然下降。',
    '🤲 掌心按压：双手合十用力推压5秒，然后松开。注意掌心温度和微麻感。物理觉知把大脑从抽象焦虑拉回具体身体。',
    '🪑 坐姿扫描：椅面给大腿的支撑力、靠背给腰的承托、扶手对手肘的触感。这三个接触点是你此刻的锚。',
    '👃 嗅觉唤醒：如果有咖啡/茶/风油精——闻一下，描述气味给脑海中的自己听。嗅觉直达边缘系统，能快速重置情绪状态。',
    '🫀 心跳觉察：右手轻放在胸口，感受心跳的节奏。不急不慢，它只是在做它的工作。你不需要控制它，只需要注意到它。',
    '✋ 温度锚定：手指触摸桌面金属部分、玻璃杯或自己的脸颊。注意温差。温度是最直接的"现在感"——你无法在过去或未来感受到温度。',
    '👂 最远的声音：闭眼5秒，寻找你能听到的最远的声音——空调声、远处车声、隔壁键盘声。听觉扩展打破注意力窄化。',
    '🧘 肩颈松解：吸气时耸起双肩到最高点，呼气时突然放下。重复3次。紧张→释放的身体节律给大脑发送"放松"信号。',
  ];

  /// Physical-interrupt reminders for Red protection level (15-min intervals).
  /// Evidence base: Behavioral activation (Martell 2001), TIPP skills from DBT
  /// (Linehan 2015). When both sleep AND anxiety are poor, cognitive strategies
  /// fail because the amygdala has hijacked the prefrontal cortex. The only way
  /// out is through the body — physical actions that force a state change.
  static const _physicalInterruptReminders = [
    '🚶 起身，走到门口再走回来。就这一段路。身体移动是打破思维死循环最直接的方法。',
    '💧 冷水冲手腕30秒。前臂内侧皮肤薄、血管浅，冷刺激直接激活潜水反射，心率下降、焦虑缓解。现在就去。',
    '🙆 站起来，双手举过头顶，用力伸展全身，保持5秒。像猫伸懒腰一样。身体舒展信号=安全信号传递给大脑。',
    '📦 整理桌面上任意3样东西——对齐杯子、摆正键盘、叠好纸张。简单的物理秩序行为给大脑一个"可控"的反馈。',
    '👁 用力闭眼5秒，然后突然睁大。重复3次。眼轮匝肌的紧张-释放循环刺激眼心反射，帮助副交感神经激活。',
    '🤝 双手快速互搓10秒直到掌心发热，然后敷在闭着的眼睛上。温热+黑暗创造了一个短暂的"避难所"。',
    '🪟 走到窗边，看向窗外最远的一个点，说出它的颜色和形状。远眺放松睫状肌，命名激活前额叶——双重打断焦虑回路。',
    '🙌 十指交叉放在脑后，双肘向外打开，胸腔打开，下巴微抬。保持这个"开放姿势"15秒。扩张的体态改善呼吸深度。',
    '🖐 拿起你手边任意一个小物件——笔、杯子、钥匙——翻转它，观察它的纹理、颜色、重量。用30秒"研究"一个普通物品。好奇心天然排斥焦虑。',
    '🚰 离开座位，走到饮水机或茶水间，接一杯水，站着喝完。这个过程中你移动了、拿取了、吞咽了——三个连续的身体动作构成了一次完整的打断。',
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
    _checks = checkRows.map((r) => DailyCompareCheck.fromJson(r)).toList();

    // Deduplicate plans: same planDate + timePeriod → keep the one with actualNote
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
        // Multiple rows — pick the one with actualNote, delete others
        entry.value.sort((a, b) {
          final noteA = (a['actualNote'] ?? a['actual_note'] ?? '').toString();
          final noteB = (b['actualNote'] ?? b['actual_note'] ?? '').toString();
          return noteB.length.compareTo(noteA.length); // longer note first
        });
        final best = entry.value.first;
        final parts = entry.key.split('|');
        // Delete all duplicates for this planDate + timePeriod
        await db.delete('daily_model_plan',
            where: 'planDate = ? AND timePeriod = ?', whereArgs: [parts[0], parts[1]]);
        // Re-insert only the best row
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
            // Safety net: strip any non-meditation content from work-hour slots
            _sanitizeWorkHourPlans(plans);

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
    // Safety net: strip any non-meditation content from work-hour slots
    _sanitizeWorkHourPlans(generated);

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
