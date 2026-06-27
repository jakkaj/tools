# Flow Spine Reconcile — a first-class `sync` maintenance verb
**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-06-27
**Status**: READY
**Spec source**: unified (this file)

## Business Specification

### Research Context
📚 Incorporates findings from `research-dossier.md`. Key drivers: the spine is built **reactively** (phases revealed once "at the `plan` pass"), never **reconciled declaratively** on entry (F-01); ADOPT/edit/direct-jump/mid-flow-harness all leave it partial (F-02/F-03); the CLI already has every primitive (F-05); `reconcile` is a taken verb name — `8c reconcile` (F-07); `eng-harness-flow` owns the chore flag (F-04); a live osk flight plan proves the drift (F-08).

### Summary
Today `/the-flow` only completes the flight plan (`the-flow.json` → `the-flow.md`) if the guided engine walks the happy path from the start. Anyone resuming an adopted, edited, or direct-jump-built plan — or a plan whose harness was installed mid-flow — gets a partial spine and has to hand-prompt "represent all phases/chores." This adds a **first-class maintenance verb** (working name **`sync`**) that the engine **auto-fires on every entry** and anyone can invoke directly, which **diffs the plan's full roster (all past/present/future phases + workshops) and the harness hook map against the flight plan, and backfills what's missing** — idempotent, advisory, CLI-driven, no new state.

### Goals
- The flight plan is **always complete on entry** — every past/present/future phase + workshop is a node — **without the user prompting**.
- All harness seam nodes (boot/backpressure/retro/harvest) are **pre-anchored across known phases** when the router is installed + the repo provisioned, respecting `eng-harness-flow`'s chore-flag ownership.
- A **stable call-target** (`/the-flow sync`) replaces the freeform English plea, and gives direct-jump users a one-shot repair.

### Non-Goals
- **No** change to the `harness flow` CLI (it already has every primitive).
- **No** new state file (KISS — recompute the target shape from the plan artifact at read time).
- **No** gating/scoring/blocking; reconcile never advances `nav` or runs a stage.
- **No** change to the sub-skills (they stay flow- and harness-blind).
- **Not** taking over `eng-harness-flow`'s chore flag — the-flow emits seam *nodes*; the router owns the *flag*.

### Target Domains

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| the-flow (SDD skill) | existing | **modify** | Add the `sync` verb + the engine reconcile routine |

> This repo has **no `docs/domains/` registry** — the "domain" is the `skills/SDD/the-flow` skill itself. Domain gates degrade to N/A accordingly.

### Testing Strategy
**Approach**: Lightweight (default). **Rationale**: the deliverable is skill markdown (no runtime code); correctness is proven by the deterministic flow-architecture linter + a dry-read trace. **Focus**: `just check-flow` L1–L6 stays clean; `/the-flow sync` resolves; the engine's every-entry trigger is present and idempotent. **Excluded**: unit tests (no code). **Mock usage**: targeted/none — N/A.

### Documentation Strategy
**Location**: none new — the skill reference files (`SKILL.md`, `00-routing.md`, `harness-seams.md`, `getting-started.md`) **are** the documentation; `CLAUDE.md`'s standing requirement is already recorded. **Rationale**: the change is internal to the skill.

### Complexity
- **Score**: CS-2 (small)
- **Breakdown**: S=1, I=1, D=0, N=1, F=1, T=0
- **Confidence**: 0.80
- **Assumptions**: the flow-architecture pattern + CLI contract are stable; another agent's recent edits to `00-routing.md`/`harness-seams.md` are compatible (pull latest before editing).
- **Dependencies**: capable `harness flow` CLI (present, 0.6.0); `eng-harness-flow` chore-flag contract (R-1).
- **Risks**: name collision (mitigated → `sync`); ownership overreach (mitigated → nodes not flags); concurrent edits to spine files.
- **Phases**: 1 (Simple).

### Acceptance Criteria
1. **AC-01** — A first-class maintenance verb exists in the Registry, resolvable as `/the-flow sync` (and via the engine), distinct from `8c reconcile`.
2. **AC-02** — The guided engine **auto-fires** reconcile on every entry (resume + adopt); it is idempotent (a complete spine produces **no** CLI writes).
3. **AC-03** — Reconcile backfills **all past/present/future** phases + workshops as nodes by diffing the plan's `### Phase Index` / `workshops/*.md` against `the-flow.json`.
4. **AC-04** — When the router is installed + repo provisioned, reconcile pre-anchors harness seam nodes (boot per phase, retro per phase, backpressure off plan, retro off ship) for all known phases, **respecting chore-flag ownership** (no chore twins; dedup on the `--hook` token).
5. **AC-05** — Best-effort: never gates/blocks/advances `nav`; all writes via `harness flow`; **no new state file**.
6. **AC-06** — `just check-flow` (L1–L6) passes; sub-skills remain harness-blind.

### Risks & Assumptions
- **Concurrent edits** to `00-routing.md`/`harness-seams.md` (another agent) — pull latest + `just check-flow` before and after.
- **Auto-fire churn** if reconcile isn't truly idempotent — the routine must be diff→backfill and write nothing when the spine is already complete.

### Open Questions
- **Verb name**: **RESOLVED 2026-06-27 → `sync`** (user-confirmed; avoids the `8c reconcile` collision).

### Workshop Opportunities
_None — the design is settled by the dossier; the only open item is the verb name (a naming decision, not a design workshop)._

### Clarifications
#### Session 2026-06-27
- **Mode**: Simple (`--simple` flag). **Testing**: Lightweight (default). **Mock**: targeted/none (default). **Docs**: none new (default — skill files are the deliverable). All defaulted per the run instruction ("default others"); no interactive questions asked.

## Planning Seam
_Refinement opportunities still open — recorded as evidence; the flow surfaces and offers these, none gate:_
- Open Workshop Opportunities: none — all resolved (verb name is a held naming decision, not a workshop).

| Artifact | Present? | Effect on the plan |
|----------|----------|--------------------|
| research-dossier.md | y | informs Key Findings + the whole design |
| workshops/*.md | n | — |

## Implementation Plan

### Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No critical markers; verb-name is a non-blocking Open Question (default `sync`) |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` (flow-architecture pattern honored in tasks) |
| G4 | ADR Compliance | N/A | No applicable accepted ADRs |
| G5 | Structure | PASS | All required sections present |
| G6 | Testing Alignment | PASS | Lightweight: linter + dry-read validation task (T005) present |
| G7 | Domain Completeness | PASS | No domain registry; single target present; manifest covers all touched files |

### Summary
One Simple phase edits four the-flow skill files to add a `sync` maintenance verb and an engine reconcile routine that runs on every entry. Reconcile diffs the plan roster + workshops + harness hook map against `the-flow.json` and backfills via `harness flow insert-node`, idempotently and best-effort, leaving `eng-harness-flow`'s chore-flag ownership intact. Validation is the deterministic `just check-flow` linter plus a resolution dry-read.

### Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/the-flow/SKILL.md` | the-flow | contract | Registry row + grammar + Hard-invariant for the new verb |
| `skills/SDD/the-flow/references/00-routing.md` | the-flow | internal | The reconcile routine + its every-entry trigger (entry paths + cadence) |
| `skills/SDD/the-flow/references/harness-seams.md` | the-flow | internal | Cross-ref: reconcile pre-anchors seam nodes; ownership split |
| `skills/SDD/the-flow/references/getting-started.md` | the-flow | internal | Regenerate the rendered view to mention `sync` (banner-marked) |

### Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Phases revealed once at the plan pass; no recurring completeness check (F-01) | Add a per-entry reconcile routine in `00-routing.md` |
| 02 | High | ADOPT back-fills only the inferred node, not the full roster (F-02) | Reconcile runs on adopt too; diff the full Phase Index |
| 03 | High | `reconcile` already names `8c` (F-07) | Name the verb **`sync`** |
| 04 | High | `eng-harness-flow` owns the chore flag; dedup on `--hook` (F-04) | Emit seam **nodes** only; never chore twins |
| 05 | Medium | `set-node` can't re-parent; forward `--next` refs rejected (F-06) | Backfill via `insert-node --after/--branch-of` only |

### Implementation

**Objective**: Add a first-class `sync` maintenance verb + engine reconcile routine that keeps the flight-plan spine declaratively complete on every entry.
**Testing Approach**: Lightweight — `just check-flow` (L1–L6) + a resolution/idempotency dry-read.

#### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Add the `sync` verb to the Registry (maintenance/utility verb — no ordinal stage id; engine-fired + directly invokable) + grammar note + a Hard-invariant line ("the engine reconciles the spine to current knowledge on every entry; idempotent, advisory, never gates"). Note its distinctness from `8c reconcile`. | the-flow | `skills/SDD/the-flow/SKILL.md` | Registry/grammar carry `sync`; invariant #11 present; `just check-flow` clean | Per finding 03 |
| [x] | T002 | Add the **Reconcile the spine** routine to `00-routing.md`: diff the plan's `### Phase Index` + `workshops/*.md` against `the-flow.json` nodes; backfill missing phase/workshop nodes via `insert-node --after/--branch-of`; idempotent (no writes when complete); CLI-only; never advances `nav`. Wire its trigger into the **entry paths** (resume + adopt) and the per-entry cadence. | the-flow | `skills/SDD/the-flow/references/00-routing.md` | Routine + Resume trigger + cadence cross-ref present; idempotency + no-gate stated; `just check-flow` clean | Per findings 01, 02, 05 |
| [x] | T003 | Add the harness half: a cross-ref + rule in `harness-seams.md` that reconcile **pre-anchors seam nodes** (boot/retro per known phase, backpressure off plan, retro off ship) when installed+provisioned, emitting **nodes only** and leaving the chore **flag** to `eng-harness-flow` (dedup on `--hook`; no twins). | the-flow | `skills/SDD/the-flow/references/harness-seams.md` | Cross-ref present; ownership split explicit; dedup rule stated | Per finding 04 |
| [x] | T004 | Regenerate the `getting-started.md` rendered view so it mentions `sync` (banner-marked regeneration only — never hand-edit). | the-flow | `skills/SDD/the-flow/references/getting-started.md` | View carries `sync` (stage table + quick ref); banner intact | — |
| [x] | T005 | Validate: `just check-flow` (L1–L6) clean; dry-read trace that `/the-flow sync` resolves via the Registry, the engine auto-fires reconcile on entry, and a complete spine is a no-op. | the-flow | (repo) | check-flow exits 0 (0 warnings, 11 Registry rows); resolution + idempotency traced in execution log | Lightweight validation task |

### Acceptance Coverage Map

| AC | Covered by | Verified in |
|----|-----------|-------------|
| AC-01 | T001 | Registry resolution dry-read (T005) |
| AC-02 | T002 | Entry-trigger + idempotency trace (T005) |
| AC-03 | T002 | Routine diff/backfill spec (T002) |
| AC-04 | T003 | Ownership/dedup rule (T003) |
| AC-05 | T001, T002 | no-gate/no-state review (T005) |
| AC-06 | T005 | `just check-flow` |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Concurrent edits to spine files by another agent | Medium | Medium | Pull latest + `just check-flow` before/after; small, additive edits |
| Reconcile not truly idempotent → churns JSON each entry | Low | Medium | Diff→backfill; write nothing when complete; T005 idempotency trace |
| Ownership overreach into chore flag | Low | High | Emit seam nodes only; T003 makes the split explicit |
