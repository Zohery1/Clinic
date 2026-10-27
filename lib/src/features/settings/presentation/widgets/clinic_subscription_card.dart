import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/top_up_subscription_screen.dart';
import '../settings_providers.dart';

/// بطاقة تفاصيل اشتراك العيادة والوقت المتبقي مع زر التجديد
class ClinicSubscriptionCard extends ConsumerWidget {
  final UserModel user;

  const ClinicSubscriptionCard({
    super.key,
    required this.user,
  });

  String _formatSubscriptionRemaining(DateTime? endDate, String status) {
    if (status == 'suspended' || status == 'expired') return 'انتهى الاشتراك';
    if (endDate == null) return 'غير محدد';
    final diff = endDate.difference(DateTime.now());
    if (diff.isNegative) return 'انتهى الاشتراك';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0 && hours > 0) return 'باقي $days يوم و $hours ساعة';
    if (days > 0) return 'باقي $days يوم';
    if (hours > 0 && minutes > 0) return 'باقي $hours ساعة و $minutes دقيقة';
    if (hours > 0) return 'باقي $hours ساعة';
    if (minutes > 0) return 'باقي $minutes دقيقة';
    return 'أقل من دقيقة';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(clinicSubscriptionProvider);
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1626) : AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2E4A) : AppColors.borderSubtle(context),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: subAsync.when(
        data: (info) {
          final remainingStr = _formatSubscriptionRemaining(info.endDate, info.status);
          final isExpiringSoon = info.endDate != null &&
              info.endDate!.isAfter(DateTime.now()) &&
              info.endDate!.difference(DateTime.now()).inHours <= 48;
          final isExpired = info.status == 'expired' ||
              (info.endDate != null && info.endDate!.isBefore(DateTime.now()));

          final badgeColor = isExpired
              ? AppColors.danger
              : isExpiringSoon
                  ? AppColors.warning
                  : AppColors.success;

          final badgeBg = isDark
              ? badgeColor.withValues(alpha: 0.15)
              : (isExpired
                  ? AppColors.dangerSubtle
                  : isExpiringSoon
                      ? AppColors.warningSubtle
                      : AppColors.successSubtle);

          final badgeText = isExpired
              ? 'منتهي'
              : isExpiringSoon
                  ? 'ينتهي قريباً'
                  : 'نشط';

          final formattedDate = info.endDate != null
              ? DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(info.endDate!)
              : 'غير محدد';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpace.sm),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Text(
                        'اشتراك العيادة',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeText,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Divider(height: 1, color: AppColors.borderSubtle(context)),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوقت المتبقي:',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          remainingStr,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isExpired || isExpiringSoon
                                ? AppColors.warning
                                : AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (info.endDate != null) ...[
                    Container(
                      height: 32,
                      width: 1,
                      color: AppColors.borderSubtle(context),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الانتهاء:',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formattedDate,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final inviteCode = ref.read(inviteCodeProvider).value ?? '';
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
                              clinicName: info.clinicName,
                              inviteCode: inviteCode,
                              clinicId: user.clinicId,
                              onRefresh: () {
                                Navigator.of(ctx).pop();
                                ref.invalidate(clinicSubscriptionProvider);
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: Text(
                    'تجديد الاشتراك / شحن الرصيد',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpace.lg),
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
        error: (_, __) => Center(
          child: Text(
            'تعذر تحميل بيانات الاشتراك',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}
