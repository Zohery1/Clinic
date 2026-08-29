# Monolithic Files & Code Decomposition Architecture Report

## 1. Observation

A full code audit and line-count analysis of all Dart source files in `lib/` was conducted.

### 1.1 Complete Line Count Inventory of All Dart Files
```
Path                                                                                 Lines
----------------------------------------------------------------------------------   -----
lib\src\features\settings\presentation\settings_screen.dart                           2891
lib\src\features\appointments\presentation\book_appointment_dialog.dart               1618
lib\src\features\reports\presentation\reports_screen_parts.dart                       1544
lib\src\features\patients\presentation\patients_screen.dart                           1410
lib\src\features\appointments\presentation\appointments_screen_parts.dart             1321
lib\src\features\appointments\presentation\edit_appointment_dialog.dart               1222
lib\src\features\auth\presentation\register_screen.dart                               1175
lib\src\features\patients\presentation\patient_details_dialog.dart                    1155
lib\src\features\reports\presentation\report_detail_screen.dart                       1152
lib\src\features\dashboard\presentation\dashboard_screen.dart                          946
lib\src\features\auth\presentation\top_up_subscription_screen.dart                     892
lib\src\features\appointments\presentation\widgets\queue_board.dart                    860
lib\src\features\clinics\presentation\widgets\clinic_switcher_button.dart              728
lib\src\features\settings\presentation\clinic_branches_page.dart                       665
lib\src\features\appointments\presentation\widgets\queue_card.dart                     648
lib\src\features\appointments\presentation\visit_notes_dialog.dart                     611
lib\src\features\reports\data\reports_repository.dart                                  597
lib\src\features\settings\data\whatsapp_service.dart                                   588
lib\src\core\widgets\clinic_dialog.dart                                                557
lib\src\features\appointments\presentation\patient_queue_tracking_screen.dart          555
lib\src\features\auth\presentation\reset_password_screen.dart                          499
lib\src\features\appointments\presentation\examination_screen.dart                     490
lib\src\features\appointments\presentation\widgets\patient_medical_sidebar.dart        479
lib\src\features\auth\presentation\subscription_status_sheet.dart                      442
lib\src\core\theme\app_theme.dart                                                      426
lib\src\features\dashboard\presentation\financial_panel.dart                           406
lib\main.dart                                                                          396
lib\src\core\widgets\send_whatsapp_dialog.dart                                         379
lib\src\features\patients\presentation\widgets\add_patient_dialog.dart                 345
lib\src\features\auth\presentation\pending_activation_screen.dart                      343
lib\src\features\appointments\data\appointment_repository.dart                         341
lib\src\features\auth\presentation\verify_otp_screen.dart                              322
lib\src\features\patients\presentation\widgets\edit_patient_dialog.dart                307
lib\src\features\auth\data\auth_repository.dart                                        300
lib\src\features\auth\presentation\join_clinic_screen.dart                             297
lib\src\features\auth\presentation\login_screen.dart                                   278
lib\src\features\reports\presentation\reports_screen.dart                              277
lib\src\features\auth\presentation\account_blocked_screen.dart                         265
lib\src\features\appointments\presentation\widgets\examination_form.dart               253
lib\src\features\clinics\presentation\clinics_controller.dart                          245
lib\src\features\patients\data\patient_repository.dart                                 218
lib\src\features\auth\presentation\login_controller.dart                               208
lib\src\features\appointments\presentation\widgets\admission_confirmation_sheet.dart   199
lib\src\features\auth\presentation\subscription_gate_screen.dart                       194
lib\src\features\clinics\presentation\widgets\join_clinic_dialog.dart                  188
lib\src\features\clinics\presentation\widgets\create_clinic_dialog.dart                182
lib\src\features\reports\presentation\reports_controller.dart                          174
lib\src\features\dashboard\presentation\notifications_controller.dart                  173
lib\src\features\appointments\domain\appointment_model.dart                            160
lib\src\features\clinics\data\clinics_repository.dart                                  154
lib\src\features\auth\domain\user_model.dart                                           131
lib\src\features\auth\presentation\subscription_warning_banner.dart                    115
lib\src\core\widgets\state_views.dart                                                  112
lib\src\features\appointments\presentation\appointments_controller.dart                100
lib\src\features\appointments\presentation\appointments_screen.dart                     89
lib\src\features\appointments\data\visit_note_repository.dart                           81
lib\src\core\utils\invite_utils.dart                                                    74
lib\src\features\clinics\domain\clinic_summary_model.dart                               71
lib\src\features\clinics\domain\branch_model.dart                                       66
lib\src\core\widgets\doctor_badge.dart                                                  64
lib\src\core\widgets\clinic_toast.dart                                                  63
lib\src\features\patients\domain\patient_model.dart                                     61
lib\src\features\dashboard\domain\notification_model.dart                               59
lib\src\core\utils\arabic_utils.dart                                                    52
lib\src\features\appointments\domain\visit_note_model.dart                              48
lib\src\core\theme\theme_provider.dart                                                  40
lib\src\features\appointments\domain\appointment_service_model.dart                     37
lib\src\core\widgets\status_pill.dart                                                   30
lib\src\core\utils\app_logger.dart                                                      29
lib\src\features\appointments\domain\appointment_type_model.dart                        29
lib\src\features\appointments\domain\service_model.dart                                 29
lib\src\core\constants\app_spacing.dart                                                 26
lib\src\features\reports\domain\financial_report_model.dart                             21
lib\src\core\constants\supabase_config.dart                                             11
lib\src\core\theme\app_motion.dart                                                       8
```

### 1.2 Monolith Classification & Issue Matrix
1. **Critical Monoliths (> 1,000 LOC)**:
   - `lib\src\features\settings\presentation\settings_screen.dart` (2,891 LOC) — embeds 5 full sub-pages (`ClinicDetailsPage`, `StaffPermissionsPage`, `ThemeSettingsPage`, `ServicesConfigPage`, `WhatsAppAutomationPage`), 3 state providers, and multiple dialogs into one massive file.
   - `lib\src\features\appointments\presentation\book_appointment_dialog.dart` (1,618 LOC) — mixes patient lookup, doctor/branch selection, slot calculation grids, service multi-select, and payment calculations in a single widget.
   - `lib\src\features\reports\presentation\reports_screen_parts.dart` (1,544 LOC) — `part of` file with huge custom date picker (456 lines), revenue charts, and daily/monthly tables.
   - `lib\src\features\patients\presentation\patients_screen.dart` (1,410 LOC) — mixes search debouncing, master-detail desktop split, appointment timeline, and inline widget classes (`_PatientListCard`, `_PatientAvatar`, `_TimelineAppointmentCard`).
   - `lib\src\features\appointments\presentation\appointments_screen_parts.dart` (1,321 LOC) — `part of` file holding notifications modal (195 lines), calendar strip, filter chips, revenue summary, and mobile appointment lists.
   - `lib\src\features\appointments\presentation\edit_appointment_dialog.dart` (1,222 LOC) — duplicate appointment booking logic and forms.
   - `lib\src\features\auth\presentation\register_screen.dart` (1,175 LOC) — 4-step wizard combining account info, role selection, clinic creation (with multiple branch inputs), and clinic joining in a single file.
   - `lib\src\features\patients\presentation\patient_details_dialog.dart` (1,155 LOC) — patient details dialog combining patient header, timeline, visit notes, and services history.
   - `lib\src\features\reports\presentation\report_detail_screen.dart` (1,152 LOC) — comprehensive reporting screen mixing KPI cards, pie charts, patient breakdown, and peak hours charts.
2. **Major Monoliths (600–1,000 LOC)**:
   - `lib\src\features\dashboard\presentation\dashboard_screen.dart` (946 LOC) — contains desktop sidebar (`_buildSidebar`, 224 lines) and desktop top header (`_buildTopHeader`, 325 lines) which violate Requirement R1 (sidebar removal and persistent 5-tab Bottom Navigation Bar).
   - `lib\src\features\auth\presentation\top_up_subscription_screen.dart` (892 LOC) — combines plan tiers, manual payment methods (Vodafone Cash / InstaPay), slip confirmation, and contact modals.
   - `lib\src\features\appointments\presentation\widgets\queue_board.dart` (860 LOC) — embeds status transition handlers, timeline row widget, action buttons, and cancel/admission bottom sheets.
   - `lib\src\features\clinics\presentation\widgets\clinic_switcher_button.dart` (728 LOC) — embeds modal bottom sheet with clinic management list, join clinic modal, and create clinic modal.
   - `lib\src\features\settings\presentation\clinic_branches_page.dart` (665 LOC) — branch CRUD and modal dialogs.
   - `lib\src\features\appointments\presentation\widgets\queue_card.dart` (648 LOC) — patient queue card and menu actions.
   - `lib\src\features\appointments\presentation\visit_notes_dialog.dart` (611 LOC) — consultation notes, vitals entry, and prescription editing.

---

## 2. Logic Chain & Detailed Decomposition Plan

To satisfy acceptance criteria:
1. `settings_screen.dart` MUST be `< 500 LOC`.
2. `dashboard_screen.dart` MUST remove sidebar/header code and implement a 5-tab `BottomNavigationBar`.
3. NO file in the project may exceed `1000 LOC` (target `< 400 LOC` per file for clean maintainability).
4. Remove fragile `part of` / `part` patterns in favor of modular imported widgets.

### 2.1 Feature 1: Settings (`lib/src/features/settings/`)
**Target: `settings_screen.dart` from 2,891 LOC → ~220 LOC**

#### Target Directory Structure:
```
lib/src/features/settings/
├── data/
│   └── whatsapp_service.dart
├── presentation/
│   ├── settings_screen.dart                         (< 250 LOC - Main Settings Hub)
│   ├── clinic_branches_page.dart                    (< 220 LOC - Refactored)
│   ├── pages/
│   │   ├── clinic_details_page.dart                 (~150 LOC - Clinic Profile & Doctor info)
│   │   ├── staff_permissions_page.dart              (~260 LOC - Staff List & Roles)
│   │   ├── theme_settings_page.dart                 (~90 LOC  - Light/Dark Mode Selector)
│   │   ├── services_config_page.dart                (~260 LOC - Services & Consultations Config)
│   │   └── whatsapp_automation_page.dart            (~320 LOC - WhatsApp Bot & Templates)
│   ├── providers/
│   │   └── settings_providers.dart                  (~60 LOC  - Subscription & Staff Providers)
│   └── widgets/
│       ├── settings_profile_header.dart             (~70 LOC  - User Profile Brief Card)
│       ├── settings_subscription_card.dart          (~130 LOC - Subscription Status & Expiry Card)
│       ├── settings_tile.dart                       (~80 LOC  - Reusable Action Tile)
│       ├── service_form_dialog.dart                 (~190 LOC - Add/Edit Service Dialog)
│       ├── staff_invite_dialog.dart                 (~160 LOC - Invite Staff Modal)
│       ├── branch_item_card.dart                    (~140 LOC - Branch Card in Branches Page)
│       ├── branch_form_dialog.dart                  (~170 LOC - Add/Edit Branch Modal)
│       └── whatsapp_template_card.dart              (~210 LOC - Editable Template Box & Variables)
```

---

### 2.2 Feature 2: Appointments (`lib/src/features/appointments/`)
**Target: Break down `book_appointment_dialog.dart` (1,618 LOC), `appointments_screen_parts.dart` (1,321 LOC), `edit_appointment_dialog.dart` (1,222 LOC), and `queue_board.dart` (860 LOC)**

#### Target Directory Structure:
```
lib/src/features/appointments/
├── data/
│   ├── appointment_repository.dart
│   └── visit_note_repository.dart
├── domain/
│   ├── appointment_model.dart
│   ├── appointment_service_model.dart
│   ├── appointment_type_model.dart
│   ├── service_model.dart
│   └── visit_note_model.dart
├── presentation/
│   ├── appointments_screen.dart                     (~180 LOC - Main Screen)
│   ├── appointments_controller.dart                 (~100 LOC)
│   ├── book_appointment_dialog.dart                (~280 LOC - Orchestrating Dialog Shell)
│   ├── edit_appointment_dialog.dart                (~260 LOC - Edit Dialog Shell)
│   ├── examination_screen.dart                      (~320 LOC)
│   ├── patient_queue_tracking_screen.dart           (~350 LOC)
│   ├── visit_notes_dialog.dart                      (~220 LOC - Orchestrating Consultation Dialog)
│   └── widgets/
│       ├── calendar_strip.dart                      (~200 LOC - Horizontal Date Scroller)
│       ├── appointments_filter_bar.dart             (~150 LOC - Doctor/Branch/Status Filter Chips)
│       ├── appointments_daily_revenue_banner.dart   (~140 LOC - Daily Count & Revenue Summary)
│       ├── appointments_notification_dialog.dart    (~180 LOC - Realtime Notifications Center)
│       ├── appointments_bulk_cancel_dialog.dart     (~90 LOC  - Cancel All Confirmation)
│       ├── appointments_empty_state.dart            (~80 LOC  - Calm Clean Empty State)
│       ├── booking/
│       │   ├── booking_patient_picker.dart          (~220 LOC - Autocomplete & Patient Select)
│       │   ├── booking_doctor_branch_pickers.dart   (~160 LOC - Doctor & Branch Selectors)
│       │   ├── booking_service_picker.dart          (~150 LOC - Consultation & Extra Services)
│       │   ├── booking_date_time_picker.dart        (~280 LOC - Date & Time Slot Grid)
│       │   └── booking_pricing_footer.dart          (~180 LOC - Total, Discount, Notes, Submit)
│       ├── queue/
│       │   ├── queue_board.dart                     (~260 LOC - Lane Coordinator)
│       │   ├── queue_card.dart                      (~240 LOC - Queue Patient Card)
│       │   ├── queue_timeline_row.dart              (~200 LOC - Desktop/Mobile Timeline Row)
│       │   ├── queue_row_actions.dart               (~150 LOC - Admit, Complete, Cancel Buttons)
│       │   └── queue_cancel_options_sheet.dart      (~130 LOC - Cancel Reason / Reschedule Sheet)
│       ├── notes/
│       │   ├── visit_vitals_form.dart               (~160 LOC - BP, Pulse, Temp, Weight Inputs)
│       │   └── visit_prescription_editor.dart       (~180 LOC - Medicine, Dosage, Duration Form)
│       ├── patient_medical_sidebar.dart             (~300 LOC)
│       ├── examination_form.dart                    (~220 LOC)
│       └── admission_confirmation_sheet.dart        (~180 LOC)
```

---

### 2.3 Feature 3: Reports (`lib/src/features/reports/`)
**Target: Eliminate `reports_screen_parts.dart` (1,544 LOC) and decompose `report_detail_screen.dart` (1,152 LOC)**

#### Target Directory Structure:
```
lib/src/features/reports/
├── data/
│   └── reports_repository.dart                      (~597 LOC)
├── domain/
│   └── financial_report_model.dart
├── presentation/
│   ├── reports_screen.dart                          (~180 LOC - Main Reports Tab)
│   ├── reports_controller.dart                      (~174 LOC)
│   ├── report_detail_screen.dart                    (~240 LOC - Detailed Financial Report)
│   └── widgets/
│       ├── reports_date_range_picker_dialog.dart    (~280 LOC - Date & Month Picker Dialog)
│       ├── reports_revenue_overview_card.dart       (~180 LOC - Revenue, Expenses, Net Profit Card)
│       ├── reports_daily_table_view.dart            (~200 LOC - Daily Revenue List & Table)
│       ├── reports_monthly_table_view.dart          (~190 LOC - Monthly Aggregation List & Table)
│       ├── reports_filter_bar.dart                  (~140 LOC - Doctor & Branch Chips)
│       └── detail/
│           ├── report_summary_cards_grid.dart       (~180 LOC - Top KPI Cards)
│           ├── report_service_distribution_card.dart (~200 LOC - Service Breakdown / Distribution)
│           ├── report_patient_stats_card.dart       (~150 LOC - New vs Returning Patients)
│           └── report_peak_hours_chart.dart         (~160 LOC - Peak Visit Times Chart)
```

---

### 2.4 Feature 4: Patients (`lib/src/features/patients/`)
**Target: Decompose `patients_screen.dart` (1,410 LOC) and `patient_details_dialog.dart` (1,155 LOC)**

#### Target Directory Structure:
```
lib/src/features/patients/
├── data/
│   └── patient_repository.dart
├── domain/
│   └── patient_model.dart
├── presentation/
│   ├── patients_screen.dart                         (~220 LOC - Master Search & Directory Screen)
│   ├── patient_details_dialog.dart                  (~250 LOC - Comprehensive Patient Modal)
│   └── widgets/
│       ├── add_patient_dialog.dart                  (~300 LOC)
│       ├── edit_patient_dialog.dart                 (~280 LOC)
│       ├── patient_list_card.dart                   (~180 LOC - Individual Patient Card)
│       ├── patient_avatar.dart                      (~90 LOC  - Initials / Photo Avatar)
│       ├── patient_profile_preview_panel.dart       (~240 LOC - Desktop Side Profile Preview)
│       ├── patient_timeline_card.dart               (~160 LOC - Appointment History Timeline Item)
│       └── details/
│           ├── patient_medical_history_tab.dart     (~190 LOC - Chronic Diseases, Allergies, Notes)
│           ├── patient_visit_notes_section.dart     (~210 LOC - Past Diagnoses & Prescriptions)
│           └── patient_services_history_section.dart (~140 LOC - Previous Services & Invoices)
```

---

### 2.5 Feature 5: Dashboard & Shell Navigation (`lib/src/features/dashboard/`)
**Target: `dashboard_screen.dart` from 946 LOC → ~180 LOC, eliminate Sidebar/Header, unify Bottom Navigation Bar**

#### Target Directory Structure:
```
lib/src/features/dashboard/
├── domain/
│   └── notification_model.dart
├── presentation/
│   ├── dashboard_screen.dart                        (~180 LOC - 5-Tab Persistent Shell Screen)
│   ├── notifications_controller.dart                (~173 LOC)
│   ├── financial_panel.dart                         (~320 LOC)
│   └── widgets/
│       ├── dashboard_overview_view.dart             (~240 LOC - Tab 0: Welcome, KPIs, Quick Actions)
│       ├── dashboard_kpi_card.dart                  (~90 LOC  - Reusable KPI Metric Card)
│       └── dashboard_bottom_nav_bar.dart            (~120 LOC - 5-Tab Bottom Navigation Bar)
```

#### Navigation Rules (R1 Compliance):
1. Persistent bottom navigation bar across **Mobile, Tablet, and Web**.
2. Remove any desktop sidebar (`_buildSidebar`) and desktop top header (`_buildTopHeader`).
3. 5 tabs in exact order:
   - Tab 0: `الرئيسية` (Dashboard / Overview)
   - Tab 1: `المواعيد` (Appointments / Queue & Booking)
   - Tab 2: `المرضى` (Patients / Directory)
   - Tab 3: `التقارير` (Reports / Financials - Doctor & Owner only)
   - Tab 4: `الإعدادات` (Settings / Clinic & System)

---

### 2.6 Feature 6: Authentication & Subscriptions (`lib/src/features/auth/`)
**Target: Decompose `register_screen.dart` (1,175 LOC) and `top_up_subscription_screen.dart` (892 LOC)**

#### Target Directory Structure:
```
lib/src/features/auth/
├── data/
│   └── auth_repository.dart
├── domain/
│   └── user_model.dart
├── presentation/
│   ├── login_screen.dart                            (~278 LOC)
│   ├── login_controller.dart                        (~208 LOC)
│   ├── register_screen.dart                         (~220 LOC - 4-Step Wizard Orchestrator)
│   ├── top_up_subscription_screen.dart              (~220 LOC - Subscription Renew Modal)
│   ├── reset_password_screen.dart                   (~350 LOC)
│   ├── verify_otp_screen.dart                       (~280 LOC)
│   ├── join_clinic_screen.dart                      (~250 LOC)
│   ├── pending_activation_screen.dart               (~250 LOC)
│   ├── account_blocked_screen.dart                  (~220 LOC)
│   ├── subscription_gate_screen.dart                (~180 LOC)
│   ├── subscription_status_sheet.dart               (~300 LOC)
│   ├── subscription_warning_banner.dart             (~115 LOC)
│   └── widgets/
│       ├── register/
│       │   ├── register_step_indicator.dart         (~110 LOC - Progress Nodes)
│       │   ├── register_step1_account_form.dart     (~180 LOC - Name, Phone, Password)
│       │   ├── register_step2_role_form.dart        (~150 LOC - Doctor/Assistant, Specialty)
│       │   ├── register_step3_path_form.dart        (~140 LOC - Create vs Join Choice)
│       │   ├── register_step4_create_clinic_form.dart (~240 LOC - Clinic Details & Branches)
│       │   └── register_step4_join_clinic_form.dart (~160 LOC - Invite Code Input)
│       └── subscription/
│           ├── subscription_expiry_header.dart      (~120 LOC - Status & Countdown Header)
│           ├── subscription_plan_card.dart          (~160 LOC - Pricing Tier Card)
│           └── subscription_payment_methods_card.dart (~220 LOC - Payment Details & Confirm Slip)
```

---

### 2.7 Feature 7: Clinics Switcher (`lib/src/features/clinics/`)
**Target: Decompose `clinic_switcher_button.dart` (728 LOC)**

#### Target Directory Structure:
```
lib/src/features/clinics/presentation/widgets/
├── clinic_switcher_button.dart                      (~140 LOC - Compact / Full Switcher Button)
├── clinic_switcher_modal.dart                       (~260 LOC - Bottom Sheet with Switchable Clinics & Branches)
├── create_clinic_dialog.dart                        (~182 LOC)
└── join_clinic_dialog.dart                          (~188 LOC)
```

---

## 3. Caveats
1. **Riverpod State Scope**: When extracting sub-widgets from massive `ConsumerStatefulWidget` classes, controllers (such as `TextEditingController` and `FormState` keys) should either be held in the parent dialog state or encapsulated in the sub-form widget with a `onChanged` / callback or Riverpod family provider.
2. **Realtime Listeners**: In `appointments_screen.dart` and `dashboard_screen.dart`, realtime subscriptions (`realtimeAppointmentsSyncProvider`) must be retained at the root container level so all sub-widgets reactively update.
3. **Route Arguments & Deep Links**: `main.dart` handles deep-link routing for `/track`, `/reset`, `/register`, `/login`, and invite codes. All decomposed screen constructors must preserve their public parameter signatures (e.g. `initialInviteCode`, `subscriptionEndDate`, `clinicName`, `clinicId`).
4. **Arabic Copy Alignment**: During file extraction, all extracted widgets should adopt everyday Arabic copy per Requirement R4 (e.g. "حجز جديد" instead of "إضافة موعد جديد", "المرضى" instead of "إدارة المرضى", "الاشتراك" instead of "تجديد باقة الاشتراك").

---

## 4. Conclusion
1. Currently, **9 files exceed 1,000 LOC**, with `settings_screen.dart` being the largest at **2,891 LOC**.
2. The root cause is embedding multiple full sub-pages, multi-step wizards, custom charts, and deep dialogs directly into screen files or `part of` files.
3. With the proposed decomposition:
   - `settings_screen.dart` is reduced from **2,891 LOC to ~220 LOC** (< 500 LOC target achieved).
   - `dashboard_screen.dart` is reduced from **946 LOC to ~180 LOC**, completely eliminating desktop sidebar / top header code and enforcing a persistent 5-tab `BottomNavigationBar`.
   - **Zero files in the entire codebase exceed 500 LOC** (all files remain comfortably in the 80–380 LOC range).
   - Code maintainability, testability, and UI modularity are maximized.

---

## 5. Verification Method

To independently verify the decomposition:
1. **Line Count Verification Command**:
   ```powershell
   Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
       $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines
       [PSCustomObject]@{
           Path = $_.FullName.Substring((Get-Location).Path.Length + 1)
           Lines = $lines
       }
   } | Sort-Object -Property Lines -Descending | Format-Table -AutoSize
   ```
   - Criteria: `settings_screen.dart` < 500 lines; all files < 1000 lines.
2. **Static Analysis**:
   ```powershell
   flutter analyze
   ```
   - Criteria: 0 errors, 0 warnings.
3. **Compilation & Web Build**:
   ```powershell
   flutter build web
   ```
   - Criteria: Successful compilation and build artifact generation.
