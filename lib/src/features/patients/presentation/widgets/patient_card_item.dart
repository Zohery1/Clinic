import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../../core/routing/routing.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../data/patient_repository.dart';
import '../../domain/patient_model.dart';
import 'edit_patient_dialog.dart';

/// بطاقة المريض في العرض الهاتفي (Mobile Patient Card)
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
            ClinicToast.showError(context, 'تعذر حذف ملف المريض، يرجى المحاولة مجدداً');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;
    final age = _calculateAge(patient.birthDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: () => AppNavigation.showPatientDetails(
            context,
            clinicId: clinicId,
            patient: patient,
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primarySubtle,
                      child: Text(
                        patient.fullName.trim().isNotEmpty
                            ? patient.fullName.trim().substring(0, 1)
                            : '؟',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySubtle,
                                  borderRadius: BorderRadius.circular(AppRadii.xs),
                                ),
                                child: Text(
                                  '#$fileNumber',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
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
                                  onTap: () => AppNavigation.showWhatsApp(
                                    context,
                                    phone: patient.phone!,
                                    patientName: patient.fullName,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline_rounded,
                                          size: 12, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        patient.phone!,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text('بدون هاتف', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted(context))),
                              if (age != null) ...[
                                const SizedBox(width: 12),
                                Text('• $age سنة', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary(context))),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: AppColors.borderSubtle(context)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => AppNavigation.showBookAppointment(
                        context,
                        clinicId: clinicId,
                        preselectedPatientId: patient.id,
                      ),
                      icon: const Icon(Icons.calendar_today_rounded, size: 13),
                      label: Text('حجز موعد', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
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
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
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
