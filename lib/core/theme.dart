import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/dimens.dart';

// -----------------------------------------------------------------------------
// 1. PALETTE DEFINITION (Private)
// Professional "Slate & Indigo" System
// -----------------------------------------------------------------------------
abstract class _Palette {
  // Brand Colors (Indigo)
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);

  // Status Colors (Emerald, Amber, Rose)
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);

  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  static const Color rose500 = Color(0xFFEF4444);
  static const Color rose600 = Color(0xFFDC2626);

  // Neutral Slate (Light)
  static const Color slate50 = Color(0xFFF8FAFC); // Background
  static const Color slate100 = Color(0xFFF1F5F9); // Surface Container
  static const Color slate200 = Color(0xFFE2E8F0); // Dividers

  // Neutral Slate (Dark/Text)
  static const Color slate300 = Color(0xFFCBD5E1); // Secondary Text (Dark)
  static const Color slate400 = Color(0xFF94A3B8); // Tertiary Text
  static const Color slate500 = Color(0xFF64748B); // Neutral Icons
  static const Color slate600 = Color(0xFF475569); // Secondary Text (Light)

  // Slate 700 removed (unused)

  static const Color slate800 = Color(0xFF1E293B); // Surface (Dark Mode)
  static const Color slate900 = Color(
    0xFF0F172A,
  ); // Card (Dark Mode) / Text (Light)
  static const Color slate950 = Color(0xFF020617); // Background (Dark Mode)

  static const Color white = Color(0xFFFFFFFF);
}

// -----------------------------------------------------------------------------
// 2. SPACINGS EXTENSION (Restored for [PROTOCOL-VISUAL-1])
// -----------------------------------------------------------------------------
@immutable
class SkladSpacings extends ThemeExtension<SkladSpacings> {
  final double xs;
  final double s;
  final double m;
  final double l;
  final double module;
  final double xl;
  final double xxl;

  const SkladSpacings({
    required this.xs,
    required this.s,
    required this.m,
    required this.l,
    required this.module,
    required this.xl,
    required this.xxl,
  });

  factory SkladSpacings.regular() => const SkladSpacings(
    xs: Dimens.gapXs,
    s: Dimens.gapS,
    m: Dimens.gapM,
    l: Dimens.gapL,
    module: Dimens.module,
    xl: Dimens.gapXl,
    xxl: Dimens.gap2xl,
  );

  @override
  SkladSpacings copyWith({
    double? xs,
    double? s,
    double? m,
    double? l,
    double? module,
    double? xl,
    double? xxl,
  }) {
    return SkladSpacings(
      xs: xs ?? this.xs,
      s: s ?? this.s,
      m: m ?? this.m,
      l: l ?? this.l,
      module: module ?? this.module,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  SkladSpacings lerp(ThemeExtension<SkladSpacings>? other, double t) {
    if (other is! SkladSpacings) return this;
    return SkladSpacings(
      xs: other.xs,
      s: other.s,
      m: other.m,
      l: other.l,
      module: other.module,
      xl: other.xl,
      xxl: other.xxl,
    );
  }
}

// -----------------------------------------------------------------------------
// 3. THEME EXTENSION (Public)
// Compatible with existing code usage (colors.surfaceLow, etc.)
// -----------------------------------------------------------------------------
@immutable
class SkladColors extends ThemeExtension<SkladColors> {
  // Backgrounds
  final Color surfaceLow; // Main Scaffold background
  final Color surfaceHigh; // Cards, Sheets, Modals
  final Color surfaceContainer; // Grouped settings, secondary areas

  // Text / Content
  final Color contentPrimary; // Headings, main inputs
  final Color contentSecondary; // Subtitles, descriptions
  final Color contentTertiary; // Timestamps, hints
  final Color neutralGray; // Icons, neutral elements

  // Actions & Borders
  final Color accentAction; // Buttons, active states
  final Color divider; // Borders, separators

  // Semantic
  final Color success;
  final Color warning;
  final Color error;

  const SkladColors({
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.surfaceContainer,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.neutralGray,
    required this.accentAction,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
  });

  // --- COMPATIBILITY LAYER (Fixes errors in other files) ---
  // Maps old Sovereign/Legacy names to new Sklad names
  Color get surface => surfaceHigh;
  Color get surfaceSubtle => surfaceLow;
  Color get border => divider;
  Color get borderSubtle => divider.withValues(alpha: 0.5);
  Color get textPrimary => contentPrimary;
  Color get textSecondary => contentSecondary;
  Color get textTertiary => contentTertiary;
  Color get accent => accentAction;
  Color get accentGlow => accentAction.withValues(alpha: 0.15);
  Color get cardGlass => surfaceHigh.withValues(alpha: 0.9);
  // ---------------------------------------------------------

  @override
  SkladColors copyWith({
    Color? surfaceLow,
    Color? surfaceHigh,
    Color? surfaceContainer,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? contentTertiary,
    Color? neutralGray,
    Color? accentAction,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return SkladColors(
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      contentPrimary: contentPrimary ?? this.contentPrimary,
      contentSecondary: contentSecondary ?? this.contentSecondary,
      contentTertiary: contentTertiary ?? this.contentTertiary,
      neutralGray: neutralGray ?? this.neutralGray,
      accentAction: accentAction ?? this.accentAction,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  SkladColors lerp(ThemeExtension<SkladColors>? other, double t) {
    if (other is! SkladColors) return this;
    return SkladColors(
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      contentPrimary: Color.lerp(contentPrimary, other.contentPrimary, t)!,
      contentSecondary: Color.lerp(
        contentSecondary,
        other.contentSecondary,
        t,
      )!,
      contentTertiary: Color.lerp(contentTertiary, other.contentTertiary, t)!,
      neutralGray: Color.lerp(neutralGray, other.neutralGray, t)!,
      accentAction: Color.lerp(accentAction, other.accentAction, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

// -----------------------------------------------------------------------------
// 4. UTILS (Public)
// -----------------------------------------------------------------------------
extension SkladThemeUtils on BuildContext {
  SkladColors get colors => Theme.of(this).extension<SkladColors>()!;
  SkladSpacings get spacings => Theme.of(this).extension<SkladSpacings>()!;
  ThemeData get theme => Theme.of(this);
  TextTheme get typography => Theme.of(this).textTheme;
}

// -----------------------------------------------------------------------------
// 5. THEME FACTORY (Public)
// -----------------------------------------------------------------------------
class SkladTheme {
  // --- LIGHT MODE ---
  static ThemeData get lightTheme {
    const colors = SkladColors(
      surfaceLow: _Palette.slate50,
      surfaceHigh: _Palette.white,
      surfaceContainer: _Palette.slate100,

      contentPrimary: _Palette.slate900,
      contentSecondary: _Palette.slate600,
      contentTertiary: _Palette.slate400,
      neutralGray: _Palette.slate500,

      accentAction: _Palette.indigo600,
      divider: _Palette.slate200,

      success: _Palette.emerald600,
      warning: _Palette.amber600,
      error: _Palette.rose600,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.surfaceLow,
      primaryColor: colors.accentAction,
      extensions: [
        colors,
        SkladSpacings.regular(), // [PROTOCOL-VISUAL-1] Spacings Injected
      ],

      // Material 3 Mappings
      colorScheme: ColorScheme.light(
        primary: colors.accentAction,
        surface: colors.surfaceHigh,
        error: colors.error,
        onSurface: colors.contentPrimary,
        // Mapping container roles
        surfaceContainerLowest: _Palette.white,
        surfaceContainerLow: _Palette.slate50,
        surfaceContainer: _Palette.slate100,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceLow,
        foregroundColor: colors.contentPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.contentPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }

  // --- DARK MODE ---
  static ThemeData get darkTheme {
    const colors = SkladColors(
      surfaceLow: _Palette.slate950,
      surfaceHigh: _Palette.slate900,
      surfaceContainer: _Palette.slate800,

      contentPrimary: _Palette.white,
      contentSecondary: _Palette.slate300,
      contentTertiary: _Palette.slate500,
      neutralGray: _Palette.slate400,

      accentAction: _Palette.indigo500, // Slightly lighter for contrast
      divider: _Palette.slate800,

      success: _Palette.emerald500,
      warning: _Palette.amber500,
      error: _Palette.rose500,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.surfaceLow,
      primaryColor: colors.accentAction,
      extensions: [
        colors,
        SkladSpacings.regular(), // [PROTOCOL-VISUAL-1] Spacings Injected
      ],

      // Material 3 Mappings
      colorScheme: ColorScheme.dark(
        primary: colors.accentAction,
        surface: colors.surfaceHigh,
        error: colors.error,
        onSurface: colors.contentPrimary,

        surfaceContainerLowest: _Palette.slate950,
        surfaceContainerLow: _Palette.slate900,
        surfaceContainer: _Palette.slate800,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceLow,
        foregroundColor: colors.contentPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colors.contentPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}
