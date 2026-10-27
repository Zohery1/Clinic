import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/data/app_chart_card.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/primitives/app_chip.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../reports/presentation/reports_controller.dart';

/// Weekly revenue line chart wrapped in `AppChartCard`. 7 points,
/// smooth bezier curve, gradient area fill. Loading = skeleton shape.
class DashboardWeeklyChart extends ConsumerStatefulWidget {
  const DashboardWeeklyChart({super.key});

  @override
  ConsumerState<DashboardWeeklyChart> createState() =>
      _DashboardWeeklyChartState();
}

class _DashboardWeeklyChartState extends ConsumerState<DashboardWeeklyChart> {
  int _touchedIndex = -1;

  String _shortDay(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      var name = intl.DateFormat('EEEE', 'ar').format(date);
      if (name.startsWith('ال')) {
        name = name.substring(2);
      }
      return name;
    } catch (_) {
      return '';
    }
  }

  String _dayFull(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return intl.DateFormat('EEEE، d MMM', 'ar').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weeklyRevenueProvider);
    final isDark = AppColors.isDark(context);

    const actions = AppChip(
      label: 'آخر 7 أيام',
      icon: Icons.calendar_view_week_rounded,
      selected: true,
      variant: AppChipVariant.filter,
    );

    Widget chart;
    if (async.isLoading && async.value == null) {
      chart = const Padding(
        padding: EdgeInsets.all(AppSpace.lg),
        child: AppSkeleton(width: double.infinity, height: 200, radius: 12),
      );
    } else if (async.hasError && async.value == null) {
      chart = Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Text(
          'تعذر تحميل الإيرادات',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: AppColors.danger,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      final data = async.value ?? const [];
      if (data.isEmpty) {
        chart = const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
          child: AppEmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'لا توجد بيانات بعد',
            message: 'ستظهر الإيرادات هنا بمجرد تسجيل حجوزات هذا الأسبوع.',
          ),
        );
      } else {
        chart = _buildChart(context, data, isDark);
      }
    }

    return AppChartCard(
      title: 'الإيرادات هذا الأسبوع',
      subtitle: 'ملخص الإيرادات اليومية',
      actions: actions,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg,
      ),
      height: 240,
      child: chart,
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<Map<String, dynamic>> data,
    bool isDark,
  ) {
    final maxRevenue = data
        .map((item) => (item['revenue'] as num? ?? 0.0).toDouble())
        .fold<double>(0.0, (a, b) => a > b ? a : b);
    final ceiling = (maxRevenue == 0 ? 100.0 : maxRevenue * 1.2);
    final spots = <FlSpot>[
      for (int i = 0; i < data.length; i++)
        FlSpot(
          i.toDouble(),
          (data[i]['revenue'] as num? ?? 0.0).toDouble(),
        ),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble().clamp(0.0, double.infinity),
        minY: 0,
        maxY: ceiling,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ceiling / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.borderSubtle(context).withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  child: Text(
                    _shortDay(data[idx]['date'] as String),
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted(context),
                      height: 1.2,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.elevated(context),
            tooltipRoundedRadius: AppRadii.radiusSm,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${_dayFull(data[s.x.round()]['date'] as String)}\n${s.y.toStringAsFixed(0)} ج.م',
                    GoogleFonts.cairo(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                )
                .toList(),
          ),
          handleBuiltInTouches: true,
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              setState(() {
                _touchedIndex = response.lineBarSpots!.first.x.round();
              });
            } else {
              setState(() => _touchedIndex = -1);
            }
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.32,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) =>
                  _touchedIndex == spot.x.round() || data.length <= 7,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: _touchedIndex == spot.x.round() ? 5 : 3,
                color: AppColors.onPrimary,
                strokeColor: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.30 : 0.20),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}