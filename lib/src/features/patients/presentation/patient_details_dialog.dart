import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/send_whatsapp_dialog.dart';
import '../../../core/widgets/state_views.dart';
import '../../appointments/presentation/book_appointment_dialog.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../domain/patient_model.dart';
import '../data/patient_repository.dart';
import 'widgets/edit_patient_dialog.dart';
import 'widgets/patient_clinical_meta_item.dart';
import 'widgets/patient_timeline_appointment_card.dart';
import 'widgets/patient_providers.dart';

export 'widgets/patient_providers.dart';
export 'widgets/appointment_services_section.dart';
export 'widgets/patient_visit_note_section.dart';

/// حوار وشاشة عرض تفاصيل المريض (متوافقة مع الهاتف وسطح المكتب)
class PatientDetailsDialog extends ConsumerWidget {
  final String clinicId;
  final PatientModel patient;

  const PatientDetailsDialog({
    super.key,
    required this.clinicId,
    required this.patient,
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

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _translateStatus(String status) {
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

  Color _getStatusColor(BuildContext context, String status) {
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
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patient.id));
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final age = _calculateAge(patient.birthDate);

    final displayAddress = patient.address != null
        ? (patient.address!.contains('|')
            ? patient.address!.split('|').first.trim()
            : patient.address!)
        : '';
    final medicalHistory = patient.medicalHistory ??
        ((patient.address != null && patient.address!.contains('|'))
            ? patient.address!.split('|').last.trim()
            : '');

    final patientsAsync = ref.watch(patientsListProvider(clinicId));
    final fullPatients = patientsAsync.value ?? [];
    final sortedFullPatients = List<PatientModel>.from(fullPatients)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final index = sortedFullPatients.indexWhere((p) => p.id == patient.id);
    final fileNo = index != -1 ? '#${index + 1}' : '';

    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return _buildMobileScreen(context, ref, appointmentsAsync, currentUser, isDoctor, age, fileNo, displayAddress, medicalHistory);
    } else {
      return _buildDesktopDialog(context, ref, appointmentsAsync, currentUser, isDoctor, age, fileNo, displayAddress, medicalHistory);
    }
  }

  Widget _buildMobileScreen(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> appointmentsAsync,
    UserModel? currentUser,
    bool isDoctor,
    int? age,
    String fileNo,
    String displayAddress,
    String medicalHistory,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.titleLarge?.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الملف الطبي للمريض',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: patient.gender == 'female'
                        ? AppTheme.doctorPalette[4].withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      patient.gender == 'female' ? Icons.woman_rounded : Icons.man_rounded,
                      color: patient.gender == 'female' ? AppTheme.doctorPalette[4] : Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizeName(patient.fullName),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ملف رقم $fileNo',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => EditPatientDialog(
                          clinicId: clinicId,
                          patient: patient,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'تعديل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      PatientClinicalMetaItem(
                        title: 'رقم الهاتف',
                        value: patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : 'غير مسجل',
                        icon: Icons.phone_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        onActionTap: (patient.phone != null && patient.phone!.isNotEmpty)
                            ? () => showSendWhatsAppDialog(context, ref, phone: patient.phone!, patientName: patient.fullName)
                            : null,
                        actionIcon: Icons.chat_bubble_outline_rounded,
                        actionColor: AppTheme.success,
                        actionTooltip: 'إرسال رسالة واتساب للمريض',
                      ),
                      const SizedBox(width: 8),
                      PatientClinicalMetaItem(
                        title: 'العنوان',
                        value: displayAddress.isNotEmpty ? displayAddress : 'غير مسجل',
                        icon: Icons.location_on_outlined,
                        color: AppTheme.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      PatientClinicalMetaItem(
                        title: 'العمر',
                        value: age != null ? '$age سنة' : 'غير مسجل',
                        icon: Icons.cake_outlined,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      PatientClinicalMetaItem(
                        title: 'رقم الملف',
                        value: fileNo,
                        icon: Icons.badge_rounded,
                        color: AppTheme.completed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMedicalHistoryCard(context, medicalHistory),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAppointmentsTimeline(context, ref, isDoctor),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => BookAppointmentDialog(
                clinicId: clinicId,
                preselectedPatientId: patient.id,
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          icon: const Icon(Icons.add_task_rounded, size: 20),
          label: const Text('حجز موعد', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildDesktopDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> appointmentsAsync,
    UserModel? currentUser,
    bool isDoctor,
    int? age,
    String fileNo,
    String displayAddress,
    String medicalHistory,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment_ind_outlined,
                              color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الملف الطبي',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'بيانات المريض وسجل زياراته',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            child: Icon(
                              patient.gender == 'female' ? Icons.woman_rounded : Icons.man_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _capitalizeName(patient.fullName),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text('ملف رقم $fileNo', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
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
                            label: const Text('حجز موعد'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          PatientClinicalMetaItem(
                            title: 'رقم الهاتف',
                            value: patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : 'غير مسجل',
                            icon: Icons.phone_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            onActionTap: (patient.phone != null && patient.phone!.isNotEmpty)
                                ? () => showSendWhatsAppDialog(context, ref, phone: patient.phone!, patientName: patient.fullName)
                                : null,
                            actionIcon: Icons.chat_bubble_outline_rounded,
                            actionColor: AppTheme.success,
                            actionTooltip: 'إرسال رسالة واتساب للمريض',
                          ),
                          const SizedBox(width: 12),
                          PatientClinicalMetaItem(
                            title: 'العنوان',
                            value: displayAddress.isNotEmpty ? displayAddress : 'غير مسجل',
                            icon: Icons.location_on_outlined,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 12),
                          PatientClinicalMetaItem(
                            title: 'العمر',
                            value: age != null ? '$age سنة' : 'غير مسجل',
                            icon: Icons.cake_outlined,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 12),
                          PatientClinicalMetaItem(
                            title: 'رقم الملف',
                            value: fileNo,
                            icon: Icons.badge_rounded,
                            color: AppTheme.completed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMedicalHistoryCard(context, medicalHistory),
                      const SizedBox(height: 24),
                      const Text('سجل الزيارات والتشخيص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      _buildAppointmentsTimeline(context, ref, isDoctor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryCard(BuildContext context, String medicalHistory) {
    return Container(
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
    );
  }

  Widget _buildAppointmentsTimeline(BuildContext context, WidgetRef ref, bool isDoctor) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patient.id));

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: EmptyStateView(
                icon: Icons.history_rounded,
                title: 'لا توجد زيارات سابقة مسجلة للمريض',
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
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
                    isDoctor: isDoctor,
                    getStatusColor: _getStatusColor,
                    translateStatus: _translateStatus,
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
    );
  }
}
