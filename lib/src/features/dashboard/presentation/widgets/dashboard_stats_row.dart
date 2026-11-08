import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/ui/tokens/typography.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../reports/presentation/reports_controller.dart';

/// Today's four numbers, held in one command strip instead of four floating
/// cards. Hairlines do the separating; color is reserved for meaning.
class DashboardStatsRow extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardStatsRow({super.key, this.onNavigateToTab});

  String _formatCurrency(num value) {
    final fmt = intl.NumberFormat('#,##0', 'ar');
    return '${fmt.format(value)} ج.م';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(todayRevenueProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final canViewReports = ref.watch(currentUserProvider)?.isOwner ?? false;

    final loading = revenueAsync.isLoading || appointmentsAsync.isLoading;
    final appointments = appointmentsAsync.value ?? const [];
    final completed = appointments.where((a) => a.status == 'completed').length;
    final waiting = appointments
        .where((a) =>
            a.status != 'completed' && !a.status.startsWith('cancelled'))
        .length;
    final total = appointments.length;
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    if (loading && appointments.isEmpty && revenueAsync.value == null) {
      return const _Skeleton();
    }

    final revenueValue = revenueAsync.when(
      data: (v) => _formatCurrency(v),
      loading: () => '…',
      error: (_, __) => '-',
    );

    final segments = <Widget>[
      _StatSegment(
        label: 'إيراد اليوم',
        value: revenueValue,
        caption: 'المحصل الفعلي',
        icon: Icons.account_balance_wallet_outlined,
        accent: AppColors.success,
        onTap: canViewReports ? () => onNavigateToTab?.call(3) : null,
      ),
      _StatSegment(
        label: 'كشوفات اليوم',
        value: '$total',
        caption: 'إجمالي الحجوزات',
        icon: Icons.event_note_rounded,
        accent: AppColors.accent(context),
        onTap: () => onNavigateToTab?.call(1),
      ),
      _StatSegment(
        label: 'مكتملة',
        value: '$completed',
        caption: '${(progress * 100).round()}% تم الكشف',
        icon: Icons.check_circle_outline_rounded,
        accent: AppColors.success,
        progress: progress,
        onTap: () => onNavigateToTab?.call(1),
      ),
      _StatSegment(
        label: 'في الانتظار',
        value: '$waiting',
        caption: waiting > 0 ? 'في صالة الانتظار' : 'لا يوجد انتظار',
        icon: Icons.hourglass_empty_rounded,
        accent: waiting > 0 ? AppColors.warning : AppColors.textMuted(context),
        emphasize: waiting > 0,
        onTap: () => onNavigateToTab?.call(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return _Panel(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < segments.length; i++) ...[
                    if (i > 0) const _VerticalHairline(),
                    Expanded(child: segments[i]),
                  ],
                ],
              ),
            ),
          );
        }

        if (constraints.maxWidth < 360) {
          return _Panel(
            child: Column(
              children: [
                for (int i = 0; i < segments.length; i++) ...[
                  if (i > 0) const _HorizontalHairline(),
                  segments[i],
                ],
              ],
            ),
          );
        }

        return _Panel(
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: segments[0]),
                    const _VerticalHairline(),
                    Expanded(child: segments[1]),
                  ],
                ),
              ),
              const _HorizontalHairline(),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: segments[2]),
                    const _VerticalHairline(),
                    Expanded(child: segments[3]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      child: child,
    );
  }
}

class _VerticalHairline extends StatelessWidget {
  const _VerticalHairline();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: AppColors.borderSubtle(context));
}

class _HorizontalHairline extends StatelessWidget {
  const _HorizontalHairline();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.borderSubtle(context));
}

class _StatSegment extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final double? progress;
  final bool emphasize;
  final VoidCallback? onTap;

  const _StatSegment({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    this.progress,
    this.emphasize = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg - 2,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppTypography.numericLg(
                AppColors.textPrimary(context),
              ).copyWith(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize ? accent : AppColors.textMuted(context),
              height: 1.3,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: AppColors.subtle(context),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        hoverColor: accent.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
