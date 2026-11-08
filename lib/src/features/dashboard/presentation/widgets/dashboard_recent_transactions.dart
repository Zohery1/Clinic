import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/routing/routing.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/ui/tokens/typography.dart';
import '../../../appointments/presentation/appointments_controller.dart';

/// Today's money movements, read as a receipt list rather than a table.
class DashboardRecentTransactions extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardRecentTransactions({super.key, this.onNavigateToTab});

  String _time(DateTime date) {
    try {
      return intl.DateFormat('hh:mm a', 'ar').format(date);
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayAppointmentsProvider);

    Widget body;
    if (async.isLoading && async.value == null) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.sm),
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      final list = List.from(async.value ?? const [])
        ..removeWhere((a) => (a.totalPaid ?? 0) <= 0)
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      if (list.isEmpty) {
        body = const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
          child: AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد حركات اليوم',
            message: 'ستظهر هنا المدفوعات فور تسجيلها.',
          ),
        );
      } else {
        final display = list.take(6).toList();
        body = Column(
          children: [
            for (int i = 0; i < display.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpace.lg,
                  endIndent: AppSpace.lg,
                  color: AppColors.borderSubtle(context),
                ),
              _TransactionRow(
                timeLabel: _time(display[i].appointmentDate),
                patientName: display[i].patient.fullName,
                amount: display[i].totalPaid,
                paid: display[i].status == 'completed',
                onTap: () => AppNavigation.showPatientDetails(
                  context,
                  clinicId: display[i].clinicId,
                  patient: display[i].toPatientModel(),
                ),
              ),
            ],
          ],
        );
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg + 2,
              AppSpace.lg,
              AppSpace.md,
              AppSpace.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.info
                        .withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.09),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 16,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  'آخر الحركات',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  'اليوم',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          body,
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String timeLabel;
  final String patientName;
  final num amount;
  final bool paid;
  final VoidCallback onTap;

  const _TransactionRow({
    required this.timeLabel,
    required this.patientName,
    required this.amount,
    required this.paid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.success : AppColors.warning;
    final fmt = intl.NumberFormat('#,##0', 'ar');

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.accent(context).withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              AppAvatar(name: patientName, size: AppAvatarSize.xs),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                        height: 1.35,
                      ),
                    ),
                    Text(
                      '$timeLabel · ${paid ? 'مدفوع' : 'معلق'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                '${fmt.format(amount)} ج.م',
                style: AppTypography.numericSm(color).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
