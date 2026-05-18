import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/ai_report.dart';
import '../../providers/report_provider.dart';
import '../../providers/record_provider.dart';
import '../../providers/intervene_provider.dart';
import '../../utils/dialogs.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _cycle = 1;

  static const _cycleLabels = {1: '日复盘', 2: '周复盘', 3: '月复盘', 4: '年复盘'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAll();
      context.read<RecordProvider>().loadByDate(_today());
      context.read<InterveneProvider>().loadAll();
    });
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _weekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${_fmt(start)} ~ ${_fmt(end)}';
  }

  String _monthRange() => '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  String _yearRange() => '${DateTime.now().year}';
  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _cycleRange {
    switch (_cycle) {
      case 1: return _today();
      case 2: return _weekRange();
      case 3: return _monthRange();
      case 4: return _yearRange();
      default: return '';
    }
  }

  DateTime _reportDate = DateTime.now().subtract(const Duration(days: 1));

  Future<void> _generateReport() async {
    final p = context.read<ReportProvider>();
    final isDaily = _cycle == 1;

    // Show confirmation dialog with date picker (daily) or just confirm (week/month/year)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${_cycleLabels[_cycle]}生成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI将聚合你所有模块数据，生成结构化复盘报告。\n\n（需连接后端AI服务，可能需要几秒钟）'),
              if (isDaily) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('复盘日期：', style: TextStyle(fontSize: 14)),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _reportDate,
                          firstDate: DateTime(2024, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _reportDate = picked;
                          setDialogState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_fmt(_reportDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                            const SizedBox(width: 4),
                            const Icon(Icons.calendar_today, size: 14, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('生成报告'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    // Check for existing daily report
    if (isDaily) {
      final dateStr = _fmt(_reportDate);
      final existing = p.findExisting(1, dateStr);
      if (existing != null) {
        final shouldReplace = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('已有复盘报告'),
            content: Text('$dateStr 的日复盘报告已存在，是否删除并重新生成？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                child: const Text('删除并重新生成'),
              ),
            ],
          ),
        );
        if (shouldReplace != true) return;
        await p.delete(existing.reportId!);
      }
    }

    final dateStr = isDaily ? _fmt(_reportDate) : null;
    final result = await p.generateReport(_cycle, date: dateStr);
    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $result'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI复盘报告已生成'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  void _openReport(AiReport r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_cycleLabels[r.cycleType] ?? '复盘'} · ${r.cycleRange ?? ''}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('✕', style: TextStyle(fontSize: 20, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    Text(r.reportContent ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractSummary(String? content) {
    if (content == null || content.isEmpty) return '暂无内容';
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.replaceAll(RegExp(r'^[#*\s\-]+'), '').trim();
      if (trimmed.isNotEmpty && trimmed.length > 3 && !trimmed.startsWith('好的') && !trimmed.startsWith('基于此')) {
        return '${trimmed.substring(0, trimmed.length.clamp(0, 60))}...';
      }
    }
    return '${content.substring(0, content.length.clamp(0, 60))}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: Consumer3<ReportProvider, RecordProvider, InterveneProvider>(
        builder: (_, reportProv, recordProv, interveneProv, __) {
          final cycleReports = reportProv.reports.where((r) => r.cycleType == _cycle).toList();
          final currentReport = cycleReports.isNotEmpty ? cycleReports.first : null;
          final allReports = reportProv.reports;
          final emotionAvg = recordProv.records.isNotEmpty
              ? '${(recordProv.records.fold(0, (s, r) => s + (r.emotionScore ?? 0)) ~/ recordProv.records.length)}'
              : '--';
          final behaviorRate = (interveneProv.successRate * 100).round();

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([reportProv.loadAll(), recordProv.loadByDate(_today()), interveneProv.loadAll()]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cycle selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [1, 2, 3, 4].map((v) {
                      final active = _cycle == v;
                      final labels = {1: '日', 2: '周', 3: '月', 4: '年'};
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _cycle = v),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(labels[v]!, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: active ? Colors.white : AppTheme.textSecondary,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // AI Report section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🤖 AI 复盘报告', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    OutlinedButton(
                      onPressed: reportProv.generating ? null : _generateReport,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
                      child: reportProv.generating
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 6),
                                Text('生成中…'),
                              ],
                            )
                          : const Text('✨ 生成复盘报告'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (currentReport != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentReport.cycleRange ?? currentReport.createTime ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 300),
                            child: SingleChildScrollView(
                              child: Text(currentReport.reportContent ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Text('点击上方按钮生成AI复盘报告', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                const SizedBox(height: 18),

                // Stat cards (3)
                Row(children: [
                  Expanded(child: _StatCard('${recordProv.records.length}', '📝 记录总数')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard('$emotionAvg', '💭 情绪均值')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard('$behaviorRate%', '✅ 行为成功率')),
                ]),
                const SizedBox(height: 18),

                // History reports
                const Text('📋 历史报告', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (allReports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Text('暂无历史报告', style: TextStyle(color: AppTheme.textMuted))),
                  )
                else
                  ...allReports.map((r) => GestureDetector(
                    onTap: () => _openReport(r),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF0F3F4), borderRadius: BorderRadius.circular(4)),
                                  child: Text(_cycleLabels[r.cycleType] ?? '复盘', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(r.cycleRange ?? r.createTime ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        if (r.reportId == null) return;
                                        if (await showDeleteConfirm(context, item: '该复盘报告')) {
                                          reportProv.delete(r.reportId!);
                                        }
                                      },
                                      child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(_extractSummary(r.reportContent), style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}
