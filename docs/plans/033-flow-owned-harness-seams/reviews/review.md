# Code Review: Simple Mode

**Plan**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md
**Spec**: /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md
**Phase**: Simple Mode
**Date**: 2026-06-17
**Reviewer**: Automated (the review verb)
**Testing Approach**: Manual (lint-gated)

## A) Verdict

**REQUEST_CHANGES**

The implementation leaves the post-plan backpressure refinement route advertising a re-plan/fold-in behavior that the stripped `plan` verb no longer supports.

**Key failure areas**:
- **Implementation**: The guided Graph still routes `backpressure-coverage.md` back through `plan`, but `20-plan.md` no longer consumes that artifact.
- **Doctrine**: Harness seam ownership is mostly centralized, but several flow-level contract surfaces contradict the new source-of-truth rules.

## B) Summary

The flow-owned harness seam inversion is broadly implemented and the evidence log covers the planned manual validation path. Domain placement and anti-reinvention checks found no material issues: the new `harness-seams.md` centralizes dispersed flow-level seam knowledge rather than duplicating an existing single source. The blocking issue is a contract mismatch introduced by stripping backpressure consumption from the `plan` sub-skill while leaving the guided route and narration promising that coverage can be folded back into a re-run plan. Secondary consistency issues should be fixed in the same pass to keep the seam contract, template, and coach voice aligned.

## C) Checklist

**Testing Approach: Manual**

- [x] Manual verification steps documented
- [x] Manual test results recorded with observed outcomes
- [x] Evidence artifacts present

Universal:
- [ ] Only in-scope files changed
- [x] Linters/type checks clean (if applicable)
- [x] Domain compliance checks pass

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| F001 | HIGH | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md:109-111; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md:7-12 | correctness / doctrine | Backpressure coverage is routed back through `plan`, but `plan` no longer consumes `backpressure-coverage.md`. | Restore a harness-blind refinement input contract in `20-plan.md`, or remove the fold-in route/narration and treat the artifact as standalone advisory output. |
| F002 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md:60-71 | correctness | Installed-but-unprovisioned node emission is contradictory: nodes are said to never vanish, then per-phase nodes are explicitly omitted. | Choose one behavior and align `harness-seams.md`, `00-routing.md`, schema, and docs. |
| F003 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json:47-96 | correctness | The worked template shows multiple phases but only one boot and one phase retro node, and the router commands omit `--json` despite the seam map depending on envelopes. | Expand the worked example to include per-phase boot/retro nodes with full envelope commands, or mark it as abbreviated and bind generation to the seam map. |
| F004 | LOW | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md:113-134 | error-handling | The docs claim an older `--event`-only router is a fallback while the flow emits only `--hook`, with no version probe or fallback command path. | Add an explicit fallback emission path or state that old routers are unsupported and should produce a reinstall/runtime-dependency message. |
| F005 | LOW | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md:3 | doctrine | The coach intro still says deterministic seams live in `00-routing.md`, contradicting the new `harness-seams.md` split. | Reword the sentence so state/routing live in `00-routing.md` and harness seam orchestration lives in `harness-seams.md`. |

## E) Detailed Findings

### E.1) Implementation Quality

#### F001 — Backpressure coverage is offered as fold-in, but `plan` no longer consumes it

- **Severity**: HIGH
- **File**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md:109-111
- **Related file**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md:7-12
- **Issue**: `00-routing.md` still says the `pre-coding` backpressure seam leads to `awaiting-backpressure`, then re-runs `plan` to fold in `backpressure-coverage.md`. The `plan` verb contract now consumes feature description, research dossier, workshops, and doctrine/domain inputs only; it no longer names or reads `backpressure-coverage.md`.
- **Impact**: Guided users can accept a first-class backpressure beat, produce coverage, and then be sent through a re-plan that ignores the produced artifact. That makes the new engine-owned seam visible but not honored in the promised way.
- **Fix**: Decide whether coverage remains an input to planning. If yes, restore a harness-blind optional refinement input in `20-plan.md` and the plan template. If no, remove the `folds the coverage in` route/narration and present coverage as advisory output only.

#### F002 — Installed/unprovisioned node-emission rules conflict

- **Severity**: MEDIUM
- **File**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md:60-71
- **Issue**: The section opens with "Emit the harness node when the router is installed" and says provisioning affects label/status, not visibility. The unprovisioned bullet then says "no per-phase ghost-node spam" and "do not stamp an adopt-to-activate node on every phase." The reconciliation list repeats that the flight-plan node is emitted when installed.
- **Impact**: Implementers of the guided engine cannot tell whether installed-but-unprovisioned repos should emit dormant nodes or omit per-phase nodes after the calm line.
- **Fix**: Pick one rule and make all three surfaces match. Either emit dormant/noop nodes when installed, or omit per-phase nodes while unprovisioned and remove the "never vanish" claim.

#### F003 — Template under-models the per-phase seam lifecycle

- **Severity**: MEDIUM
- **File**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json:47-96
- **Issue**: The template presents a six-phase plan but includes one `harness-boot` node for `p1` and one phase `harness-retro` node for `p2`. It also stores `/eng-harness-flow --hook ...` commands without `--json`, while the seam contract relies on reading the router envelope.
- **Impact**: The template is a contract-adjacent example for generated flight plans. As written, it can teach a generator to create representative rather than per-phase seam nodes.
- **Fix**: Expand the template to show boot/retro siblings for each represented phase, or explicitly mark the nodes as abbreviated examples and ensure generated plans follow `harness-seams.md`.

#### F004 — Old-router fallback is documented but not operationalized

- **Severity**: LOW
- **File**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md:113-134
- **Issue**: The mirror table says `--event` is the fallback for older routers, but the flow emits `--hook` commands and no version probe or alternate emission path is described.
- **Impact**: A user with the older event-only router could see a printed command that the installed router cannot parse, despite the documentation saying the seams still route.
- **Fix**: Either add an explicit old-router fallback rule (`--hook` primary, mapped `--event` fallback on unsupported hook) or state that hook-aware routers are required.

### E.2) Domain Compliance

No domain-compliance findings.

| Check | Status | Details |
|-------|--------|---------|
| File placement | ✅ | New `harness-seams.md` lives under `skills/SDD/the-flow/references/`; the how-guide lives under `docs/how/`; plan artifacts live under `docs/plans/033-flow-owned-harness-seams/`. |
| Contract-only imports | N/A | Markdown/JSON skill contract changes; no code imports introduced. |
| Dependency direction | ✅ | The harness remains external and is referenced through `/eng-harness-flow`; no internal harness child skill dependency was introduced. |
| Domain.md updated | N/A | This repo has no `docs/domains/**` registry/domain docs. |
| Registry current | N/A | This repo has no `docs/domains/registry.md`. |
| No orphan files | ✅ | Changed source/docs files are covered by the plan Domain Manifest; review artifacts are review-stage outputs. |
| Map nodes current | N/A | This repo has no `docs/domains/domain-map.md`. |
| Map edges current | N/A | This repo has no `docs/domains/domain-map.md`. |
| No circular business deps | N/A | No domain dependency graph exists for this repository. |
| Concepts documented | N/A | No domain concept tables exist in this repository. |

### E.3) Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md` | None as a single source; it centralizes content formerly dispersed across routing/sub-skills/docs | the-flow | proceed |
| `/Users/jordanknight/github/tools/docs/how/the-flow-harness-seams.md` | Related guidance exists in `CLAUDE.md` and the plan appendix, but the how-guide is an intended rendered/external-reader view | repo docs | proceed |
| `/Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/*` | Plan artifacts follow existing SDD plan-folder convention | repo docs | proceed |

### E.4) Testing & Evidence

**Coverage confidence**: 94%

| AC | Confidence | Evidence |
|----|------------|----------|
| AC-01 | 96% | T001 logged `harness-seams.md` with seam map, two-layer detection, node emission, honored-not-forced posture, retro lifecycle, silent paths, and v1 contract. |
| AC-02 | 92% | T004 logged all 8 sub-skills stripped; grep evidence for `/eng-harness-flow --(hook\|event)` and harness-loop concept tokens under `references/stages/` is recorded as empty. |
| AC-03 | 95% | T003 logged `00-routing.md` pointer, Graph seam decorations, and render-rule rewiring. |
| AC-04 | 90% | T001/T003 logged emission/provisioning handling, but F002 shows the written rule needs reconciliation. |
| AC-05 | 95% | T001/T005 logged per-phase retro lifecycle and no new state file; `harness-seams.md` defines phase-linked retro lifecycle. |
| AC-06 | 96% | T001/T003/T006 logged print-then-offer posture; `harness-seams.md` says seams are never auto-fired, gating, scoring, or blocking. |
| AC-07 | 99% | T008 logged `just check-flow`, slug check, JSON parse, redeploy, and spot-check outcomes. |
| AC-08 | 94% | T002/T007 logged resync section, `CLAUDE.md` pointer, how-guide, and Appendix-A tree. |
| AC-09 | 96% | T006 logged `SKILL.md` update documenting direct-jump as harness-less by design. |
| AC-10 | 98% | T005 logged schema/template alignment, JSON parse, stale phrase removal, and hook-based template updates; F003 remains a template-shape consistency issue. |

### E.5) Doctrine Compliance

#### F005 — Coach still assigns seams to `00-routing.md`

- **Severity**: LOW
- **File**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md:3
- **Rule**: Flow-owned harness seam orchestration lives in `references/harness-seams.md`; `00-routing.md` owns state/routing/Graph.
- **Issue**: The coach intro says "The deterministic engine (state, routing, seams) lives in 00-routing.md."
- **Fix**: Reword to keep state/routing in `00-routing.md` and point harness seam orchestration to `harness-seams.md`.

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC-01 | `harness-seams.md` is the single home for seam map, detection, node emission, posture, retro lifecycle, silent path. | T001 execution log; file exists in changed set. | 96% |
| AC-02 | Sub-skills have no seam firing or harness-loop concepts. | T004 execution log with grep gates recorded empty. | 92% |
| AC-03 | `00-routing.md` points to `harness-seams.md`; Graph carries literal seam beats. | T003 execution log; `00-routing.md:107-115`. | 95% |
| AC-04 | Node emission decoupled from provisioning across node, rail, narration surfaces. | T001/T003 execution log; F002 requires wording/rule reconciliation. | 90% |
| AC-05 | Per-phase retro lifecycle defined with no new state file. | T001/T005 execution log; `harness-seams.md` lifecycle section. | 95% |
| AC-06 | Seams are honored-not-forced print-then-offer beats. | T001/T003/T006 execution log; `harness-seams.md` posture. | 96% |
| AC-07 | `just check-flow`, slug check, JSON parse pass. | T008 execution log records all checks green. | 99% |
| AC-08 | Maintenance/resync record, `CLAUDE.md` pointer, docs/how guide. | T002/T007 execution log; changed docs present. | 94% |
| AC-09 | Direct-jump goes harness-less by design. | T006 execution log; `SKILL.md` changed. | 96% |
| AC-10 | Schema/template align to engine-owned `--hook` seams. | T005 execution log; F003 flags remaining template-shape ambiguity. | 98% |

**Overall coverage confidence**: 94%

## G) Commands Executed

```bash
git --no-pager status --short
git --no-pager diff --stat
git --no-pager diff --staged --stat
git --no-pager log --oneline -10
git --no-pager diff --name-status
git --no-pager diff --staged --name-status
git ls-files --others --exclude-standard
mkdir -p docs/plans/033-flow-owned-harness-seams/reviews
git --no-pager diff --no-ext-diff
git --no-pager diff --staged --no-ext-diff
git --no-pager diff --no-index -- /dev/null <untracked-file>
```

Computed diff saved to `/Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/reviews/_computed.diff`.

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review —
> only context on the work that was done before the review.

**Review result**: REQUEST_CHANGES

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
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md | reviewed | the-flow | F001 |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md | reviewed | the-flow | F005 |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json | reviewed | the-flow | align if F002 changes node semantics |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json | reviewed | the-flow | F003 |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md | reviewed | the-flow | mirror F003 if template JSON changes |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md | reviewed | the-flow | align if F002/F003 changes rendered seam model |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md | reviewed | the-flow | F001 |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/25-workshop.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/50-phase-tasks.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/60-implement.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/62-progress.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/70-review.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md | reviewed | the-flow | none |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md | reviewed | the-flow | F002, F004 |
| /Users/jordanknight/github/tools/docs/how/the-flow-harness-seams.md | reviewed | repo docs | align if F002/F003 changes seam tree |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/.the-flow-state.json | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/execution.log.md | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md | reviewed | repo docs | update if accepted fix changes AC wording |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/original-ask.md | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/the-flow.json | reviewed | repo docs | none |
| /Users/jordanknight/github/tools/docs/plans/033-flow-owned-harness-seams/the-flow.md | reviewed | repo docs | none |

### Required Fixes (if REQUEST_CHANGES)

| # | File (absolute path) | What To Fix | Why |
|---|---------------------|-------------|-----|
| F001 | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md | Make the post-plan backpressure artifact's lifecycle match the `plan` verb contract. | The guided engine currently promises a fold-in re-plan that cannot consume the produced coverage artifact. |

### Domain Artifacts to Update (if any)

| File (absolute path) | What's Missing |
|---------------------|----------------|
| N/A | This repository has no `docs/domains/**` artifacts. |

### Handback

Fixes go back through the implement verb with the same plan, then re-run this review.
