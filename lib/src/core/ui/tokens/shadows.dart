import 'package:flutter/material.dart';
import 'colors.dart';

/// Elevation tokens. Tinted slate-900, not pure black, so depth feels
/// natural on both light canvas (#F7F9FC) and dark canvas (#0B1220).
class AppShadows {
  AppShadows._();

  static List<BoxShadow> sm(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = isDark
        ? const Color(0xFF000000).withValues(alpha: 0.45)
        : const Color(0xFF0F172A).withValues(alpha: 0.05);
    return <BoxShadow>[
      BoxShadow(
        color: color,
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> md(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = isDark
        ? const Color(0xFF000000).withValues(alpha: 0.55)
        : const Color(0xFF0F172A).withValues(alpha: 0.08);
    return <BoxShadow>[
      BoxShadow(
        color: color,
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: isDark
            ? const Color(0xFF000000).withValues(alpha: 0.35)
            : const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> lg(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = isDark
        ? const Color(0xFF000000).withValues(alpha: 0.65)
        : const Color(0xFF0F172A).withValues(alpha: 0.12);
    return <BoxShadow>[
      BoxShadow(
        color: color,
        blurRadius: 32,
        spreadRadius: -4,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: isDark
            ? const Color(0xFF000000).withValues(alpha: 0.4)
            : const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
