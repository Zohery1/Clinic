import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../patients/data/patient_repository.dart';
import '../../../patients/domain/patient_model.dart';

/// ويدجت اختيار المريض مع الإكمال التلقائي وزر تسجيل مريض جديد سريع
class AppointmentPatientPicker extends ConsumerWidget {
  final String clinicId;
  final String? selectedPatientId;
  final ValueChanged<PatientModel?> onPatientSelected;
  final void Function(TextEditingController controller)? onControllerReady;

  const AppointmentPatientPicker({
    super.key,
    required this.clinicId,
    required this.selectedPatientId,
    required this.onPatientSelected,
    this.onControllerReady,
  });

  void _showAddPatientDialog(
    BuildContext context,
    WidgetRef ref,
    String initialName,
    TextEditingController autocompleteController,
  ) {
    final addPatientFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final ageController = TextEditingController();
    final medicalHistoryController = TextEditingController();
    String? selectedGender;

    ClinicDialog.show(
      context: context,
      icon: Icons.person_add_alt_1_rounded,
      title: 'تسجيل مريض جديد سريع',
      subtitle: 'سيتم تسجيل المريض وتحديده تلقائياً في نافذة الحجز',
      maxWidth: 480,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: addPatientFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                ClinicFormField(
                  label: 'الاسم الكامل للمريض',
                  hint: 'مثال: محمد أحمد علي',
                  prefixIcon: Icons.person_outline,
                  controller: nameController,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 14),
                ClinicFormField(
                  label: 'رقم الهاتف',
                  hint: 'مثال: 01012345678',
                  prefixIcon: Icons.phone_outlined,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClinicFormField(
                        label: 'العمر (بالسنوات)',
                        hint: 'مثال: 35',
                        prefixIcon: Icons.cake_outlined,
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'يرجى إدخال العمر';
                          }
                          final age = int.tryParse(val.trim());
                          if (age == null || age <= 0 || age > 150) {
                            return 'يرجى إدخال عمر صحيح';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              'الجنس',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => selectedGender = 'male'),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: selectedGender == 'male'
                                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                                          : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.male_rounded,
                                          size: 16,
                                          color: selectedGender == 'male'
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).hintColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ذكر',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selectedGender == 'male' ? FontWeight.bold : FontWeight.normal,
                                            color: selectedGender == 'male'
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => selectedGender = 'female'),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: selectedGender == 'female'
                                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                                          : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.female_rounded,
                                          size: 16,
                                          color: selectedGender == 'female'
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).hintColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'أنثى',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selectedGender == 'female' ? FontWeight.bold : FontWeight.normal,
                                            color: selectedGender == 'female'
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClinicFormField(
                  label: 'العنوان',
                  hint: 'مثال: المعادي، القاهرة',
                  prefixIcon: Icons.location_on_outlined,
                  controller: addressController,
                  optional: true,
                ),
                const SizedBox(height: 14),
                ClinicFormField(
                  label: 'السجل المرضي والملاحظات الطبية',
                  hint: 'حساسية أدوية، أمراض مزمنة...',
                  prefixIcon: Icons.history_edu_outlined,
                  controller: medicalHistoryController,
                  maxLines: 2,
                  optional: true,
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        ClinicSecondaryButton(
          label: 'إلغاء',
          onPressed: () => Navigator.pop(context),
        ),
        ClinicPrimaryButton(
          label: 'حفظ وتحديد المريض',
          icon: Icons.check_rounded,
          onPressed: () async {
            if (!addPatientFormKey.currentState!.validate()) return;
            try {
              DateTime? birthDate;
              if (ageController.text.trim().isNotEmpty) {
                final age = int.tryParse(ageController.text.trim());
                if (age != null && age > 0) {
                  final now = DateTime.now();
                  birthDate = DateTime(now.year - age, now.month, now.day);
                }
              }

              final newPatient = await ref.read(patientRepositoryProvider).createPatient(
                    clinicId: clinicId,
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                    gender: selectedGender,
                    birthDate: birthDate,
                    address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
                    medicalHistory: medicalHistoryController.text.trim().isNotEmpty
                        ? medicalHistoryController.text.trim()
                        : null,
                  );

              ref.invalidate(patientsListProvider(clinicId));
              autocompleteController.text = newPatient.fullName;
              onPatientSelected(newPatient);

              if (context.mounted) {
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppTheme.error),
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsListProvider(clinicId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المريض *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        patientsAsync.when(
          data: (patients) {
            return Autocomplete<PatientModel>(
              displayStringForOption: (p) => p.fullName,
              initialValue: selectedPatientId != null
                  ? TextEditingValue(
                      text: patients
                          .firstWhere(
                            (p) => p.id == selectedPatientId,
                            orElse: () => PatientModel(
                              id: '',
                              clinicId: '',
                              fullName: '',
                              createdAt: DateTime.now(),
                            ),
                          )
                          .fullName,
                    )
                  : null,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<PatientModel>.empty();
                }
                final query = textEditingValue.text.trim().toLowerCase();
                return patients.where((p) {
                  final nameMatch = p.fullName.toLowerCase().contains(query);
                  final phoneMatch = p.phone != null && p.phone!.contains(query);
                  return nameMatch || phoneMatch;
                });
              },
              onSelected: (patient) {
                onPatientSelected(patient);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                onControllerReady?.call(controller);
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو رقم الهاتف...',
                    prefixIcon: const Icon(Icons.person_search_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.person_add_outlined, size: 20),
                      tooltip: 'تسجيل مريض جديد',
                      onPressed: () => _showAddPatientDialog(context, ref, controller.text, controller),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (selectedPatientId == null && (val == null || val.trim().isEmpty)) {
                      return 'يرجى اختيار مريض';
                    }
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surface,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                p.fullName.isNotEmpty ? p.fullName[0] : '؟',
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            title: Text(p.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: p.phone != null ? Text(p.phone!, style: const TextStyle(fontSize: 11)) : null,
                            onTap: () => onSelected(p),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('تعذر تحميل قائمة المرضى'),
        ),
      ],
    );
  }
}
