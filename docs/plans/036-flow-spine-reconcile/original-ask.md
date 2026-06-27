# Original ask — flow-spine-reconcile
**Captured**: 2026-06-27  ·  **By**: /the-flow

> set up a flow for this work, run explore stage and plan, simple mode pelase default others then valite, all in a row wihtout stopping to ask. f there are questions along the way hold htem until the end.

**Substantive work** (the "this work" referenced above, carried from the conversation that preceded this flow):

> Add a first-class **maintenance verb** to `the-flow` (working name `sync` / `reconcile`) that the guided engine **auto-fires on every entry** *and* that anyone can invoke directly. It **declaratively reconciles the flight plan** (`the-flow.json` → `the-flow.md`) against current knowledge — every **past, present, and future** phase + workshop from the plan, plus all **harness chores/seam nodes** from `eng-harness-flow` (boot, backpressure, observe reminders, retro-drain, harvest) — so the spine is always complete **without the user having to prompt for it**. Idempotent, advisory, best-effort, CLI-driven; respects the dedup/ownership contract (the-flow emits seam *nodes*, `eng-harness-flow` owns the chore *flag*; dedup on the `--hook` token). The standing requirement was already recorded in `CLAUDE.md`/`AGENTS.md`; this flow builds the behaviour into the skill.
