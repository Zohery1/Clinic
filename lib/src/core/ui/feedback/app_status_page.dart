import 'package:flutter/material.dart';
import '../layout/auth_shell.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import '../tokens/shadows.dart';
import '../primitives/app_button.dart';

/// Unified status page for PendingActivation, TopUp, AccountBlocked,
/// SubscriptionGate and any other "non-authenticated" intermediate state.
class AppStatusPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final StatusAction? primaryAction;
  final StatusAction? secondaryAction;
  final Widget? hero;
  final bool compact;
  final bool useAuthShell;

  const AppStatusPage({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
    this.hero,
    this.compact = false,
    this.useAuthShell = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = _Content(
      hero: hero,
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      compact: compact,
    );

    if (useAuthShell) {
      return AuthShell(
        heroTitle: title,
        heroSubtitle: message,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class StatusAction {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  const StatusAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
  });
}

class _Content extends StatelessWidget {
  final Widget? hero;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final StatusAction? primaryAction;
  final StatusAction? secondaryAction;
  final bool compact;
  const _Content({
    required this.hero,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryAction,
    required this.secondaryAction,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final tint = Color.alphaBlend(
      iconColor.withValues(alpha: isDark ? 0.22 : 0.10),
      AppColors.surface(context),
    );
    final border = iconColor.withValues(alpha: isDark ? 0.4 : 0.25);

    final maxCardWidth = compact ? 480.0 : 520.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.xxxl),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppRadii.brLg,
            border: Border.all(color: AppColors.borderSubtle(context)),
            boxShadow: AppShadows.md(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hero != null) ...[
                hero!,
                const SizedBox(height: AppSpace.xl),
              ],
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint,
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 2),
                ),
                child: Icon(icon, size: 44, color: iconColor),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.displayMd(AppColors.textPrimary(context)),
              ),
              const SizedBox(height: AppSpace.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLg(AppColors.textSecondary(context)),
                ),
              ),
              if (primaryAction != null || secondaryAction != null) ...[
                const SizedBox(height: AppSpace.xxl),
                if (primaryAction != null)
                  AppButton(
                    label: primaryAction!.label,
                    icon: primaryAction!.icon,
                    onPressed: primaryAction!.onPressed,
                    loading: primaryAction!.loading,
                    variant: primaryAction!.variant,
                  ),
                if (primaryAction != null && secondaryAction != null)
                  const SizedBox(height: AppSpace.md),
                if (secondaryAction != null)
                  AppButton(
                    label: secondaryAction!.label,
                    icon: secondaryAction!.icon,
                    onPressed: secondaryAction!.onPressed,
                    variant: secondaryAction!.variant,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
