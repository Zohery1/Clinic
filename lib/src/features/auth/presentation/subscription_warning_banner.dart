import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';

class SubscriptionWarningBanner extends StatelessWidget {
  final DateTime endDate;
  final VoidCallback onRenewPressed;

  const SubscriptionWarningBanner({
    super.key,
    required this.endDate,
    required this.onRenewPressed,
  });

  String _formatRemainingTime() {
    final diff = endDate.difference(DateTime.now());
    if (diff.isNegative) return 'انتهى الاشتراك';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    if (days > 0 && hours > 0) return '$days يوم و $hours ساعة';
    if (days > 0) return '$days يوم';
    if (hours > 0) return '$hours ساعة';
    return '${diff.inMinutes % 60} دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final remainingStr = _formatRemainingTime();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'متبقي على انتهاء باقة العيادة ($remainingStr). سارع بالتجديد لتفادي التوقف.',
              style: GoogleFonts.cairo(
                color: AppColors.warning,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: InkWell(
              onTap: onRenewPressed,
              borderRadius: BorderRadius.circular(AppRadii.full),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flash_on_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تجديد الباقة',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
