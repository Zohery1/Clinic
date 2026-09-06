import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
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

    final subtitle = appointmentsAsync.isLoading
        ? 'جارٍ تحميل جدول اليوم…'
        : (total == 0
            ? 'لا توجد مواعيد اليوم. ابدأ يومك بإضافة مريض جديد أو حجز كشف.'
            : 'إجمالي المواعيد اليوم: $total (المكتمل: $completed • في الانتظار: $waiting)');

    final effectiveClinicId = user?.clinicId ?? '';

    final gradient = isDark
        ? LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              AppColors.primary.withValues(alpha: 0.18),
              AppColors.surface(context),
            ],
          )
        : const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              AppColors.primarySubtle,
              AppColors.lightSurface,
            ],
          );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadii.brLg,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.xxl,
          horizontal: AppSpace.xxl,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 700;
            final text = Expanded(
              flex: stacked ? 0 : 1,
              child: Column(
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
                          letterSpacing: 0.4,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                      // Calm clinical status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm + 2,
                          vertical: AppSpace.xs - 1,
                        ),
                        decoration: BoxDecoration(
                          color: (waiting > 0 ? AppColors.primary : AppColors.success)
                              .withValues(alpha: isDark ? 0.22 : 0.10),
                          borderRadius: AppRadii.brFull,
                          border: Border.all(
                            color: (waiting > 0 ? AppColors.primary : AppColors.success)
                                .withValues(alpha: isDark ? 0.45 : 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
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
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'مرحباً، $greetingName 👋',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
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
                    variant: AppButtonVariant.ghost,
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
                  text,
                  const SizedBox(height: AppSpace.lg),
                  actions,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                text,
                const SizedBox(width: AppSpace.xl),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}