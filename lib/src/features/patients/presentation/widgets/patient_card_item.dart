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

/// بطاقة المريض في العرض الهاتفي
class PatientCardItem extends ConsumerWidget {
  final PatientModel patient;
  final int fileNumber;
  final String clinicId;

  const PatientCardItem({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => PatientDetailsDialog(clinicId: clinicId, patient: patient),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        patient.fullName.trim().isNotEmpty
                            ? patient.fullName.trim().substring(0, 1)
                            : '؟',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  patient.fullName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$fileNumber',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (patient.phone != null && patient.phone!.isNotEmpty)
                                InkWell(
                                  onTap: () => showSendWhatsAppDialog(
                                    context,
                                    ref,
                                    phone: patient.phone!,
                                    patientName: patient.fullName,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline_rounded,
                                          size: 12, color: Color(0xFF10B981)),
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
                              else
                                Text('بدون هاتف', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                              if (age != null) ...[
                                const SizedBox(width: 12),
                                Text('• $age سنة', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => BookAppointmentDialog(
                            clinicId: clinicId,
                            preselectedPatientId: patient.id,
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 13),
                      label: const Text('حجز موعد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                    ),
                    Row(
                      children: [
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
