# Plan: Appointments & Booking UI Overhaul (Soft Structuralism)

## Objective
Implement high-end UI overhaul of the Appointments screen, Queue Board/Timeline, and Booking/Edit Dialogs in the Flutter Clinic app (`e:\SAAS\Clinic`) applying "Soft Structuralism" design principles.

## Milestones & Execution Steps

### Milestone 1: Appointments Timeline & Queue Refactor (R1)
- **Target Files**:
  - `lib/src/core/widgets/staggered_card_entry.dart` (New lightweight motion wrapper)
  - `lib/src/core/widgets/double_bezel_card.dart` (Check & refine double-bezel container)
  - `lib/src/features/appointments/presentation/widgets/queue_card.dart` (Double-bezel, nested tactile actions, glow)
  - `lib/src/features/appointments/presentation/widgets/queue_timeline_row.dart` (Double-bezel row card, status badges, macro-whitespace)
  - `lib/src/features/appointments/presentation/widgets/queue_board.dart` (12-14px spacing, outer frame)
  - `lib/src/features/appointments/presentation/widgets/queue_board_header.dart` (Soft tactile filter pills)
  - `lib/src/features/appointments/presentation/widgets/appointment_card_item.dart` (Double-bezel mobile card)
  - `lib/src/features/appointments/presentation/widgets/appointments_mobile_view.dart` (16px spacing, macro-whitespace)
- **Verification**: `flutter analyze` 0 issues, visual inspection and build confirmation.

### Milestone 2: Booking & Edit Dialogs Overhaul (R2)
- **Target Files**:
  - `lib/src/core/widgets/magnetic_nested_button.dart` (New Nested Button-in-Button with magnetic hover simulation)
  - `lib/src/features/appointments/presentation/widgets/appointment_doctor_branch_picker.dart` (Eliminate DropdownButton, implement horizontal pill selectors)
  - `lib/src/features/appointments/presentation/widgets/appointment_type_picker.dart` (Tactile chips with price badges)
  - `lib/src/features/appointments/presentation/widgets/appointment_time_picker.dart` (Refined slot pills & custom time action)
  - `lib/src/features/appointments/presentation/widgets/appointments_calendar_strip.dart` (Eliminate dropdown filters, replace with tactile pills/dialogs)
  - `lib/src/features/appointments/presentation/book_appointment_dialog.dart` (Single-page floating sheet, double-bezel container, nested CTA)
  - `lib/src/features/appointments/presentation/edit_appointment_dialog.dart` (Single-page floating sheet, double-bezel container, nested CTA)
- **Verification**: `flutter analyze` 0 issues, verify 0 DropdownButton in booking/edit dialogs.

### Milestone 3: Review, Challenger Stress Verification & Forensic Integrity Audit
- **Review**: Spawn Reviewers to check design token consistency, mobile responsiveness, RTL alignment, and Dart analyzer output.
- **Challenger**: Spawn Challengers to stress test viewport sizes (360px-1920px), null doctors/branches data states, and long patient names.
- **Forensic Audit**: Spawn `teamwork_preview_auditor` for static analysis, integrity forensics, verifying authentic Riverpod and Supabase integration with zero dummy facades or hardcoded bypasses.
- **Gate Check**: Ensure strict AND satisfaction across all criteria before reporting completion.
