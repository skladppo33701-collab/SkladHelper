import 'package:flutter/material.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/bot_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/inventory_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/planner_page.dart';
import 'package:sklad_helper_33701/features/settings/presentation/settings_page.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;

  // Ensure these match the Class names in inventory_page.dart, planner_page.dart, etc.
  final List<Widget> _screens = [
    const InventoryPage(),
    const PlannerPage(),
    const BotPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      // We wrap the dashboard in a theme that kills the splash/ripple globally for this screen
      data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            indicatorColor: Colors.transparent,
            // Removes the hover/focus/pressed highlight colors
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: NavigationBar(
            height: 85,
            backgroundColor: const Color(0xFF111827),
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              _buildCustomItem(
                0,
                Icons.inventory_2_outlined,
                Icons.inventory_2,
                'Каталог',
              ),
              _buildCustomItem(
                1,
                Icons.assignment_outlined,
                Icons.assignment,
                'Задачи',
              ),
              _buildCustomItem(
                2,
                Icons.smart_toy_outlined,
                Icons.smart_toy,
                'TG-Бот',
              ),
              _buildCustomItem(
                3,
                Icons.settings_outlined,
                Icons.settings,
                'Настройки',
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
  ) {
    // Removed isSelected variable to fix the "unused variable" warning
    return NavigationDestination(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
      selectedIcon: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selectedIcon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      label: '',
    );
  }
}
