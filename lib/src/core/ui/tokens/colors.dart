import 'package:flutter/material.dart';

/// Design Tokens — Premium Enterprise SaaS (Linear-style).
/// Indigo + White + Mint. Single source of truth for every color used by
/// the design system primitives, layout, and feature widgets.
class AppColors {
  AppColors._();

  // Brand — Authoritative Clinical Sapphire & Deep Slate
  static const Color primary = Color(0xFF1D4ED8); // Refined clinical royal blue
  static const Color primaryHover = Color(0xFF1E40AF);
  static const Color primarySubtle = Color(0xFFEFF6FF); // Ultra-soft blue tint
  static const Color primarySurface = Color(0xFFF8FAFC);
  static const Color primaryDark = Color(0xFF1E3A8A); // Deep medical navy
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Status — Pure semantic WCAG compliant
  static const Color success = Color(0xFF059669); // Emerald
  static const Color successSubtle = Color(0xFFECFDF5);
  static const Color successBright = Color(0xFF10B981);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningSubtle = Color(0xFFFFFBEB);
  static const Color warningBright = Color(0xFFF59E0B);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626); // Crimson
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBright = Color(0xFFEF4444);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0284C7); // Sky / Info
  static const Color infoSubtle = Color(0xFFF0F9FF);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Status completions & Clinical Procedures
  static const Color completed = Color(0xFF7C3AED); // Clinical violet
  static const Color completedSubtle = Color(0xFFF5F3FF);
  static const Color completedBorder = Color(0xFFDDD6FE);

  // Neutrals — Light (Crisp clinical slate, zero yellow murkiness)
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightSubtle = Color(0xFFF1F5F9);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightBorderStrong = Color(0xFF94A3B8);

  // Neutrals — Dark (Clinical Deep Slate)
  static const Color darkCanvas = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkElevated = Color(0xFF1F2937);
  static const Color darkSubtle = Color(0xFF1E293B);
  static const Color darkBorderSubtle = Color(0xFF1F293D);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkBorderStrong = Color(0xFF4B5563);

  // Elite Obsidian Command Console Tokens (Linear / Epic Clinical Cockpit)
  static const Color obsidianShell = Color(0xFF080D1A);
  static const Color obsidianCard = Color(0xFF0E1626);
  static const Color obsidianCardHover = Color(0xFF172338);
  static const Color obsidianBorder = Color(0xFF1E2E4A);
  static const Color obsidianHairline = Color(0x26FFFFFF); // 15% white hairline
  static const Color obsidianTextPrimary = Color(0xFFF8FAFC);
  static const Color obsidianTextSecondary = Color(0xFF94A3B8);
  static const Color obsidianTextMuted = Color(0xFF64748B);
  static const Color obsidianActiveGlow = Color(0xFF38BDF8); // Cyan pulse
  static const Color obsidianActiveBg = Color(0x2438BDF8); // 14% cyan fill

  // Text — Light (Warm clinical slate per DESIGN.md)
  static const Color lightTextPrimary = Color(0xFF1E293B); // Slate 800
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightTextMuted = Color(0xFF9CA3AF); // Slate 400
  static const Color lightTextOnPrimary = Color(0xFFFFFFFF);

  // Text — Dark
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Doctor palette — Distinct clinical badges
  static const List<Color> doctorPalette = <Color>[
    Color(0xFF1D4ED8), // Sapphire
    Color(0xFF0D9488), // Teal
    Color(0xFF7C3AED), // Violet
    Color(0xFFD97706), // Amber
    Color(0xFF059669), // Emerald
    Color(0xFF0284C7), // Sky
    Color(0xFFE11D48), // Rose
    Color(0xFF4F46E5), // Indigo
  ];

  // Backward-compatible aliases
  static const Color backgroundLight = lightCanvas;
  static const Color surfaceLight = lightSurface;
  static const Color surfaceDimLight = lightSubtle;
  static const Color borderLight = lightBorderSubtle;
  static const Color borderSubtleLight = lightBorderSubtle;
  static const Color backgroundDark = darkCanvas;
  static const Color surfaceDark = darkSurface;
  static const Color surfaceDimDark = darkSubtle;
  static const Color borderDark = darkBorder;
  static const Color borderSubtleDark = darkBorderSubtle;
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
