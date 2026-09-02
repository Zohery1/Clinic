import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/primitives/app_input.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/utils/invite_utils.dart';
import '../../../../main.dart';
import 'login_controller.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'verify_otp_screen.dart';

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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(email: _emailController.text.trim()),
            ),
          );
        } else if (loginState.isSuccess) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              next.errorMessage!,
              style: TextStyle(color: AppColors.onPrimary),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final loginState = ref.watch(loginControllerProvider);

    return AuthShell(
      heroTitle: 'أهلاً بك في عيادتك',
      heroSubtitle: 'منصة إدارة العيادات الذكية — كل ما تحتاجه لإدارة مواعيدك ومرضاك وفواتيرك في مكان واحد.',
      footer: const _LoginFooter(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: AppTypography.displayMd(AppColors.textPrimary(context)),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'سجّل دخولك لإدارة عيادتك بذكاء',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(AppColors.textSecondary(context)),
              ),
              const SizedBox(height: AppSpace.xxl),
              AppTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                hint: 'example@clinic.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.lg),
              AppTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                obscure: !_isPasswordVisible,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                onEditingComplete: () => _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
                  if (value.length < 6) return 'يجب ألا تقل كلمة المرور عن 6 أحرف';
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordScreen(isUpdateMode: false),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: AppTypography.bodySm(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              AppButton(
                label: 'تسجيل الدخول',
                onPressed: loginState.isLoading ? null : _submit,
                loading: loginState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.xs,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: AppTypography.bodySm(AppColors.textSecondary(context)),
        ),
        TextButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            final inviteCode = InviteUtils.extractInviteCode();
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => RegisterScreen(initialInviteCode: inviteCode)),
            );
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text(
            'أنشئ حساباً الآن',
            style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
