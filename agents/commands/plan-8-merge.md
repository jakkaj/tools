---
description: Analyze upstream changes from main and generate merge plan document
---

Please deep think / ultrathink as this is a complex task.

# plan-8-merge (alias: /8, /merge)

Analyze upstream changes from main and generate a comprehensive merge plan document before any merge execution. This command discovers all plans that landed in main since you branched, identifies conflicts with your work, and creates a crystal-clear merge plan document with diagrams, tables, and step-by-step instructions.

**Primary Output**: A merge plan document that both human and AI fully understand before any merge execution.

**Why**: When you've been working on a feature branch for days or weeks, main has moved on. Other developers merged their completed plans. You need a systematic way to understand what changed, ensure your work is compatible, and merge safely without regressions.

> **Safety First**: Before running this command, consider creating a backup branch:
> ```bash
> git branch backup-$(date +%Y%m%d)-before-merge
> ```
> This gives you a clean restore point if anything goes wrong during the merge process.

---

```md
User input:

$ARGUMENTS
# Optional flags:
# --plan "<abs path to docs/plans/<ordinal>-<slug>/>"  # Your plan folder (auto-detect if in plan dir)
# --target "main"                                       # Branch to merge from (default: main)

## Execution Flow

1) Input Resolution and Validation

   **Parse arguments:**
   - PLAN_DIR = provided --plan OR auto-detect from current directory (look for *-spec.md)
   - TARGET = provided --target OR "main"

   **Validate git state:**
   ```bash
   # Ensure working tree is clean
   if ! git diff --quiet HEAD; then
     echo "ERROR: Working tree has uncommitted changes. Commit or stash before merging."
     exit 1
   fi

   # Ensure we're on a branch (not detached HEAD)
   CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
   if [ -z "$CURRENT_BRANCH" ]; then
     echo "ERROR: Detached HEAD state. Check out a branch before running merge."
     exit 1
   fi
   ```

   **Detect plan folder:**
   - If PLAN_DIR provided, validate it exists and contains *-spec.md
   - If not provided, search current directory and parents for plan folder
   - Set PLAN_SLUG from folder name (e.g., "003-my-feature" -> "my-feature")

   **Abort conditions:**
   - No plan folder found
   - Working tree not clean
   - Detached HEAD state
   - Target branch doesn't exist

2) Common Ancestor Detection

   **Find merge base:**
   ```bash
   ANCESTOR=$(git merge-base HEAD ${TARGET})
   ```

   **Handle no common ancestor (degraded mode):**
   If merge-base fails or returns empty:
   ```
   ⚠️ WARNING: No common ancestor found between HEAD and ${TARGET}.
   This may indicate completely unrelated histories.

   Options:
   1. Use --allow-unrelated-histories with git merge (manual)
   2. Verify you're on the correct branch
   3. Check if remote tracking is set up correctly

   Proceeding in DEGRADED MODE: Full diff analysis without three-way context.
   Conflict classification accuracy will be reduced.
   ```

   **Success output:**
   ```
   ✓ Common ancestor found: ${ANCESTOR} (${ANCESTOR_DATE})
   ✓ You branched ${DAYS_AGO} days ago
   ```

3) Three-Version Extraction

   **Extract file lists:**
   ```bash
   # Files changed on main since ancestor
   git diff ${ANCESTOR}..${TARGET} --name-only > /tmp/main_files.txt

   # Files changed on your branch since ancestor
   git diff ${ANCESTOR}..HEAD --name-only > /tmp/your_files.txt

   # Find overlapping files (potential direct conflicts)
   comm -12 <(sort /tmp/main_files.txt) <(sort /tmp/your_files.txt) > /tmp/conflict_files.txt
   ```

   **For each plan artifact, retrieve three versions:**
   ```bash
   # Ancestor version
   git show ${ANCESTOR}:${FILE_PATH} > /tmp/ancestor_version

   # Target (main) version
   git show ${TARGET}:${FILE_PATH} > /tmp/target_version

   # Local version is current working copy
   ```

4) Cross-Mode Detection Gate

   **Detect plan modes:**
   - Read your plan's spec.md and check for `**Mode**: Simple` or `**Mode**: Full`
   - For each upstream plan, check their mode

   **Cross-mode warning:**
   If your plan is Simple Mode and upstream plans are Full Mode (or vice versa):
   ```
   ⚠️ CROSS-MODE MERGE DETECTED

   Your plan: ${YOUR_MODE} Mode
   Upstream plans: ${UPSTREAM_MODES}

   Cross-mode merges require additional care:
   - Simple ← Full: Upstream artifacts may have separate dossiers you don't have
   - Full ← Simple: Inline tasks need to be reconciled with your dossier structure

   Recommendation: Review merge plan carefully. Manual intervention likely required
   for footnote ledger and task table reconciliation.
   ```

   **Continue regardless** but flag in merge plan document.

5) Launch Parallel Subagents

   **IMPORTANT**: Launch ALL subagents in a **single message** with multiple Task tool calls.
   This maximizes parallelism and reduces wall-clock time.

   The number of subagents is dynamic:
   - **6 fixed subagents**: U1, Y1, C1, C2, R1, S1
   - **N dynamic subagents**: U2 through U(N+1), one per upstream plan discovered by U1

   **Launch sequence:**
   1. First, launch U1 (Upstream Discovery) to get the list of upstream plans
   2. Wait for U1 to complete
   3. Launch remaining fixed subagents (Y1, C1, C2, R1) + dynamic plan analysts (U2-UN) + S1 in parallel
   4. Wait for all to complete
   5. Proceed to synthesis

---

## Subagent Architecture

### Subagent U1: Upstream Plans Discovery

"Discover all plans that landed in ${TARGET} since the common ancestor.

**Input:**
- ANCESTOR = ${ANCESTOR}
- TARGET = ${TARGET}

**Commands to run:**
```bash
# Get all commits on target since ancestor
git log ${ANCESTOR}..${TARGET} --oneline

# Find commits touching plan folders
git log ${ANCESTOR}..${TARGET} --oneline -- \"docs/plans/\"

# For each unique plan folder touched, extract:
# - Plan ordinal and slug
# - Merge date
# - Commit count
```

**Output** (structured):
```json
{
  \"upstream_plans\": [
    {
      \"ordinal\": \"004\",
      \"slug\": \"payments\",
      \"folder\": \"docs/plans/004-payments\",
      \"merge_date\": \"2026-12-22\",
      \"days_ago\": 10,
      \"commit_count\": 15
    },
    ...
  ],
  \"total_commits\": 47,
  \"plan_count\": 3
}
```

If no upstream plans found, output:
```json
{
  \"upstream_plans\": [],
  \"total_commits\": 0,
  \"plan_count\": 0,
  \"message\": \"No new plans landed in ${TARGET} since you branched.\"
}
```
"

### Subagent U2-UN: Plan Analyst (Dynamic Template)

**Launch one subagent per upstream plan discovered by U1.**

"Analyze upstream plan ${PLAN_ORDINAL}-${PLAN_SLUG} to understand what it changed and why.

**Input:**
- PLAN_FOLDER = ${PLAN_FOLDER}
- TARGET = ${TARGET}

**Read (via git show ${TARGET}:path):**
- ${PLAN_FOLDER}/${SLUG}-spec.md (summary, goals, acceptance criteria)
- ${PLAN_FOLDER}/${SLUG}-plan.md (phases, tasks, critical findings)
- ${PLAN_FOLDER}/tasks/*/execution.log.md (implementation decisions)

**Output** - Plan Summary Card:
```markdown
### Plan ${ORDINAL}-${SLUG}

**Purpose**: [2-3 sentence summary from spec]

**Files Changed**: [count] files in [directories]
- [list top 10 files by change magnitude]

**Key Changes**:
- [bullet list of major implementation changes]
- [include API changes, model changes, config changes]

**Tests Added**:
- [test files added]
- [test coverage areas]

**Potential Conflicts with Your Work**:
- [files that overlap with your changes]
- [APIs or components that might interact]
- [semantic conflicts: same concept modified differently]

**FlowSpace Footnotes** (if present):
- [^N]: [summary] - files: [list]
```
"

### Subagent Y1: Your Changes Analyst

"Analyze your branch's changes since the common ancestor.

**Input:**
- ANCESTOR = ${ANCESTOR}
- PLAN_DIR = ${PLAN_DIR}

**Commands:**
```bash
# What you changed
git diff ${ANCESTOR}..HEAD --stat
git diff ${ANCESTOR}..HEAD --name-only
git log ${ANCESTOR}..HEAD --oneline
```

**Read:**
- Your spec.md (what you're building)
- Your plan.md (what you've done)
- Your execution logs (decisions made)

**Output:**
```markdown
### Your Changes Summary

**Branch**: ${CURRENT_BRANCH}
**Commits**: [count] since branching
**Files Modified**: [count]

**What You're Building**:
[2-3 sentence summary from your spec]

**Key Changes Made**:
- [bullet list of major changes]
- [include file paths with change descriptions]

**Components You Depend On**:
- [list of components/APIs your code uses]
- [assumptions you've made about system state]

**Potential Sensitivity Points**:
- [files/APIs that might be affected by upstream changes]
- [integration points that need verification]
```
"

### Subagent C1: File Conflict Detector

"Identify direct file-level conflicts between your changes and upstream.

**Input:**
- ANCESTOR = ${ANCESTOR}
- TARGET = ${TARGET}
- YOUR_FILES = [files you changed]
- UPSTREAM_FILES = [files upstream changed]

**Commands:**
```bash
# Find overlapping files
comm -12 <(sort /tmp/main_files.txt) <(sort /tmp/your_files.txt)

# For each overlapping file, check if git can auto-merge
git merge-tree ${ANCESTOR} HEAD ${TARGET} -- ${FILE}
```

**Output:**
```markdown
### Direct File Conflicts

**Conflict Count**: [N] files

| File | Your Change | Upstream Change | Auto-Merge? | Conflict Type |
|------|-------------|-----------------|-------------|---------------|
| path/to/file.py | Added method X | Modified method Y | Yes | Complementary |
| path/to/model.py | Added field | Modified same field | No | Contradictory |

**Files You Changed (no upstream changes)**: [count]
**Files Upstream Changed (you didn't touch)**: [count]
**Overlapping Files**: [count] ([N] auto-mergeable, [M] manual)
```
"

### Subagent C2: Semantic Conflict Detector

"Identify semantic conflicts where the same concept/component was modified in different files.

**Input:**
- YOUR_CHANGES = [summary of your changes]
- UPSTREAM_CHANGES = [summary of each upstream plan's changes]

**PHASE 1 - Candidate Generation (always runs):**

For each concept/component:
1. Check if you modified it (any file)
2. Check if upstream modified it (any file)
3. If both, flag as candidate semantic conflict

**Semantic conflict indicators:**
- Same API modified with different signatures
- Same data model with different field expectations
- Same service with different behavior assumptions
- Same configuration with conflicting values

**PHASE 2 - FlowSpace Verification (optional, if available):**

If FlowSpace MCP is available AND candidate conflicts were found:
```
For each candidate conflict:
  /flowspace-research "[component name]" --limit 3

  If results found:
    - Extract actual code signatures/definitions
    - Verify conflict is real (not false positive from summary analysis)
    - Record node_ids for merge plan evidence
  Else:
    - Mark as "cannot verify in codebase"
```

If FlowSpace unavailable: Skip Phase 2, output summary-based conflicts only.

**Output:**
```markdown
### Semantic Conflicts

**Potential Semantic Conflicts Found**: [N]
**FlowSpace Verification**: [Enabled | Skipped - FlowSpace unavailable]

| Component/Concept | Your Assumption | Upstream Reality | Risk Level | Verified | Node ID |
|-------------------|-----------------|------------------|------------|----------|---------|
| User.email field | Added validation | Added new format | High | ✓ | class:src/models/user.py:User |
| PaymentService API | Uses v1 endpoint | Migrated to v2 | Critical | ✓ | callable:src/services/payment.py:process |

**Reasoning Chain** (for each conflict):
1. [Conflict]: [description]
   - Your code at [file:line]: [what you assume]
   - Upstream code at [file:line]: [what they changed]
   - FlowSpace Evidence: [node_id if verified, "N/A" if skipped]
   - Risk: [why this is a problem]
   - Verification: [how to test this works]
```

**Anti-hallucination constraint:**
- Only flag conflicts with specific file:line evidence
- Confidence < 80%: flag for human review, do not assert as definite conflict
- Never invent code or assume changes not visible in diffs
- FlowSpace verification increases confidence but doesn't guarantee correctness
"

### Subagent R1: Regression Risk Analyst

"Identify potential regressions in both directions.

**Input:**
- YOUR_CHANGES = [files and components you modified]
- UPSTREAM_PLANS = [summary of each upstream plan]
- UPSTREAM_TESTS = [tests added by upstream]
- YOUR_TESTS = [tests you added]

**Bidirectional risk analysis:**

1. **Your changes might break upstream functionality:**
   - Which upstream tests might fail due to your changes?
   - Which upstream features depend on code you modified?

2. **Upstream changes might break your functionality:**
   - Which of your tests might fail due to upstream changes?
   - Which of your features depend on code upstream modified?

**Output:**
```markdown
### Regression Risk Analysis

**Risks Identified**: [N]

| Risk | Direction | Upstream Plan | Your Change | Likelihood | Test Command |
|------|-----------|---------------|-------------|------------|--------------|
| User model | You→Upstream | 004-payments | Added email validation | Medium | pytest tests/payments/ |
| Auth flow | Upstream→You | 006-profiles | Modified login | High | pytest tests/auth/ |

**Recommended Test Sequence:**
1. [test command] - verifies [what]
2. [test command] - verifies [what]

**Critical Regressions (must verify before merge):**
- [list any High/Critical items]
```
"

### Subagent S1: Synthesis & Ordering

"Synthesize all findings and determine optimal merge order.

**Input:**
- UPSTREAM_PLANS = [list with details]
- FILE_CONFLICTS = [from C1]
- SEMANTIC_CONFLICTS = [from C2]
- REGRESSION_RISKS = [from R1]
- YOUR_CHANGES = [from Y1]

**Determine merge order based on:**
1. Dependencies between upstream plans (check execution logs for references)
2. Conflict severity (merge low-conflict plans first)
3. Test coverage (merge well-tested plans first)

**Output:**
```markdown
### Merge Order Recommendation

**Recommended Order** (with rationale):

1. **${PLAN_1}** (merge first)
   - Conflicts: None
   - Dependencies: None
   - Risk: Low
   - Rationale: Independent changes, safe to merge first

2. **${PLAN_2}** (merge second)
   - Conflicts: 2 files
   - Dependencies: Depends on Plan 1 (uses new API)
   - Risk: Medium
   - Rationale: Conflicts are in tests, not core code

3. **${PLAN_3}** (merge last)
   - Conflicts: 1 semantic conflict
   - Dependencies: None
   - Risk: High
   - Rationale: Requires manual resolution of User model conflict

**Overall Risk Assessment:**
- Total Direct Conflicts: [N]
- Total Semantic Conflicts: [N]
- Total Regression Risks: [N]
- Estimated Manual Resolution: [N] files
- Recommended Approach: [Sequential/Batch with description]
```
"

---

## Synthesis Phase

After all subagents complete:

### 1. Collect All Findings

Gather outputs from all subagents:
- U1: List of upstream plans
- U2-UN: Plan summary cards for each upstream plan
- Y1: Your changes summary
- C1: Direct file conflicts
- C2: Semantic conflicts
- R1: Regression risks
- S1: Merge order recommendation

### 2. Deduplicate and Classify

For each conflict/risk:
- Remove duplicates (same file:line from multiple subagents)
- Apply conflict classification (see taxonomy below)
- Assign resolution strategy

### 3. Conflict Classification Taxonomy

**Complementary**: Both branches made non-conflicting changes to same file
- Both changes can coexist
- Git will auto-merge
- Verify combined behavior is correct

**Contradictory**: Both branches changed the same thing differently
- Must choose one or manually combine
- Requires human decision
- Document reasoning for choice

**Orthogonal**: One change depends on a value the other modified
- May compile but fail at runtime
- Requires understanding of both changes
- Test thoroughly after merge

**Auto-Resolvable**: Only one branch changed from ancestor
- That branch's version wins
- No manual intervention needed
- Verify behavior unchanged

### Anti-Hallucination Patterns

**Chain-of-Verification**: Every conflict resolution includes:
1. Quote the exact code from your branch
2. Quote the exact code from upstream
3. Quote the ancestor version (if different from both)
4. Explain why the resolution is correct
5. Specify verification steps

**Constrained Classification**: Only use the 4 conflict types above
- Never invent new categories
- If unclear, flag for human review
- Do not guess at resolution

**Explicit Uncertainty**: When confidence < 80%:
```
⚠️ HUMAN REVIEW REQUIRED

Confidence: [X]%
Reason for uncertainty: [explanation]
Possible interpretations:
1. [interpretation A]
2. [interpretation B]

Recommendation: [what human should check]
```

**Never Invent Code**: Resolution options are limited to:
- Keep local version
- Take incoming version
- Combine additive changes (both added different things)
- Flag for manual merge (complex changes)

### Execution Log Merge Strategy

**Critical**: Execution logs are append-only truth. NEVER discard entries.

**Merge approach:**
1. Collect all log entries from both sources
2. Sort by timestamp (interleave chronologically)
3. Add source attribution to each entry:
   ```markdown
   ## Task 2.3: Implement validation [YOUR-BRANCH]
   **Timestamp**: 2026-01-15 10:30

   ## Task 1.4: Add payment endpoint [UPSTREAM:004-payments]
   **Timestamp**: 2026-01-14 14:22
   ```
4. Flag concurrent execution (same timestamp from different sources):
   ```
   ⚠️ CONCURRENT EXECUTION: Tasks 2.3 and 1.4 executed simultaneously on different branches
   ```
5. Preserve complete history for audit trail

---

## Merge Plan Document Template

Generate the following document in ${PLAN_DIR}/merge/${DATE}/merge-plan.md:

### Document Header

```markdown
# Merge Plan: Integrating Upstream Changes

**Generated**: ${TIMESTAMP}
**Your Branch**: ${CURRENT_BRANCH} @ ${HEAD_SHA}
**Merging From**: ${TARGET} @ ${TARGET_SHA}
**Common Ancestor**: ${ANCESTOR} @ ${ANCESTOR_DATE}

---
```

### Executive Summary Section

```markdown
## Executive Summary

### What Happened While You Worked

You branched from ${TARGET} **${DAYS_AGO} days ago**. Since then, **${PLAN_COUNT} plans** landed in ${TARGET}:

| Plan | Merged | Purpose | Risk to You |
|------|--------|---------|-------------|
| ${PLAN_1} | ${DAYS} days ago | ${PURPOSE} | ${RISK_LEVEL} |
| ... | ... | ... | ... |

### Conflict Summary

- **Direct Conflicts**: ${N} files
- **Semantic Conflicts**: ${N} (flagged for human review)
- **Regression Risks**: ${N}

### Recommended Approach

\`\`\`
${ORDERED_MERGE_STEPS}
\`\`\`
```

### Timeline Diagram

```markdown
## Timeline

\`\`\`mermaid
timeline
    title Plans Merged to ${TARGET} While You Worked
    section ${WEEK_1}
      ${PLAN_1} : Merged ${DATE}
    section ${WEEK_2}
      ${PLAN_2} : Merged ${DATE}
      ${PLAN_3} : Merged ${DATE}
\`\`\`
```

### Conflict Map Diagram

```markdown
## Conflict Map

\`\`\`mermaid
graph LR
    subgraph Your["Your Changes"]
        Y1["${YOUR_FILE_1}"]
        Y2["${YOUR_FILE_2}"]
    end

    subgraph Upstream["Upstream Changes"]
        U1["${UPSTREAM_FILE_1}"]
        U2["${UPSTREAM_FILE_2}"]
    end

    Y1 -.->|CONFLICT| U1
    Y2 -.->|No Conflict| U2
\`\`\`
```

### Plan Summary Cards

```markdown
## Upstream Plans Analysis

### Plan ${ORDINAL}-${SLUG}

**Purpose**: ${SUMMARY}

| Attribute | Value |
|-----------|-------|
| Merged | ${DATE} |
| Files Changed | ${COUNT} |
| Tests Added | ${COUNT} |
| Conflicts with You | ${COUNT} |

**Key Changes**:
${BULLET_LIST}

**Potential Conflicts**:
${CONFLICT_LIST}
```

### Conflict Analysis Section

```markdown
## Conflict Analysis

### Conflict 1: ${FILE_PATH}

**Conflict Type**: ${TYPE} (Complementary/Contradictory/Orthogonal/Auto-Resolvable)

**Your Change**:
\`\`\`${LANG}
${YOUR_CODE}
\`\`\`

**Upstream Change**:
\`\`\`${LANG}
${UPSTREAM_CODE}
\`\`\`

**Ancestor Version** (for context):
\`\`\`${LANG}
${ANCESTOR_CODE}
\`\`\`

**Reasoning Chain**:
1. Your change does: ${DESCRIPTION}
2. Upstream change does: ${DESCRIPTION}
3. These are ${COMPATIBLE/INCOMPATIBLE} because: ${REASON}

**Resolution**: ${RESOLUTION_STRATEGY}

**Verification**:
- [ ] ${VERIFICATION_STEP_1}
- [ ] ${VERIFICATION_STEP_2}
```

### Regression Risk Table

```markdown
## Regression Risk Analysis

| Risk | Direction | Upstream Plan | Your Change | Likelihood | Test Command |
|------|-----------|---------------|-------------|------------|--------------|
| ${RISK_1} | ${DIR} | ${PLAN} | ${CHANGE} | ${LEVEL} | \`${CMD}\` |
| ... | ... | ... | ... | ... | ... |
```

### Merge Execution Plan

```markdown
## Merge Execution Plan

### Phase 1: Safe Merges (No Conflicts)

\`\`\`bash
# Create backup branch
git branch backup-before-merge

# Merge independent plans first
git merge origin/${TARGET} --no-commit

# Verify only expected files changed
git diff --staged --name-only

# If looks good, commit
git commit -m "Merge: ${PLAN_LIST} from ${TARGET}"

# Run tests for merged functionality
${TEST_COMMANDS}
\`\`\`

### Phase 2: Conflicting Merges

\`\`\`bash
# Continue with conflicting files
# For each conflict:

# Option A: Keep yours
git checkout --ours ${FILE_PATH}

# Option B: Take theirs
git checkout --theirs ${FILE_PATH}

# Option C: Manual merge
# Open ${FILE_PATH} and resolve markers

# After resolving:
git add ${FILE_PATH}
\`\`\`

### Phase 3: Validation

\`\`\`bash
# Full test suite
${FULL_TEST_COMMAND}

# Type checking
${TYPE_CHECK_COMMAND}

# Linting
${LINT_COMMAND}
\`\`\`
```

---

## Validation Gates

### Pre-Merge Validation Gate

Before generating merge plan, verify:
- [ ] Git state is clean (no uncommitted changes)
- [ ] Common ancestor found (or degraded mode acknowledged)
- [ ] Target branch exists and is reachable
- [ ] All subagents completed successfully
- [ ] No CRITICAL conflicts require immediate abort

### Footnote Reconciliation Protocol

**Critical**: Footnotes span 4 locations. All must sync after merge.

**Locations to update:**
1. Plan § Change Footnotes Ledger (plan.md)
2. Phase Footnote Stubs (tasks/phase-N/tasks.md)
3. Task table Notes column (footnote tags [^N])
4. Source code FlowSpace comments (if present)

**Conflict detection:**
- Your footnotes: [^1] through [^${YOUR_MAX}]
- Upstream footnotes: [^1] through [^${UPSTREAM_MAX}]
- If overlapping numbers: YOUR footnotes renumber from [^${UPSTREAM_MAX + 1}]

**Renumbering scheme:**
```
Your [^1] -> [^${NEW_START}]
Your [^2] -> [^${NEW_START + 1}]
...
```

**Update list:**
1. Update plan.md § 12: Add your renumbered footnotes
2. Update tasks/*/tasks.md: Replace [^N] tags with new numbers
3. Update source code FlowSpace comments: Replace [^N] with new numbers
4. Verify bidirectional links still resolve

### FlowSpace ID Reconciliation

**If source code has FlowSpace comments:**

For each file with embedded FlowSpace IDs:
1. Check if footnote number changed due to renumbering
2. If changed, add to update list:
   ```markdown
   ## FlowSpace ID Updates Required

   | File | Line | Old ID | New ID |
   |------|------|--------|--------|
   | src/auth.py | 45 | [^3] | [^7] |
   | src/user.py | 112 | [^4] | [^8] |
   ```

### Human Approval Gate

**MANDATORY**: No merge execution without explicit human approval.

```markdown
## Human Approval Required

Before executing this merge plan, please review:

### Summary Review
- [ ] I understand what ${PLAN_COUNT} upstream plans changed
- [ ] I understand the ${CONFLICT_COUNT} conflicts identified
- [ ] I understand the ${RISK_COUNT} regression risks

### Conflict Review
- [ ] I have reviewed each conflict's resolution strategy
- [ ] I understand which conflicts require manual resolution
- [ ] I am prepared to resolve the manual conflicts

### Risk Acknowledgment
- [ ] I will run the test suite after merging
- [ ] I understand which tests might fail
- [ ] I have a rollback plan if merge fails

---

**Proceed with merge execution?**

Type "PROCEED" to begin merge execution, or "ABORT" to cancel.
```

### Post-Merge Validation Checklist

After merge execution, verify:

```markdown
## Post-Merge Validation

- [ ] All tests pass: \`${TEST_COMMAND}\`
- [ ] No new linting errors: \`${LINT_COMMAND}\`
- [ ] Type checks pass: \`${TYPE_CHECK_COMMAND}\`
- [ ] Application starts correctly
- [ ] Key user flows still work
- [ ] Upstream plan functionality not regressed
- [ ] Your plan functionality not regressed
- [ ] Footnote ledgers synchronized (4 locations)
- [ ] FlowSpace IDs updated (if applicable)
```

### Visual Status Reconciliation

**Status precedence rules** (highest to lowest):
1. Blocked (any location shows blocked) -> all show blocked
2. In Progress (any actively being worked) -> show in progress
3. Complete (all locations agree) -> show complete
4. Pending (default) -> show pending

**4-location sync checklist:**
- [ ] Architecture Map diagram updated (:::pending/:::completed)
- [ ] Task table Status column updated ([ ]/[x])
- [ ] Task-to-Component table updated
- [ ] Plan progress tracking updated

### Atomic Update Protocol with Rollback

**Before merge:**
```bash
# Create backup branch
git branch backup-${DATE}-pre-merge
echo "Backup branch created: backup-${DATE}-pre-merge"
```

**Checkpoint phases:**
1. After each plan merge, verify tests pass
2. If tests fail, rollback to last checkpoint:
   ```bash
   git reset --hard ${CHECKPOINT_SHA}
   ```
3. Document failure in merge plan for retry

**Full rollback procedure:**
```bash
# If merge fails completely:
git checkout ${CURRENT_BRANCH}
git reset --hard backup-${DATE}-pre-merge
git branch -D backup-${DATE}-pre-merge  # optional cleanup
```

---

## Next Steps

**After generating merge plan document:**

If user says "PROCEED":
1. Execute merge plan phases in order
2. Stop after each phase for verification
3. Update checklist items as completed
4. If any phase fails, offer rollback

If user says "ABORT":
1. Save merge plan for later reference
2. Suggest alternative approaches:
   - Cherry-pick specific commits
   - Rebase instead of merge
   - Manual conflict resolution first

**Resume commands** (for later):
- Review merge plan: \`cat ${PLAN_DIR}/merge/${DATE}/merge-plan.md\`
- Retry merge: \`/8 --plan "${PLAN_DIR}"\`
- Manual merge: \`git merge ${TARGET}\`

---

## Notes

- This command is **analysis only** by default
- Merge execution requires explicit "PROCEED" response
- All context derived from git history (no external files)
- FlowSpace MCP is optional (command works without it)
- Cross-mode merges (Simple + Full) require extra care
```

---

## Success Message

After generating merge plan:

```
✅ Merge Plan Generated

Location: ${PLAN_DIR}/merge/${DATE}/merge-plan.md

Summary:
- Upstream plans: ${PLAN_COUNT}
- Direct conflicts: ${CONFLICT_COUNT}
- Semantic conflicts: ${SEMANTIC_COUNT}
- Regression risks: ${RISK_COUNT}
- Recommended approach: ${APPROACH}

Next step: Review merge plan and type "PROCEED" to execute, or "ABORT" to cancel.
```

If no upstream changes:

```
✅ No Upstream Changes

Main has no new commits since you branched ${DAYS_AGO} days ago.

Your branch is up to date. No merge needed.
```
