import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/app_theme.dart';
import 'reports_controller.dart';

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
  int _touchedPieIndex = -1;

  String get _rangeKey {
    final s = '${widget.startDate.year}-${widget.startDate.month.toString().padLeft(2, '0')}-${widget.startDate.day.toString().padLeft(2, '0')}';
    final e = '${widget.endDate.year}-${widget.endDate.month.toString().padLeft(2, '0')}-${widget.endDate.day.toString().padLeft(2, '0')}';
    return '${s}_$e';
  }

  String get _titleLabel {
    if (widget.isMonthly) {
      return intl.DateFormat('MMMM yyyy', 'ar').format(widget.startDate);
    }
    final dayName = intl.DateFormat('EEEE', 'ar').format(widget.startDate);
    final dayNum = intl.DateFormat('d MMMM yyyy', 'ar').format(widget.startDate);
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
              icon: Icon(Icons.refresh_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary),
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(detailedReportProvider(_rangeKey)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('خطأ في تحميل البيانات: $err',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          data: (report) {
            final appointmentsByType =
                (report['appointmentsByType'] as List).cast<Map<String, dynamic>>();
            final servicesByType =
                (report['servicesByType'] as List).cast<Map<String, dynamic>>();
            final totalAppRev = (report['totalAppointmentsRevenue'] as num).toDouble();
            final totalSvcRev = (report['totalServicesRevenue'] as num).toDouble();
            final totalRev = (report['totalRevenue'] as num).toDouble();
            final totalVisits = report['totalVisits'] as int;
            final newPatients = report['newPatientsCount'] as int;
            final oldPatients = report['oldPatientsCount'] as int;
            final cancelledAppointmentsCount = report['cancelledAppointmentsCount'] as int;
            final cancelledByPatientCount = report['cancelledByPatientCount'] as int? ?? 0;
            final previousRevenue = (report['previousRevenue'] as num?)?.toDouble() ?? 0.0;
            final comparisonLabel = report['comparisonLabel'] as String? ?? 'مقارنة بالفترة السابقة';
            final peakTimes = (report['peakTimes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

            final bool hasData = totalVisits > 0 || cancelledAppointmentsCount > 0 || cancelledByPatientCount > 0;

            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async =>
                  ref.invalidate(detailedReportProvider(_rangeKey)),
              child: ListView(
                padding: EdgeInsets.all(isDesktop ? 28 : 16),
                children: [
                  // ── بطاقات الملخص ──
                  _buildSummaryCards(
                    context,
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
                    _buildEmptyState(context)
                  else ...[
                    // ── أوقات الذروة ──
                    if (peakTimes.isNotEmpty) ...[
                      _buildPeakTimesChart(context, isDark, peakTimes),
                      const SizedBox(height: 20),
                    ],

                    // ── صف: Pie + بطاقة المرضى ──
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: _buildPieCard(
                                      context, isDark, totalAppRev, totalSvcRev, appointmentsByType, servicesByType)),
                              const SizedBox(width: 16),
                              Expanded(
                                  flex: 2,
                                  child: _buildPatientsCard(context, isDark, newPatients, oldPatients)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPieCard(
                                  context, isDark, totalAppRev, totalSvcRev, appointmentsByType, servicesByType),
                              const SizedBox(height: 16),
                              _buildPatientsCard(context, isDark, newPatients, oldPatients),
                            ],
                          ),

                    const SizedBox(height: 20),

                    // ── جداول الكشوفات والخدمات ──
                    if (isDesktop && appointmentsByType.isNotEmpty && servicesByType.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildBreakdownCard(
                              context,
                              isDark: isDark,
                              title: 'تفاصيل الكشوفات حسب النوع',
                              icon: Icons.medical_services_outlined,
                              accentColor: Theme.of(context).colorScheme.primary,
                              items: appointmentsByType,
                              totalRevenue: totalAppRev,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBreakdownCard(
                              context,
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
                      // ── جدول الكشوفات ──
                      if (appointmentsByType.isNotEmpty)
                        _buildBreakdownCard(
                          context,
                          isDark: isDark,
                          title: 'تفاصيل الكشوفات حسب النوع',
                          icon: Icons.medical_services_outlined,
                          accentColor: Theme.of(context).colorScheme.primary,
                          items: appointmentsByType,
                          totalRevenue: totalAppRev,
                        ),

                      if (appointmentsByType.isNotEmpty && servicesByType.isNotEmpty)
                        const SizedBox(height: 16),

                      // ── جدول الخدمات ──
                      if (servicesByType.isNotEmpty)
                        _buildBreakdownCard(
                          context,
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


  // ── بطاقات الملخص ──
  Widget _buildSummaryCards(
    BuildContext context, {
    required bool isDark,
    required bool isDesktop,
    required double totalRev,
    required double totalAppRev,
    required double totalSvcRev,
    required int totalVisits,
    required int newPatients,
    required int oldPatients,
    required int cancelledCount,
    required int cancelledByPatientCount,
    required double previousRevenue,
    required String comparisonLabel,
  }) {
    double revenueDiff = totalRev - previousRevenue;
    double revenuePct = previousRevenue == 0 ? (totalRev > 0 ? 100.0 : 0.0) : (revenueDiff / previousRevenue).abs() * 100;
    
    final shortLabel = comparisonLabel.replaceAll('مقارنة ', '');
    String trendText = '${revenuePct.toStringAsFixed(0)}% ($shortLabel)';
    bool trendIsPositive = revenueDiff >= 0;

    final cards = [
      _SummaryCardData(
        label: 'إجمالي الإيرادات',
        value: '${totalRev.toStringAsFixed(0)} ج.م',
        icon: Icons.account_balance_wallet_outlined,
        accentColor: Theme.of(context).colorScheme.primary,
        bgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        mono: true,
        trendText: trendText,
        trendIsPositive: trendIsPositive,
      ),
      _SummaryCardData(
        label: 'إيرادات الكشوفات',
        value: '${totalAppRev.toStringAsFixed(0)} ج.م',
        icon: Icons.medical_services_outlined,
        accentColor: AppColors.info,
        bgColor: isDark
            ? AppColors.infoSubtle
            : AppColors.infoSubtle,
        mono: true,
      ),
      _SummaryCardData(
        label: 'إيرادات الخدمات',
        value: '${totalSvcRev.toStringAsFixed(0)} ج.م',
        icon: Icons.build_outlined,
        accentColor: AppColors.success,
        bgColor: isDark
            ? AppColors.successSubtle
            : AppColors.successSubtle,
        mono: true,
      ),
      _SummaryCardData(
        label: 'إجمالي الزيارات',
        value: '$totalVisits زيارة',
        icon: Icons.people_alt_outlined,
        accentColor: AppColors.completed,
        bgColor: isDark
            ? AppColors.completedSubtle
            : AppColors.completedSubtle,
        mono: false,
      ),
      _SummaryCardData(
        label: 'إلغاء (من العيادة)',
        value: '$cancelledCount',
        icon: Icons.event_busy_outlined,
        accentColor: AppColors.danger,
        bgColor: isDark
            ? AppColors.dangerSubtle
            : AppColors.dangerSubtle,
        mono: false,
      ),
      _SummaryCardData(
        label: 'عدم حضور (مريض)',
        value: '$cancelledByPatientCount',
        icon: Icons.person_off_outlined,
        accentColor: AppColors.warning,
        bgColor: isDark
            ? AppColors.warningSubtle
            : AppColors.warningSubtle,
        mono: false,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSummaryCard(context, c),
                )))
            .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard(context, cards[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryCard(context, cards[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSummaryCard(context, cards[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryCard(context, cards[3])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSummaryCard(context, cards[4])),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryCard(context, cards[5])),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, _SummaryCardData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 14, color: data.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              data.value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: data.mono ? 'JetBrains Mono' : null,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          if (data.trendText != null && data.trendIsPositive != null) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (data.trendIsPositive! ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.trendIsPositive! ? Icons.arrow_upward : Icons.arrow_downward,
                      color: data.trendIsPositive! ? AppColors.success : AppColors.danger,
                      size: 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      data.trendText!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: data.trendIsPositive! ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Pie Chart ──
  Widget _buildPieCard(
    BuildContext context,
    bool isDark,
    double totalAppRev,
    double totalSvcRev,
    List<Map<String, dynamic>> appointmentsByType,
    List<Map<String, dynamic>> servicesByType,
  ) {
    final total = totalAppRev + totalSvcRev;
    final appPct = total > 0 ? (totalAppRev / total * 100) : 0.0;
    final svcPct = total > 0 ? (totalSvcRev / total * 100) : 0.0;

    final appColor = Theme.of(context).colorScheme.primary;
    const svcColor = AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: appColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pie_chart_outline_rounded, size: 16, color: appColor),
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
                    child: Text('لا توجد إيرادات',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor)),
                  ),
                )
              : Row(
                  children: [
                    // Pie
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
                                _touchedPieIndex =
                                    response.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: totalAppRev,
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
                              value: totalSvcRev,
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

                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            context,
                            color: appColor,
                            label: 'الكشوفات',
                            value: '${totalAppRev.toStringAsFixed(0)} ج.م',
                            pct: appPct,
                          ),
                          const SizedBox(height: 16),
                          _buildLegendItem(
                            context,
                            color: svcColor,
                            label: 'الخدمات',
                            value: '${totalSvcRev.toStringAsFixed(0)} ج.م',
                            pct: svcPct,
                          ),
                          const SizedBox(height: 16),
                          Divider(
                              height: 1,
                              color: Theme.of(context).dividerColor),
                          const SizedBox(height: 12),
                          Text(
                            'الإجمالي',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                              color: Theme.of(context).textTheme.titleLarge?.color,
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

  Widget _buildLegendItem(BuildContext context,
      {required Color color,
      required String label,
      required String value,
      required double pct}) {
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
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
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
                fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  // ── بطاقة المرضى ──
  Widget _buildPatientsCard(
      BuildContext context, bool isDark, int newPts, int oldPts) {
    final total = newPts + oldPts;
    const newColor = AppColors.success;
    const oldColor = AppColors.info;

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
                  color: newColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_alt_outlined, size: 16, color: newColor),
              ),
              const SizedBox(width: 10),
              Text(
                'المرضى',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // بطاقتا المرضى الجدد والقدامى
          Row(
            children: [
              Expanded(child: _buildPatientCountCard(context, 'مرضى جدد', newPts, newColor, Icons.fiber_new_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _buildPatientCountCard(context, 'مرضى قدامى', oldPts, oldColor, Icons.person_outlined)),
            ],
          ),

          const SizedBox(height: 16),

          // شريط النسبة
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: newPts / total,
                backgroundColor: oldColor.withValues(alpha: 0.25),
                color: newColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جدد: ${total > 0 ? (newPts / total * 100).toStringAsFixed(0) : 0}%',
                  style: const TextStyle(fontSize: 10, color: newColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  'قدامى: ${total > 0 ? (oldPts / total * 100).toStringAsFixed(0) : 0}%',
                  style: const TextStyle(fontSize: 10, color: oldColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientCountCard(BuildContext context, String label, int count,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  // ── جدول تفصيلي (كشوفات أو خدمات) ──
  Widget _buildBreakdownCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Map<String, dynamic>> items,
    required double totalRevenue,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عنوان
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${totalRevenue.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // ترويسة الجدول
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('النوع',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('العدد',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 3,
                  child: Text('التكلفة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text('النسبة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // صفوف البيانات
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final name = item['name'] as String;
              final count = item['count'] as int;
              final cost = (item['totalCost'] as num).toDouble();
              final pct = totalRevenue > 0 ? (cost / totalRevenue * 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${cost.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                              color: accentColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // شريط التقدم
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: totalRevenue > 0 ? (cost / totalRevenue) : 0,
                        backgroundColor: accentColor.withValues(alpha: 0.10),
                        color: accentColor,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildPeakTimesChart(BuildContext context, bool isDark, List<Map<String, dynamic>> peakTimes) {
    if (peakTimes.isEmpty) return const SizedBox.shrink();

    // Take top 7 peak times to avoid overcrowding
    final displayTimes = peakTimes.take(7).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                widget.isMonthly ? 'أكثر الأيام ازدحاماً (أوقات الذروة)' : 'أكثر الساعات ازدحاماً (أوقات الذروة)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: displayTimes.map((e) => (e['count'] as int).toDouble()).reduce((a, b) => a > b ? a : b) + 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => isDark ? Colors.grey[800]! : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${displayTimes[group.x.toInt()]['label']}\n',
                        TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${rod.toY.toInt()} زيارة',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < displayTimes.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayTimes[value.toInt()]['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black12,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  displayTimes.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (displayTimes[index]['count'] as int).toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── حالة فارغة ──
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.insert_chart_outlined_rounded,
                size: 48, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد بيانات مسجلة',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 6),
          Text(
            'لم يتم تسجيل أي زيارات مكتملة في هذه الفترة',
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// بيانات بطاقة الملخص
class _SummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final bool mono;
  final String? trendText;
  final bool? trendIsPositive;

  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.mono,
    this.trendText,
    this.trendIsPositive,
  });
}



