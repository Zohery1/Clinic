# Dispatch for Worker M3 (Replacement Gen 3): Feature Monolith Decomposition

## Scope & File Ownership
- Primary files owned:
  - `lib/src/features/settings/**`
  - `lib/src/features/patients/**`
  - `lib/src/features/appointments/**`
  - `lib/src/features/reports/**`
  - `lib/src/features/auth/**`

## Current Status & Objectives
1. Read `e:\SAAS\Clinic\.agents\ORIGINAL_REQUEST.md` and `e:\SAAS\Clinic\PROJECT.md`.
2. Notice the existing extracted modular widgets in:
   - `lib/src/features/settings/presentation/subpages/`
   - `lib/src/features/appointments/presentation/widgets/`
   - `lib/src/features/patients/presentation/widgets/`
3. Finalize modularization across all target monoliths:
   - **Settings**: Ensure `lib/src/features/settings/presentation/settings_screen.dart` is clean and strictly LESS THAN 500 LOC (< 500 lines).
   - **Appointments**: Ensure `book_appointment_dialog.dart`, `appointments_screen_parts.dart`, `edit_appointment_dialog.dart`, and `queue_board.dart` are decomposed and each file is strictly < 1000 LOC (target < 400 LOC).
   - **Patients**: Ensure `patients_screen.dart` and `patient_details_dialog.dart` are decomposed and each file is strictly < 1000 LOC (target < 400 LOC).
   - **Reports**: Decompose `reports_screen_parts.dart` and `report_detail_screen.dart` into `lib/src/features/reports/presentation/widgets/` so each file is strictly < 1000 LOC (target < 400 LOC).
   - **Auth**: Decompose `register_screen.dart` and `top_up_subscription_screen.dart` into `lib/src/features/auth/presentation/widgets/` so each file is strictly < 1000 LOC (target < 400 LOC).
4. GLOBAL LINE LIMIT CONSTRAINT:
   - Ensure NO file anywhere in `lib/` exceeds 1000 lines of code.
   - Target < 400 lines for each file.
5. Verify with `flutter analyze` that there are 0 errors and 0 warnings across the entire project.
6. Verify with `flutter test` that the 4-tier test suite passes.
7. Create `handoff.md` in `e:\SAAS\Clinic\.agents\worker_m3_monoliths_3\` detailing all refactored files and their line counts, and notify the orchestrator via `send_message`.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
