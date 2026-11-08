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

                _buildHpiBuilder(context: context, controller: complaintController),
                _buildFormField(
                  context,
                  label: 'شكوى المريض (Chief Complaint)',
                  hint: 'أدخل شكوى المريض بالتفصيل...',
                  controller: complaintController,
                  readOnly: !isDoctor,
                  icon: Icons.record_voice_over_outlined,
                  quickChips: const [
                    'ألم حاد في المعدة',
                    'حموضة وارتجاع',
                    'حرارة مرتفعة',
                    'صداع مستمر',
                    'سعال وكحة',
                    'غثيان وقيء',
                    'إرهاق ودوخة',
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  context,
                  label: 'التشخيص الطبي (Diagnosis)',
                  hint: 'التشخيص السريري والتصنيف الطبي...',
                  controller: diagnosisController,
                  readOnly: !isDoctor,
                  icon: Icons.medical_information_outlined,
                  quickChips: const [
                    'التهاب حاد بالمعدة (Gastritis)',
                    'ارتجاع مريئي (GERD)',
                    'نزلة معوية حادة',
                    'التهاب الحلق واللوزتين',
                    'نزلة برد حادة',
                    'ارتفاع ضغط الدم',
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  context,
                  label: 'الروشتة وخطة العلاج (Rx)',
                  hint: 'الأدوية الموصوفة والجرعات وملاحظات المتابعة...',
                  controller: instructionsController,
                  readOnly: !isDoctor,
                  icon: Icons.receipt_long_outlined,
                  quickChips: const [
                    'قرص قبل الإفطار بنصف ساعة',
                    'قرص بعد الوجبات',
                    'مرتين يومياً لمدة 5 أيام',
                    'كل 8 ساعات عند اللزوم',
                    'راحة تامة وسوائل دافئة',
                    'إعادة الفحص بعد أسبوع',
                  ],
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
                    'تعذر تحميل الخدمات الطبية، يرجى إعادة المحاولة',
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

  /// HPI builder: tapping a structural template inserts an editable skeleton
  /// the doctor fills in place, so the history reads clinical rather than free.
  static const List<(String, String)> _hpiTemplates = [
    ('ألم متزايد', 'بدأت الشكوى قبل (…) وتتدرج في شدتها.\nتزداد سوءاً مع (…) وتخف مع (…).\nترافقها: (…). أي أعراض مرافقة أخرى: (…).'),
    ('أعراض هضمية', 'الأعراض بدأت قبل (…)، وتتعلق بالوجبات: (…).\nترافقها: (حرقة / غثيان / انتفاخ).\nلا يوجد (قيء دم / تغير بلون البراز) — (عدّل عند اللزوم).'),
    ('صداع متكرر', 'صداع متكرر منذ (…). موقعه: (…). طبيعته: (نابض / غامض / شريطي).\nيزداد مع (…) ويخف مع (…). ترافقه أعراض عصبية: (…).'),
    ('نزلة برد', 'الكحة/الزكام بدأ قبل (…) مع (حرارة / بحة / ألم بالجيوب).\nطبيعة الإفراز: (شفاف / أصفر مخاطي).\nلا يوجد (ضيق تنفس / ألم صدر).'),
  ];

  Widget _buildHpiBuilder({
    required BuildContext context,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_edu_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'بانى التاريخ المرضي:',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          for (final (title, skeleton) in _hpiTemplates)
            InkWell(
              onTap: () {
                if (!controller.text.contains(skeleton)) {
                  final cur = controller.text.trim();
                  controller.text = cur.isEmpty ? skeleton : '$cur\n$skeleton';
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 12, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
    List<String>? quickChips,
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
        if (quickChips != null && quickChips.isNotEmpty && !readOnly) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: quickChips.map((chip) {
              return InkWell(
                onTap: () {
                  final cur = controller.text.trim();
                  if (cur.isEmpty) {
                    controller.text = chip;
                  } else if (!cur.contains(chip)) {
                    controller.text = '$cur\n• $chip';
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.borderSubtle(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        chip,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
