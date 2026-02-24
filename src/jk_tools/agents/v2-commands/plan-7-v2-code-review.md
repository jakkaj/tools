---
description: Read-only per-phase code review with domain compliance validation. V2 standalone rewrite.
---

Please deep think / ultrathink as this is a complex task.

# plan-7-v2-code-review

Read-only code review that inspects diffs, verifies domain compliance, checks for concept reinvention, and produces structured findings with file artifacts. Does NOT modify code.

---

```md
User input:

$ARGUMENTS
# Required flags (absolute paths):
# --phase "<Phase N: Title>"   # Required for Full Mode, omit for Simple Mode
# --plan "<abs path to plan.md>"
# Optional flags:
# --diff-file "<abs path to unified.diff>"   # if omitted, compute from git
# --strict                                   # treat HIGH as blocking

## Step 1: Resolve Inputs & Artifacts

**Mode Detection**: Read plan for `**Mode**: Simple` or `**Mode**: Full`

**Full Mode** artifact resolution:
- PLAN = provided --plan
- PLAN_DIR = dirname(PLAN)
- SPEC = `${PLAN_DIR}/<slug>-spec.md`
- PHASE_SLUG = slugified phase title
- PHASE_DIR = `${PLAN_DIR}/tasks/${PHASE_SLUG}`
- PHASE_DOC = `${PHASE_DIR}/tasks.md`
- EXEC_LOG = `${PHASE_DIR}/execution.log.md`
- REVIEW_FILE = `${PLAN_DIR}/reviews/review.${PHASE_SLUG}.md`
- FIX_FILE = `${PLAN_DIR}/reviews/fix-tasks.${PHASE_SLUG}.md` (only if REQUEST_CHANGES)

**Simple Mode** artifact resolution:
- PLAN = provided --plan
- PLAN_DIR = dirname(PLAN)
- SPEC = `${PLAN_DIR}/<slug>-spec.md`
- PHASE_DOC = PLAN itself (inline tasks from § Implementation)
- EXEC_LOG = `${PLAN_DIR}/execution.log.md`
- REVIEW_FILE = `${PLAN_DIR}/reviews/review.md`
- FIX_FILE = `${PLAN_DIR}/reviews/fix-tasks.md` (only if REQUEST_CHANGES)

Create `${PLAN_DIR}/reviews/` directory if it doesn't exist.

## Step 2: Gather Diffs

- If `--diff-file` provided: read it
- Otherwise: compute diff from git using this detection strategy:

  1. **Check for uncommitted changes first**: `git diff --stat` and `git diff --staged --stat`
     - If uncommitted/staged changes exist → use `git diff` and `git diff --staged` for diffs
  2. **If working tree is clean** (already committed): look at recent commit history
     - Read execution.log.md for the commit hash or file list
     - Find the commit(s) for this phase by scanning `git log --oneline -10` for phase-related messages
     - Use `git diff <commit-before-phase>..HEAD` to get the full phase diff
     - If unclear which commits belong to this phase, use the file list from execution.log.md or task table Path(s) column:
       `git log --all --follow -- <file>` to find the relevant commits, then diff from the earliest
  3. **Fallback**: If git history is unclear, read file list from task table Path(s) column and diff each file against its last committed state before the plan started
- Build a file manifest: every file touched, with action (created/modified/deleted)
- Save computed diff to `${PLAN_DIR}/reviews/_computed.diff` for reproducibility

## Step 3: Launch Review Subagents (Parallel)

Launch **5 subagents** in parallel (single message with 5 Task tool calls):

### Subagent 1: Implementation Quality Reviewer
"Review code changes for correctness, safety, and quality.

**Read**:
- All changed files (from diffs)
- Task table from PHASE_DOC (expected changes)
- Acceptance criteria from SPEC
- Key Findings from PLAN (known hazards)

**Check** (only report issues that genuinely matter — no style nits):
- **Correctness**: Logic errors, off-by-one, null handling, type mismatches
- **Security**: Input validation, injection risks, secrets exposure, auth gaps
- **Error handling**: Missing try/catch, swallowed errors, unclear error messages
- **Performance**: Obvious inefficiencies, unbounded operations, missing pagination
- **Scope compliance**: Do changes match what tasks specified? Any scope creep?
- **Pattern adherence**: Does new code follow existing codebase patterns?

**Output** (JSON array):
```json
[{\"severity\": \"HIGH|MEDIUM|LOW\", \"file\": \"abs/path:lines\", \"category\": \"correctness|security|error-handling|performance|scope|pattern\", \"issue\": \"...\", \"suggestion\": \"...\"}]
```"

### Subagent 2: Domain Compliance Validator
"Validate domain compliance for all changes in this phase.

**Read**:
- `docs/domains/registry.md` — all registered domains
- `docs/domains/domain-map.md` — domain topology and contract relationships
- `docs/domains/<slug>/domain.md` — for each domain touched
- Plan's `## Domain Manifest` — expected file→domain mapping
- All changed files

**Check**:
1. **File placement**: Every new file is under its declared domain's source tree
2. **Contract-only imports**: No imports from another domain's internal files (only contracts/ or public exports allowed)
3. **Dependency direction**:
   - business → infrastructure: ✅
   - infrastructure → business: ❌ VIOLATION
   - business → business: only via contracts
4. **Domain.md currency**: domain.md § History updated for this plan, § Composition updated if new components, § Contracts updated if public interface changed
5. **Registry currency**: docs/domains/registry.md reflects any new domains
6. **No orphan files**: Every changed file maps to a domain in the manifest
7. **Map currency**: docs/domains/domain-map.md reflects all domains, new edges labeled, contracts in node labels current, health summary table current
8. **No circular business deps**: No business→business cycles in the domain map
9. **No unlabeled edges**: Every dependency on the map has a contract label

**Output** (JSON array):
```json
[{\"severity\": \"HIGH|MEDIUM|LOW\", \"check\": \"file-placement|contract-imports|dependency-direction|domain-md|registry|orphan|map-nodes|map-edges|circular-deps\", \"file\": \"...\", \"issue\": \"...\", \"fix\": \"...\"}]
```"

### Subagent 3: Anti-Reinvention Check
"Check whether this phase introduced functionality that already exists in another domain.

**Read**:
- All NEW files created in this phase
- `docs/domains/*/domain.md` — contracts and composition for all domains
- `docs/domains/domain-map.md` — to understand existing capabilities

For each major new component (service, adapter, repository, handler):
1. Run `/code-concept-search \"<component concept>\"` against the codebase
2. Check domain contracts for overlapping capabilities
3. Flag if similar functionality exists in another domain

**Output** (JSON array):
```json
[{\"severity\": \"HIGH|MEDIUM|LOW\", \"new_component\": \"...\", \"file\": \"...\", \"existing_match\": \"...|None\", \"match_domain\": \"...\", \"recommendation\": \"reuse|extend|proceed\"}]
```
Only flag genuine duplication, not incidental similarity."

### Subagent 4: Testing & Evidence Validator
"Validate testing approach compliance and evidence quality.

**Read**:
- PHASE_DOC (task table — check completion status)
- EXEC_LOG (implementation evidence)
- SPEC § Testing Strategy (expected approach)
- Changed test files (from diffs)

**Check** (adapt to testing approach from spec):
- **All approaches**: Acceptance criteria have evidence of verification
- **Full TDD**: Test tasks precede implementation, RED-GREEN evidence exists
- **Lightweight**: Core validation tests exist for critical paths
- **Manual**: Verification steps documented with observed outcomes
- **Hybrid**: Approach-appropriate checks per task
- **Evidence quality**: Are claims backed by concrete output (test results, command output, screenshots)?
- **Coverage**: Do acceptance criteria map to verified evidence?

**Output** (JSON):
```json
{
  \"approach\": \"Full TDD|Lightweight|Manual|Hybrid\",
  \"coverage_confidence\": 0-100,
  \"violations\": [{\"severity\": \"...\", \"issue\": \"...\", \"fix\": \"...\"}],
  \"ac_coverage\": [{\"ac\": \"AC1\", \"confidence\": 0-100, \"evidence\": \"...\"}]
}
```"

### Subagent 5: Doctrine & Rules Validator
"Validate alignment with project rules, idioms, architecture.

**Read**:
- Changed files (from diffs)
- `docs/project-rules/rules.md` (if exists)
- `docs/project-rules/idioms.md` (if exists)
- `docs/project-rules/architecture.md` (if exists)
- `docs/project-rules/constitution.md` (if exists)

**Check**:
- Changed code respects coding standards from rules.md
- Follows naming and directory conventions from idioms.md
- Respects layer boundaries from architecture.md
- If no project-rules exist: report N/A (not a failure)

**Output** (JSON array):
```json
[{\"severity\": \"HIGH|MEDIUM|LOW\", \"file\": \"...\", \"rule\": \"...\", \"issue\": \"...\", \"fix\": \"...\"}]
```"

**Wait for all 5 subagents to complete.**

## Step 4: Synthesize Results

1. Collect findings from all subagents
2. Deduplicate overlapping findings
3. Assign sequential finding IDs (F001, F002, ...)
4. Order by severity: CRITICAL → HIGH → MEDIUM → LOW
5. Determine verdict:
   - Zero HIGH/CRITICAL → **APPROVE**
   - Any HIGH/CRITICAL with mitigations → **APPROVE WITH NOTES**
   - Any HIGH/CRITICAL unmitigated → **REQUEST_CHANGES**
   - If `--strict`: any HIGH → **REQUEST_CHANGES**

## Step 5: Write Review File

Write `${REVIEW_FILE}` (create `reviews/` dir if needed):

```markdown
# Code Review: [Phase Title]

**Plan**: [absolute path to plan.md]
**Spec**: [absolute path to spec.md]
**Phase**: [phase title, or "Simple Mode"]
**Date**: [today]
**Reviewer**: Automated (plan-7-v2)
**Testing Approach**: [from spec]

## A) Verdict

**[APPROVE | APPROVE WITH NOTES | REQUEST_CHANGES]**

[If REQUEST_CHANGES: brief reason]

## B) Summary

[3-5 sentences: overall quality, domain compliance status, reinvention check, testing evidence quality]

## C) Checklist

**Testing Approach: [approach]**

[Approach-specific checklist — adapt to spec's testing strategy:]

For Lightweight:
- [ ] Core validation tests present
- [ ] Critical paths covered
- [ ] Key verification points documented

For Manual:
- [ ] Manual verification steps documented
- [ ] Manual test results recorded with observed outcomes
- [ ] Evidence artifacts present

Universal (all approaches):
- [ ] Only in-scope files changed
- [ ] Linters/type checks clean (if applicable)
- [ ] Domain compliance checks pass

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|

## E) Detailed Findings

### E.1) Implementation Quality
[Subagent 1 findings — correctness, security, error handling, performance]

### E.2) Domain Compliance
[Subagent 2 findings with domain compliance table:]

| Check | Status | Details |
|-------|--------|---------|
| File placement | ✅/❌ | |
| Contract-only imports | ✅/❌ | |
| Dependency direction | ✅/❌ | |
| Domain.md updated | ✅/❌ | |
| Registry current | ✅/❌ | |
| No orphan files | ✅/❌ | |
| Map nodes current | ✅/❌ | |
| Map edges current | ✅/❌ | |
| No circular business deps | ✅/❌ | |

### E.3) Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|

### E.4) Testing & Evidence

**Coverage confidence**: [0-100%]

| AC | Confidence | Evidence |
|----|------------|----------|

### E.5) Doctrine Compliance
[Subagent 5 findings, or "N/A — no project-rules found"]

## F) Coverage Map

[Acceptance criteria ↔ evidence mapping]

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|

**Overall coverage confidence**: [N%]

## G) Commands Executed

```bash
[List actual commands used to gather diffs, run checks, etc.]
```

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review —
> only context on the work that was done before the review.

**Review result**: [APPROVE | APPROVE WITH NOTES | REQUEST_CHANGES]

**Plan**: [absolute path to plan.md]
**Spec**: [absolute path to spec.md]
**Phase**: [phase title, or "Simple Mode"]
**Tasks dossier**: [absolute path to tasks.md, or "inline in plan"]
**Execution log**: [absolute path to execution.log.md]
**Review file**: [absolute path to this review file]

### Files Reviewed

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|

### Required Fixes (if REQUEST_CHANGES)

| # | File (absolute path) | What To Fix | Why |
|---|---------------------|-------------|-----|

### Domain Artifacts to Update (if any)

| File (absolute path) | What's Missing |
|---------------------|----------------|

### Next Step

[Exact command to run — e.g.:
- For fixes: "/plan-6-v2-implement-phase --plan /abs/path --phase 'Phase N'"
- For next phase: "/plan-5-v2-phase-tasks-and-brief --phase 'Phase N+1' --plan /abs/path"
- If approved and final phase: "Implementation complete — consider committing"]
```

## Step 6: Write Fix Tasks (if REQUEST_CHANGES)

If verdict is REQUEST_CHANGES, write `${FIX_FILE}`:

```markdown
# Fix Tasks: [Phase Title]

Apply in order. Re-run review after fixes.

## Critical / High Fixes

### FT-001: [Title]
- **Severity**: CRITICAL/HIGH
- **File(s)**: [absolute paths]
- **Issue**: [what's wrong]
- **Fix**: [specific remediation steps]
- **Patch hint**:
  ```diff
  - [old code]
  + [new code]
  ```

## Medium / Low Fixes

### FT-NNN: [Title]
...

## Re-Review Checklist

- [ ] All critical/high fixes applied
- [ ] Re-run `/plan-7-v2-code-review` and achieve zero HIGH/CRITICAL
```

## Step 7: Constraints

- **Read-only**: Do NOT change source files
- **Patches are hints only**: Unified diff snippets in report, not applied
- **Report is deterministic**: Quote minimal context, use absolute paths throughout
- **Domain map validation is mandatory**: If domain-map.md exists, it MUST be checked
- **ALWAYS write review file**: Never just output to console — write the file to `${PLAN_DIR}/reviews/`
- **ALWAYS include Handover Brief**: The next agent needs full context with absolute paths
```

Acceptance criteria for this command:
- Review file written to `${PLAN_DIR}/reviews/` with sections A-H
- Fix tasks file written (if REQUEST_CHANGES) with ordered fixes and patch hints
- Computed diff saved to `${PLAN_DIR}/reviews/_computed.diff`
- Every finding has absolute file path, severity, and concrete fix
- Domain compliance table has 9 checks with ✅/❌ status
- Coverage map shows per-AC confidence scores
- Handover Brief has full absolute paths for all artifacts and files reviewed
- If APPROVE: zero HIGH/CRITICAL findings
- If REQUEST_CHANGES: fix tasks file created with severity-ordered fixes

Next step: Apply fixes from fix-tasks file, then re-run `/plan-7-v2-code-review`.
