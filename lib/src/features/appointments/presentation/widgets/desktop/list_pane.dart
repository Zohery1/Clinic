import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../../core/ui/feedback/app_error_state.dart';
import '../../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../../../../../core/ui/tokens/typography.dart';
import '../../../../auth/domain/user_model.dart';
import '../../appointments_controller.dart';
import '../../../domain/appointment_model.dart';
import '../appointment_card.dart';

/// Center pane: list of appointments for the selected day.
class DesktopListPane extends ConsumerWidget {
  final UserModel user;
  final AppointmentModel? selected;
  final ValueChanged<AppointmentModel> onSelect;

  const DesktopListPane({
    super.key,
    required this.user,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final async = ref.watch(todayAppointmentsProvider);
    final dateLabel =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(selectedDate);
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مواعيد اليوم',
            style: AppTypography.headingLg(AppColors.textPrimary(context)),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: AppTypography.bodySm(AppColors.textSecondary(context)),
          ),
          const SizedBox(height: AppSpace.lg),
          Expanded(
            child: async.when(
              data: (list) {
                final sorted = [...list]
                  ..sort((a, b) =>
                      a.appointmentDate.compareTo(b.appointmentDate));
                if (sorted.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'لا توجد مواعيد',
                    message: 'لم يتم تسجيل أي مواعيد لهذا اليوم بعد',
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpace.md),
                  itemBuilder: (_, i) {
                    final a = sorted[i];
                    return AppointmentCard(
                      appointment: a,
                      clinicId: user.clinicId,
                      isSelected: selected?.id == a.id,
                      onTap: () => onSelect(a),
                    );
                  },
                );
              },
              loading: () => Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: AppSkeleton(
                      height: 120,
                      radius: AppRadii.radiusMd,
                    ),
                  ),
                ),
              ),
              error: (e, _) => AppErrorState(
                title: 'تعذر التحميل',
                message: e.toString(),
                onRetry: () => ref.invalidate(todayAppointmentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
