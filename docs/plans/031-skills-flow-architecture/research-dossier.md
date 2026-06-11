# Research Report: Composable skills-flow architecture (the-flow restructure)

**Generated**: 2026-06-12
**Research Query**: "how the-flow is structured today — where flow knowledge leaks into stage modules, what the composable architecture must touch"
**Mode**: Pre-Plan (feeds `031-skills-flow-architecture` spec)
**Location**: `docs/plans/031-skills-flow-architecture/research-dossier.md`
**FlowSpace**: Not used (corpus is markdown skill files — standard tools; FlowSpace indexes code graphs)
**Findings**: 78 across 8 subagents (IA×10, DC×10, PS×10, QT×10, IC×10, DE×10, PL×15, DB×8), deduplicated below
**Harness**: `/eng-harness-flow` router installed; this repo is not provisioned (no `.harness/`, no governance doc) → session-start seam noops; later seam calls pass `--prompt-optional=false`. Standard testing applies.
**Authoritative input**: `workshops/001-composable-skill-flows.md` — decisions D1–D7, ruleset R1–R8, lints L1–L6, migration phases A–E are settled; this dossier grounds them in evidence, it does not re-decide them.

---

## Executive Summary

### What It Is
`skills/SDD/the-flow/` is one public skill: a dispatch `SKILL.md` (~83 lines) + lazily-loaded references (`00-routing.md` = guided engine, `coach.md` = voice, `getting-started.md` = view, 3 flight-plan files = journey contract, 11 stage modules under `stages/`). Two load paths: guided (dispatch + routing + coach + ONE stage) and direct jump (ONE stage only). Created by plan-030's atomic 13→1 consolidation (2026-06-11, rollback tag `pre-flow-consolidation`).

### The Problem (verified)
**Exactly 147 cross-stage references** sit inside the 11 stage modules (workshop's claim independently re-measured: 123 `/the-flow <id>` command strings + 61 sibling-module path refs + 11 "Next routing" headers, overlapping to 147 grep hits). Every flow edge is encoded in **5 places** (stage "Next routing" header, stage trailing next-step prose, 00-routing routing table, coach narration script, getting-started view). Measured cost: the `<id> <name>` grammar change (`b26bce2`) touched **308 strings / 249 lines / 20 files**. The leak is *prescribed*, not accidental: the v1 migration guide's step template (`scratch/paste/20260611T080711.md` ~line 259) mandates a "Next routing instruction" section.

### Key Insights
1. **Four of the five workshop layers already exist — they're just smeared.** The routing table (`00-routing.md:115–131`) IS the Graph; the SKILL.md stage table IS the Registry (duplicated in 3 places); coach.md IS the Presentation (with ~56 hardcoded commands instead of slots); flight-plan template/schema already prove the source-of-truth/rendered-view pattern. Phase B/C is consolidation of existing structure, not invention.
2. **The D7 fold is cheap and safe.** `60-implement.md` vs `61-implement-companion.md`: ~49% verbatim duplicate; the genuinely companion-specific ~51% (minih boot, briefing, ping/debrief protocol) is self-contained. `62-progress.md` is already module-agnostic (debrief triggers on `--companion-run-id`, not on caller identity) — it needs **no changes**. Blast radius: 159 companion refs total (56 inside stage 61 itself, 103 across 6 other files).
3. **Lints split cleanly by feasibility.** L1/L2/L3/L6 are stdlib-checkable today; L4 (closure) needs the formal Graph/Registry tables Phase B creates; L5 (view freshness) needs banner convention + render step (Phase D). L4's *content* already passes — the artifact produce/consume map is closed, no orphans.
4. **The public surface is load-bearing and must not move**: the `/the-flow <id> <name>` grammar, the old-slug translation table (3 live flows' state files depend on it: 027, 028, 029), and the 5 harness-seam invocations (1:1 multiset, per plan-030 AC11). Everything internal — module filenames, table layout, coach slots — is free to restructure.

### Quick Stats
- **Components**: 19 files in the skill (1 dispatch + 4 reference docs + 3 flight-plan files + 11 stage modules)
- **Leak baseline**: 147 refs (lint L1 target: 0) · companion fold blast radius: 159 refs / 7 files
- **Churn hot spots**: SKILL.md (15 commits), flight-plan files (17 combined), stage modules (2 each)
- **Host limits**: all 15 repo skills pass L6; the-flow's description = 971/1024 chars (tightest)
- **Prior Learnings**: 15 surfaced (plans 024/029/030 heaviest)
- **Domains**: no registry in repo — the skill folder is the boundary

---

## How It Currently Works — the five layers mapped to today's files

```
VIEWS        getting-started.md ......... stage table (copy #3), hand-drawn mermaid, command examples
             flight-plan.template.md .... ✅ already banner-marked "generated from JSON"
PRESENTATION coach.md ................... rail, narration scripts — ~56 hardcoded /the-flow commands (no slots)
             SKILL.md description ....... grammar restated (971 chars)
COMPOSITION  00-routing.md:99–131 ....... stage machine + 7-column routing table = the de-facto Graph
             flight-plan.schema.json .... journey contract (13 node types; companion = agents[], NOT a node type)
REGISTRY     SKILL.md:29–43 stage table . copy #1 (canonical-ish)
             00-routing.md table ........ copy #2 (mixed with Graph concerns)
             getting-started.md:22–34 ... copy #3 (unmarked view)
STAGES       references/stages/*.md ..... 11 modules — ALL carry "Next routing" headers + trailing
             (10,20,25,30,35,50,60,61,62,70,80)   next-step prose = the 147-ref leak (violates R1/R5)
```

**Load paths** (must survive unchanged): guided reads dispatch + 00-routing + coach + one stage and is the ONLY writer of `.the-flow-state.json` / `the-flow.json` / `the-flow.md`; direct jump reads one stage module, writes stage artifacts only; next guided run catches state up by artifact existence (idempotency). [IA-05, IA-06, PL-15]

**File naming couples id to module**: `10-explore.md`, `30-architect.md` … the numeric prefix appears in filename + registry id + typed command, so all three change in sync today. Workshop D2/R8: ids are flow property → verb-named files (`explore.md`) with the Registry as the only id↔verb↔file binding. [IA-08]

## The Leak, Verified (lint L1 baseline)

Reproducible census (this command becomes L1 in `check-flow-architecture.sh`):

```bash
for f in skills/SDD/the-flow/references/stages/*.md; do
  grep -cE '/the-flow [0-9]|stage [0-9]+[a-z]?|references/stages/[0-9]|## Next routing|## Next step' "$f"
done
```

| Stage file | Total | Commands | Sibling paths | Next-routing hdr |
|---|---|---|---|---|
| 10-explore.md | 23 | 20 | 5 | 1 |
| 20-specify.md | 12 | 11 | 4 | 1 |
| 25-workshop.md | 18 | 15 | 4 | 1 |
| 30-architect.md | 18 | 18 | 12 | 1 |
| 35-adr.md | 7 | 7 | 6 | 1 |
| 50-phase-tasks.md | 20 | 20 | 4 | 1 |
| 60-implement.md | 8 | 5 | 6 | 1 |
| 61-implement-companion.md | 21 | 13 | 9 | 1 |
| 62-progress.md | 7 | 5 | 3 | 1 |
| 70-review.md | 10 | 6 | 6 | 1 |
| 80-merge.md | 3 | 3 | 2 | 1 |
| **Total** | **147** | **123** | **61** | **11** |

**One edge, five homes** (spec→architect): `20-specify.md:8` (Next routing) · `30-architect.md:8` (mirror) · `00-routing.md:104,123` (machine + table) · `coach.md:137–145` (awaiting-1b script) · SKILL.md stage table. Same pattern for every edge → the 308-string cost of `b26bce2`. [DC-05, DE-02]

## Contracts Inventory

### Stage headers today vs the firm template (L2 baseline: 0/11 pass)
All 11 modules carry **Purpose / Entry conditions / Inputs / Output contract / Next routing** as prose. **None** carries the firm template's `**Verb** / **Consumes** / **Produces** / **Flags** / **Side effects**` contract block. Side-effects are scattered: stage 30 auto-runs `/validate-v2` (undeclared), 35 writes domain backlinks (undeclared), 60/61/80 fire harness seams (declared in-procedure), 62's debrief is conditional on `--companion-run-id` (declared). One deviation: 80-merge.md repeats **Purpose** 3×. [IC-01, IC-03; note: one subagent's table claimed "Next routing: NO" — overruled by direct grep evidence, all 11 have it]

### Artifact interface (L4 content already closed — no orphans)
```
research-dossier.md      ← explore     → specify, workshop, architect (optional)
<slug>-spec.md           ← specify     → workshop, architect, adr (required)
workshops/*.md           ← workshop    → architect (authoritative, optional read)
backpressure-coverage.md ← /eng-harness-flow post-spec (external) → architect (optional)
<slug>-plan.md           ← architect   → adr, tasks, implement, review, merge
docs/adr/*.md            ← adr         → architect (G4 gate), tasks
tasks/<phase>/tasks.md   ← tasks       → implement, review
execution.log.md         ← implement   → progress, review, merge
reviews/*.md, fix-tasks.md ← review    → merge; fix-tasks → implement (fix loop)
merge/*.md               ← merge       → terminal
.the-flow-state.json / the-flow.json→md ← guided engine ONLY (stages never write)
```
[IC-02]

### Lint feasibility (L1–L6)
| Lint | Check | Today | Mechanism |
|---|---|---|---|
| L1 stage leakage | grep = 0 | **FAIL (147)** | ~20 lines bash, ready now |
| L2 contract block | Verb/Consumes/Produces present | **FAIL (0/11)** | ~15 lines bash, ready now |
| L3 grammar conformance | every `/the-flow …` matches Registry | PASS-ish | ~50–80 lines python stdlib |
| L4 closure | edges→Registry; Consumes⊆upstream Produces | content passes; **table format doesn't exist yet** | needs Phase B graph tables |
| L5 view freshness | rendered banner present | flight-plan.md ✅; getting-started ❌ | banner now; render-diff needs Phase D |
| L6 host limits | YAML parses; description ≤1024 | PASS (all 15 skills; max 971) | ~30 lines python, ready now |

Pattern to copy: `scripts/check-skill-slugs.sh` — `set -euo pipefail`, `OK:`/`ERROR:`/`WARN:` prefixes, stderr for errors, exit 0/1/2, count summary. Justfile slot: new `check-flow` recipe after `skills-orphans` (~line 356); CI recipe at justfile:217 gains `check-flow` before `build`. No CI workflows or git hooks exist — lints run via just/manual. [QT-01..10]

## The D7 Fold (companion → mode of implement) — evidence

- **Duplication**: 61 is ~400 lines; ~49% verbatim-identical to 60 (the per-task progress checklist is 98% identical); ~51% genuinely companion-specific: Step 0 boot/attach minih (~40 lines), Step 0a briefing template (~25 lines), ping-per-task + drain/control:stop checklist items, findings reconciliation. [IC-06]
- **62-progress.md needs zero changes**: debrief (Step 9) already keys on `--companion-run-id`, agnostic to which module called it. [IC-10]
- **Schema already agrees**: `flight-plan.schema.json` has NO `companion` node type — companions are `agents[].kind: companion` wrapping phases. The separate 6c registry row is the anomaly. [IC-04]
- **Blast radius (159 refs / 7 files)**: SKILL.md (6: table row, slug row, invariant #7, description), 00-routing.md (4), coach.md (5), getting-started.md (8), flight-plan.template.md (3), 50-phase-tasks.md (1), 62-progress.md (31, mostly keep — protocol consumer), 61 itself (56, deleted). Post-fold: 10 modules. "Companion supersedes review" becomes a Graph edge decoration. [IC-07]

## History & Constraints

- **Plan-030 playbook worked**: atomic cutover, tag-before-build (`pre-flow-consolidation` at `44ba70f`), dedupe inventory (T002) as parity proof, grep-multiset ACs, deploy+tidy with literal slugs, live-state resume test on 3 in-flight flows. Reuse the shape. [DE-01, PL-14]
- **Cost evidence**: `b26bce2` = 20 files / 249 lines / 308 strings for one formatting change. Biggest hits: getting-started (86), coach (60), the 11 stages (~40 combined), flight-plan files (24). [DE-02]
- **Churn**: SKILL.md 15 commits, flight-plan trio 17, getting-started 9, stages 2 each → template/regen the hot spots first. [DE-03]
- **Freeze constraints**: `/eng-harness-flow --event` vocabulary is frozen ≥1 quarter from 2026-06-10 (CLAUDE.md Override #2) — plan 031 must not rename seams; the 5-seam multiset must map 1:1 across the restructure. `/the-flow`'s own public grammar + old-slug translation table are de-facto frozen (3 live flows resume through them). Internal structure is explicitly NOT frozen. [DE-04, DE-05, DE-09]
- **Docs that must update with the restructure**: CLAUDE.md:100–102 (structure description), docs/skills-pipeline/README.md (stage/module table), getting-started.md (becomes a banner-marked view), README.md:260 (stage ref). README_AGENTS counts unaffected. [DE-08]
- **Open loose end**: `docs/skills-pipeline/codebase.md` (9,738-line stale code2prompt pack of deleted v1 commands) — flagged in plan-030, deletion paused by user; decide in 031 or leave documented. [DE-10]

## Prior Learnings (institutional knowledge — pay attention)

✓ 15 findings surfaced; heaviest sources: plans 030, 029, 024. Retro history: 1 active record (plan-023 FX001 closure); frozen `docs/harness/agents/` mined read-only.

| ID | Type | Key insight | Action for 031 |
|---|---|---|---|
| PL-01 | decision | Old-slug translation at read-time carried 3 live flows through the 030 cutover | Keep table semantics identical; test resume on real stale state |
| PL-02 | gotcha | `npx skills add` never prunes — retired files linger deployed | Deploy+tidy task with `just skills-orphans` baseline before/after |
| PL-06 | gotcha | zsh unquoted-var `rm` loop silently no-ops | Literal paths in tidy commands, never `$var` loops |
| PL-10 | gotcha | Hardcoded lists drift — TRUST GREP, NOT THE PLAN | Every "no refs remain" task carries its grep in Done-When |
| PL-11 | insight | Diagrams drift in extractions (030 count-verified 18 ZWSP fences) | Diagram inventory; count+node-name parity post-edit |
| PL-12 | gotcha | The skill driving the session must edit itself LAST | Self-edit tasks at end of phase; note in risk matrix |
| PL-13 | insight | Description ≤1024 (Copilot CLI hard limit) — 030 fitted 976 | L6 lint guards it; re-measure after any description edit |
| PL-14 | insight | Dedupe inventory (shared block → single home) = parity proof | T002-style inventory before de-leaking modules |
| PL-15 | decision | State-write ownership split is load-bearing (guided writes, stages never) | Preserve verbatim through the restructure |
| PL-05/09 | gotcha | Mass renames: enumerate sites upfront, grep pre/post totals | Atomic-update-zones table in the plan |
| PL-08 | insight | Append-only blocks beat inline restructuring for auditability | Contract blocks appended/replacing headers as discrete diffs |
| PL-07 | decision | Freeze overrides get dated CLAUDE.md notes | If 031 freezes the new template surface, log it the same way |

## Domain Context

No `docs/domains/` registry exists. The skill folder is the natural boundary; the workshop's five layers are the internal sub-boundaries (map above). Recommendation from scouts: the Registry+Graph format IS a proto-domain contract — formalising it as a `docs/domains/` entry is optional and deferred; the lint script is the real boundary enforcement. [DB-01..08]

**Prior art**: `eng-harness-flow` (external) shows a stateless router with private children. Borrow: one-door grammar, children-private posture, envelope thinking. **Do not borrow statelessness itself** — the-flow is a linear journey with durable checkpoints by design (`.the-flow-state.json`); one scout's suggestion to make the-flow stateless contradicts settled plan-030 architecture and is rejected here. [PS-03, corrected]

## Critical Discoveries

### 🚨 CF-01: The leak is prescribed by the v1 guide — ruleset v2 must replace it, not just fix instances
**Impact**: Critical · **Source**: PS-01, DE-06 · `scratch/paste/20260611T080711.md` ~line 255–262 mandates "Next routing instruction" per module. Fixing the 147 refs without shipping the v2 ruleset (R1–R8 + templates + lints) regrows the leak on the next flow. The *pattern* is the product; the-flow refactor is the exemplar.

### 🚨 CF-02: Registry exists in triplicate with no declared master
**Impact**: Critical · **Source**: DB-02 · SKILL.md:29–43, 00-routing.md:115–131, getting-started.md:22–34. Phase B must declare one owner (workshop: Registry table at flow level) and demote the others to views/derivations, or L3/L4 have no ground truth.

### 🚨 CF-03: D7 fold is the highest-leverage single move
**Impact**: High · **Source**: IC-06/07/10 · Deletes the leakiest module (21 refs), removes ~98 duplicated lines, drops registry to 10 rows, requires zero changes to 62-progress, and the flight-plan schema already models companion correctly as agents[].

### 🚨 CF-04: Public surface vs internal freedom is already settled — respect it
**Impact**: High · **Source**: DE-04/05/09 · Frozen: `/the-flow <id> <name>` grammar, old-slug table, 5 harness seams (multiset 1:1), guided/direct load-path parity, state-write ownership. Free: file names, table formats, coach slots, view regeneration.

### 🚨 CF-05: L1/L2/L6 are shippable on day one — the lint baseline IS the progress metric
**Impact**: High · **Source**: QT-07, DC-08 · Phase A can ship `check-flow-architecture.sh` with L1 (147→0 tracks Phase B), L2 (0/11→11/11... →10/10 post-fold), L6 (passes, guards regressions). L4 lands when the graph tables exist; L5 banner-check lands with the banner convention.

### 🚨 CF-06: Coach narration needs slots, not literals (~56 commands)
**Impact**: Medium · **Source**: IA-04, DB-05 · coach.md scripts embed literal commands per seam. D5 settles slots (`{{render-edge}}`); the grammar line is defined once and the LLM renders commands at narration time — this is what collapses the next 308-edit event to a one-line change.

## Modification Considerations

**✅ Safe**: deleting "Next routing" headers + trailing next-step blocks (the Graph already carries every edge — verified closure); adding contract blocks; adding the lint script; banner-marking getting-started.
**⚠️ Caution**: coach.md slot conversion (keep narration byte-meaning identical; rail rendering rules are intricate); SKILL.md description edits (971/1024 — L6 lint before deploy); renaming stage files to verbs (61 path refs + external doc refs go stale — grep-driven, Phase D).
**🚫 Danger zones**: old-slug translation table (live flows resume through it); harness seam invocations inside 60/61/80 (byte-identical multiset required); state-write ownership; merge PROCEED gate wording.

## External Research Opportunities

No blocking gaps. Optional, non-blocking:
1. **npx skills CLI behavior** (install flattening, file-type handling, any size limits) — only matters for Phase D/E template/CLI packaging; verifiable empirically with a test install when needed. Skippable for the spec.
Deferred-by-design open questions (workshop Q3/Q4/Q6): CLI name/language, shared verb-library across flows, flow-state schema generalisation — all gated on a second real flow existing.

## Next Steps

- **Specify**: `/the-flow 1b specify` — scope recommendation grounded in this evidence: **phases A–C** (ruleset+lints, de-leak+D7 fold, coach slots) deliver the shareable pattern + exemplar with zero new tooling; D–E (verb-file renames, template library, authoring CLI) stay deferred until a second flow exists.
- Workshop 001 decisions carry into the spec as authoritative (`## Workshop Opportunities` already satisfied pre-spec).

---
**Research Complete**: 2026-06-12 · 8 subagents · findings deduplicated from 78 raw
