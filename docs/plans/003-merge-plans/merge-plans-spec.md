# Plan Merge Command (/8)

**Mode**: Full

> This specification incorporates findings from `research-dossier.md` and external research via Perplexity Deep Research on LLM-assisted merge strategies (2024-2025 state-of-the-art).

---

## The Problem

You've been working on your feature branch implementing a plan. While you were working, **other developers merged their completed plans into main**. Now you need to:

1. **Merge up from main** to get their changes
2. **Understand what changed** - potentially multiple plans landed while you were working
3. **Ensure no regressions** - your changes must work with their changes
4. **Create a clear merge plan** that both human and AI fully understand before execution

This is NOT about two versions of the same plan diverging. It's about **integrating upstream changes from multiple completed plans** into your working branch.

### Example Scenario

```
Your branch: feature/add-auth (working on plan 003-auth)
  ↳ Branched from main at commit abc123

While you worked, main received:
  - Plan 004-payments (merged 3 days ago)
  - Plan 005-notifications (merged 2 days ago)
  - Plan 006-user-profiles (merged yesterday)

Now you need to merge main → your branch:
  - Understand what 004, 005, 006 changed
  - Check for conflicts with your 003 changes
  - Ensure your auth changes don't break payments/notifications/profiles
  - Create a merge plan document before executing
```

---

## Research Context

Research dossier analysis revealed critical architectural constraints for the merge command:

- **Components affected**: All plan artifacts (spec.md, plan.md, tasks.md, execution.log.md), footnote ledgers (2 locations), source code FlowSpace comments
- **Critical dependencies**: Bidirectional footnote graph integrity, atomic 3-location update pattern, execution log append-only semantics
- **Modification risks**: HIGH - Merge must preserve graph integrity across 4 synchronized locations; partial merges corrupt provenance tracking
- **Link**: See `research-dossier.md` for full analysis (12 critical discoveries, 70+ findings)

---

## Summary

Create a new `/8` (alias: `/merge`) command that helps you **merge upstream changes from main** into your feature branch. The command:

1. **Discovers all plans/changes** that landed in main since you branched
2. **Analyzes each upstream plan** to understand what it changed and why
3. **Identifies potential conflicts** between upstream changes and your work
4. **Generates a comprehensive merge plan document** with diagrams, tables, and clear explanations
5. **Requires human approval** before any merge execution

The merge plan document is the primary output - it must be **crystal clear** so both human and AI fully understand what will happen before execution.

**Why**: When you've been working on a feature branch for days or weeks, main has moved on. Other plans have landed. You need a systematic way to understand what changed, ensure your work is compatible, and merge safely without regressions. The merge plan document provides the shared understanding needed before execution.

---

## Goals

### Primary: Understanding Before Action
- **G1**: Discover ALL plans/changes that landed in main since branching
- **G2**: Generate a **crystal-clear merge plan document** with diagrams, tables, and explanations
- **G3**: Ensure human and AI have **shared understanding** before any merge execution
- **G4**: Prioritize **clarity over automation** - the document is the primary deliverable

### Secondary: Safe Merge Execution
- **G5**: Identify potential conflicts between upstream changes and your work
- **G6**: Check for regressions - ensure your changes don't break upstream functionality
- **G7**: Preserve execution log integrity (append-only truth) from all sources
- **G8**: Maintain bidirectional footnote graph consistency across all 4 locations

### Technical: Implementation Approach
- **G9**: Use three-way merge with common ancestor (via `git merge-base`)
- **G10**: Derive all merge context from git history alone (no extra files to maintain)
- **G11**: Follow established command patterns (parallel subagents, validation gates)
- **G12**: Support both Simple Mode and Full Mode plans

---

## Non-Goals

- **NG1**: Automatic execution of merge without user review (clarity and approval first)
- **NG2**: Resolving source code conflicts directly (we analyze and document; git/user resolves)
- **NG3**: Maintaining separate historical examples database (derive everything from git)
- **NG4**: Real-time collaborative editing (this is batch analysis and merge)
- **NG5**: Undo/rollback after merge execution (user should commit before merging)
- **NG6**: Replacing git merge (we enhance understanding, not replace git)
- **NG7**: Fully automated regression testing (we identify risks; user validates)

---

## Complexity

- **Score**: CS-4 (large)
- **Breakdown**: S=2, I=1, D=1, N=1, F=1, T=2 (Total: 8)
- **Confidence**: 0.85 (increased after external research validated approach)
- **Assumptions**:
  - Three-way merge using `git merge-base` for common ancestor
  - Git provides branch identification and file retrieval at any commit
  - Existing command patterns (parallel subagents) are reusable
  - FlowSpace MCP is optional (fallback to standard tools)
  - All merge context derived from git (no extra files to maintain)
- **Dependencies**:
  - Existing plan folder structure
  - Git for merge-base calculation and version retrieval
  - All existing command file patterns
- **Risks**:
  - Graph corruption if footnote reconciliation fails
  - Data loss if execution logs not properly merged
  - Cross-mode merge complexity (Simple + Full)
  - Merge-base not found (branches have no common ancestor)
- **Phases** (suggested):
  1. **Input Parsing & Ancestor Resolution**: Parse branch, compute `git merge-base`, validate
  2. **Three-Version Extraction**: Retrieve ancestor, incoming, and local versions of all artifacts
  3. **Parallel Analysis**: Launch parallel subagents (6 fixed + 1 per upstream plan) for analysis
  4. **Conflict Classification & Merge Plan Generation**: Classify as complementary/contradictory/orthogonal, create merge plan
  5. **Validation & User Approval Gate**: Pre-merge validation, present for review
  6. **Merge Execution** (conversational, not automated): Apply resolutions per user instruction
  7. **Post-Merge Validation**: Verify graph integrity

### Complexity Breakdown Detail

| Factor | Score | Rationale |
|--------|-------|-----------|
| **Surface Area (S)** | 2 | Touches: spec.md, plan.md, tasks.md (per phase), execution.log.md (per phase), 2 footnote ledgers, source code comments |
| **Integration (I)** | 1 | Git integration for merge-base and version retrieval; FlowSpace optional |
| **Data/State (D)** | 1 | No database; complex state in markdown files with synchronized locations; all derived from git |
| **Novelty (N)** | 1 | Reduced from 2: external research validated three-way approach with clear patterns from LLMinus, MergeBERT, GitHub Copilot |
| **Non-Functional (F)** | 1 | Must preserve data integrity; no performance/security concerns |
| **Testing/Rollout (T)** | 2 | Requires staged rollout; needs feature flag for merge execution |

---

## Acceptance Criteria

### AC1: Upstream Discovery
- [ ] Identifies common ancestor via `git merge-base HEAD main`
- [ ] Lists ALL commits on main since branching point
- [ ] Identifies which commits are plan-related (touch `docs/plans/`)
- [ ] Groups commits by plan folder (e.g., all commits for plan-004, plan-005, etc.)
- [ ] Summarizes: "N plans landed in main while you were working"

### AC2: Per-Plan Analysis
- [ ] For each upstream plan that landed, analyzes:
  - What the plan was about (reads spec.md summary)
  - What files/components it modified
  - What tests it added or changed
  - Key implementation decisions from execution logs
- [ ] Produces a **Plan Summary Card** for each upstream plan:
  ```
  Plan 004-payments
  ├── Purpose: Add Stripe payment processing
  ├── Files Changed: 12 files in src/payments/, 3 in tests/
  ├── Key Changes: New PaymentService, updated User model
  └── Potential Conflicts: User model (you also modified)
  ```

### AC3: Conflict & Risk Identification
- [ ] Identifies file-level conflicts (same file modified by upstream and your branch)
- [ ] Identifies semantic conflicts (same component/API modified differently)
- [ ] Identifies potential regressions:
  - Your changes might break upstream functionality
  - Upstream changes might break your functionality
- [ ] Categorizes each conflict/risk:
  - **Direct Conflict**: Same file, same lines
  - **Semantic Conflict**: Same concept, different files
  - **Regression Risk**: Behavioral interaction, needs testing
  - **No Conflict**: Independent changes

### AC4: Merge Plan Document - Clarity First
- [ ] Creates `docs/plans/<your-plan>/merge/<date>/merge-plan.md`
- [ ] **Executive Summary** (1 page max):
  - What you're merging: "3 plans landed in main"
  - Quick risk assessment: "2 conflicts, 1 regression risk"
  - Recommended approach: "Merge in order, test after each"
- [ ] **Upstream Plans Overview** (visual):
  ```mermaid
  timeline
    title Plans Merged to Main While You Worked
    section Week 1
      Plan 004-payments : Merged Mon
    section Week 2
      Plan 005-notifications : Merged Wed
      Plan 006-profiles : Merged Fri
  ```
- [ ] **Conflict Map** (diagram showing where conflicts occur):
  ```mermaid
  graph LR
    subgraph Your Changes
      A[src/models/user.py]
      B[src/api/auth.py]
    end
    subgraph Plan 004
      C[src/models/user.py]
      D[src/payments/stripe.py]
    end
    A -.->|CONFLICT| C
  ```
- [ ] **Detailed Analysis** per conflict with:
  - What each side changed and why
  - Recommended resolution
  - Verification steps

### AC5: Regression Risk Analysis
- [ ] For each upstream plan, identifies:
  - Tests they added that your changes might break
  - Functionality they depend on that you modified
- [ ] For your plan, identifies:
  - Components you rely on that they modified
  - Assumptions you made that they may have invalidated
- [ ] Produces **Regression Risk Table**:
  | Risk | Upstream Plan | Your Change | Likelihood | Verification |
  |------|--------------|-------------|------------|--------------|
  | User.email field | 004-payments | Added email validation | Medium | Run payment tests |

### AC6: Recommended Merge Order
- [ ] Suggests order to merge upstream changes (if multiple plans)
- [ ] Explains dependencies between upstream plans
- [ ] Provides step-by-step merge instructions:
  ```
  Step 1: Merge plan-004-payments first (no dependencies)
  Step 2: Run tests: pytest tests/payments/
  Step 3: Merge plan-005-notifications (depends on 004)
  Step 4: Run tests: pytest tests/notifications/
  ...
  ```

### AC7: Human Approval Gate
- [ ] Presents merge plan document for review
- [ ] Requires explicit "proceed" instruction before any merge
- [ ] Allows human to modify plan (e.g., change merge order, skip a plan)
- [ ] Documents any human overrides in the merge plan

### AC8: Post-Merge Validation Checklist
- [ ] Generates checklist for after merge:
  - [ ] All tests pass
  - [ ] No new linting errors
  - [ ] Application starts correctly
  - [ ] Key user flows still work
  - [ ] Upstream plan functionality not regressed
- [ ] Links to specific tests that should be run

---

## Risks & Assumptions

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Footnote graph corruption | Medium | Critical | Implement 4-location atomic updates with rollback |
| Execution log data loss | Low | Critical | Append-only merge strategy; never discard entries |
| Cross-mode merge complexity | Medium | High | Warn user; provide manual resolution path |
| No common ancestor found | Low | High | Error with clear message; suggest manual merge |
| Performance with large plans | Low | Medium | Parallel subagents; streaming output |
| User confusion with conflicts | Low | Medium | Three-way context reduces false conflicts; clear categorization |
| LLM hallucination in merge | Medium | Medium | Require explicit reasoning; human approval gate |

### Assumptions

- A1: User has committed local changes before merging (no dirty state)
- A2: Git is available for merge-base calculation and version retrieval
- A3: Both sources reference the same plan folder (same ordinal-slug)
- A4: Branches share a common ancestor (not completely unrelated histories)
- A5: Existing command patterns (subagents, validation) are stable
- A6: FlowSpace MCP may or may not be available (command works either way)
- A7: User will review merge plan before approving execution
- A8: All merge context can be derived from git (no external files needed)

---

## Open Questions

1. **[RESOLVED: Merge execution in same command or separate?]**
   `/8` generates merge plan only. User can instruct execution in same conversation. Future `/8-b` command if dedicated execution needed.

2. **[RESOLVED: What are we merging?]**
   **Upstream changes from main.** Not two versions of the same plan, but integrating multiple completed plans that landed in main while you were working. The command discovers all upstream plans, analyzes each one, identifies conflicts with your work, and generates a comprehensive merge plan document.

3. **[RESOLVED: Clarity is the priority?]**
   **YES.** The merge plan document must be crystal clear with diagrams, tables, and explanations. Both human and AI must fully understand what will happen before any merge execution. Understanding comes before action.

4. **[NEEDS CLARIFICATION: Conflict resolution UI?]**
   For conflicts that need manual resolution, should the command provide interactive prompts or just document what needs attention?

5. **[NEEDS CLARIFICATION: Merge plan persistence?]**
   Should merge plans be retained after execution for audit purposes, or cleaned up?

---

## ADR Seeds (Optional)

### Decision Drivers
- Must preserve bidirectional graph integrity (non-negotiable architectural constraint)
- Must follow established parallel subagent pattern for consistency
- Must support both Simple and Full mode plans
- Should minimize user effort for common cases (auto-resolve where safe)
- Should derive all context from git (no extra maintenance burden)

### Decision Made: Three-Way Merge with Git-Only Context

**Chosen**: Three-way merge using `git merge-base` for common ancestor detection.

**Rationale** (from external research):
- LLMinus (Linux kernel, 2025): "to resolve a conflict, one must understand why the divergence occurred"
- MergeBERT: 63-68% accuracy with three-way, 3x improvement over two-way
- GitHub Copilot: Uses merge-base context for conflict analysis
- Three-way reduces false conflicts by distinguishing "both changed" from "one changed"

**Rejected Alternatives**:
- **Two-way merge**: Insufficient context for semantic conflict classification
- **Historical pattern retrieval**: Adds maintenance burden; three-way context is sufficient for v1
- **Manual-only merge**: Too much user effort; LLM can auto-resolve many conflicts

### Stakeholders
- Plan authors (primary users)
- Team members collaborating on plans
- CI/CD systems (if automated merge is desired in future)

---

## External Research

### Incorporated
Perplexity Deep Research on "LLM-Assisted Three-Way Merge Strategies" (2026-01-01)

### Key Findings

**1. Three-Way Merge is Industry Standard for LLM-Assisted Merge**
- LLMinus (Linux kernel, 2025 Maintainer's Summit): Uses three-way context to help LLMs understand why divergence occurred
- GitHub Copilot: Explicitly uses merge-base in conflict analysis
- MergeBERT: 63-68% accuracy with three-way differencing, 3x improvement over alternatives

**2. Semantic Conflict Categories**
Research identified four semantic categories for three-way merge:
- **Complementary**: Both branches made non-conflicting changes (auto-merge both)
- **Contradictory**: Both changed same thing differently (must choose one)
- **Orthogonal**: One change depends on value the other modified (human decision)
- **Auto-Resolvable**: Only one branch changed from ancestor (that branch wins)

**3. Anti-Hallucination Patterns**
- Chain-of-Verification: LLM verifies its own proposals
- Constrained output: Structured merge plan format reduces hallucination
- Retrieval-Augmented Generation: Historical examples improve accuracy (deferred to v2)
- Human approval gate: Never auto-execute without review

**4. Branch-Solve-Merge Pattern for Subagents**
- Don't ask one LLM "resolve this conflict"
- Instead: Parallel agents analyze each branch's intent independently
- Synthesis agent merges their analyses
- Improves correctness and reduces position bias

**5. Execution Log Strategy**
- All entries preserved from both sources
- Interleave by timestamp
- Flag concurrent logs (simultaneous execution indicator)
- Include metadata about source branch

**6. Git Commands for Three-Way Context**
```bash
# Find common ancestor
ANCESTOR=$(git merge-base HEAD incoming-branch)

# Retrieve ancestor version
git show ${ANCESTOR}:path/to/file.md

# Retrieve incoming version
git show incoming-branch:path/to/file.md

# Local version is current working copy
```

### Applied To
- **G4, G5**: Three-way merge goals
- **AC1-AC5**: Source identification, extraction, analysis, conflict detection/classification
- **ADR Seeds**: Decision rationale for three-way approach
- **Subagent Architecture**: 6 fixed subagents + dynamic U2-UN (1 per upstream plan)

### Sources
- LLMinus: https://lwn.net/Articles/1051607/
- MergeBERT: https://arxiv.org/abs/2109.00084
- GitHub Copilot Merge: https://code.visualstudio.com/docs/sourcecontrol/merge-conflicts
- Gmerge (GPT-3 merging): https://www.cs.yale.edu/homes/piskac/papers/2022ZhangETALmerge.pdf

---

## Merge Analysis Architecture

### Git-Only Context Retrieval

All merge context is derived from git history. No extra files to maintain.

```bash
# Step 1: Find common ancestor with main
ANCESTOR=$(git merge-base HEAD main)
# Example output: abc123 (where your branch diverged from main)

# Step 2: Get all commits on main since you branched
git log ${ANCESTOR}..main --oneline
# Output:
# def456 Plan 006-profiles: Complete implementation
# ghi789 Plan 005-notifications: Add email service
# jkl012 Plan 004-payments: Stripe integration

# Step 3: Identify which plans landed
git log ${ANCESTOR}..main --oneline -- "docs/plans/"
# Shows only commits that touched plan folders

# Step 4: For each upstream plan, get its details
git show main:docs/plans/004-payments/payments-spec.md
git show main:docs/plans/004-payments/payments-plan.md
# ... analyze what each plan did

# Step 5: Get files changed by main vs your branch
git diff ${ANCESTOR}..main --name-only    # What main changed
git diff ${ANCESTOR}..HEAD --name-only    # What you changed
git diff ${ANCESTOR}..main --name-only | sort > /tmp/main_files
git diff ${ANCESTOR}..HEAD --name-only | sort > /tmp/your_files
comm -12 /tmp/main_files /tmp/your_files  # Overlap = potential conflicts
```

### Subagent Architecture (Parallel Analysis)

| ID | Role | Input | Output |
|----|------|-------|--------|
| **U1** | Upstream Plans Discovery | Git log since ancestor | List of plans that landed in main |
| **U2** | Plan 004 Analyst | Plan 004's spec, plan, logs | Summary card for plan 004 |
| **U3** | Plan 005 Analyst | Plan 005's spec, plan, logs | Summary card for plan 005 |
| **U4** | Plan 006 Analyst | Plan 006's spec, plan, logs | Summary card for plan 006 |
| **Y1** | Your Changes Analyst | Your branch's diff from ancestor | What you changed and why |
| **C1** | Conflict Detector | File lists from main + your branch | Direct conflicts (same file) |
| **C2** | Semantic Conflict Detector | All plan summaries + your changes | Semantic conflicts (same concept) |
| **R1** | Regression Risk Analyst | Upstream tests + your changes | Potential regressions |
| **S1** | Synthesis & Ordering | All findings | Merge order, risk assessment |

**Note**: Number of plan analysts (U2-U4) scales with how many plans landed.

### Merge Plan Document Structure

```markdown
# Merge Plan: Integrating Upstream Changes

**Generated**: [timestamp]
**Your Branch**: feature/add-auth @ [SHA]
**Merging From**: main @ [SHA]
**Common Ancestor**: [SHA] ([date] - N days ago)

---

## Executive Summary

### What Happened While You Worked
You branched from main **14 days ago**. Since then, **3 plans** landed in main:

| Plan | Merged | Purpose | Risk to You |
|------|--------|---------|-------------|
| 004-payments | 10 days ago | Stripe integration | Medium (both touch User model) |
| 005-notifications | 7 days ago | Email service | Low (independent) |
| 006-profiles | 3 days ago | User profiles | High (both modify User API) |

### Conflict Summary
- **Direct Conflicts**: 2 files (src/models/user.py, src/api/endpoints.py)
- **Semantic Conflicts**: 1 (User model has different assumptions)
- **Regression Risks**: 3 (payment tests, profile tests, your auth tests)

### Recommended Approach
```
1. Merge 005-notifications first (independent, no conflicts)
2. Merge 004-payments, resolve User model conflict
3. Run payment tests to verify
4. Merge 006-profiles, resolve User API conflict
5. Run full test suite
```

---

## Upstream Plans Analysis

### Plan 004-payments
[Plan Summary Card with details]

### Plan 005-notifications
[Plan Summary Card with details]

### Plan 006-profiles
[Plan Summary Card with details]

---

## Conflict Analysis

### Conflict 1: src/models/user.py

**Your Change**:
- Added `email_verified: bool` field
- Added `verify_email()` method

**Plan 004's Change**:
- Added `stripe_customer_id: str` field
- Added `create_payment_method()` method

**Conflict Type**: Complementary (different fields, same file)

**Resolution**: Both changes can coexist. Git will auto-merge.

**Verification**: Run `pytest tests/models/test_user.py`

---

### Conflict 2: src/api/endpoints.py

**Your Change**:
- Added `/auth/verify-email` endpoint
- Modified `/auth/login` to check email verification

**Plan 006's Change**:
- Added `/profile/update` endpoint
- Modified `/auth/login` to load profile data

**Conflict Type**: Semantic (both modified login behavior)

**Resolution**: Manual merge needed. Both login modifications must be combined.

**Verification**:
1. Test login with verified email
2. Test login loads profile data
3. Test login with unverified email

---

## Regression Risk Analysis

| Risk | Upstream | Your Change | Likelihood | Test Command |
|------|----------|-------------|------------|--------------|
| Payment flow | 004 | User model changes | Medium | `pytest tests/payments/` |
| Profile display | 006 | User API changes | High | `pytest tests/profiles/` |
| Auth flow | Your plan | Upstream user changes | Medium | `pytest tests/auth/` |

---

## Merge Execution Plan

### Phase 1: Safe Merges (No Conflicts)
```bash
# Merge notifications first (independent)
git merge origin/main --no-commit
# Verify: git diff --staged shows only notification changes
git commit -m "Merge: 005-notifications from main"
pytest tests/notifications/
```

### Phase 2: Conflicting Merges
```bash
# Continue merge, resolve conflicts
git checkout --theirs src/payments/  # Take their payment code
git checkout --ours src/auth/        # Keep our auth code
# Manual: Combine changes in src/models/user.py
# Manual: Combine changes in src/api/endpoints.py
git add .
git commit -m "Merge: 004-payments, 006-profiles from main (resolved conflicts)"
```

### Phase 3: Validation
```bash
pytest                           # Full test suite
python -m mypy src/              # Type checking
python manage.py check           # Django checks (if applicable)
```

---

## Human Approval Required

Before executing this merge plan:
- [ ] I have reviewed the conflict analysis
- [ ] I understand the regression risks
- [ ] I am prepared to resolve the manual conflicts
- [ ] I will run the validation tests after merging

**Proceed?** [Tell me to proceed when ready]
```

---

## Testing Strategy

- **Approach**: Manual Only
- **Rationale**: This is a prompt file (markdown), not executable code. KISS principle applies.
- **Focus Areas**:
  - Verify command output structure matches expected merge plan format
  - Test with sample divergent plan folders (Simple+Simple, Full+Full, cross-mode)
  - Validate footnote reconciliation logic produces correct renumbering
- **Excluded**: Automated unit/integration tests (no code to test)
- **Mock Usage**: N/A (manual testing only)
- **Validation Method**: Run `/8` against prepared test plan folders, manually verify output

---

## Documentation Strategy

- **Location**: None (self-documenting command file)
- **Rationale**: The command file (`plan-8-merge.md`) contains all usage instructions in description and execution flow. Follows pattern of other `/plan-*` commands.
- **Target Audience**: N/A
- **Maintenance**: Update command file directly when behavior changes

---

## Clarifications

### Session 2026-01-01

**Q1: Workflow Mode**
- **Answer**: B (Full)
- **Rationale**: CS-4 complexity with multiple parallel subagents, comprehensive merge plan document

**Q2: Testing Strategy**
- **Answer**: D (Manual Only)
- **Rationale**: This is just prompt changes, no actual code. KISS principle.

**Q3: Documentation Strategy**
- **Answer**: D (No new documentation)
- **Rationale**: Command file itself is self-documenting. Follows pattern of other `/plan-*` commands.

**Q4: Merge Execution Scope**
- **Answer**: A (Analyze only) with conversational execution
- **Rationale**: `/8` generates the merge plan. User can instruct execution in same conversation. If needed later, add `/8-b` for dedicated execution command.

**Q5: What Is The Real Problem?** *(Clarified)*
- **Answer**: Integrating upstream changes from main, not divergent states of same plan
- **Rationale**: When you've been working on your feature branch, other developers merge their completed plans into main. You need to understand what ALL of those plans changed, ensure your work doesn't conflict or regress, and create a clear merge plan document before executing. The problem is understanding multiple upstream plans, not reconciling two versions of your plan.

**Q6: What Is The Primary Output?**
- **Answer**: A crystal-clear merge plan document
- **Rationale**: The merge plan document must be so clear that both human and AI fully understand what will happen before any merge execution. Diagrams, tables, conflict analysis, regression risks, merge order recommendations. Understanding before action.

**Q7: How Do We Discover Upstream Changes?**
- **Answer**: Git-only, no extra files
- **Rationale**: Use `git merge-base HEAD main` to find where you branched, then `git log` to find all plans that landed in main since. Analyze each upstream plan's spec.md, plan.md, and execution logs to understand what it changed. All context from git history.

---

**Specification Created**: 2026-01-01
**Plan Folder**: docs/plans/003-merge-plans/
**Next Step**: Run `/plan-2-clarify` for high-impact questions, or `/plan-3-architect` to proceed to architecture.
