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

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final radius = (size / 2) * 0.45;
        final centerSpace = (size / 2) * 0.48;

        if (total == 0) {
          return Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: centerSpace,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: 1,
                      color: AppColors.borderSubtle(context),
                      radius: radius,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '0 مواعيد',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted(context),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لا توجد مواعيد',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: centerSpace,
                startDegreeOffset: -90,
                sections: [
                  for (final e in entries)
                    PieChartSectionData(
                      value: e.value,
                      color: _colorFor(e.key),
                      radius: radius,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'إجمالي المواعيد',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _colorFor(String key) {
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
        return const Color(0xFF94A3B8);
    }
  }
}
