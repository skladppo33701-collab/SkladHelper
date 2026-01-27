import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Core
import '../../../../core/theme.dart';
import '../../../../core/constants/dimens.dart';

// Note: Ensure you have added this new folder structure to your project if it doesn't exist.
// Ideally, update your routing to point to this new location.

class BotPage extends ConsumerWidget {
  const BotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [PROTOCOL-VISUAL-1] Theme & Dimens access
    final colors = context.colors;
    // Removed unused spacings variable

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. STANDARD SOVEREIGN APP BAR
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: colors.surfaceLow.withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Ассистент',
              style: GoogleFonts.inter(
                color: colors.contentPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),

          // 2. CONTENT
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.gapXl,
              ), // 24
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container with Glow Effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colors.surfaceHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF24A1DE,
                          ).withValues(alpha: 0.2), // Telegram Brand Color Glow
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons
                            .telegram, // Keeping standard icon for brand recognition
                        size: 64,
                        color: const Color(
                          0xFF24A1DE,
                        ), // Official Telegram Blue
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimens.module), // 20

                  Text(
                    'TG-Бот',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: colors.contentPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: Dimens.gapM), // 12

                  Text(
                    'Telegram-бот находится в стадии разработки.\nСкоро здесь появится управление уведомлениями и статусами заказов.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colors.contentSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: Dimens.gap2xl), // 32
                  // Call to Action (Dummy for now)
                  FilledButton.icon(
                    onPressed: () {
                      // Example action: Open a link or show a "Coming Soon" toast
                      _launchUrl('https://t.me/');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF24A1DE), // Telegram Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.gapXl, // 24
                        vertical: Dimens.gapL, // 16
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimens.radiusL,
                        ), // 16
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    label: Text(
                      'Открыть Telegram',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
