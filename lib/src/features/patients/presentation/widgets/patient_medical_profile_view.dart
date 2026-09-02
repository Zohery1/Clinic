import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/primitives/app_icon_button.dart';
import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/patient_model.dart';
import 'appointment_services_section.dart';
import 'patient_providers.dart';
import 'patient_visit_note_section.dart';
import '../../../../core/widgets/doctor_badge.dart';
import '../../../../core/widgets/send_whatsapp_dialog.dart';

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

    final fileNo = '#';
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
      padding: EdgeInsets.all(AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Info Card
          Container(
            padding: EdgeInsets.all(AppSpace.xl),
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
                SizedBox(width: AppSpace.xl),
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
                          SizedBox(width: AppSpace.md),
                          if (age != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: AppRadii.brSm,
                              ),
                              child: Text(
                                ' سنة',
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
                      SizedBox(height: AppSpace.xs),
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
                                SizedBox(width: AppSpace.xs),
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
                                SizedBox(width: AppSpace.xs),
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
                SizedBox(width: AppSpace.md),
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
                    SizedBox(width: AppSpace.xs),
                    if (user.role == UserRole.doctor) ...[
                      AppIconButton(
                        tooltip: 'حذف المريض',
                        onPressed: onDelete,
                        icon: Icons.delete_outline_rounded,
                        variant: AppIconButtonVariant.subtle,
                        size: AppIconButtonSize.md,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: AppSpace.md),
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
          SizedBox(height: AppSpace.md),

          // Vitals and clinical variables grid
          LayoutBuilder(
            builder: (context, profileConstraints) {
              final isWide = profileConstraints.maxWidth >= 700;

              final statItems = [
                _ClinicalMetaStat(
                  title: 'رقم الهاتف',
                  value: patient.phone != null && patient.phone!.isNotEmpty
                      ? patient.phone!
                      : 'غير مسجل',
                  icon: Icons.phone_rounded,
                  color: AppColors.primary,
                  onActionTap: (patient.phone != null && patient.phone!.isNotEmpty)
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
                  value: age != null ? ' سنة' : 'غير مسجل',
                  icon: Icons.cake_outlined,
                  color: AppColors.warning,
                ),
                _ClinicalMetaStat(
                  title: 'رقم الملف',
                  value: fileNo,
                  icon: Icons.badge_rounded,
                  color: AppColors.completed,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: statItems[0]),
                    SizedBox(width: AppSpace.md),
                    Expanded(child: statItems[1]),
                    SizedBox(width: AppSpace.md),
                    Expanded(child: statItems[2]),
                    SizedBox(width: AppSpace.md),
                    Expanded(child: statItems[3]),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: statItems[0]),
                        SizedBox(width: AppSpace.md),
                        Expanded(child: statItems[1]),
                      ],
                    ),
                    SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Expanded(child: statItems[2]),
                        SizedBox(width: AppSpace.md),
                        Expanded(child: statItems[3]),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: AppSpace.md),

          // Medical History Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.dangerSubtle,
              borderRadius: AppRadii.brMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    SizedBox(width: AppSpace.xs),
                    Text(
                      'السجل المرضي للمريض',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.danger,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpace.xs),
                Text(
                  medicalHistory.isNotEmpty
                      ? medicalHistory
                      : 'لا يوجد سجل مرضي مسجل.',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpace.xl),

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
          SizedBox(height: AppSpace.md),

          // Appointments timeline
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.history_rounded,
                    title: 'لا توجد زيارات سابقة مسجلة للمريض',
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: appointments.length,
                  padding: EdgeInsets.only(top: AppSpace.xs),
                  itemBuilder: (context, index) {
                    final app = appointments[index];
                    final date =
                        intl.DateFormat('yyyy/MM/dd', 'ar').format(app.appointmentDate.toLocal());
                    final time =
                        intl.DateFormat('hh:mm a', 'ar').format(app.appointmentDate.toLocal());

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
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(
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
  }
}

/// Internal stat card for clinical meta items
class _ClinicalMetaStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onActionTap;
  final String? actionTooltip;

  const _ClinicalMetaStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onActionTap,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: EdgeInsets.symmetric(
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
            padding: EdgeInsets.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: AppSpace.sm),
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
                SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                          height: 1.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onActionTap != null) ...[
                      SizedBox(width: AppSpace.xs),
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
      margin: EdgeInsets.only(bottom: AppSpace.xs),
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
              padding: EdgeInsets.all(AppSpace.md),
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
                      SizedBox(width: AppSpace.xs),
                      Text(
                        widget.date,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppColors.textPrimary(context),
                          height: 1.3,
                        ),
                      ),
                      SizedBox(width: AppSpace.sm),
                      Text(
                        widget.time,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
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
                          doctorName: widget.app.doctorName,
                          compact: true,
                        ),
                        SizedBox(width: AppSpace.sm),
                        AppBadge(
                          label: widget.translateStatus(widget.app.status),
                          variant: widget.getStatusBadgeVariant(widget.app.status),
                          size: AppBadgeSize.sm,
                        ),
                        SizedBox(width: AppSpace.xs),
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
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
