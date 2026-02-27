---
description: Implement exactly one approved phase or subtask using the testing approach from the plan, with domain placement rules. V2 standalone rewrite.
---

Please deep think / ultrathink as this is a complex task.

# plan-6-v2-implement-phase

Implement **exactly one** approved phase or subtask using the **testing approach from the plan**. Apply domain placement rules. Update domain.md files after implementation.

---

## 📝 LOG DISCOVERIES AS YOU GO

Throughout implementation, capture discoveries in:
1. **Execution Log** (`execution.log.md`) — detailed narrative
2. **Discoveries Table** (`## Discoveries & Learnings` in tasks.md or plan) — structured record

Log when you encounter: something unexpected, needed research, hit a trouble spot, found a gotcha, made a decision, introduced debt, or gained an insight.

---

## 🛑 MANDATORY: UPDATE PROGRESS AFTER EVERY TASK — NO EXCEPTIONS

The user watches the flight plan for live progress. Updating it is **highest priority**.

After EACH task you MUST update these locations before proceeding to the next task:

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Per-Task Progress Checklist — use this EVERY time, NO EXCEPTIONS      ┃
┃                                                                       ┃
┃ STARTING T00X:                                                        ┃
┃ [ ] Tasks Table: [ ] → [~]                                            ┃
┃ [ ] Architecture Map: T00X node → :::inprogress (orange)              ┃
┃ [ ] Flight Plan § Stages: matching stage [ ] → [~]                    ┃
┃ [ ] Flight Plan § Flight Status Mermaid: SN class pending → active    ┃
┃ [ ] Flight Plan § Checklist: matching task [ ] → [~]                  ┃
┃                                                                       ┃
┃ COMPLETING T00X:                                                      ┃
┃ [ ] Tasks Table: [~] → [x]                                           ┃
┃ [ ] Architecture Map: T00X node → :::completed (green)                ┃
┃ [ ] Architecture Map: File nodes touched → :::completed               ┃
┃ [ ] Flight Plan § Stages: matching stage [~] → [x]                   ┃
┃ [ ] Flight Plan § Flight Status Mermaid: SN class active → done       ┃
┃ [ ] Flight Plan § Checklist: matching task [~] → [x]                  ┃
┃ [ ] Execution Log: append task entry with evidence                    ┃
┃ [ ] Discoveries table: add any gotchas/insights found                 ┃
┃                                                                       ┃
┃ IF BLOCKED:                                                           ┃
┃ [ ] Flight Plan § Flight Status Mermaid: SN class → blocked (red)     ┃
┃ [ ] (When unblocked: change back to active and continue)              ┃
┃                                                                       ┃
┃ ALL TASKS COMPLETE:                                                   ┃
┃ [ ] Flight Plan § Status: "Ready for takeoff" → "Landed"             ┃
┃                                                                       ┃
┃ ✓ ALL UPDATES DONE → Proceed to next task                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

**Flight Plan location**: `tasks.fltplan.md` in the phase directory (Full Mode) or `FX###.fltplan.md` for fixes.

DO NOT start the next task until ALL updates above are done.

---

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>" (Full Mode) or omitted (Simple Mode)
# --plan "<abs path to plan.md>"
# --subtask "<ORD-subtask-slug>" (optional)

1) Resolve paths:
   PLAN = provided --plan
   PLAN_DIR = dirname(PLAN)

   **Mode Detection**: Read PLAN for `**Mode**: Simple` or `**Mode**: Full`

   **Full Mode**:
   - PHASE_DIR = PLAN_DIR/tasks/${PHASE_SLUG}
   - PHASE_DOC = ${PHASE_DIR}/tasks.md
   - EXEC_LOG = ${PHASE_DIR}/execution.log.md
   - If --subtask: PHASE_DOC = ${PHASE_DIR}/${SUBTASK_KEY}.md

   **Simple Mode**:
   - Check for optional dossier: ${PLAN_DIR}/tasks/implementation/tasks.md
   - If exists → PHASE_DOC = that file
   - If not → PHASE_DOC = PLAN itself (inline tasks from § Implementation)
   - EXEC_LOG = ${PLAN_DIR}/execution.log.md

2) Load context:
   - Read Testing Strategy from plan (approach + mock usage)
   - Read task table from PHASE_DOC
   - Read Context Brief / Key Findings for hazards to watch for
   - **Load domain context**:
     * Read `## Target Domains` from spec
     * Read `## Domain Manifest` from plan
     * For each domain being modified, read `docs/domains/<slug>/domain.md`

3) Execute tasks:
   Follow task order. Apply testing approach from plan:

   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
   ┃ 🛑 STOP! RE-READ "MANDATORY: UPDATE PROGRESS" SECTION ABOVE 🛑     ┃
   ┃                                                                      ┃
   ┃ After EACH task you MUST update ALL locations before proceeding:     ┃
   ┃   1. Tasks Table checkbox                                            ┃
   ┃   2. Architecture Map diagram nodes                                  ┃
   ┃   3. Flight Plan (stages + Mermaid status + checklist)               ┃
   ┃   4. Execution log entry                                             ┃
   ┃                                                                      ┃
   ┃ The user is watching the flight plan. Update it FIRST.               ┃
   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

   **Full TDD**: RED-GREEN-REFACTOR loop per task
   **Lightweight**: Minimal validation tests for core functionality
   **Manual**: Document verification steps, execute manually
   **Hybrid**: Apply approach per task annotation

   ### Domain Placement Rules

   1. Every new file MUST go under its declared domain's source directory
   2. Contract files (public interfaces) go in the domain's contracts/ directory
   3. Cross-domain imports MUST use the target domain's public contracts only
      (never import from another domain's internals)
   4. Dependency direction:
      - business → infrastructure: ✅ allowed
      - infrastructure → business: ❌ never
      - business → business: ⚠️ contracts only
   5. When creating a NEW domain (domain setup task):
      - Create `docs/domains/<slug>/domain.md` using format from /extract-domain
      - Create source directory structure
      - Update `docs/domains/registry.md`

4) After ALL tasks complete — update domain files:

   For each domain touched by this phase:

   a) **Update domain.md § History**:
      ```markdown
      | [plan-ordinal-slug] | [What changed — 1 line summary] | [today] |
      ```

   b) **Update domain.md § Composition** (if new services/adapters/repos created):
      Add new rows to the composition table.

   c) **Update domain.md § Contracts** (if public interface changed):
      Add/modify contract entries.

   d) **Update domain.md § Dependencies** (if new domain relationships formed):
      Add to "This Domain Depends On" or "Domains That Depend On This".

   e) **Update domain.md § Source Location** (if new files added):
      Add file paths to source location listing.

   f) **Update docs/domains/registry.md** if domain status changed.

   g) **Update docs/domains/domain-map.md** if:
      - New domain was created → add node with exposed contracts
      - New contracts were added to existing domain → update node label
      - New cross-domain dependency formed → add labeled edge
      - Domain contracts changed → update the Health Summary table

   h) **Update domain.md § Concepts** (if contracts changed or new domain):

      For NEW domains:
        - Create Concepts table from implemented contracts
        - Group related contracts into named concepts (verb phrases)
        - Add narrative + code example per concept (base on actual implemented code)

      For CHANGED contracts:
        - Add new concepts to table if new capabilities introduced
        - Update existing concept narratives if entry points changed
        - Update code examples to match new signatures

      For UNCHANGED contracts: no Concepts updates needed.

5) Output:
   - Execution Log with per-task entries (write incrementally)
   - Unified diffs for all touched files
   - Evidence (test output, verification results)
   - Domain files updated (domain.md changes listed)
   - Final status mapped to acceptance criteria
   - Suggested commit message

6) Auto-run plan-6a-v2-update-progress for each completed task.

STOP: Report phase complete. Suggest next step.
```

**Next step (Full Mode)**: Run **/plan-7-v2-code-review --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**
**Next step (Simple Mode)**: Run **/plan-7-v2-code-review --plan "<PLAN_PATH>"**
