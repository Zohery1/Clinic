import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/ui/tokens/spacing.dart';
import 'join_clinic_screen.dart';

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
    final helloLine = widget.userName.isNotEmpty
        ? 'أهلًا بك يا ${widget.userName}'
        : 'عزيزي المساعد / السكرتير';

    final msg = 'يرجى التواصل مع مدير العيادة (${widget.clinicName}) لإعادة التفعيل.';

    return AppStatusPage(
      icon: Icons.block_rounded,
      iconColor: AppColors.danger,
      title: 'تم تعطيل حسابك من قبل إدارة العيادة',
      message: msg,
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
                    'قام الطبيب المسؤول في عيادة «${widget.clinicName}» بإيقاف صلاحيات دخول هذا الحساب مؤقتًا. يرجى مراجعة الطبيب لإعادة تفعيل حسابك.',
                    style: AppTypography.bodyMd(AppColors.textPrimary(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      primaryAction: StatusAction(
        label: 'إعادة المحاولة والتحقُّق',
        onPressed: _isChecking ? null : _checkAgain,
        loading: _isChecking,
        icon: Icons.refresh_rounded,
      ),
      secondaryAction: StatusAction(
        label: 'الخروج والربط بعيادة جديدة',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JoinClinicScreen(
                userName: widget.userName,
                onRefresh: widget.onRefresh,
              ),
            ),
          );
        },
        variant: AppButtonVariant.secondary,
        icon: Icons.add_business_rounded,
      ),
    );
  }
}
