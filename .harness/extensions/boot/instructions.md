# `harness boot` — agent briefing

Run this first, before any work in this repo. Boot is the first proof the repo
is ready, and a re-orientation to how this project wants to be operated.

## What this verb computes (the deterministic part)

This repo is a skills repository + dev-tooling installer — there is no service
to start, so "ready" means the quality gate is green. Boot:

1. Degrades deterministically if `.harness/extensions/checks/` is absent
   (`verdict: degraded`, `checks: absent`) with a `next_action` to create it.
2. Otherwise runs `harness checks --json` and folds its verdict in:
   - green → `ok`, `{ verdict: 'ready', checks: 'green' }`
   - red → `degraded`, `{ verdict: 'degraded', checks: 'red', checksExit }`.

Envelope `data` always carries `orient` — a one-line reminder of repo shape and
the paved commands.

## Your role (the inference part)

Read `verdict`. `ready` → proceed. `degraded` → resolve the named cause (create
`checks`, or fix the red gate) before starting real work; you are not blocked,
but starting on a red gate means building on an unproven base.

## Watch out for

- Boot proves only what `checks` proves — today that is slug + flow lint, not
  the full test/lint suite. A green boot is necessary, not sufficient.
- Boot starts no services because this repo has none; do not read "ready" as
  "a server is up".
