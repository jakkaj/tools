# Backpressure Coverage — Backpressure Survey Skill

**Spec**: [backpressure-survey-spec.md](./backpressure-survey-spec.md)
**Generated**: 2026-05-29
**Certainty**: Partial

> Advisory only — informs `plan-3`. Never blocks, never gates, no scores. (See plan-2d-backpressure-survey.)
> Produced as the T005 smoke run (scenario 1: a repo WITH deterministic sensors). Dogfoods the skill on its own spec.

## Existing Sensors (inventory)

| Sensor | Command | Dimension |
|--------|---------|-----------|
| Slug-collision check | `bash scripts/check-skill-slugs.sh` | architecture-fitness |
| Skills symlink/orphan doctor | `just doctor-skills` | architecture-fitness |
| Frontmatter `name`↔folder match | `awk '/^name:/' SKILL.md` vs leaf dir | behaviour |
| Doc-listing presence | `grep plan-2d-backpressure-survey README_AGENTS.md docs/skills-pipeline/README.md` | maintainability |
| (build/test/typecheck) | — none — SKILL.md is prose, not executable code | — |

## Coverage Matrix

| Criterion / failure mode | Deterministic sensor | Status | Tier |
|--------------------------|----------------------|--------|------|
| AC-6: slug does not collide (silent overwrite at install) | `check-skill-slugs.sh` exit 0 | **EXISTS** | computational |
| AC-1: frontmatter valid, `name` = folder | awk/parse + folder compare | **EXISTS** | computational |
| AC-8: both docs list the skill | grep both files for slug | **EXISTS** | computational |
| Skill body drifts to a blocking gate / numeric threshold (AC-3 invariant) | grep-lint asserting "never blocks / no numeric / no index" present AND absence of threshold words | **BUILDABLE** | computational |
| AC-5: plan-3 edit stays "if present" / never mandatory | grep-lint on plan-3 diff for "if present" + absence of new `G`-gate row | **BUILDABLE** | computational |
| AC-2: artifact emits all required sections + correct certainty for inputs | run skill on a fixture spec, assert section headings + tier vocab | **BUILDABLE** | computational |
| Skill produces a *useful/correct* survey (good judgement of failure modes) | — (judgement) | **ABSENT** | inferential |
| Skill body reads clearly for a fresh agent | — (taste) | **ABSENT** | human-judgement |

## Certainty: Partial

The deterministic-provable criteria (slug, frontmatter, doc-sync) have **EXISTS** sensors; the invariant-preservation and artifact-shape criteria are **BUILDABLE** (a small grep-lint over the SKILL bodies). The remaining behaviour ("is the survey *good*") is inherently **inferential** (prose-skill judgement) and correctly routes to `validate-v2` / `plan-7` + human — it does not drag the rating. Net: gaps are buildable, not absent → **Partial**.

## Recommended Phase 0: Establish Backpressure

| Sensor to build | Proves | Suggested form |
|-----------------|--------|----------------|
| Skill-invariant lint | AC-3 invariant present + no threshold/gate words crept into the SKILL body | `scripts/lint-skill-invariants.sh` (grep): assert `never blocks`/`no numeric`/`no persisted index` present; fail on `must be ≥`, `threshold`, `flip.*DRAFT` in plan-2d | 
| plan-3 advisory-guard lint | AC-5: the plan-3 consume-edit stays "if present" and adds no `G`-gate | grep that the `backpressure-coverage.md` block in plan-3 contains "if ... exists" + "Absence ... changes nothing" and does NOT add a new `| G8 ` row to the Gate Matrix |
| Artifact-shape smoke | AC-2: a survey run emits Inventory + Coverage Matrix + Certainty (+ conditional Phase 0) with the correct EXISTS/BUILDABLE/ABSENT × tier vocab | a fixture spec + a `grep`-based assertion script over the emitted `backpressure-coverage.md` |

> Note: this Phase 0 is **genuinely optional**. The three lints would harden the best-effort invariant against future drift (the top plan risk) — but the feature ships fine without them, since `validate-v2` already caught the drift risks inferentially this round. Build them only if you want the invariant enforced deterministically going forward.
