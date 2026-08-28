import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/appointment_repository.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../../../clinics/presentation/clinics_controller.dart';

/// ويدجت اختيار الطبيب والفرع لحجز أو تعديل الموعد
class AppointmentDoctorBranchPicker extends ConsumerWidget {
  final String clinicId;
  final String? selectedDoctorId;
  final String? selectedBranchId;
  final ValueChanged<String?> onDoctorChanged;
  final ValueChanged<String?> onBranchChanged;

  const AppointmentDoctorBranchPicker({
    super.key,
    required this.clinicId,
    required this.selectedDoctorId,
    required this.selectedBranchId,
    required this.onDoctorChanged,
    required this.onBranchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(clinicDoctorsProvider(clinicId));
    final branchesAsync = ref.watch(clinicBranchesProvider(clinicId));
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اختيار الطبيب
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الطبيب المعالج',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 6),
              doctorsAsync.when(
                data: (doctors) {
                  return DropdownButtonFormField<String?>(
                    value: selectedDoctorId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.primary.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('اختر الطبيب', style: TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('بدون طبيب محدد', style: TextStyle(fontSize: 12)),
                      ),
                      ...doctors.map(
                        (d) => DropdownMenuItem<String?>(
                          value: d.id,
                          child: Text('د. ${d.fullName}', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    onChanged: onDoctorChanged,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('تعذر تحميل الأطباء', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // اختيار الفرع
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الفرع',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 6),
              branchesAsync.when(
                data: (branches) {
                  return DropdownButtonFormField<String?>(
                    value: selectedBranchId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.primary.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('اختر الفرع', style: TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('الفرع الافتراضي', style: TextStyle(fontSize: 12)),
                      ),
                      ...branches.map(
                        (b) => DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(b.name, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    onChanged: onBranchChanged,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('تعذر تحميل الفروع', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
