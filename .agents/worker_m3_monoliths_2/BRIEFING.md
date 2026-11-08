# BRIEFING — 2026-08-28T16:51:00Z

## Mission
Decompose feature monoliths across settings, patients, appointments, reports, auth into clean modular subpages and widgets, ensuring all files are < 500-1000 LOC (target < 400 LOC), flutter analyze is 0 errors/0 warnings, and all functionality is genuinely preserved.

## 🔒 My Identity
- Archetype: worker
- Roles: implementer, qa, specialist
- Working directory: e:\SAAS\Clinic\.agents\worker_m3_monoliths_2
- Original parent: 97c83389-ff33-420a-a0d0-d3462f320c93
- Milestone: M3 (Feature Monolith Decomposition)

## 🔒 Key Constraints
- NO file in `lib/` exceeds 1000 LOC. Target < 400 LOC for all files.
- `settings_screen.dart` must be strictly < 500 LOC.
- Strict genuine implementation - no cheating, no facades, no hardcoded values.
- `flutter analyze` must pass with 0 errors and 0 warnings.
- Scope: settings, patients, appointments, reports, auth presentation layers.

## Current Parent
- Conversation ID: 97c83389-ff33-420a-a0d0-d3462f320c93
- Updated: not yet

## Task Summary
- **What to build**: Deconstruct large monolithic files into modular components, dialogs, widgets, tabs, and subpages.
- **Success criteria**: 0 errors/warnings on `flutter analyze`, all files < 1000 LOC (target < 400 LOC, settings_screen < 500 LOC), genuine behavior preserved.
- **Interface contracts**: PROJECT.md
- **Code layout**: lib/src/features/{settings,patients,appointments,reports,auth}/presentation/{widgets,subpages,dialogs,tabs}

## Change Tracker
- **Files modified**: None yet
- **Build status**: Untested
- **Pending issues**: None

## Quality Status
- **Build/test result**: Untested
- **Lint status**: Untested
- **Tests added/modified**: TBD

## Loaded Skills
- None

## Key Decisions Made
- Initial setup

## Artifact Index
- handoff.md — will be generated upon completion
