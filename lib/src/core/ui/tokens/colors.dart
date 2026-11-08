import 'package:flutter/material.dart';

/// Design Tokens — Calm Clinical Command Center.
///
/// One clinical sapphire, deep ink text, hairline structure, and semantic
/// status colors used only when they carry meaning. Every tinted surface is
/// derived at runtime through [tint]/[tintBorder] so dark mode never inherits
/// a washed-out light-mode pastel.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  // Authoritative clinical sapphire. Pinned by ui_tokens_test.
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryHover = Color(0xFF1E40AF);
  static const Color primarySubtle = Color(0xFFEFF6FF);
  static const Color primaryMuted = Color(0xFFEFF6FF);
  static const Color primarySurface = Color(0xFFF8FAFC);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// A deeper sapphire for hero panels and high-emphasis surfaces.
  static const Color primaryInk = Color(0xFF172554);
  static const Color primaryBright = Color(0xFF2563EB);

  // ── Neutral scale ──────────────────────────────────────────────────────────
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);
  static const Color gray950 = Color(0xFF020617);

  // ── Status — semantic only ─────────────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color successSubtle = Color(0xFFECFDF5);
  static const Color successBright = Color(0xFF10B981);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSubtle = Color(0xFFFFFBEB);
  static const Color warningBright = Color(0xFFF59E0B);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBright = Color(0xFFEF4444);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0284C7);
  static const Color infoSubtle = Color(0xFFF0F9FF);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Clinical completions stay violet so "done" reads apart from "healthy".
  static const Color completed = Color(0xFF7C3AED);
  static const Color completedSubtle = Color(0xFFF5F3FF);
  static const Color completedBorder = Color(0xFFDDD6FE);

  // ── Surfaces — light ───────────────────────────────────────────────────────
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightSubtle = Color(0xFFF1F5F9);
  static const Color lightSunken = Color(0xFFF1F5F9);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightBorderStrong = Color(0xFF94A3B8);

  // ── Surfaces — dark ────────────────────────────────────────────────────────
  static const Color darkCanvas = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkElevated = Color(0xFF1B2433);
  static const Color darkSubtle = Color(0xFF1E293B);
  static const Color darkSunken = Color(0xFF0D1420);
  static const Color darkBorderSubtle = Color(0xFF1F2A3C);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkBorderStrong = Color(0xFF475569);

  // ── Text — light ───────────────────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextOnPrimary = Color(0xFFFFFFFF);

  // ── Text — dark ────────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFA8B4C7);
  static const Color darkTextMuted = Color(0xFF7C8AA0);

  // ── Doctor palette ─────────────────────────────────────────────────────────
  static const List<Color> doctorPalette = <Color>[
    Color(0xFF1D4ED8),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFF059669),
    Color(0xFF0284C7),
    Color(0xFFE11D48),
    Color(0xFF4F46E5),
  ];

  // ── Backward-compatible aliases ────────────────────────────────────────────
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

  // ── Context-aware neutrals ─────────────────────────────────────────────────
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

  static Color sunken(BuildContext context) =>
      isDark(context) ? darkSunken : lightSunken;

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

  /// A dense, opaque surface for panels that sit on the canvas.
  static Color panel(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  /// Brand accent that stays legible on the active canvas. Sapphire cannot
  /// carry 4.5:1 on deep ink, so dark mode lifts it.
  static const Color darkAccent = Color(0xFF7FA8FF);

  static Color accent(BuildContext context) =>
      isDark(context) ? darkAccent : primary;

  static Color onAccent(BuildContext context) =>
      isDark(context) ? const Color(0xFF06101F) : onPrimary;

  /// Text/icon color for a filled accent surface.
  static Color accentSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B3A6B) : primarySubtle;

  // ── Dark-safe semantic tints ───────────────────────────────────────────────
  /// Background fill for a semantic color. Never returns a light-mode pastel
  /// in dark mode.
  static Color tint(
    BuildContext context,
    Color base, {
    double light = 0.10,
    double dark = 0.20,
  }) =>
      base.withValues(alpha: isDark(context) ? dark : light);

  /// Hairline that belongs to a semantic tint.
  static Color tintBorder(BuildContext context, Color base) =>
      base.withValues(alpha: isDark(context) ? 0.32 : 0.22);

  /// Semantic foreground that stays legible on both canvases.
  static Color tintText(BuildContext context, Color base) {
    if (!isDark(context)) return base;
    return Color.lerp(base, Colors.white, 0.42)!;
  }

  /// A subtle page wash used behind hero sections and empty states.
  static Color wash(BuildContext context) => isDark(context)
      ? const Color(0xFF0C1526)
      : const Color(0xFFF2F7FF);

  static Color doctorColor(String? id) {
    if (id == null || id.isEmpty) return doctorPalette.first;
    final hash = id.codeUnits.fold<int>(0, (acc, c) => (acc + c) & 0x7fffffff);
    return doctorPalette[hash % doctorPalette.length];
  }
}
