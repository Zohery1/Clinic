import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/ui/tokens/colors.dart';
import '../../../../auth/domain/user_model.dart';
import '../../../domain/appointment_model.dart';
import '../appointment_card.dart';
import 'details_pane.dart';

/// لوحة طابور المراحل عالية الكثافة (Clinical Kanban View) لشاشات سطح المكتب.
/// تدعم 4 مسارات سريرية واضحة: طابور الانتظار، مع الطبيب، مكتمل، وملغي / معتذر.
class AppointmentsKanbanView extends StatelessWidget {
  final UserModel user;
  final List<AppointmentModel> appointments;
  final AppointmentModel? activeSelected;
  final ValueChanged<AppointmentModel> onSelectAppointment;
  final VoidCallback onCloseDetails;

  const AppointmentsKanbanView({
    super.key,
    required this.user,
    required this.appointments,
    required this.activeSelected,
    required this.onSelectAppointment,
    required this.onCloseDetails,
  });

  @override
  Widget build(BuildContext context) {
    final waiting =
        appointments.where((a) => a.status == 'confirmed').toList();
    final inDoctor = appointments.where((a) => a.status == 'pending').toList();
    final completed =
        appointments.where((a) => a.status == 'completed').toList();
    final cancelled =
        appointments.where((a) => a.status.startsWith('cancelled')).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final needsHorizontalScroll = availableWidth < 1050;
        final detailsWidth =
            (availableWidth * 0.30).clamp(270.0, 340.0).toDouble();

        Widget buildLanesRow() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // مسار 1: بالانتظار
              needsHorizontalScroll
                  ? SizedBox(
                      width: 245,
                      child: _buildKanbanLane(
                        context: context,
                        title: 'صالة الانتظار',
                        subtitle: 'بانتظار النداء والدخول',
                        count: waiting.length,
                        color: AppColors.warning,
                        icon: Icons.hourglass_top_rounded,
                        items: waiting,
                      ),
                    )
                  : Expanded(
                      child: _buildKanbanLane(
                        context: context,
                        title: 'صالة الانتظار',
                        subtitle: 'بانتظار النداء والدخول',
                        count: waiting.length,
                        color: AppColors.warning,
                        icon: Icons.hourglass_top_rounded,
                        items: waiting,
                      ),
                    ),
              const SizedBox(width: 8),

              // مسار 2: مع الطبيب
              needsHorizontalScroll
                  ? SizedBox(
                      width: 245,
                      child: _buildKanbanLane(
                        context: context,
                        title: 'غرفة الكشف',
                        subtitle: 'جلسات الفحص الجارية',
                        count: inDoctor.length,
                        color: AppColors.info,
                        icon: Icons.medical_services_outlined,
                        items: inDoctor,
                      ),
                    )
                  : Expanded(
                      child: _buildKanbanLane(
                        context: context,
                        title: 'غرفة الكشف',
                        subtitle: 'جلسات الفحص الجارية',
                        count: inDoctor.length,
                        color: AppColors.info,
                        icon: Icons.medical_services_outlined,
                        items: inDoctor,
                      ),
                    ),
              const SizedBox(width: 8),

              // مسار 3: مكتمل اليوم
              needsHorizontalScroll
                  ? SizedBox(
                      width: 245,
                      child: _buildKanbanLane(
                        context: context,
                        title: 'كشوفات مكتملة',
                        subtitle: 'تم إنهاء الفحص',
                        count: completed.length,
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                        items: completed,
                      ),
                    )
                  : Expanded(
                      child: _buildKanbanLane(
                        context: context,
                        title: 'كشوفات مكتملة',
                        subtitle: 'تم إنهاء الفحص',
                        count: completed.length,
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                        items: completed,
                      ),
                    ),
              const SizedBox(width: 8),

              // مسار 4: ملغي / معتذر
              needsHorizontalScroll
                  ? SizedBox(
                      width: 245,
                      child: _buildKanbanLane(
                        context: context,
                        title: 'إلغاء واعتذار',
                        subtitle: 'مواعيد غير مكتملة',
                        count: cancelled.length,
                        color: AppColors.danger,
                        icon: Icons.cancel_outlined,
                        items: cancelled,
                      ),
                    )
                  : Expanded(
                      child: _buildKanbanLane(
                        context: context,
                        title: 'إلغاء واعتذار',
                        subtitle: 'مواعيد غير مكتملة',
                        count: cancelled.length,
                        color: AppColors.danger,
                        icon: Icons.cancel_outlined,
                        items: cancelled,
                      ),
                    ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: needsHorizontalScroll
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1020,
                        child: buildLanesRow(),
                      ),
                    )
                  : buildLanesRow(),
            ),

            // لوحة فحص جانبي إذا تم تحديد موعد
            if (activeSelected != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: detailsWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle(context)),
                  ),
                  child: DesktopDetailsPane(
                    user: user,
                    selected: activeSelected!,
                    onClose: onCloseDetails,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildKanbanLane({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required IconData icon,
    required List<AppointmentModel> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        children: [
          // رأس المسار المدمج
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                          height: 1.25,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 9.5,
                          color: AppColors.textSecondary(context),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // قائمة الكروت داخل المسار
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'لا توجد كشوفات في هذه القائمة',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(6),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = activeSelected?.id == item.id;
                      return AppointmentCard(
                        appointment: item,
                        clinicId: user.clinicId,
                        isSelected: isSelected,
                        queueIndex: index + 1,
                        onTap: () => onSelectAppointment(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
