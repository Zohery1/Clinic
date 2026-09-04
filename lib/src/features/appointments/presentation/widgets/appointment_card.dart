import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/widgets/clinic_toast.dart';
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

/// كارت موعد عالي الكثافة (Compact High-Density Card)
/// مصمم هندسياً للعيادات المزدحمة لتقليل التمرير وعرض البيانات الجوهرية بوضوح
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

  static const _statusLabels = <String, String>{
    'pending': 'مع الطبيب',
    'confirmed': 'في الانتظار',
    'completed': 'منتهي',
    'cancelled': 'ملغي',
    'cancelled_by_patient': 'غائب/معتذر',
    'cancelled_by_clinic': 'ملغي من العيادة',
  };

  static const _statusIcons = <String, IconData>{
    'pending': Icons.medical_services_outlined,
    'confirmed': Icons.hourglass_top_rounded,
    'completed': Icons.check_circle_rounded,
    'cancelled': Icons.cancel_outlined,
    'cancelled_by_patient': Icons.person_off_outlined,
    'cancelled_by_clinic': Icons.cancel_outlined,
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.info;
      case 'confirmed':
        return AppColors.warning;
      case 'completed':
        return AppColors.success;
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
                body: 'تم إلغاء حجز المريض (${appointment.patient.fullName})',
                targetRole: 'doctor',
              );
        } else if (status == 'pending') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'دخول مريض للفحص',
                body:
                    'المريض (${appointment.patient.fullName}) في انتظارك الآن',
                targetRole: 'doctor',
                playSound: true,
              );
        } else if (status == 'completed') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'إنتهاء موعد',
                body:
                    'تم الانتهاء من موعد المريض (${appointment.patient.fullName})',
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
                  : 'تم إلغاء الموعد';
      final icon = status == 'pending'
          ? Icons.person_search_rounded
          : status == 'completed'
              ? Icons.check_circle_rounded
              : status == 'confirmed'
                  ? Icons.hourglass_empty_rounded
                  : Icons.info_outline_rounded;
      final color = _statusColor(status);
      ClinicToast.show(context, message: label, icon: icon, color: color);
    } catch (e) {
      if (!context.mounted) return;
      ClinicToast.showError(context, 'حدث خطأ: $e');
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
        onConfirm: () {
          _updateStatus(context, ref, target);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;
    final formattedTime = intl.DateFormat('hh:mm a')
        .format(appointment.appointmentDate.toLocal());
    final status = appointment.status.toLowerCase();
    final isPending = status == 'pending';
    final isCompleted = status == 'completed';
    final isCancelled = status.startsWith('cancelled');
    final label = _statusLabels[status] ?? 'في الانتظار';
    final icon = _statusIcons[status] ?? Icons.hourglass_top_rounded;
    final color = _statusColor(status);

    final price = appointment.priceCharged ?? 0.0;
    final totalPaid = appointment.totalPaid;
    final remaining = (price > totalPaid) ? (price - totalPaid) : 0.0;
    final hasBalance = remaining > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySubtle
              : (AppColors.isDark(context)
                  ? const Color(0xFF1E293B)
                  : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isPending
                    ? AppColors.info.withValues(alpha: 0.4)
                    : AppColors.borderSubtle(context)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap ??
                () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => PatientDetailsDialog(
                      clinicId: clinicId,
                      patient: appointment.toPatientModel(),
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(10),
            child: Opacity(
              opacity: (isCompleted || isCancelled) ? 0.75 : 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    // ─── 1. المؤشر اللوني للحالة + رقم الطابور ───
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // شارة رقم الطابور أو الأيقونة
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.infoSubtle
                            : (isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : color.withValues(alpha: 0.1)),
                        shape: BoxShape.circle,
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
                          fontWeight: FontWeight.w800,
                          color: isPending
                              ? AppColors.info
                              : (isSelected ? AppColors.primary : color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ─── 2. الوقت في شريحة مدمجة ───
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.info.withValues(alpha: 0.12)
                            : AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isPending
                                ? AppColors.info
                                : AppColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isPending
                                  ? AppColors.info
                                  : AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ─── 3. بيانات المريض والكشف (وسط مرن) ───
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // السطر الأول: الاسم + الهاتف واتساب + نوع الكشف
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  appointment.patient.fullName,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (appointment.patient.phone != null &&
                                  appointment.patient.phone!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => showSendWhatsAppDialog(
                                    context,
                                    ref,
                                    phone: appointment.patient.phone!,
                                    patientName: appointment.patient.fullName,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_rounded,
                                          size: 11,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          appointment.patient.phone!,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (appointment.appointmentTypeName != null &&
                                  appointment
                                      .appointmentTypeName!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.subtle(context),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.borderSubtle(context),
                                    ),
                                  ),
                                  child: Text(
                                    appointment.appointmentTypeName!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),

                          // السطر الثاني: شارة الحالة + اسم الطبيب + الرصيد المالي
                          Row(
                            children: [
                              AppBadge(
                                label: label,
                                icon: icon,
                                variant: _badgeVariant(status),
                              ),
                              if (appointment.doctorName != null &&
                                  appointment.doctorName!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'د. ${appointment.doctorName}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: AppColors.textMuted(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (totalPaid > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'مدفوع ${totalPaid.toStringAsFixed(0)} ج.م',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              if (hasBalance) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'متبقي ${remaining.toStringAsFixed(0)} ج.م',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ─── 4. الإجراء الفوري السريع ───
                    _buildQuickAction(context, ref, status, isDoctor),

                    // ─── 5. قائمة الخيارات المنبثقة ───
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.textMuted(context),
                      ),
                      tooltip: 'خيارات الموعد',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 160),
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
                            showDialog<void>(
                              context: context,
                              builder: (_) => PatientDetailsDialog(
                                clinicId: clinicId,
                                patient: appointment.toPatientModel(),
                              ),
                            );
                            break;
                          case 'whatsapp':
                            if (appointment.patient.phone != null) {
                              showSendWhatsAppDialog(
                                context,
                                ref,
                                phone: appointment.patient.phone!,
                                patientName: appointment.patient.fullName,
                              );
                            }
                            break;
                          case 'revert':
                            _updateStatus(context, ref, 'confirmed');
                            break;
                          case 'cancel':
                            _openAdmission(
                                context, ref, 'cancelled_by_clinic');
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: _popupRow(
                            Icons.person_outline_rounded,
                            'ملف المريض الكامل',
                            AppColors.textPrimary(context),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: _popupRow(
                            Icons.edit_outlined,
                            'تعديل الموعد',
                            AppColors.textPrimary(context),
                          ),
                        ),
                        if (appointment.patient.phone != null &&
                            appointment.patient.phone!.isNotEmpty)
                          PopupMenuItem(
                            value: 'whatsapp',
                            child: _popupRow(
                              Icons.chat_bubble_outline_rounded,
                              'مراسلة واتساب',
                              AppColors.success,
                            ),
                          ),
                        if (isPending)
                          PopupMenuItem(
                            value: 'revert',
                            child: _popupRow(
                              Icons.replay_rounded,
                              'إعادة للانتظار',
                              AppColors.warning,
                            ),
                          ),
                        if (!isCancelled && !isCompleted)
                          PopupMenuItem(
                            value: 'cancel',
                            child: _popupRow(
                              Icons.cancel_outlined,
                              'إلغاء الموعد',
                              AppColors.danger,
                            ),
                          ),
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
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FilledButton.icon(
          onPressed: () => _openAdmission(context, ref, 'pending'),
          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
          label: Text(
            'دخول للطبيب',
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    if (status == 'pending') {
      if (isDoctor) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
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
            label: Text(
              'بدء الفحص',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FilledButton.icon(
            onPressed: () => _openAdmission(context, ref, 'completed'),
            icon: const Icon(Icons.check_rounded, size: 14),
            label: Text(
              'إنهاء الكشف',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
          ),
        );
      }
    }

    if (status == 'completed' && isDoctor) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
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
          label: Text(
            'عرض التقرير',
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            minimumSize: const Size(0, 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _popupRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
