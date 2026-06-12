# the-flow · routing & state — the guided-mode engine

Loaded by the dispatch ([`../SKILL.md`](../SKILL.md)) in **guided mode**, together with [`coach.md`](./coach.md) and the **current stage module only**. Direct jumps (`/the-flow <id|name> [flags]`) do not load this file up front — a stage module may cite a `§ Shared conventions` block below and pull it lazily when needed; that is still progressive disclosure.

This file owns: entry paths, the state contract, **state-write ownership**, the **Graph** (the single owner of "what's next" — flow-architecture pattern, `docs/skills-pipeline/flow-architecture.md`), the must-see flag fields, harness-seam detection, flight-plan bookkeeping, and the shared conventions the sub-skills cite.

---

## Entry paths — fresh / resume / adopt

On guided invocation (`/the-flow` with no args, or `/the-flow <slug>` / `/the-flow <ord>-<slug>`):

1. **Glob** `docs/plans/*/.the-flow-state.json` where `status == "active"`.
   - An explicit `<slug>` / `<ord>-<slug>` arg → resume that one (skip the scan).
2. **Branch on the result**:
   - **Exactly 1 active** → **RESUME** (below).
   - **>1 active** → list them (slug + `current_stage`) and ask which to resume; offer "start a new one".
   - **0 active**:
     - Target plan folder **already holds artifacts** (`*-spec.md`, `*-plan.md`, `tasks/phase-*/`, `reviews/`) → **ADOPT** (see [`coach.md`](./coach.md) § Adoption contract).
     - Else → **FRESH START**.

### Fresh start (no state, no artifacts)

Ask the intent (coach.md `start` narration). After the user answers:

1. Allocate the ordinal via `plan-ordinal` (alias `jk-po`); fall back to a local `docs/plans/` scan if unavailable.
2. **Derive the slug** = kebab-case of the intent's first ~3–5 significant words (drop filler).
3. `mkdir -p docs/plans/<ord>-<slug>/`.
4. **Write the verbatim ask** to `original-ask.md` (shape below) and mirror it into `state.intent`.
5. Write `.the-flow-state.json` (temp file + atomic rename).
6. Initialise `the-flow.json` (a `start`/`research` node + `assumed` future) and render `the-flow.md`.
7. Print-and-offer the **explore** edge (research-worthy intent) or the **specify** edge (clear ask) — the command is rendered from the dispatch's Command grammar + Registry, with the intent as the verb's argument.

Stages 10/20 both **reuse** an existing `docs/plans/*-<slug>/` folder by slug — creating it first is safe.

**`original-ask.md` shape**:

```markdown
# Original ask — <slug>
**Captured**: <ISO>  ·  **By**: /the-flow

> <the user's verbatim words, unedited>
```

### Resume (exactly one active state)

Read the state. Discover the artifact for `current_stage` (Graph below). Apply the **idempotency rule**, narrate (coach.md), then hand-crank `the-flow.json`/`.md` (§ Flight plan).

**Idempotency rule (every resume)**: discover the artifact for `current_stage` by existence at its expected path (newest if several, scoped by `last_checkpoint_at` mtime).
- **Found** → narrate the stage's insight, persist the next stage + `pending_command`, print-and-offer the next command.
- **Not found** → re-print `pending_command` **verbatim** and stop. **Do not advance.**

(This artifact-discovery-by-existence pattern is what makes `/compact` a no-op for state.)

**Legacy slugs**: a resumed `pending_command` may name a retired `plan-*` skill slug — translate it at read time via the dispatch's old-slug translation table (`../SKILL.md`). Never execute a retired slug; never guess an unmapped one.

---

## State contract — `.the-flow-state.json`

Lives at `docs/plans/<ord>-<slug>/.the-flow-state.json`. Self-cleans with the plan folder; one per flow.

```json
{
  "schema_version": 1,
  "slug": "the-flow",
  "plan_dir": "docs/plans/026-the-flow",
  "mode": "unknown",
  "current_stage": "awaiting-1b",
  "pending_command": "<the next runnable command — rendered via the dispatch's Command grammar + Registry at write time>",
  "intent": "<the user's one-line answer to 'what do you want to build?'>",
  "milestones_total": 7,
  "milestones_done": 2,
  "last_checkpoint_at": "2026-05-29T00:00:00Z",
  "compacted_seams": [],
  "status": "active"
}
```

- `mode`: `"Simple" | "Full" | "unknown"` — read from the spec header after stage 20.
- `current_stage`: keyed on the step just issued (`awaiting-<id>`) — the Graph keys on it.
- `pending_command`: the next runnable command in **public grammar**, rendered via the dispatch's Command grammar + Registry **at write time** (slots are never stored in state); legacy values naming retired `plan-*` slugs are translated at read time (dispatch table) and rewritten in current grammar on the next state write.
- `milestones_total`: macro-milestones for this run's mode (Full=7, Simple≈4); set after stage 20, recomputed at stage 30, then stable.
- `milestones_done`: completed macro-milestones → drives the rail fill.
- `last_checkpoint_at`: captured via `date -u +%FT%TZ`; used for artifact-discovery-by-mtime.

**Write method**: temp file + atomic rename (`.the-flow-state.json.tmp` → `.the-flow-state.json`). **Minimal by design** (KISS / no derived rollup state) — just enough to resume.

**Single terminal**: one conversation alternates stage runs and `/the-flow` check-ins; `/compact` is the hygiene valve.

<!-- The section below is a frozen contract (PL-15) quoted byte-identical across plans — its command example is exempt from lint L3 via the marker. -->
<!-- lint:allow-flow-commands -->
## State-write ownership

- **Guided mode (the dispatch + this engine) is the ONLY writer** of `.the-flow-state.json`, `the-flow.json`, and `the-flow.md`.
- **Direct-jump stage modules NEVER write the-flow state.** A direct `/the-flow 6 implement …` behaves exactly like a direct `/plan-6` run did: it produces its stage artifacts and nothing else. The next guided invocation discovers those artifacts by existence (idempotency rule) and catches the state up — resume stays correct without dual writers.
- Stage modules own **their** artifacts (spec, plan, tasks, execution log, reviews); the engine never edits those.

---

## Graph

The deterministic core — **the single owner of "what's next"** (flow-architecture R1). Edges name **verbs** in bold, never commands: the printed command is rendered at narration time from the dispatch's **Command grammar + Registry** (an accepted edge loads the verb's module from its Registry row). Decorations carry everything that rides an edge: compact hints, wrapping harness seams, gates, mode notes. The **insight** column feeds the coach's Insight beat. Target states are implied by the offered verb's id (`awaiting-<id>`); exceptions are written inline.

| state | evidence (artifact) | edges (on evidence → offer) | decorations | insight (pick 1) |
|---|---|---|---|---|
| `start` | — (ask intent) | research-worthy → **explore** · clear → **specify** | seam: session-start — probe for the router (§ Harness seams); if installed, `--event session-start` | — |
| `awaiting-1a` | `research-dossier.md` | → **specify** | compact ✓ (dossier is large) | one Critical/High finding |
| `awaiting-1b` | `<slug>-spec.md` | → **architect** · opt: **workshop** | compact ✓ (before architect) · seam: post-spec is the **recommended next step** — `/eng-harness-flow --event post-spec --spec <path>` *(router-installed only)* → `awaiting-backpressure` | CS score + Simple/Full + #Workshop Opportunities |
| `awaiting-2c` | newest `workshops/*.md` | another → **workshop** · → **architect** | seam: post-spec still offered — `/eng-harness-flow --event post-spec --spec <path>` *(router-installed only)* → `awaiting-backpressure` | the headline decision (Selected option) |
| `awaiting-backpressure` | `backpressure-coverage.md` | → **architect** | backpressure payoff (artifact produced via the router) | Certainty (Strong/Partial/Weak) + Phase 0? |
| `awaiting-3` | `<slug>-plan.md` | DRAFT → fix + re-run **architect** (stay) · Simple+READY → **implement** · Full+READY → **tasks** | compact ✓ (before implement) · validate-v2 already auto-ran | `**Status**` (READY/DRAFT) + Gate Matrix |
| `awaiting-5` | `tasks/<phase>/tasks.md` | → **implement** (± its `--companion` mode — offer it here) | the implement verb fires the pre-implement seam itself before task 1 (in-procedure side effect) | first task's Done-When |
| `awaiting-6` | `execution.log.md` / phase status | clean → **review** · more phases (Full) → **tasks** | compact ✓ (between phases) · seams fired in-verb: `--event pre-implement` (set expectation *before*), `--event phase-end` (explain *after*) · review **skippable if a companion reviewed every commit** | what landed + AC met |
| `awaiting-7` | newest `reviews/*.md` | findings → fix + re-run **review** (stay) · clean → **merge** | tier contrast: computational (post-spec backpressure) vs inferential (review) | verdict + one finding |
| `awaiting-8` | merge plan | typed `PROCEED` → `complete` | gate: typed PROCEED/ABORT — never a generic "yes" · seam: plan-complete fires inside the merge verb after execution | merge readiness |
| `complete` | — | recap + stop; set `status:"complete"` | (plan-complete already fired in-verb) | — |

## Must-see fields to scan (the Flag beat, per stage)

Where each artifact hides its **structured alarms** — lift any present, verbatim, into the Flag line (coach.md owns the phrasing). If a stage isn't listed, it rarely carries alarms (skip silently when clean).

| Stage | Scan for (quote any hits) |
|---|---|
| `awaiting-1a` | Critical/High findings the dossier marks unresolved or contradicting the ask |
| `awaiting-1b` | remaining `[NEEDS CLARIFICATION]` markers; low CS **Confidence**; unanswered Open Questions |
| `awaiting-backpressure` | **ABSENT** / **BUILDABLE** sensors (the eyeball-gaps); a recommended **Phase 0: Establish Backpressure** |
| `awaiting-3` | `**Status**: DRAFT`; Gate Matrix **FAIL** rows; inline `⚠️ GAP:` markers; `## Unresolved Gaps` table; Deviation Ledger entries |
| `awaiting-5` | tasks with no/weak Done-When; a phase carrying a flagged Key Finding |
| `awaiting-6` | acceptance criteria **not met**; blocked tasks; debt/gotchas in the Discoveries table |
| `awaiting-7` | **CRITICAL/HIGH** findings; any verdict short of clean |
| `awaiting-8` | unmerged-blocker notes; merge-readiness warnings |

---

## Harness seams — routed via `/eng-harness-flow` (detection + envelope)

The engineering harness is a **separate loop that runs side by side with the SDD pipeline in the same context — that is all**. It is owned by the external eng-harness family and reached through exactly one door: the **`/eng-harness-flow`** router, with an `--event` hint (`session-start | post-spec | pre-implement | phase-end | plan-complete`) plus context flags (`--spec`, `--plan-dir`, `--phase`, `--prompt-optional`, `--json`). **Never name or invoke the router's child skills** — they are private and may move or rename. Seam touchpoints are visible nodes in `the-flow.json`/`the-flow.md` (types `backpressure`, `harness-boot`, `harness-retro`).

**Two-layer detection (load-bearing):**

**Layer 1 — is the router installed?** Probe once per flow: `test -f ~/.agents/skills/eng-harness-flow/SKILL.md` (fallback `~/.claude/skills/eng-harness-flow/SKILL.md`). On a miss, print exactly once, verbatim:

> ⚠️ No engineering harness detected — the eng-harness skills aren't installed. Continuing without one: standard testing applies, nothing else changes. (To add the harness loop: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`.)

…then **silently omit every harness node and mention for the rest of the flow** (record the outcome once in state; never re-warn). A repo without a harness is fully supported; never nag about a missing one.

**Layer 2 — route the seam.** Router installed → call the seam with `--json` and act on the envelope (`decision: route|redirect|noop|ambiguous`): `route` → print-then-offer the returned command; setup-routing/`noop` → one calm line the first time (*"No engineering harness in this repo — proceeding without one; say 'set up a harness' anytime."*), then pass `--prompt-optional=false` on later seam calls. Verdicts and flags are narrated **verbatim from the envelope** (boot vocabulary: `healthy / SLOW / UNHEALTHY / UNAVAILABLE`) — never reimplement the router's checks.

**The five seams** (each a node *and* a narration beat when the router is installed):

- **Post-spec** (`--event post-spec --spec <path>`) — a `backpressure` node **on the spine between spec and plan**; the recommended pre-architect step; produces `backpressure-coverage.md`. Advisory; never blocks.
- **Pre-implement** (`--event pre-implement --phase <id> --plan-dir <p>`) — a `harness-boot` node before each phase; fired inside the implement verb. `UNAVAILABLE` is not an error — falls back to standard testing.
- **Phase end** (`--event phase-end --plan-dir <p>`) — a `harness-retro` node at each phase seam (fired inside the implement verb); the router owns drain-vs-harvest.
- **Plan complete** (`--event plan-complete`) — a `harness-retro` node at stage 80 / `complete`; fired inside stage 80 after the merge.
- **Session start** (`--event session-start`) — fired at flow entry; usually no node, just detection + one calm line.

Every harness node is **advisory** — surfaced for legibility, never a gate, never blocks, no scores.

---

## Flight plan — `the-flow.json` (source of truth) + `the-flow.md` (rendered)

Every run maintains a **flight plan**: `docs/plans/<ord>-<slug>/the-flow.json` (canonical DAG) and `the-flow.md` (the vertical mermaid, **generated from** the JSON). The one-line rail (coach.md) is the JSON's glanceable twin.

- **Schema**: [`flight-plan.schema.json`](./flight-plan.schema.json) (the full node + `agents[]` contract).
- **Worked example to copy**: [`flight-plan.template.json`](./flight-plan.template.json) + [`flight-plan.template.md`](./flight-plan.template.md).

**Hand-crank cadence (you are the generator). Every guided turn, after deciding the narration:**

1. **Mutate the JSON** for what just happened: completed node → `status: done`, stamp `ran_at`, capture the user's **verbatim** `user_input`, write the `note`, append produced `artifacts[]`; advance `cursor`/`recommended_next`.
2. **Reveal/refine the future**: at stage 30, replace the `assumed` phase placeholder with real `known` phase nodes (one per phase) + recompute `milestones_total`. Add conditional `assumed` nodes (fix-loops) as `branch_of` the relevant phase.
3. **Regenerate** `the-flow.md` from the JSON, then the rail.
4. **Self-check** (no validator): required fields present, every `next` id exists, exactly one `cursor`, no backwards status moves.

**Status taxonomy → colour**: `done` 🟩 · `in_progress` 🟧 · `blocked` 🟥 · `known` 🟦 (*designed* future, e.g. phases locked at stage 30) · `assumed` ⬜ dashed (*speculative* future, e.g. a conditional fix loop). Transitions: `assumed → known` (at stage 30) → `in_progress` → `done`; any active node → `blocked` → back to `in_progress`.

**Render rules for `the-flow.md`** (see schema + template for the worked form):

1. `flowchart TD` (vertical); emit the `classDef`s (done/wip/blocked/known/assumed + said/companion/worker + **harness**). The `harness` class is violet (`fill:#EDE7F6,stroke:#673AB7`) so the loop reads distinctly from the spine.
2. **Spine** = `type ∈ {research, spec, backpressure, plan, phase, merge}` linked solid `-->` in `next` order. **`backpressure` sits on the spine between `spec` and `plan`** — styled `:::harness` but on the main line (not a dotted excursion).
3. **Excursions** (`branch_of` set: deep-research, **each** workshop, fix-loop) = dotted `-.->` from their `branch_of`, rejoining at the spine. **Every workshop is its own node** — never collapse a loop into one blob.
4. **Harness seam nodes** (`type ∈ {harness-boot, harness-retro}`) = dotted `-.->` from their `branch_of`, all `:::harness`; their `command` fields are router invocations (`/eng-harness-flow --event …`), never child-skill names. Emit them ONLY when the Layer-1 probe passes — otherwise omit every harness node (including the `backpressure` spine node — falls back to a plain `spec --> plan` edge).
5. Each node `:::<class>` from its `status` (harness nodes keep `:::harness` regardless of status; convey status via the note).
6. **User bubbles**: for every node with `user_input`, emit a `said`-class flag node (`>"🗣 …"]`) dotted (`-.-`) to it — verbatim, nothing hidden.
7. **Agents**: `kind:companion` (`render:wrap`) → a **subgraph wrapping** its `covers[]` phases, companion colour; `kind:worker` (`render:side`) → a `worker`-class side-node linked `-. builds .->` to its `covers[]`.
8. Legend line beneath (done/wip/blocked/known/assumed + 🗣 user input + companion + worker + 🟪 harness loop).

> **Invariant**: never hand-edit `the-flow.md` as the primary — it is always a function of `the-flow.json`.

---

## Shared conventions (cited by stage modules — single home for deduped blocks)

### 🚫 No time estimates — Complexity Score only

Plans, specs, and task tables never carry time estimates. Use **Complexity Score (CS 1–5)**:

- CS-1 (trivial): 0–2 points | CS-2 (small): 3–4 | CS-3 (medium): 5–7 | CS-4 (large): 8–9 | CS-5 (epic): 10–12
- Factors (each 0–2): **S**urface Area, **I**ntegration, **D**ata/State, **N**ovelty, Non-**F**unctional, **T**esting/Rollout. Sum the six factors → band above.

### Domain context loading

When a stage needs domain context: read `## Target Domains` from the spec → `## Domain Manifest` from the plan → if `docs/domains/registry.md` exists, read it plus `docs/domains/<slug>/domain.md` for each touched domain (note concepts, contracts, composition, dependencies) and `docs/domains/domain-map.md` if present. Repos without a domain registry: the spec/plan tables are the whole context — proceed.

### Deep-think

Every stage module is a deep-think task — reason as thoroughly as the stage warrants; the dispatch declares this once so modules don't repeat it.

### Harness router posture

All harness touchpoints go through `/eng-harness-flow` only (children private, never named); best-effort, advisory, never gates or blocks, no scores; one-time warning when not installed (§ Harness seams above); envelope verdicts narrated verbatim. Stage modules keep their **concrete seam invocations inline and byte-identical** — only this posture paragraph is deduped.
