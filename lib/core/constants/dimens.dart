// [PROTOCOL-VISUAL-1] Sovereign Grid System
// Compliant with Dart lints (lowerCamelCase)

abstract class Dimens {
  // ===========================================================================
  // ATOMIC BASELINE (4px)
  // ===========================================================================
  static const double base = 4.0;

  // ===========================================================================
  // SPACING & GAPS
  // ===========================================================================

  /// 4.0 - Micro spacing (text to icon, tight groups)
  static const double gapXs = base;

  /// 8.0 - Small spacing (related items, buttons)
  static const double gapS = base * 2;

  /// 12.0 - Regular spacing (card internal rhythm)
  static const double gapM = base * 3;

  /// 16.0 - Large spacing (standard list padding)
  static const double gapL = base * 4;

  /// 20.0 - **THE SOVEREIGN MODULE** (Section breaks, Major Grid)
  static const double module = base * 5;

  /// 24.0 - Extra Large (Separating distinct logical blocks)
  static const double gapXl = base * 6;

  /// 32.0 - 2x Large (Major section dividers)
  static const double gap2xl = base * 8;

  /// 40.0 - 2x Module (Hero sections, bottom safe areas)
  static const double gap3xl = base * 10;

  // ===========================================================================
  // PADDINGS
  // ===========================================================================

  /// 16.0 - Standard horizontal screen padding
  static const double paddingScreenH = gapL;

  /// 20.0 - Standard vertical screen padding (matching the Module)
  static const double paddingScreenV = module;

  /// 16.0 - Standard card internal padding
  static const double paddingCard = gapL;

  /// 12.0 - Compact card padding
  static const double paddingCardCompact = gapM;

  // ===========================================================================
  // RADII
  // ===========================================================================

  /// 8.0 - Small controls, checkboxes
  static const double radiusS = base * 2;

  /// 12.0 - Buttons, Inputs
  static const double radiusM = base * 3;

  /// 16.0 - Cards, Dialogs
  static const double radiusL = base * 4;

  /// 24.0 - Large Surfaces, Sheets
  static const double radiusXl = base * 6;

  /// 999.0 - Pill shapes
  static const double radiusFull = 999.0;
}
