# Original User Request

## 2026-08-28T13:19:59Z

<USER_REQUEST>
Complete UI overhaul of a Flutter Clinic management application to transition it from a prototype to a polished, real-world product. The app runs on mobile, tablet, and web.

Working directory: `e:\SAAS\Clinic`
Integrity mode: development

## Requirements

### R1. Restructure and Simplify Navigation
- Implement a persistent Bottom Navigation Bar across all platforms (Mobile, Tablet, Web) and remove any existing sidebars or top headers.
- The 5 tabs must be: الرئيسية (Dashboard), المواعيد (Appointments), المرضى (Patients), التقارير (Reports - owner only), الإعدادات (Settings).

### R2. Refactor Massive Files into Smaller Components
- Break down monolithic files (`settings_screen.dart`, `book_appointment_dialog.dart`, `reports_screen_parts.dart`, `patients_screen.dart`, `appointments_screen_parts.dart`, `dashboard_screen.dart`) into logical, smaller files within their respective feature folders.

### R3. Implement a Consistent Design System
- Use the "Calm Medical Clean" aesthetic (white + primary blue `#1A73E8` + generous spacing).
- Support both Light and Dark modes.
- Create and use shared core widgets in `lib/src/core/widgets/` (e.g., `AppCard`, `AppEmptyState`, `AppListTile`).
- Ensure large, readable cards for appointments and patients, and clear, friendly Empty States for lists without data.
- You may use open-source snippets or external Flutter packages if they improve quality and speed.

### R4. Simplify Arabic Copy
- Use everyday, simple Arabic instead of formal terms (e.g., "المرضى" instead of "إدارة المرضى", "حجز جديد" instead of "إضافة موعد جديد").

## Acceptance Criteria

### Verification
- [ ] `flutter analyze` runs with 0 errors and 0 warnings.
- [ ] The app compiles and runs successfully on Flutter Web (`flutter build web`).
- [ ] The `settings_screen.dart` file is less than 500 lines of code.
- [ ] The `dashboard_screen.dart` file no longer contains sidebar code and uses a BottomNavigationBar.
- [ ] No file in the project exceeds 1000 lines of code.
- [ ] The app visually matches the "Calm Medical Clean" aesthetic.
</USER_REQUEST>

## 2026-08-28T22:19:27Z

<USER_REQUEST>
# Teamwork Project Prompt — Draft

> Status: Launched
> Goal: Craft prompt → get user approval → delegate to teamwork_preview
> Requested team: [none — teamwork routes from the description]

Complete high-end UI overhaul of the Appointments screen and Booking dialog in a Flutter application, applying "Soft Structuralism" design principles.

Working directory: `e:\SAAS\Clinic`

## Requirements

### R1. Refactor Appointments Timeline & Queue
- Redesign `queue_card.dart`, `queue_timeline_row.dart`, and `queue_board.dart` to use the "Double-Bezel" aesthetic.
- Introduce massive whitespace (macro-whitespace) and staggered entry animations for cards.
- Remove harsh shadows and replace with soft, diffused ambient borders/shadows.

### R2. Overhaul Booking & Edit Dialogs
- Refactor `book_appointment_dialog.dart` and `edit_appointment_dialog.dart` to be clean, single-page floating sheets.
- Replace standard Dropdowns with touch-friendly, horizontally scrollable pills for selectors (Doctors, Branches, Services).
- Update the primary CTA to use the "Nested Button-in-Button" architecture with magnetic hover simulation.

## Acceptance Criteria

### UI Quality Check
- [ ] No standard `DropdownButton` remains in the booking dialog.
- [ ] All appointment cards implement a nested container structure (outer shell + inner core).
- [ ] Code builds without errors (`flutter analyze` returns 0 issues in modified files).
- [ ] The app renders correctly without overflowing pixels on standard mobile screen sizes.
</USER_REQUEST>
