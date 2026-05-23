import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/shell.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/record_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/elite_provider.dart';
import '../../providers/study_provider.dart';
import '../../providers/focus_timer_provider.dart';
import '../../models/daily_plan.dart';
import '../../models/goal.dart';
import '../../models/morning_check_in.dart';
import '../../services/sync_service.dart';
import '../../services/api_client.dart';
import '../../services/database_helper.dart';
import '../../services/notification_service.dart';
import '../../config/reminders.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// Increment to signal that the home tab has been selected and data should reload.
  static final ValueNotifier<int> tabSelected = ValueNotifier<int>(0);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _onboardingShown = false;
  int _lastTabSignal = 0;
  Timer? _focusRefreshTimer;
  final ValueNotifier<int> _focusTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.init();
    HomePage.tabSelected.addListener(_onTabSelected);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SyncService().syncAll();
      await _loadData();
      if (mounted) await _checkMorningCheckIn();
      if (mounted) _checkOnboarding();
    });
    // Refresh current-focus card every 30s so it tracks time-slot transitions
    // without depending on FocusTimerProvider's ticking (only runs when active).
    // Scoped refresh: only the current-focus card rebuilds, not the entire page.
    _focusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _focusTick.value++;
    });
  }

  @override
  void dispose() {
    _focusRefreshTimer?.cancel();
    _focusTick.dispose();
    HomePage.tabSelected.removeListener(_onTabSelected);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabSelected() {
    if (!mounted) return;
    if (HomePage.tabSelected.value == _lastTabSignal) return;
    _lastTabSignal = HomePage.tabSelected.value;
    // Provider handles cross-page state. Server sync runs in background only.
    SyncService().syncAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sendCurrentTaskNotification();
      context.read<FocusTimerProvider>().persistSession();
    } else if (state == AppLifecycleState.resumed) {
      // Only restore timer session on resume — no need to reload all data.
      context.read<FocusTimerProvider>().restoreSession();
      SyncService().syncAll();
    }
  }

  void _sendCurrentTaskNotification() {
    final elite = context.read<EliteProvider>();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentMin = now.hour * 60 + now.minute;

    dynamic currentPlan;
    for (final p in elite.plans) {
      if (p.planDate != dateStr) continue;
      final period = p.timePeriod;
      if (period == null) continue;
      final parts = period.split('-');
      if (parts.length != 2) continue;
      final start = _parseMinutesStr(parts[0]);
      final end = _parseMinutesStr(parts[1]);
      if (start == null || end == null) continue;
      if (currentMin >= start && currentMin < end) {
        currentPlan = p;
        break;
      }
    }

    if (currentPlan != null) {
      final content = currentPlan.planContent ?? '';
      final periodLabel = currentPlan.timePeriod ?? '';
      NotificationService.show('当前任务 $periodLabel', content);
    }
  }

  int? _parseMinutesStr(String hhmm) {
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Load local data first so the UI is responsive immediately.
    // Server sync runs in background and merges results afterward.
    await context.read<GoalProvider>().loadAll();
    await context.read<RecordProvider>().loadByDate(dateStr);
    await context.read<FinanceProvider>().loadAll();
    await context.read<StudyProvider>().loadAll();
    await context.read<EliteProvider>().loadAll();
    await context.read<FocusTimerProvider>().restoreSession();

    // Sync server plans in background (don't block the UI)
    final api = ApiClient();
    if (api.hasToken) {
      try {
        final resp = await api.get('/plan/date/$dateStr');
        if (resp.ok && resp.data is List && (resp.data as List).isNotEmpty) {
          final db = await DatabaseHelper().db;
          await db.delete('daily_model_plan', where: 'planDate = ?', whereArgs: [dateStr]);
          await db.delete('daily_model_plan', where: 'plan_date = ?', whereArgs: [dateStr]);
          for (final item in resp.data) {
            if (item is! Map) continue;
            final plan = DailyModelPlan.fromJson(Map<String, dynamic>.from(item));
            final data = plan.toJson();
            data['synced'] = 1;
            await db.insert('daily_model_plan', data);
          }
          // Reload to pick up server-merged plans
          if (mounted) await context.read<EliteProvider>().loadAll();
        }
      } catch (_) {}

      // Fetch server reminders (non-blocking, fallback to built-in defaults)
      try {
        final remResp = await api.get('/config/reminders');
        if (remResp.ok && remResp.data is List) {
          RemindersStore.applyServer(
            (remResp.data as List).cast<Map<String, dynamic>>(),
          );
        }
      } catch (_) {}
    }
  }

  void _checkOnboarding() {
    if (_onboardingShown) return;
    final goalProv = context.read<GoalProvider>();
    if (goalProv.goals.isNotEmpty) return;
    _onboardingShown = true;
    _showGoalOnboarding();
  }

  /// Check if morning self-check-in has been done today.
  /// If not, show the dialog first. Then generate plans if needed.
  Future<void> _checkMorningCheckIn() async {
    final elite = context.read<EliteProvider>();
    if (elite.todayCheckIn == null) {
      await _showMorningCheckIn();
    } else {
      await _generatePlansIfNeeded();
    }
  }

  Future<void> _showMorningCheckIn() async {
    double sleepHours = 7;
    int anxietyLevel = 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final protection = MorningCheckIn.computeProtection(sleepHours, anxietyLevel);
            final labels = ['', '🟢 绿级保护', '🟡 黄级保护', '🔴 红级保护'];
            final descs = [
              '',
              '状态不错，工作时段每30分钟一次冥想提醒，助你保持专注',
              '今天需要多加关照，每20分钟一次身体锚定练习，帮你回到当下',
              '高风险天，每15分钟一次物理打断——用身体动作切断焦虑循环',
            ];
            final color = _protectionColor(protection);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('晨间自检', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('花10秒评估今天的状态，帮你调整保护强度', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),

                  // ---- Sleep hours ----
                  const Text('昨晚睡了几小时？', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: sleepHours,
                          min: 3, max: 12, divisions: 18,
                          label: '${sleepHours.toStringAsFixed(1)}小时',
                          onChanged: (v) {
                            sleepHours = double.parse(v.toStringAsFixed(1));
                            setSheetState(() {});
                          },
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text('${sleepHours.toStringAsFixed(1)}h',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ---- Anxiety level ----
                  const Text('此刻焦虑程度？', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final level = i + 1;
                      const levelLabels = ['很平静', '有点烦', '较焦虑', '很焦虑', '极度焦虑'];
                      final selected = anxietyLevel == level;
                      return GestureDetector(
                        onTap: () {
                          anxietyLevel = level;
                          setSheetState(() {});
                        },
                        child: Container(
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: selected ? null : Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Text('$level', style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppTheme.textPrimary,
                              )),
                              const SizedBox(height: 2),
                              Text(levelLabels[i], style: TextStyle(
                                fontSize: 9,
                                color: selected ? Colors.white70 : AppTheme.textMuted,
                              )),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ---- Protection preview ----
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(labels[protection], style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: color,
                        )),
                        const SizedBox(height: 4),
                        Text(descs[protection],
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final today = _todayDash();
                        final checkIn = MorningCheckIn(
                          date: today,
                          sleepHours: sleepHours,
                          anxietyLevel: anxietyLevel,
                          protectionLevel: protection,
                        );
                        await context.read<EliteProvider>().saveCheckIn(checkIn);
                        if (mounted) await _generatePlansIfNeeded();
                      },
                      child: const Text('确认', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Generate today's plan if no plans exist yet for today.
  Future<void> _generatePlansIfNeeded() async {
    final dateStr = _todayDash();
    final elite = context.read<EliteProvider>();
    final todayPlans = elite.plans.where((p) => p.planDate == dateStr).toList();
    if (todayPlans.isNotEmpty) return;

    final goalProv = context.read<GoalProvider>();
    final todayTasks = goalProv.tasks
        .where((t) => t.taskDate == dateStr && t.isComplete != 1)
        .toList();
    try {
      await elite.generateTodayPlanWithAI(dateStr, todayTasks, goals: goalProv.goals);
    } catch (_) {}
  }

  Color _protectionColor(int level) {
    switch (level) {
      case 3: return const Color(0xFFF56C6C);
      case 2: return const Color(0xFFE6A23C);
      default: return const Color(0xFF67C23A);
    }
  }

  void _showGoalOnboarding() {
    final ctrl = TextEditingController();
    String? targetDate; // null = permanent
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('设定你的目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('请输入你想达成的目标，每行一个', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: '例：\n每天学习英语30分钟\n坚持跑步3公里\n阅读10本书',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Target date row
                  Row(
                    children: [
                      const Text('到期时间：', style: TextStyle(fontSize: 13)),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now().add(const Duration(days: 90)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (picked != null) {
                            targetDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            setSheetState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                targetDate == null ? '永久' : targetDate!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: targetDate == null ? AppTheme.textMuted : AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (targetDate != null) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    targetDate = null;
                                    setSheetState(() {});
                                  },
                                  child: const Icon(Icons.close, size: 14, color: AppTheme.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('跳过'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final text = ctrl.text.trim();
                            Navigator.of(ctx).pop();
                            if (text.isNotEmpty) {
                              final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
                              final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
                              final goalProv = context.read<GoalProvider>();
                              for (final line in lines) {
                                await goalProv.addGoal(Goal(
                                  title: line.trim(),
                                  goalLevel: 1,
                                  goalType: 1,
                                  status: 1,
                                  startDate: today,
                                  targetTime: targetDate,
                                  progress: 0,
                                ));
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('已保存${lines.length}个目标')),
                                );
                              }
                            }
                          },
                          child: const Text('保存'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await SyncService().syncAll();
    await _loadData();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}年${n.month}月${n.day}日';
  }

  String _todayDash() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _weekday() {
    const w = ['日', '一', '二', '三', '四', '五', '六'];
    return '星期${w[DateTime.now().weekday % 7]}';
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? '早上好' : hour < 18 ? '下午好' : '晚上好';
    final nickname = context.watch<AuthProvider>().user?.nickname ?? '自律者';

    return Scaffold(
      appBar: AppBar(title: const Text('精进')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Welcome Card ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$greet，$nickname',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${_today()} ${_weekday()}',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(height: 6),
                          Consumer<EliteProvider>(
                            builder: (_, elite, __) {
                              final level = elite.protectionLevel;
                              final label = ['', '🟢 绿级保护', '🟡 黄级保护', '🔴 红级保护'][level];
                              final color = _protectionColor(level);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.self_improvement, color: AppTheme.primary, size: 28),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ---- Mini Stats Row ----
            Row(
              children: [
                Consumer<RecordProvider>(
                  builder: (_, p, __) => _MiniStat(label: '今日记录', value: '${p.records.length}', color: const Color(0xFF409EFF)),
                ),
                const SizedBox(width: 10),
                Consumer<GoalProvider>(
                  builder: (_, p, __) => _MiniStat(
                    label: '待办事项',
                    value: '${p.tasks.where((t) => t.isComplete != 1).length}',
                    color: const Color(0xFF67C23A),
                  ),
                ),
                const SizedBox(width: 10),
                Consumer<StudyProvider>(
                  builder: (_, study, __) {
                    return Consumer<FocusTimerProvider>(
                      builder: (_, timer, __) {
                        final totalMins = study.todayMinutes + (timer.isRunning ? timer.elapsedSeconds ~/ 60 : 0);
                        return _MiniStat(label: '记录时长', value: '$totalMins分钟', color: const Color(0xFFE6A23C));
                      },
                    );
                  },
                ),
                const SizedBox(width: 10),
                Consumer<RecordProvider>(
                  builder: (_, p, __) {
                    final avg = p.records.isNotEmpty
                        ? (p.records.fold<int>(0, (s, r) => s + (r.emotionScore ?? 0)) / p.records.length).toStringAsFixed(1)
                        : '-';
                    return _MiniStat(label: '今日情绪', value: avg, color: const Color(0xFFF56C6C));
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---- Current Focus (dark gradient card) ----
            // Current-focus card scoped to _focusTick (30s) so only this
            // card rebuilds when the current time-slot changes.
            ListenableBuilder(
              listenable: _focusTick,
              builder: (_, __) => Consumer<EliteProvider>(
                builder: (ctx, elite, _) {
                  final timer = ctx.watch<FocusTimerProvider>();
                  final now = DateTime.now();
                  final dateStr =
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  final todayPlanList =
                      elite.plans.where((p) => p.planDate == dateStr).toList();
                  return _CurrentFocusCard(
                    plans: todayPlanList,
                    timer: timer,
                    onTap: (period, content, existingNote) =>
                        _showFocusSheet(context, dateStr, period, content, existingNote),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ---- 4 Quick Actions (2x2 grid) ----
            Row(
              children: [
                Expanded(child: _QuickAction('快捷记录', '记录今日行为轨迹', Icons.edit_note, AppTheme.primary, () {
                  MainShell.switchTo(context, 2);
                })),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction('今日待办', '管理待完成任务', Icons.add_task, AppTheme.success, () {
                  MainShell.switchTo(context, 1);
                })),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _QuickAction('紧急干预', '矫正拖延与逃避', Icons.psychology, AppTheme.warning, () {
                  Navigator.pushNamed(context, '/intervene');
                })),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction('正向放松', '品质生活替代无效刷屏', Icons.lightbulb_outline, AppTheme.danger, () {
                  Navigator.pushNamed(context, '/leisure');
                })),
              ],
            ),
            const SizedBox(height: 20),

            // ---- Today's Plan (from EliteProvider) ----
            const Text('今日规划', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Consumer<EliteProvider>(
              builder: (_, elite, __) {
                final now = DateTime.now();
                final dateStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                final plans = elite.plans
                    .where((p) => p.planDate == dateStr)
                    .toList();
                if (plans.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('暂无今日规划',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: elite.generating
                                  ? null
                                  : () async {
                                final goalProv = context.read<GoalProvider>();
                                final todayTasks = goalProv.tasks
                                    .where((t) => t.taskDate == dateStr && t.isComplete != 1)
                                    .toList();
                                try {
                                  await elite.generateTodayPlanWithAI(dateStr, todayTasks, goals: goalProv.goals);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('已生成${elite.plans.where((pl) => pl.planDate == dateStr).length}项今日规划'),
                                          duration: const Duration(seconds: 2)),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('生成失败: $e'), backgroundColor: AppTheme.danger),
                                    );
                                  }
                                }
                              },
                              icon: elite.generating
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('✨', style: TextStyle(fontSize: 16)),
                              label: Text(elite.generating ? '生成中...' : '生成今日计划'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final sortedPlans = List<DailyModelPlan>.from(plans)
                  ..sort((a, b) => (a.timePeriod ?? '').compareTo(b.timePeriod ?? ''));
                final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
                int? currentIndex;
                for (int i = 0; i < sortedPlans.length; i++) {
                  final parts = (sortedPlans[i].timePeriod ?? '').split('-');
                  if (parts.length != 2) continue;
                  final s = _parseMinutesStr(parts[0]);
                  final e = _parseMinutesStr(parts[1]);
                  if (s != null && e != null && nowMin >= s && nowMin < e) {
                    currentIndex = i;
                    break;
                  }
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedPlans.length,
                      onReorder: (oldIndex, newIndex) {
                        elite.reorderPlan(dateStr, oldIndex, newIndex);
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          child: child,
                        );
                      },
                      itemBuilder: (_, i) {
                        final p = sortedPlans[i];
                        final period = p.timePeriod ?? '';
                        final content = p.planContent ?? '';
                        final type = p.planType ?? 0;
                        final typeLabel = _typeLabel(type);
                        final existingNote = p.actualNote;
                        final hasNote = existingNote != null && existingNote.isNotEmpty;
                        final completed = p.isCompleted == 1;
                        final isCurrent = i == currentIndex;
                        return Container(
                          key: ValueKey('${p.planDate}_${p.timePeriod}'),
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : completed
                                      ? AppTheme.success.withValues(alpha: 0.04)
                                      : hasNote
                                          ? AppTheme.success.withValues(alpha: 0.04)
                                          : AppTheme.primary.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrent
                                  ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
                                  : (completed || hasNote)
                                      ? Border.all(color: AppTheme.success.withValues(alpha: 0.15))
                                      : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReorderableDragStartListener(
                                  index: i,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.drag_handle,
                                        size: 22, color: AppTheme.textMuted),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _showFocusSheet(
                                      context, dateStr, period, content, existingNote),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                        color: (completed || hasNote)
                                            ? AppTheme.success
                                            : AppTheme.primary,
                                        shape: BoxShape.circle),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _showTimeEditSheet(
                                      context, dateStr, period, p),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(period,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primary)),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.access_time,
                                            size: 11, color: AppTheme.primary),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showContentEditSheet(
                                        context, dateStr, period, content),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(content,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      decoration: completed ? TextDecoration.lineThrough : null,
                                                      color: completed ? AppTheme.textMuted : AppTheme.textPrimary,
                                                  )),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(Icons.edit,
                                                size: 14,
                                                color: AppTheme.textMuted),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                  color: AppTheme.success
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
                                              child: Text(typeLabel,
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme.success)),
                                            ),
                                            if (completed) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.check_circle,
                                                  size: 13,
                                                  color: AppTheme.success),
                                              const SizedBox(width: 2),
                                              const Text('已完成',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.success)),
                                            ] else if (hasNote) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.notes,
                                                  size: 13,
                                                  color: AppTheme.success),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  existingNote.length > 20
                                                      ? '${existingNote.substring(0, 20)}...'
                                                      : existingNote,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.textMuted),
                                                ),
                                              ),
                                            ] else ...[
                                              const SizedBox(width: 8),
                                              const Text('点击记录实际状况',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          AppTheme.textMuted)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showFocusSheet(
                                      context, dateStr, period, content, existingNote),
                                  child: Icon(
                                    hasNote
                                        ? Icons.edit_note
                                        : Icons.add_circle_outline,
                                    size: 18,
                                    color: hasNote
                                        ? AppTheme.success
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ---- Quick Nav Chips ----
            const Text('快捷导航', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NavChip('财务行动', Icons.attach_money, '/finance'),
                _NavChip('三赛道学习', Icons.school, '/study'),
                _NavChip('副业规划', Icons.trending_up, '/sideline'),
                _NavChip('书籍阅读', Icons.menu_book, '/reading'),
                _NavChip('精英对标', Icons.stars, '/elite'),
                _NavChip('AI复盘报告', Icons.auto_awesome, '/reports'),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showFocusSheet(BuildContext context, String date, String period,
      String content, String? existingNote) {
    final noteCtrl = TextEditingController(text: existingNote ?? '');
    final planType = _planTypeForPeriod(date, period);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return PopScope(
          // Intercept back button — auto-save any running timer before pop.
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) return;
            // Use 'context' (HomePage scope, stays mounted after sheet dismiss)
            // instead of 'ctx' (modal scope, disposed after pop).
            final timer = context.read<FocusTimerProvider>();
            if (timer.isRunning && timer.elapsedSeconds > 0) {
              final mins = await timer.stopTimer();
              if (mins > 0 && context.mounted) {
                context.read<StudyProvider>().addTodayMinutes(mins);
              }
              if (context.mounted) {
                await context.read<StudyProvider>().loadAll();
              }
              timer.notifyStop();
            }
          },
          child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            final timer = ctx.watch<FocusTimerProvider>();
            // Read completed status inside the builder so it re-evaluates on every rebuild
            final elite = ctx.read<EliteProvider>();
            DailyModelPlan? currentPlan;
            for (final p in elite.plans) {
              if (p.planDate == date && p.timePeriod == period) {
                currentPlan = p;
                break;
              }
            }
            final completed = currentPlan?.isCompleted == 1;
            final timerRunning = timer.isRunning && timer.matchesPlan(date, period);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(period,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(content,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ---- Pomodoro Timer Section ----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: timerRunning
                              ? [const Color(0xFFE67E22), const Color(0xFFD35400)]
                              : [AppTheme.primary, const Color(0xFF34495E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text('🍅 专注计时', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 8),
                          // Timer display — scoped to timer.tick so only this rebuilds each second.
                          ListenableBuilder(
                            listenable: timer.tick,
                            builder: (_, __) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timerRunning ? timer.formattedTime : timer.formattedTarget,
                                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2),
                                ),
                                if (timerRunning) ...[
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: timer.progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    timer.isCompleted
                                        ? '🎉 目标达成！'
                                        : '已用 ${timer.formattedElapsed} / 总计 ${timer.formattedTarget}',
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ], // closes if (timerRunning) spread list
                              ], // closes ListenableBuilder Column children
                            ), // closes inner Column
                          ), // closes ListenableBuilder
                          const SizedBox(height: 16),
                          if (!timerRunning) ...[
                            // Preset duration buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [5, 15, 25, 30, 45].map((m) {
                                final isActive = timer.targetSeconds == m * 60;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () {
                                      timer.setTarget(m);
                                      setSheetState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('${m}分',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                              color: isActive ? AppTheme.primary : Colors.white)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            // Study track selector (only for learning type plans)
                            if (planType == 1)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('学习赛道：', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                    ...['speech', 'ai', 'app'].map((t) {
                                      final labels = {'speech': '英语', 'ai': 'AI', 'app': '开发'};
                                      final active = timer.trackType == t;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3),
                                        child: GestureDetector(
                                          onTap: () {
                                            timer.setTrackType(t);
                                            setSheetState(() {});
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(labels[t] ?? t,
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                                    color: active ? AppTheme.primary : Colors.white)),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            // Start button
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  timer.startTimer(
                                    minutes: timer.targetSeconds ~/ 60,
                                    planDate: date,
                                    timePeriod: period,
                                    planContent: content,
                                  );
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.play_arrow, size: 20),
                                label: const Text('开始计时', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Running controls
                            if (timer.isCompleted) ...[
                              const Icon(Icons.check_circle, color: Colors.white, size: 32),
                              const SizedBox(height: 4),
                              const Text('🎉 目标达成！', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final mins = await timer.stopTimer();
                                    if (mins > 0) {
                                      context.read<StudyProvider>().addTodayMinutes(mins);
                                    }
                                    if (ctx.mounted) {
                                      await context.read<StudyProvider>().loadAll();
                                      timer.notifyStop();
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('专注 $mins 分钟已计入学习时长 ✨'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      setSheetState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.check, size: 20),
                                  label: const Text('记录并结束', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _TimerBtn(
                                    icon: timer.isPaused ? Icons.play_arrow : Icons.pause,
                                    label: timer.isPaused ? '继续' : '暂停',
                                    onTap: () {
                                      timer.isPaused ? timer.resumeTimer() : timer.pauseTimer();
                                      setSheetState(() {});
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  _TimerBtn(
                                    icon: Icons.stop,
                                    label: '结束',
                                    color: const Color(0xFFE74C3C),
                                    onTap: () async {
                                      final mins = await timer.stopTimer();
                                      if (mins > 0) {
                                        context.read<StudyProvider>().addTodayMinutes(mins);
                                      }
                                      if (ctx.mounted) {
                                        await context.read<StudyProvider>().loadAll();
                                        timer.notifyStop();
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text('专注 $mins 分钟已计入学习时长 ✨'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                        setSheetState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                              if (timer.isPaused && !timer.isCompleted)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final mins = await timer.stopTimer();
                                      if (mins > 0) {
                                        context.read<StudyProvider>().addTodayMinutes(mins);
                                      }
                                      if (ctx.mounted) {
                                        await context.read<StudyProvider>().loadAll();
                                      }
                                      timer.notifyStop();
                                      setSheetState(() {});
                                    },
                                    child: const Text('放弃计时（已累积时间仍会保存）', style: TextStyle(fontSize: 11, color: Colors.white60)),
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---- Completion Toggle ----
                    Row(
                      children: [
                        Icon(
                          completed ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 22,
                          color: completed ? AppTheme.success : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('标记为已完成',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        Switch(
                          value: completed,
                          activeTrackColor: AppTheme.success,
                          onChanged: (v) async {
                            final newVal = v ? 1 : 0;
                            await context.read<EliteProvider>().updatePlanCompletion(date, period, newVal);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ---- Actual Note Section ----
                    const Text('实际状况记录',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('记录这个时段实际发生了什么',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      autofocus: false,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '例：做到了，感觉状态不错 / 只做了一半，被xx打断了 / 完全没做，因为在刷手机...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          await context.read<EliteProvider>().updatePlanNote(date, period, noteCtrl.text.trim());
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('保存记录'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
        ); // PopScope
      },
    );
  }

  int _planTypeForPeriod(String date, String period) {
    final elite = context.read<EliteProvider>();
    for (final p in elite.plans) {
      if (p.planDate == date && p.timePeriod == period) {
        return p.planType ?? 0;
      }
    }
    return 0;
  }

  /// Edit dialog for modifying plan content text with preset icons.
  void _showContentEditSheet(BuildContext context, String date, String period,
      String currentContent) {
    final ctrl = TextEditingController(text: currentContent);
    const presets = [
      '📚 学习', '💻 开发', '🏃 运动', '🧘 冥想',
      '💰 财务', '✍️ 写作', '🎯 目标', '🍱 休息',
      '📖 阅读', '🎵 音乐', '🌿 放松', '📊 规划',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(period,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      ),
                      const SizedBox(width: 8),
                      const Text('编辑计划内容', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Preset icon chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presets.map((p) {
                      final emoji = p.substring(0, 2);
                      final label = p.substring(3);
                      return GestureDetector(
                        onTap: () {
                          String text = ctrl.text;
                          // Remove existing emoji prefix if any
                          for (final e in ['📚', '💻', '🏃', '🧘', '💰', '✍️', '🎯', '🍱', '📖', '🎵', '🌿', '📊']) {
                            if (text.startsWith(e)) {
                              text = text.substring(e.length).trimLeft();
                              break;
                            }
                          }
                          ctrl.text = '$emoji $text'.trimLeft();
                          setSheetState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text('$emoji $label', style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '输入计划内容...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newContent = ctrl.text.trim();
                        if (newContent.isNotEmpty && newContent != currentContent) {
                          await context.read<EliteProvider>().updatePlanContent(date, period, newContent);
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: const Text('保存内容'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Edit dialog for adjusting plan time period.
  void _showTimeEditSheet(BuildContext context, String date, String period,
      DailyModelPlan plan) {
    final parts = period.split('-');
    String startStr = parts.isNotEmpty ? parts[0] : '09:00';
    String endStr = parts.length > 1 ? parts[1] : '10:00';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('调整时间段', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('当前内容：${plan.planContent ?? ""}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: '开始时间',
                          initial: startStr,
                          onChanged: (v) {
                            startStr = v;
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('—', style: TextStyle(fontSize: 20, color: AppTheme.textMuted)),
                      ),
                      Expanded(
                        child: _TimeField(
                          label: '结束时间',
                          initial: endStr,
                          onChanged: (v) {
                            endStr = v;
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  // Quick presets
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _presetChip('30分钟', () {
                        final end = _addMinutes(startStr, 30);
                        endStr = end;
                        setSheetState(() {});
                      }),
                      _presetChip('1小时', () {
                        final end = _addMinutes(startStr, 60);
                        endStr = end;
                        setSheetState(() {});
                      }),
                      _presetChip('提前30分', () {
                        final newStart = _addMinutes(startStr, -30);
                        final newEnd = _addMinutes(endStr, -30);
                        startStr = newStart;
                        endStr = newEnd;
                        setSheetState(() {});
                      }),
                      _presetChip('推迟30分', () {
                        final newStart = _addMinutes(startStr, 30);
                        final newEnd = _addMinutes(endStr, 30);
                        startStr = newStart;
                        endStr = newEnd;
                        setSheetState(() {});
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newPeriod = '$startStr-$endStr';
                        if (newPeriod != period) {
                          await context.read<EliteProvider>().updatePlanTime(date, period, newPeriod);
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Text('保存时间段 — $startStr-$endStr'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final total = h * 60 + m + minutes;
    final newH = ((total % 1440) + 1440) % 1440 ~/ 60;
    final newM = ((total % 1440) + 1440) % 1440 % 60;
    return '${newH.toString().padLeft(2, '0')}:${newM.toString().padLeft(2, '0')}';
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
      ),
    );
  }

  String _typeLabel(int t) {
    const m = {1: '学习', 2: '副业', 3: '阅读', 4: '休闲', 5: '心理', 0: '综合'};
    return m[t] ?? '综合';
  }
}

// ---- Mini Stat Card ----
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

typedef _RecordCallback = void Function(String period, String content, String? existingNote);

// ---- Current Focus Card (dark gradient) ----
class _CurrentFocusCard extends StatelessWidget {
  final List<dynamic> plans;
  final FocusTimerProvider timer;
  final _RecordCallback? onTap;
  const _CurrentFocusCard({required this.plans, required this.timer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;

    // Find plan whose time period contains the current time
    dynamic currentPlan;
    for (final p in plans) {
      final period = p.timePeriod as String?;
      if (period == null) continue;
      final parts = period.split('-');
      if (parts.length != 2) continue;
      final start = _parseMinutes(parts[0]);
      final end = _parseMinutes(parts[1]);
      if (start == null || end == null) continue;
      if (currentMin >= start && currentMin < end) {
        currentPlan = p;
        break;
      }
    }

    final content = currentPlan?.planContent ?? '暂无计划安排，去「精英对标」生成今日规划';
    final periodLabel = currentPlan?.timePeriod ?? '';
    final typeLabel = currentPlan != null ? _planTypeLabel(currentPlan.planType) : '';
    final existingNote = currentPlan?.actualNote as String?;
    final hasNote = existingNote != null && existingNote.isNotEmpty;

    // Check if timer is running for this period
    final timerRunning = currentPlan != null &&
        timer.matchesPlan(
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          currentPlan.timePeriod as String,
        );

    return GestureDetector(
      onTap: currentPlan != null && onTap != null
          ? () => onTap!(currentPlan.timePeriod as String,
              currentPlan.planContent as String, existingNote)
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: timerRunning
                ? [const Color(0xFFE67E22), const Color(0xFFD35400)]
                : [AppTheme.primary, const Color(0xFF34495E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: timerRunning ? 12 : 10,
              height: timerRunning ? 12 : 10,
              decoration: BoxDecoration(
                color: timerRunning
                    ? Colors.white
                    : (currentPlan != null ? AppTheme.success : AppTheme.warning),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: timerRunning
                          ? Colors.white.withValues(alpha: 0.6)
                          : (currentPlan != null ? AppTheme.success : AppTheme.warning)
                              .withValues(alpha: 0.5),
                      blurRadius: timerRunning ? 12 : 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timerRunning ? '🍅 专注中 — $periodLabel' :
                        (currentPlan != null ? '当前时段 $periodLabel' : '当前时段'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  if (timerRunning)
                    // Scoped to timer.tick — only timer display rebuilds, not the entire card.
                    ListenableBuilder(
                      listenable: timer.tick,
                      builder: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('剩余 ${timer.formattedTime}',
                              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 2)),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: timer.progress,
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('已用${timer.formattedElapsed} / 总计${timer.formattedTarget}  $content',
                              style: const TextStyle(fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    )
                  else
                    Text(content,
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                  if (!timerRunning && hasNote) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.notes, size: 12, color: Colors.white60),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            existingNote.length > 30 ? '${existingNote.substring(0, 30)}...' : existingNote,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timerRunning)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('计时中',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else if (currentPlan != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(typeLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                if (currentPlan != null && onTap != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: Icon(
                      timerRunning ? Icons.timer : (hasNote ? Icons.edit_note : Icons.add_circle_outline),
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  int? _parseMinutes(String hhmm) {
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _planTypeLabel(int? t) {
    const m = {1: '学习', 2: '副业', 3: '阅读', 4: '休闲', 5: '心理', 0: '综合'};
    return m[t] ?? '综合';
  }
}

// ---- Quick Action Card ----
class _QuickAction extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.title, this.desc, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ---- Timer Control Button ----
class _TimerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TimerBtn({required this.icon, required this.label, this.color = Colors.white, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---- Nav Chip ----
class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  const _NavChip(this.label, this.icon, this.route);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}

// ---- Time Field Helper ----
class _TimeField extends StatefulWidget {
  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  const _TimeField({required this.label, required this.initial, required this.onChanged});

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late String _hour;
  late String _minute;

  @override
  void initState() {
    super.initState();
    final parts = widget.initial.split(':');
    _hour = parts.isNotEmpty ? parts[0] : '09';
    _minute = parts.length > 1 ? parts[1] : '00';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Row(
          children: [
            _digitField(_hour, (v) {
              _hour = v;
              _notify();
            }),
            const Text(':', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            _digitField(_minute, (v) {
              _minute = v;
              _notify();
            }),
          ],
        ),
      ],
    );
  }

  Widget _digitField(String value, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 52,
      height: 44,
      child: TextField(
        controller: TextEditingController(text: value),
        keyboardType: TextInputType.number,
        maxLength: 2,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        onChanged: (v) {
          final num = int.tryParse(v);
          if (num != null && num >= 0 && num <= 59 && v.length <= 2) {
            onChanged(v.padLeft(2, '0'));
          }
        },
      ),
    );
  }

  void _notify() {
    widget.onChanged('$_hour:$_minute');
  }
}

