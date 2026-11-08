import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/ui/tokens/typography.dart';
import '../../../reports/presentation/reports_controller.dart';

/// Seven days of revenue as one quiet line. Dots only appear under the finger.
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
      if (name.startsWith('ال')) name = name.substring(2);
      return name;
    } catch (_) {
      return '';
    }
  }

  String _money(num value) {
    final fmt = intl.NumberFormat('#,##0', 'ar');
    return '${fmt.format(value)} ج.م';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weeklyRevenueProvider);
    final data = async.value ?? const <Map<String, dynamic>>[];
    final total = data.fold<double>(
      0,
      (sum, row) => sum + (((row['revenue'] as num?) ?? 0).toDouble()),
    );

    Widget body;
    if (async.isLoading && async.value == null) {
      body = Container(
        height: 190,
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          color: AppColors.subtle(context),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      );
    } else if (async.hasError && async.value == null) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpace.lg),
        child: Text(
          'تعذر تحميل بيانات الإيرادات.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (data.isEmpty || total == 0) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
        child: AppEmptyState(
          icon: Icons.show_chart_rounded,
          title: 'لا توجد إيرادات هذا الأسبوع',
          message: 'ستظهر هنا فور تسجيل أول دفعة.',
        ),
      );
    } else {
      body = _buildChart(context, data);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg + 2,
              AppSpace.lg,
              AppSpace.md,
              AppSpace.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.success
                        .withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.09),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.show_chart_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'إيرادات الأسبوع',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _money(total),
                        style: AppTypography.numericSm(
                          AppColors.textSecondary(context),
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    'آخر 7 أيام',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.lg,
              AppSpace.lg,
            ),
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<Map<String, dynamic>> data) {
    final spots = <FlSpot>[];
    var maxY = 0.0;
    for (var i = 0; i < data.length; i++) {
      final revenue = ((data[i]['revenue'] as num?) ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), revenue));
      if (revenue > maxY) maxY = revenue;
    }
    // Headroom so the peak never touches the border.
    maxY = (maxY * 1.22).ceilToDouble();

    final accent = AppColors.accent(context);
    final line = AppColors.borderSubtle(context);

    return SizedBox(
      height: 196,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4).clamp(1.0, double.infinity),
            getDrawingHorizontalLine: (_) => FlLine(
              color: line,
              strokeWidth: 1,
              dashArray: const <int>[3, 5],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final touched = idx == _touchedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _shortDay(data[idx]['date']?.toString() ?? ''),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            touched ? FontWeight.w800 : FontWeight.w500,
                        color: touched
                            ? accent
                            : AppColors.textMuted(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              final touched = response?.lineBarSpots;
              if (touched != null && touched.isNotEmpty) {
                final index = touched.first.spotIndex;
                if (_touchedIndex != index) {
                  setState(() => _touchedIndex = index);
                }
              } else if (_touchedIndex != -1) {
                setState(() => _touchedIndex = -1);
              }
            },
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipRoundedRadius: AppRadii.radiusSm,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              getTooltipColor: (_) => AppColors.isDark(context)
                  ? AppColors.darkElevated
                  : AppColors.primaryInk,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.spotIndex;
                  final day =
                      (idx >= 0 && idx < data.length) ? data[idx]['date'] : '';
                  final value = intl.NumberFormat('#,##0', 'ar')
                      .format(spot.y.toInt());
                  return LineTooltipItem(
                    '${_shortDay(day?.toString() ?? '')}\n$value ج.م',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.32,
              color: accent,
              barWidth: 2.4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (index != _touchedIndex) {
                    return FlDotCirclePainter(
                      radius: 0,
                      color: Colors.transparent,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 4.5,
                    color: accent,
                    strokeWidth: 2,
                    strokeColor: AppColors.surface(context),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    accent.withValues(
                      alpha: AppColors.isDark(context) ? 0.28 : 0.16,
                    ),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
