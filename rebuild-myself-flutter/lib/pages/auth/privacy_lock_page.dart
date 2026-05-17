import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class PrivacyLockPage extends StatefulWidget {
  const PrivacyLockPage({super.key});
  @override
  State<PrivacyLockPage> createState() => _PrivacyLockPageState();
}

class _PrivacyLockPageState extends State<PrivacyLockPage> {
  final _pwdCtrl = TextEditingController();
  String? _errorMsg;

  void _verify() {
    final ok = context.read<AuthProvider>().verifyPrivacyPwd(_pwdCtrl.text);
    if (ok) {
      if (Navigator.canPop(context)) Navigator.pop(context);
    } else {
      setState(() => _errorMsg = '密码错误，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text('隐私锁定', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('输入密码解锁应用', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              TextField(
                controller: _pwdCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 16),
                decoration: InputDecoration(
                  hintText: '······',
                  counterText: '',
                  errorText: _errorMsg,
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _verify, child: const Text('解锁')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<AuthProvider>().disablePrivacy();
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                child: const Text('忘记密码？清除隐私锁', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
