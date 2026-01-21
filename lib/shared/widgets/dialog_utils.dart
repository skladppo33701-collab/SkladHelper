// lib/shared/widgets/dialog_utils.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sklad_helper_33701/core/theme.dart';

class DialogUtils {
  static Future<void> showSkladDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget content,
    required String primaryButtonText,
    required VoidCallback onPrimaryTap,
    String? secondaryButtonText,
    VoidCallback? onSecondaryTap,
    bool showWarning = false,
    String? warningText,
    Color? accentColorOverride, // optional for success dialogs etc.
  }) async {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final accent = accentColorOverride ?? proColors.accentAction;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: proColors.surfaceLow, // ← FIXED: use theme value
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: buildUnifiedHeader(
          icon: icon,
          title: title,
          accentColor: accent,
          textTheme: textTheme,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              if (showWarning) ...[
                const SizedBox(height: 20),
                _buildWarningBox(
                  text:
                      warningText ??
                      'Если вы не видите письма, обязательно проверьте папку "Спам".',
                  proColors: proColors,
                  textTheme: textTheme,
                ),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: buildDialogAction(
                  text: secondaryButtonText ?? 'Отмена',
                  onTap: onSecondaryTap ?? () => Navigator.pop(context),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildDialogAction(
                  text: primaryButtonText,
                  onTap: onPrimaryTap,
                  isPrimary: true,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildUnifiedHeader({
    required IconData icon,
    required String title,
    required Color accentColor,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        16,
      ), // ↓ reduced top padding from 32→20
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // center vertically
        children: [
          Icon(icon, color: accentColor, size: 36), // slightly smaller icon
          const SizedBox(height: 8), // tight spacing
          Text(
            title,
            style:
                textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ) ??
                TextStyle(
                  color: accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildWarningBox({
    required String text,
    required SkladColors proColors,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: proColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: proColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: proColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(color: proColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDialogAction({
    // ← rename to match what you use
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
    Color? color,
    bool isDestructive = false,
  }) {
    final effectiveColor = isDestructive
        ? Colors.redAccent
        : (color ?? Colors.blueAccent);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: effectiveColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDestructive
                    ? Colors.redAccent
                    : Colors.white70,
                side: BorderSide(
                  color: isDestructive
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : Colors.white12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(text, style: GoogleFonts.inter()),
            ),
    );
  }
}
