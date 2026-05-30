# Real-Flow Examples — grounding for the-flow's narration

**Why this exists**: before implementing `the-flow`, I surveyed real SDD pipeline runs in `~/substrate/minih` (21 plans) and `~/substrate/chainglass` (40+ plans) to ground the narration in artifacts that actually get produced — not a template. This doc records what's real, where the-flow's [routing table](../workshops/001-narration-scripts-and-compact-contract.md) already matches reality, and the **gaps** real flows reveal.

> Read-only survey. Example paths are in the source repos, not this one.

---

## 1 · The artifact names the-flow keys on — CONFIRMED real

Every "discover artifact" entry in the workshop-001 routing table matches reality in both repos:

| Stage | the-flow expects | Real example (repo-relative) | ✓ |
|-------|------------------|------------------------------|---|
| 1a | `research-dossier.md` | `minih/docs/plans/007-backgrounding/research-dossier.md` | ✓ |
| 1b | `<slug>-spec.md` | `chainglass/docs/plans/001-project-setup/project-setup-spec.md` | ✓ |
| 2c | `workshops/*.md` | `minih/docs/plans/007-backgrounding/workshops/001-filesystem-layout.md` | ✓ |
| 2d | `backpressure-coverage.md` | **none found in 60+ plans** — brand new (built in plan-025) | ⚠️ novel |
| 3 | `<slug>-plan.md` | `minih/docs/plans/007-backgrounding/coordination-plan.md` | ✓ |
| flight | `<slug>.fltplan.md` | `chainglass/docs/plans/084-random-enhancements-3/multi-folder-tree.fltplan.md` | ✓ |
| 5 | `tasks/<phase>/tasks.md` (+ `tasks.fltplan.md`) | `chainglass/.../phase-1-monorepo-foundation/tasks.md` | ✓ |
| 6 | `execution.log.md` | `chainglass/.../phase-1-monorepo-foundation/execution.log.md` | ✓ |
| 7 | `reviews/*.md` | `chainglass/.../reviews/review.phase-1-monorepo-foundation.md` | ✓ |

**Implication**: T001's per-stage discovery logic is sound. No path changes needed.

---

## 2 · What the "one insight" looks like in real artifacts (grounds T002's narration)

The narration's "Did you notice X?" must pull from the artifact's high-signal field. Real shapes:

- **Execution log** records per-task `What I Did / Evidence / Files Changed`, and opens with a **`## Pre-Phase Harness Validation`** table whose rows literally read `🔴 UNAVAILABLE — No harness.md exists` → falls back to `npm build && test`. *(So the-flow's `awaiting-6` boot cue and "UNAVAILABLE is normal" framing is exactly right.)*
- **Code review** opens with a verdict — `APPROVE` / `REQUEST_CHANGES` — then a **Findings Table** `ID | Severity | File:Lines | Category | Summary | Recommendation` (e.g. `F001 | HIGH | src/adapter/sdk-copilot.ts:86-125 | correctness | …`). *(the-flow's `awaiting-7` "one finding" = the top-severity row.)*
- **Retro** (`docs/retros/*.md`) is real and matches the compound contract: timestamped `runId`, `summary`, **`magicWand`** (target + observation), and **`difficulties`** array tagged `[degrading|sustaining] knowledge|behavior`. *(Confirms the `[s/t/p/e/d/a]` drain prompt the-flow explains at `awaiting-6`.)*
- **Plan** carries the CS breakdown inline (`CS-4, S=2 I=1 D=2 N=2 F=1 T=2`) and a Domain Manifest. *(the-flow's `awaiting-3` reads `**Status**` + gate matrix.)*

---

## 3 · GAPS — real flows use branches the-flow's 11-stage map doesn't yet surface

These appear repeatedly in real plans but aren't in workshop-001's routing table. Each is a candidate optional branch the-flow could *surface* (still coach-only, still optional):

| Real branch | Evidence | Where it slots | the-flow today |
|-------------|----------|----------------|----------------|
| **External / deep research** (`external-research/*.md`) | minih 007/009 + chainglass 001/084 carry 2k-line Perplexity reports; `plan-1a` emits ready-to-run `/deepresearch` prompts | between `1a` and `1b` | **not surfaced** |
| **Prework / Phase-0 decision gate** (`prework-results.md`, scratch tests) | minih 007 `prework-results.md` ("FULL GO") gates entry to P1 | between `3` and `5`/`6` (a "prove the risky assumption" gate) | **not surfaced** (distinct from `/plan-2d`) |
| **Fix loop** (`fixes/FX001-*.{md,log.md,fltplan.md}`, `fix-tasks.*.md`) | chainglass 059 + plan-7 emits fix-tasks; fixes are first-class micro-plans | after `7` when review is `REQUEST_CHANGES` | partially — `awaiting-7` says "fix, re-run `/plan-7`" but doesn't name the FX artifact loop |
| **ADR** (`docs/adr/adr-NNNN-*.md`, `/plan-3a`) | chainglass `adr-0001…` global, plan-scoped references | around `3` when a decision needs recording | **not surfaced** |
| **Domains** (`docs/domains/registry.md` + `extract-domain`) | chainglass uses domains heavily (32-row registry, domain-map); minih does **not** | throughout, when a registry exists | **not surfaced** (this repo has no registry, so fine here — but the-flow runs in *other* repos too) |
| **Handover** (`handover.md`, `/util-0-handover`) | minih 001 handover doc | any pause/seam | **not surfaced** (overlaps with `/compact` intent) |

---

## 4 · Confirmations that de-risk the design

- **`/compact` leaves no artifact** anywhere — confirms it's a conversation-runtime action the-flow can only *recommend*, never detect via a file. The state-file + scan-resume design is the only way to survive it. ✓
- **Simple vs Full is real and labeled** (minih 014/018 Simple; chainglass 084 `Mode: Simple (single phase, 14 tasks)`). the-flow reading `**Mode**:` from the spec is grounded. ✓
- **Harness is genuinely optional** — minih runs entirely with `UNAVAILABLE` fallback; chainglass 076 actively uses `build→run→observe→fix`. the-flow must narrate both worlds (it does). ✓
- **`/plan-2d` backpressure is brand-new** — zero prior usage. the-flow surfacing it as *optional* (never assumed) is exactly correct. ✓

---

## 5 · Recommendation for implementation

The **core 11-stage flow is validated** — build T001/T002 as planned. The open question is **breadth**: real flows show ~6 extra optional branches (deep-research, prework gate, fix loop, ADR, domains, handover). Two ways to handle them without bloating v1:

- **A — Ship the spine now** (the 11 stages), add a single "other optional branches" mention at the relevant seams ("you can also `/deepresearch`, `/plan-3a` for an ADR, `/util-0-handover`…") — lightweight, honest, no new routing rows.
- **B — Extend the routing table** to first-class-handle the high-frequency ones (deep-research after 1a; the FX fix-loop after 7; domains when a registry exists) — richer, but more narration blocks + state stages to build and test.

Recommended: **A for v1** (keeps the transcription job small and matches the spec's "narration not plumbing" invariant), with B's additions logged as a fast-follow. The fix-loop (after `7`) is the strongest candidate to pull into v1 since review→fix→re-review is the most common real iteration.
