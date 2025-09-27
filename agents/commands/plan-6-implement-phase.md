---
description: Implement exactly one approved phase via strict TDD using the phase tasks and brief, recording diffs and evidence.
---

# plan-6-implement-phase

Implement **exactly** the approved phase via strict **TDD** using the **phase tasks** and **brief** produced in step 5; emit diffs and evidence. (No global analyze step.)

```md
---
description: Execute the approved phase using TDD. Consume tasks.<phase>.md + phase.<phase>.brief.md; produce diffs, logs, and proofs.
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
   TASKS_PHASE = PLAN_DIR/tasks.${PHASE_SLUG}.md
   BRIEF       = PLAN_DIR/phase.${PHASE_SLUG}.brief.md

2) **Contract**:
   - TDD loop per task: write/adjust test (RED) -> minimal code (GREEN) -> refactor (CLEAN) -> commit.
   - Assertions must **document behavior**; not generic truths.
   - **No mocks**; use real repo data/fixtures.
   - Respect stack patterns (e.g., Python test debug via `module: 'pytest'` + `--no-cov`; bounded searches; remote-safe URIs).
   (Rules/idioms affirmed here.) :contentReference[oaicite:17]{index=17} :contentReference[oaicite:18]{index=18}

3) Execution:
   - Follow task order and dependencies; [P] only for disjoint file sets.
   - After each cycle: record Test -> expected fail excerpt -> code change summary -> pass excerpt -> refactor note.
   - **Update plan footnotes**:
     * In `PLAN` (the plan markdown), for each edited file/method, append a footnote in the **Change Footnotes Ledger**
       using the exact substrate node-ID format and clickable links from `AGENTS.md`.
     * In the corresponding task Notes, end with a footnote tag (`[^N]`) pointing to that ledger entry.
       Keep numbering sequential and unique; do not skip numbers.

4) Output:
   - **Execution Log** -> write `PLAN_DIR/execution.${PHASE_SLUG}.log.md` (concise per TDD cycle).
   - **Unified diffs** for all touched files.
   - **Commands & evidence** (runner output excerpts that prove acceptance criteria).
   - **Risk/Impact & rollback** confirmation.
   - **Final status** mapped to phase acceptance criteria + suggested commit message(s)/PR title.

5) Halt on ambiguity:
   - If a step cannot proceed without a decision, **STOP** and ask **one focused question**; do not widen scope.

Note:
- This command executes one phase only. To proceed, run it again with the **next phase** when its tasks + brief are ready.
```

The execution semantics match your existing implementation command, adjusted to consume phase-scoped artifacts and BridgeContext practices.

Next step (when happy): Run **/plan-7-code-review --phase "<Phase N: Title>" --plan "<PLAN_PATH>"**.
