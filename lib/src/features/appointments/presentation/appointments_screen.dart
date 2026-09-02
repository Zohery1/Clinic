import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user_model.dart';
import '../../auth/presentation/login_controller.dart';
import 'appointments_controller.dart';
import 'book_appointment_dialog.dart';
import 'widgets/appointments_desktop_view.dart';
import 'widgets/appointments_mobile_view.dart';
import '../../../core/ui/layout/app_shell.dart';
import '../../../core/ui/layout/app_top_bar.dart';
import '../../../core/ui/tokens/colors.dart';

/// Top-level Appointments route. Renders inside an [AppShell] with
/// the page title "المواعيد", breadcrumb [الرئيسية, المواعيد], and a
/// "حجز جديد" action in the top bar. The inner layout switches
/// between [AppointmentsMobileView] and [AppointmentsDesktopView]
/// based on the available width.
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
    if (user == null) {
      return const Center(child: Text('يرجى تسجيل الدخول أولاً'));
    }
    return AppShell(
      title: 'المواعيد',
      breadcrumbs: const [
        AppBreadcrumbItem(label: 'الرئيسية'),
        AppBreadcrumbItem(label: 'المواعيد'),
      ],
      currentRoute: '/appointments',
      onNavigate: (_) {},
      user: user,
      actions: [
        AppointmentsBookingAction(user: user),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return isDesktop
              ? AppointmentsDesktopView(
                  user: user,
                  appointmentsAsync: appointmentsAsync,
                  selectedDate: selectedDate,
                )
              : AppointmentsMobileView(
                  user: user,
                  appointmentsAsync: appointmentsAsync,
                  selectedDate: selectedDate,
                );
        },
      ),
    );
  }
}

/// Top-bar action used by the dashboard and the appointments screen to
/// open the booking dialog.
class AppointmentsBookingAction extends ConsumerWidget {
  final UserModel user;
  const AppointmentsBookingAction({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'حجز جديد',
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) =>
              BookAppointmentDialog(clinicId: user.clinicId),
        );
      },
      icon: const Icon(Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }
}
