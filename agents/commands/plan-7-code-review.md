---
description: Read-only per-phase code review that inspects diffs, verifies doctrine compliance against the `tasks.md` dossier, and produces structured findings without modifying code.
---

Please deep think / ultrathink as this is a complex task. 

# plan-7-code-review

Per-phase diff audit & code review (read-only)

Goal: read the diffs for **one implemented phase**, validate they match the approved brief and tasks, and return a structured **review report** with findings, severity, and actionable fix suggestions (patch hints + fix-tasks). Do **not** edit code.

Why now: this runs after `plan-6-implement-phase`, leveraging its execution log, diffs, and test evidence; it enforces your planning gates and rules before merge.

```md
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
     PHASE_DIR   = PLAN_DIR/tasks/${PHASE_SLUG}  # abort if missing; phase tasks not generated
     PHASE_DOC   = PHASE_DIR/tasks.md            # abort if missing; plan-5 dossier not created
     EXEC_LOG    = PHASE_DIR/execution.log.md (required)
   - **Plan Footnotes Evidence**:
     Read the plan footer "Change Footnotes Ledger"; map footnote tags in `PHASE_DOC` to detailed node-ID entries
     (per `AGENTS.md`). Ensure numbering is sequential/unique and each changed file/method has a corresponding footnote entry.
   - Diffs source:
     a) If --diff-file provided -> use it as canonical unified diff
     b) Else if --base/--head provided -> run `git diff --unified=3 --no-color {base}..{head}`
     c) Else -> compute last phase range from EXEC_LOG hints or `git log` for the branch (document range)

2) Extract Testing Strategy from plan
   - Locate `## 6. Testing Philosophy` or `## Testing Approach` section in PLAN
   - Read **Testing Approach**: Full TDD | Lightweight | Manual | Hybrid
   - Read **Mock Usage**: Avoid mocks | Targeted mocks | Liberal mocks
   - Read **Focus Areas** and **Excluded** sections if present
   - If Testing Strategy section is missing, default to Full TDD and emit warning in review report
   - Store Testing Approach and Mock Usage for use in validation steps 3 and 4

3) Scope guard (PHASE ONLY)
   - Parse `PHASE_DOC` to list target files for this phase; ensure the diff touches only those or justified neighbors.
   - If violations (files outside scope without justification in the alignment brief section of `PHASE_DOC` or EXEC_LOG), flag as HIGH.

4) Rules & doctrine gates (adapt to Testing Strategy)
   - Extract Testing Approach from step 2 (Full TDD | Lightweight | Manual | Hybrid)
   - Apply approach-specific validation:

   **For Full TDD:**
     - **TDD order** (tests precede implementation in history/evidence) - CRITICAL if missing
     - **Tests as documentation** assertions (clear behavioral expectations) - CRITICAL if missing
     - **Mock usage matches spec preference** (avoid/targeted/liberal) - CRITICAL if mismatched
     - **RED-GREEN-REFACTOR cycles documented** in execution log - HIGH if missing

   **For Lightweight:**
     - **Core validation tests present** (focused on critical paths per spec Focus Areas) - HIGH if missing
     - **Mock usage matches spec preference** (avoid/targeted/liberal) - CRITICAL if mismatched
     - Skip comprehensive TDD order checks (implementation-first is acceptable)
     - Skip RED-GREEN-REFACTOR cycle requirements

   **For Manual:**
     - **Manual verification steps documented** in execution log - HIGH if missing
     - **Manual test results recorded** with observed outcomes - HIGH if missing
     - Skip automated test checks entirely
     - No mock usage checks (not applicable)

   **For Hybrid:**
     - Check phase-specific annotations in task table or phase documentation
     - Apply Full TDD rules to phases/tasks marked as requiring TDD
     - Apply Lightweight rules to phases/tasks marked as Lightweight
     - **Mock usage matches spec preference** globally - CRITICAL if mismatched

   **Universal checks (all approaches):**
     - Absolute paths and explicitness (no hidden context assumptions) - HIGH if violated
     - Plan/Rules conformance with `docs/rules-idioms-architecture/{rules.md, idioms.md}` - HIGH if violated

   - BridgeContext patterns when applicable to VS Code/TS:
     - Use `vscode.Uri` (not Node `path`) for paths
     - Use bounded `vscode.RelativePattern` (+ exclude + maxResults) for searches
     - Avoid `workspace.findFiles('**/*')` without bounds
     - Python debugging uses `{ module: 'pytest', args: ['--no-cov', ...] }` (never `program`)
     Flag deviations with precise line refs and patch hints. :contentReference[oaicite:5]{index=5}

5) Testing evidence & coverage alignment (adapt to Testing Strategy)
   - Cross-check the alignment brief acceptance criteria in `PHASE_DOC` against evidence based on Testing Approach:

   **For Full TDD approach:**
     - Verify test changes exist (added/updated tests in `tests/` or stack-native locations)
     - Ensure negative/edge/concurrency cases are present, not just happy paths
     - Map each acceptance criterion to at least one assertion that proves behavior (quote minimal assertion snippets)
     - Confirm `PHASE_DIR/execution.log.md` captures RED/GREEN/REFACTOR evidence for each task
     - Verify every item listed under `## Evidence Artifacts` in `PHASE_DOC` exists and is up to date inside `PHASE_DIR`
     - If a criterion lacks test coverage, mark HIGH with test-first fix suggestion

   **For Lightweight approach:**
     - Verify core validation tests exist for critical paths identified in spec Focus Areas
     - Check that Focus Areas from Testing Strategy are covered by validation tests
     - Confirm execution log shows validation test results and key verification points
     - Map critical acceptance criteria to validation tests (not required for all criteria)
     - If critical paths are untested, mark HIGH with validation test suggestion
     - Accept that comprehensive edge case coverage may be absent (per spec Excluded section)

   **For Manual approach:**
     - Verify execution log documents manual verification steps with clear expected outcomes
     - Check that manual test results include observed behaviors and outcomes
     - Confirm all acceptance criteria have corresponding manual verification entries
     - Look for screenshots, command output, or manual test logs as evidence artifacts
     - If manual verification is incomplete or undocumented, mark HIGH with specific checklist gaps

   **For Hybrid approach:**
     - Identify which tasks/phases are annotated as TDD vs Lightweight (check task table or phase doc)
     - Apply Full TDD evidence checks to tasks marked as requiring TDD
     - Apply Lightweight evidence checks to tasks marked as Lightweight
     - Verify phase annotations align with Testing Strategy guidance from spec
     - If mixed approach is inconsistent with spec, mark MEDIUM with clarification needed

   **Universal checks (all approaches):**
     - Verify every item listed under `## Evidence Artifacts` in `PHASE_DOC` exists inside `PHASE_DIR`
     - Confirm execution log is complete and matches the approach's expected format

6) Quality and safety review (diff-level)
   Review each hunk for:
   - **Correctness:** obvious logic defects, off-by-one, error handling
   - **Observability:** meaningful logs/metrics where required by plan/rules
   - **Performance:** unbounded scans, N+1, sync I/O in async paths
   - **Security:** path traversal, injection, unsafe temp files, secrets
   - **Remote-safety:** avoid Node `fs/path` where VS Code FS/Uri APIs are required
   Return precise comments with file:line and a one-paragraph rationale; attach patch hints when small. :contentReference[oaicite:7]{index=7} :contentReference[oaicite:8]{index=8}

7) Static & type checks (project-native)
   - Run project-native linters/type-checkers/formatters as specified by PLAN and `PHASE_DOC` (e.g., `just test-extension`, `pytest -q`, `eslint --max-warnings=0`, `tsc --noEmit`).
   - Capture command lines and summarized output. If tools are not defined, note that and recommend adding to rules. :contentReference[oaicite:9]{index=9}

8) Output files (write under PLAN_DIR/reviews/)
   - `PLAN_DIR/reviews/review.${PHASE_SLUG}.md` (the report)
     Sections:
     A) **Verdict**: APPROVE / REQUEST_CHANGES (STRICT mode: any HIGH -> REQUEST_CHANGES)
     B) **Summary** (<=10 lines)
     C) **Checklist** (adapt to Testing Strategy from plan)

        **Testing Approach: [Full TDD | Lightweight | Manual | Hybrid]**

        For Full TDD:
        - [ ] Tests precede code (RED-GREEN-REFACTOR evidence)
        - [ ] Tests as docs (assertions show behavior)
        - [ ] Mock usage matches spec: [Avoid | Targeted | Liberal]
        - [ ] Negative/edge cases covered

        For Lightweight:
        - [ ] Core validation tests present
        - [ ] Critical paths covered (per spec Focus Areas)
        - [ ] Mock usage matches spec: [Avoid | Targeted | Liberal]
        - [ ] Key verification points documented

        For Manual:
        - [ ] Manual verification steps documented
        - [ ] Manual test results recorded with observed outcomes
        - [ ] All acceptance criteria manually verified
        - [ ] Evidence artifacts present (screenshots, logs)

        For Hybrid:
        - [ ] TDD tasks follow Full TDD checklist
        - [ ] Lightweight tasks follow Lightweight checklist
        - [ ] Phase annotations match Testing Strategy
        - [ ] Mock usage matches spec globally

        Universal (all approaches):
        - [ ] BridgeContext patterns followed (Uri, RelativePattern, module: 'pytest')
        - [ ] Only in-scope files changed
        - [ ] Linters/type checks are clean
        - [ ] Absolute paths used (no hidden context)
     D) **Findings Table**
        | ID | Severity | File:Lines | Summary | Recommendation |
        |----|----------|------------|---------|----------------|
     E) **Inline Comments** (ordered by file, include minimal code blocks)
     F) **Coverage Map** (acceptance criteria <-> test files/assertions)
     G) **Commands Executed** (copy/paste)
     H) **Decision & Next Steps** (who approves; what to fix)
     I) **Footnotes Audit**: summary table listing each diff-touched path, associated footnote tag(s) from `PHASE_DOC`, and node-ID link(s) recorded in the plan ledger.
   - `PLAN_DIR/reviews/fix-tasks.${PHASE_SLUG}.md` (only if REQUEST_CHANGES)
     - Micro-tasks with exact file paths + patch hints
     - Fix ordering adapted to Testing Approach:
       * Full TDD: Tests-first ordering (what to assert, then code)
       * Lightweight: Validation tests for critical paths
       * Manual: Manual verification checklist items
       * Hybrid: Approach-specific per task

8) Style & constraints
   - Read-only: do not change source files.
   - Patches are hints only (unified diff snippets in the report).
   - Keep report deterministic and terse; quote only minimal context.

Acceptance criteria for this command
- Review report exists with a clear verdict and a complete findings table.
- Testing Approach from plan is identified and correctly applied to all validation checks.
- Every HIGH/CRITICAL finding has a concrete, minimal fix path (approach-appropriate: test-first for Full TDD, validation tests for Lightweight, manual checklist for Manual).
- Coverage map demonstrates acceptance criteria are validated per Testing Approach (test assertions for TDD/Lightweight, manual verification for Manual).
- If APPROVE: zero HIGH/CRITICAL, all gates pass for the specified Testing Approach. If REQUEST_CHANGES: fix tasks file created with approach-appropriate recommendations.

Notes:
- Plan and rules are authorities; if conflicts arise, rules win unless constitution deviation is logged in the plan. :contentReference[oaicite:10]{index=10} :contentReference[oaicite:11]{index=11}
```

Review rubric baked into this phase

- **Doctrine** (adapt to Testing Strategy from plan):
  - **Full TDD**: TDD order enforced (tests before code), tests-as-documentation required (assertions show behavior), RED-GREEN-REFACTOR cycles documented in execution log
  - **Lightweight**: Core validation tests required (focus on critical paths per spec Focus Areas), implementation-first acceptable, skip comprehensive edge case coverage if excluded in spec
  - **Manual**: Manual verification steps documented with clear expected outcomes, observed results recorded in execution log, evidence artifacts present (screenshots/logs)
  - **Hybrid**: Per-phase/per-task approach applied based on annotations - Full TDD rules for TDD-marked work, Lightweight rules for Lightweight-marked work
  - **Mock usage** (all approaches except Manual): Must align with spec preference (avoid/targeted/liberal) - CRITICAL if mismatched
  - **Real repo data/fixtures** whenever the Testing Strategy policy requires it
  - Flag drift as CRITICAL/HIGH with approach-appropriate fix guidance (test-first for Full TDD, validation tests for Lightweight, manual checklist for Manual)
- **BridgeContext patterns** for VS Code/TypeScript work: bounded `vscode.RelativePattern`, remote-safe `vscode.Uri`, pytest debug via `module` not `program` with `--no-cov`.
- **Plan authority**: Changes must map to the locked structure and explicit acceptance criteria from planning. Testing evidence must match the Testing Approach documented in the plan.

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
