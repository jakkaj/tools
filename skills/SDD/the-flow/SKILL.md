---
name: the-flow
description: |
  The single front door to the SDD pipeline (docs/plans/): research → plan → workshop → ADR → phase tasks → implement → progress → review → merge. Use when the user wants to plan, research, explore, specify or architect (now one atomic 'plan' step → one document: business spec + implementation plan), clarify, workshop, write an ADR, break a phase into tasks, implement or build a phase (optionally with a live review companion), update progress, code-review, or merge a plan — or types /the-flow (or a legacy /plan-N command), or asks to start, resume, or adopt a plan flow. Guided mode (no args) coaches from durable on-disk state; direct jump runs one stage: /the-flow <id> <verb> [flags] — 1a explore, 1b plan (spec + plan in one doc; incl. clarify), 2c workshop, 3a adr, 5 tasks, 6 implement (--companion for live review), 6a progress, 7 review, 8 merge. Ids and verbs resolve alone; printed commands carry both.
---

# /the-flow — SDD pipeline dispatch

One public skill for the whole SDD pipeline, built to the flow-architecture pattern (`docs/skills-pipeline/flow-architecture.md`): the **sub-skills** (contract-bound verbs, one per stage) live in [`references/stages/`](./references/stages/), the guided-mode engine in [`references/00-routing.md`](./references/00-routing.md), the coaching voice in [`references/coach.md`](./references/coach.md). New to the flow? [`references/getting-started.md`](./references/getting-started.md).

**Progressive disclosure is the contract: load exactly one sub-skill for the current step — never read all of them up front.**

## Two load paths

**Guided** — `/the-flow` (no args, or `<slug>` / `<ord>-<slug>`):

1. Read `references/00-routing.md` (entry paths, state contract, the Graph) **and** `references/coach.md` (rail, narration, print-then-offer).
2. Resolve fresh / resume / adopt per 00-routing.md; load **only** the current stage's sub-skill when a step is accepted, and coach the seam.
3. Guided mode owns all the-flow state writes (`.the-flow-state.json`, `the-flow.json`, `the-flow.md`).

**Direct jump** — `/the-flow <id> <verb> [flags]`:

1. Resolve the stage via the Registry below. Id and verb each resolve alone (typing `6` ≡ typing `implement`); when both are given they must name the same stage — if they disagree, show the Registry and ask which was meant (never guess).
2. Read **only** that sub-skill and follow it with the given flags (same flags the verb has always taken).
3. No coach, no rail, no state writes — and **no harness seams** (harness orchestration is the guided engine's job — direct-jump runs the bare verb, harness-less by design). Artifacts land where they always did; the next guided run discovers them by existence and catches state up.

A sub-skill may lazily pull `references/00-routing.md` § Shared conventions when it cites it — that is still progressive disclosure (the pattern's sanctioned exception 1). Reading sub-skills for stages you are not executing is not.

## Registry

**This table is the master** (the Graph master is 00-routing.md § Graph; `references/getting-started.md` is a rendered view). It assigns the flow's ids, binds verbs to modules, and states each contract.

| id | verb | module | consumes → produces | flags |
|---|---|---|---|---|
| 1a | explore | `references/stages/10-explore.md` | intent → `research-dossier.md` | `"<intent>"` |
| 1b | plan | `references/stages/20-plan.md` | intent, dossier?, workshops?, coverage? → `<slug>-plan.md` (one doc: business spec + impl plan, **always both** in one atomic pass; gates G1–G7; auto-runs `/validate-v2`; § Re-entry for mid-plan clarifications) | `"<intent>"` `[--simple]` `[--skip-clarify]` |
| 2c | workshop | `references/stages/25-workshop.md` | plan/spec?, topic → `workshops/*.md` (authoritative decisions) | `"<topic>"` |
| 3a | adr | `references/stages/35-adr.md` | plan/spec context → `docs/adr/*.md` | `"<decision>"` |
| 5 | tasks | `references/stages/50-phase-tasks.md` | plan → `tasks/<phase>/tasks.md` + context brief | `--phase "<Phase N: Title>" --plan "<path>"` |
| 6 | implement | `references/stages/60-implement.md` | plan, tasks? → code + `execution.log.md` (exactly one phase) | `--plan "<path>"` `[--phase "<Phase N: Title>"]` `[--subtask "<ORD-slug>"]` `[--companion]` `[--companion-slug "<slug>"]` |
| 6a | progress | `references/stages/62-progress.md` | task outcome → updated task table + execution log (read by the implement verb after each task; owns the companion debrief) | `--plan --phase --task --status` `[--companion-run-id]` `[--companion-slug]` |
| 7 | review | `references/stages/70-review.md` | plan, code → `reviews/*.md` | `--plan "<path>"` `[--phase "<Phase N: Title>"]` |
| 8 | merge | `references/stages/80-merge.md` | plan, review → merge plan; **executes only on typed `PROCEED`** | `--plan "<path>"` |

Module missing at its path → say so and stop. Never improvise a stage from memory.

## Command grammar

Printed commands are always `/the-flow <id> <verb> [flags]`, e.g. `/the-flow 6 implement --plan "<path>"`.
Id or verb each resolve alone; printed form always carries both, never a bare number; mismatched pair → show the Registry and ask. This section is the grammar's **single definition** — every command surface anywhere else (narration, state files, views) is rendered from it plus a Registry row, never hand-written.

## Old-slug translation & aliases (read-time)

State files and docs written before the consolidation may carry commands naming retired skill slugs (e.g. a `pending_command` in `.the-flow-state.json`). Translate at read time — never execute a retired slug; rewrite via § Command grammar on the next state write. Flags carry over unchanged. **Targets are stored in id+flag form** (never as full command strings) and rendered through the Command grammar + Registry when printed or written into state.

| retired slug / typed alias | → target (id + flags) |
|---|---|
| `plan-1a-v2-explore` | `1a explore` |
| `plan-1b-v3-specify-and-clarify` | `1b plan` |
| `plan-1b-v2-specify` | `1b plan` |
| `plan-2-v2-clarify` | `1b plan` (module § Re-entry) |
| `plan-2c-v2-workshop` | `2c workshop` |
| `plan-3-v3-architect` | `1b plan` |
| `plan-3-v2-architect` | `1b plan` |
| typed `specify` | `1b plan` |
| typed `architect` or id `3` | `1b plan` |
| `plan-3a-v2-adr` | `3a adr` |
| `plan-5-v2-phase-tasks-and-brief` | `5 tasks` |
| `plan-6-v2-implement-phase` | `6 implement` |
| `plan-6-v2-implement-phase-companion` | `6 implement --companion` |
| `plan-6a-v2-update-progress` | `6a progress` |
| `plan-7-v2-code-review` | `7 review` |
| `plan-8-v2-merge` | `8 merge` |
| typed `6c` or `companion` | `6 implement --companion` |

**Unmapped slug → print the bare stage alias and ask — never guess.** (An unrecognised `/plan-*` command: show the Registry's ids/verbs and ask which stage was meant.)

## Hard invariants (every stage, both load paths)

1. **Print first, then offer to run.** Print the exact command in a copyable block — rendered via § Command grammar (id **and** verb, never a bare number), so the reader sees what it will do without knowing the ids — then offer to run it; one accepted step per turn (guided).
2. **Nothing irreversible without explicit confirmation.** The merge (stage 8) executes **only** after the user types `PROCEED` — never on a generic "yes".
3. **Never run `/compact`** — it is a user-typed CLI built-in. Recommend: "type `/compact` yourself, then re-run `/the-flow`".
4. **Never gate, score, or block.** Workshops, backpressure, compaction, companions — all skippable; best-effort, no thresholds, no compliance floors.
5. **Never fabricate an insight.** Ground every narrated detail in a real artifact; if you can't read it, say so and fall back to file existence / git status.
6. **Never hand-edit `the-flow.md`** as the primary — it is always regenerated from `the-flow.json` (the source of truth).
7. **You don't run `minih`.** The implement verb's companion mode (`--companion`) owns the companion protocol; you narrate the affordance and record agents in `the-flow.json`.
8. **No time estimates anywhere** — Complexity Score (CS 1–5) only (`references/00-routing.md` § Shared conventions).
9. **Harness = one door.** Every harness touchpoint is `/eng-harness-flow --hook …` (permanent `--event` alias) — never name or invoke its child skills. Harness-seam orchestration is **flow-owned** (`references/harness-seams.md`); sub-skills are harness-blind.
10. **Every stage is a deep-think task** — reason as thoroughly as the stage warrants.

## State

Durable state lives at `docs/plans/<ord>-<slug>/.the-flow-state.json`, plus the flight plan (`the-flow.json` → rendered `the-flow.md`). Contract, write ownership, and the Graph: `references/00-routing.md`; harness-seam orchestration (detection, seam map, node emission, upstream contract): `references/harness-seams.md`. Sub-skills own their *stage* artifacts (spec / plan / tasks / execution log / reviews), never write the-flow state, and carry no harness knowledge.
