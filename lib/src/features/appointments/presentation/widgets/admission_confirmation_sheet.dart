import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/tokens/colors.dart';
import '../../domain/appointment_model.dart';

/// نافذة تأكيد سفلية قبل تغيير حالة المريض (Admission & Status Confirmation Sheet).
/// تدعم كافة التحولات السريرية (دخول الطبيب، إتمام الكشف، الإلغاء من العيادة، اعتذار المريض، أو إعادة للانتظار).
class AdmissionConfirmationSheet extends StatelessWidget {
  final AppointmentModel appointment;
  final String targetStatus;
  final VoidCallback onConfirm;

  const AdmissionConfirmationSheet({
    super.key,
    required this.appointment,
    required this.targetStatus,
    required this.onConfirm,
  });

  String get _actionTitle {
    switch (targetStatus) {
      case 'pending':
        return 'دخول المريض لغرفة الكشف؟';
      case 'completed':
        return 'إنهاء جلسة الكشف؟';
      case 'cancelled':
      case 'cancelled_by_clinic':
        return 'إلغاء الموعد؟';
      case 'cancelled_by_patient':
        return 'تسجيل اعتذار المريض؟';
      case 'confirmed':
        return 'إعادة المريض للانتظار؟';
      default:
        return 'تأكيد الإجراء';
    }
  }

  String get _actionDescription {
    switch (targetStatus) {
      case 'pending':
        return 'سينتقل المريض إلى حالة "قيد الكشف" في غرفة الطبيب.';
      case 'completed':
        return 'سيتم تسجيل الكشف كمكتمل ونقله للأرشيف الطبي للعيادة.';
      case 'cancelled':
      case 'cancelled_by_clinic':
        return 'سيتم إلغاء الموعد وإزالته من طابور اليوم.';
      case 'cancelled_by_patient':
        return 'سيتم تسجيل اعتذار المريض عن عدم الحضور لهذا الموعد.';
      case 'confirmed':
        return 'سيتم إعادة المريض لطابور الانتظار بالعيادة.';
      default:
        return 'هل تريد تنفيذ هذا الإجراء؟';
    }
  }

  String get _confirmLabel {
    switch (targetStatus) {
      case 'pending':
        return 'بدء الكشف';
      case 'completed':
        return 'إنهاء الكشف';
      case 'cancelled':
      case 'cancelled_by_clinic':
        return 'تأكيد الإلغاء';
      case 'cancelled_by_patient':
        return 'تسجيل الاعتذار';
      case 'confirmed':
        return 'إعادة للانتظار';
      default:
        return 'تأكيد';
    }
  }

  bool get _isDangerous => targetStatus.startsWith('cancelled');

  IconData get _actionIcon {
    switch (targetStatus) {
      case 'pending':
        return Icons.person_search_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'cancelled_by_clinic':
      case 'cancelled':
        return Icons.domain_disabled_rounded;
      case 'cancelled_by_patient':
        return Icons.person_off_outlined;
      case 'confirmed':
        return Icons.replay_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _isDangerous
        ? (targetStatus == 'cancelled_by_patient'
            ? AppColors.warning
            : AppColors.danger)
        : AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // أيقونة + عنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _actionIcon,
                    color: actionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _actionTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المريض: ${appointment.patient.fullName}',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // وصف الإجراء
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDangerous
                    ? (targetStatus == 'cancelled_by_patient'
                        ? AppColors.warningSubtle
                        : AppColors.dangerSubtle)
                    : AppColors.subtle(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _actionDescription,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // أزرار الإجراء
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: AppColors.textSecondary(context),
                    ),
                    child: Text(
                      'تراجع',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _confirmLabel,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
