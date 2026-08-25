import 'package:flutter/material.dart';

/// نظام المسافات الموحد — ممنوع أرقام عشوائية في padding/margin جديد
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// نقاط الكسر الموحدة لكل التطبيق (بدل شروط MediaQuery المتفرقة)
class AppBreakpoints {
  AppBreakpoints._();
  static const double mobile = 700;
  static const double tablet = 1100;

  static bool isMobileWidth(double width) => width < mobile;
  static bool isTabletWidth(double width) => width >= mobile && width < tablet;
  static bool isDesktopWidth(double width) => width >= tablet;
}

extension ResponsiveContext on BuildContext {
  double get screenW => MediaQuery.sizeOf(this).width;
  bool get isMobile => AppBreakpoints.isMobileWidth(screenW);
  bool get isTablet => AppBreakpoints.isTabletWidth(screenW);
  bool get isDesktop => AppBreakpoints.isDesktopWidth(screenW);
}
