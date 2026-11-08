import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Thin Material Tooltip wrapper with consistent clinical style.
class AppTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Duration? waitDuration;
  final TooltipTriggerMode triggerMode;

  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration,
    this.triggerMode = TooltipTriggerMode.longPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      triggerMode: triggerMode,
      textStyle: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
        height: 1.3,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.lightSurface : AppColors.gray900,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: child,
    );
  }
}
