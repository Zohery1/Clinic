import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../appointments/presentation/appointments_screen.dart';
import '../../appointments/presentation/appointments_controller.dart';
import '../../patients/presentation/patients_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/presentation/top_up_subscription_screen.dart';
import 'widgets/dashboard_overview_tab.dart';

/// الشاشة الرئيسية لتطبيق العيادة
/// تعتمد شريط تنقل سفلي ثابت (Persistent BottomNavigationBar) يعمل عبر كافة المنصات (Mobile, Tablet, Web)
/// باستخدام IndexedStack للحفاظ على حالة التبويبات بدون إعادة بناء.
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
    // مؤقت للتحقق من صلاحية الاشتراك لحظياً
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

  void _navigateToTab(int index) {
    final isOwner = ref.read(currentUserProvider)?.isOwner ?? false;
    if (!isOwner && index == 3) {
      // إذا كان غير مالك، التبويب 3 يمثل الإعدادات في واجهته
      setState(() => _currentIndex = 3);
      return;
    }
    if (!isOwner && index > 3) {
      setState(() => _currentIndex = (index - 1).clamp(0, 3));
      return;
    }
    setState(() => _currentIndex = index.clamp(0, isOwner ? 4 : 3));
  }

  @override
  Widget build(BuildContext context) {
    // تفعيل الاستماع الفوري لتغييرات المواعيد عبر الأجهزة المختلفة
    ref.watch(realtimeAppointmentsSyncProvider);

    // التحقق من انتهاء تاريخ الاشتراك
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
            onRefresh: () => setState(() {}),
          ),
        ),
      );
    }

    final user = ref.watch(currentUserProvider);
    final isOwner = user?.isOwner ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // بناء قائمة الشاشات حسب صلاحية المالك
    final tabs = <Widget>[
      DashboardOverviewTab(
        subscriptionEndDate: widget.subscriptionEndDate,
        inviteCode: widget.inviteCode,
        clinicName: widget.clinicName,
        clinicId: widget.clinicId,
        onNavigateToTab: _navigateToTab,
      ),
      AppointmentsScreen(
        subscriptionEndDate: widget.subscriptionEndDate,
        inviteCode: widget.inviteCode,
        clinicName: widget.clinicName,
        clinicId: widget.clinicId,
      ),
      const PatientsScreen(),
      if (isOwner) const ReportsScreen(),
      const SettingsScreen(),
    ];

    // عناصر شريط التنقل السفلي
    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard_rounded),
        label: 'الرئيسية',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today_rounded),
        label: 'المواعيد',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline_rounded),
        activeIcon: Icon(Icons.people_rounded),
        label: 'المرضى',
      ),
      if (isOwner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'التقارير',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings_rounded),
        label: 'الإعدادات',
      ),
    ];

    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: IndexedStack(
          index: safeIndex,
          children: tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.colorScheme.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              selectedLabelStyle: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              elevation: 0,
              items: navItems,
            ),
          ),
        ),
      ),
    );
  }
}
