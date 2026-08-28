import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/doctor_badge.dart';
import '../../../../core/widgets/send_whatsapp_dialog.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/patient_model.dart';
import '../../../data/patient_repository.dart';
import 'patient_avatar.dart';
import 'hover_scale_button.dart';
import 'patient_clinical_meta_item.dart';
import 'patient_timeline_appointment_card.dart';
import 'patient_providers.dart';

/// ويدجت العرض التفصيلي الشامل للملف الطبي للمريض (المعلومات، المؤشرات، التاريخ المرضي، والزيارات)
class PatientMedicalProfileView extends ConsumerWidget {
  final String clinicId;
  final UserModel user;
  final PatientModel patient;
  final Map<String, int> fileNumbers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PatientMedicalProfileView({
    super.key,
    required this.clinicId,
    required this.user,
    required this.patient,
    required this.fileNumbers,
    required this.onEdit,
    required this.onDelete,
  });

  static int? calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static String capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'مع الطبيب';
      case 'confirmed':
        return 'في الانتظار';
      case 'completed':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'في الانتظار';
    }
  }

  static Color getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Theme.of(context).colorScheme.primary;
      case 'confirmed':
        return AppTheme.warning;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = calculateAge(patient.birthDate);
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patient.id));

    final fileNo = '#${fileNumbers[patient.id] ?? ""}';
    final displayAddress = patient.address != null
        ? (patient.address!.contains('|')
            ? patient.address!.split('|').first.trim()
            : patient.address!)
        : '';
    final medicalHistory = patient.medicalHistory ??
        ((patient.address != null && patient.address!.contains('|'))
            ? patient.address!.split('|').last.trim()
            : '');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header Info Card ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                PatientAvatar(
                  gender: patient.gender,
                  radius: 30,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              capitalizeName(patient.fullName),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (age != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$age سنة',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (patient.phone != null && patient.phone!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  patient.phone!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          if (displayAddress.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  displayAddress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Actions buttons
                Row(
                  children: [
                    HoverScaleButton(
                      tooltip: 'تعديل البيانات',
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (user.role == UserRole.doctor) ...[
                      HoverScaleButton(
                        tooltip: 'حذف المريض',
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BookAppointmentDialog(
                            clinicId: clinicId,
                            preselectedPatientId: patient.id,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('حجز موعد جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Vitals and clinical variables grid ───
          LayoutBuilder(
            builder: (context, profileConstraints) {
              final isWide = profileConstraints.maxWidth >= 700;
              final items = [
                PatientClinicalMetaItem(
                  title: 'رقم الهاتف',
                  value: patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : 'غير مسجل',
                  icon: Icons.phone_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  onActionTap: (patient.phone != null && patient.phone!.isNotEmpty)
                      ? () => showSendWhatsAppDialog(context, ref, phone: patient.phone!, patientName: patient.fullName)
                      : null,
                  actionTooltip: 'إرسال رسالة واتساب للمريض',
                ),
                PatientClinicalMetaItem(
                  title: 'العنوان',
                  value: displayAddress.isNotEmpty ? displayAddress : 'غير مسجل',
                  icon: Icons.location_on_outlined,
                  color: AppTheme.success,
                ),
                PatientClinicalMetaItem(
                  title: 'العمر',
                  value: age != null ? '$age سنة' : 'غير مسجل',
                  icon: Icons.cake_outlined,
                  color: AppTheme.warning,
                ),
                PatientClinicalMetaItem(
                  title: 'رقم الملف',
                  value: fileNo,
                  icon: Icons.badge_rounded,
                  color: AppTheme.completed,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    items[0],
                    const SizedBox(width: 12),
                    items[1],
                    const SizedBox(width: 12),
                    items[2],
                    const SizedBox(width: 12),
                    items[3],
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        items[0],
                        const SizedBox(width: 12),
                        items[1],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        items[2],
                        const SizedBox(width: 12),
                        items[3],
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // ─── Medical History Card ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.error, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'السجل المرضي للمريض',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  medicalHistory.isNotEmpty ? medicalHistory : 'لا يوجد سجل مرضي مسجل.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'سجل الزيارات والتشخيص',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 12),

          // Appointments timeline
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return const Center(
                    child: EmptyStateView(
                      icon: Icons.history_rounded,
                      title: 'لا توجد زيارات سابقة مسجلة للمريض',
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: appointments.length,
                  padding: const EdgeInsets.only(top: 8),
                  itemBuilder: (context, index) {
                    final app = appointments[index];
                    final date = intl.DateFormat('yyyy/MM/dd', 'ar').format(app.appointmentDate.toLocal());
                    final time = intl.DateFormat('hh:mm a', 'ar').format(app.appointmentDate.toLocal());
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Stack(
                      children: [
                        if (index != appointments.length - 1)
                          Positioned(
                            top: 16,
                            bottom: 0,
                            right: 5,
                            child: Container(
                              width: 2,
                              color: isDark ? AppTheme.darkBorder : AppTheme.border,
                            ),
                          ),
                        Positioned(
                          top: 4,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 28, bottom: 20),
                          child: PatientTimelineAppointmentCard(
                            app: app,
                            date: date,
                            time: time,
                            clinicId: clinicId,
                            patient: patient,
                            isDoctor: user.role == UserRole.doctor,
                            getStatusColor: getStatusColor,
                            translateStatus: translateStatus,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, _) => ErrorStateView(
                message: 'خطأ: $err',
                onRetry: () => ref.invalidate(patientAppointmentsProvider(patient.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
