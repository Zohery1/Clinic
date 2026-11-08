import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/routing/routing.dart';
import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';

/// The clinic's morning brief: who you are, what today holds, and the next
/// patient walking in. Deep sapphire anchors the whole canvas.
class DashboardGreetingHero extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardGreetingHero({super.key, this.onNavigateToTab});

  String _formatDate() {
    try {
      return intl.DateFormat('EEEE، d MMMM', 'ar').format(DateTime.now());
    } catch (_) {
      return '';
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    return 'مساء الخير';
  }

  String _time(DateTime date) {
    try {
      return intl.DateFormat('hh:mm a', 'ar').format(date);
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
  }

  AppointmentModel? _nextUp(List<AppointmentModel> list) {
    final now = DateTime.now();
    final upcoming = list
        .where((a) =>
            a.status != 'completed' &&
            !a.status.startsWith('cancelled') &&
            a.appointmentDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final appointments = ref.watch(todayAppointmentsProvider).value ??
        const <AppointmentModel>[];

    final displayName = user?.fullName ?? 'دكتور';
    final isDoctor = user?.role == UserRole.doctor;
    final greetingName =
        isDoctor ? DoctorUtils.formatTitle(displayName) : displayName;

    final waiting = appointments
        .where((a) =>
            a.status != 'completed' && !a.status.startsWith('cancelled'))
        .length;
    final next = _nextUp(appointments);

    final insight = appointments.isEmpty
        ? 'لا توجد مواعيد مسجلة اليوم حتى الآن.'
        : waiting == 0
            ? 'اكتملت جميع كشوفات اليوم بنجاح.'
            : '$waiting في صالة الانتظار حالياً.';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[AppColors.primaryDark, Color(0xFF111C3D)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDark
                .withValues(alpha: AppColors.isDark(context) ? 0.28 : 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            left: -70,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xxl,
              vertical: AppSpace.xl + 2,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 760;

                final copy = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.62),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      '${_greeting()}، $greetingName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: narrow ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      insight,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryInk,
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.xl,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.radiusSm),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'حجز موعد',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            AppNavigation.showBookAppointment(
                              context,
                              clinicId: user?.clinicId ?? '',
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 42),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.radiusSm),
                            ),
                          ),
                          icon:
                              const Icon(Icons.event_note_rounded, size: 17),
                          label: const Text(
                            'جدول اليوم',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => onNavigateToTab?.call(1),
                        ),
                      ],
                    ),
                  ],
                );

                final nextCard = _NextPatientCard(
                  appointment: next,
                  timeLabel: next == null ? null : _time(next.appointmentDate),
                  onTap: () => onNavigateToTab?.call(1),
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      if (next != null) ...[
                        const SizedBox(height: AppSpace.lg),
                        nextCard,
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    if (next != null) ...[
                      const SizedBox(width: AppSpace.xxl),
                      SizedBox(width: 300, child: nextCard),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPatientCard extends StatelessWidget {
  final AppointmentModel? appointment;
  final String? timeLabel;
  final VoidCallback onTap;

  const _NextPatientCard({
    required this.appointment,
    required this.onTap,
    this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final appt = appointment;
    if (appt == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Ink(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              AppAvatar(
                name: appt.patient.fullName,
                size: AppAvatarSize.md,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الموعد القادم',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appt.patient.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      timeLabel ?? '',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.70),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
