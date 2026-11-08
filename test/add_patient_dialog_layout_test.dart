import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:clinic_management/src/core/theme/app_theme.dart';
import 'package:clinic_management/src/features/patients/presentation/widgets/add_patient_dialog.dart';
import 'package:clinic_management/src/features/auth/presentation/login_controller.dart';
import 'package:clinic_management/src/features/auth/domain/user_model.dart';

/// Layout regression test for the AddPatientDialog footer.
///
/// Background: on the live web build the dialog rendered all six fields but a
/// blank footer strip — no 'إلغاء' / 'تسجيل وحفظ' buttons visible or
/// hit-testable. Root cause: `AppTheme`'s `elevatedButtonTheme` set
/// `minimumSize: Size(double.infinity, 46)`, and Row layouts give children
/// unbounded main-axis constraints, so the save button's width resolved to
/// Infinity (and sibling offsets degenerated to NaN): the row reserved the
/// height but nothing painted or hit-tested.
///
/// This test pumps the REAL AppTheme (the original test used a bare
/// MaterialApp with default themes and therefore passed while prod broke),
/// opens the dialog through showDialog, and asserts:
///   1. both action buttons exist and are inside the dialog viewport;
///   2. their rendered widths are REAL numbers (not Infinity/NaN).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });

  final container = ProviderContainer(overrides: [
    currentUserProvider.overrideWith((ref) => UserModel(
          id: 'u1',
          clinicId: 'clinic_test',
          role: UserRole.doctor,
          fullName: 'د. اختبار',
          isActive: true,
          canDeleteAppointments: true,
          canViewReports: true,
          canEditServices: true,
          canViewMedicalHistory: true,
          canEditMedicalNotes: true,
          canCancelAppointments: true,
          createdAt: DateTime(2025),
        )),
  ]);

  tearDown(() => container.dispose());

  testWidgets('AddPatientDialog footer buttons render with the real AppTheme',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1140, 880);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: Container()),
        ),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    unawaitedFuture(
      showDialog<void>(
        context: context,
        builder: (_) => UncontrolledProviderScope(
          container: container,
          child: const AddPatientDialog(clinicId: 'clinic_test'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('تسجيل مريض جديد'), findsOneWidget);
    expect(find.text('تسجيل وحفظ'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);

    final saveRect = tester.getRect(find.byType(ElevatedButton).first);
    expect(saveRect.height, greaterThan(30));
    expect(saveRect.width.isFinite, isTrue,
        reason: 'save button width must be finite (min-width=infinity bug)');
    expect(saveRect.width, greaterThan(60));
    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.contains(saveRect.center), isTrue);
  });

  testWidgets('ElevatedButton keeps finite width inside an unbounded Row under the real AppTheme',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Row(
              children: [
                const ElevatedButton(onPressed: null, child: Text('x')),
                TextButton(onPressed: () {}, child: const Text('y')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Renders without a flex-overflow/infinity exception and lands finite.
    final rect = tester.getRect(find.byType(ElevatedButton));
    expect(rect.width.isFinite, isTrue);
    expect(rect.width, greaterThan(0));
  });
}

void unawaitedFuture(Future<void> f) {}
