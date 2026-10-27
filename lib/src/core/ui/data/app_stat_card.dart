import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../primitives/app_badge.dart';
import '../tokens/colors.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

/// Trend descriptor for a KPI card.
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

/// Premium KPI card. Title in the top-left, tinted icon top-right,
/// big numeric value in the middle, subtitle + trend at the bottom.
/// Hover lifts the card subtly.
class AppStatCard extends StatefulWidget {
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
  State<AppStatCard> createState() => _AppStatCardState();
}

class _AppStatCardState extends State<AppStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isInteractive = widget.onTap != null;

    final bg = AppColors.surface(context);
    final borderColor = _hovered && isInteractive
        ? widget.color.withValues(alpha: isDark ? 0.60 : 0.45)
        : (isDark ? const Color(0xFF1E2E4A) : const Color(0xFFE2E8F0));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: _hovered && isInteractive ? 1.2 : 1.0,
          ),
          boxShadow: _hovered && isInteractive
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: isDark ? 0.16 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            splashColor: widget.color.withValues(alpha: 0.08),
            highlightColor: widget.color.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.lg - 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary(context),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.color
                              .withValues(alpha: isDark ? 0.18 : 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.color.withValues(alpha: isDark ? 0.35 : 0.20),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(widget.icon, size: 17, color: widget.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  if (widget.isLoading)
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
                      widget.value,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary(context),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (widget.subtitle != null || widget.trend != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.subtitle ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted(context),
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (isInteractive) ...[
                          const SizedBox(width: AppSpace.xs),
                          AnimatedOpacity(
                            duration: AppMotion.fast,
                            opacity: _hovered ? 1.0 : 0.0,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 11,
                              color: widget.color,
                            ),
                          ),
                        ],
                        if (widget.trend != null) ...[
                          const SizedBox(width: AppSpace.sm),
                          _TrendBadge(trend: widget.trend!),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final AppStatTrend trend;
  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: '${trend.isUp ? '+' : '-'}${trend.value.toStringAsFixed(0)}%',
      icon: trend.isUp
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded,
      size: AppBadgeSize.sm,
      variant: trend.isUp ? AppBadgeVariant.success : AppBadgeVariant.danger,
    );
  }
}