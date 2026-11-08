# Plan: Appointments & Booking UI Overhaul (Soft Structuralism)

## Objective
Complete high-end UI overhaul of the Appointments screen and Booking dialog in the Flutter application (`e:\SAAS\Clinic`), strictly applying "Soft Structuralism" design principles.

## Milestones

### Phase 0: Codebase Survey (3 Explorers)
- **Explorer 1 (Queue & Timeline)**: Analyze `queue_card.dart`, `queue_timeline_row.dart`, `queue_board.dart`, `appointments_screen.dart`, and related widgets. Map dependencies, data models, layout structures, animations, and current card styling.
- **Explorer 2 (Dialogs & Form Inputs)**: Analyze `book_appointment_dialog.dart`, `edit_appointment_dialog.dart`, existing DropdownButton usages, form validation, state management (Riverpod/controllers), and button actions.
- **Explorer 3 (Design Tokens & Animation System)**: Analyze theme tokens, color palettes, border radius conventions, micro-animations, staggered animation utilities, hover effects, and baseline `flutter analyze` status.
- Output: Merge findings into `PROJECT.md` and prepare implementation specs.

### Milestone 1: Appointments Timeline & Queue Refactoring (R1)
- Redesign `queue_card.dart`, `queue_timeline_row.dart`, and `queue_board.dart` using the "Double-Bezel" aesthetic (outer shell with soft ambient border + inner core with tactile background and clean padding).
- Introduce massive whitespace (macro-whitespace) between sections, rows, and cards.
- Implement staggered entry animations for queue cards with subtle vertical slide and opacity fade.
- Remove harsh shadows; introduce soft, diffused ambient borders and multi-layered subtle shadows (`Color.fromRGBO(0,0,0,0.04)`).
- Verification cycle: Worker -> Reviewers (2) -> Challengers (2) -> Forensic Auditor -> Gate.

### Milestone 2: Booking & Edit Dialogs Overhaul (R2)
- Refactor `book_appointment_dialog.dart` and `edit_appointment_dialog.dart` to be sleek, single-page floating sheets with clear section hierarchy.
- Replace all standard `DropdownButton` / `DropdownFormField` with touch-friendly, horizontally scrollable pills for selectors (Doctors, Branches, Services, Time slots).
- Update primary CTA to use "Nested Button-in-Button" architecture (outer tactile button with inner highlight/icon pill) and magnetic hover simulation.
- Verification cycle: Worker -> Reviewers (2) -> Challengers (2) -> Forensic Auditor -> Gate.

### Milestone 3: E2E Verification, Responsive Layout & Forensic Audit Gate
- Run `flutter analyze` ensuring 0 errors and 0 warnings across all modified and related files.
- Test responsive rendering across standard mobile viewports (e.g. 360px, 390px, 412px width) without pixel overflow.
- Run UI tests & behavioral verifications.
- Forensic Auditor integrity verification for zero hardcoding/facades.
- Final gate confirmation and handoff report synthesis.
