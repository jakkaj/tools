---
description: For one selected phase, generate a combined `tasks.md` dossier (tasks + alignment brief) under the plan tree; stop before making code changes.
---

Please deep think / ultrathink as this is a complex task. 

# plan-5-phase-tasks-and-brief

**One phase at a time.** Generate an actionable **tasks + alignment brief dossier** (`tasks.md`) for the chosen phase, plus the supporting directory structure, and stop before implementation. This merges your previous "tasks" generation with the pre-implementation walkthrough, scoped strictly to **one** phase. Treat the dossier as the shared contract between the human sponsor and the coding agent: lean on visual aids (e.g., Mermaid flow + sequence diagrams) to cement a cohesive understanding before touching code.

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"

1) Verify PLAN exists; set PLAN_DIR = dirname(PLAN); define `PHASE_DIR = PLAN_DIR/tasks/${PHASE_SLUG}` and create it if missing (mkdir -p).
2) Locate the exact phase heading = $PHASE in PLAN. Abort if not found.
3) Derive **only** the tasks relevant to this phase using the canonical tasks format described below, but scope to:
   - Setup (only what this phase needs)
   - Tests-first (contract/integration/unit) -> MUST FAIL initially
   - Core changes for this phase only
   - Integration & Polish limited to this phase
   - [P] allowed **only** when tasks touch different files; same file => sequential
   - Every task includes **absolute paths**.
   (Template mapping & formatting from tasks-template.) :contentReference[oaicite:12]{index=12}

   **Canonical tasks table layout** (all dossiers MUST follow this column order):
   | Status | ID | Task | Type | Dependencies | Absolute Path(s) | Validation | Notes |
   - `Status` is a literal checkbox column; start each row with `[ ]` so later phases can update to `[~]` (in progress) or `[x]` (complete).
   - `ID` uses the T001… dossier sequence and should link back to the matching plan task when applicable.
   - `Task` summarizes the work item; `Type` classifies it (Setup/Test/Core/Integration/Doc/etc.).
   - `Absolute Path(s)` must list every impacted file or directory using absolute paths.
   - `Validation` captures how acceptance or readiness will be confirmed.
   - `Notes` include [P] guidance plus phase-footnote placeholders (e.g., trailing `[^3]`).

4) Write a single combined artifact `PHASE_DIR/tasks.md` containing:
   - Phase metadata (title, slug, links to SPEC and PLAN, today {{TODAY}}).
   - `## Tasks` section that renders the table exactly as defined above (Status checkbox first, then ID, Task, Type, Dependencies, Absolute Path(s), Validation, Notes) with numbered items (T001...), dependencies, [P] guidance, and validation checklist coverage.
  - `## Alignment Brief` section with:
     * Objective recap + behavior checklist (tie to PLAN acceptance criteria)
     * Invariants & guardrails (perf/memory/security budgets if relevant)
     * Inputs to read (exact file paths)
     * Visual alignment aids: capture both a Mermaid flow diagram (system states) and a Mermaid sequence diagram (actor/interaction order). Treat these as shared-understanding checkpoints so the human sponsor and coding agent agree on the flow before implementation begins.
     * **Test Plan (TDD, tests-as-docs, no mocks, real data)**: enumerate named tests with rationale, fixtures, expected outputs
     * Step-by-step implementation outline mapped 1:1 to the tasks/tests
     * Commands to run (copy/paste): env setup, test runner, linters, type checks
     * Risks/unknowns & **rollback plan**
     * **Ready Check** (checkboxes) -> await explicit GO/NO-GO
   - `## Phase Footnote Stubs` table: for each task row that will change code, append a Notes entry ending with a footnote tag (e.g., `[^3]`) and list the tag with a short placeholder description. Phase 6 will replace these placeholders with node-ID details in the plan ledger per `AGENTS.md`.
   - `## Evidence Artifacts` describing where implementation will write the execution log (`PHASE_DIR/execution.log.md`) and any supporting files.

5) Capture a short directory layout at the end of `PHASE_DIR/tasks.md` so future phases know where to place logs and ancillary evidence inside `PHASE_DIR`.
   - Note that Plan 6 writes `execution.log.md` and any other evidence directly into `PHASE_DIR`.
   - Example (adjust as files accumulate):
     ```
     docs/plans/2-feature-x/
       ├── feature-x-plan.md
       └── tasks/phase-2/
           ├── tasks.md
           └── execution.log.md  # created by /plan-6
     ```

Rules & Stack Patterns:
- Follow `docs/rules-idioms-architecture/{rules.md, idioms.md}` (TDD, tests-as-docs, no mocks, real data). :contentReference[oaicite:13]{index=13}
- Apply BridgeContext patterns when relevant: bounded `vscode.RelativePattern`, remote-safe `vscode.Uri`, Python debugging via `module: 'pytest'` with `--no-cov`. :contentReference[oaicite:14]{index=14}

STOP: Do **not** edit code. Output the combined `PHASE_DIR/tasks.md` and wait for human **GO**.
```

Why this shape: it leverages your existing **tasks** template mechanics but restricts scope firmly to **one phase**, and carries forward the alignment without the separate heavy analysis pass you asked to remove.

Next step (when happy): Run **/plan-6-implement-phase --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**.
