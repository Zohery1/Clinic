import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../../core/widgets/double_bezel_card.dart';
import '../../../auth/domain/user_model.dart';
import '../../../clinics/domain/branch_model.dart';
import '../../../clinics/presentation/clinics_controller.dart';
import '../../data/appointment_repository.dart';
import '../appointments_controller.dart';

/// شريط التقويم الأفقي الأسبوعي وفلاتر الطبيب والفرع بنظام Soft Structuralism.
/// تم التخلص بالكامل من DropdownButton واستبدالها بأزرار لمسية Tactile Filter Pills ومودال اختيار سلس.
class AppointmentsCalendarStrip extends ConsumerWidget {
  final DateTime selectedDate;
  final UserModel user;

  const AppointmentsCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.user,
  });

  String _getShortDayName(String label) {
    if (label.startsWith('ال')) {
      return label.substring(2);
    }
    return label;
  }

  void _showDoctorFilterSheet(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> doctors,
    String? selectedDoctorId,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.filter_alt_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'تصفية حسب الطبيب',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // خيار جميع الأطباء
                  _buildModalPill(
                    context: context,
                    isSelected: selectedDoctorId == null,
                    label: 'جميع الأطباء',
                    icon: Icons.people_outline_rounded,
                    onTap: () {
                      ref.read(selectedDoctorFilterProvider.notifier).state = null;
                      Navigator.pop(ctx);
                    },
                  ),
                  ...doctors.map((doc) {
                    final isSelected = doc.id == selectedDoctorId;
                    return _buildModalPill(
                      context: context,
                      isSelected: isSelected,
                      label: DoctorUtils.formatTitle(doc.fullName),
                      initials: doc.fullName.isNotEmpty
                          ? doc.fullName.trim().substring(0, 1)
                          : 'ط',
                      color: AppTheme.doctorColor(doc.id),
                      onTap: () {
                        ref.read(selectedDoctorFilterProvider.notifier).state = doc.id;
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBranchFilterSheet(
    BuildContext context,
    WidgetRef ref,
    List<BranchModel> branches,
    String? selectedBranchId,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.storefront_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'تصفية حسب الفرع',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // خيار جميع الفروع
                  _buildModalPill(
                    context: context,
                    isSelected: selectedBranchId == null,
                    label: 'جميع الفروع',
                    icon: Icons.domain_rounded,
                    onTap: () {
                      ref.read(selectedBranchFilterProvider.notifier).state = null;
                      Navigator.pop(ctx);
                    },
                  ),
                  ...branches.map((br) {
                    final isSelected = br.id == selectedBranchId;
                    return _buildModalPill(
                      context: context,
                      isSelected: isSelected,
                      label: br.name,
                      icon: Icons.location_on_outlined,
                      onTap: () {
                        ref.read(selectedBranchFilterProvider.notifier).state = br.id;
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalPill({
    required BuildContext context,
    required bool isSelected,
    required String label,
    IconData? icon,
    String? initials,
    Color? color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15)
        : (isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight);

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    final textColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initials != null) ...[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color ?? theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorFilterChip(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(clinicDoctorsProvider(user.clinicId));
    final selectedDoctorId = ref.watch(selectedDoctorFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.length <= 1) return const SizedBox.shrink();
        final canSeeAll = user.isOwner || user.canViewReports || user.role == UserRole.secretary;
        if (!canSeeAll) return const SizedBox.shrink();

        final selectedDoctor = doctors.where((d) => d.id == selectedDoctorId).firstOrNull;
        final label = selectedDoctor != null ? DoctorUtils.formatTitle(selectedDoctor.fullName) : 'جميع الأطباء';
        final isFiltered = selectedDoctorId != null;

        return InkWell(
          onTap: () => _showDoctorFilterSheet(context, ref, doctors, selectedDoctorId),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isFiltered
                  ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFiltered
                    ? theme.colorScheme.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isFiltered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 15,
                  color: isFiltered ? theme.colorScheme.primary : theme.hintColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
                    color: isFiltered
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isFiltered ? theme.colorScheme.primary : theme.hintColor,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBranchFilterChip(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(clinicBranchesProvider(user.clinicId));
    final selectedBranchId = ref.watch(selectedBranchFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return branchesAsync.when(
      data: (branches) {
        if (branches.length <= 1) return const SizedBox.shrink();

        final selectedBranch = branches.where((b) => b.id == selectedBranchId).firstOrNull;
        final label = selectedBranch != null ? selectedBranch.name : 'جميع الفروع';
        final isFiltered = selectedBranchId != null;

        return InkWell(
          onTap: () => _showBranchFilterSheet(context, ref, branches, selectedBranchId),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isFiltered
                  ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFiltered
                    ? theme.colorScheme.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isFiltered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 15,
                  color: isFiltered ? theme.colorScheme.primary : theme.hintColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
                    color: isFiltered
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isFiltered ? theme.colorScheme.primary : theme.hintColor,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final diff = now.weekday >= DateTime.saturday
        ? now.weekday - DateTime.saturday
        : now.weekday + 7 - DateTime.saturday;
    final saturday = now.subtract(Duration(days: diff));
    final days = List.generate(7, (i) => saturday.add(Duration(days: i)));

    final dayName = intl.DateFormat('EEEE', 'ar').format(selectedDate);
    final todayFormatted = intl.DateFormat('d MMMM، yyyy', 'ar').format(selectedDate);

    return DoubleBezelCard(
      outerRadius: 20.0,
      innerRadius: 17.5,
      outerPadding: const EdgeInsets.all(2.5),
      innerPadding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // أيقونة اختيار التاريخ من التقويم
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime(2028, 12, 31),
                );
                if (picked != null) {
                  ref.read(selectedDateProvider.notifier).state =
                      DateTime(picked.year, picked.month, picked.day);
                }
              },
              icon: Icon(
                Icons.calendar_month_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // قائمة الأيام السبعة
          Expanded(
            child: Row(
              children: days.map((day) {
                final isSelected = DateUtils.isSameDay(selectedDate, day);
                final dayLabel = intl.DateFormat('E', 'ar').format(day);
                final dayNum = intl.DateFormat('d').format(day);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).state =
                          DateTime(day.year, day.month, day.day);
                    },
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.curve,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getShortDayName(dayLabel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dayNum,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: 8),
          _buildDoctorFilterChip(context, ref),
          const SizedBox(width: 8),
          _buildBranchFilterChip(context, ref),

          if (MediaQuery.of(context).size.width >= 1150) ...[
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'مواعيد $dayName',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  todayFormatted,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
