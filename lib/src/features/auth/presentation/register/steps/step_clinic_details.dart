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
      return 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø§Ø³Ù… Ø§Ù„Ø¹ÙŠØ§Ø¯Ø© Ø£Ùˆ Ø§Ù„Ù…Ø±ÙƒØ² Ø§Ù„Ø·Ø¨ÙŠ';
    }
    return null;
  }

  String? _validateMainBranch(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø§Ø³Ù… Ø§Ù„ÙØ±Ø¹ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ';
    }
    return null;
  }

  String? _validateInviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© Ù„Ù„Ø§Ù†Ø¶Ù…Ø§Ù… Ù„Ù„Ø¹ÙŠØ§Ø¯Ø©';
    }
    return null;
  }

  String? _validateExtraBranchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ÙŠØ±Ø¬Ù‰ Ø¥Ø¯Ø®Ø§Ù„ Ø§Ø³Ù… Ø§Ù„ÙØ±Ø¹';
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
                ? 'Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨ ÙˆØªØ£Ø³ÙŠØ³ Ø§Ù„Ø¹ÙŠØ§Ø¯Ø© ðŸš€'
                : 'Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨ ÙˆØ§Ù„Ø§Ù†Ø¶Ù…Ø§Ù… Ù„Ù„Ø¹ÙŠØ§Ø¯Ø© ðŸš€',
            icon: Icons.check_circle_rounded,
            loading: widget.isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: 'Ø§Ù„Ø±Ø¬ÙˆØ¹ Ù„ØªØ¹Ø¯ÙŠÙ„ Ù…Ø³Ø§Ø± Ø§Ù„Ø¹ÙŠØ§Ø¯Ø©',
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
          title: 'Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø±ÙƒØ² Ø§Ù„Ø·Ø¨ÙŠ ÙˆØ§Ù„ÙØ±ÙˆØ¹',
        ),
        const SizedBox(height: AppSpace.lg),
        AppTextField(
          controller: clinicNameController,
          label: 'Ø§Ø³Ù… Ø§Ù„Ø¹ÙŠØ§Ø¯Ø© / Ø§Ù„Ù…Ø±ÙƒØ² Ø§Ù„Ø·Ø¨ÙŠ',
          hint: 'Ù…Ø«Ø§Ù„: Ù…Ø±ÙƒØ² Ø§Ù„Ù†Ø®Ø¨Ø© Ø§Ù„ØªØ®ØµØµÙŠ',
          prefixIcon: const Icon(Icons.business_rounded, size: 20),
          validator: validateClinicName,
          onEditingComplete: () => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: AppSpace.lg),
        AppTextField(
          controller: mainBranchNameController,
          label: 'Ø§Ø³Ù… Ø§Ù„ÙØ±Ø¹ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ',
          hint: 'Ù…Ø«Ø§Ù„: Ø§Ù„ÙØ±Ø¹ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ - Ù…Ø¯ÙŠÙ†Ø© Ù†ØµØ±',
          helper: 'Ø§Ù„ÙØ±Ø¹ Ø§Ù„Ø§ÙØªØ±Ø§Ø¶ÙŠ Ø§Ù„Ø°ÙŠ Ø³ØªØ¨Ø¯Ø£ Ø¨Ù‡ Ø§Ù„Ø¹ÙŠØ§Ø¯Ø© (ÙŠÙ…ÙƒÙ† ØªØ¹Ø¯ÙŠÙ„Ù‡ Ù„Ø§Ø­Ù‚Ø§Ù‹)',
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
                  'ÙØ±ÙˆØ¹ Ø¥Ø¶Ø§ÙÙŠØ© Ù„Ù„Ø¹ÙŠØ§Ø¯Ø© (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            AppButton(
              label: 'Ø¥Ø¶Ø§ÙØ© ÙØ±Ø¹',
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
              'ÙŠÙ…ÙƒÙ†Ùƒ Ø§Ù„Ø¨Ø¯Ø¡ Ø¨Ø§Ù„ÙØ±Ø¹ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠ ÙÙ‚Ø· Ø§Ù„Ø¢Ù†ØŒ ÙˆØ¥Ø¶Ø§ÙØ© ÙØ±ÙˆØ¹ Ø£Ø®Ø±Ù‰ ÙÙŠ Ø£ÙŠ ÙˆÙ‚Øª Ù…Ù† Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª.',
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
                label: 'Ø§Ù„ÙØ±Ø¹ Ø§Ù„Ø¥Ø¶Ø§ÙÙŠ Ø±Ù‚Ù… (${index + 1})',
                color: AppColors.primary,
              ),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Ø­Ø°Ù Ø§Ù„ÙØ±Ø¹',
                variant: AppIconButtonVariant.ghost,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          AppTextField(
            controller: branch.nameController,
            label: 'Ø§Ø³Ù… Ø§Ù„ÙØ±Ø¹',
            hint: 'Ù…Ø«Ø§Ù„: ÙØ±Ø¹ Ø§Ù„Ù…Ù‡Ù†Ø¯Ø³ÙŠÙ†',
            validator: validateName,
          ),
          const SizedBox(height: AppSpace.sm),
          AppTextField(
            controller: branch.addressController,
            label: 'Ø§Ù„Ø¹Ù†ÙˆØ§Ù† (Ø§Ø®ØªÙŠØ§Ø±ÙŠ)',
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
          title: 'Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø§Ù†Ø¶Ù…Ø§Ù… Ù„Ù„Ø¹ÙŠØ§Ø¯Ø©',
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Ù…Ø§ Ù‡Ùˆ Ø¯ÙˆØ±Ùƒ ÙÙŠ Ø§Ù„Ø¹ÙŠØ§Ø¯Ø©ØŸ',
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
                label: 'Ø£Ù†Ø§ Ø·Ø¨ÙŠØ¨ Ù…Ø¹Ø§Ù„Ø¬',
                icon: Icons.medical_services_outlined,
                selected: selectedRole == 'doctor',
                onTap: () => onSelectRole('doctor'),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: _RoleCard(
                role: 'secretary',
                label: 'Ø£Ù†Ø§ Ù…Ø³Ø§Ø¹Ø¯ / Ø³ÙƒØ±ØªÙŠØ±',
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
            label: 'ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© Ù…Ù† Ù…Ø¯ÙŠØ± Ø§Ù„Ø¹ÙŠØ§Ø¯Ø©',
            hint: 'Ù…Ø«Ø§Ù„: ABC123XYZ',
            helper: 'Ø§Ø·Ù„Ø¨ ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© Ù…Ù† ØµØ§Ø­Ø¨ Ø£Ùˆ Ù…Ø¯ÙŠØ± Ø§Ù„Ø¹ÙŠØ§Ø¯Ø© Ù„Ù„Ø§Ù†Ø¶Ù…Ø§Ù… Ø¥Ù„Ù‰ ÙØ±ÙŠÙ‚Ù‡',
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
                  'ÙƒÙˆØ¯ Ø§Ù„Ø¯Ø¹ÙˆØ© Ù…Ø¤ÙƒØ¯ ÙˆÙ…ÙØ¹Ù„',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ÙƒÙˆØ¯: $code',
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