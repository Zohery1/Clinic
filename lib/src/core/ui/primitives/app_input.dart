import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Premium text field. Subtle fill, 2px indigo focus ring, error state,
/// optional leading label, prefix/suffix icons.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.onEditingComplete,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    final fill = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final radius = BorderRadius.circular(AppRadii.radiusSm);

    final baseBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: hasError ? AppColors.danger : Colors.transparent,
        width: 1,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: hasError ? AppColors.danger : AppColors.primary,
        width: 2,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          validator: validator,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: obscure ? 1 : maxLines,
          minLines: minLines,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled
                ? AppColors.textPrimary(context)
                : AppColors.textMuted(context),
            height: 1.4,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? fill : (isDark ? AppColors.darkCanvas : AppColors.lightBorderSubtle),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted(context),
            ),
            errorText: errorText,
            errorStyle: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
              height: 1.3,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: baseBorder,
            enabledBorder: baseBorder,
            focusedBorder: focusedBorder,
            errorBorder: baseBorder,
            focusedErrorBorder: focusedBorder,
            disabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.borderSubtle(context), width: 1),
            ),
          ),
        ),
        if (helper != null && !hasError) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            helper!,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted(context),
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

