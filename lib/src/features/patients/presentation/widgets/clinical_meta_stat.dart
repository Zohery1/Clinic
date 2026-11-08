import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/primitives/app_icon_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';

/// بطاقة عرض البيانات الوصفية الطبية للمريض (العنوان، الهاتف، تاريخ التسجيل)
class ClinicalMetaStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMonospace;
  final VoidCallback? onActionTap;
  final String? actionTooltip;

  const ClinicalMetaStat({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isMonospace = false,
    this.onActionTap,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: isMonospace
                            ? GoogleFonts.jetBrainsMono(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                                height: 1.3,
                              )
                            : GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                                height: 1.3,
                              ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onActionTap != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      Tooltip(
                        message: actionTooltip ?? '',
                        child: AppIconButton(
                          onPressed: onActionTap,
                          icon: Icons.chat_bubble_outline_rounded,
                          variant: AppIconButtonVariant.ghost,
                          size: AppIconButtonSize.sm,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
