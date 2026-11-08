/// Material 3 window classes, shared so layout decisions stop drifting
/// between screens.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
  static const double large = 1600;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < medium;
  static bool isExpanded(double width) => width >= medium && width < expanded;
  static bool isLarge(double width) => width >= expanded && width < large;
  static bool isXLarge(double width) => width >= large;

  /// Sidebar becomes a full panel at this width.
  static const double sidebarPanel = medium;
}
