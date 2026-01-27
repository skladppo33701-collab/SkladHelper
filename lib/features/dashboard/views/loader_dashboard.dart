import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Core & Theme
import '../../../../core/theme.dart';
import '../../../../core/constants/dimens.dart';

// Pages
import '../../inventory/presentation/inventory_page.dart';
import '../../settings/presentation/settings_page.dart';

class LoaderDashboard extends ConsumerStatefulWidget {
  const LoaderDashboard({super.key});

  @override
  ConsumerState<LoaderDashboard> createState() => _LoaderDashboardState();
}

class _LoaderDashboardState extends ConsumerState<LoaderDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const InventoryPage(), const SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: IndexedStack(index: _currentIndex, children: _pages),
      // [PROTOCOL-VISUAL-1] Using the Sovereign Floating Dock style
      bottomNavigationBar: _LoaderSovereignDock(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.mediumImpact();
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _LoaderSovereignDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LoaderSovereignDock({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimens.gapL, // 16
        0,
        Dimens.gapL, // 16
        bottomPadding > 0 ? bottomPadding : Dimens.gapL, // 16
      ),
      child: Container(
        // [PROTOCOL-VISUAL-2] Reflow Hardening: Removed fixed height: 74
        constraints: const BoxConstraints(minHeight: 74),
        decoration: BoxDecoration(
          color: colors.surfaceHigh.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(Dimens.radiusXl), // 24
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
          borderRadius: BorderRadius.circular(Dimens.radiusXl), // 24
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LoaderDockItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    label: "Склад",
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _LoaderDockItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: "Настройки",
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoaderDockItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LoaderDockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimens.gapS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(Dimens.gapS), // 8
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.accentAction.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(Dimens.radiusM), // 12
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? colors.accentAction
                      : colors.contentTertiary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? colors.accentAction
                        : colors.contentTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
