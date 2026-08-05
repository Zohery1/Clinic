import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final bool isUpdateMode; // true if user opened link from email, false if requesting OTP/link

  const ResetPasswordScreen({
    super.key,
    this.isUpdateMode = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0; // 0: Enter Email, 1: Enter OTP, 2: Enter New Password
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
    // تسجيل الخروج لضمان عدم الدخول التلقائي مع الجلسة القديمة
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

  // الخطوة الأولى: إرسال رمز OTP المكون من 6 أرقام للبريد الإلكتروني
  Future<void> _sendResetOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      
      // إرسال رمز OTP المكون من 6 أرقام للإيميل مباشرة (بدون روابط)
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      setState(() {
        _step = 1;
        _successMessage = 'تم إرسال رمز التحقق المكون من 6 أرقام إلى بريدك الإلكتروني: $email';
      });
    } catch (e) {
      String errStr = e.toString().replaceAll('Exception:', '').trim();
      if (errStr.contains('User not found') || errStr.contains('user_not_found')) {
        errStr = 'البريد الإلكتروني غير مسجل بالمنظومة.';
      }
      setState(() {
        _errorMessage = 'فشل إرسال رمز التحقق: $errStr';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // الخطوة الثانية: التأكد من رمز الـ OTP
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
        await Supabase.instance.client.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.email,
        );
      } catch (_) {
        try {
          await Supabase.instance.client.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.recovery,
          );
        } catch (_) {
          await Supabase.instance.client.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.magiclink,
          );
        }
      }

      setState(() {
        _step = 2;
        _successMessage = 'تم التحقق من رمز OTP بنجاح! أدخل كلمة المرور الجديدة الآن.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'رمز التحقق (OTP) غير صحيح أو انتهت صلاحيته.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // الخطوة الثالثة: تحديث كلمة المرور وتسجيل الخروج للعودة لصفحة الدخول
  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final newPass = _newPasswordController.text;
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      // تسجيل الخروج فوراً للعودة لشاشة تسجيل الدخول
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'تم تغيير كلمة المرور بنجاح! يرجى تسجيل الدخول باستخدام كلمة المرور الجديدة.',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ));
        _navigateToLogin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحديث كلمة المرور: ${e.toString().replaceAll('Exception:', '')}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = 'استعادة كلمة المرور';
    String headerText = 'نسيت كلمة المرور؟';
    String subtitleText = 'أدخل بريدك الإلكتروني المكتوب في المنظومة وسنرسل لك رمز تحقق (OTP).';

    if (_step == 1) {
      titleText = 'التحقق من رمز OTP';
      headerText = 'أدخل رمز التحقق';
      subtitleText = 'يرجى كتابة رمز التحقق المكون من 6 أرقام الذي وصلك على البريد الإلكتروني.';
    } else if (_step == 2) {
      titleText = 'تعيين كلمة مرور جديدة';
      headerText = 'أدخل كلمة المرور الجديدة';
      subtitleText = 'يرجى كتابة كلمة مرور قوية تحتوي على أرقام وحروف ولا تقل عن 8 أحرف.';
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          titleText,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: _navigateToLogin,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _step == 1
                          ? Icons.mark_email_read_rounded
                          : (_step == 2 ? Icons.lock_open_rounded : Icons.lock_reset_rounded),
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    headerText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitleText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: GoogleFonts.cairo(
                                color: AppTheme.success,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.cairo(
                                color: AppTheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // الخطوة 0: إدخال الإيميل
                  if (_step == 0) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'example@clinic.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return 'صيغة البريد الإلكتروني غير صحيحة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'إرسال رمز التحقق (OTP)',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ]

                  // الخطوة 1: إدخال رمز OTP
                  else if (_step == 1) ...[
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق (OTP)',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.pin_outlined, size: 20),
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'يرجى إدخال رمز التحقق';
                        if (v.trim().length < 6) return 'يجب أن يتكون الرمز من 6 أرقام';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'تأكيد الرمز والمتابعة',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _sendResetOtp,
                      child: Text(
                        'لم يصلك الرمز؟ إعادة إرسال OTP',
                        style: GoogleFonts.cairo(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ]

                  // الخطوة 2: كلمة المرور الجديدة
                  else if (_step == 2) ...[
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الجديدة',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                        if (v.length < 8) return 'يجب ألا تقل كلمة المرور عن 8 أحرف';
                        if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(v)) {
                          return 'كلمة المرور ضعيفة (يجب أن تحتوي على حروف وأرقام)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmVisible,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور الجديدة',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                        if (v != _newPasswordController.text) {
                          return 'تأكيد كلمة المرور غير مطابق';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'تحديث كلمة المرور',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: Text(
                      'العودة لشاشة تسجيل الدخول',
                      style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
