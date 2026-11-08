import 'package:flutter/material.dart';
import '../ui/tokens/colors.dart';
import '../ui/tokens/spacing.dart';

export 'staggered_card_entry.dart';

/// Clinical Utility container card with flat styling, clean border, and subtle active state.
class DoubleBezelCard extends StatelessWidget {
  const DoubleBezelCard({
    super.key,
    required this.child,
    this.outerPadding = const EdgeInsets.all(1.5),
    this.innerPadding = const EdgeInsets.all(16),
    this.margin,
    this.outerRadius = 16.0,
    this.innerRadius,
    this.outerColor,
    this.borderColor,
    this.innerColor,
    this.innerGradient,
    this.innerShadows,
    this.innerBorder,
    this.onTap,
    this.clipBehavior = Clip.none,
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
    final resolvedOuterRadius = outerRadius ?? AppRadii.lg;
    final resolvedInnerRadius = innerRadius ?? (resolvedOuterRadius - 1.5).clamp(0.0, 999.0);
    final effectiveOuterBorderRadius = BorderRadius.circular(resolvedOuterRadius);
    final effectiveInnerBorderRadius = BorderRadius.circular(resolvedInnerRadius);

    final accent = glowColor ?? AppColors.primary;
    final effectiveBorderColor = borderColor ??
        (isActiveGlow ? accent : AppColors.borderSubtle(context));

    final effectiveInnerPadding = innerPadding ?? const EdgeInsets.all(16);
    final effectiveOuterPadding = outerPadding ?? const EdgeInsets.all(1.5);

    Widget innerCard = Ink(
      decoration: BoxDecoration(
        color: innerGradient == null ? (innerColor ?? AppColors.surface(context)) : null,
        gradient: innerGradient,
        borderRadius: effectiveInnerBorderRadius,
        border: innerBorder,
        boxShadow: innerShadows,
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
        color: outerColor ?? AppColors.surface(context),
        borderRadius: effectiveOuterBorderRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: isActiveGlow ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: clipBehavior ?? Clip.none,
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveInnerBorderRadius,
        clipBehavior: clipBehavior ?? Clip.none,
        child: innerCard,
      ),
    );
  }
}