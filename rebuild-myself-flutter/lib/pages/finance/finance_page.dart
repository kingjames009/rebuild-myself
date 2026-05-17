import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/finance.dart';
import '../../providers/finance_provider.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  double _pressure = 5;
  final _gapCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  bool _escaping = false;
  final _actionMinsCtrl = TextEditingController();

  // Timer
  int _timerSeconds = 0;
  Timer? _timer;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _gapCtrl.dispose();
    _incomeCtrl.dispose();
    _actionMinsCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timerRunning) return;
    setState(() {
      _timerRunning = true;
      _timerSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _timerSeconds++;
        if (_timerSeconds >= 300) {
          // 5 min auto-record
          t.cancel();
          _timerRunning = false;
          _saveAction();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('5分钟搞定！行动已记录')),
          );
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _saveAction() {
    final mins = int.tryParse(_actionMinsCtrl.text) ?? _timerSeconds ~/ 60;
    if (mins > 0 || _incomeCtrl.text.isNotEmpty) {
      context.read<FinanceProvider>().add(FinanceMentalLog(
        moneyPressure: _pressure.round(),
        gapAmount: double.tryParse(_gapCtrl.text) ?? 0,
        incomeRecord: _incomeCtrl.text.isNotEmpty ? _incomeCtrl.text : '5分钟微行动',
        escapeState: _escaping ? 1 : 0,
        actionMinutes: mins > 0 ? mins : _timerSeconds ~/ 60,
        recordDate: _today(),
      ));
      _gapCtrl.clear();
      _incomeCtrl.clear();
      _actionMinsCtrl.clear();
    }
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('财务与赚钱行动')),
      body: Consumer<FinanceProvider>(
        builder: (_, provider, __) {
          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- Pressure Slider ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('当前金钱压力', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                            Text('${_pressure.round()} / 10',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700,
                                    color: _pressure >= 7 ? AppTheme.danger
                                        : _pressure >= 4 ? AppTheme.warning
                                            : AppTheme.success)),
                          ],
                        ),
                        Slider(
                          value: _pressure, min: 1, max: 10, divisions: 9,
                          activeColor: _pressure >= 7 ? AppTheme.danger
                              : _pressure >= 4 ? AppTheme.warning
                                  : AppTheme.success,
                          onChanged: (v) => setState(() => _pressure = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ---- 3 Stat Cards ----
                Row(
                  children: [
                    _MiniStatCard('周均压力', '${provider.avgPressure}', AppTheme.danger),
                    const SizedBox(width: 10),
                    _MiniStatCard('行动分钟', '${provider.totalActionMinutes}', AppTheme.success),
                    const SizedBox(width: 10),
                    _MiniStatCard('逃避状态', provider.escapeLabel,
                        provider.escaping ? AppTheme.warning : AppTheme.success),
                  ],
                ),
                const SizedBox(height: 14),

                // ---- Record Form ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('财务心理记录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _gapCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '资金缺口金额'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _incomeCtrl,
                          decoration: const InputDecoration(hintText: '收入记录/赚钱行动'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('逃避状态', style: TextStyle(fontSize: 13)),
                            const Spacer(),
                            Switch(
                              value: _escaping,
                              activeColor: AppTheme.danger,
                              onChanged: (v) => setState(() => _escaping = v),
                            ),
                            Text(_escaping ? '逃避中' : '正常',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _escaping ? AppTheme.danger : AppTheme.success)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _actionMinsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '行动时长（分钟）'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _saveAction,
                          child: const Text('保存记录'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ---- 5-Minute Quick Action ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.bolt, color: AppTheme.success, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('5分钟搞钱微行动', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  Text('立即开始一个小赚钱动作', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_timerRunning) ...[
                          Text(
                            '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: 4),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _stopTimer,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止'),
                          ),
                        ] else
                          ElevatedButton.icon(
                            onPressed: _startTimer,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('开始5分钟'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              minimumSize: const Size(double.infinity, 44),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ---- History ----
                const Text('赚钱行动记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (provider.logs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: Text('暂无记录', style: TextStyle(color: AppTheme.textMuted))),
                    ),
                  )
                else
                  ...provider.logs.map((l) => Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: (l.escapeState == 1 ? AppTheme.danger : AppTheme.success)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                            l.escapeState == 1 ? Icons.cancel_outlined : Icons.check_circle_outline,
                            size: 20,
                            color: l.escapeState == 1 ? AppTheme.danger : AppTheme.success),
                      ),
                      title: Text(l.incomeRecord ?? '未记录', style: const TextStyle(fontSize: 14)),
                      subtitle: Text('${l.recordDate} · 压力${l.moneyPressure} · 行动${l.actionMinutes ?? 0}分钟 · ¥${l.gapAmount ?? 0}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => context.read<FinanceProvider>().delete(l.id!),
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

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }
}
