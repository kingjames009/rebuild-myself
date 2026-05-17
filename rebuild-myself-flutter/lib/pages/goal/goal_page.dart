import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/goal.dart';
import '../../models/task.dart';
import '../../providers/goal_provider.dart';
import '../../utils/dialogs.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});
  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  int _tab = 0;
  static const _tabs = ['长期', '年度', '月度', '每日', '四象限'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalProvider>().loadAll();
    });
  }

  void _showAddSheet() {
    if (_tab == 4) {
      _showTaskSheet();
      return;
    }
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final level = _tab + 1;
    int goalType = 1;
    DateTime? startDate;
    DateTime? targetDate;

    String fmt(DateTime? d) =>
        d == null ? '点击选择' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('新建${_levelLabel(level)}目标', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                // Type selector
                Row(
                  children: ['学习', '财务', '健康', '习惯'].asMap().entries.map((e) {
                    final active = goalType == e.key + 1;
                    return GestureDetector(
                      onTap: () => setSt(() => goalType = e.key + 1),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primary : AppTheme.bg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(e.value,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: active ? Colors.white : AppTheme.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: '目标标题')),
                const SizedBox(height: 12),
                TextField(controller: contentCtrl, decoration: const InputDecoration(hintText: '目标描述'), maxLines: 3),
                const SizedBox(height: 16),
                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setSt(() => startDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('开始: ${fmt(startDate)}',
                                  style: TextStyle(fontSize: 12, color: startDate == null ? AppTheme.textMuted : AppTheme.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setSt(() => targetDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag_outlined, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('截止: ${fmt(targetDate)}',
                                  style: TextStyle(fontSize: 12, color: targetDate == null ? AppTheme.textMuted : AppTheme.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      context.read<GoalProvider>().addGoal(Goal(
                        goalLevel: level, goalType: goalType, title: titleCtrl.text,
                        content: contentCtrl.text, status: 1, progress: 0,
                        startDate: startDate != null ? fmt(startDate) : null,
                        targetTime: targetDate != null ? fmt(targetDate) : null,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTaskSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('新建待办', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, decoration: const InputDecoration(hintText: '待办内容')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  context.read<GoalProvider>().addTask(TaskTodo(
                    taskTitle: ctrl.text, taskLevel: 1, isComplete: 0, taskDate: _today(),
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  String _levelLabel(int l) {
    const m = {1: '长期', 2: '年度', 3: '月度', 4: '每日'};
    return m[l] ?? '';
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目标管理')),
      body: Column(
        children: [
          // Segmented pill tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = _tab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary : AppTheme.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _tab == 4 ? const _TaskList() : _GoalList(level: _tab + 1),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---- Goal List ----
class _GoalList extends StatelessWidget {
  final int level;
  const _GoalList({required this.level});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (_, p, __) {
        final goals = p.goalsByLevel(level);
        if (goals.isEmpty) {
          return const Center(
            child: Text('暂无目标\n点击下方 + 按钮添加', textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          );
        }
        return RefreshIndicator(
          onRefresh: () => p.loadAll(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: goals.length,
            itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
          ),
        );
      },
    );
  }
}

// ---- Goal Card ----
class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showProgressSheet(context, goal),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Badge(goal.typeLabel, AppTheme.primary),
                  const SizedBox(width: 6),
                  _Badge(goal.statusLabel,
                      goal.status == 1 ? AppTheme.success : AppTheme.textMuted),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      if (await showDeleteConfirm(context, item: '该目标')) {
                        context.read<GoalProvider>().deleteGoal(goal.goalId!);
                      }
                    },
                    child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(goal.title ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (goal.content != null && goal.content!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(goal.content!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (goal.progress ?? 0) / 100, minHeight: 8,
                  backgroundColor: AppTheme.border,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('${goal.progressPercent}%',
                      style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (goal.startDate != null && goal.startDate!.isNotEmpty)
                    Text('${goal.startDate}' + (goal.targetTime != null && goal.targetTime!.isNotEmpty ? ' ~ ${goal.targetTime}' : ''),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))
                  else if (goal.targetTime != null && goal.targetTime!.isNotEmpty)
                    Text(goal.targetTime ?? '',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgressSheet(BuildContext context, Goal goal) {
    double val = (goal.progress ?? 0).toDouble();
    DateTime? startDate = goal.startDate != null && goal.startDate!.isNotEmpty
        ? DateTime.tryParse(goal.startDate!)
        : null;
    DateTime? targetDate = goal.targetTime != null && goal.targetTime!.isNotEmpty
        ? DateTime.tryParse(goal.targetTime!)
        : null;

    String fmt(DateTime? d) =>
        d == null ? '点击选择' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(goal.title ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) setSt(() => startDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('开始: ${fmt(startDate)}',
                                  style: TextStyle(fontSize: 11, color: startDate == null ? AppTheme.textMuted : AppTheme.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: targetDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) setSt(() => targetDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('截止: ${fmt(targetDate)}',
                                  style: TextStyle(fontSize: 11, color: targetDate == null ? AppTheme.textMuted : AppTheme.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('${val.round()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              const SizedBox(height: 12),
              Slider(
                value: val, min: 0, max: 100,
                activeColor: AppTheme.primary,
                onChanged: (v) => setSt(() => val = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<GoalProvider>().updateGoal(Goal(
                    goalId: goal.goalId, title: goal.title, content: goal.content,
                    goalLevel: goal.goalLevel, goalType: goal.goalType,
                    status: val >= 100 ? 2 : 1, progress: val.round(),
                    startDate: startDate != null ? fmt(startDate) : null,
                    targetTime: targetDate != null ? fmt(targetDate) : null,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Badge ----
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ---- Task List (四象限) ----
class _TaskList extends StatelessWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalProvider>(
      builder: (_, p, __) {
        if (p.tasks.isEmpty) {
          return const Center(
            child: Text('暂无待办\n点击下方 + 按钮添加', textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          );
        }
        return RefreshIndicator(
          onRefresh: () => p.loadAll(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            children: [1, 2, 3, 4].map((q) {
              final tasks = p.tasksByQuadrant(q);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuadrantHeader(q),
                  if (tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 12),
                      child: Text('暂无', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    )
                  else
                    ...tasks.map((t) => _TaskItem(task: t)),
                  const SizedBox(height: 4),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _QuadrantHeader extends StatelessWidget {
  final int q;
  const _QuadrantHeader(this.q);

  static const _labels = {1: '重要紧急', 2: '重要不紧急', 3: '紧急不重要', 4: '不重要不紧急'};
  static const _colors = {1: AppTheme.danger, 2: AppTheme.warning, 3: Colors.blue, 4: AppTheme.textMuted};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: _colors[q], shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(_labels[q]!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _colors[q])),
      ]),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final TaskTodo task;
  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.read<GoalProvider>().toggleTask(task.taskId!, !task.completed),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Icon(task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18, color: task.completed ? AppTheme.success : AppTheme.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(task.taskTitle ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                    color: task.completed ? AppTheme.textMuted : AppTheme.textPrimary,
                  )),
            ),
            GestureDetector(
              onTap: () async {
                if (await showDeleteConfirm(context, item: '该任务')) {
                  context.read<GoalProvider>().deleteTask(task.taskId!);
                }
              },
              child: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
            ),
          ]),
        ),
      ),
    );
  }
}
