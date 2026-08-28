import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../appointments_controller.dart';
import '../../domain/service_model.dart';

/// ويدجت اختيار الخدمات الإضافية وإضافة خدمة مخصصة
class AppointmentServicesPicker extends ConsumerWidget {
  final String clinicId;
  final List<ServiceModel> selectedServices;
  final ValueChanged<List<ServiceModel>> onServicesChanged;

  const AppointmentServicesPicker({
    super.key,
    required this.clinicId,
    required this.selectedServices,
    required this.onServicesChanged,
  });

  void _showAddCustomServiceDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    ClinicDialog.show(
      context: context,
      icon: Icons.medical_services_outlined,
      title: 'إضافة خدمة إضافية جديدة',
      subtitle: 'أدخل تفاصيل الخدمة وسعرها لإضافتها لهذا الموعد',
      maxWidth: 400,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الخدمة',
              hint: 'مثال: تخطيط قلب، غيار جروح...',
              prefixIcon: Icons.edit_outlined,
              controller: nameController,
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'يرجى إدخال اسم الخدمة' : null,
            ),
            const SizedBox(height: 12),
            ClinicFormField(
              label: 'السعر (ج.م)',
              hint: 'مثال: 150',
              prefixIcon: Icons.payments_outlined,
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'يرجى إدخال السعر';
                final p = double.tryParse(val.trim());
                if (p == null || p < 0) return 'سعر غير صالح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ClinicSecondaryButton(
          label: 'إلغاء',
          onPressed: () => Navigator.pop(context),
        ),
        ClinicPrimaryButton(
          label: 'إضافة الخدمة',
          icon: Icons.add_rounded,
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final newService = ServiceModel(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              clinicId: clinicId,
              name: nameController.text.trim(),
              price: double.parse(priceController.text.trim()),
            );
            final updated = List<ServiceModel>.from(selectedServices)..add(newService);
            onServicesChanged(updated);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(clinicServicesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الخدمات الطبية الإضافية',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddCustomServiceDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('خدمة مخصصة', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        servicesAsync.when(
          data: (services) {
            // دمج الخدمات المعرفة والخدمات المخصصة المحددة
            final allOptions = <ServiceModel>[...services];
            for (final s in selectedServices) {
              if (!allOptions.any((opt) => opt.id == s.id)) {
                allOptions.add(s);
              }
            }

            if (allOptions.isEmpty) {
              return const Text('لا توجد خدمات متاحة', style: TextStyle(fontSize: 12));
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allOptions.map((service) {
                final isSelected = selectedServices.any((s) => s.id == service.id);
                return FilterChip(
                  label: Text('${service.name} (+${service.price.toStringAsFixed(0)} ج.م)'),
                  selected: isSelected,
                  onSelected: (selected) {
                    final updated = List<ServiceModel>.from(selectedServices);
                    if (selected) {
                      updated.add(service);
                    } else {
                      updated.removeWhere((s) => s.id == service.id);
                    }
                    onServicesChanged(updated);
                  },
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('تعذر تحميل الخدمات', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}
