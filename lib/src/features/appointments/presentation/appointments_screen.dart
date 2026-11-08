import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/tokens/colors.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/login_controller.dart';
import '../../../core/routing/routing.dart';
import 'appointments_controller.dart';
import 'widgets/appointments_desktop_view.dart';
import 'widgets/appointments_mobile_view.dart';

/// الشاشة المركزية لإدارة المواعيد في تطبيق عيادتي (Appointments Hub).
/// تستقبل المعلمات الأساسية للمنشأة والاشتراك، وتقوم بالتوزيع المتجاوب (Responsive Layout)
/// بناءً على قيود الشاشة:
/// - شاشات سطح المكتب والأجهزة اللوحية العريضة (Width >= 900px): [AppointmentsDesktopView]
/// - شاشات الهواتف والأجهزة المدمجة (Width < 900px): [AppointmentsMobileView]
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

    // تفعيل مزود المزامنة اللحظية طالما الشاشة نشطة
    ref.watch(realtimeAppointmentsSyncProvider);

    if (user == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.canvas(context),
          body: Center(
            child: Text(
              'يرجى تسجيل الدخول أولاً للوصول إلى المواعيد',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          if (isDesktop) {
            return Scaffold(
              backgroundColor: AppColors.canvas(context),
              body: AppointmentsDesktopView(
                user: user,
                appointmentsAsync: appointmentsAsync,
                selectedDate: selectedDate,
              ),
            );
          }

          // واجهة الموبايل تدير Scaffold الخاص بها لدعم الـ FloatingActionButton
          return AppointmentsMobileView(
            user: user,
            appointmentsAsync: appointmentsAsync,
            selectedDate: selectedDate,
          );
        },
      ),
    );
  }
}

/// زر إجراء الحجز العلوي السريع المستخدم في شريط التطبيق أو لوحة التحكم.
class AppointmentsBookingAction extends ConsumerWidget {
  final UserModel user;

  const AppointmentsBookingAction({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'حجز جديد',
      onPressed: () => AppNavigation.showBookAppointment(
        context,
        clinicId: user.clinicId,
      ),
      icon: const Icon(Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }
}
