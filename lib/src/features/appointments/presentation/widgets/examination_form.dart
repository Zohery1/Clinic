import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/service_model.dart';

class ExaminationForm extends StatelessWidget {
  final bool isDoctor;
  final TextEditingController complaintController;
  final TextEditingController diagnosisController;
  final TextEditingController instructionsController;
  final AsyncValue<List<ServiceModel>> availableServicesAsync;
  final List<ServiceModel> selectedServices;
  final void Function(ServiceModel, bool) onServiceToggled;

  const ExaminationForm({
    super.key,
    required this.isDoctor,
    required this.complaintController,
    required this.diagnosisController,
    required this.instructionsController,
    required this.availableServicesAsync,
    required this.selectedServices,
    required this.onServiceToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.edit_document, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'تقرير الجلسة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFormField(
              context,
              label: 'الشكوى الرئيسية',
              hint: 'ما الذي يشكو منه المريض؟',
              controller: complaintController,
              readOnly: !isDoctor,
              icon: Icons.record_voice_over_outlined,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              context,
              label: 'التشخيص الطبي',
              hint: 'التشخيص الطبي للحالة...',
              controller: diagnosisController,
              readOnly: !isDoctor,
              icon: Icons.medical_information_outlined,
            ),
            const SizedBox(height: 20),
            _buildFormField(
              context,
              label: 'تعليمات للمريض',
              hint: 'أدوية، نصائح، أو مواعيد المراجعة...',
              controller: instructionsController,
              readOnly: !isDoctor,
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.medical_services_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'الخدمات المقدمة',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            availableServicesAsync.when(
              data: (services) {
                if (services.isEmpty) {
                  return Text(
                    'لا توجد خدمات مضافة بعد.',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                  );
                }
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: services.map((service) {
                    final isSelected = selectedServices.any((s) => s.id == service.id);
                    return FilterChip(
                      selected: isSelected,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                            : Theme.of(context).dividerColor.withOpacity(0.1),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      label: Text(
                        '${service.name} — ${service.price.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      onSelected: isDoctor ? (selected) => onServiceToggled(service, selected) : null,
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, _) => Text('خطأ: $err', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool readOnly,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).hintColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: 4,
          minLines: 3,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: readOnly ? (controller.text.isEmpty ? 'لا توجد بيانات مدخلة.' : '') : hint,
            hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.15),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.15),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
