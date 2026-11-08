import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../primitives/app_button.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Clinical Utility Error State. Direct and concise.
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.tint(context, AppColors.danger),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.tintBorder(context, AppColors.danger),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 28,
                color: AppColors.tintText(context, AppColors.danger),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
                height: 1.3,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                width: 160,
                child: AppButton(
                  label: 'إعادة المحاولة',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  size: AppButtonSize.sm,
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