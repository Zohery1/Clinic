import 'package:flutter/animation.dart';

/// حركة موحدة: سريعة للـfeedback، عادية للانتقالات
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
}
