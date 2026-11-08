import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

/// Shimmering placeholder block. Honors `prefers-reduced-motion`.
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final BoxShape shape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadii.radiusSm,
    this.padding,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;
    final base = AppColors.subtle(context);
    final highlight = AppColors.borderSubtle(context);

    Widget core;
    if (reduced) {
      core = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(radius),
          shape: shape,
        ),
      );
    } else {
      core = _Shimmer(
        width: width,
        height: height,
        radius: radius,
        shape: shape,
        base: base,
        highlight: highlight,
      );
    }

    if (padding == null) return core;
    return Padding(padding: padding!, child: core);
  }
}

class AppSkeletonText extends StatelessWidget {
  final double? width;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const AppSkeletonText({
    super.key,
    this.width,
    this.fontSize = 14,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      width: width ?? 160,
      height: fontSize + 2,
      radius: AppRadii.radiusXs,
      padding: padding,
    );
  }
}

class AppSkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? padding;

  const AppSkeletonCircle({
    super.key,
    this.size = 36,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      width: size,
      height: size,
      shape: BoxShape.circle,
      padding: padding,
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;
  final Color base;
  final Color highlight;

  const _Shimmer({
    required this.width,
    required this.height,
    required this.radius,
    required this.shape,
    required this.base,
    required this.highlight,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.shimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.radius),
            shape: widget.shape,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * t, 0),
              end: Alignment(0.0 + 2 * t, 0),
              colors: [
                widget.base,
                widget.highlight,
                widget.base,
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}