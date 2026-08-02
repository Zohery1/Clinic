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
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          border: Border(bottom: BorderSide(color: Colors.orange.shade800, width: 1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ينتهي اشتراك عيادتك بعد (${_formatRemainingTime()}). يرجى التجديد لتجنب توقف الخدمة.',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onRenewPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD97706),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('تجديد الآن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
