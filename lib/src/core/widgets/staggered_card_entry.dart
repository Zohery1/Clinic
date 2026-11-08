import 'package:flutter/material.dart';

/// Lightweight entry container (direct pass-through for instantaneous clinical responsiveness).
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
    this.baseDuration = Duration.zero,
    this.itemDelay = Duration.zero,
    this.slideOffset = 0,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) => child;
}
