# Execution Log — Phase 1: Switchover cascade (plan 029)

**Plan**: [eng-harness-switchover-plan.md](./eng-harness-switchover-plan.md) · **Mode**: Simple · **Started**: 2026-06-10T08:56Z
**Executor**: plan-6-v2-implement-phase (plain mode — no companion, per user)

## Pre-phase agent-harness validation

| Stage | Status | Notes |
|---|---|---|
| Boot | 🔴 UNAVAILABLE | No `docs/project-rules/` directory exists (no `engineering-harness.md` or legacy names) — no boot command to run |
| Interact | — | skipped (no harness) |
| Observe | — | skipped (no harness) |

**Verdict**: 🔴 UNAVAILABLE → proceed with standard testing (per skill contract, not an error). This is expected — the very subject of this plan is graceful no-harness degradation, and this repo is the live no-harness fixture.

Compound-integration check: `docs/harness/.disabled` ABSENT; `docs/harness/_buffers/` contains only `.gitignore` + `README.md` (no session buffers) → nothing to drain. No retro machinery fired — this commit removes that machinery; decision noted.

---

## T001 — Contract re-check, pre-install probe (AC7 evidence), install external family

**Status**: in progress

### Contract re-verification (substrate router SKILL.md, read 2026-06-10T08:56Z)

Source: `/Users/jordanknight/substrate/harness-engineering/skills/eng-harness-loop/eng-harness-flow/SKILL.md`

| Plan assumption | Router file says | Verdict |
|---|---|---|
| Events `session-start \| post-spec \| pre-implement \| phase-end \| plan-complete` | `:124–125`: `session-start \| post-spec \| pre-implement \| task-pause \| phase-end \| plan-complete` | ✅ match (5 used; `task-pause` exists, deliberately unused by SDD) |
| Flags `--spec --plan-dir --phase --prompt-optional --json` | `:112–113, :126–131` — all present (`--repo` reserved v2) | ✅ match |
| Envelope `decision: route\|redirect\|noop\|ambiguous` | `:178` | ✅ match |
| Boot verdicts lowercase `healthy / SLOW / UNHEALTHY / UNAVAILABLE` | `:61` | ✅ match (the casing validate-v2 caught is confirmed correct) |
| Stateless; no `.disabled` sentinel; opt-out conversational | `:19, :78` | ✅ match |

**No drift — proceed.**

### Pre-install probe (AC7 live evidence)

Captured 2026-06-10T08:56:11Z, BEFORE install:

```
test -f ~/.agents/skills/eng-harness-flow/SKILL.md  → MISS (canonical store)
test -f ~/.claude/skills/eng-harness-flow/SKILL.md  → MISS (claude view)
```

This machine was a live no-router fixture at execution start — the Layer-1 detection branch is grounded in a real observed miss, not a simulation.

### Install + post-install probe

**Deviation 1 (upstream publishing gap)**: the plan's documented install command `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y` installed only **2 old-generation skills** (`engineering-harness-setup`, `harnessability-assessment` — both already present on this machine) because the GitHub **default branch** doesn't carry the eng-harness family yet. The family (router + 6 children) lives on `feat/harness-cli-core`, which the local checkout at `/Users/jordanknight/substrate/harness-engineering` tracks **in sync** (zero unpushed commits). Branch-URL install failed (CLI mis-parses slashed branch names: `tree/feat/harness-cli-core` → branch `feat`). **Resolution**: installed from the local checkout (byte-identical to `origin/feat/harness-cli-core`): `npx skills@latest add /Users/jordanknight/substrate/harness-engineering -a claude-code -g -y --skill '*'` → 7 skills installed.

**Deviation 2 (store placement)**: local-path installs **copy** per-agent instead of canonical-store + symlink. Post-install probe (2026-06-10T08:59:10Z):

```
test -f ~/.agents/skills/eng-harness-flow/SKILL.md  → MISS  (canonical — local-path installs don't populate it)
test -f ~/.claude/skills/eng-harness-flow/SKILL.md  → PASS  (the Layer-1 probe's designed fallback path)
```

Layer-1 detection resolves via its fallback exactly as the contract specifies. Once upstream merges `feat/harness-cli-core` to main, the documented GitHub install will populate the canonical store normally.

**Cross-repo follow-up (logged)**: substrate repo must merge/publish `feat/harness-cli-core` so the documented install command actually delivers the router — until then the warning copy's install hint is forward-correct but not yet live.

**T001: ✅ COMPLETE** — contract verified (no drift), pre-install miss logged (AC7), family installed, router resolves via the probe chain.

---

## T002 — Router smoke: `--event session-start --json` in this unprovisioned repo

**Status**: in progress

Smoke executed by a subagent running the **installed copy** (`~/.claude/skills/eng-harness-flow/SKILL.md`) against this repo. Envelope (AC8 evidence):

```json
{
  "requested_stage": "boot",
  "actual_stage": "setup",
  "decision": "redirect",
  "command": "/eng-harness-0-setup",
  "why": "session-start asks for boot, but the setup gate isn't crossed — first missing required rung is S2 (no .harness/engineering-harness.md); S4 boot is also unbuilt, so the loop skills would report UNAVAILABLE.",
  "preconditions_met": false,
  "missing_rung": "S2-governance",
  "rail": { "zone": "setup", "setup_pips": "●○◐○○", "loop_pips": "○○○○○", "cursor": "governance" }
}
```

(abridged — full envelope captured in session; `flags` lifted real `harness doctor` output). Rungs observed: S0 HELD (global `harness` CLI v0.1.0, doctor `ok`), S1/S2/S3/S4 MISSING. Decision is setup-routing (`redirect`) — matches the plan's expectation for a repo with no `.harness/`. The router never errored, never gated — exactly the graceful degradation the seams rely on.

**T002: ✅ COMPLETE**

---

## T003 — Rewire plan-1a + plan-1b

**Status**: in progress

Edits: plan-1a § 2c "Load Harness Context (two-part check)" → "Harness seam — session start (router-only)" with Layer-1 probe + verbatim warning + Layer-2 envelope handling; `harness-4-retro --harvest` slug ref at Subagent-7 scrubbed (reworded "legacy minih block reader"); whole `## Compound integration` block deleted, replaced by a 3-line harness note keeping the Prior-Learnings read-only mining. plan-1b: frontmatter question list, Phase-0 step 5 (governance file-test → router-ownership note), Round-2 condition + post-Round-2 clause, entire `### Agent Harness Readiness` section deleted, next-steps footer → `--event post-spec --spec` with verbatim warning.

Greps: `eng-harness-flow` present in both ✅; `harness-[0-9]-|\.disabled|engineering-harness\.md|agent-harness\.md` → 0 hits ✅; AC3 observe grep → 0 hits ✅.

**T003: ✅ COMPLETE**

---

## T004 — Rewire plan-2c + plan-5

**Status**: in progress

plan-2c: Compound block → 3-line no-seam harness note. plan-5: inline health-check step → router-probe note; emitted T000/T0xx rows → `--event pre-implement` / `--event phase-end` router syntax (AC5); Context Brief harness subsection → router touchpoints; Compound block → emit-only note. Greps: positive hits present (plan-5: 7 router refs), forbidden + AC3 → 0 hits ✅.

**T004: ✅ COMPLETE**

---

## T005 — Rewire plan-6 + plan-6-companion

**Status**: in progress

plan-6: load-context governance read → router probe; § 2a BIO pre-flight → `--event pre-implement` with verbatim warning + lowercase verdict vocabulary narrated from the envelope; § 6 retrospective payload dropped; new step 7 `--event phase-end`; Compound block → "Harness seams (router-only)". plan-6-companion: same § 2a replacement; § 5 keeps the minih debrief mechanics (drain ping/stop/farewell/reconcile/magicWand) but drops retrospective-JSON construction + docs/retros writes, adds phase-end + final-phase plan-complete seams; Output list drops the orchestrator-retro line; Compound block (incl. farewell→retro mapping table) → harness-seams note clarifying minih = code review, not harness. Greps: router refs present (4 + 6); forbidden/choreography/AC3/`docs/retros|.retro.md|retrospective` → all 0 hits ✅.

**T005: ✅ COMPLETE**

---

## T006 — Rewire plan-6a + plan-7 + plan-8

**Status**: in progress

plan-6a: description + flags drop `--retrospective`; Step 8 → retired-duty tombstone (number kept so callers' "Step 9" refs stay stable); Step 9e (companion retro write incl. minihToUniversal mapping) deleted, magicWand surfacing renamed e; Step 10 + closing paragraphs + Compound section scrubbed of retro custody. Remaining "retrospective" tokens = the tombstone + minih farewell field names (code-review data, kept). plan-7: Subagent 6 (live validator) deleted → 5 subagents + delegation note; report § E.6 removed; Compound block (incl. sentinel-audit spot-check grep) → no-seam note. plan-8: PROCEED epilogue + new `## Harness seam` section fire `--event plan-complete`. All forbidden/choreography/AC3 greps → 0 hits ✅; plan-8 `event plan-complete` ×2 ✅.

**T006: ✅ COMPLETE**

---

## T007 — Rewire plan-3 (post-run, per PL-12)

**Status**: in progress

plan-3: Harness Loading → router probe + "provisioning is never an SDD phase"; backpressure input repointed to post-spec seam (2 sites); Output Contract item 11 + plan template section → `## Harness Seams` (router-installed predicate); Phase Index example row "Build Agent Harness" → "Establish Backpressure"; Phase Design Principles rewritten (no harness-build phase; seam rows; router-only); N.0/N.z emitted rows → `--event pre-implement`/`--event phase-end`; Agent Harness Strategy + Harness Loop templates → single `## Harness Seams` template with verbatim-envelope verdict line. Greps: 5 emitted-router-event sites ✅; forbidden/AC3/choreography → 0 hits ✅.

**T007: ✅ COMPLETE**

---

## T008 — Docs sweep (CLAUDE.md, READMEs, INSTALL, MIGRATION, pipeline README, docs/harness README)

**Status**: in progress

CLAUDE.md: layout tree harness line dropped; § Compounding Value System → "§ Engineering harness (external, routed via /eng-harness-flow)" — external-family story, two-layer detection, keep-list; freeze paragraph kept VERBATIM + Override #2 appended (paste-ready text from plan); opt-out sentinel line deleted; bundled-CLI harness example dropped. README.md: structure-table harness rows consolidated; harness-loop section → external story w/ inverted ownership line ("AI-Substrate/harness-engineering owns the loop end-to-end; this repo consumes the router"). README_AGENTS.md: install examples swapped to `the-flow`; layout tree + harness catalog section → external pointer; plan-3/the-flow rows repointed. INSTALL.md: harness category row removed (26+2), external-family install callout added; category/branch/URL examples repointed; uncommitted renumber edits folded (superseded in place). MIGRATION.md: cleanup note now covers the plan-029 retirement + external install. docs/skills-pipeline/README.md: the-flow + /plan-2d rows → router seam. docs/harness/README.md: full rewrite as slim frozen-history pointer.

Verification: slug greps over all 7 docs → only the 2 whitelisted lines (CLAUDE.md freeze-audit ¶, MIGRATION cleanup note); `.disabled` → 0 hits; `skills/harness/` → only the verbatim Override #2 audit paragraph.

**T008: ✅ COMPLETE**

---

## T009 — Tooling (justfile, compound-value.sh, schema description strings)

**Status**: in progress

justfile: `compound-value` recipe + help line + schema-drift block (old :326–340) removed BEFORE the T011 deletion (Finding 05 honoured); `just --list` parses clean; `grep "compound-value\|skills/harness/" justfile` → 0 hits. `scripts/compound-value.sh` deleted (RV-002 convenience retired — deliberate, recorded). Schemas: 3 description strings modernised (compound-2-bubble/compound-3-harvest → "harness retro flow"; "compound skills" → "the engineering-harness loop"; "compound's encoding flow" → "the retro encoding flow"); `git diff` shows description-only changes; all 3 files valid JSON; `$id` + `schema_version` + shape untouched (minih contract preserved).

**T009: ✅ COMPLETE**

---

## T010 — the-flow rewrite (LAST among skill edits, PL-12)

**Status**: in progress

the-flow SKILL.md: alias table — `/plan-2d` → router post-spec invocation, all four `/harness-N` rows deleted, "Harness routing" paragraph added; routing-table Harness column → the five seams; narration scripts (awaiting-1b/2c/5/6/8/complete) → router language with verbatim lowercase verdicts; § "Harness loop — first-class" → § "Harness seams — routed via /eng-harness-flow (side by side, never merged)" with two-layer detection + exact warning copy; render rules → router-command nodes, Layer-1 emission predicate. flight-plan.schema.json: type enum unchanged in shape, descriptions rewritten (`harness-observe` retained as documented back-compat for historical flight plans; new plans never emit it); `command` description notes router invocations. template.json: bp/hb/hr2/hh nodes → router commands; `ho` observe node REMOVED; _comment rewritten; valid JSON. template.md: spine/seam nodes + legend + footer → router story; HO node removed. getting-started.md: full rewrite — side-by-side framing, 5-seam table, two-layer detection section w/ verbatim warning, walkthrough + quick reference router-only, stale `docs/compound/` block GONE, `.harness/` ownership note.

Greps: forbidden slugs + `.disabled` over all 5 files → 0; warning copy verbatim ×1 in SKILL.md; 20 `--event` mentions in getting-started; `docs/compound` → 0; both JSON files parse; AC3 observe → 0.

**T010: ✅ COMPLETE**

---

## T011 — Delete skills/harness/ + docs/harness/_buffers/

**Status**: in progress

`rm -rf skills/harness docs/harness/_buffers` — both gone; keep-list intact (`docs/harness/{agents,README.md,schemas}`). `scripts/check-skill-slugs.sh` → exit 0, **28 skills** ✅. Live-file sweep: the only `skills/harness` mention outside `docs/plans/**` history is CLAUDE.md:62 — the whitelisted Override #2 audit paragraph ✅.

**T011: ✅ COMPLETE**

---

## T012 — Deploy tidy (literal slugs, both stores) + redeploy + verify

**Status**: in progress

Pre-tidy state: 4 stale slugs as real dirs in `~/.agents/skills/` + 4 symlinks in `~/.claude/skills/`. Tidied with LITERAL paths in both stores (PL-06 — no shell-var loops). `just install-skills-from-source` → 28 skills redeployed (canonical + symlinked views). `just doctor-skills`: canonical store healthy, **no dangling symlinks**, no legacy orphan stores; flags one PRE-EXISTING wart outside this plan's scope — `engineering-harness-setup` is a real-dir duplicate of canonical in `~/.claude/skills/` (left by the default-branch npx install; doctor prints its own fix line). `just skills-orphans`: canonical shows only the known baseline (`engineering-harness-setup`, `shopping-hunter`); claude view shows baseline + the legitimately-external eng-harness family installed at T001 — **zero stale `harness-*` slugs** (AC11 ✅). Installed-copy smoke: `eng-harness-flow` ×19 in installed getting-started.md; verbatim warning copy present in installed the-flow + plan-1a + plan-6; forbidden grep over installed plan-*/the-flow copies → 0. Skill discovery refresh confirms: old family gone, eng-harness family + router live, rewired descriptions active.

**T012: ✅ COMPLETE**

---

## T013 — Forward-pointers atop plan-024 + plan-027 (additive only)

**Status**: in progress

Note placed atop both files: 024 (skills retired wholesale → external family) and 027 (ownership claim **explicitly reversed** — do not "fix" backwards). `git diff`: 4 insertions, **0 deletions** — history untouched.

**T013: ✅ COMPLETE**

---

## T014 — Full 12-AC verification sweep (2026-06-10)

| AC | Verdict | Evidence |
|----|---------|----------|
| AC1 Router-only | ✅ | Slug grep over skills/ justfile scripts/ CLAUDE/READMEs/INSTALL/MIGRATION/pipeline-README/docs-harness (excl. frozen `agents/` history) → exactly 2 whitelisted lines: CLAUDE.md:60 freeze-audit ¶, MIGRATION.md:54 cleanup note. `eng-harness-[0-9]` child slugs → **0 hits** |
| AC2 Seams | ✅ | `grep -rln eng-harness-flow skills/SDD/` → all 10 rewired SKILL.md + 4 the-flow references + the-flow SKILL.md (15 files). Five seams with context flags; all other seam classes removed |
| AC3 Observe gone | ✅ | `grep -rni "harness observe\|harness-3-observe\|silently call" skills/SDD/` → 0 (the `-i` catching capital-S "Silently call" — validation fix held) |
| AC4 Sentinel gone | ✅ | `grep -rn "\.disabled"` over the full live surface → 0 |
| AC5 Templates | ✅ | plan-3 emits `/eng-harness-flow --event` ×5 (N.0/N.z + § Harness Seams); plan-5 ×3 (T000/T0xx + brief) |
| AC6 Deletion clean | ✅ | `skills/harness/` + `_buffers/` + `scripts/compound-value.sh` gone; `check-skill-slugs.sh` → "OK: 28 skills, no slug collisions" |
| AC7 No-router detection | ✅ (evidence chain) | Live pre-install probe MISS both stores @ 2026-06-10T08:56:11Z (T001, logged above) + verbatim warning copy in 6 sources AND 5 installed copies. Full post-landing no-router run deliberately not staged (recorded decision; plan-7 reviews branch logic inferentially) |
| AC8 Router detection | ✅ | T002 envelope: `decision: redirect` → setup track, `missing_rung: S2-governance` — setup-routing in an unprovisioned repo; no per-seam nagging design verified in sources |
| AC9 the-flow updated | ✅ | Alias table router-only (`/harness-N` rows deleted); schema/template `command` fields are router invocations; getting-started fully rewritten (no `docs/compound/`); installed-copy smoke ×19 hits |
| AC10 Docs truthful | ✅ | Override #2 ¶ in CLAUDE.md; README "Ownership (inverted by plan-029)"; forward-pointers atop 024+027 (additive only); docs/harness/README.md slim (26 lines) |
| AC11 Deploy hygiene | ✅ | Four slugs tidied from BOTH stores (literal paths); `doctor-skills` no dangling symlinks; `skills-orphans` = known baseline + expected external eng-harness family; zero stale `harness-*` |
| AC12 Contracts preserved | ✅ | Schemas: description-strings-only diff (2+1 lines), `$id`/`schema_version`/shape untouched, valid JSON; committed legacy retros in place (`docs/harness/agents/claude-code/…`); `[s/t/p/e/d/a]` narration survives ONLY in the-flow (explaining what the user saw) |

### Working tree (the one commit, user-executed)

35 tracked files changed (353 insertions, 2,073 deletions) + untracked `docs/plans/029-eng-harness-switchover/`. Uncommitted README/INSTALL/MIGRATION renumber edits folded in (superseded in place — Finding 06).

**Remark (out of scope, self-healing)**: `src/jk_tools/scripts/compound-value.sh` still mirrors the deleted script — `src/jk_tools/` is the auto-synced distribution mirror (never hand-edited); it refreshes on the next `./setup.sh` or `scripts/sync-to-dist.sh` run.

**Pre-existing machine wart (not this plan's)**: `~/.claude/skills/engineering-harness-setup` is a real-dir duplicate of canonical (left by the default-branch npx install); `just doctor-skills` prints its own fix line.

### Cross-repo follow-ups (logged, not done)

1. **Merge/publish `feat/harness-cli-core`** in `AI-Substrate/harness-engineering` so the documented install command (`npx skills@latest add AI-Substrate/harness-engineering …`) actually delivers the router + family from the default branch (today it delivers only the 2 old-generation skills; this machine installed from the in-sync local checkout). Note: the skills CLI supports `#branch` selectors but mis-parses slash-containing branch names.
2. Retro-schema custody transfer to the substrate repo (incl. `system.*` sub-schemas) + its "frozen mirror" reverse-pointer fix.
3. Substrate `skills/README.md:44` stale-slug note (this plan resolved the referencing side).
4. Consider a sanctioned prior-learnings read surface (e.g. `at=retro-harvest --json`).

### Suggested commit message

```
feat(harness)!: route SDD through the external /eng-harness-flow router; delete local harness family (plan-029)

- Five seams (session-start / post-spec / pre-implement / phase-end /
  plan-complete) now route EXCLUSIVELY via /eng-harness-flow with context
  flags; the router's child skills are private and never named here
- Two-layer detection: router-installed probe (one calm verbatim warning
  on miss) + envelope handling (route|redirect|noop|ambiguous); verdicts
  narrated verbatim (healthy / SLOW / UNHEALTHY / UNAVAILABLE)
- Observe leaves SDD entirely; .disabled sentinel concept removed;
  plan-6a retro-writing duty dropped; plan-7 Subagent-6 removed
- Delete skills/harness/ (4 skills incl. bundled schema), docs/harness/
  _buffers/, scripts/compound-value.sh, justfile drift block + recipe
- the-flow rewritten: alias table, routing cues, narration, two-layer
  detection, flight-plan schema/templates, getting-started.md
- CLAUDE.md freeze override #2 (re-freeze over /eng-harness-flow +
  --event vocabulary, ≥1 quarter); README ownership inverted; additive
  forward-pointers atop plans 024/027
- Keep-list: docs/harness/schemas/ (description-strings-only patches;
  shape + schema_version untouched — minih contract), docs/harness/
  agents/** frozen read-only history, slim docs/harness/README.md
- Deploy stores tidied (4 stale slugs, both stores, literal paths);
  28 skills redeployed from source; doctor-skills + skills-orphans clean

Plan: docs/plans/029-eng-harness-switchover/ (12/12 ACs verified —
see execution.log.md)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

**T014: ✅ COMPLETE — Phase 1 (T001–T014) DONE. 12/12 ACs pass. Awaiting user commit.**
