import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/report_provider.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // Default to yesterday for daily review — makes more sense than today
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAll();
    });
  }

  String _dateStr() =>
      '${_selectedDate.year}-${_pad(_selectedDate.month)}-${_pad(_selectedDate.day)}';

  void _showGenerateDialog(int cycle) {
    final isDaily = cycle == 1; // only daily report needs date selector
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${_cycleLabel(cycle)}复盘生成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI将聚合你所有模块数据，生成结构化复盘报告：\n\n📊 数据总结\n🔍 问题诊断\n🎯 根源溯源\n💡 定制优化方案\n\n（需连接后端AI服务，可能需要几秒钟）'),
              if (isDaily) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('复盘日期：', style: TextStyle(fontSize: 14)),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
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
                            Text(_dateStr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await context.read<ReportProvider>().generateReport(
                  cycle,
                  date: cycle == 1 ? _dateStr() : null,
                );
                if (context.mounted) {
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('生成失败: $result'), backgroundColor: AppTheme.danger),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI复盘报告已生成')),
                    );
                  }
                }
              },
              child: const Text('生成报告'),
            ),
          ],
        ),
      ),
    );
  }

  String _cycleLabel(int c) {
    const map = {1: '日', 2: '周', 3: '月', 4: '年'};
    return map[c] ?? '';
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _demoReport(int cycle) {
    return '''## 📊 数据总结
本周期共学习180分钟，阅读60分钟，副业推进40分钟，休闲活动2次。拖延行为出现3次，情绪平均评分6.5/10。

## 🔍 问题诊断
1. 下班后精力低下 → 学习拖延
2. 短视频35分钟超限 → 侵占阅读时间
3. 财务压力维持在中等水平

## 🎯 根源溯源
主要根源：下班后缺乏过渡仪式，手机作为主要放松方式。意志力在下班时已消耗殆尽。

## 💡 优化方案
1. 下班后10分钟冥想过渡
2. 短视频限额调至20分钟
3. 将最重要学习任务安排在午休后
4. 睡前阅读替代刷手机''';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI全维度复盘'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: '日复盘'),
              Tab(text: '周复盘'),
              Tab(text: '月复盘'),
              Tab(text: '年复盘'),
            ],
          ),
        ),
        body: Consumer<ReportProvider>(
          builder: (_, provider, __) {
            return TabBarView(
              children: List.generate(4, (i) => _ReportList(cycle: i + 1, provider: provider, onGenerate: () => _showGenerateDialog(i + 1))),
            );
          },
        ),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  final int cycle;
  final ReportProvider provider;
  final VoidCallback onGenerate;
  const _ReportList({required this.cycle, required this.provider, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final reports = provider.getByCycle(cycle);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('生成新复盘报告'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
        ),
        const SizedBox(height: 16),
        if (reports.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('暂无复盘报告\n点击上方按钮生成', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted))))
        else
          ...reports.map((r) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(r.createTime?.substring(0, 10) ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
                          onPressed: () => provider.delete(r.reportId!),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(r.reportContent ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
