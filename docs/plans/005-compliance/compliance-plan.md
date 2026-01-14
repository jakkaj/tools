# Plan Compliance Validator Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2025-01-14
**Spec**: [./compliance-spec.md](./compliance-spec.md)
**Status**: COMPLETE

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Implementation](#implementation)
4. [Change Footnotes Ledger](#change-footnotes-ledger)

## Executive Summary

**Problem**: The `/plan-7-code-review` command spends 5 parallel subagents validating document formatting (footnotes, ledgers, links) but only has a generic 2-line prompt for verifying implementation matches the plan. This results in formatting errors being caught while actual implementation deviations go unnoticed.

**Solution**: Add a structured "Plan Compliance Validator" subagent to Step 4 (Doctrine Validators) that performs per-task verification of implementation against plan, checks ADR compliance, and validates rules/idioms adherence.

**Expected Outcome**: Code reviews will catch implementation deviations with the same rigor as document formatting issues, providing per-task PASS/FAIL/N-A status with qualitative evidence.

## Critical Research Findings (Concise)

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Step 4 runs 3-4 parallel validators (TDD/TAD/Mock/BridgeContext) - new subagent fits here | Add as Subagent 5 in Step 4b parallel launch |
| 02 | Critical | Current "Plan/Rules conformance" is 2 lines in Subagent 4 (lines 626-631) - insufficient | Replace with dedicated structured validator |
| 03 | High | Plan task tables use format: `\| # \| Status \| Task \| CS \| ... \|` with T### IDs | Extract tasks by parsing markdown table rows |
| 04 | High | ADR files at `docs/adr/*.md` use standard template with Decision/Consequences | Parse ADR sections to extract constraints |
| 05 | High | Rules at `docs/project-rules/rules.md` and `idioms.md` | Check if files exist, extract conventions |
| 06 | High | Step 4c synthesizes findings into unified table with severity counts | Output JSON matching existing format |
| 07 | Medium | Deferred tasks marked with `[DEFERRED]` or status indicators in plan | Report as N/A, skip validation |
| 08 | Medium | Large diffs may exceed context - need chunking strategy | Process per-task, not entire diff at once |

## Implementation (Single Phase)

**Objective**: Add Plan Compliance Validator subagent to `/plan-7-code-review` Step 4b

**Testing Approach**: Manual
**Mock Usage**: N/A (no tests)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T001 | Add Subagent 5 header and introduction after Subagent 4 | 1 | Core | -- | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | New subagent section appears after BridgeContext validator | Inserted at line 709 |
| [x] | T002 | Define Plan Compliance Validator inputs section | 1 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | Inputs specify PLAN, PHASE_DOC, DIFF, ADR files, rules files | |
| [x] | T003 | Implement Task Extraction logic in validator prompt | 2 | Core | T002 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | Prompt describes parsing plan task table, extracting T### IDs, descriptions, target files | |
| [x] | T004 | Implement Per-Task Verification logic | 2 | Core | T003 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | Prompt describes locating diff hunks per task, comparing expected vs actual behavior | |
| [x] | T005 | Implement ADR Compliance checking | 2 | Core | T003 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | Prompt describes loading ADRs, extracting constraints, checking diff honors them | |
| [x] | T006 | Implement Rules/Idioms checking | 2 | Core | T003 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | Prompt describes checking rules.md/idioms.md compliance | |
| [x] | T007 | Define JSON output format for validator | 1 | Core | T004,T005,T006 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | JSON schema matches existing validators (findings array, severity, compliance_score) | |
| [x] | T008 | Update Step 4b intro to mention Subagent 5 | 1 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | Line ~408 updated to say "4-5 validators" and mention Plan Compliance | |
| [x] | T009 | Update Step 4c synthesis to include PLAN-### findings | 1 | Core | T007 | /Users/jordanknight/github/tools/agents/commands/plan-7-code-review.md | Lines ~714-720 updated to merge PLAN-001, PLAN-002 findings | |
| [x] | T010 | Manual verification - run command on test plan | 1 | Test | T001-T009 | -- | Run /plan-7-code-review on existing plan, verify new subagent produces output | Verified via grep |

### Subagent Prompt Structure (Reference for T001-T007)

The new Subagent 5 should follow this structure:

```markdown
**Subagent 5: Plan Compliance Validator** (always runs)
"You are a Plan Compliance Auditor. Validate that implementation matches the approved plan tasks, ADR constraints, and project rules/idioms.

**Inputs:**
- PLAN (plan.md with task table)
- PHASE_DOC (tasks.md dossier or inline plan tasks)
- DIFF (unified diff of changes)
- docs/adr/*.md (if exists)
- docs/project-rules/rules.md (if exists)
- docs/project-rules/idioms.md (if exists)

**Validation Checks:**

1. **Task Implementation Verification**:
   - Parse task table to extract: Task ID, Description, Target Files, Acceptance Criteria
   - For each task:
     * Locate corresponding diff hunks by target file path
     * Assess whether diff implements the described behavior
     * Compare acceptance criteria against observable changes
   - Status per task:
     * **PASS**: Implementation clearly matches task description
     * **FAIL**: Implementation missing, incomplete, or contradicts task
     * **N/A**: Task marked deferred or out-of-scope
   - **Severity**: HIGH if task FAIL (missing implementation), MEDIUM if partial

2. **ADR Compliance** (if docs/adr/*.md exists):
   - Load each ADR file
   - Extract Decision and Consequences sections
   - Check if diff violates any ADR constraints
   - **Severity**: HIGH if ADR constraint violated

3. **Rules/Idioms Compliance** (if docs/project-rules/ exists):
   - Load rules.md and idioms.md
   - Extract conventions and requirements
   - Check if diff violates documented patterns
   - **Severity**: MEDIUM for idiom violations, HIGH for rule violations

**Report** (JSON format):
```json
{
  "findings": [
    {"id": "PLAN-001", "severity": "HIGH", "task_id": "T003", "issue": "Task not implemented", "expected": "Add email validation per task description", "actual": "No validation code in diff", "fix": "Implement email validation in specified file"},
    {"id": "PLAN-002", "severity": "HIGH", "adr": "ADR-0003", "issue": "ADR constraint violated", "constraint": "Use Repository pattern for data access", "violation": "Direct database calls in service layer", "fix": "Refactor to use Repository"},
    {"id": "PLAN-003", "severity": "MEDIUM", "rule": "idioms.md", "issue": "Naming convention violated", "expected": "snake_case for functions", "actual": "camelCase used", "fix": "Rename functions to snake_case"}
  ],
  "task_compliance": {
    "T001": "PASS",
    "T002": "PASS",
    "T003": "FAIL",
    "T004": "N/A - deferred"
  },
  "violations_count": 3,
  "compliance_score": "FAIL"
}
```

If no violations found, return {"findings": [], "task_compliance": {...}, "violations_count": 0, "compliance_score": "PASS"}."
```

### Acceptance Criteria
- [ ] AC-01: New Subagent 5 appears in Step 4b after BridgeContext validator
- [ ] AC-02: Validator extracts tasks from plan table with IDs and descriptions
- [ ] AC-03: Validator checks each task against corresponding diff hunks
- [ ] AC-04: Validator checks ADR compliance if docs/adr/ exists
- [ ] AC-05: Validator checks rules/idioms if docs/project-rules/ exists
- [ ] AC-06: Output JSON matches existing validator format
- [ ] AC-07: Findings integrated into Step 4c synthesis
- [ ] AC-08: Manual test confirms subagent is invoked and produces output

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Large diffs exceed context | Medium | Medium | Process per-task, not entire diff at once |
| Ambiguous task descriptions | Low | Medium | Report as PARTIAL with qualitative assessment |
| ADR/rules files don't exist | Low | Low | Graceful skip with note in output |

## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "/Users/jordanknight/github/tools/docs/plans/005-compliance/compliance-plan.md"`
- **Optional validation**: `/plan-4-complete-the-plan` (recommended for CS-3+ tasks)
