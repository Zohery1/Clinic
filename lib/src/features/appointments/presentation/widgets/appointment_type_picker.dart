import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../appointments_controller.dart';
import '../../domain/appointment_type_model.dart';

/// ويدجت اختيار نوع الكشف / الزيارة
class AppointmentTypePicker extends ConsumerWidget {
  final String? selectedTypeId;
  final ValueChanged<AppointmentTypeModel?> onTypeChanged;

  const AppointmentTypePicker({
    super.key,
    required this.selectedTypeId,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(appointmentTypesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الكشف / الزيارة',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 6),
        typesAsync.when(
          data: (types) {
            if (types.isEmpty) {
              return const Text('لا توجد أنواع كشوفات مسجلة', style: TextStyle(fontSize: 12));
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((type) {
                final isSelected = type.id == selectedTypeId;
                return ChoiceChip(
                  label: Text('${type.name} (${type.price.toStringAsFixed(0)} ج.م)'),
                  selected: isSelected,
                  onSelected: (selected) {
                    onTypeChanged(selected ? type : null);
                  },
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('تعذر تحميل أنواع الكشوفات', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}
