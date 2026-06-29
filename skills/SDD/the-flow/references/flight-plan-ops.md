# flight-plan-ops — the-flow's operational manual for the `harness flow` CLI

> **Load rule (guided mode only):** load this file **before the first flight-plan mutation** of a session, then keep it in context for the rest of the guided run. Sub-skills (direct-jump) never touch the flight plan and never load this file. Registered in [`../SKILL.md`](../SKILL.md) "Two load paths" + [`00-routing.md`](./00-routing.md) § Flight plan.

The flight plan (`the-flow.json` → rendered `the-flow.md`) is mutated **only** through `harness flow` calls — the CLI is the generator; never hand-edit the JSON or the `.md`. This file is the the-flow-specific *how*: the nav model, the spine/excursion rule, the verb flags, and the gotchas. The routing-level *when* (which mutation fires at which seam) stays in [`00-routing.md`](./00-routing.md).

## §1 — Principle: the CLI persists; the flow dispatches

`harness flow` is **deterministic mechanics only** — it creates / mutates / inspects the flow DAG, validates node-refs + structure, and renders. It **never routes**: it doesn't know what stage comes next, never picks a verb, never reads the Graph. **the-flow owns the Graph** (the routing logic in `00-routing.md`); the CLI owns the *persistence + validation* of the position the flow decides. Keep the split clean — decide in the flow, record via the CLI.

## §2 — The nav object (replaces the removed `cursor` verb)

`nav = { now, next, intent?, bag? }` — the single position object (a clean break from the old top-level position fields; no alias).

- `now`    — the validated current node (the truth). Move it: `harness flow nav set --now <id>` (fires `cursor-moved`).
- `next`   — an advisory node-id, or null (no event). Set: `--next <id>`; clear: `--clear-next`.
- `intent` — free-text leg intent: `--intent "<text>"`.
- `bag`    — free-form shallow-merge qualifiers (no schema): `harness flow nav meta set <key> <value>` / `harness flow nav meta get [key]`.
- Inspect: `harness flow nav show` → nav + the now-node's predecessors / successors.

⚠️ The `cursor` verb is GONE — clean break, no alias. Map old usage to nav:

- the verb's old **move** (its `--to`) → `harness flow nav set --now <id>` (fires `cursor-moved`)
- the verb's old **advisory** (its recommend flag) → `harness flow nav set --next <id>`
- the old top-level position fields → the single `nav` object above

## §3 — Verb cheat-sheet

```bash
# create — Route A (plan 040 / D1): instantiate the FULL 10-node seed (spine + 5 chores + per-node instructions[]) in ONE call (--template). ALWAYS --agent the-flow.
harness flow create flight-plan --slug <slug> --path <flow.json> \
  --schema "<skill base>/references/flight-plan.schema.json" \
  --template "<skill base>/references/flight-plan.template.json" --agent the-flow [--title "<t>"] [--plan-id <id>]
#   (--bare instead of --template → a root-only flow you then build with add-node; the template seed is preferred.)

harness flow add-node    --path <f> --id <id> --type <t> --label "<l>" --status <s> [--next <a,b>] [--zone <band>]
harness flow insert-node --path <f> --id <id> --type <t> --label "<l>" --status <s> (--after <n> | --before <n> | --branch-of <n> [--rejoin <n>]) [--zone <band>]
harness flow status      --path <f> --node <id> --to <status>
harness flow set-node    --path <f> --node <id> [--label|--note|--user-input|--artifacts]   # NOTE: cannot set --next/--branch-of
harness flow nav set     --path <f> [--now <id>] [--next <id>|--clear-next] [--intent "<t>"]
harness flow render      --path <f> --output <flow.md>
harness flow rail        --path <f>            # the one-line spine rail

# Transactional batch + the new mutation primitives (plan 039) — prefer `apply` for ANY multi-node change:
harness flow apply       --path <f> --ops <file | ->   # JSON array of ops; two-phase, one DAG-check, one atomic write or none
harness flow remove-node --path <f> --id <id> [--force]                                                  # delete + rewire preds→succs
harness flow mv-node     --path <f> --id <id> (--after <n>|--before <n>|--branch-of <n>) [--rejoin <n>] [--force]   # re-parent + rewire
```

(`<skill base>` = this skill's base dir, e.g. `~/.claude/skills/the-flow`. Full verb + flag reference: `docs/how/harness-flow.md` — see §7.)

### §3b — `apply` batch mechanics (the hardcoded chore batch moved out — plan 040 / D1)

The shipped, worked canonical harness-chore `apply` batch that used to live here is **deleted** (plan 040 / D1). The chore *shape* is **no longer carried in this skill at all** — there is no skill-side copy to re-synthesize or drift. It is owned by the **single shared shape doctrine**, the `doctrine-parity:039` block in [`harness-seams.md`](./harness-seams.md), and **materialised two ways** (workshop 001 WS-2, C1):

- **the-flow present** → the shape is **baked into [`flight-plan.template.json`](./flight-plan.template.json)** at `create` (the full 10-node seed — spine + 5 chores + per-node `instructions[]`, **no create-time apply, no gate**); the plan-complete additive expander reads that *same* doctrine to splice phases 2..N's `review-N` + trios.
- **eng-harness-flow standalone** → the same shape is instantiated into its own `.harness/loop.flow.json` (it never reads any the-flow file).

General `apply` mechanics survive here (they describe the verb, not the chore shape):

- **Op kinds**: `add | upsert | set | insert | mv | remove`. `upsert` dedups on `id` (a byte-stable no-op when the node is identical) — which is what makes the plan-complete expander idempotent on re-run.
- **D5 terminal guard**: no op flips a `done`/`skipped` node back to `todo`; `remove`/`mv` of a terminal needs `--force`; a `remove`-then-re-`add`/`upsert` of the same terminal id in one batch cannot launder it (the guard is batch-wide).

## §4 — Spine vs excursion (the rule that keeps the rail clean)

The rail walks the MAIN SPINE only and excludes any node with `branch_of`.

- **SPINE** = the SDD journey: research → plan → (phase-N → review-N)* → ship.
  - wire with `--next`; reveal phases at the plan pass via `insert-node --after <prev>`.
- **EXCURSIONS** = workshops, ADRs, backpressure, fix-loops, harness seams, **reconcile** (the upstream-reconcile excursion off `ship`/a phase, only when the base has diverged).
  - attach with `insert-node --branch-of <node> [--rejoin <node>]` — the branch point's `next` is UNCHANGED.
  - excursions are EXCLUDED from the rail and render as dotted side-branches.

❗Workshops ALWAYS `--branch-of plan` — NEVER `--next` / `--after`. Chaining a workshop onto the spine is exactly the "workshops in the spine" defect (cluttered rail). Phases on the spine; everything else hangs off it.

## §5 — Zone bands (defaults by type — the flow rarely needs `--zone`)

| zone | default node types |
|------|--------------------|
| preflight | research, plan, workshop, adr (the shared renderer also maps `tasks`→preflight, but `tasks` isn't in the-flow's vocabulary) |
| flight | phase (and any unknown type) |
| postflight | review, ship, merge, retro |

Pass explicit `--zone` only to override a default. For the flight-plan vocabulary the defaults are already correct, so you do **not** need to add `--zone` to the calls above — with **one exception**: each per-phase `review` overrides its postflight default to **`--zone flight`** so the reviews interleave on the spine (see the caveat below).

> **Per-phase `review` is flight-zoned (override the default).** The default for `review` is **postflight**, which suits a single end-of-spine gate. The flight-plan spine instead carries **one `review-N` per phase** (template `review-1`; expander `review-2..N`), so each is created with **`--zone flight`** — that lands them mid-spine, interleaved `[ P1·review-1·P2·review-2 ]·ship`, instead of bunched in the postflight band (the renderer bands strictly by zone). This is the one `review` override the seed needs.

> **`ship` banding caveat (cross-repo).** `ship` belongs in **postflight** (the terminal stage). That default takes effect once the external `harness flow` renderer adds `ship` to its postflight zone-set. Until then a renderer that doesn't know `ship` falls back to the **flight** band (the "any unknown type" rule above), so `ship` renders *inside* the flight `[ … ]` band rather than after it. Harmless — the rail still ends at **Ship**; best-effort, no hand-fix (never hand-edit `the-flow.md`). If you need the postflight band now, pass `--zone postflight` when adding the `ship` node.

## §6 — Gotchas

- **Build order (single-op verbs only)**: `add-node`/`insert-node` reject forward `--next` refs — add the spine last-to-first (ship first), or add nodes then wire. **`apply` removes this wart** (plan 039): a batch resolves forward refs at the end (two-phase — materialize all nodes → wire edges → validate the final DAG once), so op order *within* a batch never matters.
- **`set-node` can't re-parent**: it cannot set `--next` / `--branch-of`. To turn an existing spine node into an excursion, use **`mv-node`** (plan 039 — re-parents + rewires, DAG-re-checked, cycle-refused), or `insert-node --branch-of` for a fresh node. To delete + rewire, use **`remove-node`**.

## §7 — Pointer

Authoritative full reference (every verb, every flag, the render contract, error codes): **`docs/how/harness-flow.md`** (in the harness-engineering repo, updated in plan 026). This file carries only the the-flow-specific usage; that doc is the exhaustive CLI reference.
