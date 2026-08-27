import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../appointments/presentation/appointments_screen.dart';
import '../../appointments/presentation/appointments_controller.dart';
import '../../patients/presentation/patients_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../reports/presentation/reports_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/subscription_warning_banner.dart';
import '../../auth/presentation/top_up_subscription_screen.dart';
import 'notifications_controller.dart';
import 'financial_panel.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';

/// الداشبورد الرئيسي — مطابق لتصميم Stitch
/// Sidebar (يمين RTL) + Top Header + محتوى 2/3 مواعيد + 1/3 مالية
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
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    // مؤقت فوري كل ثانية لإعادة التقييم لحظياً ومنع التخطي عند انتهاء الاشتراك
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }

  void _openRenewModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
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
  }

  @override
  Widget build(BuildContext context) {
    // تفعيل الاستماع الفوري لتغييرات المواعيد عبر الأجهزة المختلفة
    ref.watch(realtimeAppointmentsSyncProvider);

    // إذا انتهى تاريخ الاشتراك، يتم التحويل فوراً للشاشة الكاملة للتجديد ومحو الوصول لأي تاب
    final isExpired = widget.subscriptionEndDate != null &&
        widget.subscriptionEndDate!.isBefore(DateTime.now());

    if (isExpired) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: TopUpSubscriptionScreen(
            clinicName: widget.clinicName ?? 'العيادة',
            inviteCode: widget.inviteCode ?? '',
            clinicId: widget.clinicId ?? '',
            onRefresh: () {
              setState(() {});
            },
          ),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final user = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: isDesktop
            ? Row(
                children: [
                  // ─── Sidebar (يمين في RTL) ───
                  _buildSidebar(user),
                  // ─── المحتوى الرئيسي ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─── Top Header Bar ───
                        _buildTopHeader(user),
                        // ─── المحتوى حسب التاب المختار ───
                        Expanded(
                          child: _currentIndex == 0
                              ? _buildDashboardContent()
                              : _currentIndex == 1
                                  ? const PatientsScreen()
                                  : _currentIndex == 2
                                      ? const ReportsScreen()
                                      : const SettingsScreen(),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  if (_currentIndex != 0)
                    SafeArea(
                      bottom: false,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _currentIndex == 1
                                  ? 'سجل المرضى'
                                  : _currentIndex == 2
                                      ? 'التقارير المالية'
                                      : 'الإعدادات العامة',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                            const Spacer(),
                            const ClinicSwitcherButton(isCompact: true),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: _currentIndex == 0
                        ? AppointmentsScreen(
                            subscriptionEndDate: widget.subscriptionEndDate,
                            inviteCode: widget.inviteCode,
                            clinicName: widget.clinicName,
                            clinicId: widget.clinicId,
                          )
                        : _currentIndex == 1
                            ? const PatientsScreen()
                            : _currentIndex == 2
                                ? const ReportsScreen()
                                : const SettingsScreen(),
                  ),
                ],
              ),
        bottomNavigationBar: isDesktop
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.calendar_today_rounded, 'الرئيسية'),
                        _buildNavItem(1, Icons.people_outline_rounded, 'المرضى'),
                        if (user?.isOwner ?? false)
                          _buildNavItem(2, Icons.bar_chart_rounded, 'التقارير'),
                        _buildNavItem(3, Icons.settings_outlined, 'الإعدادات'),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Sidebar — SaaS Style: w-64 (256px) ───
  // ═══════════════════════════════════════════════
  Widget _buildSidebar(dynamic user) {
    final theme = Theme.of(context);
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo + Clinic Name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عيادتي',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                          letterSpacing: -0.01,
                        ),
                      ),
                      Text(
                        'لوحة التحكم الإدارية',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          _buildSidebarItem(0, Icons.grid_view_rounded, 'الرئيسية', true),
          _buildSidebarItem(1, Icons.people_alt_outlined, 'المرضى', false),
          if (user?.isOwner ?? false)
            _buildSidebarItem(2, Icons.trending_up_rounded, 'التقارير المالية', false),
          _buildSidebarItem(3, Icons.settings_suggest_outlined, 'الإعدادات العامة', false),
          
          const Spacer(),
          
          // User Profile Card (NO Image, letter-based initials avatar)
          if (user != null)
            _buildSidebarProfileCard(user),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, bool fillIcon) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Visual Left Indicator line
                if (isSelected)
                  Container(
                    width: 3.5,
                    height: 18,
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Icon(
                  icon,
                  color: isSelected
                      ? primaryColor
                      : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? primaryColor
                        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarProfileCard(UserModel user) {
    final theme = Theme.of(context);
    final isDoctor = user.role == UserRole.doctor;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Letter avatar (Initials based)
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            child: Text(
              user.fullName.trim().isEmpty ? 'ع' : user.fullName.trim().substring(0, 1),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isDoctor ? 'طبيب' : 'سكرتارية',
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              ref.read(currentUserProvider.notifier).state = null;
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            color: theme.colorScheme.error.withValues(alpha: 0.8),
            tooltip: 'تسجيل الخروج',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Top Header Bar — SaaS Layout ───
  // ═══════════════════════════════════════════════

  // ═══════════════════════════════════════════════
  // ─── Top Header Bar — SaaS Layout ───
  // ═══════════════════════════════════════════════
  Widget _buildTopHeader(dynamic user) {
    final theme = Theme.of(context);
    String sectionTitle = 'لوحة التحكم الرئيسية';
    if (_currentIndex == 1) sectionTitle = 'سجل المرضى';
    if (_currentIndex == 2) sectionTitle = 'التقرير المالي العام';
    if (_currentIndex == 3) sectionTitle = 'الإعدادات العامة';

    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.notifications.where((n) => !n.isRead).length;

    final showWarning = widget.subscriptionEndDate != null &&
        widget.subscriptionEndDate!.isAfter(DateTime.now()) &&
        widget.subscriptionEndDate!.difference(DateTime.now()).inHours <= 48;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Section Title
          Text(
            sectionTitle,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: theme.textTheme.titleMedium?.color,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(width: 16),
          const ClinicSwitcherButton(),
          Expanded(
            child: showWarning
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SubscriptionWarningBanner(
                        endDate: widget.subscriptionEndDate!,
                        onRenewPressed: _openRenewModal,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Notifications
          _buildHeaderIconButton(
            Icons.notifications_none_rounded,
            badge: unreadCount > 0,
            onTap: () => _showNotificationsDialog(context),
          ),
          const SizedBox(width: 8),
          // Settings
          _buildHeaderIconButton(
            Icons.settings_outlined,
            onTap: () => setState(() => _currentIndex = 3),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return 'منذ ${diff.inDays} يوم';
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(notificationsProvider);
          final notifier = ref.read(notificationsProvider.notifier);
          final theme = Theme.of(context);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: PopScope(
              onPopInvokedWithResult: (didPop, _) {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.notifications_active_rounded,
                              color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'التنبيهات والإشعارات',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    if (state.notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          notifier.markAllAsRead();
                        },
                        child: Text(
                          'مسح الكل',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: state.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : state.notifications.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.notifications_off_outlined,
                                        size: 40, color: theme.hintColor),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد تنبيهات حالياً',
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: state.notifications.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final notification = state.notifications[index];
                                IconData icon = Icons.notifications_rounded;
                                Color color = theme.colorScheme.primary;

                                if (notification.title == 'حجز جديد') {
                                  icon = Icons.event_available_rounded;
                                  color = Colors.blue;
                                } else if (notification.title == 'إضافة خدمة طبية') {
                                  icon = Icons.medical_services_rounded;
                                  color = Colors.purple;
                                }

                                return InkWell(
                                  onTap: () {
                                    notifier.markAsRead(notification.id);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(icon, color: color, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    notification.title,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (!notification.isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: theme.colorScheme.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                notification.body,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.textTheme.bodyMedium?.color
                                                      ?.withValues(alpha: 0.8),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatTimeAgo(notification.createdAt),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.hintColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      notifier.markAllAsRead();
                      Navigator.pop(context);
                    },
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      ref.read(notificationsProvider.notifier).markAllAsRead();
    });
  }

  Widget _buildHeaderIconButton(IconData icon, {bool badge = false, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), size: 19),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Dashboard Content — PC Redesign ───
  // ═══════════════════════════════════════════════
  Widget _buildDashboardContent() {
    final todayRevenue = ref.watch(todayRevenueProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Stats Banner (Daily Revenue & Total Cases) ───
          Row(
            children: [
              // Card 1: دخل اليوم المختار
              Expanded(
                child: _buildKPIBlock(
                  title: 'إيراد اليوم المختار',
                  valueWidget: todayRevenue.when(
                    data: (val) => Text(
                      '${val.toStringAsFixed(0)} ج.م',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Text('--'),
                  ),
                  icon: Icons.monetization_on_outlined,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              // Card 2: عدد حالات اليوم
              Expanded(
                child: _buildKPIBlock(
                  title: 'إجمالي حالات اليوم المختار',
                  valueWidget: appointmentsAsync.when(
                    data: (list) => Text(
                      '${list.length}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Text('--'),
                  ),
                  icon: Icons.people_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // ─── Main Content Split Layout ───
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1/3 — Financial Panel
                Container(
                  constraints: const BoxConstraints(maxWidth: 340, minWidth: 280),
                  child: const FinancialPanel(),
                ),
                const SizedBox(width: 24),
                // 2/3 — Appointments Screen (fully scrollable, handles 50+ cases)
                const Expanded(
                  child: AppointmentsScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIBlock({
    required String title,
    required Widget valueWidget,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              valueWidget,
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Mobile Bottom Nav ───
  // ═══════════════════════════════════════════════
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
