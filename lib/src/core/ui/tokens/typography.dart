import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Typography tokens for the Calm Clinical Command Center.
///
/// Cairo carries Arabic UI text. Figures use tabular numerals so amounts and
/// counters never shift width while data refreshes.
class AppTypography {
  AppTypography._();

  // Display & headings
  static const double displayLgSize = 32;
  static const double displayMdSize = 26;
  static const double headingLgSize = 22;
  static const double headingMdSize = 18;
  static const double headingSmSize = 16;

  // Body & detail
  static const double bodyLgSize = 15;
  static const double bodyMdSize = 14;
  static const double bodySmSize = 13;
  static const double captionSize = 12;
  static const double overlineSize = 11;

  // Numeric
  static const double numericLgSize = 28;
  static const double numericMdSize = 18;

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // Direct minimal builders
  static TextStyle h1(Color c) =>
      _cairo(24, FontWeight.w700, c, height: 1.25);
  static TextStyle h2(Color c) =>
      _cairo(20, FontWeight.w700, c, height: 1.3);
  static TextStyle h3(Color c) =>
      _cairo(16, FontWeight.w600, c, height: 1.35);
  static TextStyle body(Color c) =>
      _cairo(14, FontWeight.w400, c, height: 1.5);
  static TextStyle caption(Color c) =>
      _cairo(12, FontWeight.w500, c, height: 1.4);
  static TextStyle mono(Color c) =>
      _mono(16, FontWeight.w700, c, height: 1.2);

  // Scaled builders
  static TextStyle displayLg(Color color) =>
      _cairo(displayLgSize, FontWeight.w800, color, height: 1.2);
  static TextStyle displayMd(Color color) =>
      _cairo(displayMdSize, FontWeight.w800, color, height: 1.25);
  static TextStyle headingLg(Color color) =>
      _cairo(headingLgSize, FontWeight.w700, color, height: 1.3);
  static TextStyle headingMd(Color color) =>
      _cairo(headingMdSize, FontWeight.w700, color, height: 1.35);
  static TextStyle headingSm(Color color) =>
      _cairo(headingSmSize, FontWeight.w700, color, height: 1.4);
  static TextStyle bodyLg(Color color) =>
      _cairo(bodyLgSize, FontWeight.w400, color, height: 1.6);
  static TextStyle bodyMd(Color color) =>
      _cairo(bodyMdSize, FontWeight.w400, color, height: 1.55);
  static TextStyle bodySm(Color color) =>
      _cairo(bodySmSize, FontWeight.w500, color, height: 1.5);
  static TextStyle overline(Color color) => _cairo(
        overlineSize,
        FontWeight.w700,
        color,
        height: 1.3,
        letterSpacing: 0.4,
      );

  /// Money, counters, IDs. Tabular so digits hold their column.
  static TextStyle numericLg(Color color) =>
      _mono(numericLgSize, FontWeight.w800, color, height: 1.1);
  static TextStyle numericMd(Color color) =>
      _mono(numericMdSize, FontWeight.w700, color, height: 1.2);
  static TextStyle numericSm(Color color) =>
      _mono(12, FontWeight.w700, color, height: 1.3);

  static TextStyle _cairo(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle _mono(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: _tabular,
      );

  static final TextTheme light = _build(Brightness.light);
  static final TextTheme dark = _build(Brightness.dark);

  static TextTheme _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final t1 =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final t2 =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final t3 = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return TextTheme(
      displayLarge: displayLg(t1),
      displayMedium: displayMd(t1),
      displaySmall: headingLg(t1),
      headlineLarge: displayMd(t1),
      headlineMedium: headingLg(t1),
      headlineSmall: headingMd(t1),
      titleLarge: headingMd(t1),
      titleMedium: headingSm(t1),
      titleSmall: _cairo(14, FontWeight.w700, t1, height: 1.4),
      bodyLarge: bodyLg(t1),
      bodyMedium: bodyMd(t1),
      bodySmall: bodySm(t2),
      labelLarge: _cairo(14, FontWeight.w700, t1, height: 1.2),
      labelMedium: _cairo(12, FontWeight.w600, t2, height: 1.3),
      labelSmall: _cairo(11, FontWeight.w500, t3, height: 1.3),
    );
  }
}
