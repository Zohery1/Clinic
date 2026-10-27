## 2026-08-28T19:46:25Z
You are Explorer Arabic UX (Replacement Gen 2). Your task is to review Arabic copy and UI consistency across all feature screens in `e:\SAAS\Clinic\lib\src\features\`.

Read the authoritative requirements:
- `e:\SAAS\Clinic\.agents\ORIGINAL_REQUEST.md` (specifically R4: Simplified Arabic copy and R3: Calm Medical Clean design system)
- `e:\SAAS\Clinic\PROJECT.md`

Your working directory is `e:\SAAS\Clinic\.agents\explorer_m3_m4_arabic_2\`.

Specific Tasks:
1. Search all UI screens, dialogs, buttons, toasts, and empty states across `lib/src/features/` for formal/bureaucratic Arabic copy (e.g., "إدارة المرضى", "إضافة موعد جديد", "تسجيل مريض جديد", "تعديل البيانات", etc.) and map them to friendly, everyday Egyptian/Arabic clinical terms (e.g., "المرضى", "حجز جديد", "مريض جديد", "تعديل", "التقارير", etc.).
2. Inspect usage of `AppEmptyState`, `AppCard`, `AppListTile`, `AppSearchBar`, and `AppStatusBadge` to verify consistency with "Calm Medical Clean" aesthetic across all feature tabs (Dashboard, Appointments, Patients, Reports, Settings).
3. Produce a structured handoff report in `e:\SAAS\Clinic\.agents\explorer_m3_m4_arabic_2\handoff.md` with:
   - Observation: Catalog of existing copy vs proposed simplified copy.
   - Empty state & card review across all tabs.
   - Logic Chain & Recommendations for Worker.
4. Send a summary message back to the orchestrator when complete.
