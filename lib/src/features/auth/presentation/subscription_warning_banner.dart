import 'package:flutter/material.dart';

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

    return Material(
      elevation: 3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFD97706), // Amber-700
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تنبيه: ينتهي اشتراك عيادتك بعد ($remainingStr). يرجى التجديد الآن لتجنب توقف الخدمات.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  fontFamilyFallback: ['sans-serif', 'Arial'],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onRenewPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB45309),
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFB45309)),
              label: const Text(
                'تجديد الآن',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFFB45309),
                  fontFamilyFallback: ['sans-serif', 'Arial'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
