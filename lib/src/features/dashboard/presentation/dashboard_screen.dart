import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/layout/app_shell.dart';
import '../../appointments/presentation/appointments_controller.dart';
import '../../appointments/presentation/appointments_screen.dart';
import '../../appointments/presentation/book_appointment_dialog.dart';
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

  List<String> _getRoutes(bool isOwner) => [
    '/home',
    '/appointments',
    '/patients',
    if (isOwner) '/reports',
    '/settings',
  ];

  int get _effectiveIndex {
    final user = ref.read(currentUserProvider);
    final isOwner = user?.isOwner ?? false;
    final maxIndex = isOwner ? 4 : 3;
    return _currentIndex.clamp(0, maxIndex);
  }

  void _onNavigate(String route) {
    final user = ref.read(currentUserProvider);
    final isOwner = user?.isOwner ?? false;
    final routes = _getRoutes(isOwner);
    final idx = routes.indexOf(route);
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
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
            BookAppointmentDialog.show(
              context: context,
              clinicId: user.clinicId,
            );
          },
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
            BookAppointmentDialog.show(
              context: context,
              clinicId: user.clinicId,
            );
          },
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              _navigateToTab(2),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              _navigateToTab(2),
          const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
              _navigateToTab(0),
          const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
              _navigateToTab(1),
          const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
              _navigateToTab(2),
          const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
              _navigateToTab(3),
          const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
              _navigateToTab(4),
        },
        child: Focus(
          autofocus: true,
          child: AppShell(
            currentRoute: _getRoutes(isOwner)[_effectiveIndex],
            onNavigate: _onNavigate,
            user: user,
            title: _resolveTitle(_getRoutes(isOwner)[_effectiveIndex], widget.clinicName),
            subtitle: _resolveSubtitle(_getRoutes(isOwner)[_effectiveIndex]),
            unreadCount: unreadCount,
            onNotificationsTap: () =>
                DashboardNotificationsDialog.show(context),
            onSearchTap: () => _navigateToTab(2),
            actions: const <Widget>[
              ClinicSwitcherButton(isCompact: true),
            ],
            child: IndexedStack(
              index: _effectiveIndex,
              children: tabs,
            ),
          ),
        ),
      ),
    );
  }

  String _resolveTitle(String route, String? clinicName) {
    switch (route) {
      case '/home':
        return clinicName ?? 'لوحة الإدارة';
      case '/appointments':
        return 'المواعيد';
      case '/patients':
        return 'المرضى';
      case '/reports':
        return 'التقارير';
      case '/settings':
        return 'الإعدادات';
      default:
        return clinicName ?? 'لوحة الإدارة';
    }
  }

  String? _resolveSubtitle(String route) {
    switch (route) {
      case '/home':
        return 'نظرة عامة على عيادتك اليوم';
      case '/appointments':
        return 'كل حجوزاتك في مكان واحد';
      case '/patients':
        return 'سجل المرضى والمتابعة';
      case '/reports':
        return 'أداء العيادة والمؤشرات المالية';
      case '/settings':
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DashboardWeeklyChart(),
        const SizedBox(height: AppSpace.xl),
        DashboardTodayList(onNavigateToTab: onNavigateToTab),
        const SizedBox(height: AppSpace.xl),
        const DashboardRecentTransactions(),
      ],
    );
  }

  Widget _twoColumnContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DashboardWeeklyChart(),
              const SizedBox(height: AppSpace.xl),
              DashboardTodayList(onNavigateToTab: onNavigateToTab),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.xl),
        const Expanded(
          flex: 2,
          child: DashboardRecentTransactions(),
        ),
      ],
    );
  }
}