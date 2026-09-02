import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/layout/app_shell.dart';
import '../../appointments/presentation/appointments_controller.dart';
import '../../appointments/presentation/appointments_screen.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/presentation/top_up_subscription_screen.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';
import '../../patients/presentation/pages/patients_page.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'notifications_controller.dart';
import 'widgets/dashboard_greeting_hero.dart';
import 'widgets/dashboard_notifications_dialog.dart';
import 'widgets/dashboard_quick_actions.dart';
import 'widgets/dashboard_recent_transactions.dart';
import 'widgets/dashboard_stats_row.dart';
import 'widgets/dashboard_today_appointments.dart';
import 'widgets/dashboard_weekly_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final DateTime? subscriptionEndDate;
  final String? inviteCode;
  final String? clinicName;
  final String? clinicId;

  const DashboardScreen({
    super.key,
    this.subscriptionEndDate,
    this.inviteCode,
    this.clinicName,
    this.clinicId,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  static const _routes = <String>[
    '/home',
    '/appointments',
    '/patients',
    '/reports',
    '/settings',
  ];

  int get _effectiveIndex {
    final user = ref.read(currentUserProvider);
    final isOwner = user?.isOwner ?? false;
    final maxIndex = isOwner ? 4 : 3;
    return _currentIndex.clamp(0, maxIndex);
  }

  void _onNavigate(String route) {
    final idx = _routes.indexOf(route);
    if (idx >= 0) {
      setState(() => _currentIndex = idx);
    }
  }

  void _navigateToTab(int index) {
    final user = ref.read(currentUserProvider);
    final isOwner = user?.isOwner ?? false;
    final max = isOwner ? 4 : 3;
    setState(() => _currentIndex = index.clamp(0, max));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeAppointmentsSyncProvider);

    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final isExpired = widget.subscriptionEndDate != null &&
        widget.subscriptionEndDate!.isBefore(DateTime.now());
    if (isExpired) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppStatusPage(
          icon: Icons.event_busy_rounded,
          iconColor: AppColors.danger,
          title: 'انتهى الاشتراك',
          message:
              'يرجى تجديد اشتراك العيادة للاستمرار في استخدام النظام والوصول إلى بياناتك.',
          primaryAction: StatusAction(
            label: 'تجديد الاشتراك',
            icon: Icons.refresh_rounded,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  insetPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.brXl,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadii.brXl,
                    child: Container(
                      constraints: const BoxConstraints(
                          maxWidth: 700, maxHeight: 750),
                      child: TopUpSubscriptionScreen(
                        clinicName: widget.clinicName ?? 'العيادة',
                        inviteCode: widget.inviteCode ?? '',
                        clinicId: widget.clinicId ?? '',
                        onRefresh: () {
                          Navigator.of(ctx).pop();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          compact: true,
        ),
      );
    }

    final isOwner = user.isOwner;
    final unreadCount = ref
        .watch(notificationsProvider)
        .notifications
        .where((n) => !n.isRead)
        .length;

    final tabs = <Widget>[
      _HomeTab(
        clinicId: widget.clinicId,
        clinicName: widget.clinicName,
        onNavigateToTab: _navigateToTab,
      ),
      AppointmentsScreen(
        subscriptionEndDate: widget.subscriptionEndDate,
        inviteCode: widget.inviteCode,
        clinicName: widget.clinicName,
        clinicId: widget.clinicId,
      ),
      const PatientsPage(),
      if (isOwner) const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppShell(
        currentRoute: _routes[_effectiveIndex],
        onNavigate: _onNavigate,
        user: user,
        title: _resolveTitle(_effectiveIndex, widget.clinicName),
        subtitle: _resolveSubtitle(_effectiveIndex),
        unreadCount: unreadCount,
        onNotificationsTap: () =>
            DashboardNotificationsDialog.show(context),
        actions: <Widget>[
          ClinicSwitcherButton(isCompact: true),
        ],
        child: IndexedStack(
          index: _effectiveIndex,
          children: tabs,
        ),
      ),
    );
  }

  String _resolveTitle(int idx, String? clinicName) {
    switch (idx) {
      case 0:
        return clinicName ?? 'لوحة الإدارة';
      case 1:
        return 'المواعيد';
      case 2:
        return 'المرضى';
      case 3:
        return 'التقارير';
      case 4:
        return 'الإعدادات';
      default:
        return '';
    }
  }

  String? _resolveSubtitle(int idx) {
    switch (idx) {
      case 0:
        return 'نظرة عامة على عيادتك اليوم';
      case 1:
        return 'كل حجوزاتك في مكان واحد';
      case 2:
        return 'سجل المرضى والمتابعة';
      case 3:
        return 'أداء العيادة والمؤشرات المالية';
      case 4:
        return 'إعدادات الحساب والعيادة';
      default:
        return null;
    }
  }
}

class _HomeTab extends ConsumerWidget {
  final String? clinicId;
  final String? clinicName;
  final void Function(int tabIndex) onNavigateToTab;

  const _HomeTab({
    required this.clinicId,
    required this.clinicName,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final stacked = width < 1100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardGreetingHero(onNavigateToTab: onNavigateToTab),
          const SizedBox(height: AppSpace.xl),
          DashboardStatsRow(onNavigateToTab: onNavigateToTab),
          const SizedBox(height: AppSpace.xl),
          DashboardQuickActions(onNavigateToTab: onNavigateToTab),
          const SizedBox(height: AppSpace.xxl),
          if (stacked)
            _stackedContent()
          else
            _twoColumnContent(),
        ],
      ),
    );
  }

  Widget _stackedContent() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardWeeklyChart(),
        SizedBox(height: AppSpace.xl),
        DashboardTodayList(),
        SizedBox(height: AppSpace.xl),
        DashboardRecentTransactions(),
      ],
    );
  }

  Widget _twoColumnContent() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardWeeklyChart(),
              SizedBox(height: AppSpace.xl),
              DashboardTodayList(),
            ],
          ),
        ),
        SizedBox(width: AppSpace.xl),
        Expanded(
          flex: 2,
          child: DashboardRecentTransactions(),
        ),
      ],
    );
  }
}