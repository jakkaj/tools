---
description: For one selected phase, generate a scoped tasks file and pre-implementation alignment brief; stop before making code changes.
---

# plan-5-phase-tasks-and-brief

**One phase at a time.** Generate an actionable **tasks file for the chosen phase** and a concise **alignment brief** (walkthrough + commands + risks/rollback) that you will approve before implementation. This merges your previous "tasks" generation with the pre-implementation walkthrough, scoped strictly to **one** phase.

```md
---
description: For ONE selected phase, generate a phase-scoped tasks.md and a pre-implementation alignment brief; do not implement yet.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --feature-dir "<abs path to specs/<feature>>"
# --plan "<abs path to plan.md>"

1) Run {SCRIPT}; parse FEATURE_DIR and verify PLAN exists.
2) Locate the exact phase heading = $PHASE in PLAN. Abort if not found.
3) Derive **only** the tasks relevant to this phase using `/templates/tasks-template.md` rules, but scope to:
   - Setup (only what this phase needs)
   - Tests-first (contract/integration/unit) -> MUST FAIL initially
   - Core changes for this phase only
   - Integration & Polish limited to this phase
   - [P] allowed **only** when tasks touch different files; same file => sequential
   - Every task includes **absolute paths**.
   (Template mapping & formatting from tasks-template.) :contentReference[oaicite:12]{index=12}

4) Write `FEATURE_DIR/tasks.${PHASE_SLUG}.md` with:
   - Title and pointers (SPEC, PLAN)
   - Numbered tasks (T001...)
   - Dependencies + [P] guidance
   - Validation checklist (coverage of this phase's acceptance criteria)

5) Create a **Phase Alignment Brief** `FEATURE_DIR/phase.${PHASE_SLUG}.brief.md`:
   Sections:
   - Objective recap + behavior checklist (tie to PLAN acceptance criteria)
   - Invariants & guardrails (perf/memory/security budgets if relevant)
   - Inputs to read (exact file paths)
   - **Test Plan (TDD, tests-as-docs, no mocks, real data)**: enumerate named tests with rationale, fixtures, expected outputs
   - Step-by-step implementation outline mapped 1:1 to the tasks/tests
   - Commands to run (copy/paste): env setup, test runner, linters, type checks
   - Risks/unknowns & **rollback plan**
   - **Ready Check** (checkboxes) -> await explicit GO/NO-GO

Rules & Stack Patterns:
- Follow docs/rules/rules-idioms.md (TDD, tests-as-docs, no mocks, real data). :contentReference[oaicite:13]{index=13}
- Apply BridgeContext patterns when relevant: bounded `vscode.RelativePattern`, remote-safe `vscode.Uri`, Python debugging via `module: 'pytest'` with `--no-cov`. :contentReference[oaicite:14]{index=14}

STOP: Do **not** edit code. Output two files and wait for human **GO**.
```

Why this shape: it leverages your existing **tasks** template mechanics but restricts scope firmly to **one phase**, and carries forward the alignment without the separate heavy analysis pass you asked to remove.
