import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../../core/widgets/send_whatsapp_dialog.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../data/patient_repository.dart';
import '../../domain/patient_model.dart';
import '../patient_details_dialog.dart';
import 'edit_patient_dialog.dart';

/// صف جدول المرضى للعرض المكتبي
class PatientTableRow extends ConsumerWidget {
  final PatientModel patient;
  final int fileNumber;
  final String clinicId;

  const PatientTableRow({
    super.key,
    required this.patient,
    required this.fileNumber,
    required this.clinicId,
  });

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    ClinicDialog.confirm(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'حذف ملف المريض',
      description:
          'هل أنت متأكد من رغبتك في حذف ملف المريض (${patient.fullName})؟ سيؤدي هذا الإجراء لحذف كافة مواعيده وسجلاته الطبية نهائياً.',
      confirmLabel: 'حذف نهائي',
      isDangerous: true,
      onConfirm: () async {
        try {
          await ref.read(patientRepositoryProvider).deletePatient(patient.id);
          ref.invalidate(patientsListProvider(clinicId));
          if (context.mounted) {
            ClinicToast.showSuccess(context, 'تم حذف ملف المريض بنجاح');
          }
        } catch (e) {
          if (context.mounted) {
            ClinicToast.showError(context, 'حدث خطأ أثناء الحذف: $e');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;
    final age = _calculateAge(patient.birthDate);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => PatientDetailsDialog(clinicId: clinicId, patient: patient),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            // رقم الملف
            SizedBox(
              width: 70,
              child: Text(
                '#$fileNumber',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            // المريض
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      patient.fullName.trim().isNotEmpty ? patient.fullName.trim().substring(0, 1) : '؟',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patient.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // الهاتف
            Expanded(
              flex: 2,
              child: patient.phone != null && patient.phone!.isNotEmpty
                  ? InkWell(
                      onTap: () => showSendWhatsAppDialog(
                        context,
                        ref,
                        phone: patient.phone!,
                        patientName: patient.fullName,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            patient.phone!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text('بدون هاتف', style: TextStyle(fontSize: 11, color: theme.hintColor)),
            ),
            // العمر
            Expanded(
              flex: 1,
              child: Text(
                age != null ? '$age سنة' : '--',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            // الجنس
            Expanded(
              flex: 1,
              child: Text(
                patient.gender == 'male'
                    ? 'ذكر'
                    : patient.gender == 'female'
                        ? 'أنثى'
                        : '--',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            // الإجراءات
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    tooltip: 'حجز موعد',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => BookAppointmentDialog(
                          clinicId: clinicId,
                          preselectedPatientId: patient.id,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    tooltip: 'تعديل',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditPatientDialog(clinicId: clinicId, patient: patient),
                      );
                    },
                  ),
                  if (user?.isOwner == true || isDoctor)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
                      tooltip: 'حذف',
                      onPressed: () => _showDeleteDialog(context, ref),
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
