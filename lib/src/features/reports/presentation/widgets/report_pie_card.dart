import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// بطاقة نسبة توزيع الإيرادات بين الكشوفات والخدمات
class ReportPieCard extends StatefulWidget {
  final bool isDark;
  final double totalAppRev;
  final double totalSvcRev;
  final List<Map<String, dynamic>> appointmentsByType;
  final List<Map<String, dynamic>> servicesByType;

  const ReportPieCard({
    super.key,
    required this.isDark,
    required this.totalAppRev,
    required this.totalSvcRev,
    required this.appointmentsByType,
    required this.servicesByType,
  });

  @override
  State<ReportPieCard> createState() => _ReportPieCardState();
}

class _ReportPieCardState extends State<ReportPieCard> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.totalAppRev + widget.totalSvcRev;
    final appPct = total > 0 ? (widget.totalAppRev / total * 100) : 0.0;
    final svcPct = total > 0 ? (widget.totalSvcRev / total * 100) : 0.0;

    final appColor = Theme.of(context).colorScheme.primary;
    const svcColor = AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: appColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pie_chart_outline_rounded,
                    size: 16, color: appColor),
              ),
              const SizedBox(width: 10),
              Text(
                'نسبة الإيرادات',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          total == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'لا توجد إيرادات',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = response
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: widget.totalAppRev,
                              color: appColor,
                              title: '${appPct.toStringAsFixed(0)}%',
                              radius: _touchedPieIndex == 0 ? 55 : 48,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: widget.totalSvcRev,
                              color: svcColor,
                              title: '${svcPct.toStringAsFixed(0)}%',
                              radius: _touchedPieIndex == 1 ? 55 : 48,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            context,
                            color: appColor,
                            label: 'الكشوفات',
                            value:
                                '${widget.totalAppRev.toStringAsFixed(0)} ج.م',
                            pct: appPct,
                          ),
                          const SizedBox(height: 16),
                          _buildLegendItem(
                            context,
                            color: svcColor,
                            label: 'الخدمات',
                            value:
                                '${widget.totalSvcRev.toStringAsFixed(0)} ج.م',
                            pct: svcPct,
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'الإجمالي',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
    required double pct,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrains Mono',
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
