import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/data/app_data_table.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../reports_controller.dart';
import '../report_detail_screen.dart';
import 'daily_logs_filters.dart';

class DailyLogsTab extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTimeRange> onDateRangeChanged;

  const DailyLogsTab({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  String get _rangeKey {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${fmt(startDate)}_${fmt(endDate)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyStatsProvider(_rangeKey));

    final rows = async.maybeWhen(
      data: (logs) => [
        for (final l in logs) _rowFromLog(l),
      ],
      orElse: () => const <Map<String, dynamic>>[],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
        DailyLogsFilters(
          startDate: startDate,
          endDate: endDate,
          onDateRangeChanged: onDateRangeChanged,
          onExport: () => _exportCsv(context, rows),
        ),
        const SizedBox(height: AppSpace.lg),
        AppDataTable(
          columns: const [
            AppDataTableColumn(
              key: 'date',
              label: 'التاريخ',
              sortable: false,
            ),
            AppDataTableColumn(
              key: 'visits',
              label: 'عدد الزيارات',
              format: 'number',
              align: AppDataTableAlign.center,
            ),
            AppDataTableColumn(
              key: 'revenue',
              label: 'الإيرادات',
              format: 'currency',
              align: AppDataTableAlign.end,
            ),
            AppDataTableColumn(
              key: 'completed',
              label: 'المكتملة',
              format: 'number',
              align: AppDataTableAlign.center,
            ),
            AppDataTableColumn(
              key: 'cancelled',
              label: 'الملغاة',
              format: 'number',
              align: AppDataTableAlign.center,
            ),
            AppDataTableColumn(
              key: 'view',
              label: 'عرض',
              sortable: false,
              align: AppDataTableAlign.center,
              width: 60,
            ),
          ],
          rows: rows,
          isLoading: async.isLoading,
          emptyMessage: 'لا توجد سجلات يومية في هذه الفترة',
          emptyIcon: Icons.bar_chart_rounded,
          onRowTap: (row) {
            final dt = row['_date'] as DateTime?;
            if (dt == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(
                  startDate: dt,
                  endDate: dt,
                  isMonthly: false,
                ),
              ),
            );
          },
        ),
      ],
      ),
    );
  }

  Map<String, dynamic> _rowFromLog(Map<String, dynamic> log) {
    final dateStr = log['date'] as String? ?? '';
    final dt = DateTime.tryParse(dateStr);
    String dateLabel = dateStr;
    if (dt != null) {
      final dayName = intl.DateFormat('EEEE', 'ar').format(dt);
      final dayNum = intl.DateFormat('d MMMM yyyy', 'ar').format(dt);
      dateLabel = '$dayName - $dayNum';
    }
    final revenue = (log['revenue'] as num?)?.toDouble() ?? 0.0;
    final visits = (log['visits'] as num?)?.toInt() ?? 0;
    final completed = (log['completed'] as num?)?.toInt() ??
        (log['completedCount'] as num?)?.toInt() ??
        0;
    final cancelled = (log['cancelled'] as num?)?.toInt() ??
        (log['cancelledCount'] as num?)?.toInt() ??
        0;
    return {
      'date': dateLabel,
      '_date': dt,
      'visits': visits,
      'revenue': revenue,
      'completed': completed,
      'cancelled': cancelled,
      'view': 'عرض',
    };
  }

  void _exportCsv(BuildContext context, List<Map<String, dynamic>> rows) {
    final buffer = StringBuffer()
      ..writeln('التاريخ,عدد الزيارات,الإيرادات,المكتملة,الملغاة');
    for (final r in rows) {
      buffer.writeln(
        '"${r['date']}",${r['visits']},${r['revenue']},${r['completed']},${r['cancelled']}',
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تجهيز ${rows.length} سجل - جاهز للتحميل'),
      ),
    );
    debugPrint(buffer.toString());
  }
}
