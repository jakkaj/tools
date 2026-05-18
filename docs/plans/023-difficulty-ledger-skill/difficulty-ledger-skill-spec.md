# Compounding Value System

**Mode**: Simple

> **First-class concept**: "Compounding Value System" is the formal name; **`compound`** is the slug used throughout (folder paths, skill names, file references). It is a first-class concept in this repo's skills graph — alongside the SDD pipeline, general-purpose skills, and personal skills.

> **Plan folder name**: `023-difficulty-ledger-skill` (kept for stable cross-references from the dossier + 3 workshops + flight plan; the title and content reflect the Compounding Value System restructure that happened during clarification).

📚 This specification incorporates findings from [`research-dossier.md`](./research-dossier.md) and authoritative design decisions from three workshops:
- [`workshops/001-self-improvement-vibe.md`](./workshops/001-self-improvement-vibe.md) — vibe + 8 design decisions + 7 anti-vibes
- [`workshops/002-end-to-end-flow.md`](./workshops/002-end-to-end-flow.md) — five-stage loop + 6 inter-stage contracts
- [`workshops/003-compound-system-map.md`](./workshops/003-compound-system-map.md) — three-layer stack + ecosystem map

---

## Research Context

The compounding-value promise in `harness-is-the-product-v2` Principle 2 ("every difficulty catalogued is a gift to future sessions") is currently broken in this repository. Two existing producers — `plan-6a-v2-update-progress` (orchestrator + companion retros) and minih's auto-harvest — write structured retrospectives to a ledger directory. **No skill in the SDD pipeline reads from that directory.** The legacy `## Discoveries & Learnings` table convention has one reader (`plan-1a-v2-explore` Subagent 7), but it does not see the new ledger. Twenty-five of twenty-nine SDD skills neither write nor read difficulty entries. The most common agent session — anything outside `plan-6` invocation — emits zero ledger entries.

The three-workshop pass through plan 023 produced a sharper architecture than the original spec sketched: a **three-layer stack** (philosophy / substrate / meta-loop), a **compound family** of four small skills replacing the originally-proposed monolithic producer + consumer pair, and a unified **`docs/compound/`** umbrella directory replacing the earlier `docs/retros/`. The "compounding value" framing supersedes minih's narrower "compounding velocity" — captured value compounds session-over-session regardless of whether it manifests as speed.

---

## Summary

This plan delivers the **Compounding Value System** — a three-layer architecture (philosophy / substrate / meta-loop) that closes both ends of the compounding loop. Every agent session in any supported CLI can contribute friction observations to a unified ledger; periodic curation surfaces those observations as actionable improvements; encoded fixes land in the engineering harness (or other targets); future sessions inherit the improved environment via two reader paths (a substrate-template seed and an SDD-pipeline subagent read).

The system is a **first-class concept** in this repo's skills graph. It joins the SDD pipeline, general-purpose skills, and personal skills as a peer category. The slug `compound` is used in folder paths, skill names, file references, and AGENTS.md section headings; the formal name "Compounding Value System" is used in titles, prose, and external-facing documentation.

**The three layers**:

1. **Philosophy layer** — `harness-is-the-product-v2` (existing skill, unchanged). States the principle: *the harness is the product; encode, don't document; gifts to your future self*. Re-entrant; called for re-grounding at session start or context drift.
2. **Substrate layer** — `engineering-harness-v2` (renamed from `agent-harness-v2`). Establishes and audits the engineering harness (justfile recipes, dev scripts, test runner, seed scripts, env config, boot command). Produces and maintains `docs/project-rules/engineering-harness.md`. Its template's `## Known Difficulties` section is auto-seeded from the compound ledger so every agent reads accumulated friction at boot.
3. **Meta-loop layer** — the **compound family** (4 new skills under `skills/compound/`):
   - `compound-0-setup` — one-time scaffold + re-entrant re-check (creates `docs/compound/`, stages diffs for AGENTS.md / CLAUDE.md / README_AGENTS.md / justfile, hands off to engineering-harness-v2)
   - `compound-1-track` — silent log + magic-wand check at natural pauses (called by the agent during work)
   - `compound-2-bubble` — single soft prompt at session end with `[s/t/p/e/d/a]` action menu (save / fix-task / plan / encode / dismiss / all-save)
   - `compound-3-harvest` — periodic curation (typically post-`/plan-7-v2-code-review`): reads all ledger files, deduplicates, clusters, age-orders, surfaces a prioritised summary with `[s/t/p/e/d/a/r/w/s]` actions (the additional `[r/w/s]` are status-mutation lifecycle ops)

**The umbrella concept**: every self-improvement artifact lives under **`docs/compound/`** in a minimal tree (per workshop 006): `agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` per-run files, `_buffers/<agent>.session-buffer.md` transient buffers, `README.md` convention guide, optional `.disabled` opt-out sentinel. **NO on-disk index / rollup files** — cross-cutting views (per-plan, per-agent, dashboard) are computed at read time by `compound-3-harvest` and printed to the terminal. One umbrella, one schema (workshop 005), one canonical layout (workshop 006).

**The integration model**: components communicate through file surfaces (`docs/compound/`, `scratch/`, governance docs), never through direct skill-to-skill calls. The schema (deferred to a follow-up workshop) is the inter-component contract.

**Portability**: all skills work in any CLI consuming Anthropic SKILL.md (Claude Code, Codex CLI, Copilot CLI, Pi, OpenCode); no minih runtime dependency. Minih retros are read via the universal contract (workshop 005) with deterministic round-trip mapping; the importer is now in v1 (per workshop 005 § D9 reversal) via `minihToUniversal()` / `universalToMinih()` helpers. Minih continues to write its native `docs/retros/<slug>.md` until v2 (P3 migration); compound-3-harvest's back-compat reader picks those up alongside the canonical `docs/compound/agents/**/*.retro.md` files.

---

## Goals

### Philosophy layer
- The principle ("encode, don't document; gifts to your future self") stays first-class. `harness-is-the-product-v2` keeps its current re-grounding role; Principle 2 may want a small wording update from "Track Velocity Compounding" → "Track Compounding Value" to align language across the three layers.

### Substrate layer
- The engineering harness has a single auditor + scaffolder skill (`engineering-harness-v2`) that produces `docs/project-rules/engineering-harness.md` with a template that auto-seeds `## Known Difficulties` from the compound ledger.
- New agent sessions read `engineering-harness.md` at boot and inherit accumulated project friction without re-discovery.

### Meta-loop layer
- Every agent session in any supported CLI can contribute to the ledger (not just `plan-6` invocations).
- The agent self-introspects at natural pauses ("if I had a magic wand right now?") — the most honest friction signal because agents don't adapt the way humans do.
- The user is silent during work; soft at the end. One batched prompt per session. Never asks twice.
- Escalation is one keystroke: save / fix-task / plan / encoded-knowledge / dismiss.
- Encoded fixes are staged as reviewable diffs in `scratch/` — never auto-applied.
- Periodic curation (post-code-review) surfaces accumulated entries as actionable improvements and keeps the ledger current (status mutations: encoded / wontfix / still-active).

### Cross-cutting
- `docs/compound/` is the single integration surface; components communicate through files, not direct calls. The same schema works for entries from `compound-1-track`, `compound-2-bubble`, `compound-3-harvest`, `plan-6a-v2-update-progress`, and minih.
- AGENTS.md and CLAUDE.md describe the loop as an operational contract a fresh agent or human grasps in under 60 seconds.
- The system costs less attention than the friction it captures — if logging + bubbling + harvesting exceeds the cognitive cost of the friction itself, the loop is net-negative and must be revised.
- The system honours the seven anti-vibes from the vibe workshop (no nag-ware, bureaucratic ceremony, silent journal, lecture mode, auto-magic, schema-driven UX, agent over-introspection).

---

## Non-Goals

- **Not a runtime.** No skill boots processes, owns daemons, or maintains state outside the ledger files.
- **Not a replacement for minih's auto-harvest.** Minih continues to write its native `docs/retros/<slug>.md` (and per-plan ledger when `MINIH_PLAN_ID` set) until v2 P3 migration. Compound's back-compat reader (workshop 006 § D7) reads `docs/retros/*.md` alongside the canonical `docs/compound/agents/**/*.retro.md`. The universal-schema dual-write phase (workshop 005 P1) ships in v1.
- ~~**Not a minih importer in v1.**~~ **REVERSED** by workshop 005 (universal retro contract): the minih ↔ universal round-trip is now an in-scope v1 deliverable, implemented as `minihToUniversal()` / `universalToMinih()` helpers under `skills/compound/lib/retro.ts`. plan-6a Step 9 calls the helper inline; minih's existing `retrospective.json` survives unchanged via dual-write (Migration Phase 1 per workshop 005 § Migration Path).
- **Not auto-applying any fix.** Every encoded change is staged as a unified diff in `scratch/` for the user to review and `git apply`.
- **Not mid-session prompting.** The bubble-up at session end is the only user-facing surface during a session. The agent's internal magic-wand self-check is silent to the user.
- **Not a JSON Schema validator.** The ledger schema is YAML-fenced markdown — machine-parseable, not validated by a runtime in v1.
- **Not a ledger dashboard / cross-plan analytics.** Per workshop 006 KISS revision, there is no on-disk `_LEDGER.md` or other rollup file. `compound-3-harvest` computes cross-cutting views at read time (filters: `--plan` / `--agent` / `--since` / `--kind`) and prints to terminal. Deeper analytics are deferred to a follow-up plan.
- **Not bureaucratic ceremony.** No rating prompts, no satisfaction surveys, no required free-form fields. Anti-vibes 1–7 from the vibe workshop are explicit rejections.
- **Not a forced behavior.** A `docs/compound/.disabled` sentinel makes `compound-1-track` a silent no-op for projects that opt out.
- **Not a separate `compound-1-explore` skill.** The Stage 1 (explore) read is fulfilled by `plan-1a-v2-explore` Subagent 7 + `engineering-harness.md § Known Difficulties` template seeding. Cross-skill domain leak accepted as a deliberate tradeoff.
- **Not modifying `plan-3-v2-architect` or `plan-7-v2-code-review` in v1.** Both are deferred from this plan; the harvest companion is intended to run *after* `plan-7`, not modify it.

---

## Target Domains

This repository does not use the formal `docs/domains/` system (no `docs/domains/registry.md`). Per the convention for repos without a domain registry, the table below maps the feature's **scope areas** in lieu of formal domain boundaries. None require new `domain.md` files.

| Area | Status | Relationship | Role in This Feature |
|------|--------|-------------|---------------------|
| `skills/compound/` (top-level category) | **NEW** | **create** | New top-level skill category (alongside SDD/, general/, personal/). Houses the four meta-loop skills. |
| `skills/compound/compound-0-setup/` | **NEW** | **create** | Scaffold + re-entrant re-check |
| `skills/compound/compound-1-track/` | **NEW** | **create** | Silent log + magic-wand check during work |
| `skills/compound/compound-2-bubble/` | **NEW** | **create** | Session-end soft prompt + `[s/t/p/e/d/a]` action routing |
| `skills/compound/compound-3-harvest/` | **NEW** | **create** | Periodic curation + status mutations (`[r/w/s]` lifecycle ops) |
| `skills/SDD/engineering-harness-v2/` | existing | **rename + modify** | Renamed from `agent-harness-v2`. Template gains `## Known Difficulties` seeded from `docs/compound/` ledger. **Rename interpretation pending** — see Open Q1. |
| `docs/project-rules/engineering-harness.md` | existing | **rename** | Renamed from `agent-harness.md`. Produced + maintained by `engineering-harness-v2`. |
| `skills/SDD/harness-is-the-product-v2/` | existing | **modify (small)** | Principle 2 wording updated from "Track Velocity Compounding" → "Track Compounding Value" to align with the compound family's framing. Content unchanged otherwise. |
| `skills/SDD/plan-1a-v2-explore/` | existing | **modify** | Subagent 7 ("Prior Learnings Scout") extends to read `docs/compound/agents/**/*.retro.md` (canonical per workshop 006) AND `docs/retros/*.md` (minih legacy back-compat) in addition to the legacy `## Discoveries & Learnings` tables. Validates each retro frontmatter against `retro.schema.json` (workshop 005); skips malformed retros with a warning. |
| `skills/SDD/plan-6a-v2-update-progress/` | existing | **modify (one-line)** | Step 8c hardcoded path updated from `docs/retros/` → `docs/compound/`. |
| `skills/SDD/plan-6-v2-implement-phase/` | existing | **modify** | (a) Skill body adds compound vocabulary in the Track stage — explicitly invokes `compound-1-track` at natural friction points during implementation work (not just phase-end via plan-6a). (b) Cross-references `harness-is-the-product-v2` (philosophy) + `compound-0/1/2/3` family + `engineering-harness-v2` substrate. (c) End-of-phase output reminds the user to run `compound-2-bubble` (in addition to the existing plan-6a auto-call). |
| `skills/SDD/plan-6-v2-implement-phase-companion/` | existing | **modify** | Same as `plan-6-v2-implement-phase` PLUS: (a) Skill body documents the **companion farewell envelope → compound entry mapping** (`farewell.retrospective.magicWand` → compound `type: magic-wand`; `farewell.retrospective.difficulties[]` → compound `type: difficulty`; `farewell.retrospective.workedWell` → compound `type: gift`). (b) Power-On-Mode protocol section explicitly frames the companion as a **second producer** of compound entries that lands via plan-6a Step 9's auto-harvest. (c) Cross-references the schema workshop's minih round-trip mapping rules. |
| `docs/compound/` | **NEW** | **create** | The umbrella directory. Minimal canonical tree per workshop 006: `README.md` (convention guide), `_buffers/<agent>.session-buffer.md` (transient per-agent buffers; gitignored), `agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` (per-run universal `.retro.md` files; only source of truth), optional `.disabled` sentinel. **No on-disk index / `_LEDGER.md` / `sessions/` / per-plan-rollup files** — cross-cutting views computed at read time by `compound-3-harvest`. |
| `AGENTS.md` · `CLAUDE.md` | existing | **modify** | Add a "Compounding Value System" operational-contract section (10–15 lines each, mirrored content; D7 voice from workshop 001). Names the three layers; points at the slug `compound` for folder/skill conventions. |
| `README_AGENTS.md` | existing | **modify** | Add `compound/` category section ("Compounding Value System") + 4 catalog entries; add the `engineering-harness-v2` rename note. |
| `justfile` | existing | **modify** | Add `retro` recipes (`just retro` / `just retro-log` / `just retro-index`) — likely doc-pointer recipes since `just` is shell-side and the skills are agent-side. |

### New Domain Sketches

#### `compound-0-setup` (NEW)

- **Purpose**: One-time scaffold of `docs/compound/` + AGENTS.md mirrors + justfile recipes; re-entrant re-check that surfaces what's missing on subsequent runs.
- **Boundary Owns**: `docs/compound/` directory creation + initial README; staged diffs for AGENTS.md / CLAUDE.md / README_AGENTS.md / justfile; hand-off to `engineering-harness-v2` for template generation; re-check logic that detects drift in any of the above and re-suggests fixes.
- **Boundary Excludes**: producing the engineering-harness.md content (engineering-harness-v2 owns it); writing entries to the ledger (compound-1-track owns it); applying any of the staged diffs (the user does that with `git apply`).

#### `compound-1-track` (NEW)

- **Purpose**: Silent log of friction observations during agent work + periodic agent self-introspection at natural pauses ("if I had a magic wand right now?").
- **Boundary Owns**: append-only writes to `docs/compound/_session-buffer.md`; the agent self-check trigger heuristics (tool call > 30s, zero-result search, 2nd retry, backtrack, test/build failure needing guesswork, optional task-boundary check); the schema for a single entry.
- **Boundary Excludes**: presenting entries to the user (compound-2-bubble); reading entries from any scope file (compound-2 / compound-3 / plan-1a Subagent 7); routing entries to permanent storage (compound-2-bubble decides).

#### `compound-2-bubble` (NEW)

- **Purpose**: Single soft prompt at session end that surfaces all entries from `_session-buffer.md` with the `[s/t/p/e/d/a]` action menu and routes the user's choices.
- **Boundary Owns**: the session-end prompt rendering; the action menu (save / task / plan / encode / dismiss / all-save); per-entry encoding-hint display; plan-aware destination logic (writes one `.retro.md` per save action at `docs/compound/agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` per workshop 006 § Path Resolver; sets frontmatter `plan_id` from cwd/branch detection when a plan is active, null otherwise); staging encoded diffs in `scratch/encode-<id>-<target>.diff`; emitting copy-pasteable `/plan-5` and `/plan-1b` invocations; clearing the buffer after routing.
- **Boundary Excludes**: appending new entries (compound-1-track); harvesting cross-session entries (compound-3-harvest); applying any staged diff (user); generating `/plan-5` or `/plan-1b` content (it only emits invocation strings).

#### `compound-3-harvest` (NEW)

- **Purpose**: Periodic curation (typically post-`/plan-7-v2-code-review`) that reads all ledger files, deduplicates, clusters, age-orders, flags stale entries, and surfaces a prioritised improvement-suggestion summary.
- **Boundary Owns**: the cross-scope read pass; deduplication (by category + target + description-similarity); clustering (by category and target); age-ordering within clusters; staleness heuristics (`open` ≥ 4 weeks; `suggested` + no `resolved-by` ≥ 2 weeks); the prioritised top-N summary (recurrence > severity > age); the additional `[r/w/s]` lifecycle actions (resolved / wontfix / still-active); in-place status mutations on existing entries.
- **Boundary Excludes**: producing new entries (compound-1-track); the `[s/t/p/e/d/a]` per-session bubble (compound-2-bubble); applying any staged diff (user); modifying `plan-7-v2-code-review` (deferred from v1).

#### `docs/compound/` (NEW directory)

- **Purpose**: Single, repo-wide home for every self-improvement artifact from any source.
- **Boundary Owns**: directory layout per workshop 006 (`README.md`, `_buffers/<agent>.session-buffer.md`, `agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md`, optional `.disabled`); the convention guide; the opt-out sentinel semantics. **No on-disk index files** (cross-cutting views are computed by `compound-3-harvest` at read time).
- **Boundary Excludes**: the schema of individual entries (compound-1-track owns it; the schema workshop will lock specifics); the read logic of any consumer (each reader skill owns its own); how the directory is populated by minih (out of scope; we're write-compatible).

---

## Complexity

- **Score**: **CS-3 (medium)**
- **Breakdown**: S=2, I=0, D=1, N=1, F=0, T=1 → P=5 → CS-3
  - **Surface Area (S=2)**: many files cross-cutting — 4 new skills, 1 renamed skill, 3 modified pipeline skills, 4 modified governance docs, new `docs/compound/` tree, justfile updates
  - **Integration (I=0)**: purely internal; minih interop is read-compatible only; importer deferred
  - **Data/State (D=1)**: new YAML-in-markdown schema + file layout convention; a one-line path migration in plan-6a; rename of `agent-harness.md` → `engineering-harness.md` (one file, no data migration)
  - **Novelty (N=1)**: bubble-up + escalation menu UX has no precedent in our skill set; agent self-introspection is well-established in minih philosophy; three workshops have resolved most ambiguity; residual uncertainty is on schema field names, CLI prompt rendering, AGENTS.md voice, and harvest behavior — all deferred to dedicated workshops
  - **Non-Functional (F=0)**: standard; user privacy via `.disabled` sentinel; no perf or security concerns
  - **Testing/Rollout (T=1)**: observational testing via the 1-week Compounding Test; no unit tests for markdown skills (repo convention)
- **Confidence**: 0.80 (higher than the original 0.75 because three workshops have substantially reduced design uncertainty)
- **Assumptions**:
  - Skills written in Anthropic SKILL.md format are loaded into the agent's context at session start (verified for Claude Code, Codex CLI, Copilot CLI, Pi, OpenCode via `npx skills` install)
  - Agents reliably comply with `compound-1-track` log instructions when they encounter friction (emergent behavior; calibrated by the Compounding Test at 1 week post-install)
  - `docs/compound/` writes are committed to git by default (consistent with the existing convention from plan 017-harness-integration and minih's auto-harvest)
  - Plan-detection heuristic for compound-2-bubble's plan-aware destination matches `plan-1a-v2-explore` step 1 (cwd inside `docs/plans/NNN-slug/` OR branch `^\d{3}-`)
  - `scratch/` is gitignored (verified per AGENTS.md)
  - Diffs in `scratch/` are user-applicable via standard `git apply`
- **Dependencies**: no external; no blocking dependencies on other plans; optional minih interop is read-compatible only
- **Risks (complexity-related)**:
  - Agent compliance with `compound-1-track` (highest-risk variable; mitigated by hybrid trigger + pipeline-skill log reminders + 1-week Compounding Test)
  - Self-introspection over-fires (anti-vibe 7; mitigated by concrete trigger heuristics + ≤1 per 5min calibration + AC measurement)
  - Reader-side updates land but readers don't surface entries usefully (mitigated by Subagent 7 calibration + Compounding Test signal #3)
  - Three-file mirror drift (AGENTS.md / CLAUDE.md / README_AGENTS.md; mitigated by enumerating all three at spec time)
  - Schema interop tension with minih (mitigated by superset schema; importer plan deferred)
- **Phases** — Mode is **Simple** (resolved in Clarification Q1 of session 2026-05-16). Plan-3 will produce a single phase with grouped tasks rather than multi-phase. Six task groups within one phase:
  - **Group A — Workshops**: schema (Data Model), CLI flow (CLI Flow), AGENTS.md voice (Other), harvest behavior (Other). All four lock contracts before code lands.
  - **Group B — Build `compound-0-setup` + `docs/compound/` scaffold + `resolvePath()` / `slugify()` helpers + split-migration recipe** (per workshop 006).
  - **Group C — Build `compound-1-track` + `compound-2-bubble`** (the producer-side per-session pair). Empty-buffer-only task-boundary self-prompt (per Q6.1).
  - **Group D — Build `compound-3-harvest`** (the consumer-side periodic skill).
  - **Group E — Substrate + governance + pipeline integration** (Q5.1 resolved as Interpretation A — cosmetic): rename `agent-harness-v2` → `engineering-harness-v2` (skill content unchanged; produces Boot/Interact/Observe doc as before), rename governance doc `agent-harness.md` → `engineering-harness.md` (with legacy filename fallback for backwards compat), template `## Known Difficulties` seeding, AGENTS.md / CLAUDE.md / README_AGENTS.md / justfile updates, `harness-is-the-product-v2` Principle 2 wording update ("Track Velocity Compounding" → "Track Compounding Value"), `harness-is-the-product-v2` "Two harnesses, one principle" callout softened (engineering harness becomes the umbrella; substrate vs agent become sub-aspects), `(E)`/`(A)`/`(both)` tag system collapsed, **8 SDD pipeline skills' agent-harness references updated** to use the broader "engineering harness" terminology + the renamed governance-doc path, plan-6a one-line path update, plan-1a Subagent 7 reader update, **plan-6 + plan-6-companion compound integration** (compound vocabulary in skill bodies, `compound-1-track` calls during work, companion farewell envelope → compound entry mapping documented).
  - **Group F — Dogfood + Compounding Test**: use both producer + harvest in this repo for a week; calibrate self-introspection heuristics; calibrate harvest staleness thresholds; file vibe regressions as `compound-1-track` entries against the skills themselves (delicious recursion).
  - **Mode tension note**: six task groups in one phase is wide. `/plan-3-v2-architect` may surface this and recommend Full Mode instead. The user's clarification chose Simple — the architect should respect that unless wide-but-shallow proves unworkable.

---

## Testing Strategy

**Approach**: Manual + Compounding Test (resolved in Clarification Q5 of session 2026-05-16)

**Rationale**: The deliverable is markdown skills (loaded into agent context as SKILL.md) + governance docs (AGENTS.md / CLAUDE.md / README_AGENTS.md / `docs/compound/README.md`) + reader-side modifications to existing SKILL.md files. There is no application code to unit-test. The repo convention is observational testing for skill changes.

**Focus Areas**:
- **Compounding Test (1 week post-install)** — the workshop 001 four signals: (1) any `[t/p/e]` action chosen at bubble-up, (2) any entry marked `status: encoded`, (3) any session started by reading the ledger (via plan-1a Subagent 7 or engineering-harness.md `§ Known Difficulties`), (4) user did NOT disable the system. Pass = vibe was right.
- **Anti-vibe walkthroughs** — manual check that the v1 implementation does NOT trigger any of the 7 anti-vibes from `workshops/001-self-improvement-vibe.md` (verified by walking the 3 imagined sessions A/B/C against the implementation).
- **Five-stage flow walkthrough** — verify each stage from `workshops/002-end-to-end-flow.md` works end-to-end with the worked-example sequence diagram (a single difficulty traverses Explore → Track → Bubble → Harvest → Re-encode → Verify across multiple sessions).
- **Portability check** — install via `npx skills@latest add jakkaj/tools --skill <name> -a <client> -g` for each of the 5 supported CLIs (claude-code, codex, github-copilot, opencode, pi) and confirm `compound-0/1/2/3` operations work without minih.
- **Three-layer integration check** — verify philosophy (`harness-is-the-product-v2`) → substrate (`engineering-harness-v2`) → meta-loop (`compound-N`) cross-references resolve correctly; AGENTS.md describes all three; the layering is visible to a fresh contributor.

**Mock Usage**: N/A — no mocks needed. No application code that would have external dependencies to mock.

**Excluded** (not tested in v1):
- Cross-CLI hook integration (no auto-fire; hybrid trigger is agent-self-invoked + manual)
- `compound import-minih` / `self-improve import-minih` interop (deferred to follow-up plan)
- JSON Schema validation of ledger entries (no validator in v1)
- Cross-plan analytics beyond what `compound-3-harvest` provides
- Auto-verification of encoded fixes (Variant A from workshop 002; deferred)
- Cross-plan promotion (Variant B from workshop 002; deferred)

---

## Documentation Strategy

**Location**: Hybrid — SKILL.md bodies + AGENTS mirrors + `docs/compound/README.md` (resolved in Clarification Q6 of session 2026-05-16)

**Rationale**: Each skill's SKILL.md body carries its operating contract (Anthropic convention). The AGENTS.md / CLAUDE.md / README_AGENTS.md mirror trio carries the operational contract for the loop *as a project norm*. The `docs/compound/README.md` convention guide is the file-layout + schema reference *colocated with the ledger itself* — readable independent of any skill.

**Locations and their purposes**:

| Location | Owner | Purpose |
|----------|-------|---------|
| `skills/compound/compound-0-setup/SKILL.md` | compound-0-setup | Scaffold + re-check operating contract |
| `skills/compound/compound-1-track/SKILL.md` | compound-1-track | Silent log + magic-wand trigger heuristics + entry schema |
| `skills/compound/compound-2-bubble/SKILL.md` | compound-2-bubble | Session-end prompt + action menu + plan-aware destination + scratch/ staging |
| `skills/compound/compound-3-harvest/SKILL.md` | compound-3-harvest | Read-pass + dedup + cluster + age-order + staleness + lifecycle actions |
| `skills/SDD/engineering-harness-v2/SKILL.md` | engineering-harness-v2 | Substrate audit + scaffold + template § Known Difficulties seed protocol |
| `AGENTS.md` § Compounding Value System | new section | Operational contract for the system as a project norm. ≤15 lines; D7 voice (operational with one-sentence story preamble linking to `harness-is-the-product-v2`). Names the three layers; points at the slug `compound`. |
| `CLAUDE.md` § Compounding Value System | mirror of AGENTS.md | Same content, Claude-convention filename |
| `README_AGENTS.md` | catalog | New `## Compound — Compounding Value System` section with 4 catalog entries; updated `engineering-harness-v2` row |
| `docs/compound/README.md` | convention guide | Directory layout, schema reference (links to spec + schema workshop), `.disabled` sentinel semantics, integration with minih |

**Excluded** (not in v1):
- Long-form `docs/how/self-improvement-loop.md` guide — deferred; SKILL.md bodies + AGENTS mirrors are sufficient
- Standalone philosophy doc — `harness-is-the-product-v2` already plays that role; cross-referenced from each compound SKILL.md
- Per-CLI install guides — `INSTALL.md` already covers `npx skills` patterns; new skills inherit those patterns automatically

---

## Acceptance Criteria

### `compound-0-setup` (scaffold + re-check)

1. **First-run scaffold**: invoking `/compound-0-setup` in a repo with no `docs/compound/` directory creates the minimal canonical tree per workshop 006: `README.md` (convention guide), `_buffers/README.md` + `_buffers/.gitignore` (gitignores `*.session-buffer.md`), `agents/.gitkeep`. **No `sessions/` subdir; no `_LEDGER.md`; no `plans/` subdir.** Stages diffs in `scratch/` for AGENTS.md / CLAUDE.md / README_AGENTS.md "Compounding Value System" sections and for justfile retro recipes.

1a. **First-run docs/retros/ migration** (per Clarification Q5.3, refined by workshop 006 § D9): if `docs/retros/` exists in the repo (from minih auto-harvest or plan-6a's prior writes), `compound-0-setup` automatically **splits** each `<slug>.md` (parsing on `^## \d{4}-\d{2}-\d{2}T` block delimiters) into one per-run `.retro.md` file under `docs/compound/agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` using the workshop 005 `minihToUniversal()` mapping. Originals are renamed to `*.legacy.md` (reversible). Writes `docs/retros/.split-to-compound` breadcrumb. Auto-applied (not staged) — destination is purely a rename + format-upgrade of files already destined for the compound loop. Re-runs detect the breadcrumb and split only blocks not yet migrated (idempotent). User can revert with `git mv *.legacy.md *.md` and `git rm docs/retros/.split-to-compound`.
2. **Hand-off to substrate layer**: after scaffold, `compound-0-setup` invokes `engineering-harness-v2` (or stages its invocation as a follow-up step the user runs) so the engineering-harness.md template is established with `## Known Difficulties` ready to seed.
3. **Re-entrant re-check**: re-invoking `/compound-0-setup` in a repo where setup has already been done detects what's present, identifies what's missing or stale, and re-stages only the diffs needed. No destructive operations on existing files.

### `compound-1-track` (silent log)

4. **Silent on no friction**: a session in which the agent encounters no friction logs zero entries; the user sees nothing from `compound-1-track`.
5. **Append-only writes**: when the agent calls `compound-1-track` (because the user muttered something or the agent itself observed friction or the magic-wand check fired), an entry is appended to `docs/compound/_session-buffer.md` with `id`, `ts`, `source` (user | agent-self), `type` (difficulty | magic-wand | gift | insight), `category`, `target`, `description`, optional `workaround`, optional `suggested-encoding`. (Schema field shape locked by the schema workshop.)
6. **Magic-wand check rate**: in typical sessions, agent-source entries average ≤ 5 per session and the magic-wand self-check fires ≤ 1 time per 5 minutes of work (anti-vibe 7 calibration). The trigger heuristics are: tool call > 30s, zero-result search, 2nd retry of same command, backtrack from wrong assumption, test/build failure requiring guesswork, optional task-boundary check.

### `compound-2-bubble` (session-end soft prompt)

7. **Empty buffer is silent**: at session end, if `docs/compound/_session-buffer.md` is empty, no prompt appears.
8. **Single soft prompt**: at session end, if the buffer has entries, the user sees one prompt listing all entries with one-line encoding hints per entry and a single `[s/t/p/e/d/a]` menu. No per-entry prompts; no mid-session prompts.
9. **Default action preserves information**: pressing enter at the prompt = `[a]ll-save`; saves all entries by wrapping them in a universal retro envelope (workshop 005) and writing one `.retro.md` file at `docs/compound/agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` per workshop 006 § Path Resolver. Frontmatter `plan_id` is set from cwd/branch detection (active plan) or `null` (no plan). No `<plan-slug>.md` or `sessions/<date>-<branch>.md` file is written — plan/session views are computed by `compound-3-harvest` filters at read time.
10. **`[e]ncode` stages a reviewable diff**: choosing `[e]ncode` writes a candidate unified diff to `scratch/encode-<entry-id>-<target-shortname>.diff` and prints the `git apply scratch/...` command. Nothing is auto-applied.
11. **`[t]ask` and `[p]lan` emit copy-pasteable invocations**: choosing `[t]ask` prints a ready-to-run `/plan-5-v2-phase-tasks-and-brief --fix "<entry summary>"` invocation seeded from the entry; choosing `[p]lan` prints `/plan-1b-v2-specify "<entry summary>"`.
12. **Buffer cleared after routing**: after the user makes a choice (any of `[s/t/p/e/d/a]`), `_session-buffer.md` is reset to empty.

### `compound-3-harvest` (periodic curation)

13. **Reads all retros into one in-memory view**: invoking `/compound-3-harvest` scans `docs/compound/agents/**/*.retro.md` (canonical) AND `docs/retros/*.md` (minih legacy back-compat; block-parsed on the fly). Validates each retro's frontmatter against `retro.schema.json` (workshop 005); skips malformed retros with a warning; dedups by `retro_id`. The view is **transient — held in memory and printed to terminal**; no on-disk index/rollup file is written (workshop 006 KISS revision).
14. **Curates the view**: deduplicates entries (heuristic match on category + target + description-similarity), clusters by category and target, age-orders within clusters (newest first). Cluster summaries show the count and the most-frequent description-pattern.
15. **Flags stale entries**: entries with `status: open` and an age > 4 weeks, or `status: suggested` and no `resolved-by` after 2 weeks, are flagged "needs decision" with a one-keystroke menu to advance status (`[r]esolved` / `[w]ontfix` / `[s]till-active`).
16. **Prioritised summary**: presents at most 10 actionable entries, prioritised recurrence count > severity > age. Each entry has the same `[s/t/p/e/d/a]` escalation menu as `compound-2-bubble` plus the new `[r/w/s]` status-update actions.
17. **In-place status mutations**: choosing `[r/w/s]` for an entry edits the entry's `status` field in-place in the scope file (no append-only fallback in v1).

### `engineering-harness-v2` (renamed substrate skill)

18. **Skill renamed**: `skills/SDD/agent-harness-v2/` is renamed to `skills/SDD/engineering-harness-v2/`. The SKILL.md `name:` frontmatter field updates to match. **What the skill produces and what its governance doc is named depends on the resolution of Open Q1** (cosmetic rename vs scope refocus).
19. **Governance doc renamed** (per Clarification Q5.1, Interpretation A): `docs/project-rules/agent-harness.md` is renamed to `docs/project-rules/engineering-harness.md`. The skill content is unchanged — it still produces a Boot/Interact/Observe doc; "engineering harness" is now the broader umbrella term. Existing legacy filename fallback extends to read `agent-harness.md` (and the older `harness.md`) so existing projects don't break. The 8 SDD pipeline skills currently referencing `agent-harness.md` are updated to reference `engineering-harness.md` (with the legacy fallback documented).
20. **`## Known Difficulties` template seed**: the generated `engineering-harness.md` template gains a `## Known Difficulties` section auto-populated with up to 10 most-relevant entries from `docs/compound/` (filtered by `target: engineering-harness | tooling | etc.`). New agent sessions reading `engineering-harness.md` see accumulated friction at boot.

### Pipeline touchpoints

21. **`plan-1a-v2-explore` Subagent 7 reads `docs/compound/`**: Subagent 7 ("Prior Learnings Scout") is updated to read `docs/compound/agents/**/*.retro.md` (canonical per workshop 006) AND `docs/retros/*.md` (minih legacy back-compat) in addition to the legacy `## Discoveries & Learnings` tables. Filters retros relevant to the current research topic (by `frontmatter.plan_id` if a plan is detected, by recency otherwise). New entries surface in the research dossier's Prior Learnings section with the same `PL-NN` numbering.
22. **`plan-6a-v2-update-progress` path update**: Step 8c's hardcoded `docs/retros/` path updates to `docs/compound/`. One-line change. No behavior change beyond the path.

22a. **`plan-6-v2-implement-phase` calls `compound-1-track` during work**: the skill body is updated to invoke `compound-1-track` at natural friction points during implementation (the same trigger heuristics as `compound-1-track`'s default: tool call > 30s, zero-result search, 2nd retry, backtrack, test/build failure requiring guesswork). This produces fine-grained per-task entries in the buffer rather than only the coarse-grained phase-end retro that plan-6a writes. End-of-phase output reminds the user to run `/compound-2-bubble` if any buffer entries accumulated.

22b. **`plan-6-v2-implement-phase-companion` is dressed up with compound vocabulary**: the skill body is updated to:
    - Reference `harness-is-the-product-v2` (philosophy) + the compound family + `engineering-harness-v2` (substrate) as the three layers it operates within
    - Call `compound-1-track` during orchestrator-side work (same as plan-6 above)
    - Document the **companion farewell envelope → compound entry mapping**: `farewell.retrospective.magicWand` (single string + `magicWandTarget`) maps to compound `type: magic-wand`, `target: <mapped>`; `farewell.retrospective.difficulties[]` (MH-XXX prefix) maps to compound `type: difficulty`; `farewell.retrospective.workedWell` (when non-trivial) maps to compound `type: gift`. Schema details locked by the schema workshop.
    - Frame the companion as a **second producer** of compound entries (alongside the orchestrator's own `compound-1-track` calls). Both producers' outputs land as per-run `.retro.md` files at `docs/compound/agents/<agent>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` (workshop 006 path resolver). Each retro has `frontmatter.plan_id` set to the active plan; plan-grouped views come from `compound-3-harvest --plan <slug>` filters. plan-6a Step 9's auto-harvest runs the universal-schema round-trip mapping (workshop 005 § D9) to convert the companion's minih-shaped farewell envelope into a universal retro file.
    - End-of-phase output reminds the user to run `/compound-2-bubble` for the orchestrator-side buffer + `/compound-3-harvest` to triage the accumulated paired entries (orchestrator + companion) post-phase.

### Cross-cutting

23. **`docs/compound/.disabled` sentinel honoured**: a `docs/compound/.disabled` file (any contents) makes `compound-1-track` a silent no-op (no append, no error) and makes `compound-2-bubble` and `compound-3-harvest` print a clear "compound: logging disabled in this project (remove docs/compound/.disabled to re-enable)" message.
24. **Portable across CLIs (no minih dependency)**: each compound skill installs via `npx skills@latest add jakkaj/tools --skill <name> -a <client> -g` for each of: claude-code, codex, github-copilot, opencode, pi. After install, all `compound-N` operations work in each CLI without any minih binary on `$PATH` and without any `MINIH_*` environment variable set.
25. **None of the seven anti-vibes triggered**: verified by walking each of the three imagined sessions from workshop 001 (A: code review with two difficulties; B: planning research with one magic-wand; C: typo fix with no entries) against the implementation. For each anti-vibe (1–7), document explicit evidence the implementation does NOT trigger it.
26. **`AGENTS.md` / `CLAUDE.md` describe the system as a contract**: both files contain a "Compounding Value System" section (10–15 lines each, mirrored content) describing the system in operational-contract voice (per workshop 001 D7) — what the compound family does, where entries land, when the agent self-introspects, and how the three layers (philosophy / substrate / meta-loop) compose. No philosophical lecture; one-sentence story-mode preamble linking to `harness-is-the-product-v2`. The slug `compound` is named explicitly as the umbrella term.
27. **Three-layer stack documented**: AGENTS.md / CLAUDE.md mention the three layers (philosophy / substrate / meta-loop) by name with one-line descriptions and links to the relevant skills.

### Dogfood validation

28. **1-week Compounding Test passes** in this repo:
    - Signal 1: ≥ 1 user action of `[t]`, `[p]`, or `[e]` chosen during the week.
    - Signal 2: ≥ 1 entry has its `status` field updated to `encoded` with a `resolved-by` reference.
    - Signal 3: ≥ 1 subsequent session's research dossier (via `plan-1a` Subagent 7) OR new agent's `engineering-harness.md § Known Difficulties` read surfaces an entry from `docs/compound/`.
    - Signal 4: the user has NOT added any compound skill to a personal "skills I always disable" list.

---

## Risks & Assumptions

### Assumptions

- **A1 — SKILL.md loading**: skills are loaded into agent context at session start by every supported CLI consumer
- **A2 — Agent compliance with `compound-1-track`**: agents will follow log instructions when they encounter friction *most of the time*. Even 30% capture is a step-change improvement over current 0%
- **A3 — `docs/compound/` is committed to git**: matches the existing convention from plan 017-harness-integration and minih's auto-harvest
- **A4 — Plan-detection heuristic is reliable**: cwd-inside-`docs/plans/NNN-slug/` OR branch-name-matches-`^\d{3}-` (the heuristic from `plan-1a-v2-explore` step 1) is sufficient for `compound-2-bubble`'s plan-aware destination routing
- **A5 — `scratch/` is gitignored**: verified per AGENTS.md
- **A6 — Diffs in `scratch/` are user-applicable**: standard `git apply` workflow
- **A7 — Anti-vibes are exhaustive enough for v1**: the 7 anti-vibes from workshop 001 were derived from concrete failure modes; new anti-vibes may surface during dogfood week and would update workshop 001

### Risks

- **R1 — Agent compliance with `compound-1-track` is too low** (probability: medium; impact: high). Buffer empty → skill is a no-op → loop stays open. *Mitigation*: hybrid trigger (agent-self-invoked default + manual escape `/compound-2-bubble`); the modified pipeline skills (plan-1a Subagent 7) include explicit `compound-1-track` reminders at natural friction points; Compounding Test signal #1 measures this directly at 1 week.
- **R2 — Self-introspection over-fires** (probability: low-medium; impact: medium → triggers anti-vibe 7). *Mitigation*: trigger heuristics in workshop 001 are concrete; calibration target ≤ 1 per 5 min; AC#6 measures explicitly.
- **R3 — Reader-side updates land but readers don't surface entries usefully** (probability: medium; impact: high). Subagent 7 reads `docs/compound/` but presents entries dryly → users don't act on them. *Mitigation*: Group F dogfood week + Compounding Test signal #3 measures this directly. Optional follow-up workshop on reader-side surfacing UX if dogfood reveals issues.
- **R4 — User dismisses the bubble-up every time** (anti-vibe 3 in motion; probability: medium; impact: high). *Mitigation*: D5 from workshop 001 ("terse + one-line encoding hint per entry") is the primary defense; if dismiss-rate > 80% after 1 week, encoding hints need iteration — possibly a follow-up workshop.
- **R5 — Schema/CLI/voice/harvest workshops over-engineer the deferred contracts** (probability: low; impact: medium). *Mitigation*: each workshop has a clear value frame; the seven anti-vibes from workshop 001 + the six F-decisions from workshop 002 + the five M-decisions from workshop 003 constrain the design space tightly enough that over-engineering should be self-evident at review.
- **R6 — Three-file mirror drift (AGENTS.md / CLAUDE.md / README_AGENTS.md)** (probability: medium; impact: low). Three files must stay in sync. *Mitigation*: explicit spec-time enumeration; consider a `scripts/check-mirrors.sh` if drift recurs.
- **R7 — Minih interop tension surfaces during dogfood week** (probability: medium; impact: medium — bumped from low/low because plan-6-v2-implement-phase-companion is now in scope per Clarification Session 3). The companion mode actively uses minih's structured retros (farewell envelope: `magicWand`, `magicWandTarget`, `difficulties[]`, `workedWell`, `coordination`); the schema workshop must lock the round-trip mapping cleanly so plan-6-companion's outputs land as well-formed compound entries (not as opaque JSON dumps). *Mitigation*: schema workshop (queued) explicitly includes the companion farewell envelope → compound entry mapping as a sub-topic; plan-6-companion's skill body documents the mapping after the schema workshop locks it; if mapping proves clunky, the `compound import-minih` follow-up plan handles formal interop.
- ~~**R8 — `engineering-harness-v2` rename ambiguity**~~ — **RESOLVED in Session 5 (Q5.1)**: Interpretation A (cosmetic) selected. Skill still produces a Boot/Interact/Observe doc; "engineering harness" becomes the broader umbrella. Cascade work added to Group E (harness-is-the-product-v2 disambiguation softening; 8 SDD skills' terminology + path cascade; legacy filename fallback for `agent-harness.md`).

---

## Clarifications

### Session 2026-05-16 — Initial 8-question clarification

| # | Question | Answer |
|---|----------|--------|
| Q1 | Workflow Mode | **Simple** |
| Q2 | Producer skill name (originally `gifts-v2` working name) | **`self-improve-v2`** — later superseded by the compound family restructure (see Session 2 below) |
| Q3 | Skill placement | **`skills/SDD/`** — later changed to `skills/compound/` (new top-level category) per Session 2 |
| Q4 | Reader-side scope (multi-select) | **`plan-1a` Subagent 7 (mandatory)** + **`agent-harness-v2` template seeds Known Difficulties**. The user added a critical scope expansion: a paired harvest companion skill that runs after code-review cycles. |
| Q5 | Testing Strategy | **Manual + Compounding Test (recommended)** — preserved through the restructure |
| Q6 | Documentation Strategy | **Hybrid: SKILL.md + AGENTS mirrors + `docs/compound/README.md`** (path updated from `docs/retros/` per Session 2) |
| Q7 | Harvest companion name + slot | Original answer: `/plan-8a-compound-harvest` — later restructured into `compound-3-harvest` (member of the compound family) per Session 2 |
| Q8 | Agent harness applicability | **N/A — feature doesn't need an agent harness**. The 1-week Compounding Test serves as the validation surface. |

### Session 2026-05-16 (later) — Compound family restructure

After Session 1's clarifications, three workshops (vibe / end-to-end-flow / system-map) and several informal design conversations converged on a sharper architecture than Session 1 captured. The restructure:

| Decision | What changed |
|----------|--------------|
| **Three-layer stack as first-class concept** | Philosophy (`harness-is-the-product-v2`) / Substrate (`engineering-harness-v2`) / Meta-loop (compound family). Documented as the load-bearing architecture in workshop 003 § "Three-Layer Stack". |
| **Compound family replaces single producer + consumer** | The originally-proposed `self-improve-v2` (one skill, multiple modes) and `plan-8a-compound-harvest` (separate consumer) split into four small focused skills: `compound-0-setup`, `compound-1-track`, `compound-2-bubble`, `compound-3-harvest`. Each is loadable in isolation; each is re-entrant. |
| **New top-level skills category** | `skills/compound/` joins `SDD/`, `general/`, `personal/` as a peer category. The compound family lives there, not under `skills/SDD/`. |
| **Numbering 0/1/2/3 (no gap)** | The user accepted dropping `compound-1-explore` because Stage 1 (Explore) is fulfilled by `plan-1a-v2-explore` Subagent 7 + `engineering-harness.md § Known Difficulties` template seed. Cross-skill domain leak (SDD reads compound's surface) explicitly accepted as a "much faster" tradeoff. |
| **`docs/compound/` umbrella** | The directory previously called `docs/retros/` (in this spec's earlier draft) becomes `docs/compound/`. ALL self-improvement artifacts live there. (Historical note: this row originally listed per-plan files, per-session files, per-agent files, and an auto-rebuilt index — that flat-file layout was superseded by workshop 006 with the per-run isolated layout `agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` and NO on-disk index files. Cross-cutting views are computed at read time by `compound-3-harvest`. See active § Target Domains row + AC#1/#9/#13 for the current layout.) |
| **"Compounding value" framing** | The umbrella term is *compound* — short for *compounding value* (not minih's narrower "compounding velocity"). Every entry compounds value session-over-session. Like compound interest. `harness-is-the-product-v2` Principle 2 wording updates to match. |
| **`agent-harness-v2` → `engineering-harness-v2` rename** | Substrate-layer skill renamed. Interpretation pending — see Open Q1. Governance doc renames `agent-harness.md` → `engineering-harness.md` with backwards-compat read fallback. |

These decisions are reflected throughout this spec body. Workshops 001 and 002 still reference the older `gifts-v2` / `self-improve-v2` / `plan-8a-compound-harvest` / `docs/retros/` naming for traceability — they were authored during the design's evolution. Workshop 003 is the canonical post-restructure architecture document.

### Session 2026-05-16 (later still) — plan-6 + plan-6-companion compound integration

**User directive**: ensure `plan-6-v2-implement-phase-companion` is in scope and "dressed up with this compounding stuff" — the companion mode uses the minih companion runtime and should be fluent in the magic-wand / compounding-value vocabulary. The companion is already a producer of compound-shaped entries (via plan-6a Step 9's auto-harvest of the farewell envelope; historical note: this section originally said the harvest landed in `docs/compound/<plan-slug>.md` — that path was superseded by workshop 006 § Path Resolver, which routes per-run retros to `docs/compound/agents/<agent>/<date>/T<time>Z-<hash>.retro.md` with plan attribution via `frontmatter.plan_id`), but the skill body itself doesn't speak the compound language explicitly.

**Decision**: pull both `plan-6-v2-implement-phase` and `plan-6-v2-implement-phase-companion` into v1 scope as **modify** entries.

| What changes | Skill |
|--------------|-------|
| Add `compound-1-track` calls during implementation work (same trigger heuristics as compound-1-track's default) | plan-6 + plan-6-companion |
| End-of-phase output reminds the user to run `/compound-2-bubble` | plan-6 + plan-6-companion |
| Cross-reference the three layers: `harness-is-the-product-v2` (philosophy) + compound family (meta-loop) + `engineering-harness-v2` (substrate) | plan-6 + plan-6-companion |
| Document the **companion farewell envelope → compound entry mapping** in the skill body (`magicWand` → `type: magic-wand`; `difficulties[]` → `type: difficulty`; `workedWell` → `type: gift`); reference schema workshop for round-trip mapping rules | plan-6-companion only |
| Frame the companion as a **second producer** of compound entries alongside the orchestrator's own `compound-1-track` calls; both producers' outputs land via plan-6a Step 9 | plan-6-companion only |
| End-of-phase output also reminds the user to run `/compound-3-harvest` to triage paired entries (orchestrator + companion) | plan-6-companion only |

**Effect on spec**:
- Target Domains table gains 2 new "modify" rows (plan-6 + plan-6-companion)
- Acceptance Criteria gain AC#22a (plan-6 compound integration) + AC#22b (plan-6-companion compound integration)
- Group E in the Phases hint expanded to include the plan-6 / plan-6-companion modifications
- R7 (minih interop tension) probability + impact bumped from low/low → medium/medium because companion-mode involvement makes the schema-mapping question more pressing
- Schema workshop explicitly includes "companion farewell envelope → compound entry mapping" as a sub-topic (no new workshop needed)

**Why this matters**: without the integration, plan-6-companion produces structured retros that LAND in `docs/compound/` but don't FEEL like compound — they're minih-shaped artifacts that happen to share a directory. With the integration, the companion is a first-class participant in the compounding-value loop: its findings are routed through the same vocabulary, the same schema, and the same downstream readers (compound-3-harvest curation; plan-1a Subagent 7 research-time reads; engineering-harness.md template seed). The compound umbrella is then truly umbrella — not just "things that happen to live in docs/compound/."

### Session 2026-05-16 (final) — Branding lock: "Compounding Value System"

**User directive**: "We're going to be calling this the Compounding Value System and its slug name will be Compound. Compounding value system is our first class concept in these in our skills graph."

**Decision**:
- **Formal name**: **Compounding Value System** (used in titles, prose, AGENTS.md section headings, README_AGENTS.md catalog section, external-facing documentation)
- **Slug**: **`compound`** (used in folder paths `skills/compound/` and `docs/compound/`, skill names `compound-N-<verb>`, file references, code-style identifiers)
- **First-class status**: the Compounding Value System is a peer category in this repo's skills graph alongside SDD, general, and personal. It earns its own top-level `skills/compound/` folder and its own AGENTS.md section.

**Effect on spec + downstream**:
- Spec title updated: "Compounding Value System"
- Spec header gains an explicit "First-class concept" callout naming both the formal name and the slug
- Summary explicitly names the system + the first-class status
- AGENTS.md / CLAUDE.md section heading updated: § Self-Improvement Loop → § Compounding Value System
- README_AGENTS.md catalog section updated: ## Compound — self-improvement loop → ## Compound — Compounding Value System
- AC#26 wording updated to use the new section name + reference to the slug
- Workshop opportunities entry for the AGENTS.md voice workshop updated to use the new section name
- Compound-0-setup AC#1 updated to stage diffs for the renamed section

**Why this matters**: naming is identity. "Self-Improvement Loop" was descriptive but unclaimed. "Compounding Value System" is a named system with a slug — it can be referenced precisely, taught precisely, and improved precisely. The slug `compound` is short enough for path-level use; the formal name is precise enough for prose. They cooperate cleanly.

### Session 2026-05-16 (Session 5) — 4-question lock for the four pressing open questions

Four-question Q&A round to unblock Group E and lock the remaining naming/behavior choices. All four resolved to the recommended option.

#### Q5.1 — Engineering-harness-v2 rename interpretation

**Question**: Cosmetic rename, scope refocus, or hybrid?
**Answer**: **Interpretation A (Cosmetic)**.
**Effect**: The renamed `engineering-harness-v2` skill still produces a Boot/Interact/Observe doc (the agent-facing overlay); "engineering harness" becomes the **broader umbrella term** that includes both substrate (recipes/build/test/seed) AND agent overlay (Boot/Interact/Observe). This **softens** commit `36a9ade`'s explicit `(E)` vs `(A)` disambiguation in `harness-is-the-product-v2`: the two were treated as strictly distinct; under Interpretation A they become two aspects of the same broader concept.

Cascade items added to Group E scope:
- `harness-is-the-product-v2` "Two harnesses, one principle" callout updated to "Engineering harness encompasses substrate + agent-facing overlay"
- `harness-is-the-product-v2` Principle tag system (`(E)`/`(A)`/`(both)`) collapsed: probably `(E)` for the broader umbrella, with `(substrate)` / `(agent)` sub-tags inside principle bodies where the distinction matters
- All 8 SDD pipeline skills currently referencing "agent harness" (per the dossier's count) updated to use "engineering harness" terminology + the renamed governance-doc path `docs/project-rules/engineering-harness.md`
- Legacy filename fallback: read `agent-harness.md` if `engineering-harness.md` is absent (backwards compat for existing user projects)

R8 (rename ambiguity risk) → **Resolved**.

#### Q5.2 — v2-suffix on compound family

**Question**: `compound-N-v2-<verb>` (matches SDD) or flat `compound-N-<verb>`?
**Answer**: **Flat** — `compound-0-setup`, `compound-1-track`, `compound-2-bubble`, `compound-3-harvest`.
**Effect**: No spec changes (flat naming was already the assumption throughout the spec body). Confirms the Open Q2 recommendation. The compound family's naming convention is documented as: "no v2 infix because the family is brand new — no v1 predecessor."

#### Q5.3 — `docs/retros/` migration in user repos

**Question**: How does `compound-0-setup` handle existing `docs/retros/` content from minih auto-harvest or plan-6a's prior writes?
**Answer**: **Move + breadcrumb (auto on first compound-0-setup invocation)**.
**Effect**: AC#1 (`compound-0-setup` first-run scaffold) extended:
- On first invocation, detect `docs/retros/` if present; move all files into `docs/compound/` (preserving subdirectory structure)
- Leave a `docs/retros/.moved-to-compound` breadcrumb file pointing at the new location
- Auto behavior, not staged diff (per the user's selection of the "auto on first compound-0-setup" option)
- Re-runs detect the breadcrumb and skip the migration step

Note: this auto-split is a deviation from the otherwise strict "suggest-don't-mandate" pattern (anti-vibe 5). Justification: the destination is purely a rename + format-upgrade of files already destined for the compound loop — minih and plan-6a both intend their writes to feed compounding-value reflection. The breadcrumb + `*.legacy.md` rename pattern makes the split fully auditable and reversible. If the user objects post-migration, they can `git mv *.legacy.md *.md` and `git rm docs/retros/.split-to-compound`. (Refined by workshop 006 § D9 from the original "move" to the per-block "split" pattern.)

#### Q5.4 — `harness-is-the-product-v2` Principle 2 wording

**Question**: Update Principle 2 heading from "Track Velocity Compounding" → "Track Compounding Value"?
**Answer**: **Yes**.
**Effect**:
- Principle 2 heading changes from "Track Velocity Compounding" → "Track Compounding Value"
- Principle body keeps minih's "compound velocity hypothesis" framing as a referenced term (so minih readers recognise the lineage), but the principle's primary framing aligns with the Compounding Value System
- Minor cascade: the existing Principle 2 body text mentions "velocity" several times; review for places where "value" is the more general framing
- Group E scope picks up this wording change

### Session 2026-05-16 (Session 6) — 4-question lock for soft + future-flagged questions

Final Q&A round to resolve the carried-forward soft questions and the future-flagged variants. All four resolved as recommended (Q6.3 was initially pulled into v1 as a scope expansion, then re-deferred to v2 in a follow-up grill — see Q6.3 below).

#### Q6.1 — Task-boundary self-prompt behavior

**Question**: When does the optional task-boundary magic-wand check fire?
**Answer**: **Empty-buffer-only**.
**Effect**: `compound-1-track`'s trigger heuristics list explicitly states the task-boundary check fires only when no entry was logged during the current task. Avoids low-quality "I already covered this" duplicates. Resolves the carried-forward soft Open Q5. AC#6 (≤1 self-check per 5min) absorbs this calibration.

#### Q6.2 — `compound-0-setup` scaffolding consent

**Question**: Auto-scaffold on first invocation, --apply gate, or staged diff?
**Answer**: **Auto-scaffold + log as `type: gift`**.
**Effect**: Confirms AC#1's default behavior. The auto-scaffold of `docs/compound/` is logged as a `type: gift, source: agent-self, description: "bootstrapped the Compounding Value System"` entry so the user sees it at the next bubble-up. Matches the same suggest-don't-mandate-softening rationale used for Q5.3's auto-migration: the scaffolded files are pure greenfield with no destructive risk. Resolves the carried-forward soft Open Q6.

#### Q6.3 — Variant A: auto-verification of encoded fixes in v1

**Question**: Pull Variant A (auto-verification) into v1, or defer to v2?
**Answer**: **Defer to v2** (after a brief in-and-out: initially pulled into v1 as a scope expansion, then re-deferred during a follow-up grill on best-effort framing — see below).
**Initial answer**: pull into v1; close the loop at `verified`.
**Reversal rationale (follow-up grill, 2026-05-16)**: under the system's best-effort framing (no compliance gates, no enforcement levers), auto-verification stacks two soft compliance bets — the original entry must be logged, AND a future agent must remember to write a structured `resolves: <id>` back-reference on a `type: gift` entry. Either link missing → `verified` never lands → signal stays silent. The user accepted the deferral: "no need to verify them at all, just have them as encoded."
**Effect** (after reversal):
- `encoded` is the terminal lifecycle state in v1. `verified` re-joins the future-flagged variants list (Open Q11/Q12 neighbours).
- No `resolves` field on `type: gift` entries in v1 schema.
- `compound-1-track` log instructions do NOT mention auto-verification.
- `compound-3-harvest` does NOT contain verification-detection logic.
- AC#17a (auto-verification end-to-end) removed.
- Compounding Test loses signal #2a; signals #1, #2, #3, #4 stand.
- Schema workshop scope reverts (no `resolves` field discussion).
- Harvest-behavior workshop scope reverts (no verification-detection sub-topic).
- Groups C and D in the Phases hint shrink back to the pre-Q6.3 description.

#### Q6.4 — Bubble-up "anything else?" prompt

**Question**: Add the optional "anything else you noticed?" prompt to bubble-up in v1?
**Answer**: **Defer to post-dogfood revisit**.
**Effect**: Confirms workshop 001 Q1's recommendation. Bubble-up shows only entries the agent logged automatically; no free-text prompt for things the user noticed but the agent missed. Risk if added: anti-vibe 2 (bureaucratic ceremony). Revisit after 1 month of dogfood data shows whether the agent is missing too much friction. Open Q13 (now redundant) → resolved as defer.

---

## Open Questions

### Resolved in Session 5 (2026-05-16)

- ~~**[engineering-harness-v2 rename interpretation]**~~ — RESOLVED: **Interpretation A (Cosmetic)**. Group E unblocked. See Clarifications § Q5.1 for cascade items.
- ~~**[v2-suffix consistency]**~~ — RESOLVED: **flat** (compound-N-<verb>). See Clarifications § Q5.2.
- ~~**[docs/retros/ migration]**~~ — RESOLVED: **auto split + breadcrumb on first compound-0-setup invocation** (refined from "move" to "split" by workshop 006 § D9 — parses each `## <ISO>` block in `docs/retros/<slug>.md` into one per-run `.retro.md` file in the new layout via the workshop 005 mapping; originals renamed to `*.legacy.md` for reversibility; breadcrumb at `docs/retros/.split-to-compound`). AC#1a covers it. See Clarifications § Q5.3 + workshop 006.
- ~~**[harness-is-the-product-v2 Principle 2 wording]**~~ — RESOLVED: **update to "Track Compounding Value"**. See Clarifications § Q5.4.

### Resolved in Session 6 (2026-05-16)

- ~~**[task-boundary self-prompt behavior]**~~ — RESOLVED: **empty-buffer-only**. See Clarifications § Q6.1.
- ~~**[scaffolding consent]**~~ — RESOLVED: **auto-scaffold + log as `type: gift`**. See Clarifications § Q6.2.
- ~~**[Variant A — auto-verification]**~~ — RESOLVED **as deferred to v2** (after an in-and-out: initially pulled into v1, then re-deferred under best-effort framing — two stacked compliance bets too soft to land). `encoded` is the terminal v1 state. See Clarifications § Q6.3.
- ~~**[bubble-up "anything else?" prompt]**~~ — RESOLVED: **defer to post-dogfood revisit**. See Clarifications § Q6.4.

### Workshop-deferred (scope decisions for the four queued workshops)

7. **[schema field shape]** — Exact YAML field names, required-vs-optional split, minih round-trip mapping deferred to the schema workshop.
8. **[bubble-up rendering]** — Exact prompt copy, key-stroke handling, multi-entry per-action selection deferred to the CLI-flow workshop.
9. **[AGENTS.md voice and exact text]** — Exact 10–15 lines and precise placement deferred to the AGENTS.md voice workshop.
10. **[harvest companion behavior]** — Staleness thresholds, summary rendering, ledger-mutation behavior deferred to the harvest behavior workshop.

### Future-flagged (deferred to v2 or post-dogfood)

10a. **[Variant A — auto-verification]** (workshop 002 § Extras; re-deferred from Q6.3) — Should `compound-3-harvest` detect `type: gift` entries with a `resolves: <id>` back-reference and auto-flip the original `encoded → verified`? Re-deferred from v1 because the two stacked compliance bets (original logged + verifying gift logged with structured ID) are too soft under best-effort framing. Revisit when there's a more reliable verification signal (e.g. natural-language pattern match on free-text mentions of prior fixes).

11. **[Variant B — promotion]** (workshop 002 § Extras) — Should `compound-3-harvest` flag fixes used across ≥ 3 plans and suggest promotion to a more permanent home (constitution / framework default / docs/how/ article)? Recommendation: defer to v2; revisit after dogfood-week data accumulates.
12. **[Variant D — cross-project sharing]** (workshop 002 § Extras) — Should verified entries with `category: tooling` become npx-skills install candidates for other repos? Recommendation: defer to v2.

---

## Workshop Opportunities

### Done (6)

| # | Topic | Type | Outcome |
|---|-------|------|---------|
| 001 | Self-improvement vibe | Other (UX / philosophy) | Vibe statement + 8 design decisions + 7 anti-vibes + 3 imagined sessions + Compounding Test |
| 002 | End-to-end flow | Integration Pattern | Five-stage loop diagrams + 6 inter-stage contracts (F1–F6) + worked-example sequence + entry lifecycle state machine + 9-way encoding-target decision tree + 5 variants (verification / promotion / recursion / cross-project sharing / minih interop) |
| 003 | Compound system map | Integration Pattern | Three-layer stack diagram + ecosystem map + file layout + 5 integration surfaces + per-component I/O contracts + worked example + the "compound umbrella" scope decision + 5 architectural decisions (M1–M5) |
| 004 | SDD pipeline ↔ compound integration | Integration Pattern | Per-skill integration matrix (10 plan-N skills) + 4 firing-site decisions (D1–D7) + integration topology Mermaid + 4 worked walkthroughs + 10-item plan-3 acceptance criteria list + companion-mode harvest anchor (replaces /plan-7 in dominant flow) |
| 005 | Universal retro contract — JSON Schema, cross-system | Data Model | JSON Schema for `Retro` + namespaced `system.compound` and `system.minih` sub-schemas + 10 decisions (D1–D10) + 3 wire-format examples + deterministic minih round-trip mappings + 4 walkthroughs + 8 edge cases + 3-phase minih migration path + 9-item plan-3 acceptance criteria + 5-item minih RFC acceptance criteria. **Pulls minih importer into v1** (was previously deferred); **defers folder-layout to workshop 006** |
| 006 | Compound folder layout — per-run isolation by date | Storage Design | Minimal canonical tree (agent-first only; `agents/<slug>/<date>/T<HH-MM-SS>Z-<hash>.retro.md` + buffer + README + optional `.disabled`; NO on-disk index files per KISS revision) + `resolvePath()` + `slugify()` helpers + runtime-view spec (`/compound-3-harvest` filters by `--plan` / `--agent` / `--since` / `--kind` and prints to terminal) + reversible split-migration recipe + 9 decisions (D1–D9; D4 revised to "no indexes") + 4 walkthroughs + 11 edge cases + 10-item plan-3 acceptance criteria. **Subsumes spec's `sessions/<date>-<branch>.md` path** (D5); **refines spec Q5.3 from auto-move to split**; **drops all `_LEDGER` / `_INDEX` rollup files** (information over ceremony) |

### Queued (3 — required before `/plan-3-v2-architect`)

| # | Topic | Type | Why Workshop | Key Questions |
|---|-------|------|--------------|---------------|
| (next) | Bubble-up CLI flow (prompt rendering, key-stroke handling, plan-detection, multi-entry selection) | CLI Flow | No precedent in our skill set; UX details determine whether escalation actually fires; high blast radius if wrong (anti-vibe 6 = schema-driven UX is one wrong step away). | Exact prompt copy? How is `[t]/[p]/[e]` invocation emitted (printed string? clipboard? written file?)? Plan-detection heuristics for D4? Multi-entry per-action selection (e.g. choosing `[t]` for 3 entries)? Behavior on terminal narrower than 80 cols? |
| (next) | AGENTS.md / CLAUDE.md / README_AGENTS.md voice and placement | Other | Three-file mirror; voice sets the tone for the whole **Compounding Value System** as a first-class concept in this repo's skills graph; sets norms for new contributors / new agents. | Where in AGENTS.md does the "Compounding Value System" section land? Exact 10–15 lines for D7's operational-contract voice with one-sentence story preamble? README_AGENTS.md catalog entries — long form or one-liner each? Linkage to `harness-is-the-product-v2` and `engineering-harness-v2` — link, embed, or both? How does the AGENTS.md text describe the three-layer stack and name the slug `compound` as the umbrella? |
| (next) | Harvest companion behavior | Other (UX / interaction-pattern) | The skill is conceptually clear (read ledger, curate, surface) but its UX, staleness heuristics, and ledger-mutation behavior are unspecified. Without this workshop the harvest design space is wide-open during plan-3. | When does it run (after plan-7? on demand? both)? Staleness thresholds (4 weeks `open` / 2 weeks `suggested`?)? Does it mutate ledger files in place (flip `status: wontfix`) or only suggest? How does its prioritised-summary output differ from `compound-2-bubble`'s session-end prompt? Does it call compound-1-track's schema or extend it (e.g. cluster IDs)? |

### Optional follow-up workshops (not v1; listed for visibility)

| Topic | Type | Why It Might Workshop Later |
|-------|------|------------------------------|
| `compound import-minih` mapping | Data Model | If the schema workshop lands cleanly and minih interop tension surfaces during dogfood week, the importer needs a design pass before its follow-up plan ships |
| ~~`docs/compound/_LEDGER.md` rebuild logic~~ | ~~Data Model~~ | **OBSOLETE** — workshop 006 KISS revision dropped all on-disk index/rollup files; cross-cutting views are computed by `compound-3-harvest` at read time. No rebuild logic to workshop. |
| Reader-side surfacing UX in `plan-1a` Subagent 7 | Other | If the surfacing of new ledger entries in research dossiers feels off in dogfood week, this workshop tunes the presentation |
| Engineering-harness rename ripple cleanup | Other | If Open Q1 resolves toward Interpretation B (scope refocus), the cleanup of `harness-is-the-product-v2`'s disambiguation + AGENTS.md text + 8 SDD skills' cross-references needs its own design pass |

---

**Spec Complete**: 2026-05-16 (rebuild from scratch after compound restructure)
**Last Clarified**: 2026-05-16 (Session 1 — 8 questions; Session 2 — informal restructure across workshops 001/002/003)
**Spec Location**: `docs/plans/023-difficulty-ledger-skill/difficulty-ledger-skill-spec.md`

**Next steps**:
- **Critical path unblocked**: Session 5 resolved all 4 critical/newly-opened questions (engineering-harness rename interpretation, v2-suffix, retros migration, Principle 2 wording). Group E is no longer blocked.
- **Required**: run the four queued workshops (schema · CLI flow · AGENTS.md voice · harvest behavior) before `/plan-3-v2-architect`.
- After workshops: `/plan-3-v2-architect` produces the single-phase task table (Mode is Simple).
- Remaining Open Questions (carried-forward soft, workshop-deferred, future-flagged) carry recommendations and can be confirmed during plan-3 or deferred to dogfood week.
