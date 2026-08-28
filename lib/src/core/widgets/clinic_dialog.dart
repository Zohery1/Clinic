import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════
// ClinicDialog — نظام حوارات موحد للتطبيق
// يدعم ثلاثة أنواع: form / confirm / info
// ══════════════════════════════════════════════════════════

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

  // ─── Static helpers ───────────────────────────────────

  /// حوار نموذج (إضافة / تعديل)
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

  /// حوار تأكيد (حذف / إلغاء)
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
    final iconBg = (iconColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.12);
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).colorScheme.surface,
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
            // ─── Header ───
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 14 : 20,
                isMobile ? 12 : 20,
                isMobile ? 12 : 16,
                isMobile ? 8 : 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? Theme.of(context).colorScheme.primary,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: Theme.of(context).hintColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // ─── Content ───
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 20,
                  isMobile ? 10 : 16,
                  isMobile ? 14 : 20,
                  isMobile ? 6 : 8,
                ),
                child: content,
              ),
            ),
            // ─── Actions ───
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 20,
                  isMobile ? 8 : 12,
                  isMobile ? 14 : 20,
                  isMobile ? 10 : 16,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                        minimumSize: WidgetStateProperty.all(Size(80, isMobile ? 36 : 40)),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions
                        .expand((w) => [w, const SizedBox(width: 8)])
                        .toList()
                      ..removeLast(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// _ConfirmDialog — حوار تأكيد مع loading state
// ══════════════════════════════════════════════════════════
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
      (widget.isDangerous
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // icon + title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _actionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: _actionColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDangerous
                        ? _actionColor.withValues(alpha: 0.05)
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(widget.cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.confirmLabel,
                                style: const TextStyle(fontWeight: FontWeight.w700),
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
    );
  }
}

// ══════════════════════════════════════════════════════════
// ClinicFormField — حقل إدخال موحد
// ══════════════════════════════════════════════════════════

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
    final labelWidget = Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 4),
          Text(
            '(اختياري)',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 5), child: labelWidget),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          readOnly: readOnly,
          onTap: onTap,
          onTapOutside: (_) {},
          scrollPadding: const EdgeInsets.all(20.0),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6))
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

/// حقل Dropdown موحد
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
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 4),
                Text('(اختياري)',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
              ],
            ],
          ),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6))
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ],
    );
  }
}

/// Divider مع عنوان لتقسيم أقسام الفورم
class ClinicFormSection extends StatelessWidget {
  final String title;
  final IconData? icon;

  const ClinicFormSection({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ],
      ),
    );
  }
}

/// زر أساسي موحد للحوارات والشاشات
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
    final theme = Theme.of(context);
    final bgColor = isDangerous ? theme.colorScheme.error : theme.colorScheme.primary;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(88, height ?? 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
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

/// زر ثانوي موحد للحوارات والشاشات
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
          borderRadius: BorderRadius.circular(10),
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

