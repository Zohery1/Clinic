import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/primitives/app_chip.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../appointments/data/appointment_repository.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../clinics/presentation/clinics_controller.dart';
import '../reports_controller.dart';

class DailyLogsFilters extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final VoidCallback onExport;

  const DailyLogsFilters({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
    required this.onExport,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initial = DateTimeRange(start: startDate, end: endDate);
    final first = DateTime(now.year - 5);
    final last = DateTime(now.year + 1);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: first,
      lastDate: last,
      saveText: 'تطبيق',
      cancelText: 'إلغاء',
    );
    if (picked != null) onDateRangeChanged(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final clinicId = user?.clinicId ?? '';
    final doctorsAsync = ref.watch(clinicDoctorsProvider(clinicId));
    final branchesAsync = ref.watch(clinicBranchesProvider(clinicId));
    final selectedDoctorId = ref.watch(selectedReportDoctorIdProvider);
    final selectedBranchId = ref.watch(selectedReportBranchIdProvider);

    final canFilterDoctors =
        user?.isOwner == true || user?.canViewReports == true;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day);

    final last7Start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final last7End = DateTime(now.year, now.month, now.day);

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month, now.day);

    final isToday =
        _isSameDay(startDate, todayStart) && _isSameDay(endDate, todayEnd);
    final isLast7 =
        _isSameDay(startDate, last7Start) && _isSameDay(endDate, last7End);
    final isThisMonth = _isSameDay(startDate, thisMonthStart) &&
        _isSameDay(endDate, thisMonthEnd);
    final isCustom = !isToday && !isLast7 && !isThisMonth;

    final datePresets = _ChipRow(
      children: [
        AppChip(
          label: 'اليوم',
          variant: AppChipVariant.filter,
          selected: isToday,
          onSelected: (_) => onDateRangeChanged(
            DateTimeRange(start: todayStart, end: todayEnd),
          ),
        ),
        AppChip(
          label: 'آخر 7 أيام',
          variant: AppChipVariant.filter,
          selected: isLast7,
          onSelected: (_) => onDateRangeChanged(
            DateTimeRange(start: last7Start, end: last7End),
          ),
        ),
        AppChip(
          label: 'هذا الشهر',
          variant: AppChipVariant.filter,
          selected: isThisMonth,
          onSelected: (_) => onDateRangeChanged(
            DateTimeRange(start: thisMonthStart, end: thisMonthEnd),
          ),
        ),
        AppChip(
          label: isCustom
              ? 'مخصص (${intl.DateFormat('d MMM', 'ar').format(startDate)} - ${intl.DateFormat('d MMM', 'ar').format(endDate)})'
              : 'مخصص',
          icon: Icons.tune_rounded,
          variant: AppChipVariant.filter,
          selected: isCustom,
          onSelected: (_) => _pickCustomRange(context),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final stacked = c.maxWidth < 900;
          final dateBtn = _DateRangeButton(
            start: startDate,
            end: endDate,
            onPicked: onDateRangeChanged,
          );
          final doctorFilter = !canFilterDoctors
              ? _DoctorLockedBanner(userName: user?.fullName ?? '')
              : doctorsAsync.when(
                  data: (doctors) {
                    if (doctors.length <= 1) {
                      return const SizedBox.shrink();
                    }
                    return _ChipRow(
                      children: [
                        AppChip(
                          label: 'جميع الأطباء',
                          variant: AppChipVariant.filter,
                          selected: selectedDoctorId == null,
                          onSelected: (_) => ref
                              .read(selectedReportDoctorIdProvider.notifier)
                              .state = null,
                        ),
                        for (final d in doctors)
                          AppChip(
                            label: DoctorUtils.formatTitle(d.fullName),
                            variant: AppChipVariant.filter,
                            selected: selectedDoctorId == d.id,
                            onSelected: (_) => ref
                                .read(selectedReportDoctorIdProvider.notifier)
                                .state = d.id,
                          ),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
          final branchFilter = branchesAsync.when(
            data: (branches) {
              if (branches.length <= 1) return const SizedBox.shrink();
              return _ChipRow(
                children: [
                  AppChip(
                    label: 'جميع الفروع',
                    variant: AppChipVariant.filter,
                    selected: selectedBranchId == null,
                    onSelected: (_) => ref
                        .read(selectedReportBranchIdProvider.notifier)
                        .state = null,
                  ),
                  for (final b in branches)
                    AppChip(
                      label: b.name,
                      variant: AppChipVariant.filter,
                      selected: selectedBranchId == b.id,
                      onSelected: (_) => ref
                          .read(selectedReportBranchIdProvider.notifier)
                          .state = b.id,
                    ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          );
          final exportBtn = AppButton(
            label: 'تصدير CSV',
            icon: Icons.file_download_outlined,
            expand: false,
            size: AppButtonSize.sm,
            variant: AppButtonVariant.secondary,
            onPressed: onExport,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                datePresets,
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: [
                    Expanded(child: dateBtn),
                    const SizedBox(width: AppSpace.sm),
                    exportBtn,
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                doctorFilter,
                if (branchFilter is! SizedBox) ...[
                  const SizedBox(height: AppSpace.xs),
                  branchFilter,
                ],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  datePresets,
                  const SizedBox(width: AppSpace.sm),
                  dateBtn,
                  const Spacer(),
                  exportBtn,
                ],
              ),
              if (doctorFilter is! _DoctorLockedBanner) ...[
                const SizedBox(height: AppSpace.sm),
                doctorFilter,
              ],
              const SizedBox(height: AppSpace.sm),
              branchFilter,
            ],
          );
        },
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final ValueChanged<DateTimeRange> onPicked;
  const _DateRangeButton({
    required this.start,
    required this.end,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = intl.DateFormat('d MMM yyyy', 'ar');
    return AppButton(
      label: '${fmt.format(start)} - ${fmt.format(end)}',
      icon: Icons.calendar_month_rounded,
      expand: false,
      size: AppButtonSize.sm,
      variant: AppButtonVariant.secondary,
      onPressed: () async {
        final now = DateTime.now();
        final initial = DateTimeRange(start: start, end: end);
        final first = DateTime(now.year - 5);
        final last = DateTime(now.year + 1);
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: initial,
          firstDate: first,
          lastDate: last,
          saveText: 'تطبيق',
          cancelText: 'إلغاء',
        );
        if (picked != null) onPicked(picked);
      },
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  const _ChipRow({required this.children});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(width: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _DoctorLockedBanner extends StatelessWidget {
  final String userName;
  const _DoctorLockedBanner({required this.userName});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadii.brSm,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              'يتم استعراض الإحصائيات الخاصة بك فقط (د. $userName)',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
