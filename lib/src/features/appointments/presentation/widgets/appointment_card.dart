import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/primitives/app_badge.dart';
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
import 'admission_confirmation_sheet.dart';

/// Compact appointment card used in mobile and desktop lists.
class AppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final String clinicId;
  final bool isSelected;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.clinicId,
    this.isSelected = false,
    this.onTap,
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
      final color = status == 'pending'
          ? AppColors.info
          : status == 'completed'
              ? AppColors.success
              : status == 'confirmed'
                  ? AppColors.warning
                  : AppColors.textSecondary(context);
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
          Navigator.pop(context);
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

    return AppCard(
      isSelected: isSelected,
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
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Opacity(
        opacity: (isCompleted || isCancelled) ? 0.72 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TimeChip(time: formattedTime, highlight: isPending),
                if (appointment.appointmentTypeName != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  _MetaChip(label: appointment.appointmentTypeName!),
                ],
                const Spacer(),
                AppBadge(
                    label: label,
                    icon: icon,
                    variant: _badgeVariant(status)),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                AppAvatar(
                  name: appointment.patient.fullName,
                  size: AppAvatarSize.md,
                  color: isPending
                      ? AppColors.info
                      : isCompleted
                          ? AppColors.success
                          : AppColors.primary,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patient.fullName,
                        style: AppTypography.headingSm(
                            AppColors.textPrimary(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
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
                                      color: AppColors.success),
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
                            )
                          else
                            Text(
                              'بدون هاتف',
                              style: AppTypography.caption(
                                  AppColors.textMuted(context)),
                            ),
                          if (appointment.doctorName != null &&
                              appointment.doctorName!.isNotEmpty) ...[
                            const SizedBox(width: AppSpace.sm),
                            _MetaChip(label: 'د. ${appointment.doctorName}'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (appointment.totalPaid > 0)
                  AppBadge(
                    label: '${appointment.totalPaid.toStringAsFixed(0)} ج.م',
                    variant: AppBadgeVariant.success,
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            _ActionRow(
              status: status,
              isDoctor: isDoctor,
              onEdit: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => EditAppointmentDialog(
                    clinicId: clinicId,
                    appointment: appointment,
                  ),
                );
              },
              onAdmit: () => _openAdmission(context, ref, 'pending'),
              onComplete: () => _openAdmission(context, ref, 'completed'),
              onExamine: () {
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
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final bool highlight;
  const _TimeChip({required this.time, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.info : AppColors.primary;
    final bg =
        color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(AppRadii.radiusSm),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Text(
        label,
        style: AppTypography.caption(AppColors.textSecondary(context)),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String status;
  final bool isDoctor;
  final VoidCallback onEdit;
  final VoidCallback onAdmit;
  final VoidCallback onComplete;
  final VoidCallback onExamine;

  const _ActionRow({
    required this.status,
    required this.isDoctor,
    required this.onEdit,
    required this.onAdmit,
    required this.onComplete,
    required this.onExamine,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'confirmed') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _GhostButton(
              label: 'تعديل', icon: Icons.edit_outlined, onPressed: onEdit),
          const SizedBox(width: AppSpace.sm),
          _SolidButton(
            label: 'دخول للطبيب',
            icon: Icons.arrow_forward_rounded,
            color: AppColors.info,
            onPressed: onAdmit,
          ),
        ],
      );
    }
    if (status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _SolidButton(
            label: isDoctor ? 'بدء الفحص' : 'إنهاء الكشف',
            icon: isDoctor
                ? Icons.medical_services_outlined
                : Icons.check_rounded,
            color: isDoctor ? AppColors.info : AppColors.success,
            onPressed: isDoctor ? onExamine : onComplete,
          ),
        ],
      );
    }
    if (status == 'completed' && isDoctor) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _GhostButton(
              label: 'عرض التقرير',
              icon: Icons.edit_note_rounded,
              onPressed: onExamine),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _SolidButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _SolidButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.radiusSm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.onPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _GhostButton(
      {required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.radiusSm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.radiusSm),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textPrimary(context)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}