import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/tokens/colors.dart';

class RevenueLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;

  const RevenueLineChart({
    super.key,
    required this.data,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.length != labels.length) {
      return Center(
        child: Text(
          '?? ???? ??????',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textMuted(context),
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    final maxY = data.reduce((a, b) => a > b ? a : b);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final range = (maxY - minY) == 0 ? 1.0 : (maxY - minY);
    final paddedMax = maxY + range * 0.18;
    final paddedMin = (minY - range * 0.10).clamp(0.0, double.infinity);

    final gridColor = AppColors.borderSubtle(context);
    final axisColor = AppColors.textMuted(context);

    return LineChart(
      LineChartData(
        minY: paddedMin,
        maxY: paddedMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (paddedMax - paddedMin) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (data.length / 5).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                final raw = labels[idx];
                DateTime? dt = DateTime.tryParse(raw);
                String text = raw;
                if (dt != null) {
                  text = intl.DateFormat('d MMM', 'ar').format(dt);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    text,
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: axisColor,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: (paddedMax - paddedMin) / 4,
              getTitlesWidget: (value, meta) {
                if (value <= 0 && paddedMin == 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _shortMoney(value),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: axisColor,
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
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.elevated(context),
            tooltipBorder: BorderSide(
              color: AppColors.borderSubtle(context),
              width: 1,
            ),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touched) {
              return touched.map((spot) {
                final idx = spot.x.toInt();
                String label = '';
                if (idx >= 0 && idx < labels.length) {
                  final dt = DateTime.tryParse(labels[idx]);
                  if (dt != null) {
                    label = intl.DateFormat('EEEE d MMM', 'ar').format(dt);
                  } else {
                    label = labels[idx];
                  }
                }
                return LineTooltipItem(
                  '$label\n${_formatCurrency(spot.y)}',
                  GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                    height: 1.4,
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
            preventCurveOverShooting: true,
            barWidth: 2.5,
            color: AppColors.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double v) => '${v.toStringAsFixed(0)} ?.?';

  String _shortMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}?';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}?';
    return v.toStringAsFixed(0);
  }
}