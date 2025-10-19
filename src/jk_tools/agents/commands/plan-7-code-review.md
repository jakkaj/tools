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
   - Read **Testing Approach**: Full TDD | TAD | Lightweight | Manual | Hybrid
   - Read **Mock Usage**: Avoid mocks | Targeted mocks | Liberal mocks
   - Read **Focus Areas** and **Excluded** sections if present
   - If Testing Strategy section is missing, default to Full TDD and emit warning in review report
   - Store Testing Approach and Mock Usage for use in validation steps 4 and 5

3) Scope guard (PHASE ONLY)
   - Parse `PHASE_DOC` to list target files for this phase; ensure the diff touches only those or justified neighbors.
   - If violations (files outside scope without justification in the alignment brief section of `PHASE_DOC` or EXEC_LOG), flag as HIGH.

3a) Bidirectional Link Validation (CRITICAL for graph integrity)

**IMPORTANT**: This step uses **parallel subagent validation** for comprehensive and efficient graph integrity checks.

**Strategy**: Launch 5 validators simultaneously (single message with 5 Task tool calls), one per link type. Each validator focuses on specific graph edges, then results are synthesized into unified findings.

**Subagent Breakdown**:

**Subagent 1 - Task↔Log Validator**:
"Validate bidirectional links between tasks and execution logs.

**Read**:
- `${TARGET_DOC}` (dossier tasks table)
- `${TASK_LOG}` (execution log entries)

**Check**:
- Every completed task ([x]) has `log#anchor` in Notes column
- Every log entry has **Dossier Task** metadata and backlink (e.g., `**Dossier Task**: T003` and link)
- Every log entry has **Plan Task** metadata and backlink (e.g., `**Plan Task**: 2.3` and link)
- Log anchors match actual heading format (kebab-case)

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH\", \"task_id\": \"T003\", \"issue\": \"Missing log anchor in Notes\", \"expected\": \"log#task-23-implement-validation\", \"fix\": \"Add log anchor to Notes column\", \"impact\": \"Cannot navigate to execution evidence\"},
    ...
  ],
  \"validated_count\": N,
  \"broken_links_count\": M
}
```
"

**Subagent 2 - Task↔Footnote Validator**:
"Validate bidirectional links between tasks and footnotes.

**Read**:
- `${TARGET_DOC}` (tasks table + § Phase Footnote Stubs)
- `${PLAN}` § 12 (Change Footnotes Ledger)

**Check**:
- Every task with modified files has [^N] in Notes
- Every [^N] in dossier tasks has entry in dossier stubs
- Every [^N] in dossier stubs matches plan § 12 (same number, same content)
- Footnote numbers sequential, no duplicates/gaps

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"CRITICAL\", \"footnote\": \"[^3]\", \"issue\": \"Plan has [^3] but dossier missing\", \"expected\": \"Both ledgers have matching [^3]\", \"fix\": \"Run plan-6a to sync ledgers\", \"impact\": \"Breaks File→Task traversal\"},
    ...
  ],
  \"synchronized\": true/false,
  \"next_footnote\": N
}
```
"

**Subagent 3 - Footnote↔File Validator**:
"Validate FlowSpace node IDs point to actual modified files.

**Read**:
- `${PLAN}` § 12 (all FlowSpace node IDs)
- `${DIFF}` (unified diff showing modified files)

**Check**:
- Every FlowSpace node ID points to file in diff
- Every node ID follows format: `(class|method|function|file):<path>:<symbol>`
- Class/method/function names exist in actual code
- If embedded comments present (Step C3a), verify they match footnote numbers

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH\", \"node_id\": \"function:missing.py:func\", \"issue\": \"File not in diff\", \"fix\": \"Remove from footnote or add to diff\", \"impact\": \"Broken provenance link\"},
    {\"severity\": \"MEDIUM\", \"node_id\": \"validate_email\", \"issue\": \"Invalid format (missing prefix)\", \"fix\": \"Should be function:path:validate_email\"},
    ...
  ],
  \"valid_count\": N,
  \"invalid_count\": M
}
```
"

**Subagent 4 - Plan↔Dossier Sync Validator**:
"Validate plan and dossier task tables are synchronized.

**Read**:
- `${PLAN}` § 8 (plan task table)
- `${TARGET_DOC}` (dossier task table)

**Check**:
- Every plan task has matching dossier task with same Status
- Plan Log column has [📋] link to correct execution log anchor
- Plan Notes has footnote tag matching dossier Notes footnote
- Status checkboxes match: [ ]/[~]/[x]/[!]

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"CRITICAL\", \"plan_task\": \"2.3\", \"dossier_task\": \"T003\", \"issue\": \"Status mismatch - plan [x] vs dossier [ ]\", \"fix\": \"Run plan-6a to sync\", \"impact\": \"Progress tracking unreliable\"},
    {\"severity\": \"HIGH\", \"plan_task\": \"2.4\", \"issue\": \"Missing [📋] log link in Log column\", \"fix\": \"Add link to Log column\"},
    ...
  ],
  \"synchronized\": true/false
}
```
"

**Subagent 5 - Parent↔Subtask Validator**:
"Validate bidirectional parent-subtask links (if subtasks exist).

**Read**:
- `${PLAN}` § Subtasks Registry
- `${PHASE_DIR}` (list subtask files)
- Parent tasks in `${TARGET_DOC}`

**Check**:
- Every subtask in registry has matching file in PHASE_DIR
- Every subtask file has Parent Context § with parent task ID
- Parent task has subtask listed in Subtasks column
- Subtask status in registry matches completion state

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH\", \"subtask\": \"001-subtask-fixtures\", \"issue\": \"Parent task T003 missing subtask in Subtasks column\", \"fix\": \"Update Subtasks column to include 001-subtask-fixtures\", \"impact\": \"Cannot navigate from parent to subtask\"},
    {\"severity\": \"MEDIUM\", \"subtask\": \"003-subtask-bulk\", \"issue\": \"Registry shows Pending but file shows Complete\", \"fix\": \"Update registry status to [x] Complete\"},
    ...
  ],
  \"subtasks_found\": N,
  \"violations_count\": M
}
```
"

**Wait for All Validators**: Block until all 5 subagents complete their validation.

**Synthesize Results**:

After all validators complete:
1. Collect violations from each subagent
2. Deduplicate overlapping issues
3. Sort by severity (CRITICAL → HIGH → MEDIUM → LOW)
4. Merge into unified findings table:

| ID | Severity | Link Type | Issue | Expected | Fix | Impact |
|----|----------|-----------|-------|----------|-----|--------|
| V1 | CRITICAL | Task↔Footnote | Plan has [^3] but dossier missing | Both ledgers match | Run plan-6a to sync | Breaks File→Task traversal |
| V2 | CRITICAL | Plan↔Dossier | Status mismatch - plan [x] vs dossier [ ] | Statuses synchronized | Run plan-6a --task 2.3 --status completed | Progress tracking unreliable |
| ... | ... | ... | ... | ... | ... | ... |

5. Calculate graph integrity score:
   - 0 violations = ✅ INTACT
   - 1-2 medium/low = ⚠️ MINOR_ISSUES
   - 1+ high or 1+ critical = ❌ BROKEN

6. Add to review report § Step 3a findings.

**Violations Reporting**:
For each violation, include:
- **Severity**: CRITICAL | HIGH | MEDIUM | LOW (from validator output)
- **Link Type**: Which graph edge is broken (Task↔Log, Task↔Footnote, etc.)
- **Issue**: Precise description (from validator)
- **Expected**: What should exist (from validator)
- **Fix**: How to repair (from validator)
- **Impact**: Effect on graph traversability (from validator)

**Graph Integrity Verdict**:
- ✅ INTACT (0 violations) → APPROVE (for this step)
- ⚠️ MINOR_ISSUES (1-2 medium/low) → APPROVE with warnings
- ❌ BROKEN (any high/critical) → REQUEST_CHANGES (must fix before merge)

4) Rules & doctrine gates (parallel subagent validation)

   **IMPORTANT**: This step uses **parallel subagent validation** for approach-specific testing doctrine compliance and universal pattern checks.

   **Strategy**: Launch 3-4 validators simultaneously (based on Testing Approach), one per validation domain. Each validator focuses on specific compliance rules, then results are synthesized into unified doctrine findings.

   **4a) Extract Testing Approach** from step 2:
   - Read Testing Approach: Full TDD | TAD | Lightweight | Manual | Hybrid
   - Read Mock Usage preference: Avoid mocks | Targeted mocks | Liberal mocks
   - Store for subagent context

   **4b) Launch parallel validation subagents** (3-4 subagents based on approach):

   **Subagent 1: TDD Validator** (if Testing Approach = Full TDD or Hybrid with TDD tasks)
   "You are a TDD Compliance Auditor. Validate strict Test-Driven Development discipline.

   **Inputs:**
   - PHASE_DOC (tasks.md dossier)
   - EXEC_LOG (execution.log.md)
   - Diff hunks for test files and implementation files

   **Validation Checks:**

   1. **TDD order**: Tests precede implementation in git history/commit evidence
      - Parse EXEC_LOG for RED-GREEN-REFACTOR cycle timestamps
      - Cross-check diff hunks: test assertions added before implementation code
      - Look for commit messages or log entries showing test-first workflow
      - **Severity**: CRITICAL if order violated (implementation committed before tests)

   2. **Tests as documentation**: Assertions show clear behavioral expectations
      - Inspect test assertions for descriptive naming and intent
      - Verify test names describe behavior (e.g., test_whenUserLogsIn_thenSessionCreated)
      - Check that assertions document expected outcomes clearly
      - Verify negative/edge cases are documented via tests (not just happy paths)
      - **Severity**: CRITICAL if assertions are opaque, generic, or missing behavioral context

   3. **RED-GREEN-REFACTOR cycles**: Documented in execution log
      - Check EXEC_LOG for explicit RED (failing test), GREEN (passing), REFACTOR phases
      - Each task should show: write test → fails → write code → passes → refactor
      - **Severity**: HIGH if cycles not documented in EXEC_LOG

   **Report** (JSON format):
   ```json
   {
     \"findings\": [
       {\"id\": \"TDD-001\", \"severity\": \"CRITICAL|HIGH|MEDIUM|LOW\", \"file\": \"absolute/path/to/file.ts\", \"lines\": \"123-145\", \"issue\": \"One-sentence description\", \"evidence\": \"Quote from diff/log\", \"fix\": \"Specific actionable fix (2-3 sentences)\", \"patch\": \"Unified diff snippet (optional, <10 lines)\"}
     ],
     \"violations_count\": N,
     \"compliance_score\": \"PASS|FAIL\"
   }
   ```

   If no violations found, return {\"findings\": [], \"violations_count\": 0, \"compliance_score\": \"PASS\"}."

   **Subagent 2: TAD Validator** (if Testing Approach = TAD or Hybrid with TAD tasks)
   "You are a Test-Assisted Development (TAD) Compliance Auditor. Validate TAD doctrine: Scratch→Promote workflow, Test Doc blocks as executable documentation.

   **Inputs:**
   - PHASE_DOC (tasks.md dossier)
   - EXEC_LOG (execution.log.md)
   - Diff hunks for tests/ directories (both scratch/ and promoted)
   - Project CI configuration files (.github/workflows/*, pytest.ini, jest.config.js, etc.)

   **Validation Checks:**

   1. **Test Doc blocks present** on all promoted tests (not in tests/scratch/)
      - Locate promoted test files (tests/unit/, tests/integration/, etc. - NOT tests/scratch/)
      - For each test function/class, verify Test Doc comment block exists
      - **Severity**: CRITICAL if any promoted test missing Test Doc block

   2. **Test Doc blocks complete**: All 5 required fields present
      - **Why**: Purpose and value of this test (why it exists, what gap it fills)
      - **Contract**: What behavior is guaranteed (clear behavioral expectation)
      - **Usage Notes**: How to read/maintain/extend this test
      - **Quality Contribution**: Which heuristic justifies promotion (Critical path | Opaque behavior | Regression-prone | Edge case)
      - **Worked Example**: Realistic scenario walkthrough with concrete inputs/outputs
      - **Severity**: HIGH if any field incomplete or missing

   3. **Promotion heuristic applied**: Tests kept add durable value
      - Check Quality Contribution field maps to one of the 4 promotion criteria:
        * **Critical path**: Core user journey or high-impact functionality
        * **Opaque behavior**: Complex logic not obvious from reading code
        * **Regression-prone**: Bug-fix or fragile code likely to break again
        * **Edge case**: Boundary condition or unusual scenario worth documenting
      - Verify rationale is specific and meaningful (not generic like \"useful test\")
      - **Severity**: MEDIUM if rationale weak, generic, or doesn't map to heuristic

   4. **Test naming follows Given-When-Then** format
      - Pattern: test_given<Context>_when<Action>_then<Outcome>
      - Alternative patterns acceptable if equally clear: test_<scenario>_<expected_result>
      - **Severity**: LOW if naming is unclear or doesn't convey behavior

   5. **tests/scratch/ excluded from CI**
      - Check .gitignore, CI workflow files, pytest.ini, jest.config.js for exclusion rules
      - Verify scratch tests are not run in CI pipelines
      - **Severity**: HIGH if scratch tests included in CI (defeats scratch purpose)

   6. **Promoted tests reliable**: No network, sleep, flakes
      - Scan promoted test code for:
        * Network calls (requests, httpx, fetch, axios, socket)
        * Time delays (time.sleep, setTimeout, arbitrary waits)
        * Non-deterministic behavior (random, Date.now() without mocking)
        * External service dependencies (APIs, databases, unless explicitly allowed by spec)
      - Check performance requirements from spec (if specified, e.g., \"tests must run in <5s\")
      - **Severity**: HIGH if unreliable patterns found in promoted tests

   7. **Scratch exploration documented** in execution log
      - Check EXEC_LOG for evidence of scratch exploration phase
      - Look for mentions of: scratch tests written, experiments run, promotion decisions
      - **Severity**: LOW if scratch exploration not mentioned (nice-to-have context)

   8. **Test Doc blocks read like high-fidelity documentation**
      - Assess clarity, realism, comprehension value of Worked Example field
      - Verify examples use concrete, realistic data (not \"foo/bar\" placeholders)
      - Check that Contract field describes observable behavior (not implementation details)
      - **Severity**: MEDIUM if Test Doc is terse, vague, or unhelpful for understanding

   **Report** (JSON format):
   ```json
   {
     \"findings\": [
       {\"id\": \"TAD-001\", \"severity\": \"CRITICAL|HIGH|MEDIUM|LOW\", \"file\": \"absolute/path/to/test_file.py\", \"lines\": \"45-78\", \"issue\": \"One-sentence description\", \"evidence\": \"Quote from test code/Test Doc\", \"fix\": \"Specific actionable fix (2-3 sentences)\", \"patch\": \"Complete Test Doc block template or diff snippet\"}
     ],
     \"promoted_tests_count\": N,
     \"violations_count\": M,
     \"compliance_score\": \"PASS|FAIL\"
   }
   ```

   If no violations found, return {\"findings\": [], \"promoted_tests_count\": N, \"violations_count\": 0, \"compliance_score\": \"PASS\"}."

   **Subagent 3: Mock Usage Validator** (all approaches except Manual)
   "You are a Mock Usage Compliance Auditor. Validate that mock usage aligns with the spec's declared preference.

   **Inputs:**
   - Mock Usage preference from Testing Strategy: Avoid mocks | Targeted mocks | Liberal mocks
   - Diff hunks for all test files
   - Testing Approach context (Full TDD | TAD | Lightweight | Hybrid)

   **Validation Checks:**

   1. **Mock usage matches spec preference**
      - Scan test code for mock frameworks and patterns:
        * Python: unittest.mock, MagicMock, @patch, mocker fixture (pytest-mock)
        * TypeScript/JavaScript: jest.mock, sinon, @testing-library mocks
        * Count mock instances per test file and per test function
      - Apply policy-specific validation:

      **For \"Avoid mocks\" policy:**
      - Flag ANY mock usage as CRITICAL violation
      - Check for real data/fixtures/integration test setup instead
      - Acceptable exceptions: external services explicitly unreachable (document in spec)

      **For \"Targeted mocks\" policy:**
      - Flag liberal/excessive mocking as HIGH violation
      - Threshold: >3 mocks per test function, or >50% of tests using mocks
      - Check that mocks are used only for external boundaries (APIs, filesystem, time)
      - Flag internal class/method mocking as MEDIUM (indicates tight coupling)

      **For \"Liberal mocks\" policy:**
      - Accept any mock usage without restriction
      - No violations unless mocks break tests (wrong setup, incomplete stubs)

   2. **Real data/fixtures used** (if \"Avoid mocks\" or \"Targeted mocks\" policy)
      - Check for fixture files, real repo data, integration test setup
      - Verify tests use actual implementations for internal code
      - **Severity**: HIGH if mocks used instead of real data when policy requires it

   3. **Mock quality** (if mocks are used and allowed):
      - Verify mocks have realistic return values (not just empty objects)
      - Check that mocks match actual interface contracts
      - Flag incomplete or incorrect mock setups
      - **Severity**: MEDIUM if mock quality is poor (breaks test realism)

   **Report** (JSON format):
   ```json
   {
     \"findings\": [
       {\"id\": \"MOCK-001\", \"severity\": \"CRITICAL|HIGH|MEDIUM|LOW\", \"file\": \"absolute/path/to/test_file.ts\", \"lines\": \"67-89\", \"issue\": \"One-sentence description of mock policy violation\", \"evidence\": \"Quote from test code showing mock usage\", \"fix\": \"Specific alternative (real fixture, integration test, or mock reduction)\", \"patch\": \"Diff snippet showing real data/fixture approach (optional, <10 lines)\"}
     ],
     \"policy\": \"Avoid mocks|Targeted mocks|Liberal mocks\",
     \"mock_instances_count\": N,
     \"violations_count\": M,
     \"compliance_score\": \"PASS|FAIL\"
   }
   ```

   If no violations found, return {\"findings\": [], \"policy\": \"...\", \"mock_instances_count\": N, \"violations_count\": 0, \"compliance_score\": \"PASS\"}."

   **Subagent 4: BridgeContext & Universal Validator** (always runs)
   "You are a Universal Patterns & BridgeContext Auditor. Validate absolute paths, plan/rules conformance, and BridgeContext patterns for remote-safety.

   **Inputs:**
   - PLAN (entire plan document)
   - docs/rules-idioms-architecture/rules.md (if exists)
   - docs/rules-idioms-architecture/idioms.md (if exists)
   - Diff hunks for all files (focus on TS/Python code)

   **Validation Checks:**

   1. **Absolute paths and explicitness**: No hidden context assumptions
      - Scan for relative path strings in code (./foo, ../bar, ../../config.json)
      - Check for missing path validation or assumptions about current working directory (CWD)
      - Verify file paths are resolved via explicit base (workspace root, config dir, etc.)
      - Flag any code that assumes paths exist without validation
      - **Severity**: HIGH if code uses relative paths or assumes CWD without explicit resolution

   2. **Plan/Rules conformance**
      - Cross-check diff changes against rules.md and idioms.md constraints (if they exist)
      - Verify plan acceptance criteria are honored (no out-of-scope changes)
      - Check that implementation matches plan architecture decisions
      - Ensure no violations of project-specific idioms or naming conventions
      - **Severity**: HIGH if plan/rules violated

   3. **BridgeContext patterns** (for VS Code/TypeScript work):
      Remote-safety is CRITICAL for VS Code extensions. Flag violations of these patterns:

      **Use vscode.Uri (not Node path module) for file paths:**
      - ❌ Wrong: const filePath = path.join(workspaceRoot, 'file.txt');
      - ✅ Correct: const fileUri = vscode.Uri.joinPath(workspaceRootUri, 'file.txt');
      - **Severity**: HIGH (breaks remote environments)

      **Use bounded vscode.RelativePattern with exclude + maxResults for searches:**
      - ❌ Wrong: workspace.findFiles('**/*')
      - ✅ Correct: workspace.findFiles(new vscode.RelativePattern(baseUri, '*.ts'), '**/node_modules/**', 100)
      - **Severity**: HIGH (unbounded searches hang in large repos)

      **Avoid workspace.findFiles('**/*') without bounds:**
      - Must specify exclude patterns and maxResults
      - **Severity**: HIGH (performance/reliability issue)

      **Python debugging uses { module: 'pytest', args: ['--no-cov', ...] } config:**
      - ❌ Wrong: { type: 'python', program: '/path/to/pytest' }
      - ✅ Correct: { type: 'debugpy', module: 'pytest', args: ['--no-cov', 'tests/'] }
      - **Severity**: HIGH (breaks remote debugging and coverage tools)

   **Report** (JSON format):
   ```json
   {
     \"findings\": [
       {\"id\": \"UNI-001\", \"severity\": \"CRITICAL|HIGH|MEDIUM|LOW\", \"file\": \"absolute/path/to/file.ts\", \"lines\": \"123-145\", \"issue\": \"One-sentence description\", \"evidence\": \"Quote from code\", \"fix\": \"Specific actionable fix (2-3 sentences)\", \"patch\": \"Unified diff snippet showing correct pattern (optional, <10 lines)\"}
     ],
     \"violations_count\": N,
     \"compliance_score\": \"PASS|FAIL\"
   }
   ```

   If no violations found, return {\"findings\": [], \"violations_count\": 0, \"compliance_score\": \"PASS\"}."

   **Wait for All Validators**: Block until all applicable subagents complete their validation.

   **4c) Synthesize subagent results**:

   After all validators complete:
   1. **Collect findings** from all launched subagents (JSON arrays)
   2. **Merge into single findings table** with unique IDs:
      - TDD-001, TDD-002, ... (from TDD Validator)
      - TAD-001, TAD-002, ... (from TAD Validator)
      - MOCK-001, MOCK-002, ... (from Mock Usage Validator)
      - UNI-001, UNI-002, ... (from BridgeContext & Universal Validator)
   3. **Deduplicate** overlapping issues (keep highest severity if same file:lines)
   4. **Aggregate severity counts**: CRITICAL, HIGH, MEDIUM, LOW
   5. **Calculate doctrine compliance score**:
      - CRITICAL findings: -100 points each
      - HIGH findings: -50 points each
      - MEDIUM findings: -10 points each
      - LOW findings: -2 points each
      - Base score: 100
      - **Verdict**: PASS if score >= 0 (no CRITICAL/HIGH), FAIL if score < 0
   6. **Set verdict flag**:
      - If any CRITICAL or HIGH findings: set REQUEST_CHANGES flag for step 8
      - If only MEDIUM/LOW findings: APPROVE with advisory notes
      - If no findings: APPROVE unconditionally
   7. **Pass merged findings table to step 8** for report generation (Section E.1: Doctrine & Testing Compliance)

   **Execution**: Run all applicable subagents **in parallel** (concurrent prompts), then synthesize. Total wall time should be ~1 subagent duration, not 3-4x sequential. :contentReference[oaicite:5]{index=5}

5) Testing evidence & coverage alignment (adapt to Testing Strategy)
   - Cross-check the alignment brief acceptance criteria in `PHASE_DOC` against evidence based on Testing Approach:

   **For Full TDD approach:**
     - Verify test changes exist (added/updated tests in `tests/` or stack-native locations)
     - Ensure negative/edge/concurrency cases are present, not just happy paths
     - Map each acceptance criterion to at least one assertion that proves behavior (quote minimal assertion snippets)
     - Confirm `PHASE_DIR/execution.log.md` captures RED/GREEN/REFACTOR evidence for each task
     - Verify every item listed under `## Evidence Artifacts` in `PHASE_DOC` exists and is up to date inside `PHASE_DIR`
     - If a criterion lacks test coverage, mark HIGH with test-first fix suggestion

   **For TAD (Test-Assisted Development) approach:**
     - Verify promoted tests exist in tests/unit/ or tests/integration/ (not in scratch/)
     - Check that each promoted test has complete Test Doc comment block with all 5 required fields (Why, Contract, Usage Notes, Quality Contribution, Worked Example)
     - Confirm Test Doc blocks read like high-fidelity documentation (clear, realistic, valuable for comprehension)
     - Verify promotion decisions align with heuristic: tests kept are Critical path, Opaque behavior, Regression-prone, or Edge case
     - Check execution log documents scratch exploration phase and promotion rationale
     - Confirm tests/scratch/ directory is excluded from CI configuration (.gitignore, CI config, or test runner config)
     - Validate promoted tests are reliable: no network calls, sleep, or flaky dependencies (performance requirements per spec)
     - Verify test names follow Given-When-Then format (or equivalent clear behavioral naming)
     - If promoted tests lack complete Test Doc blocks, mark CRITICAL with documentation requirements
     - If tests don't provide comprehension value or promotion rationale is weak, mark MEDIUM with heuristic review
     - Accept that not all acceptance criteria have test coverage (TAD focuses on valuable tests, not comprehensive coverage)

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

6) Quality and safety review (parallel subagent analysis)

   Launch **4 parallel specialized reviewers** as subagents. Each reviewer inspects the unified diff independently, outputs findings in a structured format, then synthesize into a unified safety report.

   **Subagent 1: Correctness Reviewer**
   ```
   You are a Correctness Reviewer for code changes. Analyze the provided unified diff and identify logic defects, error handling gaps, and algorithmic issues.

   **Focus Areas:**
   - Logic defects (off-by-one errors, incorrect conditionals, wrong operators)
   - Error handling gaps (missing try/catch, unchecked null/undefined, unhandled promises)
   - Race conditions and concurrency bugs
   - Incorrect state mutations or side effects
   - Type mismatches or coercion issues
   - Boundary condition violations

   **Output Format:**
   For each finding, return:
   {
     "severity": "CRITICAL|HIGH|MEDIUM|LOW",
     "file": "absolute/path/to/file.ts",
     "lines": "123-145",
     "issue": "One-sentence description of the defect",
     "impact": "What breaks or fails if this ships",
     "fix": "Specific actionable fix (2-3 sentences)",
     "patch": "Unified diff snippet showing the fix (optional, only if < 10 lines)"
   }

   **Severity Guidelines:**
   - CRITICAL: Crashes, data corruption, security breach
   - HIGH: Wrong behavior, silent failures, broken core features
   - MEDIUM: Edge case bugs, poor error messages, degraded UX
   - LOW: Code smells, minor inefficiencies

   Return JSON array of findings. If no issues found, return empty array [].
   ```

   **Subagent 2: Security Reviewer**
   ```
   You are a Security Reviewer for code changes. Analyze the provided unified diff for security vulnerabilities and unsafe patterns.

   **Focus Areas:**
   - Path traversal (unvalidated file paths, missing canonicalization)
   - Injection vulnerabilities (SQL, command, code injection)
   - Secrets in code (API keys, passwords, tokens, credentials)
   - Unsafe temp file usage (predictable names, race conditions)
   - Insufficient input validation/sanitization
   - Authentication/authorization bypasses
   - Insecure cryptography or random number generation
   - Information disclosure (verbose errors, debug logs in production)

   **Output Format:**
   For each finding, return:
   {
     "severity": "CRITICAL|HIGH|MEDIUM|LOW",
     "file": "absolute/path/to/file.ts",
     "lines": "123-145",
     "issue": "One-sentence description of the vulnerability",
     "impact": "Exploitation scenario and consequences",
     "fix": "Specific mitigation strategy (2-3 sentences)",
     "patch": "Unified diff snippet showing the fix (optional, only if < 10 lines)"
   }

   **Severity Guidelines:**
   - CRITICAL: Remote code execution, privilege escalation, data exfiltration
   - HIGH: Authentication bypass, sensitive data exposure, injection attacks
   - MEDIUM: Information leaks, weak crypto, incomplete validation
   - LOW: Defense-in-depth gaps, hardening opportunities

   Return JSON array of findings. If no issues found, return empty array [].
   ```

   **Subagent 3: Performance Reviewer**
   ```
   You are a Performance Reviewer for code changes. Analyze the provided unified diff for performance regressions and scalability issues.

   **Focus Areas:**
   - Unbounded scans (iterating all items without pagination/limits)
   - N+1 queries (loops with I/O inside, missing batch operations)
   - Synchronous I/O in async code paths (blocking event loop)
   - Inefficient algorithms (O(n²) where O(n log n) possible)
   - Memory leaks (unclosed resources, retained references)
   - Redundant computations (cache misses, repeated work)
   - Excessive allocations in hot paths

   **Output Format:**
   For each finding, return:
   {
     "severity": "CRITICAL|HIGH|MEDIUM|LOW",
     "file": "absolute/path/to/file.ts",
     "lines": "123-145",
     "issue": "One-sentence description of the performance issue",
     "impact": "Quantified performance degradation (latency/throughput/memory)",
     "fix": "Optimization strategy (2-3 sentences)",
     "patch": "Unified diff snippet showing the fix (optional, only if < 10 lines)"
   }

   **Severity Guidelines:**
   - CRITICAL: System hangs, OOM crashes, 10x+ latency regression
   - HIGH: User-visible slowness (>1s delay), unbounded resource growth
   - MEDIUM: 2-5x degradation, inefficient but bounded operations
   - LOW: Micro-optimizations, theoretical improvements

   Return JSON array of findings. If no issues found, return empty array [].
   ```

   **Subagent 4: Observability Reviewer**
   ```
   You are an Observability Reviewer for code changes. Analyze the provided unified diff for logging, metrics, and debugging gaps.

   **Focus Areas:**
   - Missing error logs at failure points
   - Insufficient context in log messages (no request IDs, user IDs, correlation data)
   - Missing performance metrics (timers, counters, gauges)
   - Logs that break in remote/distributed environments (using local paths, Node fs/path APIs in VS Code extensions)
   - Log level misuse (info for errors, debug for critical events)
   - Unstructured logs (hard to parse, no machine-readable format)
   - Missing audit trail for critical operations

   **Output Format:**
   For each finding, return:
   {
     "severity": "CRITICAL|HIGH|MEDIUM|LOW",
     "file": "absolute/path/to/file.ts",
     "lines": "123-145",
     "issue": "One-sentence description of the observability gap",
     "impact": "Debugging/monitoring consequence if this ships",
     "fix": "Specific logging/metrics addition (2-3 sentences)",
     "patch": "Unified diff snippet showing the fix (optional, only if < 10 lines)"
   }

   **Severity Guidelines:**
   - CRITICAL: No way to debug production failures, silent data corruption
   - HIGH: Missing error context, broken remote logging, no perf metrics for SLOs
   - MEDIUM: Incomplete logs, verbose noise, poor log hygiene
   - LOW: Nice-to-have context, debug log improvements

   **Special: Remote-Safety for VS Code Extensions**
   Flag any usage of Node `fs`, `path`, or local file system APIs where VS Code `vscode.Uri` or `vscode.workspace.fs` should be used. This is HIGH severity for extensions that must support remote environments.

   Return JSON array of findings. If no issues found, return empty array [].
   ```

   **Synthesis Process:**
   1. **Aggregate findings** from all 4 reviewers into a single JSON array
   2. **Deduplicate** findings with identical file:lines (keep highest severity)
   3. **Merge by file** for reporting (group findings by file, then by line range)
   4. **Calculate safety score**:
      - CRITICAL findings: -100 points each
      - HIGH findings: -50 points each
      - MEDIUM findings: -10 points each
      - LOW findings: -2 points each
      - Base score: 100
      - **Verdict**: APPROVE if score >= 0 (no CRITICAL/HIGH), REQUEST_CHANGES if score < 0
   5. **Generate Section E.2** (Quality & Safety Findings):
      ```markdown
      ## E.2 Quality & Safety Analysis

      **Safety Score: [X]/100** (CRITICAL: [N], HIGH: [M], MEDIUM: [P], LOW: [Q])
      **Verdict: [APPROVE | REQUEST_CHANGES]**

      ### Findings by File

      #### src/file1.ts
      **[CRITICAL]** Lines 45-52: Path traversal vulnerability
      - **Issue**: User-provided path concatenated without validation
      - **Impact**: Arbitrary file read/write outside workspace
      - **Fix**: Use `vscode.Uri.joinPath()` and validate against workspace root
      - **Patch**:
        ```diff
        - const fullPath = workspaceRoot + '/' + userPath;
        + const fullPath = vscode.Uri.joinPath(workspaceRoot, userPath);
        + if (!fullPath.fsPath.startsWith(workspaceRoot.fsPath)) {
        +   throw new Error('Path outside workspace');
        + }
        ```

      **[HIGH]** Lines 78-85: Missing error logging
      - **Issue**: Promise rejection swallowed without logging
      - **Impact**: Silent failures, impossible to debug production issues
      - **Fix**: Add structured error log with context (operation, input, stack)
      - **Patch**: (see fix-tasks.md for detailed patch)

      #### src/file2.ts
      **[MEDIUM]** Lines 123-145: N+1 query pattern
      - **Issue**: Database query inside loop (100+ iterations)
      - **Impact**: 50x slowdown for large datasets (5s+ latency)
      - **Fix**: Batch fetch all IDs upfront, use Map for O(1) lookup
      ```
   6. **Populate fix-tasks.md** (if REQUEST_CHANGES) with severity-ordered tasks:
      - CRITICAL first, then HIGH, then MEDIUM/LOW
      - Each task includes file, lines, issue, fix, and patch if available
      - Testing guidance per Testing Approach (test-first for TDD, validation for Lightweight, etc.)

   **Inputs to Reviewers:**
   - Unified diff from step 1 (either --diff-file or computed range)
   - Plan context (PLAN, PHASE_DOC) for rules/requirements awareness
   - Rules/idioms from `docs/rules-idioms-architecture/` if available

   **Execution:**
   Run all 4 reviewers **in parallel** (concurrent subagent prompts), then synthesize. Total wall time should be ~1 reviewer duration, not 4x sequential.

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

        For TAD (Test-Assisted Development):
        - [ ] Promoted tests have complete Test Doc blocks (Why/Contract/Usage/Quality/Example)
        - [ ] Test names follow Given-When-Then format
        - [ ] Promotion heuristic applied (tests add durable value)
        - [ ] tests/scratch/ excluded from CI
        - [ ] Promoted tests are reliable (no network/sleep/flakes; performance per spec)
        - [ ] Mock usage matches spec in promoted tests: [Avoid | Targeted | Liberal]
        - [ ] Scratch exploration documented in execution log
        - [ ] Test Doc blocks read like high-fidelity documentation

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
     E) **Detailed Findings**
        E.1) **Doctrine & Testing Compliance** (from steps 3a, 4, 5)
        E.2) **Quality & Safety Analysis** (from step 6 parallel reviewers - see synthesis format above)
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
  - **TAD (Test-Assisted Development)**: Tests as executable documentation, Scratch→Promote workflow enforced, Test Doc comment blocks required (5 fields: Why/Contract/Usage Notes/Quality Contribution/Worked Example), promotion heuristic applied (Critical/Opaque/Regression/Edge), iterative development acceptable, promoted tests must be reliable (no network/sleep/flakes) and valuable for comprehension, tests/scratch/ excluded from CI, performance requirements per spec
  - **Lightweight**: Core validation tests required (focus on critical paths per spec Focus Areas), implementation-first acceptable, skip comprehensive edge case coverage if excluded in spec
  - **Manual**: Manual verification steps documented with clear expected outcomes, observed results recorded in execution log, evidence artifacts present (screenshots/logs)
  - **Hybrid**: Per-phase/per-task approach applied based on annotations - Full TDD rules for TDD-marked work, TAD rules for TAD-marked work, Lightweight rules for Lightweight-marked work
  - **Mock usage** (all approaches except Manual): Must align with spec preference (avoid/targeted/liberal) - CRITICAL if mismatched
  - **Real repo data/fixtures** whenever the Testing Strategy policy requires it
  - Flag drift as CRITICAL/HIGH with approach-appropriate fix guidance (test-first for Full TDD, Test Doc blocks for TAD, validation tests for Lightweight, manual checklist for Manual)
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
