import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Standardized list row tile for the clinic design system.
/// Features clean leading icon/avatar containers, crisp Arabic typography,
/// selection highlighting, and subtle ripple/hover effects.
class AppListTile extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final Color? leadingColor;

  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    this.leadingColor,
  });

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBg = widget.isSelected
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.primaryLight.withValues(alpha: 0.7))
        : (_isHovered && widget.onTap != null
            ? (isDark
                ? AppColors.surfaceDimDark
                : AppColors.surfaceDimLight)
            : Colors.transparent);

    final titleColor = widget.isSelected
        ? AppColors.primary
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    Widget? leadingWidget = widget.leading;
    if (leadingWidget != null && widget.leadingColor != null) {
      leadingWidget = Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: widget.leadingColor!.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        alignment: Alignment.center,
        child: leadingWidget,
      );
    }

    Widget content = Padding(
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            widget.trailing!,
          ],
        ],
      ),
    );

    final borderRadius = BorderRadius.circular(AppSpacing.radiusSm);

    Widget tile = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: baseBg,
        borderRadius: borderRadius,
        border: widget.isSelected
            ? Border.all(color: AppColors.primary, width: 1.0)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: borderRadius,
                splashColor: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
                child: content,
              )
            : content,
      ),
    );

    if (widget.onTap != null) {
      tile = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: tile,
      );
    }

    return tile;
  }
}
