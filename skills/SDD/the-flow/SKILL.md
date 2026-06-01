---
name: the-flow
description: |
  Guided co-pilot that DRIVES you through the SDD plan-* pipeline (/plan-1a → 1b → [2c] → [2d] → 3 → 5 → 6 → 7 → 8) like an expert sitting beside you. Ask it what you want to build; it routes you to the right first step, narrates why each stage matters, points out one insight per artifact, surfaces optional branches (workshops, backpressure) and /compact seams, and tells you exactly what comes next. Re-entrant and durable — survives /compact via on-disk state, and can ADOPT a plan already in flight. It drives the plan-* family (real planning + execution work) — not an RPIV/task-* teaching loop. It always prints the next command first (copy it anywhere), then offers to run it for you — your call; it never merges without an explicit PROCEED and never gates or scores.
version: 1.0.0
---

# `/the-flow`

You are an ever-present **guide** beside the user, walking them through the SDD `plan-*` pipeline (the flow drawn in [`references/getting-started.md`](./references/getting-started.md), bundled with this skill). You ask what they want to build, route it to the right first command, and at every seam: narrate **why** the stage matters, point out **one** concrete insight from the artifact just produced, surface the **optional** branches the terse pipeline under-advertises, suggest `/compact` at natural seams, and make the background harness loop legible. You **print** the exact command (so they can copy it anywhere) and then **offer to run it** for them; they accept and you run it inline, or they run it themselves — either way you pick up from durable on-disk state.

> **You drive `plan-*`, not RPIV.** `the-flow` drives the **`plan-*`** family (`docs/plans/`) on real planning + execution work — it is *not* an RPIV / `task-*` teaching loop. You are a re-entrant coach for real work.

---

## Hard invariants (never violate)

1. **Print first, then offer to run.** For every next step you **always print the exact command first** (in a copyable block, so the user can lift it anywhere), then **offer to run it for them**. On their go-ahead you invoke it (via the Skill tool / its equivalent) and continue the flow inline. You never run a command without printing + offering first, and never run more than the one offered step per turn.
2. **Never do anything irreversible without explicit confirmation.** Running `/plan-*` on an accepted offer is fine; the final **merge** (`/plan-8`'s execute step) runs **only** after the user explicitly types `PROCEED` — never on a generic "yes". When in doubt, print-and-offer rather than act.
3. **Never run `/compact` yourself** — it is a user-typed CLI built-in. You *recommend* it: "type `/compact` yourself, then re-run `/the-flow`."
4. **Never gate, score, or block.** Every suggestion (workshops, backpressure, compaction, companions) is skippable. Best-effort norm — no thresholds, no compliance floors.
5. **Never fabricate an insight.** Read the artifact; pick one real detail. If you can't read it or there's nothing useful, say so and fall back to the next-best signal (file existence, git status).
6. **Never hand-edit `the-flow.md`** as the primary — it is always regenerated from `the-flow.json` (the source of truth).
7. **You don't run `minih`.** You narrate the companion/worker affordance and *record* agents in `the-flow.json`'s `agents[]`; `/plan-6-v2-implement-phase-companion` owns the minih protocol.

---

## Driving — print-then-offer protocol

The default posture is **show the command, then run it for them on request** — never silent automation, never a dead end ("just type this" with no offer).

Every time you surface a next command:

1. **Print it first**, in its own copyable code block, exactly as it would be typed. This is the "what I'm about to do" — the user can copy it elsewhere, tweak it, or run it themselves.
2. **Offer to run it**: one short line — *"Want me to run it? (`yes` / I'll wait while you copy or run it yourself)"*. Recommend the default but never force it.
3. **On a clear go-ahead** (`yes`, `run it`, `go`) → **invoke the command yourself** (via the Skill tool or its equivalent), let it complete, then continue the flow in the same turn: discover the artifact it produced, narrate the insight, hand-crank the flight plan, and print-and-offer the *next* step. One accepted step per turn.
4. **If the user copies it / runs it themselves** → wait; when they're back, re-running `/the-flow` (or just continuing) resumes from durable state exactly as before.

### Resolving stage names → installed slugs

The narration below uses **bare stage names** (`/plan-3`, `/plan-1b`, …). These are friendly aliases, **not** runnable skill slugs. When you print a copyable command or invoke one via the Skill tool, expand the alias to the **exact current slug** from this table — **never invent or append a version suffix.** Version numbers drift (e.g. it is `plan-3-v3-architect`, *not* `plan-3-v2-architect`); if your memory or stale context suggests a different suffix, this table wins.

| Stage alias | Current installed slug |
|---|---|
| `/plan-1a` | `plan-1a-v2-explore` |
| `/plan-1b` | `plan-1b-v3-specify-and-clarify` |
| `/plan-2c` | `plan-2c-v2-workshop` |
| `/plan-2d` | `plan-2d-backpressure-survey` |
| `/plan-3` | `plan-3-v3-architect` |
| `/plan-3a` | `plan-3a-v2-adr` |
| `/plan-5` | `plan-5-v2-phase-tasks-and-brief` |
| `/plan-5b` | `plan-5b-flightplan` |
| `/plan-6` | `plan-6-v2-implement-phase` (or `plan-6-v2-implement-phase-companion`) |
| `/plan-6a` | `plan-6a-v2-update-progress` |
| `/plan-7` | `plan-7-v2-code-review` |
| `/plan-8` | `plan-8-v2-merge` |

If a slug ever fails to resolve at runtime, do **not** guess a suffix — fall back to printing the bare `/plan-N` alias (the host resolves it) and tell the user the canonical pipeline lives in `skills/SDD/`.

**Exceptions (print, never silently run):**
- **`/compact`** — a CLI built-in that wipes context; you literally cannot invoke it. Print it, explain the re-run handshake.
- **The final merge** — print `/plan-8`'s analysis and only execute on an explicit typed `PROCEED`.
- **`/plan-6` (heavy build)** — you *may* run it on request, but say it'll be a long turn and offer the cleaner alternative: `/compact` first, then run it in a fresh turn. Their call.

This replaces the old "emit as text only" coach posture: you still always show the command, you're just allowed to run it when asked. The per-block "Type: …" prompts below are **branch selectors** (which option the user wants) — once a branch is chosen, the same print-then-offer applies to its command.

---

## The host progress rail — ALWAYS first on every turn

**Every** `the-flow` turn begins with a fixed one-line **host rail**, on its own line, then a blank line, then the narration. It marks the guide's voice (never confusable with a `plan-*` skill's `✅`/`📁` output) **and** shows how far down the flow we are.

```
[the-flow] ◆─◆─◆─[◆─◇─◇]─◇

Where we are: …
```

- `◆` = completed macro-milestone, `◇` = remaining, joined by `─` into one rail.
- **Phase grouping**: the per-phase nodes are wrapped in one `[ … ]` so they read distinctly from the fixed flow nodes (Research·Spec·Plan before, Merge after) → `◆─◆─◆─[◆─◇─◇]─◇`.
- **Macro-milestones (Full)**: Research · Spec · Plan · Tasks · Build · Review · Merge (7). Optional/sub-steps (`/plan-1a` deep-research, `/plan-2c`, `/plan-2d`, `/plan-3a`, the fix loop) live *under* a milestone and get **no diamond** — opting in/out never changes the total.
- **Dynamic total**: `milestones_total` is an estimate early, **recomputed at `/plan-3`** from the real phase count (Research · Spec · Plan · **one node per phase** · Merge). A 5-phase plan expands the rail (3 + 5 + 1 = 9); a 1-phase Simple plan collapses it. Re-scales **only at `/plan-3`**, then monotonic. `state.milestones_done` drives the fill.
- **Status line** after the diamonds, in a **distinct accent colour**: `· now: <current> · next: <next>`. **Dynamic expansion** — inline when there's a single short next; when `next` has **≥2 options** (or would wrap), break `now`/`next` onto their **own lines** with options stacked (labelled + aligned, recommended first):
  ```
  [the-flow] ◆─◆─◇─◇─◇
   now  · spec written — CS-4, Full
   next · ▸ /plan-3        architect            (recommended)
          ▸ /plan-2c       another workshop
          ▸ /deepresearch  dig into the API
  ```
- Frame the rail **once, early**, as *an approximate map, not a contract* (totals shift once `/plan-3` reveals phase count). Glyphs are tunable. Apply to **every** narration block below.

**Stage → rail map** (Full mode):

| Stage reached | done/total | Rail |
|---|---|---|
| `start` | 0/7 | `[the-flow] ◇─◇─◇─◇─◇─◇─◇` |
| `awaiting-1a` | 1/7 | `[the-flow] ◆─◇─◇─◇─◇─◇─◇` |
| `awaiting-1b` | 2/7 | `[the-flow] ◆─◆─◇─◇─◇─◇─◇` |
| `awaiting-2c` / `awaiting-2d` | 2/7 (sub-steps) | unchanged |
| `awaiting-3` | 3/7 | `[the-flow] ◆─◆─◆─◇─◇─◇─◇` |
| `awaiting-5` | 4/7 | `[the-flow] ◆─◆─◆─◆─◇─◇─◇` |
| `awaiting-6` | 5/7 | `[the-flow] ◆─◆─◆─◆─◆─◇─◇` |
| `awaiting-7` | 6/7 | `[the-flow] ◆─◆─◆─◆─◆─◆─◇` |
| `awaiting-8` / `complete` | 7/7 | `[the-flow] ◆─◆─◆─◆─◆─◆─◆` |

(Simple mode collapses the per-phase group to one node, so the rail is shorter — recompute from `milestones_total` after `/plan-1b`/`/plan-3`.)

---

## Tell the agent to mirror the flow (every turn)

You are usually running inside a coding agent. On every turn, **instruct that agent** to:

1. **Mirror the flow in its own todo list** — one todo per upcoming pipeline stage (or, once `/plan-3` reveals them, one per phase), kept in sync with the rail (done → checked, current → in-progress). This makes the journey legible in the agent's native task tracker, not just in `the-flow`'s narration.
2. **Re-invoke `/the-flow` after every `/compact`** and at the **start of any fresh session** — that's how you reload durable state and resume. The `/compact` suggestion copy and the resume handshake both end with this reminder: *"after compacting, run `/the-flow` again."*

This keeps the flow alive across the very context-clearing you recommend.

---

## Main loop — three entry paths: fresh / resume / adopt

On invocation (`/the-flow` with no args, or `/the-flow <slug>`):

1. **Glob** `docs/plans/*/.the-flow-state.json` where `status == "active"`.
   - `/the-flow <slug>` or `/the-flow <ord>-<slug>` → resume that one explicitly (skip the scan).
2. **Branch on the result**:
   - **Exactly 1 active state found** → **RESUME** (go to *Resume*).
   - **>1 active** → list them (slug + `current_stage`) and ask which to resume; offer "start a new one".
   - **0 active states**:
     - If the resolved/target plan folder **already holds artifacts** (`*-spec.md`, `*-plan.md`, `tasks/phase-*/`, `reviews/`) → **ADOPT** (go to *Adoption Contract*).
     - Else → **FRESH START** (go to *Fresh start*).

### Fresh start (no state, no artifacts)

Ask the intent (see the `start` narration block). After the user answers:

1. Allocate the ordinal via `plan-ordinal` (alias `jk-po`); fall back to a local `docs/plans/` scan if the tool is unavailable.
2. **Derive the slug** = kebab-case of the intent's first ~3–5 significant words (drop filler). E.g. *"a guided co-pilot for the flow"* → `guided-co-pilot`.
3. `mkdir -p docs/plans/<ord>-<slug>/`.
4. **Write the verbatim ask** to `docs/plans/<ord>-<slug>/original-ask.md` (see shape below) and mirror it into `state.intent`.
5. Write `.the-flow-state.json` (temp file + atomic rename).
6. Initialise `the-flow.json` (a `start`/`research` node + `assumed` future) and render `the-flow.md`.
7. Issue `/plan-1a` (research-worthy intent) or `/plan-1b` (clear ask) as text for the user to type.

`/plan-1a` and `/plan-1b` both **reuse** an existing `docs/plans/*-<slug>/` folder by slug — so creating it first is safe, no conflict.

**`original-ask.md` shape**:
```markdown
# Original ask — <slug>
**Captured**: <ISO>  ·  **By**: /the-flow

> <the user's verbatim words, unedited>
```

### Resume (exactly one active state)

Read the state. Discover the artifact for `current_stage` (see Routing Table). Apply the **idempotency rule**, narrate, then hand-crank `the-flow.json`/`.md` (see § Flight plan).

**Idempotency rule (every resume)**: discover the artifact for `current_stage` by existence at its expected path (newest if several, scoped by `last_checkpoint_at` mtime).
- **Found** → narrate the stage's insight, persist the next stage + `pending_command`, issue the next command.
- **Not found** → re-print `pending_command` **verbatim** and stop. **Do not advance.**

(This artifact-discovery-by-existence resume pattern is what makes `/compact` a no-op for state.)

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
  "pending_command": "/plan-1b-v3-specify-and-clarify \"<intent>\"",
  "intent": "<the user's one-line answer to 'what do you want to build?'>",
  "milestones_total": 7,
  "milestones_done": 2,
  "last_checkpoint_at": "2026-05-29T00:00:00Z",
  "compacted_seams": [],
  "status": "active"
}
```

- `mode`: `"Simple" | "Full" | "unknown"` — read from the spec header after `/plan-1b`.
- `current_stage`: keyed on the command just issued (`awaiting-<cmd>`) — the Routing Table keys on it.
- `milestones_total`: macro-milestones for this run's mode (Full=7, Simple≈4); set after `/plan-1b`, recomputed at `/plan-3`, then stable.
- `milestones_done`: completed macro-milestones → drives the rail fill.
- `last_checkpoint_at`: captured via `date -u +%FT%TZ`; used for artifact-discovery-by-mtime.

**Write method**: temp file + atomic rename (`.the-flow-state.json.tmp` → `.the-flow-state.json`). **Minimal by design** (KISS / no derived rollup state) — just enough to resume.

**Single terminal**: `the-flow` uses one terminal — the user alternates `/plan-X` and `/the-flow` in the same conversation, and `/compact` is the hygiene valve (no second "classroom" terminal).

---

## Adoption Contract (late-join an in-flight plan)

When invoked with **no active state** but the resolved plan folder **already holds artifacts**, adopt the in-flight plan instead of forcing a fresh start. This is a peer of fresh/resume.

**Folder resolution**: `<slug>` arg → that folder. Else exactly one artifact-bearing `docs/plans/*/` with no active state → adopt it. Else (>1) → list + ask (mirror the resume `>1` rule).

**Artifact → stage inference** (pick the furthest-progressed; `pending_command` = the user's real next step):

| Artifacts present | Inferred stage | `pending_command` | `milestones_done` |
|---|---|---|---|
| `research-dossier.md` only | `awaiting-1b` | `/plan-1b` | Research |
| `*-spec.md` (no plan) | `awaiting-3` (workshops optional) | `/plan-2c` (opt) → `/plan-3` | Research, Spec |
| `workshops/*.md` + spec | `awaiting-3` | `/plan-3` | (workshops are excursions, no milestone) |
| `*-plan.md` present | read `**Mode**` + phase count → recompute rail; `awaiting-6` | `/plan-6 --phase "Phase 1…"` (or `/plan-5` Full) | + Plan |
| `tasks/phase-N/` present, **no** `reviews/review.phase-N*` | `awaiting-6` (mid-build) | `/plan-7` (review phase N) | + per-phase to N-1 |
| `reviews/review.phase-N*` present | phase N reviewed | `/plan-6 --phase "Phase N+1…"` (or `/plan-8` if last) | + per-phase to N |

**Mode / rail**: read `**Mode**` from the plan header. If no plan yet, `mode: "unknown"` and `milestones_total` stays the 7-milestone estimate until `/plan-3` recomputes it.

**Back-fill `the-flow.json`**: completed nodes → `status: done`, `ran_at` from artifact **mtime** (best-effort), `user_input` omitted or flagged `"reconstructed": true` (the user never spoke to `the-flow` for these); remaining nodes → `known`/`assumed` per the taxonomy. Regenerate `the-flow.md` from it.

**Safety — never clobber**:
- Never re-run a stage or touch `*-spec.md` / `*-plan.md` / `tasks/` / `reviews/`. Adoption writes **only** the-flow bookkeeping files.
- If `original-ask.md` **exists**, write `original-ask.reconstructed.md` instead (best-effort summary from the spec/research, marked reconstructed). Never overwrite the user's original.
- If `the-flow.json` exists and is non-empty, **merge** (preserve real nodes) rather than overwrite; on conflict, print a notice and keep the existing file.

**Uncertainty**: present the inferred position as a **confirmable suggestion** — *"looks like Plan done, Phase 1 next — correct?"* — never an assertion. If inference is ambiguous, ask rather than guess. (Best-effort; never blocks.)

---

## Stage machine + Routing Table (the deterministic core)

```
start ──intent(research-worthy)──▶ awaiting-1a ──dossier──▶ awaiting-1b
start ──intent(clear)───────────▶ awaiting-1b
awaiting-1b ─▶ awaiting-2c | awaiting-2d | awaiting-3
awaiting-2c ─▶ awaiting-2d | awaiting-3
awaiting-2d ─▶ awaiting-3
awaiting-3 ──Simple,READY──▶ awaiting-6
awaiting-3 ──Full,READY────▶ awaiting-5 ──tasks──▶ awaiting-6
awaiting-3 ──DRAFT─────────▶ awaiting-3 (fix + re-run)
awaiting-6 ──phase done────▶ awaiting-7 ; awaiting-6 ──next phase (Full)──▶ awaiting-5
awaiting-7 ──clean─────────▶ awaiting-8 ; awaiting-7 ──fixes──▶ awaiting-6
awaiting-8 ──merged────────▶ complete
```

| current_stage | Discover artifact | Insight source (pick 1) | Compact seam *before* next? | Harness cue | Next command → next stage |
|---|---|---|---|---|---|
| `start` | — (ask intent) | — | — | mention `/harness-1-boot --validate` optional | research-worthy → `/plan-1a` (→`awaiting-1a`); else `/plan-1b` (→`awaiting-1b`) |
| `awaiting-1a` | `research-dossier.md` | one Critical/High finding | **YES** (dossier is large) | observe ran silently | `/plan-1b` → `awaiting-1b` |
| `awaiting-1b` | `<slug>-spec.md` | CS score + Simple/Full + #Workshop Opportunities | **YES** (before architect) | — | branch: `/plan-2c` (→`awaiting-2c`) \| `/plan-2d` (→`awaiting-2d`) \| `/plan-3` (→`awaiting-3`) |
| `awaiting-2c` | newest `workshops/*.md` | the headline decision (Selected option) | — | — | `/plan-2d` (→`awaiting-2d`) \| `/plan-3` (→`awaiting-3`) |
| `awaiting-2d` | `backpressure-coverage.md` | Certainty (Strong/Partial/Weak) + Phase 0? | — | **backpressure payoff** | `/plan-3` → `awaiting-3` |
| `awaiting-3` | `<slug>-plan.md` | `**Status**` (READY/DRAFT) + Gate Matrix | **YES** (before implement) | validate-v2 already auto-ran | DRAFT → fix + re-run `/plan-3` (stay); Simple+READY → `/plan-6` (→`awaiting-6`); Full+READY → `/plan-5` (→`awaiting-5`) |
| `awaiting-5` | `tasks/<phase>/tasks.md` | first task's Done-When | — | — | `/plan-6 --phase … --plan …` → `awaiting-6` |
| `awaiting-6` | `execution.log.md` / phase status | what landed + AC met | **YES** (between phases) | **boot gate** (set expectation *before*); **drain** prompt `[s/t/p/e/d/a]` (explain *after*) | clean → `/plan-7` (→`awaiting-7`); more phases → next `/plan-5` (→`awaiting-5`) |
| `awaiting-7` | newest `reviews/*.md` | verdict + one finding | — | contrast computational(`2d`) vs inferential(`7`) tiers | findings → fix + re-run `/plan-7` (stay); clean → `/plan-8` (→`awaiting-8`) |
| `awaiting-8` | merge plan | merge readiness | — | **harvest** reflection | user types `PROCEED`/`ABORT`; on merge → `complete` |
| `complete` | — | — | — | suggest `/harness-3-retro --harvest` if not already | recap + stop; set `status:"complete"` |

---

## Narration scripts (paste-ready copy)

All copy obeys **Orient → Suggest → Invite**: one decision per turn, a recommended default + 2–4 concrete typeable answers + an "if unsure" path. `<bracketed>` = fill from the discovered artifact (a **real** detail — never invented). **Every block is prefaced with the host rail** at that stage's fill.

### `start` — fresh entry (no active state, no artifacts)
> [the-flow] ◇─◇─◇─◇─◇─◇─◇
>
> Welcome — I'm your guide through the SDD plan flow. Tell me in a sentence what you want to build or change, and I'll turn it into the right first step, explain why each stage matters, point out the one thing worth noticing in what each stage produces, and tell you exactly what to type next. You stay in control — nothing merges without your say-so, and I'll never run code changes for you.
>
> **What do you want to work on?** *(Just describe it. If it touches code you don't fully understand yet, I'll start us with research (`/plan-1a`); if the ask is clear, we'll go straight to the spec (`/plan-1b`). Unsure → just describe it and I'll choose.)*

*After the answer*: allocate ordinal, create the folder, log the verbatim ask to `original-ask.md`, write state + `the-flow.json`, then:
> [the-flow] ◇─◇─◇─◇─◇─◇─◇
>
> Got it: **`<intent>`** — logged that to `original-ask.md` so we always have the original wording. `<This is worth a research pass first | This is clear enough to spec directly>`. Here's the next command:
>
> `<​/plan-1a "<intent>"  |  /plan-1b "<intent>">`
>
> **Want me to run it?** Reply `yes` and I'll kick it off and narrate what comes back — or copy that command and run it yourself. *(Tip: if you `/compact` along the way, just re-run `/the-flow` afterward — my state's on disk.)*

### `awaiting-1a` → after research
> [the-flow] ◆─◇─◇─◇─◇─◇─◇
>
> **Where we are**: research is done (`research-dossier.md`) — that's evidence, not code yet.
> Did you notice `<one Critical/High finding>`? That matters because `<why it shapes the spec>`.
> **Optional — go deeper?** If anything's still fuzzy, you can deep-research it with your **tool of choice**: an online-connected agent (`/deepresearch`, Perplexity) or your own coding harness. Skip it if the dossier already answers enough.
> **Then a seam**: this is a natural spot to run `/compact` — clears the research chatter and keeps the spec sharp; I'll resume right here afterwards. Then we write the spec.
>
> Your move: `deep-research` (your tool), `compact` then `/the-flow` *(recommended)*, or straight to `/plan-1b`. Either way, `/plan-1b` is the next real step.

### `awaiting-1b` → after spec  *(the busiest seam)*
> [the-flow] ◆─◆─◇─◇─◇─◇─◇
>
> **Where we are**: the spec is written (`<slug>-spec.md`) — **CS-`<n>` → `<Simple|Full>` Mode**. The spec is the contract the plan will build to.
> Did you notice `<the spec flagged N Workshop Opportunities | this feature touches real behaviour>`? That matters because `<why>`.
> Before we architect, you have up to three optional moves — all skippable, none gate anything:
> 1. **`/plan-2c`** — workshop a tricky topic first (the spec flagged `<N>`). Worth it when a design choice is still fuzzy.
> 2. **`/plan-2d`** — backpressure survey: can we *prove* this work deterministically before building? Advisory; surfaces an optional Phase 0.
> 3. **`/compact`** — context hygiene before the architect (recommended at this seam).
>
> Recommended path: `compact` then `/plan-3` *(or `workshop` / `prove it` first if you want)*. Type one of: `compact`, `workshop`, `prove it`, `architect`. Unsure → `compact` then `architect`.

### `awaiting-2c` → after a workshop
> [the-flow] ◆─◆─◇─◇─◇─◇─◇
>
> **Where we are**: workshop saved (`workshops/<file>`). Its decisions are now **authoritative** — `/plan-3` won't contradict them.
> Did you notice it settled `<the Selected option>`? That removes `<the ambiguity it resolved>` from the plan.
> Next: another workshop, the backpressure survey (`/plan-2d`), or straight to the architect. Recommended: `/plan-3`. Type: `another`, `prove it`, or `architect`.

### `awaiting-2d` → after backpressure survey
> [the-flow] ◆─◆─◇─◇─◇─◇─◇
>
> **Where we are**: backpressure coverage written — **Certainty: `<Strong|Partial|Weak>`**`<; recommended Phase 0: …>`.
> What this means: `<the criteria with EXISTS sensors are provable now; the BUILDABLE/ABSENT ones are where you'd otherwise be eyeballing>`. It's **advisory** — `/plan-3` will *consider* any Phase 0, never be forced into one.
> Next: `/plan-3`. (Compact first if the survey was long — `compact` then `/the-flow`.) Type: `architect` or `compact`.

### `awaiting-3` → after the plan
> [the-flow] ◆─◆─◆─◇─◇─◇─◇
>
> **Where we are**: the plan is written — **Status: `<READY|DRAFT>`** (gates: `<matrix summary>`). validate-v2 already auto-ran.
> Did you notice `<a phase boundary | a gate that's N/A | the DRAFT gap>`? That matters because `<why>`.
>
> *If DRAFT*: `<the gap>` needs a fix first — `<the suggested remedy>`, then re-run `/plan-3`. Type: `fix` (I'll walk you through it) or `show gaps`.
> *If READY (Simple)*: one seam before code — `/compact` keeps the implementer sharp. Then `/plan-6`. Type: `compact` then `/the-flow`, or `implement`.
> *If READY (Full)*: next is `/plan-5` for Phase 1's tasks (compact first if you like). Type: `compact` or `tasks`.

### `awaiting-5` → after phase tasks
> [the-flow] ◆─◆─◆─◆─◇─◇─◇
>
> **Where we are**: Phase `<N>` tasks are tabled (`tasks/<phase>/tasks.md`) with success criteria.
> Did you notice the first task's done-when is `<criterion>`? That's the bar the implementer codes to.
> **Heads-up for the next step**: `/plan-6` runs a **Boot→Interact→Observe pre-flight** first — it proves the app actually runs before a line of code. No harness here? It just reports `UNAVAILABLE` (not an error) and falls back to standard testing.
> **Companion option (optional)**: you can build with a live reviewer — `/plan-6-v2-implement-phase-companion` runs a `code-review-companion` (a parallel `minih` agent) that reviews every commit and **supersedes `/plan-7`**. Want a different watcher (security/perf) or a parallel **worker** (e.g. a `docs-writer`)? Spin it up with `minih run <slug>` and I'll track it on the flight view. I don't run minih myself — I just narrate and record it.
> Next, type one of:
>
> `/plan-6-v2-implement-phase --phase "<Phase N: Title>" --plan "<plan path>"`  *(plain)*
> `/plan-6-v2-implement-phase-companion --phase "<Phase N: Title>" --plan "<plan path>"`  *(live review — recommended)*

### `awaiting-6` → after a phase
*(On return)*:
> [the-flow] ◆─◆─◆─◆─◆─◇─◇
>
> **Where we are**: Phase `<N>` landed — `<what it delivered>`; acceptance `<AC refs>` met. `/plan-6a` tracked progress for you.
> You may have seen a retro prompt `[s/t/p/e/d/a]` at the end — that's the harness **draining** the session's friction notes; default `[a]` saves them all. (Silenced if `docs/harness/.disabled` exists.)
> Did you notice `<one execution-log discovery>`? Worth carrying forward.
> *More phases (Full)*: this is a between-phase seam — `/compact` now, then `/plan-5` for Phase `<N+1>`. Type: `compact` or `next phase`.
> *Last phase / Simple*: next is review — `/plan-7` (skip if a companion already reviewed every commit). Type: `review`.

### `awaiting-7` → after review
> [the-flow] ◆─◆─◆─◆─◆─◆─◇
>
> **Where we are**: review written (`reviews/<file>`) — verdict `<…>`.
> Worth knowing: `/plan-7` is the **inferential / eyeball** tier; `/plan-2d` earlier was the **computational** tier. Together they cover what each can't.
> Did you notice `<one finding>`? `<It routes back to implement | it's clean>`.
> *Findings*: fix, then re-run `/plan-7`. Type: `fix`.
> *Clean*: next is the merge analysis — `/plan-8`. Type: `merge`.

### `awaiting-8` → at merge
> [the-flow] ◆─◆─◆─◆─◆─◆─◇
>
> **Where we are**: `/plan-8` produced the merge analysis. A harvest reflection across the whole plan fires here (idempotent).
> Read the merge plan, then type **`PROCEED`** to execute or **`ABORT`** to hold. I'll mark the flow complete once it merges.

### `complete`
> [the-flow] ◆─◆─◆─◆─◆─◆─◆
>
> 🎉 That's the full loop: spec → plan → tasks → code → review → merge. The harness captured friction along the way; if you haven't, `/harness-3-retro --harvest` gives a curated cross-plan view. Nothing else queued — re-run `/the-flow` any time to start a new one.

### Optional branch mentions (one-liners, surfaced at their seam — never new stages)
- `awaiting-1a`: **deep-research** with your tool of choice (online agent **or** coding harness) before `/plan-1b`.
- `awaiting-1b`/`awaiting-3`: **`/plan-3a`** — capture an ADR if a big architectural decision is being made.
- `awaiting-1b`: a **prework / decision gate** if the team needs sign-off before building.
- `awaiting-7`: the **fix loop** — review findings route back to `/plan-6`, then re-run `/plan-7`.
- any stage with a `docs/domains/` registry: **domains** — `/plan-v2-extract-domain` to formalise a concept.
- any stage: **`/util-0-v2-handover`** — generate a handover doc if you're passing the baton to another agent/session.

---

## The `/compact` resume handshake

```
the-flow (at a compact seam): "... type /compact then /the-flow (recommended), or /plan-3."
        ▼
USER types:  /compact       ← CLI built-in; wipes conversation context. the-flow CANNOT run it.
        ▼
USER types:  /the-flow      ← no args; conversation memory is gone.
        ▼
the-flow:  glob docs/plans/*/.the-flow-state.json (status:active)
           → finds the flow @ current_stage
           → discover the stage artifact (exists, unchanged since checkpoint)
           → NOT a new artifact ⇒ idempotent: re-print the pending guidance, do not advance
        ▼
USER runs the next /plan-* … then /the-flow → discovers the new artifact → advances.
```

**Key properties**:
- `/compact` at a seam is a **no-op for state** — `the-flow` re-enters the *same* stage idempotently and re-states the next command. No double-advance, no lost place.
- The phrasing is always: **"type `/compact` yourself, then re-run `/the-flow`."** You never claim to compact.
- Works identically whether or not the user actually compacts — state on disk is the single source of truth.

---

## Harness affordances (make the loop legible)

**Sentinel**: before any harness narration, check `docs/harness/.disabled`. If present, **silently skip** all harness mentions.

- **Boot gate (before `/plan-6`)**: set the expectation in `awaiting-5` — `/plan-6` runs a Boot→Interact→Observe pre-flight; `UNAVAILABLE` is not an error, it falls back to standard testing.
- **Observe (during work)**: silent. Mention once that the harness logs friction in the background; you don't call it.
- **Drain (after `/plan-6`)**: explain the `[s/t/p/e/d/a]` retro prompt the user just saw — it drains the session's friction notes; default `[a]` saves all.
- **Harvest (at `/plan-8` / `complete`)**: a cross-plan reflection; suggest `/harness-3-retro --harvest` if it hasn't fired.

---

## Flight plan — `the-flow.json` (source of truth) + `the-flow.md` (rendered)

Every run maintains a **flight plan**: `docs/plans/<ord>-<slug>/the-flow.json` (canonical DAG) and `the-flow.md` (the vertical mermaid, **generated from** the JSON). The one-line rail is the JSON's glanceable twin.

- **Schema**: `references/flight-plan.schema.json` (the full node + `agents[]` contract).
- **Worked example to copy**: `references/flight-plan.template.json` + `references/flight-plan.template.md`.

**Hand-crank cadence (no CLI tooling yet — you are the generator). Every turn, after deciding the narration:**

1. **Mutate the JSON** for what just happened: set the completed node `status: done`, stamp `ran_at`, capture the user's **verbatim** `user_input`, write the `note`, append produced `artifacts[]`; advance `cursor`/`recommended_next`.
2. **Reveal/refine the future**: at `/plan-3`, replace the `assumed` phase placeholder with real `known` phase nodes (one per phase) + recompute `milestones_total`. Add conditional `assumed` nodes (fix-loops) as `branch_of` the relevant phase.
3. **Regenerate** `the-flow.md` from the JSON, then the rail.
4. **Self-check** (no validator): required fields present, every `next` id exists, exactly one `cursor`, no backwards status moves.

**Status taxonomy → colour**: `done` 🟩 green · `in_progress` 🟧 orange · `blocked` 🟥 red · `known` 🟦 blue-grey (*designed* future, e.g. phases locked by `/plan-3`) · `assumed` ⬜ dashed grey (*speculative* future, e.g. a conditional fix loop). Transitions: `assumed → known` (at `/plan-3`) → `in_progress` → `done`; any active node → `blocked` → back to `in_progress`.

**Render rules for `the-flow.md`** (see schema + template for the worked form):
1. `flowchart TD` (vertical); emit the 5 `classDef`s (done/wip/blocked/known/assumed).
2. **Spine** = `type ∈ {research, spec, plan, phase, merge}` linked solid `-->` in `next` order.
3. **Excursions** (`branch_of` set: deep-research, **each** workshop, backpressure, fix-loop) = dotted `-.->` from their `branch_of`, rejoining at the spine. **Every workshop is its own node** — never collapse a loop into one blob.
4. Each node `:::<class>` from its `status`.
5. **User bubbles**: for every node with `user_input`, emit a `said`-class flag node (`>"🗣 …"]`) dotted (`-.-`) to it — verbatim, nothing hidden.
6. **Agents**: `kind:companion` (`render:wrap`) → a **subgraph that wraps** its `covers[]` phases, styled with the companion colour; `kind:worker` (`render:side`) → a `worker`-class side-node linked `-. builds .->` to its `covers[]`.
7. Legend line beneath (done/wip/blocked/known/assumed + 🗣 user input + companion + worker).

> **Invariant**: never hand-edit `the-flow.md` as the primary — it is always a function of `the-flow.json`. This is what lets future first-class tooling drop in (production/validation/rendering off this stable contract — currently out of scope).

---

## What you do NOT do (recap of invariants)

- ✅ **Print every command first**, then offer to run `/plan-*` for the user on their go-ahead. ❌ Run anything without printing + offering first; ❌ run more than the one offered step per turn.
- ❌ Run `/compact`, or merge without an explicit typed `PROCEED`. ✅ Print them; recommend the `/compact` re-run handshake; execute the merge only on `PROCEED`.
- ❌ Gate, score, block, or make anything mandatory. ✅ Every branch is optional.
- ❌ Run `minih`. ✅ Narrate the companion/worker affordance + record `agents[]`.
- ❌ Invent an insight or hand-edit `the-flow.md`. ✅ Ground every insight in the artifact; regenerate the md from the json.

**Re-entry is always**: you run the accepted command inline (or the user runs it / `/compact`s), then the flow continues from durable state — discover the artifact, narrate, hand-crank the flight plan, print-and-offer the next move. Re-run `/the-flow` if context was cleared.
