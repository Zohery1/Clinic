import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/feedback/app_empty_state.dart';
import '../../../core/ui/feedback/app_error_state.dart';
import '../../../core/widgets/send_whatsapp_dialog.dart';
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

/// ???? ????? ??? ?????? ?????? (??????? ?? ?????? ???? ??????)
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
        return '?? ??????';
      case 'confirmed':
        return '?? ????????';
      case 'completed':
        return '?????';
      case 'cancelled':
        return '????';
      default:
        return '?? ????????';
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.primary;
      case 'confirmed':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.warning;
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
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(
          backgroundColor: AppColors.surface(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary(context)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '????? ????? ??????',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: AppColors.surface(context),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: patient.gender == 'female'
                        ? AppColors.doctorPalette[4].withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(
                      patient.gender == 'female' ? Icons.woman_rounded : Icons.man_rounded,
                      color: patient.gender == 'female' ? AppColors.doctorPalette[4] : AppColors.primary,
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
                            color: AppColors.textPrimary(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '??? ??? $fileNo',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.primary,
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
                    borderRadius: BorderRadius.circular(AppRadii.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.radiusMd),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '?????',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      PatientClinicalMetaItem(
                        title: '??? ??????',
                        value: patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : '??? ????',
                        icon: Icons.phone_rounded,
                        color: AppColors.primary,
                        onActionTap: (patient.phone != null && patient.phone!.isNotEmpty)
                            ? () => showSendWhatsAppDialog(context, ref, phone: patient.phone!, patientName: patient.fullName)
                            : null,
                        actionIcon: Icons.chat_bubble_outline_rounded,
                        actionColor: AppColors.success,
                        actionTooltip: '????? ????? ?????? ??????',
                      ),
                      const SizedBox(width: AppSpace.sm),
                      PatientClinicalMetaItem(
                        title: '???????',
                        value: displayAddress.isNotEmpty ? displayAddress : '??? ????',
                        icon: Icons.location_on_outlined,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      PatientClinicalMetaItem(
                        title: '?????',
                        value: age != null ? '$age ???' : '??? ????',
                        icon: Icons.cake_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      PatientClinicalMetaItem(
                        title: '??? ?????',
                        value: fileNo,
                        icon: Icons.badge_rounded,
                        color: AppColors.completed,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _buildMedicalHistoryCard(context, medicalHistory),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          icon: const Icon(Icons.add_task_rounded, size: 20),
          label: const Text('??? ????', style: TextStyle(fontWeight: FontWeight.w700)),
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
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusLg),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.xxl, AppSpace.xl, AppSpace.xxl, AppSpace.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpace.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.radiusMd),
                          ),
                          child: const Icon(Icons.assignment_ind_outlined,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: AppSpace.lg),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '????? ?????',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '?????? ?????? ???? ???????',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary(context).withValues(alpha: 0.7),
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
              Divider(height: 1, color: AppColors.borderSubtle(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpace.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(
                              patient.gender == 'female' ? Icons.woman_rounded : Icons.man_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: AppSpace.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _capitalizeName(patient.fullName),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text('??? ??? $fileNo', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                            label: const Text('??? ????'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xl),
                      Row(
                        children: [
                          PatientClinicalMetaItem(
                            title: '??? ??????',
                            value: patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : '??? ????',
                            icon: Icons.phone_rounded,
                            color: AppColors.primary,
                            onActionTap: (patient.phone != null && patient.phone!.isNotEmpty)
                                ? () => showSendWhatsAppDialog(context, ref, phone: patient.phone!, patientName: patient.fullName)
                                : null,
                            actionIcon: Icons.chat_bubble_outline_rounded,
                            actionColor: AppColors.success,
                            actionTooltip: '????? ????? ?????? ??????',
                          ),
                          const SizedBox(width: AppSpace.md),
                          PatientClinicalMetaItem(
                            title: '???????',
                            value: displayAddress.isNotEmpty ? displayAddress : '??? ????',
                            icon: Icons.location_on_outlined,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpace.md),
                          PatientClinicalMetaItem(
                            title: '?????',
                            value: age != null ? '$age ???' : '??? ????',
                            icon: Icons.cake_outlined,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpace.md),
                          PatientClinicalMetaItem(
                            title: '??? ?????',
                            value: fileNo,
                            icon: Icons.badge_rounded,
                            color: AppColors.completed,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      _buildMedicalHistoryCard(context, medicalHistory),
                      const SizedBox(height: AppSpace.xxl),
                      const Text('??? ???????? ????????', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: AppSpace.md),
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
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSubtle.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.danger, size: 16),
              SizedBox(width: AppSpace.xs),
              Text(
                '????? ?????? ??????',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            medicalHistory.isNotEmpty ? medicalHistory : '?? ???? ??? ???? ????.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
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
            padding: EdgeInsets.symmetric(vertical: AppSpace.xxl),
            child: Center(
              child: AppEmptyState(
                icon: Icons.history_rounded,
                title: '?? ???? ?????? ????? ????? ??????',
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
            final isDark = AppColors.isDark(context);

            return Stack(
              children: [
                if (index != appointments.length - 1)
                  Positioned(
                    top: 16,
                    bottom: 0,
                    right: 5,
                    child: Container(
                      width: 2,
                      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
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
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => AppErrorState(
        title: '???',
        message: '???: $err',
        onRetry: () => ref.invalidate(patientAppointmentsProvider(patient.id)),
      ),
    );
  }
}
