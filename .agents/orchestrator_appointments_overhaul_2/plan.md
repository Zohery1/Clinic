# Plan: Appointments & Booking UI Overhaul (Soft Structuralism)

## Objective
Overhaul the Appointments screen and Booking dialog in the Flutter Clinic application (`e:\SAAS\Clinic`) applying "Soft Structuralism" design principles.

## Milestones

### Phase 0: Survey & Codebase Exploration
- Spawn 3 parallel Explorers to investigate:
  1. Timeline & Queue widgets (`queue_card.dart`, `queue_timeline_row.dart`, `queue_board.dart`, `appointments_screen.dart`, etc.)
  2. Dialogs & Form inputs (`book_appointment_dialog.dart`, `edit_appointment_dialog.dart`, selector widgets, validation, CTA widgets)
  3. Design system & Theme integration (Theme tokens, colors, fonts, shadows, animation utilities, RTL Arabic support)
- Aggregate Explorer reports into `PROJECT.md` (Feature Inventory, Architecture, Interface Contracts, Code Layout).

### Milestone 1: Appointments Timeline & Queue Refactoring (R1)
- Double-Bezel aesthetic (outer shell + inner core).
- Macro-whitespace and staggered entry animations.
- Soft diffused ambient borders/shadows instead of harsh drop shadows.
- Worker -> Reviewers (2) -> Challengers (2) -> Forensic Auditor -> Gate.

### Milestone 2: Booking & Edit Dialogs Overhaul (R2)
- Clean, single-page floating sheets for `book_appointment_dialog.dart` and `edit_appointment_dialog.dart`.
- Replace all standard DropdownButtons with touch-friendly, horizontally scrollable selector pills (Doctors, Branches, Services).
- Primary CTA with Nested Button-in-Button architecture and magnetic hover simulation.
- Worker -> Reviewers (2) -> Challengers (2) -> Forensic Auditor -> Gate.

### Milestone 3: Integration, E2E Verification & Audit
- Run `flutter analyze` ensuring 0 errors/warnings on all modified files.
- Verify responsiveness across mobile, tablet, and web viewports without overflow.
- Final Reviewers, Challengers, and Forensic Auditor verification.
- Final synthesis and reporting.
