## 2026-08-29T01:08:31Z
You are WORKER 2: Booking & Edit Dialogs Overhaul.
Your working directory is: e:\SAAS\Clinic\.agents\worker_dialogs_selectors_4
The project root is: e:\SAAS\Clinic

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

First, read:
- e:\SAAS\Clinic\.agents\ORIGINAL_REQUEST.md
- e:\SAAS\Clinic\PROJECT.md
- e:\SAAS\Clinic\.agents\explorer_dialogs_survey_3\handoff.md

Your exclusive write ownership:
- lib/src/core/widgets/magnetic_nested_button.dart
- lib/src/features/appointments/presentation/widgets/appointment_doctor_branch_picker.dart
- lib/src/features/appointments/presentation/widgets/appointment_type_picker.dart
- lib/src/features/appointments/presentation/widgets/appointment_time_picker.dart
- lib/src/features/appointments/presentation/widgets/appointments_calendar_strip.dart
- lib/src/features/appointments/presentation/book_appointment_dialog.dart
- lib/src/features/appointments/presentation/edit_appointment_dialog.dart

Key Tasks:
1. Implement `magnetic_nested_button.dart`:
   - "Button-in-Button" CTA architecture (outer pill shell 52px + inner action capsule 36x36px).
   - Micro-spinner loading transition in action capsule.
   - Magnetic hover translation on desktop/web (pointer tracking with clamped offset) + spring tap feedback on mobile.
2. Eliminate ALL `DropdownButton` and `DropdownButtonFormField` across the booking/edit dialogs and calendar strip:
   - In `appointment_doctor_branch_picker.dart`: replace dropdowns with touch-friendly, horizontally scrollable tactile pills for Doctors (avatar capsule + name + active glow) and Branches (icon + branch name).
   - In `appointments_calendar_strip.dart`: replace dropdowns with tactile filter pills or modal sheets.
3. Refactor `appointment_type_picker.dart` with tactile card chips and price badges.
4. Refactor `appointment_time_picker.dart` with soft time slot pills and custom time picker action.
5. Refactor `book_appointment_dialog.dart` and `edit_appointment_dialog.dart`:
   - Single-page floating sheets with 28-32px border radius, backdrop blur, double-bezel styling.
   - Clean 4-section layout with generous spacing and nested primary CTA.
6. Preserve ALL business logic: form validation, patient picker, service selection, repository mutations (`bookAppointment`, `updateAppointment`), 9 Riverpod provider invalidations, and realtime notifications.
7. Run `flutter analyze` using terminal command and ensure 0 issues in modified files.
8. Write comprehensive `handoff.md` and update `progress.md` in your working directory, then call send_message to report to parent.
