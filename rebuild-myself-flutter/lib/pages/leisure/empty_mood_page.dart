import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/empty_mood.dart';
import '../../providers/empty_mood_provider.dart';
import '../../utils/dialogs.dart';

class EmptyMoodPage extends StatefulWidget {
  const EmptyMoodPage({super.key});
  @override
  State<EmptyMoodPage> createState() => _EmptyMoodPageState();
}

class _EmptyMoodPageState extends State<EmptyMoodPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmptyMoodProvider>().loadAll();
    });
  }

  void _showAddDialog() {
    final levelCtrl = TextEditingController();
    final emptyCtrl = TextEditingController();
    final triggerCtrl = TextEditingController();
    final wasteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('空虚状态记录'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: levelCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '空虚等级 1-10')),
              const SizedBox(height: 10),
              TextField(controller: emptyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '空洞时长（小时）')),
              const SizedBox(height: 10),
              TextField(controller: triggerCtrl, decoration: const InputDecoration(hintText: '触发诱因')),
              const SizedBox(height: 10),
              TextField(controller: wasteCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '浪费时长（小时）')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              context.read<EmptyMoodProvider>().add(EmptyMoodLog(
                    emptyLevel: int.tryParse(levelCtrl.text) ?? 0,
                    emptyHours: double.tryParse(emptyCtrl.text) ?? 0,
                    triggerCause: triggerCtrl.text,
                    wasteHours: double.tryParse(wasteCtrl.text) ?? 0,
                    recordDate: _today(),
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('空虚状态溯源')),
      body: Consumer<EmptyMoodProvider>(
        builder: (_, provider, __) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryBanner(
                avgLevel: provider.avgEmptyLevel,
                totalWaste: provider.totalWasteHours,
              ),
              const SizedBox(height: 16),
              const _CausalChain(),
              const SizedBox(height: 16),
              Row(children: [
                const Text('状态记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add, size: 18), label: const Text('新增')),
              ]),
              const SizedBox(height: 8),
              if (provider.logs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('暂无记录', style: TextStyle(color: AppTheme.textMuted))))
              else
                ...provider.logs.map((l) => _EmptyCard(log: l)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final double avgLevel;
  final double totalWaste;
  const _SummaryBanner({required this.avgLevel, required this.totalWaste});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          _SummaryValue(label: '平均空虚', value: avgLevel.toStringAsFixed(1), unit: '/10'),
          _SummaryValue(label: '浪费总时长', value: totalWaste.toStringAsFixed(1), unit: '小时'),
          _SummaryValue(label: '高发时段', value: '18-22', unit: '点'),
        ].map((w) => Expanded(child: w)).toList()),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _SummaryValue({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$value$unit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]);
  }
}

class _CausalChain extends StatelessWidget {
  const _CausalChain();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('因果链追踪', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ChainNode(icon: Icons.sentiment_dissatisfied, label: '单调无聊'),
                const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textMuted),
                _ChainNode(icon: Icons.smart_display, label: '刷手机'),
                const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textMuted),
                _ChainNode(icon: Icons.mood_bad, label: '颓废'),
                const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textMuted),
                _ChainNode(icon: Icons.sentiment_very_dissatisfied, label: '内耗停滞'),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: const Text('阻断方案：一键正向替代'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainNode extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChainNode({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppTheme.primary),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]);
  }
}

class _EmptyCard extends StatelessWidget {
  final EmptyMoodLog log;
  const _EmptyCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (log.emptyLevel ?? 0) >= 7 ? AppTheme.danger.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.sentiment_dissatisfied, size: 20, color: (log.emptyLevel ?? 0) >= 7 ? AppTheme.danger : AppTheme.warning),
        ),
        title: Text('空虚等级 ${log.emptyLevel} · 空洞 ${log.emptyHours}小时 · 浪费 ${log.wasteHours}小时'),
        subtitle: Text('${log.recordDate}  ${log.triggerCause ?? ""}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () async {
            if (await showDeleteConfirm(context, item: '该空虚记录')) {
              context.read<EmptyMoodProvider>().delete(log.id!);
            }
          },
        ),
      ),
    );
  }
}
