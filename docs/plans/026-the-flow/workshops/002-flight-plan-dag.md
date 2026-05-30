# Workshop: The Flight-Plan DAG — `the-flow.json` + `the-flow.md` (hand-cranked)

**Type**: Storage Design / Data Model
**Plan**: 026-the-flow
**Spec**: [the-flow-spec.md](../the-flow-spec.md)
**Created**: 2026-05-30
**Status**: Draft

**Value Thesis**: Pins the **source-of-truth contract** (`the-flow.json`) and its two renders (`the-flow.md` mermaid + the one-line rail) so the implementer builds one stable artifact, not three drifting ones — and so future first-class tooling has a contract to target. Makes the flow's *future* visible and its *past* auditable (verbatim user input + artifact links per node).
**Target Proof Level**: Implementation Ready
**Current Proof Level**: Contract Ready (schema + renders + worked example are concrete; hand-crank cadence is judgement, validated only by the `/plan-6` walkthrough)

**Selected Value Axes**:
- **Implementation Readiness**: the implementer writes the JSON schema + the two render rules straight from here.
- **Agent Readiness**: an agent updates the DAG deterministically each turn (which field, when).
- **Knowability**: the graph makes the future (assumed vs known) and the past (what/why/who) explicit.
- **Learning Compounding**: verbatim `user_input` + artifact links per node = a durable record of what was actually done.
- **Forward-Compatibility (tooling)**: the JSON contract is what later first-class tooling will produce/validate/render.

**Related Documents**:
- [workshop 001](./001-narration-scripts-and-compact-contract.md) — D5 (rail), D6 (verbatim ask), D8 (mermaid), D9 (flight-plan DAG) — this workshop is their consolidated, implementation-ready form.
- Samples: [sample-the-flow.json](../references/sample-the-flow.json) · [sample-the-flow.md](../references/sample-the-flow.md)

**Domain Context**: No registry; the new `skills/SDD/the-flow/` skill owns this contract.

---

## Purpose

Specify the **flight-plan DAG** that `the-flow` maintains for every run: the JSON source of truth, the two things rendered from it (mermaid + rail), the status/colour taxonomy, and — critically — **how it is kept up to date by hand (inference) while first-class tooling is out of scope**.

## Fresh Entrant Outcome

A fresh human or agent can use this to reach **Implementation Ready**: write/parse `the-flow.json`, render `the-flow.md` and the rail from it, know which field changes at which seam, and do it all by inference without any CLI.

## Key Questions Addressed

1. What is the exact JSON shape of a flight-plan node + document?
2. How do `the-flow.md` (mermaid) and the rail derive from it — deterministically?
3. What are the statuses, what colour does each get, and when do they transition (esp. `assumed → known`)?
4. **Who maintains it, given there's no tooling?** (Answer: the skill, by inference, every turn.)

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | Implementation Ready | `/plan-6` writes the JSON + render rules with no further design. |
| Primary Value Axis | Implementation Readiness | The schema + render rules *are* the feature's data layer. |
| Supporting Axes | Agent Readiness, Knowability, Forward-Compat | An agent must update it deterministically; the graph must be legible; tooling must be able to target it later. |
| Downstream Loop Improved | Implementation now; tooling/agent-harness integration later | One stable contract instead of three hand-maintained renders drifting apart. |

---

## Decision Space

| Option / Question | Decision |
|---|---|
| **First-class CLI/tooling to produce, validate, and render the flight plan** | **OUT OF SCOPE (this plan).** We **hand-crank by inference + LLM power**: `the-flow` (the skill) writes/updates `the-flow.json` and re-renders `the-flow.md` + the rail itself, each turn. No generator, no JSON-schema validator, no `flight-plan` CLI yet. The JSON contract here is deliberately tooling-ready so that future first-class tooling can take over production/validation/rendering without changing the shape. |
| Source of truth | **`the-flow.json`** is canonical; `the-flow.md` + rail are **derived views**. On any change: update JSON → regenerate MD → regenerate rail. Never edit the MD by hand as the primary. |
| Validation, given no validator | **LLM self-check by inference**: before writing, the skill confirms the node has required fields, edges resolve, exactly one `cursor`, monotonic status moves. A `references/flight-plan.template.json` ships as the shape to copy. |
| Graph shape | **DAG** — `next[]` edges; excursions use `branch_of` + dotted edges that rejoin the spine. Not a tree (a node can have multiple `next`, e.g. a phase → fix-loop **and** next phase). |
| Two future shades | `known` (designed, e.g. phases locked by `/plan-3`) vs `assumed` (speculative, e.g. a conditional fix loop). |
| **Parallel agents (companions + workers)** | Tracked in `agents[]`. the-flow **narrates the affordance + records them**, but **does not run minih** (coach model); `/plan-6-companion` owns the protocol. Companion → **wraps** its phases; worker → **side-node**. Both optional. Generalises beyond `code-review-companion` to any minih agent. |

> **Why hand-crank is acceptable now**: the artifacts are small (≤~15 nodes), the skill already reads every upstream artifact to narrate, and the value (visible future + audit trail) lands immediately. Tooling is a *performance/robustness* upgrade, not a correctness prerequisite — so it can follow.

---

## The JSON contract — `the-flow.json`

**Document**:

```jsonc
{
  "schema_version": 1,
  "kind": "flight-plan",
  "slug": "<plan slug>",
  "plan_dir": "docs/plans/<ord>-<slug>",
  "mode": "Simple | Full | unknown",
  "cursor": "<id of the current node>",
  "recommended_next": "<id the-flow will suggest next>",
  "now": "<current node label>",
  "next": "<next label — omit when there are multiple options; narration lists them>",
  "agents": [ /* Agent[] — parallel minih agents (companions + workers) */ ],
  "nodes": [ /* Node[] */ ]
}
```

**Node**:

| Field | Req | Meaning |
|-------|-----|---------|
| `id` | ✓ | stable short id (`spec`, `p3`, `dr`, `fx3`) |
| `type` | ✓ | `research \| deep-research \| spec \| workshop \| backpressure \| plan \| adr \| phase \| fix-loop \| review \| merge` (each workshop is its **own** `workshop` node) |
| `label` | ✓ | display text |
| `status` | ✓ | `done \| in_progress \| blocked \| known \| assumed` (see taxonomy) |
| `next[]` | ✓ | downstream node ids (DAG edges); `[]` for terminal |
| `command` | | the `/plan-*` (or tool) command this node runs |
| `ran_at` | | ISO timestamp when executed |
| `user_input` | | **verbatim** user words that drove this step (audit) |
| `note` | | what was done & why (1–2 lines) |
| `artifacts[]` | | repo-relative paths this node produced/links (`*-spec.md`, `tasks/.../execution.log.md`, `reviews/*.md`, plan folder) |
| `branch_of` | | for excursions: the spine node id it hangs off |
| `phase` | | for `type:phase`: the phase number |
| `iterations` | | for a `fix-loop`: rounds taken (completed workshops are separate `workshop` nodes, not a collapsed loop) |
| `tool` | | for `deep-research`: `perplexity \| harness \| …` (tool of choice) |

Full worked node-set: [sample-the-flow.json](../references/sample-the-flow.json).

**Agent** (document-level `agents[]` — parallel minih agents running alongside the flow):

| Field | Req | Meaning |
|-------|-----|---------|
| `id` | ✓ | stable short id |
| `kind` | ✓ | `companion` (watches, advisory) \| `worker` (does a slice of work in parallel) |
| `slug` | ✓ | minih agent slug (e.g. `code-review-companion`, `docs-writer`) |
| `runtime` | | `minih` (today the only one) |
| `run_id` | | minih run id once booted |
| `status` | ✓ | `live \| queued \| done \| dead` |
| `covers[]` | ✓ | node ids the agent spans (a companion wraps these; a worker builds into them) |
| `render` | | `wrap` (companion → subgraph around `covers[]`) \| `side` (worker → side-node into `covers[]`) — defaults from `kind` |
| `driver` | | the skill that runs it (e.g. `/plan-6-v2-implement-phase-companion`); blank if the user `minih run`s it ad-hoc |
| `note` | | role / what it watches or builds |

> the-flow **tracks** `agents[]` (coach model — it doesn't run minih); `/plan-6-companion` owns the minih protocol. Companions are always optional (`--no-companion` fallback).

---

## Status taxonomy → colour (the single source for both renders)

| `status` | Meaning | mermaid class | Rail glyph |
|----------|---------|---------------|-----------|
| `done` | ran, accepted | `done` 🟩 green | `◆` |
| `in_progress` | running now (`cursor`) | `wip` 🟧 orange | (current; shown via `· next:`/`phase k/n`) |
| `blocked` | hit a wall, needs input | `blocked` 🟥 red | `◆`+note |
| `known` | **designed** future (e.g. phases locked by `/plan-3`) | `known` 🟦 blue-grey | `◇` |
| `assumed` | **speculative** future, may change (e.g. conditional fix loop) | `assumed` ⬜ dashed grey | `◇` (or omitted from rail until known) |

**Transitions** (all monotonic except `blocked`): `assumed → known` (when `/plan-3` designs it) → `in_progress` (started) → `done`; any active node → `blocked` → back to `in_progress`. The rail counts `done` over `milestones_total`; excursions and `assumed` conditionals don't consume a rail diamond.

---

## Render 1 — `the-flow.md` (mermaid), generated from the JSON

Rules:
1. `flowchart TD` (vertical).
2. Emit the 5 `classDef`s (done/wip/blocked/known/assumed) — copy from the template.
3. **Spine** = nodes on the `type ∈ {research, spec, plan, phase, merge}` path, linked by solid `-->` in `next` order.
4. **Excursions** (`branch_of` set: deep-research, **each** workshop, backpressure, fix-loop) = dotted `-.->` from their `branch_of` node, rejoining at the spine node in their `next`. **Every workshop is its own node** (no `↻` collapsing — hide no detail); a still-pending `fix-loop` stays a single `assumed` node until it runs.
5. Each node `:::<class>` from its `status` (`done/wip/blocked/known/assumed` classDefs).
6. **User bubbles**: for every node with `user_input`, emit a `said`-class flag node (`>"🗣 …"]`) dotted (`-.-`) to it — verbatim, nothing hidden.
7. **Agents**: for each `agents[]` entry — `kind:companion` (`render:wrap`) → a **subgraph that wraps** its `covers[]` phases, `style`d with the companion colour; `kind:worker` (`render:side`) → a `worker`-class side-node linked `-. builds .->` to its `covers[]`.
8. Legend line beneath (done/wip/blocked/known/assumed + 🗣 user input + companion + worker).

(Worked output: [sample-the-flow.md](../references/sample-the-flow.md).)

## Render 2 — the one-line rail, generated from the JSON

`[the-flow] <flow-nodes>[<phase-nodes>]<flow-nodes>  ·  <status line>` where each rail diamond is `◆` if that milestone's node is `done`, else `◇`; per-phase nodes are wrapped in one `[ … ]`. **Status line** (distinct accent colour) = `now: <cursor label> · next: <recommended_next label>`; in a phase add `· phase k/n`. **Dynamic expansion**: single short next → inline; **≥2 options or would wrap** → `now`/`next` each on their own line, options stacked (recommended first). Prints on its own line, then a blank line, then the narration (workshop 001 D5).

---

## Hand-crank contract (because CLI is OOS)

`the-flow` is the generator until tooling exists. **Every turn**, after it decides the narration:

1. **Mutate the JSON** for what just happened: set the completed node `status: done`, stamp `ran_at`, capture the user's **verbatim** `user_input`, write the `note`, append produced `artifacts[]`; advance `cursor`/`recommended_next`.
2. **Reveal/refine future**: at `/plan-3`, replace the `assumed` phase placeholder with real `known` phase nodes (one per phase) + recompute `milestones_total`. Add conditional `assumed` nodes (fix-loops) as `branch_of` the relevant phase.
3. **Regenerate** `the-flow.md` from the JSON, then the rail.
4. **Self-check** (no validator): required fields present, every `next` id exists, single `cursor`, no backwards status moves.

> Invariant: **never** hand-edit `the-flow.md` as the primary — it is always a function of `the-flow.json`. This is what lets future tooling drop in.

---

## Worked snapshot (chainglass `001`, Phase 3 in progress)

Rail: `[the-flow] ◆─◆─◆─[◆─◆─◇─◇─◇─◇]─◇ · phase 3/6` — full JSON + mermaid in the two sample files. Shows `done` (Research/Spec/Plan/P1/P2 + excursions), `in_progress` (P3), `known` (P4–P6, Merge), `assumed` (the `fix loop?` off P3).

---

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| Node + document schema | § JSON contract | AC-16 | Ready |
| Status→colour→rail table | § Status taxonomy | AC-12/15/16 | Ready |
| Two render rule-sets | § Render 1 / 2 | AC-15 | Ready |
| Hand-crank cadence | § Hand-crank contract | AC-16 (no-tooling reality) | Ready |
| Worked JSON + MD | `references/sample-the-flow.{json,md}` | all of the above | Ready |
| Ship templates | `skills/SDD/the-flow/references/flight-plan.template.{json,md}` | standardisation | Draft (built in T006) |

## Attention Reduction

| Future Loop | Before | After |
|---|---|---|
| Implementation (`/plan-6`) | "invent a JSON shape + 2 renders + update rules" | copy the schema, the 2 render rule-sets, and the hand-crank cadence |
| Agent execution | "what do I update each turn?" | the 4-step hand-crank list |
| Future tooling | "reverse-engineer the format" | a stable, documented JSON contract to target |

## Validation / Acceptance

- A reader can author `the-flow.json` for a fresh run and render both views from it. ✅
- The hand-crank cadence names exactly what changes each turn. ✅
- `assumed → known` at `/plan-3` is specified. ✅
- Templates shipped in the skill match this schema (verified in T006/T005). ⏳ (at build)

## Open Questions

- **Q1 — JSON-schema validator?** OPEN (deferred): none now (LLM self-check). When first-class tooling lands, add a real `flight-plan.schema.json`. Not a blocker.
- **Q2 — `the-flow.md` vs legacy `<slug>.fltplan.md`?** RESOLVED: separate file (`the-flow.md`) this plan; first-class tooling later decides on convergence. No edits to `plan-5b`.
- **Q3 — node id stability across re-plans?** RESOLVED: ids are stable; `/plan-3` re-plan replaces `assumed` placeholders but keeps existing `done` node ids.
