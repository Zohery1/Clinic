import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/motion.dart';

enum AppChipVariant { filter, tag }

/// Filter chip (selectable with check) or read-only tag chip.
class AppChip extends StatefulWidget {
  final String label;
  final AppChipVariant variant;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final Color? color;

  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.tag,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.color,
  });

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = widget.color ?? AppColors.primary;
    final active = widget.variant == AppChipVariant.filter && widget.selected;

    final bg = active
        ? accent.withValues(alpha: isDark ? 0.22 : 0.12)
        : (_hovered && widget.onSelected != null
            ? (isDark ? AppColors.darkSubtle : AppColors.lightSubtle)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface));
    final border = active
        ? accent.withValues(alpha: 0.5)
        : AppColors.border(context);
    final fg = active ? accent : AppColors.textPrimary(context);

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.radiusFull),
        border: Border.all(color: border, width: 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.radiusFull),
          onTap: widget.onSelected == null
              ? null
              : () => widget.onSelected!(!widget.selected),
          onHover: (v) => setState(() => _hovered = v),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (active)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: Icon(Icons.check_rounded, size: 14, color: fg),
                  )
                else if (widget.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: Icon(widget.icon, size: 14, color: fg),
                  ),
                Text(
                  widget.label,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
