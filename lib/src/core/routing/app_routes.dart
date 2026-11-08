import 'package:flutter/foundation.dart';
import '../../features/patients/domain/patient_model.dart';

/// أسماء المسارات المركزية للتطبيق (Central Application Route Names).
/// تُستخدم لفك الارتباط المباشر بين واجهات المستخدم والميزات المختلفة.
abstract class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String verifyOtp = '/verify-otp';
  static const String dashboard = '/dashboard';
  static const String queueTracking = '/track';
  static const String queue = '/queue';
  static const String preview = '/preview';
  static const String demo = '/demo';

  // مساحات العمل والميزات السريرية
  static const String examination = '/examination';
  static const String reportDetail = '/reports/detail';
  static const String bookAppointment = '/appointments/book';
  static const String patientDetails = '/patients/details';

  // صفحات الإعدادات الفرعية
  static const String clinicDetails = '/settings/clinic-details';
  static const String staffPermissions = '/settings/staff-permissions';
  static const String clinicBranches = '/settings/branches';
  static const String servicesConfig = '/settings/services';
  static const String whatsappAutomation = '/settings/whatsapp';
  static const String themeSettings = '/settings/theme';

  // بوابات حالة الحساب والاشتراك
  static const String topUp = '/top-up';
  static const String pendingActivation = '/pending-activation';
  static const String accountBlocked = '/account-blocked';
  static const String joinClinic = '/join-clinic';
  static const String subscriptionGate = '/subscription-gate';
}

/// وسائط مسار الفحص السريري (Examination Cockpit Route Arguments)
@immutable
class ExaminationRouteArgs {
  final String clinicId;
  final String appointmentId;
  final String patientId;
  final String patientName;

  const ExaminationRouteArgs({
    required this.clinicId,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
  });
}

/// وسائط مسار تقرير العمليات والأرباح التفصيلي
@immutable
class ReportDetailRouteArgs {
  final DateTime startDate;
  final DateTime endDate;
  final bool isMonthly;

  const ReportDetailRouteArgs({
    required this.startDate,
    required this.endDate,
    this.isMonthly = false,
  });
}

/// وسائط تأكيد رمز التحقق (OTP)
@immutable
class VerifyOtpRouteArgs {
  final String email;

  const VerifyOtpRouteArgs({required this.email});
}

/// وسائط التسجيل وإنشاء الحساب
@immutable
class RegisterRouteArgs {
  final String? initialInviteCode;

  const RegisterRouteArgs({this.initialInviteCode});
}

/// وسائط شاشة تجديد وشحن الاشتراك
@immutable
class TopUpRouteArgs {
  final String clinicName;
  final String inviteCode;
  final String clinicId;
  final VoidCallback onRefresh;

  const TopUpRouteArgs({
    required this.clinicName,
    required this.inviteCode,
    required this.clinicId,
    required this.onRefresh,
  });
}

/// وسائط تفاصيل المريض
@immutable
class PatientDetailsRouteArgs {
  final String clinicId;
  final PatientModel patient;

  const PatientDetailsRouteArgs({
    required this.clinicId,
    required this.patient,
  });
}

/// وسائط حجز موعد جديد
@immutable
class BookAppointmentRouteArgs {
  final String clinicId;
  final String? preselectedPatientId;

  const BookAppointmentRouteArgs({
    required this.clinicId,
    this.preselectedPatientId,
  });
}

/// وسائط شاشة انتظار التفعيل
@immutable
class PendingActivationRouteArgs {
  final String clinicName;
  final String inviteCode;
  final VoidCallback onRefresh;

  const PendingActivationRouteArgs({
    required this.clinicName,
    required this.inviteCode,
    required this.onRefresh,
  });
}

/// وسائط شاشة الحساب المعطل
@immutable
class AccountBlockedRouteArgs {
  final String userName;
  final String clinicName;
  final VoidCallback onRefresh;

  const AccountBlockedRouteArgs({
    required this.userName,
    required this.clinicName,
    required this.onRefresh,
  });
}

/// وسائط شاشة الانضمام لعيادة
@immutable
class JoinClinicRouteArgs {
  final String userName;
  final VoidCallback onRefresh;

  const JoinClinicRouteArgs({
    required this.userName,
    required this.onRefresh,
  });
}

/// وسائط بوابة الاشتراك
@immutable
class SubscriptionGateRouteArgs {
  final String clinicName;
  final DateTime? subscriptionEndDate;
  final bool isActive;
  final VoidCallback onRefresh;

  const SubscriptionGateRouteArgs({
    required this.clinicName,
    this.subscriptionEndDate,
    this.isActive = false,
    required this.onRefresh,
  });
}

