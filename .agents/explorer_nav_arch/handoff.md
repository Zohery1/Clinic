# Navigation & Architecture Specialist Investigation Report (Handoff)

## 1. Observation

### 1.1 Project Structure & Routing Entry Point
- **`lib/main.dart`**:
  - `MyApp` uses `MaterialApp` with `onGenerateRoute` (lines 57–117):
    - `/track` or `/queue` → `PatientQueueTrackingScreen` (public patient queue viewer with `appointmentId` from query parameter or fragment).
    - `/reset` → `ResetPasswordScreen(isUpdateMode: true)`.
    - `/register` (or routes containing invite code via `InviteUtils.extractInviteCode`) → `RegisterScreen`.
    - `/login` → `LoginScreen`.
    - Fallback default route `/` → `AuthGate`.
  - `AuthGate` (lines 123–439):
    - Subscribes to Supabase `onAuthStateChange` and real-time clinic stream (`Supabase.instance.client.from('clinics').stream(...)`).
    - Enforces subscription expiration check via a 1-minute heartbeat timer (`_scheduleExpirationTimer`).
    - Gate states:
      - `JoinClinicScreen` (when `role == UserRole.secretary` and `clinicId.isEmpty`).
      - `AccountBlockedScreen` (when `!currentUser.isActive`).
      - `PendingActivationScreen` (when `_subscriptionStatus == 'pending_activation'`).
      - `SubscriptionGateScreen` (when `!_isClinicActive || _subscriptionStatus == 'suspended'`).
      - `TopUpSubscriptionScreen` (when `_subscriptionStatus == 'expired'` or subscription end date is in the past).
      - `DashboardScreen` (when authenticated and subscription is active).

### 1.2 Current Dashboard & Navigation Architecture
- **`lib/src/features/dashboard/presentation/dashboard_screen.dart` (981 lines)**:
  - Acts as the post-auth application shell/scaffold.
  - Forks entirely based on screen width (`final isDesktop = MediaQuery.of(context).size.width >= 900;` at line 114):
    - **Desktop Layout (`isDesktop == true`, lines 122–146)**:
      - Renders a 256px wide Right Sidebar via `_buildSidebar(user)` (lines 236–314), with items:
        - 0: 'الرئيسية' (`Icons.grid_view_rounded`)
        - 1: 'المرضى' (`Icons.people_alt_outlined`)
        - 2: 'التقارير المالية' (`Icons.trending_up_rounded`) [only if `user?.isOwner ?? false`]
        - 3: 'الإعدادات العامة' (`Icons.settings_suggest_outlined`)
        - Bottom user profile initials card (`_buildSidebarProfileCard`, lines 379–452) with sign-out button.
      - Renders a 70px high Top Header via `_buildTopHeader(user)` (lines 461–531) with section title, `ClinicSwitcherButton`, `SubscriptionWarningBanner`, notifications button, and settings button.
      - Main Content area (lines 134–144):
        - Index 0: `_buildDashboardContent()` (lines 786–872) with Stats banner (Daily Revenue & Cases count) + Split Row (1/3 `FinancialPanel` + 2/3 `AppointmentsScreen`).
        - Index 1: `PatientsScreen()`.
        - Index 2: `ReportsScreen()`.
        - Index 3: `SettingsScreen()`.
    - **Mobile / Tablet Layout (`isDesktop == false`, lines 148–229)**:
      - Top header bar (`Container(height: 56)`, lines 150–183) when `_currentIndex != 0` showing title and compact `ClinicSwitcherButton`.
      - Body (lines 184–198):
        - Index 0: `AppointmentsScreen(...)` directly (NOTE: On mobile, index 0 is ONLY `AppointmentsScreen` — the Dashboard Overview and `FinancialPanel` are omitted entirely!).
        - Index 1: `PatientsScreen()`.
        - Index 2: `ReportsScreen()`.
        - Index 3: `SettingsScreen()`.
      - Bottom Bar (lines 202–228): Custom container with 4 items:
        - 0: 'الرئيسية' (`Icons.calendar_today_rounded`)
        - 1: 'المرضى' (`Icons.people_outline_rounded`)
        - 2: 'التقارير' (`Icons.bar_chart_rounded`) [if `user?.isOwner ?? false`]
        - 3: 'الإعدادات' (`Icons.settings_outlined`)

### 1.3 Inconsistencies & Duplicated Headers
- **`lib/src/features/appointments/presentation/appointments_screen_parts.dart` (1361 lines)**:
  - `_buildMobileLayout` (lines 761–932) renders its own top header with clinic icon, greeting (`صباح الخير / مساء الخير`), formatted date, `ClinicSwitcherButton`, orange receipt/invoice top-up button, and notification bell button.
  - This header duplicates the shell's top elements.
- **`lib/src/features/reports/presentation/reports_screen.dart` (322 lines)**:
  - Contains defensive check `if (!user.isOwner)` (lines 108–148) returning a locked screen view.
  - Redundantly branches on `isDesktop` (lines 152–170).
- **`lib/src/features/settings/presentation/settings_screen.dart` (3053 lines)**:
  - Directly handles sub-navigation by pushing sub-pages (`ClinicDetailsPage`, `StaffPermissionsPage`, `ClinicBranchesPage`, `ServicesConfigPage`, `WhatsAppAutomationPage`, `ThemeSettingsPage`) onto the `Navigator`.

---

## 2. Logic Chain

1. **Requirement R1 Mandate**:
   - R1 explicitly requires:
     > "Implement a persistent Bottom Navigation Bar across all platforms (Mobile, Tablet, Web) and remove any existing sidebars or top headers."
     > "The 5 tabs must be: الرئيسية (Dashboard), المواعيد (Appointments), المرضى (Patients), التقارير (Reports - owner only), الإعدادات (Settings)."
   - Acceptance Criteria confirms:
     > "`dashboard_screen.dart` file no longer contains sidebar code and uses a BottomNavigationBar."

2. **Decoupling Dashboard Overview from Appointments**:
   - Currently, Desktop index 0 combined Dashboard stats + `FinancialPanel` + `AppointmentsScreen`, while Mobile index 0 loaded `AppointmentsScreen` directly.
   - To satisfy the 5 distinct tabs, Tab 0 must become a dedicated **الرئيسية (Dashboard)** overview screen, and Tab 1 must become **المواعيد (Appointments)**.

3. **Role Gating for Tab 3 (التقارير - Reports)**:
   - `UserModel` in `lib/src/features/auth/domain/user_model.dart` exposes `user.isOwner` (boolean).
   - If `user.isOwner == true`: The shell renders all 5 tabs (`[Dashboard, Appointments, Patients, Reports, Settings]`).
   - If `user.isOwner == false`: The shell dynamically excludes Reports from the bottom navigation bar, rendering 4 tabs (`[Dashboard, Appointments, Patients, Settings]`), with index mapping ensuring the active tab index never exceeds the valid range.
   - `ReportsScreen` itself retains its internal guard as a defense-in-depth safety measure.

4. **Preserving Tab State with `IndexedStack`**:
   - To ensure instantaneous tab switching without losing user state (such as search queries in Patients, active date filter in Appointments, or form inputs), the persistent shell must use an `IndexedStack` holding the 5 view widgets.

5. **Cross-Platform Responsive Styling of the BottomNavigationBar**:
   - On Mobile: Standard full-width bottom navigation bar with `SafeArea`.
   - On Tablet & Web/Desktop: Center-constrained (`BoxConstraints(maxWidth: 800)`) floating or docked bottom bar with the "Calm Medical Clean" aesthetic (white surface, primary blue `#1A73E8` active state, subtle elevation/shadow, Cairo font).

---

## 3. Caveats

1. **Subpage Navigation**: Sub-pages pushed via `Navigator.of(context).push(...)` (e.g. `ClinicDetailsPage`, `ExaminationScreen`, `PatientDetailsDialog`) will render above the shell as intended, and upon popping (`Navigator.pop`), will return directly to the active tab within the persistent bottom navigation shell.
2. **Push Notifications & Modals**: The notifications dialog and `ClinicSwitcherButton` which were previously on the desktop top header can now be comfortably integrated into the Dashboard Overview header (Tab 0) and the Settings tab (Tab 4), or as clean top action icons on relevant tab pages without cluttering the global shell.
3. **Line Count Targets**: Refactoring `dashboard_screen.dart` by extracting the Dashboard Overview content into a separate widget will drastically reduce `dashboard_screen.dart` from 981 lines to under 250 lines, easily meeting the `< 500 lines` acceptance criterion.

---

## 4. Conclusion & Architecture Blueprint

### 4.1 Target Tab Specifications

| Tab Index (Owner) | Tab Index (Staff) | Label (Arabic) | Icon | Target Widget | Key Content |
|---|---|---|---|---|---|
| **0** | **0** | **الرئيسية** | `Icons.dashboard_rounded` (or `Icons.grid_view_rounded`) | `DashboardOverviewTab` | Clinic greeting, subscription banner, KPI metrics (revenue, cases), quick financial summary, quick action shortcuts |
| **1** | **1** | **المواعيد** | `Icons.calendar_month_rounded` | `AppointmentsScreen` | Date picker, 7-day strip, doctor & branch filters, queue status tabs (انتظار / تم الكشف / مكتمل / ملغى), queue cards, "حجز جديد" button |
| **2** | **2** | **المرضى** | `Icons.people_alt_rounded` | `PatientsScreen` | Patient search (name/phone/file), patient list, add patient dialog, patient profile & visit history |
| **3** | — | **التقارير** | `Icons.bar_chart_rounded` | `ReportsScreen` | Daily & monthly revenue breakdown, financial charts, services/doctors breakdown, export (Owner only) |
| **4** | **3** | **الإعدادات** | `Icons.settings_rounded` | `SettingsScreen` | User profile, subscription info, clinic/doctor details, staff permissions, branches, services & prices, WhatsApp, theme, logout |

---

### 4.2 Detailed Implementation Blueprint for `DashboardScreen` (`lib/src/features/dashboard/presentation/dashboard_screen.dart`)

```dart
// Suggested Architecture for dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../appointments/presentation/appointments_screen.dart';
import '../../appointments/presentation/appointments_controller.dart';
import '../../patients/presentation/patients_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/top_up_subscription_screen.dart';
import 'widgets/dashboard_overview_tab.dart'; // Extracted overview widget

class DashboardScreen extends ConsumerStatefulWidget {
  final DateTime? subscriptionEndDate;
  final String? inviteCode;
  final String? clinicName;
  final String? clinicId;

  const DashboardScreen({
    super.key,
    this.subscriptionEndDate,
    this.inviteCode,
    this.clinicName,
    this.clinicId,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeAppointmentsSyncProvider);

    final isExpired = widget.subscriptionEndDate != null &&
        widget.subscriptionEndDate!.isBefore(DateTime.now());

    if (isExpired) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: TopUpSubscriptionScreen(
            clinicName: widget.clinicName ?? 'العيادة',
            inviteCode: widget.inviteCode ?? '',
            clinicId: widget.clinicId ?? '',
            onRefresh: () => setState(() {}),
          ),
        ),
      );
    }

    final user = ref.watch(currentUserProvider);
    final isOwner = user?.isOwner ?? false;

    // Define items dynamically based on role
    final navItems = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'الرئيسية'),
      _NavItem(icon: Icons.calendar_month_rounded, label: 'المواعيد'),
      _NavItem(icon: Icons.people_alt_rounded, label: 'المرضى'),
      if (isOwner)
        _NavItem(icon: Icons.bar_chart_rounded, label: 'التقارير'),
      _NavItem(icon: Icons.settings_rounded, label: 'الإعدادات'),
    ];

    // Ensure _currentIndex is clamped within navItems range
    final safeIndex = _currentIndex >= navItems.length ? 0 : _currentIndex;

    // Define screen stack
    final screens = <Widget>[
      DashboardOverviewTab(
        subscriptionEndDate: widget.subscriptionEndDate,
        inviteCode: widget.inviteCode,
        clinicName: widget.clinicName,
        clinicId: widget.clinicId,
      ),
      AppointmentsScreen(
        subscriptionEndDate: widget.subscriptionEndDate,
        inviteCode: widget.inviteCode,
        clinicName: widget.clinicName,
        clinicId: widget.clinicId,
      ),
      const PatientsScreen(),
      if (isOwner) const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: safeIndex,
          children: screens,
        ),
        bottomNavigationBar: _buildPersistentBottomBar(navItems, safeIndex),
      ),
    );
  }

  Widget _buildPersistentBottomBar(List<_NavItem> items, int selectedIndex) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isSelected = selectedIndex == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.hintColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
```

---

### 4.3 Clean Code Actions for Downstream Builder
1. **Create `lib/src/features/dashboard/presentation/widgets/dashboard_overview_tab.dart`**:
   - Move `_buildDashboardContent()`, `_buildKPIBlock()`, and summary stats logic from `dashboard_screen.dart` into this new focused widget file.
   - Add clinic greeting header, `ClinicSwitcherButton`, and quick action cards ("حجز جديد", "مريض جديد").
2. **Refactor `lib/src/features/dashboard/presentation/dashboard_screen.dart`**:
   - Replace old desktop sidebar and top header code with the unified persistent `BottomNavigationBar` and `IndexedStack`.
   - Remove ~750 lines of dead sidebar/header code, keeping the file clean (< 250 lines).
3. **Clean up `AppointmentsScreen`**:
   - Ensure `AppointmentsScreen` is cleanly embedded in Tab 1 and does not render conflicting full-page scaffold headers.
4. **Preserve Sub-page Navigation**:
   - All sub-pages in `Settings` and `Appointments` continue to use `Navigator.push(MaterialPageRoute(...))` with standard `AppBar` back button navigation.

---

## 5. Verification Method

To independently verify the implementation:

1. **Static Analysis**:
   ```powershell
   flutter analyze
   ```
   *Expected result: 0 issues / 0 errors / 0 warnings.*

2. **Web Compilation**:
   ```powershell
   flutter build web
   ```
   *Expected result: Web build compiles successfully without errors.*

3. **Line Count Checks**:
   ```powershell
   (Get-Content lib/src/features/dashboard/presentation/dashboard_screen.dart).Count
   ```
   *Expected result: `< 500` lines.*

4. **Visual & Navigation Checks**:
   - Test on Web/Desktop viewport (>= 900px) and Mobile (< 700px): Confirm that **NO sidebars** and **NO top desktop headers** exist on any platform.
   - Confirm persistent `BottomNavigationBar` is visible on all 3 screen sizes (Mobile, Tablet, Desktop/Web).
   - Log in as Owner: verify all 5 tabs appear: `الرئيسية`, `المواعيد`, `المرضى`, `التقارير`, `الإعدادات`.
   - Log in as Secretary / Staff: verify only 4 tabs appear: `الرئيسية`, `المواعيد`, `المرضى`, `الإعدادات`.
   - Switch between tabs: verify `IndexedStack` maintains state (search query in patients, date filter in appointments).
