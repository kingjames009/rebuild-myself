import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/daily_record.dart';
import '../../providers/record_provider.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late String _viewDate;

  @override
  void initState() {
    super.initState();
    _viewDate = _today();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordProvider>().loadByDate(_viewDate);
    });
  }

  void _goDate(String date) {
    setState(() => _viewDate = date);
    context.read<RecordProvider>().loadByDate(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_viewDate) ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      locale: const Locale('zh'),
    );
    if (picked != null) {
      final d = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _goDate(d);
    }
  }

  void _showAddSheet(int type) {
    final contentCtrl = TextEditingController();
    final minsCtrl = TextEditingController();
    final triggerCtrl = TextEditingController();
    final emotionCtrl = TextEditingController();

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
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('新增${_typeLabel(type)}记录', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: contentCtrl, decoration: const InputDecoration(hintText: '记录内容')),
            const SizedBox(height: 10),
            TextField(controller: minsCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '耗时（分钟）')),
            const SizedBox(height: 10),
            TextField(controller: triggerCtrl, decoration: const InputDecoration(hintText: '触发原因（可选）')),
            const SizedBox(height: 10),
            TextField(controller: emotionCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '情绪评分 1-10')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (contentCtrl.text.isNotEmpty) {
                  context.read<RecordProvider>().add(DailyRecord(
                    recordType: type, content: contentCtrl.text,
                    costTime: int.tryParse(minsCtrl.text) ?? 0,
                    triggerReason: triggerCtrl.text,
                    emotionScore: int.tryParse(emotionCtrl.text) ?? 0,
                    recordDate: _viewDate,
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

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _typeLabel(int t) {
    const m = {1: '学习', 2: '作息', 3: '情绪', 4: '拖延', 5: '短视频', 6: '私密杂念'};
    return m[t] ?? '其他';
  }

  IconData _typeIcon(int t) {
    const m = {1: Icons.school, 2: Icons.bedtime, 3: Icons.mood, 4: Icons.hourglass_bottom, 5: Icons.smart_display, 6: Icons.lock};
    return m[t] ?? Icons.edit;
  }

  Color _typeColor(int t) {
    const m = {1: Colors.blue, 2: AppTheme.success, 3: AppTheme.warning, 4: AppTheme.danger, 5: Colors.deepOrange, 6: Colors.grey};
    return m[t] ?? AppTheme.primary;
  }

  String _formatDisplayDate(String d) {
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    final w = ['日', '一', '二', '三', '四', '五', '六'];
    final today = _today();
    if (d == today) return '今天 ${dt.month}月${dt.day}日 周${w[dt.weekday % 7]}';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yd = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (d == yd) return '昨天 ${dt.month}月${dt.day}日 周${w[dt.weekday % 7]}';
    return '${dt.month}月${dt.day}日 周${w[dt.weekday % 7]}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordProvider>();
    final isToday = _viewDate == _today();

    return Scaffold(
      appBar: AppBar(title: const Text('日常记录')),
      body: Column(
        children: [
          // Date navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final dt = DateTime.tryParse(_viewDate) ?? DateTime.now();
                    final prev = dt.subtract(const Duration(days: 1));
                    _goDate('${prev.year}-${prev.month.toString().padLeft(2, '0')}-${prev.day.toString().padLeft(2, '0')}');
                  },
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      Text(_formatDisplayDate(_viewDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isToday ? null : () {
                    final dt = DateTime.tryParse(_viewDate) ?? DateTime.now();
                    final next = dt.add(const Duration(days: 1));
                    _goDate('${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}');
                  },
                ),
                const Spacer(),
                if (!isToday)
                  TextButton(
                    onPressed: () => _goDate(_today()),
                    child: const Text('回到今天'),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadByDate(_viewDate),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Type chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 4, 5, 6].map((t) => GestureDetector(
                      onTap: () => _showAddSheet(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _typeColor(t).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_typeIcon(t), size: 16, color: _typeColor(t)),
                            const SizedBox(width: 4),
                            Text(_typeLabel(t), style: TextStyle(fontSize: 13, color: _typeColor(t), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (provider.loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    )),
                  if (!provider.loading && provider.records.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('暂无记录\n点击上方类型标签添加',
                            textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted))),
                      ),
                    )
                  else
                    ...provider.records.map((r) => _RecordCard(record: r)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final DailyRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = _typeColorStatic(record.recordType ?? 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(_typeIconStatic(record.recordType ?? 0), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.content ?? '', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${record.recordDate} · ${record.costTime ?? 0}分钟 · ${record.typeLabel} · 情绪${record.emotionScore ?? 0}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.read<RecordProvider>().delete(record.recordId!),
              child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIconStatic(int t) {
    const m = {1: Icons.school, 2: Icons.bedtime, 3: Icons.mood, 4: Icons.hourglass_bottom, 5: Icons.smart_display, 6: Icons.lock};
    return m[t] ?? Icons.edit;
  }

  static Color _typeColorStatic(int t) {
    const m = {1: Colors.blue, 2: AppTheme.success, 3: AppTheme.warning, 4: AppTheme.danger, 5: Colors.deepOrange, 6: Colors.grey};
    return m[t] ?? AppTheme.primary;
  }
}
