import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Fixes WidgetRef error
import 'package:sklad_helper_33701/core/theme.dart'; // Fixes SkladColors error
import 'package:sklad_helper_33701/core/providers/navigation_provider.dart'; // Fixes navigationIndexProvider error
import '../../inventory/presentation/inventory_page.dart'; // Import your pages
import '../../settings/presentation/settings_page.dart';

class LoaderDashboard extends ConsumerWidget {
  // Use ConsumerWidget, not StatefulWidget
  const LoaderDashboard({super.key});

  // Define the pages list inside the class so it's not "undefined"
  static const List<Widget> _pages = [InventoryPage(), SettingsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WidgetRef is now valid
    final currentIndex = ref.watch(navigationIndexProvider);
    final proColors = Theme.of(context).extension<SkladColors>()!;

    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        // Use withValues(alpha: ...) as per your rule
        backgroundColor: proColors.surfaceLow,
        indicatorColor: proColors.accentAction.withValues(alpha: 0.2),
        // Pill covering icon and text
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Склад',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
