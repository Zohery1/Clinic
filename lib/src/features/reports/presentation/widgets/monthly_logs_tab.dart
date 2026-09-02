import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/data/app_data_table.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../reports_controller.dart';
import '../report_detail_screen.dart';
class MonthlyLogsTab extends ConsumerWidget {
  const MonthlyLogsTab({
super.key
});
  @override  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthlyStatsProvider);
    final rows = async.maybeWhen(      data: (logs) => [for (final l in logs) _rowFromLog(l)],      orElse: () => const <Map<String, dynamic>>[],    );
    return Column(      crossAxisAlignment: CrossAxisAlignment.stretch,      mainAxisSize: MainAxisSize.min,      children: [        Row(          mainAxisAlignment: MainAxisAlignment.end,          children: [            AppButton(              label: '????? CSV',              icon: Icons.file_download_outlined,              expand: false,              size: AppButtonSize.sm,              variant: AppButtonVariant.secondary,              onPressed: () => _exportCsv(context, rows),            ),          ],        ),        const SizedBox(height: AppSpace.md),        AppDataTable(          columns: const [            AppDataTableColumn(key: 'month', label: '?????', sortable: false),            AppDataTableColumn(              key: 'visits',              label: '??? ????????',              format: 'number',              align: AppDataTableAlign.center,            ),            AppDataTableColumn(              key: 'revenue',              label: '?????????',              format: 'currency',              align: AppDataTableAlign.end,            ),            AppDataTableColumn(              key: 'avg',              label: '????? ????',              format: 'currency',              align: AppDataTableAlign.end,            ),            AppDataTableColumn(              key: 'view',              label: '?????',              sortable: false,              align: AppDataTableAlign.center,              width: 60,            ),          ],          rows: rows,          isLoading: async.isLoading,          emptyMessage: '?? ???? ????? ????? ???',          emptyIcon: Icons.calendar_view_month_rounded,          onRowTap: (row) {
            final dt = row['_date'] as DateTime?;
            if (dt == null) return;
            final monthStart = DateTime(dt.year, dt.month, 1);
            final monthEnd = DateTime(dt.year, dt.month + 1, 0);
            Navigator.of(context).push(              MaterialPageRoute(                builder: (_) => ReportDetailScreen(                  startDate: monthStart,                  endDate: monthEnd,                  isMonthly: true,                ),              ),            );
          
},        ),      ],    );
  
}  Map<String, dynamic> _rowFromLog(Map<String, dynamic> log) {
    final monthStr = log['month'] as String? ?? '';
    DateTime? dt;
    String label = monthStr;
    if (monthStr.contains('-')) {
      final parts = monthStr.split('-');
      if (parts.length == 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          dt = DateTime(y, m, 1);
          label = intl.DateFormat('MMMM yyyy', 'ar').format(dt);
        
}      
}    
}    final revenue = (log['revenue'] as num?)?.toDouble() ?? 0.0;
    final visits = (log['visits'] as num?)?.toInt() ?? 0;
    double avg = 0.0;
    if (dt != null) {
      final daysInMonth = DateTime(dt.year, dt.month + 1, 0).day;
      avg = revenue / daysInMonth;
    
}    return {
      'month': label,      '_date': dt,      'visits': visits,      'revenue': revenue,      'avg': avg,      'view': '???',    
};
  
}  void _exportCsv(BuildContext context, List<Map<String, dynamic>> rows) {
    final buffer = StringBuffer()      ..writeln('?????,??? ????????,?????????,??????? ??????');
    for (final r in rows) {
      buffer.writeln(        '"${
r['month']
}",${
r['visits']
},${
r['revenue']
},${
(r['avg'] as double).toStringAsFixed(0)
}',      );
    
}    ScaffoldMessenger.of(context).showSnackBar(      SnackBar(content: Text('?? ????? ${
rows.length
} ??? — ???? ?????')),    );
    debugPrint(buffer.toString());
  
}
}
