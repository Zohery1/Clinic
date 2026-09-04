import 'package:flutter/material.dart';
import '../../domain/appointment_model.dart';

/// نافذة تأكيد سفلية قبل تغيير حالة المريض
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
        return 'إدخال المريض للطبيب؟';
      case 'completed':
        return 'إنهاء الكشف؟';
      case 'cancelled':
      case 'cancelled_by_clinic':
        return 'إلغاء من قبل العيادة؟';
      case 'cancelled_by_patient':
        return 'إلغاء / عدم حضور المريض؟';
      default:
        return 'تأكيد الإجراء';
    }
  }

  String get _actionDescription {
    switch (targetStatus) {
      case 'pending':
        return 'سيتم نقل المريض من طابور الانتظار إلى عيادة الطبيب.';
      case 'completed':
        return 'سيتم تسجيل الكشف كمكتمل. يمكن التراجع لمدة 5 ثوانٍ.';
      case 'cancelled':
      case 'cancelled_by_clinic':
        return 'سيتم إلغاء الموعد من طرف الطبيب/العيادة نهائياً.';
      case 'cancelled_by_patient':
        return 'سيتم تسجيل الموعد كملغي بسبب عدم حضور المريض أو اعتذاره.';
      default:
        return 'هل أنت متأكد من هذا الإجراء؟';
    }
  }

  String get _confirmLabel {
    switch (targetStatus) {
      case 'pending':
        return 'إدخال الآن';
      case 'completed':
        return 'إنهاء الكشف';
      case 'cancelled':
      case 'cancelled_by_clinic':
        return 'إلغاء الموعد';
      case 'cancelled_by_patient':
        return 'تأكيد عدم الحضور';
      default:
        return 'تأكيد';
    }
  }

  bool get _isDangerous => targetStatus.startsWith('cancelled');

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
            // ─── Handle ───
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
            // ─── أيقونة + عنوان ───
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDangerous
                        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isDangerous ? Icons.cancel_outlined : Icons.arrow_forward_rounded,
                    color: _isDangerous
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _actionTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المريض: ${appointment.patient.fullName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // ─── وصف الإجراء ───
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDangerous
                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.05)
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                // removed border
              ),
              child: Text(
                _actionDescription,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ─── أزرار ───
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
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
                      backgroundColor: _isDangerous
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
