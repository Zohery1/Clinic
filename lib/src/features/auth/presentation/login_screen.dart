import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/routing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/primitives/app_input.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/utils/invite_utils.dart';
import 'login_controller.dart';

/// Clinical Utility Login Screen. Clean, direct, simple Arabic copy.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      await ref.read(loginControllerProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );

      final loginState = ref.read(loginControllerProvider);
      if (mounted) {
        if (loginState.isEmailVerificationRequired) {
          AppNavigation.toVerifyOtp(
            context,
            email: _emailController.text.trim(),
          );
        } else if (loginState.isSuccess) {
          AppNavigation.toDashboard(context, clearStack: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 3),
              content: Text(
                next.errorMessage!,
                textAlign: TextAlign.start,
              ),
              backgroundColor: AppColors.danger,
            ),
          );
      }
    });

    return AuthShell(
      heroTitle: 'عيادتي',
      heroSubtitle: 'منظومة إدارة العيادات والمواعيد الطبية.',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'بوابة الدخول',
                style: AppTypography.overline(
                  AppColors.textMuted(context),
                ).copyWith(letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                'تسجيل الدخول',
                style: AppTypography.headingLg(
                  AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'أدخل البريد الإلكتروني وكلمة المرور للمتابعة',
                style: AppTypography.bodySm(AppColors.textSecondary(context)),
              ),
              const SizedBox(height: AppSpace.xl),

              // Email
              AppTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                hint: 'name@clinic.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'صيغة البريد غير صحيحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.md),

              // Password
              AppTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                hint: '••••••••',
                obscure: !_isPasswordVisible,
                onEditingComplete: _submit,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'كلمة المرور مطلوبة';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.xs),

              // Forgot password link
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    AppNavigation.toResetPassword(context, isUpdateMode: false);
                  },
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: AppTypography.caption(AppColors.accent(context)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),

              // Submit button
              AppButton(
                label: 'تسجيل الدخول',
                icon: Icons.login_rounded,
                loading: loginState.isLoading,
                size: AppButtonSize.md,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpace.lg),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب؟',
                    style: AppTypography.bodySm(AppColors.textSecondary(context)),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  TextButton(
                    onPressed: () {
                      final inviteCode = InviteUtils.extractInviteCode();
                      AppNavigation.toRegister(
                        context,
                        inviteCode: inviteCode,
                        replace: true,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'إنشاء حساب جديد',
                      style: AppTypography.bodySm(AppColors.accent(context)).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
