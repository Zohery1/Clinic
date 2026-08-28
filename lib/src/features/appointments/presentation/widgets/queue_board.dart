import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';
import 'queue_board_header.dart';
import 'queue_timeline_row.dart';

/// لوحة إدارة المرضى والمواعيد — تصميم زمني كرونولوجي احترافي (Timeline Clinic Queue)
class QueueBoard extends ConsumerWidget {
  final List<AppointmentModel> appointments;
  final String clinicId;

  const QueueBoard({
    super.key,
    required this.appointments,
    required this.clinicId,
  });

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد مواعيد في هذه الحالة لليوم',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'يمكنك إضافة موعد جديد أو تغيير تصفية الحالات في الأعلى',
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => BookAppointmentDialog(clinicId: clinicId),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('حجز موعد جديد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final selectedFilter = ref.watch(dashboardFilterProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // 1. التصفية
    final filtered = appointments.where((appt) {
      if (selectedFilter != 'all') {
        if (selectedFilter == 'cancelled') {
          if (!appt.status.startsWith('cancelled')) return false;
        } else if (appt.status != selectedFilter) {
          return false;
        }
      }
      return true;
    }).toList();

    // 2. الترتيب الزمني
    filtered.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    return Container(
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        children: [
          // رأس الجدول مع أزرار الفلترة والتنقل
          QueueBoardHeader(
            appointments: appointments,
            clinicId: clinicId,
            selectedFilter: selectedFilter,
            selectedDate: selectedDate,
          ),
          const SizedBox(height: 8),

          // قائمة المرضى الزمنية
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final appt = filtered[index];
                      return QueueTimelineRow(
                        appt: appt,
                        clinicId: clinicId,
                        isDoctor: isDoctor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
