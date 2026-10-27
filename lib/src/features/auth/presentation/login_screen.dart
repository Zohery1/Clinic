import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/primitives/app_input.dart';
import '../../../core/utils/invite_utils.dart';
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
    final loginState = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);

    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                next.errorMessage!,
                style: TextStyle(color: theme.colorScheme.onError),
                textAlign: TextAlign.start,
              ),
              backgroundColor: theme.colorScheme.error,
            ),
          );
      }
    });

    return AuthShell(
      heroTitle: 'المنظومة السريرية الذكية',
      heroSubtitle: 'إدارة متكاملة لمواعيد المرضى، طابور كشف ذكي لحظي عبر واتساب، وسجل طبي إلكتروني موحد.',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رأس النموذج
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'سجّل دخولك للوصول إلى لوحة إدارة العيادة والمرضى',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpace.xxl),

              // حقل البريد الإلكتروني
              AppTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                hint: 'doctor@clinic.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
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

              // حقل كلمة المرور
              AppTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                hint: '••••••••',
                obscure: !_isPasswordVisible,
                onEditingComplete: _submit,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'يجب ألا تقل كلمة المرور عن 6 أحرف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.xs),

              // رابط نسيت كلمة المرور
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const ResetPasswordScreen(isUpdateMode: false),
                      ),
                    );
                  },
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: GoogleFonts.cairo(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // زر تسجيل الدخول
              AppButton(
                label: 'تسجيل الدخول',
                icon: Icons.login_rounded,
                loading: loginState.isLoading,
                size: AppButtonSize.lg,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpace.xl),

              // إنشاء حساب جديد
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب عيادة؟',
                    style: GoogleFonts.cairo(
                      color: AppColors.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  TextButton(
                    onPressed: () {
                      final inviteCode = InviteUtils.extractInviteCode();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(initialInviteCode: inviteCode),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'أنشئ حساباً الآن',
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
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
