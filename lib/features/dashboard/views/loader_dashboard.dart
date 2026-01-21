import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/core/providers/navigation_provider.dart';
import '../../inventory/presentation/inventory_page.dart';
import '../../settings/presentation/settings_page.dart';

class LoaderDashboard extends ConsumerWidget {
  const LoaderDashboard({super.key});

  static const List<Widget> _pages = [InventoryPage(), SettingsPage()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
            }
            return const TextStyle(fontSize: 12);
          }),
        ),
        child: NavigationBar(
          // --- VISIBILITY FIX ---
          // In Light Mode, surfaceLow is Gray, which blends with the background.
          // We use surfaceHigh (White) to make it pop.
          backgroundColor: isDark
              ? proColors.surfaceLow
              : proColors.surfaceHigh,

          // Add shadow to ensure separation from content
          elevation: 10,
          shadowColor: Colors.black26,

          indicatorColor: proColors.accentAction.withValues(alpha: 0.15),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            // --- LOGIC FIX ---
            // Using the new Notifier method ensuring state stability
            ref.read(navigationIndexProvider.notifier).setIndex(index);
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
      ),
    );
  }
}
