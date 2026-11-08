import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/layout/auth_shell.dart';
import '../../../core/ui/primitives/app_button.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/ui/tokens/typography.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../../../core/routing/routing.dart';
import '../data/auth_repository.dart';
import 'login_controller.dart';

/// Clinical Utility OTP Verification Screen.
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
      ClinicToast.showError(context, 'أدخل رمز التحقق المكون من 6 أرقام');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyEmailOtp(email: widget.email, token: otp);
      await ref.read(loginControllerProvider.notifier).tryAutoLogin();
      if (mounted) {
        ClinicToast.showSuccess(context, 'تم تفعيل الحساب بنجاح. جاري فتح لوحة التحكم...');
        AppNavigation.toDashboard(context, clearStack: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ClinicToast.showError(context, 'رمز التحقق غير صحيح أو انتهت صلاحيته');
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
        ClinicToast.showSuccess(context, 'تم إرسال رمز تحقق جديد إلى بريدك');
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) ClinicToast.showError(context, 'تعذر إعادة إرسال الرمز، يرجى المحاولة لاحقاً');
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
      heroTitle: 'عيادتي',
      heroSubtitle: 'تأكيد البريد الإلكتروني وتفعيل مساحة عمل العيادة.',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تأكيد الحساب',
              style: AppTypography.headingMd(AppColors.textPrimary(context)),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'أدخل رمز التحقق المرسل إلى: ${widget.email}',
              style: AppTypography.bodySm(AppColors.textSecondary(context)),
            ),
            const SizedBox(height: AppSpace.xl),

            // OTP Fields
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 50,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTypography.numericMd(AppColors.textPrimary(context)),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: AppColors.subtle(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          borderSide: BorderSide(color: AppColors.borderSubtle(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (v) => _onOtpChanged(index, v),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            AppButton(
              label: 'تأكيد الرمز وتفعيل الحساب',
              icon: Icons.check_rounded,
              onPressed: _isLoading ? null : _verifyOtp,
              loading: _isLoading,
              size: AppButtonSize.md,
            ),
            const SizedBox(height: AppSpace.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('لم تستلم رمز التحقق؟ ', style: AppTypography.bodySm(AppColors.textSecondary(context))),
                if (_countdownSeconds > 0)
                  Text('($_countdownSeconds ثانية)', style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w700))
                else
                  TextButton(
                    onPressed: _isResending ? null : _resendCode,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(
                      _isResending ? 'جاري الإرسال...' : 'إعادة الإرسال',
                      style: AppTypography.bodySm(AppColors.primary).copyWith(fontWeight: FontWeight.w700),
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
