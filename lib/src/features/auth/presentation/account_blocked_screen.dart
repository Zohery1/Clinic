import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/routing/routing.dart';

class AccountBlockedScreen extends ConsumerStatefulWidget {
  final String userName;
  final String clinicName;
  final VoidCallback onRefresh;

  const AccountBlockedScreen({
    super.key,
    required this.userName,
    required this.clinicName,
    required this.onRefresh,
  });

  @override
  ConsumerState<AccountBlockedScreen> createState() => _AccountBlockedScreenState();
}

class _AccountBlockedScreenState extends ConsumerState<AccountBlockedScreen> {
  bool _isChecking = false;

  Future<void> _checkAgain() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onRefresh();
    if (mounted) setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    final helloLine = widget.userName.isNotEmpty ? 'أهلاً ${widget.userName}' : 'مرحباً بك';

    return AppStatusPage(
      icon: Icons.block_rounded,
      iconColor: AppColors.danger,
      title: 'تم إيقاف الحساب',
      message: 'تم إيقاف صلاحية الدخول لهذه العيادة (${widget.clinicName}). يرجى مراجعة إدارة العيادة لإعادة التفعيل.',
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(helloLine, textAlign: TextAlign.center, style: AppTypography.headingSm(AppColors.primary)),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.dangerSubtle,
              borderRadius: AppRadii.brMd,
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.danger),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'تم إيقاف صلاحية الدخول لهذا الحساب من قبل إدارة العيادة.',
                    style: AppTypography.bodyMd(AppColors.textPrimary(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      primaryAction: StatusAction(
        label: 'التحقق من التفعيل',
        onPressed: _isChecking ? null : _checkAgain,
        loading: _isChecking,
        icon: Icons.refresh_rounded,
      ),
      secondaryAction: StatusAction(
        label: 'الانضمام لعيادة أخرى',
        onPressed: () {
          AppNavigation.toJoinClinic(
            context,
            userName: widget.userName,
            onRefresh: widget.onRefresh,
          );
        },
        variant: AppButtonVariant.secondary,
        icon: Icons.add_business_rounded,
      ),
    );
  }
}
