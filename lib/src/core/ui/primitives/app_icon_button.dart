import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/motion.dart';

enum AppIconButtonVariant { ghost, subtle, solid }

enum AppIconButtonSize { sm, md, lg }

/// Compact icon button with consistent dark-mode aware styling.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final AppIconButtonSize size;
  final String? tooltip;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppIconButtonVariant.ghost,
    this.size = AppIconButtonSize.md,
    this.tooltip,
    this.color,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hovered = false;

  double get _dim {
    switch (widget.size) {
      case AppIconButtonSize.sm:
        return 28;
      case AppIconButtonSize.md:
        return 36;
      case AppIconButtonSize.lg:
        return 40;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppIconButtonSize.sm:
        return 14;
      case AppIconButtonSize.md:
        return 18;
      case AppIconButtonSize.lg:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isInteractive = widget.onPressed != null;
    final radius = BorderRadius.circular(AppRadii.radiusSm);

    Color background;
    Color foreground;
    switch (widget.variant) {
      case AppIconButtonVariant.ghost:
        background = _hovered && isInteractive
            ? (isDark ? AppColors.darkSubtle : AppColors.lightSubtle)
            : Colors.transparent;
        foreground = widget.color ?? AppColors.textSecondary(context);
        break;
      case AppIconButtonVariant.subtle:
        background = _hovered && isInteractive
            ? (isDark ? AppColors.darkSubtle : AppColors.lightSubtle)
            : (isDark ? AppColors.darkSubtle : AppColors.lightSubtle);
        foreground = widget.color ?? AppColors.textPrimary(context);
        break;
      case AppIconButtonVariant.solid:
        background = _hovered && isInteractive
            ? AppColors.primaryHover
            : (widget.color ?? AppColors.primary);
        foreground = AppColors.onPrimary;
        break;
    }

    final button = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      width: _dim,
      height: _dim,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onPressed,
          onHover: (v) => setState(() => _hovered = v && isInteractive),
          child: Center(
            child: Icon(
              widget.icon,
              size: _iconSize,
              color: foreground,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(
      message: widget.tooltip!,
      child: button,
    );
  }
}
