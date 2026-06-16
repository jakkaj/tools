# Execution Log — unified-planning-doc (Phase: Implementation, Simple mode)

**Plan**: [unified-planning-doc-plan.md](./unified-planning-doc-plan.md) · **Mode**: Simple · **Testing**: Manual
**Started**: 2026-06-16

## Pre-implement harness seam (`--event pre-implement`)

- **Router**: installed (`~/.agents/skills/eng-harness-flow/SKILL.md` present).
- **Repo**: unprovisioned (no `.harness/`, no governance doc) → seam **noops calmly**.
- **Outcome**: `decision: noop` — no engineering harness substrate in this repo; proceeding with standard **Manual** verification (T009). The one-time warning already fired in earlier sessions; not re-warning. No per-task `N.0`/`N.z` harness rows (Simple mode, single phase; they would only noop).

Recorded once here per the implement contract §2a; no further harness touchpoints this phase.

---

## Tasks

| Task | Status | Notes |
|------|--------|-------|
| T001 | ✅ done | Wrote `references/stages/20-plan.md` (atomic `plan` verb, business-spec half — Part A). Six L2 labels present (`**Verb**: plan` · flags `"<intent>" [--simple] [--skip-clarify]`, **no `--implementation`**); verbatim Exit line; flow-blind (no `/the-flow N` literals, no "stage N"/"next steps"); single-status top-metadata; `## Business Specification` + `## Planning Seam` markers. Planning-Seam template uses verb-name prose (not `/the-flow 2c workshop` — that would trip L1's `/the-flow <digit>` grep). Removed superseded `20-specify.md`. |
| T002 | ✅ done | Folded architect into `20-plan.md` Part B (one atomic pass, no second command/flag): B0 mode/domain/harness/ADR, B1 gates G1–G4, B2 the 2 research subagents, B3 generate (Output Contract → `## Implementation Plan` with Gate Matrix/Domain Manifest/Key Findings/Phases or Implementation/**Acceptance Coverage Map**/Risks/Harness Seams), B4 G5–G7 + single `**Status**` + emit + **validate-v2 auto-run**. `### Target Domains` lives in the business half (= `SPEC_DOMAINS`); Part B reads it there. Deleted `30-architect.md`. |
| T003 | ✅ done | `SKILL.md`: two Registry rows (`1b specify`, `3 architect`) → one `1b plan` row → `references/stages/20-plan.md`, flags `"<intent>" [--simple] [--skip-clarify]` (no `--implementation`). Alias table: `plan-1b-*`/`plan-2-v2-clarify`/`plan-3-*` → `1b plan`; added typed `specify` and typed `architect`/id `3` → `1b plan` (direct-jump back-compat). Frontmatter description: stage list now `1b plan` (no `3 architect`), kept `specify`/`architect` as natural-language trigger words. |
| T004 | ✅ done | `00-routing.md`: Graph collapsed old `awaiting-1b`+`awaiting-3` → one `awaiting-1b` (plan done, both halves); `start`/`awaiting-1a` edges `specify`→`plan`; `awaiting-2c`/`awaiting-backpressure` reroute `architect`→`plan` (re-run, folds in) as post-plan refinements. **No `**specify**`/`**architect**` bold verbs left in any Graph edge (L4 `:293`).** Added a `## Routing markers & read-time state translation` section (single-status predicates; old `awaiting-1b`/`awaiting-3` → `awaiting-1b`) — placed as `##` so it cleanly closes the Graph section. Merged must-see `awaiting-1b`+`awaiting-3` rows. State contract: `mode`/`milestones_total` set during the `plan` pass, Full 7→6. Fixed flight-plan "stage 30" → "the `plan` pass"; entry-path leads with `*-plan.md`; harness Post-spec bullet + render rule 2 reframed (post-plan refinement). Also fixed Fresh-start `**specify**` edge → `**plan**`. |
| T005 | ✅ done | `coach.md`: rail collapsed Spec+Plan → one `plan` pip — Full `Research · Plan · Tasks · Build · Review · Merge` (6, was 7), stage→rail map rebuilt (`awaiting-1b` = 2/6 plan done; `awaiting-3` row removed), top rail example + now/next example + unified harness-rail example all reframed (plan written → tasks / post-plan backpressure refinement). **Merged the `awaiting-1b` (after spec) and `awaiting-3` (after plan) narration into one `awaiting-1b → after the plan` block**; deleted the standalone `awaiting-3` block. Added the **assertive post-plan offer**: when ≥1 Workshop Opportunity is unworkshopped the coach says so plainly (phases designed without those decisions → workshop + re-plan before building) — never a gate (workshop Decision 1 "Accepted costs"). `start`/`awaiting-1a` narration → `plan` edge; `awaiting-2c`/`awaiting-backpressure` → re-run `plan`; adoption table → Decision 5 (four shapes → `awaiting-1b`, legacy spec-only reads as business source); all `stage 30`/`7-milestone` → `plan` pass / 6. |
| T006 | ✅ done | Downstream business-source fallback (AC-07), three kinds. **(i) Content reads**: `25-workshop.md` (Consumes + "Read the business source"), `70-review.md` (both Full+Simple `SPEC =` lines) now read `<slug>-plan.md` § `## Business Specification` with a legacy `<slug>-spec.md` fallback. `50-phase-tasks.md`/`60-implement.md` confirmed to carry **no** spec refs (finding 04 "only cosmetic" — no edits). **(ii) Merge folder-detection/abort gate** (the High-impact break): `80-merge.md` `**Consumes**`, auto-detect, and validate predicates changed `*-spec.md` → `*-plan.md` (or legacy `*-spec.md`) so a unified folder no longer aborts; input-artifact list reads the plan's two sections. **(iii) adr `--spec` REQUIRED-or-abort**: `35-adr.md` Consumes/FEATURE_SPEC/pre-flight/cross-links/backlink relaxed to accept a unified `<slug>-plan.md` (business content under `## Business Specification`) or legacy spec. All edits flow-blind (no flow commands / stage ids added). |
| T007 | ✅ done | Regenerated `getting-started.md` (banner intact) against the updated masters: stage table → one `1b plan` row (architect row removed); "what changed" history note + merged-stages note; big-picture mermaid (SPECIFY subgraph → PLAN, P1B = `1b plan`, P3 removed, edges rerouted: workshop/backpressure → re-plan, `P1B --> P5`); Simple/Full mermaid + prose (one `1b plan` step); example walkthrough (merged steps 2+3, renumbered); Quick Reference (one `plan` row, post-spec = post-plan refinement); directory structure (one `<slug>-plan.md`); intro direct-jump + seam table + CS line. |
| T008 | ✅ done | Docs sweep. `docs/skills-pipeline/flow-architecture.md`: generic example verb `architect` → `plan` (contract-block template + `:16` stage example → implement + `:220` narration example). `CLAUDE.md` the-flow section: added the plan-032 consolidation history note (`1b specify`+`3 architect` → atomic `1b plan`; `20-specify.md`+`30-architect.md` → `20-plan.md`; typed aliases). `AGENTS.md` untouched (symlink). |
| T009 | ✅ done | **Verify + deploy.** `just check-flow` → **clean, 0 errors** (L1 0 leaks · L2 9/9 · L4 closure both dimensions · L5 banners · L6 ≤1024). `scripts/check-skill-slugs.sh` → 0 collisions (13 skills). Two lint errors found+fixed mid-verify: L3 `flight-plan.template.md:72` retired `/the-flow 3 architect` literal, and L6 SKILL.md description 1097→under budget (trimmed). Also collapsed the **worked-example template** (`flight-plan.template.json` + `.md`) from the retired spec→plan two-node shape to one unified `1b plan` node (backpressure → post-plan refinement excursion); fixed `flight-plan.schema.json` description example. JSON re-validated. `rg` sweep: all `<slug>-spec`/merge/adr hits are intended legacy-fallbacks; `awaiting-3`/`30-architect` only in deliberate back-compat translation notes. Routing walks (Simple/Full) + 3 integration replays (old-state→awaiting-1b translation · merge-on-unified-folder no-abort · direct-jump `/the-flow 3 architect`→`1b plan`) + four-shape adoption all reason through correctly. Historical plan folders byte-untouched (`git status` clean). Deployed `just install-skills-from-source` → canonical store confirmed (`20-plan.md` present; `20-specify.md`+`30-architect.md` gone; Registry `1b plan` row; Claude Code symlink resolves). |

## Phase-end harness seam (`--event phase-end`)

- `decision: noop` — repo still unprovisioned; no drain/harvest. Best-effort, recorded once.

## Phase complete — Simple mode, 1 phase

All 9 tasks (T001–T009) ✅. **The `specify` (1b) + `architect` (3) stages are now one atomic `plan` verb** (`references/stages/20-plan.md`) producing **one** `<slug>-plan.md` (business spec + implementation plan, always both). Routing collapsed to a single `awaiting-1b`; downstream merge/adr abort gates relaxed; all docs/views regenerated; lint green; deployed. No code (markdown + JSON only) — Manual verification per the plan. Acceptance criteria AC-01…AC-09 met (see AC Coverage Map).

**Suggested commit**: `feat(the-flow): merge specify+architect into one atomic 1b plan verb → one <slug>-plan.md (plan-032)`

## Post-review fix pass (2026-06-16) — all 7 review follow-ups resolved

Review verdict was **APPROVE** with 6 MEDIUM + 1 LOW deferrable follow-ups (no `fix-tasks.md`). User asked to clear them all before merge. Done:

| Finding | Sev | Fix |
|---------|-----|-----|
| F001 | MED | `00-routing.md`: added a **Legacy split planning complete** predicate (sibling `*-spec.md` + architect-era `*-plan.md` with no `## Business Specification`) + a read-time translation bullet → such folders are routed by the legacy spec's `**Mode**` (Simple→**implement**, Full→**tasks**), never re-planned. |
| F002 | MED | `80-merge.md`: mode + business-context reads now key on the unified `<slug>-plan.md` (top metadata + `## Business Specification` / `## Implementation Plan`), with legacy `<slug>-spec.md` only as fallback — two sites (cross-mode gate + "Read" list). |
| F003 | MED | `20-plan.md`: the `## Planning Seam` written into the artifact is now a **passive record** (open Workshop Opportunities + backpressure-coverage presence) — removed the actionable checkboxes and the `/eng-harness-flow` + `/compact` command literals; the flow (Graph + coach) owns offering refinements. (Also removed an L3 leakage source.) |
| F004 | MED | `00-routing.md` render rules 2–4: post-plan `backpressure` is a dotted `:::harness` **excursion** off `plan` (aligned to the template), not a spine node; the no-harness fallback now connects the unified `plan` node **directly** to the first `phase` (killed the stale `spec --> plan` fallback). Template `bp` note cross-references render rule 3. |
| F005 | MED | `unified-planning-doc-plan.md` Domain Manifest: added rows for `flight-plan.template.json`, `flight-plan.template.md`, `flight-plan.schema.json`, and an explicit deleted-`20-specify.md` row. |
| F006 | MED | `execution.log.md`: moved the orphaned **T006** row into task order (between T005 and T007); added the structured **Verification record (T009)** table (input / expected / observed / status). |
| F007 | LOW | `coach.md`: fresh-start `start` rail corrected from 7 pips to 6 (`◇─◇─◇─◇─◇─◇`). |

**Re-verified after the fix pass**: `just check-flow` **clean** (L1 0 leaks · L2 9/9 · L3 no unauthorized flow-command literals · L4 closure · L5 banners · L6 ≤1024); `scripts/check-skill-slugs.sh` 0 collisions (13 skills); both `flight-plan.*.json` parse; redeployed via `just install-skills-from-source` and spot-checked the canonical store (all 7 fixes present in `~/.agents/skills/the-flow/...`). No HIGH/CRITICAL existed, so no behavioural risk — the two with teeth (F001/F002, the legacy-folder path) are the meaningful ones. Merge next.

## Verification record (T009)

| Check | Input / command | Expected | Observed | Status |
|-------|-----------------|----------|----------|--------|
| Flow lint | `just check-flow` (`scripts/check-flow-architecture.sh`) | L1–L6 pass, 0 errors | L1 0 leaks · L2 9/9 labels · L4 closure both dimensions · L5 banners · L6 ≤1024 | ✅ |
| Slug collisions | `scripts/check-skill-slugs.sh` | exit 0, no duplicates | 0 collisions across 13 skills | ✅ |
| Template JSON | `python -m json.tool flight-plan.template.json` | parses | parsed clean | ✅ |
| Schema JSON | `python -m json.tool flight-plan.schema.json` | parses | parsed clean | ✅ |
| Old-state translation | replay state with `current_stage: awaiting-3` | translates → `awaiting-1b`, re-derives pending verb | routed to `awaiting-1b`; unified plan → implement | ✅ |
| Merge on unified folder | merge folder-detection over a `*-plan.md`-only folder | no abort | gate accepts unified plan (legacy `*-spec.md` fallback intact) | ✅ |
| Direct-jump alias | `/the-flow 3 architect` | resolves to `1b plan` | alias table maps id 3 + typed `architect` → `1b plan` | ✅ |
| Deploy | `just install-skills-from-source` | canonical store updated | `20-plan.md` present; `20-specify.md`/`30-architect.md` gone; Registry `1b plan` row; Claude symlink resolves | ✅ |
| Historical folders | `git status` over `docs/plans/0NN-*` | byte-untouched | clean | ✅ |

