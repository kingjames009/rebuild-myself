import 'package:flutter/material.dart';
import '../pages/home/home_page.dart';
import '../pages/goal/goal_page.dart';
import '../pages/record/record_page.dart';
import '../pages/stats/stats_page.dart';
import '../pages/settings/settings_page.dart';
import 'theme.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();

  /// Switch the active tab. Call from descendant widgets.
  static void switchTo(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    state?.switchTab(index);
  }

  static const tabs = [
    _TabInfo('首页', Icons.home_outlined, Icons.home),
    _TabInfo('目标', Icons.track_changes_outlined, Icons.track_changes),
    _TabInfo('记录', Icons.edit_note_outlined, Icons.edit_note),
    _TabInfo('数据', Icons.bar_chart_outlined, Icons.bar_chart),
    _TabInfo('我的', Icons.person_outline, Icons.person),
  ];
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  void switchTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomePage(),
          GoalPage(),
          RecordPage(),
          StatsPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: switchTab,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: MainShell.tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon, size: 22),
                  selectedIcon: Icon(t.selIcon, size: 22, color: AppTheme.primary),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final IconData selIcon;
  const _TabInfo(this.label, this.icon, this.selIcon);
}
