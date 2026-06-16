# Code Review: Simple Mode

**Plan**: /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-plan.md
**Spec**: /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-plan.md (`## Business Specification`; legacy spec also present as planning evidence)
**Phase**: Simple Mode
**Date**: 2026-06-16
**Reviewer**: Automated (the review verb)
**Testing Approach**: Manual

## A) Verdict

**APPROVE**

No HIGH or CRITICAL findings were found. The implementation is lint-clean and broadly satisfies the plan, with medium follow-ups around legacy routing, merge reader fallback, flow-ownership separation, and evidence/documentation currency.

**Key failure areas**:
- **Implementation**: Legacy split-flow folders with both `*-spec.md` and an architect-era `*-plan.md` can miss the completed-plan adoption path because the new marker requires `## Implementation Plan`.
- **Domain compliance**: The plan Domain Manifest omits several touched flow-template files and the deleted source file from the rename.
- **Reinvention**: The new `20-plan.md` Planning Seam repeats routing/refinement offers already owned by the Graph and coach.
- **Testing**: Some T009 manual replay evidence is summarized rather than recorded as concrete input/output.
- **Doctrine**: `80-merge.md` still has spec-centric reads after its folder gate was updated for unified plan folders.

## B) Summary

The core consolidation is structurally sound: `just check-flow`, slug collision checks, and JSON parsing all pass, and the Registry/Graph/module closure is clean. The one-verb `plan` module contains the required contract labels, both planning halves, G1-G7, and the validator auto-run. Downstream workshop/ADR/review/merge folder-detection changes mostly honor unified-plan-with-legacy-fallback behavior. The remaining findings are medium/low maintainability and compatibility risks, not blockers for approving this phase.

## C) Checklist

**Testing Approach: Manual**

- [x] Manual verification steps documented
- [x] Manual test results recorded with observed outcomes for core lint/slug checks
- [x] Evidence artifacts present
- [x] Only in-scope files changed
- [x] Linters/type checks clean where applicable
- [x] Domain compliance checks pass with medium documentation follow-up

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| F001 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md:120-130 | correctness | Legacy split-flow folders with both `*-spec.md` and old architect `*-plan.md` are not explicitly recognized as completed planning. | Add a legacy split-plan branch: if both files exist and the plan lacks `## Business Specification`, treat it as completed split planning and route by mode. |
| F002 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md:132-136,298-300 | correctness | Merge analysis still tells agents to read `spec.md` for mode/business context after the folder gate accepts unified `*-plan.md`. | Read mode and business summary from the unified plan top metadata / `## Business Specification`, with legacy `*-spec.md` fallback. |
| F003 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md:179-188,625-627 | pattern | The sub-skill writes actionable workshop/backpressure/compact/next-work offers into the plan artifact, duplicating Graph/coach ownership. | Keep the artifact to consumed evidence and planning output; let `00-routing.md` and `coach.md` render actionable seam offers. |
| F004 | MEDIUM | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md:191-196; /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json:47-52 | pattern | Flight-plan render guidance still references a no-harness `spec --> plan` fallback and is inconsistent about backpressure placement after unifying the plan node. | Make the no-harness fallback connect unified `plan` directly to the next spine node, and align template/rules on whether post-plan backpressure is an excursion or spine node. |
| F005 | MEDIUM | /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-plan.md:34-51 | domain | The Domain Manifest omits touched source/template files, including `flight-plan.*` and the deleted `20-specify.md`. | Add rows or explicitly state that rename/delete/template files are covered by the `the-flow` domain manifest. |
| F006 | MEDIUM | /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/execution.log.md:27-38 | testing | T009 replay/adoption/rg/deploy evidence is mostly prose summary, and T006 appears after the phase summary rather than in task order. | Add a compact verification table with input, expected result, observed result, and status; move T006 into the main task table order. |
| F007 | LOW | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md:148-153 | pattern | Fresh-start narration still shows a 7-pip rail after the flow collapsed to 6 macro-milestones. | Update the hard-coded start rail to the 6-pip form or render it from the stage map. |

## E) Detailed Findings

### E.1) Implementation Quality

**F001 - Legacy split-plan adoption can miss completed planning**

- **Severity**: MEDIUM
- **File**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md:120-130
- **Issue**: The new completed-plan predicate keys on `<slug>-plan.md` containing `## Implementation Plan`. The legacy architect module generated `# [Feature Name] Implementation Plan` and sections like `## Gate Matrix`, not a `## Implementation Plan` wrapper. Old folders with both legacy `*-spec.md` and legacy `*-plan.md` can therefore be treated as not fully planned, despite being complete under the previous contract.
- **Fix**: Add an explicit legacy branch: `*-spec.md` plus `*-plan.md` and no `## Business Specification` means "completed split planning"; route to `implement` for Simple or `tasks` for Full using the legacy spec mode.

**F002 - Merge still reads spec-centric context after unified folder detection**

- **Severity**: MEDIUM
- **File**: /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md:132-136,298-300
- **Issue**: The merge gate accepts folders with `*-plan.md`, but later instructions still say to read `spec.md` for mode and "what you're building". Unified folders may have no standalone spec, so merge analysis can lose mode/business context.
- **Fix**: Replace these reads with unified-plan top metadata and `## Business Specification`, falling back to legacy `*-spec.md` only when present.

### E.2) Domain Compliance

| Check | Status | Details |
|-------|--------|---------|
| File placement | OK | Touched source files remain under the declared `the-flow` skill/docs area; plan artifacts remain under `docs/plans/032-unified-planning-doc/`. |
| Contract-only imports | N/A | Markdown/JSON skill artifacts only; no code imports introduced. |
| Dependency direction | N/A | No business/infrastructure code dependency graph involved. |
| Domain.md updated | N/A | Repository has no `docs/domains/` registry/domain docs. |
| Registry current | N/A | Repository has no `docs/domains/registry.md`; the plan declares this explicitly. |
| No orphan files | WARN | F005: Domain Manifest omits touched `flight-plan.*` files and the deleted `20-specify.md`. |
| Map nodes current | N/A | Repository has no `docs/domains/domain-map.md`. |
| Map edges current | N/A | Repository has no `docs/domains/domain-map.md`. |
| No circular business deps | N/A | No domain map exists and no source dependency cycle was introduced. |
| Concepts documented | N/A | No domain docs/contracts exist for this repo. |

### E.3) Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|
| `20-plan.md` Planning Seam | `00-routing.md` Graph seams and `coach.md` post-plan narration | the-flow | F003 - reuse flow-owned seam rendering rather than duplicating offers inside the sub-skill artifact |
| `flight-plan.template.json` backpressure node | `00-routing.md` flight-plan render rules | the-flow | F004 - align template with render rules and unified no-harness fallback |

### E.4) Testing & Evidence

**Coverage confidence**: 82%

| AC | Confidence | Evidence |
|----|------------|----------|
| AC-01 | 88% | `20-plan.md` exists; `20-specify.md` and `30-architect.md` are deleted; Registry maps `1b plan` to `20-plan.md`. |
| AC-02 | 87% | `20-plan.md` includes single-status metadata, `## Business Specification`, `## Planning Seam`, `## Implementation Plan`, and Acceptance Coverage Map requirements. |
| AC-03 | 86% | Round 1/2 questions, G1-G7, and `/validate-v2` auto-run are present in `20-plan.md`; dry-read evidence is recorded in the execution log. |
| AC-04 | 76% | Graph/coach define dormant/live post-plan refinement behavior; routing walks are summarized but not transcripted. |
| AC-05 | 78% | Routing markers and read-time translations exist; replay is summarized without concrete state input/output. |
| AC-06 | 100% | `just check-flow`, `scripts/check-skill-slugs.sh`, and JSON parsing passed during review. |
| AC-07 | 82% | Workshop/review/ADR/merge folder gates now generally accept unified plan plus legacy fallback; merge still has spec-centric read instructions (F002). |
| AC-08 | 80% | Adoption shapes are covered in docs and historical folders appear untouched; actual adoption runs are not logged. |
| AC-09 | 86% | Registry, generated getting-started view, flow architecture docs, and CLAUDE.md reflect the single planning stage; lint corroborates closure. |

### E.5) Doctrine Compliance

No `docs/project-rules/{rules,idioms,architecture,constitution}.md` files exist. The applicable doctrine is the repository's contributor guide and the flow-architecture pattern. Findings F002-F004 and F007 are the meaningful doctrine/pattern issues: merge readers should honor unified-plan source-of-truth, sub-skills should stay flow-blind and avoid owning seam routing, flight-plan rules/templates should agree, and the rail should match the collapsed milestone count.

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC-01 | One artifact (`<slug>-plan.md`, no new standalone spec) | Source tree and Registry inspection | 88% |
| AC-02 | One document with both halves, single status, Planning Seam, Coverage Map | `20-plan.md` source inspection | 87% |
| AC-03 | No question dropped; G1-G7 and validate-v2 survive | `20-plan.md` source inspection and execution log | 86% |
| AC-04 | Refinement seam only when live | `00-routing.md`/`coach.md` source inspection | 76% |
| AC-05 | Deterministic routing/resume | `00-routing.md` markers/translation; F001 notes legacy split gap | 78% |
| AC-06 | Lints green | Review-run command output | 100% |
| AC-07 | Downstream reads unified plan + legacy fallback | Downstream module inspection; F002 notes merge read gap | 82% |
| AC-08 | No over-built migration; legacy untouched/adoptable | Source inspection and working tree scope | 80% |
| AC-09 | Registry/docs reflect one stage | SKILL/docs/getting-started inspection and flow lint | 86% |

**Overall coverage confidence**: 82%

## G) Commands Executed

```bash
git --no-pager status --short
git --no-pager diff --stat
git --no-pager diff --staged --stat
git --no-pager diff --no-ext-diff
git --no-pager diff --staged --no-ext-diff
git ls-files --others --exclude-standard
git --no-pager diff --no-index -- /dev/null <untracked-file>
just check-flow
scripts/check-skill-slugs.sh
python -m json.tool skills/SDD/the-flow/references/flight-plan.template.json >/dev/null
python -m json.tool skills/SDD/the-flow/references/flight-plan.schema.json >/dev/null
git --no-pager show HEAD:skills/SDD/the-flow/references/stages/30-architect.md | rg -n "Implementation Plan|^# |^## |Status|Mode" | head -80
git --no-pager show HEAD:skills/SDD/the-flow/references/stages/20-specify.md | rg -n "Produces|spec.md|Mode|Status|Business Specification|Implementation Plan" | head -80
rg "(1b specify|3 architect|20-specify|30-architect|awaiting-3|--implementation|Business/Implementation Status|NOT PLANNED|STALE|/the-flow 3 architect|\\*\\*specify\\*\\*|\\*\\*architect\\*\\*)" skills/SDD/the-flow docs/skills-pipeline/flow-architecture.md CLAUDE.md
rg "(<slug>-plan\\.md|<slug>-spec\\.md|Business Specification|legacy|SPEC|FEATURE_SPEC|plan folder|abort|contains)" skills/SDD/the-flow/references/stages/{25-workshop,35-adr,50-phase-tasks,60-implement,70-review,80-merge}.md
```

## H) Handover Brief

**Review result**: APPROVE

**Plan**: /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-plan.md
**Spec**: /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-plan.md (`## Business Specification`; legacy planning spec also exists at /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-spec.md)
**Phase**: Simple Mode
**Tasks dossier**: inline in plan
**Execution log**: /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/execution.log.md
**Review file**: /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/reviews/review.md

### Files Reviewed

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|
| /Users/jordanknight/github/tools/CLAUDE.md | reviewed | docs | None |
| /Users/jordanknight/github/tools/docs/skills-pipeline/flow-architecture.md | reviewed | docs | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md | reviewed | the-flow | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md | reviewed | the-flow | F001/F004 follow-up |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md | reviewed | the-flow | F007 follow-up |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json | reviewed | the-flow | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json | reviewed | the-flow | F004 follow-up |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md | reviewed | the-flow | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md | reviewed | the-flow | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md | reviewed | the-flow | F003 follow-up |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-specify.md | reviewed | the-flow | Deleted as intended; add manifest mention (F005) |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/25-workshop.md | reviewed | the-flow | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/30-architect.md | reviewed | the-flow | Deleted as intended |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/35-adr.md | reviewed | the-flow | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/70-review.md | reviewed | the-flow | None |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md | reviewed | the-flow | F002 follow-up |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-plan.md | reviewed | plan artifact | F005 follow-up |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/execution.log.md | reviewed | plan artifact | F006 follow-up |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-spec.md | reviewed | plan artifact | None |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/workshops/001-routing-seam-registry.md | reviewed | plan artifact | None |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/.the-flow-state.json | reviewed | plan artifact | None |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/the-flow.json | reviewed | plan artifact | None |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/the-flow.md | reviewed | plan artifact | None |
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/original-ask.md | reviewed | plan artifact | None |

### Required Fixes (if REQUEST_CHANGES)

| # | File (absolute path) | What To Fix | Why |
|---|---------------------|-------------|-----|
| N/A | N/A | No blocking fixes required | Verdict is APPROVE; findings are medium/low follow-ups |

### Domain Artifacts to Update (if any)

| File (absolute path) | What's Missing |
|---------------------|----------------|
| /Users/jordanknight/github/tools/docs/plans/032-unified-planning-doc/unified-planning-doc-plan.md | Domain Manifest should mention changed `flight-plan.*` files and deleted/renamed source paths, or state that plan-artifact/template changes are intentionally covered under `the-flow`. |

### Handback

Implementation is approved. Medium/low follow-ups can be handled in a later implement pass if desired; no `fix-tasks.md` was created because there are no HIGH/CRITICAL findings.
