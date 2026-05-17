import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/study.dart';
import '../../providers/study_provider.dart';
import '../../utils/dialogs.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});
  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  int _tab = 0;
  static const _tracks = ['speech', 'ai', 'app'];
  static const _trackNames = ['英语演讲', 'AI学习', '应用开发'];

  // Timer
  int _timerSeconds = 0;
  Timer? _timer;
  bool _timerRunning = false;

  final _contentCtrl = TextEditingController();
  final _minsCtrl = TextEditingController();
  double _difficulty = 3;
  bool _escaping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _minsCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timerRunning) return;
    setState(() { _timerRunning = true; _timerSeconds = 0; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _timerSeconds++;
        if (_timerSeconds >= 300) {
          t.cancel();
          _timerRunning = false;
          _saveRecord();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('5分钟学习已完成！')),
          );
        }
      });
    });
  }

  void _saveRecord() {
    final mins = int.tryParse(_minsCtrl.text) ?? _timerSeconds ~/ 60;
    if (mins > 0 || _contentCtrl.text.isNotEmpty) {
      context.read<StudyProvider>().add(StudyTrackRecord(
        trackType: _tracks[_tab],
        studyContent: _contentCtrl.text.isNotEmpty ? _contentCtrl.text : '5分钟专注学习',
        studyMinutes: mins > 0 ? mins : _timerSeconds ~/ 60,
        difficultyLevel: _difficulty.round(),
        escapeStatus: _escaping ? 1 : 0,
        recordDate: _today(),
      ));
      _contentCtrl.clear();
      _minsCtrl.clear();
    }
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('三赛道学习中心')),
      body: Consumer<StudyProvider>(
        builder: (_, p, __) {
          return RefreshIndicator(
            onRefresh: () => p.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 2x2 Stat Grid
                Row(
                  children: [
                    Expanded(child: _StatCard('英语演讲', '${p.trackMinutes('speech')}分钟', Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('AI学习', '${p.trackMinutes('ai')}分钟', Colors.deepPurple)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _StatCard('应用开发', '${p.trackMinutes('app')}分钟', Colors.teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('逃避率', '${p.escapeRate}%', AppTheme.danger)),
                  ],
                ),
                const SizedBox(height: 14),

                // Quick start button (green gradient)
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF27AE60), Color(0xFF2ECC71)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _startTimer,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_timerRunning)
                            Text('${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white))
                          else ...[
                            const Icon(Icons.bolt, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            const Text('5分钟启动学习', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (_timerRunning) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () { _timer?.cancel(); setState(() => _timerRunning = false); },
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('停止'),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Tab bar (underline style)
                Row(
                  children: List.generate(3, (i) {
                    final active = _tab == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(
                              color: active ? AppTheme.primary : Colors.transparent,
                              width: 2.5,
                            )),
                          ),
                          child: Text(
                            _trackNames[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Add record form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('新增记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _Badge(_trackNames[_tab], AppTheme.primary),
                        ]),
                        const SizedBox(height: 10),
                        TextField(controller: _contentCtrl, decoration: const InputDecoration(hintText: '学习内容')),
                        const SizedBox(height: 8),
                        TextField(controller: _minsCtrl, keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '学习时长（分钟）')),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('难度', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Expanded(
                            child: Slider(value: _difficulty, min: 1, max: 10, divisions: 9,
                                activeColor: AppTheme.primary, onChanged: (v) => setState(() => _difficulty = v)),
                          ),
                          Text('${_difficulty.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                        Row(children: [
                          const Text('逃避状态', style: TextStyle(fontSize: 12)),
                          const Spacer(),
                          Switch(value: _escaping, activeColor: AppTheme.danger,
                              onChanged: (v) => setState(() => _escaping = v)),
                          Text(_escaping ? '已逃避' : '已坚持',
                              style: TextStyle(fontSize: 12, color: _escaping ? AppTheme.danger : AppTheme.success)),
                        ]),
                        ElevatedButton(onPressed: _saveRecord, child: const Text('保存')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Records list
                const Text('学习记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (p.records.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(30),
                      child: Center(child: Text('暂无学习记录', style: TextStyle(color: AppTheme.textMuted)))))
                else
                  ...p.records.map((r) => Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (r.escapeStatus == 1 ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.escapeStatus == 1 ? '逃避' : '坚持',
                          style: TextStyle(fontSize: 10, color: r.escapeStatus == 1 ? AppTheme.danger : AppTheme.success, fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(r.studyContent ?? '', style: const TextStyle(fontSize: 14)),
                      subtitle: Text('${r.trackLabel} · ${r.studyMinutes ?? 0}分钟 · 难度${r.difficultyLevel ?? 0} · ${r.recordDate}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
  if (await showDeleteConfirm(context, item: '该学习记录')) {
    context.read<StudyProvider>().delete(r.id!);
  }
},
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
