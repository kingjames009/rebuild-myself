import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/token_store.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phone = TextEditingController();
  final _pwd = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    final auth = context.read<AuthProvider>();
    final phone = _phone.text.trim();
    final pwd = _pwd.text;
    final ok = await auth.register(phone, pwd);
    if (ok && mounted) {
      // Auto-login after registration
      final loginOk = await auth.login(phone, pwd);
      if (loginOk && mounted) {
        await TokenStore().saveCreds(pwd);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
            (_) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '手机号', prefixIcon: Icon(Icons.phone_android)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pwd,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '设置密码', prefixIcon: Icon(Icons.lock_outline)),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.loading ? null : _doRegister,
                  child: auth.loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('注册并登录'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
