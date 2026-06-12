# Code Review: Simple Mode

**Plan**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-plan.md
**Spec**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-spec.md
**Phase**: Simple Mode
**Date**: 2026-06-12
**Reviewer**: Automated (the review verb)
**Testing Approach**: Lightweight
**Computed diff**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/reviews/_computed.diff

## A) Verdict

**REQUEST_CHANGES**

The implementation still contains routing/next-step leakage in sub-skills, and the new deterministic lint reports clean because it misses those forms.

**Key failure areas**:
- **Implementation**: `check-flow-architecture.sh` misses plural/capitalized `## Next Steps` and incomplete flow-command forms, so the proof layer can pass with forbidden content present.
- **Domain compliance**: No formal `docs/domains/` registry exists; informal domain placement is otherwise consistent.
- **Testing**: Verification evidence is strong, but AC7/AC13 overclaim "grammar + bannered views only" while the implementation now has additional authorized literal classes.
- **Doctrine**: Sub-skills still name successor/routing concepts (`Next Steps`, specify next, deleted 61 module), which violates the new sub-skill pattern.

## B) Summary

The main restructuring is directionally sound: the pattern doc, Registry/Graph split, stage count reduction, deployment evidence, and lightweight verification trail are all present. The blocking issue is that the exemplar does not actually satisfy its own de-leak contract: two sub-skills still contain `## Next Steps` sections, and one of them explicitly says specification comes next. The lint passes only because L1 looks for singular/case-sensitive `Next step` forms, so AC1/AC2 are not yet a reliable proof. There are also smaller stale-vocabulary and evidence-consistency issues to clean up before this can be approved.

## C) Checklist

**Testing Approach: Lightweight**

- [x] Core validation tests present
- [x] Critical paths covered by `just check-flow`, grep censuses, resume read-through, deploy/tidy checks
- [x] Key verification points documented in execution log
- [ ] Only in-scope files changed
- [ ] Linters/type checks clean as proof of the stated acceptance criteria
- [x] Domain compliance checks pass or are N/A for this repo

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| F001 | HIGH | /Users/jordanknight/github/tools/scripts/check-flow-architecture.sh:142-144 | pattern | L1 misses plural/capitalized `## Next Steps`, so forbidden sub-skill routing sections pass. | Make the next-step marker detection case-insensitive and plural/bold-label aware, then rerun `just check-flow`. |
| F002 | HIGH | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md:894-908; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md:980-1001 | pattern | Sub-skills still carry `## Next Steps` sections; explore explicitly says specification comes next. | Remove or rename/reframe these as artifact/gate content with no successor/routing prose. |
| F003 | MEDIUM | /Users/jordanknight/github/tools/scripts/check-flow-architecture.sh:232-250 | pattern | L3 allows bannered view commands with only an id and does not catch bare verb commands. | Require id+verb in rendered command literals and add negative self-tests for id-only and verb-only forms. |
| F004 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/60-implement.md:233 | pattern | Implement procedure says `Suggest next step`, conflicting with Graph-owned routing and the fixed Exit contract. | Report phase completion and stop; let the parent flow render any next edge. |
| F005 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-specify.md:62 | pattern | Specify says the post-spec seam fires in "Next steps", despite the seam being flow-level and the sub-skill declaring no side effects. | Delete or reword to say post-spec routing is Graph-owned after this verb exits. |
| F006 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/62-progress.md:80-85 | correctness | Progress still names deleted `61-implement-companion.md` and incorrectly says implement stages fire plan-complete. | Reword: progress fires no harness seams; implement owns phase-end; merge owns plan-complete. |
| F007 | LOW | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md:22-27 | pattern | Coach still refers to "Stage 60/61" after the companion fold. | Reword to the implement verb / stage 6, optionally mentioning `--companion`. |
| F008 | MEDIUM | /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-plan.md:105-120; /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/execution.log.md:261-266 | testing | AC7/AC13 checklist says literals are only in grammar + bannered views, but execution evidence adds marker-exempt quotations and flight-plan JSON/schema data. | Update AC wording/checklist to include those authorized classes, or remove/slot those literals. |

## E) Detailed Findings

### E.1) Implementation Quality

#### F001 - HIGH - L1 blind spot lets forbidden `Next Steps` sections pass

`scripts/check-flow-architecture.sh:142-144` only matches `^Next step` and `^## Next step` with case-sensitive singular spelling. The current tree contains:

- /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md:894
- /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md:980

`just check-flow` reports `OK: L1: 0 leak lines across 10 sub-skill(s)`, proving the lint can go green while forbidden marker sections remain.

**Fix**: Expand L1 to cover `Next Steps`, `Next steps`, `**Next step**`, `**Next steps**`, and plural/capitalized variants. Add a negative self-test that plants `## Next Steps` in a toy sub-skill and expects L1 failure.

#### F002 - HIGH - Sub-skills still carry next-step/routing prose

`10-explore.md:894-908` has a `## Next Steps` section that says "Pre-Plan: specification comes next (the specify verb consumes this dossier)." That is successor knowledge inside a sub-skill. `80-merge.md:980-1001` also uses `## Next Steps`; the PROCEED/ABORT gate is valid, but the section label and "suggest alternative approaches" routing copy trip the plan's forbidden next-step contract.

**Fix**: In explore, replace the section with neutral artifact handoff/consumer notes, or remove it. In merge, rename/split the section into gate-specific wording such as `## PROCEED/ABORT execution gate` and `## Recovery commands`, preserving the required PROCEED phrase.

#### F003 - MEDIUM - L3 accepts incomplete command literals

`scripts/check-flow-architecture.sh:232-250` matches only digit-led commands and makes the verb optional. A bannered view containing `/the-flow 6` would pass because the id exists, and `/the-flow implement` is not inspected at all. The command grammar says printed commands carry both id and verb.

**Fix**: Make L3 detect both id-led and verb-led flow-token commands. For rendered views, require id+verb and verify the pair against the Registry.

#### F004 - MEDIUM - Implement still tells the agent to suggest next routing

`60-implement.md:233` says `STOP: Report phase complete. Suggest next step.` The sub-skill Exit contract says routing is the flow's job; this line asks the verb to do routing narration.

**Fix**: Change the stop instruction to report phase completion and stop.

#### F005 - MEDIUM - Specify still assigns post-spec seam ownership to "Next steps"

`20-specify.md:62` says the post-spec seam fires in Next steps after the spec is written. The spec/plan moved post-spec to the flow-level Graph, and this sub-skill declares `Side effects: none`.

**Fix**: Remove the sentence or reword it to say the parent flow's Graph owns post-spec seam routing after this verb exits.

#### F006 - MEDIUM - Progress has stale deleted-module/seam text

`62-progress.md:80-85` still says "`60-implement.md` and `61-implement-companion.md` fire its phase-end / plan-complete seams." The companion file was deleted, and plan-complete belongs to merge.

**Fix**: Reword the retired-retro paragraph to say progress fires no harness seams; implement owns phase-end; merge owns plan-complete.

#### F007 - LOW - Coach still says "Stage 60/61"

`coach.md:22-27` retains deleted-stage vocabulary in the compaction exception.

**Fix**: Reword to "the implement verb / stage 6" and optionally mention companion mode via `--companion`.

### E.2) Domain Compliance

No `docs/domains/` registry, map, or domain docs exist in this repo. The spec and plan explicitly use informal domains.

| Check | Status | Details |
|-------|--------|---------|
| File placement | ✅ | Changed source/docs/tooling files align with the plan Domain Manifest; plan-state artifacts are expected Simple Mode outputs. |
| Contract-only imports | ✅ | No cross-domain code imports were introduced; shell script is standalone. |
| Dependency direction | ✅ | No prohibited business/infrastructure dependency edge was found. |
| Domain.md updated | N/A | No `docs/domains/*/domain.md` exists. |
| Registry current | N/A | No `docs/domains/registry.md` exists. |
| No orphan files | ✅ | All reviewed files are either in the Domain Manifest or plan-state/review artifacts. |
| Map nodes current | N/A | No `docs/domains/domain-map.md` exists. |
| Map edges current | N/A | No domain map exists. |
| No circular business deps | N/A | No domain map exists. |
| Concepts documented | N/A | No domain docs exist. |

### E.3) Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|
| `scripts/check-flow-architecture.sh` | `scripts/check-skill-slugs.sh` provides script conventions only, not flow architecture linting | repo tooling | proceed |
| `docs/skills-pipeline/flow-architecture.md` | No existing formal composable-flow pattern doc found | docs | proceed |
| `docs/plans/031-skills-flow-architecture/execution.log.md` | Plan execution logs are existing plan artifacts, but this log is plan-specific | docs | proceed |

No genuine reinvention finding.

### E.4) Testing & Evidence

**Coverage confidence**: 92%

| AC | Confidence | Evidence |
|----|------------|----------|
| AC1 | 100% | `just check-flow` is wired and exits 0, but F001 means the check is incomplete. |
| AC2 | 75% | Execution log records L1 baseline and green result; F001/F002 show L1 misses current forbidden forms. |
| AC3 | 100% | L2 evidence shows 10/10 contract blocks and Exit lines. |
| AC4 | 95% | T007/T008 record 61 deletion, companion mode, Graph decoration, and flight-plan updates. |
| AC5 | 90% | T012 records all 12 retired slugs plus typed aliases and five resume cases. |
| AC6 | 93% | T001/T013 record seam multiset and PROCEED phrase parity. |
| AC7 | 82% | Coach and L3 are mostly clean; F003 and F008 identify gaps/exceptions. |
| AC8 | 95% | Registry and Graph masters are declared; getting-started has a render banner. |
| AC9 | 90% | Pattern doc checklist and variant-flow assembly pass are recorded. |
| AC10 | 95% | L6 remeasure is 967 chars and check-flow reports OK. |
| AC11 | 95% | State-write ownership and load-path parity are recorded as preserved. |
| AC12 | 95% | Deploy/tidy/orphan/doctor evidence is recorded. |
| AC13 | 78% | Literal census is recorded, but includes additional authorized classes not reflected in AC wording. |
| AC14 | 100% | Stale grep and pattern links are recorded clean. |

### E.5) Doctrine Compliance

No `docs/project-rules/` files exist. Applicable doctrine comes from CLAUDE.md and the new flow architecture pattern. Findings F001-F007 cover the doctrine failures: deterministic proof must enforce the pattern, and sub-skills must not carry flow routing or stale deleted-stage vocabulary.

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC1 | Lint script exists, conventions, flow-dir param, `just check-flow`, exits 0 | Script and just recipe present; execution log T013; live `just check-flow` output | 100% |
| AC2 | L1 leak census is zero | Live lint says zero; live grep finds uncaught `## Next Steps` sections | 75% |
| AC3 | L2 contract blocks and Exit line 10/10 | Execution log T008/T013 | 100% |
| AC4 | D7 fold complete | Execution log T007/T008 and file manifest showing 61 deleted | 95% |
| AC5 | Slug/alias translation intact | Execution log T012 | 90% |
| AC6 | Harness seams and PROCEED phrase preserved | Execution log T001/T013 | 93% |
| AC7 | L3 clean across flow-level files | Execution log T013, with F003/F008 caveats | 82% |
| AC8 | One Registry master and one Graph master | SKILL.md/00-routing and execution log | 95% |
| AC9 | Pattern doc exists and is proven | flow-architecture.md and T014 assembly evidence | 90% |
| AC10 | L6 description budget passes | Execution log T013 and lint output | 95% |
| AC11 | Load-path parity and state ownership preserved | Execution log T013 | 95% |
| AC12 | Deploy and tidy complete | Execution log T015 | 95% |
| AC13 | Whole-skill literal census scoped | Execution log T013, but plan/spec wording needs update | 78% |
| AC14 | External docs updated | Execution log T011 | 100% |

**Overall coverage confidence**: 92%

## G) Commands Executed

```bash
git --no-pager status --short
git --no-pager diff --stat
git --no-pager diff --staged --stat

mkdir -p docs/plans/031-skills-flow-architecture/reviews
git --no-pager diff --binary
git --no-pager diff --staged --binary
git ls-files --others --exclude-standard
git --no-pager diff --no-index --binary -- /dev/null <untracked-file>

just check-flow

grep -rnE '^## Next Steps' skills/SDD/the-flow/references/stages
grep -rnE 'Stage 60/61|61-implement-companion|stage 60/61' skills/SDD/the-flow/references skills/SDD/the-flow/SKILL.md
grep -nE '/the-flow [0-9]|references/stages/[0-9A-Za-z]|(^|[^/a-z])stages/[0-9A-Za-z][^[:space:]]*\.md|\*\*Next routing\*\*|^## Next routing|^Next step|^## Next step' skills/SDD/the-flow/references/stages/10-explore.md
```

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review -
> only context on the work that was done before the review.

**Review result**: REQUEST_CHANGES

**Plan**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-plan.md
**Spec**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-spec.md
**Phase**: Simple Mode
**Tasks dossier**: inline in plan
**Execution log**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/execution.log.md
**Review file**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/reviews/review.md
**Fix tasks**: /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/reviews/fix-tasks.md

### Files Reviewed

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|
| /Users/jordanknight/github/tools/CLAUDE.md | reviewed | docs | none |
| /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/.the-flow-state.json | reviewed | docs | none |
| /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-plan.md | needs fix | docs | Reconcile AC7/AC13 wording/checklist with actual authorized literal classes. |
| /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/the-flow.json | reviewed | docs | none |
| /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/the-flow.md | reviewed | docs | none |
| /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/execution.log.md | reviewed | docs | none; evidence is useful for fixing plan AC wording. |
| /Users/jordanknight/github/tools/docs/skills-pipeline/README.md | reviewed | docs | none |
| /Users/jordanknight/github/tools/docs/skills-pipeline/flow-architecture.md | reviewed | docs | none from this pass |
| /Users/jordanknight/github/tools/justfile | reviewed | repo tooling | none |
| /Users/jordanknight/github/tools/scripts/check-flow-architecture.sh | needs fix | repo tooling | Fix L1 and L3 blind spots; add negative self-tests. |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md | needs fix | the-flow | Remove "Stage 60/61" stale vocabulary. |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md | needs fix | the-flow | Remove/reframe `## Next Steps` routing template. |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-specify.md | needs fix | the-flow | Remove/reword post-spec "Next steps" seam ownership sentence. |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/25-workshop.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/30-architect.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/35-adr.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/50-phase-tasks.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/60-implement.md | needs fix | the-flow | Remove "Suggest next step" stop instruction. |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/61-implement-companion.md | reviewed deletion | the-flow | none; deletion is expected. |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/62-progress.md | needs fix | the-flow | Remove deleted 61 reference and plan-complete misattribution. |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/70-review.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md | needs fix | the-flow | Rename/reframe `## Next Steps` section while preserving PROCEED/ABORT gate wording. |

### Required Fixes (if REQUEST_CHANGES)

| # | File (absolute path) | What To Fix | Why |
|---|---------------------|-------------|-----|
| 1 | /Users/jordanknight/github/tools/scripts/check-flow-architecture.sh | Expand L1 and L3 detection; add negative tests for plural/bold next-step markers and id-only/verb-only commands. | The deterministic proof layer currently reports green while forbidden forms remain. |
| 2 | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md | Remove or reframe `## Next Steps` sections. | Sub-skills must not encode successor/routing knowledge. |
| 3 | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/60-implement.md; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-specify.md; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/62-progress.md; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md | Clean stale routing/seam/deleted-stage prose. | Keeps the D7 fold and Graph-owned routing semantics coherent. |
| 4 | /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-plan.md; /Users/jordanknight/github/tools/docs/plans/031-skills-flow-architecture/skills-flow-architecture-spec.md | Reconcile AC7/AC13 wording with the implementation's authorized literal classes, or remove those literals. | Current checklist overstates what the literal census proves. |

### Domain Artifacts to Update (if any)

| File (absolute path) | What's Missing |
|---------------------|----------------|
| N/A | No `docs/domains/` registry/domain-map/domain.md files exist in this repo. |

### Handback

Fixes go back through the implement verb with the same plan flag, then re-run this review.
