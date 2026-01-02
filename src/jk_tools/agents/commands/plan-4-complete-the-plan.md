---
description: Assess plan completeness before execution; offers an optional readiness gate.
---

Please deep think / ultrathink as this is a complex task. 

# plan-4-complete-the-plan

Verify the plan's **readiness**: TOC, TDD order, tests-as-docs, mock usage consistent with the spec, real data expectations, relative paths (for cross-machine portability), and acceptance criteria. This command stays read-only and provides a recommendation—teams may proceed once the plan is READY **or** after explicitly accepting any gaps.

```md
Inputs: PLAN_PATH, SPEC_PATH (co-located as `<plan-dir>/<slug>-spec.md>`), rules at `docs/project-rules/{rules.md, idioms.md, architecture.md}`, optional constitution.

**IMPORTANT**: This command uses **parallel subagent validation** for comprehensive plan readiness assessment.

**Strategy**: Launch 4 validators simultaneously (single message with 4 Task tool calls). Each validator focuses on specific plan quality dimension, then results synthesize into readiness verdict.

**Parallel Validation Architecture**:

**Subagent 1 - Structure Validator**:
"Validate plan structural completeness and self-containment.

**Read**: `${PLAN_PATH}` (entire plan document)

**Check**:
- TOC present with all major sections linked
- Relative paths used throughout for portability (no absolute paths like /Users/username/... or C:\Users\...)
- No assumed prior context (plan is self-contained)
- Proper heading hierarchy (# → ## → ###)
- All cross-references resolve correctly
- All code examples are inline (no external dependencies)

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH|MEDIUM|LOW\", \"section\": \"Phase X or § Y\", \"issue\": \"Description\", \"fix\": \"Specific remediation\"},
    ...
  ],
  \"structure_complete\": true/false
}
```
"

**Subagent 2 - Testing Validator**:
"Validate testing approach compliance with spec.

**Read**:
- `${PLAN_PATH}` (especially § 6 Testing Philosophy and phase task tables)
- `${SPEC_PATH}` (Testing Strategy section)

**Check**:
- TDD order evident (test tasks precede implementation tasks in each phase)
- Tests-as-docs quality (test examples show behavioral assertions, not generic truths)
- Mock policy matches spec preference (avoid/targeted/liberal)
- Test examples provided for each phase with task correlation
- Acceptance criteria have testable assertions (measurable, not vague)
- Real repo data/fixtures used when spec requires (not mocks)

**Report** (JSON format):
```json
{
  \"approach\": \"Full TDD|TAD|Lightweight|Manual|Hybrid\",
  \"mock_policy\": \"Avoid mocks|Targeted mocks|Liberal mocks\",
  \"violations\": [
    {\"severity\": \"HIGH|MEDIUM|LOW\", \"phase\": \"Phase X\", \"task\": \"X.Y\", \"issue\": \"Description\", \"fix\": \"Specific remediation\"},
    ...
  ],
  \"compliant\": true/false
}
```
"

**Subagent 3 - Completeness Validator**:
"Validate plan completeness for agent handover.

**Read**: `${PLAN_PATH}` (entire plan)

**Check**:
- Every phase has acceptance criteria section with measurable checks
- Every phase has numbered tasks with specific success criteria
- Dependencies clearly stated (no ambiguous references)
- Risks identified with severity + mitigation strategies
- Critical findings documented with numbered discoveries
- Commands to run specified (exact command lines for tests/linters/builds)
- Fidelity sufficient for agent handover (external agent could execute without missing context)

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH|MEDIUM|LOW\", \"phase\": \"Phase X or global\", \"issue\": \"Description\", \"fix\": \"Specific remediation\"},
    ...
  ],
  \"handover_ready\": true/false
}
```
"

**Subagent 4 - Doctrine Validator**:
"Validate alignment with rules, idioms, architecture, constitution.

**Read**:
- `${PLAN_PATH}` (entire plan)
- `docs/project-rules/rules.md`
- `docs/project-rules/idioms.md`
- `docs/project-rules/architecture.md`
- `docs/project-rules/constitution.md` (if exists)

**Check**:
- Plan respects rules.md (coding standards, testing requirements, tooling, CI)
- Follows docs/project-rules/idioms.md (directory conventions, naming patterns, file organization)
- Aligns with docs/project-rules/architecture.md (layer boundaries, allowed dependencies, integration contracts)
- Deviation ledger present if violating constitution principles (with justification + mitigation)
- BridgeContext patterns (if VS Code/TypeScript work): vscode.Uri, bounded searches, pytest module debug

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH|MEDIUM|LOW\", \"phase\": \"Phase X or global\", \"issue\": \"Description\", \"reference\": \"Section in rules/idioms/arch/const\", \"fix\": \"Specific remediation\"},
    ...
  ],
  \"doctrine_compliant\": true/false
}
```
"

**Subagent 5 - ADR Validator (Optional)**:
"Validate ADR awareness and alignment (if ADRs exist).

**Read**:
- `${PLAN_PATH}` (entire plan)
- `docs/adr/*.md` (only ADRs that reference this spec/plan)

**Check**:
- If ADRs exist: plan references ADR IDs in Critical Findings or Acceptance Criteria
- No direct contradiction between plan decisions and any **Accepted** ADR
- If contradictions exist: plan records deviation with mitigation or recommends superseding flow
- ADR Ledger table present in plan if relevant ADRs found

**Report** (JSON format):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH\", \"issue\": \"Plan omits ADR-0007 constraints\", \"fix\": \"Add ADR mapping in Acceptance Criteria\"},
    {\"severity\": \"MEDIUM\", \"issue\": \"Plan contradicts ADR-0003 without justification\", \"fix\": \"Document deviation or supersede ADR\"}
  ],
  \"adr_present\": true/false,
  \"adr_aligned\": true/false
}
```
"

**Wait for All Validators**: Block until all 5 subagents complete validation.

**Synthesize Results**:

After all validators complete:
1. Collect violations from each domain
2. Calculate overall readiness:
   - Structure Validator: PASS (0 HIGH) | ISSUES (N violations)
   - Testing Validator: PASS (0 HIGH) | ISSUES (N violations)
   - Completeness Validator: PASS (0 HIGH) | ISSUES (N violations)
   - Doctrine Validator: PASS (0 HIGH) | ISSUES (N violations)
   - ADR Validator: PASS (0 HIGH) | ISSUES (N violations) | N/A (no ADRs)
3. Determine overall verdict:
   - All validators PASS (0 HIGH violations) → **READY**
   - Any HIGH violations → **NOT READY** (with remediation list)
   - User can override: **NOT READY (USER OVERRIDE)** with risk acknowledgment

**Output**:
- Status = READY, NOT READY, or NOT READY (USER OVERRIDE)
- Violations table (if NOT READY):

| Severity | Validator | Issue | Fix |
|----------|-----------|-------|-----|
| HIGH | Structure | Absolute paths in Phase 2 | Use relative paths for cross-machine portability |
| HIGH | Testing | TDD order violated in Phase 2 | Reorder tasks (tests first) |
| MEDIUM | Completeness | Success criteria vague in Task 2.3 | Make measurable |
| ... | ... | ... | ... |

- Confidence assessment: Plan has **high/medium/low** fidelity for agent handover
- Concrete remediation steps (if NOT READY) - do NOT auto-apply
- Next step (when READY): Run **/plan-5-phase-tasks-and-brief** for the chosen phase
```

**Override guidance**: When the audit flags issues, present the findings and confirm whether the user wants to continue despite them. If they approve an override, note their acceptance, respect the documented risks, and proceed to `/plan-5-phase-tasks-and-brief`.

This supports your completion doctrine while letting you tailor the rigor to the project's stakes.

Next step (when happy): Run **/plan-5-phase-tasks-and-brief** once the plan is READY or the user has accepted the gaps.
