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
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Toast width
    const toastWidth = 340.0;
    
    // Calculate horizontal margin to center the toast on desktop or wide screens
    final horizontalMargin = screenWidth > 600 ? (screenWidth - toastWidth) / 2 : 20.0;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.up,
          margin: EdgeInsets.only(
            top: topPadding + 10,
            bottom: screenHeight - topPadding - 85, // positions it cleanly at the top
            left: horizontalMargin,
            right: horizontalMargin,
          ),
          backgroundColor: color,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
