import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/tokens/colors.dart';

class StatusDonutChart extends StatelessWidget {
  final Map<String, double> data;

  const StatusDonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.where((e) => e.value > 0).toList();
    final total = entries.fold<double>(0.0, (s, e) => s + e.value);
    final isDark = AppColors.isDark(context);

    if (total == 0) {
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

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 56,
            startDegreeOffset: -90,
            sections: [
              for (final e in entries)
                PieChartSectionData(
                  value: e.value,
                  color: _colorFor(e.key, isDark),
                  radius: 28,
                  showTitle: false,
                ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              total.toStringAsFixed(0),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '????',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted(context),
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _colorFor(String key, bool isDark) {
    switch (key) {
      case 'waiting':
        return AppColors.warning;
      case 'with_doctor':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }
}