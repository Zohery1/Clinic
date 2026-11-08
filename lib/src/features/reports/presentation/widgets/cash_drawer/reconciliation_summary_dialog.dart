import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/ui/tokens/colors.dart';

/// حوار ملخص تقفيل الدرج واليومية المعتمد (Reconciliation Summary Dialog)
class ReconciliationSummaryDialog extends StatelessWidget {
  final String statusMessage;
  final double openingFloat;
  final double totalExpenses;
  final double expectedCash;
  final double actualCash;
  final double diff;
  final VoidCallback onPrint;

  const ReconciliationSummaryDialog({
    super.key,
    required this.statusMessage,
    required this.openingFloat,
    required this.totalExpenses,
    required this.expectedCash,
    required this.actualCash,
    required this.diff,
    required this.onPrint,
  });

  static Future<void> show({
    required BuildContext context,
    required String statusMessage,
    required double openingFloat,
    required double totalExpenses,
    required double expectedCash,
    required double actualCash,
    required double diff,
    required VoidCallback onPrint,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: ReconciliationSummaryDialog(
          statusMessage: statusMessage,
          openingFloat: openingFloat,
          totalExpenses: totalExpenses,
          expectedCash: expectedCash,
          actualCash: actualCash,
          diff: diff,
          onPrint: () {
            Navigator.pop(ctx);
            onPrint();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.verified_rounded, color: AppColors.success),
          SizedBox(width: 8),
          Text('ملخص تقفيل الخزينة'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusMessage,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Divider(),
          _buildSummaryRow(
            'رصيد بداية الوردية:',
            '${openingFloat.toStringAsFixed(0)} ج.م',
          ),
          _buildSummaryRow(
            'المصروفات اليومية:',
            '${totalExpenses.toStringAsFixed(0)} ج.م',
          ),
          _buildSummaryRow(
            'الرصيد الدفتري المتوقع:',
            '${expectedCash.toStringAsFixed(0)} ج.م',
          ),
          _buildSummaryRow(
            'النقدية الفعلية المحصية:',
            '${actualCash.toStringAsFixed(0)} ج.م',
          ),
          _buildSummaryRow(
            'فارق المطابقة:',
            '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(0)} ج.م',
            color: diff == 0
                ? AppColors.success
                : (diff < 0 ? AppColors.danger : AppColors.info),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        ElevatedButton.icon(
          onPressed: onPrint,
          icon: const Icon(Icons.print_rounded, size: 16),
          label: const Text('طباعة ملخص التقفيل'),
        ),
      ],
    );
  }
}
