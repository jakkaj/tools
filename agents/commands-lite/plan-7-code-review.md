---
description: Read-only per-phase code review that inspects diffs, verifies doctrine compliance, and produces structured findings without modifying code.
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
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"
# Optional flags:
# --diff-file "<abs path to unified.diff>"   # if omitted, compute from git
# --base "<commit-ishA>" --head "<commit-ishB>"  # commit range; overrides --diff-file
# --pr-body "<abs path to PR.md>"            # if you want a PR summary file
# --strict                                   # treat HIGH as blocking

1) Resolve inputs & artifacts
   - PLAN = provided --plan
   - PLAN_DIR = dirname(PLAN)
   - PHASE_DOC = PLAN itself (read inline task table from `## Implementation (Single Phase)`)
   - EXEC_LOG = `${PLAN_DIR}/execution.log.md` (sibling to plan)
   - PHASE_DIR = PLAN_DIR (no separate phase directory)
   - **Artifact Tolerance**: Some artifacts may not exist:
     * No separate tasks.md dossier (tasks are inline in plan)
     * No cross-phase artifacts (single phase)
     * Execution log may be at plan level
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
   - Scope guard applies to inline task table paths in `## Implementation (Single Phase)` section.

3a) Bidirectional Link Validation

**IMPORTANT**: This step validates graph integrity between tasks and execution logs.

**Validation - Task↔Log**:
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

**Synthesize Results**:

After validation completes:
1. Collect violations
2. Sort by severity (CRITICAL → HIGH → MEDIUM → LOW)
3. Merge into unified findings table:

| ID | Severity | Link Type | Issue | Expected | Fix | Impact |
|----|----------|-----------|-------|----------|-----|--------|
| V1 | CRITICAL | Task↔Log | Missing log anchor for completed task | Log anchor present | Add log anchor to Notes column | Cannot navigate to execution evidence |
| ... | ... | ... | ... | ... | ... | ... |

4. Calculate graph integrity score:
   - 0 violations = ✅ INTACT
   - 1-2 medium/low = ⚠️ MINOR_ISSUES
   - 1+ high or 1+ critical = ❌ BROKEN

5. Add to review report § Step 3a findings.

**Violations Reporting**:
For each violation, include:
- **Severity**: CRITICAL | HIGH | MEDIUM | LOW (from validation output)
- **Link Type**: Which graph edge is broken (Task↔Log)
- **Issue**: Precise description
- **Expected**: What should exist
- **Fix**: How to repair
- **Impact**: Effect on graph traversability

**Graph Integrity Verdict**:
- ✅ INTACT (0 violations) → APPROVE (for this step)
- ⚠️ MINOR_ISSUES (1-2 medium/low) → APPROVE with warnings
- ❌ BROKEN (any high/critical) → REQUEST_CHANGES (must fix before merge)

3b) Cross-Phase Regression Guard

**SKIP**: Single phase plan — no previous phases to regress against.

4) Rules & doctrine gates (parallel subagent validation)

   **IMPORTANT**: This step uses **parallel subagent validation** for approach-specific testing doctrine compliance and universal pattern checks.

   **Strategy**: Launch 3-5 validators simultaneously (based on Testing Approach), one per validation domain. Each validator focuses on specific compliance rules, then results are synthesized into unified doctrine findings. Validators include: TDD (conditional), Mock Usage (conditional), BridgeContext & Universal (always), Plan Compliance (always), and Doctrine Evolution (always).

   **4a) Extract Testing Approach** from step 2:
   - Read Testing Approach: Full TDD | TAD | Lightweight | Manual | Hybrid
   - Read Mock Usage preference: Avoid mocks | Targeted mocks | Liberal mocks
   - Store for subagent context

   **4b) Launch parallel validation subagents** (3-5 subagents based on approach):

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

   **Subagent 2: Mock Usage Validator** (all approaches except Manual)
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

   **Subagent 3: BridgeContext & Universal Validator** (always runs)
   "You are a Universal Patterns & BridgeContext Auditor. Validate absolute paths, plan/rules conformance, and BridgeContext patterns for remote-safety.

   **Inputs:**
   - PLAN (entire plan document)
   - docs/project-rules/rules.md (if exists)
   - docs/project-rules/idioms.md (if exists)
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
      Remote-safety is CRITICAL for VS Code extensions. Flag violations of these 10 patterns:

      **Pattern 1: Use vscode.Uri (not Node path module) for file paths**
      - ❌ Wrong: `const filePath = path.join(workspaceRoot, 'file.txt');`
      - ✅ Correct: `const fileUri = vscode.Uri.joinPath(workspaceRootUri, 'file.txt');`
      - **Rationale**: Node `path` APIs assume local filesystem; breaks in remote/container/WSL environments
      - **Severity**: HIGH (breaks remote environments)

      **Pattern 2: Use bounded vscode.RelativePattern with exclude + maxResults for searches**
      - ❌ Wrong: `workspace.findFiles('**/*')`
      - ✅ Correct: `workspace.findFiles(new vscode.RelativePattern(baseUri, '*.ts'), '**/node_modules/**', 100)`
      - **Rationale**: Unbounded searches can scan millions of files (node_modules, build artifacts)
      - **Severity**: HIGH (unbounded searches hang in large repos)

      **Pattern 3: Avoid workspace.findFiles('**/*') without bounds**
      - Must specify exclude patterns and maxResults (always)
      - Common excludes: `**/node_modules/**`, `**/dist/**`, `**/.git/**`, `**/build/**`
      - Typical maxResults: 100 for UI pickers, 1000 for batch operations, 10000 absolute max
      - **Severity**: HIGH (performance/reliability issue)

      **Pattern 4: Python debugging uses { module: 'pytest', args: ['--no-cov', ...] } config**
      - ❌ Wrong: `{ type: 'python', program: '/path/to/pytest' }`
      - ✅ Correct: `{ type: 'debugpy', module: 'pytest', args: ['--no-cov', 'tests/'] }`
      - **Rationale**: Absolute paths break in containers/remote; module invocation is portable
      - **Severity**: HIGH (breaks remote debugging and coverage tools)

      **Pattern 5: Use vscode.workspace.getConfiguration() instead of process.env for settings**
      - ❌ Wrong: `const apiKey = process.env.MY_EXTENSION_API_KEY;`
      - ✅ Correct: `const config = vscode.workspace.getConfiguration('myExtension'); const apiKey = config.get('apiKey');`
      - **Rationale**: Environment variables are local process-specific; config syncs across remote connections
      - **Severity**: MEDIUM (breaks user settings in remote scenarios)

      **Pattern 6: Use vscode.tasks API instead of child_process for running commands**
      - ❌ Wrong: `child_process.exec('npm test', { cwd: workspaceRoot })`
      - ✅ Correct: `const task = new vscode.Task(...); vscode.tasks.executeTask(task);`
      - **Rationale**: child_process runs on extension host (wrong machine); tasks run in correct environment
      - **Severity**: HIGH (runs commands on wrong machine in remote)

      **Pattern 7: Use vscode.workspace.createFileSystemWatcher() with bounded patterns**
      - ❌ Wrong: `vscode.workspace.createFileSystemWatcher('**/*')`
      - ✅ Correct: `vscode.workspace.createFileSystemWatcher(new vscode.RelativePattern(baseUri, 'src/**/*.ts'))`
      - **Rationale**: Unbounded watchers consume file handles; bounded patterns are efficient
      - **Severity**: MEDIUM (performance degradation, file handle exhaustion)

      **Pattern 8: Always use Uri.fsPath for display, never manipulate path strings directly**
      - ❌ Wrong: `const display = uri.path.replace('/c:', 'C:\\');` (manual path manipulation)
      - ✅ Correct: `const display = uri.fsPath;` (handles platform differences automatically)
      - **Rationale**: Uri.fsPath handles Windows/Unix/UNC/remote paths correctly; manual manipulation breaks
      - **Severity**: MEDIUM (wrong paths displayed, file operations fail)

      **Pattern 9: Handle multi-root workspaces (check workspaceFolders array)**
      - ❌ Wrong: `const root = vscode.workspace.workspaceFolders[0];` (assumes single workspace)
      - ✅ Correct: `const folders = vscode.workspace.workspaceFolders ?? []; // handle null and iterate`
      - **Rationale**: Users can have 0 or multiple workspace folders; always handle array
      - **Severity**: HIGH (crashes on multi-root or no-workspace scenarios)

      **Pattern 10: Validate Uri.scheme for remote compatibility before file operations**
      - ❌ Wrong: `fs.readFileSync(uri.fsPath)` (assumes 'file:' scheme)
      - ✅ Correct: `if (uri.scheme === 'file') { await vscode.workspace.fs.readFile(uri); }`
      - **Rationale**: Remote/virtual URIs have schemes like 'vscode-remote', 'vscode-test-web'; Node fs APIs only work with 'file:' scheme
      - **Severity**: HIGH (crashes or wrong behavior in remote/web extensions)

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

   **Subagent 4: Plan Compliance Validator** (always runs)
   "You are a Plan Compliance Auditor. Validate that implementation matches the approved plan tasks, ADR constraints, and project rules/idioms.

   **Inputs:**
   - PLAN (plan.md with task table)
   - PHASE_DOC (tasks.md dossier or inline plan tasks for Simple Mode)
   - DIFF (unified diff of changes)
   - docs/adr/*.md (if exists)
   - docs/project-rules/rules.md (if exists)
   - docs/project-rules/idioms.md (if exists)

   **Validation Checks:**

   1. **Task Implementation Verification**:
      - Parse task table to extract: Task ID, Description, Target Files, Acceptance Criteria
      - For each task (T001, T002, etc.):
        * Locate corresponding diff hunks by target file path in Absolute Path(s) column
        * Assess whether diff implements the described behavior in Task column
        * Compare task's Validation column criteria against observable changes in diff
        * Check if acceptance criteria from plan are satisfied
      - Status per task:
        * **PASS**: Implementation clearly matches task description and acceptance criteria
        * **FAIL**: Implementation missing, incomplete, or contradicts task description
        * **N/A**: Task marked deferred, out-of-scope, or status is not [ ] or [x]
      - **Severity**: HIGH if task FAIL (missing/wrong implementation), MEDIUM if partial implementation

   2. **ADR Compliance** (if docs/adr/*.md exists):
      - Load each ADR file in docs/adr/
      - Extract Decision and Consequences sections
      - For each ADR constraint:
        * Check if diff changes violate the architectural decision
        * Look for patterns that contradict stated consequences
      - **Severity**: HIGH if ADR constraint violated
      - Skip this check gracefully if docs/adr/ directory doesn't exist

   3. **Rules/Idioms Compliance** (if docs/project-rules/ exists):
      - Load rules.md and idioms.md from docs/project-rules/
      - Extract conventions and requirements (naming, patterns, prohibited practices)
      - For each rule/idiom:
        * Check if diff changes violate documented conventions
        * Look for naming violations, pattern mismatches, prohibited code patterns
      - **Severity**: HIGH for rule violations, MEDIUM for idiom violations
      - Skip this check gracefully if docs/project-rules/ directory doesn't exist

   4. **Scope Creep Detection** (implementation went off-track):
      - **Unexpected Files**: Compare files in diff against all Absolute Path(s) in task table
        * Flag files modified that appear in NO task's target paths
        * Exception: Test files for tasks that specify "write tests" are expected
        * Exception: Config files explicitly mentioned in plan acceptance criteria
        * **Severity**: MEDIUM if unexpected file is minor (config, docs), HIGH if unexpected code file
      - **Excessive Changes**: For each task's target file, assess if changes go beyond task scope
        * Compare diff hunks against task description - did implementation do MORE than asked?
        * Flag "while I was in there" refactoring not mentioned in task
        * Flag feature additions beyond task acceptance criteria
        * Flag unrelated bug fixes or improvements bundled in
        * **Severity**: MEDIUM for minor scope expansion, HIGH for significant unplanned work
      - **Unplanned Functionality**: Look for new capabilities not in any task
        * New public APIs/functions not mentioned in plan
        * New configuration options not specified
        * New dependencies added without task justification
        * **Severity**: HIGH if adds user-facing functionality, MEDIUM if internal-only
      - **Gold Plating**: Detect over-engineering beyond requirements
        * Abstraction layers not required by plan
        * Premature optimization not in scope
        * Extra error handling beyond acceptance criteria
        * **Severity**: LOW for minor gold plating, MEDIUM if adds maintenance burden
      - For each scope creep finding, note:
        * What was expected (from plan)
        * What was actually done (from diff)
        * Whether this needs discussion or should be reverted

   **Report** (JSON format):
   ```json
   {
     \"findings\": [
       {\"id\": \"PLAN-001\", \"severity\": \"HIGH\", \"type\": \"missing_implementation\", \"task_id\": \"T003\", \"issue\": \"Task not implemented\", \"expected\": \"Add email validation per task description\", \"actual\": \"No validation code in diff for target file\", \"fix\": \"Implement email validation in specified file\"},
       {\"id\": \"PLAN-002\", \"severity\": \"HIGH\", \"type\": \"adr_violation\", \"adr\": \"ADR-0003\", \"issue\": \"ADR constraint violated\", \"constraint\": \"Use Repository pattern for data access\", \"violation\": \"Direct database calls in service layer\", \"fix\": \"Refactor to use Repository pattern per ADR-0003\"},
       {\"id\": \"PLAN-003\", \"severity\": \"MEDIUM\", \"type\": \"idiom_violation\", \"rule\": \"idioms.md\", \"issue\": \"Naming convention violated\", \"expected\": \"snake_case for functions\", \"actual\": \"camelCase used in new functions\", \"fix\": \"Rename functions to follow snake_case idiom\"},
       {\"id\": \"PLAN-004\", \"severity\": \"HIGH\", \"type\": \"scope_creep\", \"category\": \"unexpected_file\", \"file\": \"src/utils/helpers.py\", \"issue\": \"File modified but not in any task target paths\", \"expected\": \"Only modify files listed in task table\", \"actual\": \"Added new utility functions\", \"fix\": \"Either add task for this work or revert changes\"},
       {\"id\": \"PLAN-005\", \"severity\": \"MEDIUM\", \"type\": \"scope_creep\", \"category\": \"excessive_changes\", \"task_id\": \"T002\", \"file\": \"src/validators.py\", \"issue\": \"Changes exceed task scope\", \"expected\": \"Add email validation only\", \"actual\": \"Also refactored phone validation and added address validation\", \"fix\": \"Split into separate tasks or revert unplanned work\"},
       {\"id\": \"PLAN-006\", \"severity\": \"MEDIUM\", \"type\": \"scope_creep\", \"category\": \"gold_plating\", \"task_id\": \"T001\", \"issue\": \"Over-engineering beyond requirements\", \"expected\": \"Simple config loader\", \"actual\": \"Added plugin system, hot-reload, and validation framework\", \"fix\": \"Consider if complexity is justified or simplify\"}
     ],
     \"task_compliance\": {
       \"T001\": \"PASS\",
       \"T002\": \"PASS\",
       \"T003\": \"FAIL\",
       \"T004\": \"N/A - deferred\"
     },
     \"scope_creep_summary\": {
       \"unexpected_files\": [\"src/utils/helpers.py\"],
       \"excessive_changes_tasks\": [\"T002\"],
       \"gold_plating_tasks\": [\"T001\"],
       \"unplanned_functionality\": []
     },
     \"violations_count\": 6,
     \"compliance_score\": \"PASS|FAIL\"
   }
   ```

   If no violations found, return {\"findings\": [], \"task_compliance\": {...all PASS...}, \"scope_creep_summary\": {\"unexpected_files\": [], \"excessive_changes_tasks\": [], \"gold_plating_tasks\": [], \"unplanned_functionality\": []}, \"violations_count\": 0, \"compliance_score\": \"PASS\"}."

   **Subagent 5: Doctrine Evolution Analyzer** (always runs)
   "You are a Doctrine Evolution Analyst. Review the implemented code against existing ADRs, rules, and idioms to identify patterns that should be codified as new architectural decisions, rules, or idioms.

   **Inputs:**
   - DIFF (unified diff of all changes in this phase)
   - docs/adr/*.md (all existing ADRs, if directory exists)
   - docs/project-rules/*.md (all doctrine files - constitution, rules, idioms, architecture, and any future additions)
   - PLAN (for context on what was built and why)
   - EXEC_LOG (for implementation decisions and rationale)

   **Analysis Goals:**

   1. **ADR Candidate Detection**:
      - Scan diff for significant architectural decisions that emerged during implementation:
        * New integration patterns with external services/APIs
        * Technology choices (new libraries, frameworks, tools adopted)
        * Data flow patterns that define boundaries between components
        * Security/authentication approaches chosen
        * Error handling strategies that should be consistent
        * Performance trade-offs (caching, batching, lazy loading)
      - For each candidate, assess:
        * Is this decision reusable across the codebase?
        * Does it affect multiple components or future features?
        * Would a new team member benefit from knowing this decision?
        * Is there an existing ADR that should be updated instead?
      - Cross-check against existing ADRs:
        * Does this pattern reinforce an existing ADR? (note as positive evidence)
        * Does this pattern suggest an existing ADR needs updating? (flag for review)
        * Is this a genuinely new decision not covered by existing ADRs?

   2. **Rules Candidate Detection**:
      - Identify patterns in the diff that could become enforceable rules:
        * Consistent error handling patterns (e.g., always wrap external calls in try/catch)
        * Validation patterns (e.g., always validate input at service boundaries)
        * Logging conventions (e.g., always log entry/exit for public APIs)
        * Testing patterns (e.g., always mock external services in unit tests)
        * Naming conventions emerged from implementation
        * Code organization patterns (e.g., separate concerns into specific layers)
      - Evaluate rule candidates:
        * Is this pattern repeated 3+ times in the diff? (strong candidate)
        * Would violating this pattern cause bugs or inconsistency?
        * Is this enforceable via linting or code review?
        * Does this fill a gap in existing rules.md?

   3. **Idioms Candidate Detection**:
      - Look for recurring code patterns that should be documented:
        * Utility function patterns worth standardizing
        * Common data transformations
        * API call patterns (request/response handling)
        * State management approaches
        * Component composition patterns
        * Test fixture setup patterns
      - Evaluate idiom candidates:
        * Is this pattern elegant and worth copying?
        * Would documenting this help new contributors?
        * Does this show 'the right way' to do something in this codebase?
        * Is it specific enough to be actionable?

   4. **Architecture.md Update Detection**:
      - Identify structural changes that should be reflected in architecture docs:
        * New modules/services added
        * Changed boundaries between components
        * New integration points or data flows
        * Modified deployment topology
        * New anti-patterns discovered during implementation

   5. **Cross-Reference Analysis**:
      - Check if implementation reveals gaps in existing doctrine:
        * Situations where rules.md was silent but a rule was needed
        * Patterns that should have been in idioms.md
        * Architectural boundaries that were unclear
      - Check if implementation contradicts existing doctrine:
        * Code that works but doesn't follow documented patterns
        * Successful deviation that suggests doctrine needs updating

   **Report** (JSON format):
   ```json
   {
     \"adr_recommendations\": [
       {
         \"id\": \"ADR-REC-001\",
         \"type\": \"new|update\",
         \"existing_adr\": \"ADR-0003 (if update)\",
         \"title\": \"Use Circuit Breaker for External API Calls\",
         \"context\": \"Implementation added resilience patterns for payment API integration\",
         \"evidence\": [\"src/services/payment.ts:45-78\", \"src/services/shipping.ts:23-56\"],
         \"decision_summary\": \"Wrap all external HTTP calls in circuit breaker with 5s timeout, 3 retries\",
         \"consequences\": \"Adds ~10ms latency overhead; prevents cascade failures\",
         \"priority\": \"HIGH|MEDIUM|LOW\",
         \"rationale\": \"Pattern used in 3 places; critical for system resilience\"
       }
     ],
     \"rules_recommendations\": [
       {
         \"id\": \"RULE-REC-001\",
         \"type\": \"new|update\",
         \"existing_rule\": \"Section 3.2 (if update)\",
         \"rule_statement\": \"All external API calls MUST include timeout configuration\",
         \"evidence\": [\"src/services/payment.ts:52\", \"src/services/inventory.ts:34\"],
         \"enforcement\": \"Lintable via custom ESLint rule or code review checklist\",
         \"priority\": \"HIGH|MEDIUM|LOW\",
         \"rationale\": \"Prevents hanging requests; observed as consistent pattern\"
       }
     ],
     \"idioms_recommendations\": [
       {
         \"id\": \"IDIOM-REC-001\",
         \"type\": \"new|update\",
         \"title\": \"Result Type Pattern for Fallible Operations\",
         \"pattern_description\": \"Return {success: boolean, data?: T, error?: Error} instead of throwing\",
         \"code_example\": \"const result = await fetchUser(id);\\nif (!result.success) { handleError(result.error); }\",
         \"evidence\": [\"src/services/user.ts:67-89\", \"src/services/order.ts:45-67\"],
         \"priority\": \"MEDIUM|LOW\",
         \"rationale\": \"Explicit error handling; used consistently in new services\"
       }
     ],
     \"architecture_updates\": [
       {
         \"id\": \"ARCH-REC-001\",
         \"section\": \"Integration Points\",
         \"update_type\": \"add|modify\",
         \"description\": \"Add Payment Gateway integration to external services diagram\",
         \"evidence\": [\"src/services/payment.ts (new service)\"],
         \"priority\": \"MEDIUM\"
       }
     ],
     \"doctrine_gaps\": [
       {
         \"id\": \"GAP-001\",
         \"gap_type\": \"missing_rule|unclear_boundary|silent_on_pattern\",
         \"description\": \"No guidance on retry strategies for transient failures\",
         \"impact\": \"Inconsistent retry logic across services\",
         \"suggested_addition\": \"Add retry policy section to rules.md\"
       }
     ],
     \"positive_alignment\": [
       {
         \"doctrine_ref\": \"ADR-0002: Use Repository Pattern\",
         \"evidence\": [\"src/repositories/user.ts follows pattern exactly\"],
         \"note\": \"Implementation correctly follows existing ADR\"
       }
     ],
     \"summary\": {
       \"new_adrs_suggested\": 1,
       \"adr_updates_suggested\": 0,
       \"new_rules_suggested\": 2,
       \"rule_updates_suggested\": 1,
       \"new_idioms_suggested\": 1,
       \"architecture_updates_suggested\": 1,
       \"doctrine_gaps_found\": 1,
       \"positive_alignments_found\": 3
     }
   }
   ```

   **Priority Guidelines:**
   - **HIGH**: Pattern affects system reliability, security, or is used 5+ times
   - **MEDIUM**: Pattern improves consistency, used 3-4 times, benefits future work
   - **LOW**: Nice-to-have documentation, single occurrence worth noting

   **Important**: This subagent is advisory - recommendations don't block approval. Output is used to populate Section E.4 (Doctrine Evolution) in the review report."

   **Wait for All Validators**: Block until all applicable subagents complete their validation.

   **4c) Synthesize subagent results**:

   After all validators complete:
   1. **Collect findings** from all launched subagents (JSON arrays)
   2. **Merge into single findings table** with unique IDs:
      - TDD-001, TDD-002, ... (from TDD Validator)
      - MOCK-001, MOCK-002, ... (from Mock Usage Validator)
      - UNI-001, UNI-002, ... (from BridgeContext & Universal Validator)
      - PLAN-001, PLAN-002, ... (from Plan Compliance Validator)
      - DOCTRINE-REC-001, ... (from Doctrine Evolution Analyzer - advisory only)
   3. **Deduplicate** overlapping issues (keep highest severity if same file:lines)
   4. **Aggregate severity counts**: CRITICAL, HIGH, MEDIUM, LOW
   5. **Calculate doctrine compliance score**:
      - CRITICAL findings: -100 points each
      - HIGH findings: -50 points each
      - MEDIUM findings: -10 points each
      - LOW findings: -2 points each
      - Base score: 100
      - **Verdict**: PASS if score >= 0 (no CRITICAL/HIGH), FAIL if score < 0
      - **Note**: Doctrine Evolution recommendations (Subagent 5) do NOT affect score - they are advisory
   6. **Set verdict flag**:
      - If any CRITICAL or HIGH findings: set REQUEST_CHANGES flag for step 8
      - If only MEDIUM/LOW findings: APPROVE with advisory notes
      - If no findings: APPROVE unconditionally
   7. **Pass merged findings table to step 8** for report generation (Section E.1: Doctrine & Testing Compliance)
   8. **Extract Doctrine Evolution recommendations** to populate Section E.4 (new ADRs, rules, idioms suggested)

   **Execution**: Run all applicable subagents **in parallel** (concurrent prompts), then synthesize. Total wall time should be ~1 subagent duration, not 3-4x sequential.

5) Testing evidence & coverage alignment (adapt to Testing Strategy)
   - Cross-check the alignment brief acceptance criteria in `PHASE_DOC` against evidence based on Testing Approach:

   **Coverage Map Accuracy Validation** (applies to all approaches with tests):

   For each acceptance criterion → test mapping:

   1. **Explicit linkage check**:
      - Verify test names reference criterion IDs (e.g., `test_AC01_login_success`)
      - Check test docstrings/comments explicitly mention acceptance criteria
      - Look for criterion IDs in test file organization (e.g., `tests/ac01_login/`)
      - **Confidence score**: 100% if explicit ID reference, 75% if behavior match, 50% if inferred, 0% if unclear

   2. **Behavioral alignment verification**:
      - Compare acceptance criterion statement with test assertion
      - Verify test actually validates the specified behavior (not a related but different behavior)
      - Check test covers the full scope of criterion (not just subset)
      - Flag if test name is generic/unclear (e.g., `test_feature_works`)

   3. **Narrative test detection**:
      - Flag tests without clear criterion mapping as "narrative tests"
      - Narrative tests are informative but don't validate specific acceptance criteria
      - **Severity**: MEDIUM if critical criteria lack non-narrative tests
      - Examples of narrative tests:
        * Integration smoke tests ("everything works together")
        * Exploratory tests ("try various inputs")
        * Performance benchmarks without acceptance criteria thresholds

   4. **Coverage confidence reporting**:
      - Calculate per-criterion confidence score (0-100%):
        * 100%: Explicit criterion ID in test name/comment + behavioral match
        * 75%: Clear behavioral match but no explicit ID reference
        * 50%: Likely covers criterion (inferred from test behavior)
        * 25%: Weak/partial coverage (test exists but scope unclear)
        * 0%: No test found for this criterion
      - Report overall coverage confidence: (sum of all scores) / (number of criteria)
      - **Severity**:
        * HIGH if overall confidence < 50% (weak mappings dominate)
        * MEDIUM if overall confidence 50-75% (acceptable but improvable)
        * LOW if overall confidence > 75% (good mappings)

   5. **Recommendations for improving mapping**:
      - Suggest adding criterion IDs to test names
      - Recommend test file organization by acceptance criteria
      - Provide template for explicit test-to-criterion documentation

   **For Full TDD approach:**
     - Verify test changes exist (added/updated tests in `tests/` or stack-native locations)
     - Ensure negative/edge/concurrency cases are present, not just happy paths
     - Map each acceptance criterion to at least one assertion that proves behavior (quote minimal assertion snippets)
     - Confirm execution log captures RED/GREEN/REFACTOR evidence for each task
     - Verify every item listed under `## Evidence Artifacts` in `PHASE_DOC` exists and is up to date
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

   Launch **5 parallel specialized reviewers** as subagents. Each reviewer inspects the unified diff independently, outputs findings in a structured format, then synthesize into a unified safety report.

   **Subagent 1: Semantic Analysis Reviewer**
   ```
   You are a Semantic Analysis Reviewer for code changes. Analyze the provided unified diff against the spec requirements to verify domain logic correctness, algorithm accuracy, and business rule compliance.

   **Inputs:**
   - Unified diff (all modified files)
   - PLAN (for acceptance criteria and business requirements)
   - PHASE_DOC (for specific phase requirements and constraints)
   - Spec Testing Strategy section (for expected behaviors)

   **Focus Areas:**
   - Domain logic correctness (business rules implemented as specified)
   - Algorithm accuracy (correct implementation of specified algorithms, not just pattern matching)
   - Data flow correctness (inputs → processing → outputs match spec)
   - Business rule violations (deviations from requirements)
   - Specification drift (implementation doesn't match documented behavior)
   - Contract violations (breaking promised interfaces or guarantees)

   **Output Format:**
   For each finding, return:
   {
     "severity": "CRITICAL|HIGH|MEDIUM|LOW",
     "file": "absolute/path/to/file.ts",
     "lines": "123-145",
     "issue": "One-sentence description of semantic error",
     "spec_requirement": "Quote the specific spec requirement violated",
     "impact": "Business/user impact if this ships",
     "fix": "Specific fix aligned with spec (2-3 sentences)",
     "patch": "Unified diff snippet showing the fix (optional, only if < 10 lines)"
   }

   **Severity Guidelines:**
   - CRITICAL: Wrong business outcomes, data corruption, spec non-compliance breaking core functionality
   - HIGH: Logic gaps causing incorrect results in common scenarios, missing required business rules
   - MEDIUM: Edge case logic errors, incomplete spec implementation (non-critical features)
   - LOW: Semantic code smells, overly clever implementations that obscure intent

   **Important:** Focus on semantic correctness, not syntax/style. Flag only concrete spec violations with evidence.

   Return JSON array of findings. If no issues found, return empty array [].
   ```

   **Subagent 2: Correctness Reviewer**
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

   **Subagent 3: Security Reviewer**
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

   **Subagent 4: Performance Reviewer**
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

   **Subagent 5: Observability Reviewer**
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
   1. **Aggregate findings** from all 5 reviewers into a single JSON array
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
   - Rules/idioms from `docs/project-rules/` if available

   **Execution:**
   Run all 5 reviewers **in parallel** (concurrent subagent prompts), then synthesize. Total wall time should be ~1 reviewer duration, not 5x sequential.

7) Static & type checks (project-native)
   - Run project-native linters/type-checkers/formatters as specified by PLAN and `PHASE_DOC` (e.g., `just test-extension`, `pytest -q`, `eslint --max-warnings=0`, `tsc --noEmit`).
   - Capture command lines and summarized output. If tools are not defined, note that and recommend adding to rules.

8) Output files (write under PLAN_DIR/reviews/)
   - `PLAN_DIR/reviews/review.md` (the report)
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
        E.0) **Cross-Phase Regression Analysis** (from step 3b)
           - Skipped: Single phase plan

        E.1) **Doctrine & Testing Compliance** (from steps 3a, 4, 5)
           - Graph integrity violations (link validation from 3a)
           - TDD/Lightweight/Mock/Universal validator findings (from 4)
           - Testing evidence and coverage findings (from 5)

        E.2) **Semantic Analysis** (from step 6, Subagent 1 - Semantic Analysis Reviewer)
           - Domain logic correctness findings
           - Algorithm accuracy violations
           - Business rule compliance issues
           - Specification drift detection
           - Each finding includes spec_requirement quote

        E.3) **Quality & Safety Analysis** (from step 6, Subagents 2-5 - Correctness, Security, Performance, Observability)
           - Correctness: Logic defects, error handling, race conditions
           - Security: Vulnerabilities, unsafe patterns, secrets
           - Performance: Regressions, scalability issues, inefficiencies
           - Observability: Logging gaps, metrics, debugging limitations
           - (See synthesis format in step 6 for detailed structure)

        E.4) **Doctrine Evolution Recommendations** (from step 4, Subagent 5 - ADVISORY, does not affect verdict)
           - **New ADR Candidates**: Architectural decisions from implementation worth documenting
             * Title, context, evidence (file:lines), decision summary, priority
           - **ADR Updates**: Existing ADRs that should be revised based on implementation
             * ADR reference, suggested update, evidence
           - **New Rules Candidates**: Enforceable patterns discovered in implementation
             * Rule statement, evidence, enforcement mechanism, priority
             * Action: Add to `docs/project-rules/rules.md`
           - **New Idioms Candidates**: Recurring code patterns worth documenting
             * Pattern name, description, code example, evidence
             * Action: Add to `docs/project-rules/idioms.md`
           - **Architecture Updates**: Structural changes to reflect in architecture.md
             * Section, update type, description
           - **Doctrine Gaps**: Areas where existing doctrine was silent but guidance was needed
             * Gap description, impact, suggested addition
           - **Positive Alignment**: Implementation correctly followed existing doctrine (reinforces value)
           - **Summary Table**:
             | Category | New | Updates | Priority HIGH |
             |----------|-----|---------|---------------|
             | ADRs | N | M | P |
             | Rules | N | M | P |
             | Idioms | N | M | P |
             | Architecture | N | M | P |

     F) **Coverage Map** (acceptance criteria <-> test files/assertions)
        - Per-criterion confidence scores (0-100%)
        - Overall coverage confidence percentage
        - Narrative test identification
        - Weak mapping flagged with recommendations

     G) **Commands Executed** (copy/paste)
     H) **Decision & Next Steps** (who approves; what to fix)

   **Output file paths:**
   - `PLAN_DIR/reviews/review.md` (single phase)

   - `PLAN_DIR/reviews/fix-tasks.md` (only if REQUEST_CHANGES)
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
- Plan and rules are authorities; if conflicts arise, rules win unless deviation is logged in the plan.
```

Review rubric baked into this phase

- **Cross-Phase Regression** (Step 3b):
  - Skipped: Single phase plan

- **Graph Integrity** (Step 3a):
  - **Link validation**: Task↔Log bidirectional links intact
  - Flag graph breaks as CRITICAL/HIGH (blocks traversability)

- **Doctrine** (Step 4 - adapt to Testing Strategy from plan):
  - **Full TDD**: TDD order enforced (tests before code), tests-as-documentation required (assertions show behavior), RED-GREEN-REFACTOR cycles documented in execution log
  - **TAD (Test-Assisted Development)**: Tests as executable documentation, Scratch→Promote workflow enforced, Test Doc comment blocks required (5 fields: Why/Contract/Usage Notes/Quality Contribution/Worked Example), promotion heuristic rigorously applied, promoted tests must be reliable, tests/scratch/ excluded from CI
  - **Lightweight**: Core validation tests required (focus on critical paths per spec Focus Areas), implementation-first acceptable, skip comprehensive edge case coverage if excluded in spec
  - **Manual**: Manual verification steps documented with clear expected outcomes, observed results recorded in execution log, evidence artifacts present (screenshots/logs)
  - **Hybrid**: Per-phase/per-task approach applied based on annotations
  - **Mock usage** (all approaches except Manual): Must align with spec preference (avoid/targeted/liberal) - CRITICAL if mismatched
  - **Real repo data/fixtures** whenever the Testing Strategy policy requires it
  - Flag drift as CRITICAL/HIGH with approach-appropriate fix guidance

- **Coverage Map Accuracy** (Step 5):
  - **Explicit linkage**: Test names/comments reference criterion IDs (confidence: 100% explicit, 75% behavioral, 50% inferred, 0% unclear)
  - **Narrative test detection**: Flag tests without clear criterion mapping as informative but not validating
  - **Overall confidence**: Report aggregate score (HIGH if <50%, MEDIUM if 50-75%, LOW if >75%)
  - Recommend adding criterion IDs to test names, test file organization by criteria

- **Semantic Analysis** (Step 6, Subagent 1 - NEW):
  - **Domain logic**: Business rules implemented as specified in plan/spec
  - **Algorithm accuracy**: Correct implementation of specified algorithms (not just pattern matching)
  - **Data flow correctness**: Inputs → processing → outputs match spec
  - **Specification drift**: Implementation matches documented behavior (quote spec requirements in findings)
  - Flag semantic errors as CRITICAL/HIGH with spec requirement evidence

- **Quality & Safety** (Step 6, Subagents 2-5):
  - **Correctness**: Logic defects, error handling, race conditions, type mismatches
  - **Security**: Path traversal, injection, secrets, auth bypasses, weak crypto
  - **Performance**: N+1 queries, unbounded scans, memory leaks, inefficient algorithms
  - **Observability**: Missing error logs, insufficient context, broken remote logging, no metrics

- **Doctrine Evolution** (Step 4, Subagent 5 - ADVISORY):
  - **ADR candidates**: Identify significant architectural decisions that emerged during implementation
  - **Rules candidates**: Detect enforceable patterns (3+ occurrences, error prevention, lintable)
  - **Idioms candidates**: Recognize recurring code patterns worth standardizing
  - **Architecture updates**: Flag structural changes needing documentation
  - **Cross-reference**: Check implementation against existing doctrine for gaps and positive alignment
  - **Priority scoring**: HIGH (affects reliability/security, 5+ uses), MEDIUM (consistency, 3-4 uses), LOW (nice-to-have)
  - **Output**: Advisory recommendations in Section E.4; does NOT affect approval verdict

- **BridgeContext patterns** (Step 4, Subagent 3 - EXPANDED to 10 patterns):
  1. Use vscode.Uri (not Node path) for file paths
  2. Bounded vscode.RelativePattern with exclude + maxResults
  3. Never workspace.findFiles('**/*') without bounds
  4. Python debug via { module: 'pytest', args: ['--no-cov'] }
  5. Use workspace.getConfiguration() instead of process.env
  6. Use vscode.tasks API instead of child_process
  7. Bounded createFileSystemWatcher() patterns
  8. Use Uri.fsPath for display (never manipulate path strings)
  9. Handle multi-root workspaces (workspaceFolders array)
  10. Validate Uri.scheme before file operations

- **Plan authority**: Changes must map to the locked structure and explicit acceptance criteria from planning. Testing evidence must match the Testing Approach documented in the plan.

Flow update (ordered commands)

1. **plan-1b-specify** — Feature specification
2. **plan-3-architect** — Implementation plan
3. **plan-5-phase-tasks-and-brief** — Phase tasks
4. **plan-6-implement-phase** — Implementation
5. **plan-7-code-review** — Review (this command)

This ensures reviews inspect the work against the same standards enforced during planning and implementation.

Next step (when happy): APPROVE -> merge; REQUEST_CHANGES -> follow `PLAN_DIR/reviews/fix-tasks.md` then rerun **/plan-6** for fixes.
