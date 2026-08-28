import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';

/// رأس لوحة الانتظار (أزرار التصفية، حجز جديد، إلغاء المواعيد وعناوين الجدول)
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

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String filterVal, String label) {
    final isSelected = selectedFilter == filterVal;
    final theme = Theme.of(context);

    Color chipColor;
    switch (filterVal) {
      case 'confirmed':
        chipColor = const Color(0xFFF59E0B);
        break;
      case 'pending':
        chipColor = const Color(0xFF3B82F6);
        break;
      case 'completed':
        chipColor = const Color(0xFF10B981);
        break;
      case 'cancelled':
        chipColor = const Color(0xFFEF4444);
        break;
      default:
        chipColor = theme.colorScheme.primary;
    }

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(dashboardFilterProvider.notifier).state = filterVal;
        }
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        color: isSelected ? chipColor : theme.textTheme.bodyMedium?.color,
      ),
      selectedColor: chipColor.withValues(alpha: 0.1),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: chipColor.withValues(alpha: isSelected ? 1.0 : 0.5), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ─── شريط التصفية العلوي ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // زر حجز جديد
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BookAppointmentDialog(clinicId: currentUser?.clinicId ?? clinicId),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('حجز جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 16),
              // أزرار الحالات
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterChip(
                          context,
                          ref,
                          'confirmed',
                          'الانتظار (${appointments.where((a) => a.status == 'confirmed').length})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          ref,
                          'pending',
                          'مع الطبيب (${appointments.where((a) => a.status == 'pending').length})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          ref,
                          'completed',
                          'منتهي (${appointments.where((a) => a.status == 'completed').length})',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context,
                          ref,
                          'cancelled',
                          'ملغي (${appointments.where((a) => a.status.startsWith('cancelled')).length})',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // زر إلغاء مواعيد اليوم
              OutlinedButton.icon(
                onPressed: () => _showCancelAllDialog(context, ref),
                icon: const Icon(Icons.cancel_outlined, size: 14),
                label: const Text('إلغاء مواعيد اليوم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide.none,
                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ─── عناوين الجدول ───
        Container(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Row(
            children: [
              SizedBox(width: 80, child: Text('الوقت', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(flex: 3, child: Text('المريض وبياناته', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(flex: 2, child: Text('نوع الزيارة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(flex: 2, child: Text('الدفعة المالية', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(flex: 2, child: Text('حالة الكشف', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              SizedBox(width: 150, child: Center(child: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))),
            ],
          ),
        ),
      ],
    );
  }
}
