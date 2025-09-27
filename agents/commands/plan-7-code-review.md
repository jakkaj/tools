---
description: Read-only per-phase code review that inspects diffs, verifies doctrine compliance, and produces structured findings without modifying code.
---

# plan-7-code-review

Per-phase diff audit & code review (read-only)

Goal: read the diffs for **one implemented phase**, validate they match the approved brief and tasks, and return a structured **review report** with findings, severity, and actionable fix suggestions (patch hints + fix-tasks). Do **not** edit code.

Why now: this runs after `plan-6-implement-phase`, leveraging its execution log, diffs, and test evidence; it enforces your planning gates and rules before merge.

```md
---
description: Read-only code review for ONE implemented phase using the produced diffs and evidence; validate against rules, plan, and brief; propose focused fixes as tasks/patch hints.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --include-diffs
  ps: scripts/powershell/check-prerequisites.ps1 -Json -IncludeDiffs
---

User input:

$ARGUMENTS
# Required flags (absolute paths):
# --phase "<Phase N: Title>"
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"
# Optional flags:
# --diff-file "<abs path to unified.diff>"   # if omitted, compute from git
# --base "<commit-ishA>" --head "<commit-ishB>"  # commit range; overrides --diff-file
# --pr-body "<abs path to PR.md>"            # if you want a PR summary file
# --strict                                   # treat HIGH as blocking

1) Resolve inputs & artifacts
   - Run {SCRIPT} to resolve:
     PLAN        = provided --plan
     PLAN_DIR    = dirname(PLAN)
     TASKS_PHASE = PLAN_DIR/tasks.${PHASE_SLUG}.md
     BRIEF       = PLAN_DIR/phase.${PHASE_SLUG}.brief.md
     EXEC_LOG    = PLAN_DIR/execution.${PHASE_SLUG}.log.md (required)
   - **Plan Footnotes Evidence**:
     Read the plan footer "Change Footnotes Ledger"; map footnote tags in task rows to detailed node-ID entries
     (per `AGENTS.md`). Ensure numbering is sequential/unique and each changed file/method has a corresponding footnote entry.
   - Diffs source:
     a) If --diff-file provided -> use it as canonical unified diff
     b) Else if --base/--head provided -> run `git diff --unified=3 --no-color {base}..{head}`
     c) Else -> compute last phase range from EXEC_LOG hints or `git log` for the branch (document range)

2) Scope guard (PHASE ONLY)
   - Parse TASKS_PHASE to list target files for this phase; ensure the diff touches only those or justified neighbors.
   - If violations (files outside scope without justification in BRIEF/EXEC_LOG), flag as HIGH.

3) Rules & doctrine gates (hard checks)
   - Plan/Rules conformance: confirm changes uphold `docs/rules-idioms-architecture/{rules.md, idioms.md}`, including:
     - **TDD order** (tests precede implementation in history/evidence)
     - **Tests as documentation** assertions (clear behavioral expectations)
     - **No mocks**; real repo data/fixtures
     - Absolute paths and explicitness (no hidden context assumptions)
     If any are missing, mark CRITICAL with concrete remediation steps. :contentReference[oaicite:4]{index=4}
   - BridgeContext patterns when applicable to VS Code/TS:
     - Use `vscode.Uri` (not Node `path`) for paths
     - Use bounded `vscode.RelativePattern` (+ exclude + maxResults) for searches
     - Avoid `workspace.findFiles('**/*')` without bounds
     - Python debugging uses `{ module: 'pytest', args: ['--no-cov', ...] }` (never `program`)
     Flag deviations with precise line refs and patch hints. :contentReference[oaicite:5]{index=5}

4) TDD evidence & coverage alignment
   - Cross-check BRIEF acceptance criteria <-> test changes (added/updated tests in `tests/` or stack-native locations).
   - Ensure negative/edge/concurrency cases are present, not just happy paths.
   - Map each criterion to at least one assertion that proves behavior (quote minimal assertion snippets).
   - If a criterion lacks test coverage, mark HIGH with a test-first fix suggestion. :contentReference[oaicite:6]{index=6}

5) Quality and safety review (diff-level)
   Review each hunk for:
   - **Correctness:** obvious logic defects, off-by-one, error handling
   - **Observability:** meaningful logs/metrics where required by plan/rules
   - **Performance:** unbounded scans, N+1, sync I/O in async paths
   - **Security:** path traversal, injection, unsafe temp files, secrets
   - **Remote-safety:** avoid Node `fs/path` where VS Code FS/Uri APIs are required
   - **Parallelism correctness:** if tasks marked [P], ensure touched files are disjoint; else require serialization
   Return precise comments with file:line and a one-paragraph rationale; attach patch hints when small. :contentReference[oaicite:7]{index=7} :contentReference[oaicite:8]{index=8}

6) Static & type checks (project-native)
   - Run project-native linters/type-checkers/formatters as specified by PLAN/BRIEF (e.g., `just test-extension`, `pytest -q`, `eslint --max-warnings=0`, `tsc --noEmit`).
   - Capture command lines and summarized output. If tools are not defined, note that and recommend adding to rules. :contentReference[oaicite:9]{index=9}

7) Output files (write under PLAN_DIR/reviews/)
   - `PLAN_DIR/reviews/review.${PHASE_SLUG}.md` (the report)
     Sections:
     A) **Verdict**: APPROVE / REQUEST_CHANGES (STRICT mode: any HIGH -> REQUEST_CHANGES)
     B) **Summary** (<=10 lines)
     C) **Checklist** (pass/fail)
        - Tests precede code (evidence ref)
        - Tests as docs (assertions show behavior)
        - No mocks; real data/fixtures used
        - BridgeContext patterns followed (Uri, RelativePattern, module: 'pytest')
        - Only in-scope files changed
        - Linters/type checks are clean
     D) **Findings Table**
        | ID | Severity | File:Lines | Summary | Recommendation |
        |----|----------|------------|---------|----------------|
     E) **Inline Comments** (ordered by file, include minimal code blocks)
     F) **Coverage Map** (acceptance criteria <-> test files/assertions)
     G) **Commands Executed** (copy/paste)
     H) **Decision & Next Steps** (who approves; what to fix)
     I) **Footnotes Audit**: summary table listing each diff-touched path, associated footnote tag(s), and node-ID link(s).
   - `PLAN_DIR/reviews/fix-tasks.${PHASE_SLUG}.md` (only if REQUEST_CHANGES)
     - Micro-tasks with exact file paths + patch hints
     - Tests-first ordering for each fix (what to assert, then code)
     - Mark [P] only for disjoint files

8) Style & constraints
   - Read-only: do not change source files.
   - Patches are hints only (unified diff snippets in the report).
   - Keep report deterministic and terse; quote only minimal context.

Acceptance criteria for this command
- Review report exists with a clear verdict and a complete findings table.
- Every HIGH/CRITICAL finding has a concrete, minimal fix path (test-first when applicable).
- Coverage map proves that each acceptance criterion has at least one test assertion.
- If APPROVE: zero HIGH/CRITICAL, all gates pass. If REQUEST_CHANGES: fix tasks file created.

Notes:
- Plan and rules are authorities; if conflicts arise, rules win unless constitution deviation is logged in the plan. :contentReference[oaicite:10]{index=10} :contentReference[oaicite:11]{index=11}
```

Review rubric baked into this phase

- **Doctrine**: TDD, tests-as-documentation, **no mocks**, real repo data/fixtures. Flag drift as CRITICAL/HIGH with test-first fix guidance.
- **BridgeContext patterns** for VS Code/TypeScript work: bounded `vscode.RelativePattern`, remote-safe `vscode.Uri`, pytest debug via `module` not `program` with `--no-cov`.
- **Task/file safety**: [P] only for disjoint files; require serialization otherwise.
- **Plan authority**: Changes must map to the locked structure and explicit acceptance criteria from planning.

Flow update (ordered commands)

0. **plan-0-constitution**
1. **plan-1-specify**
2. **plan-2-clarify**
3. **plan-3-architect**
4. **plan-4-complete-the-plan**
5. **plan-5-phase-tasks-and-brief** (one phase only)
6. **plan-6-implement-phase** (that phase only)
7. **plan-7-code-review**: produce `reviews/review.<phase>.md` (and `fix-tasks.<phase>.md` when requesting changes)

This ensures reviews inspect the work against the same standards enforced during planning and implementation.

Next step (when happy): APPROVE -> merge and advance to the next phase (restart at **/plan-5**); REQUEST_CHANGES -> follow `PLAN_DIR/reviews/fix-tasks.<phase>.md` then rerun **/plan-6** for fixes.
