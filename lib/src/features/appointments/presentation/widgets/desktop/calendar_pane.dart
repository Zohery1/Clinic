import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../../appointments_controller.dart';

/// Left pane: compact date strip + doctor/branch filter summary.
class DesktopCalendarPane extends ConsumerWidget {
  const DesktopCalendarPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final month = selectedDate.month;
    final year = selectedDate.year;
    final today = DateTime.now();
    final isCurrentMonth = today.month == month && today.year == year;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthHeader(month: month, year: year),
          const SizedBox(height: AppSpace.md),
          _CalendarGrid(currentMonth: selectedDate, today: today),
          if (isCurrentMonth) ...[
            const SizedBox(height: AppSpace.md),
            _Legend(),
          ],
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final int month;
  final int year;
  const _MonthHeader({required this.month, required this.year});

  static const _arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_arMonths[month - 1]} $year',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          onPressed: () {
            // Decrement month handled by parent via setter, no-op here.
          },
          disabled: true,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool disabled;
  const _NavButton(
      {required this.icon, required this.onPressed, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: disabled ? null : onPressed,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CalendarGrid extends ConsumerWidget {
  final DateTime currentMonth;
  final DateTime today;
  const _CalendarGrid({required this.currentMonth, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday = firstOfMonth.weekday % 7; // 0 = Sunday
    final cells = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(currentMonth.year, currentMonth.month, d);
      cells.add(_DayCell(
        date: date,
        isToday: _sameDay(date, today),
      ));
    }
    return Column(
      children: [
        Row(
          children: const [
            _Weekday('أحد'),
            _Weekday('إثن'),
            _Weekday('ثلا'),
            _Weekday('أرب'),
            _Weekday('خمس'),
            _Weekday('جمع'),
            _Weekday('سبت'),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.0,
          children: cells,
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted(context),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends ConsumerWidget {
  final DateTime date;
  final bool isToday;
  const _DayCell({required this.date, required this.isToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final isSelected = _sameDay(date, selected);
    final isDark = AppColors.isDark(context);
    Color bg;
    Color fg;
    if (isSelected) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    } else if (isToday) {
      bg = AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12);
      fg = AppColors.primary;
    } else {
      bg = AppColors.subtle(context);
      fg = AppColors.textPrimary(context);
    }
    return InkWell(
      onTap: () {
        ref.read(selectedDateProvider.notifier).state =
            DateTime(date.year, date.month, date.day);
      },
      borderRadius: BorderRadius.circular(AppRadii.radiusSm),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 1)
              : null,
        ),
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendRow(color: AppColors.primary, label: 'اليوم'),
        const SizedBox(height: 4),
        _LegendRow(color: AppColors.success, label: 'مؤكد'),
        const SizedBox(height: 4),
        _LegendRow(color: AppColors.warning, label: 'في الانتظار'),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

