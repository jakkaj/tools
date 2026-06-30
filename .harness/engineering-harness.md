# Engineering harness

> **AGENTS START HERE → `harness instructions`** — the CLI's baked agent
> briefing (envelope contract, role split, discovery loop). Then
> `harness instructions <verb>` per verb.

## Boot command
`harness boot` — this repo is a skills repository + dev-tooling installer with no
running service, so boot composes `harness checks` and folds its verdict in, then
prints one-line orientation. Verdict: `ready` (checks green) / `degraded` (checks
red or absent). Extension: `.harness/extensions/boot/`.

## Checks command
`harness checks` — the mandated quality gate. Runs the repo's skill-quality gates
in order, failing on the first red: `skill-slugs`
(`scripts/check-skill-slugs.sh`), `flow-architecture`
(`scripts/check-flow-architecture.sh skills/SDD/the-flow`), then `skill-frontmatter`
(`scripts/check-skill-frontmatter.sh`). Composable: add a gate by appending one
`Gate` entry in `.harness/extensions/checks/extension.ts`. Agents run it before
"done"; `harness boot` composes it.

## Health check
<!-- TODO: the command/endpoint that proves the system is up (read by boot Stage 1). -->

## Interact method
<!-- TODO: how an agent sends input to the running system (boot Stage 2). -->

## Observe method
<!-- TODO: how an agent captures evidence — logs, screenshots, traces (boot Stage 3). -->

## Deterministic signal inventory
<!-- TODO: sensors that prove behaviour without inference — runtime inspectability,
     smoke paths, architecture/static checks, security/dependency/schema checks. -->

## Evidence paths
<!-- TODO: where artifacts land (log/trace/screenshot/output locations). -->

## Injection map
<!-- Where the repo's extant dev/SDD flow calls /eng-harness-flow. One row per seam.
     Filled by eng-harness-0-adopt Step 3 (with the user's go-ahead). -->

The host SDD flow (`the-flow`, `skills/SDD/the-flow/`) is **harness-aware and
self-fires** these seams at its lifecycle moments — nothing was woven into other
surfaces. Orchestration lives in `skills/SDD/the-flow/references/harness-seams.md`.

| Seam event (`--hook`) | Fires from | What fires it |
|---|---|---|
| `pre-flight` (pre-implement) | the-flow implement stage, phase start | `/eng-harness-flow` (self-fired) |
| `pre-coding` (post-spec) | the-flow, after plan locks | `/eng-harness-flow` (self-fired) |
| `coding` (task-pause) | the-flow implement stage, mid-phase | `harness observe` (per-phase chore) |
| `post-coding` (phase-end) | the-flow implement stage, phase end | `/eng-harness-flow` (self-fired) |
| `post-flight` (plan-complete) | the-flow ship stage | `/eng-harness-flow` (self-fired) |

## Back-pressure gaps
<!-- TODO: behaviours still relying on inference/human eyeballing — improvement
     candidates, named honestly. Never scores. -->

## Current maturity snapshot
**L0 — seeded at inception by `harness init`; nothing proven yet.**
<!-- The single, current L0–L4 level the harness is ACTUALLY at. Updated ONLY at
     the Improve beat (never by boot, which is read-only). See maturity-assessment.md. -->
