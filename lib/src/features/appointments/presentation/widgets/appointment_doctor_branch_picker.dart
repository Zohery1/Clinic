import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../clinics/presentation/clinics_controller.dart';
import '../../data/appointment_repository.dart';

/// ويدجت اختيار الطبيب والفرع لحجز أو تعديل الموعد باستخدام شرائط أزرار لمسية أفقية (Tactile Pills).
/// لا يحتوي على أي DropdownButton.
class AppointmentDoctorBranchPicker extends ConsumerWidget {
  final String clinicId;
  final String? selectedDoctorId;
  final String? selectedBranchId;
  final ValueChanged<String?> onDoctorChanged;
  final ValueChanged<String?> onBranchChanged;
  final bool enabled;

  const AppointmentDoctorBranchPicker({
    super.key,
    required this.clinicId,
    required this.selectedDoctorId,
    required this.selectedBranchId,
    required this.onDoctorChanged,
    required this.onBranchChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorPillSelector(
          clinicId: clinicId,
          selectedDoctorId: selectedDoctorId,
          onSelected: onDoctorChanged,
          enabled: enabled,
        ),
        const SizedBox(height: 14),
        BranchPillSelector(
          clinicId: clinicId,
          selectedBranchId: selectedBranchId,
          onSelected: onBranchChanged,
          enabled: enabled,
        ),
      ],
    );
  }
}

/// شريط اختيار الطبيب الأفقي بنظام Soft Structuralism Tactile Pills
class DoctorPillSelector extends ConsumerWidget {
  final String clinicId;
  final String? selectedDoctorId;
  final ValueChanged<String?> onSelected;
  final bool enabled;

  const DoctorPillSelector({
    super.key,
    required this.clinicId,
    required this.selectedDoctorId,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(clinicDoctorsProvider(clinicId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.badge_outlined,
              size: 15,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'الطبيب المعالج',
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        doctorsAsync.when(
          data: (doctors) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // الخيار الافتراضي: بدون طبيب محدد
                  _buildDoctorPill(
                    context: context,
                    isSelected: selectedDoctorId == null,
                    label: 'بدون طبيب محدد',
                    icon: Icons.person_outline_rounded,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    onTap: enabled ? () => onSelected(null) : null,
                  ),
                  const SizedBox(width: 8),
                  // قائمة أطباء العيادة
                  ...doctors.map((doctor) {
                    final isSelected = doctor.id == selectedDoctorId;
                    final docColor = AppTheme.doctorColor(doctor.id);
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildDoctorPill(
                        context: context,
                        isSelected: isSelected,
                        label: DoctorUtils.formatTitle(doctor.fullName),
                        initials: doctor.fullName.isNotEmpty
                            ? doctor.fullName.trim().substring(0, 1)
                            : 'ط',
                        color: docColor,
                        onTap: enabled ? () => onSelected(doctor.id) : null,
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 42,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Text(
            'تعذر تحميل الأطباء',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorPill({
    required BuildContext context,
    required bool isSelected,
    required String label,
    IconData? icon,
    String? initials,
    required Color color,
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
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
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
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: initials != null
                    ? Text(
                        initials,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : color,
                        ),
                      )
                    : Icon(
                        icon ?? Icons.person_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : color,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// شريط اختيار الفرع الأفقي بنظام Soft Structuralism Tactile Pills
class BranchPillSelector extends ConsumerWidget {
  final String clinicId;
  final String? selectedBranchId;
  final ValueChanged<String?> onSelected;
  final bool enabled;

  const BranchPillSelector({
    super.key,
    required this.clinicId,
    required this.selectedBranchId,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(clinicBranchesProvider(clinicId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 15,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'الفرع',
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        branchesAsync.when(
          data: (branches) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // الخيار الافتراضي: الفرع الافتراضي
                  _buildBranchPill(
                    context: context,
                    isSelected: selectedBranchId == null,
                    label: 'الفرع الافتراضي',
                    onTap: enabled ? () => onSelected(null) : null,
                  ),
                  const SizedBox(width: 8),
                  // قائمة الفروع
                  ...branches.map((branch) {
                    final isSelected = branch.id == selectedBranchId;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildBranchPill(
                        context: context,
                        isSelected: isSelected,
                        label: branch.name,
                        onTap: enabled ? () => onSelected(branch.id) : null,
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 42,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Text(
            'تعذر تحميل الفروع',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchPill({
    required BuildContext context,
    required bool isSelected,
    required String label,
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
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
            Icon(
              Icons.location_on_outlined,
              size: 15,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
