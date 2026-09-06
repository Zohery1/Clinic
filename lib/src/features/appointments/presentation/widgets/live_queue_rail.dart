import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';

/// شريط طابور الانتظار المباشر لقمرة قيادة الطبيب (Live Queue Rail)
/// يربط الطبيب بلحظة الانتظار الفعلية بالخارج دون مغادرة شاشة الكشف
class LiveQueueRail extends ConsumerStatefulWidget {
  final String clinicId;
  final String currentAppointmentId;
  final ValueChanged<AppointmentModel> onSelectAppointment;
  final VoidCallback? onCallNext;

  const LiveQueueRail({
    super.key,
    required this.clinicId,
    required this.currentAppointmentId,
    required this.onSelectAppointment,
    this.onCallNext,
  });

  @override
  ConsumerState<LiveQueueRail> createState() => _LiveQueueRailState();
}

class _LiveQueueRailState extends ConsumerState<LiveQueueRail> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every minute to recalculate waiting time dynamically
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatWaitDuration(DateTime appointmentDate) {
    final now = DateTime.now();
    final diff = now.difference(appointmentDate.toLocal());
    if (diff.isNegative) {
      final inMins = diff.abs().inMinutes;
      if (inMins < 60) return 'بعد $inMins دقيقة';
      return 'بعد ${(inMins / 60).floor()} ساعة';
    }
    final mins = diff.inMinutes;
    if (mins < 1) return 'الآن';
    if (mins < 60) return 'منذ $mins دقيقة';
    final hours = (mins / 60).floor();
    final remainingMins = mins % 60;
    return 'منذ $hours س و $remainingMins د';
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;

    return appointmentsAsync.when(
      data: (allAppointments) {
        // Filter appointments for this doctor if logged in as doctor
        final appointments = allAppointments.where((a) {
          if (isDoctor && a.doctorId != null && a.doctorId != currentUser?.id) {
            return false;
          }
          return a.status == 'confirmed' || a.status == 'pending';
        }).toList();

        // Sort: pending (in exam) first, then confirmed (in queue) by date
        appointments.sort((a, b) {
          if (a.status == 'pending' && b.status != 'pending') return -1;
          if (b.status == 'pending' && a.status != 'pending') return 1;
          return a.appointmentDate.compareTo(b.appointmentDate);
        });

        final waitingCount =
            appointments.where((a) => a.status == 'confirmed').length;
        final nextWaiting = appointments.firstWhere(
          (a) => a.status == 'confirmed',
          orElse: () => appointments.firstWhere(
            (a) => a.id == widget.currentAppointmentId,
            orElse: () => appointments.isEmpty
                ? AppointmentModel(
                    id: '',
                    clinicId: '',
                    patientId: '',
                    appointmentDate: DateTime.now(),
                    status: '',
                    patient: AppointmentPatient(fullName: ''),
                    totalPaid: 0,
                  )
                : appointments.first,
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: AppColors.subtle(context).withValues(alpha: 0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtle(context)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.warningBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'طابور العيادة اليوم',
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$waitingCount بالانتظار',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Queue List
              Expanded(
                child: appointments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 36,
                                color: AppColors.textMuted(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لا يوجد مرضى في الطابور حالياً',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpace.sm),
                        itemCount: appointments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final a = appointments[index];
                          final isCurrent =
                              a.id == widget.currentAppointmentId;
                          final isPending = a.status == 'pending';
                          final waitTime =
                              _formatWaitDuration(a.appointmentDate);

                          return InkWell(
                            onTap: () => widget.onSelectAppointment(a),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primarySubtle
                                    : (isPending
                                        ? AppColors.infoSubtle
                                        : AppColors.subtle(context)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : (isPending
                                          ? AppColors.info
                                              .withValues(alpha: 0.5)
                                          : Colors.transparent),
                                  width: isCurrent ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Number / Order badge
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppColors.primary
                                          : AppColors.borderSubtle(context),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? Colors.white
                                            : AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Avatar
                                  AppAvatar(
                                    name: a.patient.fullName,
                                    size: AppAvatarSize.sm,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : AppColors.doctorColor(a.doctorId),
                                  ),
                                  const SizedBox(width: 8),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.patient.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(
                                            fontSize: 12.5,
                                            fontWeight: isCurrent
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isCurrent
                                                ? AppColors.primary
                                                : AppColors.textPrimary(
                                                    context),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (isCurrent)
                                              Text(
                                                'داخل الكشف الآن',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              )
                                            else
                                              Text(
                                                waitTime,
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 10.5,
                                                  color: AppColors
                                                      .textSecondary(context),
                                                ),
                                              ),
                                            if (a.appointmentTypeName != null) ...[
                                              Text(
                                                ' • ',
                                                style: GoogleFonts.cairo(
                                                    color: AppColors.textMuted(
                                                        context),
                                                    fontSize: 10),
                                              ),
                                              Text(
                                                a.appointmentTypeName!,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10,
                                                  color: AppColors
                                                      .textSecondary(context),
                                                ),
                                              ),
                                            ],
                                            if (!isDoctor &&
                                                a.doctorName != null &&
                                                a.doctorName!.isNotEmpty) ...[
                                              Text(
                                                ' • ',
                                                style: GoogleFonts.cairo(
                                                    color: AppColors.textMuted(
                                                        context),
                                                    fontSize: 10),
                                              ),
                                              Text(
                                                DoctorUtils.formatTitle(
                                                    a.doctorName),
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10,
                                                  color: AppColors
                                                      .textSecondary(context),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Small arrow or active indicator
                                  if (isCurrent)
                                    const Icon(
                                      Icons.arrow_back_ios_rounded,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Action Footer
              if (waitingCount > 0 && nextWaiting.id.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpace.sm),
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context).withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle(context)),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onCallNext != null) {
                        widget.onCallNext!();
                      } else {
                        widget.onSelectAppointment(nextWaiting);
                      }
                    },
                    icon: const Icon(Icons.record_voice_over_rounded, size: 16),
                    label: Text(
                      'استدعاء التالي: ${nextWaiting.patient.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'خطأ في تحميل الطابور: $e',
          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.danger),
        ),
      ),
    );
  }
}
