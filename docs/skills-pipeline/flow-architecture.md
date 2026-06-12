# Flow Architecture — sub-skills as verbs, flows as graphs, one grammar

**What this is**: the authoring pattern for **composable flow skills** — multi-stage skills (like `/the-flow`) built from reusable, contract-bound **sub-skills** composed by a single flow-level **graph**. Follow this document and the lint script tells you deterministically when you're done.

**Who it's for**: anyone (human or agent) authoring a new flow skill or editing an existing one. A fresh reader should be able to assemble the worked example at the bottom — and a brand-new flow of their own — from this document alone.

**Why it exists**: the first consolidated flow (`the-flow`, plan-030) shipped with every flow edge encoded in up to five places; its 11 stage modules carried **163 cross-stage references** (measured baseline, plan-031), and one formatting change to the command surface cost **308 string edits across 20 files** (commit `b26bce2`). This pattern collapses that class of change to one authoritative edit. The leak wasn't an accident — it was prescribed by the previous guide (see [§ Supersedes](#supersedes)).

**Enforcement**: `scripts/check-flow-architecture.sh <flow-dir>` (see [§ Lints](#lints)) — hard-fail, exit 0/1/2, sibling of `check-skill-slugs.sh`. Run via `just check-flow`.

---

## The two concepts

1. **Sub-skill** — the reusable unit. A sub-skill is **named by a verb** (explore, diagnose, implement…), declares a contract (what it consumes, what it produces, what flags it takes), does its work, and **knows nothing about any flow**: no stage ids, no successor names, no flow commands, no sibling paths. It could be lifted into a different flow unchanged.
2. **Flow** — the composition. A flow assigns **ids** to sub-skills (ids are a *flow* property; verbs are a *sub-skill* property), wires them with a **Graph**, and owns every piece of "what's next". "Stage" survives only as the flow-position concept — "stage 3 of this flow *is* the architect sub-skill".

Sub-skills talk to each other **only through artifacts on disk**. The flow routes on artifact existence, never on conversation memory.

### The layered model (one owner per layer)

```
┌──────────────────────────────────────────────────────────────────┐
│ VIEWS          getting-started, quick-reference, walkthroughs    │  rendered, banner-marked,
│                (derived — never authoritative)                   │  regenerable
├──────────────────────────────────────────────────────────────────┤
│ PRESENTATION   command grammar (defined ONCE) · rail spec ·      │  flow-level
│                narration templates with slots                    │
├──────────────────────────────────────────────────────────────────┤
│ COMPOSITION    the Graph: states × artifact-evidence × edges     │  flow-level — THE single
│                + edge decorations (seams, compact hints, modes)  │  owner of "what's next"
├──────────────────────────────────────────────────────────────────┤
│ REGISTRY       the capability list: id ↔ verb ↔ module ↔         │  flow-level — assigns ids;
│                contract (consumes → produces) ↔ flags            │  sub-skills don't know their ids
├──────────────────────────────────────────────────────────────────┤
│ SUB-SKILLS     verb modules: entry conditions · procedure ·      │  library-level — know
│                output contract · exit. NOTHING about the flow.   │  NOTHING above this line
└──────────────────────────────────────────────────────────────────┘
```

**The LLM-specific insight — the renderer is the model.** Progressive disclosure guarantees the dispatch/graph layer is in context for every invocation (it's how the sub-skill got loaded at all). So when a sub-skill finishes, the flow is right there to pick the edge and *render* the next command from Grammar + Registry. Pre-rendering next-step commands inside sub-skills is what created the 308-edit incident — the model can render them at narration time.

**The portability insight — compose at build, ship sealed.** Skill systems copy a skill folder as a self-contained unit; there is no cross-skill linking at run time. A shipped flow contains its own copies of its sub-skills; reuse happens at authoring time.

---

## The Sub-skill Template

Every sub-skill is stamped from this. The contract block is at the top, machine-checkable (lint L2); the procedure is free-form; the exit is fixed.

````markdown
# <verb>

> Sub-skill — part of a verb library. Knows nothing about any flow:
> no stage ids, no successor/predecessor names, no flow commands.
> Composition is the bundling flow's job.

**Verb**: architect
**Purpose**: <one sentence — what this sub-skill does to the world>
**Consumes**: <artifact patterns, marked required/optional>
            e.g. `<slug>-spec.md` (required) · `workshops/*.md` (optional)
**Flags**: `--spec <path>` <the verb's own flags — stable regardless of which flow calls it>
**Produces**: `<slug>-plan.md` <the artifacts this sub-skill writes — the ONLY way downstream sub-skills see its work>
**Side effects**: <in-procedure seam calls, if any — see § Seam placement>
**Delegates**: <optional — see § Declared delegation> e.g. `progress — per-task protocol; resolved via the Registry`

---

## Entry conditions
<what must exist on disk before this verb can run; error message if not>

## Procedure
<the actual work — as long and rich as the verb needs>

## Output contract
<exact files written, their required sections/fields — what the lint and
 downstream consumers can rely on>

## Exit
Print the output-contract summary (✅ block: what was produced, where, key
fields). Then STOP. Do not name a next stage. If invoked standalone, end with
exactly: "Routing is the flow's job — run the parent flow bare to continue."
````

**The constant Exit line** (byte-identical in every sub-skill — lint L2 checks it):

> Routing is the flow's job — run the parent flow bare to continue.

**Forbidden content** (lint L1, hard-fail): flow-command strings (`/<flow> <id>`-shaped), stage-position references (`stage 3`, case-insensitive), paths to sibling sub-skills (`stages/<other>.md`), and any "Next routing"/"Next step(s)" heading, bold label, or line-start form — matched case-insensitively and in singular or plural (`## Next Steps` is as forbidden as `**Next routing**`). **Allowed**: the sub-skill's own verb (a function knows its name), artifact names (the wire protocol), in-procedure seam invocations, and the two sanctioned exceptions below.

### Sanctioned exception 1 — shared-conventions lazy-pull

A sub-skill may cite the bundling flow's **shared-conventions anchor** (e.g. *"see `00-routing.md` § Shared conventions"*) for deduplicated blocks like complexity-score rules or domain-loading steps. This is a deliberate, documented portability cost: the citation names a flow-level file, but only its conventions block — never routing. Keep such citations to the one anchor.

### Sanctioned exception 2 — declared delegation

When one sub-skill follows another's **protocol in-procedure** (e.g. an implement verb runs a progress verb's per-task protocol after every task), that relationship is:

1. **Declared** in the contract block: `**Delegates**: progress — per-task protocol; resolved via the Registry`
2. **Named by verb** in the procedure prose ("after each task, follow the **progress** sub-skill's protocol — resolve it via the Registry") — never by sibling path, never as a command string.

The flow's Registry resolves the verb to a module at read time. Lint L1 stays path-strict and command-strict; verb names in non-command prose are legal.

### Seam placement (by shape)

- A seam that **wraps** a stage (a survey between two stages, a compact hint between phases) is a **Graph edge decoration** — flow-owned.
- A seam **interleaved with the verb's own procedure** (a pre-flight check before task 1, a drain after the last task) stays **in the sub-skill**, declared under `**Side effects**` — it is part of the verb's work and must survive direct-jump invocation.

---

## Flow Definition

A flow is **two tables plus a grammar section**, owned at flow level. Structured markdown with strict columns — simultaneously the human doc, the LLM-native prompt, and machine-parseable (the lint parses these exact formats).

**Exactly one master per table.** The Registry lives in exactly one declared place, the Graph in exactly one declared place. Every other copy (quick references, walkthroughs) is a **view**: banner-marked, regenerated, never authoritative.

### Permitted layouts

Either layout passes the lints — the discovery is by heading, not by filename:

1. **Single-file dispatch**: one flow-level `.md` (conventionally `SKILL.md`) carrying `## Registry`, `## Graph`, and `## Command grammar`, with sub-skills under `stages/`.
2. **Dispatch + references split** (the-flow's layout): `SKILL.md` carries the Registry + Grammar; a flow-level engine file (e.g. `references/00-routing.md`) carries the Graph; sub-skills under `references/stages/`.

```
<flow-dir>/
├── SKILL.md                  # dispatch: Registry + Command grammar (+ Graph, single-file layout)
├── references/               # optional (split layout)
│   ├── 00-routing.md         #   Graph + state contract + shared conventions
│   ├── coach.md              #   narration templates (slots)
│   └── stages/               #   sub-skills (or top-level stages/)
│       └── <verb>.md
└── stages/                   # single-file layout: sub-skills live here
    └── <verb>.md
```

### Minimal flow skeleton (what the lints require)

The smallest lintable flow is: **one flow-level `.md`** containing the three headed sections (`## Registry`, `## Graph`, `## Command grammar`) **plus one sub-skill** under `stages/` (or `references/stages/`) stamped from the Sub-skill Template. Frontmatter is optional (stubs without it skip L6); rendered views are optional (no views → L5 skips with a WARN). The dispatch may carry whatever behavioral invariants the flow needs (print-then-offer, gates, state rules) — the lints don't constrain them.

## Registry

The capability list: assigns ids, binds verbs to modules, states each contract. **Column contract is firm** (the lint parses it):

````markdown
## Registry

| id | verb      | module                 | consumes → produces                            | flags |
|----|-----------|------------------------|------------------------------------------------|-------|
| 1  | gather    | `stages/gather.md`     | issue ref → `evidence.md`                      | `"<issue>"` |
| 2  | diagnose  | `stages/diagnose.md`   | `evidence.md` → `diagnosis.md`                 | — |
| 3  | report    | `stages/report.md`     | `diagnosis.md` → `report.md`                   | `--audience` |
````

- `id` — the flow's name for the position (any short token: `1`, `1a`, `6`).
- `verb` — the sub-skill's name. **The Registry is the only place ids and verbs meet** (R8).
- `module` — relative path to the sub-skill file (must exist — lint L4).
- `consumes → produces` — the artifact contract, summarized from the sub-skill's contract block.
- `flags` — the verb's own flags (`—` for none).

A row may carry a **mode flag** in its flags column (e.g. `--companion`) when a verb has optional in-procedure modes — modes are *not* separate Registry rows.

### Alias / translation tables (optional)

A flow that renames or retires entry points may keep a read-time **translation table** (old name → stage). Targets are stored in **id+flag form without the flow token** (e.g. `6 implement --companion`, never `/the-flow 6 implement --companion`) and rendered through the Grammar at read time. Each retired name appears exactly once. The table is one of the three places literal-ish command content is allowed (lint L3 exempts it).

## Graph

States × artifact-evidence × edges (+ decorations). The Graph is **the single owner of "what's next"** (R1). Column contract is firm:

````markdown
## Graph

| state      | evidence       | edges (on evidence → offer)            | decorations |
|------------|----------------|----------------------------------------|-------------|
| start      | —              | → **gather**                           | |
| awaiting-1 | `evidence.md`  | → **diagnose**                         | compact ✓ |
| awaiting-2 | `diagnosis.md` | → **report**                           | |
| awaiting-3 | `report.md`    | complete                               | |
````

- `state` — keyed on the step just issued (`awaiting-<id>`).
- `evidence` — the artifact whose existence proves the state's work happened (drives idempotent resume: artifact missing → re-print the pending step, never advance).
- `edges` — name **verbs in bold**, never commands, never module paths. Conditional edges read `condition → **verb**`.
- `decorations` — everything that *rides* an edge: compact hints, wrapping seams, gates (e.g. `gate: typed PROCEED`), mode notes ("review skippable if a companion reviewed every commit"). A flow may add extra columns (e.g. an insight-source column for narration) — extra columns are legal; the four above are required.

## Command grammar

Defined **exactly once** per flow. Every printed command everywhere else is rendered from this line + a Registry row + a Graph edge:

````markdown
## Command grammar

Printed commands are always `/<flow> <id> <verb> [flags]`, e.g.
`/triage 2 diagnose --audience ops`.
Id or verb each resolve alone; printed form always carries both; mismatched
pair → show the Registry and ask.
````

The grammar section **must show the literal flow token** in a backticked example (`/triage …` above) — the lint derives the flow's command token from this section (fallback: the flow directory name), so it never hardcodes any one flow's name.

**Literal command strings are allowed in exactly three places** (lint L3): (a) this grammar definition, (b) the alias/translation table (id+flag targets), (c) banner-marked rendered views — view strings must still conform to the Registry. Everywhere else — narration, sub-skills, engine prose — commands are rendered, not written. One escape hatch exists for **frozen contract text** that quotes a command and must survive byte-identical (e.g. a state-ownership contract): place `<!-- lint:allow-flow-commands -->` on its own line immediately before the section heading; the lint exempts that section. Use sparingly and say why in the marker's vicinity.

A change to the command surface under this model is **one edit** to this section (plus regenerating views).

---

## Narration slots

A flow with a guided/coached mode keeps its **voice** in narration templates whose command positions are **slots**, rendered at narration time from Grammar + Registry + Graph:

````markdown
### seam: awaiting-2 (after diagnosis)
> **Where we are**: the diagnosis is written — <one real detail from the artifact>.
> Next: {{render-edge: awaiting-2}}        ← expands via Graph row + Registry + Grammar
> Type: <typeable answers derived from the edges>
````

Rules:

- Narration may name **verbs** in teaching prose ("next is the architect") — verbs are Registry-stable. It may never hardcode a command string.
- Worked examples inside the voice spec (rail mock-ups, handshake diagrams) are slot-converted too, or moved into a banner-marked view.
- **Render-at-write-time**: slots cannot be stored in durable state. When a flow writes a runnable command into a state file (`pending_command` etc.), it renders the command through the Grammar at write time. Tables that *feed* state files name verbs/ids and carry an explicit render-at-write-time note.

---

## Ruleset

- **R1 — One graph, one owner.** Edges live only in the flow's Graph. Sub-skills never name other stages, ids, or flow commands. *(Lint L1)*
- **R2 — Sub-skills are verbs with contracts.** Every sub-skill declares Verb / Purpose / Consumes / Flags / Produces / Side effects at the top, from the firm template. *(Lint L2)*
- **R3 — Artifacts are the interface.** Sub-skills communicate through disk only; the Graph routes on artifact existence — never on conversation memory or "the previous stage said".
- **R4 — Presentation defined once.** One grammar line, one voice file; narration uses slots, never literal commands. *(Lint L3)*
- **R5 — Direct jump gets a constant return, not an edge.** A standalone-invoked sub-skill ends with the fixed Exit line: "Routing is the flow's job — run the parent flow bare to continue."
- **R6 — Seam placement by shape.** Wrapping seams = Graph edge decorations; in-procedure seams = sub-skill side effects, declared in the contract block.
- **R7 — Views are rendered, banner-marked, never authoritative.** Anything derivable from Registry + Graph + Grammar says so in its first line. *(Lint L5)*
- **R8 — Ids are flow property, verbs are sub-skill property.** The Registry is the only place they meet.

The two sanctioned exceptions to R1 are documented above: the shared-conventions lazy-pull and declared delegation (`**Delegates**`).

---

## Lints

Shipped as [`scripts/check-flow-architecture.sh`](../../scripts/check-flow-architecture.sh) — `check-flow-architecture.sh [flow-dir]` (default `skills/SDD/the-flow`). Conventions: `set -euo pipefail`; `OK:` / `ERROR:` / `WARN:` line prefixes; exit **0** clean, **1** any ERROR, **2** usage/environment problem. The flow-command token is **derived per flow** (from `## Command grammar`, fallback: directory name) — the script works on any flow, not just the-flow.

| # | Check | Mechanism | Severity |
|---|-------|-----------|----------|
| L1 | Sub-skill leakage | grep each sub-skill for: `/<flow> <id>`-shaped strings, case-insensitive `stage <n>` refs, sibling sub-skill paths, Next-routing/Next-step markers (heading and bold-label form). `**Delegates**` contract lines are excluded | ERROR |
| L2 | Contract block + Exit line | each sub-skill carries `**Verb**` `**Purpose**` `**Consumes**` `**Flags**` `**Produces**` `**Side effects**` and the byte-exact constant Exit line | ERROR |
| L3 | Grammar conformance | **flow-level** files carry zero `/<flow> <id> <verb>` literals outside the Command grammar section; banner-marked views may carry them but their strings must match the Registry; a section explicitly preceded by `<!-- lint:allow-flow-commands -->` is exempt (frozen-contract quotations — use sparingly, say why) | WARN until the Registry table parses, then ERROR |
| L4 | Closure | every Graph edge verb exists in the Registry; every Registry module path exists on disk | WARN until both tables parse, then ERROR |
| L5 | View banner | every rendered view (convention names `getting-started.md` / `quick-ref*.md`, plus any files listed in a `## Views` section) carries a first-line regeneration banner | ERROR when views exist; WARN-skip when none |
| L6 | Host limits | frontmatter parses; `description` ≤ 1024 chars (strictest known host) | ERROR; skip files without frontmatter (stubs) |

**Graceful degradation is deliberate**: on a flow that hasn't yet adopted the firm tables, L3/L4 run in warn-mode — the script is still useful mid-migration, and the checks harden automatically the moment the tables parse. L1 alone makes a de-leak migration self-verifying: done when the grep returns zero.

---

## Worked example

A 3-verb "triage" flow at fresh-entrant scale. Dispatch first (single-file layout):

````markdown
# /triage — dispatch

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

Printed commands are always `/triage <id> <verb> [flags]`, e.g. `/triage 2 diagnose`.
Id or verb each resolve alone; printed form always carries both; mismatched
pair → show the Registry and ask.
````

And one complete sub-skill, `stages/diagnose.md`:

````markdown
# diagnose

> Sub-skill — part of a verb library. Knows nothing about any flow:
> no stage ids, no successor/predecessor names, no flow commands.
> Composition is the bundling flow's job.

**Verb**: diagnose
**Purpose**: Read the gathered evidence and produce a root-cause diagnosis.
**Consumes**: `evidence.md` (required)
**Flags**: —
**Produces**: `diagnosis.md`
**Side effects**: none

---

## Entry conditions
`evidence.md` must exist in the working directory. If missing, say so and stop.

## Procedure
Read `evidence.md`. Identify candidate causes, test each against the evidence,
rank by likelihood. Write `diagnosis.md` with: `## Root cause`, `## Confidence`,
`## Ruled out` (one line each, with the evidence that ruled it out).

## Output contract
`diagnosis.md` with the three sections above; `## Root cause` is one paragraph;
`## Confidence` is High/Medium/Low with a reason.

## Exit
Print the output-contract summary (✅ block: what was produced, where, key
fields). Then STOP. Do not name a next stage. If invoked standalone, end with
exactly: "Routing is the flow's job — run the parent flow bare to continue."
````

Note what `diagnose.md` does **not** contain: the sibling module paths (`stages/gather.md`, `stages/report.md`), any stage id, or any flow command (`/triage 1`, `/triage 3`). Plain English may still say "the gathered evidence" — the rules (and L1) forbid *structural* coupling, not vocabulary. When the user finishes stage 1, the flow (already in context) reads the Graph row for `awaiting-1`, joins the Registry row for `diagnose`, applies the Grammar, and prints `/triage 2 diagnose`. Reordering the flow, inserting a stage, or renaming the command surface touches **only the dispatch**.

**Check your work**: `scripts/check-flow-architecture.sh <your-flow-dir>` — a freshly assembled minimal flow should pass L1/L2/L4 (L3 active once your Registry parses; L5/L6 skip with WARNs if you have no views/frontmatter).

---

## Supersedes

This document **supersedes the v1 progressive-disclosure migration guide** (the plan-030 era "split a big skill into a dispatch + lazily-loaded step modules" guide, last seen at `scratch/paste/20260611T080711.md`) **as the authoring pattern for flow skills**. That guide's step-module template ended with a section literally titled **"Next routing instruction"** — it *prescribed* that every module name its successor, which is how the-flow shipped with 163 cross-stage references and a 308-edit cost for one grammar change. The progressive-disclosure mechanics it taught (small dispatch, lazy module loads) remain correct and are assumed here; its step template is retired. If you are about to add a "Next step" section to a sub-skill: don't — that edge belongs in the Graph.

**The exemplar**: `skills/SDD/the-flow/` is the reference implementation of this pattern (Registry master in `SKILL.md`, Graph master in `references/00-routing.md`, slotted coach, banner-marked views, lint-clean sub-skills under `references/stages/`).
