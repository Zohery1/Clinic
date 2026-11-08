import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/primitives/app_input.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/routing/routing.dart';

/// Clinical Utility Reset Password Screen.
class ResetPasswordScreen extends StatefulWidget {
  final bool isUpdateMode;
  const ResetPasswordScreen({super.key, this.isUpdateMode = false});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isUpdateMode) {
      _step = 2;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _navigateToLogin() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (mounted) {
      AppNavigation.toLogin(context, clearStack: true);
    }
  }

  Future<void> _sendResetOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final email = _emailController.text.trim();
      await Supabase.instance.client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      setState(() {
        _step = 1;
        _successMessage = 'تم إرسال رمز التحقق إلى بريدك الإلكتروني بنجاح.';
      });
    } catch (e) {
      setState(() => _errorMessage = 'تعذر إرسال رمز التحقق، يرجى التأكد من صحة البريد الإلكتروني.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final email = _emailController.text.trim();
      final token = _otpController.text.trim();
      try {
        await Supabase.instance.client.auth.verifyOTP(email: email, token: token, type: OtpType.email);
      } catch (_) {
        try {
          await Supabase.instance.client.auth.verifyOTP(email: email, token: token, type: OtpType.recovery);
        } catch (_) {
          await Supabase.instance.client.auth.verifyOTP(email: email, token: token, type: OtpType.magiclink);
        }
      }
      setState(() {
        _step = 2;
        _successMessage = 'تم التحقق من الرمز بنجاح. أدخل كلمة المرور الجديدة.';
      });
    } catch (e) {
      setState(() => _errorMessage = 'رمز التحقق غير صحيح أو انتهت صلاحيته.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      _otpController.clear();
      setState(() => _successMessage = 'تم إعادة إرسال رمز التحقق.');
    } catch (e) {
      setState(() => _errorMessage = 'تعذر إعادة إرسال الرمز، يرجى المحاولة لاحقاً.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final newPass = _newPasswordController.text;
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPass));
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعيين كلمة المرور الجديدة بنجاح.'),
            backgroundColor: AppColors.success,
          ),
        );
        _navigateToLogin();
      }
    } catch (e) {
      setState(() => _errorMessage = 'تعذر تحديث كلمة المرور، يرجى إعادة المحاولة.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = widget.isUpdateMode ? 'تغيير كلمة المرور' : 'استعادة كلمة المرور';

    return AuthShell(
      heroTitle: 'عيادتي',
      heroSubtitle: 'تعيين كلمة مرور جديدة لحسابك الطبي.',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titleText,
                style: AppTypography.headingMd(AppColors.textPrimary(context)),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                _step == 0
                    ? 'أدخل بريدك الإلكتروني لاستلام رمز التحقق'
                    : _step == 1
                        ? 'أدخل رمز التحقق المرسل لبريدك الإلكتروني'
                        : 'اكتب كلمة المرور الجديدة',
                style: AppTypography.bodySm(AppColors.textSecondary(context)),
              ),
              const SizedBox(height: AppSpace.lg),

              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.successSubtle,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.successBorder),
                  ),
                  child: Text(
                    _successMessage!,
                    style: AppTypography.bodySm(AppColors.success),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSubtle,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySm(AppColors.danger),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],

              if (_step == 0) ...[
                AppTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  hint: 'name@clinic.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني المسجل';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: 'إرسال رمز التحقق',
                  icon: Icons.send_rounded,
                  onPressed: _isLoading ? null : _sendResetOtp,
                  loading: _isLoading,
                  size: AppButtonSize.md,
                ),
              ] else if (_step == 1) ...[
                AppTextField(
                  controller: _otpController,
                  label: 'رمز التحقق (OTP)',
                  hint: '123456',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin_outlined, size: 18),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'أدخل رمز التحقق (OTP)';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: 'تأكيد الرمز والمتابعة',
                  icon: Icons.check_rounded,
                  onPressed: _isLoading ? null : _verifyOtp,
                  loading: _isLoading,
                  size: AppButtonSize.md,
                ),
                const SizedBox(height: AppSpace.xs),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text('إعادة إرسال الرمز', style: AppTypography.caption(AppColors.primary)),
                  ),
                ),
              ] else ...[
                AppTextField(
                  controller: _newPasswordController,
                  label: 'كلمة المرور الجديدة',
                  obscure: !_isPasswordVisible,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'كلمة المرور يجب ألا تقل عن 6 خانات';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'تأكيد كلمة المرور',
                  obscure: !_isConfirmVisible,
                  prefixIcon: const Icon(Icons.lock_reset_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                  ),
                  validator: (v) {
                    if (v != _newPasswordController.text) return 'كلمتا المرور غير متطابقتين';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: 'تعيين كلمة المرور الجديدة',
                  icon: Icons.check_circle_rounded,
                  onPressed: _isLoading ? null : _updatePassword,
                  loading: _isLoading,
                  size: AppButtonSize.md,
                ),
              ],

              const SizedBox(height: AppSpace.md),
              Center(
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'العودة لتسجيل الدخول',
                    style: AppTypography.bodySm(AppColors.textSecondary(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
