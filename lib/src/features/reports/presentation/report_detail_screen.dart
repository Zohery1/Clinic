import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/ui/tokens/colors.dart';
import 'reports_controller.dart';
import 'widgets/report_breakdown_card.dart';
import 'widgets/report_empty_state.dart';
import 'widgets/report_patients_card.dart';
import 'widgets/report_peak_times_chart.dart';
import 'widgets/report_pie_card.dart';
import 'widgets/report_summary_cards.dart';

/// صفحة التقرير التفصيلي — يوم أو فترة زمنية محددة
class ReportDetailScreen extends ConsumerStatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool isMonthly;

  const ReportDetailScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    this.isMonthly = false,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  String get _rangeKey {
    final s =
        '${widget.startDate.year}-${widget.startDate.month.toString().padLeft(2, '0')}-${widget.startDate.day.toString().padLeft(2, '0')}';
    final e =
        '${widget.endDate.year}-${widget.endDate.month.toString().padLeft(2, '0')}-${widget.endDate.day.toString().padLeft(2, '0')}';
    return '${s}_$e';
  }

  String get _titleLabel {
    if (widget.isMonthly) {
      return intl.DateFormat('MMMM yyyy', 'ar').format(widget.startDate);
    }
    final dayName = intl.DateFormat('EEEE', 'ar').format(widget.startDate);
    final dayNum =
        intl.DateFormat('d MMMM yyyy', 'ar').format(widget.startDate);
    return '$dayName — $dayNum';
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(detailedReportProvider(_rangeKey));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: BackButton(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تقرير تفصيلي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              Text(
                _titleLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(detailedReportProvider(_rangeKey)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'تعذر تحميل بيانات التقرير، يرجى إعادة المحاولة',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
          data: (report) {
            final appointmentsByType = (report['appointmentsByType'] as List)
                .cast<Map<String, dynamic>>();
            final servicesByType =
                (report['servicesByType'] as List).cast<Map<String, dynamic>>();
            final totalAppRev =
                (report['totalAppointmentsRevenue'] as num).toDouble();
            final totalSvcRev =
                (report['totalServicesRevenue'] as num).toDouble();
            final totalRev = (report['totalRevenue'] as num).toDouble();
            final totalVisits = report['totalVisits'] as int;
            final newPatients = report['newPatientsCount'] as int;
            final oldPatients = report['oldPatientsCount'] as int;
            final cancelledAppointmentsCount =
                report['cancelledAppointmentsCount'] as int;
            final cancelledByPatientCount =
                report['cancelledByPatientCount'] as int? ?? 0;
            final previousRevenue =
                (report['previousRevenue'] as num?)?.toDouble() ?? 0.0;
            final comparisonLabel =
                report['comparisonLabel'] as String? ?? 'مقارنة بالفترة السابقة';
            final peakTimes =
                (report['peakTimes'] as List?)?.cast<Map<String, dynamic>>() ??
                    [];

            final bool hasData = totalVisits > 0 ||
                cancelledAppointmentsCount > 0 ||
                cancelledByPatientCount > 0;

            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async =>
                  ref.invalidate(detailedReportProvider(_rangeKey)),
              child: ListView(
                padding: EdgeInsets.all(isDesktop ? 28 : 16),
                children: [
                  ReportSummaryCards(
                    isDark: isDark,
                    isDesktop: isDesktop,
                    totalRev: totalRev,
                    totalAppRev: totalAppRev,
                    totalSvcRev: totalSvcRev,
                    totalVisits: totalVisits,
                    newPatients: newPatients,
                    oldPatients: oldPatients,
                    cancelledCount: cancelledAppointmentsCount,
                    cancelledByPatientCount: cancelledByPatientCount,
                    previousRevenue: previousRevenue,
                    comparisonLabel: comparisonLabel,
                  ),
                  const SizedBox(height: 20),
                  if (!hasData)
                    const ReportEmptyState()
                  else ...[
                    if (peakTimes.isNotEmpty) ...[
                      ReportPeakTimesChart(
                        isDark: isDark,
                        isMonthly: widget.isMonthly,
                        peakTimes: peakTimes,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ReportPieCard(
                              isDark: isDark,
                              totalAppRev: totalAppRev,
                              totalSvcRev: totalSvcRev,
                              appointmentsByType: appointmentsByType,
                              servicesByType: servicesByType,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ReportPatientsCard(
                              isDark: isDark,
                              newPatients: newPatients,
                              oldPatients: oldPatients,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      ReportPieCard(
                        isDark: isDark,
                        totalAppRev: totalAppRev,
                        totalSvcRev: totalSvcRev,
                        appointmentsByType: appointmentsByType,
                        servicesByType: servicesByType,
                      ),
                      const SizedBox(height: 16),
                      ReportPatientsCard(
                        isDark: isDark,
                        newPatients: newPatients,
                        oldPatients: oldPatients,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (isDesktop &&
                        appointmentsByType.isNotEmpty &&
                        servicesByType.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ReportBreakdownCard(
                              isDark: isDark,
                              title: 'تفاصيل الكشوفات حسب النوع',
                              icon: Icons.medical_services_outlined,
                              accentColor:
                                  Theme.of(context).colorScheme.primary,
                              items: appointmentsByType,
                              totalRevenue: totalAppRev,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ReportBreakdownCard(
                              isDark: isDark,
                              title: 'تفاصيل الخدمات المقدمة',
                              icon: Icons.build_outlined,
                              accentColor: AppColors.success,
                              items: servicesByType,
                              totalRevenue: totalSvcRev,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      if (appointmentsByType.isNotEmpty)
                        ReportBreakdownCard(
                          isDark: isDark,
                          title: 'تفاصيل الكشوفات حسب النوع',
                          icon: Icons.medical_services_outlined,
                          accentColor: Theme.of(context).colorScheme.primary,
                          items: appointmentsByType,
                          totalRevenue: totalAppRev,
                        ),
                      if (appointmentsByType.isNotEmpty &&
                          servicesByType.isNotEmpty)
                        const SizedBox(height: 16),
                      if (servicesByType.isNotEmpty)
                        ReportBreakdownCard(
                          isDark: isDark,
                          title: 'تفاصيل الخدمات المقدمة',
                          icon: Icons.build_outlined,
                          accentColor: AppColors.success,
                          items: servicesByType,
                          totalRevenue: totalSvcRev,
                        ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
