import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/primitives/app_avatar.dart';
import '../ui/tokens/colors.dart';
import '../ui/tokens/spacing.dart';
import '../utils/doctor_utils.dart';

export '../ui/primitives/app_avatar.dart';

/// Backward-compatible doctor identity badge. Uses [AppAvatar] from the
/// new design system plus a tinted label. Renders nothing when no name
/// is supplied (matches legacy behavior).
class DoctorBadge extends StatelessWidget {
  final String? doctorId;
  final String? doctorName;
  final bool compact;

  const DoctorBadge({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = (doctorName == null || doctorName!.trim().isEmpty)
        ? null
        : doctorName!.trim();
    if (name == null) return const SizedBox.shrink();

    final color = AppColors.doctorColor(doctorId);
    final isDark = AppColors.isDark(context);
    final bg = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final fg = color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.sm : AppSpace.md,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            name: name,
            color: color,
            size: compact ? AppAvatarSize.xs : AppAvatarSize.sm,
          ),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
            child: Text(
              DoctorUtils.formatTitle(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
