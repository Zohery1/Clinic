# Clinic Management System — AI Operating Rules & Obsidian Sync

## 1. Context Read-First Directive
Before executing any complex code analysis, refactoring, or feature development in `Clinic Management System`:
- **Step 1**: Consult the Obsidian Knowledge Base at `E:\SAAS\Obsidian to Antigravity\MCP\Clinic_Management\03_CheatSheet_AI_Context.md`.
- **Step 2**: Use Obsidian MCP tools (`read_file` / `search_files`) or file viewing tools to inspect relevant feature notes (`Clinic_Management/Features/*.md`) or database schemas (`Clinic_Management/02_Database_&_Schema.md`).
- **Do NOT** perform full directory scans across all source files unless required for specific line editing.

## 2. Automatic Obsidian Update Directive
Whenever code or database schemas are modified:
- **Schema Changes**: If `schema.sql` or database structures change, update `Clinic_Management/02_Database_&_Schema.md`.
- **Feature Additions / Modifications**: If new screens, models, or services are added/edited in `lib/src/features/`, update the corresponding note under `Clinic_Management/Features/`.
- **Architectural Changes**: If core libraries or global state providers are changed, update `Clinic_Management/01_Architecture_&_Design.md` and `Clinic_Management/03_CheatSheet_AI_Context.md`.
