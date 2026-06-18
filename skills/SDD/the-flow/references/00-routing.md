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
6. Initialise the flight plan **via the CLI** (never hand-write it): `harness flow create flight-plan --slug <slug> --path docs/plans/<ord>-<slug>/the-flow.json --schema "<skill base>/references/flight-plan.schema.json" --bare --agent the-flow` (the `--agent the-flow` is what titles the rail `[the-flow]`; without it the rail shows the slug), then seed the spine with `harness flow add-node` — a `research` node (status `in_progress`) plus `assumed` `plan`/`merge` nodes for the initial shape — set the initial position with `harness flow nav set --path docs/plans/<ord>-<slug>/the-flow.json --now research`, and render with `harness flow render --path docs/plans/<ord>-<slug>/the-flow.json --output docs/plans/<ord>-<slug>/the-flow.md`. (`<skill base>` = this skill's base dir, e.g. `~/.claude/skills/the-flow`; the flight-plan schema ships in `references/` and is supplied via `--schema`, per § Flight plan.)
7. Print-and-offer the **explore** edge (research-worthy intent) or the **plan** edge (clear ask) — the command is rendered from the dispatch's Command grammar + Registry, with the intent as the verb's argument.

Stages 10/20 both **reuse** an existing `docs/plans/*-<slug>/` folder by slug — creating it first is safe.

**`original-ask.md` shape**:

```markdown
# Original ask — <slug>
**Captured**: <ISO>  ·  **By**: /the-flow

> <the user's verbatim words, unedited>
```

### Resume (exactly one active state)

Read the state. Discover the artifact for `current_stage` (Graph below). Apply the **idempotency rule**, narrate (coach.md), then drive `the-flow.json`/`.md` via `harness flow` calls (§ Flight plan — the CLI is the generator; never hand-edit).

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

Every run maintains a **flight plan**: `docs/plans/<ord>-<slug>/the-flow.json` (canonical DAG) and `the-flow.md` (the vertical mermaid, **generated from** the JSON by `harness flow render`). The one-line rail (coach.md) is the JSON's glanceable twin.

> **Prerequisite**: guided mode drives this flight plan **only** through `harness flow` (plan 024). Probe a capable CLI before the first mutation; absent/too-old → stop with "run `harness update`" (SKILL.md § Prerequisite). No harness *adoption* is needed — the flight-plan schema ships with this skill and is supplied via `--schema`. **Load [`flight-plan-ops.md`](./flight-plan-ops.md) before the first flight-plan mutation of a session** — it carries the nav model, the spine-vs-excursion rule, the verb flags, and the gotchas. The cadence below is the routing-level *when*; that file is the *how*.

- **Schema**: [`flight-plan.schema.json`](./flight-plan.schema.json) — the CLI **descriptor** (`kind` + `statuses[]` + `nodeTypes[]`) the-flow ships and supplies to `harness flow` via `--schema`; the shared-core node/comment/root field shape is bundled in the CLI (no second copy here).
- **Worked example to copy**: [`flight-plan.template.json`](./flight-plan.template.json) + [`flight-plan.template.md`](./flight-plan.template.md).

**CLI-driven cadence (the `harness flow` CLI is the generator — you NEVER hand-edit `the-flow.json`/`.md`).** The CLI built in plan 024 owns mutation, the edge-algebra, the embedded event log, and deterministic render; guided mode is a **consumer** of it. Let `FLOW = docs/plans/<ord>-<slug>/the-flow.json`. Every guided turn, after deciding the narration, drive the flow with `harness flow` calls, threading each ok Envelope's `data.path` back into the next `--path`:

1. **Mutate for what just happened** (one call per change, `--path FLOW`) — exact flags: [`flight-plan-ops.md`](./flight-plan-ops.md) § 3:
   - a step finished → `status --to done` (fires `status-changed`, stamps `ran_at`); `→ blocked` / `→ in_progress` likewise;
   - the user's **verbatim** words → `set-node --user-input "<verbatim>"`;
   - what was done / produced → `set-node --note "<1–2 lines>"` (+ `--label` if it changed);
   - a narrative / decision note → `comment --kind <note|decision|warning|validation>`;
   - advance → `nav set --now <id>` (move; fires cursor-moved) / `--next <id>` (advisory) / `--clear-next`. (§ 2)
2. **Reveal/refine the future** — `insert-node` owns every edge splice, no hand edge-recomputation ([`flight-plan-ops.md`](./flight-plan-ops.md) § 4 spine-vs-excursion, § 6 build-order):
   - at the `plan` pass, reveal each phase → `insert-node --type phase --after <prev>` (inherits the predecessor's out-edges), then recompute `milestones_total`;
   - a conditional fix-loop / workshop / backpressure excursion → `insert-node --branch-of <node> [--rejoin <node>]` (the branch point's `next` is unchanged) — **workshops ALWAYS `--branch-of`, never on the spine**;
   - a plain new node needing no splice → `add-node`.
3. **Render** → `harness flow render --path FLOW --output docs/plans/<ord>-<slug>/the-flow.md`, then print the rail (coach.md owns the rail; the CLI owns the `.md`).
4. **Integrity is the CLI's, not yours** — `insert-node` DAG-re-checks before writing (`E309`, nothing written on a cycle/orphan); `create` validated the flight-plan overlay (statuses + nodeTypes) against the shipped `--schema`. The mutation verbs enforce only node existence (`E305`) + edge integrity — they do **not** re-check the overlay vocabulary (the flight-plan schema is supplied via `--schema`, not bundled), so the engine is responsible for using the correct node types/statuses (it owns the Graph); the renderer's unknown-type fallback never crashes. No hand self-check; no hand JSON edits.

**Status vocabulary** (the values you pass to `harness flow status --to` / `--status`): `assumed` (*speculative* future, e.g. a conditional fix loop) · `known` (*designed* future, e.g. phases locked at the `plan` pass) · `in_progress` · `done` · `blocked`. Transitions: `assumed → known` (at the `plan` pass) → `in_progress` → `done`; any active node → `blocked` → back to `in_progress`. The status→colour mapping is the **renderer's** (CLI), not the-flow's.

**Render is the CLI's — not the-flow's.** `the-flow.md` is generated from `the-flow.json` by `harness flow render --path docs/plans/<ord>-<slug>/the-flow.json --output docs/plans/<ord>-<slug>/the-flow.md`. The renderer (plan 024 Phase 2) owns **every** visual rule — `flowchart TD` + classDefs/colours, the solid spine vs dotted `branch_of` excursions, violet `:::harness` seam nodes (emitted only when the router is installed + provisioned), status→colour, the one genesis `🗣 user_input` bubble per node, the `💬N` comment badge + per-node body-log, the `decision` rhombus, the companion subgraph / worker side-node, the legend, the rail pips, and the unknown-type fallback (never crashes). Do not re-document or hand-apply any of them here — the full verb + render reference is [`docs/how/harness-flow.md`](https://github.com/AI-Substrate/harness-engineering/blob/main/docs/how/harness-flow.md).

> **Invariant**: never hand-edit `the-flow.md` — it is **always** regenerated from `the-flow.json` by `harness flow render`. And never hand-edit `the-flow.json` either — mutate it only through `harness flow` calls (§ CLI-driven cadence above).

**Legacy note (clean break).** Pre-migration flows — hand-cranked `the-flow.json` with no `provenance` block — are **not** migrated: the CLI returns `E308` (legacy-format) on read. That is an honest stop, not a bug; re-create with `harness flow create … --agent the-flow` (see SKILL.md § capability precheck).

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

### Artifact Elegance

Everything a stage emits — plans, task tables, execution logs, reviews, narration — is **output**, the expensive token. Emit the fewest that carry the meaning. This block is the single home for the rule; stage modules **cite** it (one line each) rather than restating it.

**The seven-function line test.** A line earns its place only if it does at least one of these — otherwise cut it: ① changes a decision · ② constrains an implementation · ③ proves a behaviour · ④ exposes a risk · ⑤ records evidence · ⑥ preserves intent · ⑦ enables the next action.

**Build contract, not thesis.** Prefer tables, schemas, and diffs over prose; *state* the contract, don't argue for it. One worked example beats a paragraph describing one. "Fewest phases that hold" (the `plan` verb's § Phase Design Principles) is the same principle applied to structure — folding work together beats minting ceremony.

**Link, don't copy.** When an upstream artifact already holds the detail, reference it (path / finding-id / AC-id) rather than restating it — a downstream artifact carries decisions and the links that prove them, not a re-summary of its sources.

**Safety floor — never compress these.** Default-omit applies to **decorative prose only**. Must-see fields are always shown, verbatim and in full: gate verdicts, `**Status**`, the `PROCEED`/`ABORT` line, file paths, `⚠️ GAP` / failed-gate callouts, and any structured alarm a stage is told to lift. When unsure whether a line is decorative or must-see, keep it.

### Harness router posture

Harness seams are **flow-owned** — the where/when lives in [`harness-seams.md`](./harness-seams.md), the edges in the Graph above, the *what* in the external `/eng-harness-flow` router. **Sub-skills carry no harness invocations or concepts** (they are harness-blind verbs); the engine owns every seam as a print-then-offer beat at the edge. Best-effort, advisory, never gates/blocks/scores; one calm warning when not installed; envelope verdicts narrated verbatim (`healthy / SLOW / UNHEALTHY / UNAVAILABLE`); children private and never named. Full detail: `harness-seams.md`.
