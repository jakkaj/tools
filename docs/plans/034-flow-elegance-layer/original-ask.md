# Original ask — flow-elegance-layer
**Captured**: 2026-06-17T22:02:51Z  ·  **By**: /the-flow

> get a new flow up, this is a detiled task! we should also dogfood our new changes as we write the flow itself, even if the flow prompts aer still old.

## Context (derived this session — not part of the verbatim ask)

The work is the **lean subset** of [`research-dossier.md`](./research-dossier.md) (promoted from `scratch/elegance.md`), per this session's recommendation — **not** the maximalist doc verbatim. The dossier translates the Ponytail "stop at the first rung that holds" idea into an elegance layer for the-flow. Build only the lean subset:

- **One** shared elegance doctrine, single home, **referenced not copied** (artifact rule → `00-routing.md` § Shared conventions; narration rule → tighten the existing Seam Digest in `coach.md` **in place**, not a parallel section).
- New narration wins: **summon commands** (`recap` exists; add `options`/`why`/`details`/`warnings`), **per-section budgets**, **no "nothing flagged — clean" line** (silence = clean), **gated "why this matters"** (first-exposure / resume-ambiguity / on request).
- **One line** per artifact stage (`20-plan`, `25-workshop`, `50-phase-tasks`, `60-implement`, execution-log) — "build contract, not thesis; tables/schemas/diffs over prose" — not a full doctrine block each.
- **The constraint is OUTPUT tokens, not flow file size.** Elegance targets what the flow makes the model *emit* (generated plans, task tables, narration, Seam Digests, execution logs, reviews) — expensive output tokens. The flow's own on-disk markdown is *input* (cheap to read); adding guidance to it is fine and is **not** to be minimized for size now. Shrinking the flow's on-disk footprint is a **separate later pass — out of scope here.** Prefer one referenced doctrine home over copy-paste for **DRY/maintainability + adherence** (more rules ≠ better following), not to save input tokens.

**Dogfood directive**: apply the new elegance principles to the artifacts this flow produces (fewest phases, tables over prose, tight narration) even though the installed flow prompts don't yet carry the doctrine. The `fewest-phases` plan principle is already live (committed `12271f4`).

## Decisions (grill session, 2026-06-18 — these are settled; the plan implements them)

- **Scope**: both artifact-side (plans / tasks / workshops / execution logs) **and** narration-side (`coach.md`), as **one Simple-mode pass** — not split into phases (no dependency boundary between them; splitting would be the over-decomposition the `fewest-phases` rule outlaws).
- **Design heart = the evidence-backed lever ranking** (see *Evidence addendum* in `research-dossier.md`): lead with **(1) default-omit + pull-based summons**, **(2) few-shot lean exemplars**; **(3)** coarse human-unit budgets as backup; **(4) add NO more imperative "be terse" rules** — that's the tier-4 failure mode the existing soft rules already prove.
- **Constraint**: reduce emitted **OUTPUT** only. The flow's on-disk size is *input* (cheap) and **stays** — slimming it is a separate later pass.
- **Non-goals**: no enforcement gates / scores / thresholds; no flow-architecture / Registry / Graph / flight-plan-render restructure; no harness or utility-skill changes; no parallel "Elegant Flow" section duplicating the Seam Digest; no copy-pasted doctrine (one referenced home).
- **Validation = best-effort. NO test, NO proof, NO acceptance gate.** Jordan (human) gives feedback in future if output is still too verbose. Spec **Testing Strategy = Manual/best-effort** so plan gate G6 doesn't demand tests.
- **Safety floor**: default-omit applies to *decorative prose only* — never to must-see / safety fields (gates, `PROCEED`, file paths, failed-gate / `⚠️ GAP` callouts). (Mirrors Ponytail's "never simplify away validation/safety".)
