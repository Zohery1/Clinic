import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/primitives/app_icon_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/routing/routing.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/patient_repository.dart';
import '../../domain/patient_model.dart';
import 'clinical_meta_stat.dart';
import 'medical_history_alert_card.dart';
import 'patient_providers.dart';
import 'patient_timeline_appointment_card.dart';

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
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
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

  static AppBadgeVariant getStatusBadgeVariant(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppBadgeVariant.info;
      case 'confirmed':
        return AppBadgeVariant.warning;
      case 'completed':
        return AppBadgeVariant.success;
      case 'cancelled':
        return AppBadgeVariant.danger;
      default:
        return AppBadgeVariant.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = calculateAge(patient.birthDate);
    final appointmentsAsync =
        ref.watch(patientAppointmentsProvider(patient.id));

    int? resolvedFileNum = fileNumbers[patient.id];
    if (resolvedFileNum == null) {
      final allPatients =
          ref.watch(patientsListProvider(clinicId)).value ?? <PatientModel>[];
      final sortedFull = List<PatientModel>.from(allPatients)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final idx = sortedFull.indexWhere((p) => p.id == patient.id);
      if (idx != -1) {
        resolvedFileNum = idx + 1;
      }
    }
    final fileNo = resolvedFileNum != null ? '#$resolvedFileNum' : '#';
    final displayAddress = patient.address != null
        ? (patient.address!.contains('|')
            ? patient.address!.split('|').first.trim()
            : patient.address!)
        : '';
    final medicalHistory = patient.medicalHistory ??
        ((patient.address != null && patient.address!.contains('|'))
            ? patient.address!.split('|').last.trim()
            : '');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        return Padding(
          padding: EdgeInsets.all(isCompact ? AppSpace.md : AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info Card - Clinical EMR Banner
              Container(
                padding: EdgeInsets.all(isCompact ? AppSpace.md : AppSpace.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: AppRadii.brLg,
                  border: Border.all(
                    color: AppColors.borderSubtle(context),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: AppColors.isDark(context) ? 0.25 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAvatar(
                          name: patient.fullName,
                          size: isCompact ? AppAvatarSize.md : AppAvatarSize.lg,
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      capitalizeName(patient.fullName),
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w800,
                                        fontSize: isCompact ? 16 : 19,
                                        color: AppColors.textPrimary(context),
                                        height: 1.25,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  if (age != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySubtle,
                                        borderRadius: AppRadii.brSm,
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        '$age سنة',
                                        style: GoogleFonts.cairo(
                                          color: AppColors.primary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: AppSpace.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.subtle(context),
                                      borderRadius: AppRadii.brSm,
                                    ),
                                    child: Text(
                                      fileNo,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Wrap(
                                spacing: 14,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (patient.phone != null &&
                                      patient.phone!.isNotEmpty)
                                    InkWell(
                                      onTap: () => AppNavigation.showWhatsApp(
                                        context,
                                        phone: patient.phone!,
                                        patientName: patient.fullName,
                                      ),
                                      borderRadius: AppRadii.brSm,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 14,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            patient.phone!,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 12,
                                              color: AppColors.textSecondary(
                                                  context),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (displayAddress.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: AppColors.textMuted(context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          displayAddress,
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: AppColors.textSecondary(
                                                context),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isCompact)
                          _buildProfileActions(context, ref, isCompact: false),
                      ],
                    ),
                    if (isCompact) ...[
                      const SizedBox(height: AppSpace.md),
                      _buildProfileActions(context, ref, isCompact: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Clinical Meta Grid
              LayoutBuilder(
                builder: (context, boxConstraints) {
                  final isTight = boxConstraints.maxWidth < 650;
                  final registeredDate = intl.DateFormat('yyyy/MM/dd')
                      .format(patient.createdAt.toLocal());
                  final statItems = [
                    ClinicalMetaStat(
                      title: 'رقم الملف',
                      value: fileNo,
                      icon: Icons.folder_shared_outlined,
                      color: AppColors.primary,
                      isMonospace: true,
                    ),
                    ClinicalMetaStat(
                      title: 'تاريخ التسجيل',
                      value: registeredDate,
                      icon: Icons.calendar_today_outlined,
                      color: AppColors.info,
                      isMonospace: true,
                    ),
                    ClinicalMetaStat(
                      title: 'الهاتف',
                      value: patient.phone?.isNotEmpty == true
                          ? patient.phone!
                          : 'غير مسجل',
                      icon: Icons.phone_outlined,
                      color: AppColors.success,
                      isMonospace: true,
                      onActionTap: patient.phone?.isNotEmpty == true
                          ? () => AppNavigation.showWhatsApp(
                                context,
                                phone: patient.phone!,
                                patientName: patient.fullName,
                              )
                          : null,
                      actionTooltip: 'إرسال رسالة واتساب',
                    ),
                    ClinicalMetaStat(
                      title: 'العنوان',
                      value: displayAddress.isNotEmpty
                          ? displayAddress
                          : 'غير مسجل',
                      icon: Icons.location_on_outlined,
                      color: AppColors.warning,
                    ),
                  ];

                  if (isTight) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: statItems[0]),
                            const SizedBox(width: AppSpace.md),
                            Expanded(child: statItems[1]),
                          ],
                        ),
                        const SizedBox(height: AppSpace.md),
                        Row(
                          children: [
                            Expanded(child: statItems[2]),
                            const SizedBox(width: AppSpace.md),
                            Expanded(child: statItems[3]),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: statItems[0]),
                        const SizedBox(width: AppSpace.md),
                        Expanded(child: statItems[1]),
                        const SizedBox(width: AppSpace.md),
                        Expanded(child: statItems[2]),
                        const SizedBox(width: AppSpace.md),
                        Expanded(child: statItems[3]),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpace.md),

              // Medical History Alert Ribbon
              if (medicalHistory.trim().isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context),
                    borderRadius: AppRadii.brMd,
                    border: Border.all(
                      color: AppColors.borderSubtle(context),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.textMuted(context),
                        size: 18,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        'لا توجد أمراض مزمنة أو حساسيات مسجلة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                )
              else
                MedicalHistoryAlertCard(medicalHistory: medicalHistory),
              const SizedBox(height: AppSpace.xl),

              // Title
              Text(
                'سجل الزيارات والتشخيص',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // Appointments timeline
              Expanded(
                child: appointmentsAsync.when(
                  data: (appointments) {
                    if (appointments.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.history_rounded,
                        title: 'لا توجد زيارات سابقة مسجلة للمريض',
                        message:
                            'يمكنك بدء متابعة المريض وحجز موعد جديد لإجراء الكشف وتدوين الملاحظات الطبية.',
                        actionLabel: 'حجز موعد الآن',
                        actionIcon: Icons.add_task_rounded,
                        onAction: () => AppNavigation.showBookAppointment(
                          context,
                          clinicId: clinicId,
                          preselectedPatientId: patient.id,
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: appointments.length,
                      padding: const EdgeInsets.only(top: AppSpace.xs),
                      itemBuilder: (context, index) {
                        final app = appointments[index];
                        final date = intl.DateFormat('yyyy/MM/dd')
                            .format(app.appointmentDate.toLocal());
                        final time = intl.DateFormat('hh:mm a')
                            .format(app.appointmentDate.toLocal());

                        return Stack(
                          children: [
                            if (index != appointments.length - 1)
                              Positioned(
                                top: 16,
                                bottom: 0,
                                right: 5,
                                child: Container(
                                  width: 2,
                                  color: AppColors.borderSubtle(context),
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
                              padding: const EdgeInsetsDirectional.only(
                                start: 28,
                                bottom: AppSpace.md,
                              ),
                              child: PatientTimelineAppointmentCard(
                                app: app,
                                date: date,
                                time: time,
                                clinicId: clinicId,
                                patient: patient,
                                isDoctor: user.role == UserRole.doctor,
                                getStatusColor: getStatusColor,
                                translateStatus: translateStatus,
                                getStatusBadgeVariant: getStatusBadgeVariant,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSkeletonCircle(size: 24),
                        SizedBox(height: AppSpace.md),
                        AppSkeletonText(width: 120, fontSize: 13),
                      ],
                    ),
                  ),
                  error: (err, _) => AppErrorState(
                    title: 'تعذر تحميل السجل الطبي',
                    message: 'حدث خطأ أثناء تحميل سجل زيارات المريض، يرجى إعادة المحاولة.',
                    onRetry: () =>
                        ref.invalidate(patientAppointmentsProvider(patient.id)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileActions(BuildContext context, WidgetRef ref,
      {required bool isCompact}) {
    final appointmentsAsync =
        ref.watch(patientAppointmentsProvider(patient.id));

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppIconButton(
          tooltip: 'تعديل البيانات',
          onPressed: onEdit,
          icon: Icons.edit_rounded,
          variant: AppIconButtonVariant.subtle,
          size: isCompact ? AppIconButtonSize.sm : AppIconButtonSize.md,
          color: AppColors.primary,
        ),
        if (user.role == UserRole.doctor) ...[
          AppIconButton(
            tooltip: 'حذف المريض',
            onPressed: onDelete,
            icon: Icons.delete_outline_rounded,
            variant: AppIconButtonVariant.subtle,
            size: isCompact ? AppIconButtonSize.sm : AppIconButtonSize.md,
            color: AppColors.danger,
          ),
          AppButton(
            label: 'فحص المريض',
            icon: Icons.medical_services_outlined,
            expand: false,
            onPressed: () {
              final latestAppt = appointmentsAsync.value?.isNotEmpty == true
                  ? appointmentsAsync.value!.first
                  : null;
              AppNavigation.toExamination(
                context,
                clinicId: clinicId,
                appointmentId: latestAppt?.id ?? '',
                patientId: patient.id,
                patientName: patient.fullName,
              );
            },
            size: isCompact ? AppButtonSize.sm : AppButtonSize.md,
            variant: AppButtonVariant.secondary,
          ),
        ],
        AppButton(
          label: 'حجز موعد جديد',
          icon: Icons.add_task_rounded,
          expand: false,
          onPressed: () => AppNavigation.showBookAppointment(
            context,
            clinicId: clinicId,
            preselectedPatientId: patient.id,
          ),
          size: isCompact ? AppButtonSize.sm : AppButtonSize.md,
          variant: AppButtonVariant.primary,
        ),
      ],
    );
  }
}
