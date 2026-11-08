# Eyadaty Project Execution & Architecture Rules

## 1. Non-Negotiable Honesty & Proof Protocol
- **Zero Hallucination:** NEVER claim an action was taken or a screen was rebuilt unless you actually performed the file write and verified it.
- **Proof Requirement:** After modifying any code, ALWAYS run static analysis (`flutter analyze` or `dart analyze`) and report the real output. Never say "everything passes" without running the command.

## 2. Rebuilds & Overhauls (Anti-Diff-Bias)
- When instructed to "rebuild from scratch", "wipe and replace", or "start over":
  - **FORBIDDEN:** Do NOT use search-and-replace (`edit_file`) or make cosmetic/partial tweaks to existing legacy code.
  - **MANDATORY:** You MUST completely overwrite the file using `write_file` (`Overwrite: true`), providing the full, clean, working implementation from line 1 to EOF.
  - No placeholder comments (`// TODO: add rest of code here`) or stubbed widgets.

## 3. Context Hygiene (Preventing Agent Confusion)
- **Ignore Legacy Agent Dumps:** Do NOT read or depend on historical subagent dump folders inside `.agents/` (e.g., `explorer_*`, `worker_*`, `orchestrator_*`). They contain obsolete, fragmented experiments.
- **Source of Truth:**
  - Source code: `lib/` (specifically `lib/src/features/` and `lib/src/core/`)
  - Dependencies: `pubspec.yaml`
  - Active user prompt and explicit requirements.

## 4. Flutter Architectural Standards
- **Feature-First Architecture:** Code resides in `lib/src/features/<feature>/` divided into `presentation`, `domain`, and `data`.
- **UI & Design:** Material 3 standards, clean layout hierarchy, proper Arabic/RTL text direction handling, responsive widgets without fixed arbitrary pixel overflows.
- **State Management:** Keep views decoupled from direct database or network logic.
