import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/bot_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/inventory_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/planner_page.dart';
import 'package:sklad_helper_33701/features/settings/presentation/settings_page.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InventoryPage(),
    const PlannerPage(),
    const BotPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Start listening for role changes immediately
    _listenToRoleChanges();
  }

  void _listenToRoleChanges() {
    // 1. Get current user safely
    final userState = ref.read(authStateProvider);
    final user = userState.value;

    if (user == null) return;

    // 2. Listen to Firestore document changes
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final role = snapshot.data()?['role'];

            // 3. Security Check: If not a manager anymore, invalidate auth
            if (role != 'manager') {
              ref.invalidate(authStateProvider);
              // This will trigger the main.dart AuthGate to redirect them
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(splashFactory: NoSplash.splashFactory),
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _screens[_currentIndex],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: proColors.surfaceLow,
            indicatorColor: proColors.accentAction.withValues(alpha: 0.1),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          child: NavigationBar(
            height: 70,
            elevation: 0,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: [
              _buildCustomItem(
                0,
                Icons.inventory_2_outlined,
                Icons.inventory_2,
                'Склад',
                proColors,
              ),
              _buildCustomItem(
                1,
                Icons.calendar_today_outlined,
                Icons.calendar_today,
                'Планнер',
                proColors,
              ),
              _buildCustomItem(
                2,
                Icons.smart_toy_outlined,
                Icons.smart_toy,
                'Бот',
                proColors,
              ),
              _buildCustomItem(
                3,
                Icons.settings_outlined,
                Icons.settings,
                'Настройки',
                proColors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    SkladColors proColors,
  ) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
      selectedIcon: Icon(selectedIcon, color: proColors.accentAction),
      label: label,
    );
  }
}
