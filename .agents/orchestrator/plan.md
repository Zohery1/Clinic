# UI Overhaul Master Plan

## 1. Objectives & Scope
Transform Flutter Clinic from prototype to polished, production-ready product:
1. **R1 Navigation**: Persistent 5-tab Bottom Navigation Bar across Mobile, Tablet, and Web (`الرئيسية`, `المواعيد`, `المرضى`, `التقارير`, `الإعدادات`). Remove sidebars/top headers.
2. **R2 Refactor Monoliths**: Deconstruct `settings_screen.dart`, `book_appointment_dialog.dart`, `reports_screen_parts.dart`, `patients_screen.dart`, `appointments_screen_parts.dart`, `dashboard_screen.dart` into clean, focused sub-widgets (all files < 1000 LOC, `settings_screen.dart` < 500 LOC).
3. **R3 Design System**: Calm Medical Clean (White + `#1A73E8`, light/dark mode, core widgets `AppCard`, `AppEmptyState`, `AppListTile` in `lib/src/core/widgets/`, generous spacing).
4. **R4 Simplified Copy**: Conversational everyday Arabic.
5. **Acceptance Criteria**: `flutter analyze` with 0 errors/warnings, successful `flutter build web`, line limit constraints, visual polish.

## 2. Orchestration Phases
- **Phase 0 (Survey)**: Dispatch 3 parallel Explorers to analyze codebase structure, line counts, existing navigation, design tokens, and build health.
- **Phase 1 (Test Track)**: E2E test harness and test cases (Tiers 1-4) verifying navigation, screens, state, and responsive layout.
- **Phase 2 (Design System Milestone)**: Implementation of core design tokens, theme mode, and reusable widgets in `lib/src/core/widgets/`.
- **Phase 3 (Navigation Milestone)**: Refactor shell/scaffold to persistent bottom nav, strip legacy sidebars/headers.
- **Phase 4 (Feature Refactoring Milestone)**: Modularize large screen files into clean component hierarchies.
- **Phase 5 (Arabic Copy & Aesthetics Milestone)**: Update string copy to friendly simple Arabic, refine layouts and empty states.
- **Phase 6 (Comprehensive Verification & Forensic Audit)**: Full test suite verification, build checks, and forensic audit gate.
