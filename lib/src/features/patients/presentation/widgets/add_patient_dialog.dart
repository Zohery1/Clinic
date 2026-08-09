import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/patient_repository.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';

class AddPatientDialog extends ConsumerStatefulWidget {
  final String clinicId;
  const AddPatientDialog({super.key, required this.clinicId});

  @override
  ConsumerState<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends ConsumerState<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  String? _selectedGender;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Widget _buildGenderToggle() {
    return Column(
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
                onTap: () => setState(() => _selectedGender = 'male'),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedGender == 'male'
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    // removed border
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male_rounded,
                        size: 18,
                        color: _selectedGender == 'male'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ذكر',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedGender == 'male' ? FontWeight.bold : FontWeight.normal,
                          color: _selectedGender == 'male'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = 'female'),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedGender == 'female'
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    // removed border
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female_rounded,
                        size: 18,
                        color: _selectedGender == 'female'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'أنثى',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedGender == 'female' ? FontWeight.bold : FontWeight.normal,
                          color: _selectedGender == 'female'
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;

    final col1 = [
      ClinicFormField(
        label: 'الاسم الكامل للمريض',
        hint: 'مثال: محمد أحمد علي',
        prefixIcon: Icons.person_outline,
        controller: _nameController,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم' : null,
      ),
      const SizedBox(height: 14),
      ClinicFormField(
        label: 'رقم الهاتف',
        hint: 'مثال: 01012345678',
        prefixIcon: Icons.phone_outlined,
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'يرجى إدخال رقم الهاتف';
          final clean = v.replaceAll(RegExp(r'\D'), '');
          if (clean.length < 11) return 'صيغة رقم الهاتف خاطئة (أقل من 11 رقم)';
          return null;
        },
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
              controller: _ageController,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال العمر';
                final age = int.tryParse(v.trim());
                if (age == null || age <= 0 || age > 150) return 'يرجى إدخال عمر صحيح';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGenderToggle(),
          ),
        ],
      ),
    ];

    final col2 = [
      ClinicFormField(
        label: 'العنوان',
        hint: 'مثال: المعادي، القاهرة',
        prefixIcon: Icons.location_on_outlined,
        controller: _addressController,
        optional: true,
      ),
      const SizedBox(height: 14),
      ClinicFormField(
        label: 'السجل المرضي والملاحظات',
        hint: 'الأمراض المزمنة أو أي ملاحظات طبية...',
        prefixIcon: Icons.description_outlined,
        controller: _medicalHistoryController,
        maxLines: 4,
        minLines: 3,
        optional: true,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClinicDialog(
        icon: Icons.person_add_alt_1_rounded,
        title: 'تسجيل مريض جديد',
        subtitle: 'البيانات المُدخلة ستُحفظ في سجل المريض',
        maxWidth: isMobile ? double.infinity : 640,
        content: Form(
          key: _formKey,
          child: isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [...col1, const SizedBox(height: 14), ...col2],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(children: col1)),
                    const SizedBox(width: 20),
                    Expanded(child: Column(children: col2)),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _savePatient,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('تسجيل وحفظ',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _savePatient([bool forceSave = false]) async {
    if (_selectedGender == null) {
      ClinicToast.showWarning(context, 'يرجى اختيار الجنس (ذكر أو أنثى)');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final fullName = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Smart similarity warning check (Solution 4)
      if (!forceSave) {
        final similar = await ref.read(patientRepositoryProvider).findSimilarPatients(
              widget.clinicId,
              fullName,
              phone,
            );

        if (similar.isNotEmpty) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          final first = similar.first;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    const Text('تنبيه: مريض مشابه مسجل مسبقاً'),
                  ],
                ),
                content: Text(
                  'عثر النظام على ملف مسجل باسم أو رقم مشابه جداً:\n\n'
                  '• ${first.fullName} (هاتف: ${first.phone ?? 'غير مسجل'})\n\n'
                  'هل ترغب في إنشاء ملف جديد أم الاستعانة بالملف القائم؟',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('تراجع / إلغاء'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.primary),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('إنشاء ملف جديد على أي حال'),
                  ),
                ],
              ),
            ),
          );

          if (confirm != true) return;
          setState(() => _isSaving = true);
        }
      }

      final age = int.tryParse(_ageController.text.trim());
      final birthDate = age != null ? DateTime(DateTime.now().year - age, 1, 1) : null;
      final address = _addressController.text.trim();
      final medicalHistory = _medicalHistoryController.text.trim();

      await ref.read(patientRepositoryProvider).createPatient(
            clinicId: widget.clinicId,
            fullName: fullName,
            phone: phone,
            gender: _selectedGender,
            address: address.isNotEmpty ? address : null,
            medicalHistory: medicalHistory.isNotEmpty ? medicalHistory : null,
            birthDate: birthDate,
          );

      ref.invalidate(patientsListProvider(widget.clinicId));

      if (mounted) {
        ClinicToast.showSuccess(context, 'تم تسجيل المريض بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ClinicToast.showError(context, 'خطأ: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
