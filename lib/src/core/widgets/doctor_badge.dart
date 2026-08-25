import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// شارة هوية الطبيب الموحدة — تظهر على كل الكروت (طابور، مواعيد، تقارير)
/// لون ثابت لكل طبيب مشتق من معرفه + حرف أول الاسم.
class DoctorBadge extends StatelessWidget {
  final String? doctorId;
  final String? doctorName;
  final bool compact; // نسخة مصغرة للكروت المزدحمة

  const DoctorBadge({
    super.key,
    required this.doctorId,
    required this.doctorName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = (doctorName == null || doctorName!.trim().isEmpty) ? null : doctorName!;
    if (name == null) return const SizedBox.shrink();

    final color = AppTheme.doctorColor(doctorId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color.withValues(alpha: isDark ? 0.22 : 0.12);
    final fg = isDark ? color.withValues(alpha: 1.0) : color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 14 : 16,
            height: compact ? 14 : 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              name.trim().isNotEmpty ? name.trim().substring(0, 1) : 'د',
              style: GoogleFonts.cairo(
                fontSize: compact ? 8 : 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'د. $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
