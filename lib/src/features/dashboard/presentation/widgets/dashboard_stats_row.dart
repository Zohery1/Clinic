import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/data/app_stat_card.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../reports/presentation/reports_controller.dart';

/// 4 KPI cards in a responsive grid (4 cols >=1280, 2 cols otherwise).
/// Loading renders 4 skeletons in the same shape — no spinners.
class DashboardStatsRow extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardStatsRow({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(todayRevenueProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);

    final loading = revenueAsync.isLoading || appointmentsAsync.isLoading;

    final revenueValue = revenueAsync.when(
      data: (v) => _formatCurrency(v),
      loading: () => '…',
      error: (_, __) => '–',
    );

    final appointments = appointmentsAsync.value ?? const [];
    final total = appointments.length;
    final completed = appointments.where((a) => a.status == 'completed').length;
    final waiting = appointments.where(
            (a) => a.status != 'completed' && !a.status.startsWith('cancelled'))
        .length;

    if (loading && appointments.isEmpty && revenueAsync.value == null) {
      return _skeletonGrid();
    }

    final cards = <AppStatCard>[
      AppStatCard(
        title: 'إيراد اليوم',
        value: revenueValue,
        subtitle: 'المتحصل الفعلي لليوم',
        icon: Icons.payments_rounded,
        color: AppColors.success,
        onTap: () => onNavigateToTab?.call(3),
      ),
      AppStatCard(
        title: 'مواعيد اليوم',
        value: '$total',
        subtitle: 'حجوزات مسجلة',
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
        onTap: () => onNavigateToTab?.call(1),
      ),
      AppStatCard(
        title: 'مكتملة',
        value: '$completed',
        subtitle: 'تم إنهاء الكشف',
        icon: Icons.check_circle_rounded,
        color: AppColors.completed,
        onTap: () => onNavigateToTab?.call(1),
      ),
      AppStatCard(
        title: 'في الانتظار',
        value: '$waiting',
        subtitle: 'قيد المتابعة',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        onTap: () => onNavigateToTab?.call(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1280;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0)
                SizedBox(
                  width: wide ? AppSpace.md : 0,
                  height: wide ? 0 : AppSpace.md,
                ),
              if (wide) Expanded(child: cards[i]) else cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _skeletonGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1280;
        final children = <Widget>[
          for (int i = 0; i < 4; i++)
            Container(
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: AppRadii.brMd,
                border: Border.all(
                    color: AppColors.borderSubtle(context), width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 96, height: 12),
                  SizedBox(height: AppSpace.md),
                  AppSkeleton(width: 80, height: 24),
                  SizedBox(height: AppSpace.sm),
                  AppSkeleton(width: 120, height: 10),
                ],
              ),
            ),
        ];
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                SizedBox(
                  width: wide ? AppSpace.md : 0,
                  height: wide ? 0 : AppSpace.md,
                ),
              if (wide) Expanded(child: children[i]) else children[i],
            ],
          ],
        );
      },
    );
  }

  String _formatCurrency(double v) {
    final str = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      final fromRight = str.length - i;
      buffer.write(str[i]);
      if (fromRight > 1 && fromRight % 3 == 1) buffer.write(',');
    }
    return '$buffer ج.م';
  }
}