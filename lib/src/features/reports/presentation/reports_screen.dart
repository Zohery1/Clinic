import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/layout/app_shell.dart';
import '../../../core/ui/layout/app_top_bar.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../auth/presentation/login_controller.dart';
import '../../clinics/presentation/clinics_controller.dart';
import '../../dashboard/presentation/notifications_controller.dart';
import 'reports_controller.dart';
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
        title: '???? ????? ?????? ?????',
        message: '??? ????? ?????? ?????? ??? ????????.',
        compact: true,
      );
    }
    if (!user.isOwner) {
      return AppStatusPage(
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.danger,
        title: '???????? ??????? ????? ????? ??????? ???',
        message:
            '???? ???????? ??????? ?????????? ????? ????? ??????? ???? ??? ???? ????? ???????? ?? ??????? ?????? ?????.',
        compact: true,
      );
    }

    final unread = ref
        .watch(notificationsProvider)
        .notifications
        .where((n) => !n.isRead)
        .length;
    final clinicName = ref.watch(activeClinicSummaryProvider)?.clinicName;

    final child = switch (_selectedTab) {
      0 => OverviewTab(startDate: _startDate, endDate: _endDate),
      1 => DailyLogsTab(
          startDate: _startDate,
          endDate: _endDate,
          onDateRangeChanged: _onDateRangeChanged,
        ),
      _ => const MonthlyLogsTab(),
    };

    return AppShell(
      title: '???????? ???????',
      subtitle: '?????? ?????? ??????????',
      breadcrumbs: const [
        AppBreadcrumbItem(label: '????????'),
        AppBreadcrumbItem(label: '????????'),
      ],
      currentRoute: '/reports',
      onNavigate: (_) {},
      user: user,
      clinicName: clinicName,
      unreadCount: unread,
      actions: [_refreshAction(context)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SubTabsInline(
            selected: _selectedTab,
            onSelect: (i) => setState(() => _selectedTab = i),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

Widget _refreshAction(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.refresh_rounded),
    tooltip: '?????',
    onPressed: () {
      final container = ProviderScope.containerOf(context, listen: false);
      container.invalidate(todayRevenueProvider);
      container.invalidate(monthRevenueProvider);
      container.invalidate(weeklyRevenueProvider);
      container.invalidate(sixWeeksRevenueProvider);
      container.invalidate(monthlyStatsProvider);
      container.invalidate(dailyStatsProvider);
      container.invalidate(todayStatusCountsProvider);
    },
  );
}

class _SubTabsInline extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _SubTabsInline({required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    const labels = ['???? ????', '????? ??????', '????? ??????'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == i
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected == i
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.borderSubtle(context),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected == i
                          ? AppColors.primary
                          : AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ),
 ),
        ],
      ),
    );
  }
}
