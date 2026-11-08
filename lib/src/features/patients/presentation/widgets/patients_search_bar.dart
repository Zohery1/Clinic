import 'package:flutter/material.dart';

/// شريط بحث المرضى مع خيار البحث برقم الملف فقط
class PatientsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isSearching;
  final bool searchByFileOnly;
  final ValueChanged<bool> onToggleFileOnly;

  const PatientsSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isSearching,
    required this.searchByFileOnly,
    required this.onToggleFileOnly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: searchByFileOnly
                    ? 'ابحث برقم الملف الطبي...'
                    : 'ابحث باسم المريض أو رقم الهاتف أو رقم الملف...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: onClear,
            ),
          if (isSearching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 4),
          Container(
            height: 24,
            width: 1,
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('رقم الملف فقط', style: TextStyle(fontSize: 11)),
            selected: searchByFileOnly,
            onSelected: onToggleFileOnly,
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            checkmarkColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
