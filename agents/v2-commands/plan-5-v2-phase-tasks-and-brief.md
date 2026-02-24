---
description: Generate a tasks dossier (tasks + context brief) for a phase under the plan tree; stop before making code changes. V2 standalone rewrite with domain awareness and lean output.
---

Please deep think / ultrathink as this is a complex task.

# plan-5-v2-phase-tasks-and-brief

Generate an actionable **tasks + context brief dossier** for one phase, then stop before implementation. Features 7-column task table with Domain column, focused prior-phase review, simplified audit, and Context Brief with diagrams.

---

## 🚫 NO TIME ESTIMATES — Use CS 1-5 only.

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
# --from-review "<abs path>"      # Load fixes from plan-7-v2 fix-tasks.md
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

3) **Read plan-3 task table** for this phase. Transform and expand into detailed tasks:
   - Plan-3 tasks (e.g., "2.1") become detailed tasks (T001, T002...)
   - Apply Key Findings from plan — reference specific findings in Notes
   - Every task gets a Domain from the plan's Domain Manifest

4) **Pre-Implementation Check**:
   Quick check for each file in the task table:

   | File | Exists? | Domain Check | Notes |
   |------|---------|-------------|-------|

   - Does the file exist? (create vs modify)
   - Is it in the correct domain's source tree?
   - Run `/code-concept-search` for major new concepts to check for duplication
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

   **Domain dependencies** (contracts this phase consumes — from `docs/domains/domain-map.md`):
   - `[domain]`: [contract name] — [what we use it for]
   - Example: `_platform`: ILogger — logging throughout new service
   - Example: `auth`: IAuthService.authenticate() — verify user before processing

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

   _Populated during implementation by plan-6._

   | Date | Task | Type | Discovery | Resolution | References |
   |------|------|------|-----------|------------|------------|

   **Types**: `gotcha` | `research-needed` | `unexpected-behavior` | `workaround` | `decision` | `debt` | `insight`

6) **Generate Flight Plan**: Run `/plan-5b-flightplan --phase "${PHASE}" --plan "${PLAN}"`

   The flight plan MUST follow this exact format (if plan-5b produces something different, fix it):

   ```markdown
   # Flight Plan: Phase N — [Title]

   **Plan**: [relative link to plan.md]
   **Phase**: Phase N: [Title]
   **Generated**: [today]
   **Status**: Ready for takeoff

   ---

   ## Departure → Destination

   **Where we are**: [Concrete description of current state — what exists from prior phases]

   **Where we're going**: [Concrete outcome — "A developer can...", "The system will..."]

   ---

   ## Domain Context

   ### Domains We're Changing

   | Domain | What Changes | Key Files |
   |--------|-------------|-----------|
   | [domain] | [summary of changes] | [key file paths] |

   ### Domains We Depend On (no changes)

   | Domain | What We Consume | Contract |
   |--------|----------------|----------|
   | [domain] | [what we use] | [contract name] |

   ---

   ## Flight Status

   <!-- Updated by /plan-6-v2: pending → active → done. Use blocked for problems/input needed. -->

   ```mermaid
   stateDiagram-v2
       classDef pending fill:#9E9E9E,stroke:#757575,color:#fff
       classDef active fill:#FFC107,stroke:#FFA000,color:#000
       classDef done fill:#4CAF50,stroke:#388E3C,color:#fff
       classDef blocked fill:#F44336,stroke:#D32F2F,color:#fff

       state "1: [Short label]" as S1
       state "2: [Short label]" as S2
       state "3: [Short label]" as S3

       [*] --> S1
       S1 --> S2
       S2 --> S3
       S3 --> [*]

       class S1,S2,S3 pending
   ```

   **Legend**: grey = pending | yellow = active | red = blocked/needs input | green = done

   ---

   ## Stages

   <!-- Updated by /plan-6-v2 during implementation: [ ] → [~] → [x] -->

   - [ ] **Stage 1: [Action phrase]** — [one sentence] (`affected-file.ts`)
   - [ ] **Stage 2: [Action phrase]** — [one sentence] (`new-file.ts` — new file)
   - [ ] **Stage 3: [Action phrase]** — [one sentence]

   ---

   ## Architecture: Before & After

   ```mermaid
   flowchart LR
       classDef existing fill:#E8F5E9,stroke:#4CAF50,color:#000
       classDef changed fill:#FFF3E0,stroke:#FF9800,color:#000
       classDef new fill:#E3F2FD,stroke:#2196F3,color:#000

       subgraph Before["Before Phase N"]
           B1[Component]:::existing
       end

       subgraph After["After Phase N"]
           A1[Component]:::existing
           A2[New Component]:::new
           A1 --> A2
       end
   ```

   **Legend**: existing (green, unchanged) | changed (orange, modified) | new (blue, created)

   ---

   ## Acceptance Criteria

   - [ ] [Testable criterion]

   ## Goals & Non-Goals

   **Goals**: [bullet list]
   **Non-Goals**: [bullet list]

   ---

   ## Checklist

   - [ ] T001: [Task description]
   - [ ] T002: [Task description]
   ```

   **CRITICAL**: The Flight Status Mermaid diagram MUST use `stateDiagram-v2` with exactly four classDefs (pending/active/done/blocked). Plan-6-v2 updates these classes as it works through tasks — this is how the user tracks live progress. If the flight plan doesn't have this diagram, regenerate it.

   If the flight plan comes back without Departure→Destination, Domain Context, or Flight Status Mermaid, it's incomplete — regenerate.

7) Capture directory layout at end of tasks.md:
   ```
   docs/plans/<ordinal>-<slug>/
     ├── <slug>-plan.md
     └── tasks/phase-N/
         ├── tasks.md
         ├── tasks.fltplan.md
         └── execution.log.md   # created by plan-6
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

S6) Generate Flight Plan for subtask

S7) Register subtask in plan's Subtasks Registry (create section if missing)

S8) Update parent task's Notes in tasks.md to reference subtask

STOP: Do NOT edit code. Output subtask dossier and wait for human GO.

---

## FIX MODE

Activated when `--fix` is provided. Generates a lightweight, tracked fix dossier — smaller than a subtask, with its own flight plan and execution log. For small, scoped work that still needs domain awareness, approval, and posterity.

### Fix vs Subtask vs Phase

| | Fix | Subtask | Phase |
|---|---|---|---|
| Size | 1-5 tasks | 3-10 tasks | 5-20 tasks |
| Needs plan? | Optional | Yes | Yes |
| Flight plan? | Yes (mini) | Yes | Yes |
| Execution log? | Yes | Yes | Yes |
| Code review? | Yes | Yes | Yes |

### When to Use

- Bug fix (1-3 files)
- Addressing plan-7-v2 review findings
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
   - Read the fix-tasks file from plan-7-v2 review
   - Present fix tasks to user
   - User selects which to address (may group related items)
   - Use selected items to populate Problem and Tasks sections

F3) Load domain context:
   - Read `docs/domains/registry.md` and `docs/domains/domain-map.md` (if exist)
   - Identify which domains this fix touches
   - Read relevant `docs/domains/<slug>/domain.md` for contracts and composition
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

F7) Generate mini flight plan:
   Write ${FIX_DIR}/FX${ORD}-${FIX_SLUG}.fltplan.md:

```markdown
# Flight Plan: Fix FX[ORD] — [Summary]

**Fix**: [link to fix dossier]
**Status**: Ready

## What → Why

**Problem**: [one sentence]
**Fix**: [one sentence]

## Domain Context

| Domain | Relationship | What Changes |
|--------|-------------|-------------|

## Stages

- [ ] [stage 1]
- [ ] [stage 2]

## Acceptance

- [ ] [criterion]
```

F8) Create empty execution log:
   ${FIX_DIR}/FX${ORD}-${FIX_SLUG}.log.md

F9) Register fix in parent plan (if --plan provided):
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

```bash
# Implement
/plan-6-v2-implement-phase --fix "FX001" --plan "<PLAN_PATH>"
# or standalone:
/plan-6-v2-implement-phase --fix "FX001"

# Review
/plan-7-v2-code-review --fix "FX001" --plan "<PLAN_PATH>"
```

plan-6-v2 reads the fix dossier, implements tasks, updates execution log, updates domain.md/domain-map.md if needed, marks fix Complete.

plan-7-v2 reviews the fix — same subagents scoped to fix files, validates domain compliance, produces review with handover brief.
```

Next step: Run **/plan-6-v2-implement-phase --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**
