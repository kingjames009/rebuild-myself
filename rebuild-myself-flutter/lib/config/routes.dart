import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/privacy_lock_page.dart';
import '../pages/intervene/intervene_page.dart';
import '../pages/finance/finance_page.dart';
import '../pages/study/study_page.dart';
import '../pages/sideline/sideline_page.dart';
import '../pages/reading/reading_page.dart';
import '../pages/leisure/leisure_page.dart';
import '../pages/leisure/empty_mood_page.dart';
import '../pages/elite/elite_page.dart';
import '../pages/report/report_page.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginPage(),
  '/register': (_) => const RegisterPage(),
  '/privacy-lock': (_) => const PrivacyLockPage(),
  '/intervene': (_) => const IntervenePage(),
  '/finance': (_) => const FinancePage(),
  '/study': (_) => const StudyPage(),
  '/sideline': (_) => const SidelinePage(),
  '/reading': (_) => const ReadingPage(),
  '/leisure': (_) => const LeisurePage(),
  '/empty-mood': (_) => const EmptyMoodPage(),
  '/elite': (_) => const ElitePage(),
  '/reports': (_) => const ReportPage(),
};
