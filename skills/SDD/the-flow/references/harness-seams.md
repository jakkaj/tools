# the-flow · harness seams — the flow-owned home for engineering-harness orchestration

The **single owner** of *where & when* the engineering harness is touched across the SDD flow. Loaded **lazily** by guided mode (`coach.md` + `00-routing.md`) only when the flow reaches a harness edge — progressive disclosure, the same way a stage's sub-skill is loaded only when its step is accepted. Direct-jump never loads it (direct-jump goes harness-less by design — `SKILL.md` § Two load paths).

> **The inversion (why this file exists).** Harness seams used to fire as **side-effects buried inside the stage sub-skills**, so the guided **engine** — which owns the rail, the narration, and the flight-plan nodes — never saw them: invisible, untracked, silently skipped. This file pulls every "should the harness run here, and how" decision **up into the flow**. The sub-skills under `references/stages/` are now pure **flow-blind *and* harness-blind verbs** — they describe only their own verb and carry **zero** harness knowledge (no `/eng-harness-flow` literal, no boot/backpressure/retro/observe concept). All harness knowledge lives in exactly three places: **this file** (where/when/whether), the **Graph** in `00-routing.md` (the edges that carry the seams), and the external **`/eng-harness-flow` router** (what actually happens behind the door). Nothing else.

> **One door, never its children.** Every harness touchpoint is the single entry point **`/eng-harness-flow`**. Its child skills are private and may move or rename — **never name or invoke them**. The only stable surface is `/eng-harness-flow` + its `--hook` vocabulary (and the permanent `--event` alias).

---

## How the engine presents a seam — a literal print-then-offer

A harness command is **not** a `/the-flow` command: it has no Registry row, so it is **never** rendered through the dispatch's § Command grammar or a `{{render-edge}}` slot. The engine prints it as a **literal** line — the same convention `coach.md` already uses for `/eng-harness-flow` — and then offers to run it, exactly under dispatch invariants **#1 (print-then-offer)** and **#4 (never gate)**:

1. **Print** the literal `/eng-harness-flow --hook … --json` line in a copyable block.
2. **Offer** to run it (one short line); the user accepts or waves past.
3. **On a clear go-ahead** → run it, narrate the envelope **verbatim**, advance *through* the corresponding flight-plan node (set its status), then continue the flow.

This is the mechanism that makes a seam **first-class**: the engine actually *offers and runs* the beat in guided mode — it never merely paints a node and moves on.

---

## Two-layer detection (relocated here — load-bearing)

**Layer 1 — is the router installed?** Probe once per flow: `test -f ~/.agents/skills/eng-harness-flow/SKILL.md` (fallback `~/.claude/skills/eng-harness-flow/SKILL.md`). On a **miss**, print exactly once, verbatim:

> ⚠️ No engineering harness detected — the eng-harness skills aren't installed. Continuing without one: standard testing applies, nothing else changes. (To add the harness loop: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`.)

…then **omit every harness node and beat for the rest of the flow** (record the outcome once in state; never re-warn). A repo without a harness is fully supported — never nag.

**Layer 2 — route the seam.** Router installed → call the seam with `--json` and act on the envelope (`decision: route | redirect | noop | ambiguous`):
- `route` → print-then-offer the returned command.
- setup-routing / `noop` (router installed but the repo is **unprovisioned** — no `.harness/`, no governance doc) → one calm line the first time (*"No engineering harness in this repo — proceeding without one; say 'set up a harness' anytime."*), then pass `--prompt-optional=false` on later seam calls so the user is never nagged per phase.
- Verdicts/labels are narrated **verbatim from the envelope** — never reimplement the router's checks. Boot vocabulary: `healthy / SLOW / UNHEALTHY / UNAVAILABLE`.

---

## The seam map — every edge, its hook, its node, its literal command

The flow wires **four fire-hooks** and deliberately **skips one** (the silent `coding` capture — mirroring its prior decision not to wire `task-pause`). `pre-flight` appears at **two** edges (flow entry and before each phase) — same hook, different context flags, different outcome.

| Graph edge / state | `--hook` (+ context flags) | `--event` alias | Emitted node | Literal command the engine print-then-offers |
|---|---|---|---|---|
| **flow entry** (`start`) | `pre-flight` | `session-start` | *(usually none — detection + one calm line only)* | `/eng-harness-flow --hook pre-flight --json` |
| **post-plan refinement** off `awaiting-1b` | `pre-coding` `--spec <plan path>` | `post-spec` | `backpressure` (`branch_of: "plan"`) | `/eng-harness-flow --hook pre-coding --spec "<plan path>" --json` |
| **before each phase** (into a `phase`) | `pre-flight` `--phase "<Phase N>" --plan-dir <p>` | `pre-implement` | `harness-boot` (`branch_of: "<phase-id>"`) | `/eng-harness-flow --hook pre-flight --phase "<Phase N: Title>" --plan-dir "<plan dir>" --json` |
| **each phase end** (out of a `phase`) | `post-coding` `--plan-dir <p>` | `phase-end` | `harness-retro` (`branch_of: "<phase-id>"`) | `/eng-harness-flow --hook post-coding --plan-dir "<plan dir>" --json` |
| **at merge** (after typed `PROCEED`) | `post-flight` `--plan-dir <p>` | `plan-complete` | `harness-retro` (`branch_of: "merge"`) | `/eng-harness-flow --hook post-flight --plan-dir "<plan dir>" --json` |
| **mid-build** (we do **not** wire this) | `coding` | `task-pause` | *(none — silent CLI capture, the harness's own concern)* | *(unwired — see § Seam contract)* |

**What each beat is *for* (narration source):**
- **`pre-flight` @ entry** — detect the router, narrate one calm line; no node.
- **`pre-coding` @ post-plan** — the backpressure survey: *can the planned work be proven by deterministic sensors, or only eyeballed?* Produces `backpressure-coverage.md` — **advisory output**: re-run the **plan** verb *informed by* it (the harness-blind plan verb does **not** auto-read the file; you fold what you learned into the re-plan intent). Offered as an optional post-plan refinement, never forced.
- **`pre-flight` @ phase** — the router proves the system **boots** before a line of code; verdict narrated verbatim (`healthy → build` · `SLOW → build with a note` · `UNHEALTHY → stop and ask the human: Retry / Continue without harness / Abort` · `UNAVAILABLE → standard testing`).
- **`post-coding` @ phase end** — drain **this phase's** friction notes → `.retro.md` (the router owns drain-vs-harvest; the user may see a `[s/t/p/e/d/a]` prompt).
- **`post-flight` @ merge** — the long-horizon reflection: harvest + present improvements + encode.

---

## Node emission — provisioning is the gate for per-phase nodes

**Per-phase harness nodes (`harness-boot`, `harness-retro`, and the `backpressure` excursion) are emitted only when the router is *installed* AND the repo is *provisioned*.** "Emit when installed" governs *session-level detection* (the `pre-flight` @ entry beat, which carries no node anyway); it does **not** stamp per-phase nodes on an unprovisioned repo. One rule, so the three surfaces agree:

- Router **not installed** (Layer-1 miss) → **no** harness nodes at all; the spine renders unbroken (the unified `plan` node connects straight to the first `phase`).
- Router **installed, repo provisioned** → per-phase harness nodes run their normal lifecycle (`assumed → done`), styled `:::harness` (violet).
- Router **installed, repo unprovisioned** → **no per-phase harness nodes** — just the one calm session line (Layer 2 `noop`). Do **not** stamp an "adopt-to-activate" node on every phase; per-phase nagging is the failure mode this rule prevents.

This makes the **three emission surfaces** agree:
1. **Flight-plan node** (`the-flow.json`) — a per-phase harness node appears only when installed **and** provisioned (above).
2. **Rail companion line** (`coach.md`) — shown only when the router actually **reported this session** (its envelope carried a `rail`/`now`/`next`); omit it until then (no empty scaffolding).
3. **Narration beat** — the print-then-offer at the edge, governed by Layer 2.

---

## Per-phase retro lifecycle — one node per phase, "owed" re-derived

The `post-coding` (phase-end) seam is a **first-class beat per phase**, not a buried side-effect: one `harness-retro` node per `phase`, `branch_of` that phase, on an `assumed → done` lifecycle.

- **"Drain owed" is re-derived, not stored** — no new state file. A phase whose node is `done` while its `harness-retro` sibling is still `assumed`/absent ⇒ that phase's drain is owed. The flight-plan node **is** the durable record (existing `status` + `branch_of` fields suffice — KISS, no rollup).
- **Drain before harvest.** At phase/session end the router drains the non-empty buffer first; harvest (the `post-flight` beat at merge) reads `.retro.md`. The router owns that ordering — the flow just offers the beat at the edge.

---

## Honored, not forced

Every seam is a **print-then-offer beat the engine presents at the edge** (invariants #1/#4) — the user accepts or waves past. Seams are **never** auto-fired, **never** gate, **never** score, **never** block. Best-effort throughout: a router that's missing, a repo that's unprovisioned, or an `UNAVAILABLE` verdict all fall back to standard testing with at most one calm line.

---

## Not-installed & unprovisioned — the silent paths (summary)

| Situation | What the flow does |
|---|---|
| Router **not installed** | one verbatim warning at flow entry, then **omit every harness node + beat**, silence after |
| Router installed, repo **unprovisioned** | one calm session line, `--prompt-optional=false` thereafter, **no per-phase nodes/nagging** |
| Verdict `UNAVAILABLE` at a seam | note it, proceed with standard testing (not an error) |
| Verdict `UNHEALTHY` at the boot seam | stop and ask the human: Retry / Continue without harness / Abort |
| User says "don't use the harness" | conversational opt-out — stop calling the router (there is **no** sentinel file) |

---

## Seam contract (mirrors eng-harness-flow)

> **`harness_seam_contract: v1`** — this is the durable mirror of the small slice of the external harness contract that the flow depends on. It is the **one place to edit** when the upstream contract changes. This block is the in-skill copy of the plan's `## Maintenance & resync` record (`docs/plans/033-flow-owned-harness-seams/flow-owned-harness-seams-plan.md`).

**What we mirror (the dependency surface):**

| Facet | Value (v1, 2026-06-17) |
|---|---|
| `harness_seam_contract` | `v1` — the 021 five-hook contract; **bump** when any mirrored fact below changes meaning (a hook renamed, an alias remapped, a verdict added) |
| Hooks we **wire** (emit `--hook`) | `pre-flight` (flow entry **and** before each phase) · `pre-coding` (post-plan) · `post-coding` (each phase end) · `post-flight` (at merge) |
| Hook upstream has, we **don't** wire | `coding` — the silent `harness observe "<what>" --kind <kind>` capture (one buffer entry per call); mirrors the deliberate prior `task-pause` skip. The harness owns in-flight capture once alive in-context; the flow never drives it |
| `--event` alias (permanent) | `session-start`→`pre-flight` · `pre-implement`→`pre-flight` · `post-spec`→`pre-coding` · `phase-end`→`post-coding` · `plan-complete`→`post-flight` · `task-pause`→`coding`. The flow **emits `--hook`**; `--event` is retained only for **back-compat understanding** — mapping/reading an older router's envelope, never a command the flow emits or down-emits (an older router is a runtime-dependency gap → reinstall, not an automatic fallback) |
| Envelope `decision` | `route` · `redirect` · `noop` · `ambiguous` (+ an additive `hook` field on every routing envelope) |
| Boot verdicts | `healthy` · `SLOW` · `UNHEALTHY` · `UNAVAILABLE` |
| Node types this maps to | `backpressure` · `harness-boot` · `harness-retro` (defined in `flight-plan.schema.json`) |
| Slug rule | friendly name → installed slug; **never append a guessed version suffix** |

**Upstream source-of-truth (authority, in priority order):**

1. **Live manifest (preferred resync anchor)** — `/eng-harness-flow --hooks --json` → Shape A `{ manifest_version, hooks[5] }`, nine fields per hook (`hook`, `intent`, `run_at`, `kind`, `invoke`, `aliases`, `produces`, `needs`, `preconditions`). Machine-readable and version-stamped — **re-read it, don't hand-diff prose.**
2. **Source SKILL.md** (the `AI-Substrate/harness-engineering` repo) — `skills/eng-harness-loop/eng-harness-flow/SKILL.md` §§ **Lifecycle hooks** (the five hooks + the `--event`→`--hook` alias map), **The `--hooks` discovery manifest** (the nine-field contract), **The `--json` routing envelope** (`decision` enum + additive `hook` + boot verdicts), **Parameter contract** (`--hook` / `--event` / flag surface).
3. **Runtime probe** (detection, not contract) — installed at `~/.agents/skills/eng-harness-flow/SKILL.md` (fallback `~/.claude/skills/…`); what Layer 1 tests.

**Resync procedure — when the harness family or its hooks change:**

1. Run `/eng-harness-flow --hooks --json` and read the 5-entry manifest (or, if the router is uninstalled, read the source SKILL.md §§ above).
2. Diff its `hook` / `aliases` / `kind` / `produces` / `decision` / verdict tokens against the mirror table above.
3. Reconcile the **seam map** and the **mirror table** in this file; if any mirrored fact changed meaning, **bump `harness_seam_contract`** and note what changed.
4. `just check-flow` (L1–L6) + redeploy `just install-skills-from-source`.

**Why no script.** A drift-check script was considered and **declined** — the `--hooks --json` manifest + this procedure are the contract; this file is the one file to edit.

**Runtime dependency (honesty).** The flow **emits `--hook`**, which assumes the **021 hook-aware router** is installed (≥478-line SKILL.md). An older `--event`-only router cannot parse `--hook`, and the flow does **not** silently down-emit `--event` — an older router is a **runtime-dependency gap**, surfaced as a reinstall prompt, not an automatic fallback. The `--event` alias column above documents the hook→event mapping for back-compat *understanding* (and for reading an older router's envelope), not a command the flow emits. To make `--hook` live: merge 021→main + push in the harness repo, then reinstall (`npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`).

---

> **Keep in sync, single-source.** The hook-woven flow tree in `docs/how/the-flow-harness-seams.md` (Appendix A of the plan) is a **rendered view** of the seam map above — when the seam map changes, regenerate that tree; never let it become a second source.
