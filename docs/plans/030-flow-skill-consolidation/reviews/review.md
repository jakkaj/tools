# Code Review: Simple Mode

**Plan**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md  
**Spec**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-spec.md  
**Phase**: Simple Mode  
**Date**: 2026-06-11  
**Reviewer**: Automated (the-flow stage 7 -- review)  
**Testing Approach**: Lightweight

## A) Verdict

**REQUEST_CHANGES**

Two core routing/lifecycle issues remain in the consolidated modules: the architect module routes READY Simple plans to the Full-mode task stage, and the companion implement module fires `plan-complete` before merge while also bypassing the normal review/merge route.

**Key failure areas**:
- **Implementation**: Stage routing and harness lifecycle text conflict with the consolidated dispatch/routing contract.
- **Domain compliance**: The plan's Domain Manifest omits several changed non-plan files that were touched during implementation.
- **Testing**: Structural evidence is strong, but behavioural drive evidence is mostly summarized instead of captured as reproducible command/output snippets.
- **Doctrine**: User-facing docs and utility skills still contain live references to deleted `/plan-*` surfaces.

## B) Summary

The consolidation is structurally close: the new `the-flow` dispatch is small, the stage modules exist, slug collision and JSON checks pass, and the old main-flow skill folders are removed. The main blockers are contract-level inconsistencies in next routing and harness seam ownership, both of which can mislead direct-jump users after the cutover. Documentation and utility cross-references still expose retired command names outside the intentional dispatch translation/provenance areas. Domain compliance is mostly N/A because this plan intentionally uses a concept-only domain, but the manifest must match the actual changed implementation surface.

## C) Checklist

**Testing Approach: Lightweight**

- [x] Core structural validation checks present
- [x] Critical structural paths covered
- [ ] Key behavioural verification points documented with concrete output
- [ ] Only in-scope files changed or manifest updated for scope additions
- [x] Linters/type checks clean where applicable (`check-skill-slugs.sh`, JSON validity)
- [ ] Domain compliance checks pass

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| F001 | HIGH | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/61-implement-companion.md:386-419 | correctness | Companion stage fires `plan-complete` before merge and routes only to the next phase, conflicting with stage 80's merge-owned `plan-complete` seam. | Remove `plan-complete` from stage 61 and route final companion completion to `/the-flow 8 --plan <plan dir>`; keep `/the-flow 5` only when another phase remains. |
| F002 | HIGH | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/30-architect.md:391-415 | correctness | Architect READY output always says `/the-flow 5`, but Simple Mode should route directly to implement (`/the-flow 6`). | Branch READY next-step text on detected mode: Simple -> `/the-flow 6 --plan <PLAN_PATH>`; Full -> `/the-flow 5 --phase <first phase> --plan <PLAN_PATH>`. |
| F003 | MEDIUM | /Users/jordanknight/github/tools/README.md:200,212,223,262,276<br>/Users/jordanknight/github/tools/INSTALL.md:13-16<br>/Users/jordanknight/github/tools/skills/SDD/plan-2b-v2-prep-issue/SKILL.md:26,38,278-280<br>/Users/jordanknight/github/tools/skills/SDD/code-concept-search-v2/SKILL.md:433-437<br>/Users/jordanknight/github/tools/skills/SDD/plan-0-v2-constitution/SKILL.md:246 | doctrine | Live docs/utilities still point at retired `/plan-*` command surfaces or stale SDD skill counts. | Rewrite active guidance to `/the-flow <id|name>` and update the `INSTALL.md` count to 13 SDD skills (1 main flow + 12 utilities). |
| F004 | MEDIUM | /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md:31-45 | domain | Domain Manifest omits changed non-plan files such as `README.md`, `scripts/sync-to-dist.sh`, and several utility SKILL.md files. | Add explicit manifest rows for every changed implementation/doc file or revert out-of-manifest edits. |
| F005 | MEDIUM | /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/execution.log.md:133-153 | testing | Behavioural validation claims for direct/guided loading and some grep/deploy checks are summarized, not captured as concrete command/output evidence. | Paste exact commands plus key output/counts for direct-jump, named-jump, guided load-set, retired-slug grep, harness parity, orphans, and doctor checks. |

## E) Detailed Findings

### E.1) Implementation Quality

**F001 -- Companion plan-complete seam fires too early**

`61-implement-companion.md` says final companion phases should fire `/eng-harness-flow --event plan-complete --json` after the debrief, while `00-routing.md` and `80-merge.md` make plan completion a merge-stage seam after explicit merge execution. That creates duplicate or premature long-horizon reflection and leaves final companion runs without a correct path to merge. The same block also says `/the-flow 7` is not required after companion mode, which may be acceptable if companion review is treated as equivalent, but it still needs a final route to `/the-flow 8`.

**F002 -- Architect READY next step ignores Simple Mode**

`30-architect.md` always prints `/the-flow 5 <same flags>` when a plan is READY. The routing source of truth says `awaiting-3 --Simple,READY--> awaiting-6` and `Full,READY--> awaiting-5`. In direct-jump mode there is no coach layer to correct the instruction, so a Simple Mode user can be routed into the Full-mode tasks module with missing phase context.

### E.2) Domain Compliance

| Check | Status | Details |
|-------|--------|---------|
| File placement | ✅ | Changed files remain under the expected repo surfaces for skills, docs, scripts, and plan artifacts. |
| Contract-only imports | N/A | Skill markdown and docs do not introduce code imports; `scripts/sync-to-dist.sh` removal is shell sync-surface cleanup only. |
| Dependency direction | N/A | No domain dependency graph exists for this concept-only domain. |
| Domain.md updated | N/A | Spec explicitly says no `docs/domains/` registry/domain.md machinery is created for this plan. |
| Registry current | N/A | No `docs/domains/registry.md` exists by design. |
| No orphan files | ❌ | Domain Manifest omits several changed implementation/doc files; see F004. |
| Map nodes current | N/A | No `docs/domains/domain-map.md` exists by design. |
| Map edges current | N/A | No domain map exists. |
| No circular business deps | N/A | No domain map exists. |
| Concepts documented | N/A | Concept-only domain sketch in the spec is the declared documentation level for this plan. |

### E.3) Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|
| `the-flow` dispatch + lazy stage modules | Intentional replacement of retired `plan-*` main-flow skills | sdd-pipeline-skills | proceed |
| `00-routing.md` / `coach.md` split | Existing behaviour extracted from old `the-flow` | sdd-pipeline-skills | proceed |

No genuine duplicate implementation was found outside the intentional consolidation.

### E.4) Testing & Evidence

**Coverage confidence**: 80%

| AC | Confidence | Evidence |
|----|------------|----------|
| AC1 | 95% | Execution log records deletion and `ls skills/SDD/`; read-only check lists `the-flow` plus 12 utilities. |
| AC2 | 95% | Execution log and read-only `wc -l` show `skills/SDD/the-flow/SKILL.md` has 83 lines. |
| AC3 | 90% | Execution log lists all 11 modules; changed-file manifest confirms all stage files exist. |
| AC4 | 65% | Execution log claims guided load set; no captured guided transcript/module-load evidence. |
| AC5 | 60% | Execution log reasons from the stage table; no captured direct `/the-flow 6` and named `/the-flow implement` run output. |
| AC6 | 95% | Execution log records clarify re-entry in `20-specify.md`; module exists. |
| AC7 | 90% | Execution log records tag `pre-flow-consolidation` at `44ba70f` and restore command. |
| AC8 | 95% | Read-only validation reran slug check and JSON validity successfully. |
| AC9 | 82% | Execution log records retired-slug grep scope; review grep found additional active old-surface references (F003). |
| AC10 | 85% | Execution log records install/tidy/doctor outcomes, but exact output is summarized. |
| AC11 | 75% | Execution log records harness parity PASS, but exact parity command/output is not included. |
| AC12 | 80% | Execution log records 030 live resume and 027/029 dry verification; exact dry-read transcript is summarized. |

### E.5) Doctrine Compliance

No formal `/Users/jordanknight/github/tools/docs/project-rules/**` files exist. `CLAUDE.md` conventions are broadly followed: source skill content lives under `skills/`, `src/jk_tools/` is not edited directly in this diff, and `the-flow` is now the single main-flow public skill. The remaining doctrine issue is stale public guidance to deleted command surfaces and stale skill counts (F003).

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC1 | `skills/SDD/` contains one main-flow skill; 12 absorbed folders gone. | `find skills/SDD -mindepth 1 -maxdepth 1 -type d`; execution log T009. | 95% |
| AC2 | Dispatch `SKILL.md` <= ~150 lines with stage table/invariants/state pointer. | `wc -l skills/SDD/the-flow/SKILL.md` -> 83; file reviewed. | 95% |
| AC3 | `references/stages/` covers all 11 absorbed capabilities. | Changed-file manifest and execution log T003-T006. | 90% |
| AC4 | Guided `/the-flow` loads coach + routing + current stage only. | Execution log T013(d), but transcript absent. | 65% |
| AC5 | Number/name direct jumps load the same module. | Dispatch table supports it; actual run evidence absent. | 60% |
| AC6 | Clarify re-entry reachable in `20-specify.md`. | Execution log T003 and module existence. | 95% |
| AC7 | Rollback tag exists and restore path documented. | Execution log T001. | 90% |
| AC8 | Slug check and JSON validity pass. | Review reran `scripts/check-skill-slugs.sh` and `python3 json.load`. | 95% |
| AC9 | Zero live retired-slug references outside allowed history/provenance. | Review grep found active exceptions; see F003. | 70% |
| AC10 | Deploy succeeds and retired deploy orphans are tidied. | Execution log T012, summarized output. | 85% |
| AC11 | Harness seam parity preserved. | Execution log T003-T006, summarized parity output. | 75% |
| AC12 | In-flight state resumes through translation table. | Execution log T013(a/b), summarized dry-read output. | 80% |

**Overall coverage confidence**: 80%

## G) Commands Executed

```bash
git --no-pager status --short
git --no-pager diff --stat
git --no-pager diff --staged --stat
mkdir -p docs/plans/030-flow-skill-consolidation/reviews
tmp=$(mktemp) && { git --no-pager diff --no-ext-diff; git --no-pager diff --staged --no-ext-diff; git ls-files --others --exclude-standard -z | while IFS= read -r -d '' f; do case "$f" in docs/plans/030-flow-skill-consolidation/reviews/*) continue ;; esac; git --no-pager diff --no-index -- /dev/null "$f" || true; done; } > "$tmp" && mv "$tmp" docs/plans/030-flow-skill-consolidation/reviews/_computed.diff
git --no-pager diff --name-status
git --no-pager diff --staged --name-status
git ls-files --others --exclude-standard | grep -v '^docs/plans/030-flow-skill-consolidation/reviews/'
scripts/check-skill-slugs.sh
python3 - <<'PY'
import json
for p in ['skills/SDD/the-flow/references/flight-plan.schema.json','skills/SDD/the-flow/references/flight-plan.template.json']:
    with open(p) as f:
        json.load(f)
    print(f'{p}: VALID')
PY
wc -l skills/SDD/the-flow/SKILL.md
find skills/SDD -mindepth 1 -maxdepth 1 -type d | sort | sed 's#^skills/SDD/##'
rg -n '/plan-1b-v2-specify|/plan-5\b|plan-5 output|plan-2-clarify|plan-3-v2|plan-6-v2|/plan-6a-v2|/plan-7-v2|/plan-8-v2' README.md INSTALL.md README_AGENTS.md docs/skills-pipeline/README.md CLAUDE.md skills/SDD -g '!*plan-*' -g '!the-flow/references/stages/*' -g '!the-flow/SKILL.md'
```

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review --
> only context on the work that was done before the review.

**Review result**: REQUEST_CHANGES

**Plan**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md  
**Spec**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-spec.md  
**Phase**: Simple Mode  
**Tasks dossier**: inline in plan  
**Execution log**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/execution.log.md  
**Review file**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/reviews/review.md  
**Computed diff**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/reviews/_computed.diff  
**Fix tasks**: /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/reviews/fix-tasks.md

### Files Reviewed

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|
| /Users/jordanknight/github/tools/CLAUDE.md | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/INSTALL.md | Modified | sdd-pipeline-skills | F003 |
| /Users/jordanknight/github/tools/README.md | Modified | sdd-pipeline-skills | F003 |
| /Users/jordanknight/github/tools/README_AGENTS.md | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/docs/skills-pipeline/README.md | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/scripts/migrate-skills.py | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/scripts/sync-to-dist.sh | Modified | sdd-pipeline-skills | F004 manifest coverage |
| /Users/jordanknight/github/tools/skills/SDD/code-concept-search-v2/SKILL.md | Modified | sdd-pipeline-skills | F003 / F004 |
| /Users/jordanknight/github/tools/skills/SDD/plan-0-v2-constitution/SKILL.md | Modified | sdd-pipeline-skills | F003 / F004 |
| /Users/jordanknight/github/tools/skills/SDD/plan-2b-v2-prep-issue/SKILL.md | Modified | sdd-pipeline-skills | F003 / F004 |
| /Users/jordanknight/github/tools/skills/SDD/util-0-v2-handover/SKILL.md | Modified | sdd-pipeline-skills | F004 |
| /Users/jordanknight/github/tools/skills/SDD/validate-v2/SKILL.md | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md | Modified | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/10-explore.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-specify.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/25-workshop.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/30-architect.md | New | sdd-pipeline-skills | F002 |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/35-adr.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/50-phase-tasks.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/60-implement.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/61-implement-companion.md | New | sdd-pipeline-skills | F001 |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/62-progress.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/70-review.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md | New | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-1a-v2-explore/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-1b-v3-specify-and-clarify/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-2-v2-clarify/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-2c-v2-workshop/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-3-v3-architect/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-3a-v2-adr/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-5-v2-phase-tasks-and-brief/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-6a-v2-update-progress/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-7-v2-code-review/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/skills/SDD/plan-8-v2-merge/SKILL.md | Deleted | sdd-pipeline-skills | None found |
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md | Plan artifact | plan artifact | F004 / F005 |
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-spec.md | Plan artifact | plan artifact | None found |
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/execution.log.md | Plan artifact | plan artifact | F005 |
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/original-ask.md | Plan artifact | plan artifact | None found |
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/.the-flow-state.json | Plan artifact | plan artifact | None found |
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/the-flow.json | Plan artifact | plan artifact | None found |
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/the-flow.md | Plan artifact | plan artifact | None found |

### Required Fixes

| # | File (absolute path) | What To Fix | Why |
|---|---------------------|-------------|-----|
| 1 | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/61-implement-companion.md | Remove stage-61 `plan-complete` firing and route final companion completion to `/the-flow 8 --plan <plan dir>`; keep next-phase route only when another phase remains. | Prevents premature/duplicate plan-complete harness seam before merge. |
| 2 | /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/30-architect.md | Branch READY next-step output by Mode. | Keeps Simple Mode direct-jump routing aligned with `00-routing.md`. |
| 3 | /Users/jordanknight/github/tools/README.md; /Users/jordanknight/github/tools/INSTALL.md; /Users/jordanknight/github/tools/skills/SDD/plan-2b-v2-prep-issue/SKILL.md; /Users/jordanknight/github/tools/skills/SDD/code-concept-search-v2/SKILL.md; /Users/jordanknight/github/tools/skills/SDD/plan-0-v2-constitution/SKILL.md | Replace active retired `/plan-*` references and stale counts. | Prevents users/agents from invoking deleted surfaces after the cutover. |
| 4 | /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md | Add manifest rows for changed files outside the current manifest or revert those edits. | Makes domain review reproducible and honest about the changed surface. |
| 5 | /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/execution.log.md | Add concrete command/output evidence for behavioural drive and summarized grep/deploy checks. | Raises Lightweight validation from asserted to reproducible. |

### Domain Artifacts to Update

| File (absolute path) | What's Missing |
|---------------------|----------------|
| /Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md | Domain Manifest rows for changed docs/scripts/utility skill files that were not in the original manifest. |

### Next Step

Run:

```bash
/the-flow 6 --plan "/Users/jordanknight/github/tools/docs/plans/030-flow-skill-consolidation/flow-skill-consolidation-plan.md"
```
