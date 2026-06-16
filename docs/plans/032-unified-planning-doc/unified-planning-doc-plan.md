# Unified Planning Document Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-06-16
**Spec**: [unified-planning-doc-spec.md](./unified-planning-doc-spec.md)
**Workshop (authoritative)**: [workshops/001-routing-seam-registry.md](./workshops/001-routing-seam-registry.md)
**Status**: READY

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No critical `[NEEDS CLARIFICATION]` remain; OQ1/OQ2 + AC-05 markers frozen in workshop 001 (Contract Ready) |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` in this repo |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md`. The governing constraint is the flow-architecture **pattern + lint** (`just check-flow`), honoured throughout and verified in T009 — not a project-rules gate |
| G4 | ADR Compliance | N/A | No `docs/adr/` directory |
| G5 | Structure | PASS | All required Simple-mode sections present and populated |
| G6 | Testing Alignment | PASS | Manual strategy → per-task Done-When + a dedicated verification task (T009); acceptance criteria are observable |
| G7 | Domain Completeness | PASS | No `docs/domains/` registry; sole domain `the-flow` present in Target Domains + Domain Manifest covers every touched file |

## Summary

Merge `the-flow`'s two planning stages — `1b specify` (writes `<slug>-spec.md`) and `3 architect` (writes `<slug>-plan.md`) — into **one flow-blind, atomic planning verb `1b plan`** (no modes, no flag) that **always writes both halves in one run**, producing **one canonical `<slug>-plan.md`** (a `## Business Specification` half on top, a `## Implementation Plan` half below). The verb's module is the renamed `references/stages/20-plan.md` (was `20-specify.md`); `30-architect.md` folds in as the implementation half and is deleted. Routing re-maps deterministically — old `awaiting-1b` **and** `awaiting-3` collapse into **one** `awaiting-1b` (plan done) — on exact disk markers + durable state; the workshop/backpressure seam survives as a flow-owned **post-plan refinement offer** (run an excursion, then re-run `plan` to fold it in; no offer when dormant); old state files / legacy split folders keep resolving with no migration machinery. Verified by `just check-flow` + `scripts/check-skill-slugs.sh` + a manual routing walk, then deployed via `just install-skills-from-source`.

## Target Domains

> This repo has **no `docs/domains/` registry** (skills + dev-tooling repo). The single touched area is the `the-flow` skill (+ two contributor docs). The tables here are the whole context.

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| `the-flow` (skill: `skills/SDD/the-flow`) | existing | **modify** | Merge the two planning sub-skills; re-map Registry/Graph/coach/getting-started; add downstream spec-source fallback; keep flow-blind + lint-clean |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/the-flow/references/stages/20-plan.md` | the-flow | internal (sub-skill) | Renamed from `20-specify.md`; becomes the merged atomic `plan` verb (business + implementation halves, one pass) |
| `skills/SDD/the-flow/references/stages/30-architect.md` | the-flow | internal (sub-skill) | **Deleted** after its content folds into `20-plan.md` |
| `skills/SDD/the-flow/SKILL.md` | the-flow | contract | Registry collapses to one planning row; alias/grammar updated |
| `skills/SDD/the-flow/references/00-routing.md` | the-flow | contract | Graph state re-map (one `awaiting-1b`) + exact markers + seam-live/post-plan-offer decoration + state contract |
| `skills/SDD/the-flow/references/coach.md` | the-flow | internal | Rail collapse + render-edge slots + adoption table |
| `skills/SDD/the-flow/references/getting-started.md` | the-flow | rendered view | Regenerate against updated masters (banner-marked) |
| `skills/SDD/the-flow/references/stages/25-workshop.md` | the-flow | internal | Downstream reader — unified-plan business-source + legacy fallback |
| `skills/SDD/the-flow/references/stages/35-adr.md` | the-flow | internal | Downstream reader — `--spec` accepts unified plan or legacy spec |
| `skills/SDD/the-flow/references/stages/70-review.md` | the-flow | internal | Downstream reader — business-source fallback |
| `skills/SDD/the-flow/references/stages/80-merge.md` | the-flow | internal | Downstream reader — plan-folder detection + business-source fallback |
| `skills/SDD/the-flow/references/stages/50-phase-tasks.md` | the-flow | internal | Reads spec AC/domain fields — fallback |
| `skills/SDD/the-flow/references/stages/60-implement.md` | the-flow | internal | Reads spec AC/domain fields — fallback |
| `skills/SDD/the-flow/references/stages/20-specify.md` | the-flow | internal (sub-skill) | **Deleted** — renamed to `20-plan.md` (old path removed from disk) |
| `skills/SDD/the-flow/references/flight-plan.template.json` | the-flow | internal (worked example) | T009 — collapse the retired spec→plan two-node example to one unified `1b plan` node |
| `skills/SDD/the-flow/references/flight-plan.template.md` | the-flow | rendered view | T009 — same collapse in the rendered example view |
| `skills/SDD/the-flow/references/flight-plan.schema.json` | the-flow | contract | T009 — fix the stale `/the-flow 3 architect` example in the node-type description |
| `docs/skills-pipeline/flow-architecture.md` | docs | doc | Reflect one planning stage producing one document |
| `CLAUDE.md` | docs | doc | `the-flow` contributor section: stage list + Registry description + consolidation history note |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | **L4 closure has TWO dimensions, both can fail mid-sequence.** (a) Module-path closure — `check-flow-architecture.sh:283` (`if [[ ! -f … ]]`, err `:284`) errors if a Registry module path has no file on disk; discovery is `find … -maxdepth 1` (`:78`). (b) **Graph-edge-verb closure — `:293`**: every `**bold**` verb named in a Graph edge must exist in the Registry. So the instant T003 renames the Registry verbs `specify`/`architect`→`plan`, the still-unmodified Graph edges naming `**specify**`/`**architect**` dangle and **L4 fails at `:293`** — independent of the `30-architect.md` delete. **T003 (Registry) and T004 (Graph) are lint-coupled: no intermediate `just check-flow` is green between them.** | Rename `20-specify.md`→`20-plan.md` and repoint the **single** Registry row **before** `git rm 30-architect.md`; land T003 **and** T004 together before any lint run; run `just check-flow` only at T009. |
| 02 | Critical | **Graph/coach name verbs in render-edge slots** — `00-routing.md:109–112` and `coach.md:171–199` reference `**architect**`/`**specify**` by name; slots expand via Registry lookup, so a rename breaks narration anywhere a slot/edge still names the old verb. | T004/T005 update **every** Graph edge + render-edge slot + must-see row to the single new state (`awaiting-1b`) and verb (`plan`). |
| 03 | High | **`getting-started.md` is banner-checked, not content-checked** — L5 only verifies the first-line banner exists (view-select `:305`, err `:328`); stale commands/paths pass the lint silently (`getting-started.md:1,26,28,146,150`). | T007 regenerates it **by hand against the updated Registry + Graph** (it's a rendered view; never hand-edit as primary). Not lint-gated → explicit task so it isn't missed. |
| 04 | High | **Downstream `<slug>-spec.md` reads are not all content reads — two are abort gates.** Content reads (add fallback): `25-workshop.md:9,193`; `70-review.md:44,55`; `35-adr.md` cross-link templates `:290,310`; plus AC/domain readers `50-phase-tasks.md`, `60-implement.md` (read the *plan*, only cosmetic spec mentions). **Abort/detection logic (must be rewritten, not just repointed):** `80-merge.md:10` (`**Consumes**: contains `*-spec.md``), `:49` (auto-detect "look for `*-spec.md`"), `:69` (validate folder "contains `*-spec.md`") — a unified folder has **no** `*-spec.md`, so merge **aborts before any content read**; and `35-adr.md:9,37,42` — `--spec` is **REQUIRED, "abort if missing"**. | T006 splits the work: (i) content readers get read-`## Business Specification`-then-fall-back-to-`<slug>-spec.md`; (ii) **merge's folder-detection predicate** (`:10,49,69`) changes to "contains `*-plan.md` (or legacy `*-spec.md`)"; (iii) **adr's `--spec` abort gate** relaxes to accept the unified `<slug>-plan.md` (the flow passes `--spec <plan.md>`), with subagent spec-reads + cross-links repointed (AC-07). |
| 05 | High | **Merged module must stay one flow-blind depth-1 file, and keep the L2 contract surface.** L1 leakage grep fails on stage ids / successor names / `/the-flow` commands in a sub-skill (`:144` exempts only `**Delegates**`); discovery is maxdepth-1 (spec Non-Goal: no `stages/plan/*` sub-tree). **L2 (`:166`) requires exactly these labels — `**Verb** **Purpose** **Consumes** **Flags** **Produces** **Side effects**` — plus the constant Exit line** (`20-specify.md:316` — "Routing is the flow's job…"). `**Delegates**` is NOT L2-required (it's the optional L1-exemption token). | T001 keeps `20-plan.md` a single file emitting all **six** L2 labels + the verbatim Exit line; flow-blind (no stage ids / "next step" prose); `**Side effects**: auto-runs /validate-v2`. `**Delegates**: none` optional. |
| 06 | Medium | **Mode detection was split across the two stages** — `specify` set `mode` from Round-1; `architect` recomputed `milestones_total` (`00-routing.md:80,83`). One atomic verb now owns both. | T001/T002 set `mode` from Round-1 (state write owned by guided mode) and recompute the collapsed rail (Full 7→**6**, Simple ~4) — all in the one atomic `plan` pass; no second pass to re-read it. |

## Implementation

**Objective**: Collapse `specify` + `architect` into one flow-blind `1b plan` verb producing one `<slug>-plan.md`, with deterministic routing, the seam preserved-when-live, a green lint, and back-compat for old state files + legacy folders.
**Testing Approach**: **Manual** — run the two lints + a by-hand routing walk (no runtime code; skill markdown + JSON). Each task carries an observable Done-When; T009 is the consolidated verification + deploy.

> **Note on `--simple` / mode**: this Simple-mode build is **one chunky phase** (CS-3, deliberate user override). The task list below is the single phase's inline 7-column table per the architect Simple format.

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | **Build the merged module — business-spec half of the atomic verb.** `git mv` `20-specify.md`→`20-plan.md`. Set the contract block with all **six L2-required labels** — `**Verb**: plan` · `**Purpose**` · `**Consumes**: intent, dossier?, workshops?, coverage?` · `**Flags**: [--simple] [--skip-clarify]` · `**Produces**: <slug>-plan.md (both halves)` · `**Side effects**: auto-runs /validate-v2` — and **preserve the verbatim Exit line** ("Routing is the flow's job — run the parent flow bare to continue."). (`**Delegates**: none` optional — not L2-required.) **No `--implementation` flag.** Keep the full Round-1 (Workflow Mode/Testing/Mock/Docs) + conditional Round-2 (Domain Review, topic clarifications) + § Re-entry (re-running `plan` regenerates both halves). The verb writes the **single-status top-metadata block** (`**Status**: READY \| DRAFT — UNRESOLVED GAPS` — no Business/Implementation split, no STALE) + `## Business Specification` + `## Planning Seam` (workshop Decisions 1, 2, 7 revised). | the-flow | `references/stages/20-plan.md` | File exists at new path; six L2 labels (flags omit `--implementation`) + Exit line present; contract block flow-blind (no stage ids/successors/flow commands); full question set present; emits the exact markers `^# <title>` + `^**Status**` + `^## Business Specification` + `## Planning Seam` | Per findings 05, 06. Workshop Decision 1 (revised) Registry row is the source for the contract block |
| [x] | T002 | **Fold architect into the same atomic verb — implementation-plan half; delete `30-architect.md`.** In the *same* `plan` run (no second command, no flag), after the business section, transcribe 30-architect's PHASE 0–4 faithfully (PHASE 0 mode/domain/harness/ADR loading; PHASE 1 gates G1–G4; PHASE 2 the 2 research subagents; PHASE 3 phases + Per-Phase/Simple task tables + Output Contract; PHASE 4 G5–G7 + Gate Matrix + Status + emit) so the verb **appends** `## Implementation Plan` and sets the single `**Status**: READY \| DRAFT — UNRESOLVED GAPS`; include the **Acceptance Coverage Map** (tasks→AC-ids); recompute `milestones_total`; keep the validate-v2 auto-run at the end of the one pass. Then `git rm 30-architect.md`. | the-flow | `references/stages/20-plan.md`, `references/stages/30-architect.md` (delete) | Impl half present in `20-plan.md` as part of the one atomic pass; all of G1–G7 + the 2 subagents + validate-v2 auto-run survive (dry-read vs the deleted file); Acceptance Coverage Map included; `30-architect.md` removed | Per findings 01, 06. **Ordering: T001→T003+T004→then delete here**; both L4 dimensions (`:283` module path + `:293` edge-verb) satisfied before any lint run (T009) |
| [x] | T003 | **Registry + grammar + alias (SKILL.md).** Replace the two Registry rows (`1b specify`@36, `3 architect`@38) with the single `1b plan` row (workshop Decision 1 revised — flags `[--simple] [--skip-clarify]`, **no `--implementation`**). Update the alias table (60/61/63): `plan-1b-v3-specify-and-clarify → 1b plan`; `plan-2-v2-clarify → 1b plan` (§ Re-entry); `plan-3-v3-architect → 1b plan`; add typed `specify → 1b plan`, typed `architect` / id `3 → 1b plan`. Leave `3a adr` as-is (documented minor wart). | the-flow | `SKILL.md` | One planning Registry row pointing at `references/stages/20-plan.md` (no `--implementation` flag); alias rows resolve old slugs **and** direct-jump `/the-flow 3 architect` → `1b plan` | Per findings 01, 02. Workshop Decision 8 (revised) alias table. **Lint-coupled with T004**: renaming the Registry verbs here makes every Graph edge naming `**specify**`/`**architect**` dangle (L4 `:293`) — T004 must land in the same batch before T009 lints |
| [x] | T004 | **Graph + state contract + must-see (00-routing.md).** Collapse old `awaiting-1b` **and** `awaiting-3` into **one** `awaiting-1b` (plan done — both halves written by atomic `plan`): edges DRAFT→fix+re-run `plan` (stay) · Simple+READY→**implement** · Full+READY→**tasks** · opt-when-live: **workshop** / post-spec backpressure → re-run `plan` to fold in. **Also rename the upstream edges that name `**specify**`**: `start` (`:107` `clear → **specify**`) and `awaiting-1a` (`:108` `→ **specify**`) → `**plan**` — else L4 `:293` fails. Keep `awaiting-2c`/`awaiting-backpressure` hanging off `awaiting-1b` as post-plan refinements. Add the exact disk-marker predicates (Decision 2 revised — single `Status`, `## Implementation Plan`=written, `## Business Specification`=unified; **no NOT PLANNED / STALE**) + the **seam-live predicate** as an edge decoration (flow-owned, **no auto-advance / no between-passes pause**). Add read-time translation: old `awaiting-1b` **and** `awaiting-3` → the single `awaiting-1b`. Update the **ADOPT entry-path artifact list** (`:19`, still leads with `*-spec.md` → add `*-plan.md` recognition), must-see rows (126–128), and the state contract (mode set during the `plan` pass; `milestones_total` Full=**6**). | the-flow | `references/00-routing.md` | Every Graph edge (incl. `start`/`awaiting-1a`) names a Registry verb (L4 `:293` green); the single new state + exact markers present; seam is a post-plan offer (sub-skill stays flow-blind); old `awaiting-1b`/`awaiting-3` both translate at read time to `awaiting-1b`; entry-path recognises a unified `*-plan.md`; milestones reflect 6/4 | Per findings 01, 02, 06. Workshop Decisions 2, 3, 4, 6 (all revised) |
| [x] | T005 | **Coach (coach.md).** Collapse the rail: `Spec`+`Plan` macro-milestones → one **`plan`** pip — Full `Research · Plan · Tasks · Build · Review · Merge` (6), Simple `Plan · Build · Review · Merge` (~4); the pip fills when `plan` writes the document (both halves at once). Update the stage→pip map (64–66), **the pre-171 `start`/`awaiting-1a` narration slots** plus the render-edge slots + narration section headers (171–199) to the single new state (`awaiting-1b`) / verb (`plan`), the **adoption contract table (~274–285)** per Decision 5 (revised), and optional-branch mentions (237–238) → reframe the seam as a **post-plan refinement offer** (no auto-advance, no "second pass"). **Three specifics**: (a) legacy **spec-only** maps to **`awaiting-1b`** with pending `plan`; (b) the post-plan refinement offer is **assertive** when ≥1 `## Workshop Opportunities` row is still unworkshopped — the coach beat names how many topics the phases were designed without and recommends workshop + re-plan *before building* (not a passive checklist), closing the "offer-lands-after-a-finished-plan" discoverability gap (workshop Decision 1 "Accepted costs"); (c) fix `coach.md:283` — the stale "stays the 7-milestone estimate until **stage 30** recomputes" → "until the **`plan`** pass recomputes" (and 7→6). | the-flow | `references/coach.md` | Rail shows the single collapsed plan pip at correct n/total; every render-edge slot (incl. `start`/`awaiting-1a`) references the valid `awaiting-1b` state + the `plan` verb; the seam-live beat is assertive (names the unworkshopped-topic count) when opportunities are pending; adoption table covers all four shapes (legacy-spec-only → `awaiting-1b` pending `plan`); no stale "stage 30"/"7-milestone"/"auto-advance"/"--implementation" text remains | Per finding 02 + Revision Validation. Workshop Decisions 1, 3, 5 (revised) |
| [x] | T006 | **Downstream spec-source fallback (AC-07) — THREE distinct edit kinds.** **(i) Content reads** — `25-workshop.md` (9,193), `70-review.md` (44,55), the AC/domain readers `50-phase-tasks.md` + `60-implement.md` (+ `60-implement.md:303` cosmetic spec path): change "read `<slug>-spec.md`" to "read the `## Business Specification` section of the unified `<slug>-plan.md` when present, **fall back** to a sibling `<slug>-spec.md` (legacy split folders)." **(ii) Merge folder-detection/abort gate** — `80-merge.md` `**Consumes**` (:10), auto-detect (:49), validate (:69): the plan-folder predicate currently aborts if the folder lacks `*-spec.md`; change it to **"folder resolvable if it contains `*-plan.md` (or legacy `*-spec.md`)"** so a unified folder doesn't abort; then the business-source reads (:135,246,299) get the (i) fallback. **(iii) adr `--spec` REQUIRED-or-abort** — `35-adr.md` (:9,37,42): relax the abort gate to accept a unified `<slug>-plan.md` passed as `--spec` (the flow supplies `--spec <plan.md>`); repoint the subagent spec-section reads + cross-link templates (:290,310). Keep every module flow-blind. | the-flow | `references/stages/{25-workshop,35-adr,70-review,80-merge,50-phase-tasks,60-implement}.md` | Content readers resolve business source from the unified plan w/ legacy fallback; **merge does NOT abort on a unified (no-`*-spec.md`) folder**; **adr does NOT abort on a unified plan**; dry-read confirms no module hard-requires a standalone spec for a unified plan | Per finding 04. AC-07. The merge/adr gates are the genuine downstream breaks — repoint the *detection/abort logic*, not just the content reads |
| [x] | T007 | **Regenerate getting-started.md.** Against the updated Registry + Graph (banner intact, never hand-edit as primary): stage table (26,28) → one planning row `1b plan`; legacy list (36); Simple example (146) → `/the-flow 1b plan` → `/the-flow 6 implement` (one planning command, both halves); merged-stages note (150); harness quick-ref (205); mode-assignment text (123,243). | the-flow | `references/getting-started.md` | Shows one planning stage + the new commands; `<!-- 🔄 RENDERED … -->` banner present; content matches the SKILL.md/00-routing.md masters | Per finding 03. Not lint-gated — explicit regeneration |
| [x] | T008 | **Docs sweep.** `docs/skills-pipeline/flow-architecture.md` → reflect one planning stage producing one document (any specify/architect stage-list example). `CLAUDE.md` → `the-flow` contributor section: stage list + Registry description (one planning row) + a one-line consolidation history note (plan-032). | docs | `docs/skills-pipeline/flow-architecture.md`, `CLAUDE.md` | Both docs describe one planning stage; no stale "`1b specify` + `3 architect`" two-stage description in contributor docs | AC-09. `AGENTS.md` is a symlink — never edit directly |
| [x] | T009 | **Verify (manual) + deploy.** Run `just check-flow` (exit 0, L1–L6 — both L4 dimensions) and `scripts/check-skill-slugs.sh` (exit 0). Dry-read `20-plan.md`: full question set + six L2 labels + Exit line + G1–G7 + validate-v2 survive. Routing walk by hand — **Simple**: fresh → `plan` (writes both halves) → (seam dormant → no offer) → implement; resume re-prints the right pending step. **Full**: impl pass reveals multiple phases + rail re-scales; resume mid-build works. **Integration replays (not just happy path)**: (a) drop a synthetic old `.the-flow-state.json` with `current_stage: awaiting-3` + `pending_command: /the-flow 3 architect` → confirm read-time translation routes to the single `awaiting-1b` without advancing; (b) **dry-run `merge` against a unified (no-`*-spec.md`) folder → confirm it resolves the folder, does not abort**; (c) direct-jump `/the-flow 3 architect` → resolves to `1b plan`. `rg "<slug>-spec\|SPEC_FILE\|FEATURE_SPEC\|awaiting-3\|30-architect\|plan-3-v3"` across `skills/SDD/the-flow/` — classify every hit (legacy-fallback intended / business-section read / obsolete). Adoption check: all four shapes (unified business-only, unified both, legacy spec-only, legacy spec+plan) infer the right next step; `git status` clean under historical `docs/plans/0NN-*`. Deploy `just install-skills-from-source`. | the-flow | (whole skill) | Both lints exit 0; both routing walks + the three integration replays + resume pass; merge does not abort on a unified folder; `rg` sweep shows only intended legacy-fallback/alias hits; all four adoption shapes infer correctly; legacy folders byte-untouched; deployed to canonical store | AC-06, AC-08. Final task |

### Acceptance Coverage Map

| AC | Covered by | Verified in |
|----|-----------|-------------|
| AC-01 — one artifact (`<slug>-plan.md`, no `<slug>-spec.md`) | T001, T002 | T009 dry-read + adoption check |
| AC-02 — one doc, two halves + single-status metadata + Planning Seam + Acceptance Coverage Map, in order | T001 (single-status metadata + Business Spec + Planning Seam), T002 (Impl Plan + Coverage Map) | T009 dry-read |
| AC-03 — no question dropped + G1–G7 + validate-v2 survive | T001 (question set), T002 (gates + validate-v2) | T009 dry-read |
| AC-04 — refinement seam only when live (dormant → straight to implement) | T004 (seam-live predicate, post-plan offer, Graph), T005 (coach narration) | T009 Simple/Full routing walk |
| AC-05 — deterministic routing/resume (exact markers + durable state) | T004 (markers + state predicates + read-time translation) | T009 routing walk + state inspection |
| AC-06 — lint green (`just check-flow` + slug check) | T001, T003 (L4 ordering) | T009 |
| AC-07 — downstream reads unified plan + legacy fallback (incl. merge folder-detection + adr `--spec` abort gates) | T006 (i content reads, ii merge detection, iii adr gate) | T009 dry-read of each module + merge-on-unified-folder replay |
| AC-08 — no over-built migration (legacy untouched, both shapes adopt) | T004/T005 (adoption recognizes both; no migration machinery) | T009 adoption check + `git status` clean under old plan folders |
| AC-09 — Registry + docs reflect one stage | T003 (Registry+alias), T007 (getting-started), T008 (flow-architecture + CLAUDE.md) | T009 + diff review |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| L4's **two** closure dimensions (`:283` module path, `:293` edge-verb) fail at different moments — renaming the Registry verb (T003) dangles every Graph edge until T004 lands | Medium | Low (caught at T009 lint) | T003 + T004 land as one batch; no `just check-flow` runs between them; lint only at T009 (finding 01) |
| **merge / adr abort on a unified (no-`*-spec.md`) folder** — their spec refs are detection/abort gates, not content reads | Medium | **High** (a unified flow can't reach merge or adr) | T006 (ii) rewrites merge's folder predicate to `*-plan.md`-or-legacy; T006 (iii) relaxes adr's `--spec` gate; T009 replays merge-on-unified-folder (finding 04) |
| A render-edge slot or Graph edge keeps an old verb/state name → narration error / L4 `:293` | Medium | Medium | T004/T005 sweep **every** slot + edge (incl. `start`/`awaiting-1a`) + must-see row; T009 routing walk exercises each seam (finding 02) |
| `getting-started.md` left stale (lint won't catch) | Medium | Low | Dedicated regeneration task T007 against masters; banner reasserted |
| One-file routing marker misfires on a hand-edited heading | Low | Low | Durable `.the-flow-state.json` is **primary**; exact-string marker is the resume fallback, not sole source (spec R1) |
| Merged sub-skill leaks a stage id / "next step" → L1 failure | Low | Medium | Keep `20-plan.md` flow-blind; the seam decision lives in the Graph, not the module (spec R3/R5; finding 05) |
| Simple-mode single phase sprawls (borderline CS-4) | Low | Low | One well-scoped phase; the implementation half escalates to Full only if genuine multi-phase structure emerges (spec R4) |
| External post-spec router expects a spec-shaped `--spec` file | Low (latent) | Low | Unified doc keeps a `## Business Specification` section the router can scope to; repo unprovisioned → seam noops (spec R2/A3) |

## Harness Seams

- **Entry point**: `/eng-harness-flow --event <seam> [--phase <id>] [--plan-dir <p>] --json` — the single door; child skills are private and never named here.
- **Posture for this build**: the router **is installed** (`~/.agents/skills/eng-harness-flow/SKILL.md`) but **this repo is unprovisioned** (no `.harness/`, no governance doc) → every seam **noops calmly**. No `backpressure-coverage.md` was produced and **no per-task `N.0`/`N.z` harness rows are added** to the single phase — they would only noop. Standard **Manual** verification (T009) applies.
- **Best-effort**: advisory, never blocks, no scores — consistent with the flow's invariants.

_(No `## Unresolved Gaps` — all gates PASS or N/A.)_

---

## Validation Record (2026-06-16) — pre-simplification snapshot (two-modes design)

> **Historical.** This record validated the *original* two-modes design (`plan` + `plan --implementation`). It was **superseded the same day** by the user's one-atomic-verb simplification; see **§ Revision Validation Record** below for the re-validation of the current design. The "rail 7→6 + auto-advance" phrasing in the Thesis row is a pre-simplification artifact (the atomic verb has no auto-advance).

Auto-run per the architect contract (`/validate-v2 --artifact <this plan>`), reinforced by the user ("then validate"). 4 parallel agents using the session model; thesis-aware (`--scope broad`).

**Validation Thesis** — *Raison d'être*: a buildable, on-pattern plan to merge `specify`+`architect` into one `1b plan` verb + one `<slug>-plan.md`, faithful to workshop 001, deterministic routing, green lint, no over-built migration. *Proof target*: Contract/Implementation. *Thesis verdict*: **Advanced** — value claim met; READY correctly assigned.

| Agent | Lens | Verdict | Issues |
|-------|------|---------|--------|
| Coherence & Completeness | task ordering, AC coverage, workshop fidelity, cross-refs | ⚠️→ fixed | ~90% complete; 1 HIGH (adr abort gate), 1 CRITICAL framing (L4 dual-dimension), 3 MEDIUM line/state corrections — **all applied** |
| Source-Truth | edit-site line refs + lint mechanism accuracy vs live files | ✅ | All load-bearing line refs + L4/L1/L5 claims CONFIRMED true; 2 soft corrections (L2 doesn't require `**Delegates**`; L5 err `:328`) — **applied** |
| Thesis Alignment | thesis drift, proxy, proof-level, non-goal creep | ✅ | READY correct; Actual proof = **Implementation**; Strong evidence; no drift/creep; "one step" mechanism (rail 7→6 + auto-advance) real |
| Forward-Compatibility | direct-jump, old state, downstream readers, legacy folders, router | ⚠️→ fixed | 1 HARD BREAK (merge folder-detection abort gate), 1 under-spec (adr `--spec`), test-boundary gaps — **all applied to T006 + T009** |

### Forward-Compatibility Matrix (post-fix)

| Consumer | Requirement | Verdict | Resolution |
|----------|-------------|---------|------------|
| Direct-jump `/the-flow 3 architect` | resolves to merged impl pass | ✓ | T003 alias + T009 replay (c) |
| Old `.the-flow-state.json` (`awaiting-3`) | read-time translation | ✓ | T004 translation + T009 replay (a) |
| `workshop` / `review` (content reads) | unified-or-legacy business source | ✓ | T006 (i) |
| **`merge` (folder-detection abort)** | resolve a unified no-`*-spec.md` folder | ✗→✓ | **T006 (ii)** predicate → `*-plan.md`-or-legacy; T009 replay (b) |
| **`adr` (`--spec` REQUIRED-or-abort)** | accept unified plan as `--spec` | ⚠️→✓ | **T006 (iii)** relax gate + repoint reads |
| `tasks` / `implement` | read plan (cosmetic spec mentions) | ✓ | T006 (i) |
| Legacy split folder | byte-untouched + adopt correctly | ✓ | T004/T005 Decision 5; T009 `git status` clean |
| External post-spec router (`--spec`) | scope to `## Business Specification` | ✓ (latent) | repo unprovisioned → noops |

**Applied fixes (CRITICAL/HIGH, mechanical + evidence-backed):** finding 01 (L4 two dimensions + T003/T004 coupling), finding 04 (merge/adr abort gates split out), finding 05 (six L2 labels + Exit line; `**Delegates**` optional), T001/T002/T003/T004/T005/T006/T009 + Risks + AC-07 map. **Surfaced, not applied (low/no-op):** L5 err line precision (cosmetic), 30-architect phase transcription fidelity (bounded by T002 Done-When + T009 dry-read).

**Overall: ⚠️ VALIDATED WITH FIXES → plan remains Status READY.** Thesis advanced, evidence Strong, the two genuine downstream breaks (merge + adr abort gates) closed in T006, integration replays added to T009. Buildable with no remaining design decisions.

---

## Revision Validation Record (2026-06-16) — one-atomic-verb simplification

**Trigger** — user (post-architect): *"for #4, just one verb, no more no less. its always both - business and impl, never one at a time … so no need for --implementation"*, then *"just do the fixes and run a validation skill pass."* The two-modes design (`plan` + `plan --implementation`) was simplified to **one atomic `plan` verb that always writes both halves**. The cascade was threaded through all three artifacts: workshop 001 (Decisions 1/2/3/4/5/6/7/8 revised), the spec (Non-Goal override + AC-02/04/05 + Goals/verification/Clarifications), and this plan (Summary, finding 06, T001–T005, T007, T009, AC-map, Domain Manifest).

**Re-validated** with `/validate-v2` — 3 parallel agents (session model, thesis-aware).

| Agent | Lens | Verdict | Issues |
|-------|------|---------|--------|
| Coherence & Consistency | cascade applied across plan+spec+workshop; no leftover two-pass language; cross-doc agreement; AC-map; lint-ordering | **Consistent** | 0 CRITICAL/HIGH; 1 MEDIUM (`spec.md:111` Workshop-Opportunities topic carried unmarked two-state/STALE/pause wording) — **fixed**; 3 LOW in dated/resolved blocks |
| Thesis Alignment | fidelity loss, the load-bearing "workshop-before-phases" question, non-goal creep, proof-level | **READY correct; Strong evidence** | Fidelity (full question set, G1–G7, validate-v2) preserved by construction. "Workshop-before-phases" = **Partially** preserved: outcome reachable via iterate-then-re-plan, but two real costs (a wasted first-pass phase-design+validate, and a weaker *after-the-plan* offer vs the old *before-architect* prompt). The plan over-sold it as full equivalence — **fixed** (named the cost; assertive offer added to T005) |
| Forward-Compat + Source-Truth | direct-jump, old-state translation, merge/adr abort gates, four-shape adoption, all load-bearing line refs vs LIVE files | **Compatible, Yes** | 0 CRITICAL/HIGH. Every consumer holds under one-verb; **every** load-bearing claim (L4 dual-dimension `:283`/`:293`, L2 six-label `:166`, Exit line `20-specify.md:316`, Registry/Graph/coach/merge/adr edit sites) **CONFIRMED byte-true** against the live skill. `--implementation`-drop provably safe (L2 checks label presence only) |

**Applied fixes (mechanical + grounded):**
- **MEDIUM** — `spec.md:111`: added a supersession note above § Workshop Opportunities (the originating topic statement carried unmarked "two maturity states / Business-Implementation Status / stale-marking / pause" wording).
- **LOW (thesis, substantive)** — named the accepted trade honestly (spec Non-Goal override + workshop Decision 1 "Accepted costs") instead of claiming full equivalence; added an **assertive post-plan offer** requirement to T005 (when ≥1 Workshop Opportunity is flagged-but-unworkshopped, the coach says "the plan designed phases without workshopping `<N>` topic(s) — workshop + re-plan before you build", not a passive checklist).
- **LOW** — marked the prior Validation Record as a pre-simplification snapshot (above).

**Surfaced, not applied (benign):** the resolved OQ2 body (`spec.md:105`, neutralized by the resolution note at `:102`) and the dated FC-matrix "two halves" (means two *sections*, not two passes).

**Overall: ⚠️ VALIDATED WITH FIXES → plan remains Status READY.** The simplification is internally consistent across all three docs, every load-bearing line ref is byte-true, fidelity is preserved, and the one honest caveat (workshop-before-phases is a soft trade, not free) is now named rather than papered over. Buildable as written, no remaining design decisions.
