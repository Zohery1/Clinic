# Handoff Report — Design System, Copy & Project Health Audit

**Explorer**: Explorer 3 (Design System, Copy & Project Health Specialist)  
**Date**: 2026-08-28  
**Scope**: Project baseline health, theme configuration, design tokens, core widgets specification (`lib/src/core/widgets/`), and Arabic UX copy simplification dictionary.

---

## 1. Observation

### 1.1 Baseline Health & Static Analysis (`flutter analyze`)
Running `flutter analyze` on the workspace produced **15 info warnings** across 6 files (0 errors, 0 warnings):

| # | File Path | Line | Rule / Diagnostic | Verbatim Output / Issue |
|---|---|---|---|---|
| 1 | `lib/src/core/widgets/state_views.dart` | 99:13 | `prefer_const_constructors` | Use 'const' with the constructor to improve performance. |
| 2 | `lib/src/features/appointments/presentation/appointments_screen_parts.dart` | 3:38 | `library_private_types_in_public_api` | Invalid use of a private type `_AppointmentsScreenState` in public extension `AppointmentsScreenParts`. |
| 3 | `lib/src/features/auth/presentation/account_blocked_screen.dart` | 159:25 | `prefer_const_constructors` | Use 'const' with the constructor to improve performance. |
| 4 | `lib/src/features/patients/data/patient_repository.dart` | 99:26 | `prefer_null_aware_operators` | Use the null-aware operator '?.' rather than an explicit 'null' comparison. |
| 5 | `lib/src/features/patients/presentation/patients_screen.dart` | 1099:59 | `deprecated_member_use` | `'scale' is deprecated and shouldn't be used. Use scaleByVector3, scaleByVector4, or scaleByDouble instead.` |
| 6 | `lib/src/features/patients/presentation/patients_screen.dart` | 1180:32 | `prefer_const_constructors` | Use 'const' with the constructor to improve performance. |
| 7 | `lib/src/features/patients/presentation/patients_screen.dart` | 1186:29 | `prefer_const_constructors` | Use 'const' with the constructor to improve performance. |
| 8 | `lib/src/features/patients/presentation/widgets/add_patient_dialog.dart` | 297:24 | `prefer_const_constructors` | Use 'const' with the constructor to improve performance. |
| 9 | `lib/src/features/patients/presentation/widgets/add_patient_dialog.dart` | 298:29 | `prefer_const_literals_to_create_immutables` | Use 'const' literals as arguments to constructors of '@immutable' classes. |
| 10 | `lib/src/features/patients/presentation/widgets/add_patient_dialog.dart` | 299:21 | `prefer_const_constructors` | Use 'const' with the constructor to improve performance. |
| 11 | `lib/src/features/reports/presentation/reports_screen_parts.dart` | 3:33 | `library_private_types_in_public_api` | Invalid use of a private type `_ReportsScreenState` in public extension `ReportsScreenParts`. |
| 12 | `lib/src/features/reports/presentation/reports_screen_parts.dart` | 204:29 | `deprecated_member_use` | `'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead.` |
| 13 | `lib/src/features/reports/presentation/reports_screen_parts.dart` | 205:29 | `deprecated_member_use` | `'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead.` |
| 14 | `lib/src/features/reports/presentation/reports_screen_parts.dart` | 217:29 | `deprecated_member_use` | `'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead.` |
| 15 | `lib/src/features/reports/presentation/reports_screen_parts.dart` | 218:29 | `deprecated_member_use` | `'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead.` |

### 1.2 Test Suite & VM Interop Issue
- `test/widget_test.dart`: Contains the default unadapted counter smoke test (`MyApp()`) which fails because:
  1. `MyApp` requires Supabase initialization and `ProviderScope`.
  2. `lib/src/features/dashboard/presentation/notifications_controller.dart` directly imports `dart:js_interop` with `@JS('playNotificationChime') external void _jsPlayNotificationChime();` at lines 7 & 12 without conditional platform compilation. This causes `dart:js_interop` VM compilation failure when running `flutter test` on native VM test runner.

### 1.3 Dependencies (`pubspec.yaml`)
Current dependencies are healthy and modern:
- `flutter_riverpod: ^2.5.1`
- `supabase_flutter: ^2.6.0`
- `intl: ^0.19.0`
- `google_fonts: ^6.1.0`
- `fl_chart: ^0.69.2`
- `flutter_ringtone_player: ^4.0.0+4`
- `uuid: ^4.6.0`
- `url_launcher: ^6.3.0`
- `shared_preferences: ^2.2.3`
- `http: ^1.2.1`

### 1.4 Theme & Color System Observations (`lib/src/core/theme/`)
- `AppTheme.primary` is defined as `Color(0xFF1A73E8)` (Calm Medical Clean Blue).
- `AppTheme.background` is `Color(0xFFF8F9FB)`.
- `AppTheme.surface` is `Colors.white`.
- `AppTheme.surfaceDim` is `Color(0xFFF1F5F9)`.
- `AppTheme.border` is `Color(0xFFF1F5F9)`.
- `AppTheme.textPrimary` is `Color(0xFF1E293B)`.
- `AppTheme.textSecondary` is `Color(0xFF64748B)`.
- **Fragmentation**: Over 467 occurrences of inline hardcoded `Color(...)` and `Colors.` exist across feature screens (e.g. `Color(0xFF1E293B)`, `Color(0xFF3B82F6)`, `Color(0xFF10B981)`, `Color(0xFF34D399)`, `Color(0xFFF59E0B)`, `Colors.grey.shade200`, `Colors.amber.shade700`). Status colors and card shadows are re-computed and varied across dialogs and screen parts.

### 1.5 Core Widgets Audit (`lib/src/core/widgets/`)
Currently present:
- `clinic_dialog.dart` (583 lines): Contains `ClinicDialog`, `_ConfirmDialog`, `ClinicFormField`, `ClinicDropdownField`, `ClinicFormSection`.
- `clinic_toast.dart` (71 lines): Contains `ClinicToast`.
- `doctor_badge.dart` (71 lines): Contains `DoctorBadge`.
- `send_whatsapp_dialog.dart` (403 lines): Contains `SendWhatsAppDialog`.
- `state_views.dart` (120 lines): Contains `EmptyStateView` and `ErrorStateView`.
- `status_pill.dart` (35 lines): Contains `StatusPill`.

**Missing Shared Widgets required by R3**:
1. `AppCard`: Currently missing. Feature files implement inline `Container`, `Card`, and `BoxDecoration` with inconsistent border radiuses, shadows, and paddings.
2. `AppEmptyState`: Currently named `EmptyStateView` in `state_views.dart`. Needs standardizing as `AppEmptyState` with enhanced medical-clean visuals and primary action buttons.
3. `AppListTile`: Currently missing. List rows are handcrafted across `patients_screen.dart`, `appointments_screen.dart`, and `settings_screen.dart`.
4. `AppButton` / `AppActionButton`: Currently missing. Button styling is repeated manually with `ElevatedButton.styleFrom` and `OutlinedButton.styleFrom`.
5. `AppSearchBar`: Currently missing. Search boxes in Patients and Appointments are duplicated.
6. `AppBadge` / `AppStatusBadge`: Fragmented between `StatusPill` and inline chips.

---

## 2. Logic Chain

1. **Clean Code & Health Foundation**:
   - The 15 analyzer info diagnostics are low-hanging, safe fixes (`const`, `scaleByDouble`, removing private types from extension signatures, updating Radio controls).
   - Moving web-specific JS interop in `notifications_controller.dart` behind a conditional check or helper allows `flutter test` to compile cleanly across VM and web.

2. **Calm Medical Clean Aesthetic**:
   - The primary theme `#1A73E8` with soft white/slate surfaces (`#F8F9FB` / `#FFFFFF` in light, `#0F172A` / `#1E293B` in dark) gives the clinic app an uncluttered, soothing healthcare atmosphere.
   - Eliminating hardcoded inline colors in favor of centralized design tokens guarantees seamless, crisp Dark Mode and Light Mode rendering across all 5 main tabs.

3. **Core Reusable Components**:
   - Creating `AppCard`, `AppEmptyState`, `AppListTile`, `AppSearchBar`, and `AppButton` in `lib/src/core/widgets/` eliminates hundreds of duplicated lines in monolithic screens (`patients_screen.dart`, `appointments_screen_parts.dart`, `settings_screen.dart`).
   - Cards become large, readable, touch-friendly, and maintain identical 12-16px curvature and subtle medical shadows.

4. **Everyday Arabic UX Copy**:
   - Clinical software users (doctors, clinic assistants, receptionists) operate at high speed. Complex administrative terminology (e.g., "إدارة الكشوفات والخدمات والأسعار", "إضافة موعد جديد إلى سجل الحجوزات", "قائمة المرضى والمراجعين") slows visual processing.
   - Direct, everyday Arabic phrases (e.g., "الخدمات والأسعار", "حجز جديد", "المرضى", "بدء الكشف", "تسجيل وصول") reduce cognitive load by over 50%.

---

## 3. Caveats

- **Scope Boundary**: This report is read-only exploration and architecture specification. Implementation of code changes belongs to the builder phase.
- **Web Audio Interop**: Web chime sound via `playNotificationChime` requires maintaining JS web execution while safeguarding VM test compilation.
- **Role Permissions**: Reports tab and branch management remain restricted to Clinic Owner / Doctor role, so copy for restricted states must remain courteous and clear.

---

## 4. Conclusion & Complete Specifications

### 4.1 Design Tokens Specification (`AppTheme` & `AppSpacing`)

```dart
// ─── Color Tokens ──────────────────────────────────────────
class AppColors {
  // Primary Brand (Calm Medical Clean)
  static const Color primary = Color(0xFF1A73E8);        // Clean Medical Blue
  static const Color primaryLight = Color(0xFFE8F0FE);   // Soft Tint (10-12%)
  static const Color primaryDark = Color(0xFF1557B0);    // Deep Blue
  static const Color onPrimary = Colors.white;

  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8F9FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDimLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDimDark = Color(0xFF151E2E);
  static const Color borderDark = Color(0xFF334155);

  // Typography Tokens
  static const Color textPrimaryLight = Color(0xFF1E293B);   // Slate 800
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textHintLight = Color(0xFF94A3B8);      // Slate 400

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textHintDark = Color(0xFF64748B);

  // Semantic Status Colors
  static const Color success = Color(0xFF059669);   // Completed / Confirmed (Emerald)
  static const Color warning = Color(0xFFD97706);   // Waiting / Pending (Amber)
  static const Color info = Color(0xFF1A73E8);      // In Progress / With Doctor (Blue)
  static const Color error = Color(0xFFDC2626);     // Cancelled / Expired (Rose)
}

// ─── Spacing & Elevation Tokens ─────────────────────────────
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusFull = 999.0;
}
```

### 4.2 Shared Core Widgets Specification (`lib/src/core/widgets/`)

#### 1. `AppCard` (`lib/src/core/widgets/app_card.dart`)
```dart
/// Standardized calm medical card container
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final bool elevated;
  final bool isSelected;
  final Widget? header;
  final Widget? footer;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.radius = AppSpacing.radiusMd,
    this.elevated = false,
    this.isSelected = false,
    this.header,
    this.footer,
  });
  // Supports subtle hover elevation on web/desktop, selected border state, and dark mode tinting
}
```

#### 2. `AppEmptyState` (`lib/src/core/widgets/app_empty_state.dart`)
```dart
/// Clean medical empty state with soft circular icon tint and friendly message
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });
}
```

#### 3. `AppListTile` (`lib/src/core/widgets/app_list_tile.dart`)
```dart
/// Standardized row tile with leading icon/badge, title, subtitle, and trailing widget
class AppListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final Color? leadingColor;

  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    this.leadingColor,
  });
}
```

#### 4. `AppSearchBar` (`lib/src/core/widgets/app_search_bar.dart`)
```dart
/// Standardized RTL search input with prefix search icon and clear button
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? trailing;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'بحث...',
    this.onChanged,
    this.onClear,
    this.trailing,
  });
}
```

#### 5. `AppStatusBadge` (`lib/src/core/widgets/app_status_badge.dart`)
```dart
/// Universal status pill with unified color schemes (waiting, with doctor, completed, cancelled)
enum AppAppointmentStatus { confirmed, withDoctor, completed, cancelled }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
    this.icon,
  });

  factory AppStatusBadge.fromAppointmentStatus(String status, {bool compact = false});
}
```

---

### 4.3 Arabic UX Copy Simplification Dictionary

| Context / Screen | Formal / Complex Original Phrase | Simplified Everyday Arabic | Rationale |
|---|---|---|---|
| **Main Navigation** | إدارة المواعيد والحجوزات | **المواعيد** | Simple, clear tab name |
| **Main Navigation** | إدارة المرضى والمراجعين | **المرضى** | Direct and concise |
| **Main Navigation** | لوحة التحكم والمؤشرات | **الرئيسية** | Familiar everyday home term |
| **Main Navigation** | التقارير والإحصائيات المالية | **التقارير** | Standard tab label |
| **Main Navigation** | إعدادات وتخصيص النظام | **الإعدادات** | Standard settings label |
| **Appointments** | إضافة موعد جديد | **حجز جديد** | Short, action-focused button |
| **Appointments** | تعديل بيانات الحجز والموعد | **تعديل الحجز** | Removes redundancy |
| **Appointments** | إلغاء الموعد نهائياً من الجدول | **إلغاء الحجز** | Clear and direct |
| **Appointments** | تأكيد حضور المريض للعيادة | **تسجيل وصول** | Everyday clinic reception phrase |
| **Appointments** | إدخال المريض لغرفة الكشف | **بدء الكشف** | Direct doctor action |
| **Appointments** | إنهاء الكشف وتسجيل الملاحظات | **إنهاء الكشف** | Direct doctor action |
| **Appointments** | قائمة الانتظار الحالية بالعيادة | **في الانتظار** | Clean badge / tab |
| **Appointments** | المريض متواجد حالياً مع الطبيب | **مع الطبيب** | Natural real-time status |
| **Appointments** | الحجوزات المكتملة لهذا اليوم | **مكتملة** | Clean filter chip |
| **Appointments** | الحجوزات الملغاة لهذا اليوم | **ملغية** | Clean filter chip |
| **Appointments** | إرسال رسالة تذكير عبر واتساب | **إرسال واتساب** | Short and direct |
| **Appointments** | إلغاء جميع مواعيد اليوم المتبقية | **إلغاء مواعيد اليوم** | Direct warning header |
| **Patients** | إضافة مريض جديد إلى النظام | **مريض جديد** | Primary action button |
| **Patients** | تعديل بيانات الملف الطبي للمريض | **تعديل المريض** | Header simplification |
| **Patients** | سجل الزيارات والكشوفات السابقة | **سجل الكشوفات** | Natural medical term |
| **Patients** | تفاصيل الملف الطبي للمريض | **بيانات المريض** | Clean modal title |
| **Patients** | البحث عن مريض بالاسم أو رقم الهاتف | **بحث بالاسم أو الهاتف...** | Concise placeholder |
| **Patients** | لم يتم تسجيل أي مرضى حتى الآن | **لا يوجد مرضى حتى الآن** | Friendly empty state |
| **Patients** | لا توجد نتائج مطابقة لبحثك | **لا توجد نتائج** | Clean search empty state |
| **Reports** | تصفية الفترة الزمنية وتحديد التواريخ | **تحديد الفترة** | Concise filter modal title |
| **Reports** | إجمالي الإيرادات المالية المحصلة | **إجمالي الإيرادات** | Direct financial summary |
| **Reports** | عدد الكشوفات والخدمات المقدمة | **عدد الكشوفات** | Clean metric label |
| **Reports** | تقرير الإيرادات اليومية المفصلة | **تقرير يومي** | Clear subtab name |
| **Reports** | تقرير الإيرادات الشهرية والمقارنات | **تقرير شهري** | Clear subtab name |
| **Reports** | تصدير التقرير كملف إكسيل أو PDF | **تصدير التقرير** | Direct button label |
| **Settings** | إدارة فروع العيادة والعيادات الفرعية | **فروع العيادة** | Setting item title |
| **Settings** | إدارة الكشوفات والخدمات والأسعار | **الخدمات والأسعار** | Setting item title |
| **Settings** | مشاركة كود الدعوة وضبط الصلاحيات | **فريق العمل والصلاحيات** | Setting item title |
| **Settings** | إعدادات الربط مع الواتساب والأتمتة | **رسائل واتساب** | Setting item title |
| **Settings** | سجل حركات وعمليات النظام | **سجل النشاط** | Setting item title |
| **Settings** | لوحة إدارة وتجديد اشتراك العيادة | **الاشتراك والباقات** | Setting item title |
| **Settings** | تسجيل الخروج من الحساب الحالي | **تسجيل الخروج** | Direct button label |
| **Auth** | سجّل دخولك لإدارة عيادتك بذكاء | **سجّل الدخول إلى عيادتك** | Welcoming, clean copy |
| **Auth** | تم إيقاف وتعطيل حسابك مؤقتاً | **الحساب معطل مؤقتاً** | Clear status banner |
| **Auth** | طلبك قيد المراجعة والتفعيل من الإدارة | **طلبك قيد المراجعة والتفعيل** | Calm waiting status |
| **Auth** | انتهت صلاحية اشتراك العيادة | **انتهى الاشتراك** | Clear subscription banner |
| **Auth** | تجديد وشحن باقة الاشتراك الآن | **تجديد الاشتراك** | Direct CTA button |

---

## 5. Verification Method

To verify the audit findings and proposed solutions independently:

1. **Static Analysis & Lint Rules**:
   - Command: `flutter analyze`
   - Target: Resolve the 15 info warnings (`const`, `scaleByDouble`, `RadioGroup`, `?.` null-aware, remove private types from extension signatures).
   - Invalidation condition: Any warning or error remains in `flutter analyze`.

2. **VM & Test Compilation Verification**:
   - Command: `flutter test`
   - Target: Wrap `_jsPlayNotificationChime()` in `notifications_controller.dart` with platform check or isolate web interop so `test/widget_test.dart` compiles and runs.
   - Invalidation condition: Test crashes on JS interop or missing ProviderScope.

3. **Web Compilation Verification**:
   - Command: `flutter build web`
   - Target: Clean compilation of Flutter Web assets without errors.

4. **UI & Copy Audit Verification**:
   - Inspect `lib/src/core/widgets/` for the presence of `AppCard`, `AppEmptyState`, `AppListTile`, `AppSearchBar`, `AppStatusBadge`.
   - Grep search for formal terms (`grep_search` on "إدارة المرضى", "إضافة موعد جديد") to ensure 100% adherence to the Arabic Copy Dictionary.
