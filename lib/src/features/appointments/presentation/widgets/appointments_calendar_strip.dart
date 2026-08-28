import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/user_model.dart';
import '../../../clinics/presentation/clinics_controller.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../appointments_controller.dart';

/// شريط التقويم الأفقي الأسبوعي وفلاتر الطبيب والفرع
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

  Widget _buildDoctorFilterChip(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(clinicDoctorsProvider(user.clinicId));
    final selectedDoctorId = ref.watch(selectedDoctorFilterProvider);

    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.length <= 1) return const SizedBox.shrink();
        final canSeeAll = user.isOwner || user.canViewReports || user.role == UserRole.secretary;
        if (!canSeeAll) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedDoctorId,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Theme.of(context).hintColor),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Cairo',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('جميع الأطباء'),
                ),
                ...doctors.map(
                  (doc) => DropdownMenuItem<String?>(
                    value: doc.id,
                    child: Text('د. ${doc.fullName}'),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(selectedDoctorFilterProvider.notifier).state = val;
              },
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

    return branchesAsync.when(
      data: (branches) {
        if (branches.length <= 1) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedBranchId,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Theme.of(context).hintColor),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Cairo',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('جميع الفروع'),
                ),
                ...branches.map(
                  (br) => DropdownMenuItem<String?>(
                    value: br.id,
                    child: Text(br.name),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(selectedBranchFilterProvider.notifier).state = val;
              },
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          // أيقونة اختيار التاريخ من التقويم
          Container(
            width: 48,
            height: 48,
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
          const SizedBox(width: 16),
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
                      duration: const Duration(milliseconds: 200),
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
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
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
                            style: TextStyle(
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
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  todayFormatted,
                  style: TextStyle(
                    fontSize: 14,
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
