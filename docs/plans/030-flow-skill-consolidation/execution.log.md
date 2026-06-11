# Execution Log — flow-skill-consolidation

**Plan**: [flow-skill-consolidation-plan.md](./flow-skill-consolidation-plan.md) · **Mode**: Simple (single phase, T000–T014)
**Started**: 2026-06-11T09:51:03Z
**Testing approach**: Lightweight (structural checks + behavioural drive; no mocks)

---

## T000 — Harness pre-flight (`--event pre-implement`)

- Probe: router installed at BOTH `~/.agents/skills/eng-harness-flow/SKILL.md` and `~/.claude/skills/eng-harness-flow/SKILL.md`; harness CLI `0.2.0` on PATH; **no `.harness/` dir** (governance owed — adoption rung S2 missing).
- Seam fired with `--prompt-optional=false` (calm line already shown once at session-start; state file records the posture).
- **Envelope**: `decision: noop` (engineering seam on an unprovisioned repo; adoption gate S0 ✓ / S2 ✗ / S4 ✗). Boot verdict: **UNAVAILABLE** — not an error; standard testing applies.
- Outcome recorded once; no further harness warnings this phase (T014 fires phase-end quietly at the end).

## T001 — Rollback anchor

- `git tag pre-flow-consolidation` created on `44ba70f` (HEAD; `git status --porcelain skills/` was empty — skills tree byte-identical to the tagged commit).
- **Restore one-liner** (the whole rollback path):

  ```bash
  git checkout pre-flow-consolidation -- skills/SDD scripts/migrate-skills.py && just install-skills-from-source
  ```

  Checkout syntax verified against git semantics: pathspec checkout from a tag restores the listed paths into the working tree without moving HEAD — no branch, no history rewrite (AC7).
- User-authorized git write (spec clarification, 2026-06-11). No other git mutations occur in this phase; commit/push happen only at `/plan-8` on explicit `PROCEED`.

## T002 — Extract guided-mode machinery → `references/00-routing.md` + `references/coach.md`

Written from the full current the-flow SKILL.md (519 lines, loaded verbatim in-session). `00-routing.md` = the deterministic engine; `coach.md` = the voice.

### Destination map (every section of today's SKILL.md accounted for)

| Source section (519-line SKILL.md) | Destination |
|---|---|
| Title + guide-posture intro | coach.md (intro) + SKILL.md (one-line identity) |
| "You drive plan-*, not RPIV" callout | coach.md |
| Hard invariants 1–7 | **SKILL.md** (global, kept whole) |
| Driving — print-then-offer protocol (+ go-ahead loop) | coach.md |
| "Resolving stage names → installed slugs" alias table | **SUPERSEDED** → SKILL.md stage table + old-slug translation table (the alias table's job — map friendly names to runnable targets — is now the dispatch's core) |
| Harness routing paragraph (single door, --event vocab) | 00-routing.md § Harness seams |
| Exceptions (compact / merge PROCEED / heavy build) | coach.md § print-then-offer exceptions (PROCEED + compact also restated as SKILL.md invariants) |
| Host progress rail (spec, fences, milestones, dynamic total) | coach.md |
| Stage → rail map table | coach.md |
| Harness companion rail (unified block, ⚙/🧰) | coach.md |
| "Tell the agent to mirror the flow" | coach.md |
| Main loop — fresh / resume / adopt branching | 00-routing.md § Entry paths |
| Fresh-start steps + original-ask.md shape | 00-routing.md |
| Resume + idempotency rule | 00-routing.md (+ legacy-slug translation note) |
| State contract `.the-flow-state.json` | 00-routing.md (+ NEW § State-write ownership) |
| Adoption Contract | coach.md (per plan manifest) |
| Stage machine diagram | 00-routing.md |
| Routing Table | 00-routing.md (commands rewired to `/the-flow N`; new **Module loaded** column) |
| Must-see fields (Flag beat sources) | 00-routing.md (phrasing rules stay in coach.md Flag beat) |
| Narration scripts (start → complete, all blocks) | coach.md (commands rewired to `/the-flow N`) |
| Optional branch mentions | coach.md |
| /compact resume handshake | coach.md |
| Harness seams § (two-layer detection, verbatim warning, envelope, 5 seams) | 00-routing.md (companion-rail rendering stays coach.md) |
| Flight plan § (json/md, hand-crank, taxonomy, 8 render rules) | 00-routing.md |
| "What you do NOT do (recap of invariants)" | **DROPPED** — pure restatement of invariants 1–7, which move whole into SKILL.md; zero unique content |
| Re-entry closing line | coach.md (print-then-offer step 4 + mirror-the-flow §) |

### Dedupe inventory (shared block → single new home; T003–T006 cite this)

| Shared block | Where it recurs (sources) | Single home | Modules carry |
|---|---|---|---|
| 🚫 NO TIME ESTIMATES + CS bands | plan-3, plan-5, plan-6 family, plan-7, plan-8 headers | 00-routing.md § Shared conventions (full); SKILL.md invariant (one line) | one-line pointer |
| CS rubric (6 factors, bands) | plan-1b, plan-3 | 00-routing.md § Shared conventions | pointer; stage-specific scoring *logic* stays in-module |
| "Please deep think / ultrathink" preamble | nearly all 12 | 00-routing.md § Deep-think (declared once by dispatch) | stripped |
| YAML frontmatter | all 12 | dispatch SKILL.md only | stripped |
| Domain-context-loading preamble | plan-3, plan-5, plan-6, companion | 00-routing.md § Domain context loading | one-line actionable pointer; stage-specific domain *rules* stay |
| Router posture boilerplate (trailing "Harness seams (router-only)" / "Compound integration" sections) | plan-1b, plan-3, plan-5, plan-6, companion, plan-7, plan-8 | 00-routing.md § Harness router posture | stripped IF pure posture; concrete `/eng-harness-flow --event` invocations + envelope handling stay **byte-identical** (AC11) |
| One-time "No engineering harness detected" warning | the-flow, plan-1b, plan-6 | **NOT deduped** — stays verbatim in each module that prints it (modules stay self-contained for direct jump) | verbatim |

State-write ownership documented in 00-routing.md: guided dispatch is the only writer of `.the-flow-state.json`/`the-flow.json`/`the-flow.md`; direct-jump modules never write them (artifact-discovery-by-existence keeps resume correct, same as direct `/plan-N` runs today).

Line counts: 00-routing.md 219 · coach.md 290 (vs 519 source — the delta is SKILL.md's share plus absorbed cross-skill boilerplate homes).

## T003–T006 — 11 stage modules (4 parallel extraction agents)

All 11 modules written to `skills/SDD/the-flow/references/stages/` following the T002 template (Purpose / Entry conditions / Inputs / Output contract / Next routing / ## Procedure) and dedupe inventory:

| Module | Source(s) | Lines src→mod | Notes |
|---|---|---|---|
| 10-explore.md | plan-1a (1033) | →1032 | §2c session-start seam verified as a 1765-byte exact substring |
| 20-specify.md | plan-1b (251) + plan-2 (71) | 322→320 | plan-2 absorbed as `## Re-entry: mid-plan clarifications`; plan-2 headings demoted ##→### to nest; both sources' stray unmatched ``` fences dropped (source rendering bug) |
| 25-workshop.md | plan-2c (619) | →622 | 18 ZWSP-escaped nested fences + all diagrams count-verified |
| 30-architect.md | plan-3 (417) | →415 | G1–G7 + READY/DRAFT + Gate Matrix intact; `/validate-v2` auto-run kept as REAL skill invocation; 6 seam strings byte-identical |
| 35-adr.md | plan-3a (471) | →471 | no harness content in source |
| 50-phase-tasks.md | plan-5 (399) | →403 | T000/T0xx seam-row templates byte-identical |
| 60-implement.md | plan-6 (234) | →231 | §2a pre-implement + step-7 phase-end byte-identical; warning blockquote verbatim; both `/plan-6a` auto-runs → "read `62-progress.md` and follow it" with identical flags |
| 61-implement-companion.md | companion (424) | →432 | minih protocol untouched; final-task call → 62-progress with identical six flags incl. `--companion-run-id`/`--companion-slug`; trailing harness section KEPT (unique minih-vs-harness line) |
| 62-progress.md | plan-6a (157) | →166 | Step 9 (a–e) debrief chain whole; directly invocable as `/the-flow 6a` |
| 70-review.md | plan-7 (412) | →421 | fix-loop handovers → `/the-flow 6`/`/the-flow 5` |
| 80-merge.md | plan-8 (1039) | →1048 | **PROCEED-only execute contract survived word-for-word** (zero diff hunks in the approval-gate region); plan-complete seam byte-identical |

**Companion debrief chain (T005 done-when)** — diff-verified, every piece landed: drain ping (62 §9a, byte-identical) → control:stop (62 §9b) → farewell read (62 §9c) → reconcile (62 §9d) → magicWand surface (62 §9e, fix-dossier command → `/the-flow 5 --fix`); caller-side delegation + dead-companion contingency stay in 61. Nothing dropped.

**AC11 independent parity grep** (run by orchestrator while sources still on disk; `grep -o 'eng-harness-flow --event …'` multisets src vs module): identical for 10/30/35/50/60/61/62/70; three modules carry **additive** header/next-routing mentions only (20-specify +1 post-spec, 25-workshop +1 post-spec, 80-merge +1 plan-complete) — zero source invocations lost. PASS.

**Retired-slug scan across all 11 modules**: only the `*(absorbed from …)*` header attribution lines hit (allowed).

## T008 — Bundled references updated

- `getting-started.md`: full rewrite to the consolidated surface (user explicitly requested a thorough pass). ~70 command conversions `/plan-N` → `/the-flow N` (seam table, both mermaid diagrams' labels, walkthrough, Quick Reference + added the missing `3a · adr` row, directory annotations); NEW section "One public skill, progressive disclosure" documenting guided vs direct-jump load paths + the 11-row stage map + old-slug translation; exactly ONE historical "What changed (formerly)" note retained (line 36). Versioned-slug grep: 1→0; bare `/plan-N` grep: 68→1 (the allowed historical note).
- `flight-plan.template.json` (8 edits) + `flight-plan.schema.json` (2 description strings) + `flight-plan.template.md` (1 edit): command examples → `/the-flow N` grammar; `/eng-harness-flow` entries untouched; **both JSON files re-validated** (`python3 json.load` → VALID); zero structural/enum/type changes (minih shape contract untouched).

## T007 — Dispatch SKILL.md rewritten

- `skills/SDD/the-flow/SKILL.md`: **83 lines** (`wc -l`; cap ≤150 — no overflow contingency needed). Frontmatter description **976 chars** (≤1024) containing all required trigger words (research, spec, architect, implement, review, merge) + the direct-jump grammar + every stage id/name.
- Contents: two load paths (guided = 00-routing + coach + current module only; direct jump = one module, no state writes), 11-row stage table (numbers AND names), 12-row old-slug translation table + unmapped-slug fallback ("print the bare stage alias and ask — never guess"), 10 hard invariants (the original 7 + no-time-estimates + harness-one-door + deep-think), state pointer.
- Method note: old 519-line SKILL.md was `rm`'d then rewritten fresh (full source was loaded verbatim in-session; tag `pre-flow-consolidation` holds the restore copy).

## T009 — Atomic deletion

- Removed the 12 absorbed skill folders + `scripts/migrate-skills.py` (inert — source `agents/v2-commands/` no longer exists; git history is the archive).
- `ls skills/SDD/` now: **the-flow + exactly the 12 utilities** (code-concept-search-v2, deepresearch-v2, didyouknow-v2, flowspace-research-v2, htmlify-v2, install-hve-core-rpiv, plan-0-v2-constitution, plan-2b-v2-prep-issue, plan-6b-worked-example, plan-v2-extract-domain, util-0-v2-handover, validate-v2). AC1 ✓.

## T010 — Catalog sweep (+ user-directed scope additions)

**Planned surfaces**:
- `README_AGENTS.md`: 12 retired rows + old the-flow row → ONE new `the-flow` row; both install examples → `--skill the-flow`; section heading now carries the accurate count (13 SDD skills: 1 main flow + 12 utilities); one slug-free historical note. 14 retired-slug lines → 0.
- `INSTALL.md` L91: `--skill plan-1a-v2-explore` → `--skill the-flow` (single surgical edit; file carries unrelated uncommitted user mods).
- `docs/skills-pipeline/README.md`: intro reframed (one skill + stage modules); all rows → `/the-flow <id>` (+ module path) keeping legacy column; added missing `/the-flow 8` row; harness row kept (in-cell slug mentions reworded). 12 → 0.
- `CLAUDE.md`: layout-tree comments updated; "## Editing existing v2 skills" → "## Editing the SDD pipeline (`the-flow`)" (dispatch vs modules, consolidation date, rollback tag); migrate-skills.py claim corrected ("git history retains it") + its Testing-changes bullet dropped; sync lists updated (no `.vscode`).
- `skills/SDD/validate-v2/SKILL.md`: the five Detection Signal rows reworded to artifact-form ("Tasks dossier just produced (phase-tasks stage)…"), table shape unchanged — the documented non-goal exception.

**Discovered + folded in (AC9/T011 require repo-wide zero)**:
- `README.md` L260 → "The architect stage (`/the-flow 3`)…" (L258's `/plan-4-complete-the-plan` mention kept — explicitly historical). Surgical; file has unrelated uncommitted user mods.
- **DEVIATION (logged)**: four utility skills carried retired-slug cross-reference lines — `plan-0-v2-constitution` (L470), `plan-2b-v2-prep-issue` (L279–280), `util-0-v2-handover` (L98/160/249), `code-concept-search-v2` (L435). Reference-lines ONLY updated to `/the-flow N` grammar; bodies otherwise untouched. This narrows the spec's "utilities byte-identical" non-goal — required by AC9's zero-live-references criterion; flagged for /plan-7 review.
- **USER-DIRECTED (mid-build instruction)**: `.vscode/` deleted **entirely** ("oh .vscode is an old folder, that should just be blown away") — it held 13 stale snippet copies of retired skills (incl. pre-030 orphans plan-3-v2/plan-4-v2/plan-1b-v2), 100+ `mcp.json.backup-*` files, a 396KB generated codebase pack, Peacock-only settings.json, and an installer-regenerated mcp.json. Also removed: the `.vscode` sync block in `scripts/sync-to-dist.sh` (section 7) and the stale `src/jk_tools/.vscode/` mirror dir (sync no longer produces it). `install/agents.sh` still regenerates `./.vscode/mcp.json` at setup — documented in CLAUDE.md.

## T011 — Structural validation (all four checks PASS)

1. `scripts/check-skill-slugs.sh` → **exit 0** ("OK: 15 skills, no slug collisions").
2. `python3 json.load` on `flight-plan.schema.json` + `flight-plan.template.json` → **both VALID**.
3. `wc -l skills/SDD/the-flow/SKILL.md` → **83** (≤150 ✓).
4. Repo-wide retired-slug grep (excluding `docs/plans/**`, `src/jk_tools/**`, `.git`, gitignored `scratch/`) → hits are **exactly** the dispatch's 12-row translation table + the 12 `*(absorbed from …)*` provenance attribution lines inside the modules (incl. 20-specify's Re-entry heading). Zero other live references. The attribution lines are intentional historical mentions (spec AC9 wording allows them; plan T011's stricter "only the translation table" is noted — flagged for /plan-7 to confirm acceptability).

## T012 — Deploy + tidy

- **Baseline `just skills-orphans`** (captured pre-deploy): `~/.agents/skills` 21 orphans (the 12 retired slugs + the external eng-harness family + engineering-harness-setup + shopping-hunter); `~/.claude/skills` 23 (those + harnessability-assessment + pack-code); `~/.codex/skills` clean.
- `just install-skills-from-source` → ✅; canonical `~/.agents/skills/the-flow` **diff -rq clean against source** (83-line SKILL.md + references/{00-routing,coach,getting-started,flight-plan.*} + stages/ 11 modules), symlinked views for Claude Code + Pi.
- **Tidy**: removed exactly the 12 retired slugs from `~/.agents/skills` + `~/.claude/skills` (24 removals; `~/.pi/skills` absent, `~/.copilot/skills` absent). Hand-installed/external skills (eng-harness-*, pack-code, shopping-hunter, harnessability-assessment, engineering-harness-setup) deliberately untouched.
- **Post-tidy**: orphan report contains **none** of the 12; `just doctor-skills` → canonical store 24 skills, all expected symlinks valid, no dangling links, no legacy orphan stores. One **pre-existing** warning (present in baseline, unrelated to this plan): `engineering-harness-setup` is a real dir in `~/.claude/skills` duplicating canonical (will drift) — external family, left for its owner; fix line printed by doctor.
- **Live evidence**: this session's skill-discovery list refreshed mid-build — the 12 retired slugs no longer appear; `the-flow` surfaces with the new dispatch description. AC10 ✓.

## T013 — Behavioural drive (all four observations)

- **(a) Live resume of THIS flow (030)**: state `awaiting-6`, stale `pending_command` = `/plan-6-v2-implement-phase --plan "…"` → deployed dispatch translation table (SKILL.md:60) maps `plan-6-v2-implement-phase → 6` → `references/stages/60-implement.md`; routing-table artifact for `awaiting-6` (`execution.log.md`) exists → resume advances to review. Exercised live: this build session itself ran under the translated command, and at phase end the guided coach advanced the state to `awaiting-7` with the **new-grammar** `pending_command` (`/the-flow 7 --plan "…"`), per the contract "rewrite in public grammar on the next state write". AC12 ✓.
- **(b) Dry verification (no state writes)**: 027 `pending_command` `/plan-8-v2-merge …` → table row SKILL.md:64 → stage 8 → `80-merge.md` (exists, deployed). 029 `/plan-7-v2-code-review …` → SKILL.md:63 → stage 7 → `70-review.md` (exists, deployed). Both flows untouched.
- **(c) Direct jump equivalence**: stage-table row `| 6 | implement | references/stages/60-implement.md |` serves both `/the-flow 6 --phase … --plan …` and `/the-flow implement --phase … --plan …` — one row, one module path, no other module implicated. AC5 ✓.
- **(d) Guided load set**: dispatch guided path names exactly `00-routing.md` + `coach.md` + the current stage module (steps 1–2); deployed copy verified identical to source via the canonical diff. AC4 ✓.

## T014 — Harness phase-end (`--event phase-end`)

- Signals unchanged from T000 (router installed; no `.harness/`; governance owed). Seam fired with `--prompt-optional=false` → **envelope `decision: noop`** — quiet, nothing surfaced, standard testing closed out the phase. Advisory, never a gate.

---

## Phase complete — summary

**Tasks**: 15/15 `[x]` (T000–T014). **ACs**: 12/12 met (mapping in plan). **Progress tracking**: stage 6a (plan-6a) was retired *by this very phase* — its per-task duties were performed inline (task-table checkboxes + this log after every task), and its body lives on as `references/stages/62-progress.md`.

**Deviations & judgment calls** (for /plan-7):
1. Four utility skills had retired-slug cross-reference lines updated (`plan-0-v2-constitution`, `plan-2b-v2-prep-issue`, `util-0-v2-handover`, `code-concept-search-v2`) — narrows the "utilities byte-identical" non-goal; required by AC9.
2. `.vscode/` deleted entirely (user-directed mid-build: "that should just be blown away") + sync-block removal in `sync-to-dist.sh` + stale `src/jk_tools/.vscode` mirror removal.
3. Module header `*(absorbed from …)*` attribution lines kept (intentional provenance; the only retired-slug hits outside the translation table).
4. Stray unmatched code fences in plan-1b/plan-2 sources dropped during module extraction (source rendering bug, agent-reported).
5. Pre-existing, untouched: `engineering-harness-setup` real-dir duplicate in `~/.claude/skills` (external family; doctor prints the fix).

**Rollback** (AC7): `git checkout pre-flow-consolidation -- skills/SDD scripts/migrate-skills.py && just install-skills-from-source` (tag at `44ba70f`). Note `.vscode/` removal and catalog edits are separate paths — full revert would be `git checkout pre-flow-consolidation -- . ` for tracked files.

**Suggested commit message** (for stage 8, on explicit PROCEED):

```
feat(skills)!: consolidate the 13 main-flow SDD skills into one progressive-disclosure the-flow skill (plan-030)

- skills/SDD/the-flow: 83-line dispatch SKILL.md (stage table, old-slug translation,
  hard invariants) + references/00-routing.md (engine) + references/coach.md (voice)
  + references/stages/ (11 modules, near-verbatim re-housing, harness seams byte-identical)
- delete the 12 absorbed plan-* skill folders + inert scripts/migrate-skills.py
- catalog sweep: README_AGENTS, INSTALL, README, docs/skills-pipeline/README, CLAUDE.md,
  validate-v2 detection rows (documented exception), 4 utility cross-ref lines
- remove stale .vscode/ entirely (+ sync block + mirror dir) — user-directed
- rollback anchor: git tag pre-flow-consolidation

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

---

## Review fix pass — FT-001..FT-005 (review #1 verdict: REQUEST_CHANGES, 2026-06-11)

Driven by `reviews/fix-tasks.md`. Harness seams: **not re-fired** — fix loop within the already-opened phase; both seams nooped quietly at build time with `--prompt-optional=false` (router installed, repo unprovisioned). Standard testing applies.

### FT-001 (HIGH) — plan-complete ownership moved back to merge ✅

`references/stages/61-implement-companion.md`, **5 sites** (review cited 386-419; header L8 + intro L32 + seams section L424-430 also carried it):
- L8 header Next routing: branch — next phase → `/the-flow 5`; **final phase → `/the-flow 8`** (stage 80 owns `plan-complete`).
- L32 intro bullet: "routes through `/eng-harness-flow --event plan-complete`" → "stage 80 (merge) fires after merge execution — never this stage".
- §5: the `plan-complete` invocation **removed**; replaced with explicit ownership note + final-phase route to `/the-flow 8`.
- Phase-complete next-step: branched (another phase → `/the-flow 5` + re-run 6c; final phase → `/the-flow 8`).
- Harness-seams section: "three seams" → **"two seams"** + ownership note.

**AC11 parity delta (deliberate, evidence)**:
```
$ git grep -h -o 'eng-harness-flow --event [a-z-]*' pre-flow-consolidation -- skills/SDD | sort | uniq -c
   7 eng-harness-flow --event          10 …phase-end    9 …plan-complete
  12 …post-spec                        10 …pre-implement 3 …session-start
$ grep -rho 'eng-harness-flow --event [a-z-]*' skills/SDD/the-flow | sort | uniq -c
   8 eng-harness-flow --event          10 …phase-end    8 …plan-complete   ← −1 = FT-001
  13 …post-spec                        10 …pre-implement 3 …session-start  ← +1s = additive headers (build-logged)
```

### FT-002 (HIGH) — architect READY routing branched by Mode ✅

`references/stages/30-architect.md`, **4 sites** (review cited 391-415; header L8 + intro L16 also carried it):
- L8 header Next routing + L16 Status intro + terminal-output block + trailing next-steps: all now branch — **Simple READY → `/the-flow 6 --plan`** (inline tasks); **Full READY → `/the-flow 5 --phase --plan`**; DRAFT unchanged (re-run `/the-flow 3`). Matches `00-routing.md` stage machine (`awaiting-3 ──Simple,READY──▶ awaiting-6`).

### FT-003 (MED) — live retired `/plan-*` references removed ✅

Review's 5 files **plus** widened README narrative hits its grep pattern missed (L128, 153, 179, 314, 327, 342):
- `README.md`: 11 narrative conversions (`/plan-0-constitution`, `/plan-1a-explore`, `/plan-1b-specify`, plan-4/plan-5 Simple-mode line, `/plan-2b-prep-issue`, `/plan-3-architect`, "consumable by /plan-5" → mode-branched, `/plan-5-phase-tasks-and-brief`, `/plan-6-implement-phase`, `/plan-6a-update-progress`, `/plan-7-code-review`). L258 kept — labeled "Earlier versions" (historical).
- `INSTALL.md`: SDD row → "`the-flow` … plus 12 utility skills", count 26 → **13**.
- `plan-2b-v2-prep-issue/SKILL.md` (3 sites), `code-concept-search-v2/SKILL.md` (3 bullets), `plan-0-v2-constitution/SKILL.md` (1 site): cross-refs → `/the-flow <id>` grammar.

**Evidence**:
```
$ grep -c -E '/plan-[0-9]' README.md
1        ← only L258, labeled historical
$ rg -n '<review pattern + widened>' README.md INSTALL.md README_AGENTS.md docs/skills-pipeline/README.md CLAUDE.md skills/SDD skills/general
→ remaining hits ONLY in: dispatch translation table (SKILL.md:60-61), module provenance lines,
  getting-started.md:36 (labeled "formerly"), skills-pipeline README heritage column, 30-architect.md:14 ("legacy")
```

**Flagged, not fixed**: `docs/skills-pipeline/codebase.md` — a 9,738-line committed code2prompt pack of the **long-deleted v1 `agents/commands/`** directory ("Project Path: commands"); saturated with `/plan-N` references. Stale generated artifact, not live guidance — candidate for deletion, awaiting user say-so.

### FT-004 (MED) — Domain Manifest expanded ✅

Plan §Domain Manifest: +4 rows — `README.md`, `scripts/sync-to-dist.sh`, the 4 touched utility SKILL.md files, and the `.vscode/` deletion (+ mirror). Manifest now covers every changed non-plan file in the diff.

### FT-005 (MED) — reproducible evidence captured ✅

This section + the parity/grep blocks above. Additional re-runs (exact commands + key output):
```
$ wc -l skills/SDD/the-flow/SKILL.md
      83                              ← AC2
$ find skills/SDD -mindepth 1 -maxdepth 1 -type d | sort | sed 's#^skills/SDD/##'
code-concept-search-v2 … the-flow … validate-v2   (13 dirs: the-flow + 12 utilities)  ← AC1
$ grep -n '| 6 | implement |' skills/SDD/the-flow/SKILL.md
39:| 6 | implement | `references/stages/60-implement.md` | …   ← AC5: id + name = one table row = one module
$ just install-skills-from-source && diff -rq skills/SDD/the-flow ~/.agents/skills/the-flow
(no output — canonical store byte-identical to source)            ← AC10, post-fix redeploy
$ just doctor-skills | tail
Orphan real-dir stores at legacy paths: ✅ None found
Dangling symlinks under ~/.claude/skills: ✅ None
```
AC4 (guided load set) live evidence: this session's post-compact resume Read exactly `SKILL.md` + `references/00-routing.md` + `references/coach.md`, then `references/stages/60-implement.md` only on the accepted fix-pass — the progressive-disclosure contract observed in practice.

### Fix-pass summary

5/5 fix tasks applied; modules **redeployed** (canonical store diff-clean); AC9/AC11 plan annotations amended. One new discovery flagged (stale `codebase.md` pack). Next: re-run `/the-flow 7` → target zero HIGH/CRITICAL.

### Post-fix addendum — codebase.md removed (user-directed)

User: "remoe codebase.md" → `rm docs/skills-pipeline/codebase.md` (the 9,738-line code2prompt pack of the deleted v1 `agents/commands/`). Reference check first: zero live references (only unrelated `generate-codebase-md.sh` alias in CLAUDE.md). The file was **untracked** — never committed, so no Domain Manifest row and no diff impact; pure local cleanup. The AC9 slug grep no longer trips on it.

---

## Close-out — re-review waived, merged to main (2026-06-11)

User: *"no its finde, commit and push. close it out"* — re-review **waived** (fix-pass evidence accepted); commit + push **explicitly authorized**. Work happened directly on main per repo convention (no branches), so merge = commit + push. The `plan-complete` harness seam nooped quietly (router installed, repo unprovisioned, `--prompt-optional=false`). Flow state set to `complete` (6/6 milestones); rollback anchor stays available: `git tag pre-flow-consolidation` @ `44ba70f`.
