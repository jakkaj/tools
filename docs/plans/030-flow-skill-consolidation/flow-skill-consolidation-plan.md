# Flow Skill Consolidation Implementation Plan

**Mode**: Simple
**Plan Version**: 1.1.0 (post-validation fixes applied)
**Created**: 2026-06-11
**Spec**: [flow-skill-consolidation-spec.md](./flow-skill-consolidation-spec.md)
**Status**: READY

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No `[NEEDS CLARIFICATION]` markers remain; 7 clarifications resolved 2026-06-11 |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` |
| G4 | ADR Compliance | N/A | `docs/adr/` holds only a README placeholder — no Accepted ADRs |
| G5 | Structure | PASS | All required sections present; cross-refs resolve |
| G6 | Testing Alignment | PASS | Lightweight per spec — validation tasks T011–T013; criteria measurable |
| G7 | Domain Completeness | PASS | Spec's single domain is **concept-only by spec decision** (repo keeps no `docs/domains/` registry) — no domain.md machinery, manifest covers every touched file |

## Summary

The 13 main-flow SDD skills (~6,000 lines, 13 public slugs) become one progressive-disclosure skill: a dispatch `SKILL.md` (≤150 lines) routing to lazily-loaded stage modules under `references/stages/`, with guided coaching extracted to `coach.md`/`00-routing.md`. The cut is atomic — tag `pre-flow-consolidation` first, build the new structure, delete the 12 absorbed folders, sweep the catalogs, deploy, tidy orphans. Resume continuity is preserved by a read-time translation table in the dispatch (three live flows have `pending_command` values naming retired slugs). Utilities stay public and untouched except a wording fix in validate-v2's detection table (documented non-goal exception). Note: 12 skills consolidate into **11** stage modules because plan-2-v2-clarify is absorbed as a re-entry section of `20-specify.md` (T003).

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| sdd-pipeline-skills | NEW (concept-only) | modify | The `skills/SDD/` tree — 13 skills consolidated to 1 + stage modules. No domain.md machinery per spec. |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/the-flow/SKILL.md` | sdd-pipeline-skills | contract | The public dispatch surface — rewritten |
| `skills/SDD/the-flow/references/00-routing.md` | sdd-pipeline-skills | internal | NEW — stage machine + routing table + must-see fields (guided mode) |
| `skills/SDD/the-flow/references/coach.md` | sdd-pipeline-skills | internal | NEW — rail rendering, narration scripts, adoption contract, compact handshake, harness-seam narration |
| `skills/SDD/the-flow/references/stages/*.md` (11 modules) | sdd-pipeline-skills | internal | NEW — 10-explore, 20-specify (absorbs plan-2 re-entry), 25-workshop, 30-architect, 35-adr, 50-phase-tasks, 60-implement, 61-implement-companion, 62-progress, 70-review, 80-merge |
| `skills/SDD/the-flow/references/getting-started.md` | sdd-pipeline-skills | internal | Update — slug names → stage names/module paths |
| `skills/SDD/the-flow/references/flight-plan.{schema.json,template.json,template.md}` | sdd-pipeline-skills | internal | Wording touch-up only (`command` field examples) — schema *meaning* unchanged |
| `skills/SDD/{plan-1a-v2-explore, plan-1b-v3-specify-and-clarify, plan-2-v2-clarify, plan-2c-v2-workshop, plan-3-v3-architect, plan-3a-v2-adr, plan-5-v2-phase-tasks-and-brief, plan-6-v2-implement-phase, plan-6-v2-implement-phase-companion, plan-6a-v2-update-progress, plan-7-v2-code-review, plan-8-v2-merge}/` | sdd-pipeline-skills | internal | DELETE (after modules verified) |
| `scripts/migrate-skills.py` | sdd-pipeline-skills | internal | DELETE — inert (source `agents/v2-commands/` gone); git history retains it |
| `README_AGENTS.md`, `INSTALL.md`, `docs/skills-pipeline/README.md`, `CLAUDE.md` | sdd-pipeline-skills | internal | Catalog/docs sweep |
| `skills/SDD/validate-v2/SKILL.md` | sdd-pipeline-skills | internal | 3-line detection-table wording fix (documented exception to "utilities untouched") |
| `README.md` | sdd-pipeline-skills | internal | Narrative SDD chapters — retired command names rewritten to the `/the-flow` surface (sweep discovered mid-build; widened by review FT-003) |
| `scripts/sync-to-dist.sh` | sdd-pipeline-skills | internal | `.vscode/` sync block removed — follows the user-directed `.vscode/` deletion mid-build |
| `skills/SDD/{code-concept-search-v2, plan-0-v2-constitution, plan-2b-v2-prep-issue, util-0-v2-handover}/SKILL.md` | sdd-pipeline-skills | internal | Cross-reference lines only — retired slugs → stage names (logged deviation from the "utilities byte-identical" non-goal; widened by review FT-003) |
| `.vscode/` (entire directory) + `src/jk_tools/.vscode/` mirror | sdd-pipeline-skills | internal | DELETE — user-directed mid-build ("blown away"): stale snippets/backups/codebase pack; `install/agents.sh` regenerates the project `mcp.json` at setup |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | **Stale resume state**: live flows carry `pending_command` naming retired slugs — 027 (`/plan-8-v2-merge`), 029 (`/plan-7-v2-code-review`), 030 (this plan's own state) | Dispatch SKILL.md carries an old-slug → stage translation table applied at state-read time; T013 tests resume on all three |
| 02 | Critical | **Cross-skill auto-calls become module cross-reads**: plan-6 → plan-6a per task (SKILL.md:200), companion → plan-6a with `--companion-run-id` (SKILL.md:344-361), plan-1b "Next step" footers → 2c/3 | Modules reference sibling modules by path (read `references/stages/62-progress.md` and follow it); plan-3 module's auto-run of `/validate-v2` stays a real Skill invocation (external, public) |
| 03 | Critical | **Catalog blast radius**: README_AGENTS.md has 12 catalog rows (L135-148) + 2 multi-skill install examples (L61, L76); INSTALL.md one example; docs/skills-pipeline/README.md Commands table lists all 12 | T010 collapses to one `the-flow` row + stage-module note; rewrite install examples to `--skill the-flow` |
| 04 | High | **Discovery regression**: one description (≤1024 chars) must now trigger for every pipeline ask — "implement", "review", "architect", "spec", "research", "merge" | T007 writes the expanded frontmatter description naming every stage + the direct-jump grammar |
| 05 | High | **migrate-skills.py is inert but advertised**: source dir `agents/v2-commands/` no longer exists; CLAUDE.md still says the script is "retained for replay/audit" | T009 deletes the script; T010 fixes the CLAUDE.md claim (git history is the archive) |
| 06 | High | **Deploy targets never prune**: `npx skills add` only adds; after source deletion the 12 slugs persist in `~/.agents/skills/` + per-CLI views; `just skills-orphans` enumerates source vs deployed | T012: orphans baseline → deploy → tidy the 12 retired slugs → `just doctor-skills` green |

## Implementation

**Objective**: Replace the 13-skill main flow with one dispatch-plus-modules skill, atomically, with a tagged rollback anchor.
**Testing Approach**: Lightweight (scripted structural checks + behavioural drive; no mocks — real files, real deploy).

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T000 | **Harness pre-flight** — `/eng-harness-flow --event pre-implement --plan-dir docs/plans/030-flow-skill-consolidation` | — | — | Router envelope handled; verdict narrated verbatim | _Harness seam — router installed; repo has no adopted harness so this noops quietly (advisory, never a gate)_ |
| [x] | T001 | Rollback anchor: `git tag pre-flow-consolidation` on the pre-cutover commit; record restore one-liner in execution log | sdd-pipeline-skills | (repo root) | `git tag -l pre-flow-consolidation` shows the tag; execution log documents `git checkout pre-flow-consolidation -- skills/SDD scripts/migrate-skills.py && just install-skills-from-source` | User-authorized git write (spec clarification) |
| [x] | T002 | Extract guided-mode machinery from current the-flow SKILL.md into `references/00-routing.md` (stage machine, routing table, must-see fields, state contract) and `references/coach.md` (rail rendering, narration scripts, adoption contract, compact handshake, harness-seam narration) | sdd-pipeline-skills | `skills/SDD/the-flow/references/{00-routing.md,coach.md}` | Both files exist; every section of today's the-flow SKILL.md is accounted for in a **destination map** (→ SKILL.md / coach.md / 00-routing.md / DROPPED-with-reason) recorded in the execution log; 00-routing.md documents **state-write ownership** (guided dispatch writes `.the-flow-state.json`; direct-jump modules never write it — artifact-discovery-by-existence keeps resume correct, same as today's direct `/plan-N` runs); T002 also emits the **dedupe inventory** (shared block → its single new home) that T003–T006 cite | Hard invariants stay in SKILL.md (global); narration detail moves out. Highest-risk extraction — the destination map is the parity proof |
| [x] | T003 | Stage modules batch 1: `10-explore.md` (from plan-1a), `20-specify.md` (from plan-1b + plan-2 absorbed as "## Re-entry: mid-plan clarifications"), `25-workshop.md` (from plan-2c) | sdd-pipeline-skills | `skills/SDD/the-flow/references/stages/` | Each module has Purpose / Entry conditions / Procedure / Output contract / Next routing; body parity with source skill minus blocks named in T002's dedupe inventory; harness-seam invocations byte-identical (grep source skill for `/eng-harness-flow`, copy verbatim) | Dedupe strictly per T002's inventory (NO-TIME-ESTIMATES, CS rubric, domain-loading preamble → SKILL.md/00-routing.md) |
| [x] | T004 | Stage modules batch 2: `30-architect.md` (from plan-3, keeps auto-run of `/validate-v2`), `35-adr.md` (from plan-3a) | sdd-pipeline-skills | `skills/SDD/the-flow/references/stages/` | Same done-when as T003; 30-architect's gate matrix + READY/DRAFT contract intact | Per finding 02 |
| [x] | T005 | Stage modules batch 3: `50-phase-tasks.md` (plan-5), `60-implement.md` (plan-6), `61-implement-companion.md` (companion), `62-progress.md` (plan-6a) — rewrite all 6a invocations as "read `references/stages/62-progress.md` and follow it" incl. the companion's `--companion-run-id` final-task call | sdd-pipeline-skills | `skills/SDD/the-flow/references/stages/` | Same done-when as T003; zero remaining `/plan-6a-v2-update-progress` slug invocations inside modules; companion debrief flow (drain ping → control:stop → farewell read → reconcile → magicWand surface) intact in 62 and diff-verified against plan-6a Step 9 at review | Per finding 02 — the load-bearing rewiring task; not a mechanical find-and-replace |
| [x] | T006 | Stage modules batch 4: `70-review.md` (plan-7), `80-merge.md` (plan-8, keeps PROCEED-only execute) | sdd-pipeline-skills | `skills/SDD/the-flow/references/stages/` | Same done-when as T003; both stay ≤1,200 lines after dedupe | Largest sources (1039/412 lines) |
| [x] | T007 | Rewrite dispatch `SKILL.md`: frontmatter (name `the-flow`; description ≤1024 chars naming every stage + trigger words + direct-jump grammar), stage table (numbers + names → module paths), hard invariants, progressive-disclosure rule ("load exactly one module for the current state"), old-slug → stage translation table, guided vs direct-jump load paths | sdd-pipeline-skills | `skills/SDD/the-flow/SKILL.md` | ≤150 lines (`wc -l`); table maps 1a/1b/2c/3/3a/5/6/6-companion/6a/7/8 by number AND name; translation table covers all 12 retired slugs + an unmapped-slug fallback rule (print the bare stage alias and ask — never guess); description contains "research", "spec", "architect", "implement", "review", "merge"; overflow contingency: if the draft exceeds the cap, extract dispatch internals to `references/01-dispatch.md` — never balloon SKILL.md | Per findings 01 + 04. **Blocks on T002–T006** (modules must exist; uses T002's destination map) |
| [x] | T008 | Update bundled references: `getting-started.md` (slug names → stage names/`/the-flow N` grammar), flight-plan template/schema `command`-field examples | sdd-pipeline-skills | `skills/SDD/the-flow/references/` | Grep for the 12 retired slugs inside `skills/SDD/the-flow/` returns only the dispatch translation table; schema still valid JSON, meaning unchanged | minih shape contract untouched |
| [x] | T009 | Atomic deletion: remove the 12 absorbed skill folders + `scripts/migrate-skills.py` | sdd-pipeline-skills | `skills/SDD/*`, `scripts/migrate-skills.py` | `ls skills/SDD/` shows the-flow + the **12** untouched utilities only (code-concept-search-v2, deepresearch-v2, didyouknow-v2, flowspace-research-v2, htmlify-v2, install-hve-core-rpiv, plan-0-v2-constitution, plan-2b-v2-prep-issue, plan-6b-worked-example, plan-v2-extract-domain, util-0-v2-handover, validate-v2); migrate script gone | Per finding 05; tag from T001 is the restore path. **Blocks on T003–T008** (modules verified first) |
| [x] | T010 | Catalog sweep: README_AGENTS.md (12 rows → 1, skill counts, install examples ~L61/L76 rewritten to `--skill the-flow`), INSTALL.md example (~L91), docs/skills-pipeline/README.md Commands table, CLAUDE.md (skill counts, migrate-script claim → "git history retains it", "Editing existing v2 skills" section), `.vscode/plan-*.md` snippets, validate-v2 detection-table (reword the five Detection Signal rows to artifact-form — e.g. "tasks dossier created/modified (stage 5)" — table shape unchanged) | sdd-pipeline-skills | `README_AGENTS.md`, `INSTALL.md`, `docs/skills-pipeline/README.md`, `CLAUDE.md`, `.vscode/plan-*.md`, `skills/SDD/validate-v2/SKILL.md` | Grep for the 12 retired slugs across these files returns zero hits; counts accurate | Per findings 03 + 05; validate-v2 edit is the documented non-goal exception |
| [x] | T011 | Structural validation: `scripts/check-skill-slugs.sh` exit 0; `python3 -c json.load` on flight-plan schema + template; `wc -l skills/SDD/the-flow/SKILL.md` ≤150; repo-wide grep for the 12 retired slugs excluding `docs/plans/**` and `src/jk_tools/**` returns only the dispatch translation table | sdd-pipeline-skills | (repo-wide) | All four checks pass, output captured in execution log | AC 2, 8, 9 |
| [x] | T012 | Deploy + tidy: `just skills-orphans` baseline → `just install-skills-from-source` → tidy the 12 retired slugs from all deploy targets (`~/.agents/skills`, `~/.claude/skills`, `~/.pi/skills`, legacy paths) → `just skills-orphans` clean → `just doctor-skills` green | sdd-pipeline-skills | (deploy targets) | Post-tidy `just skills-orphans` lists **none** of the 12 retired slugs (before/after output captured in execution log); doctor-skills reports no orphans/drift; canonical store the-flow == source | Per finding 06; AC 10 |
| [x] | T013 | Behavioural drive: (a) resume THIS flow — `/the-flow` translates 030's stale `pending_command` via the new table and lands at the right stage; (b) verify translation table maps 027's `/plan-8-v2-merge` + 029's `/plan-7-v2-code-review` correctly (dry-read, don't advance their flows); (c) direct jump `/the-flow 6 --phase … --plan …` and named `/the-flow implement …` load only `60-implement.md`; (d) guided `/the-flow` loads coach + routing + current stage only | sdd-pipeline-skills | `docs/plans/{027,029,030}-*/.the-flow-state.json` | All four observations recorded in execution log with the module-load evidence | AC 4, 5, 12; per finding 01 |
| [x] | T014 | **Harness phase-end** — `/eng-harness-flow --event phase-end --plan-dir docs/plans/030-flow-skill-consolidation` | — | — | Router envelope handled at phase end | _Harness seam — noops quietly here (no adopted harness); advisory_ |

### Acceptance Criteria

- [x] AC1 `skills/SDD/` contains exactly one main-flow skill (`the-flow`); the 12 absorbed folders gone from source *(← T009)*
- [x] AC2 Dispatch `SKILL.md` ≤ ~150 lines (**83**): stage table, invariants, state pointer, load-one-module rule *(← T007, verified T011)*
- [x] AC3 `references/stages/` covers all 11 absorbed capabilities with entry/procedure/output/next-routing sections *(← T003–T006)*
- [x] AC4 Guided `/the-flow` loads coach + routing + current stage module only; rail/narration/print-then-offer/state contract preserved *(← T002, verified T013d)*
- [x] AC5 `/the-flow 6 --phase … --plan …` ≡ `/the-flow implement --phase … --plan …`, loading only that module *(← T007, verified T013c)*
- [x] AC6 Clarify re-entry reachable as a section of `20-specify.md` *(← T003)*
- [x] AC7 Tag `pre-flow-consolidation` exists (`44ba70f`); restore one-liner documented and exercised logically (checkout syntax verified) *(← T001)*
- [x] AC8 `check-skill-slugs.sh` exit 0; flight-plan schema + template valid JSON *(← T011)*
- [x] AC9 Zero live references to the 12 retired slugs outside `docs/plans/**`, the dispatch translation table, and module `*(absorbed from …)*` provenance lines *(← T008+T010, verified T011; review FT-003 widened the sweep — README narrative chapters, INSTALL.md count, plan-2b/code-concept-search/plan-0 cross-refs — re-verified in the fix pass; `docs/skills-pipeline/codebase.md` is a stale generated pack of the deleted v1 commands, flagged not fixed)*
- [x] AC10 Deploy succeeds; orphans tidied; no deploy target resolves a retired slug; `doctor-skills` green (one pre-existing external-family drift note) *(← T012)*
- [x] AC11 Every `/eng-harness-flow --event …` invocation in today's 13 skills appears identically in the consolidated modules (multiset parity grep; 3 additive header mentions) *(← T003–T006, grep-verified + /plan-7 review against the tag)* **Post-review amendment (FT-001)**: stage 61's `plan-complete` invocation removed **deliberately** — review F001 found it fired before merge, but stage 80 owns that seam. Parity vs tag is now `plan-complete` 9 → 8 (all other events unchanged: phase-end 10/10, pre-implement 10/10, session-start 3/3; post-spec +1 additive header).
- [x] AC12 In-flight `.the-flow-state.json` files resume correctly via the translation table (030 exercised live; 027/029 dry-verified) *(← T007, verified T013a/b)*

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Dedupe drops a load-bearing instruction | Medium | High | T003–T006 done-when requires per-module parity accounting; AC11 grep parity for harness seams; /plan-7 review diffs modules against tag |
| Translation table misses a slug → resume breaks | Low | High | Table enumerates all 12 (finding 01); T013 exercises 030 live + 027/029 dry |
| Dispatch SKILL.md balloons into a hidden monolith | Medium | Medium | AC2 caps at ~150 lines; narration lives in coach.md only |
| Stale deployed copies shadow the new skill | High (without T012) | Medium | T012 explicit tidy step; doctor-skills verification |
| Companion debrief silently lost in rewiring | Low | High | T005 done-when names the drain→stop→farewell→reconcile chain explicitly |
| Self-reference: the skill being replaced is driving this plan | Certain | Low | Deploy is last (T012); the running session keeps loaded context; T013(a) is the live resume test |

## Harness Seams

- **Entry point**: `/eng-harness-flow --event <seam> [--phase <id>] [--plan-dir <p>] --json` — the single door; child skills never named.
- **Backpressure** (post-spec seam): nooped for this plan — repo has no adopted harness; no `backpressure-coverage.md` exists (absence changes nothing).
- **Pre-implement** (`--event pre-implement`): T000 surfaces it; fired by the implement stage at phase start. Verdict vocabulary: `healthy / SLOW / UNHEALTHY / UNAVAILABLE` — `UNAVAILABLE` is not an error, falls back to standard testing (the expected outcome here).
- **Phase end** (`--event phase-end`): T014; `--event plan-complete` fires at merge.
- **Best-effort**: all advisory, never blocks; this repo currently has no adopted harness so every seam noops quietly (`--prompt-optional=false`).
- **Event → module map (AC11 guidance — verify each by grep against the source skill)**: `session-start` → dispatch/coach (flow entry); `post-spec` → 20-specify next-steps + coach's awaiting-1b branch; `pre-implement` → 60-implement + 61-implement-companion (phase start); `phase-end` → 60-implement + 61-implement-companion (phase seam; narrated in coach's awaiting-6); `plan-complete` → 80-merge (after merge executes). Mentions in 30-architect/50-phase-tasks/70-review are narration references, not invocations — preserve wording as-is.
