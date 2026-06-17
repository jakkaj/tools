# the-flow · routing & state — the guided-mode engine

Loaded by the dispatch ([`../SKILL.md`](../SKILL.md)) in **guided mode**, together with [`coach.md`](./coach.md) and the **current stage module only**. Direct jumps (`/the-flow <id|name> [flags]`) do not load this file up front — a stage module may cite a `§ Shared conventions` block below and pull it lazily when needed; that is still progressive disclosure.

This file owns: entry paths, the state contract, **state-write ownership**, the **Graph** (the single owner of "what's next" — flow-architecture pattern, `docs/skills-pipeline/flow-architecture.md`), the must-see flag fields, flight-plan bookkeeping, and the shared conventions the sub-skills cite. **Harness-seam orchestration is owned by [`harness-seams.md`](./harness-seams.md)** — the Graph rows below carry only terse `seam:` decorations that the engine surfaces at the edge; detection, the seam map, node emission, and the upstream contract all live there.

---

## Entry paths — fresh / resume / adopt

On guided invocation (`/the-flow` with no args, or `/the-flow <slug>` / `/the-flow <ord>-<slug>`):

1. **Glob** `docs/plans/*/.the-flow-state.json` where `status == "active"`.
   - An explicit `<slug>` / `<ord>-<slug>` arg → resume that one (skip the scan).
2. **Branch on the result**:
   - **Exactly 1 active** → **RESUME** (below).
   - **>1 active** → list them (slug + `current_stage`) and ask which to resume; offer "start a new one".
   - **0 active**:
     - Target plan folder **already holds artifacts** (`*-plan.md`, legacy `*-spec.md`, `tasks/phase-*/`, `reviews/`) → **ADOPT** (see [`coach.md`](./coach.md) § Adoption contract).
     - Else → **FRESH START**.

### Fresh start (no state, no artifacts)

Ask the intent (coach.md `start` narration). After the user answers:

1. Allocate the ordinal via `plan-ordinal` (alias `jk-po`); fall back to a local `docs/plans/` scan if unavailable.
2. **Derive the slug** = kebab-case of the intent's first ~3–5 significant words (drop filler).
3. `mkdir -p docs/plans/<ord>-<slug>/`.
4. **Write the verbatim ask** to `original-ask.md` (shape below) and mirror it into `state.intent`.
5. Write `.the-flow-state.json` (temp file + atomic rename).
6. Initialise `the-flow.json` (a `start`/`research` node + `assumed` future) and render `the-flow.md`.
7. Print-and-offer the **explore** edge (research-worthy intent) or the **plan** edge (clear ask) — the command is rendered from the dispatch's Command grammar + Registry, with the intent as the verb's argument.

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
  "milestones_total": 6,
  "milestones_done": 2,
  "last_checkpoint_at": "2026-05-29T00:00:00Z",
  "compacted_seams": [],
  "status": "active"
}
```

- `mode`: `"Simple" | "Full" | "unknown"` — read from the plan's top-metadata block, set during the atomic `plan` pass (Round-1 Workflow Mode / `--simple`).
- `current_stage`: keyed on the step just issued (`awaiting-<id>`) — the Graph keys on it. Old `awaiting-1b`/`awaiting-3` both translate to the single `awaiting-1b` (§ Routing markers & read-time state translation).
- `pending_command`: the next runnable command in **public grammar**, rendered via the dispatch's Command grammar + Registry **at write time** (slots are never stored in state); legacy values naming retired `plan-*` slugs are translated at read time (dispatch table) and rewritten in current grammar on the next state write.
- `milestones_total`: macro-milestones for this run's mode (Full=6, Simple≈4); set during the `plan` pass — which recomputes the rail from the real phase count revealed in the implementation half — then stable.
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
| `start` | — (ask intent) | research-worthy → **explore** · clear → **plan** | seam: **pre-flight** @ entry — detect the router (§ Harness seams → `harness-seams.md`), usually no node; literal `/eng-harness-flow --hook pre-flight` (alias `--event session-start`) | — |
| `awaiting-1a` | `research-dossier.md` | → **plan** | compact ✓ (dossier is large) | one Critical/High finding |
| `awaiting-1b` | `<slug>-plan.md` with `## Implementation Plan` (the atomic `plan` verb writes **both** halves) | DRAFT → fix + re-run **plan** (stay) · Simple+READY → **implement** · Full+READY → **tasks** · opt-when-live → **workshop** | compact ✓ (before implement) · validate-v2 already auto-ran · seam-live (offer a post-plan refinement when ≥1 Workshop Opportunity is unworkshopped OR the harness is provisioned): the engine print-then-offers the **pre-coding** backpressure seam — literal `/eng-harness-flow --hook pre-coding --spec <path>` (alias `--event post-spec`) *(router-installed only)* → `awaiting-backpressure`. The survey is **advisory output** (what's provable by sensors vs eyeballed); re-run plan **informed by** it — the plan verb does not auto-read the coverage. No auto-advance — the refinement is an offer, never a forced second pass (`harness-seams.md`) | `**Status**` (READY/DRAFT) + Gate Matrix + CS/Simple-Full + #Workshop Opportunities |
| `awaiting-2c` | newest `workshops/*.md` | another → **workshop** · → **plan** (re-run, folds the decision into both halves) | post-plan refinement hanging off `awaiting-1b`; the **pre-coding** backpressure seam still offered *(router-installed only)* | the headline decision (Selected option) |
| `awaiting-backpressure` | `backpressure-coverage.md` | → **plan** (re-run, **informed by** the coverage — advisory, not auto-read) | post-plan refinement hanging off `awaiting-1b`; backpressure payoff (artifact produced via the router) | Certainty (Strong/Partial/Weak) + Phase 0? |
| `awaiting-5` | `tasks/<phase>/tasks.md` | → **implement** (± its `--companion` mode — offer it here) | the engine print-then-offers the **pre-flight** boot seam at the phase edge — a `harness-boot` node before task 1 (`harness-seams.md`); literal `/eng-harness-flow --hook pre-flight` | first task's Done-When |
| `awaiting-6` | `execution.log.md` / phase status | clean → **review** · more phases (Full) → **tasks** | compact ✓ (between phases) · engine-owned seams at the phase edges (`harness-seams.md`): **pre-flight** boot *before* (`--hook pre-flight`), **post-coding** retro *after* (`--hook post-coding`) · review **skippable if a companion reviewed every commit** | what landed + AC met |
| `awaiting-7` | newest `reviews/*.md` | findings → fix + re-run **review** (stay) · clean → **merge** | tier contrast: computational (post-spec backpressure) vs inferential (review) | verdict + one finding |
| `awaiting-8` | merge plan | typed `PROCEED` → `complete` | gate: typed PROCEED/ABORT — never a generic "yes" · seam: after the merge executes, the engine offers the **post-flight** retro (`--hook post-flight`) — a `harness-retro` node (`harness-seams.md`) | merge readiness |
| `complete` | — | recap + stop; set `status:"complete"` | (the post-flight retro was already offered at merge) | — |

## Routing markers & read-time state translation

The `plan` verb is **atomic** — it always writes both halves in one pass — so there is no "spec written, plan pending" intermediate state and no STALE status. The only conditions are "no plan yet", "plan present (READY)", and "plan present but a gate FAILed (DRAFT)". Routing keys on durable state first (`.the-flow-state.json` `current_stage` + `pending_command`); the exact-string checks below are the **disk fallback** for idempotent resume / adoption / post-`/compact` — case-sensitive `grep`, never a fuzzy prose scan.

| Predicate | Exact disk check (case-sensitive) |
|-----------|-----------------------------------|
| **Plan written** | `<slug>-plan.md` exists AND a line matches `^## Implementation Plan$` |
| **Plan is unified** (not a legacy architect-only plan) | a line matches `^## Business Specification$` |
| **Plan has unresolved gaps** | a line matches `^\*\*Status\*\*: DRAFT` |
| **Legacy split planning complete** | `<slug>-plan.md` exists with **no** `^## Business Specification$` line AND a sibling `<slug>-spec.md` exists — the old architect+spec pair (the legacy architect plan uses an h1 `# … Implementation Plan` title + `## Gate Matrix`/`## Phases`, never an `^## Implementation Plan$` wrapper, so "Plan written" above won't match it) |

**Read-time state translation (back-compat — never migrate on disk).** Old state files predate the collapse:

- `current_stage: awaiting-1b` (old meaning: spec done) **and** `current_stage: awaiting-3` (old meaning: plan done) both translate to the single **`awaiting-1b`**. The pending verb is then re-derived from artifacts (idempotency / adoption): a unified `<slug>-plan.md` with `## Implementation Plan` → `implement` (Simple) / `tasks` (Full); a legacy `<slug>-spec.md` only → `plan` (it reads the legacy spec as the business source and writes the unified document).
- **Legacy split-flow folder, already fully planned (don't re-plan it).** A folder carrying **both** a legacy `<slug>-spec.md` and a legacy architect-era `<slug>-plan.md` (h1 title + `## Gate Matrix`, **no** `## Business Specification`) is complete under the old split contract — matching the **Legacy split planning complete** predicate above. Treat it as `awaiting-1b` done and route by the legacy spec's `**Mode**`: Simple → **implement**, Full → **tasks**. Only a `<slug>-spec.md` with *no* plan beside it routes to **plan**.
- A `pending_command` naming `specify` or the architect verb (old id `3`) is rewritten via the dispatch's alias table to the `plan` command on the next state write.

## Must-see fields to scan (the Flag beat, per stage)

Where each artifact hides its **structured alarms** — lift any present, verbatim, into the Flag line (coach.md owns the phrasing). If a stage isn't listed, it rarely carries alarms (skip silently when clean).

| Stage | Scan for (quote any hits) |
|---|---|
| `awaiting-1a` | Critical/High findings the dossier marks unresolved or contradicting the ask |
| `awaiting-1b` | `**Status**: DRAFT`; Gate Matrix **FAIL** rows; inline `⚠️ GAP:` markers; `## Unresolved Gaps` table; Deviation Ledger entries; remaining `[NEEDS CLARIFICATION]` markers; low CS **Confidence**; unanswered Open Questions |
| `awaiting-backpressure` | **ABSENT** / **BUILDABLE** sensors (the eyeball-gaps); a recommended **Phase 0: Establish Backpressure** |
| `awaiting-5` | tasks with no/weak Done-When; a phase carrying a flagged Key Finding |
| `awaiting-6` | acceptance criteria **not met**; blocked tasks; debt/gotchas in the Discoveries table |
| `awaiting-7` | **CRITICAL/HIGH** findings; any verdict short of clean |
| `awaiting-8` | unmerged-blocker notes; merge-readiness warnings |

---

## Harness seams — owned by `harness-seams.md`

Harness-seam orchestration is **flow-owned** and lives in one file: [`harness-seams.md`](./harness-seams.md). Guided mode loads it **lazily** when the flow reaches a harness edge (progressive disclosure — the same way a stage's sub-skill is loaded only when its step is accepted). It owns: the **two-layer detection**, the **seam map** (every Graph edge → `--hook` + context flags → emitted node + the literal `/eng-harness-flow --hook …` command the engine print-then-offers), **node emission** (decoupled from provisioning), the **per-phase retro lifecycle**, the **honored-not-forced** posture, the **not-installed / unprovisioned silent paths**, and the **versioned upstream seam contract** (the `--hooks --json` mirror + resync procedure).

The four fire-hooks the flow wires — and which Graph edge each rides — are the terse `seam:` decorations in the Graph above (`pre-flight` at flow entry **and** before each phase, `pre-coding` post-plan, `post-coding` each phase end, `post-flight` at merge); the silent `coding` capture is deliberately **not** wired. **Never name or invoke the router's child skills** — the only stable surface is `/eng-harness-flow` + its `--hook` vocabulary (permanent `--event` alias). Seam nodes in `the-flow.json` use types `backpressure`, `harness-boot`, `harness-retro`; every one is **advisory** — never a gate, never blocks, no scores.

---

## Flight plan — `the-flow.json` (source of truth) + `the-flow.md` (rendered)

Every run maintains a **flight plan**: `docs/plans/<ord>-<slug>/the-flow.json` (canonical DAG) and `the-flow.md` (the vertical mermaid, **generated from** the JSON). The one-line rail (coach.md) is the JSON's glanceable twin.

- **Schema**: [`flight-plan.schema.json`](./flight-plan.schema.json) (the full node + `agents[]` contract).
- **Worked example to copy**: [`flight-plan.template.json`](./flight-plan.template.json) + [`flight-plan.template.md`](./flight-plan.template.md).

**Hand-crank cadence (you are the generator). Every guided turn, after deciding the narration:**

1. **Mutate the JSON** for what just happened: completed node → `status: done`, stamp `ran_at`, capture the user's **verbatim** `user_input`, write the `note`, append produced `artifacts[]`; advance `cursor`/`recommended_next`.
2. **Reveal/refine the future**: during the `plan` pass (when the implementation half reveals the phases), replace the `assumed` phase placeholder with real `known` phase nodes (one per phase) + recompute `milestones_total`. Add conditional `assumed` nodes (fix-loops) as `branch_of` the relevant phase.
3. **Regenerate** `the-flow.md` from the JSON, then the rail.
4. **Self-check** (no validator): required fields present, every `next` id exists, exactly one `cursor`, no backwards status moves.

**Status taxonomy → colour**: `done` 🟩 · `in_progress` 🟧 · `blocked` 🟥 · `known` 🟦 (*designed* future, e.g. phases locked at the `plan` pass) · `assumed` ⬜ dashed (*speculative* future, e.g. a conditional fix loop). Transitions: `assumed → known` (at the `plan` pass) → `in_progress` → `done`; any active node → `blocked` → back to `in_progress`.

**Render rules for `the-flow.md`** (see schema + template for the worked form):

1. `flowchart TD` (vertical); emit the `classDef`s (done/wip/blocked/known/assumed + said/companion/worker + **harness**). The `harness` class is violet (`fill:#EDE7F6,stroke:#673AB7`) so the loop reads distinctly from the spine.
2. **Spine** = `type ∈ {research, spec, plan, phase, merge}` linked solid `-->` in `next` order (a unified `plan` node replaces the old separate `spec`+`plan` pair; legacy flows that still carry both render both). The unified `plan` node connects **directly** to its next spine node (the first `phase`); a post-plan `backpressure` refinement does **not** interrupt the spine — it renders as a dotted excursion off `plan` (rule 3).
3. **Excursions** (`branch_of` set: deep-research, **each** workshop, a post-plan **backpressure** refinement, fix-loop) = dotted `-.->` from their `branch_of`, rejoining at the spine. A `backpressure` node (type `backpressure`, `branch_of: "plan"`) is one such excursion — run it; the coverage is **advisory output** that informs a re-plan (the plan verb does not auto-read it); style it `:::harness` (the router produces it) and omit it with the other harness nodes when the Layer-1 probe misses (rule 4). **Every workshop is its own node** — never collapse a loop into one blob.
4. **Harness seam nodes** (`type ∈ {harness-boot, harness-retro}`) = dotted `-.->` from their `branch_of`, all `:::harness`; their `command` fields are router invocations (`/eng-harness-flow --hook … --json`), never child-skill names. **Per-phase harness nodes are emitted only when the router is *installed* AND the repo is *provisioned*** (`harness-seams.md` § Node emission); installed-but-unprovisioned ⇒ **no per-phase harness nodes**, one calm session line only. Layer-1 miss ⇒ omit every harness node (including any `backpressure` excursion); the spine stays intact (the unified `plan` node connects directly to the first `phase`). The phase-end (`post-coding`) retro is **one node per phase** (`branch_of` that phase); "drain owed" is re-derived from a phase `done` whose `harness-retro` sibling is still `assumed`/absent — no new state file.
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

Harness seams are **flow-owned** — the where/when lives in [`harness-seams.md`](./harness-seams.md), the edges in the Graph above, the *what* in the external `/eng-harness-flow` router. **Sub-skills carry no harness invocations or concepts** (they are harness-blind verbs); the engine owns every seam as a print-then-offer beat at the edge. Best-effort, advisory, never gates/blocks/scores; one calm warning when not installed; envelope verdicts narrated verbatim (`healthy / SLOW / UNHEALTHY / UNAVAILABLE`); children private and never named. Full detail: `harness-seams.md`.
