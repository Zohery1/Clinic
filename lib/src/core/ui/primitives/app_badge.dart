import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

enum AppBadgeVariant { neutral, info, success, warning, danger, accent }

enum AppBadgeSize { sm, md }

/// Pill badge with optional leading icon or dot. Color-tinted backgrounds
/// work in both light and dark mode.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final IconData? icon;
  final bool dot;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.size = AppBadgeSize.md,
    this.icon,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);

    final hPad = size == AppBadgeSize.sm ? AppSpace.sm : AppSpace.md;
    final vPad = size == AppBadgeSize.sm ? 2.0 : AppSpace.xs;
    final fontSize = size == AppBadgeSize.sm ? 11.0 : 12.5;
    final iconSize = size == AppBadgeSize.sm ? 12.0 : 14.0;
    final dotSize = size == AppBadgeSize.sm ? 5.0 : 6.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadii.radiusFull),
        border: Border.all(color: colors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: colors.fg),
            SizedBox(width: size == AppBadgeSize.sm ? 3 : AppSpace.xs),
          ] else if (dot) ...[
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(color: colors.fg, shape: BoxShape.circle),
            ),
            SizedBox(width: size == AppBadgeSize.sm ? 4 : 6),
          ],
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: colors.fg,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors _resolveColors(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final alpha = isDark ? 0.22 : 0.12;
    final borderAlpha = isDark ? 0.35 : 0.25;

    switch (variant) {
      case AppBadgeVariant.neutral:
        return _BadgeColors(
          bg: AppColors.subtle(context).withValues(alpha: isDark ? 0.6 : 1),
          fg: AppColors.textSecondary(context),
          border: AppColors.borderSubtle(context),
        );
      case AppBadgeVariant.info:
        return _BadgeColors(
          bg: AppColors.infoSubtle.withValues(alpha: alpha * 4),
          fg: AppColors.info,
          border: AppColors.info.withValues(alpha: borderAlpha),
        );
      case AppBadgeVariant.success:
        return _BadgeColors(
          bg: AppColors.successSubtle.withValues(alpha: alpha * 4),
          fg: AppColors.success,
          border: AppColors.success.withValues(alpha: borderAlpha),
        );
      case AppBadgeVariant.warning:
        return _BadgeColors(
          bg: AppColors.warningSubtle.withValues(alpha: alpha * 4),
          fg: AppColors.warning,
          border: AppColors.warning.withValues(alpha: borderAlpha),
        );
      case AppBadgeVariant.danger:
        return _BadgeColors(
          bg: AppColors.dangerSubtle.withValues(alpha: alpha * 4),
          fg: AppColors.danger,
          border: AppColors.danger.withValues(alpha: borderAlpha),
        );
      case AppBadgeVariant.accent:
        return _BadgeColors(
          bg: AppColors.completedSubtle.withValues(alpha: alpha * 4),
          fg: AppColors.completed,
          border: AppColors.completed.withValues(alpha: borderAlpha),
        );
    }
  }
}

class _BadgeColors {
  final Color bg;
  final Color fg;
  final Color border;
  const _BadgeColors({required this.bg, required this.fg, required this.border});
}
