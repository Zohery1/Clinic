import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Lightweight staggered entrance animation widget (0 external dependencies).
/// Applies a subtle slide-up + fade entrance using [TweenAnimationBuilder]
/// and [Curves.easeOutCubic] for smooth 60fps card transitions.
class StaggeredCardEntry extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDuration;
  final Duration itemDelay;
  final double slideOffset;
  final Axis direction;

  const StaggeredCardEntry({
    super.key,
    required this.index,
    required this.child,
    this.baseDuration = const Duration(milliseconds: 240),
    this.itemDelay = const Duration(milliseconds: 35),
    this.slideOffset = 14.0,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final clampedIndex = index.clamp(0, 10);
    final totalDuration = baseDuration + (itemDelay * clampedIndex);

    return TweenAnimationBuilder<double>(
      key: ValueKey('staggered_entry_$index'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: totalDuration,
      curve: AppMotion.curve,
      builder: (context, value, child) {
        final offset = direction == Axis.vertical
            ? Offset(0, (1.0 - value) * slideOffset)
            : Offset((1.0 - value) * slideOffset, 0);

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: offset,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
