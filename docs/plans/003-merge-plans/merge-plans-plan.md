# Plan Merge Command (/8) Implementation Plan

**Mode**: Full
**Plan Version**: 1.0.0
**Created**: 2026-01-01
**Spec**: [./merge-plans-spec.md](./merge-plans-spec.md)
**Research**: [./research-dossier.md](./research-dossier.md)
**Status**: DRAFT

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technical Context](#technical-context)
3. [Critical Research Findings](#critical-research-findings)
4. [Testing Philosophy](#testing-philosophy)
5. [Implementation Phase](#phase-1-create-plan-8-mergemd-command-file)
6. [Cross-Cutting Concerns](#cross-cutting-concerns)
7. [Progress Tracking](#progress-tracking)
8. [Change Footnotes Ledger](#change-footnotes-ledger)

---

## Executive Summary

### Problem Statement
When working on a feature branch, other developers merge their completed plans into main. You need a systematic way to understand what changed upstream, identify conflicts with your work, and merge safely without regressions.

### Solution Approach
Create a single markdown command file (`agents/commands/plan-8-merge.md`) that:
- Discovers all plans that landed in main since you branched
- Launches parallel subagents to analyze upstream changes (6 fixed + 1 per upstream plan)
- Generates a crystal-clear merge plan document with diagrams and tables
- Requires human approval before any merge execution
- Derives all context from git history (no extra files)

### Expected Outcome
A single command file (~400-600 lines) following established patterns from plan-3, plan-5, plan-7 that produces comprehensive merge plan documents.

### Why Single Phase
This is a **prompt file** - one markdown document that will be interpreted by an LLM agent. There's no code to compile, no tests to write, no infrastructure to set up. The entire deliverable is writing one well-structured markdown file. Multiple phases would be over-engineering.

---

## Technical Context

### What We're Building
**File**: `agents/commands/plan-8-merge.md`
**Type**: Markdown prompt file (not executable code)
**Size**: ~400-600 lines (comparable to plan-5, plan-7)
**Pattern**: YAML front matter → $ARGUMENTS → Numbered steps → Subagents → Output template → Validation

### Integration Points
- **Git**: Uses `git merge-base`, `git log`, `git show`, `git diff` for context
- **CLI**: Discovered via YAML front matter, invoked as `/8` or `/merge`
- **Plan Artifacts**: Reads from `docs/plans/<ordinal>-<slug>/` structure
- **FlowSpace MCP**: Optional enhancement (must work without it)

### Established Patterns to Follow

From analysis of existing commands:

```markdown
# Pattern 1: YAML Front Matter (lines 1-3)
---
description: One-line summary for CLI listing
---

# Pattern 2: Command Header
# plan-8-merge (alias: /8, /merge)

# Pattern 3: $ARGUMENTS Placeholder
User input:

$ARGUMENTS

# Pattern 4: Numbered Deterministic Steps
## Execution Flow
1) [Step with validation logic]
   - [Sub-bullets for branching]
2) [Next step]

# Pattern 5: Parallel Subagent Launch
**Subagent N: [Role]**
"[Task description]

**Input**: [What it receives]
**Output**: [Expected format]"

# Pattern 6: Synthesis Framework
After all subagents complete:
1. Collect findings
2. Deduplicate
3. Classify
4. Generate output

# Pattern 7: Next Step Handoff
Next step: [Action with command link]
```

---

## Critical Research Findings

### From Research Dossier + Implementation Strategy

| # | Impact | Finding | Action for Command File |
|---|--------|---------|------------------------|
| 01 | Critical | **Bidirectional footnote graph** spans 4 locations | Include footnote reconciliation protocol in validation gates |
| 02 | Critical | **Execution logs are append-only truth** | Merge strategy must preserve ALL entries, interleave by timestamp |
| 03 | Critical | **Atomic 3-location updates** required | Post-merge validation must check dossier + plan + both ledgers |
| 04 | High | **Parallel subagents** (6 fixed + 1 per upstream plan) | Define U1, Y1, C1-C2, R1, S1 (fixed) + U2-UN (dynamic) with clear I/O |
| 05 | High | **Cross-mode complexity** (Simple vs Full) | Include mode detection gate with warning for cross-mode |
| 06 | High | **LLM hallucination risk** in conflict resolution | Chain-of-verification, constrained classification, uncertainty flagging |
| 07 | High | **FlowSpace IDs** embedded in source code | Track in subagent output, include in source code update list |
| 08 | High | **Three-way merge** is industry standard | Use `git merge-base` for ancestor, classify as Complementary/Contradictory/Orthogonal/Auto-Resolvable |
| 09 | Medium | **Visual status indicators** must sync | Status precedence rules, 4-location synchronization |
| 10 | Medium | **No common ancestor** edge case | Degraded mode fallback with explicit warning |

### Anti-Hallucination Patterns (from External Research)

These must be incorporated into the command file:

1. **Chain-of-Verification**: Every resolution includes explicit reasoning chain
2. **Constrained Classification**: Only 4 conflict types allowed (no invented categories)
3. **Explicit Uncertainty**: Confidence < 80% triggers human review flag
4. **Never Invent Code**: Can only keep local, take incoming, or combine additive changes

---

## Testing Philosophy

### Approach: Manual Only
**Rationale**: This is a markdown prompt file, not executable code. KISS applies.

### Test Scenarios

| Scenario | Setup | Expected Merge Plan Output |
|----------|-------|---------------------------|
| **No upstream** | Branch from main, no new commits on main | "Main has no new commits since you branched" message |
| **Single plan** | 1 plan merged to main after branching | 1 Plan Summary Card, simple merge order |
| **Multiple plans** | 3+ plans merged to main | N summary cards, ordered merge recommendation |
| **No conflicts** | Different files modified | All conflicts = "No Conflict" category |
| **Direct conflict** | Same file modified both sides | Conflict Analysis with file-level resolution |
| **Semantic conflict** | Same component/API, different files | Semantic Conflict flagged for human review |
| **Cross-mode** | Local=Simple, Incoming=Full (or vice versa) | Warning with manual intervention path |

### Validation Checklist
- [ ] Command file parses (valid YAML front matter)
- [ ] CLI lists command when running help
- [ ] All 6 fixed subagents + dynamic U2-UN template have Input/Output specs
- [ ] Merge plan template has all required sections (AC4)
- [ ] Human approval gate is mandatory (AC7)
- [ ] All 8 acceptance criteria satisfied

---

## Phase 1: Create plan-8-merge.md Command File

**Objective**: Write the complete `/8` merge command file following established patterns.

**Deliverable**: `agents/commands/plan-8-merge.md` (~400-600 lines)

**Dependencies**: None

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Inconsistent with other commands | Low | Medium | Reference plan-3, plan-5, plan-7 patterns |
| Missing edge cases | Medium | Medium | Cover all 7 test scenarios in logic |
| Subagent outputs don't align | Low | Medium | Define strict output schemas |

---

### Tasks (Manual Approach)

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [ ] | T001 | Create file with YAML front matter and command header | 1 | Setup | -- | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Front matter parses, title includes aliases `/8, /merge` | Follow plan-7 pattern |
| [ ] | T002 | Write executive summary (purpose, approach, key outputs) | 2 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | 2-3 paragraphs explaining command purpose and merge plan document as primary output | Reference spec Summary section |
| [ ] | T003 | Write $ARGUMENTS section with flag definitions | 1 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | `--plan`, `--target` flags documented with defaults | Target defaults to `main` |
| [ ] | T004 | Write Execution Flow Step 1: Input resolution and validation | 2 | Core | T003 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Path resolution logic, git state check (clean working tree), plan folder detection | Include error messages for invalid state |
| [ ] | T005 | Write Execution Flow Step 2: Common ancestor detection | 2 | Core | T004 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | `git merge-base HEAD main` with error handling, no-ancestor fallback to degraded mode | Per Finding 10 |
| [ ] | T006 | Write Execution Flow Step 3: Three-version extraction | 2 | Core | T005 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Git commands to retrieve ancestor/main/local versions of all plan artifacts | `git show ${ANCESTOR}:path`, `git show main:path` |
| [ ] | T007 | Write Execution Flow Step 4: Cross-mode detection gate | 2 | Core | T006 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Detect Simple vs Full mode in both sources, warn if cross-mode with manual intervention path | Per Finding 05 |
| [ ] | T008 | Write Execution Flow Step 5: Launch parallel subagents instruction | 1 | Core | T007 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | "Launch all subagents in single message" with blocking instruction | Follow plan-3 pattern |
| [ ] | T009 | Write Subagent U1: Upstream Plans Discovery | 2 | Core | T008 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Git log parsing to find all plans landed since ancestor, outputs list of plan ordinals | `git log ${ANCESTOR}..main -- "docs/plans/"` |
| [ ] | T010 | Write Subagent U2-UN: Plan Analyst (dynamic template) | 3 | Core | T009 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | One subagent per upstream plan, reads spec/plan/logs, outputs Plan Summary Card | Card includes: Purpose, Files Changed, Key Changes, Tests Added, Potential Conflicts |
| [ ] | T011 | Write Subagent Y1: Your Changes Analyst | 2 | Core | T008 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Analyzes your branch's diff from ancestor, outputs what you changed and why | `git diff ${ANCESTOR}..HEAD` analysis |
| [ ] | T012 | Write Subagent C1: File Conflict Detector | 2 | Core | T008 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Compares file lists, identifies direct conflicts (same file both sides) | `comm -12` pattern for overlap |
| [ ] | T013 | Write Subagent C2: Semantic Conflict Detector | 3 | Core | T008 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Cross-plan analysis for same component/API modified differently, flags for human review | Higher CS due to semantic analysis complexity |
| [ ] | T014 | Write Subagent R1: Regression Risk Analyst | 2 | Core | T008 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Identifies tests upstream added that your changes might break, and vice versa | Outputs Regression Risk Table |
| [ ] | T015 | Write Subagent S1: Synthesis & Ordering | 3 | Core | T008 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Determines merge order based on dependencies, synthesizes overall risk assessment | Outputs ordered merge steps |
| [ ] | T016 | Write Synthesis Framework section | 2 | Core | T015 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | "After all subagents complete..." with deduplication, classification, prioritization | Mirror plan-3 synthesis pattern |
| [ ] | T017 | Write Conflict Classification taxonomy | 2 | Core | T016 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | 4 categories: Complementary (both coexist), Contradictory (human decides), Orthogonal (dependency), Auto-Resolvable (one changed) | Per spec External Research, Finding 08 |
| [ ] | T018 | Write Anti-Hallucination patterns section | 2 | Core | T017 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Chain-of-verification, constrained output, uncertainty flagging, never invent code | Per Finding 06 |
| [ ] | T019 | Write Execution Log Merge Strategy section | 2 | Core | T016 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Append-only merge, interleave by timestamp, source attribution, concurrent execution flags | Per Finding 02 - NEVER discard entries |
| [ ] | T020 | Write Merge Plan Document Template: Header | 1 | Core | T016 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Generated timestamp, Your Branch @ SHA, Merging From @ SHA, Common Ancestor @ SHA | Per spec AC4 |
| [ ] | T021 | Write Merge Plan Document Template: Executive Summary | 2 | Core | T020 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | "What Happened While You Worked" table, Conflict Summary bullets, Recommended Approach | |
| [ ] | T022 | Write Merge Plan Document Template: Mermaid timeline diagram | 2 | Core | T021 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Timeline showing when each upstream plan merged | Use `timeline` mermaid type |
| [ ] | T023 | Write Merge Plan Document Template: Mermaid conflict map | 2 | Core | T021 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Graph showing Your Changes vs Upstream with conflict edges | Use `graph LR` with subgraphs |
| [ ] | T024 | Write Merge Plan Document Template: Plan Summary Card format | 2 | Core | T021 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Purpose, Files Changed, Key Changes, Tests Added, Potential Conflicts structure | Per spec AC2 |
| [ ] | T025 | Write Merge Plan Document Template: Conflict Analysis section | 2 | Core | T021 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Per-conflict: Your Change, Upstream Change, Conflict Type, Resolution, Verification | Include reasoning chain per anti-hallucination |
| [ ] | T026 | Write Merge Plan Document Template: Regression Risk table | 2 | Core | T021 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Risk, Upstream Plan, Your Change, Likelihood, Test Command columns | Per spec AC5 |
| [ ] | T027 | Write Merge Plan Document Template: Merge Execution Plan section | 2 | Core | T021 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Phased bash commands: Safe Merges first, Conflicting Merges second, Validation third | Per spec AC6 |
| [ ] | T028 | Write Pre-Merge Validation Gate | 2 | Core | T027 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Git state clean, ancestor found, backup created, mode compatibility checked | |
| [ ] | T029 | Write Footnote Reconciliation Protocol | 3 | Core | T028 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Detect footnote conflicts, renumbering scheme (local renumbers from max(incoming)+1), 4-location update list | Per Finding 01 - CRITICAL |
| [ ] | T030 | Write FlowSpace ID Reconciliation section | 2 | Core | T029 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Source code update list for files needing FlowSpace comment updates after footnote renumbering | Per Finding 07 |
| [ ] | T031 | Write Human Approval Gate | 2 | Core | T030 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Summary review checkbox, Conflict review checkbox, Risk acknowledgment, explicit "PROCEED?" prompt | Per spec AC7 - MANDATORY |
| [ ] | T032 | Write Post-Merge Validation Checklist | 2 | Core | T031 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | All tests pass, no linting errors, app starts, upstream functionality works, footnotes valid | Per spec AC8 |
| [ ] | T033 | Write Visual Status Reconciliation section | 2 | Core | T032 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Status precedence rules table, 4-location sync checklist (diagram, task table, checkboxes, progress) | Per Finding 09 |
| [ ] | T034 | Write Atomic Update Protocol with rollback | 2 | Core | T032 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | Backup branch creation, checkpoint phases, rollback procedure if validation fails | Per R1-08 |
| [ ] | T035 | Write Next Step Handoff section | 1 | Core | T034 | /Users/jordanknight/github/tools/agents/commands/plan-8-merge.md | "Proceed?" response handling, resume commands, verification test suggestions | |
| [ ] | T036 | Run `./setup.sh` to sync and install command | 1 | Validation | T035 | /Users/jordanknight/github/tools/setup.sh | Command appears in `~/.claude/commands/plan-8-merge.md` | |
| [ ] | T037 | Manual test: No upstream changes scenario | 2 | Validation | T036 | -- | Correct "no changes" message displayed | Test scenario 1 |
| [ ] | T038 | Manual test: Single upstream plan scenario | 2 | Validation | T036 | -- | Valid merge plan with 1 summary card | Test scenario 2 |
| [ ] | T039 | Manual test: Multiple upstream plans scenario | 2 | Validation | T036 | -- | Valid merge plan with N cards, ordered merge | Test scenario 3 |
| [ ] | T040 | Manual test: Direct file conflict scenario | 2 | Validation | T036 | -- | Conflict classified with resolution | Test scenario 4 |
| [ ] | T041 | Validate AC1-AC8 satisfaction | 2 | Validation | T040 | -- | All 8 acceptance criteria from spec pass | Final validation |

---

### Task Groupings (for implementation flow)

**Group A: File Setup (T001-T003)** - ~15 lines
Create the file, add front matter, write summary and arguments.

**Group B: Execution Flow Steps 1-5 (T004-T008)** - ~80 lines
Input validation, ancestor detection, extraction, mode detection, subagent launch.

**Group C: Parallel Subagent Definitions (T009-T015)** - ~150 lines
6 fixed subagents (U1, Y1, C1, C2, R1, S1) + dynamic U2-UN template (1 per upstream plan).

**Group D: Synthesis & Classification (T016-T019)** - ~60 lines
Synthesis framework, conflict taxonomy, anti-hallucination, log merge strategy.

**Group E: Merge Plan Document Template (T020-T027)** - ~120 lines
All sections of the output document (header, summary, diagrams, cards, tables).

**Group F: Validation & Approval (T028-T035)** - ~80 lines
Pre-merge validation, footnote reconciliation, human approval, post-merge checklist, rollback.

**Group G: Testing & Validation (T036-T041)** - Manual execution
Install command, run test scenarios, validate acceptance criteria.

---

### Acceptance Criteria

- [ ] **AC1** (Upstream Discovery): Command identifies ancestor, lists commits, groups by plan
- [ ] **AC2** (Per-Plan Analysis): Plan Summary Cards generated for each upstream plan
- [ ] **AC3** (Conflict Identification): Direct/Semantic/Regression conflicts categorized
- [ ] **AC4** (Merge Plan Document): Complete structure with diagrams, tables, recommendations
- [ ] **AC5** (Regression Risk): Risk table with test commands
- [ ] **AC6** (Merge Order): Step-by-step instructions with verification
- [ ] **AC7** (Human Approval): Mandatory gate before any execution
- [ ] **AC8** (Post-Merge Validation): Checklist for verification

---

## Cross-Cutting Concerns

### Security
- **No auto-execution**: Human approval mandatory for all git operations
- **No credentials**: Uses existing git authentication
- **Local only**: All context from local repository

### Observability
- Merge plan document is the primary observable output
- Execution log preservation maintains audit trail
- Validation gates produce checkable results

### Documentation
- **Location**: None needed
- **Rationale**: Command file is self-documenting (follows pattern of all plan-* commands)

---

## Progress Tracking

### Phase Completion Checklist
- [ ] Phase 1: Create plan-8-merge.md Command File - [Status]

### STOP Rule
**IMPORTANT**: After writing this plan:
1. Run `/plan-4-complete-the-plan` to validate readiness
2. Proceed to implementation (single phase, can use `/plan-6-implement-phase`)

---

## Change Footnotes Ledger

**NOTE**: This section will be populated during implementation by plan-6a-update-progress.

**Initial State**:
```markdown
[^1]: [To be added during implementation via plan-6a]
```

---

## Appendix: Deviation Ledger

| Principle | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|-----------|------------|------------------------------|-----------------|
| Single phase instead of multi-phase | This is one markdown file, not a complex system | 7 phases was over-engineering | Detailed task breakdown within single phase |
| No automated tests | Prompt file, not executable code | N/A - KISS | Comprehensive manual test scenarios |
| No documentation | Self-documenting command file | Separate README | Command contains all usage info |

---

## Appendix: Command File Outline

Target structure of `agents/commands/plan-8-merge.md`:

```
---
description: Analyze upstream changes from main and generate merge plan document
---

# plan-8-merge (alias: /8, /merge)

[Ultrathink instruction]

[Executive summary - 2-3 paragraphs]

---

```md
User input:

$ARGUMENTS
# --plan "<path>" (optional, auto-detect)
# --target "main" (default)

## Execution Flow

1) Input resolution and validation
2) Common ancestor detection (git merge-base)
3) Three-version extraction
4) Cross-mode detection gate
5) Launch parallel subagents

## Subagent Architecture

**Subagent U1: Upstream Plans Discovery**
[...]

**Subagent U2-UN: Plan Analysts** (one per upstream plan)
[...]

**Subagent Y1: Your Changes Analyst**
[...]

**Subagent C1: File Conflict Detector**
[...]

**Subagent C2: Semantic Conflict Detector**
[...]

**Subagent R1: Regression Risk Analyst**
[...]

**Subagent S1: Synthesis & Ordering**
[...]

## Synthesis Phase

After all subagents complete:
1. Collect findings
2. Deduplicate
3. Classify conflicts
4. Generate merge plan

### Conflict Classification
- Complementary | Contradictory | Orthogonal | Auto-Resolvable

### Anti-Hallucination Patterns
[Chain-of-verification, constraints, uncertainty]

### Execution Log Merge Strategy
[Append-only, timestamp interleave]

## Merge Plan Document Template

[Complete output format...]

## Validation Gates

### Pre-Merge
[Checklist...]

### Footnote Reconciliation
[Protocol...]

### Human Approval Gate
[Mandatory approval...]

### Post-Merge
[Checklist...]

## Next Steps

[Handoff...]
```
```

---

**Plan Complete**: 2026-01-01
**Total Tasks**: 41
**Estimated Command File Size**: ~400-600 lines
**Next Step**: Run `/plan-4-complete-the-plan` to validate readiness
