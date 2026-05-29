# Backpressure Survey Skill (`plan-2d-backpressure-survey`)

**Mode**: Simple
**Spec Version**: 1.0.0
**Created**: 2026-05-29
**Status**: Specifying

ℹ️ Consider running `/plan-1a-explore` for deeper codebase understanding (skipped here — the design was settled in a prior grounded design discussion against the `harness-foundations` source docs).

## Summary

Add a new SDD-pipeline skill, `plan-2d-backpressure-survey`, that runs **after the spec** (`plan-1b` / `plan-2c`) and **before the architect** (`plan-3-v3-architect`). It surveys whether the planned work can be **proven by deterministic backpressure** — build/type/test/lint/smoke/boot/architecture checks, CodeQL/Roslyn/dependency-rules/data-scripts — rather than by agent inference or human eyeballing. It writes an advisory `backpressure-coverage.md` artifact into the plan folder that `plan-3` consumes (like it already consumes `workshops/` and `research-dossier.md`) and turns into a real **"Phase 0: Establish Backpressure"** when material gaps exist.

This is the **computational-control counterpart** to `plan-7-v2-code-review` (the inferential/eyeball tier, which stays exactly as-is). It pulls Pattern 18 ("tier computational vs inferential controls — run computational early and often") forward to design time, filling a gap no current stage covers.

## Goals

- Author `skills/SDD/plan-2d-backpressure-survey/SKILL.md` implementing the 4-step survey routine (inventory → derive failure modes → coverage matrix → advisory verdict).
- Produce a `backpressure-coverage.md` artifact with: existing-sensor inventory, a coverage matrix (criterion/failure-mode → deterministic sensor → status `EXISTS`/`BUILDABLE`/`ABSENT` → tier `computational`/`inferential`/`human-judgement`), a qualitative **certainty rating** (Strong/Partial/Weak), and a conditional **Recommended Phase 0** sensor-building table.
- Wire it in: `plan-1b` gains a next-step suggestion; `plan-3` gains a sibling artifact read that converts the Recommended Phase 0 into an actual planned Phase 0 via its existing Phase-0 insertion mechanism.
- Keep it **advisory/best-effort**: never blocks, never flips a plan to DRAFT, no numeric thresholds/floors, no persisted index state.
- Honour the `docs/compound/.disabled` opt-out sentinel.
- Add a catalog entry (README_AGENTS.md) + a one-line pipeline-reference mention (docs/skills-pipeline/README.md).

## Non-Goals

- **Not** a blocking gate. It does not gate `plan-3`, does not flip Status to DRAFT, and emits no numeric coverage floor.
- **Not** a replacement for `plan-7` code review — the inferential/eyeball tier stays. This is its computational complement, earlier in the pipeline.
- **Not** a builder of sensors. It *recommends* and *specifies* sensors (the Phase 0 tasks); `plan-3`/`plan-6` do the actual building if the user accepts.
- **Not** building or requiring an engineering/agent harness in *this* repo. The skill *reads* `engineering-harness.md` in target repos when present and degrades gracefully when absent.
- **No** new CLI, domain registry, or runtime — pure SKILL.md authoring plus two small markdown edits (per the harness-extraction-is-separate constraint).
- **Not** renaming or touching the frozen `skills/harness/` family or the `skills/compound/schemas/` contract.

## Target Domains

> This repo has no formal `docs/domains/` registry — the **skills themselves are the product** (per CLAUDE.md). The table below maps the skill files this change touches as informal domains.

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| `skills/SDD/` pipeline | existing | **create** | New `plan-2d-backpressure-survey/SKILL.md` |
| `plan-1b-v3-specify-and-clarify` | existing | **modify** | Add a "Next steps" suggestion pointing at plan-2d |
| `plan-3-v3-architect` | existing | **modify** | Add a sibling artifact read (consume `backpressure-coverage.md` → bake Phase 0) |
| Docs (README_AGENTS.md, docs/skills-pipeline/README.md) | existing | **modify** | Catalog entry + pipeline-reference mention |

## Testing Strategy

- **Approach**: Lightweight.
- **Rationale**: `SKILL.md` is prose/instructions, not executable code — no unit-test framework applies.
- **Focus Areas**:
  - `scripts/check-skill-slugs.sh` exits 0 (no slug collision for `plan-2d-backpressure-survey`).
  - Frontmatter is valid (`name:` matches leaf folder; `description:` present).
  - **Smoke run**: invoke the new skill against a real existing spec (e.g. an earlier `docs/plans/NNN-*/`) and confirm it emits a well-formed `backpressure-coverage.md` with all required sections and a sensible certainty rating.
  - Round-trip: confirm `plan-3` reads the artifact and inserts a "Phase 0: Establish Backpressure" when the artifact recommends one (and does nothing when it doesn't).
- **Excluded**: automated unit/integration tests (no harness for prose skills).

## Documentation Strategy

- **Location**: Hybrid — public catalog (`README_AGENTS.md`) + a one-line ordering mention in `docs/skills-pipeline/README.md`.
- **Rationale**: the `SKILL.md` body is the primary, self-shipping doc (travels via `npx skills`); the catalog + pipeline reference make it discoverable in the pipeline sequence.

## Complexity

- **Score**: CS-2 (small)
- **Breakdown**: S=1, I=1, D=0, N=1, F=0, T=0  (total 3 → CS-2)
- **Confidence**: 0.85
- **Assumptions**: design already settled (home + routine + artifact format agreed in prior discussion); plan-3's Phase-0 insertion mechanism is reusable as-is.
- **Dependencies**: none blocking; reads (does not require) `engineering-harness.md`.
- **Risks**: see below.
- **Phases**: single (Simple mode).

## Acceptance Criteria

1. `skills/SDD/plan-2d-backpressure-survey/SKILL.md` exists with valid frontmatter (`name: plan-2d-backpressure-survey`) and a body specifying the 4-step routine.
2. The skill's specified output is a `backpressure-coverage.md` containing, in order: existing-sensor **Inventory**, a **Coverage Matrix** (with the four status/tier vocabularies), a qualitative **Certainty** verdict (Strong/Partial/Weak) with a one-line rationale, and a **Recommended Phase 0** table that appears **only** when material `BUILDABLE`/`ABSENT` gaps exist on behaviour/architecture dimensions.
3. The skill body explicitly states it is advisory: never blocks, never flips a plan to DRAFT, emits no numeric threshold, persists no index file, and checks `docs/compound/.disabled` before firing.
4. `plan-1b-v3-specify-and-clarify` "Next steps" includes a suggestion to run `/plan-2d-backpressure-survey` before `/plan-3`.
5. `plan-3-v3-architect` reads `backpressure-coverage.md` when present (sibling to its existing research/workshop reads) and converts a Recommended Phase 0 into a planned "Phase 0: Establish Backpressure"; absence of the artifact changes nothing (no error, no gate).
6. `scripts/check-skill-slugs.sh` exits 0 with the new skill present.
7. A smoke run against a real existing spec produces a well-formed artifact (criteria 2) and the round-trip into `plan-3` behaves per criterion 5.
8. Catalog (`README_AGENTS.md`) and pipeline reference (`docs/skills-pipeline/README.md`) list the new skill.

## Risks & Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Skill drifts toward a blocking gate over time | Low | High (violates best-effort constraint) | Bake "advisory, never blocks, no thresholds" into the SKILL.md body as a stated invariant (AC-3); mirror the wording from the compound best-effort principle. |
| Overlap/confusion with plan-3 G6 (Testing Alignment) | Med | Med | SKILL.md includes a short "how this differs from G6 / plan-7" note: G6 checks test-tasks-exist + measurable criteria; plan-7 is inferential; plan-2d surveys deterministic-sensor coverage of failure modes. |
| `plan-3` edit accidentally makes the artifact mandatory | Low | Med | Edit is phrased as "if present"; AC-5 explicitly requires absence to be a no-op. |
| Certainty rating misread as a score/SLA | Med | Low | Keep it qualitative (Strong/Partial/Weak) with rationale; no numbers (AC-2/AC-3). |
| Target repo has no `engineering-harness.md` / no justfile | Med | Low | Skill degrades gracefully — inventory simply reports "no deterministic sensors found" and certainty trends Weak with a Phase 0 recommendation. |

## Open Questions

- None blocking. Skill ordinal name `plan-2d` assumes the slot after `plan-2c-workshop`; if a different number is preferred it is a trivial rename before merge.

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| (none) | — | Design already settled against `harness-foundations` sources in prior discussion; artifact format + routine + wiring agreed. Skip workshop. | — |

## Clarifications

### Session 2026-05-29

- **Workflow Mode**: Simple (CS-2, markdown-only change). [Round 1]
- **Testing Strategy**: Lightweight — slug check + frontmatter validation + smoke run against a real spec + plan-3 round-trip. [Round 1]
- **Mock Usage**: Avoid mocks — use a real existing `docs/plans/` spec as the fixture. [Round 1]
- **Documentation Strategy**: Hybrid — README_AGENTS.md catalog entry + docs/skills-pipeline/README.md pipeline mention. [Round 1]
- **Home/wiring decision** (pre-spec): standalone pre-`/3` skill that writes `backpressure-coverage.md`, consumed by `plan-3` (chosen over an in-plan-3 advisory section or a both-pieces hybrid). [Design discussion]
- **Agent Harness Readiness**: **Not applicable.** This feature authors prose `SKILL.md` instructions — there is no runnable product surface to boot/interact/observe, so no agent harness (and no Phase 0 harness build) is needed for *this* feature. Round 2 skipped on that basis. [Recorded, not asked]
