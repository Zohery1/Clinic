import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Standardized RTL search bar for the clinic design system.
/// Features prefix search icon, clear text button, optional trailing action/filter,
/// and calm medical styling.
class AppSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? trailing;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'بحث...',
    this.onChanged,
    this.onClear,
    this.trailing,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late bool _hasText;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
      _hasText = widget.controller.text.isNotEmpty;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final hasTextNow = widget.controller.text.isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() {
        _hasText = hasTextNow;
      });
    }
  }

  void _handleClear() {
    widget.controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHintLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.transparent,
                width: 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              textDirection: TextDirection.rtl,
              onChanged: widget.onChanged,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              decoration: InputDecoration(
                filled: false,
                isDense: true,
                hintText: widget.hintText,
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: hintColor,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 11,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: hintColor,
                ),
                suffixIcon: _hasText
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: hintColor,
                        tooltip: 'مسح',
                        onPressed: _handleClear,
                        splashRadius: 18,
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          widget.trailing!,
        ],
      ],
    );
  }
}
