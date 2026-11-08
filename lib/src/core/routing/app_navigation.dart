import 'package:flutter/material.dart';

import '../../features/appointments/presentation/book_appointment_dialog.dart';
import '../../features/patients/domain/patient_model.dart';
import '../../features/patients/presentation/patient_details_dialog.dart';
import '../widgets/send_whatsapp_dialog.dart';
import 'app_routes.dart';

/// واجهة التنقل الموحدة (Central Navigation Facade).
/// تفصل تماماً بين الشاشات الطالبة والشاشات المطلوبة، مما يضمن إمكانية إعادة تصميم
/// أو استبدال أي شاشة سريرية بالكامل دون كسر أي شاشة أخرى في النظام.
class AppNavigation {
  const AppNavigation._();

  /// الانتقال إلى شاشة تسجيل الدخول
  static Future<T?> toLogin<T>(
    BuildContext context, {
    bool replace = false,
    bool clearStack = false,
  }) {
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        AppRoutes.login,
        (route) => false,
      );
    }
    if (replace) {
      return Navigator.of(context).pushReplacementNamed<T, dynamic>(
        AppRoutes.login,
      );
    }
    return Navigator.of(context).pushNamed<T>(AppRoutes.login);
  }

  /// الانتقال إلى شاشة التسجيل
  static Future<T?> toRegister<T>(
    BuildContext context, {
    String? inviteCode,
    bool replace = false,
  }) {
    final routeName = inviteCode != null && inviteCode.isNotEmpty
        ? '${AppRoutes.register}?code=$inviteCode'
        : AppRoutes.register;
    final args = RegisterRouteArgs(initialInviteCode: inviteCode);

    if (replace) {
      return Navigator.of(context).pushReplacementNamed<T, dynamic>(
        routeName,
        arguments: args,
      );
    }
    return Navigator.of(context).pushNamed<T>(
      routeName,
      arguments: args,
    );
  }

  /// الانتقال إلى شاشة إعادة تعيين كلمة المرور
  static Future<T?> toResetPassword<T>(
    BuildContext context, {
    bool isUpdateMode = false,
  }) {
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.resetPassword,
      arguments: isUpdateMode,
    );
  }

  /// الانتقال إلى شاشة تأكيد رمز التحقق (OTP)
  static Future<T?> toVerifyOtp<T>(
    BuildContext context, {
    required String email,
  }) {
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.verifyOtp,
      arguments: VerifyOtpRouteArgs(email: email),
    );
  }

  /// الانتقال إلى لوحة التحكم الرئيسية / البوابة المركزية
  static Future<T?> toDashboard<T>(
    BuildContext context, {
    bool clearStack = false,
  }) {
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        AppRoutes.dashboard,
        (route) => false,
      );
    }
    return Navigator.of(context).pushNamed<T>(AppRoutes.dashboard);
  }

  /// فتح شاشة متابعة طابور المريض (Queue Tracker)
  static Future<T?> toQueueTracking<T>(
    BuildContext context, {
    required String appointmentId,
  }) {
    return Navigator.of(context).pushNamed<T>(
      '${AppRoutes.queueTracking}?id=$appointmentId',
      arguments: appointmentId,
    );
  }

  /// الانتقال إلى مساحة عمل الفحص السريري (Examination Cockpit)
  static Future<T?> toExamination<T>(
    BuildContext context, {
    required String clinicId,
    required String appointmentId,
    required String patientId,
    required String patientName,
  }) {
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.examination,
      arguments: ExaminationRouteArgs(
        clinicId: clinicId,
        appointmentId: appointmentId,
        patientId: patientId,
        patientName: patientName,
      ),
    );
  }

  /// الانتقال إلى تقرير تفصيلي لفترة محددة
  static Future<T?> toReportDetail<T>(
    BuildContext context, {
    required DateTime startDate,
    required DateTime endDate,
    bool isMonthly = false,
  }) {
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.reportDetail,
      arguments: ReportDetailRouteArgs(
        startDate: startDate,
        endDate: endDate,
        isMonthly: isMonthly,
      ),
    );
  }

  /// صفحات الإعدادات
  static Future<T?> toClinicDetails<T>(BuildContext context) =>
      Navigator.of(context).pushNamed<T>(AppRoutes.clinicDetails);

  static Future<T?> toStaffPermissions<T>(BuildContext context) =>
      Navigator.of(context).pushNamed<T>(AppRoutes.staffPermissions);

  static Future<T?> toClinicBranches<T>(BuildContext context) =>
      Navigator.of(context).pushNamed<T>(AppRoutes.clinicBranches);

  static Future<T?> toServicesConfig<T>(BuildContext context) =>
      Navigator.of(context).pushNamed<T>(AppRoutes.servicesConfig);

  static Future<T?> toWhatsAppAutomation<T>(BuildContext context) =>
      Navigator.of(context).pushNamed<T>(AppRoutes.whatsappAutomation);

  static Future<T?> toThemeSettings<T>(BuildContext context) =>
      Navigator.of(context).pushNamed<T>(AppRoutes.themeSettings);

  /// الانتقال إلى شاشة شحن وتجديد الاشتراك
  static Future<T?> toTopUp<T>(
    BuildContext context, {
    required String clinicName,
    required String inviteCode,
    required String clinicId,
    required VoidCallback onRefresh,
    bool clearStack = false,
  }) {
    final args = TopUpRouteArgs(
      clinicName: clinicName,
      inviteCode: inviteCode,
      clinicId: clinicId,
      onRefresh: onRefresh,
    );
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        AppRoutes.topUp,
        (route) => false,
        arguments: args,
      );
    }
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.topUp,
      arguments: args,
    );
  }

  /// الانتقال إلى شاشة انتظار تفعيل العيادة
  static Future<T?> toPendingActivation<T>(
    BuildContext context, {
    required String clinicName,
    required String inviteCode,
    required VoidCallback onRefresh,
    bool clearStack = false,
  }) {
    final args = PendingActivationRouteArgs(
      clinicName: clinicName,
      inviteCode: inviteCode,
      onRefresh: onRefresh,
    );
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        AppRoutes.pendingActivation,
        (route) => false,
        arguments: args,
      );
    }
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.pendingActivation,
      arguments: args,
    );
  }

  /// الانتقال إلى شاشة الحساب المعطل
  static Future<T?> toAccountBlocked<T>(
    BuildContext context, {
    required String userName,
    required String clinicName,
    required VoidCallback onRefresh,
    bool clearStack = false,
  }) {
    final args = AccountBlockedRouteArgs(
      userName: userName,
      clinicName: clinicName,
      onRefresh: onRefresh,
    );
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        AppRoutes.accountBlocked,
        (route) => false,
        arguments: args,
      );
    }
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.accountBlocked,
      arguments: args,
    );
  }

  /// الانتقال إلى شاشة الانضمام لعيادة
  static Future<T?> toJoinClinic<T>(
    BuildContext context, {
    required String userName,
    required VoidCallback onRefresh,
    bool clearStack = false,
  }) {
    final args = JoinClinicRouteArgs(
      userName: userName,
      onRefresh: onRefresh,
    );
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        AppRoutes.joinClinic,
        (route) => false,
        arguments: args,
      );
    }
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.joinClinic,
      arguments: args,
    );
  }

  /// الانتقال إلى بوابة الاشتراك
  static Future<T?> toSubscriptionGate<T>(
    BuildContext context, {
    required String clinicName,
    DateTime? subscriptionEndDate,
    bool isActive = false,
    required VoidCallback onRefresh,
    bool clearStack = false,
  }) {
    final args = SubscriptionGateRouteArgs(
      clinicName: clinicName,
      subscriptionEndDate: subscriptionEndDate,
      isActive: isActive,
      onRefresh: onRefresh,
    );
    if (clearStack) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        AppRoutes.subscriptionGate,
        (route) => false,
        arguments: args,
      );
    }
    return Navigator.of(context).pushNamed<T>(
      AppRoutes.subscriptionGate,
      arguments: args,
    );
  }

  /// فتح نافذة حجز موعد جديد
  static Future<T?> showBookAppointment<T>(
    BuildContext context, {
    required String clinicId,
    String? preselectedPatientId,
  }) {
    return BookAppointmentDialog.show<T>(
      context: context,
      clinicId: clinicId,
      preselectedPatientId: preselectedPatientId,
    );
  }

  /// فتح ملف وسجل المريض السريري (Patient Profile / Details)
  static Future<T?> showPatientDetails<T>(
    BuildContext context, {
    required String clinicId,
    required PatientModel patient,
    bool asFullscreen = false,
  }) {
    if (asFullscreen) {
      return Navigator.of(context).pushNamed<T>(
        AppRoutes.patientDetails,
        arguments: PatientDetailsRouteArgs(
          clinicId: clinicId,
          patient: patient,
        ),
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PatientDetailsDialog(
        clinicId: clinicId,
        patient: patient,
      ),
    );
  }

  /// إرسال رسالة واتساب
  static void showWhatsApp(
    BuildContext context, {
    dynamic ref,
    required String phone,
    required String patientName,
    String? initialMessage,
  }) {
    showDialog(
      context: context,
      builder: (_) => SendWhatsAppDialog(
        phone: phone,
        patientName: patientName,
        initialMessage: initialMessage,
      ),
    );
  }

  /// الرجوع خطوة للخلف
  static void pop<T>(BuildContext context, [T? result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop<T>(result);
    }
  }
}
