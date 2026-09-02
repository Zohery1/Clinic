import 'package:flutter/material.dart';

/// DEPRECATED: removed in Phase 4. Kept as an empty stub so old imports
/// continue to compile. Use `AppButton` from `lib/src/core/ui/primitives/app_button.dart`.
class MagneticNestedButton extends StatelessWidget {
  const MagneticNestedButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.primaryColor,
    this.secondaryColor,
    this.width,
    this.height = 52.0,
    this.isDangerous = false,
    this.enabled = true,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double? width;
  final double height;
  final bool isDangerous;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled && !isLoading ? onPressed : null,
      child: Text(label),
    );
  }
}