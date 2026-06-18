# Workshop: Think Deep, Emit Lean — the elegance ethos of the-flow

**Status**: Approved (ethos shipped — 034 + artifact-side follow-up)
**Type**: Other (philosophy / working reference)
**Target Proof**: Preferred Direction
**Plan**: 034-flow-elegance-layer
**Spec**: `flow-elegance-layer-plan.md` § Business Specification
**Decision owner**: user (confirmed across 034 + this follow-up)

> This note is itself dogfood: decision-focused, tables over prose, no section that doesn't change how you'd write the flow. If a line here doesn't pass its own seven-function test, it shouldn't be here.

## Decision Needed

How should every stage of the-flow decide what to *put on the page* — in its narration **and** in the artifacts it writes (dossiers, workshops, plans, task tables, logs, reviews)? The flow was emitting like it was paid by the word; the thinking was never the problem, the **output** was.

## Selected Direction — the ethos

**Think deep, emit lean.** Reason as hard as the stage warrants; then emit only what a future human or agent needs to *act safely*. **Artifacts are contracts, not transcripts.**

The split is the whole idea: depth is free and encouraged *internally* (subagents, file sweeps, alternative-weighing); the emitted token is expensive and earns its place. Leanness is achieved **by construction** — the shape of the prompt makes the lean output the natural one — never by scolding the model to "be terse."

| The four doctrine moves | What it means in practice |
|---|---|
| **Seven-function line test** | A line stays only if it ① changes a decision · ② constrains an implementation · ③ proves a behaviour · ④ exposes a risk · ⑤ records evidence · ⑥ preserves intent · ⑦ enables the next action. Else cut it. |
| **Build contract, not thesis** | Tables, schemas, diffs over prose. *State* the contract; don't argue for it. One worked example beats a paragraph describing one. "Fewest phases that hold" is the same move applied to structure. |
| **Link, don't copy** | When an upstream artifact holds the detail, reference it (path / finding-id / AC-id). A downstream artifact carries decisions + the links that prove them — not a re-summary of its sources. |
| **Safety floor** | Default-omit applies to *decorative prose only*. Must-see fields are never compressed: gate verdicts, `**Status**`, `PROCEED`/`ABORT`, file paths, `⚠️ GAP` callouts, lifted alarms. Unsure → keep. |

## Why structure beats imperatives (the lever ranking)

The ethos is grounded, not vibes. Ranked by what actually cuts output (Perplexity deep-research, `research-dossier.md`):

| Tier | Lever | Strength | Where it lives |
|---|---|---|---|
| 1 | Default-omit + pull-based / progressive disclosure | **Strongest** — the omitted thing costs nothing to omit | summons table; curated dossier; omit-when-empty |
| 2 | Few-shot lean exemplar (lean variant **last**, recency) | Strong | the one worked verbose→lean Seam Digest pair |
| 3 | Coarse human-unit budgets | Moderate | per-facet Seam-Digest budget (1–2 / 0–3 / 1 / 0–1) |
| 4 | Imperative "be terse / comprehensive" | **Weakest** — RLHF-buried, instruction-overload | *avoided*; existing tier-4 line left as-is, never reinforced |

The corollary that drove the artifact-side follow-up: **the bloat was being *incentivised* by the prompts themselves** ("comprehensive research document", "detailed design document… in depth", "thorough specification"). Removing those output-facing words is a tier-1 move — it changes the instruction, it isn't another weak plea.

## Two surfaces, one ethos

| Surface | Lever applied (034 + follow-up) |
|---|---|
| **Narration** (`coach.md`) | pull-based summons (`recap`/`options`/`why`/`details`/`warnings`), gated why-beat, silence-is-the-all-clear, one lean-last few-shot, per-facet budget |
| **Artifacts** (stage modules) | `§ Artifact Elegance` is the **single** doctrine home; each big-emitter stage cites it in one line; `10-explore` dossier is "curated decision aid, not a warehouse"; workshops are "decision-focused notes"; link-don't-copy across the plan |

## Rejected — what the vibe is *not*

| Rejected | Why |
|---|---|
| A second `artifact-density.md` doctrine file | Duplicates the one home (`§ Artifact Elegance`) — the exact DRY sin the doctrine forbids |
| Hard per-artifact line-count budget table | Numeric floors read as compliance gates; against best-effort. Kept one coarse tier-3 budget only |
| An artifact regression/test suite with metric targets | "No test, best-effort, no proof required" — measurement apparatus is ceremony here |
| More "be terse" imperatives | Tier-4, weakest; piling them on fights the RLHF verbosity bias instead of routing around it |
| Compressing anything on the safety floor | Leanness must never cost a must-see field |

## Consequences (the vibe, lived)

- **Silence means clean.** No "nothing flagged" filler — an empty Watch-out facet just disappears.
- **Depth is invisible, not absent.** The flow still launches the agents and reads the files; you just don't see the transcript.
- **Best-effort, never enforced.** No gate, no score, no Status flip ever came from this ethos. Elegance by construction, not by audit.
- **Dogfood is the proof.** These plans, logs, and this note are written the lean way — if the flow can't keep its own house lean, the doctrine is just words.

## Open Questions

| Question | Blocks? | Next step |
|---|---|---|
| Should the curated-dossier shape get the full lean *template* (not just the citation + de-bloat)? | No | the larger artifact-exemplar pass, still deferred — a future flow, not this one |
| Worth a worked lean-vs-verbose *plan/task-table* exemplar (the narration has one; artifacts don't)? | No | same deferred pass; flagged as Non-Goal in the 034 plan |
