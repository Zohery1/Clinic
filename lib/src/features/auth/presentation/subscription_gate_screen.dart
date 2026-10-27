import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';
import 'top_up_subscription_screen.dart';

class SubscriptionGateScreen extends ConsumerStatefulWidget {
  final String clinicName;
  final DateTime? subscriptionEndDate;
  final bool isActive;
  final VoidCallback onRefresh;

  const SubscriptionGateScreen({
    super.key,
    required this.clinicName,
    this.subscriptionEndDate,
    required this.isActive,
    required this.onRefresh,
  });

  @override
  ConsumerState<SubscriptionGateScreen> createState() => _SubscriptionGateScreenState();
}

class _SubscriptionGateScreenState extends ConsumerState<SubscriptionGateScreen> {
  bool _isChecking = false;

  Future<void> _checkAgain() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onRefresh();
    if (mounted) setState(() => _isChecking = false);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'غير محدد';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final msg = !widget.isActive ? 'تم إيقاف حساب العيادة مؤقتًا بواسطة الإدارة.' : 'انتهت مدة الاشتراك. يرجى التجديد للمتابعة.';

    return AppStatusPage(
      icon: Icons.lock_outline_rounded,
      iconColor: AppColors.warning,
      title: 'الاشتراك غير مفعل',
      message: msg,
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: AppRadii.brMd,
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.clinicName, textAlign: TextAlign.center, style: AppTypography.headingSm(AppColors.textPrimary(context))),
                const SizedBox(height: AppSpace.xs),
                const ClinicSwitcherButton(),
                const SizedBox(height: AppSpace.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warningSubtle,
                    borderRadius: AppRadii.brSm,
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_busy_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: AppSpace.xs),
                      Text('تاريخ انتهاء الاشتراك: ', style: AppTypography.bodySm(AppColors.warning)),
                      Text(_formatDate(widget.subscriptionEndDate), style: AppTypography.numericMd(AppColors.warning)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      primaryAction: StatusAction(
        label: 'تجديد الاشتراك',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TopUpSubscriptionScreen(
                clinicName: widget.clinicName,
                inviteCode: '',
                clinicId: '',
                onRefresh: widget.onRefresh,
              ),
            ),
          );
        },
        icon: Icons.credit_card_rounded,
      ),
      secondaryAction: StatusAction(
        label: 'تحقُّق من الحالة',
        onPressed: _isChecking ? null : _checkAgain,
        loading: _isChecking,
        variant: AppButtonVariant.secondary,
        icon: Icons.refresh_rounded,
      ),
    );
  }
}
