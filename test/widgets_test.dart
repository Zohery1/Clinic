import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:clinic_management/src/core/ui/layout/app_top_bar.dart';
import 'package:clinic_management/src/core/widgets/double_bezel_card.dart';
import 'package:clinic_management/src/features/appointments/presentation/widgets/appointments_calendar_strip.dart';
import 'package:clinic_management/src/features/appointments/presentation/widgets/appointments_desktop_view.dart';
import 'package:clinic_management/src/features/appointments/presentation/appointments_controller.dart';
import 'package:clinic_management/src/features/appointments/data/appointment_repository.dart';
import 'package:clinic_management/src/features/clinics/presentation/clinics_controller.dart';
import 'package:clinic_management/src/features/clinics/domain/branch_model.dart';
import 'package:clinic_management/src/features/auth/domain/user_model.dart';
import 'package:clinic_management/src/features/auth/presentation/login_controller.dart';
import 'package:clinic_management/src/features/appointments/domain/appointment_model.dart';
import 'package:clinic_management/src/features/patients/domain/patient_model.dart';
import 'package:clinic_management/src/features/patients/presentation/widgets/patient_list_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  group('DoubleBezelCard Widget Tests', () {
    testWidgets('renders child content with clinical styling and responds to taps',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleBezelCard(
              onTap: () => tapped = true,
              child: const Text('بطاقة المريض'),
            ),
          ),
        ),
      );

      expect(find.text('بطاقة المريض'), findsOneWidget);

      await tester.tap(find.text('بطاقة المريض'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders layered double-bezel structure and active glow state',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoubleBezelCard(
              isActiveGlow: true,
              outerRadius: 20.0,
              innerRadius: 17.5,
              child: Text('قيد الفحص'),
            ),
          ),
        ),
      );

      expect(find.text('قيد الفحص'), findsOneWidget);

      final materialFinder = find.descendant(
        of: find.byType(DoubleBezelCard),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsOneWidget);

      final inkFinder = find.descendant(
        of: find.byType(DoubleBezelCard),
        matching: find.byType(Ink),
      );
      expect(inkFinder, findsOneWidget);
    });
  });

  group('AppTopBar Widget Tests', () {
    testWidgets('renders title, notifications, and theme toggle without search clutter',
        (tester) async {
      bool notifTapped = false;
      bool themeToggled = false;

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: AppTopBar(
                title: 'لوحة التحكم السريرية',
                onNotificationsTap: () => notifTapped = true,
                onThemeToggle: (_) => themeToggled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('لوحة التحكم السريرية'), findsOneWidget);

      // Verify no cluttered dead search box or fake status badge
      expect(find.text('نظام العيادة متصل'), findsNothing);
      expect(find.text('بحث عن مريض أو موعد...'), findsNothing);

      final notifButton = find.byIcon(Icons.notifications_none_rounded);
      expect(notifButton, findsOneWidget);
      await tester.tap(notifButton);
      await tester.pumpAndSettle();
      expect(notifTapped, isTrue);

      final themeButton = find.byIcon(Icons.dark_mode_outlined);
      expect(themeButton, findsOneWidget);
      await tester.tap(themeButton);
      await tester.pumpAndSettle();
      expect(themeToggled, isTrue);
    });

    testWidgets('renders cleanly on narrow desktop viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(920, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(64),
              child: AppTopBar(
                title: 'عيادة الدكتور عبد الرحمن الزهيري التخصصية',
                subtitle: 'إدارة الطابور والمواعيد اليومية',
                compact: false,
                actions: [
                  SizedBox(width: 140, child: Text('فرع المعادي الرئيسي')),
                ],
              ),
            ),
          ),
        ),
      );

      final ex = tester.takeException();
      if (ex != null) {
        print('FULL_EXCEPTION: ${(ex as dynamic).toStringDeep()}');
      }
      expect(ex, isNull);
      expect(find.text('عيادة الدكتور عبد الرحمن الزهيري التخصصية'), findsOneWidget);
    });

    testWidgets('renders compact top bar on mobile viewports',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(64),
              child: AppTopBar(
                title: 'عيادتي',
                compact: true,
              ),
            ),
          ),
        ),
      );

      final ex = tester.takeException();
      if (ex != null) {
        print('FULL_EXCEPTION: ${(ex as dynamic).toStringDeep()}');
      }
      expect(ex, isNull);
      expect(find.text('عيادتي'), findsOneWidget);
    });
  });

  group('AppointmentsCalendarStrip Widget Tests', () {
    testWidgets('renders cleanly on mobile viewport (375px) with selected long names without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testUser = UserModel(
        id: 'user_1',
        clinicId: 'clinic_1',
        role: UserRole.doctor,
        fullName: 'د. عبد الرحمن الزهيري التخصصية الاستشاري',
        isActive: true,
        isOwner: true,
        canDeleteAppointments: true,
        canViewReports: true,
        createdAt: DateTime.now(),
      );

      final doctors = [
        testUser,
        UserModel(
          id: 'user_2',
          clinicId: 'clinic_1',
          role: UserRole.doctor,
          fullName: 'د. سارة إبراهيم الشناوي الاستشارية',
          isActive: true,
          isOwner: false,
          canDeleteAppointments: false,
          canViewReports: false,
          createdAt: DateTime.now(),
        ),
      ];

      final branches = [
        BranchModel(
          id: 'branch_1',
          clinicId: 'clinic_1',
          name: 'فرع مدينة نصر التخصصي الرئيسي الدولي',
          isMain: true,
        ),
        BranchModel(
          id: 'branch_2',
          clinicId: 'clinic_1',
          name: 'فرع التجمع الخامس المركزي الحديث',
          isMain: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicDoctorsProvider('clinic_1').overrideWith((ref) => Future.value(doctors)),
            clinicBranchesProvider('clinic_1').overrideWith((ref) => Future.value(branches)),
            selectedDoctorFilterProvider.overrideWith((ref) => 'user_1'),
            selectedBranchFilterProvider.overrideWith((ref) => 'branch_1'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppointmentsCalendarStrip(
                selectedDate: DateTime(2026, 11, 4),
                user: testUser,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ex = tester.takeException();
      expect(ex, isNull, reason: 'Layout must not throw overflow exception on 375px mobile');
    });
  });

  group('PatientListCard Widget Tests', () {
    testWidgets('renders patient metadata and handles tap and action callbacks',
        (tester) async {
      bool tapped = false;
      bool booked = false;

      final mockPatient = PatientModel(
        id: 'patient_42',
        clinicId: 'clinic_1',
        fullName: 'سارة عبد الله أحمد',
        phone: '01099887766',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientListCard(
              patient: mockPatient,
              fileNo: 42,
              isSelected: false,
              onTap: () => tapped = true,
              onBookAppointment: () => booked = true,
              onEdit: () {},
              onDelete: () {},
              canDelete: true,
            ),
          ),
        ),
      );

      expect(find.text('Sara Abdullah Ahmed'), findsNothing);
      expect(find.text('سارة عبد الله أحمد'), findsOneWidget);
      expect(find.text('#42'), findsOneWidget);
      expect(find.text('01099887766'), findsOneWidget);

      await tester.tap(find.text('سارة عبد الله أحمد'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.add_task_rounded));
      await tester.pumpAndSettle();
      expect(booked, isTrue);
    });

    testWidgets('renders selected state with clinical highlight without throwing',
        (tester) async {
      final mockPatient = PatientModel(
        id: 'patient_99',
        clinicId: 'clinic_1',
        fullName: 'أحمد محمود',
        phone: '01122334455',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientListCard(
              patient: mockPatient,
              fileNo: 99,
              isSelected: true,
              onTap: () {},
              onBookAppointment: () {},
              onEdit: () {},
              onDelete: () {},
              canDelete: false,
            ),
          ),
        ),
      );

      expect(find.text('أحمد محمود'), findsOneWidget);
      expect(find.text('#99'), findsOneWidget);
      final ex = tester.takeException();
      if (ex != null) {
        print('FULL_EXCEPTION: ${(ex as dynamic).toStringDeep()}');
      }
      expect(ex, isNull);
    });
  });

  group('AppointmentsDesktopView Widget Tests', () {
    testWidgets('renders executive bento command deck, KPI pills, and rich empty state on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testUser = UserModel(
        id: 'user_doc_1',
        clinicId: 'clinic_test_1',
        role: UserRole.doctor,
        fullName: 'د. سامح عبد العزيز',
        isActive: true,
        isOwner: true,
        canDeleteAppointments: true,
        canViewReports: true,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clinicDoctorsProvider('clinic_test_1').overrideWith((ref) => Future.value([testUser])),
            clinicBranchesProvider('clinic_test_1').overrideWith((ref) => Future.value([])),
            selectedDateProvider.overrideWith((ref) => DateTime(2026, 11, 4)),
            todayAppointmentsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppointmentsDesktopView(
                user: testUser,
                appointmentsAsync: const AsyncValue.data([]),
                selectedDate: DateTime(2026, 11, 4),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify executive elements
      expect(find.text('حجز جديد'), findsOneWidget);
      expect(find.text('قائمة مدمجة'), findsOneWidget);
      expect(find.text('طابور المراحل'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('في الانتظار'), findsOneWidget);
      expect(find.text('مع الطبيب'), findsOneWidget);
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('ملغي'), findsOneWidget);

      // Verify rich interactive empty state
      expect(find.text('لا توجد مواعيد مسجلة لهذا اليوم'), findsOneWidget);
      expect(find.text('حجز موعد الآن'), findsOneWidget);
      final ex = tester.takeException();
      if (ex != null) {
        print('FULL_EXCEPTION: ${(ex as dynamic).toStringDeep()}');
      }
      expect(ex, isNull);
    });

    testWidgets('renders appointments list and switches between dense list and kanban view',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testUser = UserModel(
        id: 'user_doc_1',
        clinicId: 'clinic_test_1',
        role: UserRole.doctor,
        fullName: 'د. سامح عبد العزيز',
        isActive: true,
        isOwner: true,
        canDeleteAppointments: true,
        canViewReports: true,
        createdAt: DateTime.now(),
      );

      final patient = AppointmentPatient(
        fullName: 'طارق عبد المنعم الجوهري',
        phone: '01098765432',
      );

      final appt = AppointmentModel(
        id: 'appt_01',
        clinicId: 'clinic_test_1',
        patientId: 'patient_01',
        patient: patient,
        appointmentDate: DateTime(2026, 11, 4, 10, 30),
        status: 'confirmed',
        appointmentTypeName: 'كشف عام',
        doctorName: 'د. سامح عبد العزيز',
        priceCharged: 400,
        totalPaid: 400,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            clinicDoctorsProvider('clinic_test_1').overrideWith((ref) => Future.value([testUser])),
            clinicBranchesProvider('clinic_test_1').overrideWith((ref) => Future.value([])),
            selectedDateProvider.overrideWith((ref) => DateTime(2026, 11, 4)),
            todayAppointmentsProvider.overrideWith((ref) => Future.value([appt])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppointmentsDesktopView(
                user: testUser,
                appointmentsAsync: AsyncValue.data([appt]),
                selectedDate: DateTime(2026, 11, 4),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify patient in dense list
      expect(find.text('طارق عبد المنعم الجوهري'), findsOneWidget);
      expect(find.text('كشف'), findsOneWidget);

      // Switch to Kanban view
      await tester.tap(find.text('طابور المراحل'));
      await tester.pumpAndSettle();

      // Verify kanban lanes
      expect(find.text('طابور الانتظار'), findsOneWidget);
      expect(find.text('مع الطبيب'), findsAtLeastNWidgets(1));
      expect(find.text('مكتمل اليوم'), findsOneWidget);
      expect(find.text('ملغي / معتذر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows dual cancellation options in appointment menu and filters by cancelled',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testUser = UserModel(
        id: 'user_doc_1',
        clinicId: 'clinic_test_1',
        role: UserRole.doctor,
        fullName: 'د. سامح عبد العزيز',
        isActive: true,
        isOwner: true,
        canDeleteAppointments: true,
        canViewReports: true,
        createdAt: DateTime.now(),
      );

      final patient1 = AppointmentPatient(
          fullName: 'مريض قيد الانتظار', phone: '01011111111');
      final patient2 = AppointmentPatient(
          fullName: 'مريض ملغي من العيادة', phone: '01022222222');

      final appt1 = AppointmentModel(
        id: 'appt_1',
        clinicId: 'clinic_test_1',
        patientId: 'p_1',
        patient: patient1,
        appointmentDate: DateTime(2026, 11, 4, 11, 0),
        status: 'confirmed',
        totalPaid: 0.0,
      );

      final appt2 = AppointmentModel(
        id: 'appt_2',
        clinicId: 'clinic_test_1',
        patientId: 'p_2',
        patient: patient2,
        appointmentDate: DateTime(2026, 11, 4, 12, 0),
        status: 'cancelled_by_clinic',
        totalPaid: 0.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            clinicDoctorsProvider('clinic_test_1')
                .overrideWith((ref) => Future.value([testUser])),
            clinicBranchesProvider('clinic_test_1')
                .overrideWith((ref) => Future.value([])),
            selectedDateProvider.overrideWith((ref) => DateTime(2026, 11, 4)),
            todayAppointmentsProvider
                .overrideWith((ref) => Future.value([appt1, appt2])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppointmentsDesktopView(
                user: testUser,
                appointmentsAsync: AsyncValue.data([appt1, appt2]),
                selectedDate: DateTime(2026, 11, 4),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open menu on confirmed appointment card
      final moreIcon = find.byIcon(Icons.more_vert_rounded).first;
      await tester.tap(moreIcon);
      await tester.pumpAndSettle();

      // Verify dual cancellation options
      expect(find.text('إلغاء من العيادة'), findsOneWidget);
      expect(find.text('اعتذار من المريض'), findsOneWidget);

      // Dismiss menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Tap on 'ملغي' KPI tile to filter
      await tester.tap(find.text('ملغي'));
      await tester.pumpAndSettle();

      // Now only cancelled appointment is shown
      expect(find.text('مريض ملغي من العيادة'), findsOneWidget);
      expect(find.text('مريض قيد الانتظار'), findsNothing);
      final ex = tester.takeException();
      if (ex != null) {
        print('FULL_EXCEPTION: ${(ex as dynamic).toStringDeep()}');
      }
      expect(ex, isNull);
    });
  });
}
