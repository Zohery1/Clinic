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
      return 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø¨Ø±ÙŠØ¯ Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ ØµØ­ÙŠØ­';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±';
    }
    if (value.length < 6) {
      return 'ÙŠØ¬Ø¨ Ø£Ù„Ø§ ØªÙ‚Ù„ ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ø¹Ù† 6 Ø£Ø­Ø±Ù';
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
                  'Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¯Ø®ÙˆÙ„ ÙˆØ­Ù…Ø§ÙŠØ© Ø§Ù„Ø­Ø³Ø§Ø¨',
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
            label: 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ',
            hint: 'example@clinic.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: _validateEmail,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: widget.passwordController,
            label: 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±',
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
            label: 'Ø§Ù„Ù…ØªØ§Ø¨Ø¹Ø© Ù„Ù…Ø³Ø§Ø± Ø§Ù„Ø¹ÙŠØ§Ø¯Ø©',
            icon: Icons.arrow_back_rounded,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: 'Ø§Ù„Ø±Ø¬ÙˆØ¹ Ù„Ù„Ø¨ÙŠØ§Ù†Ø§Øª ÙˆØ±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ',
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
      _PasswordStrength.weak => ('Ø¶Ø¹ÙŠÙØ©', AppColors.danger, 1),
      _PasswordStrength.medium => ('Ù…ØªÙˆØ³Ø·Ø©', AppColors.warning, 2),
      _PasswordStrength.strong => ('Ù‚ÙˆÙŠØ©', AppColors.success, 3),
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
          'Ù‚ÙˆØ© ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±: $label',
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
