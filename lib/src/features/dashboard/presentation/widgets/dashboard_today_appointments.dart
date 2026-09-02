import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/data/app_section.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../patients/presentation/patient_details_dialog.dart';

/// "Today's appointments" section: header + up to 6 list rows + an
/// empty state with primary CTA. Loading = 5 skeleton rows.
/// Error = `AppErrorState` with retry.
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
    if (async.isLoading && async.value == null) {
      child = _skeletonList(context);
    } else if (async.hasError && async.value == null) {
      child = AppErrorState(
        title: 'تعذر تحميل المواعيد',
        message: 'حدث خطأ أثناء جلب قائمة مواعيد اليوم. حاول مرة أخرى.',
        onRetry: () => ref.invalidate(todayAppointmentsProvider),
      );
    } else {
      final list = List<AppointmentModel>.from(async.value ?? const [])
        ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      if (list.isEmpty) {
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
            border:
                Border.all(color: AppColors.borderSubtle(context), width: 1),
          ),
          child: Column(
            children: [
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
    }

    return AppSection(
      title: 'مواعيد اليوم',
      subtitle: '${async.value?.length ?? 0} حجز مسجل',
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  const AppSkeleton(width: 56, height: 22, radius: 8),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppSkeleton(width: 140, height: 13),
                        SizedBox(height: 6),
                        AppSkeleton(width: 96, height: 10),
                      ],
                    ),
                  ),
                  const AppSkeleton(width: 56, height: 18, radius: 999),
                ],
              ),
            ),
          ],
        ],
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
    final hoverBg = AppColors.subtle(context).withValues(
      alpha: AppColors.isDark(context) ? 0.5 : 0.7,
    );

    return Material(
      type: MaterialType.transparency,
      color: _hovered ? hoverBg : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hovered = v),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        height: 1.3,
                      ),
                    ),
                    if (appt.doctorName != null || appt.appointmentTypeName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (appt.doctorName != null && appt.doctorName!.isNotEmpty)
                            'د. ${appt.doctorName}',
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
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              AppStatusBadge.fromAppointmentStatus(appt.status, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}