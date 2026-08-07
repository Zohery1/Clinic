import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../domain/appointment_model.dart';
import '../../data/appointment_repository.dart';
import '../../presentation/appointments_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../examination_screen.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../../core/widgets/send_whatsapp_dialog.dart';
import '../book_appointment_dialog.dart';
import '../edit_appointment_dialog.dart';
import 'admission_confirmation_sheet.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../../patients/presentation/patient_details_dialog.dart';

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
      case 'cancelled_by_patient':
      case 'cancelled_by_clinic':
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
      case 'cancelled_by_patient':
      case 'cancelled_by_clinic':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFFF59E0B);
    }
  }

  void _updateStatus(BuildContext context, AppointmentModel appt, String status) async {
    try {
      await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appt.id, status);
      invalidateAppointmentsAndReports(ref);

      try {
        if (status == 'cancelled' || status == 'cancelled_by_patient' || status == 'cancelled_by_clinic') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'إلغاء موعد',
            body: 'تم إلغاء حجز المريض (${appt.patient.fullName}) بناءً على طلبه',
            targetRole: 'doctor',
          );
        } else if (status == 'pending') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'دخول مريض للفحص',
            body: 'المريض (${appt.patient.fullName}) في انتظارك الآن بغرفة الكشف',
            targetRole: 'doctor',
            playSound: true,
          );
        } else if (status == 'completed') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'إنتهاء موعد',
            body: 'تم الانتهاء من موعد المريض (${appt.patient.fullName})',
            targetRole: 'secretary',
            playSound: true,
          );
        }
      } catch (_) {}

      if (context.mounted) {
        final label = status == 'pending'
            ? 'تم نقل المريض للطبيب'
            : status == 'completed'
                ? 'تم إنهاء الكشف'
                : 'تم تغيير حالة الموعد';

        final IconData iconData;
        final Color bgColor;
        
        if (status == 'pending') {
          iconData = Icons.person_search_rounded;
          bgColor = const Color(0xFF1A73E8);
        } else if (status == 'completed') {
          iconData = Icons.check_circle_rounded;
          bgColor = const Color(0xFF10B981);
        } else if (status == 'confirmed') {
          iconData = Icons.hourglass_empty_rounded;
          bgColor = const Color(0xFFF59E0B);
        } else {
          iconData = Icons.info_outline_rounded;
          bgColor = const Color(0xFF1E293B);
        }

        ClinicToast.show(context, message: label, icon: iconData, color: bgColor);
      }
    } catch (e) {
      if (context.mounted) {
        ClinicToast.showError(context, 'حدث خطأ: $e');
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
      if (selectedFilter != 'all') {
        if (selectedFilter == 'cancelled') {
          if (!appt.status.startsWith('cancelled')) return false;
        } else if (appt.status != selectedFilter) {
          return false;
        }
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
                          _buildFilterChip(ref, 'cancelled', 'ملغي (${widget.appointments.where((a) => a.status.startsWith('cancelled')).length})', selectedFilter),
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
                    backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
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
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.4),
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
      selectedColor: chipColor.withValues(alpha: 0.1),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: chipColor.withValues(alpha: isSelected ? 1.0 : 0.5), width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      showCheckmark: false,
    );
  }

  void _showCancelAllDialog(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final waitingCount = widget.appointments.where((a) => a.status == 'confirmed').length;

    if (waitingCount == 0) {
      ClinicToast.showWarning(context, 'لا توجد مواعيد في الانتظار لإلغائها');
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

  Widget _buildTimelineRow(BuildContext context, AppointmentModel appt, bool isDoctor) {
    final formattedTime = intl.DateFormat('hh:mm a').format(appt.appointmentDate.toLocal());
    final statusColor = _getStatusColor(appt.status);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: appt.status == 'pending'
            ? theme.colorScheme.primary.withValues(alpha: 0.02) // تمييز المريض الحالي مع الطبيب
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
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => PatientDetailsDialog(
                    clinicId: widget.clinicId,
                    patient: appt.toPatientModel(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  appt.patient.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 13,
                                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (appt.patient.phone != null && appt.patient.phone!.isNotEmpty)
                            InkWell(
                              onTap: () => showSendWhatsAppDialog(
                                context,
                                ref,
                                phone: appt.patient.phone!,
                                patientName: appt.patient.fullName,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text(
                                    appt.patient.phone!,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'بدون رقم هاتف',
                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
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
                        color: theme.hintColor.withValues(alpha: 0.5),
                      ),
                    )
                  : appt.totalPaid > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 12),
                              SizedBox(width: 4),
                              Text(
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
                  color: statusColor.withValues(alpha: 0.12),
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
    final status = appt.status.toLowerCase();
    final isCancelled = status.startsWith('cancelled');
    
    Widget mainAction = const SizedBox();

    if (status == 'confirmed') { // قيد الانتظار
      mainAction = Expanded(
        child: SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () => _updateStatus(context, appt, 'pending'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login_rounded, size: 14),
                SizedBox(width: 4),
                Text('دخول للطبيب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    } else if (status == 'pending') { // مع الطبيب
      mainAction = Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () => _openExamination(context, appt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.medical_information_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(isDoctor ? 'جلسة الفحص' : 'التقرير الطبي', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () => _updateStatus(context, appt, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('إنهاء الكشف', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'completed') { // مكتمل
      mainAction = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF10B981).withValues(alpha: 0.7), size: 16),
          const SizedBox(width: 4),
          const Text('منتهي', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      );
    } else if (isCancelled) { // ملغي
      mainAction = Expanded(
        child: SizedBox(
          height: 34,
          child: TextButton.icon(
            onPressed: () => _updateStatus(context, appt, 'confirmed'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('إعادة تنشيط', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        mainAction,
        if (status != 'completed') ...[
          const SizedBox(width: 4),
          _buildThreeDotsMenu(context, appt),
        ],
      ],
    );
  }

  Widget _buildThreeDotsMenu(BuildContext context, AppointmentModel appt) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
      tooltip: 'خيارات أخرى',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          showDialog(
            context: context,
            builder: (_) => EditAppointmentDialog(
              clinicId: appt.clinicId,
              appointment: appt,
            ),
          );
        } else if (value == 'reactivate') {
          _updateStatus(context, appt, 'confirmed');
        } else if (value == 'cancel') {
          _showCancelOptionsSheet(context, appt);
        }
      },
      itemBuilder: (context) {
        final status = appt.status.toLowerCase();
        final isCancelled = status.startsWith('cancelled');

        return [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 8),
                Text('تعديل الحجز'),
              ],
            ),
          ),
          if (isCancelled)
            const PopupMenuItem(
              value: 'reactivate',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('إعادة تنشيط'),
                ],
              ),
            ),
          if (!isCancelled)
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('إلغاء الموعد', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ];
      },
    );
  }

  void _showCancelOptionsSheet(BuildContext context, AppointmentModel appt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'سبب الإلغاء',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAdmissionSheet(context, appt, 'cancelled_by_patient');
                },
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('المريض لم يحضر / اعتذر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAdmissionSheet(context, appt, 'cancelled_by_clinic');
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء من قبل العيادة / الطبيب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdmissionSheet(BuildContext context, AppointmentModel appt, String targetStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdmissionConfirmationSheet(
        appointment: appt,
        targetStatus: targetStatus,
        onConfirm: () => _updateStatus(context, appt, targetStatus),
      ),
    );
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
          Icon(Icons.inbox_rounded, size: 48, color: Theme.of(context).hintColor.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'لا توجد مواعيد تطابق الفلتر المختار',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).hintColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
