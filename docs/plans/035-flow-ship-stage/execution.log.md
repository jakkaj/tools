# Execution Log — 035-flow-ship-stage

**Plan**: `docs/plans/035-flow-ship-stage/flow-ship-stage-plan.md` (Simple, READY)
**Mode**: Simple · **Testing**: Lightweight (`just check-flow` + scratch smoke + eyeball) · **Companion**: no
**Started**: 2026-06-19

## Phase start

- Base verified clean before start: the other agent's chore-lifecycle schema WIP committed as `1f3958e` (todo/skipped statuses), so `flight-plan.schema.json` is no longer dirty — T005 can rebase its `ship` nodeType onto a clean file.
- Harness seam (`pre-implement`/boot): router installed but this repo is **unprovisioned** (no `.harness/`) → Layer-2 `noop`. Proceeding with standard Lightweight testing; no per-phase harness nodes. (Recorded once; not re-warned.)
- Decision (plan-faithful): keep the demoted machinery file named `references/stages/80-merge.md` (verb becomes `reconcile`) per the plan's Domain Manifest — preserves git blame on the reconcile machinery; the Registry binds `8c reconcile → 80-merge.md`.

## Tasks

- **T001 — author `ship` sub-skill** ✓ `references/stages/80-ship.md` (NEW). Contract block (Verb/Purpose/Consumes/Flags/Produces/Side effects) + procedure: input resolution → preconditions & degradation (nothing-to-ship/no-remote/no-gh/dirty) → read repo PR guidance → confirm#1 push → confirm#2 open PR → bounded check-watch → optional gated merge → ship report. Harness-blind, no flow-command literals (check-flow L1/L2 confirm). Covers AC-01/03/04/05/06/10.
- **T002 — demote merge → reconcile** ✓ `references/stages/80-merge.md`: `# reconcile`, `**Verb**: reconcile`, Purpose reframed as a *conditional* upstream-reconcile excursion (fired on real base divergence, not the terminal step; points to `ship` for outbound). Subagent machinery (U1/Y1/C1/C2/R1/S1 + merge-plan doc) left intact. AC-07.
- **T003 — Registry + grammar + aliases** ✓ `SKILL.md`: split row 8 → `8 ship`→80-ship.md **and** `8c reconcile`→80-merge.md; added a terminal/excursion clarifier line; alias table `plan-8-v2-merge`→`8c reconcile`, added `typed merge`→`8c reconcile`; description frontmatter journey `→ review → ship` + `8 ship, 8c reconcile` (954/1024 chars); invariant #2 reworded for ship's separate confirms + reconcile PROCEED. AC-02.
- **T004 — Graph + routing** ✓ `references/00-routing.md`: `awaiting-7` clean→**ship**; rewrote `awaiting-8` (ship report/PR; checks→complete · diverged→reconcile · red→re-ship; post-flight retro branch_of ship); `complete` row; seed `plan/ship` (+ `--zone postflight` note); must-see fields; excursion examples gained reconcile.
- **T005 — schema** ✓ `references/flight-plan.schema.json`: added `"ship"` to `nodeTypes` (kept `merge` for reconcile); description "Node-type meanings" documents ship (terminal/postflight) + merge (conditional reconcile excursion) + post-flight-at-ship. JSON valid.
- **T006 — harness seam remap** ✓ `references/harness-seams.md` (+ 00-routing line under T004): seam map row **at ship**, `branch_of: "ship"`; "post-flight @ ship"; drain/harvest + contract "Hooks we wire" rows. **No `harness_seam_contract` bump** — recorded why: the remap changed only which the-flow Graph edge the hook rides (internal-flow fact), not a mirrored upstream fact (hook/alias/verdict/node-type all unchanged). AC-08.
- **T007 — templates** ✓ `flight-plan.template.json` (`merge` node → `ship` node id/type/label/command; p6 `next:["ship"]`; retro `branch_of:"ship"` + note; `_comment` post-flight-at-ship) → regenerated `flight-plan.template.md` via `harness flow render` (also corrected pre-existing rail-format + chore-legend staleness). Rail ends at **Ship**.
- **T008 — coach.md + getting-started.md** ✓ coach: rails (37/50/76), milestones Research…**Ship** (46/47), final-stage narration (25), `awaiting-7`/`awaiting-8`/`complete` blocks (263–270), welcome line, adoption table. getting-started: journey, seam table, both mermaid subgraphs, Full-Mode walkthrough, the two Registry-view rows (added Ship + Reconcile), the worked-example step 6. Remaining "merge" mentions are all legit (reconcile machinery / spec+plan merge / JSON-merge adoption). AC-09.
- **T009 — flight-plan-ops.md** ✓ spine `… → review → ship`; reconcile added to excursions list; zone table `postflight | review, ship, merge, retro` + an honest **cross-repo `ship`-banding caveat** (external renderer maps unknown `ship`→flight until its zone-set learns ship; `--zone postflight` is the escape hatch — proven in smoke); build-order "ship first".
- **T010 — lint + deploy + smoke** ✓
  - `scripts/check-flow-architecture.sh skills/SDD/the-flow` → **exit 0**, L1–L6 clean (Registry 10 rows, closure holds, descriptions ≤1024).
  - `just install-skills-from-source` → deployed; verified `~/.agents/skills/the-flow/` carries 80-ship.md + both Registry rows + `ship` nodeType. (Live skill description now reads "review → ship".)
  - Scratch smoke (ship spine, `--zone postflight`): rail = `◆ Research · ◆ Plan · [ ◐ Implement ] · ◇ Review · ◇ Ship` — **ends at Ship, banded postflight** (AC-09). Legacy merge-terminal flow: `render: ok`, rail ends at Merge (**AC-11**). Smoke artifacts cleaned.

## Discoveries & Learnings

| # | Kind | Note |
|---|------|------|
| D1 | Decision | Kept the demoted machinery file at `80-merge.md` (verb `reconcile`) per the plan's Domain Manifest — preserves git blame; Registry binds `8c reconcile → 80-merge.md`. A future rename to `80-reconcile.md` is cosmetic. |
| D2 | Cross-repo follow-up | The external `harness flow` renderer (v0.4.0) has no `ship` in its postflight zone-set, so an un-`--zone`d ship node bands into **flight** (the "unknown type → flight" rule). Mitigated three ways: the seed passes `--zone postflight` (00-routing step 6), the smoke proves it works, and flight-plan-ops.md documents the caveat. Real fix belongs upstream (add `ship` to the renderer's postflight defaults). |
| D3 | Determinism (the flagged issue) | This run again **hand-wrote `.the-flow-state.json`** (guided-mode state) while the flight plan (`the-flow.json`) was driven deterministically via `harness flow`. Confirms the split in `scratch/handover-flow-state-determinism.md` — out of scope here (Non-Goals), but live-observed again. |
| D4 | Minor (prior) | `add-node --next <dangling>` is accepted + persisted (only `insert-node` DAG-rechecks); flight-plan-ops.md §6 "validator rejects forward --next refs" overstates it for `add-node`. Not fixed (out of scope). |

## Phase complete

All 10 tasks `[x]`. **Acceptance criteria AC-01…AC-11 all covered** (see plan's Acceptance Coverage Map; AC-09/10/11 verified by check-flow + scratch smoke + redeploy). `check-flow` exit 0; skill redeployed; both smokes pass. Best-effort throughout — no gates/scores added; `ship` and `gh` degrade cleanly.

**Not committed** — staged for review (the user holds git). Next step: `/the-flow 7 review`.
