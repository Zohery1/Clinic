import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/primitives/app_input.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import '../data/auth_repository.dart';
import '../../../core/routing/routing.dart';
import 'login_controller.dart';

class JoinClinicScreen extends ConsumerStatefulWidget {
  final String userName;
  final VoidCallback onRefresh;

  const JoinClinicScreen({
    super.key,
    required this.userName,
    required this.onRefresh,
  });

  @override
  ConsumerState<JoinClinicScreen> createState() => _JoinClinicScreenState();
}

class _JoinClinicScreenState extends ConsumerState<JoinClinicScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) {
      AppNavigation.toLogin(context, clearStack: true);
    }
  }

  void _joinClinic() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('أدخل كود الدعوة للمتابعة', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: AppColors.warning,
          ),
        );
      return;
    }

    setState(() => _isJoining = true);
    final res = await ref.read(authRepositoryProvider).joinClinicWithInviteCode(code);
    if (mounted) {
      setState(() => _isJoining = false);
      if (res['success'] == true) {
        final sessionUser = Supabase.instance.client.auth.currentUser;
        if (sessionUser != null) {
          final updatedProfile = await ref.read(authRepositoryProvider).getUserProfile(sessionUser.id);
          if (!mounted) return;
          ref.read(currentUserProvider.notifier).state = updatedProfile;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'تم الانضمام للعيادة بنجاح', style: Theme.of(context).textTheme.bodyMedium),
              backgroundColor: AppColors.success,
            ),
          );
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'كود الدعوة غير صالح أو منتهي الصلاحية', style: Theme.of(context).textTheme.bodyMedium),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = widget.userName.isNotEmpty ? 'أهلاً ${widget.userName}' : 'مرحباً بك';

    return AuthShell(
      heroTitle: 'الانضمام لعيادة',
      heroSubtitle: 'أدخل كود الدعوة للانضمام إلى طاقم العيادة.',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header icon
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'الانضمام لعيادة',
                textAlign: TextAlign.center,
                style: AppTypography.headingLg(AppColors.textPrimary(context)),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                greeting,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(AppColors.primary).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpace.xxl),

              // Info banner
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: AppColors.infoSubtle,
                  borderRadius: AppRadii.brMd,
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.info),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        'أدخل كود الدعوة المستلم من إدارة العيادة للانضمام إلى طاقم العمل.',
                        style: AppTypography.bodyMd(AppColors.textPrimary(context)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xxl),

              // Invite code input
              AppTextField(
                controller: _inviteCodeController,
                label: 'كود الدعوة',
                hint: 'مثال: CL-9X28',
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'كود الدعوة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.xl),

              // Join button
              AppButton(
                label: 'الانضمام للعيادة',
                icon: Icons.login_rounded,
                onPressed: _isJoining ? null : _joinClinic,
                loading: _isJoining,
                size: AppButtonSize.lg,
              ),
              const SizedBox(height: AppSpace.md),

              // Logout button
              AppButton(
                label: 'تسجيل الخروج',
                icon: Icons.logout_rounded,
                onPressed: _handleLogout,
                size: AppButtonSize.lg,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
