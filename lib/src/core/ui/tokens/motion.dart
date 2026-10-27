import 'package:flutter/animation.dart';

/// Motion tokens. Durations + curves used across the design system.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  /// Default ease-out cubic for state transitions.
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Skeleton shimmer period.
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// Backward-compatible alias for older code.
  static const Curve curve = easeOutCubic;
}
