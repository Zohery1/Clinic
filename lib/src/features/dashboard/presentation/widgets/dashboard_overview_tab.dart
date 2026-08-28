import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/presentation/subscription_warning_banner.dart';
import '../../../auth/presentation/top_up_subscription_screen.dart';
import '../../../clinics/presentation/widgets/clinic_switcher_button.dart';
import '../notifications_controller.dart';
import '../financial_panel.dart';
import 'dashboard_stats_row.dart';
import 'dashboard_quick_actions.dart';
import 'dashboard_today_appointments.dart';
import 'dashboard_notifications_dialog.dart';

/// تبويب النظرة العامة الرئيسية للداشبورد (DashboardOverviewTab)
/// يعرض المؤشرات الحيوية والإجراءات السريعة وجدول مواعيد اليوم والتقرير المالي
class DashboardOverviewTab extends ConsumerWidget {
  final DateTime? subscriptionEndDate;
  final String? inviteCode;
  final String? clinicName;
  final String? clinicId;
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardOverviewTab({
    super.key,
    this.subscriptionEndDate,
    this.inviteCode,
    this.clinicName,
    this.clinicId,
    this.onNavigateToTab,
  });

  void _openRenewModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
            child: TopUpSubscriptionScreen(
              clinicName: clinicName ?? 'العيادة',
              inviteCode: inviteCode ?? '',
              clinicId: clinicId ?? '',
              onRefresh: () {
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrentDate() {
    try {
      final now = DateTime.now();
      return intl.DateFormat('EEEE، d MMMM y', 'ar').format(now);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.notifications.where((n) => !n.isRead).length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final showWarning = subscriptionEndDate != null &&
        subscriptionEndDate!.isAfter(DateTime.now()) &&
        subscriptionEndDate!.difference(DateTime.now()).inHours <= 48;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth >= 900 ? AppSpacing.xxl : AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Top Header (Greeting + Date + Actions) ───
              _buildOverviewHeader(
                context: context,
                user: user,
                unreadCount: unreadCount,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Subscription Warning Banner (if within 48h) ───
              if (showWarning) ...[
                SubscriptionWarningBanner(
                  endDate: subscriptionEndDate!,
                  onRenewPressed: () => _openRenewModal(context),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ─── Stats Row (4 KPI Cards) ───
              DashboardStatsRow(onNavigateToTab: onNavigateToTab),
              const SizedBox(height: AppSpacing.lg),

              // ─── Quick Actions ───
              DashboardQuickActions(
                clinicId: clinicId,
                onNavigateToTab: onNavigateToTab,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Responsive Content Area (Appointments & Financial) ───
              if (screenWidth >= 900)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DashboardTodayAppointments(
                        clinicId: clinicId,
                        onNavigateToTab: onNavigateToTab,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    SizedBox(
                      width: 360,
                      child: const FinancialPanel(),
                    ),
                  ],
                )
              else ...[
                DashboardTodayAppointments(
                  clinicId: clinicId,
                  onNavigateToTab: onNavigateToTab,
                ),
                const SizedBox(height: AppSpacing.xl),
                const FinancialPanel(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewHeader({
    required BuildContext context,
    required dynamic user,
    required int unreadCount,
    required bool isDark,
  }) {
    final displayName = user?.fullName ?? 'دكتور';
    final dateStr = _formatCurrentDate();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting & Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، $displayName 👋',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Clinic Switcher Button
        const ClinicSwitcherButton(isCompact: true),
        const SizedBox(width: AppSpacing.sm),

        // Notifications Icon Button
        _buildNotificationIconButton(
          context: context,
          unreadCount: unreadCount,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildNotificationIconButton({
    required BuildContext context,
    required int unreadCount,
    required bool isDark,
  }) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: () => DashboardNotificationsDialog.show(context),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                size: 20,
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
