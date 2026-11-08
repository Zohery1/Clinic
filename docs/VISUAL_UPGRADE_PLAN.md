# Eyadaty — Visual Upgrade Plan: MVP → Real Product

Ground truth: live release build QA'd in-browser on 2026-11-06, every screen screenshotted
with a logged-in real account (dashboard, reports, all settings subpages, queue,
book-appointment dialog, branches, whatsapp, clinic details, theme, patients fallback).
Every item below is observed, not speculative. Fixes gated by `flutter analyze`
(5 pre-existing printer infos max) + `flutter test` (42/42).

---

## Findings by screen (evidence-based)

### 1. Design-system gaps (cross-screen)
- **F1 — Width stretch.** Settings subpages (staff-permissions, services, theme,
  whatsapp, branches, clinic-details) stretch one column across the full ~1140 px
  content area. Toggles/checks sit at the screen edge with a huge dead middle;
  primary CTA buttons (حفظ البيانات، إضافة فرع جديد، إلغاء ربط الواتساب) render
  full-width. Fix: shared `ContentMaxWidth` container (max ~880 px, centered) +
  constrained CTA widths (min 220 px, not full-bleed).
- **F2 — Status map centralization. DONE** — `lib/src/core/utils/appointment_status.dart`
  created; dashboard `_StatusPill`, appointment card, details card now use it.
  Raw `cancelled_by_clinic` pills no longer possible (verified in code, tests 42/42).
- **F3 — Spinner-only states.** Deep settings routes show a bare centered spinner
  for seconds on slow connections (whatsapp page). Needs skeleton shimmer
  (`app_skeleton.dart` exists — apply across settings + reports loading paths).
- **F4 — Empty-state depth.** Clinic-details: empty specialty/name fields render
  as blank deco fields with zero guidance; new-clinic onboarding waste. Add
  inline helper copy + example placeholders.

### 2. Dashboard
- Hero, stats row, quick actions, weekly chart, today queue, recent transactions:
  all functional with live data. Solid base.
- Weekly chart bell-curve has hard zero-dips between data days (reads as fake V
  shapes on empty days). Fix: `isCurved` smoothness + break nulls, or bar chart
  for discrete days (bars suit daily revenue semantics better than a smooth line).
- Hero + stats row density is good; the quick actions row uses chevrons that hint
  navigation but have no visual weight — give each a mono-color icon chip.

### 3. Reports
- Inner tabs work; daily log default tab surfaces zero-value 'المصاريف'/'المكافأة'
  columns — clutter for clinics that never use payouts. Hide columns whose whole
  column is zero/empty (progressive disclosure).
- KPI cards are readable but flat: add tokenized tint backgrounds by metric class
  (revenue=primary, patients=accent, seats=info) — same tint language as pills.

### 4. Settings
- Staff permissions: dense two-panel layout, tokens clean. Main gap is F1 width;
  secondary: invite-code panel deserves a copy-to-clipboard success toast
  (ClinicToast already exists).
- Branches: 'sdasd' test data aside, cards are fine; deletion has no confirm
  dialog? (verify — destructive action needs ClinicDialog confirm).
- WhatsApp page: connected panel shows raw `clinic_d26bc89c` instance ID and
  +20 phone in mono — fine, but layout is F1. Preview pane of saved template
  shows placeholder tokens raw `{{patient_name}}`? (saw `[time] [date]` bracket
  style) — add live preview substitution with sample data so admins see what
  patients will receive.

### 5. Queue & appointments
- Queue tracking OK. Book-appointment dialog working ('Express Intake' badge,
  `ج.م` price chips). Remaining visible debt: appointment time/type pickers were
  not QA'd visually (dialog flows beyond default state) — spot-check next session.

### 6. shell/deep-linking (P2 refactor, not visual)
- Dashboard shell tabs (`/home … /settings`) are out-of-band state; hash URLs
  (`#/dashboard`, `#/reports`) never sync to them. Symptom seen once: shell
  title/content desync. Real fix: init `_currentIndex` from the navigator's
  current route name + pushName on tab change. Not visual, but breaks "real
  product" bar through browser-back confusion.

---

## Phased execution order (each phase = one gated batch)

**Phase A — Layout infrastructure (unblocks everything)**
1. `ContentMaxWidth` wrapper widget in `core/ui/layout/`; wrap settings body +
   reports body + queue page content.
2. CTA width constraints (`ConstrainedBox maxWidth 320` for full-screen CTAs).

**Phase B — State polish**
3. Skeletons on loading paths (F3) — settings + reports.
4. Clinic-details helper copy + placeholders (F4).

**Phase C — Charts & data honesty**
5. Weekly chart: switch to bar type or fix curve breaks; keep ISO dates math
   already fixed.
6. Reports: zero-column hiding; KPI tint backgrounds.

**Phase D — Shell deep-link sync (P2)**
7. `_currentIndex` from route on mount; tab click pushes route name.

**Phase E — Final QA sweep** (needs browser window visible)
8. Screenshots still unverified: examination screen, notifications dialog,
   appointments standalone screen, appointment pickers inside dialogs.
9. Dark-mode pass on every upgraded screen (tokens already support it).

---

## Verified gates for each phase
```
flutter analyze → 0 errors/warnings (5 pre-existing printer infos tolerated)
flutter test    → 42/42
flutter build web --release → ✓ before visual QA
```
Status at plan write: analyze clean (0 errors/warnings), tests 42/42, Phase F2 done.
