# the-flow ↔ engineering-harness seams

How the SDD flow (`/the-flow`) touches the external engineering harness (`/eng-harness-flow`) — **where** each seam sits, **which lifecycle hook** it fires, and **what** it produces. This is a reader-facing guide; the **authoritative source** is the flow-owned reference [`skills/SDD/the-flow/references/harness-seams.md`](../../skills/SDD/the-flow/references/harness-seams.md) (the seam map, two-layer detection, node-emission rule, and the versioned upstream contract). The tree below is a *rendered view* of that file's seam map — keep them in sync; don't let this become a second source of truth.

## The big idea (plan-033 inversion)

Harness seams are **flow-owned**, not buried in the stage sub-skills. The guided **engine** (`references/00-routing.md` Graph + `references/coach.md`) offers each seam as a **print-then-offer beat at the Graph edge**, and advances *through* a first-class flight-plan node. The stage sub-skills (`references/stages/*.md`) are **harness-blind** — they describe only their own verb and carry no `/eng-harness-flow` literal and no boot/backpressure/retro concept. All harness knowledge lives in exactly three places: `harness-seams.md` (where/when/whether), the Graph (the edges), and the external `/eng-harness-flow` router (what happens behind the door).

The flow wires **four fire-hooks** and deliberately **skips one** (the silent `coding` capture). `pre-flight` appears at **two** edges — flow entry and before each phase.

## The hook-woven flow tree

```
the-flow  ·  SDD spine + ⚙ eng-harness-flow lifecycle hooks
│
├─ ⚙ pre-flight ········ flow entry · detect router · usually NO node      [--hook pre-flight]
│                         (alias: --event session-start)
│
├─ ◇ 1a explore  (optional) ─────────────────────────► research-dossier.md
│
├─ ◆ 1b plan ────────────────────────────────────────► <slug>-plan.md  (spec + impl)
│   └─ ⚙ pre-coding ···· post-plan refinement · backpressure node          [--hook pre-coding]
│         → backpressure-coverage.md (advisory) · re-plan informed by it    (alias: --event post-spec)
│
├─ ◇ 5 tasks  (Full only) ───────────────────────────► tasks/<phase>/tasks.md
│
├─ ◆ 6 implement   ◄── loops once per phase ──────────► code + execution.log.md
│   ├─ ⚙ pre-flight ···· before task 1 · harness-boot node                 [--hook pre-flight]
│   │      → verdict: healthy / SLOW / UNHEALTHY / UNAVAILABLE              (alias: --event pre-implement)
│   ├─ ⚙ coding ········ mid-build · SILENT · NOT wired by the-flow         [harness observe]
│   │      (deliberately skipped — mirrors the old task-pause skip)         (alias: --event task-pause)
│   └─ ⚙ post-coding ··· phase end · harness-retro node                     [--hook post-coding]
│          → drains this phase's friction → .retro.md                       (alias: --event phase-end)
│
├─ ◇ 7 review ───────────────────────────────────────► reviews/*.md   (no hook — inferential tier)
│
└─ ◆ 8 merge  ◄── executes only on typed PROCEED ─────► merge plan
    └─ ⚙ post-flight ··· after merge · harness-retro node                   [--hook post-flight]
           → harvest + present improvements + encode                        (alias: --event plan-complete)
```

**Hooks the-flow wires: 4 fire-hooks** — `pre-flight` (at **two** edges: entry + each phase), `pre-coding`, `post-coding`, `post-flight`. **Skips 1**: the silent `coding` hook (in-flight friction capture is the harness's own concern once alive in-context).

```
Two-layer gate over the whole ⚙ column:
  L1  router installed?  test -f ~/.agents/skills/eng-harness-flow/SKILL.md
        miss → one warning, omit every ⚙ node for the rest of the flow
  L2  route the hook --json → act on envelope (route|redirect|noop|ambiguous)
        verdicts/labels narrated verbatim; never gates, never blocks
```

## Seam map (one row per wired hook)

| Where | `--hook` (context flags) | `--event` alias | Node | Produces |
|---|---|---|---|---|
| flow entry | `pre-flight` | `session-start` | *(none — detect + one calm line)* | — |
| post-plan refinement off `1b plan` | `pre-coding --spec <plan>` | `post-spec` | `backpressure` (`branch_of: plan`) | `backpressure-coverage.md` (advisory) → re-plan informed by it |
| before each phase | `pre-flight --phase <P> --plan-dir <p>` | `pre-implement` | `harness-boot` (`branch_of: phase`) | boot verdict (`healthy / SLOW / UNHEALTHY / UNAVAILABLE`) |
| each phase end | `post-coding --plan-dir <p>` | `phase-end` | `harness-retro` (`branch_of: phase`) | drains this phase → `.retro.md` |
| at merge (after `PROCEED`) | `post-flight --plan-dir <p>` | `plan-complete` | `harness-retro` (`branch_of: merge`) | harvest + present + encode |
| *(not wired)* mid-build | `coding` | `task-pause` | *(none)* | silent `harness observe` — the harness's own concern |

## Rules of engagement

- **Honored, not forced.** Every seam is a print-then-offer beat (dispatch invariants #1/#4) — the user accepts or waves past. Never auto-fired, never gates, never scores, never blocks.
- **Calm when absent.** Router not installed → one verbatim warning at flow entry, then every harness node/beat is omitted, silence after. Router installed but the repo **unprovisioned** → one calm session line, no per-phase nagging (no ghost nodes).
- **Direct-jump goes harness-less by design.** `/the-flow <id> <verb>` runs the bare verb with no seams — harness orchestration is the guided engine's job.
- **One door.** Every touchpoint is `/eng-harness-flow`; its child skills are private and never named. The literal harness command is printed as-is (it has no `/the-flow` Registry row, so it is *not* rendered through the flow's Command grammar).

## Vocabulary & runtime

`the-flow` **emits `--hook`** (the 021 lifecycle-hook surface), which assumes the **021 hook-aware router** is installed. `--event` is a **permanent alias** documented for back-compat *understanding* (and for reading an older router's envelope) — but the flow does **not** silently down-emit `--event`: an older `--event`-only router can't parse `--hook` and is a **runtime-dependency gap** (reinstall), not an automatic fallback. To make `--hook` live: merge/pull the 021 router and reinstall (`npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`).

## Keeping the mirror honest

When the upstream harness contract changes, re-read the live manifest and reconcile **one file** — `harness-seams.md` § Seam contract:

1. Run `/eng-harness-flow --hooks --json` → the 5-entry manifest (nine fields each).
2. Diff `hook` / `aliases` / `kind` / `produces` / `decision` / verdict tokens against the mirror.
3. Reconcile the seam map + mirror table in `harness-seams.md`; bump `harness_seam_contract` if any mirrored fact changed meaning. Regenerate this tree to match.
4. `just check-flow` + `just install-skills-from-source`.

Full procedure + the versioned mirror: `harness-seams.md` § Seam contract, and the plan record at [`docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md`](../plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md) § Maintenance & resync.
