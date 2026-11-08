import 'package:flutter/material.dart';

import '../utils/invite_utils.dart';
import 'app_routes.dart';

// استيراد شاشات المصادقة والبوابات المركزية
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';
import '../../features/auth/presentation/preview_gate.dart';
import '../../features/auth/presentation/top_up_subscription_screen.dart';
import '../../features/auth/presentation/pending_activation_screen.dart';
import '../../features/auth/presentation/account_blocked_screen.dart';
import '../../features/auth/presentation/join_clinic_screen.dart';
import '../../features/auth/presentation/subscription_gate_screen.dart';

// استيراد الشاشات السريرية والتشغيلية
import '../../features/appointments/presentation/patient_queue_tracking_screen.dart';
import '../../features/appointments/presentation/examination_screen.dart';
import '../../features/appointments/presentation/book_appointment_dialog.dart';
import '../../features/patients/presentation/patient_details_dialog.dart';
import '../../features/reports/presentation/report_detail_screen.dart';

// استيراد صفحات الإعدادات
import '../../features/settings/presentation/subpages/clinic_details_page.dart';
import '../../features/settings/presentation/clinic_branches_page.dart';
import '../../features/settings/presentation/subpages/staff_permissions_page.dart';
import '../../features/settings/presentation/subpages/services_config_page.dart';
import '../../features/settings/presentation/subpages/whatsapp_automation_page.dart';
import '../../features/settings/presentation/subpages/theme_settings_page.dart';

/// موجه التطبيق المركزي (Central Application Router).
/// يوفر نقطة موحدة لإنشاء المسارات، واستخراج معلمات الروابط (Deep Links)،
/// وفك الارتباط التام بين واجهات المستخدم.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? AppRoutes.root;
    final inviteCode = InviteUtils.extractInviteCode(routeName: name);

    // 1. مسار متابعة طابور المرضى (Live Patient Queue Tracking)
    if (name.contains(AppRoutes.queueTracking) || name.contains(AppRoutes.queue)) {
      String? apptId;
      try {
        final parsedUri = Uri.tryParse(name);
        if (parsedUri != null && parsedUri.hasQuery) {
          apptId = parsedUri.queryParameters['id'];
        }
      } catch (_) {}

      if (apptId == null || apptId.isEmpty) {
        try {
          final baseUri = Uri.base;
          if (baseUri.hasQuery) {
            apptId = baseUri.queryParameters['id'];
          }
        } catch (_) {}
      }

      if (apptId == null || apptId.isEmpty) {
        try {
          final frag = Uri.base.fragment;
          if (frag.contains('id=')) {
            final fragUri = Uri.tryParse(frag.startsWith('/') ? frag : '/$frag');
            if (fragUri != null && fragUri.hasQuery) {
              apptId = fragUri.queryParameters['id'];
            }
          }
        } catch (_) {}
      }

      if (settings.arguments is String) {
        apptId = settings.arguments as String;
      }

      if (apptId != null) {
        try {
          if (apptId.contains('%')) {
            apptId = Uri.decodeQueryComponent(apptId);
          }
        } catch (_) {
          apptId = '';
        }
      }

      return MaterialPageRoute<void>(
        builder: (_) => PatientQueueTrackingScreen(appointmentId: apptId ?? ''),
        settings: settings,
      );
    }

    // 2. مسار إعادة تعيين كلمة المرور
    if (name.contains('/reset') || name == AppRoutes.resetPassword) {
      final isUpdate = settings.arguments is bool ? (settings.arguments as bool) : true;
      return MaterialPageRoute<void>(
        builder: (_) => ResetPasswordScreen(isUpdateMode: isUpdate),
        settings: settings,
      );
    }

    // 3. مسار التحقق من كود البريد (OTP)
    if (name == AppRoutes.verifyOtp) {
      final args = settings.arguments;
      final email = args is VerifyOtpRouteArgs
          ? args.email
          : (args is String ? args : '');
      return MaterialPageRoute<void>(
        builder: (_) => VerifyOtpScreen(email: email),
        settings: settings,
      );
    }

    // 4. مسار التسجيل وإنشاء حساب جديد
    if (name.contains(AppRoutes.register) || (inviteCode != null && inviteCode.isNotEmpty)) {
      final code = (settings.arguments is RegisterRouteArgs)
          ? (settings.arguments as RegisterRouteArgs).initialInviteCode
          : inviteCode;
      return MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(initialInviteCode: code),
        settings: settings,
      );
    }

    // 5. مسار المعاينة السريرية الفورية (Demo Preview)
    if (name.contains(AppRoutes.preview) || name.contains(AppRoutes.demo)) {
      return MaterialPageRoute<void>(
        builder: (_) => const PreviewGate(),
        settings: settings,
      );
    }

    // 6. مسار تسجيل الدخول
    if (name == AppRoutes.login) {
      return MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
        settings: settings,
      );
    }

    // 7. مسار قمرة قيادة الفحص السريري (Examination Cockpit)
    if (name.contains(AppRoutes.examination)) {
      String clinicId = '';
      String appointmentId = '';
      String patientId = '';
      String patientName = '';

      if (settings.arguments is ExaminationRouteArgs) {
        final args = settings.arguments as ExaminationRouteArgs;
        clinicId = args.clinicId;
        appointmentId = args.appointmentId;
        patientId = args.patientId;
        patientName = args.patientName;
      } else if (settings.arguments is Map) {
        final map = settings.arguments as Map;
        clinicId = map['clinicId']?.toString() ?? '';
        appointmentId = map['appointmentId']?.toString() ?? '';
        patientId = map['patientId']?.toString() ?? '';
        patientName = map['patientName']?.toString() ?? '';
      } else {
        try {
          final uri = Uri.tryParse(name);
          if (uri != null && uri.hasQuery) {
            clinicId = uri.queryParameters['clinicId'] ?? '';
            appointmentId = uri.queryParameters['appointmentId'] ?? '';
            patientId = uri.queryParameters['patientId'] ?? '';
            patientName = uri.queryParameters['patientName'] ?? '';
          }
        } catch (_) {}
      }

      return MaterialPageRoute<void>(
        builder: (_) => ExaminationScreen(
          clinicId: clinicId,
          appointmentId: appointmentId,
          patientId: patientId,
          patientName: patientName,
        ),
        settings: settings,
      );
    }

    // 8. مسار التقرير المالي والتشغيلي المفصل (Detailed Report)
    if (name.contains(AppRoutes.reportDetail)) {
      DateTime startDate = DateTime.now();
      DateTime endDate = DateTime.now();
      bool isMonthly = false;

      if (settings.arguments is ReportDetailRouteArgs) {
        final args = settings.arguments as ReportDetailRouteArgs;
        startDate = args.startDate;
        endDate = args.endDate;
        isMonthly = args.isMonthly;
      } else if (settings.arguments is Map) {
        final map = settings.arguments as Map;
        startDate = DateTime.tryParse(map['startDate']?.toString() ?? '') ?? DateTime.now();
        endDate = DateTime.tryParse(map['endDate']?.toString() ?? '') ?? DateTime.now();
        isMonthly = map['isMonthly'] == true;
      } else {
        try {
          final uri = Uri.tryParse(name);
          if (uri != null && uri.hasQuery) {
            final sStr = uri.queryParameters['startDate'] ?? uri.queryParameters['start'];
            final eStr = uri.queryParameters['endDate'] ?? uri.queryParameters['end'];
            if (sStr != null) startDate = DateTime.tryParse(sStr) ?? startDate;
            if (eStr != null) endDate = DateTime.tryParse(eStr) ?? endDate;
            isMonthly = uri.queryParameters['monthly'] == 'true' || uri.queryParameters['isMonthly'] == 'true';
          }
        } catch (_) {}
      }

      return MaterialPageRoute<void>(
        builder: (_) => ReportDetailScreen(
          startDate: startDate,
          endDate: endDate,
          isMonthly: isMonthly,
        ),
        settings: settings,
      );
    }

    // 9. نافذة حجز موعد جديد كمسار
    if (name == AppRoutes.bookAppointment) {
      final args = settings.arguments is BookAppointmentRouteArgs
          ? settings.arguments as BookAppointmentRouteArgs
          : null;
      final clinicId = args?.clinicId ?? '';
      return MaterialPageRoute<void>(
        builder: (_) => BookAppointmentDialog(
          clinicId: clinicId,
          preselectedPatientId: args?.preselectedPatientId,
        ),
        settings: settings,
      );
    }

    // 10. شاشة ملف وسجل المريض السريري كمسار
    if (name == AppRoutes.patientDetails && settings.arguments is PatientDetailsRouteArgs) {
      final args = settings.arguments as PatientDetailsRouteArgs;
      return MaterialPageRoute<void>(
        builder: (_) => PatientDetailsDialog(
          clinicId: args.clinicId,
          patient: args.patient,
        ),
        settings: settings,
      );
    }

    // 11. صفحات الإعدادات الفرعية
    if (name == AppRoutes.clinicDetails) {
      return MaterialPageRoute<void>(
        builder: (_) => const ClinicDetailsPage(),
        settings: settings,
      );
    }
    if (name == AppRoutes.staffPermissions) {
      return MaterialPageRoute<void>(
        builder: (_) => const StaffPermissionsPage(),
        settings: settings,
      );
    }
    if (name == AppRoutes.clinicBranches) {
      return MaterialPageRoute<void>(
        builder: (_) => const ClinicBranchesPage(),
        settings: settings,
      );
    }
    if (name == AppRoutes.servicesConfig) {
      return MaterialPageRoute<void>(
        builder: (_) => const ServicesConfigPage(),
        settings: settings,
      );
    }
    if (name == AppRoutes.whatsappAutomation) {
      return MaterialPageRoute<void>(
        builder: (_) => const WhatsAppAutomationPage(),
        settings: settings,
      );
    }
    if (name == AppRoutes.themeSettings) {
      return MaterialPageRoute<void>(
        builder: (_) => const ThemeSettingsPage(),
        settings: settings,
      );
    }

    // 12. بوابات حالة الحساب والاشتراك
    if (name == AppRoutes.topUp) {
      final args = settings.arguments is TopUpRouteArgs
          ? settings.arguments as TopUpRouteArgs
          : null;
      return MaterialPageRoute<void>(
        builder: (_) => TopUpSubscriptionScreen(
          clinicName: args?.clinicName ?? '',
          inviteCode: args?.inviteCode ?? '',
          clinicId: args?.clinicId ?? '',
          onRefresh: args?.onRefresh ?? () {},
        ),
        settings: settings,
      );
    }

    if (name == AppRoutes.pendingActivation) {
      final args = settings.arguments is PendingActivationRouteArgs
          ? settings.arguments as PendingActivationRouteArgs
          : null;
      return MaterialPageRoute<void>(
        builder: (_) => PendingActivationScreen(
          clinicName: args?.clinicName ?? '',
          inviteCode: args?.inviteCode ?? '',
          onRefresh: args?.onRefresh ?? () {},
        ),
        settings: settings,
      );
    }

    if (name == AppRoutes.accountBlocked) {
      final args = settings.arguments is AccountBlockedRouteArgs
          ? settings.arguments as AccountBlockedRouteArgs
          : null;
      return MaterialPageRoute<void>(
        builder: (_) => AccountBlockedScreen(
          userName: args?.userName ?? '',
          clinicName: args?.clinicName ?? '',
          onRefresh: args?.onRefresh ?? () {},
        ),
        settings: settings,
      );
    }

    if (name == AppRoutes.joinClinic) {
      final args = settings.arguments is JoinClinicRouteArgs
          ? settings.arguments as JoinClinicRouteArgs
          : null;
      return MaterialPageRoute<void>(
        builder: (_) => JoinClinicScreen(
          userName: args?.userName ?? '',
          onRefresh: args?.onRefresh ?? () {},
        ),
        settings: settings,
      );
    }

    if (name == AppRoutes.subscriptionGate) {
      final args = settings.arguments is SubscriptionGateRouteArgs
          ? settings.arguments as SubscriptionGateRouteArgs
          : null;
      return MaterialPageRoute<void>(
        builder: (_) => SubscriptionGateScreen(
          clinicName: args?.clinicName ?? '',
          subscriptionEndDate: args?.subscriptionEndDate,
          isActive: args?.isActive ?? false,
          onRefresh: args?.onRefresh ?? () {},
        ),
        settings: settings,
      );
    }

    // 13. المسار الافتراضي واللوحة الرئيسية — بوابة المصادقة والحالة الذكية
    return MaterialPageRoute<void>(
      builder: (_) => AuthGate(initialInviteCode: inviteCode),
      settings: settings,
    );
  }
}
