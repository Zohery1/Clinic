import 'package:flutter/material.dart';
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

  const DesktopDetailsPane({
    super.key,
    required this.user,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: selected == null
          ? const AppEmptyState(
              icon: Icons.touch_app_rounded,
              title: 'اختر موعداً لعرض التفاصيل',
              message:
                  'اضغط على أي موعد من القائمة لعرض معلومات المريض والإجراءات المتاحة',
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppointmentDetailsCard(
                    appointment: selected!,
                    clinicId: user.clinicId,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius:
                          BorderRadius.circular(AppRadii.radiusMd),
                      border:
                          Border.all(color: AppColors.borderSubtle(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 16, color: AppColors.textMuted(context)),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            'كل التغييرات تُحفظ تلقائياً في السحابة وتظهر لجميع المستخدمين فوراً',
                            style: TextStyle(
                              fontSize: 11.5,
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
    );
  }
}
