import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/feedback/app_status_page.dart';
import '../../../core/ui/layout/app_shell.dart';
import '../../../core/ui/layout/app_top_bar.dart';
import '../../../core/ui/layout/lazy_indexed_stack.dart';
import '../../../core/routing/routing.dart';
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

/// Clinical Bento Executive Dashboard. Direct, glanceable, and authoritative.
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
          message: 'يرجى تجديد الاشتراك للمتابعة في استخدام النظام.',
          primaryAction: StatusAction(
            label: 'تجديد الاشتراك',
            icon: Icons.refresh_rounded,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
            AppNavigation.showBookAppointment(
              context,
              clinicId: user.clinicId,
            );
          },
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
            AppNavigation.showBookAppointment(
              context,
              clinicId: user.clinicId,
            );
          },
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
            title: _resolveTitle(_getRoutes(isOwner)[_effectiveIndex]),
            subtitle: _resolveSubtitle(_getRoutes(isOwner)[_effectiveIndex]),
            breadcrumbs: <AppBreadcrumbItem>[
              AppBreadcrumbItem(label: widget.clinicName ?? 'عيادتي'),
            ],
            onUserTap: () => _onNavigate('/settings'),
            unreadCount: unreadCount,
            onNotificationsTap: () =>
                DashboardNotificationsDialog.show(context),
            actions: const <Widget>[
              ClinicSwitcherButton(isCompact: true),
            ],
            child: LazyIndexedStack(
              index: _effectiveIndex,
              itemBuilders: [
                (ctx) => _HomeTab(
                      clinicId: widget.clinicId,
                      clinicName: widget.clinicName,
                      onNavigateToTab: _navigateToTab,
                    ),
                (ctx) => AppointmentsScreen(
                      subscriptionEndDate: widget.subscriptionEndDate,
                      inviteCode: widget.inviteCode,
                      clinicName: widget.clinicName,
                      clinicId: widget.clinicId,
                    ),
                (ctx) => const PatientsPage(),
                if (isOwner) (ctx) => const ReportsScreen(),
                (ctx) => const SettingsScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _resolveTitle(String route) {
    switch (route) {
      case '/home':
        return 'الرئيسية';
      case '/appointments':
        return 'المواعيد';
      case '/patients':
        return 'المرضى';
      case '/reports':
        return 'التقارير';
      case '/settings':
        return 'الإعدادات';
      default:
        return 'الرئيسية';
    }
  }

  String? _resolveSubtitle(String route) {
    switch (route) {
      case '/home':
        return 'نظرة عامة على العيادة اليوم';
      case '/appointments':
        return 'جدول مواعيد العيادة';
      case '/patients':
        return 'سجل وبيانات المرضى';
      case '/reports':
        return 'إحصائيات وأرقام العيادة';
      case '/settings':
        return 'إعدادات النظام والعيادة';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;

        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardGreetingHero(onNavigateToTab: onNavigateToTab),
                  const SizedBox(height: AppSpace.md),
                  DashboardStatsRow(onNavigateToTab: onNavigateToTab),
                  const SizedBox(height: AppSpace.md),
                  DashboardQuickActions(onNavigateToTab: onNavigateToTab),
                  const SizedBox(height: AppSpace.lg),
                  if (stacked)
                    _stackedContent()
                  else
                    _twoColumnContent(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stackedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardTodayList(onNavigateToTab: onNavigateToTab),
        const SizedBox(height: AppSpace.md),
        const DashboardWeeklyChart(),
        const SizedBox(height: AppSpace.md),
        const DashboardRecentTransactions(),
      ],
    );
  }

  Widget _twoColumnContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary operational column (Today's queue & appointments)
        Expanded(
          flex: 3,
          child: DashboardTodayList(onNavigateToTab: onNavigateToTab),
        ),
        const SizedBox(width: AppSpace.md),

        // Supporting financial & analytics column
        const Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardWeeklyChart(),
              SizedBox(height: AppSpace.md),
              DashboardRecentTransactions(),
            ],
          ),
        ),
      ],
    );
  }
}
