import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/behavior.dart';
import '../../providers/intervene_provider.dart';

class IntervenePage extends StatefulWidget {
  const IntervenePage({super.key});
  @override
  State<IntervenePage> createState() => _IntervenePageState();
}

class _IntervenePageState extends State<IntervenePage> {
  // Timer
  int _timerSeconds = 0;
  Timer? _timer;
  bool _timerRunning = false;

  // Form state
  int _formTypeIndex = 0;
  int _formEmotion = 3;
  final _formTriggerCtrl = TextEditingController();
  bool _showForm = false;

  static const _types = [
    _InterveneType(1, '拖延矫正', '对抗拖延，立即行动', '⏰', Color(0xFFEBF5FB)),
    _InterveneType(2, '杂念疏导', '清理杂念，回归专注', '🧘', Color(0xFFF4ECF7)),
    _InterveneType(3, '短视频戒断', '减少刷屏，夺回时间', '📱', Color(0xFFFDEDEC)),
    _InterveneType(4, '懒惰管理', '克服惰性，保持动力', '💪', Color(0xFFFEF9E7)),
  ];

  static const _emotionOptions = [
    _EmotionOpt(1, '很差'),
    _EmotionOpt(2, '较差'),
    _EmotionOpt(3, '一般'),
    _EmotionOpt(4, '较好'),
    _EmotionOpt(5, '很好'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InterveneProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _formTriggerCtrl.dispose();
    super.dispose();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
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
          context.read<InterveneProvider>().add(BehaviorIntervene(
            interveneType: 0, moodBefore: '3', isSuccess: 1,
            interveneTime: '${_today()}T00:00:00',
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('5分钟到！继续保持')),
          );
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    final mins = _timerSeconds ~/ 60;
    setState(() => _timerRunning = false);
    if (_timerSeconds >= 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('专注了 $mins 分钟')),
      );
    }
  }

  String get _formattedTime {
    final m = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_timerSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openForm(int typeIndex) {
    setState(() {
      _formTypeIndex = typeIndex;
      _formEmotion = 3;
      _formTriggerCtrl.clear();
      _showForm = true;
    });
  }

  void _submitIntervention() {
    context.read<InterveneProvider>().add(BehaviorIntervene(
      interveneType: _types[_formTypeIndex].type,
      moodBefore: '$_formEmotion',
      isSuccess: 0,
      interveneTime: '${_today()}T00:00:00',
    ));
    setState(() => _showForm = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已记录')),
    );
  }

  int _typeRate(InterveneProvider p, int type) {
    final items = p.intervenes.where((b) => b.interveneType == type).toList();
    if (items.isEmpty) return 0;
    final done = items.where((b) => b.isSuccess == 1).length;
    return (done / items.length * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('心理行为矫正')),
      body: Consumer<InterveneProvider>(
        builder: (_, p, __) {
          final successRate = (p.successRate * 100).round();

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => p.loadAll(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Intervention type grid 2x2
                    const Text('干预类型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: 4,
                      itemBuilder: (_, i) {
                        final t = _types[i];
                        final rate = _typeRate(p, t.type);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: t.bgColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(child: Text(t.icon, style: const TextStyle(fontSize: 20))),
                                ),
                                const SizedBox(height: 6),
                                Text(t.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                const SizedBox(height: 2),
                                Text(t.desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(height: 8),
                                Text('成功率 $rate%', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: rate / 100, minHeight: 4,
                                    backgroundColor: AppTheme.border,
                                    valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 30,
                                  child: OutlinedButton(
                                    onPressed: () => _openForm(i),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      textStyle: const TextStyle(fontSize: 11),
                                      minimumSize: const Size(0, 30),
                                    ),
                                    child: const Text('快速干预'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5-minute timer
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text('5分钟专注', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            const Text('启动一个5分钟的专注计时，对抗拖延', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            const SizedBox(height: 14),
                            if (_timerRunning) ...[
                              Text(_formattedTime, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                              const SizedBox(height: 10),
                              OutlinedButton(onPressed: _stopTimer, child: const Text('停止')),
                            ] else
                              ElevatedButton(
                                onPressed: _startTimer,
                                child: const Text('开始 5 分钟'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats summary
                    const Text('干预统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _StatCard('$successRate%', '综合成功率')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard('${p.intervenes.length}', '干预次数')),
                        const SizedBox(width: 10),
                        const Expanded(child: _StatCard('0', '连续天数')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Records
                    const Text('干预记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (p.intervenes.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: Text('暂无干预记录', style: TextStyle(color: AppTheme.textMuted))),
                        ),
                      )
                    else
                      ...p.intervenes.map((r) => Card(
                        child: ListTile(
                          leading: Icon(
                            r.isSuccess == 1 ? Icons.check_circle : Icons.cancel_outlined,
                            color: r.isSuccess == 1 ? AppTheme.success : AppTheme.danger,
                            size: 22,
                          ),
                          title: Text(r.typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('情绪${r.moodBefore ?? "?"}  ${r.isSuccess == 1 ? "成功" : "未成功"}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => context.read<InterveneProvider>().delete(r.interveneId!),
                          ),
                        ),
                      )),
                  ],
                ),
              ),

              // Bottom sheet modal
              if (_showForm)
                GestureDetector(
                  onTap: () => setState(() => _showForm = false),
                  child: Container(color: const Color(0x66000000)),
                ),
              if (_showForm)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('记录干预', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        const SizedBox(height: 20),
                        const Text('干预类型', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _formTypeIndex,
                              isExpanded: true,
                              items: List.generate(_types.length, (i) => DropdownMenuItem(value: i, child: Text(_types[i].name))),
                              onChanged: (v) => setState(() => _formTypeIndex = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('干预前情绪', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (i) {
                            final active = _formEmotion == i + 1;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _formEmotion = i + 1),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: active ? AppTheme.primary : AppTheme.bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
                                  ),
                                  child: Text(_emotionOptions[i].label, textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: active ? Colors.white : AppTheme.textSecondary)),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        const Text('触发描述', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _formTriggerCtrl,
                          decoration: const InputDecoration(hintText: '描述触发本次行为的场景...'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _showForm = false),
                                child: const Text('取消'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submitIntervention,
                                child: const Text('保存记录'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InterveneType {
  final int type;
  final String name;
  final String desc;
  final String icon;
  final Color bgColor;
  const _InterveneType(this.type, this.name, this.desc, this.icon, this.bgColor);
}

class _EmotionOpt {
  final int value;
  final String label;
  const _EmotionOpt(this.value, this.label);
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
