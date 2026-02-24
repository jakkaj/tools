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

## MODE DETECTION

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

   The flight plan MUST include these sections (plan-5b generates them):
   - **Departure → Destination**: Where we are now, where we're going (concrete outcomes)
   - **Domain Context**: Domains we're changing (create/modify) with overview of changes and key files, AND domains we depend on (consume) with which contracts we use
   - **Flight Status**: Mermaid state diagram showing task progression
   - **Stages**: Checkbox list of tasks in plain English
   - **Architecture: Before & After**: Mermaid diagram showing system before/after this phase
   - **Acceptance Criteria**: What "done" looks like
   - **Goals & Non-Goals**: Scope boundaries
   - **Checklist**: Task IDs with CS scores

   If the flight plan comes back without Departure→Destination or Domain Context, it's incomplete — regenerate.

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
```

Next step: Run **/plan-6-v2-implement-phase --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**
