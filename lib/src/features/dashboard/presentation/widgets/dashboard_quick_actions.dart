import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/routing.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../patients/presentation/widgets/add_patient_dialog.dart';

/// Four daily verbs. One accent, no rainbow of icon colors.
class DashboardQuickActions extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardQuickActions({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final effectiveClinicId = user?.clinicId ?? '';

    final actions = <_ActionItem>[
      _ActionItem(
        label: 'تسجيل مريض جديد',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AddPatientDialog(clinicId: effectiveClinicId),
          );
        },
      ),
      _ActionItem(
        label: 'حجز كشف جديد',
        icon: Icons.event_available_rounded,
        onTap: () => AppNavigation.showBookAppointment(
          context,
          clinicId: effectiveClinicId,
        ),
      ),
      _ActionItem(
        label: 'طابور الكشوفات',
        icon: Icons.medical_services_outlined,
        onTap: () => onNavigateToTab?.call(1),
      ),
      if (user?.isOwner ?? false)
        _ActionItem(
          label: 'التقارير المالية',
          icon: Icons.query_stats_rounded,
          onTap: () => onNavigateToTab?.call(3),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 720 ? actions.length : 2;
        const gap = AppSpace.sm;
        final itemWidth = (w - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _QuickActionTile(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _ActionItem action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = AppColors.accent(context);

    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap,
        hoverColor: accent.withValues(alpha: isDark ? 0.10 : 0.05),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.borderSubtle(context)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.09),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                alignment: Alignment.center,
                child: Icon(action.icon, size: 17, color: accent),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                size: 16,
                color: AppColors.textMuted(context).withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
