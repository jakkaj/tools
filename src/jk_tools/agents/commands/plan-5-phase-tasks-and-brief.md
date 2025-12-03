---
description: Use subagent to review previous phase execution (if applicable), then generate a combined `tasks.md` dossier (tasks + alignment brief) under the plan tree; stop before making code changes.
---

Please deep think / ultrathink as this is a complex task.

# plan-5-phase-tasks-and-brief

## Executive Briefing

**What this command does**: Generates a detailed implementation dossier (`tasks.md`) for a single phase, transforming high-level plan tasks into executable work items with full context.

**When to use**: After plan-3 has created the architectural plan with phases. Run once per phase, in order.

### Input → Output

```
INPUT:
  --phase "Phase 2: Core Implementation"
  --plan "/abs/path/docs/plans/3-feature-x/feature-x-plan.md"

OUTPUT:
  docs/plans/3-feature-x/tasks/phase-2-core-implementation/tasks.md
```

### Sample Output Structure

```markdown
# Phase 2: Core Implementation – Tasks & Alignment Brief

**Spec**: [feature-x-spec.md](../feature-x-spec.md)
**Plan**: [feature-x-plan.md](../feature-x-plan.md)
**Date**: 2024-01-15

## Tasks

| Status | ID   | Task                              | CS  | Type | Dependencies | Absolute Path(s)              | Validation                    | Subtasks | Notes              |
|--------|------|-----------------------------------|-----|------|--------------|-------------------------------|-------------------------------|----------|--------------------|
| [ ]    | T001 | Review existing handler structure | 1   | Setup| –            | /abs/path/src/handlers/       | Documented in brief           | –        | –                  |
| [ ]    | T002 | Write failing test for new API    | 2   | Test | T001         | /abs/path/tests/test_api.py   | Test fails with expected msg  | –        | –                  |
| [ ]    | T003 | Implement API endpoint            | 3   | Core | T002         | /abs/path/src/api/endpoint.py | Test passes, returns 200      | –        | Per Critical Disc 01|

## Alignment Brief

### Prior Phases Review
(Phase 1 deliverables, lessons learned, dependencies exported...)

### Objective
- Implement the core API endpoint per acceptance criteria AC-2, AC-3

### Non-Goals
❌ NOT doing in this phase:
- Performance optimization (defer to Phase 4)
- Advanced error messages (generic OK for now)

### Visual Aids
(Mermaid flow + sequence diagrams)

### Test Plan
- `test_api_returns_valid_response` – happy path
- `test_api_handles_missing_input` – error case

### Ready Check
- [ ] All tasks have absolute paths
- [ ] Critical findings addressed
- [ ] ADR constraints mapped (N/A if none)
```

### Key Transformations

| Plan-3 Task                    | Plan-5 Expansion                                      |
|--------------------------------|-------------------------------------------------------|
| `2.1: Implement API`           | T001 (Setup), T002 (Test), T003 (Core), T004 (Verify) |
| High-level success criteria    | Specific, measurable validation per task              |
| Implicit file paths            | Explicit absolute paths required                      |

---

**One phase at a time.** First use a **subagent to thoroughly review the previous phase** (if not Phase 1) including execution log, main plan, and critical findings. Then generate an actionable **tasks + alignment brief dossier** (`tasks.md`) for the chosen phase, plus the supporting directory structure, and stop before implementation. This merges your previous "tasks" generation with the pre-implementation walkthrough, scoped strictly to **one** phase. Treat the dossier as the shared contract between the human sponsor and the coding agent: lean on visual aids (e.g., Mermaid flow + sequence diagrams) to cement a cohesive understanding before touching code.

---

## 🚫 CRITICAL PROHIBITION: NO TIME ESTIMATES

**NEVER** output time or duration estimates in **ANY FORM**:
- ❌ Hours, minutes, days, weeks, months
- ❌ "Quick", "fast", "soon", "trivial duration"
- ❌ "ETA", "deadline", "timeline"
- ❌ "~4 hours", "2-3 days", "should take X time"
- ❌ "Total Estimated Effort: X hours/days"

**ONLY** use **Complexity Score (CS 1-5)** from constitution rubric:
- ✅ CS-1 (trivial): 0-2 complexity points
- ✅ CS-2 (small): 3-4 complexity points
- ✅ CS-3 (medium): 5-7 complexity points
- ✅ CS-4 (large): 8-9 complexity points
- ✅ CS-5 (epic): 10-12 complexity points

**Rubric factors** (each scored 0-2): Scope, Interconnections, Dependencies, Novelty, Fragility, Testing
Reference: `docs/rules-idioms-architecture/constitution.md` § 9

**Before outputting tasks.md, validate**: No time language present? All task estimates use CS 1-5 only?

---

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"

1) Verify PLAN exists; set PLAN_DIR = dirname(PLAN); define `PHASE_DIR = PLAN_DIR/tasks/${PHASE_SLUG}` and create it if missing (mkdir -p).

1a) **Subagent Review of All Prior Phases** (skip if Phase 1):
   - **Determine all prior phases**: Extract phase number from $PHASE (e.g., "Phase 4: Data Flows" → review Phases 1, 2, 3)
   - **MANDATORY**: Use the Task tool to launch subagents for comprehensive review
   - **Strategy**: Launch subagents **in parallel** (single message with multiple Task tool calls) to maximize efficiency. One subagent per prior phase.

   **Parallel Subagent Structure** (one subagent per prior phase):

   For each prior phase (Phase 1 through Phase N-1), launch a dedicated subagent with this template:

   **Subagent Template for Phase X Review**:
     "Review Phase X to understand its complete implementation, learnings, and impact on subsequent phases.

     **Read**:
     - `PLAN_DIR/tasks/${PHASE_X_SLUG}/tasks.md` (complete task table)
     - `PLAN_DIR/tasks/${PHASE_X_SLUG}/execution.log.md` (full implementation log)
     - `${PLAN}` § 8 Progress Tracking for Phase X
     - `${PLAN}` § 12 Change Footnotes related to Phase X
     - `${PLAN}` § 3 Critical Findings addressed in Phase X

     **Report** (structured as Phase X Review):
     A. **Deliverables Created**: Files, modules, classes, functions, APIs with absolute paths
     B. **Lessons Learned**: Deviations, complexity discovered, approaches that worked/failed
     C. **Technical Discoveries**: Gotchas, limitations, edge cases, constraints encountered
     D. **Dependencies Exported**: What this phase provides for later phases (signatures, APIs, data structures)
     E. **Critical Findings Applied**: Which discoveries were addressed and how (file:line refs)
     F. **Incomplete/Blocked Items**: Tasks not completed, reasons, implications
     G. **Test Infrastructure**: Tests, fixtures, mocks, helpers created
     H. **Technical Debt**: Shortcuts, TODOs, temporary solutions, refactoring needs
     I. **Architectural Decisions**: Patterns established, rationale, anti-patterns to avoid
     J. **Scope Changes**: Requirements changes, features added/removed
     K. **Key Log References**: Deep links to critical decisions in execution.log.md"

   - **Launch Strategy**:
     * If reviewing Phases 1-3 → Call Task tool 3 times in a single message (parallel)
     * If reviewing Phases 1-2 → Call Task tool 2 times in a single message (parallel)
     * Each subagent uses subagent_type="general-purpose"
     * Each subagent focuses on ONE complete prior phase
   - **Wait for All Subagents**: Block until all prior phase reviews complete
   - **Synthesize Cross-Phase Insights**: Combine all subagent outputs into a comprehensive review with:
     * **Phase-by-Phase Summary**: Sequential narrative showing evolution (Phase 1 → 2 → 3 → ...)
     * **Cumulative Deliverables**: All files, APIs, modules available to current phase (organized by phase of origin)
     * **Cumulative Dependencies**: Complete dependency tree from all prior phases
     * **Pattern Evolution**: How approaches/patterns evolved across phases
     * **Recurring Issues**: Technical debt or challenges that persisted across phases
     * **Cross-Phase Learnings**: Insights from comparing different phase approaches
     * **Foundation for Current Phase**: What the current phase builds upon from each prior phase
     * **Reusable Infrastructure**: All test fixtures, mocks, helpers from any prior phase
     * **Architectural Continuity**: Patterns to maintain vs. anti-patterns to avoid
     * **Critical Findings Timeline**: How discoveries influenced each phase's implementation
   - **Use Synthesized Results**: Let the combined subagent findings inform:
     * Task breakdown (know complete landscape of what exists across all phases)
     * Dependencies column (reference ANY prior phase's deliverables)
     * Validation criteria (avoid ALL discovered gotchas from any phase)
     * Non-goals (don't re-solve problems solved in ANY phase)
     * Test plan (reuse fixtures from ANY phase)
     * Architectural consistency (maintain patterns from ALL phases)

2) **Read Critical Research Findings** from the PLAN document:
   - Locate section "## 3. Critical Research Findings" or similar heading in the plan
   - Study each numbered discovery (🚨 Critical Discovery 01, 02, 03...)
   - Note the structure: Problem, Root Cause, Solution, Impact on architecture/design
   - Identify which findings affect the current phase's implementation
   - These findings MUST inform task design, implementation approach, and validation strategies
   - Critical findings often reveal API limitations, framework requirements, or implementation constraints that change how tasks should be structured
   - Reference discoveries by number when applicable (e.g., "per Critical Discovery 02")

2a) **Read ADRs (if any)** from `docs/adr/` that reference this spec/plan:
   - Scan docs/adr/ for ADRs containing references to the current feature (by slug or spec path)
   - For each relevant ADR, extract:
     * ADR ID (NNNN) and title
     * Status (Proposed/Accepted/Rejected/Superseded)
     * The Decision (one-line summary)
     * Specific constraints that affect this phase
   - These ADR constraints MUST be incorporated into task design
   - Tag affected tasks in the Notes column with ADR IDs (e.g., "Per ADR-0007")

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
   | [ ] | T001 | Review existing copy loop in agents.sh | Setup | – | /abs/path/to/install/agents.sh | Understand extension handling | – |
   | [ ] | T002 | Implement copy loop for command files to Copilot global dir | Core | T001 | /abs/path/to/install/agents.sh | All .md files copied | – |
   | [ ] | T003 | Add .prompt.md extension during copy (per Critical Discovery 01) | Core | T002 | /abs/path/to/install/agents.sh | Files end with .prompt.md | Per Critical Discovery 01 |
   | [ ] | T004 | Write test verifying .prompt.md extension requirement | Test | T003 | /abs/path/to/tests/test_copilot_extensions.sh | Test confirms all files have .prompt.md | – |
   | [ ] | T005 | Add validation that source .md files exist before copy | Core | T002 | /abs/path/to/install/agents.sh | Error handling for missing sources | – |
   ```

   Notice how the Critical Finding:
   - Changed task T003 to explicitly reference the finding
   - Added task T004 to validate the finding's requirement
   - Informed the validation criteria (must end with .prompt.md)
   ```

   **Canonical tasks table layout** (all dossiers MUST follow this column order):
   | Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Subtasks | Notes |
   - `Status` is a literal checkbox column; start each row with `[ ]` so later phases can update to `[~]` (in progress) or `[x]` (complete).
   - `ID` uses the T001… dossier sequence and should link back to the matching plan task when applicable (e.g., in notes or alignment brief).
   - `Task` summarizes the work item with sufficient detail for implementation.
   - `CS` is the Complexity Score (1-5) computed from constitution rubric: CS-1 (trivial), CS-2 (small), CS-3 (medium), CS-4 (large), CS-5 (epic). Score each task using S,I,D,N,F,T factors (0-2 each).
   - `Type` classifies it (Setup/Test/Core/Integration/Doc/etc.).
   - `Dependencies` lists prerequisite task IDs (e.g., "T001, T002") or "–" for none.
   - `Absolute Path(s)` must list every impacted file or directory using absolute paths (REQUIRED - no relative paths).
   - `Validation` captures how acceptance or readiness will be confirmed.
   - `Subtasks` lists spawned subtask dossiers (e.g., "001-subtask-fixtures, 003-subtask-bulk") or "–" for none. Updated by plan-5a when subtask is created.
   - `Notes` include contextual references (e.g., ADR IDs, Critical Finding refs), but defer `[^N]` footnote tags until plan-6 updates the ledger.

6) Write a single combined artifact `PHASE_DIR/tasks.md` containing:
   - Phase metadata (title, slug, links to SPEC and PLAN, today {{TODAY}}).
   - `## Tasks` section that renders the table exactly as defined above (Status checkbox first, then ID, Task, CS, Type, Dependencies, Absolute Path(s), Validation, Subtasks, Notes) with numbered items (T001...), complexity scores, dependencies, and validation checklist coverage.
   - `## Alignment Brief` section with:
     * **Prior Phases Review** (if not Phase 1):
       - Include the complete cross-phase synthesis from step 1a here
       - Ensure it covers:
         • Phase-by-phase summary showing evolution of the implementation
         • Cumulative deliverables from all prior phases (organized by phase of origin)
         • Complete dependency tree across all phases
         • Pattern evolution and architectural continuity
         • Recurring issues and cross-phase learnings
         • All reusable test infrastructure from any prior phase
         • Critical findings timeline showing how discoveries influenced each phase
       - For each prior phase, cover sections A-K: deliverables created, lessons learned, technical discoveries, dependencies exported, critical findings applied, incomplete items, test infrastructure, technical debt, architectural decisions, scope changes, and key log references
       - Include deep links to all prior phase execution logs for critical decisions
       - Reference specific footnotes from plan § 12 that affected architecture or design across phases
       - This section provides essential context for understanding the complete landscape of what exists and what the current phase builds upon
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
     * **ADR Decision Constraints** (if ADRs exist):
       - List each relevant ADR: `ADR-NNNN: [Title] – [Decision one-liner]`
       - Note specific constraints from the ADR that affect this phase
       - Map constraints to specific tasks: "Constrains: [items]; Addressed by: [T00X, T00Y]"
       - Tag affected task rows in the Notes column with "Per ADR-NNNN"
     * Invariants & guardrails (perf/memory/security budgets if relevant)
     * Inputs to read (exact file paths)
     * Visual alignment aids: capture both a Mermaid flow diagram (system states) and a Mermaid sequence diagram (actor/interaction order). Treat these as shared-understanding checkpoints so the human sponsor and coding agent agree on the flow before implementation begins.
     * **Test Plan (TDD vs lightweight per spec, honor mock usage preference)**: enumerate named tests with rationale, fixtures, expected outputs
     * Step-by-step implementation outline mapped 1:1 to the tasks/tests
     * Commands to run (copy/paste): env setup, test runner, linters, type checks
     * Risks/unknowns (flag severity, mitigation steps)
     * **Ready Check** (checkboxes) -> await explicit GO/NO-GO
       - [ ] ADR constraints mapped to tasks (IDs noted in Notes column) - N/A if no ADRs exist
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
