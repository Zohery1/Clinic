import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reports/presentation/reports_controller.dart';
import '../appointments_controller.dart';
import '../../domain/appointment_type_model.dart';

/// ويدجت اختيار نوع الكشف / الزيارة بنظام Soft Structuralism Tactile Card Chips مع شارات الأسعار.
class AppointmentTypePicker extends ConsumerWidget {
  final String? selectedTypeId;
  final ValueChanged<AppointmentTypeModel?> onTypeChanged;
  final bool enabled;

  const AppointmentTypePicker({
    super.key,
    required this.selectedTypeId,
    required this.onTypeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(appointmentTypesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 15,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'نوع الكشف / الزيارة',
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        typesAsync.when(
          data: (types) {
            if (types.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'لا توجد أنواع كشوفات مسجلة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((type) {
                final isSelected = type.id == selectedTypeId;
                return _buildTypeChip(
                  context: context,
                  type: type,
                  isSelected: isSelected,
                  onTap: enabled
                      ? () => onTypeChanged(isSelected ? null : type)
                      : null,
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 38,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Text(
            'تعذر تحميل أنواع الكشوفات',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required BuildContext context,
    required AppointmentTypeModel type,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.12)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    final textColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.30 : 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark indicator when selected
            if (isSelected) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            // Type name
            Text(
              type.name,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            // Nested price badge pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.20)
                    : (isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${type.price.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
