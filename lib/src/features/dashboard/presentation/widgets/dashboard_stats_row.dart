import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/data/app_stat_card.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../reports/presentation/reports_controller.dart';

/// 4 KPI cards in a responsive layout:
/// - >= 1100px: 4 columns in a row
/// - 480px - 1099px (including 600-1099px): 2x2 grid
/// - < 480px: single column for small phone viewports
///
/// Skeletons share the exact same responsive layout function to prevent layout shifts.
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
      return _skeletonGrid(context);
    }

    final cards = <Widget>[
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
      builder: (context, constraints) =>
          _buildResponsiveGrid(context, constraints, cards),
    );
  }

  Widget _skeletonGrid(BuildContext context) {
    final skeletons = <Widget>[
      for (int i = 0; i < 4; i++)
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppRadii.brMd,
            border: Border.all(
              color: AppColors.borderSubtle(context),
              width: 1,
            ),
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

    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildResponsiveGrid(context, constraints, skeletons),
    );
  }

  Widget _buildResponsiveGrid(
    BuildContext context,
    BoxConstraints constraints,
    List<Widget> items,
  ) {
    final width = constraints.maxWidth;

    if (width >= 1100) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpace.md),
            Expanded(child: items[i]),
          ],
        ],
      );
    } else if (width >= 480) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: items[0]),
              const SizedBox(width: AppSpace.md),
              Expanded(child: items[1]),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: items[2]),
              const SizedBox(width: AppSpace.md),
              Expanded(child: items[3]),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.md),
            items[i],
          ],
        ],
      );
    }
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