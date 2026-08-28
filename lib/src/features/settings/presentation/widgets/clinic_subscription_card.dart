import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_theme.dart';
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
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
              ? AppTheme.error
              : isExpiringSoon
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF16A34A);

          final badgeBg = isExpired
              ? const Color(0xFFFEE2E2)
              : isExpiringSoon
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFDCFCE7);

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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'اشتراك العيادة',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.textTheme.titleMedium?.color,
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
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
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
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainingStr,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isExpired || isExpiringSoon
                                ? const Color(0xFFEA580C)
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (info.endDate != null) ...[
                    Container(
                      height: 30,
                      width: 1,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الانتهاء:',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
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
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const Text('تعذر تحميل بيانات الاشتراك'),
      ),
    );
  }
}
