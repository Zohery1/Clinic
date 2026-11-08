import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// بيانات بطاقة الملخص الإحصائي
class SummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final bool mono;
  final String? trendText;
  final bool? trendIsPositive;

  const SummaryCardData({
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

/// بطاقات ملخص الإيرادات والزيارات والإلغاءات في التقرير التفصيلي
class ReportSummaryCards extends StatelessWidget {
  final bool isDark;
  final bool isDesktop;
  final double totalRev;
  final double totalAppRev;
  final double totalSvcRev;
  final int totalVisits;
  final int newPatients;
  final int oldPatients;
  final int cancelledCount;
  final int cancelledByPatientCount;
  final double previousRevenue;
  final String comparisonLabel;

  const ReportSummaryCards({
    super.key,
    required this.isDark,
    required this.isDesktop,
    required this.totalRev,
    required this.totalAppRev,
    required this.totalSvcRev,
    required this.totalVisits,
    required this.newPatients,
    required this.oldPatients,
    required this.cancelledCount,
    required this.cancelledByPatientCount,
    required this.previousRevenue,
    required this.comparisonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final revenueDiff = totalRev - previousRevenue;
    final revenuePct = previousRevenue == 0
        ? (totalRev > 0 ? 100.0 : 0.0)
        : (revenueDiff / previousRevenue).abs() * 100;

    final shortLabel = comparisonLabel.replaceAll('مقارنة ', '');
    final trendText = '${revenuePct.toStringAsFixed(0)}% ($shortLabel)';
    final trendIsPositive = revenueDiff >= 0;

    final cards = [
      SummaryCardData(
        label: 'إجمالي الإيرادات',
        value: '${totalRev.toStringAsFixed(0)} ج.م',
        icon: Icons.account_balance_wallet_outlined,
        accentColor: Theme.of(context).colorScheme.primary,
        bgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        mono: true,
        trendText: trendText,
        trendIsPositive: trendIsPositive,
      ),
      SummaryCardData(
        label: 'إيرادات الكشوفات',
        value: '${totalAppRev.toStringAsFixed(0)} ج.م',
        icon: Icons.medical_services_outlined,
        accentColor: AppColors.info,
        bgColor: AppColors.infoSubtle,
        mono: true,
      ),
      SummaryCardData(
        label: 'إيرادات الخدمات',
        value: '${totalSvcRev.toStringAsFixed(0)} ج.م',
        icon: Icons.build_outlined,
        accentColor: AppColors.success,
        bgColor: AppColors.successSubtle,
        mono: true,
      ),
      SummaryCardData(
        label: 'إجمالي الزيارات',
        value: '$totalVisits زيارة',
        icon: Icons.people_alt_outlined,
        accentColor: AppColors.completed,
        bgColor: AppColors.completedSubtle,
        mono: false,
      ),
      SummaryCardData(
        label: 'إلغاء (من العيادة)',
        value: '$cancelledCount',
        icon: Icons.event_busy_outlined,
        accentColor: AppColors.danger,
        bgColor: AppColors.dangerSubtle,
        mono: false,
      ),
      SummaryCardData(
        label: 'عدم حضور (مريض)',
        value: '$cancelledByPatientCount',
        icon: Icons.person_off_outlined,
        accentColor: AppColors.warning,
        bgColor: AppColors.warningSubtle,
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
                  ),
                ))
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

  Widget _buildSummaryCard(BuildContext context, SummaryCardData data) {
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
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
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
                  color: (data.trendIsPositive! ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.12),
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
}
