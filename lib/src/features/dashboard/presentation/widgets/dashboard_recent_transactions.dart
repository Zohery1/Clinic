import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/data/app_section.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../appointments/presentation/appointments_controller.dart';
import '../../../patients/presentation/patient_details_dialog.dart';

/// "Last financial transactions" panel. Renders today\'s appointments as
/// transaction rows (time, patient, amount, status). No table headers
/// — clean list with hover highlight.
class DashboardRecentTransactions extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardRecentTransactions({super.key, this.onNavigateToTab});

  String _formatTime(DateTime date) {
    try {
      return intl.DateFormat('hh:mm a', 'ar').format(date);
    } catch (_) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayAppointmentsProvider);

    Widget body;
    if (async.isLoading && async.value == null) {
      body = _skeletonList(context);
    } else {
      final list = List.from(async.value ?? const [])
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      if (list.isEmpty) {
        body = const Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: AppEmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'لا توجد معاملات اليوم',
            message: 'ستظهر هنا الإيرادات والمدفوعات فور تسجيلها.',
          ),
        );
      } else {
        body = Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppRadii.brMd,
            border:
                Border.all(color: AppColors.borderSubtle(context), width: 1),
          ),
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderSubtle(context),
                  ),
                _TransactionRow(
                  timeLabel: _formatTime(list[i].appointmentDate),
                  patientName: list[i].patient.fullName,
                  amount: list[i].totalPaid,
                  status: list[i].status,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => PatientDetailsDialog(
                        clinicId: list[i].clinicId,
                        patient: list[i].toPatientModel(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      }
    }

    return AppSection(
      title: 'آخر المعاملات المالية',
      subtitle: 'اليوم',
      child: body,
    );
  }

  Widget _skeletonList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < 4; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderSubtle(context),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  AppSkeleton(width: 56, height: 22, radius: 8),
                  SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(width: 120, height: 12),
                        SizedBox(height: 6),
                        AppSkeleton(width: 80, height: 10),
                      ],
                    ),
                  ),
                  AppSkeleton(width: 56, height: 14),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatefulWidget {
  final String timeLabel;
  final String patientName;
  final double amount;
  final String status;
  final VoidCallback onTap;

  const _TransactionRow({
    required this.timeLabel,
    required this.patientName,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  @override
  State<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends State<_TransactionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg =
        AppColors.subtle(context).withValues(alpha: AppColors.isDark(context) ? 0.5 : 0.7);

    return Material(
      type: MaterialType.transparency,
      color: _hovered ? hoverBg : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hovered = v),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: AppRadii.brSm,
                ),
                child: Text(
                  widget.timeLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  widget.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                '${widget.amount.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  height: 1.3,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              AppStatusBadge.fromAppointmentStatus(widget.status, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}