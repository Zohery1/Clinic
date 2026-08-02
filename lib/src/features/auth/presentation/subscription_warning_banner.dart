import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        color: const Color(0xFFFFF7ED), // Amber 50
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2), // Amber 300
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
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
              'تنبيه: ينتهي اشتراك عيادتك بعد ($remainingStr). يرجى التجديد الآن.',
              style: GoogleFonts.cairo(
                color: const Color(0xFFC2410C),
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
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onRenewPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      'تجديد الآن',
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

