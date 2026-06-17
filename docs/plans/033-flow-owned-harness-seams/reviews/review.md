# Code Review: Simple Mode

**Plan**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md  
**Spec**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md  
**Phase**: Simple Mode  
**Date**: 2026-06-17  
**Reviewer**: Automated (the review verb)  
**Testing Approach**: Manual (lint-gated)

## A) Verdict

**APPROVE**

No HIGH or CRITICAL findings remain after the review-fix loop.

**Key failure areas**:
- **Doctrine**: Low-severity wording drift remains in the `--event` alias/fallback prose; the operational runtime-dependency rule is otherwise clear.

## B) Summary

The re-review finds the prior blocking backpressure fold-in issue resolved: flow-level surfaces now treat `backpressure-coverage.md` as advisory output that informs a re-plan rather than an artifact auto-read by the harness-blind `plan` verb. The installed-but-unprovisioned node-emission rule is now consistent across the seam contract, routing render rule, schema, and guide: per-phase harness nodes require an installed and provisioned router. Sub-skills are harness-blind, the new `harness-seams.md` centralizes seam orchestration, and static evidence checks are clean. One LOW documentation consistency note remains around "fallback" wording for `--event`; it is non-blocking because the same authoritative block states old routers are a runtime-dependency gap, not an automatic fallback path.

## C) Checklist

**Testing Approach: Manual**

- [x] Manual verification steps documented
- [x] Manual test results recorded with observed outcomes
- [x] Evidence artifacts present

Universal:
- [x] Only in-scope files changed
- [x] Linters/type checks clean (if applicable)
- [x] Domain compliance checks pass

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| F001 | LOW | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md:113-134; /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md:254,337 | doctrine / error-handling | The `--event` alias row still uses "fallback" wording while the runtime note says older routers are not an automatic fallback path. | Reword the alias row and plan maintenance note so `--event` is for back-compat understanding/reading older envelopes only; keep reinstall/runtime-dependency as the single old-router rule. |

## E) Detailed Findings

### E.1) Implementation Quality

No HIGH, MEDIUM, correctness, security, performance, scope, or pattern findings remain. Prior findings F001-F005 from review #1 were checked against the current diff and execution log; the only residual item is LOW wording drift captured as F001 in this review.

### E.2) Domain Compliance

No domain-compliance findings.

| Check | Status | Details |
|-------|--------|---------|
| File placement | PASS | Changed files match the plan Domain Manifest: `the-flow` skill files under `skills/SDD/the-flow/`, repo docs under `CLAUDE.md` and `docs/how/`, and plan artifacts under `docs/plans/033-flow-owned-harness-seams/`. |
| Contract-only imports | N/A | Markdown/JSON skill-contract changes; no code imports introduced. |
| Dependency direction | PASS | The harness remains external and is referenced only through `/eng-harness-flow`; no child-skill dependency was introduced. |
| Domain.md updated | N/A | This repository has no `docs/domains/**` domain registry. |
| Registry current | N/A | This repository has no `docs/domains/registry.md`. |
| No orphan files | PASS | Every changed implementation/doc file maps to the plan Domain Manifest; review artifacts are review-stage outputs. |
| Map nodes current | N/A | This repository has no `docs/domains/domain-map.md`. |
| Map edges current | N/A | This repository has no `docs/domains/domain-map.md`. |
| No circular business deps | N/A | No domain dependency graph exists for this repository. |
| Concepts documented | N/A | No domain concept tables exist in this repository. |

### E.3) Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md | None as a single source; it intentionally centralizes seam orchestration formerly dispersed across routing/sub-skills/docs. | the-flow | proceed |
| /Users/jordanknight/github/tools/docs/how/the-flow-harness-seams.md | Related material exists in the plan appendix and `CLAUDE.md`, but this guide is an intended rendered/external-reader view. | repo docs | proceed |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/* | Existing SDD plan-folder convention. | repo docs | proceed |

### E.4) Testing & Evidence

**Coverage confidence**: 95%

| AC | Confidence | Evidence |
|----|------------|----------|
| AC-01 | 97% | T001 records `harness-seams.md` with seam map, two-layer detection, node-emission rule, honored-not-forced posture, retro lifecycle, and silent paths. |
| AC-02 | 96% | T004 records all 8 stage files audited; review re-check found both sub-skill seam invocation grep and harness-loop concept grep empty. |
| AC-03 | 95% | T003 records `00-routing.md` pointer, Graph seam decorations, literal `--hook --json` print-then-offer beats, and render-rule rewiring. |
| AC-04 | 92% | T001/T003 plus the fix loop record the operative rule: per-phase nodes only when router is installed and provisioned; current surfaces align. |
| AC-05 | 96% | T001/T005 record one retro node per phase, `branch_of` phase, and "drain owed" re-derived from node state with no new state file. |
| AC-06 | 97% | T001/T003/T006 record print-then-offer seams that users may accept or wave past; no auto-fire, gate, score, or block. |
| AC-07 | 99% | Static checks are clean: `just check-flow` L1-L6, slug collision check, and JSON parsing. |
| AC-08 | 94% | T002/T007 record v1 seam-contract mirror, upstream source-of-truth, `--hooks --json` resync procedure, `CLAUDE.md` pointer, and how-guide with Appendix-A tree; F001 notes LOW wording drift only. |
| AC-09 | 97% | T006 records `SKILL.md` updated to state direct-jump has no harness seams and is harness-less by design. |
| AC-10 | 97% | T005 records schema/template alignment, stale "spine between spec and plan" prose removal, `--hook` conversion, and fix-loop `--json` additions/abbreviated-template note. |

### E.5) Doctrine Compliance

#### F001 - `--event` fallback wording conflicts with the no-fallback runtime rule

- **Severity**: LOW
- **Files**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md:113-134
  - /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md:254,337
- **Rule**: the flow emits `--hook`; older `--event`-only routers are a runtime-dependency gap that should prompt reinstall, not an automatic fallback path.
- **Issue**: `harness-seams.md:113` says `--event` is "the back-compat fallback for an older router," while `harness-seams.md:134` says the flow does not silently down-emit `--event`. The plan maintenance record has similar stale fallback phrasing.
- **Fix**: Replace "fallback" wording with "back-compat understanding" or "alias map for reading older envelopes"; preserve the reinstall/runtime-dependency rule as the only behavior.

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC-01 | `harness-seams.md` is the single home for seam map, detection, node emission, posture, retro lifecycle, and silent path. | T001 execution log; file exists in changed set. | 97% |
| AC-02 | Sub-skills have no seam firing or harness-loop concepts. | T004 execution log plus re-run greps: both empty. | 96% |
| AC-03 | `00-routing.md` points to `harness-seams.md`; Graph carries literal seam beats. | T003 execution log; changed routing file. | 95% |
| AC-04 | Node emission decoupled from provisioning across node, rail, narration surfaces. | Fix-loop F002 notes and current `harness-seams.md`/schema/getting-started wording. | 92% |
| AC-05 | Per-phase retro lifecycle defined with no new state file. | T001/T005 execution log; `harness-seams.md` lifecycle section. | 96% |
| AC-06 | Seams are honored-not-forced print-then-offer beats. | T001/T003/T006 execution log; `harness-seams.md` posture. | 97% |
| AC-07 | `just check-flow`, slug check, and JSON parse pass. | Review re-ran static checks successfully. | 99% |
| AC-08 | Maintenance/resync record, `CLAUDE.md` pointer, and docs/how guide. | T002/T007 execution log; F001 is a LOW wording cleanup. | 94% |
| AC-09 | Direct-jump goes harness-less by design. | T006 execution log; `SKILL.md` changed. | 97% |
| AC-10 | Schema/template align to engine-owned `--hook` seams. | T005 execution log; fix-loop F003 adds `--json` and abbreviated-template note. | 97% |

**Overall coverage confidence**: 95%

## G) Commands Executed

Subagents launched: implementation quality, domain compliance, anti-reinvention, testing/evidence, doctrine/rules.

```bash
git --no-pager status --short
git --no-pager diff --stat
git --no-pager diff --staged --stat
find docs/plans/033-flow-owned-harness-seams -maxdepth 3 -type f
git --no-pager ls-files --others --exclude-standard
mkdir -p docs/plans/033-flow-owned-harness-seams/reviews
git --no-pager diff --no-ext-diff
git --no-pager diff --staged --no-ext-diff
git --no-pager diff --no-index -- /dev/null <untracked-file>
grep -rnE '/eng-harness-flow --(hook|event)' skills/SDD/the-flow/references/stages/
grep -rniE 'eng-harness|backpressure|harness-boot|harness-retro|harness observe' skills/SDD/the-flow/references/stages/
python3 -m json.tool skills/SDD/the-flow/references/flight-plan.schema.json
python3 -m json.tool skills/SDD/the-flow/references/flight-plan.template.json
python3 -m json.tool docs/plans/033-flow-owned-harness-seams/the-flow.json
python3 -m json.tool docs/plans/033-flow-owned-harness-seams/.the-flow-state.json
scripts/check-skill-slugs.sh
just check-flow
```

Computed diff saved to `/Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/reviews/_computed.diff`.

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review -
> only context on the work that was done before the review.

**Review result**: APPROVE

**Plan**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md  
**Spec**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md  
**Phase**: Simple Mode  
**Tasks dossier**: inline in plan  
**Execution log**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/execution.log.md  
**Review file**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/reviews/review.md

### Files Reviewed

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|
| /Users/jordanknight/github/tools/CLAUDE.md | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md | reviewed | the-flow | Optional LOW cleanup F001 |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/25-workshop.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/50-phase-tasks.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/60-implement.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/62-progress.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/70-review.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/docs/how/the-flow-harness-seams.md | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/.the-flow-state.json | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/execution.log.md | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md | reviewed | repo docs | Optional LOW cleanup F001 |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/original-ask.md | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/the-flow.json | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/the-flow.md | reviewed | repo docs | none |

### Required Fixes (if REQUEST_CHANGES)

N/A - review result is APPROVE.

### Domain Artifacts to Update (if any)

| File (absolute path) | What's Missing |
|---------------------|----------------|
| N/A | This repository has no `docs/domains/**` artifacts. |

### Handback

Implementation is approved. The LOW wording cleanup can be handled opportunistically; it does not need another implement/review loop unless the team wants the mirror text perfectly polished before merge.
