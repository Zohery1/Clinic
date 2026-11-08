import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clinic_management/src/core/routing/app_router.dart';
import 'package:clinic_management/src/core/routing/app_routes.dart';
import 'package:clinic_management/src/features/appointments/presentation/examination_screen.dart';
import 'package:clinic_management/src/features/appointments/presentation/patient_queue_tracking_screen.dart';
import 'package:clinic_management/src/features/appointments/presentation/book_appointment_dialog.dart';
import 'package:clinic_management/src/features/reports/presentation/report_detail_screen.dart';
import 'package:clinic_management/src/features/auth/presentation/auth_gate.dart';
import 'package:clinic_management/src/features/auth/presentation/pending_activation_screen.dart';
import 'package:clinic_management/src/features/auth/presentation/account_blocked_screen.dart';
import 'package:clinic_management/src/features/auth/presentation/join_clinic_screen.dart';
import 'package:clinic_management/src/features/auth/presentation/subscription_gate_screen.dart';
import 'package:clinic_management/src/features/auth/presentation/top_up_subscription_screen.dart';
import 'package:clinic_management/src/features/patients/domain/patient_model.dart';
import 'package:clinic_management/src/features/patients/presentation/patient_details_dialog.dart';

void main() {
  group('Routing System - AppRoutes Constants', () {
    test('defines all standard clinical routes', () {
      expect(AppRoutes.root, '/');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.register, '/register');
      expect(AppRoutes.resetPassword, '/reset-password');
      expect(AppRoutes.verifyOtp, '/verify-otp');
      expect(AppRoutes.dashboard, '/dashboard');
      expect(AppRoutes.queueTracking, '/track');
      expect(AppRoutes.queue, '/queue');
      expect(AppRoutes.preview, '/preview');
      expect(AppRoutes.demo, '/demo');
      expect(AppRoutes.examination, '/examination');
      expect(AppRoutes.reportDetail, '/reports/detail');
      expect(AppRoutes.bookAppointment, '/appointments/book');
      expect(AppRoutes.patientDetails, '/patients/details');
      expect(AppRoutes.clinicDetails, '/settings/clinic-details');
      expect(AppRoutes.staffPermissions, '/settings/staff-permissions');
      expect(AppRoutes.clinicBranches, '/settings/branches');
      expect(AppRoutes.servicesConfig, '/settings/services');
      expect(AppRoutes.whatsappAutomation, '/settings/whatsapp');
      expect(AppRoutes.themeSettings, '/settings/theme');
      expect(AppRoutes.topUp, '/top-up');
      expect(AppRoutes.pendingActivation, '/pending-activation');
      expect(AppRoutes.accountBlocked, '/account-blocked');
      expect(AppRoutes.joinClinic, '/join-clinic');
      expect(AppRoutes.subscriptionGate, '/subscription-gate');
    });
  });

  group('Routing System - Route Arguments', () {
    test('ExaminationRouteArgs holds all required clinical identifiers', () {
      const args = ExaminationRouteArgs(
        clinicId: 'clinic_123',
        appointmentId: 'apt_456',
        patientId: 'pat_789',
        patientName: 'أحمد محمود',
      );

      expect(args.clinicId, 'clinic_123');
      expect(args.appointmentId, 'apt_456');
      expect(args.patientId, 'pat_789');
      expect(args.patientName, 'أحمد محمود');
    });

    test('ReportDetailRouteArgs stores dates and isMonthly flag', () {
      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 30);
      final args = ReportDetailRouteArgs(
        startDate: start,
        endDate: end,
        isMonthly: true,
      );

      expect(args.startDate, start);
      expect(args.endDate, end);
      expect(args.isMonthly, isTrue);
    });

    test('VerifyOtpRouteArgs holds email', () {
      const args = VerifyOtpRouteArgs(email: 'doctor@eyadaty.app');
      expect(args.email, 'doctor@eyadaty.app');
    });

    test('RegisterRouteArgs holds optional initial invite code', () {
      const args = RegisterRouteArgs(initialInviteCode: 'INV-999');
      expect(args.initialInviteCode, 'INV-999');
    });

    test('TopUpRouteArgs holds clinic metadata and onRefresh callback', () {
      var refreshed = false;
      final args = TopUpRouteArgs(
        clinicName: 'عيادة الأمل',
        inviteCode: 'INV-123',
        clinicId: 'c1',
        onRefresh: () => refreshed = true,
      );
      expect(args.clinicName, 'عيادة الأمل');
      expect(args.inviteCode, 'INV-123');
      expect(args.clinicId, 'c1');
      args.onRefresh();
      expect(refreshed, isTrue);
    });

    test('BookAppointmentRouteArgs holds clinicId and preselectedPatientId', () {
      const args = BookAppointmentRouteArgs(
        clinicId: 'clinic_42',
        preselectedPatientId: 'pat_100',
      );
      expect(args.clinicId, 'clinic_42');
      expect(args.preselectedPatientId, 'pat_100');
    });

    test('Subscription gate argument containers hold required callbacks and fields', () {
      var refreshedPending = false;
      final pendingArgs = PendingActivationRouteArgs(
        clinicName: 'عيادة النور',
        inviteCode: 'ACT-1',
        onRefresh: () => refreshedPending = true,
      );
      expect(pendingArgs.clinicName, 'عيادة النور');
      pendingArgs.onRefresh();
      expect(refreshedPending, isTrue);

      var refreshedBlocked = false;
      final blockedArgs = AccountBlockedRouteArgs(
        userName: 'د. سامي',
        clinicName: 'عيادة النور',
        onRefresh: () => refreshedBlocked = true,
      );
      expect(blockedArgs.userName, 'د. سامي');
      blockedArgs.onRefresh();
      expect(refreshedBlocked, isTrue);

      var refreshedJoin = false;
      final joinArgs = JoinClinicRouteArgs(
        userName: 'مروة سكرتيرة',
        onRefresh: () => refreshedJoin = true,
      );
      expect(joinArgs.userName, 'مروة سكرتيرة');
      joinArgs.onRefresh();
      expect(refreshedJoin, isTrue);

      var refreshedGate = false;
      final gateArgs = SubscriptionGateRouteArgs(
        clinicName: 'عيادة النور',
        subscriptionEndDate: DateTime(2026, 12, 31),
        isActive: false,
        onRefresh: () => refreshedGate = true,
      );
      expect(gateArgs.isActive, isFalse);
      gateArgs.onRefresh();
      expect(refreshedGate, isTrue);
    });
  });

  group('Routing System - AppRouter.onGenerateRoute Deep-Link & Edge Cases', () {
    testWidgets('generates default AuthGate route for unknown routes', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      const settings = RouteSettings(name: '/non-existent-route-path');
      final route = AppRouter.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(ctx);
      expect(widget, isA<AuthGate>());
    });

    testWidgets('generates AuthGate explicitly for /dashboard and root /', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      final rootRoute = AppRouter.onGenerateRoute(const RouteSettings(name: '/'));
      expect((rootRoute as MaterialPageRoute).builder(ctx), isA<AuthGate>());

      final dashRoute = AppRouter.onGenerateRoute(const RouteSettings(name: '/dashboard'));
      expect((dashRoute as MaterialPageRoute).builder(ctx), isA<AuthGate>());
    });

    testWidgets('handles malformed deep-link query parameters safely without throwing', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      // Test %ZZ invalid percent encoding
      const malformedSettings = RouteSettings(name: '/track?id=%ZZ');
      final route = AppRouter.onGenerateRoute(malformedSettings);
      expect(route, isA<MaterialPageRoute>());
      final widget = (route as MaterialPageRoute).builder(ctx);
      expect(widget, isA<PatientQueueTrackingScreen>());
      final screen = widget as PatientQueueTrackingScreen;
      expect(screen.appointmentId, '');

      // Test empty query param
      const emptySettings = RouteSettings(name: '/track?id=');
      final emptyRoute = AppRouter.onGenerateRoute(emptySettings);
      expect((emptyRoute as MaterialPageRoute).builder(ctx), isA<PatientQueueTrackingScreen>());

      // Test valid query param
      const validSettings = RouteSettings(name: '/track?id=apt_9999');
      final validRoute = AppRouter.onGenerateRoute(validSettings);
      final validWidget = (validRoute as MaterialPageRoute).builder(ctx) as PatientQueueTrackingScreen;
      expect(validWidget.appointmentId, 'apt_9999');
    });

    testWidgets('handles /queue path cleanly', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      const settings = RouteSettings(name: '/queue');
      final route = AppRouter.onGenerateRoute(settings);
      expect((route as MaterialPageRoute).builder(ctx), isA<PatientQueueTrackingScreen>());
    });

    testWidgets('handles /appointments/book as a route', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      const settings = RouteSettings(
        name: AppRoutes.bookAppointment,
        arguments: BookAppointmentRouteArgs(
          clinicId: 'clinic_test',
          preselectedPatientId: 'pat_test',
        ),
      );
      final route = AppRouter.onGenerateRoute(settings);
      expect(route, isA<MaterialPageRoute>());
      final widget = (route as MaterialPageRoute).builder(ctx);
      expect(widget, isA<BookAppointmentDialog>());
      final dialog = widget as BookAppointmentDialog;
      expect(dialog.clinicId, 'clinic_test');
      expect(dialog.preselectedPatientId, 'pat_test');
    });

    testWidgets('handles /patients/details as a route with PatientDetailsRouteArgs', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      final mockPatient = PatientModel(
        id: 'p1',
        clinicId: 'c1',
        fullName: 'فاطمة علي',
        phone: '01012345678',
        createdAt: DateTime.now(),
      );
      final settings = RouteSettings(
        name: AppRoutes.patientDetails,
        arguments: PatientDetailsRouteArgs(
          clinicId: 'c1',
          patient: mockPatient,
        ),
      );
      final route = AppRouter.onGenerateRoute(settings);
      expect(route, isA<MaterialPageRoute>());
      final widget = (route as MaterialPageRoute).builder(ctx);
      expect(widget, isA<PatientDetailsDialog>());
      final dialog = widget as PatientDetailsDialog;
      expect(dialog.clinicId, 'c1');
      expect(dialog.patient.fullName, 'فاطمة علي');
    });

    testWidgets('handles /examination with ExaminationRouteArgs, Map, and URI query params', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      // 1. Strongly-typed args
      const typedSettings = RouteSettings(
        name: AppRoutes.examination,
        arguments: ExaminationRouteArgs(
          clinicId: 'c1',
          appointmentId: 'a1',
          patientId: 'p1',
          patientName: 'كريم',
        ),
      );
      final typedRoute = AppRouter.onGenerateRoute(typedSettings);
      final typedWidget = (typedRoute as MaterialPageRoute).builder(ctx) as ExaminationScreen;
      expect(typedWidget.clinicId, 'c1');
      expect(typedWidget.appointmentId, 'a1');
      expect(typedWidget.patientName, 'كريم');

      // 2. Map args
      const mapSettings = RouteSettings(
        name: AppRoutes.examination,
        arguments: {
          'clinicId': 'c2',
          'appointmentId': 'a2',
          'patientId': 'p2',
          'patientName': 'سارة',
        },
      );
      final mapRoute = AppRouter.onGenerateRoute(mapSettings);
      final mapWidget = (mapRoute as MaterialPageRoute).builder(ctx) as ExaminationScreen;
      expect(mapWidget.clinicId, 'c2');
      expect(mapWidget.patientName, 'سارة');

      // 3. Query string deep link
      const querySettings = RouteSettings(
        name: '/examination?clinicId=c3&appointmentId=a3&patientId=p3&patientName=محمود',
      );
      final queryRoute = AppRouter.onGenerateRoute(querySettings);
      final queryWidget = (queryRoute as MaterialPageRoute).builder(ctx) as ExaminationScreen;
      expect(queryWidget.clinicId, 'c3');
      expect(queryWidget.patientName, 'محمود');

      // 4. Fallback without arguments (does not throw)
      const emptySettings = RouteSettings(name: AppRoutes.examination);
      final emptyRoute = AppRouter.onGenerateRoute(emptySettings);
      expect((emptyRoute as MaterialPageRoute).builder(ctx), isA<ExaminationScreen>());
    });

    testWidgets('handles /reports/detail with ReportDetailRouteArgs and query params', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      final start = DateTime(2026, 11, 1);
      final end = DateTime(2026, 11, 30);
      final settings = RouteSettings(
        name: AppRoutes.reportDetail,
        arguments: ReportDetailRouteArgs(
          startDate: start,
          endDate: end,
          isMonthly: true,
        ),
      );
      final route = AppRouter.onGenerateRoute(settings);
      final widget = (route as MaterialPageRoute).builder(ctx) as ReportDetailScreen;
      expect(widget.startDate, start);
      expect(widget.isMonthly, isTrue);

      // Deep link with query string
      const querySettings = RouteSettings(name: '/reports/detail?start=2026-11-01&end=2026-11-15&monthly=true');
      final queryRoute = AppRouter.onGenerateRoute(querySettings);
      final queryWidget = (queryRoute as MaterialPageRoute).builder(ctx) as ReportDetailScreen;
      expect(queryWidget.isMonthly, isTrue);
    });

    testWidgets('handles all subscription gates without throwing', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      final topUpRoute = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.topUp));
      expect((topUpRoute as MaterialPageRoute).builder(ctx), isA<TopUpSubscriptionScreen>());

      final pendingRoute = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.pendingActivation));
      expect((pendingRoute as MaterialPageRoute).builder(ctx), isA<PendingActivationScreen>());

      final blockedRoute = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.accountBlocked));
      expect((blockedRoute as MaterialPageRoute).builder(ctx), isA<AccountBlockedScreen>());

      final joinRoute = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.joinClinic));
      expect((joinRoute as MaterialPageRoute).builder(ctx), isA<JoinClinicScreen>());

      final gateRoute = AppRouter.onGenerateRoute(const RouteSettings(name: AppRoutes.subscriptionGate));
      expect((gateRoute as MaterialPageRoute).builder(ctx), isA<SubscriptionGateScreen>());
    });

    testWidgets('handles settings subpages cleanly', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      final routes = [
        AppRoutes.clinicDetails,
        AppRoutes.staffPermissions,
        AppRoutes.clinicBranches,
        AppRoutes.servicesConfig,
        AppRoutes.whatsappAutomation,
        AppRoutes.themeSettings,
      ];
      for (final r in routes) {
        final res = AppRouter.onGenerateRoute(RouteSettings(name: r));
        expect((res as MaterialPageRoute).builder(ctx), isNotNull);
      }
    });
  });
}
