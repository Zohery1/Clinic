## 2026-08-29T01:48:29Z

Task to audit:
High-end UI overhaul of the Appointments screen and Booking dialog in Flutter application (e:\SAAS\Clinic), applying "Soft Structuralism" design principles.

Requirements to verify:
1. R1. Refactor Appointments Timeline & Queue:
   - Redesign queue_card.dart, queue_timeline_row.dart, and queue_board.dart to use the "Double-Bezel" aesthetic.
   - Introduce massive whitespace (macro-whitespace) and staggered entry animations for cards.
   - Remove harsh shadows and replace with soft, diffused ambient borders/shadows.
2. R2. Overhaul Booking & Edit Dialogs:
   - Refactor book_appointment_dialog.dart and edit_appointment_dialog.dart to be clean, single-page floating sheets.
   - Replace standard Dropdowns with touch-friendly, horizontally scrollable pills for selectors (Doctors, Branches, Services).
   - Update the primary CTA to use the "Nested Button-in-Button" architecture with magnetic hover simulation.

Acceptance Criteria:
- No standard DropdownButton remains in the booking dialog.
- All appointment cards implement a nested container structure (outer shell + inner core).
- Code builds without errors (flutter analyze returns 0 issues in modified files).
- The app renders correctly without overflowing pixels on standard mobile screen sizes.
