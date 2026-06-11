# Flow Skill Consolidation — one progressive-disclosure `the-flow` skill

**Mode**: Simple
**Created**: 2026-06-11
**Original ask**: [original-ask.md](./original-ask.md)

ℹ️ No `research-dossier.md` — research context below is drawn from the in-conversation assessment (2026-06-11): the progressive-disclosure migration doc at `scratch/paste/20260611T080711.md`, measured skill sizes, and the agreed target tree.

## Research Context

- The 13 main-flow SDD skills total **~6,046 lines** across `skills/SDD/` (the-flow 519, plan-8 1039, plan-1a 1033, plan-2c 619, plan-3a 471, plan-6-companion 424, plan-3 417, plan-7 412, plan-5 399, plan-1b 251, plan-6 234, plan-6a 157, plan-2 71).
- The migration doc's decision rubric scored this family ~15/24 ("strong candidate"); the agreed design keeps the router small and modules lazy so per-step context does not regress (today's bare `/plan-6` = 234 lines; target dispatch+module ≈ 330).
- `the-flow` is already the router/state machine; the Skill tool is today's lazy-loading mechanism. The consolidation makes the family's *file layout* match that architecture and cuts the public surface from 13 to 1.
- Known costs accepted up front: `/plan-N` muscle memory dies (no back-compat aliases — house rule), other CLIs see one skill, stage modules are invisible to skill discovery except via the dispatch table.
- `npx skills add` never prunes — retired slugs linger in deploy targets until tidied (`just skills-orphans`).

## Summary

Collapse the main SDD pipeline — currently 13 public skills (`plan-1a`, `plan-1b`, `plan-2`, `plan-2c`, `plan-3`, `plan-3a`, `plan-5`, `plan-6`, `plan-6-companion`, `plan-6a`, `plan-7`, `plan-8`, `the-flow`) — into **one** public progressive-disclosure workflow skill: a small dispatch `SKILL.md` plus lazily-loaded stage modules under `references/stages/`. Guided mode keeps today's coaching (rail, narration, print-then-offer) via a `coach.md` module; direct jump (`/the-flow 6 --phase …`) loads exactly one stage module with no coach overhead. Utilities stay public and untouched. A rollback path lets the current 13-skill surface be restored quickly if the consolidation sucks.

## Goals

- **One public skill** for the whole pipeline: `the-flow` (small dispatch SKILL.md, ~100–150 lines).
- **12 skills fold in** as `references/stages/` modules; `plan-2-v2-clarify` is absorbed into the specify module as a re-entry section (it's already soft-deprecated).
- **Two load paths**: guided (`/the-flow` → coach + routing + current stage only) and direct jump (`/the-flow <stage> [flags]` → that stage module only).
- **Dedupe shared boilerplate** (NO TIME ESTIMATES block, CS rubric, harness-seam paragraphs, domain-loading preamble) — stated once in the dispatch/routing layer, inherited by all stages.
- **Quick rollback**: git tag **`pre-flow-consolidation`** on main before cutover; restore = `git checkout pre-flow-consolidation -- skills/SDD && just install-skills-from-source`. Zero bytes in the working tree, no branches.
- **Clean cutover (atomic)**: one plan, one cut — tag first, build the new structure, delete the 12 folders, sweep catalogs, deploy, tidy orphans. No window with both surfaces live.
- **Behaviour preserved**: stage logic moves, it is not redesigned; harness seams (`/eng-harness-flow --event …`) fire identically from the modules.

## Non-Goals

- **Utilities unchanged**: `validate-v2`, `flowspace-research-v2`, `code-concept-search-v2`, `deepresearch-v2`, `didyouknow-v2`, `htmlify-v2`, `util-0-v2-handover`, `plan-0-v2-constitution`, `plan-2b-v2-prep-issue`, `plan-6b-worked-example`, `plan-v2-extract-domain`, `install-hve-core-rpiv` stay public, byte-identical.
- **No stage-logic redesign** — this is a re-housing + dedupe, not a rewrite of what each stage does.
- **No new runtime tooling** — no validators, no CLIs, no persisted derived state (KISS).
- **Harness family untouched** — `/eng-harness-flow` remains the single external door; no child-skill names appear anywhere.
- **`docs/plans/**` history untouched** — old slugs in past plans remain as point-in-time records.
- **minih retro schema contract untouched.**
- **No back-compat aliases** — `/plan-6` etc. are not shimmed; the cut is clean (house rule).

## Target Domains

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| sdd-pipeline-skills | **NEW** (concept-only) | **modify** | The `skills/SDD/` tree — 13 skills consolidated to 1 + stage modules |

### New Domain Sketches

#### sdd-pipeline-skills [NEW — concept-only]
- **Purpose**: The spec-driven-development pipeline surface this repo ships (`skills/SDD/`), distributed via `npx skills`.
- **Boundary Owns**: pipeline skill content, stage modules, the dispatch/routing contract, flight-plan schema/template, getting-started guide.
- **Boundary Excludes**: utility skills (stay as peers), the external eng-harness family, installer infra (`install/`, `agents/`), distribution mirror (`src/jk_tools/` — auto-synced, never edited).
- **Note**: this repo maintains no `docs/domains/` registry; this is a documentation mapping only — no `domain.md` machinery will be created.

## Testing Strategy

- **Approach**: Lightweight (scripted validation tasks; no runtime code exists)
- **Rationale**: skill content is markdown — verification is structural checks + a behavioural drive of the new surface.
- **Focus Areas**: `scripts/check-skill-slugs.sh` (no collisions); JSON validity of `flight-plan.schema.json`/`.template.json`; grep sweeps proving zero live references to retired slugs (catalogs, skills, justfile); `just doctor-skills` + deploy smoke (`just install-skills-from-source`); a quick drive of fresh / resume / direct-jump paths confirming only the intended module is loaded per step.
- **Excluded**: a formal committed eval suite; CI automation.
- **Mock Usage**: none — real files, real deploy targets, real `npx skills` runs.

## Documentation Strategy

- **Location**: update existing docs only — `README_AGENTS.md` (catalog), `docs/skills-pipeline/README.md`, `CLAUDE.md`, and the consolidated skill's own `references/getting-started.md`.
- **Rationale**: the skill's bundled references are the how-to; new doc files would be ceremony.

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2, I=2, D=1, N=1, F=0, T=1 (P=7)
- **Confidence**: 0.75
- **Assumptions**: stage bodies move largely verbatim (minus deduped boilerplate); the Skill-tool host resolves one skill with args the same way it resolves many.
- **Dependencies**: `npx skills` flatten/deploy behaviour; `just install-skills-from-source`; `scripts/check-skill-slugs.sh`.
- **Risks**: see Risks & Assumptions.
- **Phases**: single phase (Simple) — ordered task groups: rollback anchor → scaffold + modules → dispatch SKILL.md → cutover (delete + sweep) → deploy + verify.

## Acceptance Criteria

1. `skills/SDD/` contains **exactly one** main-flow skill (`the-flow`); the 12 absorbed skill folders no longer exist in source.
2. `the-flow/SKILL.md` is a dispatch layer ≤ ~150 lines: stage table (id + name → module path), global invariants, state contract pointer, and the progressive-disclosure rule ("load exactly one module for the current state — never read all modules up front").
3. `references/stages/` holds modules covering all 11 absorbed capabilities (explore, specify+clarify, workshop, architect, adr, phase-tasks, implement, implement-companion, progress, review, merge), each with entry conditions, procedure, output contract, and next-routing.
4. Guided mode: `/the-flow` (no args) loads `coach.md` + routing + the current stage module only, and preserves today's behaviour — rail, narration beats, print-then-offer, fresh/resume/adopt, `.the-flow-state.json` contract.
5. Direct jump: **numbers and names both resolve** — `/the-flow 6 --phase "<P>" --plan "<path>"` and `/the-flow implement --phase "<P>" --plan "<path>"` execute identical implement-phase behaviour, loading only that stage module.
6. Clarify re-entry (old `plan-2`) is reachable as a section of the specify module.
7. Rollback: tag `pre-flow-consolidation` exists on the pre-cutover commit; `git checkout pre-flow-consolidation -- skills/SDD && just install-skills-from-source` restores the prior 13-skill surface end-to-end (source + deploy), documented in the plan's execution log.
8. `scripts/check-skill-slugs.sh` exits 0; flight-plan schema + template remain valid JSON.
9. Grep for the 12 retired slugs across live surfaces (`skills/`, `README_AGENTS.md`, `docs/skills-pipeline/`, `CLAUDE.md`, `justfile`, `scripts/`) returns only intentional historical mentions (`docs/plans/**` untouched).
10. `just install-skills-from-source` succeeds; canonical store carries the new `the-flow`; `just skills-orphans` lists the 12 retired slugs with tidy lines; after tidy, no live deploy target resolves a retired slug.
11. Harness-seam parity: every `/eng-harness-flow --event …` invocation present in today's 13 skills appears identically in the consolidated modules (same events, same flags).
12. An in-flight `.the-flow-state.json` (e.g. this plan's own, at `awaiting-*`) still resumes correctly under the consolidated skill.

## Risks & Assumptions

| Risk | Mitigation |
|------|-----------|
| Boilerplate dedupe drops a load-bearing instruction | Per-module diff against its source skill during review; AC 11's grep parity for harness seams |
| Hidden monolith — dispatch SKILL.md balloons | AC 2 caps it; details live only in modules |
| Stale deployed copies of retired skills (npx never prunes) | AC 10 — `skills-orphans` + tidy as an explicit task |
| Self-reference: this very plan is being driven by the skill being replaced | Deploy is the last task; the running session keeps its loaded context; post-cutover resume is AC 12 |
| Other CLIs / muscle memory lose `/plan-N` entry | Accepted, documented in catalogs; direct-jump grammar is the replacement |
| Module invisibility to skill discovery | Dispatch table in SKILL.md enumerates every module with a one-liner |

## Open Questions

None — all resolved in Clarifications (Session 2026-06-11).

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Dispatch contract (`SKILL.md` surface) | CLI Flow | The routing table IS the product; getting arg grammar + module map right up front avoids rework | Stage ids/names; flag pass-through; behaviour when a module is missing; how coach vs direct paths share state writes |

*(Likely skippable — the in-conversation design already settled the target tree; the architect can fold this in.)*

## Clarifications

### Session 2026-06-11

- Q: Workflow mode? → A: **Simple** — single-phase plan, inline ordered tasks.
- Q: Testing strategy? → A: **Lightweight** — scripted structural checks + behavioural drive of fresh/resume/direct-jump.
- Q: Mock usage? → A: **Avoid mocks** — real files, real deploy targets, real `npx skills` runs.
- Q: Documentation strategy? → A: **Update existing only** — README_AGENTS, docs/skills-pipeline/README, CLAUDE.md, bundled getting-started; no new doc files.
- Q: Rollback mechanism? → A: **Git tag** — `pre-flow-consolidation` on main before cutover; restore via `git checkout pre-flow-consolidation -- skills/SDD` + redeploy. No branches, no archive copies.
- Q: Cutover timing? → A: **Atomic** — tag, build, delete the 12 folders, sweep, deploy, tidy orphans in one plan. No dual-surface window.
- Q: Direct-jump grammar? → A: **Numbers + names** — `/the-flow 6 …` and `/the-flow implement …` are equivalent.
