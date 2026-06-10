# Research Report: eng-harness switchover — route the SDD pipeline through `/eng-harness-flow`

**Generated**: 2026-06-10T08:20:00Z
**Research Query**: "switch the SDD pipeline + the-flow from the local skills/harness/* family to the eng-harness-* skills (AI-Substrate/harness-engineering): remove the four local harness skills; route EVERY harness seam through /eng-harness-flow ONLY (with --event context) — never call the child eng-harness-* skills directly, they are private and may move/rename; detect missing eng-harness skills / missing repo harness and warn calmly; update the-flow SKILL.md + references/getting-started.md"
**Mode**: Pre-Plan (plan folder `docs/plans/029-eng-harness-switchover/`)
**FlowSpace**: Not used (markdown-only repo; direct reads + 8 parallel subagents)
**Findings**: ~130 across 8 subagents (IA-seam-map ×42 rows, IC ×33, DC ×14, DE ×41, PL ×22, DB ×8, PS ×10, QT ×10) + first-hand reads of both repos

---

## Executive Summary

### What It Does
This repo's SDD pipeline (10 `plan-*` skills + `the-flow`) currently hard-codes ~184 references to four **local** harness skills (`skills/harness/harness-1-boot`, `-2-backpressure`, `-3-observe`, `-4-retro`): auto-firing them at seams, checking a file sentinel, reading/writing harness buffer + retro paths directly, and rendering them as first-class flight-plan nodes. The substrate repo (`/Users/jordanknight/substrate/harness-engineering`) now ships a superseding family — `eng-harness-setup/` (3 skills) + `eng-harness-loop/` (3 skills + the **`eng-harness-flow`** stateless router) — designed for exactly this migration: a parent flow calls `/eng-harness-flow --event <seam>` and the router owns ALL harness routing in one place.

### Business Purpose
One stable public entry point (`/eng-harness-flow`) instead of four pinned slugs. Child skills become private implementation the substrate repo can move/rename freely — which is precisely what the vocabulary freeze was trying (and failing) to guarantee with name-pinning. The user's hard constraint, recorded verbatim in `original-ask.md`: **"we only call the main eng-harness-flow skill, we should never call the others directly, they might change later or move around."**

### Key Insights
1. **The substrate repo anticipates this exact change.** `eng-harness-flow/SKILL.md` §"Called repeatedly along an externally-managed flow" calls it "the inversion of `the-flow`'s hard-coded harness cues… Refactoring `the-flow` to do so is a follow-up, not a dependency." Its `skills/README.md:44` notes external tooling (naming "an SDD `the-flow` routing table") still references the old `harness-1-boot … harness-4-retro` names and calls updating them "a follow-up."
2. **This is a deliberate ownership reversal of plan-027** (APPROVED 2026-05-30), which made *tools* the canonical runtime-loop home and wrote that into README/INSTALL/CLAUDE.md. The spec must supersede 027 explicitly or future agents will "fix" the repo backwards (PL-01).
3. **It is also freeze override #2**: the four local names were re-frozen ≥1 quarter on 2026-06-08; deleting them on ~2026-06-10 is a second in-window break. Mitigant: routing through one never-changing name *fulfills the freeze's intent better than four names did* (PL-07, DB-07).
4. **The seams split into two classes** (IA key observation): (a) uniform `## Compound integration` blocks in 8 skills — mechanically replaceable by one router call per seam; (b) **substrate interactions** that never call the skills by name — plan-6/companion's inline Boot→Interact→Observe pre-flight, plan-5's health check, plan-7's Subagent 6 — which re-implement boot logic against a governance-doc path that no longer exists in the new world. The spec must decide whether `--event pre-implement` absorbs class (b).
5. **eng-harness skills are NOT installed on this machine today** (verified: no `eng-harness-*` under `~/.agents/skills` or `~/.claude/skills`) — the detection requirement is live, not theoretical. And this repo itself has no harness (no governance doc), making it the perfect live fixture for the calm "no engineering harness detected" warning.

### Quick Stats
- **Blast radius**: 184 slug hits in 23 live files (+13 `/plan-2d` alias mentions); 8 uniform Compound-integration blocks; ~12 sentinel check sites; 8 buffer check sites; 42 seams in the consolidated map
- **Heaviest files**: the-flow `references/getting-started.md` (27 hits), the-flow `SKILL.md` (19), plan-3 (11), plan-5 (10), plan-6-companion (9), README_AGENTS.md (9), CLAUDE.md (9)
- **Prior Learnings**: 22 surfaced (plans 017, 022, 023, 024, 025, 026, 027) + 3 encoded compound retro entries
- **Domains**: no registry; 3-domain framing proposed (DB-08)
- **Test coverage**: no CI; advisory-only `doctor-skills`/`skills-orphans`; grep-gates are the established test pattern (PL-10)

---

## The Target System (what we're switching TO)

> Captured first-hand from `/Users/jordanknight/substrate/harness-engineering/skills/` (read end-to-end this session). This section is the durable record of the external contract.

### Family inventory

| Group | Skill | Role |
|---|---|---|
| `eng-harness-setup/` | `eng-harness-0-setup` | install CLI → scout → stand up boot (no files of its own) |
| | `eng-harness-0-harnessability-assessment` | graded readiness report → `.harness/reports/harnessability/latest.{md,json}` |
| | `eng-harness-0-add-extension` | guided authoring of a new `harness <verb>` |
| `eng-harness-loop/` | **`eng-harness-flow`** | **the front door — stateless router; the ONLY skill we may call** |
| | `eng-harness-1-boot` | Boot stage (private) |
| | `eng-harness-2-backpressure` | Backpressure Check (private) |
| | `eng-harness-4-retro` | whole friction lifecycle (private). **There is NO eng-harness-3-observe** — in-flight capture is the CLI verb `npx --no-install harness observe "<what>" --kind <kind>` |

### `/eng-harness-flow` — the contract we integrate against

- **Stateless pure dispatcher**: `(repo signals A–J, conversation, optional hint) → next harness action`. Writes no artifacts, never gates/scores/blocks, never invents a health verdict (that's `harness doctor`'s), safe to call any number of times. Re-derives position every call (survives `/compact` by design).
- **Two zones**: 🧰 setup gate (S0 install → S1 scout* → S2 governance → S3 inject* → S4 build+run boot LAST; *skippable/advisory) then ⚙️ engineering dispatch. Router refuses engineering dispatch until S0+S2+S4 hold — an installed-but-unprovisioned repo routes to setup, gracefully.
- **Parameter contract**:
  ```
  /eng-harness-flow [at=<stage>] [--event <seam>] [--plan-dir <path>] [--spec <path>]
                    [--phase <id>] [--prompt-optional <bool>] [--repo <path>] [--json]
  ```
  `at=` ∈ auto|setup|boot|backpressure|observe|retro-drain|retro-harvest|improve. **`--event` ∈ session-start | post-spec | pre-implement | task-pause | phase-end | plan-complete** (six seams — two more than our four-seam sketch). `--prompt-optional=false` = parent owns skip-suppression (stateless router re-offers skipped optionals otherwise). `--repo` reserved v2.
- **Hints are validated, never blindly obeyed** — conflict matrix returns `decision` ∈ `route | redirect | noop | ambiguous` (e.g. `at=boot` with no governance → `redirect` to setup with `missing_rung`; `at=retro-drain` with empty buffer → `noop`; >1 plan and no `--plan-dir` → `ambiguous`, asks).
- **`--json` routing envelope** (machine callers): `requested_stage, actual_stage, decision, command, why, produces, preconditions_met, missing_rung, next_suggested, rail{...}, now, next, flags[], insight`.
- **Seam table for parents** (verbatim semantics):
  ```
  --event session-start                      → boot --validate
  --event post-spec      --spec <path>       → backpressure
  --event phase-end      --plan-dir <path>   → retro --drain   (buffer non-empty)
  --event plan-complete                      → retro --harvest (buffer empty; drain-before-harvest enforced by router)
  ```
- **Per-turn UX**: two-zone rail (`🧰 ●●◐○○ → ⚙️ …↺`), Orient → Flag → Insight → Suggest → Invite, print-then-offer — deliberately mirrors `the-flow`.
- **No `.disabled` sentinel**: "opting out is conversational" — the user says so and the agent stops calling. (Semantic break with our file sentinel, not a path move.)
- **Known soft spot**: `at=observe` capture payload is described as `--entry-*` fields but those fields are **not enumerated** in the parameter block (DB-01) — pin down with substrate before relying on it.

### The other breaking contract changes

| Dimension | Old (this repo) | New (substrate) |
|---|---|---|
| Entry surface | 4 named skills + `/plan-2d` alias | **1 router**; children private |
| Governance doc | `docs/project-rules/engineering-harness.md` (+ legacy `agent-harness.md`/`harness.md` fallback) | **`.harness/engineering-harness.md` — canonical and ONLY location, fallback chain retired** |
| Opt-out | `docs/harness/.disabled` file sentinel | conversational only |
| Observe | `harness-3-observe` skill | `npx --no-install harness observe` CLI verb (buffer/IDs/timestamps/validation/gitignore owned by CLI) |
| Buffers | `docs/harness/_buffers/<agent>.session-buffer.md` | gitignored `.harness/temp/<bucket>/` |
| Retro records | `docs/harness/agents/<agent>/<date>/*.retro.md` | committed `.harness/records/retro/<date>/<NNN>-<slug>.md` via `harness record retro`; **legacy `docs/harness/agents/**` still read by harvest (back-compat)** |
| Boot verdicts | HEALTHY / SLOW / UNHEALTHY / UNAVAILABLE | identical ✅ |
| Backpressure artifact | `docs/plans/<ord>-<slug>/backpressure-coverage.md` | **identical path + shape** ✅ (lowest-risk seam piece) |
| Drain prompt | `[s/t/p/e/d/a]`, default `[a]` | identical ✅ |
| Harvest `--json` | 8 jq paths consumed by `scripts/compound-value.sh` | shape preserved (`harness.{maturity,verdict,boot_ms}`, `entries.*`, `top_clusters[]`, `schema_version` semver) ✅ — verify field *presence*, not exit code (PL-11) |
| Retro schema | `docs/harness/schemas/retro.schema.json` | **byte-identical across all 3 copies today, zero drift** (DB-03); substrate's bundled copy self-describes as "mirror of the frozen `docs/harness/schemas/retro.schema.json`" — a reverse pointer to OUR path |
| Install | `npx skills@latest add jakkaj/tools …` | `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y` (or `harness skills install --target claude-code --global`); **never bare `npx harness`** — always `npx --no-install harness …` |

---

## How It Currently Works (what we're switching FROM)

### Seam class (a) — the uniform `## Compound integration` blocks (8 skills)

plan-1a:1051, plan-2c:619, plan-5:562, plan-6:245, plan-6-companion:435, plan-6a:286, plan-7:443, plan-8:1034. Each: sentinel check → start buffer-check (drain if non-empty) → silent observe during → drain at end (some: harvest suggest/auto). Highly uniform; mechanically replaceable with one router call per seam. plan-1b and plan-3 have NO block — their touch is suggest-next-step (1b:261) and template emission (plan-3).

### Seam class (b) — substrate interactions (never name the skills)

- **plan-6:100–130 / plan-6-companion:215–245** — inline 3-stage Boot→Interact→Observe pre-phase validation (≈ boot re-implemented in the skill body, reading the governance doc directly). UNHEALTHY → stop-and-ask; UNAVAILABLE → note and proceed.
- **plan-5:93–98** — harness health check for the Context Brief.
- **plan-7:194–218** — Subagent 6 live boot/interact/observe validation vs ACs (uses variant verdict strings `HARNESS_UNAVAILABLE`, no SLOW — normalize during migration, DB-02).
- **plan-1a §2c / plan-1b:54–55** — harness existence/maturity discovery for dossier/spec.

These read `docs/project-rules/engineering-harness.md` — a path the new world abandons. **Spec decision needed**: absorb into `--event pre-implement` routing (DB-04 recommends: "SDD never file-tests harness state") or keep direct reads at the NEW path.

### The consolidated 42-row seam map

The full skill × seam × current call × proposed `--event` table (with verbatim blocks and line numbers) is preserved in the subagent record: `/Users/jordanknight/.claude/projects/-Users-jordanknight-github-tools/e396b283-612f-420b-b88f-e971e149ef15/tool-results/toolu_018PszyeJsuRtjqfLgMwKu78.json`. Proposed mapping summary:

| Our seam | `--event` |
|---|---|
| skill start (buffer check → drain) | `session-start` |
| spec done → recommend backpressure (plan-1b:261, the-flow awaiting-1b) | `post-spec --spec <path>` |
| pre-phase boot (plan-6/companion pre-flight; plan-5 T000 rows; plan-3 N.0 rows) | `pre-implement --phase <id> --plan-dir <p>` |
| silent observe during work | `task-pause` — or the CLI verb directly (open question) |
| end of phase (drain; plan-3 N.z rows; plan-5 T0xx rows) | `phase-end --plan-dir <p>` |
| companion final debrief / plan-8 / the-flow complete (harvest) | `plan-complete` |

### Templates emit the names too (CF — high leverage)

plan-3 (N.0/N.z task rows + `## Harness Loop` output section) and plan-5 (T000/T0xx rows + Context Brief touchpoints) **bake `/harness-1-boot` and `/harness-4-retro --drain` into generated plan/tasks artifacts** — replacing call sites alone leaves stale names propagating into every future plan. The templates must emit `/eng-harness-flow --event …` syntax.

### the-flow's harness rendering

- Alias table `SKILL.md:48,57–60`: `/plan-2d` + `/harness-1..4` → local slugs.
- Routing-table "Harness cue" column (:254–266); sentinel paragraph (:441); render rules (:472–479).
- `references/flight-plan.schema.json:43–47`: node `type` enum includes `backpressure, harness-boot, harness-observe, harness-retro`; description hard-codes the local commands + sentinel.
- `references/flight-plan.template.{json,md}`: worked harness nodes with `"command": "/harness-2-backpressure"` etc.; violet `harness` classDef; legend.
- `references/getting-started.md`: 27 hits — loop description, 2 mermaids, plugs-in table, opt-out paragraph, directory block (which has **pre-existing drift**: line 227 still says `docs/compound/`), quick-reference rows, closing location note.
- Schema `$comment` names two more sync-mirrors: `references/sample-the-flow.json` and `workshops/002-flight-plan-dag.md` (IC-33).

---

## Detection & calm warning — design inputs (the second half of the ask)

> Ask verbatim: "detect if the harness skills are availale and the harness is terhe too and if not warn the user that no engineering harness detected, and that we are goign to work without one (no drama, just a good solid warning)."

**Two-layer ladder** (PS-10), mirroring established in-repo precedents:

- **Layer 1 — router installed?** Deterministic probe: `test -f ~/.agents/skills/eng-harness-flow/SKILL.md` (canonical store; real dirs), fallback `~/.claude/skills/eng-harness-flow/SKILL.md` (symlink view); optionally corroborate `harness --version` (the `minih --version` precedent, plan-6-companion:44–46). On miss → ONE ℹ️-toned line + the install command. ℹ️ not ⚠️: absence is capability-reduction, not correctness risk (the FlowSpace vs plan-ordinal tone distinction, PS-01/PS-02).
- **Layer 2 — repo has a harness?** **Delegate, don't reimplement**: call `/eng-harness-flow` and act on its envelope (`decision: noop`/setup-routing = no harness provisioned). The router's signals A–F already absorb the installed-but-unprovisioned case. Never copy signals into SDD skills.
- **Warn once per flow**: every precedent (FlowSpace, minih, plan-6 pre-flight) detects at ONE early point, prints once, caches the outcome, and lets downstream sections branch silently. Concretely: detect at pipeline entry (the-flow/plan-1a/plan-1b), record once in the artifact/EXEC_LOG, never re-nag.
- **Warning copy register** (matches plan-5's neutral-declarative precedent): *"No engineering harness detected — proceeding without one (standard testing approach applies). Install: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`."*
- **Layer 0 open question**: keep `docs/harness/.disabled` as an SDD-side opt-out (PS-10 recommends — checked BEFORE any delegation, preserving silent-skip), or adopt the substrate's conversational-only model. Spec decision.

---

## Domain Context

No `docs/domains/` registry. Proposed framing (DB-08):

1. **`sdd-pipeline`** (this repo): owns `skills/SDD/*`, the-flow state/flight plans, `docs/plans/**` layout incl. the *location* of `backpressure-coverage.md`. Excludes ALL harness internals — no buffer/governance/sentinel/record paths, no child slugs, no drain/harvest choreography, no schema custody.
2. **`eng-harness`** (substrate repo): owns the skill family, the `harness` CLI, all `.harness/**` substrate, the maturity ladder, the drain UX, bundled schema. Consumes `--spec`/`--plan-dir` as opaque paths.
3. **`harness-seam`** (the cross-repo contract, documented in BOTH repos): the `/eng-harness-flow` slug + parameter contract + `--json` envelope; `<plan-dir>/backpressure-coverage.md` name+shape; verdict vocabulary; `[s/t/p/e/d/a]` narration; `retro.schema.json` semver.

**One-way dependency rule**: `sdd-pipeline → /eng-harness-flow` ONLY. Degraded mode replaces both the sentinel conditionals and the UNAVAILABLE-fallbacks with one rule: router absent or `noop` ⇒ proceed silently with standard testing.

Candidate post-switch action: `/plan-v2-extract-domain` to formalize `harness-seam` (optional).

---

## Dependencies & Tooling couplings (break list)

| # | Artifact | Failure mode on deletion | Action |
|---|---|---|---|
| 1 | `justfile:326–339` doctor-skills drift check | **Actively instructs recreating the deleted tree** ("bundled copy missing — create: cp …") on every run | Remove/repoint (same commit as deletion) |
| 2 | `justfile:39,243` + `scripts/compound-value.sh:2,9` | Comments name `harness-4-retro --harvest --json` as producer | Repoint; functionally OK if envelope shape holds (it does — verify field presence) |
| 3 | `INSTALL.md:95,115,121` | `npx skills add jakkaj/tools/skills/harness` fails outright (path gone) | Replace with substrate install commands |
| 4 | Deploy stores | 4 real dirs in `~/.agents/skills` + 4 symlinks in `~/.claude/skills` linger (npx never prunes) | Literal-slug `rm` cleanup (zsh word-split gotcha, PL-06) + `just skills-orphans` verify |
| 5 | Sentinel checks (~12 sites) | Point at `docs/harness/.disabled` — semantically dead in new world | Per spec decision (keep as layer-0 or remove) |
| 6 | Buffer checks (8 sites) + plan-1a retro reads + plan-6 open-entry counts | Paths the repo no longer owns | Replace with `--event` routing (router owns drain-vs-harvest) |
| 7 | plan-6a Steps 8c.ii/9.e | **Writes `.retro.md` directly** into `docs/harness/agents/…` against our schema — the single deepest reach-in | Spec decision: route via `harness record retro` CLI vs keep direct writes as seam contract |
| 8 | `docs/harness/schemas/` | Stays (minih shape-contract copy; `$id` URLs pinned to this path; `system.compound`/`system.minih` sub-schemas exist ONLY here); bundled deploy copy vanishes with skill | Keep dir; record custody decision; fix substrate's "frozen mirror" reverse-pointer |
| 9 | `docs/harness/agents/**` 1 committed retro + `_buffers/` (empty) | Records: still read by substrate harvest (legacy back-compat) ✅. Buffers: NOT in substrate's legacy read list — would strand (ours is empty — no-op) | Leave records; note buffers retired |
| 10 | `plan-7:456` self-audit grep for the sentinel string | False findings the moment the sentinel changes | Rewrite audit target ("router call present") |
| 11 | `src/jk_tools/` | No skill content (verified); `scripts/compound-value.sh` mirror stale — auto-overwritten on next sync | None (edit source only) |
| 12 | Uncommitted README.md/INSTALL.md/MIGRATION.md edits | The pending 3→4-skill renumber catch-up documents the family being deleted — largely mooted | Decide: commit-first (clean history) vs fold into switchover |

## Docs sweep (41 DE findings, summarized)

- **CLAUDE.md**: layout tree (:34), Compounding Value System section (:50–70 — four-skill enumeration, schemas paragraph incl. bundled-copy + drift-check sentences, opt-out line, ledger surface), bundling example (:104), and **the vocabulary-freeze paragraph (:64) — must record override #2 with the audit trail, never silently delete** (it is the designated record of exactly this event). New frozen surface: `/eng-harness-flow` + its `--event` vocabulary.
- **README.md** (:63–92): table rows, harness-loop section, **ownership-split line (:88) inverts**.
- **README_AGENTS.md**: install examples using `--skill harness-1-boot` (:54–57, 73), tree (:117), plan-3 cross-ref (:139), the-flow row (:151), whole harness catalog section (:160–171); category-count drift with INSTALL.md to reconcile.
- **INSTALL.md** (:16,25,80,94–103,115,121) and **MIGRATION.md** (:52–54): category rows, slug examples, subfolder installs, runtime/setup split sentence; MIGRATION gains the four slugs as the newest stale-deploy cleanup case.
- **docs/skills-pipeline/README.md** (:21,34): the-flow row + backpressure pipeline row → repoint (the pipeline *step* survives; the implementing skill is now reached via the router).
- **docs/harness/README.md + _buffers/README.md**: ALREADY stale (still name retired `compound-0..3` skills) — rewrite as legacy-ledger pointers.
- **schemas/README.md + schema description strings**: stale "compound skills" mentions (patch-level doc edits); provenance paragraph is the natural home for the custody decision.
- **Forward-pointers** (PL-13 pattern): add atop 024 and 027 plan files noting 029 supersedes their skill surface. Never rewrite `docs/plans/**` history.

---

## Prior Learnings (institutional knowledge — pay attention)

| ID | Source | Key insight | Action |
|----|--------|-------------|--------|
| PL-01 | plan-027 | 027 (APPROVED 2026-05-30) made tools the runtime-loop home; 029 **reverses** it | Spec supersedes 027 explicitly |
| PL-06 | 024 T014 | npx never prunes; zsh unquoted-var rm loop silently no-ops | Literal-slug cleanup task, 2 stores |
| PL-07 | CLAUDE.md / f9fdcb5 | Freeze reset 2026-06-08, ≥1 quarter; this is override #2 | Declare cost-understood; re-freeze over `/eng-harness-flow` |
| PL-08 | 024 non-goals | Schema shape + `schema_version` agreement is THE cross-system rule with minih | Keep `docs/harness/schemas/`; don't change meaning |
| PL-10 | 024 | Grep gates ARE the tests; Done-When = a grep, never a hand-list | Every cascade task gets pre/post greps |
| PL-11 | 024 AC4 | `compound-value.sh` consumes 8 jq paths; `jq // 0` masks missing fields | Test with real JSON, check field presence |
| PL-12 | 024 pre-phase | Installed copies drive the session — edit the driver skills LAST | Sequence the-flow/plan-3 edits last |
| PL-13 | 024 T017 | Immutable history + forward-pointer pattern | Pointers atop 024/027; exclude docs/plans/** from greps |
| PL-14/15 | 023/025/027 + memory | KISS no-indexes; best-effort/no-gates — re-affirmed three plans running | Warning stays advisory; no bridge state files |
| PL-18 | 026 OH-003 | getting-started.md travels inside the skill via npx | Update in same commit; smoke the installed copy content |
| PL-19 | a47d17d | Harness capability was already evicted from tools once ("wrong repo") | Frame 029 as completing an established migration |
| PL-21 | plan-017 | plan-6 "step 2a" / plan-7 E.6 validation predate the loop skills — class (b) seams | Spec must address them distinctly |
| PL-22 | plan-022 | Two-phase shippable migration (add alongside → delete legacy) | Consider Phase A route + fallback, Phase B delete + cleanup |

Compound activity: ✓ 3 entries surfaced from 1 retro (2026-05-19) — 3 encoded, 0 open. RV-002 is the provenance of the harvest-JSON contract: breaking it silently would un-encode a recorded gift.

---

## Critical Discoveries

1. **CF-01 Ownership reversal** (PL-01) — supersede 027 in the spec, update its doc surfaces (README:88, INSTALL:103, schemas README).
2. **CF-02 Freeze override #2** (PL-07/DB-07) — record in CLAUDE.md freeze paragraph with audit trail; new frozen surface = the router name + `--event` vocabulary.
3. **CF-03 Router not installed here yet** — layer-1 detection is live; install command verified: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`.
4. **CF-04 doctor-skills drift check** (justfile:326–339) will instruct users to recreate the deleted tree — must change in the same commit.
5. **CF-05 plan-6a writes retros directly** — deepest reach-in; needs explicit routing decision.
6. **CF-06 Observe is a CLI verb, not a skill** — substrate has no observe skill; open question whether `npx harness observe` is exempt from the router-only rule (router's `at=observe --entry-*` payload is under-specified upstream).
7. **CF-07 Two seam classes** — class (b) inline BIO validations re-implement boot against the dead governance path; absorb into `pre-implement` or repath.
8. **CF-08 Sentinel semantically dead upstream** — decide layer-0 fate (~12 sites).
9. **CF-09 Templates propagate names into future artifacts** — plan-3/plan-5 must emit router syntax.
10. **CF-10 Schema custody** — zero drift today; bundled copy vanishes; substrate self-describes as mirror of OUR path; sub-schemas exist only here; `$id` URLs pinned.
11. **CF-11 The repo itself is the no-harness fixture** — the calm warning will fire here on every flow; perfect for validation.

---

## Modification Considerations

### ✅ Safe to modify
- The 8 uniform Compound-integration blocks (mechanical, grep-verifiable).
- `backpressure-coverage.md` consumption in plan-3/plan-5 — artifact path identical both sides; zero change needed to the consuming logic.
- Doc sweeps (CLAUDE/README*/INSTALL/MIGRATION/skills-pipeline) — prose only.

### ⚠️ Modify with caution
- **the-flow** (alias table, routing cues, flight-plan schema enum + templates + getting-started) — it's the skill DRIVING this very flow; edit last (PL-12); schema has two extra sync-mirrors (sample-the-flow.json, workshop 002).
- **plan-3/plan-5 templates** — emitted syntax reaches every future plan.
- **CLAUDE.md freeze paragraph** — append the override record; never delete.
- **plan-7 Subagent 6 + plan-6 pre-flight** — behavioral seams (stop-and-ask on UNHEALTHY) that users depend on; keep the UNHEALTHY-vs-UNAVAILABLE distinction whatever the routing.

### 🚫 Danger zones
- `docs/harness/schemas/` — cross-system minih contract; do not move/rename/change meaning (only patch description strings).
- `docs/plans/**` — immutable history; forward-pointers only.
- `src/jk_tools/` — auto-synced mirror; never edit.
- The drain `[s/t/p/e/d/a]` UX and harvest JSON shape — encoded contracts (RV-002/RV-003).

---

## Verification (what exists, what's missing)

**Recipe** (QT-09): `scripts/check-skill-slugs.sh` → "OK: 28 skills", exit 0 · `! grep -rn "skills/harness/" <live files>` · forbidden-slug grep `harness-[1-4]-\|/plan-2d` over live files → only whitelisted alias/historical hits · positive grep: `grep -rln "eng-harness-flow" skills/SDD/` → the ~10 rewired skills · `just doctor-skills` (no "bundled copy missing"; dangling-symlink section) · `just skills-orphans` (the 4 slugs appear with tidy lines; run them; pre-existing orphans: `engineering-harness-setup`, `shopping-hunter`, `pack-code` are the known baseline) · install smoke against the pushed branch, inspecting installed `getting-started.md` content.

**Gaps** (QT-10): no flight-plan schema validator (template claims "validates against" but nothing checks); no CI at all; doctor/orphans are advisory (exit 0 always — grep their output to gate); nothing can prove `/eng-harness-flow` resolves from this repo (deploy-side `ls` only); `migrate-skills.py` replay is dead (source dirs gone) — CLAUDE.md "Testing changes" bullet already stale. → These are backpressure-survey inputs (`/eng-harness-flow --event post-spec` once the router is installed — or honestly noted as eyeball-tier).

---

## Open Questions for the spec (`/plan-1b`)

1. **Observe routing**: is the `npx harness observe` CLI verb exempt from router-only (it's a verb, not a skill), or do SDD skills route capture via `at=observe --entry-*` (payload under-specified upstream)?
2. **Sentinel fate**: keep `docs/harness/.disabled` as SDD-side layer-0 opt-out, or go conversational-only like upstream?
3. **plan-6a retro writes**: route via `harness record retro` CLI vs keep direct writes under a declared seam contract?
4. **Class (b) seams**: absorb plan-6/companion inline BIO pre-flight + plan-7 Subagent 6 into `--event pre-implement` routing, or keep direct reads repathed to `.harness/engineering-harness.md`?
5. **Alias policy**: `/plan-2d` and `/harness-1..4` → thin repoints to router calls, or tombstone lines?
6. **Event vocabulary**: adopt all six seams or just the four we use today?
7. **Flight-plan node types**: keep `backpressure/harness-boot/harness-observe/harness-retro` as STAGE names (commands become router calls) vs consolidate?
8. **Schema custody**: who owns canonical `retro.schema.json` now; fix substrate's reverse-pointer; sub-schema bundling upstream?
9. **Uncommitted README/INSTALL/MIGRATION edits**: commit-first or fold in?
10. **Landing shape**: one cascade or two-phase (route-with-fallback → delete+cleanup, PL-22)?
11. **Cross-repo follow-ups** (out of scope here, log for substrate): pin `--entry-*` fields; update its "frozen mirror" sentence; its README:44 follow-up note gets resolved by this plan.

## External Research Opportunities

None — every gap is local or cross-repo (substrate repo is on disk and was read directly). The `--entry-*` payload question is a substrate-repo conversation, not web research.

## Next Steps

User has already directed: proceed to `/plan-1b` (spec). The spec must encode: router-only constraint, the two-layer detection + calm warning, the seam map, the 11 open questions above, supersession of 027, and freeze override #2.

---

**Research Complete**: 2026-06-10T08:20:00Z
**Report Location**: `docs/plans/029-eng-harness-switchover/research-dossier.md`
