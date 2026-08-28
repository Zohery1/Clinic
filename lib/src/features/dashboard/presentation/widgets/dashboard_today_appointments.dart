import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../patients/presentation/patient_details_dialog.dart';
import '../../../auth/presentation/login_controller.dart';

/// بطاقة ملخص مواعيد اليوم وقائمة الانتظار في الداشبورد
class DashboardTodayAppointments extends ConsumerWidget {
  final String? clinicId;
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardTodayAppointments({
    super.key,
    this.clinicId,
    this.onNavigateToTab,
  });

  String _formatTime(DateTime date) {
    try {
      return intl.DateFormat('hh:mm a', 'ar').format(date);
    } catch (_) {
      return '${date.hour}:${date.minute}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final user = ref.watch(currentUserProvider);
    final effectiveClinicId = user?.clinicId ?? clinicId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'مواعيد اليوم',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    appointmentsAsync.when(
                      data: (list) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          '${list.length}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => onNavigateToTab?.call(1),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 12),
                  label: Text(
                    'عرض الكل',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // Content
          appointmentsAsync.when(
            data: (appointments) {
              if (appointments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: AppEmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'لا توجد مواعيد مسجلة اليوم',
                    message: 'يمكنك إضافة موعد جديد أو استعراض الأيام الأخرى',
                    actionLabel: 'حجز جديد',
                    actionIcon: Icons.add,
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => BookAppointmentDialog(clinicId: effectiveClinicId),
                      );
                    },
                  ),
                );
              }

              final sortedList = List<AppointmentModel>.from(appointments)
                ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

              final displayList = sortedList.take(6).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                itemBuilder: (context, index) {
                  final appt = displayList[index];
                  return _buildAppointmentTile(context, appt, isDark);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'تعذر تحميل المواعيد',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(BuildContext context, AppointmentModel appt, bool isDark) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PatientDetailsDialog(
            clinicId: appt.clinicId,
            patient: appt.toPatientModel(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Time Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                _formatTime(appt.appointmentDate),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Patient Name & details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.patient.fullName,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (appt.doctorName != null || appt.appointmentTypeName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (appt.doctorName != null && appt.doctorName!.isNotEmpty) 'د. ${appt.doctorName}',
                        if (appt.appointmentTypeName != null && appt.appointmentTypeName!.isNotEmpty) appt.appointmentTypeName!,
                      ].join(' • '),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Status Badge
            AppStatusBadge.fromAppointmentStatus(appt.status),
          ],
        ),
      ),
    );
  }
}
