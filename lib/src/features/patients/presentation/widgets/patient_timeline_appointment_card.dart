import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../../core/widgets/doctor_badge.dart';
import '../../../../core/routing/routing.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../domain/patient_model.dart';
import 'appointment_services_section.dart';
import 'patient_visit_note_section.dart';

/// كارت خط زمني تفاعلي لموعد أو زيارة المريض
class PatientTimelineAppointmentCard extends ConsumerStatefulWidget {
  final AppointmentModel app;
  final String date;
  final String time;
  final String clinicId;
  final PatientModel patient;
  final bool isDoctor;
  final Color Function(BuildContext, String)? getStatusColor;
  final String Function(String)? translateStatus;
  final AppBadgeVariant Function(String)? getStatusBadgeVariant;

  const PatientTimelineAppointmentCard({
    super.key,
    required this.app,
    required this.date,
    required this.time,
    required this.clinicId,
    required this.patient,
    required this.isDoctor,
    this.getStatusColor,
    this.translateStatus,
    this.getStatusBadgeVariant,
  });

  static String defaultTranslateStatus(String status) {
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

  static AppBadgeVariant defaultBadgeVariant(String status) {
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
  ConsumerState<PatientTimelineAppointmentCard> createState() =>
      _PatientTimelineAppointmentCardState();
}

class _PatientTimelineAppointmentCardState
    extends ConsumerState<PatientTimelineAppointmentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final statusText = widget.translateStatus != null
        ? widget.translateStatus!(widget.app.status)
        : PatientTimelineAppointmentCard.defaultTranslateStatus(widget.app.status);

    final badgeVariant = widget.getStatusBadgeVariant != null
        ? widget.getStatusBadgeVariant!(widget.app.status)
        : PatientTimelineAppointmentCard.defaultBadgeVariant(widget.app.status);

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
                          label: statusText,
                          variant: badgeVariant,
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
                              onPressed: () => AppNavigation.toExamination(
                                context,
                                clinicId: widget.clinicId,
                                appointmentId: widget.app.id,
                                patientId: widget.patient.id,
                                patientName: widget.patient.fullName,
                              ),
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
