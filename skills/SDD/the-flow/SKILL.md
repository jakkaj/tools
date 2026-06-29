---
name: the-flow
description: |
  The single front door to the SDD pipeline (docs/plans/): research → plan → workshop → ADR → phase tasks → implement → progress → review → ship. Use when the user wants to plan, research, explore, specify or architect (now one atomic 'plan' step → one document: business spec + implementation plan), clarify, workshop, write an ADR, break a phase into tasks, implement or build a phase (optionally with a live review companion), update progress, code-review, or ship a plan (push + PR + watch checks) — or types /the-flow (or a legacy /plan-N command), or asks to start, resume, or adopt a plan flow. Guided mode (no args) coaches from durable on-disk state; direct jump runs one stage: /the-flow <id> <verb> [flags] — 1a explore, 1b plan (spec + plan in one doc; incl. clarify), 2c workshop, 3a adr, 5 tasks, 6 implement (--companion for live review), 6a progress, 7 review, 8 ship, 8c reconcile. Ids and verbs resolve alone; printed commands carry both.
---

# /the-flow — SDD pipeline dispatch

One public skill for the whole SDD pipeline, built to the flow-architecture pattern (`docs/skills-pipeline/flow-architecture.md`): the **sub-skills** (contract-bound verbs, one per stage) live in [`references/stages/`](./references/stages/), the guided-mode engine in [`references/00-routing.md`](./references/00-routing.md), the coaching voice in [`references/coach.md`](./references/coach.md). New to the flow? [`references/getting-started.md`](./references/getting-started.md).

**Progressive disclosure is the contract: load exactly one sub-skill for the current step — never read all of them up front.**

## Two load paths

**Guided** — `/the-flow` (no args, or `<slug>` / `<ord>-<slug>`):

1. Read `references/00-routing.md` (entry paths, state contract, the Graph) **and** `references/coach.md` (rail, narration, print-then-offer).
2. Resolve fresh / resume / adopt per 00-routing.md; load **only** the current stage's sub-skill when a step is accepted, and coach the seam.
3. Guided mode owns all the-flow state, and drives **all** of it — position *and* session bag — through `harness flow nav` calls: the flight plan (`the-flow.json` → `the-flow.md`) is the single state substrate (plan 024 — the CLI is the generator; **nothing is hand-written**; run the capability precheck first, § Prerequisite). **Before the first flight-plan mutation of a session, also load [`references/flight-plan-ops.md`](./references/flight-plan-ops.md)** — the nav model, the spine-vs-excursion rule, and the verb flags + gotchas (loaded on demand, not up front; sub-skills never load it).

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
| 2c | workshop | `references/stages/25-workshop.md` | plan/spec?, topic → `workshops/*.md` (authoritative decisions) | `<plan> "<topic>"` `[--from-spec]` `[--list]` |
| 3a | adr | `references/stages/35-adr.md` | plan/spec context → `docs/adr/*.md` | `"<decision>"` |
| 5 | tasks | `references/stages/50-phase-tasks.md` | plan → `tasks/<phase>/tasks.md` + context brief | `--phase "<Phase N: Title>" --plan "<path>"` |
| 6 | implement | `references/stages/60-implement.md` | plan, tasks? → code + `execution.log.md` (exactly one phase) | `--plan "<path>"` `[--phase "<Phase N: Title>"]` `[--subtask "<ORD-slug>"]` `[--companion]` `[--companion-slug "<slug>"]` |
| 6a | progress | `references/stages/62-progress.md` | task outcome → updated task table + execution log (read by the implement verb after each task; owns the companion debrief) | `--plan --phase --task --status` `[--companion-run-id]` `[--companion-slug]` |
| 7 | review | `references/stages/70-review.md` | plan, code → `reviews/*.md` | `--plan "<path>"` `[--phase "<Phase N: Title>"]` |
| 8 | ship | `references/stages/80-ship.md` | plan, review → pushed branch + PR (repo-guidance-aware) + watched CI checks; push & PR-open **each behind a confirm**, merge optional; **flushes telemetry (no confirm)** | `--plan "<path>"` `[--base "<branch>"]` `[--no-watch]` `[--draft]` |
| 8c | reconcile | `references/stages/80-merge.md` | (conditional excursion — divergent base) → reconcile/merge plan; **merge executes only on typed `PROCEED`** | `--plan "<path>"` `[--target "<branch>"]` |
| sync | sync | `references/00-routing.md` | flight plan + plan artifacts → **reconciled** flight plan: backfills every past/present/future phase + workshop + harness seam-node that current knowledge implies; **idempotent** (a complete spine writes nothing), advisory, CLI-only, never advances `nav` | (none) — auto-fired every guided entry; also invokable on demand |

Module missing at its path → say so and stop. Never improvise a stage from memory.

> **`8 ship` is the terminal spine stage; `8c reconcile` is a conditional excursion** (fired only when the base has meaningfully diverged), never on the spine. Typed `merge` and the legacy `plan-8-v2-merge` resolve to `8c reconcile` (alias table below).
> **`sync` is a maintenance verb, not a journey stage** — it has no ordinal id, produces no stage artifact, and never moves the cursor or runs a stage. It is the engine's **every-entry spine-reconcile pass** (the routine lives in `references/00-routing.md` § Reconcile the spine), exposed as a verb so anyone can run it on demand (and so a direct-jump-built or hand-adopted plan can be repaired in one call). Distinct from `8c reconcile` (which merges a divergent git base — unrelated). See invariant #11.

## Command grammar

Printed commands are always `/the-flow <id> <verb> [flags]`, e.g. `/the-flow 6 implement --plan "<path>"`.
Id or verb each resolve alone; printed form always carries both, never a bare number; mismatched pair → show the Registry and ask. This section is the grammar's **single definition** — every command surface anywhere else (narration, state files, views) is rendered from it plus a Registry row, never hand-written.
The maintenance verb `sync` resolves alone (its id and verb are the same token): `/the-flow sync` runs the spine-reconcile pass on demand. It takes no stage flags; it never advances the journey.

## Old-slug translation & aliases (read-time)

Docs and **legacy** state files written before the consolidation may carry commands naming retired skill slugs (e.g. a `pending_command` in a leftover `.the-flow-state.json`, read only during the one-shot resume backfill — § State). Translate at read time — never execute a retired slug; the live source of a pending command is now `nav.next` + the Command grammar, rendered at read time (never stored). Flags carry over unchanged. **Targets are stored in id+flag form** (never as full command strings) and rendered through the Command grammar + Registry when printed or written into state.

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
| `plan-8-v2-merge` | `8c reconcile` |
| typed `merge` | `8c reconcile` |
| typed `6c` or `companion` | `6 implement --companion` |

**Unmapped slug → print the bare stage alias and ask — never guess.** (An unrecognised `/plan-*` command: show the Registry's ids/verbs and ask which stage was meant.)

## Hard invariants (every stage, both load paths)

1. **Print first, then offer to run.** Print the exact command in a copyable block — rendered via § Command grammar (id **and** verb, never a bare number), so the reader sees what it will do without knowing the ids — then offer to run it; one accepted step per turn (guided). **One exception, by design:** the harness *router call* (`/eng-harness-flow --hook … --json`) **auto-fires** at each seam — it's read-only/advisory and positional, so it can't be forgotten as context grows or compacts; only the *action it routes to* follows print-then-offer (call-only depth — `references/harness-seams.md` § How the engine presents a seam).
2. **Nothing irreversible without explicit confirmation.** Outward-facing actions each gate: the **ship** verb's push and PR-open are **separate** confirms (a "yes" to push is not a "yes" to open a PR); the **reconcile** merge (8c) and any immediate merge execute **only** after the user types `PROCEED` — never on a generic "yes". *(One deliberate exception: **ship flushes telemetry without a confirm** via `harness telemetry sync` — a counts-only, out-of-tree push to `refs/harness-telemetry/*` that publishes no work, touches no branch/PR, and is reversible, so it is not an outward-facing gate.)*
3. **Never run `/compact`** — it is a user-typed CLI built-in. Recommend: "type `/compact` yourself, then re-run `/the-flow`".
4. **Never gate, score, or block.** The *actions* these surface — workshops, the backpressure survey, compaction, companions — are all skippable; best-effort, no thresholds, no compliance floors. **Scope note:** "skippable" describes the *action a seam routes to*, never the seam's router *call* — per #1/#9 the `/eng-harness-flow --hook … --json` call still **auto-fires positionally at every seam**; the user declines the *action*, not the *call*.
5. **Never fabricate an insight.** Ground every narrated detail in a real artifact; if you can't read it, say so and fall back to file existence / git status.
6. **Never hand-edit the flight plan, and never hand-author a state file.** `the-flow.md` is always regenerated from `the-flow.json` by `harness flow render`; `the-flow.json` itself is mutated **only** through `harness flow` calls (plan 024 — the CLI is the generator). There is **no `.the-flow-state.json`** — all the-flow state (position + session `bag`) lives in `the-flow.json`, and the CLI is its only writer. Guided mode requires a capable CLI (§ Prerequisite).
7. **You don't run `minih`.** The implement verb's companion mode (`--companion`) owns the companion protocol; you narrate the affordance. Agent bookkeeping into the flight plan awaits the v2 `harness flow agent` verb — until it lands, `agents[]` stays unpopulated and is never hand-edited (per invariant #6).
8. **No time estimates anywhere** — Complexity Score (CS 1–5) only (`references/00-routing.md` § Shared conventions).
9. **Harness = one door, auto-fired at each seam.** Every harness touchpoint is `/eng-harness-flow --hook …` (permanent `--event` alias) — never name or invoke its child skills. The router *call* **auto-fires** mechanically from the durable `nav.now` position at each seam (so it survives long/compacted context); the routed *action* stays print-then-offer (call-only). Harness-seam orchestration is **flow-owned** (`references/harness-seams.md`); sub-skills are harness-blind.
10. **Every stage is a deep-think task** — reason as thoroughly as the stage warrants.
11. **Keep the spine complete — reconcile every guided entry.** On **every** guided entry (resume *and* adopt), before narrating, the engine runs the **spine-reconcile pass** (`references/00-routing.md` § Reconcile the spine, exposed as the `sync` verb): it diffs the plan's full phase/workshop roster + the harness seam-node set against `the-flow.json` and **backfills whatever current knowledge implies but the flight plan is missing** — all past/present/future phases, every workshop, and — **unconditionally under D1** — the per-phase harness seam nodes (provisioning affects only whether they're *run*, never whether they exist). It is **idempotent** (a complete spine writes nothing), **advisory in what it FINDS**, **CLI-only** (invariant #6), and **never gates, never advances `nav`, never runs a stage**. The **mechanical enforcer** is the Tier-1 run-now step in `references/00-routing.md` § CLI-driven cadence (step 3, sibling to `render`) — **not** prose memory: it rides the positional "a long or compacted session cannot skip it" guarantee, so **RUN is mandatory + mechanical** (render-class) while what it **FINDS** stays advisory/non-gating. The user must never have to ask "make sure all phases/chores are represented" — that omission is the bug this invariant exists to kill. Direct-jump does **not** auto-reconcile (harness-less by design); the `sync` verb runs the pass on demand.
12. **Orient every turn — read `nav`, run `orient`, re-ground on the spine.** Before acting on any guided turn, read the durable position (`harness flow nav show`) and run **`harness flow orient`** — it prints the rail + the `nav.now` node's `label`/`command`/**authored `instructions[]`** + the chores due here. This is **positional and mechanical** — a **Tier-1 cadence step, a sibling to `render` and the spine-reconcile (#11)** — run unconditionally every entry, **never an offered beat**, riding the same *"a long or compacted session cannot skip it"* guarantee as the seam auto-fire (#9). It is the fix for "cheap models don't follow the flow": "what do I do next" becomes a **read, not an inference**, so even a weak model (or a freshly-`/compact`-ed context) re-grounds on the spine every turn instead of drifting off it — the node's `instructions[]` are re-read each turn, never remembered. The orient **read** is mandatory + mechanical; what it surfaces (instructions, due chores) stays **advisory/non-gating** (chores never gate — #4). *(Guaranteed enforcement on an adversarially-weak model ultimately needs a harness-side per-turn hook — the skill can only instruct; that bigger ask is noted, not blocking.)*

## State

Durable state **is** the flight plan — `nav` (position + the free-form `bag`) + node statuses in `docs/plans/<ord>-<slug>/the-flow.json` (rendered to `the-flow.md`). **No separate state file** — the CLI is the only state writer. Contract, write ownership, and the Graph: `references/00-routing.md`; harness-seam orchestration (detection, seam map, node emission, upstream contract): `references/harness-seams.md`. Sub-skills own their *stage* artifacts (spec / plan / tasks / execution log / reviews), never write the-flow state, and carry no harness knowledge.

## Prerequisite — a capable `harness flow` CLI (capability + version floor)

Guided mode drives the flight plan (`the-flow.json` → `the-flow.md`) **exclusively** through the `harness flow` verb family (plan 024). It is a hard runtime dependency:

- **Capability precheck — run once per guided session, before the first flight-plan mutation.** Probe `harness flow --help` (and, for a version floor, `harness --version`). If `harness` is missing, or the `flow` verb family is absent (an older CLI), or its surface is too old to carry `create`/`insert-node`/`nav`/`rail`/`render` → **error-and-stop** with the honest hedge: *"the-flow needs a capable `harness flow` CLI (plan 024). Run `harness update` (or `npm i -g @ai-substrate/engineering-harness`), then re-run `/the-flow`."* Do **not** fall back to hand-cranking the JSON — the CLI is the only writer.
- **No adoption required.** This is *not* the engineering-harness loop. the-flow's flight plans live in `docs/plans/<ord>-<slug>/the-flow.json` and need **no** `.harness/` setup, no governance doc, no harness adoption — only the global CLI on `$PATH` (`harness` is an ambient tool like `git`). The flight-plan schema ships **with this skill** (`references/flight-plan.schema.json`) and is supplied via `--schema`; nothing is bundled or installed into the consuming repo.
- **Clean break (`E308`).** Pre-024 hand-cranked flows (a `the-flow.json` with no `provenance` block) are **not** migrated — the CLI returns `E308` (legacy-format) on read. That is an honest stop, not a bug: re-create with `harness flow create flight-plan --schema <skill base>/references/flight-plan.schema.json --agent the-flow` (`<skill base>` = this skill's base dir, e.g. `~/.claude/skills/the-flow`; the `--agent the-flow` titles the rebuilt rail `[the-flow]`; any prior `.md` stays as a static record).
- **Version skew is a runtime-dependency gap, not an auto-fallback.**
  - *Forward skew* (skill needs a newer CLI than installed) → the capability precheck above stops with "run `harness update`".
  - *Reverse skew* (an **old** the-flow that still hand-cranks the JSON, run against a **new** CLI) → the old hand-crank's write produces a `the-flow.json` the new CLI then reads as `E308` (no `provenance`) — a clean stop, **not** silent divergence. The fix is to update the skill, never to special-case it.
- **Deploy order — CLI first, then skill.** Always land a capable `harness flow` (publish / `harness update`) **before** deploying this migrated skill, so the precheck passes the moment the skill goes live. Rollback is additive/reversible: revert the skill + `harness update --pin <prev>` (the CLI is a global npm package).
