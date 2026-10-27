import 'package:flutter/material.dart';

import '../../../../core/ui/primitives/app_chip.dart';
import '../../../../core/ui/primitives/app_input.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';

class PatientsSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool searchByFileOnly;
  final ValueChanged<bool> onToggleFileOnly;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool compact;

  const PatientsSearchHeader({
    super.key,
    required this.controller,
    required this.searchByFileOnly,
    required this.onToggleFileOnly,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          hint: searchByFileOnly
              ? 'ابحث برقم الملف...'
              : (compact
                  ? 'ابحث بالاسم أو الهاتف...'
                  : 'ابحث بالاسم، الهاتف...'),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textMuted(context),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? _ClearButton(onClear: onClear)
              : null,
        ),
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppChip(
            label: compact ? 'رقم الملف' : 'بحث برقم الملف فقط',
            icon: Icons.tag_rounded,
            variant: AppChipVariant.filter,
            selected: searchByFileOnly,
            onSelected: onToggleFileOnly,
          ),
        ),
      ],
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onClear;
  const _ClearButton({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'مسح البحث',
      icon: Icon(
        Icons.clear_rounded,
        size: 18,
        color: AppColors.textMuted(context),
      ),
      onPressed: onClear,
    );
  }
}