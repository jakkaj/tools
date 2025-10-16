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
2) **Read Critical Research Findings** from the PLAN document:
   - Locate section "## 3. Critical Research Findings" or similar heading in the plan
   - Study each numbered discovery (🚨 Critical Discovery 01, 02, 03...)
   - Note the structure: Problem, Root Cause, Solution, Impact on architecture/design
   - Identify which findings affect the current phase's implementation
   - These findings MUST inform task design, implementation approach, and validation strategies
   - Critical findings often reveal API limitations, framework requirements, or implementation constraints that change how tasks should be structured
   - Reference discoveries by number when applicable (e.g., "per Critical Discovery 02")
3) Locate the exact phase heading = $PHASE in PLAN. Abort if not found.
4) **Read plan-3's task table format** from the PLAN document:
   - plan-3 outputs tasks with columns: `#`, `Status`, `Task`, `Success Criteria`, `Log`, `Notes`
   - Example: `| 1.1 | [ ] | Add Copilot directory variables | Variables defined in agents.sh | - | |`
   - These are high-level tasks that need to be expanded into detailed implementation tasks.

5) **Transform and expand** plan-3 tasks into the canonical tasks format:
   - **Expansion**: Each high-level plan-3 task (e.g., "1.1") may become multiple detailed tasks (T001, T002, T003...)
   - **Apply Critical Findings**: Ensure tasks account for all relevant discoveries from step 2. Reference specific findings in task descriptions or Notes when applicable. Critical findings may require additional tasks (e.g., workarounds, validation tests, constraint handling).
   - **Mapping**:
     * `#` (e.g., "1.1") → `ID` (e.g., "T001") - Use T001… sequence; note plan task reference in comments
     * `Task` → `Task` (expand with specifics, add absolute paths inline or reference in Absolute Path(s) column)
     * `Success Criteria` → `Validation` (make more specific and measurable)
     * Add new `Type` column (Setup/Test/Core/Integration/Doc/etc.)
     * Add new `Dependencies` column (use T-IDs or "–" for none)
     * Add new `Absolute Path(s)` column (REQUIRED: list every impacted file/directory)
   - **Scope to this phase only**:
     * Setup (only what this phase needs)
     * Tests-first (contract/integration/unit) -> MUST FAIL initially
     * Core changes for this phase only
     * Integration & Polish limited to this phase
     * [P] allowed **only** when tasks touch different files; same file => sequential
     * Every task includes **absolute paths**.

   **Example transformation (showing how Critical Findings affect task breakdown):**
   ```
   Critical Finding from plan.md § 3:
   🚨 Critical Discovery 01: Copilot File Extension Requirement
   Problem: GitHub Copilot ignores plain `.md` files in prompt directories
   Root Cause: Discovery logic explicitly filters on `*.prompt.md` pattern
   Solution: Always rename output files to include `.prompt.md` extension
   Impact: This enforces the file renaming requirement (FR3 in spec)

   Plan-3 input (from plan.md):
   | 2.1 | [ ] | Implement file copy loop | All .md files copied to global | - | |
   | 2.2 | [ ] | Add rename logic during copy | Files saved as `.prompt.md` | - | |

   Plan-5 output (for tasks.md) - EXPANDED with Critical Finding applied:
   | [ ] | T001 | Review existing copy loop in agents.sh | Setup | – | /abs/path/to/install/agents.sh | Understand extension handling | Serial (shared file) |
   | [ ] | T002 | Implement copy loop for command files to Copilot global dir | Core | T001 | /abs/path/to/install/agents.sh | All .md files copied | Serial (shared file) |
   | [ ] | T003 | Add .prompt.md extension during copy (per Critical Discovery 01) | Core | T002 | /abs/path/to/install/agents.sh | Files end with .prompt.md | Addresses Copilot discovery requirement (footnote captured during plan-6) |
   | [ ] | T004 | Write test verifying .prompt.md extension requirement | Test | T003 | /abs/path/to/tests/test_copilot_extensions.sh | Test confirms all files have .prompt.md | [P] eligible (new test file) |
   | [ ] | T005 | Add validation that source .md files exist before copy | Core | T002 | /abs/path/to/install/agents.sh | Error handling for missing sources | Serial (shared file) |
   ```

   Notice how the Critical Finding:
   - Changed task T003 to explicitly reference the finding
   - Added task T004 to validate the finding's requirement
   - Informed the validation criteria (must end with .prompt.md)
   - Ensured traceability without pre-emptive footnote tags
   ```

   **Canonical tasks table layout** (all dossiers MUST follow this column order):
   | Status | ID | Task | Type | Dependencies | Absolute Path(s) | Validation | Notes |
   - `Status` is a literal checkbox column; start each row with `[ ]` so later phases can update to `[~]` (in progress) or `[x]` (complete).
   - `ID` uses the T001… dossier sequence and should link back to the matching plan task when applicable (e.g., in notes or alignment brief).
   - `Task` summarizes the work item with sufficient detail for implementation.
   - `Type` classifies it (Setup/Test/Core/Integration/Doc/etc.).
   - `Dependencies` lists prerequisite task IDs (e.g., "T001, T002") or "–" for none.
   - `Absolute Path(s)` must list every impacted file or directory using absolute paths (REQUIRED - no relative paths).
   - `Validation` captures how acceptance or readiness will be confirmed.
   - `Notes` include [P] guidance and contextual references, but defer `[^N]` footnote tags until plan-6 updates the ledger.

6) Write a single combined artifact `PHASE_DIR/tasks.md` containing:
   - Phase metadata (title, slug, links to SPEC and PLAN, today {{TODAY}}).
   - `## Tasks` section that renders the table exactly as defined above (Status checkbox first, then ID, Task, Type, Dependencies, Absolute Path(s), Validation, Notes) with numbered items (T001...), dependencies, [P] guidance, and validation checklist coverage.
   - `## Alignment Brief` section with:
     * Objective recap + behavior checklist (tie to PLAN acceptance criteria)
     * **Non-Goals (Scope Boundaries)**: Explicitly call out what this phase is **NOT** doing to prevent scope creep and keep implementation focused. Include:
       - Features/functionality deliberately excluded from this phase (but might be in future phases)
       - Edge cases or scenarios being deferred
       - Optimizations or polish that can wait
       - Refactoring or cleanup not required for acceptance
       - Alternative approaches explicitly rejected and why
       Example format:
       ```
       ❌ NOT doing in this phase:
       - Performance optimization (defer to Phase 5)
       - User-facing error messages (using generic messages for now)
       - Migration of legacy data (Phase 3 handles only new data)
       - Advanced caching (simple in-memory cache sufficient for now)
       ```
     * **Critical Findings Affecting This Phase**: List relevant discoveries from plan § 3 that impact this phase's implementation. For each, briefly note: the finding title, what it constrains/requires, and which tasks address it.
     * Invariants & guardrails (perf/memory/security budgets if relevant)
     * Inputs to read (exact file paths)
     * Visual alignment aids: capture both a Mermaid flow diagram (system states) and a Mermaid sequence diagram (actor/interaction order). Treat these as shared-understanding checkpoints so the human sponsor and coding agent agree on the flow before implementation begins.
     * **Test Plan (TDD vs lightweight per spec, honor mock usage preference)**: enumerate named tests with rationale, fixtures, expected outputs
     * Step-by-step implementation outline mapped 1:1 to the tasks/tests
     * Commands to run (copy/paste): env setup, test runner, linters, type checks
     * Risks/unknowns (flag severity, mitigation steps)
     * **Ready Check** (checkboxes) -> await explicit GO/NO-GO
   - `## Phase Footnote Stubs` section: include the heading and an empty table shell (or explicit note) so plan-6 can add entries post-implementation; do **not** create footnote tags or stubs during planning.
   - `## Evidence Artifacts` describing where implementation will write the execution log (`PHASE_DIR/execution.log.md`) and any supporting files.

7) Capture a short directory layout at the end of `PHASE_DIR/tasks.md` so future phases know where to place logs and ancillary evidence inside `PHASE_DIR`.
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
- Follow `docs/rules-idioms-architecture/{rules.md, idioms.md}` (TDD, tests-as-docs; apply the mock usage preference captured in the spec; use real data when required). :contentReference[oaicite:13]{index=13}
- Apply BridgeContext patterns when relevant: bounded `vscode.RelativePattern`, remote-safe `vscode.Uri`, Python debugging via `module: 'pytest'` with `--no-cov`. :contentReference[oaicite:14]{index=14}

STOP: Do **not** edit code. Output the combined `PHASE_DIR/tasks.md` and wait for human **GO**.
```

Why this shape: it leverages your existing **tasks** template mechanics but restricts scope firmly to **one phase**, and carries forward the alignment without the separate heavy analysis pass you asked to remove.

Next step (when happy): Run **/plan-6-implement-phase --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**.
