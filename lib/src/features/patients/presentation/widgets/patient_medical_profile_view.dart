import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/primitives/app_icon_button.dart';
import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../appointments/presentation/examination_screen.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/patient_repository.dart';
import '../../domain/patient_model.dart';
import 'appointment_services_section.dart';
import 'patient_providers.dart';
import 'patient_visit_note_section.dart';
import '../../../../core/widgets/doctor_badge.dart';
import '../../../../core/widgets/send_whatsapp_dialog.dart';
import '../../../../core/utils/doctor_utils.dart';

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
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patient.id));

    int? resolvedFileNum = fileNumbers[patient.id];
    if (resolvedFileNum == null) {
      final allPatients = ref.watch(patientsListProvider(clinicId)).value ?? <PatientModel>[];
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
              // Header Info Card
              Container(
                padding: EdgeInsets.all(isCompact ? AppSpace.md : AppSpace.xl),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: AppRadii.brMd,
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: patient.fullName,
                  size: AppAvatarSize.lg,
                ),
                const SizedBox(width: AppSpace.xl),
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
                                fontSize: 18,
                                color: AppColors.textPrimary(context),
                                height: 1.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          if (age != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: AppRadii.brSm,
                              ),
                              child: Text(
                                '$age سنة',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
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
                                  color: AppColors.textMuted(context),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  patient.phone!,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: AppColors.textMuted(context),
                                    height: 1.3,
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
                                  color: AppColors.textMuted(context),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  displayAddress,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: AppColors.textMuted(context),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                // Actions buttons
                Row(
                  children: [
                    AppIconButton(
                      tooltip: 'تعديل البيانات',
                      onPressed: onEdit,
                      icon: Icons.edit_rounded,
                      variant: AppIconButtonVariant.subtle,
                      size: AppIconButtonSize.md,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    if (user.role == UserRole.doctor) ...[
                      AppIconButton(
                        tooltip: 'حذف المريض',
                        onPressed: onDelete,
                        icon: Icons.delete_outline_rounded,
                        variant: AppIconButtonVariant.subtle,
                        size: AppIconButtonSize.md,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      AppButton(
                        label: 'فحص المريض',
                        icon: Icons.medical_services_outlined,
                        onPressed: () {
                          final latestAppt = appointmentsAsync.value?.isNotEmpty == true
                              ? appointmentsAsync.value!.first
                              : null;
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ExaminationScreen(
                                clinicId: clinicId,
                                appointmentId: latestAppt?.id ?? '',
                                patientId: patient.id,
                                patientName: patient.fullName,
                              ),
                            ),
                          );
                        },
                        size: AppButtonSize.md,
                        variant: AppButtonVariant.secondary,
                      ),
                      const SizedBox(width: AppSpace.xs),
                    ],
                    AppButton(
                      label: 'حجز موعد جديد',
                      icon: Icons.add_task_rounded,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BookAppointmentDialog(
                            clinicId: clinicId,
                            preselectedPatientId: patient.id,
                          ),
                        );
                      },
                      size: AppButtonSize.md,
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Vitals and clinical variables grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              final statItems = [
                _ClinicalMetaStat(
                  title: 'رقم الهاتف',
                  value: patient.phone != null && patient.phone!.isNotEmpty
                      ? patient.phone!
                      : 'غير مسجل',
                  icon: Icons.phone_android_rounded,
                  color: AppColors.primary,
                  isMonospace: true,
                  onActionTap: patient.phone != null && patient.phone!.isNotEmpty
                      ? () => showSendWhatsAppDialog(
                          context,
                          ref,
                          phone: patient.phone!,
                          patientName: patient.fullName)
                      : null,
                  actionTooltip: 'إرسال رسالة واتساب للمريض',
                ),
                _ClinicalMetaStat(
                  title: 'العنوان',
                  value: displayAddress.isNotEmpty ? displayAddress : 'غير مسجل',
                  icon: Icons.location_on_outlined,
                  color: AppColors.success,
                ),
                _ClinicalMetaStat(
                  title: 'العمر',
                  value: age != null ? '$age سنة' : 'غير مسجل',
                  icon: Icons.cake_outlined,
                  color: AppColors.warning,
                ),
                _ClinicalMetaStat(
                  title: 'رقم الملف',
                  value: fileNo,
                  icon: Icons.badge_rounded,
                  color: AppColors.completed,
                  isMonospace: true,
                ),
              ];

              if (isWide) {
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
              } else {
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
              }
            },
          ),
          const SizedBox(height: AppSpace.md),

          // Medical History Alert Ribbon (Calm neutral if empty, prominent clinical alert if present)
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
            _MedicalHistoryAlertCard(medicalHistory: medicalHistory),
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
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (context) => BookAppointmentDialog(
                          clinicId: clinicId,
                          preselectedPatientId: patient.id,
                        ),
                      );
                    },
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
                          child: _PatientTimelineAppointmentCard(
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
                title: 'حدث خطأ',
                message: 'خطأ: ',
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
}

/// Internal stat card for clinical meta items
class _ClinicalMetaStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isMonospace;
  final VoidCallback? onActionTap;
  final String? actionTooltip;

  const _ClinicalMetaStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isMonospace = false,
    this.onActionTap,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: AppRadii.brSm,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: AppColors.textMuted(context),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: isMonospace
                            ? GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                                height: 1.3,
                              )
                            : GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                                height: 1.3,
                              ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onActionTap != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      Tooltip(
                        message: actionTooltip ?? '',
                        child: AppIconButton(
                          onPressed: onActionTap,
                          icon: Icons.chat_bubble_outline_rounded,
                          variant: AppIconButtonVariant.ghost,
                          size: AppIconButtonSize.sm,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Clinical Alert Card for patient medical history & allergies
class _MedicalHistoryAlertCard extends StatefulWidget {
  final String medicalHistory;

  const _MedicalHistoryAlertCard({required this.medicalHistory});

  @override
  State<_MedicalHistoryAlertCard> createState() =>
      _MedicalHistoryAlertCardState();
}

class _MedicalHistoryAlertCardState extends State<_MedicalHistoryAlertCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final history = widget.medicalHistory.trim();
    final isLong = history.length > 90 || history.contains('\n');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.warningSubtle,
        borderRadius: AppRadii.brMd,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.35 : 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.health_and_safety_rounded,
                    color: isDark ? AppColors.warningBright : AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'تنبيه طبي: التاريخ المرضي والحساسيات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.warningBright
                          : AppColors.warning,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              if (isLong)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: AppRadii.brSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'طي التفاصيل' : 'عرض التفاصيل كاملة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.warningBright
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.warningBright
                              : AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.easeOutCubic,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _isExpanded ? 180 : 44,
              ),
              child: SingleChildScrollView(
                physics: _isExpanded
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Text(
                  history,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                    height: 1.45,
                  ),
                  maxLines: _isExpanded ? null : 2,
                  overflow:
                      _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inlined and modernized timeline appointment card
class _PatientTimelineAppointmentCard extends ConsumerStatefulWidget {
  final AppointmentModel app;
  final String date;
  final String time;
  final String clinicId;
  final PatientModel patient;
  final bool isDoctor;
  final Color Function(BuildContext, String) getStatusColor;
  final String Function(String) translateStatus;
  final AppBadgeVariant Function(String) getStatusBadgeVariant;

  const _PatientTimelineAppointmentCard({
    required this.app,
    required this.date,
    required this.time,
    required this.clinicId,
    required this.patient,
    required this.isDoctor,
    required this.getStatusColor,
    required this.translateStatus,
    required this.getStatusBadgeVariant,
  });

  @override
  ConsumerState<_PatientTimelineAppointmentCard> createState() =>
      _PatientTimelineAppointmentCardState();
}

class _PatientTimelineAppointmentCardState
    extends ConsumerState<_PatientTimelineAppointmentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(
          color: AppColors.borderSubtle(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: AppRadii.brMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.textMuted(context),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        widget.date,
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textPrimary(context),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        widget.time,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DoctorBadge(
                          doctorId: widget.app.doctorId,
                          doctorName: widget.app.doctorName != null
                              ? DoctorUtils.formatTitle(widget.app.doctorName)
                              : null,
                          compact: true,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        AppBadge(
                          label: widget.translateStatus(widget.app.status),
                          variant: widget.getStatusBadgeVariant(widget.app.status),
                          size: AppBadgeSize.sm,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textMuted(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 1,
                        color: AppColors.borderSubtle(context),
                      ),
                      AppointmentServicesSection(appointmentId: widget.app.id),
                      PatientVisitNoteSection(
                        clinicId: widget.clinicId,
                        appointmentId: widget.app.id,
                        patientId: widget.patient.id,
                        patientName: widget.patient.fullName,
                        isDoctor: widget.isDoctor,
                      ),
                      if (widget.isDoctor)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpace.md,
                            left: AppSpace.md,
                            bottom: AppSpace.md,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: AppButton(
                              label: 'فتح شاشة الكشف والفحص الطبي',
                              icon: Icons.open_in_new_rounded,
                              variant: AppButtonVariant.secondary,
                              size: AppButtonSize.sm,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ExaminationScreen(
                                      clinicId: widget.clinicId,
                                      appointmentId: widget.app.id,
                                      patientId: widget.patient.id,
                                      patientName: widget.patient.fullName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
