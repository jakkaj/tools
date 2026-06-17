# Execution Log — flow-owned harness seams (plan-033)

**Plan**: `docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md`
**Mode**: Simple (one phase, T001–T008) · **Testing**: Manual (lint-gated)
**Started**: 2026-06-17

## Harness seam (recorded once, per the calm-path contract)

The `/eng-harness-flow` router is installed (the Jun-11 `--event`-only build), but **this repo is
unprovisioned** (no `.harness/`, no governance doc). The pre-implement seam therefore resolves to a
calm **noop** → standard testing applies, nothing else changes. Per the plan's `## Harness Seams`
note, this flow runs harness-less on itself; the seam *contract* is the subject matter, not a live
scaffold. No router invocation made; no per-phase harness nodes on this flow's own flight plan.
(This is exactly the unprovisioned gap plan-033 fixes for the *produced* contract.)

---

## Tasks

<!-- per-task entries appended below as each task completes -->

### T001 — author `harness-seams.md` core  ✅
Created `skills/SDD/the-flow/references/harness-seams.md`. Covers all six concerns: the **seam map**
(every edge → `--hook` + context flags → emitted node → the literal print-then-offer command; `pre-flight`
listed at **two** edges — flow entry and before each phase), **two-layer detection** (relocated from
00-routing), **node-emission rule** (emit when installed; status reflects provisioning; unprovisioned =
calm omit, one session line), **honored-not-forced** (print-then-offer, engine presents — never the verb),
**per-phase retro lifecycle** + "owed" re-derivation (no new state file), and the **not-installed/unprovisioned
silent paths**. The harness command is documented as a **literal** (no Registry row → not § Command grammar /
not a `{{render-edge}}` slot). References no child-skill names. → AC-01, AC-04, AC-05, AC-06.

### T002 — `## Seam contract (mirrors eng-harness-flow)` block  ✅
Appended to `harness-seams.md`: the versioned mirror (`harness_seam_contract: v1`), hooks-we-wire
(`pre-flight`×2 / `pre-coding` / `post-coding` / `post-flight`), the silent `coding` hook we don't wire,
the full permanent `--event`→`--hook` alias map, envelope decisions + additive `hook` field, boot verdicts,
slug rule, the three-tier upstream source-of-truth (live `--hooks --json` manifest preferred / source SKILL.md
§§ / runtime probe), and the step-by-step resync procedure + runtime-dependency honesty note. → AC-08 (part).

### T003 — rewire `00-routing.md`  ✅
- Intro "this file owns" line: dropped "harness-seam detection", added the pointer to `harness-seams.md`.
- § Harness seams (≈23 lines: detection + envelope + the five-seam list) **collapsed to a compact pointer**
  to `harness-seams.md` (lazily loaded at a harness edge); kept the node-type names + advisory posture.
- Graph rows → terse engine-owned `--hook` `seam:` decorations: `start` (pre-flight @ entry), `awaiting-1b`
  (pre-coding backpressure, engine print-then-offers), `awaiting-2c` (pre-coding still offered), `awaiting-5`
  (engine offers pre-flight boot — `harness-boot` node, **not** "the implement verb fires it"), `awaiting-6`
  (engine-owned pre-flight/post-coding at the phase edges), `awaiting-8` (engine offers post-flight retro),
  `complete` (post-flight already offered). All now read as engine beats, not in-verb side-effects.
- Render rule 4 → `--hook`; documents emit-on-installed / status-reflects-provisioning / no ghost-node spam /
  per-phase retro + "drain owed" re-derivation (no new state file).
- Shared-conventions § Harness router posture → rewritten: seams flow-owned, **sub-skills carry no harness
  invocations or concepts**, points at `harness-seams.md` (was "stage modules keep seam invocations inline").
→ AC-03, AC-04, AC-05, AC-06.

### T004 — strip all 8 sub-skills fully harness-blind  ✅
**Enumerated first**: `grep -rlE 'eng-harness-flow' references/stages/` = exactly 8 (10-explore, 20-plan,
25-workshop, 50-phase-tasks, 60-implement, 62-progress, 70-review, 80-merge). Stripped:
- **60-implement** (5 edits): Side-effects (harness→domain.md updates), §2 harness-availability probe, §2a
  Pre-Phase Harness Seam, §7 Phase-end seam, companion "step 7 phase-end still fires" parenthetical, the
  `> Harness posture` footer.
- **80-merge** (4): Side-effects, PROCEED step 5 (plan-complete seam), Success-Message harness line, the
  `## Harness seam` section.
- **10-explore** (3): Side-effects (session-start→none), §2c session-start seam, closing harness note →
  harness-blind "frozen prior-learnings" note. **Kept** the Prior-Learnings Scout's read of `docs/harness/agents/**`
  (frozen read-only history — keep-list sanctioned, not a seam concept; doesn't trip the concept-grep).
- **50-phase-tasks** (4): §4 harness-availability probe, §5 T000/T0xx seam-task rows, Context-Brief harness block,
  closing harness note.
- **25-workshop** (1), **70-review** (3: Side-effects, live-runtime note reword, closing harness note),
  **62-progress** (3: Side-effects, Step-8 retro reword, closing note) → fully harness-blind (no `/eng-harness-flow`
  literal, no boot/backpressure/retro concept). Review's tier framing already lived in coach.md (de-dup; nothing
  to move).
- **20-plan** (14): removed ALL backpressure/harness content — Consumes, A0 §4 & §6, A4 Planning-Seam intro +
  template row, B0 Harness bullet, B2 backpressure block, Phase-Index "Establish Backpressure" row, Output-Contract
  item 9, Full-template `### Harness Seams`, 3 Phase-Design harness principles → 1 harness-blind "no build-tooling
  phase" principle, Per-Phase N.0/N.z rows + `### Harness Seams` template, Output line, and the Purpose-line
  "(workshop/backpressure)".
**Gates**: firing grep `/eng-harness-flow --(hook|event)` = EMPTY ✓; concept grep `eng-harness|backpressure|harness-boot|harness-retro|harness observe` = EMPTY ✓. **G4**: `docs/adr/` has only README.md — no Accepted ADR governs the-flow harness wiring → PASS. `just check-flow` L1–L6 clean. → AC-02.
**Behavioral consequence (deliberate, per the inversion):** the plan verb no longer auto-consumes `backpressure-coverage.md` / designs a "Phase 0: Establish Backpressure" — that harness knowledge now lives only in the flow (`harness-seams.md` + Graph + coach). Consistent with AC-09 (direct-jump goes harness-less) and the user's "sub-skills focus only on their things" principle.

### T005 — align schema + template  ✅
- `flight-plan.schema.json`: node-`type` description → engine-owned seams + `--hook`; **corrected** the stale
  "sits on the spine between spec and plan" → "post-PLAN excursion off the unified plan node, branch_of plan";
  `command` description `--event` → `--hook`.
- `flight-plan.template.json`: `_comment` + all 4 harness nodes (`bp` pre-coding, `hb` pre-flight, `hr2`
  post-coding, `hh` post-flight) → `--hook` + engine-owned framing; `hh` gained `--plan-dir`. Retro nodes are
  `branch_of` their phase (`hr2`→p2; `hh`→merge).
- `flight-plan.template.md` re-rendered: prose + 4 mermaid harness labels → `--hook`, engine-owned.
**Gates**: both JSON parse ✓; `grep 'spine between spec and plan'` absent in schema **and** template ✓; retro
nodes `branch_of`-linked; residual `--event` only inside explicit "alias --event …" notes. → AC-10, AC-05.

### T006 — light-touch coach.md + SKILL.md  ✅
- `coach.md` (9 edits): harness-companion-rail example `(post-spec)`→`(pre-coding)`; added the pointer to
  `harness-seams.md` (seam→edge + literal `--hook` command owned there); awaiting-1b/2c backpressure literals
  `--event post-spec`→`--hook pre-coding`; awaiting-5 "implement stage fires the pre-implement seam"→"the flow
  offers the pre-flight boot seam" (`--hook pre-flight`); awaiting-6 phase-end→post-coding (engine-offered);
  awaiting-7 tier line "post-spec backpressure"→"the backpressure check"; awaiting-8 plan-complete→post-flight
  (`--hook post-flight`); complete narration post-flight.
- `SKILL.md` (3 edits): invariant #9 → `--hook` (+ "--event permanent alias", flow-owned `harness-seams.md`,
  sub-skills harness-blind); Direct-jump step 3 → **"no harness seams (harness-less by design)"**; State section
  → points harness orchestration at `harness-seams.md`, "sub-skills carry no harness knowledge".
→ AC-06, AC-09. (Both files now reference `harness-seams.md`; direct-jump-harness-less stated.)

### T007 — docs  ✅
- **CLAUDE.md** (4 edits): harness-section paragraph → `--hook` vocab + flow-owned pointer to
  `harness-seams.md` + sub-skills-harness-blind (plan-033); Depth line += plan-033; "Editing the SDD pipeline"
  structural sentence += `references/harness-seams.md` as the flow-owned harness home + "to change where/when the
  harness fires, edit harness-seams.md".
- **`docs/how/the-flow-harness-seams.md`** created (dir created) — standalone seam guide **embedding the
  Appendix-A hook-woven flow tree verbatim** + seam-map table + two-layer gate + vocabulary/runtime + resync.
- **getting-started.md** regenerated (banner-marked view): seam table → 5 rows with `--hook` + `--event` alias
  + "four fire-hooks, skips coding"; mermaid `--event`→`--hook` + engine-offered; walkthrough + Quick-Ref →
  `--hook`, removed the now-stale **N.0/N.z** (plan) and **T000/T0xx** (tasks) seam-row references (those
  emitters were stripped in T004); one-sentence + "five times"→"at each seam".
- `## Maintenance & resync` in the plan: verified finalized (names upstream source-of-truth, anchors resync on
  `--hooks --json`, carries the v1 mirror + procedure + runtime-dependency note).
**Gates**: getting-started clean of stale tokens; all residual `--event` in the skill are alias-qualified;
guide present with the Appendix-A tree. → AC-08.

### T008 — verify + deploy  ✅
- `just check-flow` → **L1–L6 clean, 0 warnings**.
- `scripts/check-skill-slugs.sh` → **13 skills, no slug collisions**.
- JSON parse: `flight-plan.schema.json`, `flight-plan.template.json`, `the-flow.json`, `.the-flow-state.json` all OK.
- `just install-skills-from-source` → redeployed; canonical store `~/.agents/skills/the-flow/` updated.
- Spot-check: `harness-seams.md` present in canonical store (14.4 KB); deployed `references/stages/` concept-grep
  EMPTY (harness-blind); `harness_seam_contract: v1` + `--hook pre-flight` live; Claude Code view symlinked.
→ AC-07.

---

## Phase complete — all 8 tasks [x]

plan-033 implemented: harness seams are now **flow-owned, engine-offered per-phase beats**. New flow-owned
`references/harness-seams.md` (seam map + two-layer detection + node emission + per-phase retro lifecycle +
honored-not-forced + versioned upstream contract); `00-routing.md` Graph rows + render rules rewired to
engine-owned `--hook` seams; **all 8 sub-skills fully harness-blind** (firing grep + concept grep both EMPTY);
schema/template aligned + stale "spine between spec and plan" corrected; coach.md/SKILL.md light-touch +
direct-jump-harness-less; CLAUDE.md pointers + `docs/how/the-flow-harness-seams.md` (Appendix-A tree) +
getting-started regenerated. Verified L1–L6 + slugs + JSON; redeployed.

**Acceptance criteria**: AC-01 (harness-seams.md single home) · AC-02 (no seam firing/concept in sub-skills) ·
AC-03 (00-routing pointer + engine-offered Graph beats) · AC-04 (emit-decoupled-from-provisioning) · AC-05
(per-phase retro lifecycle, no new state file) · AC-06 (honored-not-forced print-then-offer) · AC-07
(check-flow + slugs + JSON) · AC-08 (resync record + CLAUDE.md + docs/how) · AC-09 (direct-jump harness-less) ·
AC-10 (schema/template alignment) — **all met**.

**Deliberate trade (logged):** the plan/tasks verbs no longer auto-consume `backpressure-coverage.md` or emit
N.0/N.z·T000/T0xx seam rows — that harness knowledge moved up into the flow. Consistent with the inversion
principle + AC-09. Vetoable.

**Suggested commit:** `feat(the-flow): flow-owned harness seams — engine-offered --hook beats, harness-blind sub-skills (plan-033)`

---

## Review fix loop — review #1 = REQUEST_CHANGES (1 HIGH + 1 MED-doctrine + 3 MED/LOW)

`/the-flow 7 review` returned **REQUEST_CHANGES** (review.md / fix-tasks.md). All 5 findings resolved:

- **F001 (HIGH) — backpressure fold-in vs harness-blind plan verb.** The flow promised "re-run plan to fold
  the coverage in," but the stripped `plan` verb no longer reads `backpressure-coverage.md`. **User decision
  (AskUserQuestion): Option A — drop the fold-in; backpressure is ADVISORY OUTPUT.** Reworded every surface so
  the survey *informs* the re-plan (the plan verb does not auto-read it): `00-routing.md` (awaiting-1b decoration,
  awaiting-backpressure row, render rule 3), `coach.md` (awaiting-1b/awaiting-backpressure narration + rail
  example), `harness-seams.md` (pre-coding beat), `flight-plan.template.json` (bp note), `getting-started.md`
  (walkthrough + quick-ref), `docs/how/the-flow-harness-seams.md` (tree line + seam-map row), and the plan's
  Appendix-A tree. Plan verb unchanged (stays harness-blind). Most aligned with the inversion principle.
- **F002 (MED) — node-emission contradiction** ("never vanish per phase" vs "no per-phase ghost-node spam").
  Resolved to one rule: **per-phase harness nodes emit only when installed AND provisioned**; installed+unprovisioned
  → one calm line, no per-phase nodes. Aligned `harness-seams.md` § Node emission, `00-routing.md` render rule 4,
  `flight-plan.schema.json` node-type description, and `getting-started.md` Detection.
- **F003 (MED) — template under-models per-phase seams + missing `--json`.** Added `--json` to all 4 harness
  commands in `flight-plan.template.json` + the 4 mermaid labels in `flight-plan.template.md`; added `--json` to
  the render-rule-4 command pattern; marked the template's harness nodes as an **abbreviated** example (one boot +
  one retro; real plans emit one of each per phase per `harness-seams.md`).
- **F004 (LOW) — old-router fallback wording.** Reworded `harness-seams.md` Runtime-dependency + `docs/how` Vocabulary:
  the flow emits `--hook` (021 required); an older `--event`-only router is a **runtime-dependency gap (reinstall)**,
  **not** an auto-fallback; `--event` column is for back-compat understanding only.
- **F005 (LOW) — coach intro.** `coach.md:3` "(state, routing, seams) lives in 00-routing.md" → "state/routing/Graph
  in 00-routing.md; harness-seam orchestration in `harness-seams.md`".

**Re-verify**: no backpressure fold-in language remains; sub-skills concept-grep still EMPTY; both JSON parse;
all 4 template harness commands carry `--json`; `just check-flow` L1–L6 clean; redeployed (F002+F004 wording live
in canonical store). **Re-review pending.**

> **Note on AC-04 wording (for the re-review):** AC-04 in the plan still reads "emitted when the router is *installed*;
> status/label reflects provisioning" — its own phrasing carried the tension F002 flagged. The **operative rule** is
> the plan's resolved UX (Open Questions "calm omit" + Risks "no per-phase nodes when unprovisioned"): per-phase nodes
> require installed **and** provisioned. The implementation now states this consistently; AC-04's spec text is left
> as the validated record with this clarification logged here.
