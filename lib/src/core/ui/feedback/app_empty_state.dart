import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../primitives/app_button.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Calm medical empty state. Soft circular icon container, friendly copy,
/// and an optional primary action. Backed by the new token system.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final iconBg = Color.alphaBlend(
      AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
      AppColors.surface(context),
    );
    final iconBorder = AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.18);

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
              child: Icon(icon, size: 32, color: AppColors.primary),
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
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary(context),
                    height: 1.55,
                  ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: 220,
                child: AppButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  onPressed: onAction,
                  size: AppButtonSize.md,
                  variant: AppButtonVariant.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}