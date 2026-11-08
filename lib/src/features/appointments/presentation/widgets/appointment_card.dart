import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/routing/routing.dart';
import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/appointment_status.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../edit_appointment_dialog.dart';
import 'admission_confirmation_sheet.dart';

/// بطاقة الموعد السريري المدمجة عالية الكثافة (Clinical High-Density Appointment Card).
/// تدعم عرض التفاصيل بدقة، مع أزرار الإجراء السريع (كشف / إنهاء / دخول)
/// وخيارات إلغاء ثنائية دقيقة (إلغاء العيادة / اعتذار المريض) وإمكانية إعادة المريض للانتظار.
class AppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final String clinicId;
  final bool isSelected;
  final int? queueIndex;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.clinicId,
    this.isSelected = false,
    this.queueIndex,
    this.onTap,
  });

  // Canonical labels come from the central map in core/utils.
  static Map<String, String> get _statusLabels => appointmentStatusLabels;

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.info;
      case 'confirmed':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
      case 'cancelled_by_patient':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  AppBadgeVariant _badgeVariant(String status) {
    switch (status) {
      case 'pending':
        return AppBadgeVariant.info;
      case 'confirmed':
        return AppBadgeVariant.warning;
      case 'completed':
        return AppBadgeVariant.success;
      case 'cancelled_by_patient':
        return AppBadgeVariant.warning;
      default:
        return AppBadgeVariant.danger;
    }
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(appointment.id, status);
      invalidateAppointmentsAndReports(ref);

      try {
        if (status.startsWith('cancelled')) {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'إلغاء موعد',
                body: status == 'cancelled_by_patient'
                    ? 'اعتذر المريض (${appointment.patient.fullName}) عن الحضور'
                    : 'تم إلغاء موعد (${appointment.patient.fullName}) من العيادة',
                targetRole: 'doctor',
              );
        } else if (status == 'pending') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'دخول مريض',
                body: 'المريض (${appointment.patient.fullName}) في انتظارك الآن',
                targetRole: 'doctor',
                playSound: true,
              );
        } else if (status == 'completed') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'انتهاء كشف',
                body: 'تم انتهاء كشف (${appointment.patient.fullName})',
                targetRole: 'secretary',
                playSound: true,
              );
        }
      } catch (_) {}

      if (!context.mounted) return;
      final label = status == 'pending'
          ? 'تم نقل المريض للطبيب'
          : status == 'completed'
              ? 'تم إنهاء الكشف'
              : status == 'confirmed'
                  ? 'تمت إعادة المريض للانتظار'
                  : status == 'cancelled_by_patient'
                      ? 'تم تسجيل اعتذار المريض'
                      : 'تم إلغاء الموعد من العيادة';

      ClinicToast.show(
        context,
        message: label,
        icon: Icons.check_circle_outline,
        color: _statusColor(status),
      );
    } catch (e) {
      if (!context.mounted) return;
      ClinicToast.showError(context, 'حدث خطأ أثناء التحديث.');
    }
  }

  void _openAdmission(BuildContext context, WidgetRef ref, String target) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdmissionConfirmationSheet(
        appointment: appointment,
        targetStatus: target,
        onConfirm: () => _updateStatus(context, ref, target),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;
    final formattedTime =
        intl.DateFormat('hh:mm a').format(appointment.appointmentDate.toLocal());
    final status = appointment.status.toLowerCase();
    final isPending = status == 'pending';
    final isCompleted = status == 'completed';
    final isCancelled = status.startsWith('cancelled');
    final label = _statusLabels[status] ?? 'في الانتظار';
    final color = _statusColor(status);

    final price = appointment.priceCharged ?? 0.0;
    final totalPaid = appointment.totalPaid;
    final remaining = (price > totalPaid) ? (price - totalPaid) : 0.0;
    final hasBalance = remaining > 0;

    final bg = isSelected
        ? AppColors.primarySubtle
        : (isPending ? AppColors.infoSubtle : AppColors.surface(context));

    final borderColor = isSelected
        ? AppColors.primary
        : (isPending ? AppColors.info : AppColors.borderSubtle(context));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: borderColor,
            width: isSelected || isPending ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: InkWell(
            onTap: onTap ??
                () {
                  AppNavigation.showPatientDetails(
                    context,
                    clinicId: clinicId,
                    patient: appointment.toPatientModel(),
                  );
                },
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Opacity(
              opacity: isCompleted ? 0.85 : (isCancelled ? 0.70 : 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm, vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // رقم الطابور أو الحرف الأولي
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        queueIndex != null
                            ? '$queueIndex'
                            : (appointment.patient.fullName.isNotEmpty
                                ? appointment.patient.fullName[0]
                                : '#'),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),

                    // معلومات المريض والتوقيت
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                appointment.patient.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              AppBadge(
                                label: label,
                                size: AppBadgeSize.sm,
                                variant: _badgeVariant(status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                formattedTime,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                              if (appointment.doctorName != null &&
                                  appointment.doctorName!.isNotEmpty)
                                Text(
                                  '• ${DoctorUtils.formatTitle(appointment.doctorName)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted(context),
                                  ),
                                ),
                              if (hasBalance)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerSubtle,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.xs),
                                  ),
                                  child: Text(
                                    'متبقي ${remaining.toStringAsFixed(0)} ج.م',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),

                    // زر الإجراء السريع (كشف / دخول / إنهاء)
                    _buildQuickAction(context, ref, status, isDoctor),
                    const SizedBox(width: 2),

                    // قائمة الإجراءات الإضافية المخصصة
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 17,
                        color: AppColors.textMuted(context),
                      ),
                      tooltip: 'خيارات الموعد',
                      padding: EdgeInsets.zero,
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            showDialog<void>(
                              context: context,
                              builder: (_) => EditAppointmentDialog(
                                clinicId: clinicId,
                                appointment: appointment,
                              ),
                            );
                            break;
                          case 'profile':
                            AppNavigation.showPatientDetails(
                              context,
                              clinicId: clinicId,
                              patient: appointment.toPatientModel(),
                            );
                            break;
                          case 'whatsapp':
                            if (appointment.patient.phone != null) {
                              AppNavigation.showWhatsApp(
                                context,
                                phone: appointment.patient.phone!,
                                patientName: appointment.patient.fullName,
                              );
                            }
                            break;
                          case 'revert':
                            _openAdmission(context, ref, 'confirmed');
                            break;
                          case 'cancel_by_clinic':
                            _openAdmission(context, ref, 'cancelled_by_clinic');
                            break;
                          case 'cancel_by_patient':
                            _openAdmission(
                                context, ref, 'cancelled_by_patient');
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 16),
                              const SizedBox(width: 8),
                              Text('ملف المريض',
                                  style: GoogleFonts.cairo(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 16),
                              const SizedBox(width: 8),
                              Text('تعديل الموعد',
                                  style: GoogleFonts.cairo(fontSize: 12)),
                            ],
                          ),
                        ),
                        if (appointment.patient.phone != null)
                          PopupMenuItem(
                            value: 'whatsapp',
                            child: Row(
                              children: [
                                const Icon(Icons.chat_outlined, size: 16),
                                const SizedBox(width: 8),
                                Text('مراسلة واتساب',
                                    style: GoogleFonts.cairo(fontSize: 12)),
                              ],
                            ),
                          ),
                        if (isCompleted || isCancelled)
                          PopupMenuItem(
                            value: 'revert',
                            child: Row(
                              children: [
                                const Icon(Icons.replay_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('إعادة للانتظار',
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        if (!isCancelled && !isCompleted) ...[
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'cancel_by_clinic',
                            child: Row(
                              children: [
                                const Icon(Icons.domain_disabled_rounded,
                                    size: 16, color: AppColors.danger),
                                const SizedBox(width: 8),
                                Text('إلغاء من العيادة',
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'cancel_by_patient',
                            child: Row(
                              children: [
                                const Icon(Icons.person_off_outlined,
                                    size: 16, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Text('اعتذار من المريض',
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, WidgetRef ref, String status, bool isDoctor) {
    if (status == 'confirmed') {
      return ElevatedButton(
        onPressed: () {
          if (isDoctor) {
            AppNavigation.toExamination(
              context,
              clinicId: clinicId,
              appointmentId: appointment.id,
              patientId: appointment.patientId,
              patientName: appointment.patient.fullName,
            );
          } else {
            _openAdmission(context, ref, 'pending');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(54, 28),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xs)),
        ),
        child: Text(
          isDoctor ? 'كشف' : 'دخول',
          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    } else if (status == 'pending') {
      return ElevatedButton(
        onPressed: () {
          if (isDoctor) {
            AppNavigation.toExamination(
              context,
              clinicId: clinicId,
              appointmentId: appointment.id,
              patientId: appointment.patientId,
              patientName: appointment.patient.fullName,
            );
          } else {
            _openAdmission(context, ref, 'completed');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(54, 28),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.xs)),
        ),
        child: Text(
          isDoctor ? 'استكمال' : 'إنهاء',
          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
