# Code Review: Simple Mode — the-flow Ship Stage (plan 035)

**Plan**: `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/flow-ship-stage-plan.md`
**Spec**: `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/flow-ship-stage-plan.md` § `## Business Specification` (unified plan)
**Phase**: Simple Mode (single cohesive change, inline tasks T001–T010)
**Date**: 2026-06-19
**Reviewer**: Automated (the review verb)
**Testing Approach**: Lightweight (`just check-flow` + scratch smoke + eyeball)

## A) Verdict

**APPROVE**

Zero HIGH/CRITICAL findings. The change is coherent across all 10 touched surfaces, the deterministic linter passes, and the acceptance criteria are covered (structural ACs deterministically; runtime-behavior ACs by prose inspection, which is proportionate for a skill-prose change). Two **LOW** advisories below are optional polish — neither blocks.

**Key failure areas**: none blocking.
- **Implementation**: one LOW robustness nit — the "commits-ahead" probe resolves a *local* base ref where a sibling probe uses `origin/<base>` (narrow edge; primary guard already safe).
- **Domain compliance**: N/A — no `docs/domains/` registry in this skills repo (plan G7 N/A by design).
- **Reinvention**: clean — `ship` (outbound PR) and the demoted `reconcile` (inbound divergence) are a clean split; no duplication.
- **Testing**: AC-05 / AC-06 (bounded CI-watch, `gh`-absent degradation) are prose-verified only — inherent to Lightweight skill prose, recorded as a LOW note.
- **Doctrine**: N/A — no `docs/project-rules/` in this repo.

## B) Summary

Plan 035 replaces the-flow's terminal stage (`8 merge`) with a new outbound **`ship`** verb (push → open PR with repo guidance → watch CI checks → report) and demotes the existing upstream-reconcile machinery to a conditional **`8c reconcile`** excursion. The change spans one new sub-skill (`80-ship.md`) plus nine modified flow surfaces (Registry/SKILL.md, Graph/00-routing.md, schema, both templates, harness-seams, coach, getting-started, flight-plan-ops, and the demoted 80-merge.md). All surfaces were independently verified to agree on ship-as-terminal + reconcile-as-excursion; the flow-architecture linter (`just check-flow skills/SDD/the-flow`) passes clean (L1–L6, exit 0), which deterministically confirms the Registry↔Graph↔alias closure. Domain and doctrine compliance are N/A by absence of registries (a skills repo). Anti-reinvention is clean — the reconcile machinery is preserved intact and still reachable, and `ship` delegates to it on base divergence rather than re-implementing merge logic. Testing follows the declared Lightweight strategy; the structural ACs are deterministically verified, while the runtime-behavior ACs (gh/CI/confirm-gate paths) are verified by prose inspection because they cannot be exercised without a real branch+PR+CI (explicitly out of scope, no mocks).

## C) Checklist

**Testing Approach: Lightweight**

- [x] Core validation present — `just check-flow skills/SDD/the-flow` passes (L1–L6, exit 0), re-run independently during this review
- [x] Critical paths covered — flow-architecture closure (Registry/Graph/alias), schema validity, rail-renders-ship smoke (logged), legacy-merge-terminal render (logged, AC-11)
- [x] Key verification points documented — execution.log.md T010 records check-flow output, redeploy, and the smoke rail string

Universal (all approaches):
- [x] Only in-scope files changed — all under `skills/SDD/the-flow/` (+ plan-folder artifacts); no scope creep into `minih`/harness child skills/other domains
- [x] Linters/type checks clean — `check-flow` exit 0; schema JSON valid
- [N/A] Domain compliance checks — no `docs/domains/` registry (skills repo)

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| F001 | LOW | `skills/SDD/the-flow/references/stages/80-ship.md:59` | correctness | "commits-ahead" probe uses local `${BASE}..HEAD` while the divergence probe (line 140) uses `origin/${BASE}`; on a shallow/partial clone or stale local base ref the count can error (non-zero exit, empty output) so the `is 0` guard silently fails to fire | Use `origin/${BASE}..HEAD` for consistency, and/or treat a non-zero `rev-list` exit as "cannot determine → stop the PR path" |
| F002 | LOW | `docs/plans/035-flow-ship-stage/flow-ship-stage-plan.md` § Acceptance Coverage Map | testing | AC-05 (bounded CI-watch) and AC-06 (`gh`-absent / PR-exists / no-remote / detached-HEAD degradation) are marked "covered" but are prose/inspection-verified only — not exercised by the linter or the (cleaned-up) smoke | Annotate these as prose-verified, or add a reproducible scratch case exercising bounded-watch + a degradation branch |

## E) Detailed Findings

### E.1) Implementation Quality

**F001 (LOW, correctness/robustness)** — `80-ship.md:59`.
The nothing-to-ship guard computes commits-ahead as `git rev-list --count ${BASE}..HEAD`, where `${BASE}` is resolved in step 1 from `gh repo view --json defaultBranchRef` (the *remote* default branch *name*, e.g. `main`). That makes line 59 read a **local** ref, while the divergence probe at line 140 correctly reads the **remote** ref (`git rev-list --count HEAD..origin/${BASE}`). On a fresh full clone the local base ref exists and the guard works; on a shallow/partial clone, or when the local base is absent/stale, `rev-list` errors (non-zero exit + empty output rather than the literal `0`), so the "0 commits ahead → stop" branch does not fire. The documented main-only reality is still safe because the `BRANCH == BASE` guard (line 58) fires first and prevents a head==base PR. The only residual edge is a *feature* branch with 0 commits ahead **and** a missing/stale local base ref, where step 5 could reach `gh pr create` and hit gh's own graceful "No commits between …" refusal — a narrow, non-crashing miss against AC-10's "never errors out of `gh pr create`". Hence LOW. Recommendation: switch line 59 to `origin/${BASE}..HEAD` (matching line 140), and/or treat a non-zero `rev-list` exit as "cannot determine → stop the PR path".

No other implementation issues. The git/gh commands are otherwise correct; the degradation branches (no-remote, gh-absent, dirty-tree, PR-already-exists, no-checks, pending-at-cap) are sound and non-contradictory; the bounded watch is genuinely bounded (`timeout ${cap}m` or a capped polling loop with explicit no-checks and still-pending exits); the confirm gates are separate (push = confirm #1, PR-open = confirm #2 which "NEVER inherits the push 'yes'", merge = typed `PROCEED`); and the sub-skill contract block + Exit line are well-formed, harness-blind, and free of flow-command literals (verified by `check-flow` L1/L2).

### E.2) Domain Compliance

No `docs/domains/` registry, `domain-map.md`, or domain manifest exists in this repository (it is a skills repo). Per the plan, the formal domain system is **N/A by absence of a registry** (G7 N/A). The plan's own "Domain Manifest" is a file→the-flow-skill mapping for traceability, not a registered-domain contract — every changed file maps to the `the-flow` skill as intended, with no orphans.

| Check | Status | Details |
|-------|--------|---------|
| File placement | N/A | No domain registry; all files under `skills/SDD/the-flow/` |
| Contract-only imports | N/A | Skill prose, no code imports |
| Dependency direction | N/A | No domain graph |
| Domain.md updated | N/A | No `docs/domains/` |
| Registry current | N/A | No `docs/domains/registry.md` |
| No orphan files | ✅ | Every changed file is in the plan's Domain Manifest (the-flow) |
| Map nodes current | N/A | No `docs/domains/domain-map.md` |
| Map edges current | N/A | No domain map |
| No circular business deps | N/A | No domain map |
| Concepts documented | N/A | No domain contracts |

### E.3) Anti-Reinvention

Clean split — no genuine duplication.

| New Component | Existing Match? | Location | Status |
|--------------|----------------|----------|--------|
| `ship` verb (outbound: push + PR + watch checks) | None | — | proceed |
| `ship` base-divergence handling | Delegates to | `80-merge.md` (reconcile excursion) | proceed — hands off, does not re-implement |
| `reconcile` (demoted `merge`) | Retained intact | `80-merge.md` | proceed — distinct inbound purpose, still reachable via `8c` |

`ship` is purely outbound and explicitly hands off to the reconcile excursion on a meaningfully diverged base (`80-ship.md` step 7) rather than re-implementing the upstream conflict/regression analysis. The demoted `80-merge.md` retains its subagent machinery (U1/Y1/C1/C2/R1/S1 + merge-plan doc) and is reachable as `8c reconcile`, so it is not dead code. No other stage sub-skill performs push/PR/CI-watch.

### E.4) Testing & Evidence

**Coverage confidence**: ~88% (structural ACs deterministic; runtime ACs prose-verified — proportionate for Lightweight skill prose).

| AC | Confidence | Evidence |
|----|------------|----------|
| AC-01 ship contract well-formed | 92 | `80-ship.md` has full contract + Exit; `check-flow` L1/L2 pass |
| AC-02 Registry/aliases/journey | 95 | Both Registry rows present (SKILL.md:43–44); aliases→`8c reconcile` (76–77); journey "→ review → ship"; `check-flow` L4 closure passes |
| AC-03 repo-guidance read + default | 68 | Prose inspection (`80-ship.md` step 3); no PR template in repo → default path documented; not live-exercised |
| AC-04 separate confirms / PROCEED | 80 | Inspection: push=#1, PR=#2 ("never inherits"), merge=typed PROCEED; invariant #2 reworded |
| AC-05 bounded CI-watch | 50 | Prose only — bound + no-checks + pending-at-cap paths present, not exercised (F002) |
| AC-06 gh-absent / PR-exists / no-remote degradation | 50 | Prose only — branches present, not exercised (F002) |
| AC-07 reconcile retains machinery | 90 | `80-merge.md` machinery intact, verb=`reconcile`, conditional excursion |
| AC-08 schema nodeType + seam remap | 90 | `ship` in nodeTypes; post-flight rides `branch_of:"ship"` (harness-seams.md:48); no-bump justified (110) |
| AC-09 check-flow + redeploy + smoke | 96 | `check-flow` exit 0 re-verified now; redeploy logged; smoke rail ends at Ship |
| AC-10 on-default-branch degradation | 78 | Inspection + main-only reality; `BRANCH==BASE` guard before any `gh pr create`; see F001 for the narrow residual edge |
| AC-11 legacy merge-terminal renders | 90 | `merge` nodeType retained; logged legacy render "rail ends at Merge" |

Approach followed: yes (Lightweight = check-flow + smoke + eyeball, no mocks). Out-of-scope discoveries are correctly scoped: D3 (`.the-flow-state.json` hand-write determinism) is a declared Non-Goal; D2 (upstream renderer ship-banding caveat, mitigated by `--zone postflight`) and D4 (`add-node` forward-ref) are follow-ups, not defects of this change.

### E.5) Doctrine Compliance

N/A — no `docs/project-rules/` (rules.md / idioms.md / architecture.md / constitution.md) exists in this repository. The applicable doctrine is the **flow-architecture pattern**, which is enforced deterministically by `scripts/check-flow-architecture.sh` (passes clean, exit 0) rather than by a project-rules file. The contributor guide (CLAUDE.md) conventions for editing the flow — edit the sub-skill for stage behaviour, the Graph for routing, the grammar line for the command surface, and lint with `just check-flow` — were all honored.

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC-01 | `ship` sub-skill with standard contract, harness-blind | `80-ship.md` + check-flow L1/L2 | 92 |
| AC-02 | Registry `8 ship` + `8c reconcile`; aliases; journey | SKILL.md:43–44,76–77 + check-flow L4 | 95 |
| AC-03 | Reads repo PR guidance, degrades to defaults | `80-ship.md` step 3 (inspection) | 68 |
| AC-04 | Separate push/PR confirms; merge typed-PROCEED | `80-ship.md` steps 4,5,7 (inspection) | 80 |
| AC-05 | Bounded CI-watch + no-checks + pending paths | `80-ship.md` step 6 (inspection) | 50 |
| AC-06 | Degrades for gh-absent / PR-exists / no-remote | `80-ship.md` step 2 (inspection) | 50 |
| AC-07 | Reconcile excursion retains machinery | `80-merge.md` (inspection) | 90 |
| AC-08 | Schema `ship` nodeType + post-flight seam remap | schema:18 + harness-seams.md:48,110 | 90 |
| AC-09 | check-flow + getting-started/templates/coach + smoke | check-flow exit 0 (re-verified) + log | 96 |
| AC-10 | On-default-branch degradation | `80-ship.md` step 2a + guard (see F001) | 78 |
| AC-11 | Legacy merge-terminal still renders | schema retains `merge`; logged render | 90 |

**Overall coverage confidence**: ~88%

## G) Commands Executed

```bash
# Mode/artifact resolution + diff gathering
git branch --show-current
git status --porcelain
git --no-pager diff --stat ; git --no-pager diff --staged --stat
git --no-pager log --oneline -12
mkdir -p docs/plans/035-flow-ship-stage/reviews
git --no-pager diff -- skills/SDD/the-flow/ > reviews/_computed.diff
git --no-pager diff --no-index -- /dev/null skills/SDD/the-flow/references/stages/80-ship.md  # untracked new file

# Registry / doctrine presence
ls -la docs/domains        # → absent (N/A)
ls -la docs/project-rules  # → absent (N/A)

# Deterministic check (AC-09) — re-verified during review
just check-flow skills/SDD/the-flow   # → exit 0, L1–L6 clean

# Ground-verification of cross-surface coherence
grep -nE '^\| 8c? ' skills/SDD/the-flow/SKILL.md
grep -nE 'reconcile|plan-8-v2-merge|typed .merge' skills/SDD/the-flow/SKILL.md
grep -nE 'ship|merge|nodeType' skills/SDD/the-flow/references/flight-plan.schema.json
grep -nE 'branch_of|ship|post-flight' skills/SDD/the-flow/references/harness-seams.md
sed -n '58,59p;140p' skills/SDD/the-flow/references/stages/80-ship.md
```

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review —
> only context on the work that was done before the review.

**Review result**: APPROVE

**Plan**: `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/flow-ship-stage-plan.md`
**Spec**: `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/flow-ship-stage-plan.md` § `## Business Specification`
**Phase**: Simple Mode
**Tasks dossier**: inline in plan (§ Implementation → Tasks, T001–T010)
**Execution log**: `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/execution.log.md`
**Review file**: `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/reviews/review.md`
**Computed diff**: `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/reviews/_computed.diff`

### Files Reviewed

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-ship.md` | created | the-flow | Optional: F001 (line 59 local→`origin/` base ref) |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-merge.md` | modified (demoted→reconcile) | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md` | modified | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md` | modified | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json` | modified | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md` | modified | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json` | modified | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md` | modified (regenerated) | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md` | modified | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md` | modified (regenerated view) | the-flow | None |
| `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan-ops.md` | modified | the-flow | None |

### Required Fixes (if REQUEST_CHANGES)

None — verdict is APPROVE. The two LOW advisories below are optional and non-blocking.

| # | File (absolute path) | What To Fix | Why |
|---|---------------------|-------------|-----|
| (opt) F001 | `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/80-ship.md:59` | Use `origin/${BASE}..HEAD` (match line 140) and/or treat non-zero `rev-list` exit as "stop the PR path" | Robustness on shallow/partial clones; tightens AC-10's "never errors out of gh pr create" for one narrow edge |
| (opt) F002 | `/Users/jordanknight/github/tools/docs/plans/035-flow-ship-stage/flow-ship-stage-plan.md` (Coverage Map) | Annotate AC-05/AC-06 as prose-verified, or add a scratch case exercising bounded-watch + a degradation branch | Honest evidence labelling for the runtime-behavior ACs |

### Domain Artifacts to Update (if any)

None — no `docs/domains/` registry exists in this repo (N/A).

### Handback

APPROVE, final phase (Simple Mode, single phase): Implementation complete — consider committing. The two LOW advisories are optional polish and need not block a commit/ship.
