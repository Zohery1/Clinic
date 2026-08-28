import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../../core/widgets/send_whatsapp_dialog.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../../patients/presentation/patient_details_dialog.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../examination_screen.dart';
import '../edit_appointment_dialog.dart';
import 'admission_confirmation_sheet.dart';

/// صف جدول الطابور الزمني في لوحة الانتظار
class QueueTimelineRow extends ConsumerWidget {
  final AppointmentModel appt;
  final String clinicId;
  final bool isDoctor;

  const QueueTimelineRow({
    super.key,
    required this.appt,
    required this.clinicId,
    required this.isDoctor,
  });

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
        return const Color(0xFF3B82F6);
      case 'confirmed':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
      case 'cancelled_by_patient':
      case 'cancelled_by_clinic':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appt.id, status);
      invalidateAppointmentsAndReports(ref);

      try {
        if (status.startsWith('cancelled')) {
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

        final iconData = status == 'pending'
            ? Icons.person_search_rounded
            : status == 'completed'
                ? Icons.check_circle_rounded
                : status == 'confirmed'
                    ? Icons.hourglass_empty_rounded
                    : Icons.info_outline_rounded;

        final bgColor = status == 'pending'
            ? const Color(0xFF1A73E8)
            : status == 'completed'
                ? const Color(0xFF10B981)
                : status == 'confirmed'
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF1E293B);

        ClinicToast.show(context, message: label, icon: iconData, color: bgColor);
      }
    } catch (e) {
      if (context.mounted) {
        ClinicToast.showError(context, 'حدث خطأ: $e');
      }
    }
  }

  void _showAdmissionSheet(BuildContext context, WidgetRef ref, String targetStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdmissionConfirmationSheet(
        appointment: appt,
        targetStatus: targetStatus,
        onConfirm: () {
          Navigator.pop(context);
          _updateStatus(context, ref, targetStatus);
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final status = appt.status.toLowerCase();
    final theme = Theme.of(context);

    if (status == 'confirmed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAdmissionSheet(context, ref, 'pending'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('دخول للطبيب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 6),
          _buildMoreMenu(context, ref),
        ],
      );
    } else if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDoctor)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExaminationScreen(
                      clinicId: clinicId,
                      appointmentId: appt.id,
                      patientId: appt.patient.id,
                      patientName: appt.patient.fullName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.medical_services_outlined, size: 14),
              label: const Text('بدء الفحص', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _showAdmissionSheet(context, ref, 'completed'),
              icon: const Icon(Icons.check_rounded, size: 14),
              label: const Text('إنهاء الكشف', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          const SizedBox(width: 6),
          _buildMoreMenu(context, ref),
        ],
      );
    } else if (status == 'completed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDoctor)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExaminationScreen(
                      clinicId: clinicId,
                      appointmentId: appt.id,
                      patientId: appt.patient.id,
                      patientName: appt.patient.fullName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 14),
              label: const Text('عرض التقرير', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          const SizedBox(width: 4),
          _buildMoreMenu(context, ref),
        ],
      );
    } else {
      return _buildMoreMenu(context, ref);
    }
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: Theme.of(context).hintColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'details', child: Text('عرض تفاصيل المريض', style: TextStyle(fontSize: 12))),
        const PopupMenuItem(value: 'edit', child: Text('تعديل الموعد', style: TextStyle(fontSize: 12))),
        if (appt.status != 'confirmed')
          const PopupMenuItem(value: 'return_waiting', child: Text('إعادة للانتظار', style: TextStyle(fontSize: 12))),
        if (!appt.status.startsWith('cancelled'))
          const PopupMenuItem(
            value: 'cancel',
            child: Text('إلغاء الموعد', style: TextStyle(fontSize: 12, color: AppTheme.error)),
          ),
      ],
      onSelected: (val) {
        if (val == 'details') {
          showDialog(
            context: context,
            builder: (_) => PatientDetailsDialog(clinicId: clinicId, patient: appt.toPatientModel()),
          );
        } else if (val == 'edit') {
          showDialog(
            context: context,
            builder: (_) => EditAppointmentDialog(clinicId: clinicId, appointment: appt),
          );
        } else if (val == 'return_waiting') {
          _updateStatus(context, ref, 'confirmed');
        } else if (val == 'cancel') {
          _showAdmissionSheet(context, ref, 'cancelled');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedTime = intl.DateFormat('hh:mm a').format(appt.appointmentDate.toLocal());
    final statusColor = _getStatusColor(appt.status);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: appt.status == 'pending'
            ? theme.colorScheme.primary.withValues(alpha: 0.02)
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
                    clinicId: clinicId,
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
              child: _buildActionButtons(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
