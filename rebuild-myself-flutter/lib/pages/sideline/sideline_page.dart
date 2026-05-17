import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/sideline.dart';
import '../../providers/sideline_provider.dart';

class SidelinePage extends StatefulWidget {
  const SidelinePage({super.key});
  @override
  State<SidelinePage> createState() => _SidelinePageState();
}

class _SidelinePageState extends State<SidelinePage> {
  String _direction = 'english';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SidelineProvider>().loadAll();
    });
  }

  void _showAddSheet() {
    final actionCtrl = TextEditingController();
    double energy = 3;
    final blockCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('${_dirLabel(_direction)}副业记录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(controller: actionCtrl, decoration: const InputDecoration(hintText: '每日行动内容'), maxLines: 3),
              const SizedBox(height: 10),
              Row(children: [
                const Text('精力消耗', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Expanded(child: Slider(value: energy, min: 1, max: 10, divisions: 9,
                    activeColor: AppTheme.primary, onChanged: (v) => setSt(() => energy = v))),
                Text('${energy.round()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              TextField(controller: blockCtrl, decoration: const InputDecoration(hintText: '阻碍原因（可选）')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (actionCtrl.text.isNotEmpty) {
                    context.read<SidelineProvider>().add(SidelinePlan(
                      sideType: _direction, dailyAction: actionCtrl.text,
                      energyCost: energy.round(), progress: 0,
                      blockReason: blockCtrl.text, recordDate: _today(),
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _dirLabel(String d) {
    const m = {'english': '英语方向', 'ai': 'AI方向', 'dev': '开发综合'};
    return m[d] ?? d;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('轻量副业规划')),
      body: Consumer<SidelineProvider>(
        builder: (_, p, __) {
          return RefreshIndicator(
            onRefresh: () => p.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Direction radio chips
                Row(
                  children: ['english', 'ai', 'dev'].map((d) {
                    final active = _direction == d;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _direction = d),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primary : AppTheme.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_dirLabel(d), textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: active ? Colors.white : AppTheme.textSecondary)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Progress per direction
                ...[
                  ('english', '英语方向', Colors.blue),
                  ('ai', 'AI方向', Colors.deepPurple),
                  ('dev', '开发综合', Colors.teal),
                ].map((e) {
                  final prog = p.progressFor(e.$1);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: (e.$3 as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Icon(Icons.trending_up, size: 18, color: e.$3),
                            ),
                            const SizedBox(width: 10),
                            Text(e.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: prog / 100, minHeight: 8,
                                backgroundColor: AppTheme.border,
                                valueColor: AlwaysStoppedAnimation(e.$3 as Color)),
                          ),
                          const SizedBox(height: 4),
                          Text('$prog%', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: _showAddSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('记录副业行动'),
                ),
                const SizedBox(height: 16),

                // Records
                const Text('每日微行动记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (p.plans.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(30),
                      child: Center(child: Text('暂无记录', style: TextStyle(color: AppTheme.textMuted)))))
                else
                  ...p.plans.map((r) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.trending_up, size: 20, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.dailyAction ?? '', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('${r.typeLabel} · ${r.recordDate} · 精力${r.energyCost ?? 0}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                if (r.blockReason != null && r.blockReason!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('障碍: ${r.blockReason}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.danger)),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            onPressed: () => context.read<SidelineProvider>().delete(r.id!),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
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
