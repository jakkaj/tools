# Fix Tasks: Simple Mode

Apply in order. Re-run review after fixes.

## Critical / High Fixes

### FT-001: Reconcile backpressure fold-in routing with the `plan` verb contract
- **Severity**: HIGH
- **File(s)**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/stages/20-plan.md
- **Issue**: `00-routing.md` still routes `backpressure-coverage.md` back through `plan` and promises the coverage is folded in, but `20-plan.md` no longer consumes that artifact after the harness-blind strip.
- **Fix**: Choose one contract and update all affected prose:
  1. Restore a harness-blind optional refinement input in `20-plan.md` for `${PLAN_DIR}/backpressure-coverage.md`, then keep the Graph re-plan route; or
  2. Treat backpressure coverage as standalone advisory output and remove "fold in" / "re-run plan to fold in" promises from `00-routing.md`, `coach.md`, `harness-seams.md`, `flight-plan.template.*`, `getting-started.md`, and the plan docs.
- **Patch hint**:
  ```diff
  - `awaiting-backpressure` ... → **plan** (re-run, folds the coverage in)
  + `awaiting-backpressure` ... [chosen behavior: either re-run plan with an explicit coverage input, or present coverage as advisory output only]
  ```

## Medium / Low Fixes

### FT-002: Make installed-but-unprovisioned node emission internally consistent
- **Severity**: MEDIUM
- **File(s)**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/00-routing.md
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.schema.json
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/getting-started.md
  - /Users/jordanknight/github/tools/docs/how/the-flow-harness-seams.md
- **Issue**: The seam contract says installed routers emit nodes that never vanish per phase, but also says unprovisioned repos should not stamp per-phase ghost nodes.
- **Fix**: Pick one behavior and align every surface:
  - Emit dormant/noop nodes when installed; or
  - Omit per-phase nodes while unprovisioned and keep only the one calm line.
- **Patch hint**:
  ```diff
  - Emit the harness node when the router is installed ... never by making the node vanish per phase.
  + [Single chosen rule, with node/rail/narration consequences stated consistently.]
  ```

### FT-003: Clarify or expand the flight-plan template's per-phase seam shape
- **Severity**: MEDIUM
- **File(s)**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.json
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/flight-plan.template.md
- **Issue**: The template shows six phases but only one boot node and one phase retro node. It also omits `--json` from router commands even though seam handling depends on the router envelope.
- **Fix**: Either expand the example to include per-phase boot/retro siblings, or mark it as abbreviated and state generated flight plans must follow `harness-seams.md`; include `--json` where an envelope is expected.
- **Patch hint**:
  ```diff
  - "command": "/eng-harness-flow --hook pre-flight ..."
  + "command": "/eng-harness-flow --hook pre-flight ... --json"
  ```

### FT-004: Resolve old-router fallback wording
- **Severity**: LOW
- **File(s)**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/harness-seams.md
- **Issue**: The docs say `--event` is a fallback for older routers, but the emitted commands use `--hook` and no fallback version probe is specified.
- **Fix**: Either specify a fallback emission path to mapped `--event` commands, or state that hook-aware routers are required and older routers should trigger a reinstall/runtime-dependency message.
- **Patch hint**:
  ```diff
  - If only an older `--event`-only router is present, the `--event` alias row above is the fallback...
  + [Either define the fallback probe/emission behavior, or state old routers are unsupported for `--hook` emission.]
  ```

### FT-005: Update the coach intro to match the harness-seams split
- **Severity**: LOW
- **File(s)**:
  - /Users/jordanknight/github/tools/skills/SDD/the-flow/references/coach.md
- **Issue**: The coach intro still says deterministic seams live in `00-routing.md`.
- **Fix**: Reword so `00-routing.md` owns state/routing and `harness-seams.md` owns harness seam orchestration.
- **Patch hint**:
  ```diff
  - The deterministic engine (state, routing, seams) lives in 00-routing.md
  + The deterministic engine's state/routing live in 00-routing.md; harness seam orchestration lives in harness-seams.md
  ```

## Re-Review Checklist

- [ ] All critical/high fixes applied
- [ ] F002-F005 consistency fixes either applied or explicitly accepted as deferred
- [ ] Re-run this review verb and achieve zero HIGH/CRITICAL
