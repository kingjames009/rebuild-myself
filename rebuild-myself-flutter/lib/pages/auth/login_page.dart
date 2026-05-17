import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/token_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _pwd = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCreds();
  }

  Future<void> _loadCreds() async {
    final creds = await TokenStore().loadCreds();
    if (creds != null && mounted) {
      _phone.text = creds['phone'] ?? '';
      _pwd.text = creds['pwd'] ?? '';
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final auth = context.read<AuthProvider>();
    final phone = _phone.text.trim();
    final pwd = _pwd.text;
    final ok = await auth.login(phone, pwd);
    if (ok && mounted) {
      await TokenStore().saveCreds(phone, pwd);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Consumer<AuthProvider>(
            builder: (_, auth, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  const Text('精进', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  const Text('全维度人生重塑自律成长', style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '手机号', prefixIcon: Icon(Icons.phone_android)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pwd,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: '密码', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.loading ? null : _doLogin,
                    child: auth.loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: auth.loading ? null : () => Navigator.pushNamed(context, '/register'),
                    child: const Text('注册新账号'),
                  ),
                  const Spacer(flex: 3),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
