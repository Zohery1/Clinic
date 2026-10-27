import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../auth/domain/user_model.dart';

/// بطاقة الملف الشخصي المختصرة في رأس شاشة الإعدادات
class UserProfileHeader extends StatelessWidget {
  final UserModel user;

  const UserProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDoctor = user.role == UserRole.doctor;
    final isDark = AppColors.isDark(context);

    final avatarBg = isDark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primarySubtle;

    final badgeBg = isDoctor
        ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primarySubtle)
        : (isDark ? AppColors.warning.withValues(alpha: 0.15) : AppColors.warningSubtle);

    final badgeColor = isDoctor ? AppColors.primary : AppColors.warning;

    final displayName = isDoctor
        ? DoctorUtils.formatTitle(user.fullName)
        : user.fullName;

    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1626) : AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderSubtle(context),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: avatarBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                user.fullName.trim().isEmpty
                    ? 'ع'
                    : user.fullName
                        .trim()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join(''),
                style: GoogleFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    isDoctor ? 'طبيب' : 'سكرتارية',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
