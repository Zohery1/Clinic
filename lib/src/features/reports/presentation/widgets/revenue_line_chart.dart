import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';

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
      return const _GhostGridWithEmptyState();
    }

    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    final rawMaxY = data.reduce((a, b) => a > b ? a : b);
    final rawMinY = data.reduce((a, b) => a < b ? a : b);

    final double paddedMax;
    final double paddedMin;
    if (rawMaxY <= 0) {
      paddedMax = 1000.0;
      paddedMin = 0.0;
    } else {
      final range = (rawMaxY - rawMinY) == 0 ? 1.0 : (rawMaxY - rawMinY);
      paddedMax = rawMaxY + range * 0.18;
      paddedMin = (rawMinY - range * 0.10).clamp(0.0, double.infinity);
    }

    final horizontalInterval = (paddedMax - paddedMin) / 4;
    final gridColor = AppColors.borderSubtle(context);
    final axisColor = AppColors.textMuted(context);

    return LineChart(
      LineChartData(
        minY: paddedMin,
        maxY: paddedMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
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
              interval: horizontalInterval,
              getTitlesWidget: (value, meta) {
                if (value <= 0 && paddedMin == 0) {
                  return const SizedBox.shrink();
                }
                final whole = value.roundToDouble();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _shortMoney(whole),
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
            isCurved: data.length > 1,
            curveSmoothness: 0.32,
            preventCurveOverShooting: true,
            barWidth: 2.5,
            color: AppColors.primary,
            dotData: FlDotData(show: data.length == 1),
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

  String _formatCurrency(double v) => '${v.toStringAsFixed(0)} ج.م';

  String _shortMoney(double v) {
    final intVal = v.round();
    final isNegative = intVal < 0;
    final absVal = intVal.abs();
    String res;
    if (absVal >= 1000000) {
      res = '${(absVal / 1000000).toStringAsFixed(1)}م';
    } else if (absVal >= 1000) {
      res = '${(absVal / 1000).toStringAsFixed(0)}ك';
    } else {
      res = absVal.toString();
    }
    return isNegative ? '-$res' : res;
  }
}

class _GhostGridWithEmptyState extends StatelessWidget {
  const _GhostGridWithEmptyState();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GhostGridPainter(
              color: AppColors.borderSubtle(context),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  size: 22,
                  color: AppColors.textMuted(context),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'لا توجد حركات إيرادات مسجلة لهذه الفترة',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GhostGridPainter extends CustomPainter {
  final Color color;
  const _GhostGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    const lines = 4;
    final interval = size.height / (lines + 1);

    for (int i = 1; i <= lines; i++) {
      final y = interval * i;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(math.min(startX + dashWidth, size.width), y),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GhostGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
