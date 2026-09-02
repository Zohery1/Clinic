import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/shadows.dart';
import '../tokens/motion.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, destructive }

enum AppButtonSize { sm, md, lg }

/// Premium Enterprise SaaS button. Full-width by default.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool disabled;
  final bool expand;
  final AppButtonSize size;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.disabled = false,
    this.expand = true,
    this.size = AppButtonSize.md,
    this.variant = AppButtonVariant.primary,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  double get _height {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 32;
      case AppButtonSize.md:
        return 40;
      case AppButtonSize.lg:
        return 48;
    }
  }

  double get _hPad {
    switch (widget.size) {
      case AppButtonSize.sm:
        return AppSpace.md;
      case AppButtonSize.md:
        return AppSpace.lg;
      case AppButtonSize.lg:
        return AppSpace.xl;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 13;
      case AppButtonSize.md:
        return 14;
      case AppButtonSize.lg:
        return 15;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppButtonSize.sm:
        return 14;
      case AppButtonSize.md:
        return 16;
      case AppButtonSize.lg:
        return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isInteractive = !widget.disabled && !widget.loading && widget.onPressed != null;

    final background = _resolveBackground(isDark);
    final foreground = _resolveForeground(isDark);
    final border = _resolveBorder(isDark);

    final radius = BorderRadius.circular(
      widget.variant == AppButtonVariant.ghost ? AppRadii.radiusSm : AppRadii.radiusMd,
    );

    final width = widget.expand ? double.infinity : null;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      width: width,
      height: _height,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: border == null ? null : Border.all(color: border, width: 1),
        boxShadow: widget.variant == AppButtonVariant.primary && isInteractive
            ? AppShadows.sm(context)
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: isInteractive ? widget.onPressed : null,
          onHover: (v) => setState(() => _hovered = v && isInteractive),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _hPad),
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: widget.loading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: _iconSize + 2,
                        height: _iconSize + 2,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      )
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: _iconSize, color: foreground),
                            const SizedBox(width: AppSpace.sm),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.cairo(
                              fontSize: _fontSize,
                              fontWeight: FontWeight.w700,
                              color: foreground,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveBackground(bool isDark) {
    if (widget.disabled) {
      return isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _hovered ? AppColors.primaryHover : AppColors.primary;
      case AppButtonVariant.secondary:
        return _hovered
            ? (isDark ? AppColors.darkSubtle : AppColors.lightSubtle)
            : AppColors.surface(context);
      case AppButtonVariant.ghost:
        return _hovered
            ? (isDark ? AppColors.darkSubtle : AppColors.lightSubtle)
            : Colors.transparent;
      case AppButtonVariant.danger:
      case AppButtonVariant.destructive:
        return _hovered ? AppColors.dangerBright : AppColors.danger;
    }
  }

  Color _resolveForeground(bool isDark) {
    if (widget.disabled) {
      return AppColors.textMuted(context);
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
      case AppButtonVariant.destructive:
        return AppColors.onPrimary;
      case AppButtonVariant.secondary:
        return AppColors.textPrimary(context);
      case AppButtonVariant.ghost:
        return AppColors.textPrimary(context);
    }
  }

  Color? _resolveBorder(bool isDark) {
    if (widget.variant == AppButtonVariant.ghost) return null;
    if (widget.variant == AppButtonVariant.primary ||
        widget.variant == AppButtonVariant.danger ||
        widget.variant == AppButtonVariant.destructive) {
      return null;
    }
    return AppColors.border(context);
  }
}
