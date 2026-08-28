import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../notifications_controller.dart';

/// نافذة التنبيهات والإشعارات الفورية
class DashboardNotificationsDialog extends ConsumerWidget {
  const DashboardNotificationsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const DashboardNotificationsDialog(),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          notifier.markAllAsRead();
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'التنبيهات والإشعارات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              if (state.notifications.isNotEmpty)
                TextButton(
                  onPressed: () => notifier.markAllAsRead(),
                  child: Text(
                    'مسح الكل',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: state.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : state.notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 40,
                                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'لا توجد تنبيهات حالياً',
                                style: GoogleFonts.cairo(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  fontSize: 13,
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
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          IconData icon = Icons.notifications_rounded;
                          Color color = AppColors.primary;

                          if (notification.title == 'حجز جديد') {
                            icon = Icons.event_available_rounded;
                            color = AppColors.primary;
                          } else if (notification.title == 'إضافة خدمة طبية') {
                            icon = Icons.medical_services_rounded;
                            color = AppColors.completed;
                          }

                          return InkWell(
                            onTap: () => notifier.markAsRead(notification.id),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                                horizontal: AppSpacing.sm,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              notification.title,
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                            if (!notification.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          notification.body,
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          _formatTimeAgo(notification.createdAt),
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: isDark
                                                ? AppColors.textHintDark
                                                : AppColors.textHintLight,
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
              child: Text(
                'إغلاق',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
