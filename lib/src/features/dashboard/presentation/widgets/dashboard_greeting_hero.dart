import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../appointments/presentation/examination_screen.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';

/// Full-width hero panel above the dashboard stats.
/// Subtle primary gradient, calm clinical status pill, greeting in Cairo with safe
/// line heights, contextual subtitle with today's appointment counts,
/// primary CTA + secondary link.
class DashboardGreetingHero extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardGreetingHero({super.key, this.onNavigateToTab});

  String _formatDate() {
    try {
      return intl.DateFormat('EEEE، d MMMM y', 'ar').format(DateTime.now());
    } catch (_) {
      return '';
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء النور';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final isDark = AppColors.isDark(context);

    final displayName = user?.fullName ?? 'دكتور';
    final isDoctor = user?.role == UserRole.doctor;
    final greetingName =
        isDoctor ? DoctorUtils.formatTitle(displayName) : displayName;

    final total = appointmentsAsync.value?.length ?? 0;
    final completed = appointmentsAsync.value
            ?.where((a) => a.status == 'completed')
            .length ??
        0;
    final waiting = appointmentsAsync.value
            ?.where(
                (a) => a.status != 'completed' && !a.status.startsWith('cancelled'))
            .length ??
        0;
    final inProgress = appointmentsAsync.value
        ?.where((a) => a.status == 'pending')
        .firstOrNull;
    final waitingList = appointmentsAsync.value
        ?.where((a) => a.status == 'confirmed')
        .toList();
    if (waitingList != null && waitingList.length > 1) {
      waitingList.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    }
    final nextWaiting = waitingList?.firstOrNull;

    final effectiveClinicId = user?.clinicId ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brLg,
        border: Border.all(
          color: AppColors.borderSubtle(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle top brand accent line (2px)
          Positioned(
            top: 0,
            left: AppSpace.xl,
            right: AppSpace.xl,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.6 : 0.8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpace.xl,
              horizontal: AppSpace.xl,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 700;
                final textWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: [
                        Text(
                          '${_greeting()} · ${_formatDate()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: AppColors.primary,
                            height: 1.4,
                          ),
                        ),
                        // Live clinical status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (waiting > 0 ? AppColors.primary : AppColors.success)
                                .withValues(alpha: isDark ? 0.18 : 0.08),
                            borderRadius: AppRadii.brFull,
                            border: Border.all(
                              color: (waiting > 0 ? AppColors.primary : AppColors.success)
                                  .withValues(alpha: isDark ? 0.40 : 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: waiting > 0
                                      ? AppColors.primary
                                      : AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                waiting > 0
                                    ? 'العيادة نشطة • $waiting في الانتظار'
                                    : 'جاهز للاستقبال',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: waiting > 0
                                      ? AppColors.primary
                                      : AppColors.success,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs + 2),
                    Text(
                      'مرحباً، $greetingName 👋',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    if (appointmentsAsync.isLoading)
                      Text(
                        'جارٍ تحميل جدول اليوم…',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(context),
                          height: 1.5,
                        ),
                      )
                    else if (total == 0)
                      Text(
                        'لا توجد مواعيد اليوم. ابدأ يومك بإضافة مريض جديد أو حجز كشف.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(context),
                          height: 1.5,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildCountBadge(
                            context: context,
                            label: 'إجمالي المواعيد',
                            count: total,
                            color: AppColors.primary,
                          ),
                          _buildCountBadge(
                            context: context,
                            label: 'المكتمل',
                            count: completed,
                            color: AppColors.success,
                          ),
                          _buildCountBadge(
                            context: context,
                            label: 'في الانتظار',
                            count: waiting,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    if (inProgress != null)
                      _buildActiveSessionBanner(
                        context: context,
                        inProgress: inProgress,
                        effectiveClinicId: effectiveClinicId,
                        isDoctor: isDoctor,
                        canViewHistory: user?.canViewMedicalHistory ?? false,
                      )
                    else if (nextWaiting != null)
                      _buildNextWaitingBanner(
                        context: context,
                        nextWaiting: nextWaiting,
                      ),
                  ],
                );

                final actions = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Flex(
                    direction: stacked ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: 'حجز جديد',
                        icon: Icons.event_available_rounded,
                        size: AppButtonSize.md,
                        expand: stacked,
                        variant: AppButtonVariant.primary,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => BookAppointmentDialog(
                              clinicId: effectiveClinicId,
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        width: stacked ? 0 : AppSpace.sm,
                        height: stacked ? AppSpace.sm : 0,
                      ),
                      AppButton(
                        label: 'عرض المواعيد',
                        icon: Icons.arrow_back_rounded,
                        size: AppButtonSize.md,
                        expand: stacked,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => onNavigateToTab?.call(1),
                      ),
                    ],
                  ),
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      textWidget,
                      const SizedBox(height: AppSpace.lg),
                      actions,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: textWidget),
                    const SizedBox(width: AppSpace.xl),
                    actions,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.borderSubtle(context),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
              height: 1.3,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionBanner({
    required BuildContext context,
    required AppointmentModel inProgress,
    required String effectiveClinicId,
    required bool isDoctor,
    required bool canViewHistory,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
          Text(
            'في غرفة الكشف الآن:',
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              inProgress.patient.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          if (isDoctor || canViewHistory)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExaminationScreen(
                      clinicId: effectiveClinicId,
                      appointmentId: inProgress.id,
                      patientId: inProgress.patientId,
                      patientName: inProgress.patient.fullName,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'متابعة الجلسة',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNextWaitingBanner({
    required BuildContext context,
    required AppointmentModel nextWaiting,
  }) {
    final isDark = AppColors.isDark(context);
    String formattedTime;
    try {
      formattedTime = intl.DateFormat('hh:mm a', 'ar').format(nextWaiting.appointmentDate.toLocal());
    } catch (_) {
      formattedTime = intl.DateFormat('hh:mm a').format(nextWaiting.appointmentDate.toLocal());
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning,
            ),
          ),
          Text(
            'المريض التالي في الانتظار:',
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              nextWaiting.patient.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          Text(
            formattedTime,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
