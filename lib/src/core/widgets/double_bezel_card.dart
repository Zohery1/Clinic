import 'package:flutter/material.dart';

/// DEPRECATED: removed in Phase 4. Kept as an empty stub so old imports
/// continue to compile. Use `AppCard` from `lib/src/core/widgets/app_card.dart`
/// or primitives from `lib/src/core/ui/`.
class DoubleBezelCard extends StatelessWidget {
  const DoubleBezelCard({
    super.key,
    required this.child,
    this.outerPadding,
    this.innerPadding,
    this.margin,
    this.outerRadius,
    this.innerRadius,
    this.outerColor,
    this.borderColor,
    this.innerColor,
    this.innerGradient,
    this.innerShadows,
    this.innerBorder,
    this.onTap,
    this.clipBehavior,
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
  final Clip clipBehavior;
  final bool isActiveGlow;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) => child;
}

/// DEPRECATED: removed in Phase 4. Kept as an empty stub so old imports
/// continue to compile. The new mobile view uses inline staggered animation.
class StaggeredCardEntry extends StatelessWidget {
  const StaggeredCardEntry({
    super.key,
    required this.index,
    required this.child,
    this.baseDuration,
    this.itemDelay,
    this.slideOffset,
    this.direction,
  });
  final int index;
  final Widget child;
  final Duration baseDuration;
  final Duration itemDelay;
  final double slideOffset;
  final Axis direction;

  @override
  Widget build(BuildContext context) => child;
}