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
import '../../../../core/utils/doctor_utils.dart';
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

    final price = appointment.priceCharged ?? 0.0;
    final totalPaid = appointment.totalPaid;
    final remaining = (price > totalPaid) ? (price - totalPaid) : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      backgroundColor: AppColors.surface(context),
      borderColor: AppColors.borderSubtle(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── رأس البطاقة: المريض والحالة والواتساب ───
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingLg(
                        AppColors.textPrimary(context),
                      ).copyWith(height: 1.3),
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
                        borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: AppSpace.lg),

          // ─── 1. بيانات الحجز والزيارة ───
          _buildSectionHeader(
            context,
            'بيانات الحجز والزيارة',
            Icons.event_note_rounded,
          ),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
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
                  isMono: true,
                ),
                if (appointment.appointmentTypeName != null &&
                    appointment.appointmentTypeName!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.medical_information_outlined,
                    label: 'نوع الكشف',
                    value: appointment.appointmentTypeName!,
                  ),
                ],
                if (appointment.doctorName != null &&
                    appointment.doctorName!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.person_pin_outlined,
                    label: 'الطبيب',
                    value: DoctorUtils.formatTitle(appointment.doctorName),
                  ),
                ],
                if (appointment.branchName != null &&
                    appointment.branchName!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.storefront_outlined,
                    label: 'الفرع',
                    value: appointment.branchName!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // ─── 2. البيانات المالية والتحصيل ───
          _buildSectionHeader(
            context,
            'البيانات المالية والتحصيل',
            Icons.account_balance_wallet_outlined,
          ),
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'إجمالي المدفوع',
                  value: '${totalPaid.toStringAsFixed(0)} ج.م',
                  valueColor: totalPaid > 0 ? AppColors.success : null,
                  isMono: true,
                ),
                if (appointment.priceCharged != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  _DetailRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'السعر المستحق',
                    value: '${price.toStringAsFixed(0)} ج.م',
                    isMono: true,
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Icon(
                      Icons.price_check_rounded,
                      size: 16,
                      color: AppColors.textSecondary(context),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'حالة التحصيل',
                        style: AppTypography.bodySm(
                            AppColors.textSecondary(context)),
                      ),
                    ),
                    if (remaining > 0)
                      AppBadge(
                        label: 'متبقي ${remaining.toStringAsFixed(0)} ج.م',
                        icon: Icons.warning_amber_rounded,
                        variant: AppBadgeVariant.danger,
                      )
                    else if (totalPaid > 0)
                      const AppBadge(
                        label: 'مسدد بالكامل',
                        icon: Icons.check_circle_rounded,
                        variant: AppBadgeVariant.success,
                      )
                    else
                      const AppBadge(
                        label: 'لم يتم التحصيل',
                        icon: Icons.hourglass_empty_rounded,
                        variant: AppBadgeVariant.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // ─── 3. الخدمات الطبية المرفقة ───
          _buildSectionHeader(
            context,
            'الخدمات الطبية المرفقة',
            Icons.medical_services_outlined,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: (appointment.serviceNames != null &&
                    appointment.serviceNames!.isNotEmpty)
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: appointment.serviceNames!.map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderSubtle(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              service,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.textMuted(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'لا توجد خدمات إضافية مرفقة بهذا الموعد',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textMuted(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpace.lg),

          // ─── 4. الإجراءات السريرية ───
          _buildSectionHeader(
            context,
            'الإجراءات السريرية',
            Icons.bolt_rounded,
          ),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              // إجراءات سريرية رئيسية حسب الحالة
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

              // إجراءات الإدارة والملف
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

              // إجراء الإلغاء
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

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpace.sm),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
              height: 1.35,
            ),
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
  final Color? valueColor;
  final bool isMono;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isMono = false,
  });

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
            style: isMono
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary(context),
                  )
                : AppTypography.bodySm(
                        valueColor ?? AppColors.textPrimary(context))
                    .copyWith(fontWeight: FontWeight.w600, height: 1.35),
          ),
        ),
      ],
    );
  }
}