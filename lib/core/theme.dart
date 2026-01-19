import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional Color Palette Extension
class SkladColors extends ThemeExtension<SkladColors> {
  final Color accentAction;
  final Color surfaceHigh; // For cards/elevated items
  final Color surfaceLow; // For background depth
  final Color success;
  final Color warning;
  final Color error;

  SkladColors({
    required this.accentAction,
    required this.surfaceHigh,
    required this.surfaceLow,
    required this.success,
    required this.warning,
    required this.error,
  });

  @override
  SkladColors copyWith({Color? accentAction}) => this;

  @override
  SkladColors lerp(ThemeExtension<SkladColors>? other, double t) {
    if (other is! SkladColors) return this;
    return SkladColors(
      accentAction: Color.lerp(accentAction, other.accentAction, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

class AppTheme {
  // Brand Identity Colors
  static const Color proIndigo = Color(0xFF6366F1); // Modern Blue-Purple
  static const Color darkSlate = Color(0xFF0F172A); // Deep Slate Background

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF020617), // Richer "OLED" Black
      primaryColor: proIndigo,

      // Modern Extensions
      extensions: [
        SkladColors(
          accentAction: proIndigo,
          surfaceHigh: const Color(0xFF1E293B), // Navy-Grey for cards
          surfaceLow: const Color(0xFF0F172A),
          success: const Color(0xFF10B981),
          warning: const Color(0xFFF59E0B),
          error: const Color(0xFFEF4444),
        ),
      ],

      colorScheme: ColorScheme.fromSeed(
        seedColor: proIndigo,
        brightness: Brightness.dark,
        primary: proIndigo,
        surface: const Color(0xFF0F172A),
        onSurface: Colors.white,
      ),

      // Professional Typography
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            titleLarge: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            bodyMedium: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),

      // Input Decoration (Clean Samsung/Google Look)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: proIndigo, width: 2),
        ),
      ),

      // Modern Button Style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: proIndigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
    );
  }

  // Light Theme (Apple/Samsung Style)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: proIndigo,
      extensions: [
        SkladColors(
          accentAction: proIndigo,
          surfaceHigh: Colors.white,
          surfaceLow: const Color(0xFFF1F5F9),
          success: const Color(0xFF10B981),
          warning: const Color(0xFFF59E0B),
          error: const Color(0xFFEF4444),
        ),
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: proIndigo,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );
  }
}
