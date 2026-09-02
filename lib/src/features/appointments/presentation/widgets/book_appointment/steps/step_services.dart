import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/ui/tokens/colors.dart';
import '../../../../../../core/ui/tokens/spacing.dart';
import '../../../../../../core/ui/tokens/typography.dart';
import '../../../../domain/service_model.dart';
import '../../appointment_services_picker.dart';

class StepServices extends ConsumerWidget {
  final String clinicId;
  final List<ServiceModel> selectedServices;
  final ValueChanged<List<ServiceModel>> onChanged;

  const StepServices({
    super.key,
    required this.clinicId,
    required this.selectedServices,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خدمات إضافية',
          style: AppTypography.headingLg(AppColors.textPrimary(context)),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'اختياري — أضف خدمات مثل التحاليل أو الإجراءات الإضافية',
          style: AppTypography.bodySm(AppColors.textSecondary(context)),
        ),
        const SizedBox(height: AppSpace.lg),
        AppointmentServicesPicker(
          clinicId: clinicId,
          selectedServices: selectedServices,
          onServicesChanged: onChanged,
        ),
      ],
    );
  }
}


