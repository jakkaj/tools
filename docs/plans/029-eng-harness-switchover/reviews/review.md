# Code Review: Simple Mode — eng-harness Switchover (plan 029)

**Plan**: /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/eng-harness-switchover-plan.md
**Spec**: /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/eng-harness-switchover-spec.md
**Phase**: Simple Mode (inline tasks T001–T014 from § Implementation)
**Date**: 2026-06-10
**Reviewer**: Automated (plan-7-v2)
**Testing Approach**: Lightweight (deterministic grep gates as Done-When)

## A) Verdict

**APPROVE WITH NOTES**

The switchover is correct, complete, and internally consistent. All 12 acceptance criteria were re-verified live against the working tree and pass. One MEDIUM placement/consistency defect (F001, plan-8 seam) is worth fixing but does **not** block: the behaviour is advisory/best-effort/never-blocks, a correct top-level `## Harness seam` section already describes the intent, and the rest of the change is clean.

**Key failure areas** (one sentence each):
- **Implementation**: One MEDIUM — plan-8's `--event plan-complete` directive lives inside the pre-merge `## Success Message` literal instead of the post-merge PROCEED branch (F001). Everything else clean.
- **Domain compliance**: N/A — no `docs/domains/` registry exists (registry creation is explicitly out of scope per spec); spec-level domains honoured.
- **Reinvention**: Clean — no SDD skill re-implements harness internals; no new local harness files created.
- **Testing**: Clean — every Done-When is a deterministic grep/script; all 12 ACs re-verified live this review.
- **Doctrine**: Clean — no `docs/project-rules/`; CLAUDE.md conventions honoured (AGENTS.md symlink untouched; `src/jk_tools/` mirror not hand-edited).

## B) Summary

This Simple-Mode change rewires the five surviving harness seams in the SDD pipeline to a single external router (`/eng-harness-flow --event <seam>`), deletes the four local `skills/harness/*` skills plus `docs/harness/_buffers/` and `scripts/compound-value.sh`, removes observe/sentinel/buffer machinery, and rewrites the-flow's story — landing as one user-executed commit (git is agent-read-only). Overall quality is high: the rewired skills consistently **delegate** rather than reimplement, the verbatim Layer-1 warning is byte-identical across all six source files (md5 `73d49f49…`), boot verdict vocabulary is correctly lowercase (`healthy / SLOW / UNHEALTHY / UNAVAILABLE`), and the minih retro-schema contract is preserved (description-strings-only diff; shape + `schema_version` byte-identical). Domain and doctrine checks are N/A by absence of registries, with the spec-level keep-list honoured (`docs/harness/agents/**` untouched). The single substantive finding is a seam-placement defect in plan-8 where the `plan-complete` firing instruction is embedded in user-facing output rather than the executable post-merge step.

## C) Checklist

**Testing Approach: Lightweight**

- [x] Core validation gates present — every task Done-When is a deterministic grep/script
- [x] Critical paths covered — all 12 ACs runnable as written and re-verified this review
- [x] Key verification points documented in execution.log.md (per-AC evidence table)

Universal (all approaches):
- [x] Only in-scope files changed (35 tracked files; all in the Domain Manifest)
- [x] JSON artifacts parse valid (4/4: 2 flight-plan + 2 schemas)
- [x] Slug-collision check clean (`check-skill-slugs.sh` → exit 0, 28 skills)
- [x] Domain compliance — N/A (no registry); spec-level keep-list honoured
- [ ] One MEDIUM seam-placement note (F001) — non-blocking

## D) Findings Table

| ID | Severity | File:Lines | Category | Summary | Recommendation |
|----|----------|------------|----------|---------|----------------|
| F001 | MEDIUM | skills/SDD/plan-8-v2-merge/SKILL.md:1021-1028 | seam / consistency | `--event plan-complete` directive sits inside the pre-merge `## Success Message` literal (printed at plan generation), not in the post-merge `## Next Steps` PROCEED branch; may fire at wrong time / not at all, and leaks agent-directive prose into emitted user output | Move the firing instruction into `## Next Steps` → "If user says PROCEED" as the final step after merge phases complete |
| F002 | LOW | src/jk_tools/scripts/compound-value.sh | scope / mirror | The auto-synced distribution mirror still carries `compound-value.sh` after the source `scripts/compound-value.sh` was deleted | Run `./scripts/sync-to-dist.sh` (or `./setup.sh`) before/with the commit so the mirror doesn't ship a stale copy; never hand-edit `src/jk_tools/` |

## E) Detailed Findings

### E.1) Implementation Quality

**F001 (MEDIUM) — plan-8 plan-complete seam is misplaced.**
`skills/SDD/plan-8-v2-merge/SKILL.md` lines 1021-1028 place the operational directive — *"After the merge executes (plan complete), fire the plan-complete harness seam … `/eng-harness-flow --event plan-complete --json` … and act on the envelope"* — **inside the `## Success Message` fenced literal block (lines 1007-1029)**. That block is the text emitted when the merge plan is *generated*, i.e. BEFORE the user types PROCEED and before any merge runs (the same block, line 1019, still says *"type PROCEED to execute"*). Meanwhile the actual post-merge execution path — `## Next Steps` → *"If user says PROCEED: 1. Execute merge plan phases in order …"* (lines 971-975) — contains **no** seam reference. Net effect: the seam is anchored to a moment that hasn't happened yet, the agent-directive prose + command get printed verbatim to the user as part of a success message, and the branch that actually runs after the merge never fires it.
*Mitigation (why MEDIUM, not HIGH):* a correct top-level `## Harness seam (router-only)` section (lines 1043-1045) states the seam fires "after the merge executes" via the router; the whole behaviour is advisory/best-effort/never-blocks and skips silently when the router is absent, so a misfire degrades gracefully.
*Fix:* relocate the firing instruction to the PROCEED branch in `## Next Steps` as the final post-merge step; keep at most a brief user-facing line (no agent directive) in the success message.

**F002 (LOW) — stale mirror copy of a deleted script.**
`scripts/compound-value.sh` was correctly deleted, but the auto-synced distribution mirror `src/jk_tools/scripts/compound-value.sh` still exists (`scripts/` is mirrored into `src/jk_tools/`). Per CLAUDE.md the mirror is regenerated by `scripts/sync-to-dist.sh` / `./setup.sh` and must never be hand-edited. Already noted by the implementer ("out of scope, self-healing"). If the commit lands before a sync, the tree ships a stale mirror copy; running the sync first avoids that.

Verdict-vocabulary, warning-copy, seam flags, dangling-references, JSON-validity, and step-cross-reference checks are all **clean** (see E.5 and Coverage Map).

### E.2) Domain Compliance

No `docs/domains/` registry exists; the spec explicitly scopes registry creation out (§ Target Domains) and declares spec-level domains. Domain checks are therefore N/A by absence; the spec-level keep-list and one-way `sdd-pipeline → /eng-harness-flow` rule were verified instead.

| Check | Status | Details |
|-------|--------|---------|
| File placement | N/A | No registry; all changed files are within the manifest's declared trees |
| Contract-only imports | ✅ | SDD calls only the public `/eng-harness-flow` router; zero child-slug references in live files |
| Dependency direction | ✅ | One-way `sdd-pipeline → /eng-harness-flow`; harness never calls SDD |
| Domain.md updated | N/A | No domain registry |
| Registry current | N/A | No `docs/domains/registry.md` |
| No orphan files | ✅ | Every changed file maps to a Domain Manifest row |
| Map nodes current | N/A | No `docs/domains/domain-map.md` |
| Map edges current | N/A | No domain map |
| No circular business deps | ✅ | Single external dependency edge; no cycles |
| Concepts documented | N/A | No registry; seam contract documented in spec sketch + getting-started.md |

### E.3) Anti-Reinvention

| New Component | Existing Match? | Domain | Status |
|--------------|----------------|--------|--------|
| (none) | N/A | — | proceed — change is net-removal; no new local harness files created |

Confirmed by the delegation/contract reviewer: no SDD skill re-implements boot/observe/drain-harvest/retro-JSON/`.retro.md`/`.harness/` work; everything delegates to the router. `the-flow` only *narrates* the `[s/t/p/e/d/a]` drain prompt to explain what the user already saw (allowed by the seam contract).

### E.4) Testing & Evidence

**Coverage confidence**: 96%

| AC | Confidence | Evidence (re-verified this review) |
|----|------------|-----------------------------------|
| AC1 Router-only | 100 | Slug grep → exactly 2 whitelisted lines (CLAUDE.md:60 freeze-audit, MIGRATION.md:54 cleanup); zero `eng-harness-[0-9]` child slugs in live files |
| AC2 Seams | 95 | `grep -rln eng-harness-flow skills/SDD/` → 15 files (10 plan-* + the-flow SKILL + 4 references); F001 flags placement of plan-8's seam |
| AC3 Observe gone | 100 | `grep -rni "harness observe\|harness-3-observe\|silently call" skills/SDD/` → 0 |
| AC4 Sentinel gone | 100 | `grep -rn "\.disabled"` over full live surface → 0 |
| AC5 Templates emit router syntax | 100 | plan-3 `--event` ×5; plan-5 `--event` ×3 |
| AC6 Deletion clean | 100 | `skills/harness/`, `_buffers/`, `compound-value.sh` gone; `check-skill-slugs.sh` → exit 0 / 28 skills |
| AC7 No-router detection | 90 | Pre-install probe MISS logged (T001); warning copy byte-identical (md5 `73d49f49…`) across 6 sources; full no-router run deliberately not staged (recorded decision — reviewed inferentially) |
| AC8 Router detection | 95 | T002 envelope `decision: redirect`, `missing_rung: S2-governance`; router smoke is read-only |
| AC9 the-flow updated | 100 | No `/harness-N` alias rows; no `docs/compound`; getting-started rewritten; JSON valid |
| AC10 Docs truthful | 100 | Override #2 present in CLAUDE.md; README ownership inverted (line 84); 024/027 forward-pointers additive-only (4 insertions, 0 deletions) |
| AC11 Deploy hygiene | 95 | No bare local `harness-N` slugs in either store; hits are the legitimately-external `eng-harness-*` family (T001); router resolves via the documented `~/.claude` fallback |
| AC12 Contracts preserved | 100 | Schema diff description-strings-only; `$id`/`schema_version`/shape byte-identical; `docs/harness/agents/**` untouched |

### E.5) Doctrine Compliance

No `docs/project-rules/` directory → no rules/idioms/architecture/constitution to validate against (N/A, not a failure). CLAUDE.md (the de-facto contributor guide) conventions were checked and honoured:
- **AGENTS.md symlink**: still `AGENTS.md -> CLAUDE.md`, not separately modified (convention: edit CLAUDE.md, never AGENTS.md). ✅
- **`src/jk_tools/` mirror**: not hand-edited (the stale `compound-value.sh` is F002, a sync artifact, not a manual edit). ✅
- **Git read-only**: working tree left uncommitted for the user to commit. ✅

## F) Coverage Map

| AC | Description | Evidence | Confidence |
|----|-------------|----------|------------|
| AC1–AC12 | See § E.4 | Live grep/script re-runs + execution.log.md | 90–100% |

**Overall coverage confidence**: 96%

## G) Commands Executed

```bash
git status; git --no-pager diff --stat
git --no-pager diff > docs/plans/029-eng-harness-switchover/reviews/_computed.diff
ls docs/domains docs/project-rules docs/adr 2>/dev/null
# AC1
grep -rn "harness-1-boot\|harness-2-backpressure\|harness-3-observe\|harness-4-retro" skills/ justfile scripts/ CLAUDE.md README*.md INSTALL.md MIGRATION.md docs/skills-pipeline/ docs/harness/
grep -rn "eng-harness-[0-9]" skills/ justfile scripts/ CLAUDE.md README*.md INSTALL.md MIGRATION.md docs/skills-pipeline/ docs/harness/
# AC2/AC3/AC4/AC5
grep -rln "eng-harness-flow" skills/SDD/
grep -rni "harness observe\|harness-3-observe\|silently call" skills/SDD/
grep -rn "\.disabled" skills/ justfile scripts/ CLAUDE.md README*.md INSTALL.md MIGRATION.md docs/skills-pipeline/ docs/harness/README.md
grep -c "eng-harness-flow --event" skills/SDD/plan-3-v3-architect/SKILL.md skills/SDD/plan-5-v2-phase-tasks-and-brief/SKILL.md
# AC6
bash scripts/check-skill-slugs.sh
# AC7 warning copy byte-identity
for f in <6 source files>; do grep -o "No engineering harness detected…" "$f" | md5; done
# AC11 stores
ls ~/.agents/skills ~/.claude/skills | grep -E "^harness-[0-9]"
test -f ~/.agents/skills/eng-harness-flow/SKILL.md; test -f ~/.claude/skills/eng-harness-flow/SKILL.md
# AC12 schema + keep-list
git --no-pager diff docs/harness/schemas/
git --no-pager diff --stat docs/harness/agents/
# JSON validity
python3 -m json.tool <flight-plan + schema json> >/dev/null
# Doctrine
ls -la AGENTS.md; git --no-pager diff --stat AGENTS.md
```

## H) Handover Brief

> Copy this section to the implementing agent. It has no context on the review —
> only context on the work that was done before the review.

**Review result**: APPROVE WITH NOTES

**Plan**: /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/eng-harness-switchover-plan.md
**Spec**: /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/eng-harness-switchover-spec.md
**Phase**: Simple Mode (inline tasks T001–T014)
**Tasks dossier**: inline in plan (§ Implementation)
**Execution log**: /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/execution.log.md
**Review file**: /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/reviews/review.md
**Computed diff**: /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/reviews/_computed.diff

### Files Reviewed (selected; 35 tracked files changed total)

| File (absolute path) | Status | Domain | Action Needed |
|---------------------|--------|--------|---------------|
| /Users/jordanknight/github/tools/skills/SDD/plan-8-v2-merge/SKILL.md | modified | sdd-pipeline | F001 — relocate plan-complete seam (MEDIUM, non-blocking) |
| /Users/jordanknight/github/tools/src/jk_tools/scripts/compound-value.sh | stale mirror | sdd-pipeline | F002 — run sync-to-dist before commit (LOW) |
| /Users/jordanknight/github/tools/skills/SDD/plan-1a-v2-explore/SKILL.md | modified | sdd-pipeline | none — clean |
| /Users/jordanknight/github/tools/skills/SDD/plan-1b-v3-specify-and-clarify/SKILL.md | modified | sdd-pipeline | none — clean |
| /Users/jordanknight/github/tools/skills/SDD/plan-2c-v2-workshop/SKILL.md | modified | sdd-pipeline | none — clean |
| /Users/jordanknight/github/tools/skills/SDD/plan-3-v3-architect/SKILL.md | modified | sdd-pipeline | none — clean (emits router syntax ×5) |
| /Users/jordanknight/github/tools/skills/SDD/plan-5-v2-phase-tasks-and-brief/SKILL.md | modified | sdd-pipeline | none — clean (emits router syntax ×3) |
| /Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase/SKILL.md | modified | sdd-pipeline | none — clean (verdicts lowercase) |
| /Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md | modified | sdd-pipeline | none — clean |
| /Users/jordanknight/github/tools/skills/SDD/plan-6a-v2-update-progress/SKILL.md | modified | sdd-pipeline | none — retro duty retired cleanly |
| /Users/jordanknight/github/tools/skills/SDD/plan-7-v2-code-review/SKILL.md | modified | sdd-pipeline | none — 5 subagents consistent |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md | modified | sdd-pipeline | none — clean |
| /Users/jordanknight/github/tools/skills/SDD/the-flow/references/{getting-started.md,flight-plan.schema.json,flight-plan.template.json,flight-plan.template.md} | modified | sdd-pipeline / harness-seam | none — JSON valid; warning copy verbatim |
| /Users/jordanknight/github/tools/docs/harness/schemas/{retro,system.compound}.schema.json | modified | harness-seam | none — description-strings-only; contract preserved |
| /Users/jordanknight/github/tools/{CLAUDE,README,README_AGENTS,INSTALL,MIGRATION}.md, docs/skills-pipeline/README.md, docs/harness/README.md | modified | sdd-pipeline | none — clean (Override #2, ownership inverted) |
| /Users/jordanknight/github/tools/{skills/harness/**, docs/harness/_buffers/**, scripts/compound-value.sh} | deleted | sdd-pipeline (legacy) | none — deletion verified |
| /Users/jordanknight/github/tools/docs/plans/{024,027}-*/*-plan.md | modified | sdd-pipeline | none — additive forward-pointers only |

### Recommended Fixes (non-blocking — APPROVE WITH NOTES)

| # | File (absolute path) | What To Fix | Why |
|---|---------------------|-------------|-----|
| 1 | /Users/jordanknight/github/tools/skills/SDD/plan-8-v2-merge/SKILL.md:1021-1028 | Move the `/eng-harness-flow --event plan-complete --json` firing instruction out of the `## Success Message` literal and into `## Next Steps` → "If user says PROCEED" as the final post-merge step (lines 971-975). Keep at most a brief non-directive line in the success message. | The seam must fire AFTER the merge executes, not be printed to the user at plan-generation time; the executable PROCEED branch currently never fires it (F001) |
| 2 | /Users/jordanknight/github/tools/src/jk_tools/scripts/compound-value.sh | Run `./scripts/sync-to-dist.sh` (or `./setup.sh`) so the auto-synced mirror drops the deleted script; do not hand-edit `src/jk_tools/` | Avoid committing a stale mirror copy of a deleted source script (F002) |

### Domain Artifacts to Update (if any)

None — no `docs/domains/` registry exists (out of scope per spec). Spec-level keep-list verified intact.

### Next Step

This is the final phase of a Simple-Mode plan. The two findings are non-blocking; the user may either:
- **Address F001 then commit** (recommended): `/plan-6-v2-implement-phase --plan /Users/jordanknight/github/tools/docs/plans/029-eng-harness-switchover/eng-harness-switchover-plan.md` (apply the plan-8 seam relocation + run sync-to-dist), then re-run `/plan-7-v2-code-review` for a clean APPROVE; or
- **Accept the notes and commit now** — behaviour is advisory/best-effort and degrades gracefully. Run `./scripts/sync-to-dist.sh` first (F002), then execute the single commit per execution.log.md's suggested message (git is agent-read-only — the user commits).
