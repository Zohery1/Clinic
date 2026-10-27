import 'package:flutter/material.dart';
import '../ui/primitives/app_badge.dart';
import '../ui/tokens/colors.dart';

export '../ui/primitives/app_badge.dart';

/// Backward-compatible wrapper. Legacy code that built an `AppStatusBadge`
/// with a raw `Color` keeps working — the color is mapped to the closest
/// badge variant from the new design system.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
    this.icon,
  });

  /// Factory used by the old API. Maps known appointment status strings
  /// to a label + icon + variant.
  factory AppStatusBadge.fromAppointmentStatus(
    String status, {
    bool compact = false,
  }) {
    final normalized = status.trim().toLowerCase();

    if (normalized == 'waiting' ||
        normalized == 'pending' ||
        normalized == 'في الانتظار' ||
        normalized == 'انتظار') {
      return AppStatusBadge(
        label: 'في الانتظار',
        color: AppColors.warning,
        icon: Icons.access_time_rounded,
        compact: compact,
      );
    } else if (normalized == 'withdoctor' ||
        normalized == 'with_doctor' ||
        normalized == 'in_progress' ||
        normalized == 'مع الطبيب' ||
        normalized == 'داخل الكشف') {
      return AppStatusBadge(
        label: 'مع الطبيب',
        color: AppColors.info,
        icon: Icons.medical_services_outlined,
        compact: compact,
      );
    } else if (normalized == 'completed' ||
        normalized == 'مكتمل' ||
        normalized == 'تم الكشف' ||
        normalized == 'منتهي') {
      return AppStatusBadge(
        label: 'مكتمل',
        color: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        compact: compact,
      );
    } else if (normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'ملغي' ||
        normalized == 'ملغية' ||
        normalized == 'تم الإلغاء') {
      return AppStatusBadge(
        label: 'ملغي',
        color: AppColors.danger,
        icon: Icons.cancel_outlined,
        compact: compact,
      );
    } else if (normalized == 'confirmed' ||
        normalized == 'مؤكد' ||
        normalized == 'حجز مؤكد') {
      return AppStatusBadge(
        label: 'مؤكد',
        color: AppColors.primary,
        icon: Icons.event_available_rounded,
        compact: compact,
      );
    }

    return AppStatusBadge(
      label: status,
      color: AppColors.lightTextMuted,
      compact: compact,
    );
  }

  AppBadgeVariant _resolveVariant() {
    final c = color.toARGB32();
    final s = AppColors.success.toARGB32();
    final w = AppColors.warning.toARGB32();
    final d = AppColors.danger.toARGB32();
    final i = AppColors.info.toARGB32();
    final p = AppColors.primary.toARGB32();
    if (c == s) return AppBadgeVariant.success;
    if (c == w) return AppBadgeVariant.warning;
    if (c == d) return AppBadgeVariant.danger;
    if (c == i || c == p) return AppBadgeVariant.info;
    return AppBadgeVariant.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: label,
      icon: icon,
      dot: icon == null,
      size: compact ? AppBadgeSize.sm : AppBadgeSize.md,
      variant: _resolveVariant(),
    );
  }
}

