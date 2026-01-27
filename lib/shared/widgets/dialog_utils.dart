import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sklad_helper_33701/core/theme.dart';

class DialogUtils {
  // --- MAIN DIALOG FUNCTION ---
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
    Color? accentColorOverride,
  }) async {
    final proColors = Theme.of(context).extension<SkladColors>()!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final accentColor = accentColorOverride ?? proColors.accentAction;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        titlePadding: EdgeInsets.zero,
        title: buildUnifiedHeader(
          icon: icon,
          title: title,
          color: accentColor,
          colors: colors,
          textTheme: textTheme,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            if (showWarning) ...[
              const SizedBox(height: 20),
              _buildWarningBox(proColors, textTheme, warningText),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        actions: [
          Column(
            children: [
              buildDialogAction(
                context: context,
                text: primaryButtonText,
                onTap: onPrimaryTap,
                isPrimary: true,
                color: accentColor,
                colors: colors,
              ),
              if (secondaryButtonText != null) ...[
                const SizedBox(height: 12),
                buildDialogAction(
                  context: context,
                  text: secondaryButtonText,
                  onTap: onSecondaryTap ?? () => Navigator.pop(context),
                  isPrimary: false,
                  colors: colors,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- PUBLIC HELPER 1: HEADER ---
  static Widget buildUnifiedHeader({
    required IconData icon,
    required String title,
    required Color color,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // --- PUBLIC HELPER 2: ACTION BUTTON ---
  static Widget buildDialogAction({
    required BuildContext context,
    required String text,
    required VoidCallback onTap,
    required bool isPrimary,
    required ColorScheme colors,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: isPrimary
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Text(
                text,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            )
          // [STYLE UPDATE] Thin stroke for cancel buttons
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                // Thin stroke as requested
                side: const BorderSide(color: Colors.white12, width: 0.5),
              ),
              onPressed: onTap,
              child: Text(text, style: GoogleFonts.inter()),
            ),
    );
  }

  // --- PRIVATE HELPER: WARNING BOX ---
  static Widget _buildWarningBox(
    SkladColors proColors,
    TextTheme textTheme,
    String? text,
  ) {
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
              text ?? 'Проверьте папку "Спам", если письмо не пришло.',
              style: textTheme.bodySmall?.copyWith(color: proColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
