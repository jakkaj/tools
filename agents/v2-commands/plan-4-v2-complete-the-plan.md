---
description: Assess plan completeness before execution; domain-aware readiness gate. V2 standalone rewrite.
---

Please deep think / ultrathink as this is a complex task.

# plan-4-v2-complete-the-plan

Verify the plan's **readiness**: structure, testing alignment, domain completeness, domain map health, and acceptance criteria. Read-only — provides a recommendation. Teams may proceed once READY or after explicitly accepting gaps.

```md
Inputs: PLAN_PATH, SPEC_PATH (co-located as `<plan-dir>/<slug>-spec.md>`), rules at `docs/project-rules/{rules.md, idioms.md, architecture.md}` (if present), optional constitution.

**Strategy**: Launch 5 validators in parallel (single message with 5 Task tool calls; Subagent 5/ADR is conditional on docs/adr/ existing). Each focuses on a plan quality dimension, then results synthesize into readiness verdict.

**Subagent 1 - Structure Validator**:
"Validate plan structural completeness.

**Read**: `${PLAN_PATH}` (entire plan)

**Check**:
- Summary section present and concise
- Target Domains section present with domain/status/relationship table
- Domain Manifest present (file → domain mapping)
- Key Findings table present
- Phase task tables present with success criteria
- Acceptance criteria present and testable
- Proper heading hierarchy
- All cross-references resolve

**Report** (JSON):
```json
{
  \"violations\": [{\"severity\": \"HIGH|MEDIUM|LOW\", \"section\": \"...\", \"issue\": \"...\", \"fix\": \"...\"}],
  \"structure_complete\": true/false
}
```
"

**Subagent 2 - Testing Alignment Validator**:
"Validate testing approach aligns with spec — without requiring inline test examples or testing philosophy sections.

**Read**:
- `${PLAN_PATH}` (phase task tables)
- `${SPEC_PATH}` (Testing Strategy section)

**Check**:
- Spec's testing approach (TDD/Lightweight/Manual/Hybrid) is reflected in task ordering
- If TDD: test tasks appear before implementation tasks in phases
- If Lightweight: at least basic validation tasks exist
- If Manual: verification steps are described
- Acceptance criteria have measurable assertions (not vague)
- Mock usage intent matches spec preference (if specified)

**Note**: V2 plans intentionally omit inline test examples, testing philosophy sections, and commands-to-run. Do NOT flag these as missing — they are delegated to implementor agency.

**Report** (JSON):
```json
{
  \"approach\": \"Full TDD|Lightweight|Manual|Hybrid\",
  \"violations\": [{\"severity\": \"HIGH|MEDIUM|LOW\", \"phase\": \"...\", \"issue\": \"...\", \"fix\": \"...\"}],
  \"compliant\": true/false
}
```
"

**Subagent 3 - Domain Completeness Validator**:
"Validate domain system artifacts are complete and consistent.

**Read**:
- `${PLAN_PATH}` (Target Domains, Domain Manifest)
- `${SPEC_PATH}` (Target Domains)
- `docs/domains/registry.md` (if exists)
- `docs/domains/domain-map.md` (if exists)
- `docs/domains/<slug>/domain.md` for each target domain (if exists)

**Check**:
- Every domain in spec's Target Domains is addressed in the plan
- NEW domains have domain setup tasks in the plan
- Existing domains referenced in the plan actually exist in registry (if registry exists)
- Domain Manifest covers all files in phase task tables
- Domain Manifest classifications are consistent (contract/internal/cross-domain)
- If domain map exists: plan's new domains and relationships are consistent with map topology
- No circular business-domain dependencies introduced
- Consumed domains (relationship: consume) have contracts identified
- NEW domains with contracts have `§ Concepts` section planned (concepts should be identified during extraction or implementation)

**Report** (JSON):
```json
{
  \"domains_addressed\": [\"auth\", \"notifications\"],
  \"new_domains\": [\"notifications\"],
  \"violations\": [{\"severity\": \"HIGH|MEDIUM|LOW\", \"domain\": \"...\", \"issue\": \"...\", \"fix\": \"...\"}],
  \"domain_complete\": true/false
}
```
"

**Subagent 4 - Doctrine Validator**:
"Validate alignment with project rules, idioms, architecture, constitution.

**Read**:
- `${PLAN_PATH}` (entire plan)
- `docs/project-rules/rules.md` (if exists)
- `docs/project-rules/idioms.md` (if exists)
- `docs/project-rules/architecture.md` (if exists)
- `docs/project-rules/constitution.md` (if exists)

**Check**:
- Plan respects coding standards and testing requirements from rules.md
- Follows directory conventions and naming patterns from idioms.md
- Aligns with layer boundaries and dependency rules from architecture.md
- Deviation ledger present if violating constitution principles
- If no project-rules exist: report N/A (not a failure)

**Report** (JSON):
```json
{
  \"violations\": [{\"severity\": \"HIGH|MEDIUM|LOW\", \"issue\": \"...\", \"reference\": \"...\", \"fix\": \"...\"}],
  \"doctrine_compliant\": true/false
}
```
"

**Subagent 5 - ADR Validator (Optional — only if docs/adr/ exists)**:
"Validate ADR awareness and alignment.

**Read**:
- `${PLAN_PATH}`
- `docs/adr/*.md` (only ADRs that reference this spec/plan)

**Check**:
- If ADRs exist: plan doesn't contradict Accepted ADRs
- If contradictions exist: deviation documented with mitigation
- ADR constraints reflected in relevant phase tasks

**Report** (JSON):
```json
{
  \"violations\": [{\"severity\": \"HIGH\", \"issue\": \"...\", \"fix\": \"...\"}],
  \"adr_present\": true/false,
  \"adr_aligned\": true/false
}
```
"

**Wait for All Validators**: Block until all subagents complete.

**Synthesize Results**:

1. Collect violations from each validator
2. Calculate overall readiness:
   - Structure: PASS | ISSUES
   - Testing Alignment: PASS | ISSUES
   - Domain Completeness: PASS | ISSUES
   - Doctrine: PASS | ISSUES | N/A
   - ADR: PASS | ISSUES | N/A
3. Determine verdict:
   - All PASS (0 HIGH) → **READY**
   - Any HIGH → **NOT READY** (with remediation list)
   - User can override: **NOT READY (USER OVERRIDE)**

**Output**:

| Validator | Status | HIGH | MEDIUM | LOW |
|-----------|--------|------|--------|-----|
| Structure | PASS/ISSUES | N | N | N |
| Testing Alignment | PASS/ISSUES | N | N | N |
| Domain Completeness | PASS/ISSUES | N | N | N |
| Doctrine | PASS/ISSUES/N/A | N | N | N |
| ADR | PASS/ISSUES/N/A | N | N | N |

Violations table (if any):

| Severity | Validator | Issue | Fix |
|----------|-----------|-------|-----|

- Verdict: **READY** / **NOT READY**
- Remediation steps (if NOT READY)
- Next step (when READY): Run **/plan-5-v2-phase-tasks-and-brief**
```

**Override guidance**: If issues flagged, present findings and ask whether to continue. If user accepts, note the override and proceed to `/plan-5-v2-phase-tasks-and-brief`.

Next step (when happy): Run **/plan-5-v2-phase-tasks-and-brief** once READY or user has accepted gaps.
