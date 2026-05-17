import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/shell.dart';
import 'providers/auth_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/record_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/study_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/elite_provider.dart';
import 'providers/sideline_provider.dart';
import 'providers/leisure_provider.dart';
import 'providers/intervene_provider.dart';
import 'providers/empty_mood_provider.dart';
import 'providers/report_provider.dart';
import 'providers/aspiration_provider.dart';
import 'providers/focus_timer_provider.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/privacy_lock_page.dart';
import 'services/api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => RecordProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => EliteProvider()),
        ChangeNotifierProvider(create: (_) => SidelineProvider()),
        ChangeNotifierProvider(create: (_) => LeisureProvider()),
        ChangeNotifierProvider(create: (_) => InterveneProvider()),
        ChangeNotifierProvider(create: (_) => EmptyMoodProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => AspirationProvider()),
        ChangeNotifierProvider(create: (_) => FocusTimerProvider()),
      ],
      child: MaterialApp(
        title: '精进｜全维度人生重塑',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
        routes: appRoutes,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    ApiClient().onUnauthorized = () {
      context.read<AuthProvider>().logout();
    };
    _init();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().init();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        if (!auth.isLoggedIn) return const LoginPage();
        if (auth.privacyLocked) return const PrivacyLockPage();
        return const MainShell();
      },
    );
  }
}
