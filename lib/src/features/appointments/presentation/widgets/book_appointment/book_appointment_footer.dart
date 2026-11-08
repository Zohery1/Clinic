import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/ui/primitives/app_button.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';

/// تذييل نافذة حجز كشف واستقبال سريع (Express Intake Footer)
class BookAppointmentFooter extends StatelessWidget {
  final bool isMobile;
  final double totalPrice;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const BookAppointmentFooter({
    super.key,
    required this.isMobile,
    required this.totalPrice,
    required this.isSaving,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.subtle(context).withValues(alpha: 0.3),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadii.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المطلوب تحصيله: ',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'إلغاء',
                    variant: AppButtonVariant.ghost,
                    expand: true,
                    onPressed: isSaving ? null : onCancel,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: AppButton(
                    label: 'تأكيد الحجز',
                    icon: Icons.check_rounded,
                    variant: AppButtonVariant.primary,
                    expand: true,
                    loading: isSaving,
                    onPressed: isSaving ? null : onSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.subtle(context).withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المطلوب تحصيله: ',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ctrl + Enter للحفظ',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          AppButton(
            label: 'إلغاء',
            variant: AppButtonVariant.ghost,
            expand: false,
            onPressed: isSaving ? null : onCancel,
          ),
          const SizedBox(width: AppSpace.sm),
          AppButton(
            label: 'تأكيد الحجز',
            icon: Icons.check_rounded,
            variant: AppButtonVariant.primary,
            expand: false,
            loading: isSaving,
            onPressed: isSaving ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
