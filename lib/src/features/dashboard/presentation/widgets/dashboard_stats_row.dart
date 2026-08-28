import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reports/presentation/reports_controller.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import 'dashboard_stats_card.dart';

/// صف البطاقات الإحصائية للداشبورد
class DashboardStatsRow extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardStatsRow({
    super.key,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);

    final revenueString = todayRevenueAsync.when(
      data: (val) => '${val.toStringAsFixed(0)} ج.م',
      loading: () => '...',
      error: (_, __) => '--',
    );

    final appointments = appointmentsAsync.value ?? [];
    final totalCount = appointments.length;
    final completedCount = appointments.where((a) => a.status == 'completed').length;
    final waitingCount = appointments.where((a) => a.status != 'completed' && !a.status.startsWith('cancelled')).length;

    final cards = [
      DashboardStatsCard(
        title: 'إيراد اليوم',
        value: revenueString,
        icon: Icons.monetization_on_outlined,
        color: AppColors.success,
        subtitle: 'المتحصل الفعلي لليوم',
        isLoading: todayRevenueAsync.isLoading,
        onTap: () => onNavigateToTab?.call(3),
      ),
      DashboardStatsCard(
        title: 'إجمالي المواعيد',
        value: appointmentsAsync.isLoading ? '...' : '$totalCount',
        icon: Icons.calendar_today_rounded,
        color: AppColors.primary,
        subtitle: 'حجوزات مسجلة اليوم',
        isLoading: appointmentsAsync.isLoading,
        onTap: () => onNavigateToTab?.call(1),
      ),
      DashboardStatsCard(
        title: 'حالات مكتملة',
        value: appointmentsAsync.isLoading ? '...' : '$completedCount',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.completed,
        subtitle: 'تم إنهاء الكشف',
        isLoading: appointmentsAsync.isLoading,
        onTap: () => onNavigateToTab?.call(1),
      ),
      DashboardStatsCard(
        title: 'في الانتظار',
        value: appointmentsAsync.isLoading ? '...' : '$waitingCount',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        subtitle: 'قيد المتابعة حالياً',
        isLoading: appointmentsAsync.isLoading,
        onTap: () => onNavigateToTab?.call(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[i]),
              ],
            ],
          );
        } else if (constraints.maxWidth >= 550) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                cards[i],
              ],
            ],
          );
        }
      },
    );
  }
}
