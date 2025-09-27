---
description: Implement exactly one approved phase via strict TDD using the combined `tasks.md` dossier, recording diffs and evidence.
---

# plan-6-implement-phase

Implement **exactly** the approved phase via strict **TDD** using the **phase tasks** and **brief** produced in step 5; emit diffs and evidence. (No global analyze step.)

```md
---
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -IncludeTasks
---

User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"

1) Run {SCRIPT}; resolve:
   PLAN        = provided --plan
   PLAN_DIR    = dirname(PLAN)
   PHASE_DIR   = PLAN_DIR/tasks/${PHASE_SLUG}
   PHASE_DOC   = PHASE_DIR/tasks.md  # combined tasks + alignment brief
   ensure `PHASE_DIR` exists (mkdir is not allowed here; abort if missing) and `PHASE_DOC` is present; load task definitions plus the Alignment Brief sections from it.

2) **Contract**:
   - TDD loop per task: write/adjust test (RED) -> minimal code (GREEN) -> refactor (CLEAN) -> commit.
   - Assertions must **document behavior**; not generic truths.
   - **No mocks**; use real repo data/fixtures.
   - Respect stack patterns (e.g., Python test debug via `module: 'pytest'` + `--no-cov`; bounded searches; remote-safe URIs).
   - Consult the Alignment Brief section inside `PHASE_DOC` before each task to reaffirm invariants, guardrails, and test expectations.
   (Rules/idioms affirmed here.) :contentReference[oaicite:17]{index=17} :contentReference[oaicite:18]{index=18}

3) Execution:
   - Follow task order and dependencies listed in `PHASE_DOC`; [P] only for disjoint file sets.
   - After each cycle: record Test -> expected fail excerpt -> code change summary -> pass excerpt -> refactor note.
   - **Update plan footnotes**:
     * In `PLAN` (the plan markdown), for each edited file/method, append a footnote in the **Change Footnotes Ledger**
       using the exact substrate node-ID format and clickable links from `AGENTS.md`.
     * In `PHASE_DOC`, ensure each task's Notes entry ends with the correct footnote tag (`[^N]`) mapped to that ledger entry. Maintain sequential, unique numbering.

4) Output:
   - **Execution Log** -> write `PHASE_DIR/execution.log.md` (concise per TDD cycle).
   - **Unified diffs** for all touched files.
   - **Commands & evidence** (runner output excerpts that prove acceptance criteria).
   - **Risk/Impact & rollback** confirmation.
   - **Final status** mapped to phase acceptance criteria + suggested commit message(s)/PR title.
   - Update the `## Evidence Artifacts` section in `PHASE_DOC` with links to the log and any newly produced evidence (store artifacts inside `PHASE_DIR`).

5) Halt on ambiguity:
   - If a step cannot proceed without a decision, **STOP** and ask **one focused question**; do not widen scope.

Note:
- This command executes one phase only. To proceed, run it again with the **next phase** when its tasks + brief are ready.
- Store any ancillary artifacts generated during this phase inside `PHASE_DIR` to keep the plan tree organized.
```

The execution semantics match your existing implementation command, adjusted to consume phase-scoped artifacts and BridgeContext practices.

Next step (when happy): Run **/plan-7-code-review --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**.
