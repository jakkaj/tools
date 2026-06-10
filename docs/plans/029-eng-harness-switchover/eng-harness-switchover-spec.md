# eng-harness switchover — route the SDD pipeline through `/eng-harness-flow`

**Mode**: Simple

> 📚 Specification incorporates findings from [research-dossier.md](./research-dossier.md) (~130 findings, 8 subagents + first-hand reads of both repos).

## Summary

Replace this repo's four local harness skills (`skills/harness/harness-1-boot`, `-2-backpressure`, `-3-observe`, `-4-retro`) with the external **eng-harness** family from `AI-Substrate/harness-engineering`, reached **exclusively** through its stateless router skill **`/eng-harness-flow`**. Every harness touchpoint in the SDD pipeline and `the-flow` becomes a single router call with seam context. The four local skills are deleted; everything harness-flavoured in this repo is removed except an explicit keep-list; docs and tooling are repointed. Two-layer detection (router installed? repo harness provisioned?) yields **one calm warning** when absent — then the pipeline proceeds silently with standard testing.

**Hard constraint (user, verbatim)**: *"we only call the main eng-harness-flow skill, we should never call the others directly, they might change later or move around."* Child `eng-harness-*` slugs never appear in this repo's live files.

**Side-by-side principle (user, 2026-06-10)**: the SDD pipeline and the engineering harness *work side by side in the same context — but that is all*. SDD calls the router at its seams; the harness, once alive in the session context, runs its own loop (including observe). SDD never operates harness internals.

## Goals

- One stable public harness surface: `/eng-harness-flow` + its `--event` vocabulary. Children are private and free to move.
- Every surviving seam routes through the router with context (`--spec` / `--plan-dir` / `--phase`); SDD keeps only *seam placement*, the router owns *routing*.
- **Observe leaves SDD entirely**: no SDD skill instructs, calls, or describes in-flight capture. Observe is an engineering-harness in-context concept — established when the harness comes into operation (session-start routing) and run by the harness itself.
- Graceful two-layer degradation: not installed → one calm warning + install hint, then silence; installed-but-unprovisioned → delegate to the router, no SDD-side nagging.
- Aggressive removal with an explicit keep-list (below): default posture is *remove*; we are selective only about what stays.
- `the-flow` (SKILL.md + flight-plan schema/templates + `references/getting-started.md`) tells the new story.
- Plan-027's ownership claim explicitly superseded; freeze override #2 recorded in CLAUDE.md.

## Non-Goals

- No changes to the substrate repo — cross-repo asks (custody transfer of the retro schema; fix its "frozen mirror" reverse-pointer; resolve its README:44 follow-up note) are **logged as follow-ups**, not done here.
- No provisioning of an engineering harness for this repo (separate effort, per standing user direction).
- No observe instructions anywhere in SDD skills — not the CLI verb, not `at=observe`, nothing. (Harness's concern.)
- No changes to the retro JSON schema's *meaning* (cross-system contract with minih).
- No rewriting of `docs/plans/**` history (forward-pointers only).
- No gates, scores, thresholds, or blocking behaviour — every harness touchpoint stays advisory/best-effort.
- No new persisted state files (KISS — detection computed at call time).

## Target Domains

> No `docs/domains/` registry exists; domains below are spec-level. (Registry creation is out of scope.)

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| sdd-pipeline | existing (de facto: `skills/SDD/*`) | **modify** | All 10 plan-* skills + the-flow rewired to call the router only; observe + sentinel + harness file-tests removed |
| harness-seam | **NEW** (conceptual contract) | **create** | The stable cross-repo contract this repo codes against |
| eng-harness | external (substrate repo) | **consume** | The router + family consumed via `npx skills add AI-Substrate/harness-engineering`; never modified here |

### New Domain Sketches

#### harness-seam [NEW]
- **Purpose**: The frozen contract between the SDD pipeline and the external harness family — everything this repo may rely on.
- **Boundary Owns**: the `/eng-harness-flow` slug + parameter contract (`at=`, `--event` seams, `--plan-dir`, `--spec`, `--phase`, `--prompt-optional`, `--json`); the `--json` routing envelope (`decision: route|redirect|noop|ambiguous`, `command`, `next_suggested`, `flags`); artifact `<plan-dir>/backpressure-coverage.md` (name, location, Certainty + Phase 0 shape); boot verdict vocabulary `healthy/SLOW/UNHEALTHY/UNAVAILABLE` (casing per the router contract, SKILL.md:61); the `[s/t/p/e/d/a]` drain prompt (SDD narrates what the user just saw, never implements); `retro.schema.json` shape + `schema_version` semver.
- **Boundary Excludes**: child skill slugs, `.harness/**` internals, the harness CLI's verbs (incl. observe), drain/harvest choreography, retro record production — all belong to **eng-harness**. Plan-folder layout belongs to **sdd-pipeline**; the harness writes into it only by invitation (`--spec`/`--plan-dir`).
- **One-way rule**: `sdd-pipeline → /eng-harness-flow` ONLY. The harness never calls SDD skills.

## SDD seam set (the only harness touchpoints that survive)

| Seam | Where | Router call |
|---|---|---|
| session start | the-flow entry / first auto-firing skill | `--event session-start` (router handles boot + any pending-drain routing) |
| post-spec | plan-1b "next steps" + the-flow `awaiting-1b` | `--event post-spec --spec <path>` (recommended, skippable) |
| pre-implement | plan-6 / plan-6-companion before first task; plan-3 N.0 / plan-5 T000 emitted rows | `--event pre-implement --phase <id> --plan-dir <p>` (verdict narrated; UNHEALTHY → ask human, UNAVAILABLE → proceed) |
| phase end | plan-6/companion end-of-phase; plan-3 N.z / plan-5 T0xx emitted rows | `--event phase-end --plan-dir <p>` |
| plan complete | companion final debrief, plan-7/plan-8 end, the-flow `complete` | `--event plan-complete` |

Retired (not rewired): all during-work observe seams; all buffer-existence checks (router owns drain-vs-harvest); plan-6a's retro writes; plan-2c's no-drain special case; plan-7's sentinel-audit grep. The `task-pause` event goes unused by SDD.

## Testing Strategy

- **Approach**: Lightweight — deterministic grep-gates as every task's Done-When (the proven plan-024 pattern: "the greps ARE the tests"), plus the repo's own scripts.
- **Rationale**: Markdown/skill repo; no CI; grep gates + `check-skill-slugs` + `doctor-skills` + `skills-orphans` + install smoke are the available deterministic sensors.
- **Focus Areas**: forbidden-slug greps returning only whitelisted historical lines; positive greps (`eng-harness-flow` present in every rewired skill); `scripts/check-skill-slugs.sh` exit 0 / 28 skills; `just doctor-skills` clean; `just skills-orphans` tidy-then-baseline; install smoke inspecting installed `getting-started.md` content.
- **Mock Usage**: none needed — the originally planned synthetic harvest-JSON check is moot because `scripts/compound-value.sh` + `just compound-value` are **removed** (harness tooling moves upstream with the concept).
- **Excluded**: no flight-plan schema validator exists (known gap, accepted); no automated test of the router itself (substrate repo's job).

## Documentation Strategy

- **Location**: No new documents. Updates to existing surfaces are in-scope tasks: CLAUDE.md, README.md, README_AGENTS.md, INSTALL.md, MIGRATION.md, `docs/skills-pipeline/README.md`, slim `docs/harness/README.md` rewrite, and the-flow's bundled `references/getting-started.md` (the seam contract's user-facing home — it travels with the skill).
- **Rationale**: Encode-don't-document; the contract lives where users already look.

## Removal Plan — explicit keep-list; everything else harness-flavoured goes

**KEEP (selective, with reasons):**

| Keep | Why |
|---|---|
| `docs/harness/schemas/` (retro + `system.compound` + `system.minih` + fixtures + README) | Published `$id` home of the cross-system shape contract; minih agreement is shape + `schema_version`. Only stale description strings patched. **Custody transfer to the substrate repo logged as the cross-repo follow-up** — removal here happens then, not now. |
| `docs/harness/agents/**` (1 committed retro) | Frozen institutional history; read by plan-1a prior-learnings mining and by upstream harvest as a legacy path. Read-only forever. |
| `docs/harness/README.md` | Survives as a **slim rewritten pointer**: "legacy ledger — records frozen; loop now lives in AI-Substrate/harness-engineering via /eng-harness-flow". |
| `just doctor-skills` / `just skills-orphans` / `check-skill-slugs.sh` | Generic skill-deploy tooling (minus the schema-drift block); needed for the tidy + verification. |
| `docs/plans/**` harness mentions | Immutable history; forward-pointers atop 024/027 only. |

**REMOVE (everything else):**

- `skills/harness/` — all four skills incl. the bundled `references/retro.schema.json` deploy copy.
- `docs/harness/.disabled` concept — every check site (~12) deleted; opt-out is conversational.
- `docs/harness/_buffers/` — entire dir (README + .gitignore); buffer concept now `.harness/temp/`, CLI-owned, and not in upstream's legacy-read list.
- All `docs/project-rules/engineering-harness.md` (+ legacy names) file-tests in SDD skills — replaced by router delegation.
- All during-work observe instructions in SDD skills (plan-1a/2c/5/6/6-companion/7/8 "silently call harness-3-observe" sections).
- plan-6a's direct `.retro.md` writes (orchestrator + companion farewell retros) — duty dropped.
- plan-6/6-companion's inline Boot→Interact→Observe pre-flight re-implementation and plan-7's Subagent-6 harness-validation coupling — replaced by `--event pre-implement` routing + verdict handling (vocabulary matched to the router contract: `healthy/SLOW/UNHEALTHY/UNAVAILABLE`).
- `justfile:326–339` schema-drift block + `just compound-value` recipe + help-text lines + `scripts/compound-value.sh` — harness tooling moves upstream with the concept. (Note: this retires the RV-002-encoded harvest-JSON convenience — recorded deliberately; upstream harvest prints its own curated view and `--json`.)
- the-flow `/harness-1..4` alias rows; `/plan-2d` becomes a thin repoint to `/eng-harness-flow --event post-spec`.
- Deployed copies: `~/.agents/skills/harness-{1-boot,2-backpressure,3-observe,4-retro}` + matching `~/.claude/skills/` symlinks (literal slugs, both stores).

## Complexity

- **Score**: CS-4 (large)
- **Breakdown**: S=2, I=2, D=1, N=1, F=1, T=2 (P=9)
- **Confidence**: 0.85
- **Mode note**: User chose **Simple** deliberately despite the CS-4 rubric (recorded override): single-phase plan, strictly ordered task train, **landed all at once as one commit** (user decision).
- **Assumptions**: substrate family installs cleanly via `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`; router `--event` contract stable as read 2026-06-10; `backpressure-coverage.md` path/shape identical both sides (verified).
- **Dependencies**: the external family must be installed locally before the rewired seams are exercised (task 0).
- **Risks**: see Risks & Assumptions.
- **Phases**: 1 — ordered task train within one landing: (0) install external family + verify router resolves → (1) rewire seams + remove observe/sentinel/file-tests across the 10 SDD skills → (2) plan-3/plan-5 template emission → (3) docs + tooling sweep (incl. removals) → (4) the-flow + references **last among skill edits** (PL-12: installed copies drive the session) → (5) delete `skills/harness/` + deploy tidy + forward-pointers + verification greps. All in **one commit** (user preference; user executes the commit — git is agent-read-only).

## Detection & warning design (core requirement)

- **Layer 0 — opt-out**: none on disk. The `.disabled` sentinel concept is **removed**; opt-out is conversational, matching upstream.
- **Layer 1 — router installed?** Deterministic probe at pipeline entry (the-flow start / first auto-firing skill): `test -f ~/.agents/skills/eng-harness-flow/SKILL.md` (canonical store), fallback `~/.claude/skills/eng-harness-flow/SKILL.md`. On miss, print **exactly one** calm warning, then silently omit every harness touchpoint for the rest of the flow:
  > ⚠️ No engineering harness detected — the eng-harness skills aren't installed. Continuing without one: standard testing applies, nothing else changes. (To add the harness loop: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`.)
- **Layer 2 — repo harness provisioned?** Router installed → call `/eng-harness-flow --event <seam> [--json]` and act on the envelope. `decision: route` → print-then-offer the returned command. Setup-routing/`noop` (repo unprovisioned) → one calm line the first time (*"No engineering harness in this repo — proceeding without one; say 'set up a harness' anytime."*), then `--prompt-optional=false` on subsequent seam calls so optional offers don't re-nag. **Never** copy the router's signals A–F into SDD skills — delegate, don't reimplement.
- **Warn once per flow** (FlowSpace/minih precedent): detect at one early point, record the outcome once in the artifact/EXEC_LOG, branch silently downstream.

## Acceptance Criteria

1. **Router-only**: `grep -rn "harness-1-boot\|harness-2-backpressure\|harness-3-observe\|harness-4-retro" skills/ justfile scripts/ CLAUDE.md README*.md INSTALL.md MIGRATION.md docs/skills-pipeline/ docs/harness/` returns only whitelisted historical lines (MIGRATION cleanup note; CLAUDE.md freeze-audit paragraph). No child `eng-harness-[0-9]` slug appears in any live file.
2. **Seams rewired or retired**: the five surviving seams route via `/eng-harness-flow --event …` with context; every other seam in the dossier's 42-row map is removed. `grep -rln "eng-harness-flow" skills/SDD/` lists every rewired skill.
3. **Observe gone from SDD**: no SDD skill contains observe instructions — `grep -rni "harness observe\|harness-3-observe\|silently call" skills/SDD/` → no harness-observe hits (case-insensitive `-i` is load-bearing: files contain both "Silently call" and "silently call").
4. **Sentinel gone**: `grep -rn "\.disabled" skills/ justfile scripts/ CLAUDE.md README*.md INSTALL.md MIGRATION.md docs/skills-pipeline/ docs/harness/README.md` → no hits (schemas/fixtures + `docs/plans/**` history exempt).
5. **Templates emit router syntax**: plan-3's N.0/N.z rows + `## Harness Loop` section and plan-5's T000/T0xx rows + Context Brief touchpoints generate `/eng-harness-flow --event …` lines — no stale names propagate into future artifacts.
6. **Deletion clean**: `skills/harness/` removed; `scripts/check-skill-slugs.sh` exits 0 reporting 28 skills; `! grep -rn "skills/harness/" <live files>` passes; `docs/harness/_buffers/` gone; `scripts/compound-value.sh` + `just compound-value` + justfile drift block gone.
7. **Detection works (no-router case)**: with `eng-harness-flow` absent from skill stores, a fresh flow prints exactly one calm warning (copy above) and emits zero harness nodes/cues/tasks thereafter. Evidence level: live pre-install probe miss recorded before task 0's install + verbatim warning copy in rewired sources and installed copies (a full post-landing no-router run would require uninstalling the family — deliberately not staged; recorded decision).
8. **Detection works (router case)**: with the family installed, seams print-then-offer router commands; an unprovisioned repo gets the one-line note + setup option once, never per-seam nagging.
9. **the-flow updated**: alias table maps `/plan-2d` → `/eng-harness-flow --event post-spec` (child/`harness-N` slugs gone); flight-plan schema/template node `command` fields are router invocations; emission predicate uses the new detection; `references/getting-started.md` rewritten (incl. fixing its stale `docs/compound/` block); installed-copy smoke shows the new content.
10. **Docs truthful**: CLAUDE.md records freeze override #2 with audit trail (freeze paragraph never deleted) and re-freezes over `/eng-harness-flow` + `--event` vocabulary; README ownership line inverted; INSTALL category installs fixed; forward-pointers added atop plan-024 and plan-027 plan files; 027's ownership claim explicitly superseded; `docs/harness/README.md` rewritten as the slim legacy pointer.
11. **Deploy hygiene**: the four slugs tidied from `~/.agents/skills` + `~/.claude/skills` (literal slugs, both stores); `just skills-orphans` then shows only the known baseline (`engineering-harness-setup`, `shopping-hunter`, `pack-code` where present) **plus the legitimately-external eng-harness family installed at task 0** (expected orphans — external by design; the check is that no stale `harness-*` slugs remain); no dangling symlinks per `doctor-skills`.
12. **Contracts preserved**: `docs/harness/schemas/` untouched in meaning (description-string patches only); committed legacy retro left in place; drain `[s/t/p/e/d/a]` narration unchanged where it survives (the-flow explains what the user saw).

## Risks & Assumptions

| Risk | Mitigation |
|---|---|
| Freeze override #2 (2 days into reset window) confuses future agents | CLAUDE.md audit-trail paragraph; new frozen surface = the one router name (serves the freeze's intent better) |
| 027's ownership statements get "fixed" backwards later | Explicit supersession + forward-pointers atop 027 (and 024) |
| Editing the driver skills mid-session destabilises this very flow | Installed copies drive the session (PL-12); the-flow/plan-3 edits sequenced last |
| One-commit landing makes bisecting harder if something's off | Verification greps run pre-commit; rollback is a single revert |
| Hand-enumerated file lists drift | Every Done-When is a grep, never a list (PL-10) |
| zsh unquoted-var `rm` loop silently no-ops during deploy tidy | Literal slugs in the cleanup task (PL-06 gotcha) |
| Removing `compound-value` retires an RV-002-encoded gift | Deliberate, recorded here; upstream harvest provides the curated view + `--json` |
| Without observe instructions, will friction still get captured? | Yes — by the harness itself once in operation in-context (session-start routing); repos without a harness never had capture anyway |

## Open Questions

None blocking. **Defaults adopted** (override any time): six-seam router vocabulary available, SDD uses five (`task-pause` unused); flight-plan node types keep their stage names (`backpressure/harness-boot/harness-observe/harness-retro`) with router-invocation `command` fields; schema custody transfer = logged cross-repo follow-up; uncommitted README/INSTALL/MIGRATION renumber edits folded into this rewrite.

**Cross-repo follow-ups (for the substrate repo, logged not done):** take custody of the canonical retro schema (incl. `system.*` sub-schemas) + update its "frozen mirror" pointer; resolve its `skills/README.md:44` note about external tooling referencing old slugs (this plan resolves it); consider whether prior-learnings mining should have a sanctioned read surface (e.g. `at=retro-harvest --json`).

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| *(none)* | — | Design space covered by the research dossier + the substrate repo's own contract docs; remaining unknowns were decisions, now made | — |

## Clarifications

### Session 2026-06-10

- **Q: Workflow mode?** → **A: Simple** (user override of the CS-4 rubric; ordering handled as a strictly ordered task train; landed all at once as **one commit**).
- **Q: Testing strategy?** → **A: Lightweight** — grep gates as Done-When + repo scripts + install smoke.
- **Q: Mock usage?** → **A: Targeted** *(since mooted — `compound-value.sh` is removed, so the synthetic harvest-JSON check is no longer needed; effectively no mocks).*
- **Q: New documentation?** → **A: None** — existing surfaces updated in-scope; seam contract documented in the rewritten `getting-started.md`.
- **Q: Keep the `.disabled` sentinel?** → **A: Remove the concept entirely** — all check sites deleted; opt-out conversational (matches upstream). User also requested the harness-paths report (delivered in-session; encoded as the Removal Plan above).
- **Q: plan-6a's direct `.retro.md` writes?** → **A: Drop the duty** — plan-6a stops writing orchestrator/companion farewell retros; `docs/harness/agents/**` becomes read-only history.
- **Q: Observe routing?** → **A: Observe is not an SDD concern at all** (user, verbatim: *"'observe' means call the harness observe skill if its not alreafy present and in operation in teh context. that is how observe works, our skills will not do that anymore, observe is a engineering harness concept, not SDD. they work side by side in same context but that is all."*). All during-work observe instructions removed from SDD skills; the harness observes for itself once in operation in-context.
- **Q: Landing shape?** → **A: One cascade, all at once, one commit** (user: *"yep all at once. once commit."*). User executes the commit (git is agent-read-only).
- **Removal posture** (user): *"if its all going acros to harness concept now, lets be selective on what should not be removed"* → encoded as the explicit keep-list in `## Removal Plan`; everything else harness-flavoured is removed.
- **Agent Harness Readiness** (recorded, not asked — answer predetermined): **Continue without.** This repo is a markdown skills repo with no governance doc; it doubles as the live no-harness fixture for AC7. Provisioning remains the substrate repo's separate effort.
- **Hard constraint** (user, earlier this session): router-only access to the harness family; children are private.
