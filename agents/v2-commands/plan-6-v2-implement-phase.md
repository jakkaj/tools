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

## 🛑 UPDATE PROGRESS AFTER EVERY TASK

After completing EACH task:
1. ☑️ Tasks Table — `[ ]` → `[x]`
2. 🎨 Architecture Map — node → `:::completed`
3. 📝 Execution Log — append task entry with evidence
4. ✈️ Flight Plan (`tasks.fltplan.md` or `FX###.fltplan.md`) — update:
   - **Stages**: `[ ]` → `[~]` (starting) → `[x]` (done)
   - **Flight Status Mermaid**: change task state class `pending` → `active` → `done` (or `blocked` if stuck)
   - **Checklist**: `[ ]` → `[x]` for matching task ID
   - When ALL stages complete: change `**Status**: Ready for takeoff` → `**Status**: Landed`

DO NOT start the next task until updates are done.

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
