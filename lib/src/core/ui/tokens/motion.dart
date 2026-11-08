import 'package:flutter/animation.dart';

/// Motion tokens for crisp, instantaneous clinical transitions.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);

  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve curve = Curves.easeOutCubic;
  static const Duration shimmer = Duration(milliseconds: 1200);
}
