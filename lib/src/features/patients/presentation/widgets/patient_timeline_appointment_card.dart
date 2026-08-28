import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/doctor_badge.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../domain/patient_model.dart';
import 'appointment_services_section.dart';
import 'patient_visit_note_section.dart';

/// بطاقة موعد في الخط الزمني لسجل زيارات المريض
class PatientTimelineAppointmentCard extends ConsumerStatefulWidget {
  final AppointmentModel app;
  final String date;
  final String time;
  final String clinicId;
  final PatientModel patient;
  final bool isDoctor;
  final Color Function(BuildContext, String) getStatusColor;
  final String Function(String) translateStatus;

  const PatientTimelineAppointmentCard({
    super.key,
    required this.app,
    required this.date,
    required this.time,
    required this.clinicId,
    required this.patient,
    required this.isDoctor,
    required this.getStatusColor,
    required this.translateStatus,
  });

  @override
  ConsumerState<PatientTimelineAppointmentCard> createState() => _PatientTimelineAppointmentCardState();
}

class _PatientTimelineAppointmentCardState extends ConsumerState<PatientTimelineAppointmentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
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
                        const SizedBox(width: 8),
                        StatusPill(
                          label: widget.translateStatus(widget.app.status),
                          color: widget.getStatusColor(context, widget.app.status),
                          compact: true,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Theme.of(context).hintColor.withValues(alpha: 0.5),
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
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
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
