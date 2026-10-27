import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/ui/tokens/colors.dart';
import '../../../../../../core/ui/tokens/spacing.dart';
import '../../../../../../core/ui/tokens/typography.dart';
import '../../appointment_patient_picker.dart';

class StepPatient extends ConsumerWidget {
  final String clinicId;
  final String? selectedPatientId;
  final ValueChanged<String?> onChanged;
  final void Function(TextEditingController controller)? onControllerReady;

  const StepPatient({
    super.key,
    required this.clinicId,
    required this.selectedPatientId,
    required this.onChanged,
    this.onControllerReady,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر المريض',
          style: AppTypography.headingLg(AppColors.textPrimary(context)),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'ابحث باسم المريض أو رقم الهاتف',
          style: AppTypography.bodySm(AppColors.textSecondary(context)),
        ),
        const SizedBox(height: AppSpace.lg),
        AppointmentPatientPicker(
          clinicId: clinicId,
          selectedPatientId: selectedPatientId,
          onPatientSelected: (p) => onChanged(p?.id),
          onControllerReady: onControllerReady,
        ),
      ],
    );
  }
}


