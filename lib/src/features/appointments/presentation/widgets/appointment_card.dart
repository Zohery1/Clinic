import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/utils/doctor_utils.dart';
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
              ? (AppColors.isDark(context)
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primarySubtle)
              : (isPending
                  ? (AppColors.isDark(context)
                      ? AppColors.info.withValues(alpha: 0.12)
                      : AppColors.infoSubtle)
                  : AppColors.surface(context)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isPending
                    ? AppColors.info.withValues(alpha: 0.45)
                    : AppColors.borderSubtle(context)),
            width: isSelected ? 1.5 : (isPending ? 1.2 : 1.0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : (isPending
                  ? [
                      BoxShadow(
                        color: AppColors.info.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null),
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
              opacity: isCompleted
                  ? 0.85
                  : (isCancelled ? 0.70 : 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 460;

                    // 1. المؤشر اللوني
                    Widget buildColorBar([double height = 38]) => Container(
                          width: 3,
                          height: height,
                          decoration: BoxDecoration(
                            color: isPending ? AppColors.info : color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );

                    // 2. شارة رقم الطابور أو الأيقونة
                    Widget buildQueueBadge([double size = 30]) => Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: isPending
                                ? AppColors.infoSubtle
                                : (isSelected
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : color.withValues(alpha: 0.12)),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            queueIndex != null
                                ? '$queueIndex'
                                : (appointment.patient.fullName.isNotEmpty
                                    ? appointment.patient.fullName[0]
                                    : '#'),
                            style: queueIndex != null
                                ? GoogleFonts.jetBrainsMono(
                                    fontSize: size * 0.4,
                                    fontWeight: FontWeight.w800,
                                    color: isPending
                                        ? AppColors.info
                                        : (isSelected ? AppColors.primary : color),
                                  )
                                : GoogleFonts.cairo(
                                    fontSize: size * 0.4,
                                    fontWeight: FontWeight.w800,
                                    color: isPending
                                        ? AppColors.info
                                        : (isSelected ? AppColors.primary : color),
                                  ),
                          ),
                        );

                    // 3. الوقت في شريحة مدمجة
                    final timeWidget = Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.info.withValues(alpha: 0.12)
                            : AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isPending
                              ? AppColors.info.withValues(alpha: 0.25)
                              : AppColors.borderSubtle(context),
                          width: 0.8,
                        ),
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
                    );

                    // 4. نوع الكشف
                    Widget? appointmentTypeWidget;
                    if (appointment.appointmentTypeName != null &&
                        appointment.appointmentTypeName!.isNotEmpty) {
                      appointmentTypeWidget = Container(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                            height: 1.35,
                          ),
                        ),
                      );
                    }

                    // 5. زر الواتساب
                    Widget? whatsappWidget;
                    if (appointment.patient.phone != null &&
                        appointment.patient.phone!.isNotEmpty) {
                      whatsappWidget = InkWell(
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
                      );
                    }

                    // 6. اسم الطبيب
                    Widget? doctorWidget;
                    if (appointment.doctorName != null &&
                        appointment.doctorName!.isNotEmpty) {
                      doctorWidget = Text(
                        DoctorUtils.formatTitle(appointment.doctorName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textMuted(context),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      );
                    }

                    // 7. الشارة المالية
                    final financialBadges = [
                      if (totalPaid > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
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
                      if (hasBalance)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
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
                    ];

                    // 8. زر الإجراء السريع
                    final quickActionWidget = _buildQuickAction(context, ref, status, isDoctor);

                    // 9. القائمة المنبثقة
                    final menuWidget = PopupMenuButton<String>(
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
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              buildColorBar(22),
                              const SizedBox(width: 6),
                              buildQueueBadge(22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appointment.patient.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(context),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              menuWidget,
                            ],
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              timeWidget,
                              if (appointmentTypeWidget != null) appointmentTypeWidget,
                              if (doctorWidget != null) doctorWidget,
                              if (whatsappWidget != null) whatsappWidget,
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    AppBadge(
                                      label: label,
                                      icon: icon,
                                      variant: _badgeVariant(status),
                                    ),
                                    ...financialBadges,
                                  ],
                                ),
                              ),
                              if (quickActionWidget != null) ...[
                                const SizedBox(width: 6),
                                quickActionWidget,
                              ],
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        buildColorBar(38),
                        const SizedBox(width: 10),
                        buildQueueBadge(30),
                        const SizedBox(width: 12),
                        timeWidget,
                        const SizedBox(width: 16),
                        // Patient Name + Doctor Info
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                appointment.patient.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (doctorWidget != null) ...[
                                    doctorWidget,
                                    const SizedBox(width: 8),
                                  ],
                                  if (whatsappWidget != null) whatsappWidget,
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Service Type & Status Badge
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (appointmentTypeWidget != null) ...[
                                appointmentTypeWidget,
                                const SizedBox(height: 4),
                              ],
                              AppBadge(
                                label: label,
                                icon: icon,
                                variant: _badgeVariant(status),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Financial Status
                        if (financialBadges.isNotEmpty) ...[
                          Wrap(
                            spacing: 4,
                            children: financialBadges,
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Action Station
                        if (quickActionWidget != null) ...[
                          quickActionWidget,
                          const SizedBox(width: 8),
                        ],
                        menuWidget,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildQuickAction(
      BuildContext context, WidgetRef ref, String status, bool isDoctor) {
    if (status == 'confirmed') {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          child: FilledButton.icon(
            onPressed: () => _openAdmission(context, ref, 'pending'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: Text(
              'دخول للطبيب',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.padded,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    if (status == 'pending') {
      if (isDoctor) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
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
                  height: 1.35,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                elevation: 0,
              ),
            ),
          ),
        );
      } else {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: FilledButton.icon(
              onPressed: () => _openAdmission(context, ref, 'completed'),
              icon: const Icon(Icons.check_rounded, size: 14),
              label: Text(
                'إنهاء الكشف',
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                elevation: 0,
              ),
            ),
          ),
        );
      }
    }

    if (status == 'completed' && isDoctor) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
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
                height: 1.35,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.padded,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
      );
    }

    return null;
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
