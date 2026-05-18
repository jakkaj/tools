# Compounding Value System Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-05-18
**Spec**: [./difficulty-ledger-skill-spec.md](./difficulty-ledger-skill-spec.md)
**Status**: DRAFT

> **First-class concept**: "Compounding Value System" is the formal name; **`compound`** is the slug used throughout (folder paths, skill names, file references). It is a first-class peer category in this repo's skills graph alongside SDD, general, and personal.

📚 This plan synthesizes the spec + 6 authoritative workshops:
- [`workshops/001-self-improvement-vibe.md`](./workshops/001-self-improvement-vibe.md) — vibe + anti-vibes + Compounding Test
- [`workshops/002-end-to-end-flow.md`](./workshops/002-end-to-end-flow.md) — five-stage loop + inter-stage contracts
- [`workshops/003-compound-system-map.md`](./workshops/003-compound-system-map.md) — three-layer stack + integration surfaces
- [`workshops/004-sdd-pipeline-compound-integration.md`](./workshops/004-sdd-pipeline-compound-integration.md) — per-skill integration matrix + 4 firing sites
- [`workshops/005-universal-retro-contract.md`](./workshops/005-universal-retro-contract.md) — JSON schema + round-trip + namespaces
- [`workshops/006-compound-folder-layout.md`](./workshops/006-compound-folder-layout.md) — KISS layout + runtime views

Per the [Plan-3 skill convention for plans with comprehensive workshops](./workshops/), no additional research subagents were launched — the workshops are authoritative design and this plan is pure synthesis.

---

## Summary

Implement the **Compounding Value System** (`compound`) as a first-class peer category in this repo's skills graph. The system is a three-layer architecture: philosophy (`harness-is-the-product-v2`, already exists), substrate (`engineering-harness-v2`, renamed from `agent-harness-v2`), and meta-loop (4 new `compound-N` skills + the `docs/compound/` ledger surface). Every supported CLI agent (Claude Code, Codex, GitHub Copilot, OpenCode, Pi) silently logs friction during work; sees a soft session-end prompt to triage entries; and gets periodic auto-curation surfaced at natural reflection moments inside the SDD pipeline (companion-mode last-phase debrief + plan-8 merge). Cross-system retros adopt a universal JSON Schema contract that round-trips cleanly to/from minih's existing `retrospective.json` shape, so minih's auto-harvest is back-compat readable in v1 and natively adoptable in v2 (coordinated via a GitHub RFC issue). Validated by the 4-signal Compounding Test over a 1-week dogfood window in this repo.

## Target Domains (Areas)

This repository does not use the formal `docs/domains/` system. Areas below map the plan's scope in lieu of formal domain boundaries:

| Area | Status | Relationship | Role |
|------|--------|--------------|------|
| `skills/compound/` | **NEW** | **create** | New top-level skill category (peer to SDD/, general/, personal/) |
| `skills/compound/compound-0-setup/` | **NEW** | **create** | Scaffold + re-check + reversible split-migration from `docs/retros/` |
| `skills/compound/compound-1-track/` | **NEW** | **create** | Silent per-agent buffer writer; trigger heuristics |
| `skills/compound/compound-2-bubble/` | **NEW** | **create** | Session-end soft prompt; envelope wrap; `[s/t/p/e/d/a]` routing |
| `skills/compound/compound-3-harvest/` | **NEW** | **create** | Runtime-filtered curation; terminal print; back-compat reader; `--prune` |
| `skills/compound/schemas/` | **NEW** | **create** | Universal retro JSON Schema + namespace sub-schemas + fixtures |
| `skills/SDD/engineering-harness-v2/` | existing | **rename + modify** | Cosmetic rename from `agent-harness-v2` (per Q5.1); template gains `## Known Difficulties` seed |
| `docs/project-rules/engineering-harness.md` | renamed | **rename** | From `agent-harness.md`; legacy filename fallback for back-compat |
| `skills/SDD/harness-is-the-product-v2/` | existing | **modify (small)** | Principle 2 wording: "Track Velocity Compounding" → "Track Compounding Value"; soften (E)/(A) disambiguation |
| `skills/SDD/plan-1a-v2-explore/` | existing | **modify** | Subagent 7 reads compound + back-compat; orchestrator-side `compound-1-track`; end-auto-bubble; harvest suggestion at start |
| `skills/SDD/plan-1b-v2-specify/` | existing | **modify** | Orchestrator-side `compound-1-track` (no end-bubble; chains to plan-2) |
| `skills/SDD/plan-2c-v2-workshop/` | existing | **modify** | Orchestrator-side `compound-1-track` |
| `skills/SDD/plan-3-v2-architect/` | existing | **modify (self)** | Orchestrator-side `compound-1-track`; end-auto-bubble; harvest suggestion at start (this very skill — modified LAST) |
| `skills/SDD/plan-5-v2-phase-tasks-and-brief/` | existing | **modify** | Orchestrator-side `compound-1-track` (light) |
| `skills/SDD/plan-6-v2-implement-phase/` | existing | **modify** | `compound-1-track` during work; end-auto-bubble per phase; harvest suggestion after final phase |
| `skills/SDD/plan-6-v2-implement-phase-companion/` | existing | **modify** | Same as plan-6 PLUS companion farewell envelope → universal retro mapping; **AUTO-fire compound-3-harvest at FINAL-phase debrief** (replaces /plan-7 as harvest anchor) |
| `skills/SDD/plan-6a-v2-update-progress/` | existing | **modify** | Step 8c path update (`docs/retros/` → `docs/compound/`); Step 9 runs `minihToUniversal()` mapping; writes per-run `.retro.md` via `resolvePath()` |
| `skills/SDD/plan-7-v2-code-review/` | existing | **modify** | Orchestrator-side `compound-1-track`; end-auto-bubble + harvest (preserved for rare solo `/plan-6` flow) |
| `skills/SDD/plan-8-v2-merge/` | existing | **modify** | Orchestrator-side `compound-1-track`; end-auto-bubble + auto-harvest |
| 8 SDD skills (Spec § Q5.1 cascade) | existing | **modify (small)** | Cross-reference updates from `agent-harness.md` → `engineering-harness.md` (with documented fallback) |
| `docs/compound/` | **NEW** | **create** | Minimal canonical tree (per workshop 006): `README.md` + `_buffers/` + `agents/<slug>/<date>/<retro>.retro.md` + optional `.disabled` sentinel |
| `AGENTS.md` · `CLAUDE.md` | existing | **modify** | Add "Compounding Value System" section (10–15 lines mirrored content; D7 voice) |
| `README_AGENTS.md` | existing | **modify** | Add `## Compound — Compounding Value System` catalog section + 4 entries; update engineering-harness-v2 row |

## Domain Manifest

[Every file the plan introduces or modifies, mapped to its area:]

| File | Area | Classification | Rationale |
|------|------|----------------|-----------|
| `/Users/jordanknight/github/tools/skills/compound/schemas/retro.schema.json` | schemas | contract | Universal retro contract (workshop 005 § JSON Schema) |
| `/Users/jordanknight/github/tools/skills/compound/schemas/system.compound.schema.json` | schemas | contract | Compound's namespace extension (lifecycle metadata) |
| `/Users/jordanknight/github/tools/skills/compound/schemas/system.minih.schema.json` | schemas | contract | Minih's namespace extension (vendored from minih) |
| `/Users/jordanknight/github/tools/skills/compound/schemas/README.md` | schemas | internal | Convention guide for schema dir |
| `/Users/jordanknight/github/tools/skills/compound/schemas/fixtures/*.retro.md` | schemas | internal | 5+ test fixtures (full / minimum / multi-kind / lifecycle / malformed) |
| `/Users/jordanknight/github/tools/skills/compound/compound-0-setup/SKILL.md` | compound-0-setup | contract | Scaffold + re-check + migration (workshop 006 § Migration Recipe) |
| `/Users/jordanknight/github/tools/skills/compound/compound-1-track/SKILL.md` | compound-1-track | contract | Silent log + trigger heuristics + per-agent buffer |
| `/Users/jordanknight/github/tools/skills/compound/compound-2-bubble/SKILL.md` | compound-2-bubble | contract | Session-end prompt + envelope wrap + scratch/ staging |
| `/Users/jordanknight/github/tools/skills/compound/compound-3-harvest/SKILL.md` | compound-3-harvest | contract | Read pass + cluster + terminal print + runtime filters + back-compat |
| `/Users/jordanknight/github/tools/docs/compound/README.md` | docs/compound/ | internal | Convention guide for the ledger surface |
| `/Users/jordanknight/github/tools/docs/compound/_buffers/README.md` | docs/compound/ | internal | Buffer semantics |
| `/Users/jordanknight/github/tools/docs/compound/_buffers/.gitignore` | docs/compound/ | internal | `*.session-buffer.md` |
| `/Users/jordanknight/github/tools/docs/compound/agents/.gitkeep` | docs/compound/ | internal | Preserve empty agents/ dir in git |
| `/Users/jordanknight/github/tools/skills/SDD/engineering-harness-v2/SKILL.md` | engineering-harness-v2 | contract | Renamed from agent-harness-v2; gains template seed |
| `/Users/jordanknight/github/tools/skills/SDD/harness-is-the-product-v2/SKILL.md` | harness-is-the-product-v2 | contract | Principle 2 wording + (E)/(A) softening |
| `/Users/jordanknight/github/tools/skills/SDD/plan-1a-v2-explore/SKILL.md` | plan-1a-v2-explore | cross-domain | Subagent 7 reader + orchestrator compound calls |
| `/Users/jordanknight/github/tools/skills/SDD/plan-1b-v2-specify/SKILL.md` | plan-1b-v2-specify | cross-domain | Orchestrator compound calls |
| `/Users/jordanknight/github/tools/skills/SDD/plan-2c-v2-workshop/SKILL.md` | plan-2c-v2-workshop | cross-domain | Orchestrator compound calls |
| `/Users/jordanknight/github/tools/skills/SDD/plan-3-v2-architect/SKILL.md` | plan-3-v2-architect | cross-domain | Orchestrator compound calls + harvest suggestion |
| `/Users/jordanknight/github/tools/skills/SDD/plan-5-v2-phase-tasks-and-brief/SKILL.md` | plan-5-v2-phase-tasks-and-brief | cross-domain | Orchestrator compound calls (light) |
| `/Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase/SKILL.md` | plan-6-v2-implement-phase | cross-domain | Compound calls + end-bubble + final-phase harvest suggestion |
| `/Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md` | plan-6-v2-implement-phase-companion | cross-domain | Companion + farewell envelope mapping + AUTO-harvest at final phase |
| `/Users/jordanknight/github/tools/skills/SDD/plan-6a-v2-update-progress/SKILL.md` | plan-6a-v2-update-progress | cross-domain | Step 8c path + Step 9 round-trip mapping |
| `/Users/jordanknight/github/tools/skills/SDD/plan-7-v2-code-review/SKILL.md` | plan-7-v2-code-review | cross-domain | Compound calls + end-bubble + auto-harvest (rare path) |
| `/Users/jordanknight/github/tools/skills/SDD/plan-8-v2-merge/SKILL.md` | plan-8-v2-merge | cross-domain | Compound calls + end-bubble + auto-harvest |
| `/Users/jordanknight/github/tools/docs/project-rules/engineering-harness.md` (template) | engineering-harness governance | contract | Renamed from agent-harness.md; gains `## Known Difficulties` template seed |
| `/Users/jordanknight/github/tools/AGENTS.md` | governance | cross-domain | New "Compounding Value System" section |
| `/Users/jordanknight/github/tools/CLAUDE.md` | governance | cross-domain | Mirror of AGENTS.md section |
| `/Users/jordanknight/github/tools/README_AGENTS.md` | governance | cross-domain | New catalog section + entries + rename note |
| 8 SDD SKILL.md files (Q5.1 cascade — see Path/Done When column of Task T011) | various | cross-domain | Replace `agent-harness.md` → `engineering-harness.md` cross-references (folded into T011 atomic rename) |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | **Six workshops exhaustively cover the design.** No additional research needed. Workshops are authoritative; plan-3 synthesizes only. | All tasks reference the workshop(s) that locked the relevant decision. Implementer reads the cited workshop before coding the task. |
| 02 | Critical | **30 tasks in one phase (Simple Mode is wide).** User explicitly chose Simple in Q1; this plan respects that. Each task is small (one file edit or one SKILL.md create); the breadth is real but the depth per-task is shallow. | Tasks are sequenced by dependency, not arbitrary order. Plan-6 implements sequentially. Plan-7 reviews at end (and spot-checks sentinel/buffer coverage). No phase fan-out. |
| 03 | High | **Self-modification: `plan-3-v2-architect` is one of the 9 SDD skills receiving a compound-integration body update.** Modifying this skill mid-run is awkward. | Task T022 (plan-3 update) is sequenced LAST among the pipeline-integration tasks (after T013-T021), so this skill's own logic is stable through the rest of the implementation. |
| 04 | High | **All auto-firing skills must check the `docs/compound/.disabled` sentinel before invoking.** Cross-cutting requirement per workshop 004 § D5; if missed in any skill, the user's opt-out leaks. | T013-T022 each include "sentinel-gating check" as part of the body update. T020 (plan-7 update) folds in a spot-check across 2-3 auto-firing skills during review (replaces dedicated grep-audit task). |
| 05 | High | **All auto-firing skills must check `_session-buffer.md` at start.** Cross-cutting per workshop 004 § EC2 (cross-session buffer carryover). If missed, leftover entries from previous session strand. | T013-T022 each include "start-of-skill buffer check" in their body. T020 spot-check covers this as part of plan-7 review. |
| 06 | High | **Minih back-compat is read-only in v1.** Compound-3-harvest reads both `docs/compound/agents/**/*.retro.md` (canonical) AND `docs/retros/*.md` (legacy block format; back-compat parser). No minih changes required for v1. RFC issue coordinates v2 migration. | T009 implements the back-compat reader. T030 drafts (not posts) the minih RFC; user posts when ready. |
| 07 | High | **Dependency-foundation: schemas + compound-0-setup + tree scaffold are prerequisites for EVERYTHING else.** Compound-1/2/3 write to the tree; pipeline integration calls compound-1/2/3; governance docs describe what exists. | Tasks T001-T010 (foundation + compound-0/1/2/3 SKILL.mds + dogfood) come FIRST. Pipeline integration (T013-T022) and governance (T023-T024) come AFTER. Install + dogfood + Compounding Test (T025-T029) come LAST. |
| 08 | Medium | **Cosmetic rename cascade (engineering-harness-v2) touches 8 other SDD skills.** Per Q5.1, this is interpretation A — skill content unchanged, only the name and produced doc filename change. The 8 cascaded skills get cross-reference path updates. | T011 bundles the rename + template seed + 8-skill cross-reference cascade into one atomic task. Legacy `agent-harness.md` filename fallback per AC#19 ensures back-compat for existing user projects. |

---

## Implementation

**Objective**: Ship the Compounding Value System v1 — 4 new compound skills + 1 renamed substrate skill + 9 pipeline-integration body updates + governance doc updates + reversible migration from `docs/retros/` — and validate via 1-week dogfood Compounding Test in this repo.

**Testing Approach**: **Manual + Compounding Test** (workshop 001 four-signal validation at 1 week). No unit tests (skills are markdown; repo convention). Validation surface:
- **Compounding Test signals 1-4** (1-week dogfood window)
- **Anti-vibe walkthroughs** (verify none of 7 anti-vibes triggered)
- **Three imagined sessions A/B/C** from workshop 001 walked against implementation
- **Five-stage flow walkthrough** from workshop 002
- **Portability check** (install via `npx skills` to all 5 supported CLIs)
- **Three-layer integration check** (philosophy → substrate → meta-loop cross-refs)

### Task Sequence Rationale

Tasks ordered by dependency chain:

1. **T001-T009 (Foundation)**: Top-level dir + schemas + compound-0/1/2/3 SKILL.mds. Nothing else can land until the universal schema + foundation skill + producer/curator triple exist.
2. **T010 (Dogfood compound-0-setup)**: Run the foundation skill on jakkaj/tools itself — creates the seed tree for this repo's own use during the rest of implementation.
3. **T011-T012 (Engineering harness substrate)**: Cosmetic rename (incl. 8-skill cross-ref cascade + template seed) + `harness-is-the-product-v2` Principle 2 update. Independent of compound family — can run in parallel with T006-T009 in principle.
4. **T013-T022 (Pipeline integration)**: 9 SDD skill body updates per workshop 004 matrix. Each needs compound-1/2/3 to exist as call targets. T022 (plan-3 self-modify) is LAST.
5. **T023-T024 (Governance docs)**: AGENTS+CLAUDE mirrored section + README_AGENTS catalog update. Need everything else to exist so descriptions are accurate.
6. **T025-T026 (Install + portability)**: `just install-skills` + verify across 5 CLIs.
7. **T027-T029 (Dogfood + Compounding Test + design-review walkthroughs)**: 1-week dogfood window; verify all 4 Compounding Test signals; walk anti-vibes 1-7 + imagined sessions A/B/C.
8. **T030 (Coordination side-task)**: Draft (don't post) the minih RFC.

### Tasks

| Status | ID | Task | Area | Path(s) | Done When | Notes |
|--------|-----|------|------|---------|-----------|-------|
| [ ] | T001 | Create `skills/compound/` top-level dir + `skills/compound/schemas/` subdir | skills/compound/ | `/Users/jordanknight/github/tools/skills/compound/`, `/Users/jordanknight/github/tools/skills/compound/schemas/` | Both directories exist; empty | Foundation — no content yet |
| [ ] | T002 | Write universal retro JSON Schema | schemas | `/Users/jordanknight/github/tools/skills/compound/schemas/retro.schema.json` | File exists; valid JSON; matches workshop 005 § "JSON Schema (the contract)" verbatim | Workshop 005 D5 (7 kinds), D6 (identity), D8 (versioning) |
| [ ] | T003 | Write compound's namespace extension sub-schema | schemas | `/Users/jordanknight/github/tools/skills/compound/schemas/system.compound.schema.json` | File exists; valid JSON; matches workshop 005 § "Compound's namespace sub-schema" verbatim | Lifecycle metadata (`status`, `resolved_by`, harvest counters, `source`) |
| [ ] | T004 | Write minih's namespace extension sub-schema | schemas | `/Users/jordanknight/github/tools/skills/compound/schemas/system.minih.schema.json` | File exists; valid JSON; matches workshop 005 § "Minih's namespace sub-schema" verbatim | Vendored from minih; `run_dir`, `events_count`, `status` |
| [ ] | T005 | Write schemas convention guide + ≥5 test fixtures | schemas | `/Users/jordanknight/github/tools/skills/compound/schemas/README.md`, `/Users/jordanknight/github/tools/skills/compound/schemas/fixtures/{full,minimum,multi-kind,lifecycle,malformed}.retro.md` | README explains schemas + fixtures; ≥5 fixture `.retro.md` files exist covering: full retro, minimum-viable retro, multi-kind retro, lifecycle-metadata-rich retro, malformed retro (negative test); README documents how to validate a retro file by hand against the schema | Workshop 005 § Wire Format Examples (1-3) + § Edge Cases (EC1, EC2, EC7) |
| [ ] | T006 | Write `compound-0-setup` SKILL.md | compound-0-setup | `/Users/jordanknight/github/tools/skills/compound/compound-0-setup/SKILL.md` | SKILL.md has `name: compound-0-setup` + description frontmatter; body covers: (a) first-run scaffold per workshop 006 canonical tree; (b) reversible `docs/retros/` split-migration per workshop 006 § Migration Recipe (parse minih blocks → universal retros via workshop 005 mapping → write per-run files → rename originals to `*.legacy.md` → write `.split-to-compound` breadcrumb); (c) re-entrant re-check that idempotently re-runs any missing scaffold steps; (d) hand-off to `engineering-harness-v2`; (e) `docs/compound/.disabled` sentinel check (silent no-op if present); (f) auto-log of self-scaffold as `type: gift` entry per spec Q6.2 | Spec AC#1, AC#1a, AC#2, AC#3; Workshop 006 § D9, § Migration Recipe; Workshop 005 § D9 round-trip |
| [ ] | T007 | Write `compound-1-track` SKILL.md | compound-1-track | `/Users/jordanknight/github/tools/skills/compound/compound-1-track/SKILL.md` | SKILL.md frontmatter + body covers: (a) silent append-only write to `docs/compound/_buffers/<agent>.session-buffer.md`; (b) entry format (universal Entry schema from workshop 005 — id, kind, description + optional target, severity, workaround, suggested_encoding, references, system.compound); (c) trigger heuristics (tool call > 30s; zero-result search; 2nd retry; backtrack; test/build failure requiring guesswork; magic-wand self-prompt at natural pauses); (d) calibration target ≤1 self-prompt per 5min, ≤5 entries per session; (e) **task-boundary check fires ONLY when buffer is empty** (per Q6.1); (f) `.disabled` sentinel: silent no-op; (g) per-agent buffer = no inter-agent trampling | Spec AC#4, AC#5, AC#6, AC#23 (sentinel); Workshop 001 (anti-vibe 7); Workshop 005 (Entry schema); Workshop 006 (buffer location D3) |
| [ ] | T008 | Write `compound-2-bubble` SKILL.md | compound-2-bubble | `/Users/jordanknight/github/tools/skills/compound/compound-2-bubble/SKILL.md` | SKILL.md frontmatter + body covers: (a) read `docs/compound/_buffers/<agent>.session-buffer.md`; (b) empty buffer = silent (no prompt); (c) single soft prompt with one-line encoding hint per entry + `[s/t/p/e/d/a]` action menu; (d) pressing enter = `[a]ll-save` default; (e) wrap entries in universal retro envelope per workshop 005 schema (set `schema_version`, `retro_id`, `agent`, timestamps, `plan_id` from cwd/branch detection or null); (f) write one `.retro.md` per save action via `resolvePath()` algorithm from workshop 006 § Path Resolver (`docs/compound/agents/<slugified-agent>/<YYYY-MM-DD>/T<HH-MM-SS>Z-<hash>.retro.md`); (g) `[e]ncode` stages diff in `scratch/encode-<entry-id>-<target>.diff`; (h) `[t]ask`/`[p]lan` emit copy-pasteable `/plan-5 --fix` / `/plan-1b` invocations; (i) clear buffer after routing; (j) `.disabled` sentinel: silent no-op; (k) start-of-skill: if buffer non-empty from prior session (cross-session leftover), bubble immediately | Spec AC#7-12, AC#23; Workshop 005 (envelope wrap); Workshop 006 § Path Resolver, § EC2 (carryover); Workshop 004 § Walkthrough D |
| [ ] | T009 | Write `compound-3-harvest` SKILL.md | compound-3-harvest | `/Users/jordanknight/github/tools/skills/compound/compound-3-harvest/SKILL.md` | SKILL.md frontmatter + body covers: (a) scan `docs/compound/agents/**/*.retro.md` (canonical) + `docs/retros/*.md` (legacy back-compat block parser); (b) validate each retro against `retro.schema.json`; skip malformed with warning; (c) dedup by `retro_id` (universal wins over legacy); (d) cluster open entries by kind + target; age-order within cluster; (e) stale flag (`open` >4 weeks; `suggested` >2 weeks without `resolved-by`); (f) prioritized top-10 by recurrence > severity > age; (g) **terminal print only — NO on-disk index/rollup writes** per workshop 006 KISS revision; (h) runtime filters: `--plan <slug>`, `--agent <slug>`, `--since <date>`, `--kind <kind>` (combinable); (i) `[s/t/p/e/d/a/r/w/s]` action menu (the `[r/w/s]` are status-mutation lifecycle ops; mutate `system.compound.status` in-place in the source `.retro.md` file); (j) `--prune --older-than 90d --apply` (dry-run default); (k) `.disabled` sentinel: print "logging disabled" message and exit; (l) start-of-skill: if buffer non-empty, advise to run compound-2-bubble first | Spec AC#13-17, AC#23; Workshop 005 (validation, round-trip); Workshop 006 § "Runtime Views" + § D4 KISS + § D6 pruning + § D7 back-compat |
| [ ] | T010 | Dogfood compound-0-setup: create `docs/compound/` tree for this repo | docs/compound/ | `/Users/jordanknight/github/tools/docs/compound/README.md`, `/Users/jordanknight/github/tools/docs/compound/_buffers/README.md`, `/Users/jordanknight/github/tools/docs/compound/_buffers/.gitignore`, `/Users/jordanknight/github/tools/docs/compound/agents/.gitkeep` | All 4 files exist with content per compound-0-setup spec; running compound-0-setup again is idempotent (no diffs); `docs/retros/` split-migration runs cleanly (no `docs/retros/*.md` to migrate in this repo, but breadcrumb pattern is documented if/when minih starts producing) | Workshop 006 § Canonical Tree; this is the dogfood — proves T006 works |
| [ ] | T011 | Rename `agent-harness-v2` → `engineering-harness-v2` (skill + governance doc + template seed + 8-skill cross-ref cascade) | engineering-harness-v2 + various | git mv `/Users/jordanknight/github/tools/skills/SDD/agent-harness-v2/` → `/Users/jordanknight/github/tools/skills/SDD/engineering-harness-v2/`; edit `/Users/jordanknight/github/tools/skills/SDD/engineering-harness-v2/SKILL.md`; cascade-edit 8 SDD SKILL.md files | (a) Directory renamed; `SKILL.md` `name:` frontmatter updated; description uses "engineering harness" umbrella term; body unchanged (Q5.1 Interpretation A — cosmetic). (b) Skill body documents that it now produces `docs/project-rules/engineering-harness.md`; legacy filename fallback reads `agent-harness.md`/`harness.md`, prefers `engineering-harness.md` for new writes (AC#19). (c) Produced doc template gains `## Known Difficulties` section auto-populated with up to 10 most-relevant entries from `docs/compound/` (filtered by `target: engineering-harness | tooling | infra`; sorted by recurrence). (d) The 8 cross-referencing SDD skills (`plan-0-v2-constitution`, `plan-1a-v2-explore`, `plan-2-v2-clarify`, `plan-3-v2-architect`, `plan-4-v2-complete-the-plan`, `plan-5-v2-phase-tasks-and-brief`, `plan-6-v2-implement-phase`, `plan-6-v2-implement-phase-companion`) have all `agent-harness.md` references replaced with `engineering-harness.md`; verify via `grep -rl 'agent-harness.md' skills/SDD/` before/after | Spec AC#18, AC#19, AC#20; Q5.1 cascade |
| [ ] | T012 | Update `harness-is-the-product-v2`: Principle 2 wording + soften disambiguation | harness-is-the-product-v2 | `/Users/jordanknight/github/tools/skills/SDD/harness-is-the-product-v2/SKILL.md` | Principle 2 heading: "Track Velocity Compounding" → "Track Compounding Value"; body keeps minih's "compound velocity hypothesis" as a referenced term; "Two harnesses, one principle" callout softened to "Engineering harness encompasses substrate + agent-facing overlay"; `(E)`/`(A)`/`(both)` principle tag system collapsed (probably `(E)` for the broader umbrella with `(substrate)` / `(agent)` sub-tags inside principle bodies where the distinction matters) | Spec Q5.1 cascade; Q5.4 |
| [ ] | T013 | Update `plan-1a-v2-explore` for compound integration | plan-1a-v2-explore | `/Users/jordanknight/github/tools/skills/SDD/plan-1a-v2-explore/SKILL.md` | (a) Subagent 7 reads `docs/compound/agents/**/*.retro.md` + back-compat `docs/retros/*.md`; (b) validates each retro frontmatter against `retro.schema.json`; (c) filters retros relevant to current research (by `plan_id` if plan detected, by recency otherwise); (d) adds "compound activity" one-liner to research dossier's Prior Learnings header (e.g. "✓ 8 entries from prior sessions referenced — 3 encoded, 5 open"); (e) orchestrator-side compound-1-track calls during research (NOT subagent-side — D6 defers to v2); (f) auto-fire compound-2-bubble at end of plan-1a (logical pause); (g) suggest compound-3-harvest at start if ≥5 unharvested entries (print one-liner; don't auto-fire); (h) `.disabled` sentinel check before all auto-invocations; (i) start-of-skill `_session-buffer.md` check | Workshop 004 § Per-Skill Integration Matrix; Spec AC#21, AC#23 |
| [ ] | T014 | Update `plan-1b-v2-specify` for compound integration | plan-1b-v2-specify | `/Users/jordanknight/github/tools/skills/SDD/plan-1b-v2-specify/SKILL.md` | Orchestrator-side compound-1-track calls during spec writing; chains to plan-2 (no end-bubble — chained handoff); sentinel + buffer-check at start | Workshop 004 § Per-Skill Integration Matrix |
| [ ] | T015 | Update `plan-2c-v2-workshop` for compound integration | plan-2c-v2-workshop | `/Users/jordanknight/github/tools/skills/SDD/plan-2c-v2-workshop/SKILL.md` | Orchestrator-side compound-1-track calls during workshop creation; chains back to plan-2/plan-3 (no end-bubble); sentinel + buffer-check at start | Workshop 004 § Per-Skill Integration Matrix |
| [ ] | T016 | Update `plan-5-v2-phase-tasks-and-brief` for compound integration | plan-5-v2-phase-tasks-and-brief | `/Users/jordanknight/github/tools/skills/SDD/plan-5-v2-phase-tasks-and-brief/SKILL.md` | Orchestrator-side compound-1-track (light — fewer trigger points); chains to plan-6 (no end-bubble); sentinel + buffer-check at start | Workshop 004 § Per-Skill Integration Matrix |
| [ ] | T017 | Update `plan-6-v2-implement-phase` for compound integration | plan-6-v2-implement-phase | `/Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase/SKILL.md` | (a) compound-1-track during work using same trigger heuristics as compound-1-track's defaults; (b) per-phase auto-fire compound-2-bubble at end-of-phase (logical pause); (c) after FINAL phase: suggest compound-3-harvest if ≥10 unharvested entries (print invocation; no auto-fire — solo `/plan-6` flow is rare); (d) end-of-phase output reminds user `/compound-2-bubble` if entries accumulated; (e) sentinel + buffer-check | Workshop 004; Spec AC#22a |
| [ ] | T018 | Update `plan-6-v2-implement-phase-companion` for compound integration | plan-6-v2-implement-phase-companion | `/Users/jordanknight/github/tools/skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md` | All of T017 PLUS: (a) reference the three layers (philosophy / substrate / meta-loop); (b) document the **companion farewell envelope → universal retro mapping**: `farewell.retrospective.magicWand` → entry with `kind: magic-wand` and target from `magicWandTarget`; `farewell.retrospective.difficulties[]` → entries with `kind: difficulty`; `farewell.retrospective.workedWell` → entry with `kind: gift`; `farewell.retrospective.confusing` → entry with `kind: confusion`; `farewell.retrospective.coordination` → entry with `kind: coordination`; `farewell.retrospective.improvementSuggestions[]` → entries with `kind: improvement-suggestion`; reference workshop 005 § D9 for mapping logic; (c) frame the companion as a SECOND PRODUCER of compound entries alongside orchestrator's calls; both producers' outputs land via plan-6a Step 9; (d) **AUTO-fire `/compound-3-harvest` at end of FINAL-phase debrief** (replaces /plan-7 as harvest anchor for the dominant flow); (e) end-of-phase output reminds user `/compound-2-bubble` for orchestrator-side buffer; (f) sentinel + buffer-check | Workshop 004 § Per-Skill Integration Matrix + § The Four Firing Sites; Workshop 005 § D9; Spec AC#22b |
| [ ] | T019 | Update `plan-6a-v2-update-progress` for compound integration | plan-6a-v2-update-progress | `/Users/jordanknight/github/tools/skills/SDD/plan-6a-v2-update-progress/SKILL.md` | (a) Step 8c path update: `docs/retros/` → `docs/compound/` (one-line); (b) Step 9 runs `minihToUniversal()` mapping (per workshop 005 § D9 TypeScript pseudocode — agent implements inline; no separate lib in v1); (c) Step 9 writes one per-run `.retro.md` via `resolvePath()` from workshop 006 (path: `docs/compound/agents/<sanitized-companion-slug>/<date>/T<time>Z-<hash>.retro.md`); (d) `system.minih.run_dir` populated from companion's run dir; (e) sentinel check | Workshop 004; Workshop 005 § D9, § Walkthrough A; Workshop 006 § Path Resolver; Spec AC#22 |
| [ ] | T020 | Update `plan-7-v2-code-review` for compound integration | plan-7-v2-code-review | `/Users/jordanknight/github/tools/skills/SDD/plan-7-v2-code-review/SKILL.md` | Orchestrator-side compound-1-track during review; auto-fire compound-2-bubble at end (logical pause); auto-fire compound-3-harvest at end (preserved for rare solo `/plan-6` flow per workshop 004 § Walkthrough B); sentinel + buffer-check; **spot-check 2-3 auto-firing skills for sentinel + buffer-check coverage as part of review** (replaces dedicated grep-audit task) | Workshop 004 § Per-Skill Integration Matrix; Findings 04, 05 |
| [ ] | T021 | Update `plan-8-v2-merge` for compound integration | plan-8-v2-merge | `/Users/jordanknight/github/tools/skills/SDD/plan-8-v2-merge/SKILL.md` | Orchestrator-side compound-1-track during merge analysis; auto-fire compound-2-bubble at end (pipeline endpoint); auto-fire compound-3-harvest at end (plan-completion reflection moment); sentinel + buffer-check | Workshop 004 § The Four Firing Sites |
| [ ] | T022 | Update `plan-3-v2-architect` for compound integration (SELF-MODIFY — last among pipeline edits) | plan-3-v2-architect | `/Users/jordanknight/github/tools/skills/SDD/plan-3-v2-architect/SKILL.md` | Orchestrator-side compound-1-track during architect work; auto-fire compound-2-bubble at end (logical pause — plan complete); suggest compound-3-harvest at start if ≥10 unharvested entries (print invocation; no auto-fire); sentinel + buffer-check; **modify this skill LAST** among the pipeline updates to keep its logic stable through T013-T021 | Workshop 004 § Per-Skill Integration Matrix; Finding 03 (self-modification ordering) |
| [ ] | T023 | Add "Compounding Value System" section to AGENTS.md + mirror in CLAUDE.md | governance | `/Users/jordanknight/github/tools/AGENTS.md`, `/Users/jordanknight/github/tools/CLAUDE.md` | Section heading "Compounding Value System"; 10-15 lines describing the three layers (philosophy / substrate / meta-loop), the umbrella slug `compound`, the four compound-N skills, the `docs/compound/` ledger surface, the `.disabled` opt-out, the back-compat read of `docs/retros/`; D7 voice (operational-contract with one-sentence story preamble linking to `harness-is-the-product-v2`); pointer to spec + workshops for depth; both files contain identical content (mirrored; accept short-term drift) | Spec AC#26, AC#27; Workshop 001 D7 |
| [ ] | T024 | Update `README_AGENTS.md` with compound catalog section + engineering-harness-v2 rename note | governance | `/Users/jordanknight/github/tools/README_AGENTS.md` | New section `## Compound — Compounding Value System` with 4 catalog entries (compound-0-setup, compound-1-track, compound-2-bubble, compound-3-harvest); update existing `agent-harness-v2` catalog row → `engineering-harness-v2` (with the rename note); update categories table to add `compound/` row | Spec; Workshop 001 D7 |
| [ ] | T025 | Install all skills via `just install-skills` | quality | (command) | `npx skills@latest add jakkaj/tools -a claude-code -a codex -a opencode -a github-copilot -a pi -g` succeeds; `~/.claude/skills/compound-0-setup`, `~/.claude/skills/compound-1-track`, `~/.claude/skills/compound-2-bubble`, `~/.claude/skills/compound-3-harvest` exist as symlinks; `~/.claude/skills/engineering-harness-v2` exists (renamed); `~/.claude/skills/agent-harness-v2` is gone | Spec AC#24 (portability across 5 CLIs) — but for v1 dogfood, claude-code only is enough |
| [ ] | T026 | Verify portability: install to all 5 supported CLIs | quality | (commands) | Above install succeeds for each of `-a claude-code`, `-a codex`, `-a github-copilot`, `-a opencode`, `-a pi`; each CLI's skill dir contains the 4 compound skills (or their canonical universal-path symlinks); no minih binary required; no `MINIH_*` env var required | Spec AC#24 |
| [ ] | T027 | Dogfood week — emit and triage compound entries against the system itself | dogfood | `/Users/jordanknight/github/tools/docs/compound/` (writes accumulate here) | After ≥7 days of normal use: `docs/compound/agents/claude-code/` contains ≥3 dated subdirs with `.retro.md` files; entries cover at least 3 of 7 kinds; at least one entry has `system.compound.status` advanced from `open` → `encoded` | Spec § Compounding Test signals |
| [ ] | T028 | Verify Compounding Test — all 4 signals pass | dogfood | (manual check of session transcripts + `docs/compound/agents/**/*.retro.md`) | Single 4-item observational checklist after the dogfood week: **(1)** ≥1 user action `[t/p/e]` chosen (not just `[a]ll-save` / `[d]ismiss`); **(2)** ≥1 `.retro.md` has `system.compound.status: encoded` AND `system.compound.resolved_by:` set (grep `'status: encoded'`); **(3)** ≥1 subsequent session surfaces a compound entry — either via plan-1a Subagent 7 Prior Learnings citation OR via `engineering-harness.md § Known Difficulties` boot-read; **(4)** user has NOT added any compound skill to a "skills I always disable" list AND `docs/compound/.disabled` is absent in jakkaj/tools | Spec AC#28 (all 4 signals) |
| [ ] | T029 | Manual design-review walkthroughs (anti-vibes + imagined sessions) | quality | (manual walkthrough against workshop 001) | (a) For each of anti-vibes 1-7 (nag-ware, ceremony, silent journal, lecture mode, auto-magic, schema-driven UX, agent over-introspection): document one concrete piece of evidence the implementation does NOT trigger it. (b) Walk three imagined sessions A/B/C from workshop 001: Session A (code review with 2 difficulties) — bubble fires, user picks `[t]`, one task invocation emitted; Session B (planning research with 1 magic-wand) — bubble fires, user picks `[a]`, entry saved to plan-scope file; Session C (typo fix with no entries) — bubble silent | Workshop 001 anti-vibes 1-7 + imagined sessions; Spec AC#25 |
| [ ] | T030 | Draft minih RFC issue (do NOT post) | coordination | (text file in `scratch/`) | Draft saved as `scratch/minih-rfc-draft.md`; body references spec + workshops 004/005/006; proposes universal schema adoption + per-run isolation layout + 3-phase migration (dual-write → compound canonical → minih drops legacy); user posts when ready (out-of-scope for this plan to auto-post) | Workshop 005 § "Acceptance Criteria for the minih RFC"; Workshop 006 § D7 |

### Acceptance Criteria

[All criteria sourced from spec § Acceptance Criteria — references AC#1 through AC#28 as numbered there.]

**`compound-0-setup`** (T006, T010):
- [ ] AC#1: First-run scaffold creates the minimal canonical tree per workshop 006 (README.md, _buffers/README.md, _buffers/.gitignore, agents/.gitkeep). No `sessions/`, `_LEDGER.md`, or `plans/` subdirs.
- [ ] AC#1a: First-run `docs/retros/` split-migration: parse each block, write per-run `.retro.md` via workshop 005 mapping, rename originals to `*.legacy.md`, write `.split-to-compound` breadcrumb. Idempotent on re-runs.
- [ ] AC#2: Hand-off to `engineering-harness-v2` invoked or staged.
- [ ] AC#3: Re-entrant re-check is non-destructive on existing tree.

**`compound-1-track`** (T007):
- [ ] AC#4: Silent on no friction (zero entries logged; user sees nothing).
- [ ] AC#5: Append-only writes to `_buffers/<agent>.session-buffer.md` with universal Entry schema (id, kind, description + optionals).
- [ ] AC#6: Magic-wand check rate ≤ 1 per 5 min; entries-per-session avg ≤ 5 (anti-vibe 7 calibration).

**`compound-2-bubble`** (T008):
- [ ] AC#7: Empty buffer = silent.
- [ ] AC#8: Single soft prompt with `[s/t/p/e/d/a]` menu; one-line encoding hint per entry.
- [ ] AC#9: Default = `[a]ll-save`; wraps entries in universal retro envelope; writes one `.retro.md` at `agents/<slug>/<date>/T<time>Z-<hash>.retro.md`; sets `frontmatter.plan_id` from cwd/branch detection.
- [ ] AC#10: `[e]ncode` stages `scratch/encode-<id>-<target>.diff`; nothing auto-applied.
- [ ] AC#11: `[t]ask` / `[p]lan` emit copy-pasteable `/plan-5 --fix` / `/plan-1b` invocations.
- [ ] AC#12: Buffer cleared after routing.

**`compound-3-harvest`** (T009):
- [ ] AC#13: Reads `docs/compound/agents/**/*.retro.md` + `docs/retros/*.md` (back-compat); validates each against `retro.schema.json`; dedups by `retro_id`; in-memory view printed to terminal (no on-disk index).
- [ ] AC#14: Curates view — dedup, cluster, age-order within clusters.
- [ ] AC#15: Stale flag (`open` >4 weeks; `suggested` >2 weeks).
- [ ] AC#16: Prioritised top-10 by recurrence > severity > age; `[s/t/p/e/d/a/r/w/s]` menu.
- [ ] AC#17: In-place status mutations on `[r/w/s]` (mutate `system.compound.status` in source file).

**`engineering-harness-v2`** (T011):
- [ ] AC#18: Skill renamed; SKILL.md frontmatter `name:` updated.
- [ ] AC#19: Governance doc renamed; legacy filename fallback (read `agent-harness.md` / `harness.md`) preserved.
- [ ] AC#20: Template `## Known Difficulties` seeded from compound ledger (up to 10 entries).

**Pipeline touchpoints** (T013, T019, T017-T018):
- [ ] AC#21: plan-1a Subagent 7 reads compound + back-compat; surfaces entries in research dossier with `PL-NN` numbering.
- [ ] AC#22: plan-6a Step 8c path updated `docs/retros/` → `docs/compound/`.
- [ ] AC#22a: plan-6 calls compound-1-track during work; end-of-phase reminder.
- [ ] AC#22b: plan-6-companion documents farewell envelope → universal retro mapping; AUTO-fires compound-3-harvest at FINAL phase.

**Cross-cutting** (T013-T022, T023-T024, T020 spot-check):
- [ ] AC#23: `docs/compound/.disabled` sentinel honoured (silent no-op for compound-1-track; "logging disabled" message for compound-2-bubble + compound-3-harvest; ALL auto-firing skills check sentinel before invoking).
- [ ] AC#24: Portable across 5 CLIs (claude-code, codex, github-copilot, opencode, pi) via `npx skills`; no minih dependency.
- [ ] AC#25: None of 7 anti-vibes triggered (verified by walking imagined sessions A/B/C).
- [ ] AC#26: AGENTS.md + CLAUDE.md describe the system as a contract (10-15 lines mirrored; D7 voice).
- [ ] AC#27: Three-layer stack documented in AGENTS.md / CLAUDE.md.

**Dogfood validation** (T027-T028):
- [ ] AC#28: 1-week Compounding Test passes: Signal 1 (action chosen) ✓; Signal 2 (entry encoded with resolved-by) ✓; Signal 3 (subsequent session surfaces entry) ✓; Signal 4 (user has not disabled) ✓.

### Risks

[From spec § Risks, refined for this plan:]

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| R1 — Agent compliance with `compound-1-track` is too low | medium | high | Hybrid trigger (agent-self-invoked + manual `/compound-2-bubble` escape); 9 pipeline skills auto-invoke during their work; Compounding Test signal #1 measures at 1 week. Per best-effort framing, low compliance is acceptable for v1 — the system fails GRACEFULLY (empty buffers → silent bubbles → no friction added) |
| R3 — Reader-side updates land but readers don't surface entries usefully | medium | high | Dogfood week + Compounding Test signal #3 measures directly. If dogfood shows entries land but research dossier readers ignore them, the reader-side surfacing UX gets its own follow-up workshop (queued as optional follow-up in spec) |
| R4 — User dismisses bubble every time | medium | high | Workshop 001 D5 (terse + one-line encoding hint per entry); if dismiss-rate >80% after 1 week, encoding hints need iteration via the queued "bubble-up CLI flow" workshop |
| R6 — Three-file mirror drift (AGENTS.md / CLAUDE.md / README_AGENTS.md) | low | low | Mirrors are 10-15 lines, change rarely; T023 keeps AGENTS+CLAUDE in one atomic edit. If drift becomes real, handle as one-off manual fix; no script automation. |
| R7 — Minih interop tension during dogfood | medium | medium | Schema workshop 005 locks the round-trip; back-compat reader handles legacy `docs/retros/` block format without minih changes; RFC issue (T030) coordinates v2 minih native adoption |
| R-NEW1 — Self-modification of plan-3 mid-run | low | medium | T022 sequenced LAST among pipeline edits; skill's own logic stable through T013-T021 (Finding 03) |
| R-NEW2 — Dependency chain breakage (compound-1/2/3 missing when pipeline skills reference them) | low | medium | T001-T010 (foundation) sequenced FIRST; T011-T022 (rename + pipeline) sequenced after; verified by plan-7 review + T020 spot-check (Finding 07) |
| R-NEW3 — Three queued workshops left undone (bubble-up CLI flow / AGENTS.md voice / harvest companion behavior) | low | low | Per spec § Workshop Opportunities, all three are independent of plan-3 consumption. Plan-3 proceeds with best-effort defaults from workshops 001-006; queued workshops can run post-implementation if dogfood surfaces UX gaps |

---

## Next Steps

**Simple Mode**: skip plan-5; go directly to plan-6.

- **Optional**: `/plan-4-v2-complete-the-plan --plan ./docs/plans/023-difficulty-ledger-skill/difficulty-ledger-skill-plan.md` for validation readiness check
- **Ready to implement**: `/plan-6-v2-implement-phase --plan ./docs/plans/023-difficulty-ledger-skill/difficulty-ledger-skill-plan.md`
- **Optional pre-implementation**: run the 3 queued workshops (bubble-up CLI flow · AGENTS.md voice · harvest companion behavior) to tighten T008 / T025-T027 / T009 respectively. Workshops are independent; can also run post-implementation if dogfood surfaces gaps.
- **Coordination side-task**: post the minih RFC (T030 drafts it; user posts) once spec + workshops are pushed to `jakkaj/tools` `main` so the RFC's documentation links resolve.

---

✅ **Plan created** (trimmed via /validate-v2 elegance pass — 40 → 30 tasks; merges + 2 drops; no scope change):
- Location: `/Users/jordanknight/github/tools/docs/plans/023-difficulty-ledger-skill/difficulty-ledger-skill-plan.md`
- Phases: 1 (Simple Mode)
- Tasks: 30
- Areas: 5 new + 15 existing modified
- Workshops consumed: 6 (001 vibe / 002 flow / 003 system map / 004 SDD integration / 005 retro schema / 006 folder layout)
- Acceptance criteria: 28 (sourced from spec)
- Risks: 7 (4 from spec + 3 new to this plan)

**Next step**: run `/plan-6-v2-implement-phase --plan ./docs/plans/023-difficulty-ledger-skill/difficulty-ledger-skill-plan.md` to begin implementation (or `/plan-4-v2-complete-the-plan --plan ...` for an optional readiness validation pass first).
