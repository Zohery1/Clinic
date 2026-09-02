import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../primitives/app_button.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Red-tinted error placeholder with a friendly headline,
/// a one-line explanation, and an optional retry button.
class AppErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final iconBg = Color.alphaBlend(
      AppColors.danger.withValues(alpha: isDark ? 0.20 : 0.10),
      AppColors.surface(context),
    );
    final iconBorder = AppColors.danger.withValues(alpha: isDark ? 0.4 : 0.25);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                border: Border.all(color: iconBorder, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 32, color: AppColors.danger),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary(context),
                  height: 1.55,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: 200,
                child: AppButton(
                  label: 'إعادة المحاولة',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  size: AppButtonSize.md,
                  variant: AppButtonVariant.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}