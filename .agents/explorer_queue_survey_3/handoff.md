# Handoff Report: Appointments Queue & Timeline Survey (Explorer 1)

## 1. Observation

### 1.1 Target Files & Architectural Locations
Direct filesystem and static analysis identified the following files governing the Queue & Timeline experience:

| File Path | Role | Lines | Key Widget / Class |
|---|---|---|---|
| `lib/src/features/appointments/presentation/widgets/queue_card.dart` | Kanban/Lane Queue Card | 682 | `QueueCard`, `_PrimaryButton`, `_SecondaryButton`, `_DangerIconButton` |
| `lib/src/features/appointments/presentation/widgets/queue_timeline_row.dart` | Desktop Timeline Row Item | 543 | `QueueTimelineRow` |
| `lib/src/features/appointments/presentation/widgets/queue_board.dart` | Desktop Queue Board & List View | 136 | `QueueBoard` |
| `lib/src/features/appointments/presentation/widgets/queue_board_header.dart` | Queue Board Header & Filters | 218 | `QueueBoardHeader` |
| `lib/src/features/appointments/presentation/widgets/appointment_card_item.dart` | Mobile Appointment Card | 414 | `AppointmentCardItem` |
| `lib/src/features/appointments/presentation/widgets/appointments_mobile_view.dart` | Mobile View Host Screen | 240 | `AppointmentsMobileView` |
| `lib/src/features/appointments/presentation/widgets/appointments_desktop_view.dart` | Desktop View Host Screen | 46 | `AppointmentsDesktopView` |
| `lib/src/features/appointments/presentation/widgets/appointments_calendar_strip.dart` | 7-day strip + Doctor/Branch Filters | 289 | `AppointmentsCalendarStrip` |
| `lib/src/features/appointments/presentation/widgets/admission_confirmation_sheet.dart` | Bottom sheet status confirmation | 207 | `AdmissionConfirmationSheet` |
| `lib/src/features/appointments/presentation/widgets/queue_lane_type.dart` | Queue Lane Enum | 2 | `enum QueueLaneType { waiting, withDoctor, completed, cancelled }` |
| `lib/src/features/appointments/presentation/appointments_controller.dart` | Riverpod State Providers | 114 | `todayAppointmentsProvider`, `selectedDateProvider`, `dashboardFilterProvider`, etc. |
| `lib/src/features/appointments/domain/appointment_model.dart` | Core Data Model | 174 | `AppointmentModel`, `AppointmentPatient` |
| `lib/src/core/widgets/double_bezel_card.dart` | Core Double-Bezel Component | 63 | `DoubleBezelCard` |
| `lib/src/core/theme/app_theme.dart` | Design Tokens & Theme | 541 | `AppColors`, `AppTheme`, `AppSpacing` |
| `lib/src/core/theme/app_motion.dart` | Motion & Timing Tokens | 10 | `AppMotion` (`fast: 150ms`, `normal: 250ms`, `curve: Curves.easeOutCubic`) |

---

### 1.2 Direct UI Observations in Existing Widgets

#### A. `queue_card.dart`
- **Container Nesting & Decoration** (`queue_card.dart:42-64`):
  ```dart
  Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: laneType == QueueLaneType.withDoctor 
              ? const Color(0xFF3B82F6).withValues(alpha: 0.04) 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: laneType == QueueLaneType.withDoctor 
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.12) 
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
  ```
- **Observations**:
  1. Single-layer container with a 12px radius, no outer shell/inner core separation.
  2. Bottom margin is only `8px` — dense and lacking macro-whitespace.
  3. Action buttons (`_PrimaryButton`, `_SecondaryButton`, `_DangerIconButton` at lines 577-681) use hardcoded 8px radii, flat rectangular fills without tactile bezel depth.
  4. Status badges (`_buildQueuePositionBadge`, `_buildStatusIcon` lines 281-328) use rigid 36x36px boxes with 8px radius.
  5. Absence of entrance animations when cards load or change lane.

#### B. `queue_timeline_row.dart`
- **Container Structure** (`queue_timeline_row.dart:289-296`):
  ```dart
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: appt.status == 'pending'
          ? theme.colorScheme.primary.withValues(alpha: 0.02)
          : null,
    ),
    child: Row(
      children: [
        // 1. وقت الحجز (width: 80)
        // 2. المريض وبياناته (flex: 3)
        // 3. نوع الزيارة (flex: 2)
        // 4. الدفعة المالية (flex: 2)
        // 5. حالة الموعد (flex: 2)
        // 6. الإجراءات السياقية (width: 150)
      ],
    ),
  );
  ```
- **Observations**:
  1. In `queue_board.dart:120`, the separator is only `const SizedBox(height: 4)`. Rows are presented as raw table cells without card-level structural separation.
  2. No outer ambient border, no double-bezel elevation, no tactile container.
  3. The action buttons (`ElevatedButton.icon`, `OutlinedButton.icon` at lines 152-242) use sharp 6px borders and rigid paddings (`horizontal: 10, vertical: 6`).
  4. Status badge (lines 513-528) is a plain container with `color.withValues(alpha: 0.12)` and 20px radius.

#### C. `appointment_card_item.dart`
- **Container Structure** (`appointment_card_item.dart:127-154`):
  ```dart
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appointment.status == 'pending'
                  ? const Color(0xFF1A73E8).withValues(alpha: 0.3)
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: appointment.status == 'pending' ? 1.5 : 1,
            ),
          ),
  ```
- **Observations**:
  1. Simple 16px single-border container with harsh drop border on active state.
  2. Lacks double-bezel depth, diffused ambient lighting, and staggered entry motion.

#### D. `queue_board_header.dart` & `queue_board.dart`
- **Filter Chips** (`queue_board_header.dart:89-107`):
  ```dart
  ChoiceChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (selected) { ... },
    selectedColor: chipColor.withValues(alpha: 0.1),
    backgroundColor: theme.colorScheme.surface,
    side: BorderSide(color: chipColor.withValues(alpha: isSelected ? 1.0 : 0.5), width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    showCheckmark: false,
  )
  ```
- **Observations**:
  1. Uses standard Flutter `ChoiceChip` with a standard 8px radius and 1.5px border outline.
  2. Table header strip (`queue_board_header.dart:200-214`) is a plain flat strip with 12px vertical padding.

---

### 1.3 State Management & Data Flow Observations
- **`todayAppointmentsProvider`** (`appointments_controller.dart:43-55`): Fetches `List<AppointmentModel>` for `selectedDateProvider`, taking into account `selectedDoctorFilterProvider` and `selectedBranchFilterProvider`.
- **`dashboardFilterProvider`** (`appointments_controller.dart:68`): Holds filter state (`'confirmed'`, `'pending'`, `'completed'`, `'cancelled'`, or `'all'`).
- **`realtimeAppointmentsSyncProvider`** (`appointments_controller.dart:71-101`): Listens on Supabase channel `realtime:appointments:<clinicId>` with a 500ms debounce timer to trigger `invalidateAppointmentsAndReports(ref)`.
- **Status Enum Values**:
  - `'confirmed'`: In waiting queue (الانتظار).
  - `'pending'`: With doctor / in examination (مع الطبيب).
  - `'completed'`: Finished examination (منتهي).
  - `'cancelled'`, `'cancelled_by_patient'`, `'cancelled_by_clinic'`: Cancelled (ملغي).
- **Mutations & Realtime Notifications**:
  - Updating status calls `ref.read(appointmentRepositoryProvider).updateAppointmentStatus(id, status)`.
  - Dispatches broadcast notifications via `ref.read(notificationsProvider.notifier).sendBroadcastNotification(...)`.
  - Permission checks via `currentUserProvider` (`canCancelAppointments`, `canViewMedicalHistory`, `role == UserRole.doctor`).

---

## 2. Logic Chain

1. **Premise 1**: The "Soft Structuralism" design philosophy requires:
   - **Double-Bezel Architecture**: An outer shell with soft ambient border (outer radius 20–28px, 2–3px outer padding, alpha 0.02–0.05 border) and an elevated inner core with tactile background and clean inner padding (16–20px).
   - **Macro-Whitespace**: Generous vertical and horizontal breathing room (e.g. 14–18px between cards/rows, 20–24px outer board margins).
   - **Diffused Ambient Shadows**: Replacing harsh single-direction shadows with dual-layer micro-shadows (a sharp 1px ambient rim + a diffused 8–16px ambient depth).
   - **Staggered Entry Motion**: 60fps staggered entrance animations for queue cards and timeline rows.

2. **Premise 2 (Current Gap)**:
   - `queue_card.dart` has only a single 12px container with 8px margin and flat 20px blur shadow.
   - `queue_timeline_row.dart` is rendered inside a flat `ListView.separated` with `SizedBox(height: 4)`, causing items to look like a cramped spreadsheet rather than a modern clinic command center.
   - `appointment_card_item.dart` is a single 16px container with a 1px/1.5px border.
   - `queue_board_header.dart` relies on raw Material `ChoiceChip` with harsh 1.5px borders instead of tactile pill selectors.

3. **Premise 3 (Riverpod & Functional Safety)**:
   - All appointment actions (Admit to Doctor, Complete Examination, Cancel, WhatsApp dialogue, Open Examination Screen, Patient Details Dialog, Edit Dialog) depend on `AppointmentModel`, `ref.watch(currentUserProvider)`, `appointmentRepositoryProvider`, and `invalidateAppointmentsAndReports(ref)`.
   - Modifying the visual presentation layer while retaining widget inputs (`appointment`, `clinicId`, `isDoctor`, `queuePosition`, `withDoctorCount`) guarantees 100% preservation of business logic and real-time syncing.

4. **Inference / Solution Blueprint**:
   - **Step A (`DoubleBezelCard` Integration & Adaptation)**:
     Refactor `QueueCard`, `AppointmentCardItem`, and `QueueTimelineRow` to use the Double-Bezel architecture.
   - **Step B (Macro-Whitespace)**:
     Increase spacing in `queue_board.dart` from `4px` to `12px-14px` between timeline cards, and in `appointments_mobile_view.dart` from `12px` to `16px`.
   - **Step C (Staggered Animation Helper)**:
     Create a clean, lightweight staggered animation wrapper (e.g., `StaggeredSlideFade`) using `TweenAnimationBuilder` or an indexed `AnimationController` that delivers smooth 200–300ms staggered entrances with `Curves.easeOutCubic` without introducing heavy external package dependencies.
   - **Step D (Header & Filter Pill Overhaul)**:
     Redesign `QueueBoardHeader` chips into tactile floating filter pills with badge counters and soft status halos.
   - **Step E (Action Buttons Redesign)**:
     Replace raw buttons with tactile nested action buttons with micro-scale interactive feedback and distinct semantic status colors.

---

## 3. Detailed Structural Mapping & Implementation Plan

### 3.1 Component Architecture Map

```
lib/src/features/appointments/
├── domain/
│   ├── appointment_model.dart            [Data model - Keep intact]
│   ├── appointment_service_model.dart    [Services join model - Keep intact]
│   └── appointment_type_model.dart       [Types model - Keep intact]
├── presentation/
│   ├── appointments_controller.dart      [Riverpod state & realtime sync - Keep intact]
│   ├── appointments_screen.dart          [Responsive router (Desktop vs Mobile) - Enhance container]
│   ├── examination_screen.dart           [Doctor examination session - Keep functional]
│   ├── patient_queue_tracking_screen.dart[Patient queue screen - Keep functional]
│   └── widgets/
│       ├── queue_board.dart              ──> [Macro-whitespace + Staggered ListView + Outer Bezel Frame]
│       ├── queue_board_header.dart       ──> [Soft Structuralism Filter Pills + Tactile CTA]
│       ├── queue_timeline_row.dart       ──> [Double-Bezel Timeline Card + Tactile Badges + Actions]
│       ├── queue_card.dart               ──> [Double-Bezel Queue Card + Queue Number Glow + Tactile Actions]
│       ├── appointment_card_item.dart    ──> [Double-Bezel Mobile Card + Soft Status Badges]
│       ├── appointments_calendar_strip.dart -> [Double-Bezel 7-day Strip + Tactile Day Bubble + Custom Dropdowns]
│       ├── appointments_desktop_view.dart──> [Clean Spacing + QueueBoard host]
│       ├── appointments_mobile_view.dart ──> [Macro-whitespace + Double-Bezel Stat Cards + Filter Pills]
│       ├── admission_confirmation_sheet.dart -> [Soft Structuralism Bottom Sheet with Tactile CTAs]
│       └── queue_lane_type.dart          [Enum - Keep intact]
```

---

### 3.2 Detailed Design Specs for Implementation

#### 1. Double-Bezel Specification for Queue Widgets

| Token / Layer | Light Mode | Dark Mode | Radii & Spacing |
|---|---|---|---|
| **Outer Bezel Background** | `Colors.black.withValues(alpha: 0.02)` / `0xFFF1F5F9` | `Colors.white.withValues(alpha: 0.03)` / `0xFF151E2E` | `outerRadius: 22.0` (Cards), `18.0` (Rows) |
| **Outer Bezel Border** | `Colors.black.withValues(alpha: 0.04)` / `0xFFE2E8F0` | `Colors.white.withValues(alpha: 0.06)` / `0xFF334155` | `width: 1.0` |
| **Outer Padding** | `const EdgeInsets.all(2.5)` | `const EdgeInsets.all(2.5)` | Creates the tactile recessed lip |
| **Inner Core Background** | `AppColors.surfaceLight` (`0xFFFFFFFF`) | `AppColors.surfaceDark` (`0xFF1E293B`) | `innerRadius: outerRadius - 2.5` |
| **Inner Core Shadow 1 (Rim)** | `BoxShadow(color: Colors.white, offset: Offset(0, 1), blurRadius: 1)` | `BoxShadow(color: Colors.white.withValues(alpha: 0.05), offset: Offset(0, 1), blurRadius: 1)` | Micro-top highlight |
| **Inner Core Shadow 2 (Ambient)**| `BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: Offset(0, 4), blurRadius: 12)` | `BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: Offset(0, 4), blurRadius: 16)` | Diffused depth |
| **Active / In-Exam Glow** | `BoxShadow(color: Color(0xFF1A73E8).withValues(alpha: 0.08), blurRadius: 16, offset: Offset(0, 2))` | `BoxShadow(color: Color(0xFF1A73E8).withValues(alpha: 0.15), blurRadius: 20, offset: Offset(0, 2))` | Applied when `status == 'pending'` |

#### 2. Macro-Whitespace Specification

- **Timeline Row Spacing (`queue_board.dart`)**:
  - Replace `separatorBuilder: (_, __) => const SizedBox(height: 4)` with `separatorBuilder: (_, __) => const SizedBox(height: 12)`.
  - Outer `ListView` padding: `padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)`.
- **Mobile Cards Spacing (`appointments_mobile_view.dart`)**:
  - Increase item bottom padding from `12px` to `16px`.
  - Screen edge margins: `16px` horizontal, `16px` vertical.
- **Queue Card Spacing (`queue_card.dart`)**:
  - Replace `padding: const EdgeInsets.only(bottom: 8)` with `padding: const EdgeInsets.only(bottom: 14)`.

#### 3. Staggered Entry Animation Specification

- Implement a reusable lightweight animation wrapper:
  ```dart
  class StaggeredCardEntry extends StatelessWidget {
    final int index;
    final Widget child;
    final Duration baseDuration;
    final Duration itemDelay;

    const StaggeredCardEntry({
      super.key,
      required this.index,
      required this.child,
      this.baseDuration = const Duration(milliseconds: 280),
      this.itemDelay = const Duration(milliseconds: 40),
    });

    @override
    Widget build(BuildContext context) {
      final totalDelayMs = (index.clamp(0, 10) * itemDelay.inMilliseconds);
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: baseDuration + Duration(milliseconds: totalDelayMs),
        curve: AppMotion.curve,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          );
        },
        child: child,
      );
    }
  }
  ```
- **Benefits**: Zero external package dependencies, automatic disposal, runs at 60fps across Flutter Web, Mobile, and Desktop.

#### 4. Status Indicator & Badge System

- **Waiting (`confirmed`)**: Amber tint (`#F59E0B`), tactile queue badge with mono font (`JetBrains Mono`, w800).
- **With Doctor / In Examination (`pending`)**: Medical clean blue (`#1A73E8`), soft ambient glow, glowing active indicator dot.
- **Completed (`completed`)**: Emerald green (`#10B981`), checkmark icon badge, clear paid amount badge.
- **Cancelled (`cancelled_*`)**: Rose/Red tint (`#EF4444`), dimmed opacity (0.7), strike-through or muted text.

---

## 4. Caveats

1. **Pre-existing Doctor & Branch Dropdowns in `appointments_calendar_strip.dart`**:
   - `AppointmentsCalendarStrip` currently uses standard `DropdownButtonHideUnderline` for Doctor/Branch selection (lines 47-130).
   - *Recommendation*: While Builder 2 or subsequent tasks overhaul dialog dropdowns into horizontal pills, `AppointmentsCalendarStrip`'s dropdowns should be wrapped in tactile pill containers or replaced with horizontal scrolling pills for complete consistency.
2. **Web Performance & Repaint Boundaries**:
   - For long appointment lists (e.g. >50 appointments on a busy clinic day), ensure `StaggeredCardEntry` clamps index multiplier to 10–12 items max to avoid late-scrolled items having unnecessary delays.
3. **No Database Schema or API Changes**:
   - All changes are strictly UI/UX frontend enhancements; no database migrations or Supabase RPC alterations are needed.

---

## 5. Conclusion

The Appointments Queue & Timeline architecture is cleanly separated into presentation widgets, data models, and Riverpod controllers. The transition to "Soft Structuralism" can be achieved without breaking any business logic or real-time event handlers.

The 4 primary implementation deliverables for the Builder are:
1. **`queue_card.dart` & `appointment_card_item.dart`**: Implement `DoubleBezelCard` outer shell + inner core, layered micro-shadows, tactile status avatars, and nested action buttons.
2. **`queue_timeline_row.dart` & `queue_board.dart`**: Convert flat table rows into independent Double-Bezel timeline row cards, expand vertical gap to 12–14px (macro-whitespace), and add subtle column headers.
3. **`queue_board_header.dart`**: Upgrade filter chips into soft tactile filter pills with count badges and smooth active indicators.
4. **Staggered Animations**: Integrate lightweight index-based slide-fade animations across all queue and timeline lists.

---

## 6. Verification Method

To independently verify the architecture and subsequent implementation:

1. **Static Analysis & Lint Verification**:
   ```powershell
   flutter analyze lib/src/features/appointments/
   ```
   *Expected result: 0 errors, 0 warnings.*

2. **Web Build Verification**:
   ```powershell
   flutter build web --no-tree-shake-icons
   ```
   *Expected result: Successful compilation without type errors or deprecation warnings.*

3. **Visual & Behavioral Checks**:
   - Inspect `queue_board.dart` on desktop (>900px width) to verify 12px macro-whitespace between double-bezel timeline cards.
   - Inspect `appointments_mobile_view.dart` on mobile viewport (<600px width) to verify responsive Double-Bezel appointment cards with smooth staggered entry.
   - Test changing appointment status (Waiting -> With Doctor -> Completed) to verify that `AdmissionConfirmationSheet`, toast messages, notifications, and Riverpod invalidations execute reliably.
