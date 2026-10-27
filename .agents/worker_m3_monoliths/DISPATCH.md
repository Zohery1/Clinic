# Dispatch for Worker M3: Feature Monolith Decomposition

## Scope & File Ownership
- Primary files owned:
  - `lib/src/features/settings/**`
  - `lib/src/features/patients/**`
  - `lib/src/features/appointments/**`
  - `lib/src/features/reports/**`
  - `lib/src/features/auth/**`

## Objectives
1. Read `e:\SAAS\Clinic\.agents\ORIGINAL_REQUEST.md` and `e:\SAAS\Clinic\PROJECT.md`.
2. Decompose Monolithic Files:
   - `lib/src/features/settings/presentation/settings_screen.dart` (currently 2,891 LOC):
     - Extract sub-sections and dialogs into dedicated sub-widgets/sub-pages in `lib/src/features/settings/presentation/widgets/` or `subpages/`.
     - Ensure `settings_screen.dart` is clean and strictly LESS THAN 500 LOC (< 500 lines).
   - `lib/src/features/appointments/`:
     - Decompose `book_appointment_dialog.dart` (1,618 LOC), `appointments_screen_parts.dart` (1,321 LOC), `edit_appointment_dialog.dart` (1,222 LOC), `queue_board.dart` (860 LOC) into clean modular components in `lib/src/features/appointments/presentation/widgets/` or `dialogs/`.
   - `lib/src/features/patients/`:
     - Decompose `patients_screen.dart` (1,410 LOC) and `patient_details_dialog.dart` (1,155 LOC) into modular widgets in `lib/src/features/patients/presentation/widgets/`.
   - `lib/src/features/reports/`:
     - Decompose/eliminate `reports_screen_parts.dart` (1,544 LOC) and `report_detail_screen.dart` (1,152 LOC) into modular widgets.
   - `lib/src/features/auth/`:
     - Decompose `register_screen.dart` (1,175 LOC) and `top_up_subscription_screen.dart` (892 LOC) into modular components.
3. GLOBAL LINE LIMIT CONSTRAINT:
   - Ensure NO file anywhere in `lib/` exceeds 1000 lines of code.
   - Target < 400 lines for each file.
4. Verify with `flutter analyze` that there are 0 errors and 0 warnings.
5. Create `handoff.md` in `e:\SAAS\Clinic\.agents\worker_m3_monoliths\` detailing all refactored files and their line counts.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
