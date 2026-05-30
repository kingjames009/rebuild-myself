import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/daily_check.dart';
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

  // Collapsible sections
  bool _showEssentials = false;

  static const _categoryLabels = ['晨间', '日间', '下班后', '睡前'];
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
    super.dispose();
  }

  String get _dateStr {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _prevDate() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  }

  void _nextDate() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('精英对标')),
      body: Consumer<EliteProvider>(
        builder: (_, p, __) {
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

                // Section: Life Essentials (生活必备项)
                _buildEssentialsCard(),
                const SizedBox(height: 10),

                // Section: Daily Self-Check
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

}

