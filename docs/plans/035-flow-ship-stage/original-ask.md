# Original Ask — 035-flow-ship-stage

**Captured**: 2026-06-19
**Flow**: the-flow (guided)

## Verbatim request

> do a plan. keep an eye out for this please [image: the-flow hand-writing
> `.the-flow-state.json` via Create/Edit file tools] and report — i'm surprised
> it's still creating the flow state like this, it should be deterministic as
> part of harness now, so maybe it still lingers in the flow prompting itself.
> identify and report if it happens please.

Plan subject resolved via clarifying question → **Ship-stage redesign**.

## Resolved intent

Replace the-flow's merge-centric final stage (`8 merge`) with a `ship` verb:
push the branch and open a PR using repo guidance (PR template / `CONTRIBUTING`
/ `CODEOWNERS` / default base) when present, watch the PR's CI checks, and
report failures (offering a `fix-loop` excursion on red). Demote the existing
local-merge upstream-reconcile analysis to a **conditional** excursion fired
only when the base branch has meaningfully diverged; make the actual merge
**optional** (platform auto-merge or a separate PROCEED-gated step). Best-effort
throughout: `gh` degrades gracefully, opening a PR stays behind an explicit
confirm gate, no new gates/scores/thresholds.

## Note

This plan was spawned alongside a separate diagnostic finding (the
`.the-flow-state.json` hand-write — captured in the session report). That
finding is its own concern and is **not** in this plan's scope.
