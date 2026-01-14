# Plan Compliance Validator for plan-7-code-review

**Mode**: Simple

## Summary

**WHAT**: Add a structured Plan Compliance Validator subagent to the `/plan-7-code-review` command that performs line-by-line verification that implementation code matches the approved plan tasks, ADR decisions, and project idioms.

**WHY**: The current plan-7-code-review command has inverted validation priorities. It spends 5 parallel subagents validating document formatting (footnotes, ledgers, links) but only has a generic 2-line prompt for verifying implementation matches the plan. This results in many formatting errors being caught while actual implementation deviations go unnoticed.

## Goals

- **Structured task-to-code verification**: For each task in the plan table, verify the diff implements the expected behavior (not just "something exists")
- **ADR compliance checking**: Verify implementation honors architectural decisions from `docs/adr/*.md`
- **Rules/idioms validation**: Check code changes adhere to `docs/project-rules/rules.md` and `idioms.md`
- **Per-task PASS/FAIL reporting**: Provide specific evidence for each task's compliance status
- **Actionable deviation findings**: When implementation diverges from plan, provide clear descriptions of expected vs actual behavior

## Non-Goals

- Replacing existing document validation (footnotes, ledgers, links) - those are valuable
- Adding new document formats or process changes
- Changing the overall plan-7-code-review workflow
- Real-time or continuous compliance monitoring
- Automated code fixes (review is read-only)

## Complexity

**Score**: CS-2 (small)

**Breakdown**: S=1, I=0, D=0, N=1, F=0, T=0

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Surface Area (S) | 1 | Single file modified: `agents/commands/plan-7-code-review.md` |
| Integration (I) | 0 | Internal only - no external service dependencies |
| Data/State (D) | 0 | No schema changes, reads existing plan artifacts |
| Novelty (N) | 1 | Clear requirements but needs structured extraction logic |
| Non-Functional (F) | 0 | Standard LLM subagent performance |
| Testing/Rollout (T) | 0 | Manual testing of command output |

**Total**: 3 = CS-2 (small)

**Confidence**: 0.85

**Assumptions**:
- Plan task tables have consistent format across plans
- ADR files follow standard markdown structure
- Rules/idioms files exist in predictable locations

**Dependencies**:
- Existing plan-7-code-review command structure
- Plan task table format (from plan-5)
- ADR format (from plan-3a-adr)

**Risks**:
- Large diffs may exceed context limits for task-by-task analysis
- Ambiguous task descriptions may make compliance hard to assess

**Phases**: Single phase (add new subagent to existing command)

## Acceptance Criteria

1. **AC-01**: When plan-7-code-review runs, a new "Plan Compliance Validator" subagent is launched alongside existing validators
2. **AC-02**: The validator extracts each task from the plan table (T001, T002, etc.) with its description, target files, and acceptance criteria
3. **AC-03**: For each task, the validator locates corresponding diff hunks and verifies the implementation matches the task description
4. **AC-04**: If `docs/adr/*.md` files exist, the validator extracts architectural constraints and checks the diff honors them
5. **AC-05**: If `docs/project-rules/rules.md` or `idioms.md` exist, the validator checks code changes follow documented conventions
6. **AC-06**: The validator outputs structured JSON with per-task compliance status (PASS/FAIL/PARTIAL)
7. **AC-07**: Findings are integrated into Section E.1 (Doctrine & Testing Compliance) of the review report
8. **AC-08**: Non-compliant tasks are flagged with severity (HIGH for missing implementation, MEDIUM for partial, LOW for style deviations)

## Risks & Assumptions

**Risks**:
- **Context limits**: Very large diffs may require chunking or summarization
- **Ambiguous tasks**: Tasks without clear acceptance criteria are hard to validate
- **False positives**: Over-eager matching may flag correct implementations as non-compliant

**Assumptions**:
- Plans created by plan-5-phase-tasks-and-brief have consistent task table format
- Task descriptions are specific enough to verify against code
- ADR files use standard ADR template with Decision/Consequences sections

## Open Questions

1. Should the validator run in parallel with existing subagents (Step 3a/4) or as a new step?
2. How should partial compliance be scored (task 80% complete)?
3. Should ADR violations block the review (CRITICAL) or just warn (HIGH)?
4. How to handle tasks that are intentionally deferred or out-of-scope for this phase?

## ADR Seeds (Optional)

**Decision Drivers**:
- Balance thoroughness with context window limits
- Maintain read-only constraint (no code changes)
- Integrate cleanly with existing parallel subagent pattern

**Candidate Alternatives**:
- A: Single comprehensive validator (all checks in one subagent)
- B: Split into 3 validators (Task, ADR, Rules) running in parallel
- C: Sequential validation with early-exit on critical failures

**Stakeholders**: Users of plan-7-code-review command

## Testing Strategy

**Approach**: Manual
**Rationale**: This is a prompt-only markdown change to an existing command file. No code execution, no runtime behavior to test programmatically.
**Focus Areas**: Manual verification that the new subagent prompt is invoked and produces expected output format
**Excluded**: All automated testing - changes are prompt text only
**Mock Usage**: N/A (no tests)

## Documentation Strategy

**Location**: None
**Rationale**: This is an internal enhancement to an existing command. The command's existing documentation covers usage; no new user-facing documentation required.
**Target Audience**: N/A
**Maintenance**: N/A

## Clarifications

### Session 2025-01-14

**Q1: Workflow Mode** - Already set to Simple (CS-2 task, single file change)

**Q2: Testing Approach**
- Answer: D (Manual Only)
- Rationale: "No tests, just prompt markdown changes" - user explicitly requested no automated testing

**Q3: Documentation Strategy**
- Answer: D (No new documentation)
- Rationale: "Nothing else needed" - internal command enhancement, no user-facing docs required

**Q4: Validator Placement in Workflow**
- Answer: B (Parallel with Step 4 - Doctrine Validators)
- Rationale: Natural fit with TDD/TAD/Mock validators; similar validation purpose

**Q5: Partial Compliance Reporting**
- Answer: D (Qualitative assessment)
- Rationale: No numeric scores - descriptive assessment of what's present vs missing

**Q6: ADR Violation Severity**
- Answer: B (HIGH severity)
- Rationale: Strong warning that triggers REQUEST_CHANGES but doesn't block the review entirely

**Q7: Deferred Task Handling**
- Answer: B (Report as N/A)
- Rationale: Explicitly listed in report as "Not validated - deferred per plan" for transparency

## Open Questions

All resolved - see Clarifications section above.
