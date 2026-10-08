import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import 'dashboard_screen.dart';
import 'files_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onOpenVault: () => setState(() => _index = 1),
        onOpenActivity: () => setState(() => _index = 2),
      ),
      const FilesScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded, color: AppColors.teal),
              label: 'Tableau',
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded, color: AppColors.teal),
              label: 'Coffre',
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded, color: AppColors.teal),
              label: 'Activité',
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_rounded),
              selectedIcon: Icon(Icons.tune_rounded, color: AppColors.teal),
              label: 'Réglages',
            ),
          ],
        ),
      ),
    );
  }
}
