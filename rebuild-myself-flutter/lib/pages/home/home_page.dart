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
import '../../services/sync_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SyncService().syncAll();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await context.read<GoalProvider>().loadAll();
    await context.read<RecordProvider>().loadByDate(dateStr);
    await context.read<FinanceProvider>().loadAll();
    final elite = context.read<EliteProvider>();
    await elite.loadAll();

    // Auto-generate today's plan if none exists
    final todayPlans = elite.plans.where((p) => p.planDate == dateStr).toList();
    if (todayPlans.isEmpty) {
      final goalProv = context.read<GoalProvider>();
      final todayTasks = goalProv.tasks
          .where((t) => t.taskDate == dateStr && t.isComplete != 1)
          .toList();
      await elite.generateTodayPlanWithAI(dateStr, todayTasks, goals: goalProv.goals);
    }
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
                        final today = _todayDash();
                        final studyMins = study.records.where((r) => r.recordDate == today).fold<int>(0, (s, r) => s + (r.studyMinutes ?? 0));
                        final timerMins = timer.isRunning ? timer.elapsedSeconds ~/ 60 : 0;
                        final totalMins = studyMins + timerMins;
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
            Consumer<EliteProvider>(
              builder: (ctx, elite, __) {
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
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (_, child) => Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(8),
                            child: child,
                          ),
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
                        return Container(
                          key: ValueKey(p.planId),
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onTap: () => _showFocusSheet(
                                context, dateStr, period, content, existingNote),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: hasNote
                                    ? AppTheme.success.withValues(alpha: 0.04)
                                    : AppTheme.primary.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(8),
                                border: hasNote
                                    ? Border.all(
                                        color:
                                            AppTheme.success.withValues(alpha: 0.15))
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: const Icon(Icons.drag_handle,
                                        size: 18, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                        color: hasNote
                                            ? AppTheme.success
                                            : AppTheme.primary,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(period,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(content,
                                            style: const TextStyle(fontSize: 14)),
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
                                            if (hasNote) ...[
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
                                  const SizedBox(width: 4),
                                  Icon(
                                    hasNote
                                        ? Icons.edit_note
                                        : Icons.add_circle_outline,
                                    size: 18,
                                    color: hasNote
                                        ? AppTheme.success
                                        : AppTheme.textMuted,
                                  ),
                                ],
                              ),
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
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final timer = ctx.watch<FocusTimerProvider>();
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
                          // Timer display
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
                          ],
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
                                    if (ctx.mounted) {
                                      context.read<StudyProvider>().loadAll();
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
                                      if (ctx.mounted) {
                                        context.read<StudyProvider>().loadAll();
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
                              if (timer.isPaused)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      timer.cancelTimer();
                                      setSheetState(() {});
                                    },
                                    child: const Text('放弃计时', style: TextStyle(fontSize: 11, color: Colors.white60)),
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---- Actual Note Section ----
                    const Text('实际状况记录',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('不是勾选完成，是记录这个时段实际发生了什么',
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
        );
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
                  if (timerRunning) ...[
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
                  ] else
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
