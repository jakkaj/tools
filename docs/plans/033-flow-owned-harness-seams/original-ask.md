# Original ask — flow-owned-harness-seams
**Captured**: 2026-06-16T10:03:49Z  ·  **By**: /the-flow

> please recap how the flow works with the eng flow in `eng-harness-flow`. this skill has
> various entrypoints that we need to honor, im finding it is not being honored, so i want
> to see what it looks like baking it in more seriously to the flow json that is produced.
> do the inversion now, where would it be baked in. It's skipping backpressure checks, it
> should be draining and presenting retros from the harness per phase etc.

> i think we should move them up to the flow only, not inside the other commands? this way
> the commands maintain single responsibility (as the rules state for the flow itself)... as
> we consider the flow as the orchestration element. we might give it another file that it
> can reference on where and when to run the eng flow? also the eng flow may not be installed
> in which case it just goes along about its business without it.

> we should also ensure that next time the harness flow skills change or the seams change,
> we can easily update ourselves here.

> na, just make sure we document our process, and where to update from for next time, i.e.
> in the plan when we write it. for now, start a new the-flow and let's track it all, no need
> to do any more "physical" tracking than that.

---

**Distilled intent**: Invert the harness integration in `the-flow` so the engineering-harness
seams are **first-class, engine-owned orchestration** rather than side-effects buried inside
the stage sub-skills. Pull every `/eng-harness-flow --event …` invocation **up out of**
`20-plan.md` / `60-implement.md` / `80-merge.md` (single-responsibility verbs) and **into a
single flow-owned reference** (`references/harness-seams.md`) that owns *where & when* each
seam fires, the two-layer detection, the node-emission rule, and the not-installed silent path.
Emit per-phase `harness-retro` nodes into `the-flow.json` whenever the router is **installed**
(status reflects provisioning — never silently vanish). Graceful no-op when the router is
absent. Document the **resync process + upstream source-of-truth** (the installed
`eng-harness-flow` SKILL.md §Parameter contract + §envelope) **inside the plan doc** — no
extra scripts or physical tracking; `the-flow`'s own artifacts are the tracking.
