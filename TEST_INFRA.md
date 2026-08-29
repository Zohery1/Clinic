# Test Infrastructure & Strategy

## Overview
This document describes the hermetic testing infrastructure, architecture, and multi-tier test suite for the **Clinic Management System** (Eyadaty / عيادتي).

The test suite is structured into **4 distinct tiers** ensuring complete verification ranging from isolated core widgets to complex real-world daily clinic workflows across mobile, tablet, and desktop viewports.

---

## 1. Test Architecture & Harness

### 1.1 Hermetic Execution & Mocking Strategy
The application uses **Flutter Riverpod** for state management and **Supabase** for backend synchronization. To achieve fast, deterministic, reproducible tests without requiring internet access or a running Supabase backend:
- **`TestAppHarness`** (`test/test_helpers/test_app_harness.dart`): Provides unified `defaultOverrides` for all Riverpod providers and builds the root `MaterialApp` with Arabic RTL directionality, theme configurations (`AppTheme.lightTheme` & `AppTheme.darkTheme`), and surface sizing.
- **Fake Repositories** (`test/test_helpers/mock_repositories.dart`):
  - `FakeAuthRepository`: Simulates user sessions, login/logout, staff fetching, permissions, and invite codes.
  - `FakeAppointmentRepository`: In-memory appointment management, status lifecycle, service add-ons, and pricing calculations.
  - `FakePatientRepository`: In-memory patient storage, normalized Arabic search, and duplicate/similarity detection.
  - `FakeReportsRepository`: In-memory revenue statistics, daily/monthly breakdown, and service categorization.
  - `FakeClinicsRepository`: Multi-clinic switching, branch management, and subscription state.
  - `FakeVisitNoteRepository`: Doctor visit notes, diagnosis, prescriptions, and historical note retrieval.
  - `FakeNotificationsNotifier`: In-memory notification state eliminating Web JS audio and Supabase Realtime interop dependencies.
- **Test Fixtures** (`test/test_helpers/test_data.dart`): Comprehensive predefined test fixtures for doctors (owner & non-owner), secretaries, blocked staff, patients, branches, appointments, services, and financial reports.

### 1.2 Viewport & Responsive Simulation
`TestAppHarness` includes standard screen surface manipulators:
- `setMobile(tester)`: 390x844 (Mobile portrait)
- `setTablet(tester)`: 768x1024 (Tablet portrait)
- `setDesktop(tester)`: 1280x800 (Desktop web standard)
- `resetSurfaceSize(tester)`: Cleans up surface constraints post-test via `addTearDown`.

---

## 2. Multi-Tier Test Suite Structure

```
test/
├── test_helpers/
│   ├── mock_repositories.dart       # In-memory fake repositories for all features
│   ├── test_app_harness.dart        # Test app builder, provider overrides, viewport sizing
│   └── test_data.dart               # Canonical test fixtures & models
├── tier1_features/
│   ├── appointment_filtering_test.dart  # Filtering by doctor, branch, date & provider queries
│   ├── core_widgets_test.dart           # AppCard, AppEmptyState, AppListTile, AppSearchBar, AppStatusBadge
│   ├── navigation_tabs_test.dart        # Persistent 5-tab BottomNavigationBar & IndexedStack
│   ├── patient_search_test.dart         # Arabic text search, substring, phone, address filtering
│   └── theme_switching_test.dart        # Light/Dark tokens, ThemeNotifier, Calm Medical design tokens
├── tier2_boundaries/
│   ├── empty_states_test.dart           # Empty patient list, appointments, search, notifications
│   ├── role_permissions_test.dart       # Doctor owner vs non-owner vs secretary, blocked accounts, subscription gate
│   └── validation_boundaries_test.dart  # Form field validations, phone length, age bounds, missing gender
├── tier3_combinations/
│   ├── patient_to_booking_flow_test.dart # Patient creation -> Appointment booking -> List display
│   ├── search_filter_resets_test.dart    # Multi-filter combinations & reset behavior
│   └── theme_navigation_flow_test.dart   # Theme switching during cross-tab navigation
├── tier4_scenarios/
│   └── daily_clinic_workflow_e2e_test.dart # Full day operational lifecycle (login -> exam -> checkout -> reports)
└── widget_test.dart                     # Smoke tests for unauthenticated & authenticated app launch
```

---

## 3. Tier Breakdown & Coverage

### Tier 1: Feature Coverage
- **Navigation & Tabs**: Verifies persistent 5-tab `BottomNavigationBar` (الرئيسية, المواعيد, المرضى, التقارير, الإعدادات) using `IndexedStack` across Mobile, Tablet, and Desktop platforms without sidebars.
- **Theme & Design Tokens**: Validates `AppColors.primary` (`#1A73E8`), Light surfaces (`#FFFFFF` / `#F8F9FB`), Dark surfaces (`#1E293B` / `#0F172A`), `AppSpacing` tokens, and `ThemeNotifier`.
- **Shared Core Widgets**: Verifies `AppCard` (selection, elevated, headers), `AppEmptyState` (action callback, iconography), `AppListTile`, `AppSearchBar` (input & clear), and `AppStatusBadge` (status mapping).
- **Appointment Filtering**: Verifies querying today appointments, filtering by doctor ID, branch ID, and selected date state.
- **Patient Search**: Tests normalized substring matching across patient names, phone numbers, and addresses.

### Tier 2: Boundary & Corner Cases
- **Empty States**: Tests empty patient list, empty appointments list, zero-match search results, empty notification dialog, and empty service lists.
- **Validation Boundaries**: Tests required name input, phone length (< 11 digits), invalid/zero age, missing gender selection, and missing patient selection in booking.
- **Role Permissions & Security**: Tests elevated owner permissions vs restricted associate doctor vs secretary, role-gated Reports tab, blocked user screen (`AccountBlockedScreen`), and subscription expiration gate (`TopUpSubscriptionScreen`).

### Tier 3: Cross-Feature Combinations
- **Theme Switching During Navigation**: Tests toggling Light/Dark theme while actively navigating across all 5 tabs and ensuring state retention in `IndexedStack`.
- **Patient Creation to Booking Flow**: Multi-step flow creating a patient in the repository/dialog, launching booking dialog, selecting appointment type and services, confirming booking, and verifying appearance in appointments view.
- **Search & Filter Resets**: Verifies live search query filtering, clearing search input, multi-attribute filter application (doctor + branch + date), and clean resets.

### Tier 4: Real-World Scenarios
- **Full Daily Clinic Workflow E2E**:
  1. Doctor Login & Dashboard Briefing: Welcome header, KPI cards, quick actions.
  2. Walk-In Patient Registration: Register patient demographics, phone, medical history.
  3. Appointment Booking: Schedule appointment with appointment type and add-on services.
  4. Queue Progression & Status Lifecycle: `confirmed` -> `waiting` -> `withDoctor` -> `completed`.
  5. Clinical Examination & Notes Recording: Record clinical complaint, diagnosis, prescription, and extra services.
  6. Financial Reporting & Checkout: Verify revenue updates, visit count increments, and reports data.
  7. Clinic Settings & Configuration: Inspect branches, theme settings, and staff configuration.

---

## 4. How to Run Tests

### Run All Tests
```bash
flutter test
```

### Run Tier 1 Tests (Feature Coverage)
```bash
flutter test test/tier1_features/
```

### Run Tier 2 Tests (Boundaries & Permissions)
```bash
flutter test test/tier2_boundaries/
```

### Run Tier 3 Tests (Cross-Feature Combinations)
```bash
flutter test test/tier3_combinations/
```

### Run Tier 4 Tests (Real-World Scenarios)
```bash
flutter test test/tier4_scenarios/
```
