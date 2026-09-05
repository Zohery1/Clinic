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
      return 'يرجى إدخال الاسم الكامل';
    }
    if (value.trim().length < 3) {
      return 'الاسم قصير جداً (3 أحرف على الأقل)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف للتواصل';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.length < 10) {
      return 'يرجى إدخال رقم هاتف صحيح (10 أرقام على الأقل)';
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
            title: 'البيانات الشخصية ورقم التواصل',
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: widget.fullNameController,
            label: 'الاسم الكامل',
            hint: 'مثال: د. أحمد محمد',
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            validator: _validateName,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: widget.phoneController,
            label: 'رقم الهاتف (الواتساب الشخصي)',
            hint: '01xxxxxxxxx',
            helper:
                'سيُستخدم لتواصل الإدارة وإرسال إشعارات الحساب المهمة',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
            validator: _validatePhone,
            onEditingComplete: _submit,
          ),
          const SizedBox(height: AppSpace.xxl),
          AppButton(
            label: 'المتابعة لحساب الدخول',
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
