import 'package:flutter/material.dart';

/// Design Tokens — Premium Enterprise SaaS (Linear-style).
/// Indigo + White + Mint. Single source of truth for every color used by
/// the design system primitives, layout, and feature widgets.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primarySubtle = Color(0xFFEFF4FF);
  static const Color primarySurface = Color(0xFFF8FAFF);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color successSubtle = Color(0xFFECFDF5);
  static const Color successBright = Color(0xFF10B981);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSubtle = Color(0xFFFFFBEB);
  static const Color warningBright = Color(0xFFF59E0B);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBright = Color(0xFFEF4444);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSubtle = Color(0xFFEFF6FF);

  // Status completions
  static const Color completed = Color(0xFF7C3AED);
  static const Color completedSubtle = Color(0xFFF5F3FF);

  // Neutrals — Light
  static const Color lightCanvas = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightSubtle = Color(0xFFF1F5F9);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightBorderStrong = Color(0xFF94A3B8);

  // Neutrals — Dark
  static const Color darkCanvas = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111A2E);
  static const Color darkElevated = Color(0xFF1A2540);
  static const Color darkSubtle = Color(0xFF1F2A44);
  static const Color darkBorderSubtle = Color(0xFF1F2A44);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderStrong = Color(0xFF64748B);

  // Text — Light
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightTextOnPrimary = Color(0xFFFFFFFF);

  // Text — Dark
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Doctor palette
  static const List<Color> doctorPalette = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF059669),
    Color(0xFF4F46E5),
    Color(0xFFEA580C),
  ];

  // Backward-compatible aliases
  static const Color backgroundLight = lightCanvas;
  static const Color surfaceLight = lightSurface;
  static const Color surfaceDimLight = lightSubtle;
  static const Color borderLight = lightBorderSubtle;
  static const Color backgroundDark = darkCanvas;
  static const Color surfaceDark = darkSurface;
  static const Color surfaceDimDark = darkSubtle;
  static const Color borderDark = darkBorder;
  static const Color textPrimaryLight = lightTextPrimary;
  static const Color textSecondaryLight = lightTextSecondary;
  static const Color textHintLight = lightTextMuted;
  static const Color textPrimaryDark = darkTextPrimary;
  static const Color textSecondaryDark = darkTextSecondary;
  static const Color textHintDark = darkTextMuted;
  static const Color successLight = successSubtle;
  static const Color warningLight = warningSubtle;
  static const Color infoLight = infoSubtle;
  static const Color errorLight = dangerSubtle;
  static const Color error = danger;
  static const Color completedLight = completedSubtle;
  static const Color primaryLight = primarySubtle;

  // Context-aware helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvas(BuildContext context) =>
      isDark(context) ? darkCanvas : lightCanvas;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color elevated(BuildContext context) =>
      isDark(context) ? darkElevated : lightElevated;

  static Color subtle(BuildContext context) =>
      isDark(context) ? darkSubtle : lightSubtle;

  static Color borderSubtle(BuildContext context) =>
      isDark(context) ? darkBorderSubtle : lightBorderSubtle;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color borderStrong(BuildContext context) =>
      isDark(context) ? darkBorderStrong : lightBorderStrong;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color doctorColor(String? id) {
    if (id == null || id.isEmpty) return doctorPalette.first;
    final hash = id.codeUnits.fold<int>(0, (acc, c) => (acc + c) & 0x7fffffff);
    return doctorPalette[hash % doctorPalette.length];
  }
}
