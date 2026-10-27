import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/shadows.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../../../../main.dart';
import '../data/auth_repository.dart';
import 'login_controller.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});
  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _countdownSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _countdownSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredOtp => _controllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      ClinicToast.showError(context, 'يرجى إدخال رمز التحقق المكون من 6 أرقام كاملة');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyEmailOtp(email: widget.email, token: otp);
      await ref.read(loginControllerProvider.notifier).tryAutoLogin();
      if (mounted) {
        ClinicToast.showSuccess(context, 'تم التحقق من الرمز بنجاح!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ClinicToast.showError(context, 'فشل التحقق: رمز غير صحيح');
      }
    }
  }

  Future<void> _resendCode() async {
    if (_countdownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resendEmailOtp(widget.email);
      if (mounted) {
        ClinicToast.showSuccess(context, 'تم إعادة إرسال رمز التحقق إلى بريدك الإلكتروني');
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) ClinicToast.showError(context, 'فشل إرسال الرمز. حاول مرة أخرى بعد قليل.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      heroTitle: 'تحقق من بريدك',
      heroSubtitle: 'أدخل الرمز المرسل لبريدك الإلكتروني لتفعيل حسابك وبدء استخدام عيادتي.',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadii.brMd,
                  boxShadow: AppShadows.sm(context),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'أدخل رمز التحقق (OTP)',
              textAlign: TextAlign.center,
              style: AppTypography.headingLg(AppColors.textPrimary(context)),
            ),
            const SizedBox(height: AppSpace.sm),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTypography.bodyMd(AppColors.textSecondary(context)),
                children: [
                  const TextSpan(text: 'تم إرسال رمز تأكيد مكون من 6 أرقام إلى البريد الإلكتروني:\n'),
                  TextSpan(
                    text: widget.email,
                    style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTypography.numericMd(AppColors.primary),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: AppColors.subtle(context),
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.brSm,
                          borderSide: BorderSide(color: AppColors.borderSubtle(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadii.brSm,
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (v) => _onOtpChanged(index, v),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpace.xxl),
            AppButton(
              label: 'تأكيد الرمز والمتابعة',
              icon: Icons.bolt_rounded,
              onPressed: _isLoading ? null : _verifyOtp,
              loading: _isLoading,
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('لم يصلك الرمز؟ ', style: AppTypography.bodySm(AppColors.textSecondary(context))),
                if (_countdownSeconds > 0)
                  Text(' إعادة الإرسال بعد ($_countdownSecondsث)', style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w700))
                else
                  TextButton(
                    onPressed: _isResending ? null : _resendCode,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text(
                      _isResending ? 'جاري الإرسال...' : 'إعادة إرسال الرمز الآن',
                      style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
