import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';

/// رأس لوحة الانتظار (أزرار التصفية، حجز جديد، إلغاء المواعيد وعناوين الجدول)
/// بتصميم Soft Structuralism المطور مع كبسولات لمسية عائمة وفلاتر انسيابية
class QueueBoardHeader extends ConsumerWidget {
  final List<AppointmentModel> appointments;
  final String clinicId;
  final String selectedFilter;
  final DateTime selectedDate;

  const QueueBoardHeader({
    super.key,
    required this.appointments,
    required this.clinicId,
    required this.selectedFilter,
    required this.selectedDate,
  });

  void _showCancelAllDialog(BuildContext context, WidgetRef ref) {
    final waitingCount = appointments.where((a) => a.status == 'confirmed').length;

    if (waitingCount == 0) {
      ClinicToast.showWarning(context, 'لا توجد مواعيد في الانتظار لإلغائها');
      return;
    }

    ClinicDialog.confirm(
      context: context,
      icon: Icons.warning_amber_rounded,
      title: 'إلغاء مواعيد اليوم',
      description:
          'سيتم إلغاء كل مواعيد الانتظار ($waitingCount موعد) لهذا اليوم. لا يشمل ذلك المواعيد المكتملة أو قيد الفحص.',
      confirmLabel: 'إلغاء المواعيد',
      isDangerous: true,
      onConfirm: () async {
        await ref.read(appointmentRepositoryProvider).cancelAllTodayAppointments(
              clinicId,
              selectedDate,
            );
        ref.invalidate(todayAppointmentsProvider);

        try {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'إلغاء جميع المواعيد',
            body: 'قام الطبيب بإلغاء جميع مواعيد الانتظار لهذا اليوم ($waitingCount موعد)',
            targetRole: 'secretary',
            playSound: true,
          );
        } catch (_) {}

        if (context.mounted) {
          ClinicToast.showSuccess(context, 'تم إلغاء مواعيد الانتظار بنجاح');
        }
      },
    );
  }

  Widget _buildFilterPill(
    BuildContext context,
    WidgetRef ref, {
    required String filterVal,
    required String label,
    required int count,
    required Color accentColor,
    required IconData icon,
  }) {
    final isSelected = selectedFilter == filterVal;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(dashboardFilterProvider.notifier).state = filterVal;
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? accentColor.withValues(alpha: 0.18)
                    : accentColor.withValues(alpha: 0.11))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.035)
                    : Colors.black.withValues(alpha: 0.025)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.6 : 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.8),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? accentColor
                    : theme.hintColor.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : accentColor)
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 6),
              // Tactile Counter Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: isDark ? 0.35 : 0.2)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? Colors.white : accentColor)
                        : theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalCount = appointments.length;
    final waitingCount = appointments.where((a) => a.status == 'confirmed').length;
    final pendingCount = appointments.where((a) => a.status == 'pending').length;
    final completedCount = appointments.where((a) => a.status == 'completed').length;
    final cancelledCount = appointments.where((a) => a.status.startsWith('cancelled')).length;

    return Column(
      children: [
        // ─── شريط التصفية العلوي بتصميم Soft Structuralism ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              // زر حجز جديد اللمسي المطور
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => BookAppointmentDialog(
                        clinicId: currentUser?.clinicId ?? clinicId,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'حجز جديد',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    minimumSize: Size.zero,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // أزرار الحالات اللمسية العائمة
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterPill(
                          context,
                          ref,
                          filterVal: 'all',
                          label: 'الكل',
                          count: totalCount,
                          accentColor: theme.colorScheme.primary,
                          icon: Icons.all_inclusive_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          context,
                          ref,
                          filterVal: 'confirmed',
                          label: 'الانتظار',
                          count: waitingCount,
                          accentColor: const Color(0xFFF59E0B),
                          icon: Icons.hourglass_top_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          context,
                          ref,
                          filterVal: 'pending',
                          label: 'مع الطبيب',
                          count: pendingCount,
                          accentColor: const Color(0xFF3B82F6),
                          icon: Icons.person_search_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          context,
                          ref,
                          filterVal: 'completed',
                          label: 'منتهي',
                          count: completedCount,
                          accentColor: const Color(0xFF10B981),
                          icon: Icons.check_circle_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterPill(
                          context,
                          ref,
                          filterVal: 'cancelled',
                          label: 'ملغي',
                          count: cancelledCount,
                          accentColor: const Color(0xFFEF4444),
                          icon: Icons.cancel_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // زر إلغاء مواعيد اليوم اللمسي
              OutlinedButton.icon(
                onPressed: () => _showCancelAllDialog(context, ref),
                icon: const Icon(Icons.cancel_outlined, size: 14),
                label: const Text(
                  'إلغاء مواعيد اليوم',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),

        // ─── عناوين الجدول المؤطرة بلمسة Soft Structuralism ───
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 85,
                child: Text(
                  'الوقت',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'المريض وبياناته',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'نوع الزيارة',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'الدفعة المالية',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'حالة الكشف',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: Center(
                  child: Text(
                    'الإجراءات',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
