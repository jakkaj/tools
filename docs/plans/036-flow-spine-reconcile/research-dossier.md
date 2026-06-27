# Research Dossier: a reconcile/sync maintenance verb for the-flow's flight-plan spine

**Generated**: 2026-06-27T05:48:00Z
**Query**: "How does the-flow build & maintain the flight-plan spine today, where does it fall short of declarative completeness (all past/present/future phases + workshops + harness chores), and what is the right shape for a reconcile/sync maintenance verb?"
**Effort**: Standard (lead-only; deep context gathered earlier this session)
**Tools**: Standard
**Evidence**: 6 current sources · 1 live artifact (cross-repo drift example)

## Answer

1. The flight plan is built **reactively and incrementally** on the happy path, never **reconciled declaratively**. Phases are revealed **once**, "at the `plan` pass" (`00-routing.md` CLI cadence step 2); nothing re-asserts completeness on later entries.
2. This silently leaves the spine partial whenever the `plan` pass didn't run or the roster changed afterward: **ADOPT** entry (back-fills only the inferred furthest-progressed node, not the full roster), a **plan edited after** the pass, a **direct-jump-built** plan (no engine, no nodes), or a **harness installed mid-flow**.
3. Harness seam nodes are emitted **at the edge you're on** (`harness-seams.md` seam map: "before each phase" / "each phase end"), not **pre-anchored across all known phases**, so future phases' retro-drain / boot beats aren't visible up front.
4. The CLI already exposes every primitive a reconcile needs (`insert-node --after/--branch-of`, `set-node`, `nav`, `chores`, `status`, `render`); reconcile is therefore a **diff-then-backfill** routine, naturally **idempotent** (a complete spine → no-op).
5. **Name collision**: `reconcile` is already a taken verb — Registry id **`8c reconcile`** (the divergent-base merge excursion, `80-merge.md`). A new maintenance verb named `reconcile` would collide; **`sync`** avoids it.
6. Ownership must be respected: `eng-harness-flow` **owns the chore flag** (dedup on the `--hook` token). The new verb may emit the-flow's own **seam nodes** but must **not** mint chore twins (`harness-seams.md` § Chore-flag ownership).
7. A live artifact proves the failure is real: the osk flight plan (hand-reconciled) drifted — missing `hboot-phase-0`, `hretro-phase-3`, a `backpressure` node and a ship `harness-retro`, plus four standalone `chore` twins instead of flagged seam nodes. Encoding the contract once fixes this; hand-prompting does not.

## Evidence

| ID | Finding | Evidence | Planning implication | Confidence |
|----|---------|----------|----------------------|------------|
| F-01 | Phases revealed only "at the `plan` pass" via `insert-node --after`; no recurring completeness check | `00-routing.md` § Flight plan, CLI-driven cadence step 2 | Reconcile must run on **every** entry, not once | High |
| F-02 | ADOPT back-fills only inferred nodes (furthest-progressed), not the full phase roster | `coach.md` § Adoption contract (artifact→stage table) | Adopt-then-reconcile closes the biggest gap | High |
| F-03 | Harness seam nodes emitted at the current edge, not pre-anchored across all phases | `harness-seams.md` § The seam map; § Node emission | Reconcile should pre-anchor boot/retro for all known phases (when installed+provisioned) | High |
| F-04 | `eng-harness-flow` owns the chore flag; dedups on the `--hook` token; flags existing seam nodes rather than adding twins | `harness-seams.md` § Chore-flag ownership (R-1) | Reconcile emits **seam nodes only**; never chore twins | High |
| F-05 | CLI primitives suffice: `insert-node --after/--branch-of`, `set-node`, `nav`, `chores`, `status`, `render` | `harness flow --help`; `flight-plan-ops.md` §3 cheat-sheet | No CLI change needed; reconcile is pure orchestration | High |
| F-06 | `set-node` **cannot** re-parent (`--next`/`--branch-of`); validator rejects forward `--next` refs | `flight-plan-ops.md` §6 Gotchas | Reconcile inserts via `--after`/`--branch-of` (splice-safe); never rewires existing nodes | High |
| F-07 | `reconcile` is already Registry id `8c reconcile` (merge excursion); typed `merge` aliases to it | `SKILL.md` Registry + alias table | New verb should be **`sync`** (or accept the collision risk) | High |
| F-08 | Hand-reconciled osk flight plan drifted from the canonical shape (missing nodes; chore twins) | `/Users/jordanknight/osk/osk-split-billing/docs/plans/001-shopify-eng-environment/the-flow.json` | Use as the fixture; encode the canonical target shape | High |

## Historical Evidence

| ID | Prior friction / decision | Source | Applicability now | Implication |
|----|---------------------------|--------|-------------------|-------------|
| H-01 | Flow-architecture pattern: Registry+Graph single masters; sub-skills are flow- **and** harness-blind verbs | `00-routing.md` §5; `harness-seams.md` (the inversion) | Direct | Reconcile lives in the **engine** (00-routing.md), never in a sub-skill |
| H-02 | KISS / no persisted derived state — recompute cross-cutting views at read time | `MEMORY.md` (feedback_kiss_information_over_ceremony); `00-routing.md` § State contract | Direct | Reconcile keeps **no new state**; recomputes target shape from the plan artifact each entry |
| H-03 | Harness is best-effort — no gates/scores/blocks | `SKILL.md` invariant #4; `harness-seams.md` § Honored, not forced | Direct | Reconcile is advisory; a complete spine is a silent no-op |
| H-04 | Plan 033 made seams flow-owned + added `due_chores` "due here" beat | `harness-seams.md` § Chore-flag ownership | Direct | Reconcile's harness half pre-anchors nodes the `due_chores` beat then surfaces |

## Risks and Unknowns

| Item | Evidence | Why it matters | Resolution / next evidence |
|------|----------|----------------|----------------------------|
| Verb-name collision | F-07 | `reconcile` already names 8c | **Decide: `sync` (recommended) vs `reconcile`** — held question |
| Auto-fire every entry could feel noisy | F-01, H-03 | A non-idempotent reconcile would churn the JSON each turn | Must be diff→backfill; no writes when complete; emit nothing when nothing changed |
| Ownership overreach | F-04 | Writing chore flags would violate eng-harness-flow's R-1 ownership | Emit seam **nodes** only; leave the chore flag to the router |
| Direct-jump is engine-less by design | `SKILL.md` § Two load paths | A `sync` verb is special — it's an engine/maintenance verb, not a stage | Allow explicit `/the-flow sync` to run the reconcile routine even from a direct invocation (documented exception) |

## Planning Handoff

- **Preserve**: the flow-architecture pattern (Registry/Graph masters; sub-skills harness-blind); CLI-only writes (invariant #6); `eng-harness-flow`'s chore-flag ownership; best-effort/no-gate (#4); no new state (KISS).
- **Change carefully**: `00-routing.md` (add the reconcile routine + its every-entry trigger in the cadence/entry paths) and `SKILL.md` (Registry row + a Hard-invariant line). These are the core spine files — another agent has edited them recently; pull latest and lint with `just check-flow`.
- **Likely files/symbols**: `skills/SDD/the-flow/SKILL.md` (Registry + invariant + grammar), `references/00-routing.md` (reconcile step + entry trigger + Graph note), `references/harness-seams.md` (cross-ref for the seam-node half), `references/getting-started.md` (regenerate the rendered view), `CLAUDE.md` (standing requirement — **already added**).
- **Decisions still required**: (1) **verb name** — `sync` vs `reconcile` (collision pushes to `sync`); (2) whether the engine auto-fires it as a *literal verb invocation* or an *inlined engine routine the verb also exposes* (recommend: one routine, exposed as the verb, auto-called by the engine).

## External Research
_None material — this is fully answerable from repo evidence + the live artifact._
