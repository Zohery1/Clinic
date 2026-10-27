import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Typography tokens. Cairo for UI + JetBrains Mono for numbers / IDs.
/// Exposes a complete `TextTheme` for light + dark so it can plug straight
/// into `ThemeData.textTheme`.
class AppTypography {
  AppTypography._();

  // Display & Headings
  static const double displayLgSize = 32;
  static const double displayMdSize = 26;
  static const double headingLgSize = 22;
  static const double headingMdSize = 18;
  static const double headingSmSize = 16;

  // Body
  static const double bodyLgSize = 15;
  static const double bodyMdSize = 14;
  static const double bodySmSize = 13;
  static const double captionSize = 12;
  static const double overlineSize = 11;

  // Numeric (mono)
  static const double numericLgSize = 28;
  static const double numericMdSize = 18;

  // Generic builders
  static TextStyle displayLg(Color color) => _cairo(displayLgSize, FontWeight.w800, color, height: 1.2);
  static TextStyle displayMd(Color color) => _cairo(displayMdSize, FontWeight.w800, color, height: 1.25);
  static TextStyle headingLg(Color color) => _cairo(headingLgSize, FontWeight.w700, color, height: 1.3);
  static TextStyle headingMd(Color color) => _cairo(headingMdSize, FontWeight.w700, color, height: 1.35);
  static TextStyle headingSm(Color color) => _cairo(headingSmSize, FontWeight.w700, color, height: 1.4);
  static TextStyle bodyLg(Color color) => _cairo(bodyLgSize, FontWeight.w400, color, height: 1.55);
  static TextStyle bodyMd(Color color) => _cairo(bodyMdSize, FontWeight.w400, color, height: 1.5);
  static TextStyle bodySm(Color color) => _cairo(bodySmSize, FontWeight.w500, color, height: 1.45);
  static TextStyle caption(Color color) => _cairo(captionSize, FontWeight.w500, color, height: 1.4);
  static TextStyle overline(Color color) => _cairo(
        overlineSize,
        FontWeight.w700,
        color,
        height: 1.3,
        letterSpacing: 0.5,
      );

  static TextStyle numericLg(Color color) => _mono(numericLgSize, FontWeight.w800, color, height: 1.1);
  static TextStyle numericMd(Color color) => _mono(numericMdSize, FontWeight.w700, color, height: 1.2);

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
      );

  /// Full light TextTheme. Plug into ThemeData(textTheme: ...).
  static TextTheme get light {
    const t1 = AppColors.lightTextPrimary;
    const t2 = AppColors.lightTextSecondary;
    const t3 = AppColors.lightTextMuted;
    const onP = AppColors.lightTextOnPrimary;

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
      bodyMedium: bodyMd(t2),
      bodySmall: bodySm(t2),
      labelLarge: _cairo(14, FontWeight.w700, onP, height: 1.2),
      labelMedium: _cairo(12, FontWeight.w600, t2, height: 1.3),
      labelSmall: caption(t3),
    );
  }

  /// Full dark TextTheme.
  static TextTheme get dark {
    const t1 = AppColors.darkTextPrimary;
    const t2 = AppColors.darkTextSecondary;
    const t3 = AppColors.darkTextMuted;
    const onP = AppColors.lightTextOnPrimary;

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
      bodyMedium: bodyMd(t2),
      bodySmall: bodySm(t2),
      labelLarge: _cairo(14, FontWeight.w700, onP, height: 1.2),
      labelMedium: _cairo(12, FontWeight.w600, t2, height: 1.3),
      labelSmall: caption(t3),
    );
  }
}
