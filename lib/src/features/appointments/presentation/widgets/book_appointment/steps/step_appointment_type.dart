import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/ui/tokens/colors.dart';
import '../../../../../../core/ui/tokens/spacing.dart';
import '../../../../../../core/ui/tokens/typography.dart';
import '../../../../../reports/presentation/reports_controller.dart';
import '../../../../domain/appointment_type_model.dart';

class StepAppointmentType extends ConsumerWidget {
  final String? selectedTypeId;
  final ValueChanged<AppointmentTypeModel?> onChanged;

  const StepAppointmentType({
    super.key,
    required this.selectedTypeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(appointmentTypesProvider);
    return typesAsync.when(
      data: (types) {
        if (types.isEmpty) {
          return Center(
            child: Text(
              'لا توجد أنواع كشوفات مسجلة',
              style: AppTypography.bodyMd(AppColors.textMuted(context)),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر نوع الكشف',
              style: AppTypography.headingLg(AppColors.textPrimary(context)),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'يحدد هذا السعر الأساسي للموعد',
              style: AppTypography.bodySm(AppColors.textSecondary(context)),
            ),
            const SizedBox(height: AppSpace.lg),
            Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: types.map((t) {
                final selected = t.id == selectedTypeId;
                return _TypeCard(
                  type: t,
                  selected: selected,
                  onTap: () => onChanged(selected ? null : t),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'تعذر تحميل الأنواع: $e',
          style: AppTypography.bodySm(AppColors.danger),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final AppointmentTypeModel type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.primary : AppColors.border(context);
    final bg = selected ? AppColors.primarySubtle : AppColors.surface(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.radiusMd),
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.radiusMd),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.medical_information_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      type.name,
                      style: AppTypography.headingSm(
                          AppColors.textPrimary(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                '${type.price.toStringAsFixed(0)} ج.م',
                style: AppTypography.numericMd(AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





