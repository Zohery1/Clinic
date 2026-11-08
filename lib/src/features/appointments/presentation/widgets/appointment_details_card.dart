import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/routing/routing.dart';
import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/primitives/app_badge.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/appointment_status.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../dashboard/presentation/notifications_controller.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../edit_appointment_dialog.dart';
import '../visit_notes_dialog.dart';
import 'admission_confirmation_sheet.dart';

/// بطاقة التفاصيل السريرية الكاملة المدمجة (High-Density Clinical Details Card).
/// تدعم إتمام الفحص، التحويل للانتظار، وإلغاء الموعد المزدوج (عيادة / مريض).
class AppointmentDetailsCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final String clinicId;

  const AppointmentDetailsCard({
    super.key,
    required this.appointment,
    required this.clinicId,
  });

  // Canonical labels come from the central map in core/utils.
  static Map<String, String> get _statusLabels => appointmentStatusLabels;

  static const _statusIcons = <String, IconData>{
    'pending': Icons.person_search_rounded,
    'confirmed': Icons.hourglass_top_rounded,
    'completed': Icons.check_circle_rounded,
    'cancelled': Icons.cancel_outlined,
    'cancelled_by_patient': Icons.person_off_outlined,
    'cancelled_by_clinic': Icons.domain_disabled_rounded,
  };

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
                    : 'تم إلغاء حجز المريض (${appointment.patient.fullName}) من العيادة',
                targetRole: 'doctor',
              );
        } else if (status == 'pending') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'دخول مريض لغرفة الكشف',
                body:
                    'المريض (${appointment.patient.fullName}) داخل غرفة الفحص الآن',
                targetRole: 'doctor',
                playSound: true,
              );
        } else if (status == 'completed') {
          ref.read(notificationsProvider.notifier).sendBroadcastNotification(
                title: 'اكتمال الكشف',
                body:
                    'تم الانتهاء من فحص المريض (${appointment.patient.fullName})',
                targetRole: 'secretary',
                playSound: true,
              );
        }
      } catch (_) {}

      if (!context.mounted) return;
      final label = status == 'pending'
          ? 'تم دخول المريض لغرفة الكشف'
          : status == 'completed'
              ? 'تم إنهاء الكشف بنجاح'
              : status == 'confirmed'
                  ? 'تمت إعادة المريض لصالة الانتظار'
                  : status == 'cancelled_by_patient'
                      ? 'تم تسجيل اعتذار المريض'
                      : 'تم إلغاء الكشف من العيادة';

      ClinicToast.show(
        context,
        message: label,
        icon: Icons.check_rounded,
        color: AppColors.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      ClinicToast.showError(context, 'تعذر تحديث حالة الكشف، يرجى إعادة المحاولة');
    }
  }

  void _openConfirmation(BuildContext context, WidgetRef ref, String target) {
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
    final formattedDate = intl.DateFormat('EEEE، d MMMM yyyy', 'ar')
        .format(appointment.appointmentDate.toLocal());
    final formattedTime = intl.DateFormat('hh:mm a')
        .format(appointment.appointmentDate.toLocal());
    final status = appointment.status.toLowerCase();
    final label = _statusLabels[status] ?? 'في الانتظار';
    final icon = _statusIcons[status] ?? Icons.hourglass_top_rounded;
    final isCancelled = status.startsWith('cancelled');
    final isCompleted = status == 'completed';
    final canCancel = !isCancelled && !isCompleted;

    final price = appointment.priceCharged ?? 0.0;
    final totalPaid = appointment.totalPaid;
    final remaining = (price > totalPaid) ? (price - totalPaid) : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      backgroundColor: AppColors.surface(context),
      borderColor: AppColors.borderSubtle(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── رأس البطاقة: المريض والحالة والواتساب ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: appointment.patient.fullName,
                size: AppAvatarSize.md,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patient.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (appointment.patient.phone != null &&
                        appointment.patient.phone!.isNotEmpty)
                      InkWell(
                        onTap: () => AppNavigation.showWhatsApp(
                          context,
                          phone: appointment.patient.phone!,
                          patientName: appointment.patient.fullName,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_rounded,
                                size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              appointment.patient.phone!,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
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
              const SizedBox(width: AppSpace.xs),
              AppBadge(
                label: label,
                icon: icon,
                size: AppBadgeSize.sm,
                variant: _badgeVariant(status),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          // ─── 1. بيانات الحجز والزيارة ───
          _buildSectionHeader(
            context,
            'بيانات الحجز والزيارة',
            Icons.event_note_rounded,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.canvas(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'التاريخ',
                  value: formattedDate,
                ),
                Divider(height: 8, color: AppColors.borderSubtle(context)),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'الوقت',
                  value: formattedTime,
                  isMono: true,
                ),
                if (appointment.appointmentTypeName != null &&
                    appointment.appointmentTypeName!.isNotEmpty) ...[
                  Divider(height: 8, color: AppColors.borderSubtle(context)),
                  _DetailRow(
                    icon: Icons.medical_information_outlined,
                    label: 'نوع الكشف',
                    value: appointment.appointmentTypeName!,
                  ),
                ],
                if (appointment.doctorName != null &&
                    appointment.doctorName!.isNotEmpty) ...[
                  Divider(height: 8, color: AppColors.borderSubtle(context)),
                  _DetailRow(
                    icon: Icons.person_pin_outlined,
                    label: 'الطبيب',
                    value: DoctorUtils.formatTitle(appointment.doctorName),
                  ),
                ],
                if (appointment.branchName != null &&
                    appointment.branchName!.isNotEmpty) ...[
                  Divider(height: 8, color: AppColors.borderSubtle(context)),
                  _DetailRow(
                    icon: Icons.storefront_outlined,
                    label: 'الفرع',
                    value: appointment.branchName!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // ─── 2. البيانات المالية والتحصيل ───
          _buildSectionHeader(
            context,
            'البيانات المالية والتحصيل',
            Icons.account_balance_wallet_outlined,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.canvas(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'المدفوع',
                  value: '${totalPaid.toStringAsFixed(0)} ج.م',
                  valueColor: totalPaid > 0 ? AppColors.success : null,
                  isMono: true,
                ),
                if (appointment.priceCharged != null) ...[
                  Divider(height: 8, color: AppColors.borderSubtle(context)),
                  _DetailRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'المستحق',
                    value: '${price.toStringAsFixed(0)} ج.م',
                    isMono: true,
                  ),
                ],
                Divider(height: 8, color: AppColors.borderSubtle(context)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.price_check_rounded,
                        size: 15,
                        color: AppColors.textSecondary(context),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      SizedBox(
                        width: 90,
                        child: Text(
                          'حالة السداد',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                      if (remaining > 0)
                        AppBadge(
                          label: 'متبقي ${remaining.toStringAsFixed(0)} ج.م',
                          icon: Icons.warning_amber_rounded,
                          size: AppBadgeSize.sm,
                          variant: AppBadgeVariant.danger,
                        )
                      else if (totalPaid > 0)
                        const AppBadge(
                          label: 'مسدد بالكامل',
                          icon: Icons.check_circle_rounded,
                          size: AppBadgeSize.sm,
                          variant: AppBadgeVariant.success,
                        )
                      else
                        const AppBadge(
                          label: 'لم يحصل',
                          icon: Icons.hourglass_empty_rounded,
                          size: AppBadgeSize.sm,
                          variant: AppBadgeVariant.warning,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // ─── 3. الإجراءات السريرية وخيارات الإلغاء ───
          _buildSectionHeader(
            context,
            'الإجراءات السريرية والتحكم',
            Icons.bolt_rounded,
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // 1. إجراءات التقدم السريري
              if (status == 'confirmed')
                AppButton(
                  label: 'نقل للطبيب',
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () => _openConfirmation(context, ref, 'pending'),
                ),
              if (status == 'pending' && isDoctor)
                AppButton(
                  label: 'بدء الفحص',
                  icon: Icons.medical_services_outlined,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () {
                    AppNavigation.toExamination(
                      context,
                      clinicId: clinicId,
                      appointmentId: appointment.id,
                      patientId: appointment.patientId,
                      patientName: appointment.patient.fullName,
                    );
                  },
                ),
              if (status == 'pending' && !isDoctor)
                AppButton(
                  label: 'إنهاء الكشف',
                  icon: Icons.check_rounded,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () =>
                      _openConfirmation(context, ref, 'completed'),
                ),
              if (isCompleted && isDoctor)
                AppButton(
                  label: 'عرض التقرير',
                  icon: Icons.edit_note_rounded,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () {
                    AppNavigation.toExamination(
                      context,
                      clinicId: clinicId,
                      appointmentId: appointment.id,
                      patientId: appointment.patientId,
                      patientName: appointment.patient.fullName,
                    );
                  },
                ),
              if (isCompleted)
                AppButton(
                  label: 'ملاحظات الزيارة',
                  icon: Icons.note_alt_rounded,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
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

              // 2. إدارة وتعديل
              AppButton(
                label: 'الملف الطبي',
                icon: Icons.person_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                expand: false,
                onPressed: () {
                  AppNavigation.showPatientDetails(
                    context,
                    clinicId: clinicId,
                    patient: appointment.toPatientModel(),
                  );
                },
              ),
              AppButton(
                label: 'تعديل',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
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

              // 3. خيارات الإلغاء الثنائية (من العيادة أو اعتذار المريض)
              if (canCancel) ...[
                AppButton(
                  label: 'إلغاء من العيادة',
                  icon: Icons.domain_disabled_rounded,
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () =>
                      _openConfirmation(context, ref, 'cancelled_by_clinic'),
                ),
                AppButton(
                  label: 'اعتذار من المريض',
                  icon: Icons.person_off_outlined,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () =>
                      _openConfirmation(context, ref, 'cancelled_by_patient'),
                ),
              ],

              // 4. إعادة للانتظار للحالات الملغاة أو المنتهية
              if (isCancelled || isCompleted)
                AppButton(
                  label: 'إعادة للانتظار',
                  icon: Icons.replay_rounded,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () =>
                      _openConfirmation(context, ref, 'confirmed'),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary(context)),
        const SizedBox(width: 6),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: isMono
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary(context),
                  )
                : GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary(context),
                  ),
          ),
        ),
      ],
    );
  }
}
