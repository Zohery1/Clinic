import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../domain/appointment_model.dart';
import '../../data/appointment_repository.dart';
import '../../presentation/appointments_controller.dart';
import '../../../reports/presentation/reports_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../examination_screen.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../book_appointment_dialog.dart';

/// الحالات المختلفة لمكان المريض في طابور العيادة
enum QueueLaneType { waiting, withDoctor, completed, cancelled }

/// لوحة إدارة المرضى والمواعيد — تصميم زمني كرونولوجي احترافي (Timeline Clinic Queue)
class QueueBoard extends ConsumerStatefulWidget {
  final List<AppointmentModel> appointments;
  final String clinicId;

  const QueueBoard({
    super.key,
    required this.appointments,
    required this.clinicId,
  });

  @override
  ConsumerState<QueueBoard> createState() => _QueueBoardState();
}

class _QueueBoardState extends ConsumerState<QueueBoard> {

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'مع الطبيب';
      case 'confirmed':
        return 'في الانتظار';
      case 'completed':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'في الانتظار';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF3B82F6); // Blue
      case 'confirmed':
        return const Color(0xFFF59E0B); // Orange
      case 'completed':
        return const Color(0xFF10B981); // Green
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFFF59E0B);
    }
  }

  void _updateStatus(BuildContext context, AppointmentModel appt, String status) async {
    final previousStatus = appt.status;
    try {
      await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appt.id, status);
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(monthRevenueProvider);

      if (context.mounted) {
        final label = status == 'pending'
            ? 'تم نقل المريض للطبيب'
            : status == 'completed'
                ? 'تم إنهاء الكشف'
                : 'تم تغيير حالة الموعد';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(label),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'تراجع',
              onPressed: () async {
                await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appt.id, previousStatus);
                ref.invalidate(todayAppointmentsProvider);
                ref.invalidate(todayRevenueProvider);
                ref.invalidate(monthRevenueProvider);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final selectedFilter = ref.watch(dashboardFilterProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // 1. التصفية
    final filtered = widget.appointments.where((appt) {
      if (selectedFilter != 'all' && appt.status != selectedFilter) {
        return false;
      }
      return true;
    }).toList();

    // 2. الترتيب الزمني
    filtered.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    return Container(
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        children: [
          // ─── شريط التصفية العلوي ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // زر حجز جديد على اليمين
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => BookAppointmentDialog(clinicId: currentUser?.clinicId ?? ''),
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
                // أزرار الحالات (Chips) في المنتصف
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterChip(ref, 'confirmed', 'الانتظار (${widget.appointments.where((a) => a.status == 'confirmed').length})', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(ref, 'pending', 'مع الطبيب (${widget.appointments.where((a) => a.status == 'pending').length})', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(ref, 'completed', 'منتهي (${widget.appointments.where((a) => a.status == 'completed').length})', selectedFilter),
                          const SizedBox(width: 8),
                          _buildFilterChip(ref, 'cancelled', 'ملغي (${widget.appointments.where((a) => a.status == 'cancelled').length})', selectedFilter),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // زر إلغاء مواعيد اليوم المباشر على اليسار
                OutlinedButton.icon(
                  onPressed: () => _showCancelAllDialog(context, ref, selectedDate),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('إلغاء مواعيد اليوم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide.none,
                    backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
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
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 80, child: Text('الوقت', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                const Expanded(flex: 3, child: Text('المريض وبياناته', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                const Expanded(flex: 2, child: Text('نوع الزيارة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                const Expanded(flex: 2, child: Text('الدفعة المالية', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                const Expanded(flex: 2, child: Text('حالة الكشف', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                const SizedBox(width: 150, child: Center(child: Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)))),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── قائمة المرضى الزمنية ───
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final appt = filtered[index];
                      return _buildTimelineRow(context, appt, isDoctor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String filterVal, String label, String selectedFilter) {
    final isSelected = selectedFilter == filterVal;
    final theme = Theme.of(context);
    
    Color chipColor;
    switch (filterVal) {
      case 'confirmed':
        chipColor = const Color(0xFFF59E0B); // Amber / Yellow
        break;
      case 'pending':
        chipColor = const Color(0xFF3B82F6); // Blue
        break;
      case 'completed':
        chipColor = const Color(0xFF10B981); // Green
        break;
      case 'cancelled':
        chipColor = const Color(0xFFEF4444); // Red
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
      selectedColor: chipColor.withOpacity(0.1),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: chipColor.withOpacity(isSelected ? 1.0 : 0.5), width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      showCheckmark: false,
    );
  }

  void _showCancelAllDialog(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final waitingCount = widget.appointments.where((a) => a.status == 'confirmed').length;

    if (waitingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد مواعيد في الانتظار لإلغائها'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ClinicDialog.confirm(
      context: context,
      icon: Icons.warning_amber_rounded,
      title: 'إلغاء مواعيد اليوم',
      description: 'سيتم إلغاء كل مواعيد الانتظار ($waitingCount موعد) لهذا اليوم. لا يشمل ذلك المواعيد المكتملة أو قيد الفحص.',
      confirmLabel: 'إلغاء المواعيد',
      isDangerous: true,
      onConfirm: () async {
        await ref.read(appointmentRepositoryProvider).cancelAllTodayAppointments(
              widget.clinicId,
              selectedDate,
            );
        ref.invalidate(todayAppointmentsProvider);
        ref.invalidate(todayRevenueProvider);
        ref.invalidate(monthRevenueProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء مواعيد الانتظار بنجاح'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Widget _buildTimelineRow(BuildContext context, AppointmentModel appt, bool isDoctor) {
    final formattedTime = intl.DateFormat('hh:mm a').format(appt.appointmentDate.toLocal());
    final statusColor = _getStatusColor(appt.status);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: appt.status == 'pending'
            ? theme.colorScheme.primary.withOpacity(0.02) // تمييز المريض الحالي مع الطبيب
            : null,
      ),
      child: Row(
        children: [
          // 1. وقت الحجز
          SizedBox(
            width: 80,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedTime.split(' ')[0],
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  formattedTime.split(' ')[1] == 'PM' ? 'م' : 'ص',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 2. المريض وبياناته
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    appt.patient.fullName.trim().substring(0, 1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patient.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appt.patient.phone ?? 'بدون رقم هاتف',
                        style: TextStyle(fontSize: 11, color: theme.hintColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. نوع الزيارة
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appt.appointmentTypeName ?? 'كشف عام',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),

          // 4. الدفعة المالية
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: appt.status.toLowerCase() == 'cancelled'
                  ? Text(
                      '--',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor.withOpacity(0.5),
                      ),
                    )
                  : appt.totalPaid > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'مسدد (${appt.totalPaid.toStringAsFixed(0)})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 12),
                              const SizedBox(width: 4),
                              const Text(
                                'غير مسدد',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),

          // 5. حالة الموعد
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _translateStatus(appt.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // 6. الإجراءات السياقية
          SizedBox(
            width: 150,
            child: Center(
              child: _buildActionButtonsForRow(context, appt, isDoctor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsForRow(BuildContext context, AppointmentModel appt, bool isDoctor) {
    final theme = Theme.of(context);
    switch (appt.status.toLowerCase()) {
      case 'confirmed': // قيد الانتظار
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(context, appt, 'pending'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, size: 12),
                    SizedBox(width: 4),
                    Text('دخول للطبيب', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _updateStatus(context, appt, 'cancelled'),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              color: const Color(0xFFEF4444),
              tooltip: 'إلغاء الموعد',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      case 'pending': // مع الطبيب
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _openExamination(context, appt),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_information_outlined, size: 12),
                  const SizedBox(width: 4),
                  Text(isDoctor ? 'جلسة الفحص' : 'التقرير الطبي', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, appt, 'completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('إنهاء الكشف', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _updateStatus(context, appt, 'cancelled'),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  color: const Color(0xFFEF4444),
                  tooltip: 'إلغاء الموعد',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        );
      case 'completed': // مكتمل
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF10B981).withOpacity(0.7), size: 16),
            const SizedBox(width: 4),
            const Text('منتهي', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        );
      case 'cancelled': // ملغي
        return TextButton(
          onPressed: () => _updateStatus(context, appt, 'confirmed'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: EdgeInsets.zero,
          ),
          child: const Text('إعادة تنشيط', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        );
      default:
        return const SizedBox();
    }
  }

  void _openExamination(BuildContext context, AppointmentModel appt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExaminationScreen(
          clinicId: widget.clinicId,
          appointmentId: appt.id,
          patientId: appt.patientId,
          patientName: appt.patient.fullName,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Theme.of(context).hintColor.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'لا توجد مواعيد تطابق الفلتر المختار',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).hintColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
