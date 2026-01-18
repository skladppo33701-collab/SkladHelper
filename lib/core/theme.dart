import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ───────────────── BRAND COLORS ─────────────────
  static const Color brandBlue = Color(0xFF2563EB);

  // Dark palette (SOLID — no opacity)
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1B1D23);
  static const Color darkInput = Color(0xFF2A2D36);

  static const Color textPrimary = Color(0xFFEDEEF0);
  static const Color textSecondary = Color(0xFFB4B7C0);
  static const Color iconColor = Color(0xFFD1D4DC);

  // ───────────────── DARK THEME ─────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,

      // ───────── COLOR SCHEME ─────────
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        brightness: Brightness.dark,
        primary: brandBlue,
        onPrimary: Colors.white,
        secondary: brandBlue,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: textPrimary,
        error: Colors.redAccent,
        onError: Colors.black,
        surfaceTint: Colors.transparent, // Removes purple tint from surfaces
      ),

      // ───────── TYPOGRAPHY ─────────
      textTheme: GoogleFonts.robotoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),

      // ───────────────── TEXT SELECTION (NO PURPLE) ─────────────────
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brandBlue,
        selectionColor: brandBlue.withValues(
          alpha: 0.2,
        ), // Light blue highlight
        selectionHandleColor: brandBlue, // FIXED: The 'drop' handle is now blue
      ),

      // ───────── ICONS (NO BLUR) ─────────
      iconTheme: const IconThemeData(color: iconColor, size: 22),

      // ───────────────── INPUT DECORATION (SINGLE LINE STYLE) ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: false, // Set to false for the clean "line-only" look
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        // Floating label colors
        floatingLabelStyle: const TextStyle(
          color: brandBlue,
          fontWeight: FontWeight.bold,
        ),
        labelStyle: const TextStyle(color: textSecondary),
        // FIXED: Using UnderlineInputBorder for the single line style
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white12, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: brandBlue, width: 2),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white12),
        ),
      ),

      // ───────── BUTTONS ─────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      // ───────── DIALOGS ─────────
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.roboto(
          fontSize: 15,
          color: textSecondary,
        ),
      ),

      // ───────── SWITCHES ─────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : iconColor,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brandBlue.withValues(alpha: 0.4)
              : darkInput,
        ),
      ),

      // ───────── DIVIDERS ─────────
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
      ),
    );
  }
}
