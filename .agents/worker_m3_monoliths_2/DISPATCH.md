# Dispatch for Worker M3 (Replacement Gen 2): Feature Monolith Decomposition

## Scope & File Ownership
- Primary files owned:
  - `lib/src/features/settings/**`
  - `lib/src/features/patients/**`
  - `lib/src/features/appointments/**`
  - `lib/src/features/reports/**`
  - `lib/src/features/auth/**`

## Current Status & Objectives
1. Read `e:\SAAS\Clinic\.agents\ORIGINAL_REQUEST.md` and `e:\SAAS\Clinic\PROJECT.md`.
2. Notice that `lib/src/features/settings/presentation/subpages/` already contains several sub-pages extracted from `settings_screen.dart`. Complete the refactoring of `lib/src/features/settings/presentation/settings_screen.dart` so it is strictly LESS THAN 500 LOC (< 500 lines).
3. Decompose the remaining monolithic files:
   - Appointments: `book_appointment_dialog.dart` (1,618 LOC), `appointments_screen_parts.dart` (1,321 LOC), `edit_appointment_dialog.dart` (1,222 LOC), `queue_board.dart` (860 LOC) in `lib/src/features/appointments/presentation/`.
   - Patients: `patients_screen.dart` (1,410 LOC) and `patient_details_dialog.dart` (1,155 LOC) in `lib/src/features/patients/presentation/`.
   - Reports: `reports_screen_parts.dart` (1,544 LOC) and `report_detail_screen.dart` (1,152 LOC) in `lib/src/features/reports/presentation/`.
   - Auth: `register_screen.dart` (1,175 LOC) and `top_up_subscription_screen.dart` (892 LOC) in `lib/src/features/auth/presentation/`.
4. GLOBAL LINE LIMIT CONSTRAINT:
   - Ensure NO file anywhere in `lib/` exceeds 1000 lines of code.
   - Target < 400 lines for each file.
5. Verify with `flutter analyze` that there are 0 errors and 0 warnings.
6. Create `handoff.md` in `e:\SAAS\Clinic\.agents\worker_m3_monoliths_2\` detailing all refactored files and their line counts, and notify the orchestrator.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
