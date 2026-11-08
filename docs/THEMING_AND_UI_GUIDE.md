# Eyadaty Theming & UI Design System Guide

This guide documents the design tokens, component standards, typography, color semantics, and BiDi formatting rules used across the **Eyadaty** platform.

---

## 1. Design System Philosophy

Eyadaty's user interface is crafted specifically for high-stress, high-throughput clinical environments. The design prioritizes:
1. **High Visual Density:** Maximizing clinical data visibility without requiring excessive vertical scrolling.
2. **Cognitive Hierarchy:** Clear visual differentiation between patient identifiers, diagnostic vitals, appointment statuses, and financial figures.
3. **Calm Clinical Aesthetic:** Deep clinical sapphires (`#2563EB`, `#1E40AF`), crisp slate surfaces, and clean borders rather than loud, distracting gradients.
4. **Instant Keyboard Navigation:** Core dialogs support keyboard shortcuts (`Ctrl+Enter`, `Esc`) for rapid reception and intake operations.

---

## 2. Design Tokens (`lib/src/core/ui/tokens/`)

### Colors (`AppColors`)
All colors must be sourced from `AppColors`. Never hardcode raw hex codes in widgets.

- **Primary Clinical Brand:**
  - `AppColors.primary`: `#2563EB` (Clinical Blue)
  - `AppColors.primaryDark`: `#1D4ED8`
  - `AppColors.primaryLight`: `#3B82F6`
  - `AppColors.primarySubtle`: Semi-transparent blue tint for container fills
- **Semantic Statuses:**
  - `AppColors.success`: `#10B981` (Completed appointments, confirmed revenues, balanced cash)
  - `AppColors.warning`: `#F59E0B` (Pending queues, intake warnings)
  - `AppColors.danger`: `#EF4444` (Cancelled appointments, cash drawer deficits, petty expenses)
  - `AppColors.info`: `#06B6D4` (General clinical notices, surplus balances)
- **Theme-Aware Accessors:**
  Always use the context-sensitive accessors to guarantee automatic Light & Dark mode adaptation:
  - `AppColors.surface(context)`: Main card and sheet background
  - `AppColors.subtle(context)`: Muted container fill
  - `AppColors.borderSubtle(context)`: Subtle divider and card border line
  - `AppColors.textPrimary(context)`: High-contrast primary reading text
  - `AppColors.textSecondary(context)`: Secondary explanatory metadata

### Spacing Scale (`AppSpace`)
The layout adheres strictly to an 8-point / 4-point clinical grid:
- `AppSpace.xs`: 4.0
- `AppSpace.sm`: 8.0
- `AppSpace.md`: 12.0
- `AppSpace.lg`: 16.0
- `AppSpace.xl`: 24.0
- `AppSpace.xxl`: 32.0

### Corner Radii (`AppRadii`)
- `AppRadii.radiusXs`: 4.0 (Micro badges)
- `AppRadii.radiusSm`: 8.0 (Input fields, buttons)
- `AppRadii.radiusMd`: 12.0 (Cards, dialog cards)
- `AppRadii.radiusLg`: 16.0 (Major workspace panels)
- `AppRadii.radiusXl`: 24.0 (Modal sheets and dialog containers)
- `AppRadii.radiusPill`: 999.0 (Rounded status chips)

---

## 3. Typography Standards

Eyadaty uses **Cairo** for all Arabic text and **JetBrains Mono** for numerical, clinical, and financial data.

- **Headlines & Titles:** `GoogleFonts.cairo(fontWeight: FontWeight.w700 | FontWeight.w800)`
- **Body & Labels:** `GoogleFonts.cairo(fontWeight: FontWeight.w400 | FontWeight.w600)`
- **Financial & Metrics:** `GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800)` ensures tabular figures align accurately in lists and invoice tables.

---

## 4. UI Primitives

Reusable atomic primitives are located in `lib/src/core/ui/primitives/`:
- **`AppButton`:** Standardized button with loading state, icons, and variants (`primary`, `secondary`, `ghost`, `danger`).
- **`AppBadge`:** Status pill for queue and examination statuses.
- **`AppAvatar`:** Patient and doctor initials avatar with consistent clinical color hashing.
- **`AppIconButton`:** High-density icon button with tooltips and accessible touch targets.

---

## 5. Right-to-Left (RTL) & BiDi Formatting Rules

Eyadaty is an Arabic-first application. To ensure perfect text rendering and avoid layout bugs:

1. **Directionality:** All custom dialogs and root views must be wrapped in `Directionality(textDirection: TextDirection.rtl, child: ...)`.
2. **BiDi Term Isolation:**
   Whenever English terms (e.g., `Walk-in`, `Express Intake`, `Manager Tool`, `KPI`, `API`, `OTP`, `ID`, `JSON`) appear inside Arabic strings, enclose them in parentheses or format them with separate spans/backticks to prevent punctuation from jumping across the line:
   ```dart
   // Good
   Text('طابور الانتظار الآن (Walk-in)')
   // Bad
   Text('طابور الانتظار الآن Walk-in')
   ```
3. **Punctuation Endings:**
   Arabic sentences must terminate with periods, colons, or questions on the correct left-hand edge of the line in RTL mode.
