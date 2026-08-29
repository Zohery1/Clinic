# Dispatch for Worker M2: Navigation Restructure & Dashboard Overhaul

## Scope & File Ownership
- Primary files owned: `lib/src/features/dashboard/**` (specifically `lib/src/features/dashboard/presentation/dashboard_screen.dart`, `lib/src/features/dashboard/presentation/widgets/dashboard_overview_tab.dart`, etc.)

## Objectives
1. Read `e:\SAAS\Clinic\.agents\ORIGINAL_REQUEST.md` and `e:\SAAS\Clinic\PROJECT.md`.
2. Restructure `dashboard_screen.dart`:
   - Implement a persistent 5-tab `BottomNavigationBar` using `IndexedStack` across all platforms (Mobile, Tablet, Web).
   - The 5 tabs:
     - 0: الرئيسية (DashboardOverviewTab)
     - 1: المواعيد (AppointmentsScreen)
     - 2: المرضى (PatientsScreen)
     - 3: التقارير (ReportsScreen) [Gated: only displayed/accessible if `user.isOwner == true`]
     - 4: الإعدادات (SettingsScreen)
   - Remove any existing sidebars (`_buildSidebar`, `NavigationRail`, etc.) and top headers (`_buildTopHeader`) so the layout is clean, unified, and consistent on mobile, tablet, and web.
3. Extract `DashboardOverviewTab`:
   - Move overview widgets, metrics, quick actions, charts, and summaries from `dashboard_screen.dart` into `lib/src/features/dashboard/presentation/widgets/dashboard_overview_tab.dart` (and sub-widgets as needed).
   - Ensure `lib/src/features/dashboard/presentation/dashboard_screen.dart` is clean, concise, and < 250 LOC.
4. Verify with `flutter analyze` that no errors or warnings are introduced.
5. Create `handoff.md` in `e:\SAAS\Clinic\.agents\worker_m2_nav\` with full report and line counts.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
