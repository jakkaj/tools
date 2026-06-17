# tasks

> Sub-skill — part of a verb library. Knows nothing about any flow:
> no stage ids, no successor/predecessor names, no flow commands.
> Composition is the bundling flow's job.

**Verb**: tasks
**Purpose**: Generate an actionable tasks + context brief dossier for exactly one phase (or a subtask / lightweight tracked fix), then stop before any code changes.
**Consumes**: a plan (Full Mode, typically `**Status**: READY` from the architect verb) with the target phase identified; the plan's task table, Key Findings, Domain Manifest, prior-phase dossiers and execution logs. Subtask mode additionally needs a parent task ID; fix mode needs only a summary (`--plan` optional).
**Flags**: `--phase "<Phase N: Title>"` + `--plan "<abs path to plan.md>"`; optional subtask mode `--subtask "<summary>" --parent "T###"`; optional fix mode `--fix "<summary>"` / `--from-review "<abs path>"` / `--fix --list`
**Produces**: `PLAN_DIR/tasks/<phase-slug>/tasks.md` (Executive Briefing, Prior Phase Context, Pre-Implementation Check, Architecture Map, canonical 7-column Tasks table, Context Brief, Discoveries & Learnings) — or a subtask dossier `<ORD>-subtask-<slug>.md`, or a fix dossier `FX###-<slug>.md` + empty execution log. STOPS before implementation; terminal report = dossier path + wait for human GO.
**Side effects**: none

---

## Procedure

Generate an actionable **tasks + context brief dossier** for one phase, then stop before implementation. Features 7-column task table with Domain column, focused prior-phase review, simplified audit, and Context Brief with diagrams.

---

> Complexity: CS 1–5 only — no time estimates (rubric: `references/00-routing.md` § Shared conventions).

---

### Input → Output

```
INPUT:
  --phase "Phase 2: Core Implementation"
  --plan "/abs/path/docs/plans/3-feature-x/feature-x-plan.md"

OUTPUT:
  docs/plans/3-feature-x/tasks/phase-2-core-implementation/tasks.md
```

---

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --plan "<abs path to plan.md>"
#
# Subtask mode (optional):
# --subtask "<summary>"
# --parent "T003"
#
# Fix mode (optional):
# --fix "<summary>"               # Activates fix mode — lightweight tracked fix
# --from-review "<abs path>"      # Load fixes from the review verb's fix-tasks.md
# --fix --list                    # List existing fixes

## MODE DETECTION

If `--fix` provided → **Fix Mode** (jump to Fix section below).
If `--subtask` provided → **Subtask Mode** (jump to Subtask section below).
Otherwise → **Phase Mode** (continue).

---

## PHASE MODE

1) Verify PLAN exists; set PLAN_DIR = dirname(PLAN); define PHASE_DIR = PLAN_DIR/tasks/${PHASE_SLUG}; create if missing.

2) **Prior Phase Review** (skip if Phase 1):

   Determine all prior phases. Launch **parallel subagents** (one per prior phase) with this focused template:

   "Review Phase X implementation. Read:
   - `PLAN_DIR/tasks/${PHASE_X_SLUG}/tasks.md`
   - `PLAN_DIR/tasks/${PHASE_X_SLUG}/execution.log.md`
   - Plan progress tracking for Phase X

   Report these 5 sections ONLY:

   A. **Deliverables**: Files, modules, APIs created (absolute paths)
   B. **Dependencies Exported**: Signatures, interfaces, data structures available for later phases
   C. **Gotchas & Debt**: Edge cases, technical debt, things that didn't work as expected
   D. **Incomplete Items**: Tasks not completed, blockers carrying forward
   E. **Patterns to Follow**: Established patterns, architectural decisions, anti-patterns to avoid"

   Wait for all subagents. Synthesize into Prior Phase Context section.

3) **Read the plan's task table** (from the architect verb) for this phase. Transform and expand into detailed tasks:
   - Plan tasks (e.g., "2.1") become detailed tasks (T001, T002...)
   - Apply Key Findings from plan — reference specific findings in Notes
   - Every task gets a Domain from the plan's Domain Manifest

4) **Pre-Implementation Check**:
   Quick check for each file in the task table:

   | File | Exists? | Domain Check | Notes |
   |------|---------|-------------|-------|

   - Does the file exist? (create vs modify)
   - Is it in the correct domain's source tree?
   - For major new concepts, check for duplication: scan `docs/domains/*/domain.md` § Concepts tables first, then search the source
   - Flag contract changes (higher risk)

5) **Write tasks.md** containing:

   ### Executive Briefing
   - **Purpose**: 2-3 sentences — what this phase delivers and why
   - **What We're Building**: Concrete description
   - **Goals**: ✅ bullet list
   - **Non-Goals**: ❌ what this phase is NOT doing

   ### Prior Phase Context
   [From step 2 — 5 sections per completed phase]

   ### Pre-Implementation Check
   [From step 4 — quick table]

   ### Architecture Map
   Mermaid diagram showing components and their relationships:

   ```mermaid
   flowchart TD
       classDef pending fill:#9E9E9E,stroke:#757575,color:#fff
       classDef completed fill:#4CAF50,stroke:#388E3C,color:#fff

       subgraph Phase["Phase N: [Title]"]
           T001["T001: [Task]"]:::pending
           T002["T002: [Task]"]:::pending
           T001 --> T002
       end

       subgraph Files["Files"]
           F1["/path/to/file"]:::pending
       end

       T001 -.-> F1
   ```

   ### Tasks

   **Canonical 7-column format** (all dossiers MUST use this):

   | Status | ID | Task | Domain | Path(s) | Done When | Notes |
   |--------|-----|------|--------|---------|-----------|-------|
   | [ ] | T001 | [What to build] | [domain] | /abs/path | [Success criteria] | |

   - `Status`: `[ ]` pending, `[~]` in progress, `[x]` complete, `[!]` blocked
   - `ID`: T001, T002... sequence
   - `Task`: What to build — enough detail for implementation
   - `Domain`: Which domain this task delivers into
   - `Path(s)`: Absolute paths to files touched
   - `Done When`: Plain language success criteria
   - `Notes`: Finding references, domain constraints, etc.

   ### Context Brief

   **Key findings from plan**:
   - [Finding N: brief + action required]

   **Domain dependencies** (concepts and contracts this phase consumes — from `docs/domains/*/domain.md`):
   - `[domain]`: [Concept Name] ([entry point]) — [what we use it for]
   - Example: `_platform/events`: File change subscription (useFileChanges) — live file updates in tree
   - Example: `_platform/state`: Read single state value (useGlobalState) — workflow status display
   - Example: `auth`: User authentication (IAuthService.authenticate()) — verify user before processing

   **Domain constraints**:
   - [Import rules, dependency direction, contract boundaries]

   **Reusable from prior phases**:
   - [Test fixtures, helpers, patterns available]

   **Mermaid flow diagram** (system states):
   ```mermaid
   flowchart LR
       A[Input] --> B[Process] --> C[Output]
   ```

   **Mermaid sequence diagram** (actor interactions):
   ```mermaid
   sequenceDiagram
       Actor->>Service: request
       Service->>Repository: query
       Repository-->>Service: result
       Service-->>Actor: response
   ```

   ### Discoveries & Learnings

   _Populated during implementation by the implement verb._

   | Date | Task | Type | Discovery | Resolution | References |
   |------|------|------|-----------|------------|------------|

   **Types**: `gotcha` | `research-needed` | `unexpected-behavior` | `workaround` | `decision` | `debt` | `insight`

6) Capture directory layout at end of tasks.md:
   ```
   docs/plans/<ordinal>-<slug>/
     ├── <slug>-plan.md
     └── tasks/phase-N/
         ├── tasks.md
         └── execution.log.md   # created by the implement verb
   ```

STOP: Do NOT edit code. Output tasks.md and wait for human GO.

---

## SUBTASK MODE

Activated when `--subtask` is provided. Focused subtask dossier alongside parent phase.

S1) Resolve paths:
   - PLAN, PLAN_DIR, PHASE_DIR from flags
   - SUBTASK_SLUG = kebab-case summary
   - ORD = next ordinal (001, 002...)
   - SUBTASK_FILE = `${PHASE_DIR}/${ORD}-subtask-${SUBTASK_SLUG}.md`

S2) Parse parent context:
   - Load plan key findings
   - Load parent tasks.md, locate PARENT_TASK row

S3) Define subtask tasks:
   - Break down into ST001, ST002... using same 7-column format
   - Notes reference parent T-ID

S4) Pre-Implementation Check (scoped to subtask files only)

S5) Write subtask dossier containing:
   - Parent Context (phase, task, why this subtask)
   - Executive Briefing (scoped to subtask)
   - Pre-Implementation Check
   - Architecture Map (parent task as blocked node, subtask nodes, "unblocks" edge)
   - Tasks table (ST### rows)
   - Context Brief (scoped)
   - Discoveries & Learnings (empty table)
   - After Subtask Completion (resumption guide)

S6) Register subtask in plan's Subtasks Registry (create section if missing)

S7) Update parent task's Notes in tasks.md to reference subtask

STOP: Do NOT edit code. Output subtask dossier and wait for human GO.

---

## FIX MODE

Activated when `--fix` is provided. Generates a lightweight, tracked fix dossier — smaller than a subtask, with its own execution log. For small, scoped work that still needs domain awareness, approval, and posterity.

### Fix vs Subtask vs Phase

| | Fix | Subtask | Phase |
|---|---|---|---|
| Size | 1-5 tasks | 3-10 tasks | 5-20 tasks |
| Needs plan? | Optional | Yes | Yes |
| Execution log? | Yes | Yes | Yes |
| Code review? | Yes | Yes | Yes |

### When to Use

- Bug fix (1-3 files)
- Addressing review-verb findings
- Small enhancement within an existing domain
- Quick refactor with clear scope
- Config/documentation fix that needs tracking

### When NOT to Use

- Touches 5+ domains → use a phase
- Changes domain contracts → use a phase
- Needs research/discovery → use a plan

### Fix Flow

F1) Resolve paths:
   - If `--fix --list`: show existing fixes and exit
   - If --plan provided: FIX_DIR = PLAN_DIR/fixes/
   - If standalone (no --plan): FIX_DIR = docs/fixes/
   - Create FIX_DIR if missing
   - FIX_ORD = next available FX### ordinal (scan existing FX*.md files)
   - FIX_SLUG = kebab-case summary
   - FIX_FILE = ${FIX_DIR}/FX${ORD}-${FIX_SLUG}.md

F2) If `--from-review` provided:
   - Read the fix-tasks file from the review verb's output
   - Present fix tasks to user
   - User selects which to address (may group related items)
   - Use selected items to populate Problem and Tasks sections

F3) Load domain context:
   - Load domain context per `references/00-routing.md` § Domain context loading
   - Identify which domains this fix touches
   - If fix affects domain contracts → flag as higher risk in the dossier

F4) Quick codebase check:
   - Read the files that will be changed — verify they exist and belong to expected domains
   - NO full pre-implementation audit (too heavy for a fix)
   - NO prior-phase review (fixes are self-contained)

F5) Check for relevant workshops:
   - If --plan exists, check PLAN_DIR/workshops/ for relevant workshops
   - Note any consumed workshops in the dossier

F6) Write fix dossier (FIX_FILE):

```markdown
# Fix FX[ORD]: [Summary]

**Created**: [today]
**Status**: Proposed
**Plan**: [link to parent plan, or "Standalone"]
**Source**: [what prompted this — review finding ID, bug report, user request]
**Domain(s)**: [domains touched with relationship]

---

## Problem

[2-3 sentences: What's broken or missing? Why does it matter?]

## Proposed Fix

[2-5 sentences: What will be changed and how?]

## Domain Impact

| Domain | Relationship | What Changes |
|--------|-------------|-------------|

## Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | FX[ORD]-1 | [task] | [domain] | [/abs/path] | [criteria] | |

## Workshops Consumed

[Links to relevant workshops, or "None"]

## Acceptance

- [ ] [testable criterion]

## Discoveries & Learnings

_Populated during implementation._

| Date | Task | Type | Discovery | Resolution |
|------|------|------|-----------|------------|
```

F7) Create empty execution log:
   ${FIX_DIR}/FX${ORD}-${FIX_SLUG}.log.md

F8) Register fix in parent plan (if --plan provided):
   - Check for `## Fixes` section in plan
   - If missing, append it:
     ```markdown
     ## Fixes

     | ID | Created | Summary | Domain(s) | Status | Source |
     |----|---------|---------|-----------|--------|--------|
     ```
   - Add row for this fix

STOP: Output fix dossier. Wait for user **APPROVE** before implementation.

### After Approval

The fix dossier travels by artifact: the **implement** verb consumes it via its `--fix "FX001"` flag (with or without `--plan`), implements the tasks, updates the execution log, updates domain.md/domain-map.md if needed, and marks the fix Complete. The **review** verb then re-checks it via its own `--fix "FX001"` flag — same subagents scoped to fix files, validates domain compliance, produces review with handover brief.
```

---

## Exit

Print the output-contract summary (✅ block: what was produced, where, key fields — then wait for human GO). Then STOP. Do not name a next stage. If invoked standalone, end with exactly: "Routing is the flow's job — run the parent flow bare to continue."
