import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../domain/appointment_model.dart';
import '../../presentation/appointments_controller.dart';
import '../../data/appointment_repository.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../../presentation/examination_screen.dart';
import 'queue_board.dart';
import 'admission_confirmation_sheet.dart';
import '../edit_appointment_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../../patients/presentation/patient_details_dialog.dart';

/// بطاقة مريض مبسطة ومخصصة حسب حالته في الطابور
class QueueCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final QueueLaneType laneType;
  final int? queuePosition; // رقم الدور (فقط في الانتظار)
  final String clinicId;
  final int withDoctorCount; // عدد المرضى الحاليين مع الطبيب

  const QueueCard({
    super.key,
    required this.appointment,
    required this.laneType,
    this.queuePosition,
    required this.clinicId,
    required this.withDoctorCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final formattedTime = intl.DateFormat('hh:mm a').format(appointment.appointmentDate.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: laneType == QueueLaneType.withDoctor 
                ? const Color(0xFF3B82F6).withValues(alpha: 0.04) 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: laneType == QueueLaneType.withDoctor 
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.12) 
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Opacity(
            opacity: (laneType == QueueLaneType.completed || laneType == QueueLaneType.cancelled) ? 0.65 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopRow(context, formattedTime),
                  if (laneType != QueueLaneType.completed && laneType != QueueLaneType.cancelled) ...[
                    const SizedBox(height: 10),
                    _buildActionButtons(context, ref, isDoctor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context, String formattedTime) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── رقم الدور (فقط في الانتظار) أو أيقونة الحالة ───
        if (laneType == QueueLaneType.waiting && queuePosition != null)
          _buildQueuePositionBadge(context)
        else
          _buildStatusIcon(context),
        const SizedBox(width: 10),
        // ─── بيانات المريض ───
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => PatientDetailsDialog(
                      clinicId: clinicId,
                      patient: appointment.toPatientModel(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        appointment.patient.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 11, color: Theme.of(context).hintColor),
                  const SizedBox(width: 3),
                  Text(
                    formattedTime,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  if (appointment.appointmentTypeName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        appointment.appointmentTypeName!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // الخدمات المقدمة — فقط في المكتمل والملغي
              if ((laneType == QueueLaneType.completed || laneType == QueueLaneType.cancelled) &&
                  appointment.totalPaid > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${appointment.totalPaid.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (laneType != QueueLaneType.completed) ...[
          const SizedBox(width: 4),
          _buildThreeDotsMenu(context),
        ],
      ],
    );
  }

  Widget _buildThreeDotsMenu(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
          tooltip: 'خيارات أخرى',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit') {
              showDialog(
                context: context,
                builder: (_) => EditAppointmentDialog(
                  clinicId: appointment.clinicId,
                  appointment: appointment,
                ),
              );
            } else if (value == 'reactivate') {
              _showAdmissionSheet(context, ref, 'confirmed');
            } else if (value == 'cancel') {
              _showCancelOptionsSheet(context, ref);
            }
          },
          itemBuilder: (context) {
            final isCancelled = laneType == QueueLaneType.cancelled;

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
      },
    );
  }

  Widget _buildQueuePositionBadge(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$queuePosition',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;
    switch (laneType) {
      case QueueLaneType.withDoctor:
        icon = Icons.person_rounded;
        color = const Color(0xFF3B82F6);
      case QueueLaneType.completed:
        icon = Icons.check_circle_outline_rounded;
        color = const Color(0xFF10B981);
      case QueueLaneType.cancelled:
        icon = Icons.cancel_outlined;
        color = const Color(0xFFEF4444);
      case QueueLaneType.waiting:
        icon = Icons.hourglass_top_rounded;
        color = const Color(0xFFF59E0B);
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isDoctor) {
    final currentUser = ref.read(currentUserProvider);
    final canViewMedicalHistory = currentUser?.canViewMedicalHistory ?? false;

    if (laneType == QueueLaneType.waiting) {
      return Row(
        children: [
          Expanded(
            child: _PrimaryButton(
              label: 'إدخال للطبيب',
              icon: Icons.arrow_forward_rounded,
              onTap: () => _showAdmissionSheet(context, ref, 'pending'),
            ),
          ),
          const SizedBox(width: 6),
          _DangerIconButton(
            onTap: () => _showCancelOptionsSheet(context, ref),
          ),
        ],
      );
    }

    if (laneType == QueueLaneType.withDoctor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDoctor || canViewMedicalHistory)
            _PrimaryButton(
              label: isDoctor ? 'فتح جلسة الفحص' : 'التقرير الطبي',
              icon: Icons.medical_information_outlined,
              onTap: () => _openExamination(context),
            ),
          if (isDoctor || canViewMedicalHistory)
            const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'إنهاء الكشف',
                  onTap: () => _showAdmissionSheet(context, ref, 'completed'),
                ),
              ),
              const SizedBox(width: 6),
              _DangerIconButton(
                onTap: () => _showCancelOptionsSheet(context, ref),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showCancelOptionsSheet(BuildContext context, WidgetRef ref) {
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
                  final currentUser = ref.read(currentUserProvider);
                  if (currentUser != null && currentUser.role == UserRole.secretary && !currentUser.canCancelAppointments) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ليس لديك صلاحية لإلغاء الموعد أو الاعتذار للمرضى. يرجى مراجعة الطبيب.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _showAdmissionSheet(context, ref, 'cancelled_by_patient');
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
                  final currentUser = ref.read(currentUserProvider);
                  if (currentUser != null && currentUser.role == UserRole.secretary && !currentUser.canCancelAppointments) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ليس لديك صلاحية لإلغاء الموعد أو الاعتذار للمرضى. يرجى مراجعة الطبيب.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _showAdmissionSheet(context, ref, 'cancelled_by_clinic');
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

  void _openExamination(BuildContext context) {
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
  }

  void _showAdmissionSheet(BuildContext context, WidgetRef ref, String targetStatus) {
    // التحقق: لا يمكن إدخال مريض للطبيب إذا كان هناك مريض آخر مع الطبيب
    if (targetStatus == 'pending' && withDoctorCount >= 1) {
      ClinicToast.showError(context, 'لا يمكن إدخال مريض جديد قبل إنهاء الكشف الحالي');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdmissionConfirmationSheet(
        appointment: appointment,
        targetStatus: targetStatus,
        onConfirm: () => _updateStatus(context, ref, targetStatus),
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appointment.id, status);
      invalidateAppointmentsAndReports(ref);

      try {
        if (status == 'cancelled') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
            title: 'إلغاء موعد',
            body: 'تم إلغاء حجز المريض (${appointment.patient.fullName}) بناءً على طلبه',
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
                : 'تم إلغاء الموعد';

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
}

// ─── أزرار مساعدة ───

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            // removed border
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DangerIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            // removed border
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
