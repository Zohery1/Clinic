import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../primitives/app_badge.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class AppStatTrend {
  final double value;
  final bool isUp;
  final String? label;

  const AppStatTrend({
    required this.value,
    required this.isUp,
    this.label,
  });
}

/// Clinical Utility Stat Card. Flat slate card, clean border, zero unnecessary gradients.
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final AppStatTrend? trend;
  final VoidCallback? onTap;
  final bool isLoading;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.surface(context);
    final borderColor = AppColors.borderSubtle(context);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                if (isLoading)
                  Container(
                    width: 96,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: AppRadii.brXs,
                    ),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (subtitle != null || trend != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      if (subtitle != null)
                        Expanded(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textMuted(context),
                              height: 1.3,
                            ),
                          ),
                        ),
                      if (trend != null) ...[
                        const SizedBox(width: AppSpace.xs),
                        AppBadge(
                          label: '${trend!.isUp ? '+' : '-'}${trend!.value.toStringAsFixed(0)}%',
                          icon: trend!.isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: AppBadgeSize.sm,
                          variant: trend!.isUp ? AppBadgeVariant.success : AppBadgeVariant.danger,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}