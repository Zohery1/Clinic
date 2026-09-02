import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/data/app_chart_card.dart';
import '../../../../core/ui/data/app_section.dart';
import '../../../../core/ui/data/app_stat_card.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../reports_controller.dart';
import 'revenue_line_chart.dart';
import 'status_donut_chart.dart';
class OverviewTab extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;
  const OverviewTab({
    super.key,    required this.startDate,    required this.endDate,  
});
  String get _rangeKey {
    String fmt(DateTime d) =>        '${
d.year
}-${
d.month.toString().padLeft(2, '0')
}-${
d.day.toString().padLeft(2, '0')
}';
    return '${
fmt(startDate)
}_${
fmt(endDate)
}';
  
}  @override  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayRevenueProvider);
    final week = ref.watch(weeklyRevenueProvider);
    final month = ref.watch(monthRevenueProvider);
    final daily = ref.watch(dailyStatsProvider(_rangeKey));
    final status = ref.watch(todayStatusCountsProvider);
    final weeklyTotal = week.maybeWhen(      data: (data) => data.fold<double>(        0.0,        (acc, m) => acc + ((m['revenue'] as num?)?.toDouble() ?? 0.0),      ),      orElse: () => 0.0,    );
    return SingleChildScrollView(      padding: const EdgeInsets.all(AppSpace.lg),      child: Column(        crossAxisAlignment: CrossAxisAlignment.stretch,        children: [          LayoutBuilder(            builder: (context, c) {
              final vertical = c.maxWidth < 700;
              final cards = [                _kpi(                  context,                  title: '??????? ?????',                  async: today,                  icon: Icons.payments_outlined,                  color: AppColors.primary,                  subtitle: '??? ????',                ),                _kpi(                  context,                  title: '??????? ???????',                  async: AsyncValue.data(weeklyTotal),                  icon: Icons.date_range_outlined,                  color: const Color(0xFF7C3AED),                  subtitle: '??? 7 ????',                ),                _kpi(                  context,                  title: '??????? ?????',                  async: month,                  icon: Icons.account_balance_wallet_outlined,                  color: AppColors.success,                  subtitle: '????? ??????',                ),              ];
              if (vertical) {
                return Column(                  children: [                    for (var i = 0;
 i < cards.length;
 i++) ...[                      cards[i],                      if (i < cards.length - 1)                        const SizedBox(height: AppSpace.md),                    ],                  ],                );
              
}              return Row(                children: [                  for (var i = 0;
 i < cards.length;
 i++) ...[                    Expanded(child: cards[i]),                    if (i < cards.length - 1)                      const SizedBox(width: AppSpace.md),                  ],                ],              );
            
},          ),          const SizedBox(height: AppSpace.xl),          LayoutBuilder(            builder: (context, c) {
              final stacked = c.maxWidth < 900;
              final lineCard = _buildLineChartCard(daily);
              final donutCard = _buildDonutCard(status);
              if (stacked) {
                return Column(                  children: [                    lineCard,                    const SizedBox(height: AppSpace.lg),                    donutCard,                  ],                );
              
}              return Row(                crossAxisAlignment: CrossAxisAlignment.stretch,                children: [                  Expanded(flex: 2, child: lineCard),                  const SizedBox(width: AppSpace.lg),                  Expanded(flex: 1, child: donutCard),                ],              );
            
},          ),        ],      ),    );
  
}  Widget _kpi(    BuildContext context, {
    required String title,    required AsyncValue<double> async,    required IconData icon,    required Color color,    required String subtitle,  
}) {
    return AppStatCard(      title: title,      icon: icon,      color: color,      subtitle: subtitle,      isLoading: async.isLoading,      value: async.when(        data: (v) => '${
v.toStringAsFixed(0)
} ?.?',        loading: () => '—',        error: (_, __) => '—',      ),    );
  
}  Widget _buildLineChartCard(AsyncValue<List<Map<String, dynamic>>> daily) {
    return daily.when(      data: (logs) {
        final data = <double>[];
        final labels = <String>[];
        final byDate = <String, double>{

};
        for (final l in logs) {
          final d = l['date'] as String?;
          if (d == null) continue;
          byDate[d] = (l['revenue'] as num?)?.toDouble() ?? 0.0;
        
}        final start = DateTime(          startDate.year,          startDate.month,          startDate.day,        );
        final end = DateTime(endDate.year, endDate.month, endDate.day);
        for (var d = start;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))) {
          final key =              '${
d.year
}-${
d.month.toString().padLeft(2, '0')
}-${
d.day.toString().padLeft(2, '0')
}';
          data.add(byDate[key] ?? 0.0);
          labels.add(key);
        
}        return AppChartCard(          title: '????????? ???????',          subtitle: '?????? ????????',          height: 280,          child: RevenueLineChart(data: data, labels: labels),        );
      
},      loading: () => const AppChartCard(        title: '????????? ???????',        subtitle: '?????? ????????',        height: 280,        child: AppSkeleton(height: 220, radius: 8),      ),      error: (e, _) => AppChartCard(        title: '????????? ???????',        subtitle: '?????? ????????',        height: 280,        child: AppErrorState(          icon: Icons.error_outline_rounded,          title: '???? ????? ????????',          message: e.toString(),        ),      ),    );
  
}  Widget _buildDonutCard(AsyncValue<Map<String, double>> status) {
    return AppSection(      title: '???? ?????? ?????',      subtitle: '????? ???????',      padding: EdgeInsets.zero,      child: AppChartCard(        title: '',        height: 280,        padding: const EdgeInsets.all(AppSpace.lg),        child: status.when(          data: (m) => Column(            crossAxisAlignment: CrossAxisAlignment.stretch,            children: [              Expanded(child: StatusDonutChart(data: m)),              const SizedBox(height: AppSpace.sm),              Wrap(                spacing: AppSpace.sm,                runSpacing: AppSpace.xs,                alignment: WrapAlignment.center,                children: [                  _legend(context, '?? ????????',                      m['waiting'] ?? 0, AppColors.warning),                  _legend(context, '?? ??????',                      m['with_doctor'] ?? 0, AppColors.info),                  _legend(context, '?????',                      m['completed'] ?? 0, AppColors.success),                  _legend(context, '????',                      m['cancelled'] ?? 0, AppColors.danger),                ],              ),            ],          ),          loading: () => const AppSkeleton(height: 220, radius: 8),          error: (e, _) => AppErrorState(            icon: Icons.error_outline_rounded,            title: '???? ????? ????????',            message: e.toString(),          ),        ),      ),    );
  
}  Widget _legend(BuildContext context, String label, double value, Color color) {
    return Row(      mainAxisSize: MainAxisSize.min,      children: [        Container(          width: 8,          height: 8,          decoration: BoxDecoration(color: color, shape: BoxShape.circle),        ),        const SizedBox(width: 4),        Text(          '$label · ${
value.toStringAsFixed(0)
}',          style: GoogleFonts.cairo(            fontSize: 11,            fontWeight: FontWeight.w600,            color: AppColors.textMuted(context),          ),        ),      ],    );
  
}
}