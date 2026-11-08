import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/tokens/colors.dart';
import '../ui/tokens/spacing.dart';

/// Clinical Utility Unified Dialog System.
class ClinicDialog extends StatelessWidget {

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  const ClinicDialog({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.content,
    required this.actions,
    this.maxWidth = 480,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required Widget content,
    required List<Widget> actions,
    double maxWidth = 480,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ClinicDialog(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          content: content,
          actions: actions,
          maxWidth: maxWidth,
        ),
      ),
    );
  }

  static Future<bool?> confirm({
    required BuildContext context,
    IconData icon = Icons.warning_amber_rounded,
    Color? iconColor,
    required String title,
    required String description,
    required String confirmLabel,
    String cancelLabel = 'إلغاء',
    bool isDangerous = false,
    Future<void> Function()? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final iconBg = effectiveIconColor.withValues(alpha: 0.12);
    final isMobile = MediaQuery.of(context).size.width < 650;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            side: BorderSide(
              color: AppColors.borderSubtle(context),
              width: 1.0,
            ),
          ),
          backgroundColor: AppColors.surface(context),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 12 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 14 : 20,
                    isMobile ? 14 : 20,
                    isMobile ? 14 : 20,
                    isMobile ? 10 : 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Icon(
                          icon,
                          color: effectiveIconColor,
                          size: isMobile ? 18 : 20,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 14.5 : 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.textMuted(context),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 14 : 20,
                      isMobile ? 12 : 16,
                      isMobile ? 14 : 20,
                      isMobile ? 8 : 12,
                    ),
                    child: content,
                  ),
                ),

                // Actions
                if (actions.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions
                          .expand((w) => [w, const SizedBox(width: 8)])
                          .toList()
                        ..removeLast(),
                    ),
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

class _ConfirmDialog extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;
  final Future<void> Function()? onConfirm;

  const _ConfirmDialog({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDangerous,
    this.onConfirm,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _loading = false;

  Color get _actionColor =>
      widget.iconColor ??
      (widget.isDangerous ? AppColors.danger : AppColors.primary);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(false),
        },
        child: Focus(
          autofocus: true,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              side: BorderSide(
                color: AppColors.borderSubtle(context),
                width: 1.0,
              ),
            ),
            backgroundColor: AppColors.surface(context),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _actionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Icon(widget.icon, color: _actionColor, size: 20),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Text(
                        widget.description,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loading ? null : () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                            ),
                            child: Text(
                              widget.cancelLabel,
                              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () async {
                                    if (widget.onConfirm != null) {
                                      setState(() => _loading = true);
                                      try {
                                        await widget.onConfirm!();
                                        if (context.mounted) Navigator.pop(context, true);
                                      } catch (_) {
                                        if (mounted) setState(() => _loading = false);
                                        rethrow;
                                      }
                                    } else {
                                      Navigator.pop(context, true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _actionColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    widget.confirmLabel,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
}

class ClinicFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool optional;
  final VoidCallback? onTap;

  const ClinicFormField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.readOnly = false,
    this.optional = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 4),
                Text(
                  '(اختياري)',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.cairo(
            fontSize: 13.5,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: AppColors.textMuted(context))
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class ClinicDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final bool optional;

  const ClinicDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 4),
                Text(
                  '(اختياري)',
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted(context)),
                ),
              ],
            ],
          ),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.cairo(
            fontSize: 13.5,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: AppColors.textMuted(context))
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
          ),
        ),
      ],
    );
  }
}

class ClinicFormSection extends StatelessWidget {
  final String title;
  final IconData? icon;

  const ClinicFormSection({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: AppColors.borderSubtle(context))),
        ],
      ),
    );
  }
}

class ClinicPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDangerous;
  final double? height;

  const ClinicPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDangerous = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDangerous ? AppColors.danger : AppColors.primary;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(88, height ?? 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
    );
  }
}

class ClinicSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? height;

  const ClinicSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(72, height ?? 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
