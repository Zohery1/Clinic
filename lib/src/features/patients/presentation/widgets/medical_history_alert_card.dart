import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../../../core/ui/tokens/spacing.dart';

/// بطاقة التنبيه السريري للتاريخ المرضي والحساسيات المزمنة
class MedicalHistoryAlertCard extends StatefulWidget {
  final String medicalHistory;

  const MedicalHistoryAlertCard({super.key, required this.medicalHistory});

  @override
  State<MedicalHistoryAlertCard> createState() =>
      _MedicalHistoryAlertCardState();
}

class _MedicalHistoryAlertCardState extends State<MedicalHistoryAlertCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final history = widget.medicalHistory.trim();
    final isLong = history.length > 90 || history.contains('\n');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.warningSubtle,
        borderRadius: AppRadii.brMd,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.35 : 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.health_and_safety_rounded,
                    color: isDark ? AppColors.warningBright : AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'تنبيه طبي: التاريخ المرضي والحساسيات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color:
                          isDark ? AppColors.warningBright : AppColors.warning,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              if (isLong)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: AppRadii.brSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'طي التفاصيل' : 'عرض التفاصيل كاملة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.warningBright
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.warningBright
                              : AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.easeOutCubic,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _isExpanded ? 180 : 44,
              ),
              child: SingleChildScrollView(
                physics: _isExpanded
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Text(
                  history,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                    height: 1.45,
                  ),
                  maxLines: _isExpanded ? null : 2,
                  overflow:
                      _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
