# Flight Plan: Backpressure Survey Skill

**Spec**: [backpressure-survey-spec.md](./backpressure-survey-spec.md)
**Plan**: [backpressure-survey-plan.md](./backpressure-survey-plan.md)
**Generated**: 2026-05-29
**Status**: Landed

---

## The Mission

**What we're building**: A new SDD-pipeline skill, `plan-2d-backpressure-survey`, that runs after the spec and before the architect. It asks the one question nothing in the pipeline asks today: *will we be able to **prove** this work deterministically, or are we going to be eyeballing it?* It inventories the deterministic sensors a repo already has, maps them against the feature's real failure modes, rates coverage, and — when there are gaps — recommends building the missing sensors as a "Phase 0" before feature work begins.

**Why it matters**: It pulls the computational-control tier (Pattern 18) forward to design time, so missing backpressure is caught and planned for *before* code is written — not discovered during review when it's expensive.

---

## Where We Are → Where We're Headed

```
TODAY:                                  AFTER this plan:
plan-1b → (2c) → plan-3                  plan-1b → (2c) → [plan-2d] → plan-3

🔵 plan-1b spec (same)                   🟡 plan-1b → suggests plan-2d
❌ no deterministic-coverage check        🔴 plan-2d backpressure survey (NEW)
🔵 plan-3 reads research/workshops       🟡 plan-3 → also reads backpressure-coverage.md
🔵 plan-7 inferential review (same)      🔵 plan-7 inferential review (unchanged)
```

🔵 unchanged 🟡 modified 🔴 new

---

## Scope

**Goals**:
- New `skills/SDD/plan-2d-backpressure-survey/SKILL.md` (4-step survey routine).
- Emits advisory `backpressure-coverage.md`: inventory + coverage matrix + qualitative certainty + conditional Recommended Phase 0.
- Wire `plan-1b` (next-step suggestion) and `plan-3` (consume artifact → bake Phase 0).
- Catalog + pipeline-reference docs.

**Non-Goals**:
- Not a blocking gate; no numeric thresholds; no persisted index.
- Does not replace plan-7 (inferential tier stays).
- Does not build sensors or any harness/CLI in this repo.

---

## Journey Map

```mermaid
flowchart LR
    classDef done fill:#4CAF50,stroke:#388E3C,color:#fff
    classDef ready fill:#9E9E9E,stroke:#757575,color:#fff

    S[Specify]:::done --> P[Plan]:::done
    P --> P1[Implementation: skill + wiring + docs]:::done
    P1 --> D[Done]:::done
```

**Legend**: green = done | grey = not started

---

## Phases Overview

| Phase | Title | Tasks | CS | Status |
|-------|-------|-------|----|--------|
| 1 | Implementation (skill + wiring + docs + validate) | 5 | CS-2 | Complete |

---

## Acceptance Criteria

- [ ] New `plan-2d-backpressure-survey/SKILL.md` with valid frontmatter + 4-step routine.
- [ ] Artifact spec: inventory + coverage matrix (EXISTS/BUILDABLE/ABSENT × computational/inferential/human-judgement) + qualitative certainty + conditional Phase 0.
- [ ] Stated invariant: advisory, never blocks, no thresholds, no index file, honours `.disabled`.
- [ ] `plan-1b` next-step suggestion added.
- [ ] `plan-3` consumes the artifact when present; absence is a no-op.
- [ ] `check-skill-slugs.sh` exits 0.
- [ ] Smoke run against a real spec + plan-3 round-trip verified.
- [ ] Catalog + pipeline-reference list the skill.

---

## Key Risks

| Risk | Mitigation |
|------|-----------|
| Drift toward a blocking gate | "Advisory, never blocks, no thresholds" stated as an invariant in the SKILL.md body. |
| Overlap with plan-3 G6 / plan-7 | SKILL.md includes a short "how this differs" note. |
| plan-3 edit makes the artifact mandatory | Phrased "if present"; absence required to be a no-op. |

---

## Flight Log

### Phase 1: Implementation — Complete (2026-05-29)

**What was done**: Authored `skills/SDD/plan-2d-backpressure-survey/SKILL.md` (4-step survey routine + artifact template + advisory invariant + `.disabled` opt-out + "how this differs from G6/plan-7" note). Wired `plan-1b` (next-step suggestion) and `plan-3` (two touchpoints: PHASE 2 sibling read + an optional, parallel "Phase 0: Establish Backpressure" conditional — no new gate). Added catalog + pipeline-reference docs. Validated: slug check exit 0, frontmatter matches folder, smoke run produced a well-formed `backpressure-coverage.md` (Partial certainty, dogfooded on its own spec), and the plan-3 round-trip verified deterministically (touchpoints present, `G8` count = 0, absence-is-no-op wording present).

**Key changes**:
- `skills/SDD/plan-2d-backpressure-survey/SKILL.md` — new skill
- `skills/SDD/plan-1b-v3-specify-and-clarify/SKILL.md` — next-step suggestion
- `skills/SDD/plan-3-v3-architect/SKILL.md` — two-touchpoint advisory consume
- `README_AGENTS.md`, `docs/skills-pipeline/README.md` — catalog + pipeline ref
- `docs/plans/025-backpressure-survey/backpressure-coverage.md` — smoke-run artifact

**Decisions made**: Kept strictly advisory (no gate, no thresholds, no index). The plan-3 Phase-0 mechanism was harness-specific, so T003 added a *parallel* conditional rather than reusing a generic hook (per validation).
