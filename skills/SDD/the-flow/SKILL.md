---
name: the-flow
description: |
  The single front door to the SDD pipeline (docs/plans/): research → spec → workshop → architect → ADR → phase tasks → implement → progress → review → merge. Use when the user wants to plan, research, explore, specify, clarify, workshop, architect, write an ADR, break a phase into tasks, implement or build a phase, update progress, code-review, or merge a plan — or types /the-flow (or a legacy /plan-N command), or asks to start, resume, or adopt a plan flow. Guided mode (no args) coaches stage-by-stage from durable on-disk state; direct jump runs exactly one stage: /the-flow <id> <name> [flags] — 1a explore, 1b specify (incl. clarify re-entry), 2c workshop, 3 architect, 3a adr, 5 tasks, 6 implement, 6c companion, 6a progress, 7 review, 8 merge. Id and name each resolve alone (/the-flow 6 ≡ /the-flow implement ≡ /the-flow 6 implement), but every command the flow prints carries both — /the-flow 6 implement --phase "Phase 1: X" --plan "<path>" — so readers see what will run without knowing the numbers. Stage logic lives in references/stages/*.md, loaded lazily — one module per step.
---

# /the-flow — SDD pipeline dispatch

One public skill for the whole SDD pipeline. Stage logic lives in [`references/stages/`](./references/stages/) (one module per stage), the guided-mode engine in [`references/00-routing.md`](./references/00-routing.md), the coaching voice in [`references/coach.md`](./references/coach.md). New to the flow? [`references/getting-started.md`](./references/getting-started.md).

**Progressive disclosure is the contract: load exactly one stage module for the current step — never read all modules up front.**

## Two load paths

**Guided** — `/the-flow` (no args, or `<slug>` / `<ord>-<slug>`):

1. Read `references/00-routing.md` (entry paths, state contract, routing table) **and** `references/coach.md` (rail, narration, print-then-offer).
2. Resolve fresh / resume / adopt per 00-routing.md; load **only** the current stage's module when a step is accepted, and coach the seam.
3. Guided mode owns all the-flow state writes (`.the-flow-state.json`, `the-flow.json`, `the-flow.md`).

**Direct jump** — `/the-flow <id> <name> [flags]`:

1. Resolve the stage via the table below. Id and name each resolve alone (`/the-flow 6` ≡ `/the-flow implement`); when both are given they must name the same stage — if they disagree, show the stage table and ask which was meant (never guess).
2. Read **only** that module and follow it with the given flags (same flags the stage has always taken).
3. No coach, no rail, no state writes — artifacts land where they always did; the next guided run discovers them by existence and catches state up.

A stage module may lazily pull `references/00-routing.md` § Shared conventions when it cites it — that is still progressive disclosure. Reading modules for stages you are not executing is not.

## Stage table

| id | name | module | what it does |
|---|---|---|---|
| 1a | explore | `references/stages/10-explore.md` | research the codebase → `research-dossier.md` |
| 1b | specify | `references/stages/20-specify.md` | spec + clarify in one pass (§ Re-entry for mid-plan clarifications) |
| 2c | workshop | `references/stages/25-workshop.md` | design workshop → `workshops/*.md` (authoritative decisions) |
| 3 | architect | `references/stages/30-architect.md` | implementation plan + gates G1–G7 (auto-runs `/validate-v2`) |
| 3a | adr | `references/stages/35-adr.md` | architecture decision record |
| 5 | tasks | `references/stages/50-phase-tasks.md` | phase task table + context brief |
| 6 | implement | `references/stages/60-implement.md` | build exactly one phase |
| 6c | companion | `references/stages/61-implement-companion.md` | build with a live minih review companion |
| 6a | progress | `references/stages/62-progress.md` | per-task progress + companion debrief (read by 6/6c after each task) |
| 7 | review | `references/stages/70-review.md` | code review → `reviews/*.md` |
| 8 | merge | `references/stages/80-merge.md` | merge analysis; **executes only on typed `PROCEED`** |

Module missing at its path → say so and stop. Never improvise a stage from memory.

## Old-slug translation (read-time)

State files and docs written before the consolidation may carry commands naming retired skill slugs (e.g. a `pending_command` in `.the-flow-state.json`). Translate at read time — never execute a retired slug; rewrite in public grammar (`/the-flow <id> <name> …`) on the next state write. Flags carry over unchanged.

| retired slug | → stage |
|---|---|
| `plan-1a-v2-explore` | 1a |
| `plan-1b-v3-specify-and-clarify` | 1b |
| `plan-2-v2-clarify` | 1b (module § Re-entry) |
| `plan-2c-v2-workshop` | 2c |
| `plan-3-v3-architect` | 3 |
| `plan-3a-v2-adr` | 3a |
| `plan-5-v2-phase-tasks-and-brief` | 5 |
| `plan-6-v2-implement-phase` | 6 |
| `plan-6-v2-implement-phase-companion` | 6c |
| `plan-6a-v2-update-progress` | 6a |
| `plan-7-v2-code-review` | 7 |
| `plan-8-v2-merge` | 8 |

**Unmapped slug → print the bare stage alias and ask — never guess.** (An unrecognised `/plan-*` command: show this table's ids/names and ask which stage was meant.)

## Hard invariants (every stage, both load paths)

1. **Print first, then offer to run.** Print the exact command in a copyable block — always as `/the-flow <id> <name> …` (e.g. `/the-flow 6 implement …`), never a bare number, so the reader sees what it will do without knowing the ids — then offer to run it; one accepted step per turn (guided).
2. **Nothing irreversible without explicit confirmation.** The merge (stage 8) executes **only** after the user types `PROCEED` — never on a generic "yes".
3. **Never run `/compact`** — it is a user-typed CLI built-in. Recommend: "type `/compact` yourself, then re-run `/the-flow`".
4. **Never gate, score, or block.** Workshops, backpressure, compaction, companions — all skippable; best-effort, no thresholds, no compliance floors.
5. **Never fabricate an insight.** Ground every narrated detail in a real artifact; if you can't read it, say so and fall back to file existence / git status.
6. **Never hand-edit `the-flow.md`** as the primary — it is always regenerated from `the-flow.json` (the source of truth).
7. **You don't run `minih`.** Stage 6c owns the companion protocol; you narrate the affordance and record agents in `the-flow.json`.
8. **No time estimates anywhere** — Complexity Score (CS 1–5) only (`references/00-routing.md` § Shared conventions).
9. **Harness = one door.** Every harness touchpoint is `/eng-harness-flow --event …` — never name or invoke its child skills.
10. **Every stage is a deep-think task** — reason as thoroughly as the stage warrants.

## State

Durable state lives at `docs/plans/<ord>-<slug>/.the-flow-state.json`, plus the flight plan (`the-flow.json` → rendered `the-flow.md`). Contract, write ownership, routing table, and harness-seam detection: `references/00-routing.md`. Stage modules own their *stage* artifacts (spec / plan / tasks / execution log / reviews) and never write the-flow state.
