import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Professional Color Palette Extension with more shades for flexibility
class SkladColors extends ThemeExtension<SkladColors> {
  final Color accentAction; // Main interactive color (buttons, links)
  final Color accentSecondary; // Subtle variant for highlights
  final Color surfaceHigh; // Elevated surfaces (cards, dialogs)
  final Color surfaceLow; // Backgrounds (scaffold, sheets)
  final Color neutralGray; // Subtle text, dividers, icons
  final Color onAccent; // Text on accent color
  final Color success; // Positive feedback
  final Color warning; // Caution feedback
  final Color error;

  // --- ADDED MISSING COLORS ---
  final Color contentPrimary; // Main text color (Titles, strong text)
  final Color contentSecondary; // Secondary text color (Subtitles, hints)

  SkladColors({
    required this.accentAction,
    required this.accentSecondary,
    required this.surfaceHigh,
    required this.surfaceLow,
    required this.neutralGray,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.contentPrimary,
    required this.contentSecondary,
  });

  @override
  SkladColors copyWith({
    Color? accentAction,
    Color? accentSecondary,
    Color? surfaceHigh,
    Color? surfaceLow,
    Color? neutralGray,
    Color? onAccent,
    Color? success,
    Color? warning,
    Color? error,
    Color? contentPrimary,
    Color? contentSecondary,
  }) {
    return SkladColors(
      accentAction: accentAction ?? this.accentAction,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      neutralGray: neutralGray ?? this.neutralGray,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      contentPrimary: contentPrimary ?? this.contentPrimary,
      contentSecondary: contentSecondary ?? this.contentSecondary,
    );
  }

  @override
  SkladColors lerp(ThemeExtension<SkladColors>? other, double t) {
    if (other is! SkladColors) return this;
    return SkladColors(
      accentAction: Color.lerp(accentAction, other.accentAction, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      neutralGray: Color.lerp(neutralGray, other.neutralGray, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      contentPrimary: Color.lerp(contentPrimary, other.contentPrimary, t)!,
      contentSecondary: Color.lerp(
        contentSecondary,
        other.contentSecondary,
        t,
      )!,
    );
  }
}

/// Global theme constants
const proIndigo = Color(0xFF6366F1);

class SkladTheme {
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F1A),
      primaryColor: proIndigo,
      extensions: <ThemeExtension<dynamic>>[
        SkladColors(
          accentAction: proIndigo,
          accentSecondary: proIndigo.withValues(alpha: 0.6),
          surfaceHigh: const Color(0xFF1F2937),
          surfaceLow: const Color(0xFF111827),
          neutralGray: const Color(0xFF6B7280),
          onAccent: Colors.white,
          success: const Color(0xFF10B981),
          warning: const Color(0xFFF59E0B),
          error: const Color(0xFFEF4444),
          // --- DEFINED DARK TEXT COLORS ---
          contentPrimary: Colors.white,
          contentSecondary: Colors.white.withValues(alpha: 0.7),
        ),
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: proIndigo,
        brightness: Brightness.dark,
        surface: const Color(0xFF1F2937),
        onSurface: Colors.white70,
        error: const Color(0xFFEF4444),
      ).copyWith(secondary: const Color(0xFF6B7280)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0F1A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: proIndigo,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: proIndigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: proIndigo,
          side: BorderSide(color: proIndigo.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6B7280), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: proIndigo, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.white60),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF6B7280),
        thickness: 0.5,
        space: 16,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            bodyMedium: const TextStyle(color: Colors.white70),
            labelMedium: const TextStyle(color: Colors.white60),
          ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: proIndigo,
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: const Color(0xFFF3F4F6),
        indicatorColor: proIndigo.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: proIndigo,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(color: Colors.black54, fontSize: 12);
        }),
      ),
      extensions: <ThemeExtension<dynamic>>[
        SkladColors(
          accentAction: proIndigo,
          accentSecondary: proIndigo.withValues(alpha: 0.6),
          surfaceHigh: Colors.white,
          surfaceLow: const Color(0xFFF1F5F9),
          neutralGray: const Color(0xFF6B7280),
          onAccent: Colors.black87,
          success: const Color(0xFF10B981),
          warning: const Color(0xFFF59E0B),
          error: const Color(0xFFEF4444),
          // --- DEFINED LIGHT TEXT COLORS ---
          contentPrimary: const Color(0xFF0F172A), // Slate 900
          contentSecondary: const Color(0xFF64748B), // Slate 500
        ),
      ],
      colorScheme: ColorScheme.fromSeed(
        seedColor: proIndigo,
        brightness: Brightness.light,
        surface: Colors.white,
      ).copyWith(secondary: const Color(0xFF6B7280)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black87,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: proIndigo,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: proIndigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: proIndigo,
          side: BorderSide(color: proIndigo.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6B7280), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: proIndigo, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF6B7280),
        thickness: 0.5,
        space: 16,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
          .copyWith(
            bodyMedium: const TextStyle(color: Colors.black54),
            labelMedium: const TextStyle(color: Colors.black45),
          ),
      iconTheme: const IconThemeData(color: Colors.black54),
    );
  }
}
