import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// شارة حالة موحدة — نص ملون على tint بنفس اللون (pill)
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11, vertical: compact ? 2 : 4),
      decoration: AppTheme.statusDecoration(color),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: compact ? 10 : 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
