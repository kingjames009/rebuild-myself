import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/holiday_config.dart';
import '../../models/daily_check.dart';
import '../../models/time_block.dart';
import '../../models/custom_priority.dart';
import '../../providers/elite_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/aspiration_provider.dart';

class ElitePage extends StatefulWidget {
  const ElitePage({super.key});
  @override
  State<ElitePage> createState() => _ElitePageState();
}

class _ElitePageState extends State<ElitePage> {
  int _habitCategory = 1;
  final _deviationCtrl = TextEditingController();
  final _escapeReasonCtrl = TextEditingController();
  double _progressScore = 5;
  DateTime _selectedDate = DateTime.now();

  // Work schedule editing
  String _workStart = '09:00';
  String _workEnd = '18:00';
  String _lunchStart = '12:00';
  String _lunchEnd = '13:00';
  String _studyStart = '08:00';
  String _studyEnd = '22:00';
  bool _workScheduleLoaded = false;

  // Custom priority
  final _customCtrl = TextEditingController();
  String _customSegment = '下班后';

  int _essentialTab = 0; // 0=all, 1-5 categories

  // Collapsible sections
  bool _showCustomPriority = false;
  bool _showAdvancedBlocks = false;
  bool _showEssentials = false;

  static const _categoryLabels = ['晨间', '日间', '下班后', '睡前'];
  static const _planTypeLabels = {
    1: '学习', 2: '副业', 3: '阅读', 4: '休闲', 5: '心理', 0: '未分类'
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EliteProvider>().loadAll();
      context.read<GoalProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _deviationCtrl.dispose();
    _escapeReasonCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  String get _dateStr {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _prevDate() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  }

  void _nextDate() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  void _syncWorkScheduleFromProvider(EliteProvider p) {
    if (!_workScheduleLoaded) {
      final ws = p.workSchedule;
      _workStart = ws.workStart;
      _workEnd = ws.workEnd;
      _lunchStart = ws.lunchStart;
      _lunchEnd = ws.lunchEnd;
      _studyStart = ws.studyStart;
      _studyEnd = ws.studyEnd;
      _workScheduleLoaded = true;
    }
  }

  Future<void> _saveWorkSchedule() async {
    final isWorkday = HolidayConfig.isWorkday(DateTime.now());
    final ws = WorkSchedule(
      workStart: _workStart,
      workEnd: _workEnd,
      lunchStart: _lunchStart,
      lunchEnd: _lunchEnd,
      studyStart: _studyStart,
      studyEnd: _studyEnd,
    );
    await context.read<EliteProvider>().saveWorkSchedule(ws);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isWorkday ? '工作时间已保存' : '学习时间已保存'),
            duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _generatePlan() async {
    final p = context.read<EliteProvider>();
    final today = _today();
    final goalProv = context.read<GoalProvider>();
    final todayTasks = goalProv.tasks
        .where((t) => t.taskDate == today && t.isComplete != 1)
        .toList();
    try {
      await p.saveWorkSchedule(WorkSchedule(
        workStart: _workStart,
        workEnd: _workEnd,
        lunchStart: _lunchStart,
        lunchEnd: _lunchEnd,
        studyStart: _studyStart,
        studyEnd: _studyEnd,
      ));
      await p.generateTodayPlanWithAI(today, todayTasks, goals: goalProv.goals);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('已生成全天计划（${p.plans.where((pl) => pl.planDate == today).length}项）'),
              duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _submitCheck() {
    if (_deviationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写偏差内容')),
      );
      return;
    }
    context.read<EliteProvider>().addCheck(DailyCompareCheck(
          planDate: _dateStr,
          deviationContent: _deviationCtrl.text,
          escapeReason: _escapeReasonCtrl.text,
          progressScore: _progressScore.round(),
        ));
    _deviationCtrl.clear();
    _escapeReasonCtrl.clear();
    setState(() => _progressScore = 5);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('自检提交成功')),
    );
  }

  Future<void> _addCustomItem() async {
    if (_customCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事项内容')),
      );
      return;
    }
    await context
        .read<EliteProvider>()
        .addCustomItem(_customCtrl.text.trim(), _customSegment);
    _customCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('优先事项已添加'), duration: Duration(seconds: 1)),
      );
    }
  }

  String _typeLabel(int? t) => _planTypeLabels[t] ?? '综合';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('精英对标')),
      body: Consumer<EliteProvider>(
        builder: (_, p, __) {
          _syncWorkScheduleFromProvider(p);

          final todayPlans =
              p.plans.where((plan) => plan.planDate == _dateStr).toList();
          final catHabits =
              p.habits.where((h) => h.habitCategory == _habitCategory).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<GoalProvider>().loadAll();
              await p.loadAll();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _prevDate,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('<',
                            style: TextStyle(
                                fontSize: 22,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w300)),
                      ),
                    ),
                    Text(_dateStr,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    GestureDetector(
                      onTap: _nextDate,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('>',
                            style: TextStyle(
                                fontSize: 22,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w300)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Section 1: Today's Model Plan
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📋 今日模范计划',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        if (todayPlans.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                                child: Text(
                                    '暂无计划，先设置工作时间再生成\n覆盖上班前、上班时、午休、下班后全天时段',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppTheme.textMuted))),
                          )
                        else
                          ...todayPlans.map((plan) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(plan.timePeriod ?? '',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFE8F8F5),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(
                                              _typeLabel(plan.planType),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.success)),
                                        ),
                                        const SizedBox(width: 4),
                                        ...List.generate(
                                            plan.difficulty ?? 1,
                                            (_) => const Text('★',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.warning))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(plan.planContent ?? '',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: AppTheme.textPrimary)),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Section 2: Generate + Clear
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: p.generating ? null : _generatePlan,
                    icon: p.generating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('✨', style: TextStyle(fontSize: 16)),
                    label: Text(p.generating ? '生成中...' : '生成今日计划'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () async {
                      await context
                          .read<EliteProvider>()
                          .clearPlansForDate(_dateStr);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('已清空今日计划'),
                              duration: Duration(seconds: 1)),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary),
                    child: const Text('清空今日计划',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 10),

                // Section 4: Life Essentials (生活必备项)
                _buildEssentialsCard(),
                const SizedBox(height: 10),

                // Section 5: Work Schedule Settings
                _buildWorkScheduleCard(),
                const SizedBox(height: 10),

                // Section 4: Custom Priority Items
                _buildCustomPriorityCard(p),
                const SizedBox(height: 10),

                // Section 5: Advanced Time Blocks
                _buildAdvancedBlocksCard(p),
                const SizedBox(height: 16),

                // Section 6: Daily Self-Check
                _buildSelfCheckCard(),
                const SizedBox(height: 16),

                // Section 7: Elite Habit Library
                _buildHabitLibraryCard(catHabits, p),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Essentials Card (生活必备项) ----
  Widget _buildEssentialsCard() {
    return Consumer<AspirationProvider>(
      builder: (_, ap, __) => GestureDetector(
        onTap: () => setState(() => _showEssentials = !_showEssentials),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💪 生活必备项',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text('${ap.essentials.where((e) => e.enabled == 1).length}/${ap.essentials.length}项启用',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Icon(
                        _showEssentials ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.textSecondary),
                  ],
                ),
                if (_showEssentials) ...[
                  const SizedBox(height: 12),
                  if (ap.essentials.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                          child: Text('暂无必备项配置',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted))),
                    )
                  else
                    ...ap.essentials.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(e.categoryLabel,
                                    style: const TextStyle(fontSize: 10, color: AppTheme.primary)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text('${e.defaultDuration}分钟 · ${e.periodLabel}',
                                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: e.enabled == 1,
                                onChanged: (v) => ap.toggleEssential(e.id!, v ? 1 : 0),
                                activeColor: AppTheme.primary,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok = await ap.resetEssentials();
                        if (ok && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已重置为默认必备项'), duration: Duration(seconds: 1)),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10)),
                      child: const Text('重置为默认', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Work Schedule Card ----
  Widget _buildWorkScheduleCard() {
    final now = DateTime.now();
    final isWorkday = HolidayConfig.isWorkday(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(isWorkday ? '⏰ 工作时间设置' : '⏰ 时间设置',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(isWorkday ? '工作日' : '休息日',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                isWorkday
                    ? '设定上下班时间，系统将据此划分全天5个时段'
                    : '设定学习起止时间，系统据此安排今日学习计划',
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 14),
            if (isWorkday) ...[
              Row(
                children: [
                  Expanded(
                      child: _TimePickerCell('上班', _workStart,
                          (v) => setState(() => _workStart = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _TimePickerCell('下班', _workEnd,
                          (v) => setState(() => _workEnd = v))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _TimePickerCell('午休开始', _lunchStart,
                          (v) => setState(() => _lunchStart = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _TimePickerCell('午休结束', _lunchEnd,
                          (v) => setState(() => _lunchEnd = v))),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                      child: _TimePickerCell('开始学习', _studyStart,
                          (v) => setState(() => _studyStart = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _TimePickerCell('结束学习', _studyEnd,
                          (v) => setState(() => _studyEnd = v))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _TimePickerCell('午休开始', _lunchStart,
                          (v) => setState(() => _lunchStart = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _TimePickerCell('午休结束', _lunchEnd,
                          (v) => setState(() => _lunchEnd = v))),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _saveWorkSchedule,
                child: Text(isWorkday ? '保存工作时间' : '保存学习时间',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
            if (!isWorkday) ...[
              const SizedBox(height: 8),
              const Text('提示：工作日将自动切换为上下班时间设置',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  // ---- Custom Priority Card ----
  Widget _buildCustomPriorityCard(EliteProvider p) {
    return GestureDetector(
      onTap: () =>
          setState(() => _showCustomPriority = !_showCustomPriority),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('⭐ 自定义优先事项',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  const Text('最高优先级',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.warning)),
                  const Spacer(),
                  Icon(
                      _showCustomPriority
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppTheme.textSecondary),
                ],
              ),
              if (!_showCustomPriority &&
                  p.customItems.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('${p.customItems.length}项',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
              ],
              if (_showCustomPriority) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _customCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: '输入事项，如「30分钟英语口语」',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: _SegmentDropdown(_customSegment,
                          (v) => setState(() => _customSegment = v)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _addCustomItem,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(44, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('添加',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                if (p.customItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...p.customItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(item.preferredSegment,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primary)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(item.content,
                                    style: const TextStyle(fontSize: 13))),
                            GestureDetector(
                              onTap: () => p.deleteCustomItem(item.id!),
                              child: const Icon(Icons.close,
                                  size: 16, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 4),
                const Text('自定义事项将优先于习惯库排入计划',
                    style:
                        TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---- Advanced Time Blocks Card ----
  Widget _buildAdvancedBlocksCard(EliteProvider p) {
    return GestureDetector(
      onTap: () =>
          setState(() => _showAdvancedBlocks = !_showAdvancedBlocks),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔧 高级：自定义时段分配',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(
                      _showAdvancedBlocks
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppTheme.textSecondary),
                ],
              ),
              if (_showAdvancedBlocks) ...[
                const SizedBox(height: 6),
                const Text('手动编辑周末/工作日的时间块（工作日全天生成为空，由工作时间驱动）',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                // Day type selector
                Row(
                  children: [
                    const Text('日类型：',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    _ChipToggle('工作日', _configDayType == 'workday',
                        () => setState(() => _configDayType = 'workday')),
                    const SizedBox(width: 6),
                    _ChipToggle('周末', _configDayType == 'weekend',
                        () => setState(() => _configDayType = 'weekend')),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _resetBlocks,
                      icon: const Icon(Icons.restore, size: 14),
                      label: const Text('默认',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_currentBlocks(p).length, (i) {
                  final b = _currentBlocks(p)[i];
                  return _buildBlockRow(b, i, p);
                }),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: _addBlock,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('添加时间块',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _saveBlocks,
                    child: const Text('保存时间设置',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockRow(TimeBlockConfig b, int i, EliteProvider p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: _TimeField(
                b.start, (v) => setState(() => b.start = v)),
          ),
          const Text(' - ',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          SizedBox(
            width: 52,
            child: _TimeField(
                b.end, (v) => setState(() => b.end = v)),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 56,
            child: _TypeDropdown(
                b.type, (v) => setState(() => b.type = v)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                controller:
                    TextEditingController(text: b.label),
                onChanged: (v) => b.label = v,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '标签',
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 6, vertical: 8),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeBlock(i),
            child: const Icon(Icons.close,
                size: 16, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // ---- Self Check Card ----
  Widget _buildSelfCheckCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✅ 每日自检',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('偏差内容',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _deviationCtrl,
              decoration: const InputDecoration(
                  hintText: '与计划偏差了什么'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const Text('逃避原因',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _escapeReasonCtrl,
              decoration: const InputDecoration(hintText: '为什么逃避'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('进度评分',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _progressScore,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: AppTheme.primary,
                    onChanged: (v) =>
                        setState(() => _progressScore = v),
                  ),
                ),
                Text('${_progressScore.round()}/10',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _submitCheck,
              child: const Text('提交自检'),
            ),
          ],
        ),
      ),
    );
  }

  bool _generatingHabits = false;

  // ---- Habit Library Card ----
  Widget _buildHabitLibraryCard(List catHabits, EliteProvider p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('精英习惯库',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(
                  height: 32,
                  child: TextButton.icon(
                    onPressed: _generatingHabits
                        ? null
                        : () async {
                            setState(() => _generatingHabits = true);
                            try {
                              final ok = await p.generateAiHabits();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'AI已生成精英习惯，基于全球顶尖人物真实日常' : '生成失败，请检查网络和AI服务'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _generatingHabits = false);
                            }
                          },
                    icon: _generatingHabits
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('✨', style: TextStyle(fontSize: 14)),
                    label: Text(_generatingHabits ? '生成中...' : 'AI 生成',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: List.generate(4, (i) {
                  final active = _habitCategory == i + 1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _habitCategory = i + 1),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _categoryLabels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: active
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            if (catHabits.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('暂无习惯',
                        style:
                            TextStyle(color: AppTheme.textMuted))),
              )
            else
              ...catHabits.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(h.habitContent ?? '',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius:
                                  BorderRadius.circular(6)),
                          child: Text(
                              '强度 ${h.intensityLevel ?? 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  // ---- Advanced time block helpers ----

  String _configDayType = 'workday';

  List<TimeBlockConfig> _currentBlocks(EliteProvider p) =>
      _configDayType == 'workday' ? p.workdayBlocks : p.weekendBlocks;

  void _addBlock() {
    final p = context.read<EliteProvider>();
    final blocks = _currentBlocks(p);
    final last = blocks.isNotEmpty ? blocks.last.end : '06:00';
    final newBlock = TimeBlockConfig(
        start: last, end: _addMinutes(last, 30), type: 1);
    blocks.add(newBlock);
    setState(() {});
  }

  void _removeBlock(int i) {
    final p = context.read<EliteProvider>();
    final blocks = _currentBlocks(p);
    if (blocks.length <= 1) return;
    blocks.removeAt(i);
    setState(() {});
  }

  String _addMinutes(String time, int mins) {
    final parts = time.split(':');
    int h = int.tryParse(parts[0]) ?? 0;
    int m = int.tryParse(parts[1]) ?? 0;
    m += mins;
    while (m >= 60) {
      h++;
      m -= 60;
    }
    if (h >= 24) h -= 24;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _saveBlocks() async {
    final p = context.read<EliteProvider>();
    final blocks = _currentBlocks(p).map((b) => b.copy()).toList();
    await p.saveTimeBlocks(_configDayType, blocks);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('时间设置已保存'),
            duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _resetBlocks() async {
    await context
        .read<EliteProvider>()
        .resetTimeBlocks(_configDayType);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('已恢复默认设置'),
            duration: Duration(seconds: 1)),
      );
    }
  }
}

// ---- Time Picker Cell ----
class _TimePickerCell extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _TimePickerCell(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          ),
        );
        if (t != null) {
          onChanged(
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label  ',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.access_time,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ---- Chip Toggle ----
class _ChipToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChipToggle(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : AppTheme.textSecondary,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

// ---- Segment Dropdown ----
class _SegmentDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SegmentDropdown(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(
              fontSize: 11, color: AppTheme.textPrimary),
          items: CustomPriorityItem.segments
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      style: const TextStyle(fontSize: 11))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ---- Time Field (HH:MM) ----
class _TimeField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TimeField(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: TextEditingController(text: value),
        onChanged: (v) {
          if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(v)) onChanged(v);
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

// ---- Type Dropdown ----
class _TypeDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TypeDropdown(this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          style: const TextStyle(
              fontSize: 11, color: AppTheme.textPrimary),
          items: TimeBlockConfig.typeLabels.entries
              .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 11))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

