import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';

/// عنوان قسم الإعدادات
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm, right: AppSpace.xs),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// عنصر خيار في شاشة الإعدادات
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final iconBg = isDark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primarySubtle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppRadii.brMd,
          border: Border.all(
            color: AppColors.borderSubtle(context),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            title: Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary(context),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),
            trailing: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textMuted(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة إجراء خاص (مثل تسجيل الخروج أو مغادرة العيادة)
class SettingsActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SettingsActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(
          color: AppColors.borderSubtle(context),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          title: Text(
            title,
            style: GoogleFonts.cairo(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          trailing: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textMuted(context),
          ),
        ),
      ),
    );
  }
}
