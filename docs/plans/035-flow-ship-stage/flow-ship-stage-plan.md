# the-flow Ship Stage — Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-06-19
**Status**: READY
**Spec source**: unified (this file)

## Business Specification

### Summary

Replace the-flow's merge-centric final stage (`8 merge`) with a **`ship`** verb whose job is to *get work out*: push the branch, open a PR (using repo guidance when present), watch the PR's CI checks, and report failures. The existing local-merge **upstream-reconcile** machinery (today's `80-merge.md`) is preserved but **demoted** to a conditional excursion fired only on real base divergence; the actual merge becomes **optional** (platform auto-merge, or a separate confirm-gated step). The point: the flow's terminal beat should be "PR up, checks watched, problems reported" — not a heavy local git merge.

### Goals

- Final stage reads as **ship**, not merge — push → open PR → watch checks → report.
- **Repo-guidance-aware**: read a PR template / `CONTRIBUTING` / `CODEOWNERS` / default base when present; degrade cleanly when absent.
- **Watch CI checks** after the PR opens and **report problems**; a red check offers a `fix-loop`, never blocks.
- **Demote merge**: keep the upstream-reconcile analysis as a conditional excursion; make the actual merge optional.
- **Best-effort throughout**: `gh` degrades gracefully; publishing stays behind an explicit confirm gate; no new gates/scores/thresholds.

### Non-Goals

- Building CI itself, or any check definitions — the verb *reads* check status, it doesn't author checks.
- Auto-merging without confirmation, or any always-on auto-merge policy.
- Deleting the upstream-reconcile capability — it is demoted, not removed.
- Fixing the `.the-flow-state.json` hand-write determinism (separate concern — see `scratch/handover-flow-state-determinism.md`).
- Touching `minih`, the harness child skills, or anything outside `skills/SDD/the-flow/`.

### Target Domains

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| the-flow (SDD pipeline skill) | existing | **modify** | Replace the terminal stage; add the `ship` sub-skill; demote merge to a reconcile excursion |

> No `docs/domains/` registry exists (skills repo) — the formal domain system is **N/A**. "Domain" here is the the-flow skill itself; G7 is N/A by absence of a registry.

### Testing Strategy

- **Approach**: Lightweight. This is prompt/markdown (skill) authoring — the deterministic check is `just check-flow skills/SDD/the-flow` (flow-architecture linter), plus a smoke run of a flight plan through the `ship` node in `scratch/`, plus an eyeball.
- **Rationale**: no test harness for skill prose; `check-flow` + smoke is the proportionate, repeatable signal. Consistent with the repo's best-effort stance.
- **Focus areas**: sub-skill contract well-formedness (harness-blind, no flow-command literals), Registry/Graph/alias coherence, rail renders with `ship` as terminal.
- **Excluded**: unit tests of `gh`/CI behavior (smoke-only); the `.the-flow-state.json` determinism work.
- **Mock Usage**: Avoid mocks entirely — smoke against real `harness flow` + a real `gh` dry-run.

### Documentation Strategy

- **Location**: No new documentation. The skill files are the docs; `getting-started.md` regenerates as the rendered view and captures the change. The plan folder records rationale.
- **Rationale**: a self-documenting skill change; a separate doc would drift.

### Complexity

- **Score**: CS-4 (large) — *run as **Simple Mode by user choice**: it's one cohesive change, and the sequencing here is **external coordination** (another agent's WIP), not internal phase dependencies — so phase gates would add ceremony without value. Validation flagged the true scope as CS-4.*
- **Breakdown**: S=2, I=2, D=1, N=2, F=1, T=1 (sum 9 → CS-4)
- **Confidence**: 0.75 — validation surfaced an omitted file (`flight-plan-ops.md`), the reconcile-verb grammar gap (now resolved), and missing publish degradation modes (now added)
- **Assumptions**: `harness flow` CLI stays capable (v0.4.0 confirmed); `gh` present in dev environments (degrades when not); the new `ship` nodeType lands cleanly in the schema.
- **Dependencies**: the other agent's in-flight schema WIP (chore lifecycle) touches the same `flight-plan.schema.json` — coordinate the `nodeTypes` edit.
- **Risks**: schema-edit collision; overlap with the active declarative-tracking rework on `00-routing.md`/`coach.md`.
- **Phases**: 1 (Simple) — one cohesive change, inline tasks.

### Acceptance Criteria

1. **AC-01** — A `ship` verb exists at `references/stages/80-ship.md` with the standard sub-skill contract (Verb/Purpose/Consumes/Produces/Flags/Exit), harness-blind, no flow-command literals.
2. **AC-02** — The Registry binds `8 ship` → `80-ship.md`; typed `merge` and `plan-8-v2-merge` alias-resolve to the demoted reconcile excursion; the journey line reads "…→ review → ship".
3. **AC-03** — The `ship` verb reads repo PR guidance (PR template / `CONTRIBUTING` / `CODEOWNERS` / default base) when present and degrades to defaults when absent (this repo: absent → title from plan, body = spec summary + the Claude Code footer).
4. **AC-04** — Push and PR-open are **separate** explicit confirms (PR-open is outward-facing and never fires on an affirmative inherited from the push prompt); the actual merge stays typed-`PROCEED`-gated or handed to platform auto-merge.
5. **AC-05** — After PR creation the verb watches CI checks with a **bounded** poll (defined interval + cap), reports pass/fail, and has explicit paths for **no checks configured** (report "no CI", stop) and **still-pending at cap** (report "still running", stop). On red it surfaces the failing check + offers a `fix-loop` excursion, and never blocks.
6. **AC-06** — The verb degrades cleanly (printed instruction, no hard error) for each: `gh` absent/unauthed (→ `git push` + compare URL), **PR already exists** (→ reuse it, jump to watch), and **no remote / no upstream / detached HEAD**.
7. **AC-07** — The local-merge upstream-reconcile machinery (current `80-merge.md`) is preserved as a conditional `8c reconcile` excursion, fired only on real base divergence — not the headline terminal stage.
8. **AC-08** — The flight-plan schema gains a `ship` nodeType (postflight zone); the harness `post-flight` retro rides the `ship` edge (`branch_of:"ship"`) instead of `merge`, with the seam contract version handled (bump or recorded).
9. **AC-09** — `just check-flow skills/SDD/the-flow` passes; `getting-started.md` + both templates + `coach.md` + `flight-plan-ops.md` reflect ship-as-terminal; redeploy from source succeeds and a scratch smoke shows the rail ending at **Ship**.
10. **AC-10** — The verb detects "on the default branch / head == base / nothing to push" (this repo's main-only reality) and degrades to a printed instruction — it never errors out of `gh pr create`.
11. **AC-11** — A pre-existing on-disk `the-flow.json` whose terminal node is `merge` still renders cleanly under the new ship-terminal Graph (renderer legacy/unknown-type fallback) — old flows don't break.

### Risks & Assumptions

- **Schema collision (HIGH)** — `flight-plan.schema.json` is mid-edit by the other agent (chore WIP). Mitigation: coordinate / land the `nodeTypes` edit after their WIP commits; this plan should not be implemented until that settles.
- **Rework overlap (HIGH)** — `00-routing.md`/`coach.md` are in the active declarative-tracking rework lane. Mitigation: sequence this plan *after* (or in coordination with) that rework; flagged in memory.
- **`gh`/CI variance (MED)** — check names/latency vary per repo; watching must be best-effort with a bounded wait + a "still running" report, never a hard block.
- **Outward-facing publish (MED)** — push + PR + merge are irreversible-ish; all stay behind explicit confirm gates (invariant #2).

### Open Questions

- Verb name `ship` vs `pr` — plan assumes **`ship`** (action verb covering push+PR+checks). Easy to swap before implementation.
- **Reconcile demotion — RESOLVED (per validation):** aliases must resolve to a Registry **id+verb**, so "reconcile excursion" needs a real grammar home. Decision: add a Registry row **`8c reconcile` → `references/stages/80-merge.md`** (the kept machinery; its sub-skill `**Verb**:` becomes `reconcile`). `8 ship` is the terminal; typed `merge` and `plan-8-v2-merge` alias-resolve to `8c reconcile`. The reconcile node attaches as a `branch_of` excursion, never the spine. *(User may override the id/name.)*

### Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| ship verb CLI/UX flow | CLI Flow | The push→PR→watch→report→(fix-loop\|merge) sequence has several confirm gates + degradation branches worth pinning before authoring | When exactly to confirm? How long to watch checks? What's the red-check → fix-loop handoff? |

### Clarifications

#### Session 2026-06-19
- **Workflow Mode** → Simple (focused one-stage redesign).
- **Testing Strategy** → Lightweight (`check-flow` + scratch smoke + eyeball).
- **Mock Usage** → Avoid mocks entirely.
- **Documentation Strategy** → No new documentation.

## Planning Seam
_Refinement opportunities still open — recorded as evidence; the flow surfaces and offers these, none gate:_
- Open Workshop Opportunities: ship verb CLI/UX flow (optional — recommended before authoring `80-ship.md`).

| Artifact | Present? | Effect on the plan |
|----------|----------|--------------------|
| research-dossier.md | n | — (session context + targeted probes used instead) |
| workshops/*.md | n | — |

## Implementation Plan

### Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | no `[NEEDS CLARIFICATION]` markers; Round 1 answered |
| G2 | Constitution | N/A | no `docs/project-rules/constitution.md` |
| G3 | Architecture | N/A | no `docs/project-rules/architecture.md` (flow-architecture pattern enforced by `check-flow`, not a gate file) |
| G4 | ADR Compliance | N/A | no relevant accepted ADRs |
| G5 | Structure | PASS | all required sections present + populated |
| G6 | Testing Alignment | PASS | Lightweight → T009 is the validation task |
| G7 | Domain Completeness | N/A | no domain registry (skills repo) |

### Summary

One cohesive Simple-mode change to `skills/SDD/the-flow/`: author a new `ship` sub-skill as the terminal verb, demote the existing merge machinery to a conditional `reconcile` excursion, and re-thread the flow surfaces (Registry, Graph, schema nodeType, templates, coach, getting-started, harness seam) so the journey ends at **ship**. Verified by `check-flow` + a scratch smoke run; deployed from source. Best-effort throughout — `gh` and repo-guidance both degrade cleanly.

### Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `references/stages/80-ship.md` | the-flow | internal (NEW) | the new ship verb sub-skill |
| `references/stages/80-merge.md` | the-flow | internal | demoted → reconcile excursion (kept machinery) |
| `SKILL.md` | the-flow | contract | Registry row, journey line, alias table |
| `references/00-routing.md` | the-flow | internal | Graph terminal + reconcile excursion edge |
| `references/flight-plan.schema.json` | the-flow | contract | `ship` nodeType (+ zone) |
| `references/harness-seams.md` | the-flow | internal | `post-flight` rides the `ship` edge |
| `references/flight-plan.template.json` / `.template.md` | the-flow | internal | worked example ends at ship |
| `references/flight-plan-ops.md` | the-flow | internal | spine line, `postflight` zone table, build-order (finding 08) |
| `references/coach.md` | the-flow | internal | narration: ship terminal, merge→reconcile |
| `references/getting-started.md` | the-flow | internal | regenerated rendered view |

### Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | `80-merge.md` is an **inbound upstream-reconcile** tool (pull main in, conflict/regression analysis), not an outbound ship tool — the two concerns are conflated under "merge" | Split: author `80-ship.md` (outbound); demote 80-merge to a conditional reconcile excursion |
| 02 | High | `gh` is present + authed here (2.92.0, base=`main`) but won't be everywhere | ship verb gh-precheck → degrade to `git push` + compare URL when absent (AC-06) |
| 03 | High | **No** PR template / `CONTRIBUTING` / `CODEOWNERS` in this repo | repo-guidance reading is best-effort; default title/body when absent (AC-03) |
| 04 | High | Blast radius ~9–13 the-flow files incl. `flight-plan.schema.json` `nodeTypes`, which is **mid-edit by the other agent** | sequence the schema edit; coordinate (Risk) |
| 05 | High | harness `post-flight` retro rides the `merge` edge (`harness-seams.md:48`, `branch_of:"merge"`) | remap to `branch_of:"ship"` (AC-08) |
| 06 | Medium | push/PR/merge are outward-facing; invariant #2 forbids irreversible actions without confirmation | confirm gate on PR open; merge stays PROCEED-gated (AC-04) |
| 07 | Medium | schema already has a `fix-loop` excursion type | red check → offer fix-loop, never block (AC-05) |
| 08 | High | `flight-plan-ops.md` hardcodes the spine `… → review → merge` (L49), the `postflight` zone table (L63), and "merge first" build-order (L69) — **omitted from the first task pass** | T010 rewrites its spine line, zone table (`postflight \| review, ship, merge, retro`), build-order; gives `ship` a zone band |
| 09 | High | This repo + the smoke env are on **`main`** (base `main`, "main-only/no-branches" rule) — `gh pr create` head==base fails; ship has no branch to push by default | ship detects "on default branch / nothing to push" → printed instruction, never errors (AC-10) |

### Implementation

**Objective**: Make `ship` the-flow's terminal stage (push → PR → watch checks → report), demote merge to a conditional reconcile excursion, and re-thread every flow surface — best-effort, lint-clean, deployed.

**Testing Approach**: Lightweight — `just check-flow skills/SDD/the-flow` + a scratch smoke run of a flight plan through the `ship` node + eyeball. No mocks.

#### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Author the `ship` sub-skill: contract block + procedure (preconditions → read repo guidance → confirm → push + `gh pr create` → watch checks → report/fix-loop → optional merge) | the-flow | `skills/SDD/the-flow/references/stages/80-ship.md` | File exists; harness-blind; no flow-command literals; covers AC-03/04/05/06 | Per finding 01,02,03 |
| [x] | T002 | Demote merge → `reconcile`: keep the upstream-analysis machinery, drop the "final stage" framing; sub-skill `**Verb**:` becomes `reconcile`; attaches as a conditional `branch_of` excursion | the-flow | `references/stages/80-merge.md` | Machinery intact; verb=`reconcile`; not terminal | Per finding 01; AC-07 |
| [x] | T003 | Registry + grammar + aliases: add `8 ship`→`80-ship.md` **and** `8c reconcile`→`80-merge.md`; journey line "…→ review → ship"; map typed `merge`/`plan-8-v2-merge` → `8c reconcile` | the-flow | `skills/SDD/the-flow/SKILL.md` | both Registry rows present; aliases resolve to id+verb; `check-flow` L4 closure passes | AC-02; reconcile-grammar |
| [x] | T004 | Graph + routing: spine terminal = ship; add reconcile as a conditional `branch_of` excursion; replace the `awaiting-8` merge seam; fix the `seed … assumed plan/merge` spine-seed (00-routing.md:31) | the-flow | `references/00-routing.md` | Graph ends at ship; reconcile is `branch_of`; seed updated | Enumerate exact lines; coordinate (rework overlap) |
| [x] | T005 | Schema: add `ship` nodeType (postflight zone) + description; keep `merge` as the reconcile excursion type | the-flow | `references/flight-plan.schema.json` | `harness flow` accepts a `ship` node; zone=postflight | **File dirty in-tree NOW** — start only after chore-WIP commits; rebase `nodeTypes` onto theirs (finding 04) |
| [x] | T006 | Harness seam remap: `post-flight` retro rides the `ship` edge (`branch_of:"ship"`); bump `harness_seam_contract` (v1-frozen) or record why not | the-flow | `references/harness-seams.md`, `references/00-routing.md` | seam table + branch_of + contract version updated; no `merge`-terminal seam | AC-08; finding 05 |
| [x] | T007 | Templates: worked example ends at `ship` — rewrite the `_comment`, the `merge` node (`command`/type), the `branch_of:"merge"` retro node; regenerate the `.md` via `harness flow render` | the-flow | `references/flight-plan.template.json` / `.template.md` | template validates; rendered `.md` shows ship terminal; no stale merge node | never hand-edit the `.md`; CLI renderer bands `ship` in flight zone (cross-repo follow-up) |
| [x] | T008 | coach.md narration (the ~12 merge mentions) + getting-started.md rendered view: ship terminal, merge→reconcile excursion; regenerate the banner-marked view | the-flow | `references/coach.md`, `references/getting-started.md` | both reflect ship; getting-started regenerated not hand-edited | AC-09 |
| [x] | T009 | `flight-plan-ops.md`: rewrite the spine line (`… → review → ship`), the `postflight` zone table (`postflight \| review, ship, merge, retro`), and the build-order note; give `ship` its zone band | the-flow | `references/flight-plan-ops.md` | no stale `merge`-terminal spine; `ship` zoned | Per finding 08 |
| [x] | T010 | Lint + deploy + smoke: `just check-flow` passes; redeploy from source; scratch smoke shows the rail ending at **Ship**; a legacy `merge`-terminal flow still renders | the-flow | (repo) | `check-flow` exit 0; redeploy ok; smoke rail ends `… · Ship`; AC-11 holds | AC-09/10/11; Lightweight test |

### Acceptance Coverage Map

| AC | Covered by | Verified in |
|----|-----------|-------------|
| AC-01 | T001 | file exists, contract well-formed |
| AC-02 | T003 | Registry/alias + `check-flow` |
| AC-03 | T001 | guidance-read + default-when-absent |
| AC-04 | T001 | confirm gate on PR; PROCEED on merge |
| AC-05 | T001 | watch + report + fix-loop offer |
| AC-06 | T001 | gh-absent degradation |
| AC-07 | T002 | reconcile excursion retains machinery |
| AC-08 | T005, T006 | schema nodeType + seam remap |
| AC-09 | T007, T008, T009, T010 | check-flow + smoke + redeploy |
| AC-10 | T001, T010 | on-default-branch degradation; smoke |
| AC-11 | T005, T010 | legacy merge-terminal renders |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Schema-edit collision — `flight-plan.schema.json` is **dirty in-tree NOW** (chore WIP uncommitted) | High | Med | T005 starts **only after** the WIP commits; rebase the `nodeTypes` enum onto theirs — don't author against the pre-WIP file |
| Overlap with the active declarative-tracking rework (`00-routing`/`coach`) | High | Med | Land this plan after that rework; T004/T008 enumerate exact lines + coordinate |
| On the default branch / nothing to push (main-only repo) | High | High | ship detects head==base / no branch → printed instruction, never errors (AC-10) |
| Unbounded or empty check-watch (no CI configured, or pending forever) | Med | Med | bounded poll (interval + cap) + explicit no-checks / still-pending report paths (AC-05) |
| CI-check watching varies per repo (names, latency) | Med | Med | Bounded wait + "still running" report; never block (AC-05) |
| Outward-facing publish (push/PR/merge) | Med | High | **Separate** confirms for push vs PR-open; typed `PROCEED` on merge (AC-04) |
| Seam contract is v1-frozen | Low | Med | bump `harness_seam_contract` when remapping post-flight, or record why not (T006) |
