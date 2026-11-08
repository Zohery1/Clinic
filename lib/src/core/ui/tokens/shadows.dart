import 'package:flutter/material.dart';
import 'colors.dart';

/// Elevation tokens. Flat, clean, subtle clinical shadows.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> sm(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.04);
    return <BoxShadow>[
      BoxShadow(
        color: color,
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> md(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.06);
    return <BoxShadow>[
      BoxShadow(
        color: color,
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> lg(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.08);
    return <BoxShadow>[
      BoxShadow(
        color: color,
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
