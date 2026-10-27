import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ClinicToast {
  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, icon: Icons.check_circle_outline_rounded, color: AppTheme.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, icon: Icons.error_outline_rounded, color: AppTheme.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, icon: Icons.info_outline_rounded, color: AppTheme.primary);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, icon: Icons.warning_amber_rounded, color: AppTheme.warning);
  }

  static void show(BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Toast width
    const toastWidth = 340.0;
    
    // Calculate horizontal margin to center the toast on desktop or wide screens
    final horizontalMargin = screenWidth > 600 ? (screenWidth - toastWidth) / 2 : 20.0;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.up,
          margin: EdgeInsets.only(
            bottom: 24,
            left: horizontalMargin,
            right: horizontalMargin,
          ),
          backgroundColor: const Color(0xFF0B1324),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withValues(alpha: 0.45), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
