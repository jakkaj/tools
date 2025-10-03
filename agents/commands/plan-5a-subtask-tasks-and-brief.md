---
description: Derive a subtask-scoped tasks + alignment brief dossier that augments an existing phase without creating a new plan.
---

Please deep think / ultrathink as this is a nuanced extension of plan-5 outputs.

# plan-5a-subtask-tasks-and-brief

Generate an actionable **subtask dossier** alongside the parent phase's `tasks.md`. Use this when a request needs structured planning but stays within an approved phase. Produce a self-contained markdown file named `PHASE_DIR/<ordinal>-subtask-<slug>.md` and stop before any implementation.

```md
User input:

$ARGUMENTS
# Required flag:
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"
# Optional flags:
# --phase "<Phase N: Title>"      # infer if omitted (see below)
# --ordinal "NNN"                 # override next subtask ordinal when you must align with pre-created shells
# Trailing argument (positional):  # summary/title for this subtask request
#   e.g., "Generate integration fixtures for bulk import API"

1) Resolve paths & derive identifiers:
   - PLAN      = provided --plan; abort if missing.
   - PLAN_DIR  = dirname(PLAN).
   - If --phase supplied, match exact heading within PLAN; else infer:
     * scan PLAN_DIR/tasks/* for `tasks.md`; if exactly one `phase-*` contains the most recent GO, adopt it.
     * if multiple phases are eligible, stop and request explicit `--phase`.
   - PHASE_SLUG from phase heading (same slug plan-5 uses).
   - PHASE_DIR = PLAN_DIR/tasks/${PHASE_SLUG}; ensure exists (mkdir -p allowed here).
   - SUBTASK_SUMMARY = trailing argument trimmed; err if empty.
   - SUBTASK_SLUG = kebab-case summary (`[^a-z0-9-]` → '-', collapse dups, trim dash).
   - Determine ordinal:
     * Existing files matching `${PHASE_DIR}/[0-9][0-9][0-9]-subtask-*.md` → take highest NNN.
     * ORD = --ordinal if provided else highest+1 (zero-pad to 3 digits; start at `001`).
   - SUBTASK_FILE = `${PHASE_DIR}/${ORD}-subtask-${SUBTASK_SLUG}.md`.
   - SUBTASK_LOG  = `${PHASE_DIR}/${ORD}-subtask-${SUBTASK_SLUG}.execution.log.md`.

2) Parse parent context:
   - Load PLAN to review:
     * `## 3. Critical Research Findings` (as in plan-5 step 2).
     * The chosen phase heading and its task table (plan-3 output).
     * Any Ready/GO markers or guardrails relevant to subtasks.
   - Load `PHASE_DIR/tasks.md` (if missing, abort; subtask requires existing phase dossier).
   - Collect parent dossier metadata: objective, invariants, diagrams, ready check, etc. Note references to reuse or narrow scope.

3) Define subtask linkage:
   - Identify which parent task(s) (T001… from phase dossier) the subtask supports. Capture IDs and plan-table coordinates (e.g., phase task `2.3`).
   - Confirm subtask scope stays within existing phase acceptance criteria; if not, halt.

4) Content expectations for `${SUBTASK_FILE}` (mirror plan-5 layout, scoped to subtask):
   - Front matter: title = `Subtask <ORD>: <Summary>`; include parent phase + plan links; record today as {{TODAY}}.
   - `## Subtask Metadata` table with:
     * Parent Plan, Parent Phase, Parent Task(s) (T-IDs + plan table refs), Subtask Summary, Requested By (default "Human Sponsor"), Created {{NOW}}.
   - `## Tasks` table using canonical columns
     | Status | ID | Task | Type | Dependencies | Absolute Path(s) | Validation | Notes |
     * Use IDs `ST001`, `ST002`, … (serial, reflect mapping to parent T-ID in Notes like "Supports T003 [^1]").
     * Dependencies reference other ST IDs (and optionally parent T-IDs in Notes).
     * Absolute paths remain mandatory (absolute); include parent dossier paths if reused.
     * Notes end with footnote placeholders for every code-touching task.
   - `## Alignment Brief` tailored to the subtask:
     * Objective recap referencing parent phase goal + targeted parent tasks.
     * Checklist derived from parent acceptance criteria, highlighting deltas introduced by this subtask.
     * **Critical Findings Affecting This Subtask**: cite relevant discoveries (same structure as plan-5).
     * Invariants/guardrails inherited from parent + any new subtasks constraints.
     * Inputs to read (files, specs, existing artifacts).
     * Visual aids: at least one Mermaid flow diagram + one sequence diagram focusing on this subtask slice; condense actors to keep clarity while aligning with parent diagrams.
     * Test Plan: enumerate tests specific to this subtask (TDD vs lightweight align with parent instructions).
     * Implementation outline: map steps 1:1 to ST tasks + tests.
     * Commands to run, focused on this subtask (linters/tests/etc.).
     * Risks & unknowns with mitigations.
     * Ready Check (checkbox list) gating `/plan-6-implement-phase` or `/plan-6-implement-phase --subtask` usage.
   - `## Phase Footnote Stubs` table listing placeholder descriptions keyed by footnote tags used in Tasks.
   - `## Evidence Artifacts` describing:
     * `execution.log.md` path = `${ORD}-subtask-${SUBTASK_SLUG}.execution.log.md`.
     * Any directories/files for artifacts (tests, fixtures, diagrams exports, etc.).
   - Trailing directory sketch showing `PHASE_DIR` contents including subtask file + execution log (note that plan-6 writes the log, plan-6a updates both plan + subtask).

5) Safeguards & consistency:
   - Do **not** duplicate tasks already captured in `tasks.md`; instead refine them into ST tasks or note shared dependencies.
   - Respect BridgeContext patterns, repo rules, and mock preferences identical to plan-5 (cite `docs/rules-idioms-architecture/*`).
   - Highlight any cross-file parallelism opportunities with `[P]` in Notes, consistent with parent dossier policy.
   - Ensure the Ready Check and commands reference invoking `/plan-6-implement-phase` with `--subtask ${ORD}-subtask-${SUBTASK_SLUG}`.
   - Do **not** touch code or update logs; stop after writing `${SUBTASK_FILE}`.

6) Output:
   - Write `${SUBTASK_FILE}` using ASCII; maintain markdown table alignment.
   - If `${SUBTASK_LOG}` already exists (prior runs), leave untouched but mention it in Evidence Artifacts; otherwise note that plan-6 will create it.
   - Provide a concise summary of parent linkage at the end (e.g., "Supports T003 in Phase 4").

STOP once the subtask dossier is generated. Await human GO before implementation.
```

Why this exists: Subtasks add structured planning for mid-phase branches without exploding the main dossier. They inherit critical context while allowing fine-grained execution tracking.
