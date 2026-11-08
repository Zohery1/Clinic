import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/routing/routing.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/utils/appointment_status.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/ui/tokens/typography.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../auth/presentation/login_controller.dart';

/// Today's queue as a quiet timeline: time, patient, state, one action.
class DashboardTodayList extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardTodayList({super.key, this.onNavigateToTab});

  String _formatTime(DateTime date) {
    try {
      return intl.DateFormat('hh:mm', 'ar').format(date);
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _period(DateTime date) {
    try {
      return intl.DateFormat('a', 'ar').format(date);
    } catch (_) {
      return date.hour < 12 ? 'ص' : 'م';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayAppointmentsProvider);
    final user = ref.watch(currentUserProvider);
    final effectiveClinicId = user?.clinicId ?? '';

    final list = List<AppointmentModel>.from(async.value ?? const [])
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    final total = list.length;
    final completed = list.where((a) => a.status == 'completed').length;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    Widget body;
    if (async.isLoading && async.value == null) {
      body = _skeleton(context);
    } else if (async.hasError && async.value == null) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: AppErrorState(
          title: 'تعذر تحميل المواعيد',
          message: 'تعذر الاتصال لتحميل كشوفات اليوم، يرجى إعادة المحاولة.',
          onRetry: () => ref.invalidate(todayAppointmentsProvider),
        ),
      );
    } else if (list.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
        child: AppEmptyState(
          icon: Icons.event_note_outlined,
          title: 'لا توجد مواعيد مسجلة اليوم',
          message: 'ابدأ بحجز موعد جديد أو إدخال مريض للطابور.',
          actionLabel: 'حجز موعد جديد',
          actionIcon: Icons.add_rounded,
          onAction: () => AppNavigation.showBookAppointment(
            context,
            clinicId: effectiveClinicId,
          ),
        ),
      );
    } else {
      final display = list.take(7).toList();
      body = Column(
        children: [
          for (int i = 0; i < display.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
                color: AppColors.borderSubtle(context),
              ),
            _QueueRow(
              appointment: display[i],
              timeLabel: _formatTime(display[i].appointmentDate),
              period: _period(display[i].appointmentDate),
              onOpen: () {
                if (display[i].status == 'completed') {
                  AppNavigation.showPatientDetails(
                    context,
                    clinicId: display[i].clinicId,
                    patient: display[i].toPatientModel(),
                  );
                } else {
                  AppNavigation.toExamination(
                    context,
                    clinicId: display[i].clinicId,
                    appointmentId: display[i].id,
                    patientId: display[i].patientId,
                    patientName: display[i].patient.fullName,
                  );
                }
              },
            ),
          ],
        ],
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg + 2,
              AppSpace.lg,
              AppSpace.md,
              AppSpace.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context)
                        .withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.09),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.people_alt_outlined,
                    size: 16,
                    color: AppColors.accent(context),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  'مواعيد اليوم',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    '$total',
                    style: AppTypography.numericSm(
                      AppColors.textSecondary(context),
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(1),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.accent(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text(
                    'الجدول الكامل',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppColors.subtle(context),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accent(context),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpace.sm),
          body,
        ],
      ),
    );
  }

  Widget _skeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.sm),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.subtle(context),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final AppointmentModel appointment;
  final String timeLabel;
  final String period;
  final VoidCallback onOpen;

  const _QueueRow({
    required this.appointment,
    required this.timeLabel,
    required this.period,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final isCompleted = status == 'completed';
    final isWaiting = status == 'waiting' || status == 'confirmed';
    final isActive = status == 'in_progress';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;

        return Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onOpen,
            hoverColor: AppColors.accent(context).withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeLabel,
                          style: AppTypography.numericSm(
                            AppColors.textPrimary(context),
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          period,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted(context),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    width: 2,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _statusColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  AppAvatar(
                    name: appointment.patient.fullName,
                    size: AppAvatarSize.sm,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appointment.patient.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(context),
                            height: 1.35,
                          ),
                        ),
                        Text(
                          appointment.appointmentTypeName ?? 'كشف عيادة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted(context),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: AppSpace.sm),
                    _StatusPill(status: status),
                  ],
                  const SizedBox(width: AppSpace.sm),
                  if (isWaiting || isActive)
                    SizedBox(
                      height: 32,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent(context),
                          foregroundColor: AppColors.onAccent(context),
                          minimumSize: const Size(0, 32),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.radiusSm),
                          ),
                        ),
                        onPressed: onOpen,
                        child: compact
                            ? const Icon(Icons.play_arrow_rounded, size: 16)
                            : const Text(
                                'بدء',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    )
                  else
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        isCompleted
                            ? Icons.receipt_long_outlined
                            : Icons.chevron_left_rounded,
                        size: 17,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(BuildContext context) {
    switch (appointment.status) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.accent(context);
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color base;
    late final String label;

    switch (status) {
      case 'completed':
        base = AppColors.success;
        break;
      case 'in_progress':
        base = AppColors.accent(context);
        break;
      case 'cancelled_by_patient':
      case 'cancelled_by_clinic':
      case 'cancelled':
        base = AppColors.danger;
        break;
      case 'confirmed':
        base = AppColors.warning;
        break;
      default:
        base = AppColors.warning;
    }
    label = appointmentStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tint(context, base, light: 0.09, dark: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: AppColors.tintBorder(context, base)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.tintText(context, base),
          height: 1.4,
        ),
      ),
    );
  }
}
