import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/appointment_model.dart';
import 'appointments_calendar_strip.dart';
import 'queue_board.dart';

/// العرض المكتبي الكامل لشاشة المواعيد
class AppointmentsDesktopView extends StatelessWidget {
  final UserModel user;
  final AsyncValue<List<AppointmentModel>> appointmentsAsync;
  final DateTime selectedDate;

  const AppointmentsDesktopView({
    super.key,
    required this.user,
    required this.appointmentsAsync,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppointmentsCalendarStrip(selectedDate: selectedDate, user: user),
        const SizedBox(height: 16),
        Expanded(
          child: appointmentsAsync.when(
            data: (appointments) => QueueBoard(
              appointments: appointments,
              clinicId: user.clinicId,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'حدث خطأ في تحميل البيانات: $err',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
