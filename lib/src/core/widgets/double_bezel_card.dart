import 'package:flutter/material.dart';
import '../ui/tokens/colors.dart';
import '../ui/tokens/spacing.dart';

export 'staggered_card_entry.dart';

/// Clinical double-bezel card container providing structural elegance,
/// a recessed outer rim bezel, elevated inner surface, dual micro-shadows,
/// and responsive active-glow halo states.
class DoubleBezelCard extends StatelessWidget {
  const DoubleBezelCard({
    super.key,
    required this.child,
    this.outerPadding = const EdgeInsets.all(2.5),
    this.innerPadding = const EdgeInsets.all(16),
    this.margin,
    this.outerRadius = 20.0,
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

  final Widget child;
  final EdgeInsetsGeometry? outerPadding;
  final EdgeInsetsGeometry? innerPadding;
  final EdgeInsetsGeometry? margin;
  final double? outerRadius;
  final double? innerRadius;
  final Color? outerColor;
  final Color? borderColor;
  final Color? innerColor;
  final Gradient? innerGradient;
  final List<BoxShadow>? innerShadows;
  final Border? innerBorder;
  final VoidCallback? onTap;
  final Clip? clipBehavior;
  final bool isActiveGlow;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedOuterRadius = outerRadius ?? AppRadii.radiusLg;
    final resolvedInnerRadius = innerRadius ??
        (resolvedOuterRadius - 2.5).clamp(0.0, 999.0);
    final effectiveOuterBorderRadius = BorderRadius.circular(resolvedOuterRadius);
    final effectiveInnerBorderRadius = BorderRadius.circular(resolvedInnerRadius);

    final accent = glowColor ?? AppColors.primary;

    // Outer shell rim color
    final resolvedOuterColor = outerColor ??
        (isActiveGlow
            ? accent.withValues(alpha: isDark ? 0.16 : 0.08)
            : (isDark
                ? Colors.white.withValues(alpha: 0.035)
                : const Color(0xFFF1F5F9)));

    // Outer bezel border color
    final resolvedBorderColor = borderColor ??
        (isActiveGlow
            ? accent.withValues(alpha: isDark ? 0.65 : 0.45)
            : (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight));

    // Outer halo / elevation shadow
    final outerShadows = isActiveGlow
        ? [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    // Inner surface fill & shadows
    final resolvedInnerBg = innerColor ?? AppColors.surface(context);
    final defaultInnerShadows = <BoxShadow>[
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.9),
        offset: const Offset(0, 1),
        blurRadius: 1,
        spreadRadius: 0,
      ),
      if (isActiveGlow)
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
    ];

    final effectiveInnerShadows = innerShadows ?? defaultInnerShadows;
    final effectiveOuterPadding = outerPadding ?? const EdgeInsets.all(2.5);
    final effectiveInnerPadding = innerPadding ?? const EdgeInsets.all(16);

    Widget innerCard = Ink(
      decoration: BoxDecoration(
        color: innerGradient == null ? resolvedInnerBg : null,
        gradient: innerGradient,
        borderRadius: effectiveInnerBorderRadius,
        border: innerBorder ??
            Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              width: 0.75,
            ),
        boxShadow: effectiveInnerShadows,
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: effectiveInnerBorderRadius,
              child: Padding(
                padding: effectiveInnerPadding,
                child: child,
              ),
            )
          : Padding(
              padding: effectiveInnerPadding,
              child: child,
            ),
    );

    return Container(
      margin: margin,
      padding: effectiveOuterPadding,
      decoration: BoxDecoration(
        color: resolvedOuterColor,
        borderRadius: effectiveOuterBorderRadius,
        border: Border.all(
          color: resolvedBorderColor,
          width: isActiveGlow ? 1.5 : 1.0,
        ),
        boxShadow: outerShadows,
      ),
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveInnerBorderRadius,
        clipBehavior: clipBehavior ?? Clip.antiAlias,
        child: innerCard,
      ),
    );
  }
}