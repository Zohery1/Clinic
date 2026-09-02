import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/primitives/app_input.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import 'login_screen.dart';

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
        _successMessage = 'تم إرسال رمز التحقق إلى بريدك الإلكتروني: $email';
      });
    } catch (e) {
      String errStr = e.toString().replaceAll('Exception:', '').trim();
      if (errStr.contains('User not found') || errStr.contains('user_not_found')) {
        errStr = 'البريد الإلكتروني غير مسجل بالمنظومة.';
      }
      setState(() => _errorMessage = 'فشل إرسال رمز التحقق: $errStr');
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
        _successMessage = 'تم التحقق من رمز OTP بنجاح! أدخل كلمة المرور الجديدة الآن.';
      });
    } catch (e) {
      setState(() => _errorMessage = 'رمز التحقق (OTP) غير صحيح أو انتهت صلاحيته.');
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
      setState(() => _successMessage = 'تم إعادة إرسال رمز التحقق إلى بريدك: $email');
    } catch (e) {
      setState(() => _errorMessage = 'فشل إعادة إرسال الرمز. حاول مرة أخرى بعد قليل.');
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم تغيير كلمة المرور بنجاح! يرجى تسجيل الدخول بكلمة المرور الجديدة.', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ));
        _navigateToLogin();
      }
    } catch (e) {
      setState(() => _errorMessage = 'فشل تحديث كلمة المرور: ${e.toString().replaceAll('Exception:', '')}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _banner(BuildContext context, IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadii.brSm,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(text, style: AppTypography.bodySm(color).copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String titleText = widget.isUpdateMode ? 'تعيين كلمة مرور جديدة' : 'استعادة كلمة المرور';
    String subtitleText;
    IconData headerIcon;

    if (_step == 0) {
      subtitleText = 'أدخل بريدك الإلكتروني المكتوب في المنظومة وسنرسل لك رمز تحقق.';
      headerIcon = Icons.lock_reset_rounded;
    } else if (_step == 1) {
      subtitleText = 'يرجى كتابة رمز التحقق المكون من 6 أرقام الذي وصلك على البريد الإلكتروني.';
      headerIcon = Icons.mark_email_read_rounded;
    } else {
      subtitleText = 'يرجى كتابة كلمة مرور قوية تحتوي على أرقام وحروف ولا تقل عن 8 أحرف.';
      headerIcon = Icons.lock_open_rounded;
    }

    final heroTitle = widget.isUpdateMode ? 'كلمة مرور جديدة' : 'استعادة كلمة المرور';
    final heroSubtitle = widget.isUpdateMode
        ? 'اختر كلمة مرور قوية لحماية حسابك وعيادتك.'
        : 'أعد تعيين كلمة المرور بسهولة عبر رمز تحقق يُرسل إلى بريدك الإلكتروني.';

    return AuthShell(
      heroTitle: heroTitle,
      heroSubtitle: heroSubtitle,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(headerIcon, size: 32, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: AppTypography.headingLg(AppColors.textPrimary(context)),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd(AppColors.textSecondary(context)),
              ),
              const SizedBox(height: AppSpace.xxl),
              if (_successMessage != null) ...[
                _banner(context, Icons.check_circle_outline_rounded, AppColors.success, _successMessage!),
                const SizedBox(height: AppSpace.lg),
              ],
              if (_errorMessage != null) ...[
                _banner(context, Icons.error_outline_rounded, AppColors.danger, _errorMessage!),
                const SizedBox(height: AppSpace.lg),
              ],
              if (_step == 0) ...[
                AppTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  hint: 'example@clinic.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                      return 'صيغة البريد الإلكتروني غير صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(label: 'إرسال رمز التحقق', onPressed: _isLoading ? null : _sendResetOtp, loading: _isLoading),
              ] else if (_step == 1) ...[
                AppTextField(
                  controller: _otpController,
                  label: 'رمز التحقق (OTP)',
                  hint: '123456',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'يرجى إدخال رمز التحقق';
                    if (v.trim().length < 6) return 'يجب أن يتكون الرمز من 6 أرقام';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(label: 'تأكيد الرمز والمتابعة', onPressed: _isLoading ? null : _verifyOtp, loading: _isLoading),
                const SizedBox(height: AppSpace.md),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text('لم يصلك الرمز؟ إعادة الإرسال', style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
              ] else ...[
                AppTextField(
                  controller: _newPasswordController,
                  label: 'كلمة المرور الجديدة',
                  obscure: !_isPasswordVisible,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                    if (v.length < 8) return 'يجب ألا تقل كلمة المرور عن 8 أحرف';
                    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(v)) return 'كلمة المرور ضعيفة (يجب أن تحتوي على حروف وأرقام)';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'تأكيد كلمة المرور الجديدة',
                  obscure: !_isConfirmVisible,
                  prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                    if (v != _newPasswordController.text) return 'تأكيد كلمة المرور غير مطابق';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(label: 'تحديث كلمة المرور', onPressed: _isLoading ? null : _updatePassword, loading: _isLoading),
              ],
              const SizedBox(height: AppSpace.lg),
              Center(
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text('العودة لشاشة تسجيل الدخول', style: AppTypography.bodySm(AppColors.textSecondary(context)).copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
