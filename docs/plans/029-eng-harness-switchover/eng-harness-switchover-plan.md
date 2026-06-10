# eng-harness Switchover Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-06-10
**Spec**: [eng-harness-switchover-spec.md](./eng-harness-switchover-spec.md)
**Status**: READY

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No `[NEEDS CLARIFICATION]` markers; 8 clarifications resolved in spec session 2026-06-10 |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` (directory absent) |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` |
| G4 | ADR Compliance | N/A | `docs/adr/` holds only a README — zero Accepted ADRs |
| G5 | Structure | PASS | All Simple-mode contract sections present |
| G6 | Testing Alignment | PASS | Lightweight per spec; every task's Done-When is a deterministic grep/script (PL-10: "the greps ARE the tests") |
| G7 | Domain Completeness | PASS | Documented exception: no `docs/domains/` registry exists; spec explicitly scopes registry creation out (§ Target Domains note) and Documentation Strategy is "no new documents" — the NEW `harness-seam` domain is formalised in the spec sketch + the rewritten `getting-started.md` (T010), not in a registry |

## Summary

The SDD pipeline currently reaches into its own four local harness skills by name across ~19 live files, plus a sentinel file, buffer dirs, governance file-tests, and inline harness re-implementations. This plan rewires the five surviving seams to a single external entry point — `/eng-harness-flow --event <seam>` from `AI-Substrate/harness-engineering` — deletes the four local skills and everything harness-flavoured outside an explicit keep-list, and adds two-layer detection with exactly one calm warning when no harness is available. Observe leaves SDD entirely (the harness observes for itself once alive in-context). The whole cascade lands as **one commit, executed by the user** (git is agent-read-only).

## Target Domains

> No `docs/domains/` registry exists; domains are spec-level (registry creation out of scope per spec).

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| sdd-pipeline | existing (de facto: `skills/SDD/*`) | **modify** | 10 plan-* skills + the-flow rewired to router-only; observe/sentinel/file-tests removed; docs + tooling swept |
| harness-seam | **NEW** (conceptual contract) | **create** | The frozen cross-repo contract: `/eng-harness-flow` slug + `--event` vocabulary + envelope + artifact shapes (documented in spec sketch + `getting-started.md`, not a registry) |
| eng-harness | external (substrate repo) | **consume** | Router + family installed via `npx skills@latest add AI-Substrate/harness-engineering`; never modified here |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/plan-1a-v2-explore/SKILL.md` | sdd-pipeline | internal | Session-start seam + detection; harness-context section replaced |
| `skills/SDD/plan-1b-v3-specify-and-clarify/SKILL.md` | sdd-pipeline | internal | Post-spec seam in next-steps; readiness machinery removed |
| `skills/SDD/plan-2c-v2-workshop/SKILL.md` | sdd-pipeline | internal | Compound block + no-drain special case removed |
| `skills/SDD/plan-5-v2-phase-tasks-and-brief/SKILL.md` | sdd-pipeline | internal | Emitted T000/T0xx rows → router syntax; brief touchpoints |
| `skills/SDD/plan-6-v2-implement-phase/SKILL.md` | sdd-pipeline | internal | Inline BIO pre-flight → `--event pre-implement`; phase-end seam |
| `skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md` | sdd-pipeline | internal | Same as plan-6 + debrief → `--event plan-complete` |
| `skills/SDD/plan-6a-v2-update-progress/SKILL.md` | sdd-pipeline | internal | Retro-writing duty dropped |
| `skills/SDD/plan-7-v2-code-review/SKILL.md` | sdd-pipeline | internal | Subagent-6 harness coupling + sentinel-audit grep removed |
| `skills/SDD/plan-8-v2-merge/SKILL.md` | sdd-pipeline | internal | Plan-complete seam |
| `skills/SDD/plan-3-v3-architect/SKILL.md` | sdd-pipeline | internal | Template emission (N.0/N.z, `## Harness Loop`) → router syntax; edited only after this architect run |
| `skills/SDD/the-flow/SKILL.md` | sdd-pipeline | internal | Alias table, routing cues, narration, detection — edited LAST (PL-12) |
| `skills/SDD/the-flow/references/flight-plan.schema.json` | sdd-pipeline | contract | Node types keep stage names; `command` fields become router invocations |
| `skills/SDD/the-flow/references/flight-plan.template.json` / `.md` | sdd-pipeline | contract | Worked examples updated to router commands |
| `skills/SDD/the-flow/references/getting-started.md` | harness-seam | contract | User-facing home of the seam contract; full rewrite incl. stale `docs/compound/` block |
| `skills/harness/harness-{1-boot,2-backpressure,3-observe,4-retro}/` | sdd-pipeline (legacy) | internal | **DELETED** (incl. bundled `references/retro.schema.json`) |
| `CLAUDE.md` | sdd-pipeline | internal | Compounding Value System rewrite; freeze override #2 audit trail |
| `README.md`, `README_AGENTS.md`, `INSTALL.md`, `MIGRATION.md` | sdd-pipeline | internal | Ownership line inverted; counts 32→28; folds uncommitted renumber edits |
| `docs/skills-pipeline/README.md` | sdd-pipeline | internal | Pipeline reference rows repointed |
| `docs/harness/README.md` | sdd-pipeline | internal | Rewritten as slim legacy pointer |
| `docs/harness/schemas/*` | harness-seam | contract | KEEP — description-string patches only; shape + `schema_version` untouched (minih contract) |
| `docs/harness/_buffers/` | sdd-pipeline (legacy) | internal | **DELETED** (buffer concept now upstream `.harness/temp/`) |
| `docs/harness/agents/**` | sdd-pipeline | internal | KEEP — frozen read-only history (prior-learnings mining + upstream legacy-read) |
| `justfile` | sdd-pipeline | internal | Drift block + `compound-value` recipe + help line removed |
| `scripts/compound-value.sh` | sdd-pipeline | internal | **DELETED** (harness tooling moves upstream; retires RV-002 convenience, recorded) |
| `docs/plans/024-harness-nucleus/harness-nucleus-plan.md`, `docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-plan.md` | sdd-pipeline | internal | Additive forward-pointers only (history never rewritten) |

## Key Findings

> Research: `research-dossier.md` (~130 findings, 8 subagents) stands in for fresh research; all live facts below re-verified by deterministic sweep on 2026-06-10.

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | **Router-only hard constraint** (user, verbatim): children are private and may move/rename | Every rewired call is `/eng-harness-flow --event …`; AC1 grep forbids any `eng-harness-[0-9]` child slug in live files |
| 02 | Critical | **eng-harness family NOT installed on this machine** (probe re-verified: no `eng-harness-flow` in either store) | T001 records the pre-install probe miss as live AC7 evidence *before* installing; T002 router smoke gives AC8 evidence after |
| 03 | High | **PL-12 — installed copies drive the session**; the-flow re-fires at every seam and plan-3 is running right now | the-flow edited LAST among skills (T010); plan-3 edited only after this architect run completes (T007) |
| 04 | High | **PL-06 — `npx skills add` never prunes**; deleting source leaves all four deployed copies live, and zsh unquoted-var rm loops silently no-op | T012 removes literal slugs from BOTH stores with literal paths, then verifies via `skills-orphans` |
| 05 | High | `just doctor-skills` drift block (justfile ~:326–340) hard-references `skills/harness/harness-4-retro/references/retro.schema.json` — breaks the moment the dir is deleted | T009 removes the block BEFORE T011 deletes the skills |
| 06 | High | `README.md`/`INSTALL.md`/`MIGRATION.md` carry uncommitted 3→4 renumber edits (git status confirmed) | T008 folds them into the rewrite — superseded in place, never reverted |
| 07 | Medium | `docs/harness/schemas/` is the published `$id` home of the cross-system shape contract (minih keeps its own copy) | KEEP; description-string patches only; custody transfer to substrate repo is a **logged cross-repo follow-up**, not done here |
| 08 | Medium | Backpressure artifact (`<plan-dir>/backpressure-coverage.md` — name, location, Certainty + Phase 0 shape) is identical in both systems | Seam rewiring leaves every artifact reference unchanged — only the producer changes (router-dispatched instead of local skill) |

## Implementation

**Objective**: Land the full switchover — install the external family, rewire five seams router-only, remove everything outside the keep-list, rewrite the-flow's story, delete + tidy + verify — as one strictly ordered task train in a single commit.

**Testing Approach**: Lightweight (per spec) — deterministic grep gates as every Done-When, plus `scripts/check-skill-slugs.sh`, `just doctor-skills`, `just skills-orphans`, and an installed-copy smoke. No mocks (compound-value tooling is removed, mooting the synthetic-JSON check).

### Seam & detection contract (paste-ready for T003–T010)

The five surviving seams — per the 42-row seam map in [research-dossier.md](./research-dossier.md), everything else (the 8 "Compound integration" blocks, during-work observe instructions, buffer-existence checks, plan-6a retro writes, plan-2c's no-drain case, plan-7's sentinel-audit grep, end-of-phase drain choreography) is **removed, not rewired**:

| Seam | Router call |
|---|---|
| session start | `/eng-harness-flow --event session-start` |
| post-spec | `/eng-harness-flow --event post-spec --spec <path>` |
| pre-implement | `/eng-harness-flow --event pre-implement --phase <id> --plan-dir <p>` |
| phase end | `/eng-harness-flow --event phase-end --plan-dir <p>` |
| plan complete | `/eng-harness-flow --event plan-complete` |

**Layer 1 (router installed?)** — probe at pipeline entry: `test -f ~/.agents/skills/eng-harness-flow/SKILL.md` (fallback `~/.claude/skills/eng-harness-flow/SKILL.md`). On miss, print exactly once, verbatim:

> ⚠️ No engineering harness detected — the eng-harness skills aren't installed. Continuing without one: standard testing applies, nothing else changes. (To add the harness loop: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`.)

…then silently omit every harness touchpoint for the rest of the flow (record the outcome once in the artifact/EXEC LOG; never re-warn).

**Layer 2 (repo harness provisioned?)** — router installed → call the seam with `--json` and act on the envelope (`decision: route|redirect|noop|ambiguous`). `route` → print-then-offer the returned command. Setup-routing/`noop` → one calm line the first time (*"No engineering harness in this repo — proceeding without one; say 'set up a harness' anytime."*), then `--prompt-optional=false` on later seam calls. Boot verdicts are narrated **verbatim from the envelope** — router vocabulary as read 2026-06-10: `healthy / SLOW / UNHEALTHY / UNAVAILABLE` (UNHEALTHY → ask the human; UNAVAILABLE → proceed, standard testing). **Never copy the router's internal signals into SDD skills — delegate, don't reimplement.** Contract reference for re-verification: `/Users/jordanknight/substrate/harness-engineering/skills/eng-harness-loop/eng-harness-flow/SKILL.md` (T001 re-checks it before any rewiring).

### Paste-ready (T008): CLAUDE.md freeze-override #2 paragraph

Append to the existing Vocabulary-freeze paragraph (never delete the original text):

> **Override #2 (plan-029, 2026-06-10)**: the four-name freeze surface was retired wholesale — `skills/harness/` was deleted and every SDD harness seam now routes through the external **`/eng-harness-flow`** router (`AI-Substrate/harness-engineering`); child skills are private and never named in this repo. The freeze window resets from 2026-06-10 over the new surface: **`/eng-harness-flow` + its `--event` vocabulary** (`session-start | post-spec | pre-implement | phase-end | plan-complete`) is the stable public surface for **≥1 quarter** — harness capability evolves upstream, never as renames of this entry point. Depth: `docs/plans/029-eng-harness-switchover/`.

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Re-verify the router contract (read the substrate `eng-harness-flow/SKILL.md`; confirm the five `--event` seams + flags match § Seam & detection contract — halt and report drift if not), record pre-install probe miss (AC7 evidence), then install the external family: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`; verify router resolves | eng-harness | `~/.agents/skills/`, `~/.claude/skills/` | Five events + flags confirmed in router SKILL.md; pre-install `test -f …/eng-harness-flow/SKILL.md` fails (logged); post-install it passes in canonical store | Machine-level, not a repo change. Order: contract check + probe BEFORE install |
| [x] | T002 | Router smoke in this unprovisioned repo: `/eng-harness-flow --event session-start --json` → capture envelope | eng-harness | — | Envelope JSON logged; `decision` is setup-routing/`noop` (repo has no `.harness/`) — live AC8 evidence | Read-only smoke; no harness provisioning |
| [x] | T003 | Rewire **plan-1a + plan-1b**: replace harness-context section with Layer-1 detection + `--event session-start` (1a, first auto-firing skill); next-steps footer → `--event post-spec --spec` (1b); remove Compound blocks, governance file-tests, agent-harness-readiness question, observe mentions. Keep `docs/harness/agents/**` prior-learnings mining (read-only history) | sdd-pipeline | `skills/SDD/plan-1a-v2-explore/SKILL.md`, `skills/SDD/plan-1b-v3-specify-and-clarify/SKILL.md` | `grep -l "eng-harness-flow"` matches both; `grep -n "harness-[0-9]-\|\.disabled\|engineering-harness\.md\|agent-harness\.md" <both>` → no hits | Warning copy verbatim from § contract above |
| [x] | T004 | Rewire **plan-2c + plan-5**: 2c drops its Compound block + no-drain special case; plan-5's emitted T000/T0xx rows + Context Brief harness subsection emit router syntax (`pre-implement` / `phase-end`); observe out | sdd-pipeline | `skills/SDD/plan-2c-v2-workshop/SKILL.md`, `skills/SDD/plan-5-v2-phase-tasks-and-brief/SKILL.md` | Same grep pattern as T003; plan-5 template text contains `/eng-harness-flow --event pre-implement` and `--event phase-end` | AC5 covers emission |
| [x] | T005 | Rewire **plan-6 + plan-6-companion**: inline Boot→Interact→Observe pre-flight → `--event pre-implement --phase --plan-dir` + verdict handling (narrated verbatim; `healthy/SLOW/UNHEALTHY/UNAVAILABLE` per the router contract); end-of-phase → `--event phase-end`; companion debrief → `--event plan-complete`; remove observe instructions, buffer checks, drain choreography (router owns drain-vs-harvest) | sdd-pipeline | `skills/SDD/plan-6-v2-implement-phase/SKILL.md`, `skills/SDD/plan-6-v2-implement-phase-companion/SKILL.md` | Same greps; `grep -n "_buffers\|harness-3-observe\|drain.*\[s/t/p/e/d/a\]" <both>` → no choreography hits (narrating what the user *saw* is allowed in the-flow only) | Verdict casing matches upstream: lowercase `healthy` (router SKILL.md:61) |
| [x] | T006 | Rewire **plan-6a + plan-7 + plan-8**: 6a stops writing `.retro.md` files (duty dropped); plan-7 drops Subagent-6 harness-validation coupling + sentinel-audit grep; plan-8 routes `--event plan-complete` | sdd-pipeline | `skills/SDD/plan-6a-v2-update-progress/SKILL.md`, `skills/SDD/plan-7-v2-code-review/SKILL.md`, `skills/SDD/plan-8-v2-merge/SKILL.md` | Same greps; `grep -n "\.retro\.md" plan-6a` → no write instructions; plan-8 contains `--event plan-complete` | `docs/harness/agents/**` becomes read-only history |
| [x] | T007 | Rewire **plan-3** (safe now — this run is complete): N.0/N.z emitted rows + `## Harness Loop` output template → router events; backpressure-coverage input description repointed to router-produced artifact; sentinel/file-test predicates → two-layer detection | sdd-pipeline | `skills/SDD/plan-3-v3-architect/SKILL.md` | Emitted-template text greps show `/eng-harness-flow --event`; forbidden greps clean | PL-12: edited after, never during, its own run |
| [x] | T008 | **Docs sweep**: CLAUDE.md (Compounding Value System rewritten to external-family story; freeze override #2 audit paragraph — original freeze text never deleted; re-freeze over `/eng-harness-flow` + `--event` vocabulary), README.md (ownership line inverted), README_AGENTS.md (harness section → external pointer; counts 32→28), INSTALL.md, MIGRATION.md, `docs/skills-pipeline/README.md`, `docs/harness/README.md` → slim legacy pointer. Folds the uncommitted renumber edits | sdd-pipeline | `CLAUDE.md`, `README.md`, `README_AGENTS.md`, `INSTALL.md`, `MIGRATION.md`, `docs/skills-pipeline/README.md`, `docs/harness/README.md` | AC1/AC4 greps over these files return only whitelisted lines (MIGRATION cleanup note; CLAUDE.md freeze-audit paragraph); freeze-override paragraph present | Superseded edits folded, not reverted (Finding 06) |
| [x] | T009 | **Tooling**: justfile — remove schema-drift block, `compound-value` recipe, help line; delete `scripts/compound-value.sh`; patch stale description strings in `docs/harness/schemas/*` (strings only — shape + `schema_version` untouched) | sdd-pipeline | `justfile`, `scripts/compound-value.sh`, `docs/harness/schemas/` | `grep -n "compound-value\|skills/harness/" justfile` → no hits; `scripts/compound-value.sh` gone; schema git diff shows description-only changes | MUST land before T011 (Finding 05) |
| [x] | T010 | **the-flow rewrite — LAST among skill edits**: SKILL.md (alias table: `/plan-2d` → `/eng-harness-flow --event post-spec`, all `/harness-N` rows deleted; routing-table harness cues → router seams; narration scripts; sentinel → two-layer detection with exact warning copy; harness-loop section → side-by-side + router story); flight-plan.schema.json (node types keep stage names, `command` fields = router invocations, emission predicate = detection); both templates; getting-started.md full rewrite (incl. stale `docs/compound/` block) | sdd-pipeline / harness-seam | `skills/SDD/the-flow/SKILL.md`, `references/flight-plan.schema.json`, `references/flight-plan.template.{json,md}`, `references/getting-started.md` | `grep -n "harness-[0-9]-\|\.disabled" <all 5>` → no hits; warning copy present verbatim in SKILL.md; getting-started contains seam table + no `docs/compound/` | PL-12 driver — touch nothing here until T003–T009 land |
| [x] | T011 | **Delete** `skills/harness/` (all four skills incl. bundled `references/retro.schema.json`) and `docs/harness/_buffers/` | sdd-pipeline | `skills/harness/`, `docs/harness/_buffers/` | Both dirs gone; `scripts/check-skill-slugs.sh` exits 0 reporting **28** skills; `grep -rn "skills/harness/" <live files>` → no hits | Keep-list untouched: `schemas/`, `agents/`, slim `README.md` |
| [x] | T012 | **Deploy tidy + redeploy**: remove literal slugs `harness-1-boot`, `harness-2-backpressure`, `harness-3-observe`, `harness-4-retro` from `~/.agents/skills/` AND `~/.claude/skills/`; `just install-skills-from-source`; verify | sdd-pipeline | `~/.agents/skills/`, `~/.claude/skills/` | All four slugs absent from both stores; `just doctor-skills` clean (no dangling symlinks); `just skills-orphans` shows only the known baseline **plus the legitimately-external eng-harness family installed at T001** (expected — the check is that no stale `harness-*` slugs remain); installed-copy smoke: `grep "eng-harness-flow" ~/.claude/skills/the-flow/references/getting-started.md` hits | Literal paths only — no shell-var loops (Finding 04) |
| [x] | T013 | **Forward-pointers**: additive note atop plan-024 and plan-027 plan files — superseded by 029; 027's ownership claim explicitly superseded | sdd-pipeline | `docs/plans/024-harness-nucleus/harness-nucleus-plan.md`, `docs/plans/027-upstream-harness-improvements/upstream-harness-improvements-plan.md` | Note present at head of both files; `git diff` for these files shows additions only | History never rewritten |
| [x] | T014 | **Full verification sweep**: run all 12 acceptance checks; record evidence in `execution.log.md`; hand to user for the single commit | sdd-pipeline | repo root | Every AC below passes as specified; EXEC LOG records command + output for each | User executes the one commit (git agent-read-only) |

### Acceptance Criteria

- [ ] **AC1 Router-only**: `grep -rn "harness-1-boot\|harness-2-backpressure\|harness-3-observe\|harness-4-retro" skills/ justfile scripts/ CLAUDE.md README*.md INSTALL.md MIGRATION.md docs/skills-pipeline/ docs/harness/` → only whitelisted historical lines; no `eng-harness-[0-9]` child slug in any live file
- [ ] **AC2 Seams**: the five seams route via `/eng-harness-flow --event …` with context; `grep -rln "eng-harness-flow" skills/SDD/` lists every rewired skill; all other seams removed
- [ ] **AC3 Observe gone**: `grep -rni "harness observe\|harness-3-observe\|silently call" skills/SDD/` → no harness-observe hits (case-insensitive `-i` is load-bearing — current files contain both "Silently call" and "silently call")
- [ ] **AC4 Sentinel gone**: `grep -rn "\.disabled" skills/ justfile scripts/ CLAUDE.md README*.md INSTALL.md MIGRATION.md docs/skills-pipeline/ docs/harness/README.md` → no hits
- [ ] **AC5 Templates emit router syntax**: plan-3 N.0/N.z + `## Harness Loop`, plan-5 T000/T0xx + brief generate `/eng-harness-flow --event …` lines
- [ ] **AC6 Deletion clean**: `skills/harness/` gone; `check-skill-slugs.sh` exit 0 / 28 skills; `_buffers/` gone; compound-value tooling gone
- [ ] **AC7 No-router detection**: evidence chain = live pre-install probe miss logged (T001) + exact one-time warning copy present verbatim in rewired sources and installed copies (T012 smoke). A full post-landing no-router flow run would require uninstalling the family installed at T001 — deliberately not staged (recorded evidence-level decision; plan-7 reviews the branch logic inferentially)
- [ ] **AC8 Router detection**: post-install seam smoke returns envelope; unprovisioned repo gets the one-line note, never per-seam nagging
- [ ] **AC9 the-flow updated**: alias table router-only; schema/template `command` fields are router invocations; getting-started rewritten; installed-copy smoke passes
- [ ] **AC10 Docs truthful**: freeze override #2 audit trail in CLAUDE.md; README ownership inverted; forward-pointers atop 024/027; slim `docs/harness/README.md`
- [ ] **AC11 Deploy hygiene**: four slugs tidied from both stores; `skills-orphans` shows only the known baseline plus the expected external eng-harness family (no stale `harness-*` slugs); no dangling symlinks
- [ ] **AC12 Contracts preserved**: `docs/harness/schemas/` shape + `schema_version` untouched; committed legacy retro in place; drain `[s/t/p/e/d/a]` narration survives only as the-flow explaining what the user saw

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Freeze override #2 (2 days into reset window) confuses future agents | Medium | Medium | CLAUDE.md audit-trail paragraph; new frozen surface = the one router name + `--event` vocabulary |
| 027's ownership statements get "fixed" backwards later | Medium | Medium | Explicit supersession + forward-pointers atop 027 (and 024) — T013 |
| Editing driver skills mid-session destabilises this very flow | Medium | High | PL-12 ordering: plan-3 after its run (T007), the-flow last (T010) |
| One-commit landing harder to bisect | Low | Medium | All verification greps run pre-commit (T014); rollback = single revert |
| Hand-enumerated file lists drift | Medium | Medium | Every Done-When is a grep, never a list (PL-10) |
| zsh unquoted-var rm silently no-ops during deploy tidy | Medium | Low | Literal slugs, both stores, verified by `skills-orphans` (PL-06) |
| Removing `compound-value` retires an RV-002-encoded gift | Certain | Low | Deliberate + recorded; upstream harvest provides curated view + `--json` |
| Friction capture without observe instructions | Low | Low | Harness observes for itself once in operation (session-start routing); no-harness repos never had capture |

## Cross-repo follow-ups (logged, not done)

For the substrate repo: take custody of the canonical retro schema (incl. `system.*` sub-schemas) + fix its "frozen mirror" reverse-pointer; resolve its `skills/README.md:44` stale-slug note (this plan resolves the referencing side); consider a sanctioned prior-learnings read surface (e.g. `at=retro-harvest --json`).

---

## Validation Record (2026-06-10)

### Validation Thesis

**Raison d'être**: The SDD pipeline hard-codes four local harness skills across ~19 live files (plus sentinel/buffers/file-tests/inline re-implementations); the harness family now lives upstream behind the stateless router `/eng-harness-flow`. This plan must give an implementing agent an exact, ordered, provable route to switch every harness touchpoint to that single router entry point — without breaking the running pipeline, losing the minih retro-schema contract, resurrecting deleted skills from deploy stores, or rewriting history.

**Value claim**: Harness evolution becomes free for this repo; SDD skills get simpler; flows degrade gracefully (one calm warning, then silence).

**Artifact promise**: T001–T014 executable strictly in order, each Done-When a deterministic grep/script, landing as ONE user-executed commit passing all 12 ACs.

**Intended beneficiaries**: plan-6 implementing agent (primary); plan-7 reviewer; the user (one reviewable commit); future flows of the rewired skills.

**Proof target**: Implementation

**Evidence standard**: Deterministic grep gates as Done-When; live-fixture detection evidence (probe-before-install, router smoke); contract verified against the substrate router file.

**Thesis source**: spec Summary/Goals/Clarifications + original-ask.md (user hard constraint verbatim, spec:11)

**Thesis verdict**: Advanced

**Main thesis risk** (pre-fix, from Thesis agent): T008's freeze-override paragraph lacked paste-ready guidance and the router-contract assumption had no re-verification pathway — both fixed in place (paste-ready block added; T001 now re-checks the substrate contract before any rewiring).

---

| Agent | Lenses Covered | Thesis Axes Covered | Issues | Verdict |
|-------|---------------|---------------------|--------|---------|
| Coherence & Ordering | System Behavior, Integration & Ripple, Hidden Assumptions, Edge Cases | Downstream Usefulness | 1 HIGH fixed (AC3 case-sensitivity) | ⚠️ → ✅ |
| Risk & Completeness | Evidence Sufficiency, Proof-Level Fit, Deployment & Ops, Domain Boundaries, Concept Documentation | Evidence Sufficiency, Migration Safety | 1 HIGH + 1 MEDIUM + 1 LOW fixed (AC7 evidence level; AC11 baseline; seam-map pointer) | ⚠️ → ✅ |
| Thesis Alignment | Thesis Alignment, Evidence Sufficiency, Proof-Level Fit | Thesis Alignment, Implementation Readiness | 1 HIGH + 1 MEDIUM fixed (contract re-verification pathway; T008 paste-ready paragraph) | ⚠️ → ✅ |
| Forward-Compatibility | Forward-Compatibility, Technical Constraints, Integration & Ripple | Contract Integrity | 1 CRITICAL fixed (verdict casing `HEALTHY`→`healthy`) | ⚠️ → ✅ |

Lens coverage: 12/15. Spec patched in lockstep for the same five mechanical corrections (AC3 `-i`, verdict casing ×2, AC7 evidence wording, AC11 baseline) so plan and spec verify identically.

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| plan-6 implementation run | Ordered task table with unambiguous verdict literals | shape mismatch | ❌ → ✅ fixed | Plan said `HEALTHY`; router SKILL.md:61 says `healthy / SLOW / UNHEALTHY / UNAVAILABLE` — corrected at both sites |
| plan-7 review | AC1–AC12 runnable as written | test boundary | ✅ | Grep syntax verified; AC3 hardened with `-i` |
| the-flow rewrite (T010) | Exact verdict + warning copy for narration | encapsulation lockout | ❌ → ✅ fixed | Same casing fix; warning copy verified verbatim plan↔spec |
| future flows consuming router | Seam calls + vocabulary match real runtime contract | contract drift | ❌ → ✅ fixed | Events, params (`--spec --plan-dir --phase --prompt-optional --json`), envelope (`route\|redirect\|noop\|ambiguous`), install command, probe path all verified against substrate SKILL.md; `task-pause` exists and is correctly unused |
| plan-3 template emission | Emitted seam calls match router event list | contract drift | ✅ | All five events match router SKILL.md:124 |
| Lifecycle safety (PL-12) | Driver-skill edit ordering protects the live session | lifecycle ownership | ✅ | T007 after plan-3's run; T010 last; T012 redeploy after all edits |
| Retro schema (minih) | Shape + `schema_version` untouched | shape mismatch | ✅ | T009 description-strings-only rule |

**Thesis alignment**: Value claim advanced (Yes) at Implementation proof level (post-fix); main residual risk is upstream router drift after landing, mitigated by T001's contract re-check at execution time.

**Outcome alignment** (Forward-Compatibility agent, verbatim — pre-fix): "This plan, **as written with the verdict vocabulary error**, does **NOT** put the repo on the trajectory toward 'One stable public harness surface: /eng-harness-flow + its --event vocabulary. Children are private and free to move.' … The fix is a one-line correction to lines 104 and 114 (change `HEALTHY` → `healthy`)." — Fix applied at both sites (plus spec ×2); with it, the named blocker is cleared and the plan is on that trajectory.

**Standalone?**: No — downstream consumers enumerated above.

Overall: VALIDATED WITH FIXES
