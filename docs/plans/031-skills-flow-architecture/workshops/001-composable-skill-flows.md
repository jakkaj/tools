# Workshop: Composable Skill Flows — stages as verbs, flows as graphs, prompts as templates

**Type**: Other (Skill Architecture / Authoring Pattern)
**Plan**: 031-skills-flow-architecture
**Spec**: none yet — pre-spec workshop; this document feeds the future spec
**Created**: 2026-06-11T20:58:49Z
**Status**: Draft

**Value Thesis**: Make flow skills out of reusable, contract-bound stage *verbs* composed by a single flow-level *graph*, with all repeated surfaces (stage modules, the flow graph, the router prompt, the flight-plan JSON, phase task tables, narration scripts) stamped from firm templates — so a wording/format change is one edit instead of 308, a new flow is a graph file instead of a rewrite, and stages stay portable because composition happens at **build time**, never at run time.

**Target Proof Level**: Contract Ready
**Current Proof Level**: Contract Ready (templates + graph format + ruleset + lints specified; not yet validated against a second flow)

**Selected Value Axes**:
- **Safety to Change** (primary): today one formatting decision touched 20 files / 308 strings (commit `b26bce2`); the architecture should make that a 1–2 edit change.
- **Implementation Readiness**: firm templates mean a new stage or a new flow is fill-in-the-blanks, not archaeology.
- **Agent Readiness**: an agent authoring a new flow follows the ruleset + templates with minimal clarification; lints tell it deterministically when it's done.
- **Learning Compounding**: the ruleset upgrades `scratch/paste/20260611T080711.md` (the guide used for plan-030) so the *next* consolidation doesn't re-create the leak.
- **Review Compression**: "stages must grep clean of other stages" is a mechanical review check, not a judgment call.

**Related Documents**:
- `scratch/paste/20260611T080711.md` — the original progressive-disclosure migration guide (v1; its step-module template *prescribes* the leak this workshop removes — see § The Bug In The Guide)
- `docs/plans/030-flow-skill-consolidation/` — the consolidation that built `the-flow` and exposed the problem
- `skills/SDD/the-flow/` — the worked subject; commit `b26bce2` is the 308-edit motivating incident

---

## Purpose

Define the architecture that separates **what a stage does** (verb modules with contracts) from **how stages compose** (a flow-level graph) from **how it all reads** (templates + one command grammar) — and specify the firm templates, the ruleset, the deterministic lints, and the build-time authoring CLI that would let us stamp out *other* flows the same way. This makes the next flow-skill build (and every future edit to `the-flow`) cheaper, safer, and mechanically verifiable.

## Fresh Entrant Outcome

A fresh human or agent should be able to use this workshop to reach **Contract Ready** with no additional context.

They should be able to:

- Write a new stage module from the Stage Template and know exactly which sections are forbidden (anything naming another stage).
- Define a new flow by filling in the Registry + Graph tables, without touching any stage module.
- Run the lints (greps specified here) and know deterministically whether the architecture holds.
- Explain why composition happens at build time and what that buys for portability.

## Key Questions Addressed

1. What is the firm template for a stage module (the verb contract), and what is it *forbidden* to contain?
2. What does the flow-level composition artifact look like, and why is it structured markdown rather than JSON?
3. Which surfaces are templates, which are instances, and who owns each?
4. How do flows stay portable across skill systems if a CLI helps author them?
5. What ruleset + lints enforce the architecture (the reusable "skills architecture")?
6. What is the migration path for `the-flow` itself?

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | Contract Ready | The next loop is writing the spec + plan for the refactor; it needs contracts and templates, not a running CLI |
| Primary Value Axis | Safety to Change | The 308-edit incident is the baseline; the architecture exists to collapse that class of change |
| Supporting Value Axes | Implementation Readiness, Agent Readiness, Learning Compounding, Review Compression | Templates make authoring mechanical; lints make review mechanical; the ruleset stops the bug recurring |
| Downstream Loop Improved | Flow-skill authoring + every future edit to `the-flow` | New flows become graph files over a verb library; edits become single-owner changes |

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| 147 cross-stage refs measured across 11 stage modules | § The Leak, Measured | The leakage claim | Ready |
| 308 command strings / 20 files in one formatting change | commit `b26bce2` | The cost-of-change claim | Validated (it happened) |
| "Next routing instruction" section in the v1 guide's step template | `scratch/paste/20260611T080711.md` line ~259 | The bug is in the guide, not just the output | Ready |
| Stage Template | § The Stage Template | Contract for all future stage modules | Draft |
| Flow Definition format (Registry + Graph tables) | § The Flow Definition | Contract for composition | Draft |
| Lint command set | § The Lints | Deterministic enforcement | Draft (not yet scripted) |
| Worked mini-flow example | § Worked Example | Fresh-entrant comprehension | Draft |

---

## The Leak, Measured

The current `the-flow` (post plan-030) is one skill, but internally each stage module still *knows the flow*:

```
$ for f in skills/SDD/the-flow/references/stages/*.md; do
    grep -cE '/the-flow [0-9]|stage [0-9]+[a-z]?|references/stages/[0-9]' $f
  done
10-explore.md: 23    20-specify.md: 12    25-workshop.md: 18
30-architect.md: 18  35-adr.md: 7         50-phase-tasks.md: 20
60-implement.md: 8   61-implement-companion.md: 21
62-progress.md: 7    70-review.md: 10     80-merge.md: 3
                                          ─────────────────
                                          ≈147 cross-stage refs
```

Every edge in the pipeline is encoded in up to **five places**: the stage's "Next routing" header, the stage's trailing "Next step" prose, the routing table, the coach narration script for that seam, and the getting-started quick reference. Plus the templates. That is why `/the-flow <id>` → `/the-flow <id> <name>` cost 308 string edits.

### The Bug In The Guide

The v1 migration guide (`scratch/paste/20260611T080711.md`) *prescribes* this: its step-module template ends with a section literally titled **"Next routing instruction"**. The spaghetti was specified, not accidental. The stages were born as standalone skills that *had* to know their successors (nothing sat above them); the consolidation moved them under a router but never demoted them — they kept their edges. This workshop's ruleset is the v2 of that guide.

---

## Overview — the layered model

Treat a flow skill as a tiny workflow engine whose files happen to be markdown. Five layers, each with one owner:

```
┌─────────────────────────────────────────────────────────────────┐
│ VIEWS          getting-started, quick-reference, walkthroughs   │  rendered, banner-marked,
│                (derived — never authoritative)                  │  regenerable
├─────────────────────────────────────────────────────────────────┤
│ PRESENTATION   command grammar (defined ONCE) · rail spec ·     │  flow-level
│                narration templates with slots                   │
├─────────────────────────────────────────────────────────────────┤
│ COMPOSITION    the Graph: states × artifact-evidence × edges    │  flow-level — THE single
│                + edge decorations (seams, compact hints, modes) │  owner of "what's next"
├─────────────────────────────────────────────────────────────────┤
│ REGISTRY       the capability list: id ↔ verb ↔ module ↔        │  flow-level — assigns ids;
│                contract (consumes → produces) ↔ flags           │  stages don't know their ids
├─────────────────────────────────────────────────────────────────┤
│ STAGES         verb modules: entry conditions · procedure ·     │  library-level — know
│                output contract · exit. NOTHING about the flow.  │  NOTHING above this line
└─────────────────────────────────────────────────────────────────┘
            stages talk to each other ONLY through artifacts on disk
```

**The key LLM-specific insight — the renderer is the model.** In code, indirection resolves at runtime for free; in skill-land, indirection costs a file-load and duplication costs drift. Progressive disclosure already guarantees the dispatch/graph layer is in context for *every* invocation (it's how the stage module got loaded at all). So when a stage finishes, the router is right there to pick the edge and *render* the next command from grammar + registry. The 308 literal strings exist because we pre-rendered what the model can render at narration time. Templates + one grammar rule replace them all.

**The portability insight — compose at build, ship sealed.** Skill systems (`npx skills`, Claude/Codex skill dirs) copy a skill folder as a self-contained unit; there is no cross-skill linking at run time. So "reusable stage library" cannot mean runtime sharing. It means: the authoring CLI **assembles** a flow skill from the library at build time — like static linking. Each shipped flow contains its own copies; the library is the source of truth at authoring time; drift is managed by re-running the assembler (exactly the `sync-to-dist.sh` pattern this repo already uses). Running a flow never depends on the CLI — the CLI builds flows, it never runs them.

---

## Decision Space

| # | Decision | Options | Decision |
|---|----------|---------|----------|
| D1 | Graph format | (a) structured **markdown tables** with a strict column contract · (b) JSON/YAML graph + generator · (c) both | **(a) Selected.** Markdown tables are simultaneously the human doc, the LLM-native prompt, and machine-parseable (a CLI can parse the same table later). JSON-first **rejected**: needs a renderer before delivering any value, and the LLM would still read the rendered form. Revisit (c) only when a second flow proves the parse need. |
| D2 | Where stage ids live | (a) in the stage (current: `30-architect.md` encodes position) · (b) in the flow — stages are verb-named, the Registry maps `3 ↔ architect ↔ architect.md` | **(b) Selected.** Numbers are *flow* properties (a lite-flow may order the same verbs differently); verbs are *stage* properties. Numbered filenames **rejected**: they encode position in the artifact that must not know its position. Migration may keep `NN-` prefixes until Phase D (cosmetic). |
| D3 | Seam ownership | (a) all harness/compact seams in stages · (b) all in graph · (c) split by shape | **(c) Selected.** A seam that *wraps* a stage (post-spec backpressure, between-phase compact) is an **edge decoration** in the graph. A seam *interleaved with the stage's own procedure* (pre-implement firing before task 1, phase-end after the last task) stays in the stage module — it is part of the verb's work, and must survive direct-jump invocation. |
| D4 | Lint enforcement | (a) advisory prose rule · (b) repo script, hard-fail like `check-skill-slugs.sh` | **(b) Selected.** These are structural checks (like slug collisions), not vibe scoring — the best-effort/no-gates rule applies to judging *human work*, not to linting *architecture*. |
| D5 | Narration coupling | (a) coach scripts carry literal commands (current) · (b) narration templates with `<next-edge>` slots; commands always rendered from grammar + registry | **(b) Selected.** Coach may still *say* "next is the architect" in teaching prose (verbs are registry-stable); it may never hardcode a command string. |
| D6 | CLI scope | (a) authoring + running · (b) authoring only: scaffold, lint, render views, assemble | **(b) Selected.** Running depends on the host skill system; the CLI is a build tool (static-site-generator shaped). Anything the CLI generates is committed plain markdown. |
| D7 | Companion (6c) under the verb model | (a) separate verb (current) · (b) a *mode* of `implement` | **(b) Selected** (user decision — see Q7). Companion = "run the minih review agent in the background or not, and here's how; otherwise ignore." Optional in-procedure section of the implement verb; review-supersession moves to a graph edge decoration; the 21-cross-ref module is deleted. |

---

## The Stage Template (firm)

Every stage module is stamped from this. The contract block is at the top, machine-checkable; the procedure is free-form; the exit is fixed.

````markdown
# <verb>

> Stage module — part of a verb library. Knows nothing about any flow:
> no stage ids, no successor/predecessor names, no flow commands.
> Composition is the bundling flow's job.

**Verb**: architect
**Purpose**: <one sentence — what this stage does to the world>
**Consumes**: <artifact patterns, marked required/optional>
            e.g. `<slug>-spec.md` (required) · `workshops/*.md` (optional) · `backpressure-coverage.md` (optional)
**Flags**: `--spec <path>` <the verb's own flags — stable regardless of which flow calls it>
**Produces**: `<slug>-plan.md` <the artifacts this stage writes — the ONLY way downstream stages see its work>
**Side effects**: <seams fired from inside the procedure, if any — D3 in-procedure seams only>

---

## Entry conditions
<what must exist on disk before this verb can run; error message if not>

## Procedure
<the actual work — as long and rich as the verb needs; this is the part that was
 always fine in the old skills and moves over nearly verbatim>

## Output contract
<exact files written, their required sections/fields — what the lint and
 downstream consumers can rely on>

## Exit
Print the output-contract summary (✅ block: what was produced, where, key
fields). Then STOP. Do not name a next stage. If invoked standalone, end with
exactly: "Routing is the flow's job — run the parent flow bare to continue."
````

**Forbidden content** (lint-enforced): other verbs' names in command position, any `/the-flow <id>`-shaped string, any `references/stages/<other>` path, any "Next routing"/"Next step" section. **Allowed**: the stage's own verb (a function knows its name), artifact names (the wire protocol), in-procedure seam calls per D3.

---

## The Flow Definition (firm)

A flow is two tables plus a grammar line, owned by the flow's dispatch layer. This *is* the data format — structured markdown, strict columns, parseable later.

### 1. Registry — the capability list (assigns ids; binds verbs to modules)

````markdown
## Registry

| id | verb      | module                      | consumes → produces                         | flags |
|----|-----------|-----------------------------|---------------------------------------------|-------|
| 1a | explore   | `stages/explore.md`         | intent → `research-dossier.md`              | `"<intent>"` |
| 1b | specify   | `stages/specify.md`         | intent, dossier? → `<slug>-spec.md`         | `"<intent>"` |
| 3  | architect | `stages/architect.md`       | spec, workshops?, coverage? → `<slug>-plan.md` | `--spec` |
| 6  | implement | `stages/implement.md`       | plan, tasks? → code + `execution.log.md`    | `--phase --plan` |
| 7  | review    | `stages/review.md`          | plan, code → `reviews/*.md`                 | `--plan` |
| 8  | merge     | `stages/merge.md`           | plan, review → merged (PROCEED-gated)       | `--plan` |
````

### 2. Graph — states × evidence × edges (+ decorations)

````markdown
## Graph

| state        | evidence (artifact)     | edges (on evidence → offer)                      | decorations |
|--------------|--------------------------|--------------------------------------------------|-------------|
| start        | —                        | research-worthy → **explore**; clear → **specify** | seam: session-start |
| awaiting-1b  | `<slug>-spec.md`         | → **architect** · opt: **workshop**              | compact ✓ · seam: post-spec (recommended) |
| awaiting-3   | `<slug>-plan.md` READY   | Simple → **implement** · Full → **tasks**        | compact ✓ |
| awaiting-6   | `execution.log.md` done  | clean → **review** · more phases → **tasks**     | compact ✓ · (seams fired in-stage per D3) |
| awaiting-7   | `reviews/*.md` clean     | → **merge**; findings → **implement** (fix loop) | |
| awaiting-8   | merge analysis           | PROCEED → complete                               | gate: typed PROCEED |
````

Edges name **verbs**, never commands. The graph row + registry row + grammar line are everything needed to render a command.

### 3. Grammar — defined exactly once

````markdown
## Command grammar
Printed commands are always `/<flow> <id> <verb> [flags]`, e.g.
`/the-flow 6 implement --phase "<Phase N: Title>" --plan "<path>"`.
Id or verb each resolve alone; printed form always carries both; mismatched
pair → show the Registry and ask.
````

Yesterday's 308-edit change under this model: edit the grammar line. Done.

### 4. Narration — templates with slots (voice stays, commands don't)

````markdown
### seam: awaiting-3 (after the plan)
> **Where we are**: the plan is written — Status: <READY|DRAFT> (gates: <matrix>).
> <flag-beat: lift the plan's alarm fields verbatim>
> <insight-beat: one real detail from the artifact>
> Next: {{render-edge}}            ← expands via Graph row + Registry + Grammar
> Type: <typeable answers derived from the edges>
````

---

## Template Inventory — template → instance → owner

The user-named surfaces, made explicit. "Template" = lives in the authoring library; "instance" = stamped into a flow skill at build time; "runtime output" = produced when the flow runs.

| Surface | Template (library) | Instance (per flow) | Runtime output (per plan/run) |
|---|---|---|---|
| Stage module | `stage.template.md` (§ Stage Template) | `stages/<verb>.md` | the stage's artifacts |
| Router/dispatch prompt | `dispatch.template.md` (two load paths, invariants, slots for Registry/Grammar) | `SKILL.md` | — |
| Flow graph | `graph.template.md` (column contract) | `00-routing.md` § Graph | — |
| Narration voice | `coach.template.md` (rail spec, Orient→Flag→Insight→Suggest→Invite, seam-script skeletons) | `coach.md` | the turn-by-turn narration |
| Flow state | `flow-state.schema.json` | (schema copied in) | `.the-flow-state.json` |
| Flight plan | `flight-plan.schema.json` + node templates (spine node, phase node, excursion node, seam node, user-bubble) | (schema + worked template copied in) | `the-flow.json` → `the-flow.md` |
| Phase/task table | `task-table.template.md` (7-column contract) | embedded in the tasks/architect verbs | `tasks/<phase>/tasks.md` |
| Views | `getting-started.template.md`, `quick-ref.template.md` | rendered + committed with banner | — |

Note the pattern already proven in this repo: `the-flow.json` (source) → `the-flow.md` (rendered view, banner-marked, never hand-edited). This inventory just applies that discipline to the skill's *own* files. One deliberate KISS deviation: views are committed derived files (normally we recompute views at read time) because skills must ship self-contained — `npx skills` copies folders, nothing renders at install. Mitigation: banner + freshness lint.

---

## The Authoring CLI (sketch — build-time only, never runs flows)

Working name open (candidates: `skillsmith`, `flowforge`). Verbs, not implementation:

```
$ skillsmith new flow <name>          # scaffold dispatch + graph + coach from templates
$ skillsmith new stage <verb>         # scaffold a library stage from stage.template.md
$ skillsmith assemble <flow>          # copy library verbs into the flow skill (static link);
                                      #   stamp Registry/Grammar slots into dispatch + coach
$ skillsmith lint <flow>              # run L1–L5 below; exit 0/1
$ skillsmith render <flow>            # regenerate views (getting-started, quick-ref, mermaid map)
$ skillsmith graph <flow>             # print the flow as mermaid (from the Graph table)
```

Hard constraint: **everything it emits is plain committed markdown**; a flow skill must be fully usable by someone (or some CLI's skill system) that has never heard of `skillsmith`. The CLI is to flow skills what a static site generator is to a website.

---

## The Ruleset (the reusable skills architecture — v2 of the paste guide)

- **R1 — One graph, one owner.** Edges ("what's next") live only in the flow's Graph. Stage modules never name other stages, ids, or flow commands. *(Lint L1)*
- **R2 — Stages are verbs with contracts.** Every stage declares Verb / Purpose / Consumes / Flags / Produces / Side-effects at the top, from the firm template. *(Lint L2)*
- **R3 — Artifacts are the interface.** Stages communicate through disk only; the graph routes on artifact existence (the idempotency rule the-flow already has — keep it, it's the good bone). Never on conversation memory or "the previous stage said."
- **R4 — Presentation defined once.** One grammar line, one rail spec, one voice file; narration uses slots, never literal commands. *(Lint L3)*
- **R5 — Direct jump gets a constant return, not an edge.** A standalone-invoked stage ends with the fixed "run the parent flow bare to continue" line.
- **R6 — Seam placement by shape.** Wrapping seams = graph edge decorations; in-procedure seams = stage side-effects, declared in the contract block. (Harness one-door rule unchanged: only `/eng-harness-flow --event …`, never children.)
- **R7 — Views are rendered, banner-marked, never authoritative.** Anything derivable from Registry + Graph + Grammar says so in its first line. *(Lint L5)*
- **R8 — Ids are flow property, verbs are stage property.** The Registry is the only place they meet.

## The Lints (deterministic — sensors prove, not the LLM)

| # | Check | Mechanism (sketch) | Pass condition |
|---|-------|--------------------|----------------|
| L1 | Stage leakage | grep each `stages/<verb>.md` for: other registry verbs in command position, `/<flow> [0-9]`-shaped strings, paths to sibling modules, "Next routing/Next step" headings | 0 hits (today: ~147) |
| L2 | Contract block present | grep each stage for the required `**Verb**/**Consumes**/**Produces**` fields | all present |
| L3 | Grammar conformance | every `/<flow> …` string in flow-level files matches `/<flow> <id> <verb>` against the Registry | all match |
| L4 | Closure | every Graph edge target exists in the Registry; every stage's Consumes is some upstream's Produces or a declared flow input | graph closed |
| L5 | View freshness | every view carries the rendered-banner; (later) `skillsmith render --check` diffs | clean |
| L6 | Host limits | frontmatter parses as YAML; `description` ≤ 1024 chars (strictest known host — Copilot CLI enforces it; Claude Code is permissive, so overruns ship silently until a stricter host rejects the skill) | all skills under limit |

Shipped as `scripts/check-flow-architecture.sh` (sibling of `check-skill-slugs.sh`), hard-fail. L1 alone makes the migration self-verifying: done when the grep returns zero.

---

## Worked Example — a mini-flow assembled from the library

A 3-verb "triage" flow, to show the whole shape at fresh-entrant scale:

````markdown
# /triage — dispatch (stamped from dispatch.template.md)

## Registry
| id | verb     | module               | consumes → produces            | flags |
|----|----------|----------------------|--------------------------------|-------|
| 1  | gather   | `stages/gather.md`   | issue ref → `evidence.md`      | `"<issue>"` |
| 2  | diagnose | `stages/diagnose.md` | `evidence.md` → `diagnosis.md` | — |
| 3  | report   | `stages/report.md`   | `diagnosis.md` → `report.md`   | `--audience` |

## Graph
| state      | evidence       | edges            | decorations |
|------------|----------------|------------------|-------------|
| start      | —              | → **gather**     | |
| awaiting-1 | `evidence.md`  | → **diagnose**   | compact ✓ |
| awaiting-2 | `diagnosis.md` | → **report**     | |
| awaiting-3 | `report.md`    | complete         | |

## Command grammar
Printed commands: `/triage <id> <verb> [flags]`.
````

`stages/diagnose.md` contains its Purpose/Consumes/Produces/Procedure and ends with the constant Exit line. It does not contain the strings `gather`, `report`, `/triage 1`, or `/triage 3` anywhere. When the user finishes stage 1, the router (already in context) reads the Graph row for `awaiting-1`, joins the Registry row for `diagnose`, applies the grammar, and prints:

```
/triage 2 diagnose
```

Reordering the flow, inserting a stage, or renaming the command surface touches **only this file**.

---

## Migration Path for `the-flow`

No time estimates — CS only. Each phase independently shippable; lints make completion deterministic.

| Phase | What | CS | Done when |
|-------|------|----|-----------|
| A | Write the ruleset doc (v2 of the paste guide) + `check-flow-architecture.sh` (L1–L4) | CS-1 | lint runs, reports current 147 as failures |
| B | De-leak the stage modules: delete "Next routing" headers + trailing next-steps; add contract blocks + constant Exit line; Graph absorbs any edge not already in the routing table. **Includes the D7 fold**: delete `61-implement-companion.md`, move its minih protocol into an optional companion-mode section of the implement verb, add the review-supersession edge decoration (11 modules → 10) | CS-2 | L1 = 0 hits, L2 clean, no `6c` in Registry |
| C | Coach → slot templates: replace literal commands in narration scripts with `{{render-edge}}` per D5; Grammar section becomes the single definition | CS-2 | L3 clean |
| D | Extract the template library (`stage.template.md`, `dispatch.template.md`, `coach.template.md`, schemas) into `skills-architecture/templates/` (location TBD in spec); verb-name the stage files per D2 | CS-2 | a second toy flow can be assembled by hand from templates |
| E | The authoring CLI (`new` / `assemble` / `lint` / `render`) | CS-3 | toy flow assembled by CLI byte-identical to hand assembly |

Phases A–C deliver most of the value (single-owner edges, 1-edit grammar changes) with zero new tooling. D–E are only worth it when a second real flow shows up — which is exactly the trigger the user named ("a system we can re-use to split up other flows").

## Attention Reduction

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Editing the command surface | 308 strings / 20 files / regex + 10 hand-fixes | 1 grammar line (+ regenerate views) |
| Adding a stage | new module + edits in routing table, coach, getting-started, templates, plus every stage that references neighbours | 1 module from template + 1 Registry row + Graph edges |
| Reordering / inserting stages | unknown blast radius across ~147 cross-refs | Graph edges only |
| Building a new flow (e.g. lite-flow) | re-do plan-030 by hand from a guide that bakes in the leak | Registry + Graph over existing verbs; assemble |
| Reviewing a flow change | read everything, judge consistency by eye | run the lints; review only the Graph diff |
| Onboarding an agent to author flows | imitate the-flow (inherits its flaws) | follow templates + ruleset; lints confirm |

## Validation / Acceptance

This workshop reaches its target proof level when:

- The Stage Template and Flow Definition tables are concrete enough that Phase B/C of the migration can be specced from them without re-opening design questions.
- The ruleset (R1–R8) and lints (L1–L5) cover every leak class found in the measurement (cross-stage refs, literal commands, duplicated grammar, unowned views).
- A reader can assemble the worked mini-flow by hand using only this document.
- The portability constraint is satisfied on paper: nothing in a shipped flow references the CLI or the library.

## Open Questions

### Q1: Graph format — markdown tables or JSON?
**RESOLVED**: Structured markdown tables with strict column contracts (D1). They are the doc, the prompt, and the data at once; a CLI can parse them later. Revisit only if a second flow proves a parse need the tables can't meet.

### Q2: Do stage filenames keep their `NN-` prefixes?
**RESOLVED**: No — verbs are stage property, ids are flow property (D2/R8). But the rename is cosmetic and deferred to Phase D to keep Phases B/C diff-small.

### Q3: CLI name, language, and home repo?
**OPEN**: `skillsmith` / `flowforge` / other; Python-stdlib-only (repo convention for bundled CLIs) vs Rust; lives in this repo's `scripts/` vs its own repo. Decide at Phase E trigger — explicitly out of scope until a second real flow exists (echoes the "harness extraction is a separate later effort" precedent).

### Q4: Can two flows in one repo share a verb library without drift?
**OPEN**: Build-time copy (assemble) answers correctness but not ergonomics — `assemble` would need a `--check` mode (like `sync-to-dist.sh`) so CI catches a flow that's stale against the library. Design at Phase D.

### Q5: Does the coach voice generalize across flows?
**RESOLVED (direction)**: Yes — the voice (rail, Orient→Flag→Insight→Suggest→Invite, print-then-offer, compact handshake) is flow-agnostic and becomes `coach.template.md`; each flow supplies vocabulary (milestone names, seam scripts) into slots. The SDD-specific insights (e.g. "computational vs inferential tier") stay in the SDD flow's seam scripts.

### Q6: Is `.the-flow-state.json` schema part of the template set?
**OPEN**: Probably yes — `flow-state.schema.json` with flow-agnostic fields (`current_state`, `pending_command`, `milestones_*`) + a flow-specific extension block. Needs one more example flow to know where the seam is.

### Q7: What happens to stage 6c (companion) under the verb model?
**RESOLVED** (user, 2026-06-12): **Fold it in — companion is a mode of `implement`, not a verb.** The entire companion concept reduces to one optional question inside the implement verb: *do you run the minih code-review companion in the background or not?* If yes, here's how (spin-up, ping cadence, per-commit review, final debrief); if no, ignore — the section is skipped entirely and the verb is unchanged. Consequences:
- Registry loses the `6c` row; `implement` gains an optional companion mode (flag or user ask at the awaiting-tasks seam).
- `61-implement-companion.md` (the leakiest module — 21 cross-refs) is **deleted**; its unique minih-protocol content becomes a clearly-fenced *optional* section of the implement verb (an in-procedure concern per D3/R6 — it changes how the verb executes, not where the flow goes).
- The one piece of *flow* knowledge it carried — "a companion that reviewed every commit supersedes the review stage" — is a **graph edge decoration** on `awaiting-6 → review` ("skippable if companion reviewed all commits"), exactly where the coach already narrates it. Stage knows how to run a companion; only the graph knows what that means for routing.
- Dispatch invariant #7 ("Stage 6c owns the companion protocol") becomes "the implement verb's companion mode owns the protocol."

---

_Workshop complete. Decisions here are authoritative inputs for the 031 spec/architect stages per the flow's workshop contract._
