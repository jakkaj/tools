# Code Review: Simple Mode

**Plan**: `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-plan.md`  
**Spec**: `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-spec.md`  
**Phase**: Simple Mode  
**Date**: 2026-05-30  
**Reviewer**: Automated (plan-7-v2)  
**Testing Approach**: Hybrid

## A) Verdict

**APPROVE**

## B) Summary

The implementation matches the approved Simple-mode plan: runtime harness skill docs now capture signal-readiness, inference-gap, and proof/back-pressure opportunities while preserving advisory, non-gating behavior. The schema-safe fixture validates through the existing retro schema without enum expansion. Domain compliance is clean against the informal plan domains, with setup/provisioning still owned by harness-engineering. No implementation, reinvention, testing, doctrine, or harness-live blockers were found.

## C) Checklist

**Testing Approach: Hybrid**

- [x] Lightweight validation checks present
- [x] Targeted schema fixture validation present
- [x] Real skill files and schema artifacts used; no mocks
- [x] Only in-scope files changed
- [x] Linters/type checks clean
- [x] Domain compliance checks pass

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| - | - | - | - | No findings. | - |

## E) Detailed Findings

### E.1) Implementation Quality

No findings. The implementation quality reviewer returned `[]`.

### E.2) Domain Compliance

No findings. The domain compliance validator returned `[]`.

| Check | Status | Details |
|-------|--------|---------|
| File placement | ✅ | Changed files map to the plan's informal Domain Manifest. |
| Contract-only imports | ✅ | No code imports were introduced; the new retro fixture respects the schema contract. |
| Dependency direction | ✅ | Docs preserve tools runtime ownership and external harness-engineering setup ownership. |
| Domain.md updated | ✅ N/A | The plan explicitly does not create formal `docs/domains/` artifacts. |
| Registry current | ✅ N/A | No formal domain registry exists or was required. |
| No orphan files | ✅ | Plan artifacts, runtime skills, schema docs/fixture, and top-level docs are covered by the plan. |
| Map nodes current | ✅ N/A | No formal domain map exists or was required. |
| Map edges current | ✅ N/A | No formal domain map exists or was required. |
| No circular business deps | ✅ N/A | No business-domain dependency graph was introduced. |
| Concepts documented | ✅ N/A | No formal domain contracts were introduced. |

### E.3) Anti-Reinvention

No findings. The anti-reinvention checker returned `[]`.

| New Component | Existing Match? | Domain | Status |
|--------------|-----------------|--------|--------|
| `signal-backpressure.retro.md` fixture | Existing fixture pattern only | compound-contract | Proceed |

### E.4) Testing & Evidence

**Coverage confidence**: 91%

| AC | Confidence | Evidence |
|----|------------|----------|
| AC1 | 90% | `harness-1-boot` now includes signal-readiness wording at `/Users/jordanknight/github/tools/skills/harness/harness-1-boot/SKILL.md:15` and reporting details around `/Users/jordanknight/github/tools/skills/harness/harness-1-boot/SKILL.md:102`. |
| AC2 | 92% | Boot preserves `UNAVAILABLE` and no-setup behavior in `/Users/jordanknight/github/tools/skills/harness/harness-1-boot/SKILL.md:163` and the execution log lines 23-30. |
| AC3 | 88% | `harness-2-observe` includes inference-gap triggers and schema-safe examples around `/Users/jordanknight/github/tools/skills/harness/harness-2-observe/SKILL.md:86`. |
| AC4 | 87% | The new fixture `/Users/jordanknight/github/tools/skills/compound/schemas/fixtures/signal-backpressure.retro.md` validates against the existing schema; validation output is recorded in execution log lines 59-62. |
| AC5 | 89% | `harness-3-retro --drain` now calls out ease and proof/back-pressure improvements; execution log lines 39-45 record the change. |
| AC6 | 86% | `harness-3-retro --harvest` includes advisory back-pressure leverage guidance at `/Users/jordanknight/github/tools/skills/harness/harness-3-retro/SKILL.md:327` and explicitly avoids gates/indexes at line 332. |
| AC7 | 94% | Runtime/setup ownership is documented in `/Users/jordanknight/github/tools/README.md:76` and `/Users/jordanknight/github/tools/INSTALL.md:103`. |
| AC8 | 93% | Retro schema JSON parsing and fixture frontmatter validation passed for all non-malformed fixtures. |
| AC9 | 90% | Grep checks confirmed `plan-2d-backpressure-survey` and `the-flow` still contain advisory/non-blocking wording. |
| AC10 | 92% | Execution log lines 55-68 record JSON parsing, frontmatter validation, drift checks, legacy slug checks, orphan reporting, and doctor reporting. |

### E.5) Doctrine Compliance

No findings. No `docs/project-rules/{rules,idioms,architecture,constitution}.md` files exist in this repo, so formal doctrine checks are N/A. The required compound spot-check passed for sampled SDD skills: `plan-6-v2-implement-phase`, `plan-7-v2-code-review`, and `plan-6-v2-implement-phase-companion` all include `docs/compound/.disabled` and `_buffers` coverage.

### E.6) Harness Live Validation

N/A — no `docs/project-rules/engineering-harness.md`, `docs/project-rules/agent-harness.md`, or `docs/project-rules/harness.md` exists in tools. Live validation was skipped by design; static/schema/drift evidence was used instead.

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC1 | Boot describes/reports signal/back-pressure readiness dimensions. | `harness-1-boot/SKILL.md:15`, `harness-1-boot/SKILL.md:102`, execution log. | 90% |
| AC2 | Boot treats missing governance docs as `UNAVAILABLE` and does not scaffold setup artifacts. | `harness-1-boot/SKILL.md:163`, execution log. | 92% |
| AC3 | Observe includes inference-gap and missing deterministic signal triggers. | `harness-2-observe/SKILL.md:86`, execution log. | 88% |
| AC4 | Observe maps gaps into schema-valid retro entries. | `signal-backpressure.retro.md`; frontmatter validation command output. | 87% |
| AC5 | Retro drain prompts for ease and proof/back-pressure improvements. | `harness-3-retro/SKILL.md`, execution log. | 89% |
| AC6 | Retro harvest distinguishes back-pressure improvements without persisted indexes. | `harness-3-retro/SKILL.md:327-332`. | 86% |
| AC7 | Tools docs state runtime/setup ownership split. | `README.md:76`, `INSTALL.md:103`, `skills/compound/README.md`. | 94% |
| AC8 | Sample retro entries validate against existing schema without new kinds. | Frontmatter validation passed for `fixtures/signal-backpressure.retro.md`. | 93% |
| AC9 | Advisory language remains non-blocking and threshold-free. | Grep checks against `plan-2d-backpressure-survey` and `the-flow`. | 90% |
| AC10 | Validation includes schema, drift, and orphan reporting. | Execution log lines 55-68 and review command outputs. | 92% |

**Overall coverage confidence**: 91%

## G) Commands Executed

```bash
git --no-pager status --short
git --no-pager diff --stat
git --no-pager diff --name-only
git ls-files --others --exclude-standard
git --no-pager diff --check
python3 -m json.tool skills/compound/schemas/retro.schema.json
cd skills/compound/schemas && python3 - <<'PY'
import json
from pathlib import Path
import jsonschema
import yaml
schema = json.loads(Path('retro.schema.json').read_text())
for path in sorted(Path('fixtures').glob('*.retro.md')):
    if path.name == 'malformed.retro.md':
        continue
    content = path.read_text()
    if not content.startswith('---\n'):
        raise SystemExit(f'{path}: missing YAML frontmatter')
    frontmatter = content.split('---', 2)[1]
    jsonschema.validate(yaml.safe_load(frontmatter), schema)
    print(f'OK {path}')
PY
rg -n 'Signal readiness|runtime loop only|Back-pressure leverage|schema-safe|Ownership split' README.md INSTALL.md skills/harness/harness-1-boot/SKILL.md skills/harness/harness-2-observe/SKILL.md skills/harness/harness-3-retro/SKILL.md skills/compound/README.md skills/compound/schemas/README.md
find skills -mindepth 2 -maxdepth 2 -type d \( -name 'boot-harness' -o -name 'compound-0-setup' -o -name 'compound-1-track' -o -name 'compound-2-bubble' -o -name 'compound-3-harvest' \)
rg -n 'never blocks|Never gate|Advisory|advisory|no scores|no numeric thresholds|no thresholds' skills/SDD/plan-2d-backpressure-survey/SKILL.md skills/SDD/the-flow/SKILL.md
just skills-orphans
just doctor-skills
just lint
rg -q 'docs/compound/\.disabled' skills/SDD/plan-6-v2-implement-phase/SKILL.md skills/SDD/plan-7-v2-code-review/SKILL.md skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md
rg -q '_buffers' skills/SDD/plan-6-v2-implement-phase/SKILL.md skills/SDD/plan-7-v2-code-review/SKILL.md skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md
```

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review —
> only context on the work that was done before the review.

**Review result**: APPROVE

**Plan**: `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-plan.md`  
**Spec**: `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-spec.md`  
**Phase**: Simple Mode  
**Tasks dossier**: Inline in plan  
**Execution log**: `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/execution.log.md`  
**Review file**: `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/reviews/review.md`

### Files Reviewed

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|
| `/Users/jordanknight/github/tools/README.md` | Approved | dev-tooling | None |
| `/Users/jordanknight/github/tools/INSTALL.md` | Approved | dev-tooling | None |
| `/Users/jordanknight/github/tools/skills/compound/README.md` | Approved | compound-contract | None |
| `/Users/jordanknight/github/tools/skills/compound/schemas/README.md` | Approved | compound-contract | None |
| `/Users/jordanknight/github/tools/skills/compound/schemas/fixtures/signal-backpressure.retro.md` | Approved | compound-contract | None |
| `/Users/jordanknight/github/tools/skills/harness/harness-1-boot/SKILL.md` | Approved | harness-runtime | None |
| `/Users/jordanknight/github/tools/skills/harness/harness-2-observe/SKILL.md` | Approved | harness-runtime | None |
| `/Users/jordanknight/github/tools/skills/harness/harness-3-retro/SKILL.md` | Approved | harness-runtime | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/original-ask.md` | Approved | plan artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/research-dossier.md` | Approved | plan artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-spec.md` | Approved | plan artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-plan.md` | Approved | plan artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements.fltplan.md` | Approved | plan artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/execution.log.md` | Approved | plan artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/the-flow.json` | Approved | flow artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/the-flow.md` | Approved | flow artifact | None |
| `/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/.the-flow-state.json` | Approved | flow artifact | None |

### Required Fixes

None.

### Domain Artifacts to Update

None. Formal `docs/domains/` artifacts do not exist in tools and were explicitly out of scope.

### Next Step

Implementation reviewed and approved. Next command:

```text
/plan-8-v2-merge --plan "/Users/jordanknight/github/tools/docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-plan.md"
```
