import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../data/patient_repository.dart';
import '../../domain/patient_model.dart';
import '../widgets/patient_medical_profile_view.dart';

Future<void> showPatientsDeleteDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String clinicId,
  required PatientModel patient,
  required VoidCallback? onAfterDelete,
}) async {
  final fullName = PatientMedicalProfileView.capitalizeName(patient.fullName);
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surface(ctx),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderSubtle(ctx)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.dangerSubtle,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تأكيد الحذف',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من حذف المريض "$fullName"؟\nسيتم حذف جميع الحجوزات والسجلات التابعة له.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: AppColors.textSecondary(ctx),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'إلغاء',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'نعم، احذف',
                        icon: Icons.delete_outline_rounded,
                        variant: AppButtonVariant.danger,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (ok != true) return;

  try {
    await ref.read(patientRepositoryProvider).deletePatient(patient.id);
    ref.invalidate(patientsListProvider(clinicId));
    if (context.mounted) {
      ClinicToast.showSuccess(context, 'تم حذف المريض بنجاح');
    }
    onAfterDelete?.call();
  } catch (e) {
    if (context.mounted) {
      ClinicToast.showError(context, 'خطأ: $e');
    }
  }
}