# Backpressure Survey Skill Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-05-29
**Spec**: [backpressure-survey-spec.md](./backpressure-survey-spec.md)
**Status**: READY

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No `[NEEDS CLARIFICATION]` markers in spec |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` |
| G4 | ADR Compliance | N/A | No accepted ADRs (`docs/adr/` has README only) |
| G5 | Structure | PASS | All required sections present + populated |
| G6 | Testing Alignment | PASS | Lightweight strategy; T005 is the validation task; criteria measurable; mocks avoided per spec |
| G7 | Domain Completeness | PASS | No formal domain registry; informal skill-file mapping complete in Domain Manifest |

## Summary

Add `plan-2d-backpressure-survey`, an advisory SDD-pipeline skill that runs after the spec and before the architect. It surveys whether planned work is provable by **deterministic backpressure** (build/type/test/lint/smoke/boot/architecture checks, CodeQL/Roslyn/dep-rules/data-scripts) vs agent inference, writes a `backpressure-coverage.md` artifact (inventory + coverage matrix + qualitative certainty + conditional Recommended Phase 0), and `plan-3` consumes that artifact to bake in a real "Phase 0: Establish Backpressure" when gaps exist. It is the computational-control counterpart to `plan-7` (the inferential tier, unchanged). Pure markdown: one new SKILL.md + two small consumer edits + docs.

## Target Domains

> No formal `docs/domains/` registry exists — the skills are the product. Informal skill-file mapping below.

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| `skills/SDD/` pipeline | existing | **create** | New `plan-2d-backpressure-survey/SKILL.md` |
| `plan-1b-v3-specify-and-clarify` | existing | **modify** | "Next steps" suggestion → plan-2d |
| `plan-3-v3-architect` | existing | **modify** | Sibling artifact read → bake Phase 0 |
| Docs (catalog + pipeline ref) | existing | **modify** | README_AGENTS.md + docs/skills-pipeline/README.md |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/plan-2d-backpressure-survey/SKILL.md` | SDD pipeline | contract | The new skill (public surface shipped via npx skills) |
| `skills/SDD/plan-1b-v3-specify-and-clarify/SKILL.md` | SDD pipeline | internal | Add next-step suggestion only |
| `skills/SDD/plan-3-v3-architect/SKILL.md` | SDD pipeline | internal | Add "if present" artifact read + Phase-0 bake |
| `README_AGENTS.md` | Docs | internal | Catalog entry |
| `docs/skills-pipeline/README.md` | Docs | internal | Pipeline-ordering mention |

Classification: `contract` (public interface), `internal` (domain-internal), `cross-domain` (editing another domain's files)

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Best-effort constraint: the harness/compound family forbids numeric thresholds, compliance floors, and blocking gates (user memory + plan-024). | SKILL.md states the advisory invariant explicitly; certainty stays qualitative (Strong/Partial/Weak); never flips plan to DRAFT. |
| 02 | High | `plan-3` already reads sibling artifacts in PHASE 2 (research-dossier, workshops, lines 87/92) and already has a Phase-0 conditional in PHASE 3 § Phase Design Principles (line 231) — but that conditional is **harness-specific** ("Build Agent Harness"), not generic. | T003 has **two touchpoints, both additive following existing patterns**: (a) PHASE 2 § Check for Existing Research — add an "if `backpressure-coverage.md` present" sibling read; (b) PHASE 3 § Phase Design Principles — add a **parallel** "Phase 0: Establish Backpressure" conditional next to the harness one. No new gate, no G-series change. Not a refactor, but not a single paragraph either — scope both edits. |
| 03 | High | Risk of overlap with plan-3 G6 (Testing Alignment) and plan-7 (review). | SKILL.md carries a short "How this differs" note: G6 checks test-tasks-exist + measurable criteria; plan-7 is the inferential tier; plan-2d surveys deterministic-sensor coverage of *experienced failure modes* (Principle #33). |
| 04 | Med | Opt-out + graceful degradation conventions already exist in sibling skills. | Mirror the `docs/compound/.disabled` sentinel check from `skills/harness/harness-2-observe/SKILL.md`; when no `engineering-harness.md`/justfile exists in the target repo, inventory reports "no sensors found" and certainty trends Weak. |
| 05 | Med | Slug uniqueness is enforced at install time (`npx skills` flattens by slug). | T005 runs `scripts/check-skill-slugs.sh`; `plan-2d-backpressure-survey` must not collide. |

## Implementation

**Objective**: Author the new advisory skill and wire it into the pipeline + docs, keeping it strictly best-effort.
**Testing Approach**: Lightweight — slug-collision check + frontmatter validation + a smoke run against a real existing spec + a plan-3 round-trip check (T005). No unit tests (prose skill). Mocks avoided (real `docs/plans/` spec as fixture).

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Author the new skill SKILL.md: frontmatter (`name: plan-2d-backpressure-survey`); body with the 4-step routine (inventory → derive failure modes → coverage matrix → advisory verdict); the `backpressure-coverage.md` output template (Inventory / Coverage Matrix with EXISTS·BUILDABLE·ABSENT × computational·inferential·human-judgement / qualitative Certainty + rationale / conditional Recommended Phase 0); **operational (non-numeric) definitions of the three certainty tiers** — Strong = every behaviour+architecture criterion has an EXISTS sensor; Partial = gaps are BUILDABLE; Weak = material behaviour/architecture criteria are ABSENT or no sensors found; the advisory invariant block (never blocks, no thresholds, no index file); the `docs/compound/.disabled` opt-out check; and a "How this differs from G6 / plan-7" note. | SDD pipeline | `/Users/jordanknight/github/tools/skills/SDD/plan-2d-backpressure-survey/SKILL.md` | File exists; frontmatter valid; all routine steps + artifact template + certainty definitions + invariants present (AC-1,2,3). Artifact output path is specified as `${PLAN_DIR}/backpressure-coverage.md` (sibling to research-dossier.md). **Recommended Phase 0 trigger** stated qualitatively: include the table when ≥1 behaviour/architecture criterion is BUILDABLE or ABSENT with no EXISTS sensor; omit it when all such criteria are EXISTS or only inferential/human-judgement/testing-doc gaps remain (this is a routing trigger, NOT a quality threshold). | Mirror opt-out wording from `skills/harness/harness-2-observe/SKILL.md`. Ground language in harness-foundations Rule 3 / Principle 16,33 / Pattern 18. |
| [x] | T002 | Wire `plan-1b`: add a "Next steps" line suggesting `/plan-2d-backpressure-survey` before `/plan-3` (sits beside the existing workshop suggestion). | SDD pipeline | `/Users/jordanknight/github/tools/skills/SDD/plan-1b-v3-specify-and-clarify/SKILL.md` | Next-steps block names plan-2d (AC-4). | Additive only; do not change question flow. |
| [x] | T003 | Wire `plan-3` at **two touchpoints** (finding 02): (a) PHASE 2 § Check for Existing Research (near line 87) — add an "if `${PLAN_DIR}/backpressure-coverage.md` present" sibling read alongside research-dossier/workshops; (b) PHASE 3 § Phase Design Principles (near line 231) — add a **parallel** conditional: "if the artifact recommends a Phase 0 → include 'Phase 0: Establish Backpressure' as an **optional, user-decided** candidate" next to the existing harness Phase-0 rule. Absence of the artifact = no-op (no error, no gate). | SDD pipeline | `/Users/jordanknight/github/tools/skills/SDD/plan-3-v3-architect/SKILL.md` | plan-3 reads the artifact from `${PLAN_DIR}` when present and emits a "Phase 0: Establish Backpressure" entry when it recommends one; when the artifact is absent the generated plan is structurally identical to today (no Phase 0, no error, no gate) (AC-5). | Phrase strictly "if present" and "optional recommendation, user-decided" — NOT "authoritative"/"required". Add NO new gate (G-series untouched). |
| [x] | T004 | Docs: add catalog entry to `README_AGENTS.md` and a one-line ordering mention to `docs/skills-pipeline/README.md`. | Docs | `/Users/jordanknight/github/tools/README_AGENTS.md`, `/Users/jordanknight/github/tools/docs/skills-pipeline/README.md` | Both list `plan-2d-backpressure-survey` in pipeline order (AC-8). | Match existing catalog row/format. |
| [x] | T005 | Validate: run `scripts/check-skill-slugs.sh` (exit 0); validate frontmatter; **two smoke scenarios** — (1) a real spec in a context WITH deterministic sensors (this repo has `justfile` + `check-skill-slugs.sh`) → artifact emits Strong/Partial certainty with EXISTS rows; (2) a context WITHOUT `engineering-harness.md`/sensors → artifact degrades gracefully to Weak certainty + a Recommended Phase 0. Then confirm the plan-3 round-trip emits a "Phase 0: Establish Backpressure" when recommended and produces a structurally identical plan when the artifact is absent. | SDD pipeline | `/Users/jordanknight/github/tools/scripts/check-skill-slugs.sh` | Slug check exits 0; both smoke scenarios produce well-formed artifacts with the expected certainty tier; round-trip behaves per AC-5 (AC-6,7). | This is the Lightweight validation task (G6). |

### Acceptance Criteria

- [ ] AC-1: `skills/SDD/plan-2d-backpressure-survey/SKILL.md` exists with valid frontmatter + 4-step routine.
- [ ] AC-2: Artifact spec emits Inventory + Coverage Matrix (EXISTS/BUILDABLE/ABSENT × computational/inferential/human-judgement) + qualitative Certainty (Strong/Partial/Weak) + rationale + conditional Recommended Phase 0 (only on material behaviour/architecture gaps).
- [ ] AC-3: Body states the advisory invariant — never blocks, never flips plan to DRAFT, no numeric threshold, no persisted index. Honours `.disabled` with explicit behaviour: when `docs/compound/.disabled` exists, the skill **silently exits without creating or modifying `backpressure-coverage.md`** (no log, no prompt, no error — mirroring `harness-2-observe`).
- [ ] AC-4: `plan-1b` next-steps suggests plan-2d before plan-3.
- [ ] AC-5: `plan-3` consumes the artifact at `${PLAN_DIR}/backpressure-coverage.md` when present and emits a `Phase 0: Establish Backpressure` entry iff the artifact recommends one (as an optional, user-decided candidate); when the artifact is absent the generated plan is byte-structurally identical to today's output (no Phase 0 entry, no error, no gate, no Status change).
- [ ] AC-6: `scripts/check-skill-slugs.sh` exits 0 with the new skill present.
- [ ] AC-7: Smoke run against a real spec produces a well-formed artifact; plan-3 round-trip behaves per AC-5.
- [ ] AC-8: Catalog (README_AGENTS.md) + pipeline reference (docs/skills-pipeline/README.md) list the skill.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Skill drifts toward a blocking gate over time | Low | High | Advisory invariant stated as a first-class block in SKILL.md (AC-3); mirror compound best-effort wording. |
| Overlap/confusion with plan-3 G6 / plan-7 | Med | Med | "How this differs" note in SKILL.md (finding 03). |
| plan-3 edit makes artifact mandatory | Low | Med | Phrase "if present"; AC-5 requires absence to be a no-op. |
| Certainty rating misread as a score/SLA | Med | Low | Qualitative only (Strong/Partial/Weak) + rationale; no numbers. |
| Target repo lacks engineering-harness.md / justfile | Med | Low | Graceful degradation: inventory reports "no sensors"; certainty Weak + Phase 0 recommended (finding 04). |

---

## Validation Record (2026-05-29)

### Validation Thesis

**Raison d'être**: Nothing in the SDD pipeline asks, at design time, whether planned work can be *proven by deterministic backpressure* vs inference/eyeballing; this plan builds the skill that asks it.

**Value claim**: Missing deterministic backpressure is detected and planned-for (as an optional Phase 0) before code is written — not discovered late in review.

**Artifact promise**: The implementer can build a strictly-advisory skill (never blocks, no thresholds, no index, honours `.disabled`) + two no-op-on-absence consumer edits.

**Intended beneficiaries**: Future planning agents + the human, via early visibility of provability gaps.

**Proof target**: Implementation (Simple-mode plan → plan-6 builds directly).

**Evidence standard**: Existing insertion points verified in plan-3/plan-1b; measurable Done-When per task; two-scenario smoke run.

**Thesis source**: `backpressure-survey-spec.md` + harness-foundations (Rule 3, Principle 16/33, Pattern 18).

**Thesis verdict**: Advanced.

**Main thesis risk**: Skill drifts toward a blocking gate over time — mitigated by the stated advisory invariant (AC-3), the "optional, user-decided" plan-3 wording (T003), and qualitative-only certainty.

---

| Agent | Lenses Covered | Thesis Axes Covered | Issues | Verdict |
|-------|---------------|---------------------|--------|---------|
| Coherence + Completeness | Coherence, Completeness, Proof-Level Fit, Hidden Assumptions, CS-challenge | Implementation Readiness, Evidence Sufficiency | 2 CRITICAL (downgraded to precision fixes), 2 HIGH, 5 MED/LOW — all fixed or accepted | ⚠️ → ✅ |
| Thesis Alignment | Thesis Alignment, Evidence Sufficiency, Proof-Level Fit | Thesis Alignment, Best-effort invariant | 3 MED/LOW — fixed | ✅ |
| Forward-Compatibility | Forward-Compatibility, Contract Integrity, Lifecycle Ownership | Downstream Usefulness | 0 (all insertion points verified to exist) | ✅ |

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| plan-6 implementer | 5 tasks buildable, paths exist, measurable Done-When | encapsulation lockout / test boundary | ✅ | All paths verified; ACs measurable (grep/exit-code/smoke) |
| plan-3-v3-architect | real insertion point + reusable Phase-0 pattern | contract drift | ✅ (with fix) | PHASE 2 read at :87; Phase-0 conditional at :231 — harness-specific, so T003 adds a *parallel* case (plan now states both touchpoints) |
| plan-3-v3-architect | artifact optional; absence no-ops, no gate | lifecycle ownership | ✅ | "if present" pattern proven (:87–95); AC-5 hardened to require identical output on absence |
| plan-1b-v3 | "Next steps" target exists, flow undisturbed | contract drift | ✅ | "Next steps:" block at :255; T002 additive-only |

**Thesis alignment**: Value claim advanced at Implementation proof level; main risk (gate-drift) is mitigated in the SKILL.md invariant + the "optional/user-decided" plan-3 wording.

**Outcome alignment**: The plan advances the VPO Outcome — "surveys whether the planned work can be proven by deterministic backpressure … rather than by agent inference or human eyeballing" — by creating the survey skill, wiring it advisorily into plan-1b/plan-3, and keeping it best-effort throughout.

**Standalone?**: No — downstream consumers (plan-6, plan-3, plan-1b) exist and were validated.

Overall: VALIDATED WITH FIXES
