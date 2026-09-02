import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../../../core/ui/tokens/shadows.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../patients/presentation/widgets/add_patient_dialog.dart';

/// 4 quick action cards in a responsive 2x2 grid (desktop) or
/// horizontal scroll (mobile).
class DashboardQuickActions extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardQuickActions({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final effectiveClinicId = user?.clinicId ?? '';

    final actions = <_QuickAction>[
      _QuickAction(
        title: 'مريض جديد',
        subtitle: 'إضافة سجل جديد',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.primary,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AddPatientDialog(clinicId: effectiveClinicId),
          );
        },
      ),
      _QuickAction(
        title: 'حجز موعد',
        subtitle: 'حجز جديد في الجدول',
        icon: Icons.event_available_rounded,
        color: AppColors.completed,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => BookAppointmentDialog(clinicId: effectiveClinicId),
          );
        },
      ),
      _QuickAction(
        title: 'بدء الكشف',
        subtitle: 'استكمال الكشف الطبي',
        icon: Icons.medical_services_rounded,
        color: AppColors.success,
        onTap: () => onNavigateToTab?.call(1),
      ),
      _QuickAction(
        title: 'تقارير اليوم',
        subtitle: 'لوحة الأداء المالي',
        icon: Icons.insights_rounded,
        color: AppColors.info,
        onTap: () => onNavigateToTab?.call(3),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;

        if (wide) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: AppSpace.md,
            mainAxisSpacing: AppSpace.md,
            childAspectRatio: 3.4,
            children: [for (final a in actions) _ActionTile(action: a)],
          );
        }

        return SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
            itemBuilder: (_, i) => SizedBox(
              width: 220,
              child: _ActionTile(action: actions[i]),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionTile extends StatefulWidget {
  final _QuickAction action;
  const _ActionTile({required this.action});

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final isDark = AppColors.isDark(context);

    final border = _hovered
        ? action.color.withValues(alpha: isDark ? 0.55 : 0.4)
        : AppColors.borderSubtle(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppRadii.brMd,
          border: Border.all(color: border, width: 1),
          boxShadow:
              _hovered ? AppShadows.md(context) : AppShadows.sm(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppRadii.brMd,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: action.onTap,
            splashColor: action.color.withValues(alpha: 0.08),
            highlightColor: action.color.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: action.color
                          .withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: AppRadii.brSm,
                    ),
                    child: Icon(action.icon, size: 20, color: action.color),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          action.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary(context),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: AppColors.textMuted(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}