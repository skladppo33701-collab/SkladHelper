import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Page Imports
import 'package:sklad_helper_33701/features/bot/bot/presentation/bot_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/inventory_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/planner_page.dart';
import 'package:sklad_helper_33701/features/settings/presentation/settings_page.dart';

// Providers
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/core/providers/navigation_provider.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
  // Define the screens exactly matching the main.dart navigation order
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
        .listen((snapshot) async {
          if (snapshot.exists && mounted) {
            // Check if the role is no longer 'manager'
            if (snapshot.data()?['role'] != 'manager') {
              // 1. Sign out safely
              await FirebaseAuth.instance.signOut();

              // 2. Reset the state in the app
              ref.invalidate(authStateProvider);
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      // Navigation is handled exclusively by RootNavigationShell in main.dart
      // This prevents the double-navigation bar "Gray Area" bug.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[currentIndex],
      ),
    );
  }
}
