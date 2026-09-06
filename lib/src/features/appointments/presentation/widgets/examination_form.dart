import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../domain/service_model.dart';
import 'clinical_vitals_ribbon.dart';

class ExaminationForm extends StatelessWidget {
  final bool isDoctor;
  final TextEditingController complaintController;
  final TextEditingController diagnosisController;
  final TextEditingController instructionsController;
  final AsyncValue<List<ServiceModel>> availableServicesAsync;
  final List<ServiceModel> selectedServices;
  final void Function(ServiceModel, bool) onServiceToggled;
  final ClinicalVitalsData? vitals;
  final ValueChanged<ClinicalVitalsData>? onVitalsChanged;

  const ExaminationForm({
    super.key,
    required this.isDoctor,
    required this.complaintController,
    required this.diagnosisController,
    required this.instructionsController,
    required this.availableServicesAsync,
    required this.selectedServices,
    required this.onServiceToggled,
    this.vitals,
    this.onVitalsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderSubtle(context)),
      ),
      color: AppColors.surface(context),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            final reportSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_document,
                        size: 20,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'تقرير الجلسة والفحص الطبي',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── شريط المؤشرات الحيوية ───
                if (vitals != null && onVitalsChanged != null) ...[
                  ClinicalVitalsRibbon(
                    vitals: vitals!,
                    onChanged: onVitalsChanged!,
                    readOnly: !isDoctor,
                  ),
                  const SizedBox(height: 20),
                ],

                _buildFormField(
                  context,
                  label: 'الشكوى الرئيسية (Chief Complaint)',
                  hint: 'ما الذي يشكو منه المريض؟',
                  controller: complaintController,
                  readOnly: !isDoctor,
                  icon: Icons.record_voice_over_outlined,
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  context,
                  label: 'التشخيص الطبي (Diagnosis)',
                  hint: 'التشخيص الطبي للحالة...',
                  controller: diagnosisController,
                  readOnly: !isDoctor,
                  icon: Icons.medical_information_outlined,
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  context,
                  label: 'التعليمات والخطة العلاجية (Instructions & Plan)',
                  hint: 'أدوية، نصائح، أو مواعيد المراجعة...',
                  controller: instructionsController,
                  readOnly: !isDoctor,
                  icon: Icons.receipt_long_outlined,
                ),
              ],
            );

            final servicesSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        size: 18,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'الخدمات المقدمة',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary(context),
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
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: services.map((service) {
                        final isSelected =
                            selectedServices.any((s) => s.id == service.id);
                        return FilterChip(
                          selected: isSelected,
                          backgroundColor: AppColors.subtle(context),
                          selectedColor: AppColors.primarySubtle,
                          checkmarkColor: AppColors.primary,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderSubtle(context),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                service.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : AppColors.borderSubtle(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${service.price.toStringAsFixed(0)} ج.م',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onSelected: isDoctor
                              ? (selected) =>
                                  onServiceToggled(service, selected)
                              : null,
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text(
                    'خطأ في تحميل الخدمات: $e',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            );

            if (isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  reportSection,
                  const SizedBox(height: 32),
                  Divider(height: 1, color: AppColors.borderSubtle(context)),
                  const SizedBox(height: 24),
                  servicesSection,
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  reportSection,
                  const SizedBox(height: 24),
                  Divider(height: 1, color: AppColors.borderSubtle(context)),
                  const SizedBox(height: 20),
                  servicesSection,
                ],
              );
            }
          },
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
            Icon(icon,
                size: 16,
                color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: null,
          minLines: 3,
          style: GoogleFonts.cairo(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 13.5,
              color: AppColors.textMuted(context),
            ),
            filled: true,
            fillColor: AppColors.subtle(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderSubtle(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.borderSubtle(context),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(
                color: AppColors.primary,
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
