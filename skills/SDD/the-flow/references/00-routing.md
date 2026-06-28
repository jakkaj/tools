# the-flow · routing & state — the guided-mode engine

Loaded by the dispatch ([`../SKILL.md`](../SKILL.md)) in **guided mode**, together with [`coach.md`](./coach.md) and the **current stage module only**. Direct jumps (`/the-flow <id|name> [flags]`) do not load this file up front — a stage module may cite a `§ Shared conventions` block below and pull it lazily when needed; that is still progressive disclosure.

This file owns: entry paths, the state contract, **state-write ownership**, the **Graph** (the single owner of "what's next" — flow-architecture pattern, `docs/skills-pipeline/flow-architecture.md`), the must-see flag fields, flight-plan bookkeeping, and the shared conventions the sub-skills cite. **Harness-seam orchestration is owned by [`harness-seams.md`](./harness-seams.md)** — the Graph rows below carry only terse `seam:` decorations that the engine surfaces at the edge; detection, the seam map, node emission, and the upstream contract all live there.

---

## Entry paths — fresh / resume / adopt

On guided invocation (`/the-flow` with no args, or `/the-flow <slug>` / `/the-flow <ord>-<slug>`):

1. **Glob** `docs/plans/*/the-flow.json`; for each, read `nav` via `harness flow nav show` and treat the flow as **active** when `nav.bag.status == "active"` **OR** — for live flows that predate the bag — `bag.status` is absent **AND** `nav.now` is a real non-seed node **AND** its terminal node isn't done. (This is the **same active signal §6 uses**; keying on `bag.status` alone would miss every pre-bag flow — e.g. a post-027 flow whose position is canonical in `nav` but never carried a `bag`.) A flow with only a legacy `.the-flow-state.json` and no `the-flow.json` → treat as active and **backfill on resume** (§ Resume).
   - An explicit `<slug>` / `<ord>-<slug>` arg → resume that one (skip the scan).
2. **Branch on the result**:
   - **Exactly 1 active** → **RESUME** (below).
   - **>1 active** → list them (slug + `nav.now`) and ask which to resume; offer "start a new one".
   - **0 active**:
     - Target plan folder **already holds artifacts** (`*-plan.md`, legacy `*-spec.md`, `tasks/phase-*/`, `reviews/`) → **ADOPT** (see [`coach.md`](./coach.md) § Adoption contract).
     - Else → **FRESH START**.

### Fresh start (no state, no artifacts)

Ask the intent (coach.md `start` narration). After the user answers:

1. Allocate the ordinal via `plan-ordinal` (alias `jk-po`); fall back to a local `docs/plans/` scan if unavailable.
2. **Derive the slug** = kebab-case of the intent's first ~3–5 significant words (drop filler).
3. `mkdir -p docs/plans/<ord>-<slug>/`.
4. **Write the verbatim ask** to `original-ask.md` (shape below) and mirror it into `nav.intent` (set in step 6).
5. **Create + seed the flight plan via the CLI** (never hand-write it) — run the **ordered block below**.
6. Print-and-offer the **explore** edge (research-worthy intent) or the **plan** edge (clear ask) — the command is rendered from the dispatch's Command grammar + Registry, with the intent as the verb's argument.

**Create + seed block** — define the path **once** (real runs use `docs/plans/<ord>-<slug>/`; a scratch/eval run redirects only `PLAN_DIR`/`FLOW_PATH`). **Route A (plan 039): the spine is instantiated from the pre-authored bare-spine template in ONE `create --template` call** — the seed is complete-at-create (`research → plan → phase-1 → ship`), so there is **no per-node `add-node` and no last-to-first build-order wart** (`create` stamps the whole spine atomically; later structural edits use the transactional `apply`, which resolves forward `--next` refs in one batch — `flight-plan-ops.md` §6):

```bash
PLAN_DIR="docs/plans/<ord>-<slug>"; FLOW_PATH="$PLAN_DIR/the-flow.json"
SCHEMA="<skill base>/references/flight-plan.schema.json"     # <skill base> = this skill's dir, e.g. ~/.claude/skills/the-flow
TEMPLATE="<skill base>/references/flight-plan.template.json" # the bare-spine, HARNESS-AGNOSTIC seed (research → plan → phase-1 → ship)

# root + complete bare spine in ONE call — the template seed carries `cursor` (→ nav.now) + the 4 spine nodes;
# create stamps root identity. ALWAYS --agent the-flow (→ rail title [the-flow]; without it the rail shows the slug).
harness flow create flight-plan --slug <slug> --path "$FLOW_PATH" --schema "$SCHEMA" --template "$TEMPLATE" --agent the-flow

# position + session bag (the template `cursor` already set nav.now=research; add the verbatim intent + mode)
harness flow nav set      --path "$FLOW_PATH" --intent "<the verbatim ask>"
harness flow nav meta set --path "$FLOW_PATH" mode <Simple|Full|unknown>
harness flow nav meta set --path "$FLOW_PATH" status active

# CONDITIONAL harness chore apply (harness-seams.md § Flight-plan harness seams; § Node emission).
# ONLY when the router is INSTALLED *and* the repo is PROVISIONED (Layer-1 + Layer-2 both hold): the seam routine
# lays phase-1's per-phase trio (boot + observe + drain) + the two globals (backpressure off `plan`, ship harvest
# off `ship`) via ONE additive `harness flow apply --ops -` batch. Gate OFF → skip entirely; the spine stays the
# 4-node harness-agnostic seed above. (Multiphase: the plan-complete additive expander splices phase-2..N — § Flight plan step 2.)

harness flow render --path "$FLOW_PATH" --output "$PLAN_DIR/the-flow.md"
```

Stages 10/20 both **reuse** an existing `docs/plans/*-<slug>/` folder by slug — creating it first is safe.

**`original-ask.md` shape**:

```markdown
# Original ask — <slug>
**Captured**: <ISO>  ·  **By**: /the-flow

> <the user's verbatim words, unedited>
```

### Resume (exactly one active state)

Read position via `harness flow nav show` (+ node statuses) — **not** a state file. Discover the artifact for the current node (Graph below). Apply the **idempotency rule**, **reconcile the spine** (§ Reconcile the spine — runs on every resume *and* adopt, idempotent: a complete spine writes nothing), narrate (coach.md), then drive `the-flow.json`/`.md` via `harness flow` calls (§ Flight plan — the CLI is the generator; never hand-edit). On the **first** resume of a flow that still carries a legacy `.the-flow-state.json`, run the one-shot backfill below first.

**Idempotency rule (every resume)**: discover the artifact for the current node (`nav.now`) by existence at its expected path (newest if several, by mtime — the CLI stamps `ran_at`/`modified_at` on nodes).
- **Found** → narrate the stage's insight, advance `nav` (`harness flow nav set --now`/`--next`), print-and-offer the next command (derived from `nav.next` + Registry).
- **Not found** → re-print the pending command (derived from `nav.next` + Registry) **verbatim** and stop. **Do not advance.**

(This artifact-discovery-by-existence pattern is what makes `/compact` a no-op for state.)

**Legacy slugs**: a resumed `pending_command` may name a retired `plan-*` skill slug — translate it at read time via the dispatch's old-slug translation table (`../SKILL.md`). Never execute a retired slug; never guess an unmapped one.

### One-shot resume backfill — legacy `.the-flow-state.json` → `nav`/`bag`

**`nav` is authoritative; never clobber it.** Plan 027 already migrated in-flight flows' **position** into `nav`, so a live flow today carries a populated, canonical `nav` *and* (if old) a stale, disagreeing `.the-flow-state.json`. `nav` always wins; the legacy file is only ever *read* to recover session qualifiers `nav` doesn't yet have, then deleted. On the **first** resume of a flow:

```
read nav via `harness flow nav show` (+ node statuses) and the-flow.json
# nav is the source of truth for POSITION — never overwritten below.
if nav.now is a real (non-seed) node:          # post-027 flows — the normal case
      # position already canonical → backfill ONLY absent session bag:
      if nav.bag.status absent → nav meta set status active   # ("complete" if the terminal node is done)
      if nav.bag.mode   absent → nav meta set mode <from plan **Mode**>
      if nav.intent     absent → nav set --intent "<from original-ask.md>"
      delete the legacy .the-flow-state.json    # it is now superseded
elif nav.now is empty / at the seed node:      # genuinely pre-nav flow
      # do NOT lift current_stage→node from the file:
      #   awaiting-<id> are Graph position markers, not node ids — there is no resolver.
      derive position from ARTIFACTS via § Adoption (coach.md), then set nav.now from THAT.
else:                                          # nothing yet → fresh / adopt per the entry paths above
```

- **Idempotency signal = `nav.now` being a real non-seed node** (true for every live flow today), **not** `nav.bag.status` (some live flows lack a bag). A second resume is a no-op.
- **The `current_stage`→node lift is dropped** — no sound resolver, and unnecessary because position already lives in `nav`.
- **Deletion is the default, not optional**: a left-behind `.the-flow-state.json` with `status:active` is a resurrection hazard for any reader not yet repointed to `nav`.

---

## State contract — the flight plan (`nav` + `bag`), no separate file

All durable the-flow state lives in `docs/plans/<ord>-<slug>/the-flow.json`, written **only** by `harness flow`. There is **no `.the-flow-state.json`**. Position and session qualifiers live in `nav` (read via `harness flow nav show`):

- `nav.now` — the current node id (the position truth). Replaces the old `current_stage`; `awaiting-<id>` is just a render of where `now` sits, never a stored field.
- `nav.next` — advisory next node id. The **pending command is *derived*** from it (`nav.next` → Graph → Registry + Command grammar) at read time — never stored. The `--plan`/`--phase` flags derive from `plan_dir`/`slug` + the next-incomplete phase node.
- `nav.intent` — the user's one-line answer to "what do you want to build?" (mirrors `original-ask.md`); set with `nav set --intent`.
- `nav.bag` — the free-form, schema-free, shallow-merge qualifier bag (`harness flow nav meta set <k> <v>`):
  - `bag.mode` — `"Simple" | "Full" | "unknown"`, read from the plan's top-metadata block at the `plan` pass.
  - `bag.status` — `"active" | "complete"`; flips to `complete` at ship/merge. It is the active flag **and** the resume idempotency signal; when absent, the terminal node's status is a read-time fallback.
  - `bag.compacted_seams` (and any other session qualifier) — as needed; the bag has no schema.
- **Rail fill is *derived*, never stored** — `harness flow rail` computes the pips from live node status + zones (no `milestones_total`/`milestones_done` counters). Node `ran_at`/`modified_at` stamps replace `last_checkpoint_at` for artifact-discovery-by-mtime.

**Write method**: `harness flow nav set` / `nav meta set` (the CLI owns the atomic write). **Minimal by design** (KISS / no derived rollup state) — position + a free-form bag, just enough to resume; everything else is derived at read time.

**Single terminal**: one conversation alternates stage runs and `/the-flow` check-ins; `/compact` is the hygiene valve.

<!-- The section below is a frozen contract (PL-15) quoted byte-identical across plans — its command example is exempt from lint L3 via the marker. -->
<!-- lint:allow-flow-commands -->
## State-write ownership

- **The `harness flow` CLI is the ONLY state writer.** Guided mode (the dispatch + this engine) drives **one** substrate — `the-flow.json` (`nav` + `bag` + node statuses, rendered to `the-flow.md`) — exclusively through `harness flow` calls. There is **no hand-authored `.the-flow-state.json`**.
- **Direct-jump stage modules NEVER write the-flow state.** A direct `/the-flow 6 implement …` behaves exactly like a direct `/plan-6` run did: it produces its stage artifacts and nothing else. The next guided invocation discovers those artifacts by existence (idempotency rule) and catches the state up — resume stays correct without dual writers.
- Stage modules own **their** artifacts (spec, plan, tasks, execution log, reviews); the engine never edits those.

---

## Graph

The deterministic core — **the single owner of "what's next"** (flow-architecture R1). Edges name **verbs** in bold, never commands: the printed command is rendered at narration time from the dispatch's **Command grammar + Registry** (an accepted edge loads the verb's module from its Registry row). Decorations carry everything that rides an edge: compact hints, wrapping harness seams, gates, mode notes. The **insight** column feeds the coach's Insight beat. Target states are implied by the offered verb's id (`awaiting-<id>`); exceptions are written inline.

| state | evidence (artifact) | edges (on evidence → offer) | decorations | insight (pick 1) |
|---|---|---|---|---|
| `start` | — (ask intent) | research-worthy → **explore** · clear → **plan** | seam: **pre-flight** @ entry — detect the router (§ Harness seams → `harness-seams.md`), usually no node; literal `/eng-harness-flow --hook pre-flight` (alias `--event session-start`) | — |
| `awaiting-1a` | `research-dossier.md` | → **plan** | compact ✓ (clears research chatter before planning) | the top supported finding, a material historical warning, or — if the dossier surfaced none — an explicit clean result |
| `awaiting-1b` | `<slug>-plan.md` with `## Implementation Plan` (the atomic `plan` verb writes **both** halves) | DRAFT → fix + re-run **plan** (stay) · Simple+READY → **implement** · Full+READY → **tasks** · opt-when-live → **workshop** | compact ✓ (before implement) · validate-v2 already auto-ran · seam-live (offer a post-plan refinement when ≥1 Workshop Opportunity is unworkshopped OR the harness is provisioned): the engine print-then-offers the **pre-coding** backpressure seam — literal `/eng-harness-flow --hook pre-coding --spec <path>` (alias `--event post-spec`) *(router-installed only)* → `awaiting-backpressure`. The survey is **advisory output** (what's provable by sensors vs eyeballed); re-run plan **informed by** it — the plan verb does not auto-read the coverage. No auto-advance — the *re-plan* is the offer, never a forced second pass; the `--hook pre-coding` *call* still auto-fires per §6 step 3 (`harness-seams.md`) | `**Status**` (READY/DRAFT) + Gate Matrix + CS/Simple-Full + #Workshop Opportunities |
| `awaiting-2c` | newest `workshops/*.md` | another → **workshop** · → **plan** (re-run, folds the decision into both halves) | post-plan refinement hanging off `awaiting-1b`; the **pre-coding** backpressure seam still offered *(router-installed only)* | the headline decision (Selected option) |
| `awaiting-backpressure` | `backpressure-coverage.md` | → **plan** (re-run, **informed by** the coverage — advisory, not auto-read) | post-plan refinement hanging off `awaiting-1b`; backpressure payoff (artifact produced via the router) | Certainty (Strong/Partial/Weak) + Phase 0? |
| `awaiting-5` | `tasks/<phase>/tasks.md` | → **implement** (± its `--companion` mode — offer it here) | the engine print-then-offers the **pre-flight** boot seam at the phase edge — a `harness-boot` node before task 1 (`harness-seams.md`); literal `/eng-harness-flow --hook pre-flight` | first task's Done-When |
| `awaiting-6` | `execution.log.md` / phase status | clean → **review** · more phases (Full) → **tasks** | compact ✓ (between phases) · engine-owned seams at the phase edges (`harness-seams.md`): **pre-flight** boot *before* (`--hook pre-flight`), **post-coding** retro *after* (`--hook post-coding`) · review **skippable if a companion reviewed every commit** | what landed + AC met |
| `awaiting-7` | newest `reviews/*.md` | findings → fix + re-run **review** (stay) · clean → **ship** | tier contrast: computational (post-spec backpressure) vs inferential (review) | verdict + one finding |
| `awaiting-8` | ship report / PR opened (`ship/<date>/ship-report.md`) | checks green or reported → `complete` · base diverged → **reconcile** (excursion, `branch_of: "ship"`) · red check → fix + re-run **ship** (stay) | push & PR-open **each behind a confirm**; the reconcile/immediate merge is typed-`PROCEED`-gated — never a generic "yes" · seam: after ship, the engine offers the **post-flight** retro (`--hook post-flight`) — a `harness-retro` node (`branch_of: "ship"`, `harness-seams.md`) | PR URL + check status |
| `complete` | — | recap + stop; set `nav.bag.status:"complete"` | (the post-flight retro was already offered at ship) | — |

## Routing markers & read-time state translation

The `plan` verb is **atomic** — it always writes both halves in one pass — so there is no "spec written, plan pending" intermediate state and no STALE status. The only conditions are "no plan yet", "plan present (READY)", and "plan present but a gate FAILed (DRAFT)". Routing keys on `nav` first (`nav.now` / `nav.next`, read via `harness flow nav show`); the exact-string checks below are the **disk fallback** for idempotent resume / adoption / post-`/compact` (and for a flow that has only artifacts + a legacy state file) — case-sensitive `grep`, never a fuzzy prose scan.

| Predicate | Exact disk check (case-sensitive) |
|-----------|-----------------------------------|
| **Plan written** | `<slug>-plan.md` exists AND a line matches `^## Implementation Plan$` |
| **Plan is unified** (not a legacy architect-only plan) | a line matches `^## Business Specification$` |
| **Plan has unresolved gaps** | a line matches `^\*\*Status\*\*: DRAFT` |
| **Legacy split planning complete** | `<slug>-plan.md` exists with **no** `^## Business Specification$` line AND a sibling `<slug>-spec.md` exists — the old architect+spec pair (the legacy architect plan uses an h1 `# … Implementation Plan` title + `## Gate Matrix`/`## Phases`, never an `^## Implementation Plan$` wrapper, so "Plan written" above won't match it) |

**Read-time state translation (back-compat — never migrate on disk).** Old state files predate the collapse:

- `current_stage: awaiting-1b` (old meaning: spec done) **and** `current_stage: awaiting-3` (old meaning: plan done) both translate to the single **`awaiting-1b`**. The pending verb is then re-derived from artifacts (idempotency / adoption): a unified `<slug>-plan.md` with `## Implementation Plan` → `implement` (Simple) / `tasks` (Full); a legacy `<slug>-spec.md` only → `plan` (it reads the legacy spec as the business source and writes the unified document).
- **Legacy split-flow folder, already fully planned (don't re-plan it).** A folder carrying **both** a legacy `<slug>-spec.md` and a legacy architect-era `<slug>-plan.md` (h1 title + `## Gate Matrix`, **no** `## Business Specification`) is complete under the old split contract — matching the **Legacy split planning complete** predicate above. Treat it as `awaiting-1b` done and route by the legacy spec's `**Mode**`: Simple → **implement**, Full → **tasks**. Only a `<slug>-spec.md` with *no* plan beside it routes to **plan**.
- A `pending_command` naming `specify` or the architect verb (old id `3`) is translated via the dispatch's alias table to the `plan` command at read time (and when rendered into the flight plan).

## Must-see fields to scan (the Flag beat, per stage)

Where each artifact hides its **structured alarms** — lift any present, verbatim, into the Flag line (coach.md owns the phrasing). If a stage isn't listed, it rarely carries alarms (skip silently when clean).

| Stage | Scan for (quote any hits) |
|---|---|
| `awaiting-1a` | Critical/High risks (when present) or material historical warnings the dossier marks unresolved or contradicting the ask |
| `awaiting-1b` | `**Status**: DRAFT`; Gate Matrix **FAIL** rows; inline `⚠️ GAP:` markers; `## Unresolved Gaps` table; Deviation Ledger entries; remaining `[NEEDS CLARIFICATION]` markers; low CS **Confidence**; unanswered Open Questions |
| `awaiting-backpressure` | **ABSENT** / **BUILDABLE** sensors (the eyeball-gaps); a recommended **Phase 0: Establish Backpressure** |
| `awaiting-5` | tasks with no/weak Done-When; a phase carrying a flagged Key Finding |
| `awaiting-6` | acceptance criteria **not met**; skipped/blocked tasks; `Deferred`/`Noteworthy` Discoveries rows; new `TODO`/`FIXME`/`HACK` in the phase diff; deferred companion findings — the **Deferred & Noteworthy** digest the implement verb emits at phase end |
| `awaiting-7` | **CRITICAL/HIGH** findings; any verdict short of clean |
| `awaiting-8` | failing CI checks; push/PR-open blockers; base-divergence (reconcile) warnings; the whole-plan **Deferred & Noteworthy** rollup the ship verb computes — everything punted across all phases that's about to go out |

---

## Harness seams — owned by `harness-seams.md`

Harness-seam orchestration is **flow-owned** and lives in one file: [`harness-seams.md`](./harness-seams.md). Guided mode loads it **lazily** when the flow reaches a harness edge (progressive disclosure — the same way a stage's sub-skill is loaded only when its step is accepted). It owns: the **two-layer detection**, the **seam map** (every Graph edge → `--hook` + context flags → emitted node + the literal `/eng-harness-flow --hook …` command the engine print-then-offers), **node emission** (decoupled from provisioning), the **per-phase retro lifecycle**, the **honored-not-forced** posture, the **not-installed / unprovisioned silent paths**, and the **versioned upstream seam contract** (the `--hooks --json` mirror + resync procedure).

The four fire-hooks the flow wires — and which Graph edge each rides — are the terse `seam:` decorations in the Graph above (`pre-flight` at flow entry **and** before each phase, `pre-coding` post-plan, `post-coding` each phase end, `post-flight` at ship); the silent `coding` capture is deliberately **not** wired. **Never name or invoke the router's child skills** — the only stable surface is `/eng-harness-flow` + its `--hook` vocabulary (permanent `--event` alias). Seam nodes in `the-flow.json` use types `backpressure`, `harness-boot`, `harness-retro`; every one is **advisory** — never a gate, never blocks, no scores.

---

## Flight plan — `the-flow.json` (source of truth) + `the-flow.md` (rendered)

Every run maintains a **flight plan**: `docs/plans/<ord>-<slug>/the-flow.json` (canonical DAG) and `the-flow.md` (the vertical mermaid, **generated from** the JSON by `harness flow render`). The one-line rail (coach.md) is the JSON's glanceable twin.

> **Prerequisite**: guided mode drives this flight plan **only** through `harness flow` (plan 024). Probe a capable CLI before the first mutation; absent/too-old → stop with "run `harness update`" (SKILL.md § Prerequisite). No harness *adoption* is needed — the flight-plan schema ships with this skill and is supplied via `--schema`. **Load [`flight-plan-ops.md`](./flight-plan-ops.md) before the first flight-plan mutation of a session** — it carries the nav model, the spine-vs-excursion rule, the verb flags, and the gotchas. The cadence below is the routing-level *when*; that file is the *how*.

- **Schema**: [`flight-plan.schema.json`](./flight-plan.schema.json) — the CLI **descriptor** (`kind` + `statuses[]` + `nodeTypes[]`) the-flow ships and supplies to `harness flow` via `--schema`; the shared-core node/comment/root field shape is bundled in the CLI (no second copy here).
- **Create-seed (Route A, plan 039)**: [`flight-plan.template.json`](./flight-plan.template.json) — the bare-spine, **harness-agnostic** `--template` seed instantiated at `create` (`research → plan → phase-1 → ship`, zero harness nodes).
- **Worked example to copy** (every status, agents, the harnessed shape): [`flight-plan.example.json`](./flight-plan.example.json) + [`flight-plan.example.md`](./flight-plan.example.md).

**CLI-driven cadence (the `harness flow` CLI is the generator — you NEVER hand-edit `the-flow.json`/`.md`).** The CLI built in plan 024 owns mutation, the edge-algebra, the embedded event log, and deterministic render; guided mode is a **consumer** of it. Let `FLOW = docs/plans/<ord>-<slug>/the-flow.json`. Every guided turn, after deciding the narration, drive the flow with `harness flow` calls, threading each ok Envelope's `data.path` back into the next `--path`:

1. **Mutate for what just happened** (one call per change, `--path FLOW`) — exact flags: [`flight-plan-ops.md`](./flight-plan-ops.md) § 3:
   - a step finished → `status --to done` (fires `status-changed`, stamps `ran_at`); `→ blocked` / `→ in_progress` likewise;
   - the user's **verbatim** words → `set-node --user-input "<verbatim>"`;
   - what was done / produced → `set-node --note "<1–2 lines>"` (+ `--label` if it changed);
   - a narrative / decision note → `comment --kind <note|decision|warning|validation>`;
   - advance → `nav set --now <id>` (move; fires cursor-moved) / `--next <id>` (advisory) / `--clear-next`. (§ 2)
2. **Reveal/refine the future** — `insert-node` owns every edge splice, no hand edge-recomputation ([`flight-plan-ops.md`](./flight-plan-ops.md) § 4 spine-vs-excursion, § 6 build-order):
   - at the `plan` pass (plan-complete), the **plan-complete ADDITIVE EXPANDER** runs (Route A, plan 039): for N>1 phases it emits **ONE** `harness flow apply --ops -` batch that splices `phase-2..N` after `phase-1` — **purely additive, nothing relocates, no `mv`**. When the harness gate holds (router installed **AND** repo provisioned) each new phase carries its own **boot + observe + drain** chores (deterministic ids `boot-N`/`observe-N`/`retro-N`); **gate off → bare phase nodes only** (R1 — the spine never goes half-harnessed). A **Simple (1-phase)** plan needs no expansion — it was complete at `create`. The expander is **byte-stable idempotent** (AC-03), so re-running it no-ops on a complete spine — which is exactly what lets the every-entry **§ Reconcile the spine** pass invoke it safely on **each** entry (the *idempotent superset* that catches adopted / post-pass-edited / direct-jump-built / harness-installed-mid-flow plans the single reveal misses). *(`insert-node --type phase` remains valid for a one-off manual phase add; the expander is the batch that keeps multiphase + its chores consistent.)*
   - a conditional fix-loop / workshop / backpressure / reconcile excursion → `insert-node --branch-of <node> [--rejoin <node>]` (the branch point's `next` is unchanged) — **workshops ALWAYS `--branch-of`, never on the spine**; the **reconcile** excursion branches off `ship` (or a phase) only when the base has diverged;
   - a plain new node needing no splice → `add-node`.
3. **Reconcile the spine, render, fire any due seam, surface what's due here.** **First, run the spine-reconcile pass** (§ Reconcile the spine) as a **Tier-1 mechanical step — a sibling to `render`, run unconditionally every guided entry (skip only on fresh start), never an offered beat.** It rides the same positional *"a long or compacted session cannot skip it"* guarantee as the seam auto-fire below, so **RUN is mandatory and mechanical** while what it **FINDS stays advisory/non-gating**. Idempotent — a complete spine writes nothing and renders nothing; reconcile is the same *species* as `render` (pure structural hygiene, read-only when clean), which is exactly why it needs no offer. **Then** `harness flow render --path FLOW --output docs/plans/<ord>-<slug>/the-flow.md`, then print the rail (coach.md owns the rail; the CLI owns the `.md`). Then read `harness flow nav show` and:
   - **Auto-fire any harness seam due at `nav.now` (positional, mandatory, read-only).** When `nav.now` carries a `seam:` decoration in the Graph above (which prints the literal `/eng-harness-flow --hook …` command) — or `due_chores` names a harness hook — **fire the router call now**: `/eng-harness-flow --hook … --json`. This is driven by `nav.now`, **not** by whether the prior turn's offer survived in context, so a long or compacted session cannot skip a seam. The `--json` call is read-only/advisory (never mutates, never blocks); narrate its envelope **verbatim**, then **print-then-offer only the command it routes to** (call-only depth — invariants #1/#4). Layer-1/Layer-2 detection still short-circuits a missing/unprovisioned router to its silent path. **Firing means actually INVOKING `/eng-harness-flow` through the host's skill mechanism — the Skill tool in Claude Code, the equivalent slash-command invocation elsewhere — with the node's exact `--hook`; never narrate a plausible envelope, reimplement the check inline, or flip the node to `done` without a real call (AC-14). The envelope is narrated verbatim from that real invocation (invariant #5 — never fabricate). Declining is a real `harness flow status <chore> --to skipped` CLI call (honest, recorded), never a narrated skip and never a fake `done` — a discipline, not a gate (no compliance floor, invariant #4). For an `observe` chore the equivalent is actually running `harness observe "<what>" --kind <kind>`, a real capture, not a narrated one.** Mechanism + per-edge hook/node: [`harness-seams.md`](./harness-seams.md) §§ How the engine presents a seam, Compaction-robust firing.
   - When **`due_chores`** is non-empty, surface them in the narration — the **"due here" beat**: the harness-loop chores anchored at the current node that are still outstanding, e.g. *"due here: `pre-coding` — run `/eng-harness-flow --hook pre-coding`"*. It is **advisory** — a presented due item, never a gate (invariant #4) — and when `due_chores` is `[]` (nothing anchored here) or absent (an older CLI without the field), say nothing. (`due_chores` = the chores whose `branch_of` anchor is `nav.now`, status still `todo`; harness plan 033. See [`harness-seams.md`](./harness-seams.md) § Chore-flag ownership.)
4. **Integrity is the CLI's, not yours** — `insert-node` DAG-re-checks before writing (`E309`, nothing written on a cycle/orphan); `create` validated the flight-plan overlay (statuses + nodeTypes) against the shipped `--schema`. The mutation verbs enforce only node existence (`E305`) + edge integrity — they do **not** re-check the overlay vocabulary (the flight-plan schema is supplied via `--schema`, not bundled), so the engine is responsible for using the correct node types/statuses (it owns the Graph); the renderer's unknown-type fallback never crashes. No hand self-check; no hand JSON edits.

**Status vocabulary** (the values you pass to `harness flow status --to` / `--status`): `assumed` (*speculative* future, e.g. a conditional fix loop) · `known` (*designed* future, e.g. phases locked at the `plan` pass) · `in_progress` · `done` · `blocked`. Transitions: `assumed → known` (at the `plan` pass) → `in_progress` → `done`; any active node → `blocked` → back to `in_progress`. The status→colour mapping is the **renderer's** (CLI), not the-flow's.

**Render is the CLI's — not the-flow's.** `the-flow.md` is generated from `the-flow.json` by `harness flow render --path docs/plans/<ord>-<slug>/the-flow.json --output docs/plans/<ord>-<slug>/the-flow.md`. The renderer (plan 024 Phase 2) owns **every** visual rule — `flowchart TD` + classDefs/colours, the solid spine vs dotted `branch_of` excursions, violet `:::harness` seam nodes (emitted only when the router is installed + provisioned), status→colour, the one genesis `🗣 user_input` bubble per node, the `💬N` comment badge + per-node body-log, the `decision` rhombus, the companion subgraph / worker side-node, the legend, the rail pips, and the unknown-type fallback (never crashes). Do not re-document or hand-apply any of them here — the full verb + render reference is [`docs/how/harness-flow.md`](https://github.com/AI-Substrate/harness-engineering/blob/main/docs/how/harness-flow.md).

> **Invariant**: never hand-edit `the-flow.md` — it is **always** regenerated from `the-flow.json` by `harness flow render`. And never hand-edit `the-flow.json` either — mutate it only through `harness flow` calls (§ CLI-driven cadence above).

**Legacy note (clean break).** Pre-migration flows — hand-cranked `the-flow.json` with no `provenance` block — are **not** migrated: the CLI returns `E308` (legacy-format) on read. That is an honest stop, not a bug; re-create with `harness flow create … --agent the-flow` (see SKILL.md § capability precheck).

---

## Reconcile the spine — the every-entry completeness pass

**The flight plan must represent the whole journey as currently known — every past, present, and future phase + workshop, plus every harness seam-node — on every entry, without the user asking.** Today the spine is built *incrementally* as the engine walks the happy path (phases revealed once at the `plan` pass, § Flight plan step 2); that leaves it partial whenever the pass never ran for the current roster — an **adopted** plan (§ Adoption back-fills only the inferred node), a plan **edited after** the pass, a **direct-jump-built** plan (no engine, no nodes), or a harness **installed mid-flow**. This pass closes that gap by **reconciling declaratively from the artifacts** rather than trusting incremental build. It is the engine routine behind the `sync` verb (`../SKILL.md` Registry + invariant #11).

**When it runs.** On **every** guided entry — after resolve (resume/adopt), before narrating — and on demand via the `sync` verb. Fresh start has nothing to reconcile (skip). **Idempotent**: a complete spine produces **no** CLI writes and renders nothing.

**How it's enforced — a Tier-1 mechanical cadence step, not prose memory.** Reconcile is wired into § Flight plan / CLI-driven cadence **step 3 as a sibling to `render`** — run **unconditionally** (skip-on-fresh only), **never an offered beat**. It rides the same positional *"a long or compacted session cannot skip it"* guarantee as the harness-seam auto-fire, so it survives long/compacted sessions. This is what makes invariant #11's "mandatory every entry" actually hold under load — the prose declaration alone was the thing that failed. The axis split is exact: **RUN is mandatory + mechanical** (render-class — pure structural hygiene, read-only when clean); **what it FINDS stays advisory/non-gating** (never gates, blocks, or advances `nav` — below).

**What it reconciles** (diff current knowledge → flight-plan nodes; backfill only what's missing; all writes via `harness flow`, build-order safe per § Flight plan / flight-plan-ops.md §6):

1. **Phases — all of them.** Read the plan's `#### Phase Index` (Full) or its single `### Implementation` block (Simple → one phase). For each phase with no matching spine node → `insert-node --type phase --after <prev>`. Status from disk: a phase already completed → `done`; the current one → `in_progress`; the rest → `known`. **Never downgrade** a node that is further along than the artifact implies — `nav`/status already-advanced always wins.
2. **Workshops — past and present.** For each `workshops/*.md` with no matching node → `insert-node --type workshop --branch-of plan` (workshops are ALWAYS excursions — flight-plan-ops.md §4), status `done` (the file exists).
3. **Harness seam-nodes / per-phase chores** *(router installed **and** repo provisioned only)*. Pre-anchor, across **all known phases**, the per-phase seam set the seam map defines — `harness-boot` (`pre-flight`) + `observe` (`coding`, 039) + `harness-retro` `(drain)` (`post-coding`) per phase, plus the two globals `backpressure` off `plan` and `harness-retro` `(harvest)` off `ship`. **Route A (plan 039): on a flight plan these are laid as a single byte-stable additive `apply` by the create-time conditional chore apply (create routine) and the plan-complete additive expander, gated identically (installed AND provisioned) at BOTH create and expansion (R1) — so reconcile's expander invocation just re-asserts them idempotently (no-op on a complete spine).** The pre-039 split still governs **coexistence** with a the-flow built *without* the chores: reconcile emits seam **nodes only** and **`eng-harness-flow` owns the chore *flag*** (dedup on the `--hook` token, flagging a matching seam node rather than minting a twin — `harness-seams.md` § Chore-flag ownership, § Reconcile pre-anchors seam nodes); D5 + byte-stability make the two paths converge with no double-placement. Router not installed, or repo unprovisioned → emit **no** harness nodes/chores at all (unbroken spine / no per-phase nagging — `harness-seams.md` § Node emission).
4. **Render** once iff anything changed (`harness flow render`).

**What it never does.** Never advances `nav` (it reconciles *structure*, not position). Never runs a stage, gates, blocks, or scores. Never edits stage artifacts. Never re-parents an existing node (`set-node` can't — flight-plan-ops.md §6); a structurally wrong existing node is left as-is and noted, not rewritten. CLI-only (invariant #6); **no new state file** — the plan artifact is the source of "what should be here," recomputed at read time (KISS).

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
