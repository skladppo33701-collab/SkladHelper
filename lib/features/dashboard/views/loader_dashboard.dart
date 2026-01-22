import 'package:flutter/material.dart';
import '../../inventory/presentation/inventory_page.dart'; // Correct relative import
import '../../settings/presentation/settings_page.dart';

class LoaderDashboard extends StatefulWidget {
  const LoaderDashboard({super.key});

  @override
  State<LoaderDashboard> createState() => _LoaderDashboardState();
}

class _LoaderDashboardState extends State<LoaderDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const InventoryPage(), const SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Склад',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
