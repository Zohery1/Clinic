import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/ui/tokens/typography.dart';
import '../../../../core/widgets/app_card.dart';
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
import '../visit_notes_dialog.dart';

/// Full appointment details card used in the desktop right pane.
class AppointmentDetailsCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final String clinicId;

  const AppointmentDetailsCard({
    super.key,
    required this.appointment,
    required this.clinicId,
  });

  static const _statusLabels = <String, String>{
    'pending': 'مع الطبيب',
    'confirmed': 'في الانتظار',
    'completed': 'منتهي',
    'cancelled': 'ملغي',
    'cancelled_by_patient': 'ملغي',
    'cancelled_by_clinic': 'ملغي',
  };

  static const _statusIcons = <String, IconData>{
    'pending': Icons.person_search_rounded,
    'confirmed': Icons.hourglass_top_rounded,
    'completed': Icons.check_circle_rounded,
    'cancelled': Icons.cancel_outlined,
    'cancelled_by_patient': Icons.cancel_outlined,
    'cancelled_by_clinic': Icons.cancel_outlined,
  };

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
      ClinicToast.show(
        context,
        message: 'تم تحديث حالة الموعد',
        icon: Icons.check_rounded,
        color: AppColors.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      ClinicToast.showError(context, 'حدث خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;
    final formattedDate = intl.DateFormat('EEEE، d MMMM yyyy', 'ar')
        .format(appointment.appointmentDate.toLocal());
    final formattedTime = intl.DateFormat('hh:mm a')
        .format(appointment.appointmentDate.toLocal());
    final status = appointment.status.toLowerCase();
    final label = _statusLabels[status] ?? 'في الانتظار';
    final icon = _statusIcons[status] ?? Icons.hourglass_top_rounded;
    final canCancel = status != 'cancelled' &&
        status != 'cancelled_by_patient' &&
        status != 'cancelled_by_clinic' &&
        status != 'completed';

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: appointment.patient.fullName,
                size: AppAvatarSize.lg,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patient.fullName,
                      style:
                          AppTypography.headingLg(AppColors.textPrimary(context)),
                    ),
                    const SizedBox(height: 2),
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
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              appointment.patient.phone!,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              AppBadge(
                label: label,
                icon: icon,
                variant: _badgeVariant(status),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          AppCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            backgroundColor: AppColors.subtle(context),
            borderColor: AppColors.borderSubtle(context),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'التاريخ',
                  value: formattedDate,
                ),
                const SizedBox(height: AppSpace.sm),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'الوقت',
                  value: formattedTime,
                ),
                if (appointment.appointmentTypeName != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.medical_information_outlined,
                    label: 'نوع الكشف',
                    value: appointment.appointmentTypeName!,
                  ),
                ],
                if (appointment.doctorName != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.person_pin_outlined,
                    label: 'الطبيب',
                    value: 'د. ${appointment.doctorName}',
                  ),
                ],
                if (appointment.branchName != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.storefront_outlined,
                    label: 'الفرع',
                    value: appointment.branchName!,
                  ),
                ],
                if (appointment.totalPaid > 0) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'إجمالي المدفوع',
                    value: '${appointment.totalPaid.toStringAsFixed(0)} ج.م',
                  ),
                ],
                if (appointment.serviceNames != null &&
                    appointment.serviceNames!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.medical_services_outlined,
                    label: 'الخدمات',
                    value: appointment.serviceNames!.join('، '),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppButton(
                label: 'الملف الشخصي',
                icon: Icons.person_rounded,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => PatientDetailsDialog(
                      clinicId: clinicId,
                      patient: appointment.toPatientModel(),
                    ),
                  );
                },
              ),
              AppButton(
                label: 'تعديل',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => EditAppointmentDialog(
                      clinicId: clinicId,
                      appointment: appointment,
                    ),
                  );
                },
              ),
              if (status == 'confirmed')
                AppButton(
                  label: 'نقل للطبيب',
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.primary,
                  expand: false,
                  onPressed: () => _updateStatus(context, ref, 'pending'),
                ),
              if (status == 'pending' && isDoctor)
                AppButton(
                  label: 'بدء الفحص',
                  icon: Icons.medical_services_outlined,
                  variant: AppButtonVariant.primary,
                  expand: false,
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
                ),
              if (status == 'pending' && !isDoctor)
                AppButton(
                  label: 'إنهاء الكشف',
                  icon: Icons.check_rounded,
                  variant: AppButtonVariant.primary,
                  expand: false,
                  onPressed: () => _updateStatus(context, ref, 'completed'),
                ),
              if (status == 'completed' && isDoctor)
                AppButton(
                  label: 'عرض التقرير',
                  icon: Icons.edit_note_rounded,
                  variant: AppButtonVariant.secondary,
                  expand: false,
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
                ),
              if (status == 'completed')
                AppButton(
                  label: 'ملاحظات الزيارة',
                  icon: Icons.note_alt_rounded,
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => VisitNotesDialog(
                        clinicId: clinicId,
                        appointmentId: appointment.id,
                        patientId: appointment.patientId,
                        patientName: appointment.patient.fullName,
                      ),
                    );
                  },
                ),
              if (canCancel)
                AppButton(
                  label: 'إلغاء الموعد',
                  icon: Icons.cancel_outlined,
                  variant: AppButtonVariant.destructive,
                  expand: false,
                  onPressed: () => _updateStatus(context, ref, 'cancelled'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary(context)),
        const SizedBox(width: AppSpace.sm),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodySm(AppColors.textSecondary(context)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySm(AppColors.textPrimary(context))
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}