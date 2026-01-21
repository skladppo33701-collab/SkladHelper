import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/bot_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/inventory_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/planner_page.dart';
import 'package:sklad_helper_33701/features/settings/presentation/settings_page.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/core/providers/navigation_provider.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
  final List<Widget> _screens = [
    const InventoryPage(),
    const PlannerPage(),
    const BotPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToRoleChanges();
  }

  void _listenToRoleChanges() {
    final userState = ref.read(authStateProvider);
    final user = userState.value;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            if (snapshot.data()?['role'] != 'manager') {
              ref.invalidate(authStateProvider);
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(splashFactory: NoSplash.splashFactory),
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _screens[currentIndex],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            // 1. Hide default labels so we can render our own inside the container
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            // 2. Hide default indicator so we can build a custom one
            indicatorColor: Colors.transparent,
          ),
          child: NavigationBar(
            height: 70,
            elevation: 10,
            shadowColor: Colors.black26,

            // Dark Mode: Dark Slate (Visible against black). Light Mode: White.
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : proColors.surfaceHigh,

            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              ref.read(navigationIndexProvider.notifier).setIndex(index);
            },
            destinations: [
              _buildCustomItem(
                0,
                Icons.inventory_2_outlined,
                Icons.inventory_2,
                'Склад',
                proColors,
                isDark,
              ),
              _buildCustomItem(
                1,
                Icons.calendar_today_outlined,
                Icons.calendar_today,
                'Планнер',
                proColors,
                isDark,
              ),
              _buildCustomItem(
                2,
                Icons.smart_toy_outlined,
                Icons.smart_toy,
                'Бот',
                proColors,
                isDark,
              ),
              _buildCustomItem(
                3,
                Icons.settings_outlined,
                Icons.settings,
                'Настройки',
                proColors,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildCustomItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
    SkladColors proColors,
    bool isDark,
  ) {
    // Small text style
    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );

    return NavigationDestination(
      label: '', // Hidden via Theme, but kept empty here to be safe
      // 3. UNSELECTED STATE (No Background)
      icon: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textStyle.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),

      // 4. SELECTED STATE (Custom Container Background covering EVERYTHING)
      selectedIcon: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          // This is your "Indicator" color
          color: proColors.accentAction.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selectedIcon, size: 22, color: proColors.accentAction),
            const SizedBox(height: 4),
            Text(
              label,
              style: textStyle.copyWith(color: proColors.accentAction),
            ),
          ],
        ),
      ),
    );
  }
}
