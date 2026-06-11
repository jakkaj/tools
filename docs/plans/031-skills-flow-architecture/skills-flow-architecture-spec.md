# Composable Skills-Flow Architecture — ruleset v2 + lints, the-flow as exemplar

**Mode**: Simple
**Created**: 2026-06-12
**Plan dir**: `docs/plans/031-skills-flow-architecture/`
**Authoritative design input**: [`workshops/001-composable-skill-flows.md`](./workshops/001-composable-skill-flows.md) — decisions D1–D7, ruleset R1–R8, lints L1–L6 are settled; this spec scopes and sequences them, it does not re-decide them.
**Validated**: `validate-v2` 2026-06-12 (4 agents: accuracy / completeness / thesis / forward-compat) — 2 CRITICAL + 4 HIGH findings applied: the AC2/AC3-vs-AC4 contradiction repaired, seam-multiset accounting corrected (AC6), the public `6c` id's fate defined (AC5/Non-Goals), L3 widened to all flow-level files (AC7), the one-edit claim qualified + censused (AC13), stale codebase.md loose end removed.

📚 Specification incorporates findings from [`research-dossier.md`](./research-dossier.md).

## Research Context

- **The leak is verified**: exactly **147 cross-stage reference hits** inside the 11 stage modules (line counts: 123 `/the-flow <id>` command strings, 61 sibling-module paths, 11 "Next routing" lines — categories **overlap** to 147 grep hits). Every flow edge is encoded in **5 places**; one formatting change (`b26bce2`) cost 308 strings / 249 lines / 20 files.
- **The leak is prescribed, not accidental** (CF-01): the v1 migration guide's step template mandates a "Next routing instruction" section. Fixing instances without shipping the v2 ruleset regrows the leak — **the pattern is the product; the-flow refactor is the exemplar**.
- **Four of the five layers already exist, just smeared**: the routing table in `00-routing.md` IS the Graph; the stage table IS the Registry (triplicated — SKILL.md, 00-routing.md, getting-started.md, no declared master, CF-02); coach.md IS the Presentation (~50+ hardcoded commands, no slots, CF-06).
- **The D7 fold is cheap and safe** (CF-03): `61-implement-companion.md` is substantially verbatim-duplicate of `60-implement.md`; `62-progress.md` needs **no fold-specific changes** (debrief keys on `--companion-run-id`, caller-agnostic — though it receives the universal de-leak edits like every module); `flight-plan.schema.json` already models companion as `agents[].kind: companion`, not a node type.
- **Frozen vs free** (CF-04): frozen — `/the-flow <id> <name>` grammar, old-slug translation table (live flows 027/028/029 resume through it), the 5 harness-seam `--event` invocations, guided/direct load-path parity, state-write ownership. Free — module internals, table formats, coach slots, view regeneration.
- **Lints split by feasibility** (CF-05): L1/L2/L6 shippable day one; L3 needs ~python-stdlib-scale parsing; L4 needs the formal Registry/Graph tables this work creates; L5 banner-check lands with the banner convention.

## Summary

Ship the **shareable composable-flow pattern** — the ruleset v2 doc (R1–R8 + firm Stage Template + Flow Definition format + single command grammar) and a deterministic lint script (`check-flow-architecture.sh`) — and **prove it by refactoring `the-flow` as the exemplar**: stage modules become contract-bound verbs with zero flow knowledge (147 refs → 0), one flow-level Registry+Graph owns every edge, narration renders commands from slots instead of literals, and the companion stage folds into implement as a mode (11 modules → 10). This collapses the 308-edit class of change to **one authoritative edit** (derived views are banner-marked and refreshed separately — view regeneration tooling is deferred Phase-D/E work) and gives the next flow a template to be stamped from instead of a guide that bakes in the leak.

## Goals

- **G1 — The pattern, shareable**: a standalone ruleset v2 doc (v2 of the paste guide) a fresh human/agent can follow to author a new flow — R1–R8, the firm **Sub-skill Template** (the unit's first-class definition — Clarification #5), the Flow Definition (Registry + Graph + Grammar), narration-slot convention, and the lint set. Sufficient to hand-assemble the workshop's mini-flow example, and explicitly declared the successor of the v1 guide's step template.
- **G2 — Deterministic enforcement**: `scripts/check-flow-architecture.sh` (sibling of `check-skill-slugs.sh`, hard-fail, exit 0/1/2) implementing L1 (stage leakage), L2 (contract block), L3 (grammar conformance), L6 (host limits); L4 (closure) once the Registry/Graph tables exist; L5 as a banner-presence check. **Parameterized by flow-skill directory** (default: the-flow) so a second flow can be linted without Phase-E tooling. Wired into `just check-flow`.
- **G3 — the-flow de-leaked (the exemplar)**: every stage module stamped to the firm template — contract block (`**Verb**` / `**Purpose**` / `**Consumes**` / `**Flags**` / `**Produces**` / `**Side effects**`) at top, "Next routing" fields and trailing next-step prose deleted, constant Exit line; the Graph absorbs any edge not already in the routing table. L1: 147 → 0. (Stage citations of `00-routing.md § Shared conventions` are **explicitly permitted** — a documented portability exception in the pattern doc, per the dispatch's lazy-pull contract.)
- **G4 — One graph, one registry, one grammar**: a single declared master for the Registry and Graph at flow level; the other stage-table copies become explicitly derived views (getting-started banner-marked); the command grammar **defined** exactly once — everything else is a conforming example checked by L3.
- **G5 — D7 fold**: `61-implement-companion.md` deleted; its minih protocol becomes a clearly-fenced **optional companion mode** inside the implement verb; "companion supersedes review" becomes a Graph edge decoration; the Registry drops the `6c` row, with typed `6c`/`companion` surviving as a **read-time alias** to implement-with-companion-mode (PL-01 pattern). `62-progress.md`'s debrief protocol is untouched (still keyed on `--companion-run-id`).
- **G6 — Narration slots (D5)**: coach.md scripts carry `{{render-edge}}`-style slots; commands are rendered at narration time from Grammar + Registry + Graph; zero literal stage commands outside the single grammar definition.

## Non-Goals

- **No verb-file renames** (workshop Phase D): stage files keep their `NN-` prefixes this plan; D2 records ids-as-flow-property, the rename is cosmetic and deferred.
- **No template-library extraction as files** (Phase D) and **no authoring CLI** (Phase E): both wait for a second real flow to exist. The firm templates ship as documented contracts *inside the ruleset doc*, not as a `templates/` directory.
- **No statelessness**: the-flow keeps `.the-flow-state.json` durable checkpoints — settled plan-030 architecture; the eng-harness-flow statelessness pattern is explicitly not borrowed.
- **No public-surface changes, with one deliberate exception**: the `/the-flow <id> <name>` grammar, the old-slug translation table semantics, the 5 harness-seam `--event` invocations (vocabulary frozen ≥1 quarter from 2026-06-10, CLAUDE.md Override #2), guided/direct load-path parity, state-write ownership, and the merge **PROCEED** gate all survive byte-meaning-identical. The exception is the **deliberate retirement of the `6c` registry row** (workshop D7, user-decided): `6c`/`companion` remains typeable via read-time alias (AC5), so no caller breaks.
- **No minih/substrate changes**; no new flows built this plan (the mini-flow stays a worked example on paper).

## Target Domains

*(No `docs/domains/` registry exists in this repo — the skill folder is the natural boundary; entries below are informal.)*

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| the-flow skill (`skills/SDD/the-flow/`) | existing | **modify** | The exemplar: de-leak 11 stage modules, fold 6c, consolidate Registry/Graph, slot the coach, update flight-plan trio driver examples |
| repo tooling (`scripts/`, `justfile`) | existing | **modify** | Add `check-flow-architecture.sh` (flow-dir parameterized) + `just check-flow` recipe (pattern: `check-skill-slugs.sh`) |
| docs (`docs/skills-pipeline/`, `CLAUDE.md`, `README.md`) | existing | **modify** | The shareable ruleset v2 doc (new) + pointer/structure updates where the restructure is described |

## Testing Strategy

- **Approach**: Lightweight — the lints ARE the verification layer. Every "no refs remain" task carries its grep in its Done-When (PL-10: trust grep, not the plan).
- **Focus areas**: L1 leak census 147→0; L2 contract blocks 10/10 post-fold; L3 zero unauthorized literal commands across flow-level files; L6 descriptions ≤1024 (the-flow currently 971 — tightest in repo); seam **invocation-string** multiset with its expected delta recorded pre/post; merge **PROCEED**-gate wording byte-parity; diagram inventory with node-name/count parity pre/post (PL-11); resume check against the live stale state files plus one synthetic companion-pending fixture.
- **Excluded**: no test framework, no CI workflow changes beyond the `just` recipe; no fixture suites beyond the single synthetic companion-resume fixture (lints run against the real tree).
- **Mock usage**: avoid entirely — real files only; resume checks use the actual stale `.the-flow-state.json` files on disk (the one synthetic state file is a real file, not a mock).

## Documentation Strategy

- **Location**: standalone shareable pattern doc (home decided at architect — likely `docs/skills-pipeline/`), plus updates to existing docs that describe the structure: `CLAUDE.md` (the-flow section **and** the flow-authoring touchpoints), `docs/skills-pipeline/README.md`, `README.md` stage ref, `getting-started.md` (becomes a banner-marked rendered view).
- **Discoverability / supersession** (closes the CF-01 regrowth vector): the pattern doc states it supersedes the v1 guide's step-module template, and is linked from the places a future flow author actually starts (CLAUDE.md skill-authoring section, `docs/skills-pipeline/README.md`) — a pattern nobody finds regrows the leak.
- **Rationale**: the original ask — "a new pattern that we can share with others, and this will be our exemplar" — makes the pattern doc a first-class deliverable, not an afterthought.

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2 (20+ files across skill + scripts + docs), I=1 (npx-skills deploy + live-flow resume; no external systems), D=1 (new Registry/Graph table formats; state semantics preserved verbatim), N=1 (design fully settled in workshop 001), F=1 (freeze constraints, host description limits), T=1 (deterministic lint-based verification)
- **Confidence**: 0.80
- **Assumptions**: workshop 001 decisions hold without re-litigation; the routing table's edge set is complete (dossier verified closure — no orphan artifacts); 62-progress needs no fold-specific changes (dossier IC-10 — universal de-leak edits still apply to it).
- **Dependencies**: none external. `npx skills` deploy behaviour (never prunes) handled by deploy+tidy with literal paths (PL-02, PL-06).
- **Risks**: see § Risks & Assumptions.
- **Phases**: single phase (Simple mode), internally ordered A → B → C: ruleset doc + lint script first (baseline 147 visible), then de-leak + D7 fold (L1→0, L2→10/10), then coach slots + view regeneration (L3 clean). Self-edits to the running skill ordered last within each group (PL-12).

## Acceptance Criteria

1. `scripts/check-flow-architecture.sh` exists, follows the `check-skill-slugs.sh` conventions (`set -euo pipefail`, `OK:`/`ERROR:`/`WARN:` prefixes, exit 0/1/2), **takes a flow-skill directory argument** (default `skills/SDD/the-flow`), runs via `just check-flow`, and **exits 0 against the restructured the-flow**.
2. **L1 = 0**: the leak census over `skills/SDD/the-flow/references/stages/*.md` returns **0 total hits** (baseline: 147). The lint pattern covers the forms that actually occur: `/the-flow [0-9]`-shaped strings, case-insensitive `stage [0-9]+[a-z]?`, sibling paths `references/stages/[0-9]`, and Next-routing/Next-step markers in **both** heading and bold-label form (`\*\*Next routing\*\*` / `## Next routing` / `^Next step` / `## Next step`) so a reintroduced routing line without a command string still trips it.
3. **L2 = 10/10**: every surviving stage module — **including `62-progress.md`** — opens with the firm contract block (`**Verb**` / `**Purpose**` / `**Consumes**` / `**Flags**` / `**Produces**` / `**Side effects**`) and ends with the constant Exit line, byte-identical to the workshop template: "Routing is the flow's job — run the parent flow bare to continue."
4. **D7 fold complete**: `61-implement-companion.md` deleted; the implement verb carries a clearly-fenced optional companion-mode section owning the minih protocol; the Graph carries the "skippable if companion reviewed all commits" decoration on the review edge; no `6c` row in the Registry. Dispatch cleanup included: invariant #7 reworded per workshop Q7 ("the implement verb's companion mode owns the protocol"), the description's stage list drops `6c` (then AC10 re-measures), and the **flight-plan trio** (`flight-plan.schema.json` driver example, `flight-plan.template.json` `"driver"` field, `flight-plan.template.md`) updates its `/the-flow 6c companion` driver examples to the new companion-mode form — `agents[].kind: companion` itself is already correct and stays. In `00-routing.md`, the awaiting-5 row's `6c` offer updates; the `agents[]` flight-plan render rules stay. `62-progress.md`'s debrief logic is unchanged (still keyed on `--companion-run-id`); it receives only the universal de-leak/contract edits of AC2/AC3 (including removal of its now-dangling references to the deleted 61 module).
5. **Slug + alias translation intact**: all 12 retired `plan-*` slugs still resolve; `plan-6-v2-implement-phase-companion` **and** typed `6c`/`companion` resolve via read-time alias to implement-with-companion-mode (exact printed command form decided at architect — Open Question 4 — but the alias semantics are required). Resume verification: 027 (`plan-8-v2-merge`) and 029 (`plan-7-v2-code-review`) resolve through the table into current public grammar; 028's prose `pending_command` is a translation **no-op** (resume relies on its `current_stage: awaiting-8`); one **synthetic** state file with a companion `pending_command` resolves through the alias.
6. **Harness seams preserved (string-granularity)**: the five `--event` invocations keep their **owning locations** per workshop D3 — `session-start` at flow entry (dispatch/00-routing + 10-explore procedure), `post-spec` re-homed to flow level as a Graph edge decoration (its stage-module copies in 20-specify/25-workshop are de-leak deletions), `pre-implement` + `phase-end` in the implement verb's procedure, `plan-complete` in the merge verb's procedure. "Byte-identical" applies to the **invocation strings** (`/eng-harness-flow --event …`), not their containing lines; `--event` vocabulary unchanged. Expected multiset delta recorded pre/post: stage-61's copies and the de-leaked stage-module `post-spec` copies disappear; everything else 1:1. The regenerated getting-started view's `--event` mentions are re-verified after render. The one-time no-harness warning text re-homes to flow level with the post-spec decoration. The merge **PROCEED** gate wording is byte-identical pre/post.
7. **L3 clean across flow-level files**: `SKILL.md`, `00-routing.md`, `coach.md`, and `getting-started.md` contain zero literal `/the-flow <id> <verb>` command strings except (a) the single Grammar definition, (b) the old-slug/alias translation table, and (c) banner-marked rendered-view content regenerated from the Registry+Graph (whose strings must conform to the Registry). Coach narration uses render slots; the PL-14-style dedupe inventory taken before conversion is the parity evidence for the byte-meaning review.
8. **One declared master**: the flow-level Registry and Graph tables are explicitly declared the single source of truth; `getting-started.md` carries a first-line rendered-view banner (L5 presence check passes) **and its content is regenerated** against the post-fold Registry/Graph (no stale `6c` rows, walkthrough commands, or mermaid nodes); the remaining stage-table copy (dispatch SKILL.md) is either the master or explicitly marked derived — decided at architect, but exactly one master exists.
9. **The pattern doc exists and is proven**: (a) content checklist — R1–R8, the firm **Sub-skill Template** (Clarification #5), the Flow Definition format (Registry + Graph + Grammar tables), the narration-slot convention, the lint table, the worked mini-flow, the shared-conventions portability exception, and a supersession note naming the v1 guide; (b) **assembly check** — a fresh-context subagent given only the pattern doc assembles a flow from it and the result passes `check-flow-architecture.sh` (L1/L2/L4) — shareability tied to the deterministic layer, not vibes; (c) the doc is linked from CLAUDE.md and `docs/skills-pipeline/README.md`.
10. **L6 passes post-edit**: every skill description in the repo ≤1024 chars (re-measured after any SKILL.md description edit).
11. **Load-path parity + state ownership preserved**: guided mode still reads dispatch + routing/graph + coach + exactly one stage module; direct jump reads exactly one stage module and writes no flow state; the **State-write ownership** section of `00-routing.md` survives verbatim (PL-15) — checked by grep against its current text.
12. **Deploy + tidy**: after `npx skills` redeploy, the canonical store reflects the restructure and the retired module copy is removed with a **literal-path** `rm` (`rm ~/.agents/skills/the-flow/references/stages/61-implement-companion.md`, PL-06); `just skills-orphans` reports clean for the-flow.
13. **Whole-skill literal census (the one-edit claim, honestly)**: post-restructure, a census of `/the-flow <id>`-shaped strings across the entire skill finds literals **only** in (a) the Grammar definition and (b) banner-marked rendered views; the count is recorded in the execution log. The Summary's claim is thereby scoped: one authoritative edit + banner-marked views refreshed separately (regeneration tooling stays deferred).
14. **External docs updated**: `CLAUDE.md`, `docs/skills-pipeline/README.md`, and `README.md` reflect the post-fold 10-module structure — `grep -n "61-implement-companion\|6c companion" CLAUDE.md docs/skills-pipeline/README.md README.md` returns 0 stale hits (alias documentation mentions allowed where explicitly describing the translation).

## Risks & Assumptions

| Risk | Impact | Mitigation |
|---|---|---|
| **Self-editing skill** (PL-12): the-flow drives this very session while being edited | Mid-flight breakage of the driver | Self-edit tasks ordered LAST within the phase; deployed copy (`~/.claude/skills/the-flow/`) only changes at the deploy step, so source edits are inert to the running session; rollback = git revert (plan-030 tag precedent) |
| Live flows 027/028/029 resume through surfaces being edited | Broken resume for in-flight plans | AC5 resume check against the real stale state files + synthetic companion fixture; translation table semantics frozen |
| Coach slot conversion drifts narration meaning | The guided voice degrades subtly | PL-14 dedupe inventory before conversion = parity evidence (AC7); byte-meaning review per script block; rail spec untouched |
| Seam multiset miscount after the 61 deletion + 20/25 de-leak | Freeze violation (Override #2) | AC6 enumerates owning locations and the **expected delta**; string-granularity grep multiset recorded pre/post |
| Diagram drift during fold/regeneration (PL-11) | Stale mermaid nodes (6c) survive in views | Diagram inventory with node-name/count parity pre/post (getting-started stage map, flight-plan template, 00-routing render rules) |
| `npx skills` never prunes the deleted module | Stale deployed companion module shadows the fold | AC12 deploy+tidy with literal paths; `just skills-orphans` baseline before/after (PL-02) |
| SKILL.md description budget (971/1024) | A stricter host (Copilot CLI) silently rejects | L6 in the lint script; re-measure after every description edit (PL-13) — note the fold *shortens* the description (drops 6c) |
| Hardcoded ref lists in the plan drift from reality | "Done" declared while refs remain | Every removal task's Done-When IS the grep (PL-10) |

**Assumptions**: workshop 001 is authoritative and complete for design; the dossier's closure analysis (no orphan artifacts) holds; this plan runs on `main` (no branches) with git operations user-triggered only.

## Open Questions

*(Architect-level decisions, not blockers — no critical clarification markers remain.)*

1. **Home of the pattern doc**: `docs/skills-pipeline/flow-architecture.md` vs a new top-level docs dir — decide at architect (G1 content is fixed either way).
2. **Registry master location**: dispatch `SKILL.md` stage table vs `00-routing.md` Registry+Graph section — workshop puts Registry+Graph at flow level; architect picks the file and demotes the other copies (AC8 requires exactly one master).
3. **L4 timing**: ship closure-lint logic in the script from day one (inert until the tables exist) or add it in the same change that lands the tables — architect's call; AC1 only requires final exit 0.
4. **Printed form of companion mode**: flag (`/the-flow 6 implement --companion …`) vs a mode question at the tasks seam — architect decides; AC5 only requires that the alias resolution semantics exist and are documented.

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| — | — | **Already satisfied pre-spec**: `workshops/001-composable-skill-flows.md` (D1–D7, R1–R8, L1–L6, migration phases) is the authoritative design input for this spec | — |

## Clarifications

### Session 2026-06-12

| # | Question | Answer |
|---|----------|--------|
| 1 | Workflow Mode (Full recommended for the multi-phase shape) | **Simple** — user override; single-phase plan with inline tasks, internally ordered A→B→C. CS-3 supports it. |
| 2 | Testing Strategy | **Lightweight** — the lint script is the verification layer; greps live in Done-Whens (PL-10); plus the live-state resume check. |
| 3 | Mock Usage | **Avoid mocks entirely** — real files; lints run against the actual tree; resume checks use the real stale state files (one synthetic companion fixture, itself a real file). |
| 4 | Documentation Strategy | **Pattern doc + updates** — standalone shareable ruleset v2 doc (home decided at architect) plus pointer/structure updates to CLAUDE.md, docs/skills-pipeline/README.md, README.md, getting-started.md, with explicit supersession of the v1 guide. |
| 5 | Terminology (user, mid-architect): what do we call the reusable unit inside a flow? | **Sub-skill** — the contract-bound module formerly called "stage module"/"verb module". A sub-skill is *named by a verb* (explore, implement…) and knows nothing about any flow; flows assign ids and compose sub-skills via the Registry+Graph. The pattern doc defines the sub-skill as its first-class concept ("this is what a sub-skill looks like; this is how a flow composes them"). "Stage" survives only as the flow-position concept. Directory rename (`references/stages/` → `references/sub-skills/`) stays deferred with the Phase-D cosmetic renames. |
