import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/token_store.dart';
import '../../services/phone_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _pwd = TextEditingController();
  bool _phonePermissionRequested = false;

  @override
  void initState() {
    super.initState();
    _loadCreds().then((_) => _tryAutoFillPhone());
  }

  Future<void> _loadCreds() async {
    final creds = await TokenStore().loadCreds();
    if (creds != null && mounted) {
      _pwd.text = creds['pwd'] ?? '';
    }
  }

  Future<void> _tryAutoFillPhone() async {
    // Don't request if phone is already filled from saved creds
    if (_phone.text.isNotEmpty) return;
    if (_phonePermissionRequested) return;
    _phonePermissionRequested = true;

    final hasPermission = await PhoneService.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      // Show rationale dialog before system permission request
      final granted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('自动填充手机号'),
          content: const Text('允许「精进」读取本机号码，以便快速登录？\n\n不会泄露您的隐私信息。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('拒绝'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('允许'),
            ),
          ],
        ),
      );
      if (granted != true) return;
      await PhoneService.requestPermission();
      // Wait a moment for the system permission dialog to return
      await Future.delayed(const Duration(milliseconds: 500));
    }

    var raw = await PhoneService.getPhoneNumber();
    if (raw != null && raw.isNotEmpty && mounted) {
      // Strip +86 / 86 prefix from SIM card number
      String phone = raw.trim();
      if (phone.startsWith('+86')) {
        phone = phone.substring(3);
      } else if (phone.startsWith('86') && phone.length == 13) {
        phone = phone.substring(2);
      }
      setState(() => _phone.text = phone);
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
