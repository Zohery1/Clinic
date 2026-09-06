import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/motion.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../auth/presentation/login_controller.dart';
import 'widgets/cash_drawer_reconciliation_tab.dart';
import 'widgets/daily_logs_tab.dart';
import 'widgets/monthly_logs_tab.dart';
import 'widgets/overview_tab.dart';


class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 89));
  DateTime _endDate = DateTime.now();

  void _onDateRangeChanged(DateTimeRange range) {
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const AppStatusPage(
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.warning,
        title: 'يرجى تسجيل الدخول أولاً',
        message: 'قم بتسجيل الدخول للوصول إلى التقارير.',
        compact: true,
      );
    }
    if (!user.isOwner) {
      return const AppStatusPage(
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.danger,
        title: 'هذه الصفحة متاحة لمدير العيادة فقط',
        message:
            'يرجى التواصل مع مدير العيادة لطلب صلاحية الوصول إلى التقارير والبيانات المالية.',
        compact: true,
      );
    }

    final child = switch (_selectedTab) {
      0 => OverviewTab(startDate: _startDate, endDate: _endDate),
      1 => DailyLogsTab(
          startDate: _startDate,
          endDate: _endDate,
          onDateRangeChanged: _onDateRangeChanged,
        ),
      2 => const MonthlyLogsTab(),
      _ => const CashDrawerReconciliationTab(),
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _SubTabsInline(
                  selected: _selectedTab,
                  onSelect: (i) => setState(() => _selectedTab = i),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SubTabsInline extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _SubTabsInline({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const labels = [
      'نظرة عامة',
      'السجلات اليومية',
      'السجلات الشهرية',
      'تقفيل الخزينة والدرج 💰',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: AppMotion.normal,
                  curve: AppMotion.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected == i
                        ? AppColors.primarySubtle
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected == i
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight:
                          selected == i ? FontWeight.w700 : FontWeight.w600,
                      color: selected == i
                          ? AppColors.primary
                          : AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
              if (i < labels.length - 1) const SizedBox(width: AppSpace.xs),
            ],
          ],
        ),
      ),
    );
  }
}