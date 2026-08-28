import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standardized calm medical card container for the clinic design system.
/// Supports hover animations on desktop/web, selection states, custom headers/footers,
/// and light/dark theme adaptations.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final bool isSelected;
  final Widget? header;
  final Widget? footer;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.radius = AppSpacing.radiusMd,
    this.elevated = false,
    this.isSelected = false,
    this.header,
    this.footer,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final defaultBorder = isDark ? AppColors.borderDark : AppColors.borderLight;

    final effectiveBg = widget.backgroundColor ??
        (widget.isSelected
            ? (isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primaryLight.withValues(alpha: 0.6))
            : defaultBg);

    final effectiveBorder = widget.borderColor ??
        (widget.isSelected
            ? AppColors.primary
            : (_isHovered && widget.onTap != null
                ? (isDark ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5))
                : defaultBorder));

    final borderRadius = BorderRadius.circular(widget.radius);

    final boxShadow = widget.elevated || (_isHovered && widget.onTap != null)
        ? [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ]
        : (widget.isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              ]
            : null);

    Widget cardContent = widget.child;

    if (widget.header != null || widget.footer != null) {
      cardContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null) ...[
            Padding(
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
              child: widget.header!,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ],
          Padding(
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: widget.child,
          ),
          if (widget.footer != null) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            Padding(
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
              child: widget.footer!,
            ),
          ],
        ],
      );
    } else if (widget.padding != null) {
      cardContent = Padding(
        padding: widget.padding!,
        child: cardContent,
      );
    }

    Widget body = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: borderRadius,
        border: Border.all(
          color: effectiveBorder,
          width: widget.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: borderRadius,
                splashColor: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
                child: cardContent,
              )
            : cardContent,
      ),
    );

    if (widget.onTap != null) {
      body = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: body,
      );
    }

    return body;
  }
}
