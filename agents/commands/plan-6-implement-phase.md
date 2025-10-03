---
description: Implement exactly one approved phase or subtask via strict TDD using the relevant dossier, recording diffs and evidence.
---

# plan-6-implement-phase

Implement **exactly** one approved phase or subtask via strict **TDD** using the relevant **tasks + alignment brief** dossier; emit diffs and evidence. (No global analyze step.)

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

2) **Contract**:
   - TDD loop per task: write/adjust test (RED) -> minimal code (GREEN) -> refactor (CLEAN) -> commit.
   - Assertions must **document behavior**; not generic truths.
   - **No mocks**; use real repo data/fixtures.
   - Respect stack patterns (e.g., Python test debug via `module: 'pytest'` + `--no-cov`; bounded searches; remote-safe URIs).
   - Consult the Alignment Brief section inside `PHASE_DOC` before each task to reaffirm invariants, guardrails, and test expectations.
   (Rules/idioms affirmed here.) :contentReference[oaicite:17]{index=17} :contentReference[oaicite:18]{index=18}

3) Execution:
   - Follow task order and dependencies listed in `PHASE_DOC`; [P] only for disjoint file sets (respect ST/T scopes).
   - After each cycle: record Test -> expected fail excerpt -> code change summary -> pass excerpt -> refactor note.
   - **Update plan footnotes**:
     * In `PLAN` (the plan markdown), for each edited file/method, append a footnote in the **Change Footnotes Ledger**
       using the exact substrate node-ID format and clickable links from `AGENTS.md`.
     * In `PHASE_DOC`, ensure each task's Notes entry ends with the correct footnote tag (`[^N]`) mapped to that ledger entry—whether the IDs are `T###` or `ST###`. Maintain sequential, unique numbering across the dossier.

4) Output:
   - **Execution Log** -> write to `EXEC_LOG` (phase log or subtask-specific log) with concise per TDD cycle entries.
   - **Unified diffs** for all touched files.
   - **Commands & evidence** (runner output excerpts that prove acceptance criteria).
   - **Risk/Impact** confirmation.
   - **Final status** mapped to dossier acceptance criteria + suggested commit message(s)/PR title.
   - Update the `## Evidence Artifacts` section in `PHASE_DOC` with links to the log and any newly produced evidence (store artifacts inside `PHASE_DIR`).
   - If executing a subtask, also review the parent phase dossier to ensure cross-references (e.g., Ready Check, supporting tasks) remain accurate.

5) Halt on ambiguity:
   - If a step cannot proceed without a decision, **STOP** and ask **one focused question**; do not widen scope.

Note:
- This command executes one dossier at a time (phase or subtask). To proceed, rerun it with the next target when its tasks + brief are ready.
- Store any ancillary artifacts generated during this work inside `PHASE_DIR` to keep the plan tree organized.
```

The execution semantics match your existing implementation command, adjusted to consume phase-scoped artifacts and BridgeContext practices.

Next step (when happy): Run **/plan-7-code-review --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**.
