# Eyadaty Architecture Documentation

This document describes the architectural principles, directory layout, routing contracts, and state management conventions of the **Eyadaty** clinical SaaS platform.

---

## 1. High-Level Architectural Pattern

Eyadaty is built as a **Feature-First, Layered Flutter Application** designed for high reliability, responsiveness, and multi-tenant clinical workflow orchestration.

### Layered Architecture (per Feature)
Each feature lives in `lib/src/features/<feature_name>/` and is divided into three distinct layers:

1. **Domain Layer (`domain/`)**:
   - Pure Dart models, value objects, and business entities (e.g., `AppointmentModel`, `PatientModel`, `PettyExpenseItem`).
   - Free of Flutter UI code and database dependencies.
   - Immutable with `factory fromJson` and `Map<String, dynamic> toJson` serialization.

2. **Data Layer (`data/`)**:
   - Repositories and external service drivers (e.g., `AppointmentRepository`, `PatientRepository`).
   - Interfaces directly with Supabase via `supabase.from('...')` queries and Realtime streams.
   - Encapsulates database schema nuances, RLS-compliant querying, and exception mapping.

3. **Presentation Layer (`presentation/`)**:
   - Flutter UI widgets, screens, dialogs, and Riverpod controllers/notifiers.
   - Subdivided into `widgets/` for reusable subcomponents and `pages/` (or `subpages/`) for complex layouts.
   - Kept decoupled from raw database calls: views only consume Riverpod providers and invoke repository methods through controllers or facades.

```
lib/src/
├── core/
│   ├── config/              # Environment configurations & Supabase client bootstrap
│   ├── routing/             # AppRoutes, AppRouter, AppNavigation facade
│   ├── theme/               # ThemeData, Material 3 configurations
│   ├── ui/
│   │   ├── feedback/        # Empty states, error displays, skeletons
│   │   ├── primitives/      # AppButton, AppBadge, AppAvatar, AppIconButton
│   │   └── tokens/          # AppColors, AppSpace, AppRadii, AppShadows, AppMotion, AppTypography
│   ├── utils/               # Doctor utils, date/time formatting, validators
│   └── widgets/             # Cross-cutting widgets (ClinicToast, ClinicDialog)
└── features/
    ├── appointments/        # Booking, queue, Kanbans, clinical examinations
    ├── auth/                # Login, OTP verification, gates, user sessions
    ├── clinics/             # Clinic configuration, branches, settings
    ├── dashboard/           # KPIs, quick actions, today appointments ticker, notifications
    ├── patients/            # Patient registry, search, timeline, medical profiles
    ├── reports/             # Financial logs, cash drawer reconciliation, analytics
    └── settings/            # Clinic details, services config, staff permissions, WhatsApp automation
```

---

## 2. State Management Standard (Riverpod)

Eyadaty relies on **Flutter Riverpod** for predictable, reactive, and testable dependency injection and state management.

### Key Rules
1. **AsyncValue for Remote Data:** Remote queries use `AsyncNotifier` or `FutureProvider` returning `AsyncValue<T>`. Views use `.when(data: ..., loading: ..., error: ...)` to handle all states gracefully.
2. **Deterministic Invalidation Chains:** After modifying clinical state (e.g., booking an appointment or changing queue status), related providers must be explicitly invalidated to ensure real-time consistency across tabs:
   ```dart
   ref.invalidate(todayAppointmentsProvider);
   ref.invalidate(appointmentsForDateProvider);
   ref.invalidate(todayRevenueProvider);
   ```
3. **Optimistic Updates:** For high-speed queue operations (e.g., admitting patients, marking examinations as completed), local state is updated immediately with background network sync to keep the clinic workflow instantaneous.

---

## 3. Centralized Routing & Navigation Contract

A core architectural pillar in Eyadaty is **strict decoupling of screens through `AppNavigation` and `AppRouter`**.

### The Problem It Solves
Previously, screens directly imported other screens and pushed them using `Navigator.push(MaterialPageRoute(builder: (_) => ExaminationScreen(...)))`. This created tight coupling: modifying or redesigning one screen broke dozens of distant callers across multiple features.

### The Decoupled Navigation Pattern

1. **Route Identifiers (`AppRoutes`):**
   Constant string names for all named routes (e.g., `AppRoutes.login`, `AppRoutes.dashboard`, `AppRoutes.examination`, `AppRoutes.reportDetail`).

2. **Route Generator (`AppRouter`):**
   A single, centralized resolver (`AppRouter.onGenerateRoute`) that inspects route settings, decodes strongly typed arguments (`ExaminationRouteArgs`, `ReportDetailRouteArgs`), parses deep-link parameters (e.g., `/track?id=...`, `/queue`, `/reset`), and maps them to concrete widgets.

3. **Type-Safe Navigation Facade (`AppNavigation`):**
   All navigation across screens and global dialogs is performed strictly via static methods on `AppNavigation`:
   ```dart
   // Screen Navigation
   AppNavigation.toExamination(context, clinicId: clinicId, appointmentId: aptId, ...);
   AppNavigation.toReportDetail(context, clinicId: clinicId, date: reportDate);
   AppNavigation.toLogin(context);

   // Modal & Dialog Workspaces
   AppNavigation.showBookAppointment(context, clinicId: clinicId);
   AppNavigation.showPatientDetails(context, clinicId: clinicId, patient: patient);
   AppNavigation.showWhatsApp(context, ref, phone: phone, patientName: name);
   ```

### Screen Independence & Redesign Rule
Because all callers communicate solely with `AppNavigation`, **any screen in `lib/src/features/` can be completely redesigned, rewritten from scratch, or replaced with an alternative implementation without touching or breaking any calling code**. The screen's internal dependencies, layout hierarchy, or child widgets remain completely isolated.

---

## 4. UI Modularity & Clean Decomposition

To prevent monolithic presentation files that are difficult to maintain and test, screens and dialogs must adhere to a strict component decomposition standard:

- **Orchestrator Role:** Main screen or dialog widgets act purely as high-level coordinators (managing controllers, keyboard shortcuts, and layout composition).
- **Subcomponents:** Specialized visual areas (headers, metric grids, data inputs, action footers) are extracted into cohesive, single-responsibility widgets located in `presentation/widgets/<feature_subfolder>/`.
- **Pure Stateless Subcomponents:** Subcomponents should prefer `StatelessWidget` and receive values and callbacks (`onChanged`, `onTap`) rather than mutating shared mutable state directly.

---

## 5. Arabic RTL & BiDi Architecture

Eyadaty is architected with native Right-to-Left (RTL) ergonomics:
- **Base Direction:** The root application defines `locale: const Locale('ar')` with `GlobalMaterialLocalizations` and `GlobalWidgetsLocalizations`.
- **BiDi Isolation:** Whenever English technical terms, acronyms, or codes appear inside Arabic copy, they must be formatted using backticks or wrapped in LTR blocks to ensure the BiDi text engine maintains correct punctuation and sentence ordering.
- **Directional UI Primitives:** Avoid hardcoded `left`/`right` paddings and alignments; use `EdgeInsetsDirectional`, `AlignmentDirectional`, and `start`/`end` semantics for responsive mirroring.
