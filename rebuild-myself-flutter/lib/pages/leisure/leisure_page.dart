import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/leisure.dart';
import '../../providers/leisure_provider.dart';

class LeisurePage extends StatefulWidget {
  const LeisurePage({super.key});
  @override
  State<LeisurePage> createState() => _LeisurePageState();
}

class _LeisurePageState extends State<LeisurePage> {
  String _selectedType = 'relax';

  static const _types = [
    _TypeItem('relax', '放松', Icons.self_improvement, Colors.blue),
    _TypeItem('meditate', '冥想', Icons.spa, Colors.purple),
    _TypeItem('quotes', '治愈短句', Icons.format_quote, Colors.teal),
    _TypeItem('stretch', '拉伸', Icons.fitness_center, Colors.green),
    _TypeItem('organize', '环境整理', Icons.cleaning_services, Colors.orange),
    _TypeItem('knowledge', '碎片新知', Icons.lightbulb, Colors.indigo),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeisureProvider>().loadAll();
    });
  }

  void _showAddSheet() {
    final minsCtrl = TextEditingController();
    double happy = 5;
    final type = _types.firstWhere((t) => t.id == _selectedType);

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
              Text('${type.title}记录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(controller: minsCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '时长（分钟）')),
              const SizedBox(height: 12),
              Row(children: [
                const Text('愉悦感', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Expanded(child: Slider(value: happy, min: 1, max: 10, divisions: 9,
                    activeColor: AppTheme.success, onChanged: (v) => setSt(() => happy = v))),
                Text('${happy.round()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.success)),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<LeisureProvider>().add(LifeLeisureRecord(
                    leisureType: _selectedType,
                    leisureMinutes: int.tryParse(minsCtrl.text) ?? 0,
                    happyScore: happy.round(),
                    recordDate: _today(),
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

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('生活丰盈 · 轻爱好')),
      body: Consumer<LeisureProvider>(
        builder: (_, p, __) {
          return RefreshIndicator(
            onRefresh: () => p.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Happiness bar chart style card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite, color: AppTheme.danger, size: 22),
                            const SizedBox(width: 8),
                            Text('今日愉悦指数 ', style: const TextStyle(fontSize: 15)),
                            Text('${p.todayHappiness} / 10',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                                    color: p.todayHappiness >= 7 ? AppTheme.success
                                        : p.todayHappiness >= 4 ? AppTheme.warning : AppTheme.danger)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Simple happiness bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                              value: p.todayHappiness / 10, minHeight: 10,
                              backgroundColor: AppTheme.border,
                              valueColor: AlwaysStoppedAnimation(
                                  p.todayHappiness >= 7 ? AppTheme.success
                                      : p.todayHappiness >= 4 ? AppTheme.warning : AppTheme.danger)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Type chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((t) => GestureDetector(
                    onTap: () {
                      setState(() => _selectedType = t.id);
                      _showAddSheet();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedType == t.id ? t.color : t.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16, color: _selectedType == t.id ? Colors.white : t.color),
                          const SizedBox(width: 4),
                          Text(t.title, style: TextStyle(fontSize: 13,
                              color: _selectedType == t.id ? Colors.white : t.color,
                              fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Records
                const Text('今日休闲记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (p.records.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(30),
                      child: Center(child: Text('还没有休闲记录\n点击上方标签开始记录',
                          textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)))))
                else
                  ...p.records.map((r) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.spa, size: 20, color: AppTheme.success),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('${r.leisureMinutes ?? 0}分钟 · ${r.recordDate}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Text('${r.happyScore ?? 0}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                                color: (r.happyScore ?? 0) >= 7 ? AppTheme.success
                                    : (r.happyScore ?? 0) >= 4 ? AppTheme.warning : AppTheme.danger)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.read<LeisureProvider>().delete(r.id!),
                          child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.textMuted),
                        ),
                      ]),
                    ),
                  )),
                const SizedBox(height: 14),

                // Boredom alternatives
                const Text('无聊时试试这些', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...[
                  _AltCard('🧘', '冥想5分钟', '闭上眼睛，关注呼吸'),
                  _AltCard('📖', '读治愈短句', '打开一本喜欢的书'),
                  _AltCard('🧹', '整理桌面', '清爽环境，清爽心情'),
                  _AltCard('🏃', '拉伸身体', '缓解肩颈僵硬'),
                  _AltCard('🎵', '听一首歌', '放松心情的好方法'),
                  _AltCard('✍️', '写3行日记', '记录今天的小确幸'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypeItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  const _TypeItem(this.id, this.title, this.icon, this.color);
}

class _AltCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _AltCard(this.emoji, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
        ]),
      ),
    );
  }
}
