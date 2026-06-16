# Unified Planning Document — consolidate `specify` + `architect` into one step

**Mode**: Simple
**Spec**: docs/plans/032-unified-planning-doc/unified-planning-doc-spec.md
**Created**: 2026-06-16
ℹ️ No `research-dossier.md` — the design is grounded in the review of `scratch/paste/20260616T040625.md` (external refactor brief) and a fresh read of the live flow (`SKILL.md`, `00-routing.md`, `coach.md`, `flow-architecture.md`, the lint).

## Summary

Today the SDD planning work is split across two stages and two artifacts: `1b specify` writes the business-facing `<slug>-spec.md`, then `3 architect` reads it and writes the technical `<slug>-plan.md`. For the common case (Simple mode, no provisioned harness) the seam between them is empty ceremony — two commands, two files, two narration turns for one continuous "what + how" thought.

This feature **collapses the two planning stages into one step that produces one canonical document**: `<slug>-plan.md` with a **Business Specification** on top and an **Implementation Plan** below. The merged stage keeps *everything* that made the two stages valuable — the full front-loaded question set, the optional workshop/backpressure seam, the G1–G7 gates, validate-v2, Simple/Full mode — but presents it as a single document that matures from business contract to implementation plan, narrated as one stage.

The change is **on-pattern**: the merged stage stays a flow-blind sub-skill, the Registry collapses to one planning row, routing stays deterministic, and `just check-flow` stays green. It deliberately rejects the source brief's heavier ideas (fuzzy section-scanning for routing, an external-router stub file, and a migration system for historical plans).

## Goals

- **One step, one document.** A new flow run produces exactly one planning artifact (`<slug>-plan.md`) and reaches it through a single planning verb — no separate `<slug>-spec.md`.
- **Lose no fidelity.** The merged stage still front-loads the complete question set (Workflow Mode incl. Simple/Full, Testing, Mock, Documentation) and the conditional Round-2 (Domain Review, topic clarifications); still runs the G1–G7 gates; still auto-runs validate-v2.
- **Keep the seam, but only when it's live.** Workshop and post-spec backpressure stay reachable as **post-plan refinements** (run one, then re-run `plan` to fold it in); a Simple-mode, no-harness run gets no offer and goes straight to implement.
- **Stay deterministic and lint-clean.** Routing/resume distinguishes the two halves via a single exact section marker plus durable state — never fuzzy prose-scanning. The sub-skill stays flow-blind; `just check-flow` and the slug check both pass.
- **Reduce, don't relocate, ceremony.** The win is fewer steps and one document to read — not a migration system or new tooling.

## Non-Goals

- **Not** touching `explore`, `tasks`, `implement`, `progress` beyond the `--plan` path they already accept. *(Note: `workshop`, `review`, `merge`, and `adr` currently read `<slug>-spec.md` by path and DO get a minimal spec-source update — see AC-07. That much is in scope; a wholesale rewrite of those stages is not.)*
- **Not** splitting the merged stage into depth-2 sub-files (`references/stages/plan/*.md`). It stays **one flow-blind sub-skill module** so the lint (`check-flow-architecture.sh`, which discovers sub-skills at `maxdepth 1`) keeps checking it for leakage + contract. Progressive disclosure inside the merged module uses the sanctioned § Shared-conventions lazy-pull, not a sub-tree the lint can't see.
- **Not** migrating historical `docs/plans/0NN-*` split spec+plan folders to the unified format — they stay byte-untouched and remain adoptable.
- **Not** changing the external `/eng-harness-flow` router (it lives in another repo); the post-spec seam simply targets the unified file's `## Business Specification` section.
- **Not** building a flight-plan validator, a new CLI, or any new tooling.
- **Superseded (user, 2026-06-16):** planning is now a **single atomic verb `plan`** that **always writes both halves** in one run (no `--implementation` flag, no business-only state). The earlier design kept a mid-stage pause "because workshop-before-phases is load-bearing"; that need is now met by **iteration instead of a pause** — run `plan`, and if the surfaced `## Workshop Opportunities` warrant it, run `2c workshop` / post-spec backpressure and **re-run `plan`** (which regenerates *both* halves with the decisions folded in). Still **not** building an uninterrupted no-questions run: `plan` still front-loads the full question set; what's removed is the second user-facing pass/flag, not the questions. **Accepted trade (named, not papered over):** with no mid-stage pause, a workshop *after* the first `plan` means re-running `plan` and discarding the first implementation half (including its validate-v2), and the workshop offer now lands *after* a finished plan rather than *before* phases exist — so the coach makes that offer **assertive** when ≥1 Workshop Opportunity is still unworkshopped (it names how many topics the phases were designed without). For the common Simple/no-harness case the seam is dormant and this cost never materialises.

## Target Domains

> This repo has **no `docs/domains/` registry** (it is a skills + dev-tooling repo). The single touched area is the `the-flow` skill itself; the spec/plan tables below are the whole context.

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| `the-flow` (skill: `skills/SDD/the-flow`) | existing | **modify** | Merge the two planning sub-skills + Registry/Graph/coach/getting-started; keep flow-blind + lint-clean |

## Testing Strategy

- **Approach**: **Manual** (user-directed). No runtime code changes — this is skill markdown + JSON templates.
- **Rationale**: the deterministic safety net already exists as lints; verification is running them and walking the flow by hand.
- **Verification steps** (executed manually):
  1. `just check-flow` → exit 0 (L1–L6 clean: no sub-skill leakage, contract blocks intact, grammar/closure hold).
  2. `scripts/check-skill-slugs.sh` → exit 0 (no slug collisions after the Registry change).
  3. Dry-read the merged planning sub-skill: confirm the full question set + G1–G7 gates + the auto-run of validate-v2 survive.
  4. Walk the routing by hand — **Simple**: fresh run → `plan` (writes both halves) → (post-plan refinement offered only if live) → implement; a `/compact`-resume re-prints the correct pending step.
  5. Walk the routing by hand — **Full**: confirm the implementation half reveals multiple phases (architect's job) and the rail re-scales; resume mid-build still works.
  6. Confirm a no-harness Simple run goes straight to implement (no refinement offer); confirm a run with flagged Workshop Opportunities is offered the post-plan refinement.
  7. `rg "<slug>-spec|SPEC_FILE|FEATURE_SPEC|awaiting-3|30-architect|plan-3-v3"` across `skills/SDD/the-flow/` — classify every hit as legacy-fallback (intended), business-section read, or obsolete-to-remove.
  8. Adoption check: point a fresh `/the-flow` at (a) a unified plan with only the business half and (b) a legacy split spec+plan folder — confirm each infers the right next step.
- **Excluded**: automated test framework, TDD.
- **Mock Usage**: **N/A** — no runtime code to mock; real skill files only.

## Documentation Strategy

- **Location**: **Update existing canonical docs** (no new files).
  - `docs/skills-pipeline/flow-architecture.md` — reflect one planning stage producing one document.
  - `CLAUDE.md` — the `the-flow` contributor section (stage list, Registry description).
  - `skills/SDD/the-flow/references/getting-started.md` — regenerated view (banner-marked; never hand-edited as primary).
- **Rationale**: the merge changes the canonical shape of the flow; the pattern doc and contributor guide must not drift from it.

## Complexity

- **Score**: CS-3 (medium) — borderline CS-4, driven by surface-area breadth rather than depth.
- **Breakdown**: S=2 (many files: 2 sub-skills + Registry + Graph + coach + getting-started + 2 docs), I=1 (downstream `--plan` consumers + routing predicate, all prose), D=1 (state + one-file routing marker), N=1 (the two-halves-one-file routing is the one novel bit), F=1 (lint + historical-plan back-compat), T=0 (manual, trivial rollout).
- **Confidence**: 0.70
- **Assumptions**: Simple mode is acceptable for a CS-3/4 change (explicit user choice — single phase, but a chunky one); the verb-naming/alias details are resolvable in the workshop + architect.
- **Dependencies**: the flow-architecture lint (`scripts/check-flow-architecture.sh`); deploy via `just install-skills-from-source`.
- **Risks**: see § Risks & Assumptions.
- **Phases**: 1 (Simple mode — one consolidation phase).

## Acceptance Criteria

1. **AC-01 — One artifact.** A fresh flow run produces exactly one planning file, `<slug>-plan.md`; no `<slug>-spec.md` is created. *(Observable: list the plan folder.)*
2. **AC-02 — One document, two halves in order.** `<slug>-plan.md` contains, in order: (a) a **top metadata block** carrying `Mode` and a **single `Status`** (READY | DRAFT — UNRESOLVED GAPS) — `plan` always writes both halves, so there is no "business ready, implementation not planned" intermediate to represent; (b) a `## Business Specification` section (Summary, Goals, Non-Goals, Workflow Mode, Acceptance Criteria, Target Domains, Testing/Documentation Strategy, Complexity, Risks, Open Questions, Workshop Opportunities, Clarifications); (c) a short `## Planning Seam` section recording the optional workshop/backpressure/clarify refinements + artifacts-considered, visible in-document; (d) a `## Implementation Plan` section (Gate Matrix, Domain Manifest, Key Findings, Phases/Tasks or Simple-mode tasks, **Acceptance Coverage Map** mapping tasks→AC-ids, Risks, Unresolved Gaps). *(Observable: the single `Status` field + the three section markers (`## Business Specification`, `## Planning Seam`, `## Implementation Plan`) present, in order.)*
3. **AC-03 — No question dropped.** The merged planning stage front-loads the complete question set — **Workflow Mode (Simple/Full)**, Testing Strategy, Mock Usage, Documentation Strategy — plus the conditional Round-2 (Domain Review, topic clarifications), exactly as the two stages do today, AND the architect's pre-generation gates G1–G7 + the auto-run of validate-v2 survive on the implementation half. *(Observable: the merged sub-skill contains the Round-1 + Round-2 question tables and the G1–G7 gate list; a dry walk confirms none is dropped vs today's `20-specify.md` + `30-architect.md`.)*
4. **AC-04 — Refinement seam only when live.** `plan` always writes both halves in one run (no mid-stage pause). *After* the plan, when the seam is live (flagged Workshop Opportunities with no workshop yet, or a provisioned harness) the coach **offers** an optional refinement — workshop / backpressure / compact, then re-run `plan` to fold it in; a Simple-mode run with no provisioned harness gets **no offer** and routes straight to implement. Never gates, never blocks. *(Observable: stage logic + a dry routing walk.)*
5. **AC-05 — Deterministic routing/resume.** The flow distinguishes "no plan yet" from "plan written" (and READY vs DRAFT) using **durable state (`.the-flow-state.json`) as the primary signal, backed by an exact section-marker check on disk** (`## Implementation Plan` present = plan written; `## Business Specification` present = unified vs legacy split; the single `Status` field for READY/DRAFT) — never fuzzy prose-scanning. The **exact marker string(s) and the state predicates are frozen in the routing workshop** (§ Workshop Opportunities), then encoded in the Graph. A `/compact`-resume re-prints the correct pending step without advancing. *(Observable: routing walk + state inspection; the Graph rows name the exact markers.)*
6. **AC-06 — Lint stays green.** After the change, `just check-flow` exits 0 (L1–L6) and `scripts/check-skill-slugs.sh` exits 0. *(Observable: run both.)*
7. **AC-07 — Downstream reads the unified file (with legacy fallback).** The verbs that today read `<slug>-spec.md` by path — `workshop` (`25-workshop.md`), `review` (`70-review.md`), `merge` (`80-merge.md`), `adr` (`35-adr.md`) — plus the AC/domain/testing readers `tasks` + `implement` get a **minimal spec-source update**: read the `## Business Specification` section of the unified `<slug>-plan.md` when present, and **fall back to a sibling `<slug>-spec.md`** when it isn't (legacy split folders). New flows need no separate spec file; the harness post-spec seam targets the unified file's business section. *(Observable: each named module resolves its business source from the plan with a documented legacy fallback; a dry read confirms no module hard-requires a separate spec file for a unified plan.)*
8. **AC-08 — No over-built migration.** Historical `docs/plans/0NN-*` split folders are left byte-untouched; adoption logic still recognizes both the legacy split shape and the new unified shape. No pointer-stub or auto-migration machinery is added. *(Observable: no diffs under old plan folders; adoption table covers both.)*
9. **AC-09 — Registry + docs reflect one stage.** The Registry has a single planning row (one verb → unified `<slug>-plan.md`); the retired `3 architect` resolves via the read-time alias table; getting-started, flow-architecture.md, and CLAUDE.md describe one planning stage. *(Observable: Registry diff, alias entry, doc updates.)*

## Risks & Assumptions

| # | Risk / Assumption | Mitigation |
|---|---|---|
| R1 | One-file routing marker misfires if a user hand-edits the document's headings | Use an exact-string section marker as the disk signal **plus** durable `.the-flow-state.json` as the primary; the marker is the resume fallback, not the only source of truth |
| R2 | External `/eng-harness-flow --event post-spec --spec` expects a spec-shaped file | The unified doc keeps a `## Business Specification` section the router can scope to; this repo is unprovisioned (seam noops) so the risk is latent, not active |
| R3 | Lint L1 leakage if the merged stage names a successor/“next step” | Keep the merged sub-skill flow-blind (no stage ids, no next-routing); routing lives only in the Graph |
| R4 | CS-3/4 work carried as a single Simple-mode phase could sprawl | Architect phase design keeps it to one well-scoped phase; escalate to Full only if the plan reveals genuine multi-phase structure |
| R5 | The merged sub-skill must decide whether to pause at the seam while staying flow-blind — a hybrid (intra-stage timing, flow-owned decision) the pattern doesn't cleanly cover | The routing workshop resolves placement per flow-architecture § Seam placement (Graph edge decoration vs declared `**Side effects**`); the sub-skill never names a stage or route |
| A1 | Simple mode is the user's deliberate choice despite borderline CS | Recorded; honored |
| A2 | Verb name / id / alias details are not yet fixed | Resolved in the routing workshop + architect (Registry) |
| A3 | The unified `## Business Specification` section's shape must satisfy what the external post-spec router expects from `--spec` | Latent here (repo unprovisioned → seam noops); the workshop confirms the section name/shape the router scopes to; if ever incompatible, feed the router the legacy spec section rather than forking the canonical doc |

## Open Questions

> **Both OQs are owned by the routing workshop** (§ Workshop Opportunities) — they are interdependent with the routing/seam design and must be resolved together, before the architect writes the Registry/Graph changes. **Resolved (2026-06-16):** workshop 001 froze them, then the user simplified to a single atomic `plan` verb — **OQ1**: verb = `plan` (id `1b`, no modes; `/the-flow 3 architect` aliases to `1b plan`); **OQ2**: moot — an atomic verb has no stale half, so there is no STALE marker.

- **OQ1 — Verb & id & direct-jump.** Keep id `1b` with verb `specify` (absorbing architect), or a new verb (e.g. `plan`)? How do `/the-flow 3 architect` and the retired `plan-3-v3-architect` slug alias at read time so direct-jump and old state files keep resolving? *(Lean: one planning row; the verb name is the workshop's call.)*
- **OQ2 — Clarify re-entry after the plan half.** When the business half is re-opened after the implementation half exists, how is the implementation half marked stale (candidate mechanisms: an `Implementation Status: STALE` header flag, a top-of-section banner, or a state-file flag) so downstream doesn't silently trust it?

## Workshop Opportunities

> **Superseded 2026-06-16** — this topic was workshopped (001), then simplified to an **atomic `plan` verb**: single `Status`, one `awaiting-1b` state, **no two maturity states / no STALE / no mid-stage pause**. The "two maturity states / Business-Implementation Status / stale-marking / pause" wording in the row below is the *original* topic statement, retained for history; see workshop 001 Decisions 2/3/4/6 (revised).

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Two-halves-one-file routing, the conditional seam, **and the Registry/alias surface** | State Machine | The load-bearing, interdependent design risk: one document must represent two maturity states, resume deterministically after `/compact`, pause at the seam *only when live*, and re-map the current two-stage Registry/Graph onto one stage without breaking direct-jump or adoption | **Routing/state**: How does the Graph key business-done vs implementation-done? What are the exact section markers + `Business/Implementation Status` predicates, and how does durable state back them? How do `awaiting-1b` / `awaiting-3` collapse or re-map? · **Seam**: Where does the pause live so the sub-skill stays flow-blind (Graph edge decoration vs in-procedure `**Side effects**`, per flow-architecture § Seam placement)? How does a Simple/no-harness run flow straight through? · **Registry/alias (OQ1)**: keep id `1b` with which verb, or a new verb (`plan`)? How do `/the-flow 3 architect` + the retired `plan-3-v3-architect` slug alias at read time? · **Adoption**: the artifact→state mapping for a half-written unified doc vs a legacy split folder. · **Stale-marking (OQ2)**: how is the implementation half flagged stale when the business half is re-opened? |

## Clarifications

### Session 2026-06-16

- **Q (Workflow Mode)** → **Simple** (user-stated: "simple mode, but full flow" — Simple document/plan shape, but run every stage). CS is borderline CS-4; Simple is a deliberate user override.
- **Q (Testing Strategy)** → **Manual** (user: "we will just do manual validation"). Verification = run the lints + walk the flow by hand.
- **Q (Mock Usage)** → **N/A** (default — no runtime code to mock; stated by the agent, open to objection).
- **Q (Documentation Strategy)** → **Update existing canonical docs** (default — flow-architecture.md + CLAUDE.md + getting-started; stated by the agent, open to objection).
- **Design requirement (user)** → the merged stage **must keep the full front-loaded question set** (Mode/Testing/Mock/Docs + Round-2) — nothing dropped in the merge. Captured as **AC-03**.
- **Artifact shape (user, prior turn)** → **one document** (`<slug>-plan.md`, business spec on top, implementation plan below).
- **Design change (user, 2026-06-16, post-architect)** → **one atomic verb `plan`**: always writes both halves (business + implementation) in a single run; **no `--implementation` flag, no second pass**. Supersedes the workshop's two-modes design; cascades to a single `Status` (AC-02), one routing state, and no STALE (workshop D2/D3/D4/D6 revised). Workshop-before-phases is preserved by iterate-then-re-plan (Non-Goals override).

---

## Validation Record (2026-06-16)

### Validation Thesis
- **Raison d'être**: define WHAT/WHY for merging the-flow's two planning stages into one step + one document — cutting ceremony for the common Simple case without losing fidelity.
- **Value claim**: the build gets unambiguous, testable ACs (one artifact; no question dropped; seam-only-when-live; deterministic routing; lint-green gate; no over-built migration).
- **Proof target**: Decision/Contract. **Thesis source**: `original-ask.md` + § Summary.
- **Thesis verdict**: Advanced (was *Partially*; the post-validation fixes closed the main gaps). **Main thesis risk**: one file must encode two maturity states deterministically — now explicitly owned by the routing workshop, not left implicit.

Validated with `/validate-v2 --scope broad`, including the originating brief (`scratch/paste/20260616T040625.md`) as a candidate-ideas source.

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Clarity & Completeness | UX, Edge Cases, Hidden Assumptions, Concept Docs | 7C/3H/5M (deferred-by-design or fixed) | ⚠️→ workshop owns routing |
| Thesis Alignment | Thesis, Evidence Sufficiency, Proof-Level Fit | 1C/2H/3M fixed/deferred | ⚠️→✅ |
| Forward-Compatibility | Forward-Compat, Integration & Ripple, Deployment/Ops | 1 HIGH (downstream verbs) FIXED in AC-07 | ⚠️→ fixed |
| Brief-Mining / Idea Coverage | Concept Docs, Hidden Assumptions, Evidence | 3 adoptable ideas FOLDED IN | ✅ |

### Forward-Compatibility Matrix (verbatim from the FC agent — pre-fix snapshot)

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| architect/plan | one `<slug>-plan.md`, two halves; mode/ACs/constraints explicit | Encapsulation Lockout | ❌→ workshop resolves verb/id | spec defers OQ1 to workshop |
| workshop | read business source from plan or legacy spec | Shape Mismatch | ❌→ FIXED | `25-workshop.md` hardcodes `<slug>-spec.md`; AC-07 now adds the fallback |
| tasks/implement/review/merge | read business-half fields w/ legacy fallback | Shape Mismatch | ⚠️→ FIXED | AC-07 now names them + the fallback |
| adr (`--spec`) | accept unified plan or legacy spec | Contract Drift | ⚠️→ FIXED | AC-07 now covers `adr` |
| harness router (post-spec `--spec`) | scope to `## Business Specification` | Contract Drift | latent | repo unprovisioned; A3 records it |

**Outcome alignment** (echoed verbatim from the FC agent): *"The spec advances the OUTCOME ('one step, one document' for Simple case, fidelity intact) by freezing the target shape (AC-02 and AC-05) but fails forward-compatibility on five critical fronts … The spec is strategically sound but operationally incomplete."*
**Post-fix note**: the HIGH front (downstream verbs hardcoding `<slug>-spec.md`) is now closed in AC-07; the remaining fronts (exact markers, verb/id, adoption mapping, seam mechanism) are deliberately routed to the **routing workshop** — the very next step.

**Overall: ⚠️ VALIDATED WITH FIXES** — thesis sound, three brief ideas adopted, the one genuine under-scoping (downstream read-path) fixed; load-bearing routing design handed to the workshop by design.
