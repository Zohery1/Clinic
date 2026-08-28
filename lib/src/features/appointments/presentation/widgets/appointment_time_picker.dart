import 'package:flutter/material.dart';
import '../../domain/appointment_model.dart';

/// ويدجت اختيار وقت الموعد (الشرائح الزمنية أو وقت مخصص)
class AppointmentTimePicker extends StatelessWidget {
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final List<AppointmentModel> existingAppointments;

  const AppointmentTimePicker({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    this.existingAppointments = const [],
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'وقت الموعد *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (picked != null) {
                  onTimeChanged(picked);
                }
              },
              icon: const Icon(Icons.access_time_rounded, size: 14),
              label: const Text('وقت مخصص', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          ),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: allTimeSlots.length,
            itemBuilder: (context, index) {
              final slot = allTimeSlots[index];
              final isSelected = slot == formattedSelected;
              final isBooked = _isSlotBooked(slot);

              return InkWell(
                onTap: () {
                  onTimeChanged(parseSlotTime(slot));
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isBooked
                            ? theme.colorScheme.error.withValues(alpha: 0.1)
                            : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isBooked
                              ? theme.colorScheme.error.withValues(alpha: 0.3)
                              : theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isBooked
                              ? theme.colorScheme.error
                              : theme.textTheme.bodyMedium?.color,
                    ),
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
