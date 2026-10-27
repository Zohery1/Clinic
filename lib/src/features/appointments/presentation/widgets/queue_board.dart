import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/double_bezel_card.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';
import 'queue_board_header.dart';
import 'queue_timeline_row.dart';

/// لوحة إدارة المرضى والمواعيد — تصميم زمني كرونولوجي احترافي (Timeline Clinic Queue)
/// مبني بأسلوب Soft Structuralism مع بطاقات Double-Bezel وفواصل مريحة وحركات دخول متدرجة
class QueueBoard extends ConsumerWidget {
  final List<AppointmentModel> appointments;
  final String clinicId;

  const QueueBoard({
    super.key,
    required this.appointments,
    required this.clinicId,
  });

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 42,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مواعيد في هذه الحالة لليوم',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'يمكنك إضافة موعد جديد أو تغيير تصفية الحالات في الأعلى',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => BookAppointmentDialog(clinicId: clinicId),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'حجز موعد جديد',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
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

    return DoubleBezelCard(
      outerRadius: 24.0,
      innerRadius: 21.5,
      outerPadding: const EdgeInsets.all(2.5),
      innerPadding: EdgeInsets.zero,
      child: Column(
        children: [
          // رأس الجدول مع أزرار الفلترة والتنقل
          QueueBoardHeader(
            appointments: appointments,
            clinicId: clinicId,
            selectedFilter: selectedFilter,
            selectedDate: selectedDate,
          ),

          // قائمة المرضى الزمنية بمسافات Macro-Whitespace (12px) وحركات دخول متدرجة
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final appt = filtered[index];
                      return StaggeredCardEntry(
                        index: index,
                        child: QueueTimelineRow(
                          appt: appt,
                          clinicId: clinicId,
                          isDoctor: isDoctor,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

