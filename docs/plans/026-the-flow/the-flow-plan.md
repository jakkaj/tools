# the-flow — Guided Co-Pilot — Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-05-29
**Spec**: [the-flow-spec.md](./the-flow-spec.md)
**Status**: READY

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | 0 `[NEEDS CLARIFICATION]` markers; skill-structure fork resolved (Round 2 → single re-entrant). |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md`. |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md`. |
| G4 | ADR Compliance | N/A | `docs/adr/` holds only `README.md` (index) — no Accepted ADRs. |
| G5 | Structure | PASS | All required Simple-mode sections present + populated. |
| G6 | Testing Alignment | PASS | Lightweight strategy; T005 is the validation task; ACs are measurable. |
| G7 | Domain Completeness | PASS | No domain registry (skills are the product — informal mapping); Domain Manifest covers every file in the task table; the one NEW "domain" is the skill folder, whose setup task is T001/T002 (authoring it). |

## Summary

`the-flow` is a single, re-entrant SDD-pipeline skill that walks a user through the existing `plan-*` flow (`getting-started.md`) like an expert beside them: it asks what they want to build, routes that to `/plan-1a`/`/plan-1b`, then at each seam narrates why the stage matters, points out one insight from the artifact just produced, surfaces the optional branches the terse pipeline under-advertises (`/plan-2c`, `/plan-2d`), suggests `/compact` at the canonical seams, and makes the harness loop legible. Because it recommends `/compact` (which discards conversation context), it carries durable on-disk state (`.the-flow-state.json`) and resumes idempotently — the spine design is fully specified in workshop 001 (drive model, state contract, stage machine, per-seam copy, `/compact` handshake) — that part is transcription. Two capabilities are **designed in this plan** (no workshop): it **adopts plans already in flight** (late-join — see the **Adoption Contract** section: back-fill state + flight-plan files from existing artifacts, then continue, with concrete inference + safety rules) so it's a general user-assistive tool not a fresh-start-only one, and it ships the **flight-plan JSON schema** (AC-19, normative field set = workshop 002). The deliverable is one `SKILL.md` plus shipped flight-plan **schema + templates** and catalog/reference doc edits; it adds **no** new orchestration plumbing (the pipeline already self-chains) and never gates, scores, or runs code-changing/merge commands.

## Target Domains

This repo has no domain registry — the skills themselves are the product (consistent with plans 022–025); mapping is informal.

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| `skills/SDD/the-flow/` | **NEW** | **create** | The single re-entrant co-pilot skill — the entire deliverable. |
| `skills/SDD/` pipeline + `skills/harness/` | existing | **consume** | Referenced by name only (narration targets). No edits. |
| Catalog docs | existing | **modify** | Add catalog rows + a map mention. |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/the-flow/SKILL.md` | the-flow | contract | The new skill — its public surface (frontmatter + body). Created by T001/T002. |
| `README_AGENTS.md` | catalog docs | cross-domain | Add catalog row (T003). |
| `docs/skills-pipeline/README.md` | catalog docs | cross-domain | Add pipeline-reference row (T003). |
| `skills/SDD/the-flow/references/getting-started.md` | catalog docs | cross-domain | Add `/the-flow` mention as the conversational front-door (T004). |
| `skills/SDD/the-flow/references/flight-plan.template.json` | the-flow | contract | Flight-plan DAG standardisation template + worked example (T006). |
| `skills/SDD/the-flow/references/flight-plan.template.md` | the-flow | contract | Flight-plan mermaid standardisation template + worked example (T006). |
| `skills/SDD/the-flow/references/flight-plan.schema.json` | the-flow | contract | JSON Schema for the flight-plan DAG (nodes + `agents[]`) — standardisation/docs only, hand-validated (T006). |

> Runtime-only artifacts (written by the skill at runtime, not this repo's source): `.the-flow-state.json` (resume state), `original-ask.md` (verbatim ask, D6), `the-flow.json` (flight-plan DAG / source of truth, D9), and `the-flow.md` (mermaid, generated from the json, D8) — all under `docs/plans/<ord>-<slug>/`. The skill *source* additionally ships `references/flight-plan.template.{json,md}` (in the manifest, via T006).

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | `the-flow` is **narration + judgement, not new plumbing** — the `plan-*` pipeline already self-chains (every skill ends with a `Next step` line; several auto-fire). | Tasks only read each artifact + re-frame the skill's own `Next step` line; never reimplement orchestration (stated invariant). |
| 02 | Critical | Must not collide/confuse with `sdd-tutorial` (RPIV/`task-*` vs `plan-*`). | Distinct slug + description + an explicit "drives `plan-*`, not RPIV" body line; catalog row states the distinction (T001, T003). |
| 03 | Critical | `/compact` discards conversation context ⇒ the skill needs **durable state + idempotent re-entry**. | `.the-flow-state.json` (temp-file+rename) + scan-discovery + idempotency rule (T001), per workshop §State Contract / D2. |
| 04 | High | Drive model **resolved to Option A (coach)** (workshop D0) — closes the spec's "A vs C" workshop opportunity. | All narration is "speak → tell user the exact command → user re-runs `/the-flow`" (T002). Never invoke plan skills itself. |
| 05 | High | Fresh-start chicken-and-egg (no plan folder yet) **resolved**: `the-flow` allocates the ordinal + creates the dir, then `/plan-1a`/`/plan-1b` reuse it by slug (workshop D1). | T001 fresh-start path: allocate via `plan-ordinal`, derive slug, `mkdir`, write state, then issue `/plan-1a`/`/plan-1b`. |
| 06 | Medium | **Single terminal** (not `sdd-tutorial`'s two); `/compact` is the hygiene valve (workshop D3). | Document single-terminal rhythm in the body; no two-terminal handoff copy. |
| 07 | High | **Late-join is expected to be a common real case** — users will reach for a guide *after* they've already run `/plan-1a/1b/3` by hand (assumption, not yet measured; the minih/chainglass survey in `references/real-flow-examples.md` shows plans were driven ad-hoc rather than from a single front-door). A fresh-start-only skill would be useless mid-cycle. | Adoption path (T007) per § Adoption Contract: detect existing artifacts → back-fill state + `the-flow.json/.md` + `original-ask.md` (best-effort, no-clobber) → resume from the user's actual position as a confirmable suggestion. Never re-runs/overwrites completed work. |

## Implementation

**Objective**: Transcribe workshop 001's resolved design into one re-entrant `the-flow/SKILL.md` with **three entry paths (fresh / resume / adopt-mid-plan)**, ship the flight-plan schema + templates, wire the catalog/reference docs, and validate structurally + by dry-run walkthrough (incl. a re-entry-after-`/compact` simulation **and a mid-plan-adoption back-fill**).

**Testing Approach**: Lightweight — `check-skill-slugs.sh` exit 0, frontmatter `name`↔folder match, catalog grep, and a dogfooded dry-run walkthrough over ≥3 stages including a `/compact` re-entry sim (no mocks — real plan folder `026-the-flow`).

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Author the skill's **mechanics**: frontmatter (`name: the-flow`, description distinguishing it from `sdd-tutorial` — drives `plan-*`); the re-entrant main loop (fresh-start: ask intent → allocate ordinal via `plan-ordinal` → **derive slug = kebab-case of the intent's first ~3–5 significant words, e.g. "a guided co-pilot for the flow" → `guided-co-pilot`** → `mkdir docs/plans/<ord>-<slug>/` → **write the verbatim ask to `original-ask.md` (D6)** → write state (incl. `intent`) → issue `/plan-1a`/`/plan-1b`; resume: glob `docs/plans/*/.the-flow-state.json` where `status:active` → 0=fresh / 1=resume / >1=list+ask / `<slug>` arg overrides; **adopt-mid-plan: when there is no active state but the resolved/arg plan folder already holds artifacts (`*-spec.md`, `*-plan.md`, `tasks/phase-*/`, `reviews/`), back-fill state + `original-ask.md` (best-effort from spec/research) by inferring `mode`, `milestones_done`, and the current stage from artifact existence, then resume from the user's actual position — never re-run or overwrite completed work**); the `.the-flow-state.json` contract (schema + temp-file+rename); the idempotency + discovery rule (**discover the stage's artifact by existence at its expected path — newest if several, scoped by `last_checkpoint_at` mtime; found → advance exactly once; no new artifact → reprint `pending_command`, do not advance**). | the-flow | `/Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md` | File exists; `name: the-flow` matches leaf folder; description says it drives `plan-*` and is not `sdd-tutorial`; fresh-start + resume + **adopt-mid-plan** + discovery + idempotency all present; **fresh-start writes `original-ask.md` verbatim**; **adopt back-fills state + flight files from existing artifacts without overwriting completed work**; **slug-derivation rule + per-stage discovery method stated**; state schema + write method documented. | Per workshop §State Contract, D1, D2, D4, D6. Findings 02/03/05/07. |
| [x] | T002 | Author the skill's **content**: the **host progress-rail rule (D5)** — every turn begins with `[the-flow] ◆…◇` (◆=done / ◇=remaining macro-milestone, joined by `─`; glyphs tunable; rendered from `state.milestones_done`/`_total`; 7 macro-milestones recomputed to mode after `/plan-1b`; a distinct-colour `· now:/next:` status line with **dynamic expansion** + `· phase k/n` in a phase), applied to every narration block per the Stage→rail map; the stage machine + routing table (all 11 stages: `start, awaiting-1a/-1b/-2c/-2d/-3/-5/-6/-7/-8, complete`, each with discover-artifact / insight-source / compact-seam / harness-cue / next-command); the 11 per-seam narration blocks (Orient→Suggest→Invite, affordance contract), **each prefaced with the sigil**; **light one-line mentions of the optional non-spine branches (D7)** — deep-research-with-tool-of-choice at `awaiting-1a` (online agent or coding harness), plus `/plan-3a` ADR, prework gate, the fix loop after `7`, domains, `/util-0-handover` at their seams; **the companion/worker affordance (D10)** at the build seam — default `code-review-companion` via `/plan-6-companion`, plus attaching other minih agents (companion or worker), all optional, narrated + tracked (not run by the-flow); the `/compact` resume handshake ("type `/compact` yourself, then re-run `/the-flow`"); **the agent self-mirroring instruction (D11 / AC-20)** — each turn tells the coding agent to mirror the flow in its own todo list (one todo per upcoming stage / current phase, synced to the rail) and to re-invoke `/the-flow` after every `/compact` and on any fresh session; harness cues (boot expectation *before* `/plan-6`; drain/harvest explained *after*; **honours `docs/compound/.disabled`** — silently skips harness narration); the explicit invariants block (never runs code-changing/merge commands; **never invokes `/plan-*` itself — every command is emitted as text for the user to type, per drive-model Option A**; never gates/scores/blocks; `/plan-2c`/`/plan-2d`/`/compact` and all D7 branches are always optional). | the-flow | `/Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md` | **Host sigil rule stated + present on every narration block**; all 11 stages in the routing table; all 11 narration blocks present in coaching voice; **deep-research light mention (tool of choice) at `awaiting-1a` + the other D7 branches mentioned at their seams**; `/compact` handshake sequence present; **agent self-mirroring instruction present (mirror flow in todos + re-run `/the-flow` after `/compact`/fresh session, AC-20)**; boot-before/drain-after cues present; `.disabled` check present; invariants block present (no code/merge; **no self-invocation of `/plan-*`**; no gate/score; optional branches). | Transcribe workshop §Routing Table, §Narration Scripts, §Resume Handshake; D5/D6/D7; AC-20. Findings 01/04/06. |
| [x] | T003 | Wire catalog docs: add a `the-flow` row to the skill catalog and the pipeline reference, framing it as the guided co-pilot **front-door** for the `plan-*` pipeline, that it *drives/narrates* (not teaches) and is distinct from `sdd-tutorial`. | catalog docs | `/Users/jordanknight/github/tools/README_AGENTS.md`, `/Users/jordanknight/github/tools/docs/skills-pipeline/README.md` | Both files contain a `the-flow` row with the front-door + "distinct from sdd-tutorial" framing. | Mirror the plan-2d catalog-row precedent (plan-025). |
| [x] | T004 | Add a `/the-flow` mention to the pipeline map it voices (e.g., a line in §"The Big Picture" or §"Quick Reference"). | catalog docs | `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md` | `getting-started.md` references `/the-flow` as the conversational front-door to the pipeline. | Light touch; the map the skill narrates. |
| [x] | T005 | Validate (Lightweight, no mocks): run the slug check; confirm frontmatter↔folder; dry-run the coach loop on a real plan folder (dogfood `026-the-flow`) across ≥3 stages **including a re-entry-after-`/compact` simulation** (state read back → correct stage resumed → idempotent, no double-advance); grep the three docs for `the-flow`. | the-flow + catalog docs | `/Users/jordanknight/github/tools/scripts/check-skill-slugs.sh`, the new skill, the three docs | `bash scripts/check-skill-slugs.sh` exits 0; `name: the-flow` = folder; walkthrough covers ≥3 stages **including the idempotency two-branch** (run a real plan skill to produce the stage artifact → `/the-flow` advances exactly once; re-run with no new artifact → reprints the pending command, no double-advance); **confirm harness narration is silently omitted when `docs/compound/.disabled` is present**; **read the body and confirm the invariants block lists all four** (no code/merge; no self-invocation of `/plan-*`; no gate/score; optional branches); **confirm the host sigil prefaces the `start` (and ≥2 other) narration blocks (AC-12)**; **confirm fresh-start writes `original-ask.md` with the verbatim ask in the dry-run (AC-13)**; **adoption dry-run: point `/the-flow` at a plan folder that already has a spec + plan but no the-flow state (dogfood `026-the-flow` itself) → confirm it back-fills state + `the-flow.json/.md` + `original-ask.md` and resumes at the correct stage without overwriting the spec/plan (AC-18); and confirm the no-clobber rule (a pre-existing `original-ask.md` is preserved, `.reconstructed.md` written instead)**; **schema check: confirm `references/flight-plan.schema.json` exists and hand-validate `references/sample-the-flow.json` against it — every required field (`id`, `type`, `status` …) present, no unknown-field rejection (AC-19)**; **confirm a narration turn instructs the agent to mirror the flow in todos + re-run `/the-flow` after `/compact` (AC-20)**; `the-flow` found in all three docs. | AC-2/4/5/8/10/11/12/13/18/19/20 verified here. Avoid mocks — real plan folder. |
| [x] | T006 | **Flight-plan DAG + shipped templates**: maintain `the-flow.json` (source-of-truth DAG — nodes carry `type/status/command/ran_at/user_input(verbatim)/note/artifacts[]/next[]/branch_of`; document-level **`agents[]`** for parallel minih agents — `kind:companion\|worker`+`covers[]`+`render`+`status`) and **generate `the-flow.md` from it** each turn (vertical spine + dashed rejoining excursions, **each workshop its own node**; status→colour incl. `known`/`assumed`; `assumed→known` at `/plan-3`; **🗣 verbatim user-input bubbles**; **companion wraps its phases (subgraph), worker = side-node**); **ship the standardisation templates + JSON Schema in the skill** with the worked example: `flight-plan.template.{json,md}` (worked example) **and `flight-plan.schema.json` (the DAG contract — nodes + `agents[]`)**. Hand-cranked by inference — first-class CLI/validator is OOS (workshop 002 § Decision Space). | the-flow | `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json`, `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md`, `/Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json`; (runtime) `docs/plans/<ord>-<slug>/the-flow.json` + `the-flow.md` | `flight-plan.template.{json,md}` **and `flight-plan.schema.json`** present — **schema encodes the FULL field set from workshop 002 § JSON contract: nodes `id`(required)`/type/status/command/ran_at/user_input/note/artifacts[]/next[]/branch_of` + optional `phase/iterations/tool`, and `agents[]` `id`(required)`/kind/slug/runtime/run_id/status/covers[]/render/driver/note`; `references/sample-the-flow.json` validates against it by inspection (all required present, no unknown-field rejection); the schema file carries a `$comment` marking it reference-only / mirrors-the-template (pull-forward of workshop 002 Q1, validator still OOS)**; runtime `the-flow.json` written (nodes + `agents[]`) + `the-flow.md` regenerated from it; `known`/`assumed` shades, 🗣 bubbles, companion-wrap + worker-side all render. Dry-run on `026-the-flow`. | Per workshop 002 (DAG) + 001 D8/D9/D10. AC-15/16/17/19. Samples in `references/sample-the-flow.{json,md}`. |
| [x] | T007 | **Mid-plan adoption (late-join / back-fill)**: author the third entry path so `/the-flow` invoked part-way through a cycle (no active state, but plan folder already has artifacts) **adopts** the in-flight plan: detect artifacts (`*-spec.md` → Spec done; `*-plan.md` → Plan done + read `mode` + phase count; `tasks/phase-N/` → that phase started; `reviews/` → reviewed), reconstruct `.the-flow-state.json` (stage, `milestones_done/_total`, `pending_command` = the user's actual next step), best-effort reconstruct `original-ask.md` (verbatim if recoverable, else summarise from spec/research with a `reconstructed:` note), and **back-fill `the-flow.json` + `the-flow.md`** marking already-done nodes `done` and the rest `known/assumed` — **without re-running or overwriting any completed work** — then resume narration from the user's real position. | the-flow | `/Users/jordanknight/github/tools/skills/SDD/the-flow/SKILL.md` | Adoption path present + documented as a peer of fresh/resume, **implementing the § Adoption Contract** (folder resolution incl. >1→list+ask; the full artifact→stage inference table incl. partial-phase `awaiting-6`/`/plan-7` and spec-only `mode:unknown`; mtime-based `ran_at` + `reconstructed` `user_input` on back-filled nodes); back-fills state + `the-flow.json/.md` + `original-ask.md` with the **no-clobber safety rules** (`.reconstructed.md` fallback, merge-not-overwrite `the-flow.json`); presents the inferred stage as a **confirmable suggestion**; explicitly never re-runs/overwrites done work. | Per AC-18 + § Adoption Contract, Finding 07. Validated by the T005 adoption dry-run. |

### Adoption Contract (T007 / AC-18 design — front-loaded here since no workshop covers late-join)

The spine (T001/T002) is transcribed from workshop 001; **adoption has no workshop**, so its contract is specified here so `/plan-6` doesn't improvise it.

**Trigger**: invocation with **no active `.the-flow-state.json`** AND the resolved plan folder contains any of `*-spec.md` / `*-plan.md` / `tasks/phase-*/` / `reviews/`.

**Folder resolution**: `<slug>` arg → that folder. Else exactly one artifact-bearing `docs/plans/*/` with no active state → adopt it. Else (>1) → list + ask (mirror the resume `>1` rule).

**Artifact → stage inference** (pick the furthest-progressed; `pending_command` = the user's real next step):

| Artifacts present | Inferred stage | `pending_command` | `milestones_done` |
|---|---|---|---|
| `research-dossier.md` only | `awaiting-1b` | `/plan-1b` | Research |
| `*-spec.md` (no plan) | `awaiting-2c`/`awaiting-3` | `/plan-2c` (opt) → `/plan-3` | Research, Spec |
| `workshops/*.md` + spec | `awaiting-3` | `/plan-3` | + (workshops are excursions, no milestone) |
| `*-plan.md` present | read `**Mode**` + phase count → recompute rail; `awaiting-6` | `/plan-6 --phase "Phase 1…"` | + Plan |
| `tasks/phase-N/` present, **no** `reviews/review.phase-N*` | `awaiting-6` (mid-build) | `/plan-7` (review phase N) | + per-phase to N-1 |
| `reviews/review.phase-N*` present | phase N reviewed | `/plan-6 --phase "Phase N+1…"` (or `/plan-8` if last) | + per-phase to N |

**Mode / rail**: read `**Mode**` from the plan header. If no plan yet, `mode:unknown` and `milestones_total` stays the 7-milestone estimate until `/plan-3` recomputes it.

**Back-fill `the-flow.json`**: completed nodes → `status:done`, `ran_at` from artifact mtime (best-effort), `user_input` omitted or flagged `reconstructed:true` (the user never spoke to the-flow for these); remaining nodes → `known`/`assumed` per the normal taxonomy. Regenerate `the-flow.md` from it.

**Safety (never clobber)**: never re-run a stage or touch `*-spec.md`/`*-plan.md`/`tasks/`/`reviews/`. If `original-ask.md` exists, write `original-ask.reconstructed.md` instead. If `the-flow.json` exists and is non-empty, **merge** (preserve any real nodes) rather than overwrite; on conflict, print a notice and keep the existing file.

**Uncertainty**: present the inferred position as a **confirmable suggestion** ("looks like Plan done, Phase 1 next — correct?"), never an assertion; if inference is ambiguous, ask rather than guess (best-effort, never blocks).

### Acceptance Criteria

- [x] **AC-1** — `skills/SDD/the-flow/SKILL.md` exists; valid frontmatter (`name:` = folder); description unambiguously distinguishes it from `sdd-tutorial` (drives `plan-*`, not RPIV). *(T001)*
- [x] **AC-2** — Single + re-entrant: one `/the-flow` handles fresh start (no active state → ask intent) and resume (active state → advance from recorded stage); `>1` active → list + ask; `<slug>` arg overrides. *(T001, T005)*
- [x] **AC-3** — Fresh start asks what to build and routes to `/plan-1a` or `/plan-1b` with a stated choice rule. *(T001)*
- [x] **AC-4** — Durable resume-state contract (plan dir, slug, mode, current stage, pending command, last checkpoint) with temp-file+rename — sufficient to resume after `/compact`. *(T001, T005)*
- [x] **AC-5** — Idempotent resume: discovers the new artifact and advances exactly once; if none, re-prints the pending command without double-advancing. *(T001, T005)*
- [x] **AC-6** — Per-stage narration map covers all seams (`1a,1b,2c,2d,3,5,6,7,8`), each with Orient line + one-artifact-insight pointer + optional branch(es) + next command, in coaching voice. *(T002)*
- [x] **AC-7** — `/compact` suggested at the canonical seams (after `1a`, before `3`, before `6`, between phases), each phrased optional + "type `/compact` yourself, then re-run `/the-flow`". *(T002)*
- [x] **AC-8** — Harness affordances surfaced at the right seams (boot gate before `6`; observe mentioned; drain/harvest explained) and **honours `docs/compound/.disabled`**. *(T002)*
- [x] **AC-9** — `/plan-2c` (post-spec) and `/plan-2d` (pre-architect) surfaced as optional branches; `/plan-2d` verdict + any Phase 0 framed user-decided, never a gate. *(T002)*
- [x] **AC-10** — Never runs code-changing/merge commands; **never invokes `/plan-*` itself (issues every command as text for the user — drive-model Option A)**; never blocks/scores/gates — stated as an explicit invariant in the body. *(T002)*
- [x] **AC-11** — `check-skill-slugs.sh` exits 0; catalog rows in `README_AGENTS.md` + `docs/skills-pipeline/README.md`; `getting-started.md` mentions `the-flow`. *(T003, T004, T005)*
- [x] **AC-12** — **Host-identity sigil**: every `the-flow` turn opens with the fixed one-line banner (`✦━━ the-flow ━━✦`, tunable) so the guide's voice is unmistakable vs `plan-*` output — stated as a rule + on every narration block. *(T002, T005)*
- [x] **AC-13** — **Verbatim ask logged**: fresh start writes the user's unedited ask to `docs/plans/<ord>-<slug>/original-ask.md` (+ `state.intent`). *(T001, T005)*
- [x] **AC-15** — **`the-flow.md` flight view** regenerated from `the-flow.json` each turn: vertical spine Research·Spec·Plan·[per-phase]·Merge + dashed excursions; node colours done/wip/blocked/known/assumed; phases expand after `/plan-3`. *(T006)*
- [x] **AC-16** — **Flight-plan JSON DAG** (`the-flow.json`) is the source of truth: nodes carry `type/status/command/ran_at/user_input(verbatim)/note/artifacts[]/next[]/branch_of`; document-level `agents[]`; status `done|in_progress|blocked|known|assumed` (`assumed→known` at `/plan-3`); skill ships `references/flight-plan.template.{json,md}`. *(T006)*
- [x] **AC-17** — **Companion/worker affordance**: build-seam narration surfaces a default `code-review-companion` (via `/plan-6-companion`, supersedes `/plan-7`) + attaching other minih agents (companion/worker); recorded in `agents[]` (companion→wrap, worker→side-node); the-flow narrates+tracks but doesn't run minih; all optional. *(T002, T006)*
- [x] **AC-14** — **Optional branches = light mentions**: deep-research (tool of choice) at `awaiting-1a`, plus `/plan-3a`/prework/fix-loop/domains/`/util-0-handover` surfaced as one-line optional mentions, not stages. *(T002)*
- [x] **AC-18** — **Mid-plan adoption (late-join)**: `/the-flow` with no active state but an artifact-bearing plan folder back-fills state + `the-flow.json/.md` + `original-ask.md` (best-effort) per the **§ Adoption Contract** and resumes from the user's actual position as a confirmable suggestion, with no-clobber safety, never re-running/overwriting completed work. Third entry path (fresh/resume/adopt). *(T007, T001, T005)*
- [x] **AC-19** — **Ships flight-plan schema + samples**: `references/flight-plan.schema.json` encodes the **full** node + `agents[]` field set from workshop 002 § JSON contract (incl. required `id`) so `sample-the-flow.json` validates against it; ships alongside `flight-plan.template.{json,md}` and `sample-the-flow.{json,md}`; docs/standardisation only, `$comment`-marked reference-only, hand-validated (no runtime validator — OOS). *(T006, T005)*
- [x] **AC-20** — **Agent self-mirroring + re-entry reminder**: each narration turn instructs the coding agent to mirror the flow in its own todo list (one todo per upcoming stage / current phase, synced to the rail) and to re-invoke `/the-flow` after every `/compact` and on any fresh session; the `/compact` copy + resume handshake both carry the reminder. *(T002, T005)*

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Confusion / slug collision with `sdd-tutorial` | Low | Medium | Distinct slug + description + explicit body line; catalog row states it; `check-skill-slugs.sh` in T005. |
| Drift into reimplementing the pipeline's auto-chaining | Medium | Medium | Finding 01 + invariant: narration only reads artifacts + re-frames each skill's own `Next step` line. |
| Re-entry double-advances / loses place after `/compact` | Low | High | Idempotency rule (T001) + the dry-run re-entry-after-compact sim (T005), per workshop §Resume Handshake. |
| Over-prompting `/compact` | Low | Low | Suggest only at the 4 canonical seams, always phrased optional (T002). |
| Stale narration if a pipeline skill is renamed | Low | Low | Reference current names; vocab frozen per plan-024; low-frequency, accepted. |
| Adoption mis-infers stage / clobbers in-flight work | Medium | High | Artifact→stage inference is read-only; adoption writes **only** the-flow bookkeeping files (state, `the-flow.json/.md`, `original-ask.md`) and never re-runs a stage or touches spec/plan/tasks; verified by the T005 adoption dry-run on a real plan folder. |

## Agent Harness Strategy

Not applicable (user override — `the-flow` is a prose skill with no running software to Boot/Interact/Observe; recorded in spec `## Clarifications`). The skill *narrates* the harness loop but neither builds nor depends on one.

---

## Validation Record (2026-05-29)

### Validation Thesis

**Raison d'être**: A single re-entrant front-door that walks a user through the `plan-*` SDD pipeline — narrating each stage, surfacing optional branches (`/plan-2c`, `/plan-2d`) and `/compact` seams, and surviving compaction via durable on-disk state.

**Value claim**: A newcomer needs zero knowledge of which command comes next; the design is pre-resolved (workshop 001) so implementation is transcription, not design.

**Artifact promise**: `/plan-6` can implement the skill directly from this plan with no further design.

**Intended beneficiaries**: Newcomers to the pipeline (human or agent); the implementer at `/plan-6`.

**Proof target**: Implementation.

**Evidence standard**: Tasks that transcribe the authoritative workshop; measurable ACs; faithfulness to the resolved decisions (drive model A, state contract, idempotency, `.disabled` honour).

**Thesis source**: `the-flow-spec.md` (Goals/Non-Goals) + `workshops/001` (D0–D4) + `research-dossier.md` (Critical 01/02/03).

**Thesis verdict**: Advanced.

**Main thesis risk**: The Option-A "never invokes `/plan-*` itself" constraint previously lived only in prose — now an explicit invariant + AC (fixed this run).

---

| Agent | Lenses Covered | Thesis Axes Covered | Issues | Verdict |
|-------|---------------|---------------------|--------|---------|
| Coherence/Completeness | Coherence, Completeness, Hidden Assumptions, Edge Cases, Concept Docs, CS-challenge | Implementation Readiness, Proof-Level Fit | 1 MEDIUM fixed | ✅ |
| Thesis/Risk | Thesis Alignment, Evidence Sufficiency, Proof-Level Fit, Risk, Non-goal creep | Thesis Alignment, Evidence Sufficiency | 1 MEDIUM + 4 LOW fixed/accepted | ✅ |
| Forward-Compatibility | Forward-Compatibility (5 modes), Integration & Ripple, Domain Boundaries, Deployment/Ops | Downstream Usefulness, Contract Integrity | 3 MEDIUM (test-boundary) fixed | ⚠️→✅ |

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| `/plan-6` (Simple-mode implementer) | Unambiguous task table covering all of workshop 001 | contract drift | ✅ | *(superseded — now 7 tasks / 20 ACs; see 2026-05-30 Addendum)* spine tasks map 1:1 to the 11 workshop deliverables |
| Workshop 001 (authoritative contract) | State contract, 11-stage routing table, 11 narration blocks, `/compact` handshake, fresh-start ordinal, resume discovery, idempotency, harness cues, invariants, drive model A, single-terminal | contract drift | ✅ | All present and task-owned; no drift |
| `check-skill-slugs.sh` / `npx skills` | Unique `the-flow` slug | shape mismatch | ✅ | Slug unique; distinction from `sdd-tutorial` in description + body + catalog; checked in T005 |
| T005 Lightweight test | Can exercise idempotency + `.disabled` + invariants | test boundary | ✅ (fixed) | T005 Done-When now specifies the two-branch idempotency test, `.disabled` silencing check, and invariants-block read |

**Thesis alignment**: Value claim advanced at the Implementation proof target; evidence strong (faithful transcription of an authoritative, Implementation-Ready workshop); the one prose-only invariant is now explicit.

**Outcome alignment**: This plan, as written (with fixes applied), carries the workshop's authoritative contract into a clear 5-task table that advances the VPO outcome — *"a single front-door into the plan-* pipeline that requires zero prior knowledge of which command comes next."*

**Standalone?**: No — downstream consumer `/plan-6` (Simple mode) exists and consumes this plan directly.

Overall: ⚠️ VALIDATED WITH FIXES

---

### Rebuild Addendum (2026-05-30)

Plan rebuilt via `/plan-3-v3-architect`. Scope grew since the 2026-05-29 validation:

- **+T006 schema** — the skill now ships `references/flight-plan.schema.json` (the DAG contract) alongside the templates/samples (**AC-19**; user: "skill should include sample schema too").
- **+T007 mid-plan adoption** — a third entry path (fresh / resume / **adopt**): late-join an in-flight plan by back-filling state + `the-flow.json/.md` + `original-ask.md` from existing artifacts, then continuing — never re-running/overwriting completed work (**AC-18**, Finding 07; user: "should also be able to be run part way through a plan cycle … sort it out … then continue").

Now **7 tasks / 20 ACs** (AC-20 added below). Gate Matrix re-run: G1 PASS, G2/G3/G4 N/A, G5/G6/G7 PASS → **Status remains READY**. The forward-compat row "5 tasks / 11 ACs" above is superseded; the 1:1 spine mapping still holds (T006/T007 extend it).

### `/validate-v2` Re-Run (2026-05-30, 3 parallel agents — narrow plan scope)

Ran after the rebuild to cover the adoption + schema surface the prior validation predated. Convergent findings + fixes applied this turn:

| Finding (agent consensus) | Severity | Fix applied |
|---|---|---|
| Adoption (T007/AC-18) framed as "transcription" but **no workshop design**; edge cases (partial-phase stage, no-arg multi-folder, spec-only mode, adopted-node `ran_at`/`user_input`) unspecified | HIGH | Added the **§ Adoption Contract** (front-loaded design: trigger, folder resolution, full artifact→stage inference table, mode/rail, back-fill field handling); dropped the "transcription" framing for T007 in Summary. |
| Adoption back-fill could **clobber** a hand-driven folder; "never overwrite" was prose-only | HIGH/MED | Concrete no-clobber rules: `original-ask.reconstructed.md` fallback; merge-not-overwrite `the-flow.json`; inferred stage is a **confirmable suggestion**. Risk row + AC-18/spec updated. |
| Schema field-set (AC-16/AC-19) **omitted required `id`** + `phase/iterations/tool/runtime/note` → builder ships a schema that rejects the sample | HIGH/FAIL | AC-16/AC-19 + T006 now point at **workshop 002 § JSON contract as normative**, list the full field set, and require `sample-the-flow.json` to validate. |
| Schema pull-forward **reverses workshop 002 Q1** (which deferred it) without recording it | MED | AC-19 + T006 state it's a deliberate pull-forward (validator still OOS); schema file carries a `$comment` marking it reference-only. |
| T005 never actually **tested** the schema (AC-19) | RISK | Added a T005 schema-existence + sample-validation step. |
| Finding 07 "survey shows ad-hoc" unsupported | LOW | Softened to a stated assumption + cited `references/real-flow-examples.md`. |
| Stale "5 tasks / 11 ACs" in the embedded forward-compat row | LOW | Marked superseded. |
| CS-3 borderline (adoption adds inferential D/N surface) | — | Agents concur CS-3 **holds** (D 2→3, P→8, still CS-3); the design is now front-loaded in § Adoption Contract, honouring the spec's Simple-mode justification. |

Lifecycle-ownership (the-flow never runs minih), contract-drift vs workshops/samples, and the best-effort/no-gate invariant all **PASS**. New ask folded in: **AC-20** (agent mirrors the flow in its todos + re-invokes `/the-flow` after `/compact`).

**Post-fix verdict**: ✅ **VALIDATED** — Status READY; buildable by `/plan-6` (adoption design + schema field set now explicit in-plan).
