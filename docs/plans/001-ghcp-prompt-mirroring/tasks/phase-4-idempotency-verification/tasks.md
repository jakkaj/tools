---
phase: "Phase 4: Idempotency Verification"
slug: phase-4-idempotency-verification
plan: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md
spec: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-spec.md
today: 2025-09-28
notes:
  template_notice: "templates/tasks-template.md not present; dossier follows repository convention manually."
---

## Tasks
| ID   | Task | Dependencies | [P] Guidance | Validation Checklist Coverage |
|------|------|--------------|--------------|-------------------------------|
| T001 | Review current rerun behavior, logging, and overwrite assumptions in `/Users/jordanknight/github/tools/install/agents.sh`, comparing with Phase 4 acceptance criteria. | – | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Aligns plan tasks 4.1–4.3; establishes baseline expectations |
| T002 | Create new smoke-test script at `/Users/jordanknight/github/tools/tests/install/test_complete_flow.sh` that executes two installer runs against a temp `HOME`, capturing file counts/log markers and expecting explicit idempotency confirmation (initially RED). | T001 | `[P]` eligible (new file) | Covers “Run complete flow twice”, “Verify file overwrites”, “Smoke test passes” |
| T003 | Execute the smoke test (`bash tests/install/test_complete_flow.sh`) to document the failing state (missing idempotency confirmation / mismatched outputs). | T002 | Serial (depends on new test assertions) | Confirms tests-first failure and highlights current gaps |
| T004 | Enhance `/Users/jordanknight/github/tools/install/agents.sh` to emit deterministic summary output after second loop (e.g., `[✓ Idempotent]` with counts) and ensure temporary workspace handling avoids duplicate writes. | T003 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Satisfies “Script is idempotent”, “No duplicate files created” |
| T005 | Add inline documentation / comments in `/Users/jordanknight/github/tools/install/agents.sh` summarizing idempotent design decisions, referencing overwrite semantics and smoke test reference (per plan task 4.3). | T004 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Addresses “Document idempotent design”, ties to acceptance checklist |
| T006 | Re-run `tests/install/test_complete_flow.sh` (GREEN) capturing logs for `execution.log.md`, and follow with `shellcheck` on the new script. | T005 | `[P]` eligible (execution + tooling) | Verifies “Second run succeeds”, “Smoke test passes” |

## Alignment Brief
**Objective recap & behavior checklist**  
- Demonstrate installer remains idempotent: multiple runs produce identical Copilot/legacy outputs with no duplicates.  
- Provide explicit reporting (counts + SUCCESS indicator) post-run.  
- Document idempotent strategy in the script for future maintainers.  
- Acceptance criteria: two-pass smoke test succeeds, file counts match, new log output present, idempotent design documented.

**Invariants & guardrails**  
- Do not introduce stateful caches; rely on overwriting `cp`.  
- Preserve logging tone (`print_status`, `[↻]` lines).  
- Tests must operate in isolated temp HOME/workspace (no mocks).  
- Ensure commands remain cross-platform friendly (macOS/Linux).  
- Avoid touching skipped Phase 3 scope—settings checks remain optional.

**Inputs to read**  
- `/Users/jordanknight/github/tools/install/agents.sh` (loop + logging).  
- `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md` (§Phase 4).  
- Phase 1 & 2 execution logs for temp HOME patterns.  
- `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` (reuse temp dir utilities).  
- `AGENTS.md` for logging tone guidance.

**Test Plan (TDD, tests-as-docs, no mocks, real data)**  
1. `tests/install/test_complete_flow.sh::test_idempotent_two_run_flow`  
   - **Purpose**: Ensure consecutive installer runs succeed without duplicates and emit `[✓ Idempotent]` summary.  
   - **Setup**: Temp HOME/workspace; run installer twice; compare file counts using `find`.  
   - **Expected Output**: Matching counts; summary log present; exit code 0.  
2. `tests/install/test_complete_flow.sh::test_smoke_log_artifacts`  
   - **Purpose**: Capture log output for evidence; ensure crucial counts recorded.  
   - **Setup**: Re-run script and parse log file saved to temp path.  
   - **Expected Output**: Log contains first/second run markers plus `[✓ Idempotent]` line.

**Implementation outline (maps to tasks/tests)**  
1. T001 → Review script & note required log additions.  
2. T002 → Author smoke test script referencing new summary log expectation.  
3. T003 → Run test (RED) showing missing summary/log/det counts.  
4. T004 → Update installer loop to compute counts post-run and print `[✓ Idempotent] Copied X prompt files (Y sources)` plus ensure workspace path existence checks.  
5. T005 → Add inline comment(s) describing overwrite/idempotency reasoning; mention smoke test path.  
6. T006 → Re-run smoke test (GREEN), capture log + run `shellcheck`.

**Commands to run**  
- `bash tests/install/test_complete_flow.sh`  
- `bash tests/install/test_complete_flow.sh | tee /tmp/phase4-idempotency.log`  
- `shellcheck tests/install/test_complete_flow.sh`  
- `git status --short`

**Risks / unknowns & rollback plan**  
- *Risk*: Counting logic may differ on systems without `.prompt.md` (workspace absent) → ensure tests allow optional workspace or mock.  
- *Risk*: Additional logging could break prior tests; confirm other harnesses updated if needed.  
- *Rollback*: `git restore install/agents.sh tests/install/test_complete_flow.sh`; delete generated logs.

**Ready Check (await GO/NO-GO)**  
- [x] Temp HOME workflow approved for smoke test.  
- [x] Expectation for new `[✓ Idempotent]` summary agreed.  
- [x] `shellcheck` coverage available.  
- [x] Acceptance criteria + test plan executed (see `execution.log.md`).

## Phase Footnote Stubs
| Task ID | Notes |
|---------|-------|
| T002 | Add idempotency smoke test script at `/Users/jordanknight/github/tools/tests/install/test_complete_flow.sh`. [^8] |
| T004 | Add idempotency summary logging/count logic to `/Users/jordanknight/github/tools/install/agents.sh`. [^9] |
| T005 | Document idempotent design decisions within `/Users/jordanknight/github/tools/install/agents.sh`. [^10] |

[^8]: Phase 4 T002 – Added smoke test harness for two-run validation.
  - `file:tests/install/test_complete_flow.sh`
[^9]: Phase 4 T004 – Implemented Copilot prompt summary + idempotency indicator.
  - `function:install/agents.sh:main`
[^10]: Phase 4 T005 – Inline documentation of idempotent overwrite strategy.
  - `function:install/agents.sh:main`

## Evidence Artifacts
- Phase execution log: `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/tasks/phase-4-idempotency-verification/execution.log.md`.  
- Smoke test harness: `/Users/jordanknight/github/tools/tests/install/test_complete_flow.sh`.  
- Test transcript: `/tmp/phase4-idempotency.log` (optional capture during reruns).  
- Shell lint output: `shellcheck tests/install/test_complete_flow.sh` (recorded in execution log).

```
docs/plans/001-ghcp-prompt-mirroring/
  ├── ghcp-prompt-mirroring-plan.md
  ├── ghcp-prompt-mirroring-spec.md
  └── tasks/
      ├── phase-1-directory-variable-setup/
      │   ├── tasks.md
      │   └── execution.log.md
      ├── phase-2-copy-rename-operations/
      │   ├── tasks.md
      │   └── execution.log.md
      ├── phase-3-vs-code-settings-merge/
      │   └── tasks.md  # retained for historical reference (phase skipped)
      └── phase-4-idempotency-verification/
          ├── tasks.md
          └── execution.log.md  # to be created by /plan-6
```
