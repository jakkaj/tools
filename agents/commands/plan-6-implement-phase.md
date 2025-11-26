---
description: Implement exactly one approved phase or subtask using the testing approach specified in the plan, recording diffs and evidence.
---

# plan-6-implement-phase

Implement **exactly** one approved phase or subtask using the **testing approach specified in the plan** (Full TDD, Lightweight, Manual, or Hybrid) with the relevant **tasks + alignment brief** dossier; emit diffs and evidence. (No global analyze step.)

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"
# Optional flag:
# --subtask "<ORD-subtask-slug>"   # Execute a subtask dossier (e.g., "003-subtask-bulk-import-fixtures")

1) Resolve paths:
   PLAN         = provided --plan
   PLAN_DIR     = dirname(PLAN)

   **Detect Workflow Mode:**
   - Read PLAN file and check for `**Mode**: Simple` or `**Mode**: Full` in header
   - If `Mode: Simple` → Use **Simple Mode** (inline tasks, no dossier required)
   - If `Mode: Full` or not specified → Use **Full Mode** (requires dossier)

   **Full Mode Path Resolution:**
   PHASE_HEADING = provided --phase (required when multiple phases exist); slugify to get `PHASE_SLUG` exactly as plan-5/plan-5a generate directories (e.g., "Phase 4: Data Flows" → `phase-4-data-flows`).
   If `--phase` omitted, infer `PHASE_SLUG` by locating the unique tasks directory that contains either `tasks.md` or the requested `--subtask` file; abort when inference is ambiguous.
   PHASE_DIR    = PLAN_DIR/tasks/${PHASE_SLUG}
   ensure `PHASE_DIR` exists (mkdir is not allowed here; abort if missing).
   When `--subtask` is omitted:
     - PHASE_DOC = `${PHASE_DIR}/tasks.md`; must exist. This is the dossier to execute.
     - EXEC_LOG  = `${PHASE_DIR}/execution.log.md` (create when writing step 4).
   When `--subtask` is provided:
     - SUBTASK_KEY   = flag value (e.g., `003-subtask-bulk-import-fixtures`).
     - PHASE_DOC     = `${PHASE_DIR}/${SUBTASK_KEY}.md`; must exist and follow plan-5a format.
     - EXEC_LOG      = `${PHASE_DIR}/${SUBTASK_KEY}.execution.log.md`; create if missing during step 4.
     - Capture parent task linkage from the subtask metadata table before execution.
   Load task definitions and Alignment Brief sections from `PHASE_DOC`.

   **Simple Mode Path Resolution:**
   - `--phase` flag is ignored (single phase)
   - PHASE_DIR = PLAN_DIR (no separate tasks directory)
   - Check if dossier exists: `${PLAN_DIR}/tasks/implementation/tasks.md`
     * If exists → PHASE_DOC = that file (user ran plan-5 optionally)
     * If not exists → PHASE_DOC = PLAN itself (read inline task table from § Implementation)
   - EXEC_LOG = `${PLAN_DIR}/execution.log.md` (sibling to plan file)
   - INLINE_MODE = true if reading tasks from plan directly

   **Simple Mode Task Loading:**
   When INLINE_MODE = true:
   - Parse `## Implementation (Single Phase)` section from PLAN
   - Extract `### Tasks` table (same 9-column format as dossier)
   - Extract `### Acceptance Criteria` as validation checkpoints
   - Testing Approach and Mock Usage from section header
   - No Alignment Brief section (use plan's Executive Summary for context)

2) **Contract** (Read Testing Strategy First):
   a) Extract Testing Strategy from `PLAN`:
      - Locate `## Testing Strategy` section
      - Read **Approach**: Full TDD | TAD | Lightweight | Manual | Hybrid
      - Read **Mock Usage**: Avoid mocks | Targeted mocks | Liberal mocks
      - Read **Focus Areas** and **Excluded** to understand priorities

   b) Apply approach-specific workflow:
      **Full TDD**:
        - RED-GREEN-REFACTOR loop per task: write/adjust test (RED) -> minimal code (GREEN) -> refactor (CLEAN) -> commit
        - Assertions must **document behavior**; not generic truths
        - Apply mock policy from spec (typically "avoid mocks"; use real repo data/fixtures)

      **TAD (Test-Assisted Development)**:
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ⚠️ **CRITICAL**: You MUST execute tests repeatedly
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        - Scratch → **RUN** → Promote cycle per task:
          1. Create/use tests/scratch/ directory (exclude from CI if not already)
          2. Write probe tests to explore behavior (fast iteration, no documentation needed)
          3. **🔴🟢 RUN scratch tests REPEATEDLY** during implementation (RED→GREEN cycle):
             * Write scratch test for small isolated behavior
             * **RUN test** with test runner (expect failure - RED)
               ```bash
               pytest tests/scratch/test_feature.py -v  # Python
               npm test tests/scratch/  # JavaScript/TypeScript
               ```
             * Write minimal code to pass test
             * **RUN test again** (expect success - GREEN)
             * Refactor if needed, **re-run test**
             * REPEAT for next behavior (10-20+ cycles expected)
             * This tight loop validates isolated code WITHOUT running entire project
             * **Show test execution output** as evidence of RED→GREEN cycles
          4. Implement code iteratively, refining with scratch probes after each test run
          5. When behavior stabilizes, identify valuable tests using promotion heuristic (expect ~5-10% promotion rate):
             * Keep if: Critical path, Opaque behavior, Regression-prone, or Edge case
             * **Most scratch tests are DELETED** - they're temporary development tools
          6. Promote valuable tests (typically 1-2 per feature) to tests/unit/ or tests/integration/
          7. Add Test Doc comment block to each promoted test (required fields):
             - Why: business/bug/regression reason (1-2 lines)
             - Contract: plain-English invariant(s) this test asserts
             - Usage Notes: how to call/configure the API; gotchas
             - Quality Contribution: what failure this will catch; link to issue/PR/spec
             - Worked Example: inputs/outputs summarized for scanning
          8. Delete scratch probes that don't add durable value (expect to delete 90-95%)
          9. Document learning notes from scratch exploration in execution log
        - Test naming: "Given...When...Then..." format (e.g., `test_given_iso_date_when_parsing_then_returns_normalized_cents`)
        - Promoted tests must be deterministic without network/sleep/flakes (performance requirements from spec)
        - Apply mock policy from spec to promoted tests only
        - Tests are executable documentation; optimize for next developer's understanding

      **Lightweight**:
        - Write minimal validation tests focused on core functionality
        - Prioritize smoke tests and integration checks
        - Skip extensive unit testing for simple operations
        - Test critical paths only

      **Manual**:
        - Document manual verification steps with clear expected outcomes
        - Create validation checklists in acceptance criteria
        - No automated test writing required
        - Record manual test execution results

      **Hybrid**:
        - Apply Full TDD to tasks marked complex/high-risk
        - Apply Lightweight to tasks marked simple/low-risk
        - Check phase task table for per-task testing annotations

   c) Universal principles (all approaches):
      - Consult the Alignment Brief section inside `PHASE_DOC` before each task to reaffirm invariants, guardrails, and test expectations
      - Respect stack patterns (e.g., Python test debug via `module: 'pytest'` + `--no-cov`; bounded searches; remote-safe URIs)
      - Honor mock usage preference from Testing Strategy
      (Rules/idioms affirmed here.) :contentReference[oaicite:17]{index=17} :contentReference[oaicite:18]{index=18}

3) Execution (adapt to Testing Strategy):
   - Follow task order and dependencies listed in `PHASE_DOC`; [P] only for disjoint file sets (respect ST/T scopes).

   **For Full TDD**:
     - After each RED-GREEN-REFACTOR cycle: record Test -> expected fail excerpt -> code change summary -> pass excerpt -> refactor note

   **For TAD**:
     - **MANDATORY**: Include test execution output showing RED→GREEN cycles
     - During scratch exploration: record test runs (RED→GREEN cycles), iteration counts, timing, **paste test runner output**
     - After scratch exploration: record probe tests written (count), runs executed, behavior explored, insights gained
     - After implementation: record code changes, how scratch probes informed design
     - After promotion: record which tests promoted (typically 1-2), promotion ratio (e.g., "2 of 15 = 13% promoted"), promotion rationale (heuristic applied), Test Doc blocks added
     - After cleanup: record which scratch tests deleted, learning notes preserved
     - **Evidence checklist**: ✓ Test failures shown, ✓ Test passes shown, ✓ Multiple RED→GREEN cycles demonstrated

   **For Lightweight**:
     - After implementing functionality: write validation test -> run test -> record pass/fail -> document key verification points

   **For Manual**:
     - After implementing functionality: execute manual verification steps -> record observed behavior -> confirm acceptance criteria met

   **For Hybrid**:
     - Check task annotation; apply Full TDD or Lightweight workflow accordingly

4) Output (format adapts to Testing Strategy):
   - **Execution Log** -> write to `EXEC_LOG` (phase log or subtask-specific log):
     * Full TDD: Concise per RED-GREEN-REFACTOR cycle entries (include dossier task ID and plan task ID in metadata - see plan-6a log format)
     * TAD: Scratch exploration notes, promotion decisions with heuristic rationale, Test Doc blocks, learning notes (include task IDs)
     * Lightweight: Per-task validation test results and key verification points (include task IDs)
     * Manual: Manual verification steps executed and observed outcomes (include task IDs)
     * Hybrid: Mix of TDD cycles, TAD promotions, and validation results per task annotation (include task IDs)
     * **CRITICAL**: Follow plan-6a execution log format with dossier task ID, plan task ID, and backlinks

   - **Atomic Progress Update** (delegate to plan-6a - REQUIRED):
     * **IMMEDIATELY** after writing each task entry to EXEC_LOG, delegate to plan-6a for atomic updates:

       **Full Mode:**
       ```bash
       /plan-6a-update-progress \
         --phase "${PHASE_HEADING}" \
         --plan "${PLAN}" \
         --task "${TASK_ID}" \
         --status "completed|in_progress|blocked" \
         --changes "class:path:ClassName,method:path:ClassName.method,function:path:funcName,file:path"
       ```

       **Simple Mode (INLINE_MODE = true):**
       ```bash
       /plan-6a-update-progress \
         --plan "${PLAN}" \
         --task "${TASK_ID}" \
         --status "completed|in_progress|blocked" \
         --changes "class:path:ClassName,method:path:ClassName.method,function:path:funcName,file:path" \
         --inline
       ```
       The `--inline` flag tells plan-6a to update the inline task table in the plan itself.

     * This ensures:
       - **Full Mode**: Dossier task table + Plan task table + Both footnote ledgers updated
       - **Simple Mode**: Plan inline task table + Plan footnote ledger updated
       - Progress checklist updated (if present)
     * **DO NOT** manually update task tables or footnotes; always delegate to plan-6a for consistency
     * For subtask work, include `--subtask "${SUBTASK_KEY}"` flag in the plan-6a command

   - **Unified diffs** for all touched files.
   - **Commands & evidence** (runner output excerpts that prove acceptance criteria):
     * Full TDD/TAD/Lightweight: Test runner output (TAD includes promoted tests only, not scratch/)
     * Manual: Screenshots, command output, or manual test logs
     * TAD: Evidence that tests/scratch/ is excluded from CI, promoted tests are deterministic and reliable
   - **Risk/Impact** confirmation.
   - **Final status** mapped to dossier acceptance criteria + suggested commit message(s)/PR title.
   - **Subtask completion prompt**:
     * When executing with `--subtask` AND all ST### tasks complete, display:
       ```
       ✅ Subtask ${SUBTASK_KEY} Complete

       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
       📋 Resumption Guide
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

       Why this subtask existed:
         {Reason from subtask Parent Context section}

       What's now resolved:
         {Summary of subtask deliverables/ST tasks completed}

       Resume parent work:
         Phase: {PHASE_HEADING}
         Task: T{XXX} - {task summary}
         Status: {current status - check if was blocked}

       Next steps:
         1. Update parent task in tasks.md (unblock if needed)
         2. Resume main phase implementation

       Resume command:
         /plan-6-implement-phase --phase "{PHASE_HEADING}" --plan "{PLAN}"
       ```
     * Also update Subtasks Registry in PLAN: locate the subtask row and change status from `[ ] Pending` to `[x] Complete`.
   - Update the `## Evidence Artifacts` section in `PHASE_DOC` with links to the log and any newly produced evidence (store artifacts inside `PHASE_DIR`).
   - If executing a subtask, also review the parent phase dossier to ensure cross-references (e.g., Ready Check, supporting tasks) remain accurate.

5) Halt on ambiguity:
   - If a step cannot proceed without a decision, **STOP** and ask **one focused question**; do not widen scope.

Note:
- **Full Mode**: This command executes one dossier at a time (phase or subtask). To proceed, rerun it with the next target when its tasks + brief are ready.
- **Simple Mode**: This command executes all tasks in the single inline phase. No phase flag needed.
- Store any ancillary artifacts generated during this work inside `PHASE_DIR` (Full Mode) or `PLAN_DIR` (Simple Mode) to keep files organized.
```

The execution semantics match your existing implementation command, adjusted to consume phase-scoped artifacts and BridgeContext practices.

**Next step (when happy):**

**Full Mode**: Run **/plan-7-code-review --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**

**Simple Mode**: Run **/plan-7-code-review --plan "<PLAN_PATH>"** (no --phase needed)
