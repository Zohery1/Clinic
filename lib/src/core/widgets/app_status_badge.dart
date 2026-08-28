import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Standardized status badge / pill widget for appointments, payments, and clinic items.
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

  /// Factory constructor to map standard appointment status strings into styled status badges.
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
        color: AppColors.error,
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

    // Default fallback
    return AppStatusBadge(
      label: status,
      color: AppColors.textSecondaryLight,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
    final verticalPadding = compact ? 2.0 : AppSpacing.xs;
    final fontSize = compact ? 11.0 : 12.5;
    final iconSize = compact ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: color,
            ),
            SizedBox(width: compact ? 3.0 : AppSpacing.xs),
          ] else ...[
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: compact ? 4.0 : 6.0),
          ],
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
