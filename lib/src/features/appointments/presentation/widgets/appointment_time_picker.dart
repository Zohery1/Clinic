import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/appointment_model.dart';

/// ويدجت اختيار وقت الموعد بنظام Soft Structuralism Soft Time Slot Pills
/// مع دعم اختيار وقت مخصص وتحديد الشرائح المحجوزة والمتاحة بوضوح.
class AppointmentTimePicker extends StatelessWidget {
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final List<AppointmentModel> existingAppointments;
  final bool enabled;

  const AppointmentTimePicker({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    this.existingAppointments = const [],
    this.enabled = true,
  });

  static List<String> get allTimeSlots {
    final List<String> slots = [];
    // 7:00 AM to 11:30 AM
    for (int hour = 7; hour <= 11; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00 AM');
      slots.add('${hour.toString().padLeft(2, '0')}:30 AM');
    }
    // 12:00 PM to 11:30 PM
    slots.add('12:00 PM');
    slots.add('12:30 PM');
    for (int hour = 1; hour <= 11; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00 PM');
      slots.add('${hour.toString().padLeft(2, '0')}:30 PM');
    }
    // 12:00 AM to 2:00 AM (next day early morning slots)
    slots.add('12:00 AM');
    slots.add('12:30 AM');
    slots.add('01:00 AM');
    slots.add('01:30 AM');
    slots.add('02:00 AM');
    return slots;
  }

  static TimeOfDay parseSlotTime(String slot) {
    final parts = slot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts[1] == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  static String formatArabicTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  static String formatSlotToArabic(String slot) {
    final t = parseSlotTime(slot);
    return formatArabicTime(t);
  }

  bool _isSlotBooked(String slot) {
    final slotTime = parseSlotTime(slot);
    return existingAppointments.any((app) {
      final appTime = TimeOfDay.fromDateTime(app.appointmentDate.toLocal());
      return appTime.hour == slotTime.hour && appTime.minute == slotTime.minute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedSelected = formatTimeOfDay(selectedTime);
    final arabicFormattedSelected = formatArabicTime(selectedTime);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title, current selection pill, and custom time action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 15,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'وقت الموعد *',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 8),
                // Current Selected Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        arabicFormattedSelected,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Custom time button
            InkWell(
              onTap: enabled
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (ctx, child) {
                          return Directionality(
                            textDirection: TextDirection.rtl,
                            child: child ?? const SizedBox.shrink(),
                          );
                        },
                      );
                      if (picked != null) {
                        onTimeChanged(picked);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'وقت مخصص',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Scrollable slots container
        Container(
          height: 135,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.1,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: allTimeSlots.length,
            itemBuilder: (context, index) {
              final slot = allTimeSlots[index];
              final isSelected = slot == formattedSelected;
              final isBooked = _isSlotBooked(slot);
              final arabicSlot = formatSlotToArabic(slot);

              Color bgColor;
              Color borderColor;
              Color textColor;

              if (isSelected) {
                bgColor = theme.colorScheme.primary;
                borderColor = theme.colorScheme.primary;
                textColor = Colors.white;
              } else if (isBooked) {
                bgColor = isDark
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.errorLight;
                borderColor = isDark
                    ? AppColors.error.withValues(alpha: 0.35)
                    : AppColors.error.withValues(alpha: 0.25);
                textColor = AppColors.error;
              } else {
                bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
                borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
                textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
              }

              return InkWell(
                onTap: (enabled && !isBooked)
                    ? () => onTimeChanged(parseSlotTime(slot))
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.curve,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.40 : 0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        arabicSlot,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w800 : (isBooked ? FontWeight.w500 : FontWeight.w600),
                          color: textColor,
                          decoration: isBooked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isBooked && !isSelected) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.block_rounded,
                          size: 9,
                          color: AppColors.error,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
