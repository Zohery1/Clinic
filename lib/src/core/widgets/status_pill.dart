import 'package:flutter/material.dart';
import '../ui/primitives/app_badge.dart';
import '../ui/tokens/colors.dart';

export '../ui/primitives/app_badge.dart';

/// Backward-compatible wrapper. Old `StatusPill(label, color)` API is
/// preserved; rendering forwards to [AppBadge] from the new system.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
  });

  AppBadgeVariant _variant() {
    final c = color.toARGB32();
    if (c == AppColors.success.toARGB32()) return AppBadgeVariant.success;
    if (c == AppColors.warning.toARGB32()) return AppBadgeVariant.warning;
    if (c == AppColors.danger.toARGB32()) return AppBadgeVariant.danger;
    if (c == AppColors.completed.toARGB32()) return AppBadgeVariant.accent;
    if (c == AppColors.primary.toARGB32() ||
        c == AppColors.info.toARGB32()) {
      return AppBadgeVariant.info;
    }
    return AppBadgeVariant.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: label,
      size: compact ? AppBadgeSize.sm : AppBadgeSize.md,
      variant: _variant(),
    );
  }
}
