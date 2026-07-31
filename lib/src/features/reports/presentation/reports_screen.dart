import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/login_controller.dart';
import 'reports_controller.dart';
import 'report_detail_screen.dart';
import '../../../core/widgets/clinic_dialog.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedSubTab = 0; // 0 for daily logs, 1 for monthly logs

  // Default date range: last 90 days
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 89));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _calculateTrend(double current, double previous) {
    if (previous == 0) return 'مستقر (لا توجد بيانات سابقة)';
    final percent = ((current - previous) / previous) * 100;
    final prefix = percent >= 0 ? '+' : '';
    return '$prefix${percent.toStringAsFixed(1)}% مقارنة بالفترة السابقة';
  }

  String get _rangeParamString {
    final startStr = "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final endStr = "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";
    return "${startStr}_$endStr";
  }

  bool get _isFiltered {
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 89));
    final currentStart = DateTime(_startDate.year, _startDate.month, _startDate.day);
    return (currentStart.difference(defaultStart).inDays).abs() > 1;
  }

  void _resetToDefault() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 89));
      _endDate = DateTime.now();
    });
  }

  void _selectDateRange() async {
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final years = [2025, 2026, 2027];

    showDialog(
      context: context,
      builder: (context) {
        int filterTypeIndex = 0; // 0 for Days, 1 for Months
        int subTypeIndex = 0;    // 0 for Single, 1 for Range
        DateTime localSingleDay = DateTime.now();
        DateTime localRangeStart = _startDate;
        DateTime localRangeEnd = _endDate;

        int localSingleMonth = DateTime.now().month;
        int localSingleYear = DateTime.now().year;

        int localStartMonth = DateTime.now().month;
        int localStartYear = DateTime.now().year;
        int localEndMonth = DateTime.now().month;
        int localEndYear = DateTime.now().year;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textCol = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF1E293B));
            final textSecCol = Theme.of(context).textTheme.bodySmall?.color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
            final containerBgSelected = isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : AppTheme.primaryLight;
            final containerBgUnselected = isDark ? Theme.of(context).scaffoldBackgroundColor : AppTheme.surfaceDim;
            final borderCol = Theme.of(context).dividerColor;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: ClinicDialog(
                icon: Icons.date_range_rounded,
                title: 'تصفية الفترة الزمنية',
                subtitle: 'اختر يوماً محدداً أو نطاقاً زمنياً لتصفية التقارير',
                maxWidth: 400,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick Presets
                    Text(
                      'خيارات سريعة للتصفية:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecCol),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPresetChip(
                          label: 'اليوم',
                          isDark: isDark,
                          borderCol: borderCol,
                          onTap: () {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
                            final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                            setState(() {
                              _startDate = start;
                              _endDate = end;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildPresetChip(
                          label: 'أمس',
                          isDark: isDark,
                          borderCol: borderCol,
                          onTap: () {
                            final now = DateTime.now();
                            final yesterday = now.subtract(const Duration(days: 1));
                            final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
                            final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
                            setState(() {
                              _startDate = start;
                              _endDate = end;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildPresetChip(
                          label: 'آخر 7 أيام',
                          isDark: isDark,
                          borderCol: borderCol,
                          onTap: () {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
                            final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                            setState(() {
                              _startDate = start;
                              _endDate = end;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildPresetChip(
                          label: 'آخر 30 يوم',
                          isDark: isDark,
                          borderCol: borderCol,
                          onTap: () {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
                            final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                            setState(() {
                              _startDate = start;
                              _endDate = end;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildPresetChip(
                          label: 'هذا الشهر',
                          isDark: isDark,
                          borderCol: borderCol,
                          onTap: () {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, 1);
                            final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                            setState(() {
                              _startDate = start;
                              _endDate = end;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        _buildPresetChip(
                          label: 'الشهر السابق',
                          isDark: isDark,
                          borderCol: borderCol,
                          onTap: () {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month - 1, 1);
                            final end = DateTime(now.year, now.month, 0, 23, 59, 59);
                            setState(() {
                              _startDate = start;
                              _endDate = end;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 8),
                    const SizedBox(height: 12),
                    // Segmented Toggle Days/Months
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() {
                              filterTypeIndex = 0;
                              subTypeIndex = 0;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: filterTypeIndex == 0 ? containerBgSelected : containerBgUnselected,
                                borderRadius: BorderRadius.circular(8),
                                // removed border
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'أيام',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: filterTypeIndex == 0 ? Theme.of(context).colorScheme.primary : textSecCol,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() {
                              filterTypeIndex = 1;
                              subTypeIndex = 0;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: filterTypeIndex == 1 ? containerBgSelected : containerBgUnselected,
                                borderRadius: BorderRadius.circular(8),
                                // removed border
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'شهور',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: filterTypeIndex == 1 ? Theme.of(context).colorScheme.primary : textSecCol,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Radio Single vs Range
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: Text(
                              filterTypeIndex == 0 ? 'يوم واحد فقط' : 'شهر واحد فقط',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                            ),
                            value: 0,
                            groupValue: subTypeIndex,
                            onChanged: (val) => setDialogState(() => subTypeIndex = val!),
                            contentPadding: EdgeInsets.zero,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: Text(
                              filterTypeIndex == 0 ? 'مجموعة أيام' : 'مجموعة شهور',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                            ),
                            value: 1,
                            groupValue: subTypeIndex,
                            onChanged: (val) => setDialogState(() => subTypeIndex = val!),
                            contentPadding: EdgeInsets.zero,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pickers Area
                    if (filterTypeIndex == 0) ...[
                      // Days
                      if (subTypeIndex == 0) ...[
                        // Single Day
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: localSingleDay,
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => localSingleDay = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              // removed border
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  intl.DateFormat('d MMMM yyyy', 'ar').format(localSingleDay),
                                  style: TextStyle(fontSize: 13, color: textCol),
                                ),
                                Icon(Icons.calendar_month_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Range of Days
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now(),
                              initialDateRange: DateTimeRange(start: localRangeStart, end: localRangeEnd),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                localRangeStart = picked.start;
                                localRangeEnd = picked.end;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              // removed border
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${intl.DateFormat('d MMM', 'ar').format(localRangeStart)} - ${intl.DateFormat('d MMM yyyy', 'ar').format(localRangeEnd)}",
                                  style: TextStyle(fontSize: 13, color: textCol),
                                ),
                                Icon(Icons.date_range_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ]
                    ] else ...[
                      // Months
                      if (subTypeIndex == 0) ...[
                        // Single Month
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: localSingleMonth,
                                style: TextStyle(color: textCol, fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'الشهر',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: List.generate(
                                  12,
                                  (i) => DropdownMenuItem(value: i + 1, child: Text(monthsAr[i], style: TextStyle(fontSize: 12, color: textCol))),
                                ),
                                onChanged: (val) => setDialogState(() => localSingleMonth = val!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: localSingleYear,
                                style: TextStyle(color: textCol, fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'السنة',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: years.map(
                                  (y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: TextStyle(fontSize: 12, color: textCol))),
                                ).toList(),
                                onChanged: (val) => setDialogState(() => localSingleYear = val!),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Range of Months
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: localStartMonth,
                                    style: TextStyle(color: textCol, fontSize: 14),
                                    decoration: const InputDecoration(
                                      labelText: 'من شهر',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    items: List.generate(
                                      12,
                                      (i) => DropdownMenuItem(value: i + 1, child: Text(monthsAr[i], style: TextStyle(fontSize: 12, color: textCol))),
                                    ),
                                    onChanged: (val) => setDialogState(() => localStartMonth = val!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: localStartYear,
                                    style: TextStyle(color: textCol, fontSize: 14),
                                    decoration: const InputDecoration(
                                      labelText: 'السنة',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    items: years.map(
                                      (y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: TextStyle(fontSize: 12, color: textCol))),
                                    ).toList(),
                                    onChanged: (val) => setDialogState(() => localStartYear = val!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: localEndMonth,
                                    style: TextStyle(color: textCol, fontSize: 14),
                                    decoration: const InputDecoration(
                                      labelText: 'إلى شهر',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    items: List.generate(
                                      12,
                                      (i) => DropdownMenuItem(value: i + 1, child: Text(monthsAr[i], style: TextStyle(fontSize: 12, color: textCol))),
                                    ),
                                    onChanged: (val) => setDialogState(() => localEndMonth = val!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: localEndYear,
                                    style: TextStyle(color: textCol, fontSize: 14),
                                    decoration: const InputDecoration(
                                      labelText: 'السنة',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    items: years.map(
                                      (y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: TextStyle(fontSize: 12, color: textCol))),
                                    ).toList(),
                                    onChanged: (val) => setDialogState(() => localEndYear = val!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ]
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      DateTime finalStart;
                      DateTime finalEnd;

                      if (filterTypeIndex == 0) {
                        // Days
                        if (subTypeIndex == 0) {
                          finalStart = localSingleDay;
                          finalEnd = localSingleDay;
                        } else {
                          finalStart = localRangeStart;
                          finalEnd = localRangeEnd;
                        }
                      } else {
                        // Months
                        if (subTypeIndex == 0) {
                          finalStart = DateTime(localSingleYear, localSingleMonth, 1);
                          finalEnd = DateTime(localSingleYear, localSingleMonth + 1, 0);
                        } else {
                          finalStart = DateTime(localStartYear, localStartMonth, 1);
                          finalEnd = DateTime(localEndYear, localEndMonth + 1, 0);
                        }
                      }

                      setState(() {
                        _startDate = finalStart;
                        _endDate = finalEnd;
                      });

                      Navigator.pop(context);
                    },
                    child: const Text('تطبيق التصفية'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isDark,
    required Color borderCol,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          // removed border
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final monthRevenueAsync = ref.watch(monthRevenueProvider);
    final weeklyRevenueAsync = ref.watch(weeklyRevenueProvider);
    final sixWeeksRevenueAsync = ref.watch(sixWeeksRevenueProvider);

    final dailyStatsAsync = user != null
        ? ref.watch(dailyStatsProvider(_rangeParamString))
        : const AsyncValue<List<Map<String, dynamic>>>.loading();
    final monthlyStatsAsync = user != null
        ? ref.watch(monthlyStatsProvider)
        : const AsyncValue<List<Map<String, dynamic>>>.loading();

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (user == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Text('يرجى تسجيل الدخول أولاً',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isDesktop
          ? Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: _buildFinancialAnalyticsTab(
                todayRevenueAsync,
                monthRevenueAsync,
                weeklyRevenueAsync,
                sixWeeksRevenueAsync,
                dailyStatsAsync,
                monthlyStatsAsync,
              ),
            )
          : Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: const Text('التقارير المالية والتحليلات'),
              ),
              body: _buildFinancialAnalyticsTab(
                todayRevenueAsync,
                monthRevenueAsync,
                weeklyRevenueAsync,
                sixWeeksRevenueAsync,
                dailyStatsAsync,
                monthlyStatsAsync,
              ),
            ),
    );
  }

  // تبويب التحليلات المالية
  Widget _buildFinancialAnalyticsTab(
    AsyncValue<double> todayRevenueAsync,
    AsyncValue<double> monthRevenueAsync,
    AsyncValue<List<Map<String, dynamic>>> weeklyRevenueAsync,
    AsyncValue<List<double>> sixWeeksRevenueAsync,
    AsyncValue<List<Map<String, dynamic>>> dailyStatsAsync,
    AsyncValue<List<Map<String, dynamic>>> monthlyStatsAsync,
  ) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {
        ref.invalidate(todayRevenueProvider);
        ref.invalidate(monthRevenueProvider);
        ref.invalidate(weeklyRevenueProvider);
        ref.invalidate(sixWeeksRevenueProvider);
        ref.invalidate(dailyStatsProvider);
        ref.invalidate(monthlyStatsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (MediaQuery.of(context).size.width < 900) ...[
            // عنوان وتفاصيل
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التقارير المالية والتحليلات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                ),
                const SizedBox(height: 2),
                Text(
                  'عرض ملخص الأداء المالي والزيارات بشكل تفصيلي',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // بطاقات الدخل المتجاورة الثلاثة (Stitch Design)
          LayoutBuilder(
            builder: (context, constraints) {
              final useVertical = constraints.maxWidth < 600;

              // Today's Trend & Points
              final dailyData = dailyStatsAsync.value ?? [];
              final activeDailyData = dailyData.where((d) => (d['revenue'] as num).toDouble() > 0).toList();
              final todayRevenue = todayRevenueAsync.value ?? 0.0;
              final yesterdayRevenue = activeDailyData.length > 1 ? (activeDailyData[1]['revenue'] as num).toDouble() : 0.0;
              final dailyTrend = _calculateTrend(todayRevenue, yesterdayRevenue);
              final dailyPoints = _getDailyPoints(dailyData, todayRevenue);

              final cardToday = _buildStitchRevenueCard(
                'إيرادات اليوم',
                todayRevenue,
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                Icons.payments_outlined,
                trendLabel: dailyTrend,
                isSuccessTrend: todayRevenue >= yesterdayRevenue,
                sparklinePoints: dailyPoints,
              );

              // Weekly Trend & Points (Chronological weeks grouped for last 6 weeks)
              final weeklyData = weeklyRevenueAsync.value ?? [];
              final weeklyTotal = weeklyData.fold<double>(0.0, (sum, item) => sum + (item['revenue'] as num).toDouble());
              // Sparkline requires a List<double>. If sixWeeksRevenue is loading, provide 0-filled list.
              final sixWeeksPoints = sixWeeksRevenueAsync.value ?? List.filled(6, 0.0);

              final cardWeek = _buildStitchRevenueCard(
                'إيرادات الأسبوع',
                weeklyTotal,
                const Color(0xFF8B5CF6),
                Theme.of(context).brightness == Brightness.dark ? const Color(0xFF8B5CF6).withOpacity(0.12) : const Color(0xFFF3E8FF),
                Icons.date_range_outlined,
                trendLabel: 'نشاط الإيرادات لآخر 6 أسابيع',
                isSuccessTrend: true,
                sparklinePoints: sixWeeksPoints,
              );

              // Monthly Trend & Points (Target-free comparison with past months)
              final monthlyData = monthlyStatsAsync.value ?? [];
              final activeMonthlyData = monthlyData.where((m) => (m['revenue'] as num).toDouble() > 0).toList();
              final thisMonthRevenue = monthRevenueAsync.value ?? 0.0;
              final lastMonthRevenue = activeMonthlyData.length > 1 ? (activeMonthlyData[1]['revenue'] as num).toDouble() : 0.0;
              final monthlyTrend = _calculateTrend(thisMonthRevenue, lastMonthRevenue);
              final monthlyPoints = _getMonthlyPoints(monthlyData, thisMonthRevenue);

              final cardMonth = _buildStitchRevenueCard(
                'إيرادات الشهر',
                thisMonthRevenue,
                Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF34D399).withOpacity(0.12)
                    : const Color(0xFFECFDF5),
                Icons.account_balance_wallet_outlined,
                trendLabel: monthlyTrend,
                isSuccessTrend: thisMonthRevenue >= lastMonthRevenue,
                sparklinePoints: monthlyPoints,
              );

              if (useVertical) {
                return Column(
                  children: [
                    cardToday,
                    const SizedBox(height: 12),
                    cardWeek,
                    const SizedBox(height: 12),
                    cardMonth,
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: cardToday),
                    const SizedBox(width: 12),
                    Expanded(child: cardWeek),
                    const SizedBox(width: 12),
                    Expanded(child: cardMonth),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // الجدول وسجلات التقارير (Stitch Design)
          Container(
            decoration: AppTheme.cardDecorationFlat(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط التصفح والتحكم
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final isMobile = c.maxWidth < 650;

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: _buildSubTabButton('سجل الأيام', 0)),
                                  Expanded(child: _buildSubTabButton('سجل الشهور', 1)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (_isFiltered) ...[
                                  Expanded(
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                      icon: const Icon(Icons.history_rounded, size: 14),
                                      label: const Text('الافتراضي', style: TextStyle(fontSize: 11)),
                                      onPressed: _resetToDefault,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: BorderSide.none,
                                    ),
                                    icon: Icon(Icons.calendar_month_rounded, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                                    label: Text('أيام مخصصة', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                                    onPressed: _selectDateRange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.download_rounded, size: 14),
                                    label: const Text('تصدير', style: TextStyle(fontSize: 11)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                                        const SnackBar(duration: const Duration(seconds: 2), content: Text('جاري تصدير الملف بصيغة PDF...')),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSubTabButton('سجل الأيام التفصيلي', 0),
                                _buildSubTabButton('سجل الشهور التراكمي', 1),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (_isFiltered) ...[
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                  icon: const Icon(Icons.history_rounded, size: 14),
                                  label: const Text('الافتراضي', style: TextStyle(fontSize: 11)),
                                  onPressed: _resetToDefault,
                                ),
                                const SizedBox(width: 8),
                              ],
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  side: BorderSide.none,
                                ),
                                icon: Icon(Icons.calendar_month_rounded, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                                label: Text('عرض أيام مخصصة', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                                onPressed: _selectDateRange,
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.download_rounded, size: 14),
                                label: const Text('تصدير التقرير', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                                    const SnackBar(duration: const Duration(seconds: 2), content: Text('جاري تصدير الملف بصيغة PDF...')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // البيانات وجدول السجلات
                _selectedSubTab == 0
                    ? _buildDailyTableView(dailyStatsAsync)
                    : _buildMonthlyTableView(monthlyStatsAsync),

                // الترقيم في تذييل الجدول
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Builder(
                    builder: (context) {
                      final dailyLogs = dailyStatsAsync.value ?? [];
                      final filteredDaily = dailyLogs;
                      final monthlyLogs = monthlyStatsAsync.value ?? [];
                      final filteredMonthly = monthlyLogs;
                      
                      final totalItems = _selectedSubTab == 0 
                          ? filteredDaily.length
                          : filteredMonthly.length;
                      
                      final displayCount = totalItems > 15 ? 15 : totalItems;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'عرض $displayCount سجل من أصل $totalItems سجل نشط',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Text(
                            'الحد الأقصى: 15 سجل',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  List<double> _getDailyPoints(List<Map<String, dynamic>> dailyData, double todayRevenue) {
    final now = DateTime.now();
    final Map<String, double> revenueMap = {};
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      revenueMap[dateStr] = 0.0;
    }
    for (final d in dailyData) {
      final dateStr = d['date'] as String;
      if (revenueMap.containsKey(dateStr)) {
        revenueMap[dateStr] = (d['revenue'] as num).toDouble();
      }
    }
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    revenueMap[todayStr] = todayRevenue;

    final sortedKeys = revenueMap.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((k) => revenueMap[k]!).toList();
  }


  List<double> _getMonthlyPoints(List<Map<String, dynamic>> monthlyData, double thisMonthRevenue) {
    final now = DateTime.now();
    final Map<String, double> revenueMap = {};
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      revenueMap[monthStr] = 0.0;
    }
    for (final m in monthlyData) {
      final monthStr = m['month'] as String;
      if (revenueMap.containsKey(monthStr)) {
        revenueMap[monthStr] = (m['revenue'] as num).toDouble();
      }
    }
    final thisMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    revenueMap[thisMonthStr] = thisMonthRevenue;

    final sortedKeys = revenueMap.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((k) => revenueMap[k]!).toList();
  }

  // بطاقة الدخل البصرية الممتازة (Stitch Design)
  Widget _buildStitchRevenueCard(
    String label,
    double amount,
    Color accentColor,
    Color bgColor,
    IconData icon, {
    String? trendLabel,
    bool isSuccessTrend = true,
    List<double>? sparklinePoints,
    List<double>? barHeights,
    double? progressValue,
    String? progressTarget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${amount.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
            ],
          ),

          // الرسم التوضيحي داخل الكارت
          if (sparklinePoints != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: CustomPaint(
                painter: _SparklinePainter(sparklinePoints, accentColor),
                child: Container(),
              ),
            ),
          ] else if (barHeights != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                // RTL: reverse list so newest bar appears on the right
                children: List.generate(barHeights.length, (idx) {
                  final reversedIdx = barHeights.length - 1 - idx;
                  final h = barHeights[reversedIdx];
                  final frac = reversedIdx / (barHeights.length - 1);
                  final barColor = accentColor.withOpacity(0.2 + frac * 0.8);
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      height: (h * 3.5).clamp(3.0, 36.0),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ] else if (progressValue != null) ...[
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue.clamp(0.0, 1.0),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
                    color: accentColor,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(progressTarget ?? '', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                    Text('${(progressValue * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                  ],
                ),
              ],
            ),
          ],

          if (trendLabel != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isSuccessTrend ? Icons.trending_up_rounded : Icons.info_outline_rounded,
                  size: 13,
                  color: isSuccessTrend
                      ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981))
                      : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 4),
                Text(
                  trendLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSuccessTrend
                        ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981))
                        : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, int index) {
    final isSelected = _selectedSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  // جدول سجلات الأيام التفصيلي
  Widget _buildDailyTableView(AsyncValue<List<Map<String, dynamic>>> dailyStatsAsync) {
    return dailyStatsAsync.when(
      data: (logs) {
        final filteredLogs = logs;
        final finalItems = filteredLogs.take(15).toList();

        if (finalItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bar_chart_rounded, size: 40, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد سجلات مالية مسجلة بعد',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        final isMobile = MediaQuery.of(context).size.width < 900;

        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: finalItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final log = finalItems[index];
              final date = DateTime.parse(log['date'] as String);
              final dayName = intl.DateFormat('EEEE', 'ar').format(date);
              final dayNum = intl.DateFormat('d MMMM yyyy', 'ar').format(date);
              final revenue = (log['revenue'] as num).toDouble();
              final visits = log['visits'] as int;
              
              final today = DateTime.now();
              final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(
                      startDate: date,
                      endDate: date,
                      isMonthly: false,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    '$dayName - $dayNum',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  subtitle: Text(
                    isToday ? '$visits كشف • نشط اليوم' : '$visits كشف',
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday 
                          ? const Color(0xFFF59E0B) 
                          : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${revenue.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_left_rounded, size: 16, color: Theme.of(context).hintColor),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Column(
          children: [
            // ترويسة الجدول
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('اليوم والتاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  Expanded(flex: 2, child: Text('الإيرادات الكلية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  Expanded(flex: 2, child: Text('عدد الزيارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  Expanded(flex: 2, child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  SizedBox(width: 40, child: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)), textAlign: TextAlign.center)),
                ],
              ),
            ),

            // صفوف الجدول
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: finalItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final log = finalItems[index];
                final date = DateTime.parse(log['date'] as String);
                final dayName = intl.DateFormat('EEEE', 'ar').format(date);
                final dayNum = intl.DateFormat('d MMMM yyyy', 'ar').format(date);
                final revenue = (log['revenue'] as num).toDouble();
                final visits = log['visits'] as int;
                final isFriday = false;

                final today = DateTime.now();
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

                final statusLabel = isToday ? 'نشط اليوم' : (isFriday ? 'عطلة رسمية' : 'مكتمل');
                final statusColor = isToday 
                    ? const Color(0xFFF59E0B) // Amber
                    : (isFriday 
                        ? (Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF94A3B8)) 
                        : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981)));
                final statusBg = isToday 
                    ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                    : (isFriday 
                        ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5)) 
                        : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5)));

                return InkWell(
                  onTap: isFriday ? null : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(
                        startDate: date,
                        endDate: date,
                        isMonthly: false,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            '$dayName - $dayNum',
                            style: TextStyle(
                              fontSize: 12,
                              color: isFriday ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${revenue.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                              color: isFriday ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$visits حالة',
                            style: TextStyle(
                              fontSize: 12,
                              color: isFriday ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: isFriday
                              ? Icon(Icons.block_flipped, size: 16, color: Theme.of(context).hintColor)
                              : Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('خطأ: $err')),
    );
  }

  // جدول سجلات الشهور التراكمي
  Widget _buildMonthlyTableView(AsyncValue<List<Map<String, dynamic>>> monthlyStatsAsync) {
    return monthlyStatsAsync.when(
      data: (logs) {
        final filteredLogs = logs;
        final finalItems = filteredLogs.take(15).toList();

        if (finalItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bar_chart_rounded, size: 40, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد سجلات مالية مسجلة بعد',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        final isMobile = MediaQuery.of(context).size.width < 900;

        if (isMobile) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: finalItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final log = finalItems[index];
              final monthParts = (log['month'] as String).split('-');
              final year = int.parse(monthParts[0]);
              final month = int.parse(monthParts[1]);
              final date = DateTime(year, month, 1);
              final monthLabel = intl.DateFormat('MMMM yyyy', 'ar').format(date);
              final revenue = (log['revenue'] as num).toDouble();
              final visits = log['visits'] as int;

              final monthStart = DateTime(year, month, 1);
              final monthEnd = DateTime(year, month + 1, 0);
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(
                      startDate: monthStart,
                      endDate: monthEnd,
                      isMonthly: true,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    monthLabel,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  subtitle: Text(
                    '$visits حالة كشف',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${revenue.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_left_rounded, size: 16, color: Theme.of(context).hintColor),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Column(
          children: [
            // ترويسة الجدول
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('الشهر والسنة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  Expanded(flex: 2, child: Text('الإيرادات الإجمالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  Expanded(flex: 2, child: Text('إجمالي الزيارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  Expanded(flex: 2, child: Text('الحالة المالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)))),
                  SizedBox(width: 40, child: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)), textAlign: TextAlign.center)),
                ],
              ),
            ),

            // صفوف الجدول
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: finalItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final log = finalItems[index];
                final monthParts = (log['month'] as String).split('-');
                final year = int.parse(monthParts[0]);
                final month = int.parse(monthParts[1]);
                final date = DateTime(year, month, 1);
                final monthLabel = intl.DateFormat('MMMM yyyy', 'ar').format(date);
                final revenue = (log['revenue'] as num).toDouble();
                final visits = log['visits'] as int;

                final today = DateTime.now();
                final isCurrentMonth = today.year == year && today.month == month;

                final statusLabel = isCurrentMonth ? 'نشط حالياً' : 'مغلق ومؤكد';
                final statusColor = isCurrentMonth 
                    ? const Color(0xFFF59E0B) // Amber
                    : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981));
                final statusBg = isCurrentMonth 
                    ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)) 
                    : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5));

                final monthStart = DateTime(year, month, 1);
                final monthEnd = DateTime(year, month + 1, 0);
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(
                        startDate: monthStart,
                        endDate: monthEnd,
                        isMonthly: true,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            monthLabel,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${revenue.toStringAsFixed(0)} ج.م',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$visits حالة كشف',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (err, _) => Center(child: Text('خطأ: $err')),
    );
  }

}

// رسم خط الاتجاه البياني البسيط مع تعبئة تدرجية (Sparkline Painter)
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SparklinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final minVal = points.reduce((a, b) => a < b ? a : b);
    // When all values equal, show a gentle mid-line at 60% height
    final range = maxVal - minVal > 0 ? maxVal - minVal : null;

    // Points come in newest-first order (index 0 = most recent).
    // Painter maps: i=0 (newest) → x=0 (LEFT), i=n-1 (oldest) → x=size.width (RIGHT).
    // This gives RTL reading: past on the right, present on the left.
    final List<Offset> offsets = [];
    final stepX = points.length > 1 ? size.width / (points.length - 1) : size.width;
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX; // LTR index → newest at LEFT (x=0), oldest at RIGHT (x=width)
      final double y;
      if (range == null) {
        y = size.height * 0.4;
      } else {
        y = size.height - ((points[i] - minVal) / range) * size.height * 0.85 - size.height * 0.07;
      }
      offsets.add(Offset(x, y));
    }

    // Draw gradient fill beneath the line
    if (offsets.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(offsets.first.dx, size.height);
      fillPath.lineTo(offsets.first.dx, offsets.first.dy);
      for (int i = 1; i < offsets.length; i++) {
        final prev = offsets[i - 1];
        final curr = offsets[i];
        final cpX = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
      fillPath.lineTo(offsets.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.18), color.withOpacity(0.01)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // Draw the line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    for (int i = 0; i < offsets.length; i++) {
      if (i == 0) {
        linePath.moveTo(offsets[i].dx, offsets[i].dy);
      } else {
        // Smooth cubic bezier
        final prev = offsets[i - 1];
        final curr = offsets[i];
        final cpX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Dot at the newest point (leftmost = offsets.first, since index 0 = newest = x=0)
    final dotO = offsets.first;
    canvas.drawCircle(dotO, 3.0, Paint()..color = color);
    canvas.drawCircle(dotO, 3.0, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.points != points;
}



