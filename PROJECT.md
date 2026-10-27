# Project: Appointments & Booking UI Overhaul (Soft Structuralism)

## Architecture
- **Framework**: Flutter (Mobile, Tablet, Web) with Riverpod (`flutter_riverpod: ^2.5.1`)
- **Backend & Realtime**: Supabase Flutter SDK (`supabase_flutter: ^2.6.0`) with realtime broadcast notifications
- **Design Philosophy**: "Soft Structuralism"
  - **Double-Bezel**: Outer shell with 1px subtle ambient border (`Colors.black.withValues(alpha: 0.04)` / dark: `Colors.white.withValues(alpha: 0.06)`), 2.5px outer padding, and elevated inner core (`AppColors.surfaceLight` / `AppColors.surfaceDark`).
  - **Macro-Whitespace**: Generous vertical and horizontal breathing room (12–16px between cards/rows).
  - **Diffused Ambient Shadows**: Multi-layered soft shadows (`offset: Offset(0, 4), blurRadius: 12, color: Colors.black.withValues(alpha: 0.03)`).
  - **Staggered Animations**: Lightweight `StaggeredCardEntry` using `TweenAnimationBuilder` and `Curves.easeOutCubic`.
  - **Tactile Horizontal Pills**: Replacing standard dropdowns with horizontally scrollable pill selectors (Doctors, Branches, Services).
  - **Nested CTA Architecture**: "Button-in-Button" with outer gradient container + inner high-contrast action pill and magnetic cursor pull on web/desktop.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Double-Bezel Appointments Cards | Outer shell + inner core for queue cards, mobile appointment cards, and timeline rows | M1 | Survey / R1 |
| 2 | Macro-Whitespace Spacing | 12-16px vertical gap between timeline rows and queue items | M1 | Survey / R1 |
| 3 | Staggered Entry Motion | Lightweight `StaggeredCardEntry` slide-fade entrance animation | M1 | Survey / R1 |
| 4 | Soft Ambient Borders & Shadows | Diffused multi-layer ambient shadows replacing harsh drop shadows | M1 | Survey / R1 |
| 5 | Dropdown Elimination | Replace all DropdownButton / DropdownFormField with horizontal scrollable selector pills | M2 | Survey / R2 |
| 6 | Single-Page Floating Sheet | Refactor `book_appointment_dialog.dart` and `edit_appointment_dialog.dart` into responsive sheets (28-32px radius) | M2 | Survey / R2 |
| 7 | Nested CTA with Magnetic Hover | "Button-in-Button" CTA with magnetic cursor hover simulation | M2 | Survey / R2 |
| 8 | Static Analysis & Zero Issues | `flutter analyze` returns 0 issues across all modified files | M3 | Acceptance |
| 9 | Mobile Responsive Verification | Verify zero pixel overflow on standard mobile viewports (360px-412px) | M3 | Acceptance |
| 10 | Forensic Integrity Verification | Zero hardcoded test values or dummy facades; full Riverpod & Supabase integration | M3 | Audit |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Refactor Appointments Timeline & Queue (R1) | `queue_card.dart`, `queue_timeline_row.dart`, `queue_board.dart`, `appointment_card_item.dart`, `appointments_mobile_view.dart`, `appointments_calendar_strip.dart` | none | IN_PROGRESS |
| 2 | Overhaul Booking & Edit Dialogs (R2) | `book_appointment_dialog.dart`, `edit_appointment_dialog.dart`, `appointment_doctor_branch_picker.dart`, `appointment_type_picker.dart`, `appointment_time_picker.dart`, nested CTA widget | M1 | PLANNED |
| 3 | Integration, Responsive Verification & Forensic Audit | `flutter analyze` 0 issues, mobile layout tests, challenger stress checks, forensic audit gate | M1, M2 | PLANNED |

## Interface Contracts

### Double-Bezel Card Contract
- `DoubleBezelCard(child, {outerRadius: 22.0, innerRadius: 19.5, outerPadding: 2.5, borderColor, ambientShadow, innerColor, padding})`
- Outer Container: subtle border, translucent bezel background (`Colors.black.withValues(alpha: 0.02)` / dark: `Colors.white.withValues(alpha: 0.03)`).
- Inner Core: elevated surface with dual ambient micro-shadows (`Offset(0, 1), blurRadius: 1` top rim + `Offset(0, 4), blurRadius: 12` ambient depth).

### Selector Pills Contract
- `DoctorPillSelector(selectedDoctorId, onSelected, {clinicId, enabled})`: Horizontal scrollable strip of doctor pills with avatar capsule and active primary glow.
- `BranchPillSelector(selectedBranchId, onSelected, {clinicId, enabled})`: Horizontal scrollable strip of branch pills with location icon.
- `ServicePillSelector(selectedServices, onToggle, {clinicId})`: Tactile horizontal filter chips with price indicator.

### Nested CTA Button Contract
- `MagneticNestedButton(label, icon, {onPressed, isLoading, primaryColor, magneticRadius})`:
  - Outer Tactile Pill: 52px height, 26px radius, primary gradient, ambient glow.
  - Inner Action Pill: 36x36px, 18px radius, white translucent capsule holding icon or micro-spinner.
  - Magnetic Hover: desktop/web pointer movement pulls button up to 5px toward cursor; mobile provides spring scale feedback (0.97).

## Code Layout
```
lib/src/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_spacing.dart
│   │   └── app_motion.dart
│   └── widgets/
│       ├── double_bezel_card.dart
│       ├── magnetic_nested_button.dart
│       ├── staggered_card_entry.dart
│       ├── app_card.dart
│       ├── app_empty_state.dart
│       └── app_status_badge.dart
└── features/
    └── appointments/
        ├── domain/
        │   ├── appointment_model.dart
        │   ├── appointment_service_model.dart
        │   └── appointment_type_model.dart
        ├── data/
        │   └── appointment_repository.dart
        └── presentation/
            ├── appointments_controller.dart
            ├── appointments_screen.dart
            ├── book_appointment_dialog.dart
            ├── edit_appointment_dialog.dart
            └── widgets/
                ├── queue_board.dart
                ├── queue_board_header.dart
                ├── queue_timeline_row.dart
                ├── queue_card.dart
                ├── appointment_card_item.dart
                ├── appointments_mobile_view.dart
                ├── appointments_desktop_view.dart
                ├── appointments_calendar_strip.dart
                ├── appointment_doctor_branch_picker.dart
                ├── appointment_type_picker.dart
                ├── appointment_time_picker.dart
                ├── appointment_services_picker.dart
                └── admission_confirmation_sheet.dart
```
