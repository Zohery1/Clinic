import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/data/app_section.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../appointments/presentation/examination_screen.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../patients/presentation/patient_details_dialog.dart';

/// "Today's appointments" section:
/// - Header with total count + completion ratio
/// - Subtle 2px clinical progress bar under the header
/// - Up to 6 list rows with min-height 60px touch target & clean hover
/// - Quick "فحص" button on waiting/active appointments for instant examination access
/// - Empty state with primary CTA
/// - Loading = 5 skeleton rows
/// - Error = `AppErrorState` with retry
class DashboardTodayList extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardTodayList({super.key, this.onNavigateToTab});

  String _formatTime(DateTime date) {
    try {
      return intl.DateFormat('hh:mm a', 'ar').format(date);
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayAppointmentsProvider);
    final user = ref.watch(currentUserProvider);
    final effectiveClinicId = user?.clinicId ?? '';

    Widget child;
    final list = List<AppointmentModel>.from(async.value ?? const [])
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    final total = list.length;
    final completed = list.where((a) => a.status == 'completed').length;
    final progressRatio = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    if (async.isLoading && async.value == null) {
      child = _skeletonList(context);
    } else if (async.hasError && async.value == null) {
      child = AppErrorState(
        title: 'تعذر تحميل المواعيد',
        message: 'حدث خطأ أثناء جلب قائمة مواعيد اليوم. حاول مرة أخرى.',
        onRetry: () => ref.invalidate(todayAppointmentsProvider),
      );
    } else if (list.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: AppEmptyState(
          icon: Icons.event_available_rounded,
          title: 'لا توجد مواعيد اليوم',
          message: 'يومك فارغ حالياً. احجز أول موعد أو راجع جدول المرضى.',
          actionLabel: 'حجز جديد',
          actionIcon: Icons.add_rounded,
          onAction: () {
            showDialog(
              context: context,
              builder: (_) => BookAppointmentDialog(
                clinicId: effectiveClinicId,
              ),
            );
          },
        ),
      );
    } else {
      final display = list.take(6).toList();
      child = Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppRadii.brMd,
          border: Border.all(color: AppColors.borderSubtle(context), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (total > 0) _ClinicalProgressBar(ratio: progressRatio),
            for (int i = 0; i < display.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle(context),
                ),
              _AppointmentRow(
                appt: display[i],
                timeLabel: _formatTime(display[i].appointmentDate),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => PatientDetailsDialog(
                      clinicId: display[i].clinicId,
                      patient: display[i].toPatientModel(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    final subtitle = total > 0
        ? '$total حجز مسجل • $completed مكتمل'
        : '${async.value?.length ?? 0} حجز مسجل';

    return AppSection(
      title: 'مواعيد اليوم',
      subtitle: subtitle,
      action: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => onNavigateToTab?.call(1),
        icon: const Icon(Icons.arrow_back_rounded, size: 14),
        label: Text(
          'عرض الكل',
          style: GoogleFonts.cairo(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _skeletonList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < 5; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderSubtle(context),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  AppSkeleton(width: 56, height: 22, radius: 8),
                  SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(width: 140, height: 13),
                        SizedBox(height: 6),
                        AppSkeleton(width: 96, height: 10),
                      ],
                    ),
                  ),
                  AppSkeleton(width: 56, height: 18, radius: 999),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 2px subtle clinical progress bar showing completion ratio
class _ClinicalProgressBar extends StatelessWidget {
  final double ratio;

  const _ClinicalProgressBar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      width: double.infinity,
      color: AppColors.borderSubtle(context),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: ratio,
        child: Container(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatefulWidget {
  final AppointmentModel appt;
  final String timeLabel;
  final VoidCallback onTap;

  const _AppointmentRow({
    required this.appt,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  State<_AppointmentRow> createState() => _AppointmentRowState();
}

class _AppointmentRowState extends State<_AppointmentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final appt = widget.appt;
    final isDark = AppColors.isDark(context);
    final hoverBg = AppColors.subtle(context).withValues(
      alpha: isDark ? 0.5 : 0.7,
    );

    final isActiveWaiting =
        appt.status != 'completed' && !appt.status.startsWith('cancelled');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        color: _hovered ? hoverBg : Colors.transparent,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.subtle(context),
                        borderRadius: AppRadii.brSm,
                      ),
                      child: Text(
                        widget.timeLabel,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    // Patient name & appointment metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            appt.patient.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                              height: 1.35,
                            ),
                          ),
                          if (appt.doctorName != null ||
                              appt.appointmentTypeName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (appt.doctorName != null &&
                                    appt.doctorName!.isNotEmpty)
                                  DoctorUtils.formatTitle(appt.doctorName),
                                if (appt.appointmentTypeName != null &&
                                    appt.appointmentTypeName!.isNotEmpty)
                                  appt.appointmentTypeName!,
                              ].join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary(context),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    // Quick Action: "فحص" button for active / waiting appointments
                    if (isActiveWaiting) ...[
                      Tooltip(
                        message: 'بدء الكشف الطبي',
                        child: InkWell(
                          borderRadius: AppRadii.brSm,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ExaminationScreen(
                                  clinicId: appt.clinicId,
                                  appointmentId: appt.id,
                                  patientId: appt.patientId,
                                  patientName: appt.patient.fullName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm + 2,
                              vertical: AppSpace.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.22 : 0.10,
                              ),
                              borderRadius: AppRadii.brSm,
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: isDark ? 0.45 : 0.25,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.medical_services_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                if (MediaQuery.of(context).size.width >= 640) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    'فحص',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    AppStatusBadge.fromAppointmentStatus(
                      appt.status,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}