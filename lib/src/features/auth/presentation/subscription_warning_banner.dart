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

    if (days > 0) {
      if (hours > 0) {
        return '$days يوم و $hours ساعة';
      }
      return '$days يوم';
    } else if (hours > 0) {
      return '$hours ساعة';
    } else {
      final mins = diff.inMinutes % 60;
      return '$mins دقيقة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingText = _formatRemainingTime();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft amber background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تنبيه اقتراب انتهاء الاشتراك',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF92400E),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ينتهي اشتراك عيادتك بعد ($remainingText). يرجى التجديد لتجنب توقف الخدمة.',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFB45309),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onRenewPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.flash_on_rounded, size: 15),
            label: Text(
              'تجديد الآن',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
