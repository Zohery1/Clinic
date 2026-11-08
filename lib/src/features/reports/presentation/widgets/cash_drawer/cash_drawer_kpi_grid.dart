import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';

/// شبكة بطاقات المؤشرات المالية الأربعة للدرج والخزينة (4-Card Bento Grid)
class CashDrawerKpiGrid extends StatelessWidget {
  final TextEditingController openingFloatCtrl;
  final double todayRev;
  final double totalExpenses;
  final int expensesCount;
  final double expectedCash;
  final VoidCallback onOpeningFloatChanged;

  const CashDrawerKpiGrid({
    super.key,
    required this.openingFloatCtrl,
    required this.todayRev,
    required this.totalExpenses,
    required this.expensesCount,
    required this.expectedCash,
    required this.onOpeningFloatChanged,
  });

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget valueWidget,
    required IconData icon,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.08)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.4)
              : AppColors.borderSubtle(context),
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          valueWidget,
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 800;
        final isRevNegative = todayRev < 0;
        final isExpectedNegative = expectedCash < 0;
        final revColor = isRevNegative ? AppColors.warning : AppColors.success;
        final expectedColor = isExpectedNegative ? AppColors.danger : AppColors.completed;

        final cards = [
          _buildKpiCard(
            context,
            title: 'رصيد بداية الوردية',
            subtitle: 'العهدة النقدية الافتتاحية',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: openingFloatCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => onOpeningFloatChanged(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Text(
                  'ج.م',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
          ),
          _buildKpiCard(
            context,
            title: 'التحصيل الإجمالي اليوم',
            subtitle: isRevNegative ? 'صافي سالب بعد المرتجعات' : 'كشوفات وخدمات مؤكدة',
            valueWidget: Text(
              '${todayRev.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: revColor,
              ),
            ),
            icon: Icons.payments_outlined,
            color: revColor,
          ),
          _buildKpiCard(
            context,
            title: 'المصروفات النثرية',
            subtitle: '$expensesCount بنود صرف مسجلة',
            valueWidget: Text(
              '${totalExpenses.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
            icon: Icons.receipt_long_outlined,
            color: AppColors.danger,
          ),
          _buildKpiCard(
            context,
            title: 'الرصيد المتوقع بالدرج',
            subtitle: isExpectedNegative ? 'تنبيه: الرصيد المتوقع بالسالب' : 'عهدة + تحصيل - مصروفات',
            valueWidget: Text(
              '${expectedCash.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: expectedColor,
              ),
            ),
            icon: Icons.calculate_outlined,
            color: expectedColor,
            highlight: true,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1)
                  const SizedBox(height: AppSpace.md),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1)
                const SizedBox(width: AppSpace.md),
            ],
          ],
        );
      },
    );
  }
}
