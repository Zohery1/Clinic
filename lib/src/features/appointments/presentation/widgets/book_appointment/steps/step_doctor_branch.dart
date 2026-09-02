import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/ui/tokens/colors.dart';
import '../../../../../../core/ui/tokens/spacing.dart';
import '../../../../../../core/ui/tokens/typography.dart';
import '../../appointment_doctor_branch_picker.dart';

class StepDoctorBranch extends ConsumerWidget {
  final String clinicId;
  final String? selectedDoctorId;
  final String? selectedBranchId;
  final ValueChanged<String?> onDoctorChanged;
  final ValueChanged<String?> onBranchChanged;

  const StepDoctorBranch({
    super.key,
    required this.clinicId,
    required this.selectedDoctorId,
    required this.selectedBranchId,
    required this.onDoctorChanged,
    required this.onBranchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الطبيب والفرع',
          style: AppTypography.headingLg(AppColors.textPrimary(context)),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'اختر الطبيب المعالج والفرع الذي ستتم فيه الزيارة',
          style: AppTypography.bodySm(AppColors.textSecondary(context)),
        ),
        const SizedBox(height: AppSpace.lg),
        AppointmentDoctorBranchPicker(
          clinicId: clinicId,
          selectedDoctorId: selectedDoctorId,
          selectedBranchId: selectedBranchId,
          onDoctorChanged: onDoctorChanged,
          onBranchChanged: onBranchChanged,
        ),
      ],
    );
  }
}


