import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/ui/primitives/app_input.dart';
import '../../../../../core/ui/primitives/app_button.dart';
import '../../../../../core/ui/primitives/app_chip.dart';
import '../../../../../core/ui/primitives/app_icon_button.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../../../../../core/ui/tokens/motion.dart';
import '../register_state.dart';

class StepClinicDetails extends ConsumerStatefulWidget {
  final TextEditingController clinicNameController;
  final TextEditingController mainBranchNameController;
  final TextEditingController inviteCodeController;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const StepClinicDetails({
    super.key,
    required this.clinicNameController,
    required this.mainBranchNameController,
    required this.inviteCodeController,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  ConsumerState<StepClinicDetails> createState() => _StepClinicDetailsState();
}

class _StepClinicDetailsState extends ConsumerState<StepClinicDetails> {
  final _formKey = GlobalKey<FormState>();

  String? _validateClinicName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال اسم العيادة أو المركز الطبي';
    }
    return null;
  }

  String? _validateMainBranch(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال اسم الفرع الرئيسي';
    }
    return null;
  }

  String? _validateInviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال كود الدعوة للانضمام للعيادة';
    }
    return null;
  }

  String? _validateExtraBranchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال اسم الفرع';
    }
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (widget.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final notifier = ref.read(registerControllerProvider.notifier);
    final isCreating = state.clinicPath == 'create';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCreating)
            _CreateSection(
              clinicNameController: widget.clinicNameController,
              mainBranchNameController: widget.mainBranchNameController,
              validateClinicName: _validateClinicName,
              validateMainBranch: _validateMainBranch,
              validateExtraBranchName: _validateExtraBranchName,
              extraBranches: state.extraBranches,
              onAddBranch: notifier.addExtraBranch,
              onRemoveBranch: notifier.removeExtraBranch,
            )
          else
            _JoinSection(
              inviteCodeController: widget.inviteCodeController,
              selectedRole: state.selectedRole,
              onSelectRole: notifier.setSelectedRole,
              isLocked: state.isInviteCodeLocked,
              validateInviteCode: _validateInviteCode,
            ),
          const SizedBox(height: AppSpace.xxl),
          AppButton(
            label: isCreating
                ? 'إنشاء الحساب وتأسيس العيادة 🚀'
                : 'إنشاء الحساب والانضمام للعيادة 🚀',
            icon: Icons.check_circle_rounded,
            loading: widget.isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: 'الرجوع لتعديل مسار العيادة',
            icon: Icons.arrow_forward_rounded,
            variant: AppButtonVariant.ghost,
            onPressed: widget.isSubmitting ? null : widget.onBack,
          ),
        ],
      ),
    );
  }
}

class _CreateSection extends StatelessWidget {
  final TextEditingController clinicNameController;
  final TextEditingController mainBranchNameController;
  final FormFieldValidator<String> validateClinicName;
  final FormFieldValidator<String> validateMainBranch;
  final FormFieldValidator<String> validateExtraBranchName;
  final List<ExtraBranchDraft> extraBranches;
  final VoidCallback onAddBranch;
  final ValueChanged<int> onRemoveBranch;

  const _CreateSection({
    required this.clinicNameController,
    required this.mainBranchNameController,
    required this.validateClinicName,
    required this.validateMainBranch,
    required this.validateExtraBranchName,
    required this.extraBranches,
    required this.onAddBranch,
    required this.onRemoveBranch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.apartment_rounded,
          title: 'بيانات المركز الطبي والفروع',
        ),
        const SizedBox(height: AppSpace.lg),
        AppTextField(
          controller: clinicNameController,
          label: 'اسم العيادة / المركز الطبي',
          hint: 'مثال: مركز النخبة التخصصي',
          prefixIcon: const Icon(Icons.business_rounded, size: 20),
          validator: validateClinicName,
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: AppSpace.lg),
        AppTextField(
          controller: mainBranchNameController,
          label: 'اسم الفرع الرئيسي',
          hint: 'مثال: الفرع الرئيسي - مدينة نصر',
          helper: 'الفرع الافتراضي الذي ستبدأ به العيادة (يمكن تعديله لاحقاً)',
          prefixIcon: const Icon(Icons.store_mall_directory_rounded, size: 20),
          validator: validateMainBranch,
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.share_location_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpace.sm),
                Text(
                  'فروع إضافية للعيادة (اختياري)',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            AppButton(
              label: 'إضافة فرع',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              expand: false,
              onPressed: onAddBranch,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        if (extraBranches.isEmpty)
          const _EmptyBranchesHint()
        else
          Column(
            children: [
              for (int i = 0; i < extraBranches.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.md),
                _ExtraBranchCard(
                  branch: extraBranches[i],
                  index: i,
                  validateName: validateExtraBranchName,
                  onRemove: () => onRemoveBranch(i),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _EmptyBranchesHint extends StatelessWidget {
  const _EmptyBranchesHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: AppRadii.brSm,
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.textMuted(context)),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              'يمكنك البدء بالفرع الرئيسي فقط الآن، وإضافة فروع أخرى في أي وقت من الإعدادات.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtraBranchCard extends StatelessWidget {
  final ExtraBranchDraft branch;
  final int index;
  final FormFieldValidator<String> validateName;
  final VoidCallback onRemove;

  const _ExtraBranchCard({
    required this.branch,
    required this.index,
    required this.validateName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.normal,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brSm,
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppChip(
                label: 'الفرع الإضافي رقم ${index + 1}',
                color: AppColors.primary,
              ),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'حذف الفرع',
                variant: AppIconButtonVariant.ghost,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          AppTextField(
            controller: branch.nameController,
            label: 'اسم الفرع',
            hint: 'مثال: فرع المهندسين',
            validator: validateName,
          ),
          const SizedBox(height: AppSpace.sm),
          AppTextField(
            controller: branch.addressController,
            label: 'العنوان (اختياري)',
          ),
        ],
      ),
    );
  }
}

class _JoinSection extends StatelessWidget {
  final TextEditingController inviteCodeController;
  final String selectedRole;
  final ValueChanged<String> onSelectRole;
  final bool isLocked;
  final FormFieldValidator<String> validateInviteCode;

  const _JoinSection({
    required this.inviteCodeController,
    required this.selectedRole,
    required this.onSelectRole,
    required this.isLocked,
    required this.validateInviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.badge_rounded,
          title: 'بيانات المركز الطبي والفروع',
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          'ما هو دورك في العيادة؟',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                role: 'doctor',
                label: 'أنا طبيب معالج',
                icon: Icons.medical_services_outlined,
                selected: selectedRole == 'doctor',
                onTap: () => onSelectRole('doctor'),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: _RoleCard(
                role: 'secretary',
                label: 'أنا مساعد / سكرتير',
                icon: Icons.badge_outlined,
                selected: selectedRole == 'secretary',
                onTap: () => onSelectRole('secretary'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (isLocked)
          _LockedCodeBanner(code: inviteCodeController.text)
        else
          AppTextField(
            controller: inviteCodeController,
            label: 'كود الدعوة من مدير العيادة',
            hint: 'مثال: ABC123XYZ',
            helper: 'اطلب كود الدعوة من صاحب أو مدير العيادة للانضمام إلى فريقها',
            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
            validator: validateInviteCode,
          ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.primary;
    final bg = selected ? AppColors.primarySubtle : AppColors.surface(context);
    final borderColor = selected ? accent : AppColors.border(context);
    final fg = selected ? accent : AppColors.textPrimary(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brSm,
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(height: AppSpace.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedCodeBanner extends StatelessWidget {
  final String code;
  const _LockedCodeBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.successSubtle,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 22, color: AppColors.success),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كود الدعوة مؤكد ومفعل',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'كود: $code',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_rounded,
              size: 16, color: AppColors.textMuted(context)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

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