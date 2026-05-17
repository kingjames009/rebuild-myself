import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nicknameCtrl = TextEditingController(text: '自律者');
  final _goalCtrl = TextEditingController();
  final _lockPwdCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _healthNoteCtrl = TextEditingController();
  bool _lockEnabled = false;
  bool _lockExists = false;
  final _nicknameFocus = FocusNode();
  final _healthFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _healthNoteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.user?.nickname != null && auth.user!.nickname!.isNotEmpty) {
      _nicknameCtrl.text = auth.user!.nickname!;
    }
    if (auth.user?.longTermGoal != null && auth.user!.longTermGoal!.isNotEmpty) {
      _goalCtrl.text = auth.user!.longTermGoal!;
    }
    if (auth.user?.height != null) {
      _heightCtrl.text = auth.user!.height!.toString();
    }
    if (auth.user?.weight != null) {
      _weightCtrl.text = auth.user!.weight!.toString();
    }
    if (auth.user?.healthNote != null && auth.user!.healthNote!.isNotEmpty) {
      _healthNoteCtrl.text = auth.user!.healthNote!;
    }
    _healthFocus.addListener(() {
      if (!_healthFocus.hasFocus) _saveHealth();
    });
    _weightFocus.addListener(() {
      if (!_weightFocus.hasFocus) _saveHealth();
    });
    _healthNoteFocus.addListener(() {
      if (!_healthNoteFocus.hasFocus) _saveHealth();
    });
    _nicknameFocus.addListener(() {
      if (!_nicknameFocus.hasFocus) {
        _saveNickname();
      }
    });
  }

  @override
  void dispose() {
    _saveHealth();
    _nicknameCtrl.dispose();
    _goalCtrl.dispose();
    _lockPwdCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _healthNoteCtrl.dispose();
    _nicknameFocus.dispose();
    _healthFocus.dispose();
    _weightFocus.dispose();
    _healthNoteFocus.dispose();
    super.dispose();
  }

  void _saveNickname() {
    final name = _nicknameCtrl.text.trim();
    if (name.isNotEmpty && name != '自律者') {
      context.read<AuthProvider>().updateProfile({'nickname': name});
    }
  }

  void _saveGoal() {
    final goal = _goalCtrl.text.trim();
    context.read<AuthProvider>().updateProfile({'longTermGoal': goal});
  }

  void _saveHealth() {
    final h = double.tryParse(_heightCtrl.text.trim());
    final w = double.tryParse(_weightCtrl.text.trim());
    final note = _healthNoteCtrl.text.trim();
    final data = <String, dynamic>{};
    if (h != null) data['height'] = h;
    if (w != null) data['weight'] = w;
    if (note.isNotEmpty) data['healthNote'] = note;
    if (data.isNotEmpty) {
      context.read<AuthProvider>().updateProfile(data);
    }
  }

  void _toggleLock(bool v) {
    if (!v) {
      context.read<AuthProvider>().disablePrivacy();
      setState(() { _lockEnabled = false; _lockExists = false; _lockPwdCtrl.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('隐私锁已关闭')));
    } else {
      setState(() { _lockEnabled = true; });
    }
  }

  void _setLockPwd() {
    if (_lockPwdCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码至少4位')));
      return;
    }
    context.read<AuthProvider>().setPrivacyPwd(_lockPwdCtrl.text);
    setState(() { _lockExists = true; _lockPwdCtrl.clear(); });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码已设置')));
  }

  void _showAvatarSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('更换头像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AvatarOption(
                    icon: Icons.camera_alt,
                    label: '拍照',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUpload(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _AvatarOption(
                    icon: Icons.photo_library,
                    label: '从相册选择',
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUpload(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 400, maxHeight: 400);
    if (picked == null) return;

    final api = ApiClient();
    final resp = await api.uploadFile('/user/avatar', picked.path);
    if (resp.ok && mounted) {
      final avatarUrl = resp.data?.toString() ?? '';
      if (avatarUrl.isNotEmpty) {
        context.read<AuthProvider>().updateProfile({'avatar': avatarUrl});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像更新成功')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: ${resp.msg ?? "请重试"}'), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: const Text('将跳转至密码修改页面'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
        ],
      ),
    );
  }

  void _syncData() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('同步成功')));
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导出成功')));
  }

  void _viewReports() {
    Navigator.pushNamed(context, '/reports');
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('注销账户'),
        content: const Text('确定要注销账户吗？此操作不可恢复！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(auth) {
    final avatar = auth.user?.avatar;
    if (avatar != null && avatar.isNotEmpty) {
      final url = avatar.startsWith('http') ? avatar : '${ApiConfig.serverOrigin}$avatar';
      return Image.network(
        url,
        width: 72, height: 72, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: AppTheme.textSecondary),
      );
    }
    return const Center(child: Icon(Icons.person, size: 36, color: AppTheme.textSecondary));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarSheet(),
                    child: Stack(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECF0F1),
                            borderRadius: BorderRadius.circular(36),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildAvatar(auth),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(color: const Color(0x80000000), borderRadius: BorderRadius.circular(10)),
                            child: const Text('换头像', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _nicknameCtrl,
                          focusNode: _nicknameFocus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: '昵称',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _saveNickname(),
                        ),
                      ),
                      const Text('✏', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _goalCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    decoration: const InputDecoration(
                      hintText: '长期目标',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                    onSubmitted: (_) => _saveGoal(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          focusNode: _healthFocus,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          decoration: const InputDecoration(
                            hintText: '身高(cm)',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _saveHealth(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _weightCtrl,
                          focusNode: _weightFocus,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          decoration: const InputDecoration(
                            hintText: '体重(kg)',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _saveHealth(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _healthNoteCtrl,
                    focusNode: _healthNoteFocus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    decoration: const InputDecoration(
                      hintText: '健康备注（血压、睡眠等）',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    onSubmitted: (_) => _saveHealth(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Privacy lock
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🔒 隐私锁', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Switch(
                        value: _lockEnabled || auth.privacyLocked,
                        onChanged: _toggleLock,
                        activeColor: AppTheme.primary,
                      ),
                    ],
                  ),
                  if (_lockEnabled || auth.privacyLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lockPwdCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: _lockExists || auth.privacyLocked ? '修改密码' : '设置密码',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _setLockPwd,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                            child: Text(auth.privacyLocked ? '修改' : '设置'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Account security
          Card(
            child: ListTile(
              title: const Text('🔑 账户安全', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: const Text('修改密码', style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
              onTap: _changePassword,
            ),
          ),
          const SizedBox(height: 10),

          // Data management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💾 数据管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _syncData,
                          child: const Text('同步数据'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _exportData,
                          child: const Text('导出数据'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // AI Report
          Card(
            child: ListTile(
              title: const Text('📊 AI报告', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('查看历史', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
                ],
              ),
              onTap: _viewReports,
            ),
          ),
          const SizedBox(height: 10),

          // Theme
          Card(
            child: ListTile(
              title: const Text('🎨 主题', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              trailing: const Text('浅色', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ),
          ),
          const SizedBox(height: 10),

          // App version
          Card(
            child: ListTile(
              title: const Text('应用版本', style: TextStyle(fontSize: 16)),
              trailing: const Text('1.0.0', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ),
          ),
          const SizedBox(height: 20),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
              child: const Text('退出登录', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),

          // Delete account
          Center(
            child: GestureDetector(
              onTap: _deleteAccount,
              child: const Text('注销账户', style: TextStyle(fontSize: 13, color: Color(0x99E74C3C))),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AvatarOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}
