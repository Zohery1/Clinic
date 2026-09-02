import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/ui/primitives/app_chip.dart';
import '../../../../../core/ui/primitives/app_button.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../../../../../core/ui/tokens/motion.dart';
import '../register_state.dart';

class StepClinicPath extends ConsumerWidget {
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const StepClinicPath({
    super.key,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerControllerProvider);
    final notifier = ref.read(registerControllerProvider.notifier);

    return Column(
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
              child: const Icon(Icons.alt_route_rounded,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                'مسار العيادة في المنصة',
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
        const SizedBox(height: AppSpace.sm),
        Text(
          'حدد ما إذا كنت تؤسس عيادتك ومركزك الطبي الخاص، أم تنضم إلى فريق عمل عيادة قائمة بكود دعوة.',
          style: GoogleFonts.cairo(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (state.isInviteCodeLocked) ...[
          _LockedBanner(code: state.inviteCode),
          const SizedBox(height: AppSpace.md),
        ],
        _PathCard(
          path: 'create',
          title: 'تأسيس عيادة جديدة (مالك العيادة)',
          subtitle:
              'أنا صاحب المركز الطبي أو العيادة، وأرغب في تأسيس حساب عيادة وإضافة فروعها وإدارة الأطباء والموظفين.',
          icon: Icons.add_business_rounded,
          tags: const ['مالك العيادة', 'إدارة الفروع', 'تقارير كاملة'],
          selected: state.clinicPath == 'create',
          onSelect: () => notifier.setClinicPath('create'),
        ),
        const SizedBox(height: AppSpace.md),
        _PathCard(
          path: 'join',
          title: 'الانضمام لعيادة موجودة (كود دعوة)',
          subtitle:
              "أنا طبيب معالج أو مساعد/سكرتير، ولدي كود دعوة من مدير العيادة للانضمام.",
          icon: Icons.group_add_rounded,
          tags: const ['طبيب معالج', 'مساعد / سكرتير', 'ربط فوري'],
          selected: state.clinicPath == 'join',
          onSelect: () => notifier.setClinicPath('join'),
        ),
        const SizedBox(height: AppSpace.xxl),
        AppButton(
          label: state.clinicPath == 'create'
              ? 'المتابعة لإعداد بيانات العيادة'
              : 'المتابعة لكود الانضمام',
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            notifier.setCurrentStep(3);
            onSubmit();
          },
        ),
        const SizedBox(height: AppSpace.sm),
        AppButton(
          label: 'الرجوع للبيانات ورقم الهاتف',
          icon: Icons.arrow_forward_rounded,
          variant: AppButtonVariant.ghost,
          onPressed: onBack,
        ),
      ],
    );
  }
}

class _PathCard extends StatelessWidget {
  final String path;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> tags;
  final bool selected;
  final VoidCallback onSelect;

  const _PathCard({
    required this.path,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tags,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.primary;
    final bg = selected ? AppColors.primarySubtle : AppColors.surface(context);
    final borderColor = selected ? accent : AppColors.border(context);
    final titleColor = selected ? accent : AppColors.textPrimary(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppRadii.brMd,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.easeOutCubic,
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brMd,
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppMotion.normal,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? accent : AppColors.subtle(context),
                  borderRadius: AppRadii.brSm,
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.textMuted(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                        _RadioCircle(selected: selected),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(context),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags
                          .map((t) => AppChip(
                                label: t,
                                color: accent,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  final bool selected;
  const _RadioCircle({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.borderStrong(context),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: selected
          ? Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

class _LockedBanner extends StatelessWidget {
  final String code;
  const _LockedBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.successSubtle,
        borderRadius: AppRadii.brMd,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded,
              size: 20, color: AppColors.success),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              'تم فتح الرابط بكود دعوة ($code). يمكنك الانضمام مباشرة للعيادة.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}