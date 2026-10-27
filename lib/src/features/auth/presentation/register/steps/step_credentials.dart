import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/ui/primitives/app_input.dart';
import '../../../../../core/ui/primitives/app_button.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../register_state.dart';

enum _PasswordStrength { weak, medium, strong }

class StepCredentials extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const StepCredentials({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  ConsumerState<StepCredentials> createState() => _StepCredentialsState();
}

class _StepCredentialsState extends ConsumerState<StepCredentials> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String _passwordValue = '';

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'يجب ألا تقل كلمة المرور عن 6 أحرف';
    }
    return null;
  }

  _PasswordStrength _strength(String value) {
    if (value.length < 6) return _PasswordStrength.weak;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(value);
    if (value.length >= 10 && hasLetter && hasDigit && hasSymbol) {
      return _PasswordStrength.strong;
    }
    if (value.length >= 8 && hasLetter && hasDigit) {
      return _PasswordStrength.medium;
    }
    return _PasswordStrength.weak;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(registerControllerProvider.notifier);
    notifier.setEmail(widget.emailController.text);
    notifier.setPassword(widget.passwordController.text);
    notifier.setCurrentStep(2);
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength(_passwordValue);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: AppRadii.brSm,
                ),
                child: const Icon(Icons.lock_person_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  'بيانات الدخول وحماية الحساب',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: widget.emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@clinic.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: _validateEmail,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: widget.passwordController,
            label: 'كلمة المرور',
            obscure: _obscure,
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: _validatePassword,
            onChanged: (v) => setState(() => _passwordValue = v),
            onEditingComplete: _submit,
          ),
          const SizedBox(height: AppSpace.sm),
          _PasswordStrengthBar(strength: strength),
          const SizedBox(height: AppSpace.xxl),
          AppButton(
            label: 'المتابعة لمسار العيادة',
            icon: Icons.arrow_back_rounded,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: 'الرجوع للبيانات ورقم الهاتف',
            icon: Icons.arrow_forward_rounded,
            variant: AppButtonVariant.ghost,
            onPressed: widget.onBack,
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final _PasswordStrength strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final (label, color, segments) = switch (strength) {
      _PasswordStrength.weak => ('ضعيفة', AppColors.danger, 1),
      _PasswordStrength.medium => ('متوسطة', AppColors.warning, 2),
      _PasswordStrength.strong => ('قوية', AppColors.success, 3),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final filled = i < segments;
            return Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled
                        ? color
                        : AppColors.borderSubtle(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'قوة كلمة المرور: $label',
          style: GoogleFonts.cairo(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
