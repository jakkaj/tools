# Flow-owned harness seams

**Mode**: Simple
**Plan Version**: 1.1.0
**Created**: 2026-06-16
**Revised**: 2026-06-17 — migrated the seam vocabulary from `--event` to the 021 lifecycle **`--hook`** surface (see § Maintenance & resync + Clarifications Session 2026-06-17 + ## Post-validation revision)
**Status**: READY
**Spec source**: unified (this file)

ℹ️ No prior research pass; design was settled conversationally before this document (see `original-ask.md`).

## Business Specification

### Summary

The engineering-harness seams (reached through the one door `/eng-harness-flow`, now keyed on the 021 lifecycle **`--hook`** vocabulary — `pre-flight` / `pre-coding` / `post-coding` / `post-flight`, with `--event` kept as a permanent alias) are wired into `the-flow` only weakly. They fire as **side-effects buried inside the stage sub-skills** — **five** sub-skills actually fire or emit a seam (`20-plan`, `60-implement`, `80-merge`, plus `10-explore`'s `session-start` call and `50-phase-tasks`' seam task-rows), with passing mentions in three more — so the guided **engine** — the thing that owns the rail, the narration, and the flight-plan nodes — does not own them. The result: the seams are invisible on the flight plan, never narrated as beats, never tracked, and silently skipped; an unprovisioned repo drops every harness node entirely. This change **inverts** that. Harness-seam orchestration moves **up into the flow** (the orchestration element) and lives in **one new flow-owned reference** — `references/harness-seams.md` — the single home for *where & when* each seam fires, the two-layer detection, the node-emission rule, the honored-not-forced posture, and the not-installed silent path. The sub-skills go back to being pure **flow-blind *and* harness-blind verbs** (single responsibility, as the flow-architecture pattern already demands of them) — no harness orchestration *and* no harness concepts; **all** harness knowledge lives in the flow (`harness-seams.md` + Graph + `coach.md`) and the router. In a provisioned repo the seams become first-class, narrated, per-phase checkpoints (backpressure offered after the plan, boot before each phase, retro drained after each phase); in an unprovisioned or harness-free repo the flow carries on calmly. A documented resync process keeps the mirror honest when the upstream harness contract changes.

### Goals

- **Single home**: every "when/whether to run the harness" decision lives in `references/harness-seams.md`. **Nothing about the harness — orchestration *or* conceptual framing — remains in any sub-skill.**
- **Sub-skills fully harness-blind**: strip every `/eng-harness-flow` touch **and every harness-loop concept** (boot/backpressure/retro/observe tier-talk) from the stage sub-skills; they describe only their verb. Conceptual harness framing (e.g. the review tier line) moves up to `coach.md`/`harness-seams.md`.
- **Engine-owned beats**: guided mode **print-then-offers** each seam's `/eng-harness-flow --hook …` command at the Graph edge (a **literal** harness invocation — the sanctioned non-`/the-flow` convention, **not** § Command grammar) and advances *through* the corresponding flight-plan node — it offers and runs the beat, never merely paints a node.
- **Per-phase retro**: the phase-end drain is a first-class beat *per phase*, not a buried side-effect — the user's "drain & present retros per phase".
- **Honored, not forced**: seams are prominent **print-then-offer** beats (dispatch invariants #1/#4) — never auto-fired, never gating.
- **Calm when absent**: router not installed → one-time warning, then silence; installed-but-unprovisioned → one calm session line, **no per-phase nagging**.
- **Maintainable**: a documented resync process + a named upstream source-of-truth so a future seam/vocabulary change is a one-file update here.

### Non-Goals

- **NOT** adopting a harness in the tools repo (no `.harness/`, no governance doc) — a separate effort; this repo stays harness-free and that path must remain fully supported.
- **NOT** building any harness infrastructure (no CLI, no eval, no registry, **no drift-check script**) — the user chose *document the process, don't script it*.
- **NOT** changing the external `eng-harness-flow` router or naming/altering its child skills.
- **NOT** preserving harness firing on bare direct-jump — bare `/the-flow <id> <verb>` deliberately goes harness-less (orchestration is the guided engine's job).
- **NOT** introducing any score, threshold, gate, or compliance floor — best-effort throughout.

### Target Domains

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| the-flow (SDD pipeline skill) | existing | **modify** | The entire change lives here: a new flow-owned reference + Graph/render-rule edits + sub-skill strips + schema/template alignment |
| repo docs (CLAUDE.md, docs/how/) | existing | **modify** | Contributor-facing pointers + a standalone seam-contract guide |

> This repo has no `docs/domains/` registry, so the table above is a descriptive single-domain mapping — `the-flow` is the unit of change. The harness itself is **external** (`AI-Substrate/harness-engineering`) and out of scope to modify.

### Testing Strategy

- **Approach**: Manual (lint-gated). There is no unit-test harness for skill markdown; the deterministic lint **is** the gate.
- **Rationale**: the change is markdown + JSON skill-contract content; correctness = lint-clean + grep-verifiable strips + valid JSON + readable contract. Mirrors how plan-031/032 were verified.
- **Focus areas**: `just check-flow` L1 (no leakage in stripped sub-skills), L2 (contract blocks intact), L3 (no unauthorized `/the-flow` literals in flow-level files — note `/eng-harness-flow` is *not* a `/the-flow` command, so harness invocations are legitimate in flow-level `harness-seams.md`), L4 (Graph edges + module paths resolve), L5 (view banners), L6 (≤1024 description). Plus `check-skill-slugs.sh` and JSON-parse of both flight-plan files.
- **Mock usage**: N/A — no executable logic.
- **Excluded**: runtime behaviour of a *provisioned* harness (no harness in this repo to exercise end-to-end).

### Documentation Strategy

- **Location**: Hybrid. (1) `## Maintenance & resync` **in this plan doc** (the canonical process record — the user's explicit ask); (2) `CLAUDE.md` harness section points at `harness-seams.md`; (3) a standalone `docs/how/the-flow-harness-seams.md` guide for external readers.
- **Rationale**: the in-plan record satisfies "document where to update from for next time"; CLAUDE.md keeps contributors oriented; the how-guide serves readers outside this plan folder.

### Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2 (≈9 files), I=1 (integrates an external router whose contract already exists), D=0 (no data/state), N=1 (some novelty in the per-phase node lifecycle), F=0, T=1 (lint-gated manual). Sum = 5 → CS-3.
- **Confidence**: 0.80
- **Assumptions**: the external `eng-harness-flow` contract (the five `--hook` lifecycle hooks + `--event` alias, the `--hooks --json` manifest, the `--json` envelope, boot verdicts) is stable enough that a documented mirror + resync procedure suffices.
- **Dependencies**: the installed `eng-harness-flow` SKILL.md + its `--hooks --json` manifest (read-only, the source-of-truth mirror target). `--hook` emission **requires the 021 hook-aware router** (≥478-line SKILL.md) installed at runtime; see § Maintenance & resync (Runtime dependency).
- **Risks**: see § Risks & Assumptions.
- **Phases**: 1 (Simple).

### Acceptance Criteria

1. **AC-01** — `references/harness-seams.md` exists and is the single home: it contains the **seam map** (Graph edge/state → `--hook` + context flags → emitted node type, with the `--event` alias noted; `pre-flight` listed at **two** edges — flow entry and before each phase), the **two-layer detection** (relocated here), the **node-emission rule**, the **honored-not-forced** posture, the **per-phase retro lifecycle**, and the **not-installed silent path**.
2. **AC-02** — No `/eng-harness-flow` *orchestration* (seam firing **or** seam task-row emission) remains in any sub-skill under `references/stages/`. The **five** sub-skills that today fire/emit a seam — `20-plan`, `60-implement`, `80-merge`, `10-explore` (its `session-start` call) and `50-phase-tasks` (its pre-implement/phase-end task rows) — carry zero seam invocations afterward; the other three hit-files (`25-workshop`, `70-review`, `62-progress`) become **fully harness-blind too** — no `/eng-harness-flow` literal **and no harness-loop concept** (boot/backpressure/retro/observe); any conceptual framing they carried (e.g. review's tier line) moves up to `coach.md`/`harness-seams.md`. **No verb retains any harness awareness.** Verified by `! grep -rnE '/eng-harness-flow --(hook|event)' references/stages/` **and** the harness-loop-concept grep (`! grep -rniE 'eng-harness|backpressure|harness-boot|harness-retro|harness observe' references/stages/`) — both empty, modulo an incidental non-harness "test harness" — plus a per-file audit.
3. **AC-03** — `00-routing.md` § Harness seams is a **pointer** to `harness-seams.md`; the Graph rows carry only terse `seam:` decorations; render rules reference `harness-seams.md` for emission. **The Graph edge into/out of each `phase` (and the post-plan refinement off `plan`) carries a print-then-offer of the seam's `/eng-harness-flow --hook …` command** — printed as a **literal** line (harness commands have no Registry row, so they are **not** rendered via § Command grammar or a `{{render-edge}}` slot — this is the literal convention `coach.md` already uses for `/eng-harness-flow`), print-then-offered under invariants #1/#4 — so the guided engine *offers and advances through* the harness beat, never merely paints a node.
4. **AC-04** — Node emission is **decoupled from provisioning**: harness nodes are emitted when the router is *installed*; **status/label** reflects provisioning (provisioned → normal lifecycle; unprovisioned → calm, **no per-phase ghost-node spam**). Documented in `harness-seams.md` + render rules **for all three surfaces** (flight-plan node, rail companion line, narration beat) — reconciling the existing rules so they don't appear to contradict: emit the *node* when installed, but per `coach.md` omit the *rail companion line* until the router actually reports this session.
5. **AC-05** — The **per-phase `harness-retro` lifecycle** is defined: one retro node per phase; "drain owed" is re-derived from "phase node `done` but its retro sibling still `assumed`/absent" — **no new state file** (the flight-plan node is the durable record).
6. **AC-06** — **Honored, not forced**: every seam is a **first-class print-then-offer beat** the engine presents at the edge (invariants #1/#4) — the user accepts or waves past; never auto-fired, never gating — stated explicitly in `harness-seams.md`. This is the mechanism that makes "first-class" mean *the beat is actually offered (and run on yes) in guided mode*, not merely rendered.
7. **AC-07** — `just check-flow` passes L1–L6 and `check-skill-slugs.sh` reports 0 collisions after the change; both flight-plan JSON files parse.
8. **AC-08** — **Maintenance**: this plan's `## Maintenance & resync` section names the upstream source-of-truth (the `AI-Substrate/harness-engineering` repo's `eng-harness-flow` SKILL.md §§ Lifecycle hooks / `--hooks` manifest / `--json` envelope, runtime-probed at `~/.agents/skills/eng-harness-flow/SKILL.md`) **and points resync at the live `/eng-harness-flow --hooks --json` manifest**, carries the **versioned seam-contract mirror**, and gives the step-by-step update procedure; `CLAUDE.md`'s harness section points at `harness-seams.md`; `docs/how/the-flow-harness-seams.md` exists **and embeds the hook-woven flow tree (Appendix A)**.
9. **AC-09** — **Direct-jump goes harness-less by design** — documented as a deliberate trade (a choice, not a regression).
10. **AC-10** — **Schema/template alignment**: `flight-plan.schema.json` node-type descriptions reflect engine-owned (not sub-skill-fired) seams and **correct the stale** "sits on the spine between spec and plan" backpressure prose (it is now a post-*plan* excursion); `flight-plan.template.json`/`.md` show per-phase retro nodes with literal `/eng-harness-flow --hook …` router-invocation commands.

### Risks & Assumptions

| | |
|---|---|
| **Risk — direct-jump regression** | Stripping sub-skill seams means a provisioned-repo user driving stages with bare direct-jump loses harness pre-flight/retro. **Mitigation**: document as deliberate (AC-09); guided mode is the supported path for harness orchestration. |
| **Risk — mirror drift** | The seam-contract mirror in `harness-seams.md` can drift from the upstream router. **Mitigation**: versioned mirror + named source-of-truth + a written resync procedure (documented, not enforced — the user declined a script). |
| **Risk — ghost-node nag** | Emitting per-phase harness nodes in an unprovisioned repo would nag. **Mitigation**: the resolved UX call (AC-04) — no per-phase nodes when unprovisioned, one calm session line only. |
| **Assumption** | The external contract is stable enough that a documented mirror suffices between syncs. |

### Open Questions

None blocking. The one genuine UX coin-flip (ghost "adopt" nodes vs calm omit in an installed-but-unprovisioned repo) is **resolved in this plan** as *calm omit* (AC-04) and is recorded below for visibility — veto-able.

### Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions | Status |
|-------|------|--------------|---------------|--------|
| Unprovisioned-repo harness UX | Integration Pattern | The single genuine UX fork | ghost "adopt-to-activate" nodes vs calm omit? | **Resolved in-plan** → calm omit; per-phase nodes light up only once provisioned |

### Clarifications

#### Session 2026-06-16
- **Workflow Mode** → Simple (via `--simple`; CS-3, single domain, one logical change).
- **Testing Strategy** → Manual (lint-gated): `just check-flow` + `check-skill-slugs.sh` + reading; redeploy + spot-check.
- **Mock Usage** → N/A (no executable code).
- **Documentation Strategy** → Hybrid: `## Maintenance & resync` in this plan + `CLAUDE.md` pointer + `docs/how/` guide.
- **Direct-jump consequence** → user-confirmed direction: orchestration is the flow's job, so bare direct-jump goes harness-less (AC-09).
- **Maintainability** → user chose *document the resync process + source-of-truth in the plan*, **not** a drift-check script.

#### Session 2026-06-17 — seam vocabulary migration (events → hooks)
- **Upstream change**: `eng-harness-flow` plan 021 (`AI-Substrate/harness-engineering`, PR up) re-skinned its surface as **five neutral lifecycle hooks** (`--hook pre-flight|pre-coding|coding|post-coding|post-flight`); `--event` is now a **permanent alias** (six old seams map onto the five hooks — `session-start` + `pre-implement` both → `pre-flight`). New discovery surfaces: `--hooks --json` (a 5-entry manifest, 9 fields each) + `--help`; the `--json` envelope gained an additive `hook` field. Verified live against the 021 branch SKILL.md (478 lines).
- **Decision** (user, 2026-06-17): `the-flow` **emits `--hook`** as primary — assume the 021 hook-aware router is pulled/installed. `--event` stays documented as the permanent alias. the-flow wires **four** hooks — `pre-flight` (flow entry **and** before each phase), `pre-coding` (post-plan), `post-coding` (each phase end), `post-flight` (at merge) — and **skips** the silent `coding` hook, mirroring the prior decision to skip `task-pause`.
- **Maintainability win**: resync now anchors on the live `/eng-harness-flow --hooks --json` manifest (re-read the 5-entry contract), not a hand-diff of prose — a direct payoff of the "easily update ourselves next time" ask.
- **Runtime dependency**: `--hook` emission requires the 021 router installed (merge 021→main + push + reinstall). Recorded as an assumption per user direction ("assume it will be pulled").
- **Sub-skills fully harness-blind (tightening)**: per the user principle "they should be just focused on their things — the-flow + router hold all the knowledge," the 3 mention files (`25-workshop`/`70-review`/`62-progress`) are stripped of **all** harness references, not just command literals; conceptual framing (review's tier line) moves up to `coach.md` (which already carries it). After T004 **no sub-skill retains any harness awareness**. (Summary/Goals/KF-01/AC-02/T004/Risks updated.)

## Planning Seam
_Refinement opportunities still open — recorded as evidence; the flow surfaces and offers these, none gate:_
- Open Workshop Opportunities: none — the one UX fork resolved in-plan (calm omit).
- Backpressure coverage: not captured.

| Artifact | Present? | Effect on the plan |
|----------|----------|--------------------|
| research-dossier.md | n | — |
| workshops/*.md | n | — |
| backpressure-coverage.md | n | — |

## Implementation Plan

### Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No `[NEEDS CLARIFICATION]` markers remain |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` (flow-architecture pattern is honoured via `just check-flow`, not a rules file) |
| G4 | ADR Compliance | PASS | `docs/adr/` present; no Accepted ADR governs `the-flow` harness wiring — verified during T004 |
| G5 | Structure | PASS | All required sections present |
| G6 | Testing Alignment | PASS | Manual strategy; every task has explicit verification steps |
| G7 | Domain Completeness | PASS | Single existing domain (`the-flow`); Domain Manifest covers every touched file |

### Summary

Author one new flow-owned reference (`references/harness-seams.md`) that owns all harness-seam orchestration, then rewire `00-routing.md` (pointer + terse Graph decorations + render rules that emit per-phase harness nodes), strip `/eng-harness-flow` firing from the stage sub-skills so they are pure flow-blind verbs, align the flight-plan schema/template, and document the resync process (in-plan + CLAUDE.md + a `docs/how/` guide). Verified by `just check-flow` (L1–L6) + slug check + JSON parse, then redeployed.

### Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/the-flow/references/harness-seams.md` | the-flow | contract (NEW) | The single home for seam orchestration + the versioned seam-contract mirror |
| `skills/SDD/the-flow/references/00-routing.md` | the-flow | internal | § Harness seams → pointer; Graph rows → terse `seam:` decorations; render rules 2–5 |
| `skills/SDD/the-flow/references/coach.md` | the-flow | internal | Harness narration sources when/where from `harness-seams.md`; keeps the voice |
| `skills/SDD/the-flow/SKILL.md` | the-flow | internal | Two-load-paths note (guided lazily loads `harness-seams.md` at a harness edge); document direct-jump-harness-less |
| `skills/SDD/the-flow/references/stages/20-plan.md` | the-flow | internal | Strip seam firing (A0 §6, B2 backpressure, Phase-Design harness rows, `### Harness Seams` output, Next-steps) |
| `skills/SDD/the-flow/references/stages/60-implement.md` | the-flow | internal | Strip pre-implement + phase-end seam firing |
| `skills/SDD/the-flow/references/stages/80-merge.md` | the-flow | internal | Strip plan-complete seam firing |
| `skills/SDD/the-flow/references/stages/{25-workshop,70-review,62-progress,10-explore,50-phase-tasks}.md` | the-flow | internal | Audit harness mentions; strip **all** harness references → fully harness-blind verbs |
| `skills/SDD/the-flow/references/flight-plan.schema.json` | the-flow | contract | Node-type descriptions: engine-owned seams; correct stale backpressure prose |
| `skills/SDD/the-flow/references/flight-plan.template.json` | the-flow | internal | Worked example: per-phase retro nodes; router-invocation commands |
| `skills/SDD/the-flow/references/flight-plan.template.md` | the-flow | internal | Re-rendered from the template JSON |
| `skills/SDD/the-flow/references/getting-started.md` | the-flow | internal | Banner-marked rendered view — regenerate if it references seams |
| `CLAUDE.md` | repo docs | cross-domain | Harness section points at `harness-seams.md` |
| `docs/how/the-flow-harness-seams.md` | repo docs | contract (NEW) | Standalone seam-contract guide |

Classification: `contract` (public interface), `internal` (domain-internal), `cross-domain` (editing another area's files).

### Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Blast radius is **8 sub-skills**, and the firing surface is **5, not 3** — seam *firing/emission* lives in `20-plan, 60-implement, 80-merge` **plus** `10-explore` (fires the session-start → `pre-flight` seam) and `50-phase-tasks` (emits pre-implement/phase-end task rows). Only `25-workshop, 70-review, 62-progress` are pure *mentions*. (Today's sub-skills carry `--event` literals; the strip catches **hook or event**, and the rewired engine emits `--hook`.) | T004 enumerates first, then audits all 8; strips firing/emission from the **5** and **strips the 3 mention files fully harness-blind too** — moves review's computational-vs-inferential tier framing up to `coach.md` (which already carries it). After T004, **no sub-skill retains any harness awareness**. |
| 02 | High | The current contract is **internally inconsistent**: render rule 4 emits harness nodes when the router is *installed*, but the plan-032 generator additionally **omitted** them when *unprovisioned* — so nodes vanished. | T001/T003 decouple emit (installed) from status (provisioned); document the unprovisioned = calm-omit-per-phase rule once. |
| 03 | High | Seams currently fire as **in-verb side-effects**, which is the root cause of "not honored" — the engine never sees them. | T001/T003 make them engine-owned Graph beats; T004 removes the side-effects. |
| 04 | Medium | `flight-plan.schema.json:46` still says backpressure "sits on the spine between spec and plan" — **stale** since the spec+plan unification (plan-032); it is now a post-*plan* excursion. | T005 corrects the schema prose + template. |
| 05 | Medium | `/eng-harness-flow` literals are legitimate in **flow-level** files (`harness-seams.md`, 00-routing) and do **not** trip lint L3 (which targets `/the-flow` literals) — but harness *footers* in sub-skills read like "next steps/routing" and can trip **L1**. | Stripping them (T004) is a net L1 improvement; confirm in T008. |

### Implementation

**Objective**: Make harness seams flow-owned, engine-driven, per-phase first-class beats — visible, narrated, durably tracked, honored-not-forced — emitted whenever the router is installed and calm when it is not.
**Testing Approach**: Manual (lint-gated) — `just check-flow` (L1–L6) + `check-skill-slugs.sh` + JSON parse + redeploy/spot-check.

#### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Author `harness-seams.md` core: the **seam map** (edge/state → `--hook` + flags → node type → **the literal print-then-offer command the engine presents at that edge** — a plain `/eng-harness-flow --hook …` line, not grammar-rendered; `pre-flight` listed at two edges — flow entry and before each phase — same hook, different context flags), **two-layer detection** (relocated from 00-routing), **node-emission rule** (emit when installed; status reflects provisioning; unprovisioned = calm omit, one session line), **honored-not-forced** (print-then-offer, engine presents — never the verb), **per-phase retro lifecycle** + "owed" re-derivation, the **not-installed silent path**. | the-flow | `skills/SDD/the-flow/references/harness-seams.md` | File exists; covers all six concerns incl. the per-seam offered command; references no child-skill names | AC-01, AC-04, AC-05, AC-06 |
| [x] | T002 | Add the `## Seam contract (mirrors eng-harness-flow)` block to `harness-seams.md`: versioned mirror (**hooks wired** `pre-flight`/`pre-coding`/`post-coding`/`post-flight` + the silent `coding` hook we don't wire / the `--event`→`--hook` alias map / decisions / verdicts / slug rule), the **upstream source-of-truth pointer** (+ the live `--hooks --json` manifest as the resync anchor), and the **resync procedure**. | the-flow | `harness-seams.md` | Block present with `harness_seam_contract: v1` + hook→event alias map + `--hooks --json` anchor + upstream path + procedure | AC-08 (part) |
| [x] | T003 | Rewire `00-routing.md`: § Harness seams → one-line pointer to `harness-seams.md`; Graph rows → terse `seam:` decorations that the engine surfaces as a **literal print-then-offer** of the router command at the edge (into/out of each phase, and the post-plan refinement off plan) — a plain literal line like coach.md's existing `/eng-harness-flow` narration, **not** a `{{render-edge}}` slot or § Command grammar; render rules 2–5 source emission from `harness-seams.md` (engine-owned, per-phase retro, decoupled emit/status). | the-flow | `skills/SDD/the-flow/references/00-routing.md` | Pointer in place; Graph rows carry an offered harness beat at the phase edges; render rules reference the new file; `just check-flow` L4 green | AC-03, AC-04, AC-05, AC-06 |
| [x] | T004 | **Enumerate first** (`grep -rln 'eng-harness-flow' references/stages/` — confirm the set is exactly 8), then audit all 8; strip seam-firing/emission from the **5** (incl. `10-explore`'s `session-start` call + `50-phase-tasks`' pre-implement/phase-end task rows) → flow-blind verbs; **strip the 3 mention files (`25-workshop`, `70-review`, `62-progress`) fully harness-blind too** — remove every `/eng-harness-flow` literal **and every harness-loop concept** (boot/backpressure/retro/observe tier-talk), relocating any conceptual framing (e.g. review's tier line — already in `coach.md`) up to the flow layer; concept gate `! grep -rniE 'eng-harness|backpressure|harness-boot|harness-retro|harness observe' references/stages/` empty. Verify G4 (no Accepted ADR contradicts). | the-flow | `skills/SDD/the-flow/references/stages/{20-plan,60-implement,80-merge,25-workshop,70-review,62-progress,10-explore,50-phase-tasks}.md` | `! grep -rnE '/eng-harness-flow --(hook|event)' references/stages/` empty; the harness-loop-concept grep (task body) empty; **all 8 sub-skills fully harness-blind** | AC-02 |
| [x] | T005 | Align schema + template: `flight-plan.schema.json` node-type descriptions → engine-owned seams; **correct** the stale "between spec and plan" backpressure prose → post-plan excursion; regenerate `flight-plan.template.json` (per-phase retro nodes **each with `branch_of: "<phase-id>"` + an `assumed`→`done` lifecycle** + literal `/eng-harness-flow --hook …` router-invocation commands) and re-render `flight-plan.template.md`. | the-flow | `flight-plan.schema.json`, `flight-plan.template.json`, `flight-plan.template.md` | Both JSON parse; template shows a per-phase retro node `branch_of`-linked to its phase; `! grep -q 'spine between spec and plan'` on **both** schema and template | AC-10, AC-05 |
| [x] | T006 | Light-touch `coach.md` (harness narration sources when/where from `harness-seams.md`, keeps the voice) + `SKILL.md` (guided mode lazily loads `harness-seams.md` at a harness edge; document **direct-jump-harness-less**). | the-flow | `coach.md`, `SKILL.md` | Both reference `harness-seams.md`; direct-jump-harness-less stated; L6 description still ≤1024 | AC-06, AC-09 |
| [x] | T007 | Docs: **verify/finalize** the existing `## Maintenance & resync` section in **this plan** (already drafted at authoring time); point `CLAUDE.md`'s harness section at `harness-seams.md`; **create `docs/how/` if absent** and write `docs/how/the-flow-harness-seams.md` **embedding the Appendix-A hook-woven flow tree verbatim**; regenerate `getting-started.md` banner view. | the-flow + repo docs | `…/flow-owned-harness-seams-plan.md`, `CLAUDE.md`, `docs/how/the-flow-harness-seams.md`, `getting-started.md` | `docs/how/` exists; CLAUDE.md points at `harness-seams.md`; guide written **and contains the Appendix-A tree**; getting-started regenerated; resync section names the upstream source-of-truth | AC-08 |
| [x] | T008 | Verify + deploy: `just check-flow` (L1–L6) + `scripts/check-skill-slugs.sh` + JSON-parse both flight-plan files; redeploy `just install-skills-from-source`; spot-check canonical store reflects `harness-seams.md`. | the-flow | (whole skill) | Lint L1–L6 clean; 0 slug collisions; JSON valid; canonical store updated | AC-07 |

### Acceptance Coverage Map

| AC | Covered by | Verified in |
|----|-----------|-------------|
| AC-01 | T001 | File exists; six concerns present |
| AC-02 | T004 | grep of `references/stages/` |
| AC-03 | T003 | 00-routing pointer + render rules; L4 |
| AC-04 | T001, T003 | emission rule + render rules text |
| AC-05 | T001, T003 | per-phase retro lifecycle text |
| AC-06 | T001, T006 | print-then-offer statement |
| AC-07 | T008 | `just check-flow` + slug + JSON |
| AC-08 | T002, T007 | resync section + CLAUDE.md + docs/how |
| AC-09 | T006 | direct-jump-harness-less statement |
| AC-10 | T005 | schema/template diff |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Direct-jump harness regression | Medium | Low | Documented as deliberate (AC-09); guided is the supported harness path |
| Seam-contract mirror drift | Medium | Medium | Versioned mirror + named source-of-truth + resync procedure (T002) |
| Over-stripping a non-harness word (e.g. "test harness") | Low | Low | T004 concept-grep targets harness-*loop* vocab (eng-harness/backpressure/boot/retro), not the bare word "harness"; per-file audit |
| Ghost-node nag in unprovisioned repos | Low | Low | Resolved: calm omit (AC-04) |

### Harness Seams

> **Intentionally omitted as a live scaffold.** This repo is unprovisioned and `the-flow`'s *own* build doesn't run the harness on itself. The seam *contract* this plan defines is the subject matter (see `harness-seams.md` once built), not a set of seams fired during this plan's implementation.

## Maintenance & resync

> **This section is the durable "where to update from next time" record** (the user's explicit ask). It is mirrored into `references/harness-seams.md` § Seam contract when T002 lands; this copy is the plan-level record.

**Upstream source-of-truth.** `the-flow` consumes a small, stable slice of the external harness contract owned by **`AI-Substrate/harness-engineering`** (plan 021 — the five lifecycle hooks). Authority, in priority order:

- **Live manifest (preferred resync anchor)**: `/eng-harness-flow --hooks --json` → Shape A `{ manifest_version, hooks[5] }`, nine fields per hook (`hook`, `intent`, `run_at`, `kind`, `invoke`, `aliases`, `produces`, `needs`, `preconditions`). Machine-readable and version-stamped — **re-read it, don't hand-diff prose**.
- **Source SKILL.md** (harness repo): `skills/eng-harness-loop/eng-harness-flow/SKILL.md` → **§ Lifecycle hooks** (the five hooks + the `--event`→`--hook` alias map), **§ The `--hooks` discovery manifest** (the nine-field contract), **§ The `--json` routing envelope** (`decision` enum + the additive `hook` field + boot verdicts), **§ Parameter contract** (the `--hook` / `--event` / flag surface).
- **Runtime probe** (detection, not contract): installed at `~/.agents/skills/eng-harness-flow/SKILL.md` (fallback `~/.claude/skills/eng-harness-flow/SKILL.md`) — what the-flow's Layer-1 probe tests.

**What we mirror (the dependency surface — keep in one place, `harness-seams.md` § Seam contract):**

| Facet | Value (v1, 2026-06-17) |
|-------|------------------------|
| `harness_seam_contract` | `v1` — the 021 five-hook contract; bump when an upstream-mirrored fact changes meaning |
| Hooks we wire (emit `--hook`) | `pre-flight` (flow entry **and** before each phase) · `pre-coding` (post-plan) · `post-coding` (each phase end) · `post-flight` (at merge) |
| Hook upstream has, we **don't** wire | `coding` — the silent `harness observe` capture (mirrors the deliberate prior `task-pause` skip) |
| `--event` alias (permanent) | `session-start`→`pre-flight` · `pre-implement`→`pre-flight` · `post-spec`→`pre-coding` · `phase-end`→`post-coding` · `plan-complete`→`post-flight` · `task-pause`→`coding`. the-flow **emits `--hook`**; `--event` kept for back-compat only |
| Envelope decisions | `route` · `redirect` · `noop` · `ambiguous` (+ the additive `hook` field on every routing envelope) |
| Boot verdicts | `healthy` · `SLOW` · `UNHEALTHY` · `UNAVAILABLE` |
| Slug rule | friendly name → installed slug; **never append a guessed version suffix** |

**Resync procedure — when the harness family or its hooks change:**

1. Run `/eng-harness-flow --hooks --json` and read the 5-entry manifest (or, if the router is uninstalled, read the source SKILL.md §§ above).
2. Diff its `hook` / `aliases` / `kind` / `produces` / `decision` / verdict tokens against the mirror table above.
3. Reconcile the **seam map** and the **mirror table** in `harness-seams.md`; if any mirrored fact changed meaning (a hook renamed, an alias remapped, a verdict added), **bump `harness_seam_contract`** and note what changed.
4. `just check-flow` (L1–L6) + redeploy `just install-skills-from-source`.

**Why no script.** A drift-check script was considered and **declined** (user: "document our process… no need to do any more physical tracking"). The `--hooks --json` manifest + this procedure are the contract; `harness-seams.md` is the one file to edit.

**Runtime dependency (honesty).** `--hook` emission assumes the **021 hook-aware router** is installed (≥478-line SKILL.md). As of 2026-06-17 the 021 PR is up but unmerged/uninstalled — the installed router is still the Jun-11 `--event`-only copy (343 lines). To make `--hook` live: merge 021→main + push in the harness repo, then reinstall (`npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`). Because `--event` is a permanent alias, the mirror's alias row records the `--event` equivalent of every hook as the fallback for any older router.

---

### Validation Record — informal pre-pass (2026-06-16)

_(The formal thesis-aware `validate-v2` record is appended at the **end** of this document — see ## Validation Record (2026-06-17).)_

A validate-*style* pre-pass — 3 parallel agents (coherence, thesis-alignment, source-truth/forward-compat), not the `validate-v2` skill itself. Verdicts: **APPROVE-WITH-FIXES** · thesis value-claim **Partially → Yes after fixes** · source-truth **factually sound** (every file/token claim verified except one mislabel). **0 CRITICAL, 3 MEDIUM, several LOW — all applied:**

| # | Sev | Finding | Resolution |
|---|-----|---------|------------|
| V1 | MED | Firing surface is **5 sub-skills, not 3** — `10-explore` fires `session-start`, `50-phase-tasks` emits seam task-rows (not mere mentions). | Corrected Summary, KF-01, AC-02, T004 to the 5-firing/3-mention split; grep gate broadened to all 8. |
| V2 | MED | "Engine-owned" under-specified the **firing locus** — risk of painting a node without the engine actually offering the seam command in guided mode (proxy optimization). | AC-03/AC-06 + T001/T003 now require the Graph edge to carry a **print-then-offer** of the `/eng-harness-flow --event …` command, advancing *through* the harness beat — not merely rendering a node. |
| V3 | MED | "8 hit-files" count asserted, not re-derived before stripping. | T004 now **enumerates first** (`grep -rln`), then strips. |
| V4 | LOW | `getting-started.md` mislabeled `repo docs` in T007 (it is a `the-flow` file). | T007 Domain relabeled `the-flow + repo docs`. |
| — | INFO | Verified true: `schema.json:46` stale prose; emit-on-installed vs omit-when-unprovisioned inconsistency; all upstream contract tokens (`events/decisions/verdicts/task-pause`) match; the no-new-state-file claim is mechanically sound (existing `status`/`branch_of` fields suffice); lint L3 won't false-positive on `/eng-harness-flow`. | No change needed. |

Net: Status remains **READY**; the central thesis risk (seams visible-but-not-run) is closed by the V2 fix.

---

## Validation Record (2026-06-17)

_The formal thesis-aware `validate-v2` skill run (4 parallel read-only agents) over the post-pre-pass plan._

### Validation Thesis

**Raison d'être**: Harness seams in `the-flow` aren't *honored* — they fire as side-effects buried in stage sub-skills, so the guided engine never owns them (invisible, untracked, silently skipped). The plan specifies the inversion to flow-owned, engine-offered-at-edge, per-phase seams + a documented resync.

**Value claim**: Seams become visible + narrated + durably-tracked + actually offered/run in guided mode (when a harness exists), calm when absent, cheaply re-syncable; sub-skills regain single responsibility.

**Artifact promise**: The implement phase + a future maintainer can build the inversion with minimal clarification.

**Intended beneficiaries**: the implement phase; `the-flow`'s guided-mode users; future resync maintainers; the sub-skills (single responsibility restored).

**Proof target**: Implementation

**Evidence standard**: real file refs, testable ACs mapped to tasks, a deterministic verify path, a resync record naming the authoritative upstream.

**Thesis source**: `original-ask.md` + plan Summary/Goals (grounded, not inferred)

**Thesis verdict**: Advanced

**Main thesis risk**: The 3 mention-only sub-skills could retain `/eng-harness-flow` command literals after T004, leaving single-responsibility only partially restored — closed by the tightened T004/AC-02 gate.

---

| Agent | Lenses Covered | Thesis Axes | Issues | Verdict |
|-------|---------------|-------------|--------|---------|
| Coherence & Risk | System Behavior, Integration & Ripple, Hidden Assumptions, Edge Cases | Implementation Readiness, Safety to Change | 1 MED + 3 LOW — all fixed | ⚠️ → ✅ |
| Completeness & Readiness | Evidence Sufficiency, Proof-Level Fit, Deployment & Ops, Domain Boundaries | Evidence Sufficiency, Implementation Readiness, Contract Integrity | 1 MED + 3 LOW — all fixed | ⚠️ → ✅ |
| Thesis Alignment | Thesis Alignment | Thesis Alignment | 2 LOW (1 fixed via T004 gate, 1 accepted: direct-jump trade) | ✅ |
| Forward-Compatibility | Forward-Compatibility | Downstream Usefulness, Contract Integrity | 1 MED + 1 LOW — fixed | ⚠️ → ✅ |

Lens coverage: 11/15 (Thesis Alignment ✓ mandatory; Forward-Compatibility ✓ mandatory — not STANDALONE).

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| Implement phase (T001–T008) | every file/edit named, ACs testable, verify path | test boundary | ✅ | Domain Manifest + Acceptance Coverage Map + T008 lint/slug/JSON path |
| `references/harness-seams.md` (new) | seam map + emission rule + per-phase lifecycle + versioned contract block | shape mismatch | ✅ | T001 (six concerns) + T002 (`harness_seam_contract: v1` block) |
| Future resync maintainer | authoritative upstream path + procedure + correct mirror | contract drift | ✅ | § Maintenance & resync; mirror tokens verified live against upstream SKILL.md |
| Guided engine (`00-routing.md` + `coach.md`) | edits don't contradict dispatch invariants | contract drift / lifecycle | ✅ *(after fix)* | command-grammar mislabel corrected → **literal** print-then-offer (coach.md precedent), not § Command grammar |

**Thesis alignment**: Value claim advanced (Yes) at the Implementation proof level with Strong evidence; main risk — mention-only sub-skills retaining `/eng-harness-flow` literals — closed by the tightened T004/AC-02 gate.

**Outcome alignment**: As written the plan does advance the VPO Outcome — *"move them up to the flow only… the flow as the orchestration element"* with *"draining and presenting retros from the harness per phase"* — via engine-owned per-phase `harness-retro` beats and the single flow-owned `harness-seams.md`; the one blocking blemish is a naming contradiction (harness command described as a grammar-rendered `/the-flow` command rather than the literal it must be), which is a wording fix, not a design flaw, and once corrected the plan fully satisfies all four downstream consumers.

**Standalone?**: No — four named downstream consumers.

Overall: **VALIDATED WITH FIXES** — 2 MEDIUM + 6 LOW found and applied; thesis advanced at the Implementation proof level; no CRITICAL/HIGH; no open blockers.

---

## Post-validation revision (2026-06-17) — seam vocabulary: events → hooks

After the validation records above, the upstream `eng-harness-flow` contract was confirmed (plan 021, branch `021-harness-flow-hooks`, PR up) to expose **five neutral lifecycle hooks** as its primary surface, with `--event` demoted to a permanent alias. Per user direction, the plan was revised to **emit `--hook`** throughout (assuming the 021 router lands at runtime).

**Scope of the revision (mechanical — design unchanged):**
- event→hook token swap across Summary / Goals / Complexity / AC-01,02,03,08,10 / T001,T002,T004,T005 / KF-01.
- grep gates broadened to `! grep -rnE '/eng-harness-flow --(hook|event)'` (catches both vocabularies during the sub-skill strip).
- `## Maintenance & resync` mirror rewritten to the five-hook contract, re-anchored on the live `/eng-harness-flow --hooks --json` manifest; `coding` recorded as the unwired silent hook; the `--event` permanent-alias map captured as the fallback.
- new Clarifications block (Session 2026-06-17) records the decision + the runtime dependency.

**Why no fresh validation block:** this is a 1:1 vocabulary alias-swap proven by the upstream § Lifecycle hooks mapping table — the thesis, the node model (`harness-boot` / `harness-retro` / `backpressure` types are unchanged), the task structure (T001–T008), and all four Forward-Compatibility consumers are unchanged. The FC row-4 fix (the harness command is a **literal**, not § Command grammar) holds identically for `--hook`. The lone behavioural delta — `session-start` + `pre-implement` now name the **same** `pre-flight` hook — is reflected in AC-01/T001 (pre-flight listed at two edges) and *simplifies* the seam map rather than complicating it. **Status remains READY.** A fresh `/validate-v2` pass is available on request but not required for a mechanical contract-vocabulary migration.

---

## Appendix A — hook-woven flow tree (canonical source for `docs/how/`)

> **Drop this in verbatim during T007** — the `docs/how/the-flow-harness-seams.md` guide must embed this tree, and `getting-started.md` may reuse it. It is the single rendered picture of the-flow spine with the `eng-harness-flow` lifecycle hooks at their attachment points. Keep it in sync with `harness-seams.md` § seam map (this is a *rendered view* of that contract, not a second source).

```
the-flow  ·  SDD spine + ⚙ eng-harness-flow lifecycle hooks
│
├─ ⚙ pre-flight ········ flow entry · detect router · usually NO node      [--hook pre-flight]
│                         (alias: --event session-start)
│
├─ ◇ 1a explore  (optional) ─────────────────────────► research-dossier.md
│
├─ ◆ 1b plan ────────────────────────────────────────► <slug>-plan.md  (spec + impl)
│   └─ ⚙ pre-coding ···· post-plan refinement · backpressure node          [--hook pre-coding]
│         → backpressure-coverage.md (advisory) · re-plan informed by it    (alias: --event post-spec)
│
├─ ◇ 5 tasks  (Full only) ───────────────────────────► tasks/<phase>/tasks.md
│
├─ ◆ 6 implement   ◄── loops once per phase ──────────► code + execution.log.md
│   ├─ ⚙ pre-flight ···· before task 1 · harness-boot node                 [--hook pre-flight]
│   │      → verdict: healthy / SLOW / UNHEALTHY / UNAVAILABLE              (alias: --event pre-implement)
│   ├─ ⚙ coding ········ mid-build · SILENT · NOT wired by the-flow         [harness observe]
│   │      (deliberately skipped — mirrors the old task-pause skip)         (alias: --event task-pause)
│   └─ ⚙ post-coding ··· phase end · harness-retro node                     [--hook post-coding]
│          → drains this phase's friction → .retro.md                       (alias: --event phase-end)
│
├─ ◇ 7 review ───────────────────────────────────────► reviews/*.md   (no hook — inferential tier)
│
└─ ◆ 8 merge  ◄── executes only on typed PROCEED ─────► merge plan
    └─ ⚙ post-flight ··· after merge · harness-retro node                   [--hook post-flight]
           → harvest + present improvements + encode                        (alias: --event plan-complete)
```

**Hooks the-flow wires: 4 fire-hooks** — `pre-flight` (at **two** edges: entry + each phase), `pre-coding`, `post-coding`, `post-flight`. **Skips 1**: the silent `coding` hook.

```
Two-layer gate over the whole ⚙ column:
  L1  router installed?  test -f ~/.agents/skills/eng-harness-flow/SKILL.md
        miss → one warning, omit every ⚙ node for the rest of the flow
  L2  route the hook --json → act on envelope (route|redirect|noop|ambiguous)
        verdicts/labels narrated verbatim; never gates, never blocks
```
