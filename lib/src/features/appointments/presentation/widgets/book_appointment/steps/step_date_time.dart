import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../../core/ui/tokens/colors.dart';
import '../../../../../../core/ui/tokens/spacing.dart';
import '../../../../../../core/ui/tokens/typography.dart';
import '../../../appointments_controller.dart';
import '../../appointment_time_picker.dart';

class StepDateTime extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const StepDateTime({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  ConsumerState<StepDateTime> createState() => _StepDateTimeState();
}

class _StepDateTimeState extends ConsumerState<StepDateTime> {
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      widget.onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsForDayAsync =
        ref.watch(appointmentsForDateProvider(widget.selectedDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التاريخ والوقت',
          style: AppTypography.headingLg(AppColors.textPrimary(context)),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'حدد اليوم والوقت المناسب للموعد',
          style: AppTypography.bodySm(AppColors.textSecondary(context)),
        ),
        const SizedBox(height: AppSpace.lg),
        Material(
          color: AppColors.subtle(context),
          borderRadius: BorderRadius.circular(AppRadii.radiusMd),
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppRadii.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.radiusMd),
                border: Border.all(color: AppColors.borderSubtle(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius:
                          BorderRadius.circular(AppRadii.radiusSm),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تاريخ الموعد',
                          style: AppTypography.bodySm(
                              AppColors.textSecondary(context)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          intl.DateFormat('EEEE، d MMMM yyyy', 'ar')
                              .format(widget.selectedDate),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.textMuted(context)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppointmentTimePicker(
          selectedTime: widget.selectedTime,
          onTimeChanged: widget.onTimeChanged,
          existingAppointments: appointmentsForDayAsync.value ?? const [],
        ),
      ],
    );
  }
}


