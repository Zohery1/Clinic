import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../../../../auth/domain/user_model.dart';
import '../../../domain/appointment_model.dart';
import '../appointment_details_card.dart';

/// Right pane: full details of the selected appointment.
class DesktopDetailsPane extends StatelessWidget {
  final UserModel user;
  final AppointmentModel? selected;
  final VoidCallback? onClose;

  const DesktopDetailsPane({
    super.key,
    required this.user,
    required this.selected,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpace.lg),
        child: AppEmptyState(
          icon: Icons.touch_app_rounded,
          title: 'اختر موعداً لعرض التفاصيل',
          message:
              'اضغط على أي موعد من القائمة لعرض معلومات المريض والإجراءات المتاحة',
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.person_pin_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'تفاصيل الموعد السريري',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Spacer(),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'إغلاق التفاصيل',
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppointmentDetailsCard(
                    appointment: selected!,
                    clinicId: user.clinicId,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.borderSubtle(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_done_outlined,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'المزامنة السحابية فورية ومباشرة مع شاشة الطبيب والاستقبال',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
