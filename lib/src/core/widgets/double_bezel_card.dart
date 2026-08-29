import 'package:flutter/material.dart';
import 'staggered_card_entry.dart';

export 'staggered_card_entry.dart';

/// Soft Structuralism Double-Bezel Card Component.
/// Features a recessed outer shell with subtle ambient border (2.5px bezel lip)
/// and an elevated inner core with dual micro-shadows (micro-rim highlight + diffused depth).
/// Also supports active state halo/glow effects for in-progress or selected items.
class DoubleBezelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry outerPadding;
  final EdgeInsetsGeometry innerPadding;
  final EdgeInsetsGeometry? margin;
  final double outerRadius;
  final double? innerRadius;
  final Color? outerColor;
  final Color? borderColor;
  final Color? innerColor;
  final Gradient? innerGradient;
  final List<BoxShadow>? innerShadows;
  final Border? innerBorder;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  final bool isActiveGlow;
  final Color? glowColor;

  const DoubleBezelCard({
    super.key,
    required this.child,
    this.outerPadding = const EdgeInsets.all(2.5),
    this.innerPadding = const EdgeInsets.all(16),
    this.margin,
    this.outerRadius = 22.0,
    this.innerRadius,
    this.outerColor,
    this.borderColor,
    this.innerColor,
    this.innerGradient,
    this.innerShadows,
    this.innerBorder,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.isActiveGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedOuterColor = outerColor ??
        (isActiveGlow
            ? (glowColor ?? theme.colorScheme.primary).withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02)));

    final resolvedBorderColor = borderColor ??
        (isActiveGlow
            ? (glowColor ?? theme.colorScheme.primary).withValues(alpha: isDark ? 0.35 : 0.25)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)));

    final resolvedInnerRadius = innerRadius ?? (outerRadius - 2.5).clamp(0.0, 999.0);

    final defaultShadows = [
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.9),
        offset: const Offset(0, 1),
        blurRadius: 1,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: isDark
            ? (isActiveGlow
                ? (glowColor ?? theme.colorScheme.primary).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.25))
            : (isActiveGlow
                ? (glowColor ?? theme.colorScheme.primary).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03)),
        offset: const Offset(0, 4),
        blurRadius: isActiveGlow ? 16 : 12,
        spreadRadius: isActiveGlow ? 1 : 0,
      ),
    ];

    Widget content = Container(
      margin: margin,
      padding: outerPadding,
      decoration: BoxDecoration(
        color: resolvedOuterColor,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(
          color: resolvedBorderColor,
          width: isActiveGlow ? 1.2 : 1.0,
        ),
        boxShadow: isActiveGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? theme.colorScheme.primary)
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Container(
        padding: innerPadding,
        decoration: BoxDecoration(
          color: innerGradient == null ? (innerColor ?? theme.colorScheme.surface) : null,
          gradient: innerGradient,
          borderRadius: BorderRadius.circular(resolvedInnerRadius),
          border: innerBorder,
          boxShadow: innerShadows ?? defaultShadows,
        ),
        clipBehavior: clipBehavior,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(outerRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
