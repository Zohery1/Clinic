import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/user_model.dart';
import '../../../clinics/domain/branch_model.dart';
import '../../../clinics/presentation/clinics_controller.dart';
import '../../data/appointment_repository.dart';
import '../appointments_controller.dart';

/// شريط التقويم الأسبوعي وفلاتر الطبيب والفرع بنظام Clinical Bento Utility.
/// يدعم اختيار الأيام بلمسة واحدة، التنقل السريع بين الأيام، وفلاتر الأطباء والفروع
/// بدون أي مشاكل overflow على الشاشات الصغيرة (375px) أو الشاشات العريضة.
class AppointmentsCalendarStrip extends ConsumerWidget {
  final DateTime selectedDate;
  final UserModel user;

  const AppointmentsCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.user,
  });

  String _cleanDayLabel(String label) {
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
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تصفية المواعيد حسب الطبيب',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تصفية المواعيد حسب الفرع',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
        ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
        : AppColors.subtle(context);

    final borderColor = isSelected
        ? AppColors.primary
        : AppColors.borderSubtle(context);

    final textColor = isSelected
        ? AppColors.primary
        : AppColors.textPrimary(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initials != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color ?? AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: AppColors.primary,
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
        final label = selectedDoctor != null
            ? DoctorUtils.formatTitle(selectedDoctor.fullName)
            : 'جميع الأطباء';
        final isFiltered = selectedDoctorId != null;

        return InkWell(
          onTap: () => _showDoctorFilterSheet(context, ref, doctors, selectedDoctorId),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isFiltered
                  ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                  : AppColors.subtle(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFiltered ? AppColors.primary : AppColors.borderSubtle(context),
                width: isFiltered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 14,
                  color: isFiltered ? AppColors.primary : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
                      color: isFiltered
                          ? AppColors.primary
                          : AppColors.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isFiltered ? AppColors.primary : AppColors.textSecondary(context),
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
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isFiltered
                  ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                  : AppColors.subtle(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFiltered ? AppColors.primary : AppColors.borderSubtle(context),
                width: isFiltered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: isFiltered ? AppColors.primary : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
                      color: isFiltered
                          ? AppColors.primary
                          : AppColors.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isFiltered ? AppColors.primary : AppColors.textSecondary(context),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final datePickerButton = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: 'اختيار تاريخ محدد',
        onPressed: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2024, 1, 1),
            lastDate: DateTime(2030, 12, 31),
            locale: const Locale('ar'),
          );
          if (picked != null) {
            ref.read(selectedDateProvider.notifier).state =
                DateTime(picked.year, picked.month, picked.day);
          }
        },
        icon: const Icon(
          Icons.calendar_month_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );

    final daysRow = Row(
      children: days.map((day) {
        final isSelected = DateUtils.isSameDay(selectedDate, day);
        final isToday = DateUtils.isSameDay(now, day);
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
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isToday
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _cleanDayLabel(dayLabel),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.95)
                          : (isToday
                              ? AppColors.primary
                              : AppColors.textSecondary(context)),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    dayNum,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? AppColors.primary
                              : AppColors.textPrimary(context)),
                    ),
                  ),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );

    if (isMobile) {
      return AppCard(
        padding: const EdgeInsets.all(10),
        radius: AppRadii.radiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                datePickerButton,
                const SizedBox(width: 8),
                Expanded(child: daysRow),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDoctorFilterChip(context, ref)),
                const SizedBox(width: 8),
                Expanded(child: _buildBranchFilterChip(context, ref)),
              ],
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: AppRadii.radiusMd,
      child: Row(
        children: [
          datePickerButton,
          const SizedBox(width: 10),
          Expanded(child: daysRow),
          const SizedBox(width: 10),
          _buildDoctorFilterChip(context, ref),
          const SizedBox(width: 8),
          _buildBranchFilterChip(context, ref),
          if (screenWidth >= 1180) ...[
            const SizedBox(width: 14),
            Container(
              height: 36,
              width: 1,
              color: AppColors.borderSubtle(context),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'مواعيد $dayName',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  todayFormatted,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
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
