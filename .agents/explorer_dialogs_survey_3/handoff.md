# Soft Structuralism Dialogs & Selectors Survey — Handoff Report

**Working Directory**: `e:\SAAS\Clinic\.agents\explorer_dialogs_survey_3`  
**Target Files Analyzed**:
- `lib/src/features/appointments/presentation/book_appointment_dialog.dart`
- `lib/src/features/appointments/presentation/edit_appointment_dialog.dart`
- `lib/src/features/appointments/presentation/widgets/appointment_doctor_branch_picker.dart`
- `lib/src/features/appointments/presentation/widgets/appointment_patient_picker.dart`
- `lib/src/features/appointments/presentation/widgets/appointment_type_picker.dart`
- `lib/src/features/appointments/presentation/widgets/appointment_time_picker.dart`
- `lib/src/features/appointments/presentation/widgets/appointment_services_picker.dart`
- `lib/src/features/appointments/presentation/widgets/appointments_calendar_strip.dart`
- `lib/src/features/appointments/presentation/visit_notes_dialog.dart`
- `lib/src/features/appointments/presentation/widgets/admission_confirmation_sheet.dart`
- `lib/src/core/widgets/clinic_dialog.dart`
- `lib/src/core/widgets/double_bezel_card.dart`
- `lib/src/core/theme/app_theme.dart`
- `lib/src/core/theme/app_motion.dart`

---

## 1. Observation

Direct observation of current implementation files, lines, and components:

### 1.1 Booking Dialog (`book_appointment_dialog.dart`)
- **Location**: Lines 20–321.
- **Architecture**: `ConsumerStatefulWidget` (`BookAppointmentDialog`).
- **Form State**:
  - `_selectedPatientId` (String?)
  - `_selectedDoctorId` (String?)
  - `_selectedBranchId` (String?)
  - `_selectedAppointmentTypeId` (String?)
  - `_basePrice` (double)
  - `_selectedServices` (List<ServiceModel>)
  - `_selectedDate` (DateTime, default `now()`)
  - `_selectedTime` (TimeOfDay, default `18:00`)
  - `_isSaving` (bool)
- **Container Structure**: Wrapped in `ClinicDialog` (`maxWidth: 580`), standard Dialog shape (`RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`).
- **Sub-widgets Used**:
  - `AppointmentPatientPicker` (Line 167)
  - `AppointmentDoctorBranchPicker` (Line 180)
  - `AppointmentTypePicker` (Line 190)
  - Date Picker Container with `showDatePicker` (Lines 202–253)
  - `AppointmentTimePicker` (Line 257)
  - `AppointmentServicesPicker` (Line 265)
  - Total Price summary card (Lines 278–301)
- **Data Mutation & Pipeline**:
  - Invokes `appointmentRepositoryProvider.bookAppointment(...)` (Lines 87–96).
  - Invalidates 9 Riverpod providers: `todayAppointmentsProvider`, `appointmentsForDateProvider`, `todayRevenueProvider`, `monthRevenueProvider`, `weeklyRevenueProvider`, `sixWeeksRevenueProvider`, `monthlyStatsProvider`, `dailyStatsProvider`, `detailedReportProvider` (Lines 98–106).
  - Triggers realtime broadcast notification via `notificationsProvider.notifier.sendBroadcastNotification(...)` (Lines 108–117).

### 1.2 Edit Dialog (`edit_appointment_dialog.dart`)
- **Location**: Lines 18–327.
- **Architecture**: `ConsumerStatefulWidget` (`EditAppointmentDialog`) taking `clinicId` and `appointment` (`AppointmentModel`).
- **State Initialization**: Populates initial values from `widget.appointment` and loads existing services via `appointmentRepositoryProvider.getAppointmentServices(widget.appointment.id)` (Lines 58–81).
- **Sub-widgets Used**: Mirrors `BookAppointmentDialog` with `AppointmentDoctorBranchPicker`, `AppointmentTypePicker`, Date Picker, `AppointmentTimePicker` (with current appointment filtered out from collision highlight), and `AppointmentServicesPicker`.
- **Data Mutation & Pipeline**:
  - Invokes `appointmentRepositoryProvider.updateAppointment(...)` (Lines 102–112).
  - Invalidates the same 9 Riverpod providers and broadcasts notification.

### 1.3 Dropdown Usages Identified for Elimination
- **`appointment_doctor_branch_picker.dart`**:
  - **Doctor Selector**: `DropdownButtonFormField<String?>` (Lines 49–74). Items: `null` ("بدون طبيب محدد") + doctor list.
  - **Branch Selector**: `DropdownButtonFormField<String?>` (Lines 99–124). Items: `null` ("الفرع الافتراضي") + branch list.
- **`appointments_calendar_strip.dart`**:
  - **Doctor Filter**: `DropdownButton<String?>` (Lines 48–74).
  - **Branch Filter**: `DropdownButton<String?>` (Lines 99–125).

### 1.4 Other Selector Components
- **`appointment_type_picker.dart`** (Lines 40–59): Uses standard Material `Wrap` + `ChoiceChip`.
- **`appointment_time_picker.dart`** (Lines 106–165): Fixed height 120px container with 4-column `GridView.builder` rendering 45 text slots + `showTimePicker` button.
- **`appointment_services_picker.dart`** (Lines 133–158): `Wrap` + `FilterChip` + custom service dialog modal.
- **`appointment_patient_picker.dart`** (Lines 291–386): `Autocomplete<PatientModel>` with `fieldViewBuilder` + quick registration modal `_showAddPatientDialog`.

---

## 2. Logic Chain & Technical Transformation Blueprint

```
Current Architecture                        Target: "Soft Structuralism" Blueprint
┌──────────────────────────────┐            ┌─────────────────────────────────────────┐
│ Standard ClinicDialog        │            │ Single-Page Floating Sheet (Responsive) │
│ - BorderRadius: 16           │            │ - BorderRadius: 28-32                   │
│ - Flat single border         │  ────────> │ - Dual-Bezel outer/inner shell          │
│ - Standard elevation shadow  │            │ - Ambient backdrop blur (sigma: 12)     │
│                              │            │ - Smooth BouncingScrollPhysics          │
└──────────────────────────────┘            └─────────────────────────────────────────┘

┌──────────────────────────────┐            ┌─────────────────────────────────────────┐
│ DropdownButtonFormField      │            │ Tactile Horizontally Scrollable Pills   │
│ - Popover menu list          │  ────────> │ - Doctor avatar + Name + Active Glow    │
│ - Hidden options on tap      │            │ - Branch icon + Name pill strip         │
│ - Clunky mobile ergonomics   │            │ - Horizontal ribbon with RTL physics    │
└──────────────────────────────┘            └─────────────────────────────────────────┘

┌──────────────────────────────┐            ┌─────────────────────────────────────────┐
│ Standard ClinicPrimaryButton │            │ Nested "Button-in-Button" + Magnetic    │
│ - Flat ElevatedButton        │  ────────> │ - Outer pill shell (52px, gradient, amb)│
│ - Basic text + icon          │            │ - Inner action pill (36px, contrast)    │
│ - No hover physics           │            │ - Magnetic cursor translation (Desktop) │
└──────────────────────────────┘            └─────────────────────────────────────────┘
```

### 2.1 Elimination of Dropdowns & Tactile Pill Selector Specs

#### A. Doctor Selector (`AppointmentDoctorBranchPicker` / New `DoctorPillSelector`)
1. **Data Source**: `ref.watch(clinicDoctorsProvider(clinicId))`.
2. **Layout**: Horizontal scrollable pill strip (`SingleChildScrollView(scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics())`).
3. **Pill Anatomy**:
   - **Avatar Capsule**: Circle avatar (24x24) with doctor initial or doctor color tint (`AppTheme.doctorColor(doctor.id)`).
   - **Text**: `د. ${doctor.fullName}` (or `بدون طبيب محدد` for null).
   - **Active State**:
     - Background: `AppColors.primaryLight` (or `primary.withValues(alpha: 0.15)`).
     - Border: `1.5px solid AppColors.primary`.
     - Text: Bold Cairo, `AppColors.primary`.
     - Ambient Shadow: `BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 6, offset: Offset(0, 2))`.
   - **Inactive State**:
     - Background: `AppColors.surfaceDimLight` (dark: `AppColors.surfaceDimDark`).
     - Border: `1px solid AppColors.borderLight` (dark: `AppColors.borderDark`).
     - Text: Muted text primary / secondary.

#### B. Branch Selector (New `BranchPillSelector`)
1. **Data Source**: `ref.watch(clinicBranchesProvider(clinicId))`.
2. **Layout**: Horizontal scrollable pill strip or wrap.
3. **Pill Anatomy**:
   - **Prefix Icon**: `Icons.location_on_outlined` or `Icons.storefront_outlined`.
   - **Text**: Branch name (or `الفرع الافتراضي` for null).
   - **Active/Inactive Styling**: Same dual-state contrast matching Doctor selector.

#### C. Appointment Type Selector
1. **Data Source**: `ref.watch(appointmentTypesProvider)`.
2. **Pill Anatomy**: Tactile card chip with integrated price badge pill:
   - Left side: `${type.name}`.
   - Right side nested pill: `${type.price.toStringAsFixed(0)} ج.م`.
   - Active state has primary stroke and soft glow.

#### D. Time Slot Selector (`AppointmentTimePicker`)
1. **Data Source**: Categorized / filtered time slots (الصباح / المساء / الليل) or horizontal slot ribbon.
2. **Slot Status Pill**:
   - **Available**: Soft surface pill, `12px` font, clickable.
   - **Selected**: Highlighted primary pill with white bold text and glow.
   - **Booked**: Disabled pill with muted strikethrough or error tint ("محجوز").
3. **Custom Time Action**: Tactile icon pill `وقت مخصص` invoking `showTimePicker`.

---

### 2.2 Floating Sheet Layout & Container Styling Specs

1. **Responsive Modal Container**:
   - **Desktop/Tablet (>650px)**:
     - `maxWidth: 600`, `maxHeight: 88vh`.
     - Outer Bezel: `padding: 3px`, `borderRadius: BorderRadius.circular(30)`, background `Colors.black.withValues(alpha: 0.03)` (dark: `Colors.white.withValues(alpha: 0.05)`).
     - Inner Core: `borderRadius: BorderRadius.circular(27)`, surface background, soft diffused shadow `BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 36, offset: Offset(0, 14))`.
     - Backdrop: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))` with `Colors.black.withValues(alpha: 0.35)`.
   - **Mobile (<650px)**:
     - Floating bottom sheet with top drag handle indicator (`width: 44, height: 4, borderRadius: 2`).
     - `borderRadius: BorderRadius.vertical(top: Radius.circular(28))`.
     - Edge-to-edge padding discipline (`horizontal: 16, vertical: 16`).

2. **Header & Section Hierarchy**:
   - **Header**: Outer soft icon capsule (42x42, `borderRadius: 14`) + Dual-line title/subtitle (`حجز موعد جديد` / `أدخل بيانات الموعد`) + Circular close button.
   - **Visual Chunking (4 Sections)**:
     - **Section 1**: المريض والعيادة (Patient search + Doctor pills + Branch pills).
     - **Section 2**: تفاصيل الموعد (Type chips + Date tactile card + Time slot ribbon).
     - **Section 3**: الخدمات الطبية الإضافية (Filter pills + custom service action).
     - **Section 4**: ملخص التكلفة والتأكيد (Double-bezel calculation card + Nested CTA).

3. **Validation Error Display**:
   - Inline soft warning banner / pill instead of harsh raw snackbars:
     - Container `color: AppColors.errorLight`, border `1px solid AppColors.error.withValues(alpha: 0.2)`.
     - Icon `Icons.info_outline_rounded, color: AppColors.error`.
     - Animated opacity with `AnimatedCrossFade` or `AnimatedSwitcher`.

---

### 2.3 Nested Primary CTA Button & Magnetic Hover Architecture

#### A. "Nested Button-in-Button" Structure
```
┌─────────────────────────────────────────────────────────────────┐
│ Outer Tactile Pill (Height: 52px, Radius: 26px)                │
│ Background: Primary Gradient [0xFF1A73E8 -> 0xFF1557B0]         │
│ Shadow: BoxShadow(color: 0x591A73E8, blurRadius: 16, y: 6)     │
│ ┌──────────────────────┐               ┌──────────────────────┐ │
│ │ Nested Action Pill   │               │ Button Label         │ │
│ │ 36x36, Radius: 18px  │               │ "تأكيد الحجز"        │ │
│ │ Color: White/20%     │               │ Cairo Bold 14.5px    │ │
│ │ Icon: Check / Arrow  │               │ Color: White         │ │
│ └──────────────────────┘               └──────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```
- When `isLoading == true`: The nested action pill smoothly transitions into a white micro circular progress indicator (`strokeWidth: 2.2`), while label updates to `جاري الحفظ...`.

#### B. Magnetic Hover Simulation (Desktop/Web) & Touch Fallback
```dart
class MagneticNestedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  // ...
}

class _MagneticNestedButtonState extends State<MagneticNestedButton> {
  Offset _magneticOffset = Offset.zero;
  bool _isHovered = false;
  bool _isPressed = false;

  void _onHover(PointerHoverEvent event, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = event.localPosition - center;
    // Calculate magnetic pull (clamped to max 5px translation)
    setState(() {
      _magneticOffset = Offset(
        (delta.dx / size.width * 8).clamp(-5.0, 5.0),
        (delta.dy / size.height * 8).clamp(-4.0, 4.0),
      );
    });
  }

  // Touch fallback: Scale 0.97 on pointer down, 1.0 on pointer up
  // Desktop: Scale 1.02 on hover + magnetic offset translate
}
```

---

### 2.4 State Management & Data Consistency (Zero Regression Guarantee)

| Layer | Component | Verification / Integrity Points |
|---|---|---|
| **Repository** | `AppointmentRepository` | Exact signature maintained: `bookAppointment`, `updateAppointment`, `getAppointmentServices`, `getAppointmentsByDate`. |
| **Validation** | Form & Date Constraints | `_formKey.currentState!.validate()`, patient selection check (`_selectedPatientId != null`), date/time past-validation check. |
| **Providers** | 9 Cached Providers | Invalidation sequence preserved: `todayAppointmentsProvider`, `appointmentsForDateProvider`, `todayRevenueProvider`, `monthRevenueProvider`, `weeklyRevenueProvider`, `sixWeeksRevenueProvider`, `monthlyStatsProvider`, `dailyStatsProvider`, `detailedReportProvider`. |
| **Realtime** | Notifications | Broadcast notification sent via `notificationsProvider.notifier.sendBroadcastNotification`. |
| **Supabase** | UTC Conversion | Date conversion `toUtc().toIso8601String()` handled safely at repository boundary. |

---

## 3. Caveats

1. **Horizontal Pill Scrolling inside Vertical Dialog Scroll**:
   - Ensure horizontal pill strips do not capture vertical scroll gestures. Standard Flutter `SingleChildScrollView(scrollDirection: Axis.horizontal)` works seamlessly if parent uses `SingleChildScrollView(scrollDirection: Axis.vertical)`.
2. **Web Mouse Hover vs Touch**:
   - `MouseRegion` must be guarded so mobile touch events only trigger `onTapDown` / `onTapUp` tactile bounce without phantom hover state locks.
3. **Empty Data Fallbacks**:
   - If a clinic has no extra doctors or branches registered, the selector should default to single pill (`الفرع الافتراضي` / `بدون طبيب محدد`) without breaking horizontal layout.
4. **RTL Directionality**:
   - All horizontal pill streams must respect RTL flow (`Directionality(textDirection: TextDirection.rtl)`).

---

## 4. Conclusion

The Appointment Booking & Edit dialogs in `lib/src/features/appointments/presentation/` are cleanly decoupled and ready for the Soft Structuralism upgrade:
1. **Dropdown Elimination**: All 4 DropdownButton instances (Doctor & Branch in dialogs, Doctor & Branch in calendar strip) can be eliminated and replaced with tactile horizontal pill selectors.
2. **Floating Sheet Layout**: The dialog container will be upgraded to a responsive dual-bezel floating modal with frosted backdrop blur and smooth form section grouping.
3. **Nested CTA Button**: The primary CTA will implement the "Nested Button-in-Button" architecture with magnetic cursor hover simulation on web/desktop and micro-spring touch response on mobile.
4. **Zero Regression**: Complete alignment with existing Riverpod providers, Supabase service queries, and validation rules.

---

## 5. Verification Method

To verify the implementation independently:

1. **Static Analysis**:
   ```bash
   flutter analyze lib/src/features/appointments/
   ```
   Must return 0 errors and 0 warnings.

2. **UI Inspection Checklist**:
   - [ ] Verify `book_appointment_dialog.dart` and `edit_appointment_dialog.dart` contain **zero** `DropdownButton` or `DropdownButtonFormField`.
   - [ ] Verify Doctor and Branch selectors render as horizontal scrollable pill strips.
   - [ ] Verify dialog container has rounded corners (28-32px) and ambient diffused shadow.
   - [ ] Verify primary button uses Nested Button-in-Button structure (outer pill + inner action pill).
   - [ ] Verify hover on web/desktop triggers magnetic cursor pull and scale.
   - [ ] Test on mobile viewport (<650px) to verify bottom floating sheet adaptation and no overflow errors.

3. **Functional Regression Test**:
   - [ ] Book a new appointment with selected doctor, branch, type, time slot, and extra services.
   - [ ] Verify appointment appears in today's list and correct price is calculated.
   - [ ] Open Edit dialog on the created appointment, modify time and services, verify successful update.
