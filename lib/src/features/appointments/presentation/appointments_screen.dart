import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/login_controller.dart';
import 'appointments_controller.dart';
import 'widgets/appointments_desktop_view.dart';
import 'widgets/appointments_mobile_view.dart';

/// شاشة المواعيد الرئيسية — تدعم التصميم المكتبي والهاتفي
class AppointmentsScreen extends ConsumerWidget {
  final DateTime? subscriptionEndDate;
  final String? inviteCode;
  final String? clinicName;
  final String? clinicId;

  const AppointmentsScreen({
    super.key,
    this.subscriptionEndDate,
    this.inviteCode,
    this.clinicName,
    this.clinicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (user == null) {
      return Center(
        child: Text(
          'يرجى تسجيل الدخول أولاً',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    if (isDesktop) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppointmentsDesktopView(
          user: user,
          appointmentsAsync: appointmentsAsync,
          selectedDate: selectedDate,
        ),
      );
    } else {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppointmentsMobileView(
          user: user,
          appointmentsAsync: appointmentsAsync,
          selectedDate: selectedDate,
        ),
      );
    }
  }
}