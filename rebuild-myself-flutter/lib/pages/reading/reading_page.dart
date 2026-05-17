import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/book.dart';
import '../../providers/reading_provider.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});
  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  int _tab = 0;
  static const _types = ['wealth', 'psychology', 'leisure'];
  static const _typeNames = ['财商赚钱', '心理成长', '人文休闲'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadingProvider>().loadAll();
    });
  }

  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final minsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    double progress = 0;
    bool escaping = false;

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
              const Text('新增阅读记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '书名')),
              const SizedBox(height: 10),
              TextField(controller: minsCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '阅读时长（分钟）')),
              const SizedBox(height: 8),
              Row(children: [
                const Text('进度', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Expanded(child: Slider(value: progress, min: 0, max: 100, divisions: 20,
                    activeColor: AppTheme.primary, onChanged: (v) => setSt(() => progress = v))),
                Text('${progress.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              TextField(controller: notesCtrl, decoration: const InputDecoration(hintText: '读书笔记'), maxLines: 3),
              const SizedBox(height: 8),
              Row(children: [
                const Text('逃避状态', style: TextStyle(fontSize: 12)),
                const Spacer(),
                Switch(value: escaping, activeColor: AppTheme.danger,
                    onChanged: (v) => setSt(() => escaping = v)),
                Text(escaping ? '逃避中' : '坚持中',
                    style: TextStyle(fontSize: 12, color: escaping ? AppTheme.danger : AppTheme.success)),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    context.read<ReadingProvider>().add(BookReadRecord(
                      bookType: _types[_tab], bookName: nameCtrl.text,
                      readMinutes: int.tryParse(minsCtrl.text) ?? 0,
                      bookNotes: notesCtrl.text, readProgress: progress.round(),
                      escapeStatus: escaping ? 1 : 0, recordDate: _today(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('书籍阅读')),
      body: Consumer<ReadingProvider>(
        builder: (_, p, __) {
          return RefreshIndicator(
            onRefresh: () => p.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 2 Stat Cards
                Row(children: [
                  Expanded(child: _StatCard('总阅读', '${p.totalMinutes}分钟', AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard('在读数量', '${p.records.length}本', AppTheme.success)),
                ]),
                const SizedBox(height: 14),

                // Quick start (purple gradient)
                Container(
                  width: double.infinity, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showAddSheet,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('5分钟轻阅读启动', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tab bar (underline)
                Row(
                  children: List.generate(3, (i) {
                    final active = _tab == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(
                            color: active ? AppTheme.primary : Colors.transparent, width: 2.5))),
                          child: Text(_typeNames[i], textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: active ? AppTheme.primary : AppTheme.textSecondary)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                if (p.records.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(30),
                      child: Center(child: Text('暂无阅读记录\n点击紫色按钮添加', textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textMuted)))))
                else
                  ...p.records.map((r) => Card(
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
                            child: const Icon(Icons.menu_book, size: 20, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(r.bookName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                  _MiniBadge(r.escapeStatus == 1 ? '逃避' : '坚持',
                                      r.escapeStatus == 1 ? AppTheme.danger : AppTheme.success),
                                ]),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                      value: (r.readProgress ?? 0) / 100, minHeight: 6,
                                      backgroundColor: AppTheme.border,
                                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary)),
                                ),
                                const SizedBox(height: 4),
                                Text('${r.typeLabel} · ${r.readMinutes ?? 0}分钟 · ${r.readProgress ?? 0}% · ${r.recordDate}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                if (r.bookNotes != null && r.bookNotes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(r.bookNotes!, maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            onPressed: () => context.read<ReadingProvider>().delete(r.id!),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))]),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniBadge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
