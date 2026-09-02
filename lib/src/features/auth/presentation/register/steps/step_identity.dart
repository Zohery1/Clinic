import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/ui/primitives/app_input.dart';
import '../../../../../core/ui/primitives/app_button.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../register_state.dart';

class StepIdentity extends ConsumerStatefulWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final VoidCallback onSubmit;

  const StepIdentity({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    required this.onSubmit,
  });

  @override
  ConsumerState<StepIdentity> createState() => _StepIdentityState();
}

class _StepIdentityState extends ConsumerState<StepIdentity> {
  final _formKey = GlobalKey<FormState>();

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â¥Ã˜Â¯Ã˜Â®Ã˜Â§Ã™â€ž Ã˜Â§Ã™â€žÃ˜Â§Ã˜Â³Ã™â€¦ Ã˜Â§Ã™â€žÃ™Æ’Ã˜Â§Ã™â€¦Ã™â€ž';
    }
    if (value.trim().length < 3) {
      return 'Ã˜Â§Ã™â€žÃ˜Â§Ã˜Â³Ã™â€¦ Ã™â€šÃ˜ÂµÃ™Å Ã˜Â± Ã˜Â¬Ã˜Â¯Ã˜Â§Ã™â€¹ (3 Ã˜Â£Ã˜Â­Ã˜Â±Ã™Â Ã˜Â¹Ã™â€žÃ™â€° Ã˜Â§Ã™â€žÃ˜Â£Ã™â€šÃ™â€ž)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â¥Ã˜Â¯Ã˜Â®Ã˜Â§Ã™â€ž Ã˜Â±Ã™â€šÃ™â€¦ Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â§Ã˜ÂªÃ™Â Ã™â€žÃ™â€žÃ˜ÂªÃ™Ë†Ã˜Â§Ã˜ÂµÃ™â€ž';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.length < 10) {
      return 'Ã™Å Ã˜Â±Ã˜Â¬Ã™â€° Ã˜Â¥Ã˜Â¯Ã˜Â®Ã˜Â§Ã™â€ž Ã˜Â±Ã™â€šÃ™â€¦ Ã™â€¡Ã˜Â§Ã˜ÂªÃ™Â Ã˜ÂµÃ˜Â­Ã™Å Ã˜Â­ (10 Ã˜Â£Ã˜Â±Ã™â€šÃ˜Â§Ã™â€¦ Ã˜Â¹Ã™â€žÃ™â€° Ã˜Â§Ã™â€žÃ˜Â£Ã™â€šÃ™â€ž)';
    }
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(registerControllerProvider.notifier);
    notifier.setFullName(widget.fullNameController.text);
    notifier.setPhone(widget.phoneController.text);
    notifier.setCurrentStep(1);
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepHeader(
            icon: Icons.person_pin_rounded,
            title: 'Ã˜Â§Ã™â€žÃ˜Â¨Ã™Å Ã˜Â§Ã™â€ Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ˜Â´Ã˜Â®Ã˜ÂµÃ™Å Ã˜Â© Ã™Ë†Ã˜Â±Ã™â€šÃ™â€¦ Ã˜Â§Ã™â€žÃ˜ÂªÃ™Ë†Ã˜Â§Ã˜ÂµÃ™â€ž',
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: widget.fullNameController,
            label: 'Ã˜Â§Ã™â€žÃ˜Â§Ã˜Â³Ã™â€¦ Ã˜Â§Ã™â€žÃ™Æ’Ã˜Â§Ã™â€¦Ã™â€ž',
            hint: 'Ã™â€¦Ã˜Â«Ã˜Â§Ã™â€ž: Ã˜Â¯. Ã˜Â£Ã˜Â­Ã™â€¦Ã˜Â¯ Ã™â€¦Ã˜Â­Ã™â€¦Ã˜Â¯',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            validator: _validateName,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: widget.phoneController,
            label: 'Ã˜Â±Ã™â€šÃ™â€¦ Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â§Ã˜ÂªÃ™Â (Ã˜Â§Ã™â€žÃ™Ë†Ã˜Â§Ã˜ÂªÃ˜Â³Ã˜Â§Ã˜Â¨ Ã˜Â§Ã™â€žÃ˜Â´Ã˜Â®Ã˜ÂµÃ™Å )',
            hint: '01xxxxxxxxx',
            helper:
                'Ã˜Â³Ã™Å Ã™ÂÃ˜Â³Ã˜ÂªÃ˜Â®Ã˜Â¯Ã™â€¦ Ã™â€žÃ˜ÂªÃ™Ë†Ã˜Â§Ã˜ÂµÃ™â€ž Ã˜Â§Ã™â€žÃ˜Â¥Ã˜Â¯Ã˜Â§Ã˜Â±Ã˜Â© Ã™Ë†Ã˜Â¥Ã˜Â±Ã˜Â³Ã˜Â§Ã™â€ž Ã˜Â¥Ã˜Â´Ã˜Â¹Ã˜Â§Ã˜Â±Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ˜Â­Ã˜Â³Ã˜Â§Ã˜Â¨ Ã˜Â§Ã™â€žÃ™â€¦Ã™â€¡Ã™â€¦Ã˜Â©',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
            validator: _validatePhone,
            onEditingComplete: _submit,
          ),
          const SizedBox(height: AppSpace.xxl),
          AppButton(
            label: 'Ã˜Â§Ã™â€žÃ™â€¦Ã˜ÂªÃ˜Â§Ã˜Â¨Ã˜Â¹Ã˜Â© Ã™â€žÃ˜Â­Ã˜Â³Ã˜Â§Ã˜Â¨ Ã˜Â§Ã™â€žÃ˜Â¯Ã˜Â®Ã™Ë†Ã™â€ž',
            icon: Icons.arrow_back_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _StepHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: AppRadii.brSm,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
