import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../domain/appointment_model.dart';
import '../../presentation/appointments_controller.dart';
import '../../data/appointment_repository.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../../../reports/presentation/reports_controller.dart';
import '../../presentation/examination_screen.dart';
import 'queue_board.dart';
import 'admission_confirmation_sheet.dart';

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
                ? const Color(0xFF3B82F6).withOpacity(0.04) 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: laneType == QueueLaneType.withDoctor 
                    ? const Color(0xFF3B82F6).withOpacity(0.12) 
                    : Colors.black.withOpacity(0.02),
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

  Color _getLaneBorderColor(BuildContext context) {
    switch (laneType) {
      case QueueLaneType.waiting:
        return const Color(0xFFF59E0B).withOpacity(0.2);
      case QueueLaneType.withDoctor:
        return const Color(0xFF3B82F6).withOpacity(0.35);
      case QueueLaneType.completed:
        return Theme.of(context).dividerColor;
      case QueueLaneType.cancelled:
        return Theme.of(context).dividerColor;
    }
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
              Text(
                appointment.patient.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  Widget _buildQueuePositionBadge(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.12),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isDoctor) {
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
          _PrimaryButton(
            label: isDoctor ? 'فتح جلسة الفحص' : 'التقرير الطبي',
            icon: Icons.medical_information_outlined,
            onTap: () => _openExamination(context),
          ),
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
                  Navigator.pop(context);
                  _showAdmissionSheet(context, ref, 'cancelled_by_patient');
                },
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('المريض لم يحضر / اعتذر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا يمكن إدخال مريض جديد قبل إنهاء الكشف الحالي'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final previousStatus = appointment.status;
    try {
      await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appointment.id, status);
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(monthRevenueProvider);

      if (context.mounted) {
        final label = status == 'pending'
            ? 'تم نقل المريض للطبيب'
            : status == 'completed'
                ? 'تم إنهاء الكشف'
                : 'تم إلغاء الموعد';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(label),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'تراجع',
              onPressed: () async {
                await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appointment.id, previousStatus);
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
