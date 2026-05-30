# the-flow — User Experience Walkthrough

**What this is**: a concrete, turn-by-turn picture of what using `/the-flow` *feels like* — every command the user types, every reply the skill gives back, and where the seams (`/compact`, optional branches, harness prompts) land. Illustrative scenario, real narration (drawn from [workshop 001](./workshops/001-narration-scripts-and-compact-contract.md)).

> **Reading key**
> 🧑 **USER** = what the human types · 🤖 **the-flow** = what the skill says back · ⚙️ = a `plan-*` skill runs (its own output, summarised) · 💾 = state written to `.the-flow-state.json` · ✂️ = a `/compact` seam · 🟣 = harness loop fires
>
> **Host sigil**: every 🤖 turn really opens with the one-line banner `✦━━ the-flow ━━✦` so you always know it's the guide talking, not a `plan-*` skill. It's shown on the first turn below and then omitted here for readability — assume it on every 🤖 line.

---

## The rhythm in one picture

```
🧑 /the-flow ──► 🤖 "what do you want to build?" ──► 🧑 answer
                                                          │
                                          💾 state written, folder created
                                                          │
        ┌─────────────────────────────────────────────────┘
        ▼
   🤖 "type this: /plan-1b …"  ──►  🧑 runs ⚙️/plan-1b  ──►  🧑 /the-flow
        ▲                                                        │
        │                                              🤖 reads the new artifact,
        │                                                 says ONE insight,
        └──────────── repeat per stage ◄──────────────────  offers next move (+ ✂️ at seams)
```

You only ever type two kinds of thing: **a `/plan-*` command the-flow hands you**, then **`/the-flow`** to come back. That's the whole loop.

---

## Scenario

> A developer wants to **add a `POST /api/widgets` endpoint** to an existing app. They've never used the SDD pipeline and don't know which command is which. They just run `/the-flow`.

The mode (Simple vs Full) gets chosen inside `/plan-1b`; this example lands on **Full** (CS-3, 2 phases) to show every seam. A Simple-mode run would just skip `/plan-5` and the per-phase loop.

---

## Turn-by-turn

### 1 · Fresh start

🧑 **USER**
```
/the-flow
```

🤖 **the-flow** *(no active state found → fresh start)*
> ✦━━ the-flow ━━✦
> Welcome — I'm your guide through the SDD plan flow. Tell me in a sentence what you want to build or change, and I'll turn it into the right first step, explain why each stage matters, point out the one thing worth noticing in what each stage produces, and tell you exactly what to type next. You stay in control — nothing merges without your say-so, and I'll never run code changes for you.
>
> **What do you want to work on?** *(Just describe it. If it touches code you don't fully understand yet, I'll start us with research (`/plan-1a`); if the ask is clear, we'll go straight to the spec (`/plan-1b`). Unsure → just describe it and I'll choose.)*

🧑 **USER**
```
add a POST /api/widgets endpoint that creates a widget with a name and colour
```

💾 *the-flow allocates ordinal `005`, slug `api-widgets`, creates `docs/plans/005-api-widgets/`, **logs the verbatim ask to `original-ask.md`**, writes `.the-flow-state.json` (`current_stage: awaiting-1a`).*

🤖 **the-flow**
> Got it: **add a POST /api/widgets endpoint…** — logged that to `original-ask.md` so we keep your original wording. The ask is clear enough to spec directly — but it touches an existing API I don't know the shape of, so I'd actually start with a quick research pass. Type this next:
>
> `/plan-1a "how are API endpoints structured in this app?"`
>
> When it finishes, come back and run **`/the-flow`** — I'll pick up right here.

---

### 2 · After research  *(stage: `awaiting-1a`)*

🧑 **USER** runs ⚙️ `/plan-1a "…"` → 8 subagents → writes `research-dossier.md`. Then:
```
/the-flow
```

🟣 *`harness-2-observe` ran silently during the research; nothing for the user to do.*

🤖 **the-flow** *(discovers `research-dossier.md`, picks one finding)*
> **Where we are**: research is done (`research-dossier.md`) — that's evidence, not code yet.
> Did you notice **every endpoint goes through `src/api/validate.ts` before the handler**? That matters because our new endpoint should reuse that validator, not roll its own.
> **Optional — go deeper?** If anything's still fuzzy you can deep-research it with your tool of choice — an online agent (`/deepresearch`, Perplexity) or your coding harness. The dossier looks complete enough here, so I'd skip it.
> **Then a seam**: a good spot to run `/compact` — clears the research chatter and keeps the spec sharp; I'll resume right here afterwards (my state's on disk). Then we write the spec.
>
> Your move: `deep-research` (your tool), `compact` then `/the-flow` *(recommended)*, or straight to `/plan-1b`. Either way, `/plan-1b` is the next real step.

✂️ 🧑 **USER**
```
/compact
```
*(conversation context is cleared — the-flow's memory of this session is gone, but the state file isn't)*
```
/the-flow
```

🤖 **the-flow** *(scans `docs/plans/*/.the-flow-state.json`, finds `005-api-widgets` @ `awaiting-1a`; the spec doesn't exist yet → idempotent, re-states the move)*
> Picking back up on **api-widgets** — research is in, spec is next. Type:
>
> `/plan-1b "POST /api/widgets to create a widget (name, colour)"`
>
> Then run **`/the-flow`**.

---

### 3 · After the spec  *(stage: `awaiting-1b` — the busiest seam)*

🧑 **USER** runs ⚙️ `/plan-1b "…"` → asks the testing/mode questions → writes `api-widgets-spec.md` (CS-3 → **Full**). Then:
```
/the-flow
```

🤖 **the-flow** *(reads the spec: CS, mode, workshop opportunities)*
> **Where we are**: the spec is written — **CS-3 → Full Mode**. The spec is the contract the plan will build to.
> Did you notice it flagged **2 Workshop Opportunities** (the validation rules and the error-response shape)? That matters because nailing those now is cheaper than discovering them mid-build.
> Before we architect, you have up to three optional moves — all skippable, none gate anything:
> 1. **`/plan-2c`** — workshop a tricky topic first (the spec flagged 2). Worth it when a design choice is still fuzzy.
> 2. **`/plan-2d`** — backpressure survey: can we *prove* this works deterministically before building? Advisory; surfaces an optional Phase 0.
> 3. **`/compact`** — context hygiene before the architect (recommended at this seam).
>
> Recommended path: `compact` then `/plan-3`. Type one of: `compact`, `workshop`, `prove it`, `architect`. Unsure → `compact` then `architect`.

🧑 **USER**
```
prove it
```

🤖 **the-flow**
> Good call — let's check we can prove it. Type:
>
> `/plan-2d-backpressure-survey docs/plans/005-api-widgets`
>
> Then **`/the-flow`**.

---

### 4 · After the backpressure survey  *(stage: `awaiting-2d`)*

🧑 **USER** runs ⚙️ `/plan-2d` → writes `backpressure-coverage.md`. Then:
```
/the-flow
```

🤖 **the-flow** *(the backpressure payoff)*
> **Where we are**: backpressure coverage written — **Certainty: Partial; recommended Phase 0: add a contract test for the 400-on-bad-colour path.**
> What this means: the happy-path (`201` on valid input) already has an `EXISTS` sensor, but the *rejection* behaviour is `BUILDABLE` — without that test you'd be eyeballing it. It's **advisory** — `/plan-3` will *consider* that Phase 0, never be forced into one.
> Next: `/plan-3`. Type: `architect` or `compact`.

✂️ 🧑 **USER**
```
compact
```
```
/the-flow
```

🤖 **the-flow**
> Back on **api-widgets** — survey's done, time to architect. Type `/plan-3-v3-architect docs/plans/005-api-widgets/api-widgets-spec.md`, then **`/the-flow`**.

---

### 5 · After the plan  *(stage: `awaiting-3`)*

🧑 **USER** runs ⚙️ `/plan-3` → inline gates + auto-runs `validate-v2` + flight plan → writes `api-widgets-plan.md` (**Status: READY**, 2 phases). Then:
```
/the-flow
```

🤖 **the-flow** *(reads plan status + gate matrix)*
> **Where we are**: the plan is written — **Status: READY** (all 7 gates pass), 2 phases. `validate-v2` already auto-ran and was clean.
> Did you notice **Phase 0 from the survey got folded in as the first task of Phase 1**? Good — the rejection test is now planned, not improvised.
> We're in Full Mode, so next is `/plan-5` to break Phase 1 into tasks. One seam first: `/compact` keeps the next steps sharp. Type: `compact` then `/the-flow`, or `tasks`.

🧑 **USER**
```
tasks
```

🤖 **the-flow**
> Type:
>
> `/plan-5-v2-phase-tasks-and-brief --phase "Phase 1: Route & Validation" --plan "docs/plans/005-api-widgets/api-widgets-plan.md"`
>
> Then **`/the-flow`**.

---

### 6 · After phase tasks  *(stage: `awaiting-5`)*

🧑 **USER** runs ⚙️ `/plan-5` → writes `tasks/phase-1/tasks.md` + flight plan. Then:
```
/the-flow
```

🤖 **the-flow**
> **Where we are**: Phase 1 tasks are tabled with success criteria.
> Did you notice the first task's done-when is **"`POST /api/widgets` with a bad colour returns `400` with `{error}`"**? That's the bar the implementer codes to — straight from the backpressure survey.
> Next: implement this phase. Type:
>
> `/plan-6-v2-implement-phase-companion --phase "Phase 1: Route & Validation" --plan "docs/plans/005-api-widgets/api-widgets-plan.md"`
>
> *(or plain `/plan-6-v2-implement-phase` without live review)*. Then **`/the-flow`**.
>
> Heads-up for what happens first ↓ — before any code, `/plan-6` runs a **Boot→Interact→Observe pre-flight**: it proves the app actually runs (`just dev` healthy) before a line is written. If there's no harness it just says `UNAVAILABLE` and falls back to normal testing — not an error.

---

### 7 · After the phase  *(stage: `awaiting-6`)*

🧑 **USER** runs ⚙️ `/plan-6-companion` → 🟣 boot pre-flight → implements → `/plan-6a` tracks progress → 🟣 end-of-phase `harness-3-retro --drain` shows the `[s/t/p/e/d/a]` prompt. Then:
```
/the-flow
```

🤖 **the-flow**
> **Where we are**: Phase 1 landed — the route, the validator reuse, and the 400-rejection test are all in; acceptance AC-1…AC-3 met. `/plan-6a` tracked it for you.
> You may have seen a retro prompt `[s/t/p/e/d/a]` at the end — that's the harness **draining** the session's friction notes; default `[a]` saves them all. (Silenced if `docs/compound/.disabled` exists.)
> Did you notice the companion flagged **the colour field accepts any string**? Worth carrying into Phase 2.
> This is a between-phase seam — `/compact` now, then `/plan-5` for Phase 2. Type: `compact` or `next phase`.

✂️ 🧑 **USER** `compact` → `/the-flow` → 🤖 "Back on api-widgets — Phase 2 tasks next: `/plan-5 --phase "Phase 2: …"`…"

*(Phase 2 repeats steps 6–7: `/plan-5` → `/plan-6` → `/the-flow`. On the last phase, the companion's final-phase debrief auto-fires `harness-3-retro --harvest` 🟣.)*

---

### 8 · After review / at merge  *(stages: `awaiting-7` → `awaiting-8`)*

🧑 **USER** (last phase done) runs ⚙️ `/plan-7` (or the companion already covered it) → `/the-flow`:

🤖 **the-flow**
> **Where we are**: review is clean. Worth knowing: `/plan-7` is the **eyeball** tier; the `/plan-2d` survey earlier was the **computational** tier — together they cover what each can't.
> Next is the merge analysis — `/plan-8`. Type: `merge`.

🧑 **USER** runs ⚙️ `/plan-8` → 🟣 harvest reflection → `/the-flow`:

🤖 **the-flow**
> **Where we are**: `/plan-8` produced the merge analysis.
> Read the merge plan, then type **`PROCEED`** to execute or **`ABORT`** to hold. I'll mark the flow complete once it merges.

---

### 9 · Complete  *(stage: `complete`)*

💾 *state `status: complete`.*

🤖 **the-flow**
> 🎉 That's the full loop: research → spec → backpressure → plan → tasks → code → review → merge. The harness captured friction along the way; if you haven't, `/harness-3-retro --harvest` gives a curated cross-plan view. Nothing else queued — re-run `/the-flow` any time to start a new one.

---

## What the user never had to know

- **Which command comes next** — the-flow always hands them the exact line.
- **That `/plan-2c`, `/plan-2d`, or `/compact` even exist** — surfaced at the right seam, always optional.
- **What the purple harness prompts meant** — explained in plain language as they fired.
- **How to resume after `/compact`** — they just re-ran `/the-flow`; the state file did the rest.

## What the user was always in control of

- Every code-changing and merge command — **they** typed it; the-flow only ever *suggested*.
- Skipping any optional branch (`workshop` / `prove it` / `compact`) with no penalty.
- Stopping any time — the flow resumes from disk whenever they come back.

---

> This walkthrough is illustrative documentation, not a spec. The authoritative per-seam copy + state machine live in [workshop 001](./workshops/001-narration-scripts-and-compact-contract.md); the buildable contract is in [the-flow-plan.md](./the-flow-plan.md).
