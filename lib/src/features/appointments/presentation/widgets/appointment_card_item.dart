import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/widgets/clinic_toast.dart';
import '../../../../core/widgets/double_bezel_card.dart';
import '../../../../core/widgets/send_whatsapp_dialog.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../../patients/presentation/patient_details_dialog.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../edit_appointment_dialog.dart';
import '../examination_screen.dart';
import 'admission_confirmation_sheet.dart';

/// بطاقة موعد في عرض الموبايل بتصميم Soft Structuralism و Double-Bezel
class AppointmentCardItem extends ConsumerWidget {
  final AppointmentModel appointment;
  final String clinicId;

  const AppointmentCardItem({
    super.key,
    required this.appointment,
    required this.clinicId,
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.person_search_rounded;
      case 'confirmed':
        return Icons.hourglass_top_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
      case 'cancelled_by_patient':
      case 'cancelled_by_clinic':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appointment.id, status);
      invalidateAppointmentsAndReports(ref);

      try {
        if (status.startsWith('cancelled')) {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'إلغاء موعد',
            body: 'تم إلغاء حجز المريض (${appointment.patient.fullName})',
            targetRole: 'doctor',
          );
        } else if (status == 'pending') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'دخول مريض للفحص',
            body: 'المريض (${appointment.patient.fullName}) في انتظارك الآن بغرفة الكشف',
            targetRole: 'doctor',
            playSound: true,
          );
        } else if (status == 'completed') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'إنتهاء موعد',
            body: 'تم الانتهاء من موعد المريض (${appointment.patient.fullName})',
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
                : status == 'confirmed'
                    ? 'تمت إعادة المريض للانتظار'
                    : 'تم إلغاء الموعد';

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
        appointment: appointment,
        targetStatus: targetStatus,
        onConfirm: () {
          Navigator.pop(context);
          _updateStatus(context, ref, targetStatus);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;
    final formattedTime = intl.DateFormat('hh:mm a').format(appointment.appointmentDate.toLocal());
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);
    final status = appointment.status.toLowerCase();
    final isPending = status == 'pending';
    final isCancelled = status.startsWith('cancelled');
    final isCompleted = status == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Macro-whitespace
      child: DoubleBezelCard(
        outerRadius: 22.0,
        innerRadius: 19.5,
        outerPadding: const EdgeInsets.all(2.5),
        innerPadding: const EdgeInsets.all(16),
        isActiveGlow: isPending,
        glowColor: const Color(0xFF3B82F6),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => PatientDetailsDialog(
              clinicId: clinicId,
              patient: appointment.toPatientModel(),
            ),
          );
        },
        child: Opacity(
          opacity: (isCompleted || isCancelled) ? 0.72 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. رأس البطاقة: الوقت ونوع الحجز والحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                              : theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: isPending ? const Color(0xFF3B82F6) : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formattedTime,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isPending ? const Color(0xFF3B82F6) : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (appointment.appointmentTypeName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Text(
                            appointment.appointmentTypeName!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: isDark ? 0.4 : 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPending) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ] else ...[
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _translateStatus(appointment.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. بيانات المريض
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isPending
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                        : (isCompleted
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : theme.colorScheme.primary.withValues(alpha: 0.1)),
                    child: Text(
                      appointment.patient.fullName.trim().isNotEmpty
                          ? appointment.patient.fullName.trim().substring(0, 1)
                          : '؟',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPending
                            ? const Color(0xFF3B82F6)
                            : (isCompleted
                                ? const Color(0xFF10B981)
                                : theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patient.fullName,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (appointment.patient.phone != null &&
                                appointment.patient.phone!.isNotEmpty)
                              InkWell(
                                onTap: () => showSendWhatsAppDialog(
                                  context,
                                  ref,
                                  phone: appointment.patient.phone!,
                                  patientName: appointment.patient.fullName,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 13,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      appointment.patient.phone!,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        color: const Color(0xFF10B981),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                'بدون هاتف',
                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                              ),
                            if (appointment.doctorName != null &&
                                appointment.doctorName!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_pin_outlined,
                                      size: 10,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'د. ${appointment.doctorName}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // الدفعة المالية
                  if (appointment.totalPaid > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${appointment.totalPaid.toStringAsFixed(0)} ج.م',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. شريط الأزرار السريعة
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'confirmed') ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => EditAppointmentDialog(
                            clinicId: clinicId,
                            appointment: appointment,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('تعديل', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAdmissionSheet(context, ref, 'pending'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: const Text(
                        'دخول للطبيب',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ] else if (status == 'pending') ...[
                    if (isDoctor)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExaminationScreen(
                                clinicId: clinicId,
                                appointmentId: appointment.id,
                                patientId: appointment.patientId,
                                patientName: appointment.patient.fullName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.medical_services_outlined, size: 14),
                        label: const Text(
                          'بدء الفحص',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          minimumSize: Size.zero,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _showAdmissionSheet(context, ref, 'completed'),
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text(
                          'إنهاء الكشف',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          minimumSize: Size.zero,
                        ),
                      ),
                  ] else if (status == 'completed' && isDoctor) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExaminationScreen(
                              clinicId: clinicId,
                              appointmentId: appointment.id,
                              patientId: appointment.patientId,
                              patientName: appointment.patient.fullName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 14),
                      label: const Text('عرض التقرير', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
