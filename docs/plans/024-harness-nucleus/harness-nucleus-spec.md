# Harness Nucleus Consolidation

**Mode**: Simple
**Spec Version**: 2.0
**Created**: 2026-05-28
**Plan Folder**: `docs/plans/024-harness-nucleus/`
**Research**: 📚 Specification incorporates findings from [`research-dossier.md`](./research-dossier.md) (74 findings, 9 validation-pass fixes applied)

---

## Summary

Consolidate the compound + harness skill family into three harness-themed loop-stage skills under a new `skills/harness/` category, retire the standalone philosophy skill by encoding its principles inline, and update every cross-reference in lockstep so no consumer silently breaks. The new skill names map directly to the loop stages they serve: **Boot → (Do Work) → Observe → Retro**.

**Resolved name mapping** (per Round 2, corrected for loop-stage naming):

| Old (6 skills) | New (3 skills) | Lifecycle role |
|----------------|----------------|----------------|
| `engineering-harness-v2` (VALIDATE + STATUS modes) | `harness-1-boot` | Boot — verify harness is healthy + report maturity at session start |
| `compound-1-track` | `harness-2-observe` | Observe — silent producer; capture friction to per-agent buffer during work |
| `compound-2-bubble` + `compound-3-harvest` | `harness-3-retro` (`--drain` / `--harvest` modes) | Retro — `--drain` at session end (replaces bubble); `--harvest` at FINAL/merge (replaces harvest) |
| `harness-is-the-product-v2` | **RETIRED** | Philosophy migrates inline into the 3 surviving skill bodies + repo README |
| `engineering-harness-v2` (CREATE mode) | **DROPPED** | Scaffold-the-governance-doc concept → owned by the user's separate engineering-harness setup effort |
| `compound-0-setup` | **DROPPED** | Scaffold-the-ledger + migrate-legacy-retros concept → owned by the user's separate engineering-harness setup effort |

**Net: 6 skills → 3 surviving (`harness-1-boot`, `harness-2-observe`, `harness-3-retro`) + 1 retirement + 2 dropped.**

This is **consolidation only**. The dropped scaffold/migration/audit concepts are alive — they move to a **separate engineering-harness setup effort the user is running independently** (not tracked in this plan). New-repo extraction, CLI + extension architecture, and the net-new `harness-backpressure-eval` skill are deferred to a plan-025+ extraction track (Workshop Opportunities). This scope discipline flows from the Simple Mode selection (Round 1, Q1) and avoids the dossier's PL-05 vocabulary-fragility risk by keeping each rename atomic.

### What carries forward vs what's dropped

**Every runtime-loop behavior + all 5 principles have a successor** (nothing in the loop disappears):
- Boot/Interact/Observe health check + maturity report → `harness-1-boot` (VALIDATE + STATUS bodies move verbatim)
- Silent observe + magic-wand reflex → `harness-2-observe` (1:1 body move)
- Session-end drain (`[s/t/p/e/d/a]` menu, encode diff) → `harness-3-retro --drain`
- Cluster + age + top-10 + `--json` → `harness-3-retro --harvest`
- 5 principles → distributed inline (see § Phases Step 2)

**Dropped concepts move to the separate setup effort** (NOT lost, NOT re-invented here):
- Scaffold `docs/compound/` ledger tree
- Migrate legacy `docs/retros/*.md` → `.retro.md`
- Scaffold `docs/project-rules/engineering-harness.md` governance doc
- Audit project type to seed the governance doc
- Detect + migrate legacy `harness.md` / `agent-harness.md` filenames

**First-run implication**: the 3 surviving skills assume their on-disk dependencies already exist and handle missing-deps gracefully (boot reports `UNAVAILABLE`; observe/retro no-op on missing dirs). A fresh repo can't be made loop-functional from these 3 skills alone — that's the setup effort's job. In tools-repo specifically: `docs/compound/` is already scaffolded; the governance doc is absent but boot handles that. No regression.

## Goals

- **G1**: Skill names match the loop stage they serve. `compound-1-track` → `harness-2-observe` is no longer a name about the artifact (`compound`) but the role (`observe` friction).
- **G2**: One philosophy artifact (`harness-is-the-product-v2`) retires; its 5 principles distribute inline into the surviving skill bodies + repo README — "encode don't document" applied to itself.
- **G3**: Every cross-reference updates atomically. After the cascade lands, `grep -rl 'compound-[0-9]\|harness-is-the-product\|engineering-harness-v2' .` returns empty across the codebase (modulo `docs/plans/023-difficulty-ledger-skill/` which is immutable per Critical Finding 06).
- **G4**: The latent 2-deep harness-doc fallback bug in `plan-3-v3-architect` (Critical Finding 03) is repaired in the same commit train.
- **G5**: Post-completion vocabulary freeze: no further renames in this family for ≥1 quarter (Critical Finding 05). The three `harness-N-*` names are the stable surface.

## Non-Goals

- **Scaffold / migration / audit concepts** (was `compound-0-setup` + `engineering-harness-v2` CREATE mode) → owned by the user's **separate engineering-harness setup effort**. Not designed, tracked, or re-invented in this plan.
- New repo extraction (separate from `jakkaj/tools`). → plan-025+ Workshop Opportunity.
- CLI + extension architecture for the new repo. → plan-025+ Workshop Opportunity.
- `harness-backpressure-eval` skill (net-new, no current analog). → plan-025+ Workshop Opportunity.
- Rename of the `engineering-harness.md` **filename** (Critical Finding 03 — cross-system contract per IC-07; non-negotiable). `harness-1-boot` reads the same filename via the same fallback chain.
- Schema-file renames at `skills/compound/schemas/` (IC-01 + IC-08 — v1-home commitment with minih until npm-package extraction). Schemas stay put this plan.
- Changes to `docs/compound/` runtime path root (IC-09 — 9+ skills hard-code; minih back-compat). The ledger tree path is unchanged; only the SKILL.md folders move to `skills/harness/`.
- Changes to the universal retro schema wire format or the `[s/t/p/e/d/a]` action menu (IC-02, IC-06 — cross-system / user-facing).
- Rewriting plan-023 design history (Critical Finding 06 — immutable; forward-pointer added instead).

## Research Context

The research dossier mapped 74 findings. Load-bearing for this spec:

- **6 target skills**: one battle-tested (`engineering-harness-v2`), one lightly-used (`harness-is-the-product-v2`), 4 experimental-to-unshipped (compound-0/1/2/3). Only 1 retro in the live ledger → renaming is low user-impact (Critical Finding 04).
- **8 SDD skills** carry explicit `## Compound integration` sections invoking compound by name — atomic-update zone.
- **5 governance docs** (CLAUDE.md, AGENTS.md, README_AGENTS.md, INSTALL.md, MIGRATION.md) carry skill-name references — atomic-update zone.
- **`justfile` + `scripts/compound-value.sh`** parse `compound-3-harvest --json` via hard-coded jq filters — atomic-update zone; new `harness-3-retro --harvest --json` MUST preserve `harness.maturity` / `harness.verdict` / `harness.boot_ms` paths or rewrite atomically.
- **`src/jk_tools/`** auto-synced distribution mirror — `./scripts/sync-to-dist.sh` after all source edits.
- **Latent bug**: `plan-3-v3-architect/SKILL.md:50,231` carries a 2-deep harness-doc fallback chain that omits the canonical name. Repair in same train (Critical Finding 03).
- **Cross-system frozen**: schema files, `.retro.md` path layout, `.disabled` sentinel, action menu, `engineering-harness.md` filename, runtime path root.
- **11 prior learnings** — most relevant: PL-04 (npx-skills orphan trap), PL-05 (vocabulary fragility), PL-06 (trust grep not the plan), PL-09 (sentinel + buffer-check cross-cutting gate).

## Target Domains

This spec touches domain-like boundaries not formalized in any `docs/domains/registry.md` (the registry doesn't exist in this repo). Formalizing them is a plan-025+ Workshop Opportunity, NOT in scope here.

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| harness (the loop family) | **proposed-but-unregistered** | **create** the `skills/harness/` category; **modify** the 3 surviving skills | New home for `harness-1-boot`, `harness-2-observe`, `harness-3-retro`; retire the philosophy skill |
| compound (the ledger substrate) | **proposed-but-unregistered** | **modify** (the `skills/compound/` dir shrinks to `schemas/` only) | Schemas stay; the 4 compound-* SKILL.md folders leave (2 renamed into harness/, 2 dropped to setup effort) |
| sdd-pipeline | existing-implicit | **consume** (8 skills carry `## Compound integration` appendices to update) | All 8 appendices update atomically to invoke harness-2/harness-3; no SDD behavior change |
| dev-tooling | existing-implicit | **consume** | `src/jk_tools/` synced; `justfile` recipe + `scripts/compound-value.sh` updated atomically |

## Testing Strategy

**Approach**: Lightweight (Round 1, Q2) — grep-audit gates as Done-When commands per PL-06/PL-09; walkthrough-style design review modeled on plan-023's `walkthroughs.md`; synthetic-fixture test for any retained behavior per PL-11.

**Rationale**: Most edits are markdown skill bodies + cross-reference updates. The "test" is a grep that returns empty (old name) or hits the expected files (new name). RED-GREEN-REFACTOR would be ceremony. Each atomic-update zone carries Verify pre/post grep commands — those ARE the tests.

**Focus Areas**:
- Grep-audit cascade verification after each rename (every atomic-update zone)
- `just doctor-skills` post-install run for orphan detection (PL-04)
- `npx skills add jakkaj/tools -a claude-code -g` smoke install — confirm catalog parses + 3 new slugs install + 6 old slugs gone
- Walkthroughs doc tracing `harness-2-observe` → `harness-3-retro --drain` → `harness-3-retro --harvest` against fixture retros
- `harness-3-retro --harvest --json` output shape regression check against `scripts/compound-value.sh`

**Excluded**: RED-GREEN-REFACTOR for markdown edits; performance/security tests (no such surface).

### Mock Usage

**Policy**: Avoid mocks entirely (Round 1, Q3) — real fixtures only (real `.retro.md` content for any harvest/drain test). KISS-aligned with PL-07; per FX001 RV-001 a mock would have hidden the boot-filter taxonomy bug that only real-fixture grep caught.

## Documentation Strategy

**Location**: Hybrid (Round 1, Q4) — update all 5 tools-repo governance docs atomically + encode the 5 principles inline into the surviving skill bodies + repo README.

**Update targets**:
- `CLAUDE.md` § Compounding Value System — rewrite layer naming + skill names; record vocabulary-freeze
- `AGENTS.md` — mirror the CLAUDE.md update
- `README_AGENTS.md` — fix install snippets (the two `--skill harness-is-the-product-v2` calls 404 after retirement) + catalog rows
- `INSTALL.md` — update 2 skill-name references (grep audit confirmed)
- `MIGRATION.md` — update 4 skill-name references (grep audit confirmed)

**Rationale**: PL-05 vocabulary fragility — under-documented renames creep back. Five-doc atomic update is the prevention. New repo README/CLI docs are OUT of scope (deferred).

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2 (3 skills moved/merged/extracted + 8 SDD appendices + 5 governance docs + tooling + mirror), I=1 (existing minih back-compat + npx-install paths preserved; no NEW integrations), D=1 (folder moves + path-preserving; schema/ledger paths unchanged), N=1 (rename/merge pattern established by plan-1b-v3 + plan-3-v3), F=0 (no perf/security surface), T=2 (grep-audit gates + dogfood install + `just doctor-skills` + atomic commit + cleanup)
- **Total P**: 7 → CS-3
- **Confidence**: 0.85 — name mapping now locked; main residual uncertainty is the `engineering-harness-v2` mode-extraction (separating VALIDATE+STATUS from CREATE cleanly).

### Assumptions

- The user's separate engineering-harness setup effort will (eventually) provide a scaffold path for fresh repos; this plan does not need to.
- The 8 SDD `## Compound integration` appendices update atomically in a single commit (PL-03).
- `npx skills` continues writing to `~/.agents/skills/` canonical + per-CLI symlinks (per `ff321a1`).
- The minih cross-system contract (IC-04, IC-08) stays stable during plan-024.

### Dependencies

- `npx skills` install path stability (Vercel Labs CLI — external)
- `just doctor-skills` recipe (per `ff321a1`) — orphan-detection verification tool
- `./scripts/sync-to-dist.sh` — canonical mirror sync command

### Risks

- **R1 (HIGH)**: Vocabulary regression — bare "harness" creeps back (PL-05). Mitigation: grep-audit gate as Done-When on the final cascade task.
- **R2 (HIGH)**: npx-skills orphan trap — old-named skills remain in `~/.agents/skills/<old>/` after rename (PL-04). Mitigation: explicit `rm -rf` cleanup of all 6 old slugs + `just doctor-skills` post-install.
- **R3 (MEDIUM)**: Tooling silent-breakage — `scripts/compound-value.sh` parses `compound-3-harvest --json` (Critical Finding 02). Mitigation: `harness-3-retro --harvest --json` preserves the same JSON shape OR atomic rewrite of script + recipe + help text.
- **R4 (MEDIUM)**: Mode-extraction error — separating `engineering-harness-v2` VALIDATE+STATUS (→ harness-1-boot) from CREATE (dropped) could leave dangling CREATE references in SDD skills that suggest `/engineering-harness-v2 --create`. Mitigation: grep for `--create` invocation suggestions during cascade; update to point at the setup effort or remove.
- **R5 (MEDIUM)**: Self-modifying skill ordering — modifying SDD orchestrators (plan-1a, plan-3, plan-6, plan-6a) that drive plan-024's own implementation (PL-02). Mitigation: order those edits LAST.
- **R6 (LOW)**: Cascade enumeration drift (PL-06). Mitigation: every cascade task's Done-When is a grep, not a hardcoded list.

### Phases (single phase per Simple Mode)

One phase with inline tasks; plan-3-v3-architect generates the task table under `## Implementation`. High-level task groups (plan-3-v3 will sequence with PL-02 driver-edits-LAST + PL-03 atomic-cascade in mind):

1. **Create `skills/harness/` + move/merge/extract the 3 surviving skills**:
   - `skills/compound/compound-1-track/` → `skills/harness/harness-2-observe/` (`git mv` + frontmatter `name:` + body refs). **Body refs = self-renames AND cross-skill references to DROPPED skills**: rewrite the `compound-0-setup` self-heal suggestions at `compound-1-track:58,121` to "no-op gracefully + report `UNAVAILABLE`" (per § first-run implication) — `compound-0-setup` has no successor slug, so they must NOT be re-pointed, they must be neutralized.
   - `skills/compound/compound-2-bubble/` + `skills/compound/compound-3-harvest/` → MERGE into `skills/harness/harness-3-retro/` (`--drain` = bubble body, `--harvest` = harvest body)
   - Extract VALIDATE + STATUS mode bodies from `skills/SDD/engineering-harness-v2/SKILL.md` → `skills/harness/harness-1-boot/SKILL.md`; DROP the CREATE mode body (goes to the user's separate setup effort — do NOT relocate it within this repo). **Also rewrite the dangling `--create` / `/agent-harness-v2` references inside the moved VALIDATE+STATUS body** (`engineering-harness-v2:248,268`) to point at the setup effort or remove — a graceful `UNAVAILABLE` that still prints "run `--create`" is a dead pointer. **DECISION RESOLVED (2026-05-28):** the CREATE-only `## Known Difficulties` ledger auto-seed (Step 4a) and `## Anti-Patterns` block live OUTSIDE the VALIDATE/STATUS sections. BOTH the *seed/write* AND any boot-time *read* are CREATE-time/setup concerns → out of scope (Non-Goal). Source-verified during plan validation: neither VALIDATE nor STATUS reads `## Known Difficulties`, so adding a boot-read would *add* behavior — `harness-1-boot` instead replicates VALIDATE+STATUS verbatim (nothing cut, nothing added). Re-introducing a boot-read is a deliberate future enhancement. Encoded in plan KF05 + T004.
2. **Retirement + philosophy distribution**: delete `skills/SDD/harness-is-the-product-v2/`; the 5 principles distribute inline:
   - "Harness IS the product" → repo README + `harness-1-boot` body header
   - "Track compounding value" → `harness-2-observe` description + body framing
   - "Encode don't document" → `harness-3-retro` body (the `--harvest` encode action IS the encoding)
   - "Measure" → `harness-1-boot` body
   - "Agents are real users" → repo README + cross-cutting framing in each skill's description
3. **Delete consumed source skills**: `skills/SDD/engineering-harness-v2/` (fully consumed — VALIDATE+STATUS moved, CREATE dropped); `skills/compound/compound-0-setup/` (dropped — scaffold concept is the setup effort's). `skills/compound/` shrinks to `schemas/` only.
4. **Cascade updates** — 4 atomic-update zones with grep-verified Done-When:
   - 8 SDD `## Compound integration` appendices → invoke `harness-2-observe` / `harness-3-retro --drain` / `harness-3-retro --harvest`; remove any `/engineering-harness-v2 --create` or `/compound-0-setup` invocation suggestions (point at the setup effort instead, or drop)
   - 5 governance docs → rewrite layer names + catalog rows + install snippets
   - Tooling → `justfile compound-value` recipe + `scripts/compound-value.sh` updated (same `--json` shape if rename-only; else atomic rewrite)
   - `src/jk_tools/` → `./scripts/sync-to-dist.sh` after all source edits
5. **Latent-bug fix** — `plan-3-v3-architect/SKILL.md:50,231` 2-deep → full 3-deep chain (`engineering-harness.md` → `agent-harness.md` → `harness.md`); Phase 0 instruction creates `engineering-harness.md` canonical name (Critical Finding 03).
6. **Cleanup verification** — `rm -rf ~/.agents/skills/{compound-0-setup,compound-1-track,compound-2-bubble,compound-3-harvest,engineering-harness-v2,harness-is-the-product-v2}/` (PL-04); `just install-skills-from-source`; `just doctor-skills`; `npx skills add jakkaj/tools -a claude-code -g` smoke install; grep-audit gates passing.
7. **Documentation** — `walkthroughs.md` design-review doc tracing the post-restructure loop with a synthetic `.retro.md` fixture; vocabulary-freeze recorded (commit message + CLAUDE.md paragraph).
8. **Plan-023 forward-pointer** — Critical Finding 06: one-line forward-pointer at top of `difficulty-ledger-skill-plan.md`.

## Acceptance Criteria

1. **AC1**: `grep -l 'compound-[0-9]' skills/SDD/*/SKILL.md` returns empty AND `grep -l 'harness-2-observe\|harness-3-retro' skills/SDD/*/SKILL.md` returns the 8 previously-tagged files (dossier DC-08).
2. **AC2**: `grep -rln 'harness-is-the-product\|engineering-harness-v2\|agent-harness-v2' skills/ CLAUDE.md AGENTS.md README_AGENTS.md INSTALL.md MIGRATION.md` returns empty (old names gone from all live skill bodies + governance docs). **Immutable / excluded from the audit** (these legitimately name the retired skills): all of `docs/plans/**` (including *this* plan folder), `docs/compound/agents/**/*.retro.md`, and `skills/compound/schemas/`. The legacy `agent-harness-v2` slug is included because grepping `engineering-harness-v2` alone misses it (e.g. `plan-1a-v2-explore:244,246`).
3. **AC3**: `grep -ln 'compound-[0-9]\|harness-is-the-product\|engineering-harness-v2\|agent-harness-v2' CLAUDE.md AGENTS.md README_AGENTS.md INSTALL.md MIGRATION.md` returns empty (old names) AND each doc references the new `harness-N-*` names. Pattern uses `compound-[0-9]` (not bare `compound-`) so it does not flag the kept `docs/compound/` runtime path or the `compound-value` recipe (AC4).
4. **AC4**: `harness-3-retro --harvest --json` preserves the **full** shape `scripts/compound-value.sh` consumes — `harness.{maturity,verdict,boot_ms}` AND `entries.{total,open,encoded,suggested}` AND `top_clusters[]` (8 jq paths total; the script defaults missing fields via `jq // 0`, so verify field *presence*, not just exit code). `scripts/compound-value.sh` (or renamed equivalent) produces non-empty output on a valid retro; `just compound-value` (or renamed) succeeds (Critical Finding 02).
5. **AC5**: `just doctor-skills` reports no orphans; `~/.agents/skills/{compound-0-setup,compound-1-track,compound-2-bubble,compound-3-harvest,engineering-harness-v2,harness-is-the-product-v2}/` explicitly removed + verified absent (PL-04).
6. **AC6**: `npx skills add jakkaj/tools -a claude-code -g` succeeds; the 3 new slugs (`harness-1-boot`, `harness-2-observe`, `harness-3-retro`) appear in `~/.claude/skills/`; the 6 old slugs are gone.
7. **AC7**: `skills/SDD/plan-3-v3-architect/SKILL.md` carries the full 3-deep fallback chain in **canonical-FIRST order** — `engineering-harness.md` → `agent-harness.md` → `harness.md` (lines 50 + 231 currently use a 2-deep `agent-harness.md`-first chain) AND Phase 0 instruction creates `engineering-harness.md` (canonical), not `agent-harness.md` (Critical Finding 03). This edit lands LAST in the commit train (PL-02 — plan-3 is the architect driving the work).
8. **AC8**: `harness-1-boot` reads `docs/project-rules/engineering-harness.md` (with `agent-harness.md` / `harness.md` fallback) and reports `UNAVAILABLE` gracefully when absent — proving the dropped CREATE mode left no hard dependency.
9. **AC9**: A `walkthroughs.md` traces a session through `harness-2-observe` → `harness-3-retro --drain` → `harness-3-retro --harvest` using a synthetic `.retro.md` fixture.
10. **AC10**: `docs/plans/023-difficulty-ledger-skill/difficulty-ledger-skill-plan.md` carries a forward-pointer line at the top noting the rename to plan-024 names.
11. **AC11**: Vocabulary-freeze recorded: (a) commit message + (b) CLAUDE.md § Compounding Value System paragraph stating the 3 `harness-N-*` names are stable ≥1 quarter.
12. **AC12**: The 5 retired principles are present inline at their planned locations (§ Phases Step 2); `grep -l 'compounding value\|encode.*don.*document\|agents.*real.*users\|harness.*is.*the.*product' skills/harness/ README.md` returns expected hits.
13. **AC13** (dangling-ref gate — closes the Step 1 / Step 4 coverage gap): `grep -rln 'compound-[0-9]\|engineering-harness-v2\|agent-harness-v2\|--create' skills/harness/*/SKILL.md` returns empty — proving the migrated bodies (`harness-1-boot`, `harness-2-observe`, `harness-3-retro`) carry NO dangling references to dropped skills/modes. (AC1 only scans `skills/SDD/`; G3's repo-wide grep is a Goal, not a gate — this AC is the gate for the new `skills/harness/` location.)

## Risks & Assumptions

See § Complexity § Risks (R1–R6) and § Complexity § Assumptions.

## Open Questions

All 7 dossier open questions are resolved (Round 1 + Round 2) or deferred:

- **OQ1 (naming)** — resolved: `harness-N-<role>` ordinals; loop-stage role names (boot/observe/retro), corrected from the substrate/ledger drift.
- **OQ2 (harness-retro shape)** — resolved: single skill, `--drain` / `--harvest` modes.
- **OQ3 (engineering-harness-v2 fate)** — resolved: VALIDATE+STATUS → `harness-1-boot`; CREATE dropped to the separate setup effort; `engineering-harness.md` filename preserved.
- **OQ4 (extraction timing)** — deferred to plan-025+ (Simple Mode).
- **OQ5 (docs/compound/ path)** — resolved: KEEP per IC-08/IC-09; only SKILL.md folders move to `skills/harness/`.
- **OQ6 (CLI scope)** — deferred to plan-025+ (Simple Mode).
- **OQ7 (harness-backpressure-eval)** — deferred to plan-025+ (net-new skill).

No remaining `[NEEDS CLARIFICATION]` markers.

## Workshop Opportunities

For plan-025+ (the extraction track). The engineering-harness **setup effort** is explicitly NOT listed here — the user owns it on a separate track.

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| New repo extraction (harness-nucleus standalone repo) | Storage Design / Integration Pattern | Cross-repo coordination; slug-collision risk; minih back-compat; deletion-PR coordination | Contract surface between tools-repo SDD skills and the new repo's harness skills? When does `skills/compound/schemas/` extract to `@ai-substrate/retro-schema` npm? |
| CLI + extension architecture | CLI Flow / API Contract | The new repo's CLI with extension points; extension boundary needs design | Python entry points vs shell hooks vs in-repo skill files? `harness <verb>` command surface? Extension discovery + load mechanism? |
| `harness-backpressure-eval` skill | State Machine / Integration Pattern | Net-new skill, no current analog; the dedicated mid-plan back-pressure analysis | Auto-fire (after planning? before implementation?) or user-invoked? New G8 gate in `plan-3-v3-architect`? |
| Formalize harness + compound as registered domains | Other (domain extraction) | DB-08 proposes `docs/domains/registry.md` + `domain-map.md`; introducing the registry is novel for this repo | Should the extraction track introduce the domain registry? Concept tables per domain.md? |

## Clarifications

### Session 2026-05-28

**Round 1** (front-loaded; before sketch):

- **Q1 (Workflow Mode)**: **Simple** — single-phase plan; defer multi-phase decomposition to plan-025+.
- **Q2 (Testing Strategy)**: **Lightweight** — grep-audit gates, walkthroughs.md-style review, synthetic fixtures.
- **Q3 (Mock Usage)**: **Avoid mocks entirely** — real fixtures only.
- **Q4 (Documentation Strategy)**: **Hybrid** — 5 governance docs + inline philosophy.

**Round 2** (sketch-dependent):

- **Q1 (Naming convention)**: **`harness-N-<role>` ordinals** — with loop-stage role names.
- **Q2 (harness-retro shape)**: **Single skill, two modes** — `harness-3-retro --drain` + `--harvest`.
- **Q3 (engineering-harness-v2 fate)**: **VALIDATE+STATUS → `harness-1-boot`; CREATE dropped** to the user's separate setup effort. Filename `engineering-harness.md` preserved (Critical Finding 03).

**Post-Round-2 correction** (user feedback during sketch review):

- Loop-stage role names (boot / observe / retro), NOT artifact/noun names (substrate / ledger). My initial sketch drifted to `harness-0-substrate` / `harness-1-ledger`; corrected to the loop-stage names the user originally specified.
- `compound-0-setup` and `engineering-harness-v2` CREATE mode are **DROPPED**, not renamed. Their scaffold/migration/audit concepts belong to a **separate engineering-harness setup effort the user is running independently** — out of scope here, not tracked even as a Workshop Opportunity.
- Final family: 3 skills (`harness-1-boot`, `harness-2-observe`, `harness-3-retro`) + 1 retirement (`harness-is-the-product-v2`) + 2 drops.

**Implicit decisions** (resolved by dossier defaults; not asked):

- **OQ5 (docs/compound/ path)**: KEEP per IC-08/IC-09 cross-system commitment with minih.
- **Agent harness governance for plan-024 itself**: Not needed. Markdown edits + script runs + git + npx install. No running app to Boot/Interact/Observe.

**Total questions asked**: 7 (4 Round 1 + 3 Round 2). Within the ≤8 cap.

---

*Spec status: VALIDATED WITH FIXES (v2.0) — plan generated (`harness-nucleus-plan.md`, Simple Mode, 17 tasks). The open scope decision (Known Difficulties relocation) is RESOLVED and encoded in plan KF05 + T004.*

---

## Validation Record (2026-05-28)

### Validation Thesis

**Raison d'être**: Direct a lossless, atomic consolidation of 6 compound+harness skills into 3 loop-stage skills (boot/observe/retro), retiring the philosophy skill by inlining its 5 principles, dropping 2 setup-time skills to a separate effort, and cascading every cross-reference atomically so no SDD consumer, the minih cross-system contract, or the `engineering-harness.md` filename contract silently breaks.

**Value claim**: Implementation can proceed knowing it is pure rename/merge (nothing lost, nothing added) and the surviving skills work as a companion set assuming an already-set-up engineering harness.

**Proof target**: Implementation-readiness, tested with source-code-match evidence (not the spec's self-assertion).

**Thesis source**: User request ("that my assertions are true and that we are ready to implement") + this spec + `research-dossier.md` + multi-turn scope conversation.

**Thesis verdict**: Partially advanced — assertions hold for the merge/rename and "nothing added"; the spec as originally written would silently cut two *runtime* concepts mis-filed as setup-time, and the user's "ready to implement" is overstated (status is architect-ready).

**Main thesis risk**: Accepting the spec as "ready to implement" ships a never-passable AC2 and a dangling-reference coverage gap as Done-When gates — defeating the integrity guarantee the consolidation exists to provide. (Both fixed in this pass.)

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Concept-Preservation | Concept Documentation, Hidden Assumptions, Evidence Sufficiency, System Behavior | 2 HIGH, 2 MED, 2 LOW | nothing-cut: YES-with-caveats |
| Thesis + Readiness | Thesis Alignment, Proof-Level Fit, Completeness, Coherence | 1 HIGH (AC2), 3 MED, 2 LOW | architect-ready, not implement-ready |
| Forward-Compatibility | Forward-Compatibility, Integration & Ripple, Deployment & Ops | 1 BLOCKED (dangling refs), 2 MED, 2 LOW | 4/5 consumers PASS |

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| `/plan-3-v3-architect` (+ PL-02 self-edit) | Complete spec + own 2-deep chain fixed canonical-first, edited LAST | Contract drift / lifecycle | PASS (was LOW) | AC7 tightened to canonical-first + LAST-in-train |
| 8 SDD `## Compound integration` appendices | Stable new names + dropped `--create`/`compound-0-setup` suggestions removed | Dead pointer | PASS | Step 4 zone 1 + AC1; `agent-harness-v2` added to AC2/AC3 patterns |
| `scripts/compound-value.sh` + justfile | `--harvest --json` keeps all 8 jq paths | Shape mismatch | PASS (was LOW) | AC4 expanded to full 8-path schema |
| minih (cross-system) | Schemas + `.retro.md` layout + `.disabled` + action menu untouched | Contract drift | PASS | Non-Goals fence all; no task edits them |
| Migrated skill bodies (`harness-1-boot`, `harness-2-observe`) | No dangling refs to dropped skills inside moved bodies | Dead pointer | PASS (was BLOCKED) | Step 1 broadened to cross-skill refs + new AC13 greps `skills/harness/` |

**Thesis alignment**: Value claim partially advanced; target Implementation, actual Architect-ready; main risk was un-passable gates + silently-cut runtime concepts — gates fixed; one concept-relocation decision remains open.

**Outcome alignment**: Outcome = "name the loop stage each skill serves and retire one skill, WITHOUT breaking the 8 SDD consumers, the minih cross-system contract, or the engineering-harness.md filename contract." — The spec advances loop-stage naming, the retirement, the 8 SDD consumers, the minih contract, and the filename contract (4 of 5 consumers PASS); the 5th (migrated bodies carrying dangling refs to dropped skills) was BLOCKED and is now closed by the broadened Step 1 + AC13.

**Standalone?**: No — concrete downstream consumers exist (plan-3, 8 SDD appendices, tooling, minih).

### Resolved decision — `## Known Difficulties` auto-seed (relocated, not silently dropped)

`engineering-harness-v2` Step 4a auto-seeds a `## Known Difficulties` friction table from the compound ledger, and a `## Anti-Patterns` block — both live inside CREATE mode (dropped). These are NOT in VALIDATE/STATUS, so a naive "extract VALIDATE+STATUS, drop CREATE" would silently lose them. **Resolution (confirmed 2026-05-28, refined during plan validation)**: BOTH the *seed/write* and any boot-time *read* are out of scope. Source-verified: neither VALIDATE nor STATUS reads `## Known Difficulties`, so a boot-read would be net-new behavior. `harness-1-boot` replicates VALIDATE+STATUS verbatim → nothing cut, nothing added. The seed goes to the separate setup effort; re-adding a boot-read is a future enhancement. Encoded in `harness-nucleus-plan.md` KF05 + T004.

Overall: **VALIDATED WITH FIXES** — mechanical gate defects (AC2/AC3/AC4/AC7) and the dangling-ref coverage gap (Step 1 + AC13) fixed in this pass; one scope decision (Known Difficulties relocation) flagged for the user.
