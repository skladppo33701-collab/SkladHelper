import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui';

// Absolute Imports
import 'package:sklad_helper_33701/firebase_options.dart';
import 'package:sklad_helper_33701/core/theme.dart';
import 'package:sklad_helper_33701/core/providers/theme_provider.dart';
import 'package:sklad_helper_33701/core/providers/navigation_provider.dart';
import 'package:sklad_helper_33701/features/auth/providers/auth_provider.dart';
import 'package:sklad_helper_33701/features/auth/views/login_screen.dart';

// Page Imports
import 'package:sklad_helper_33701/features/inventory/presentation/inventory_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/planner_page.dart';
import 'package:sklad_helper_33701/features/inventory/presentation/bot_page.dart';
import 'package:sklad_helper_33701/features/pickup/presentation/pickup_page.dart';
import 'package:sklad_helper_33701/features/settings/presentation/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for the Russian locale used in the app
  await initializeDateFormatting('ru', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: SkladApp()));
}

class SkladApp extends ConsumerWidget {
  const SkladApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return MaterialApp(
      title: 'Sklad Helper Pro',
      debugShowCheckedModeBanner: false,
      theme: SkladTheme.lightTheme,
      darkTheme: SkladTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        // Dynamic System UI Overlay based on the current theme
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            // FIX 1: Set solid color to remove gray bar
            systemNavigationBarColor: isDark
                ? const Color(0xFF0F172A)
                : Colors.white,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) =>
          user != null ? const RootNavigationShell() : const LoginScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, stack) => const LoginScreen(),
    );
  }
}

class RootNavigationShell extends ConsumerWidget {
  const RootNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final colors = Theme.of(context).extension<SkladColors>()!;

    final List<Widget> pages = [
      const InventoryPage(), // 0: Resources
      const BotPage(), // 1: AI Telegram Bot
      const PickUpPage(), // 2: Logistics
      const PlannerPage(), // 3: Strategy
      const SettingsPage(), // 4: Profile
    ];

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: _SovereignDock(
        currentIndex: currentIndex,
        onTap: (index) {
          HapticFeedback.mediumImpact();
          ref.read(navigationIndexProvider.notifier).setIndex(index);
        },
      ),
    );
  }
}

class _SovereignDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SovereignDock({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SkladColors>()!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      // Padding ensures the dock stays "floating" above the system navigation area
      // but the Scaffold's body will now respect this height.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomPadding > 0 ? bottomPadding : 16,
      ),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: colors.surfaceHigh.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DockItem(
                  Icons.inventory_2_outlined,
                  Icons.inventory_2,
                  "Склад",
                  0,
                  currentIndex,
                  onTap,
                ),
                _DockItem(
                  Icons.smart_toy_outlined,
                  Icons.smart_toy,
                  "TG бот",
                  1,
                  currentIndex,
                  onTap,
                ),
                _DockItem(
                  Icons.local_shipping_outlined,
                  Icons.local_shipping,
                  "Выдача",
                  2,
                  currentIndex,
                  onTap,
                ),
                _DockItem(
                  Icons.calendar_today_outlined,
                  Icons.calendar_today,
                  "План",
                  3,
                  currentIndex,
                  onTap,
                ),
                _DockItem(
                  Icons.person_outline,
                  Icons.person,
                  "Профиль",
                  4,
                  currentIndex,
                  onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DockItem(
    this.icon,
    this.activeIcon,
    this.label,
    this.index,
    this.currentIndex,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final colors = Theme.of(context).extension<SkladColors>()!;

    // FIX 2: Expanded is now the PARENT of GestureDetector
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? colors.accentAction.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? colors.accentAction : colors.contentTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? colors.accentAction : colors.contentTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
