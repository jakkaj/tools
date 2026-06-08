---
name: harness-2-backpressure
description: |
  Advisory deterministic-backpressure coverage survey. Runs AFTER the spec (plan-1b / plan-2c) and BEFORE the architect (plan-3). Inventories the deterministic sensors a repo already has (build / type / test / lint / smoke / boot / architecture checks, CodeQL / Roslyn / dependency-rules / data-scripts), derives the feature's experienced failure modes from the spec's acceptance criteria + target domains + risks, maps each criterion/failure-mode to a sensor (EXISTS / BUILDABLE / ABSENT × computational / inferential / human-judgement), emits a qualitative certainty rating (Strong / Partial / Weak), and — only when material behaviour/architecture gaps exist — recommends a "Phase 0: Establish Backpressure". Writes docs/plans/<ordinal>-<slug>/backpressure-coverage.md, which plan-3-v3-architect consumes. ADVISORY / best-effort only: never blocks, never flips a plan to DRAFT, no numeric thresholds, no persisted index. Honours docs/harness/.disabled.
---
Please deep think / ultrathink as this is a complex task.

# harness-2-backpressure

The **Backpressure Check** stage of the harness loop (Boot → **Backpressure Check** → Do Work and Observe → Retro and Magic Wand → Improve), wired into the SDD flow between the spec and the architect. A *Backpressure Check is distinct from back pressure itself*: it is an advisory, LLM-assisted look at the scoped work and the deterministic sensors the repo exposes — the proof still comes from the sensors, never from the LLM saying things look good.

Survey whether the planned work can be **proven by deterministic backpressure** — build failures, type errors, tests, lint, runtime/smoke checks, boot probes, architecture checks (dependency rules, ArchUnit, Roslyn analyzers, CodeQL), schema validators, data-check scripts — rather than by agent **inference** or human **eyeballing**.

This is the **computational-control tier pulled forward to design time**. It runs after the spec and before `plan-3-v3-architect`, so that *missing* backpressure is caught and planned for (as an optional "Phase 0") **before** code is written — not discovered late in `plan-7` review when it is expensive.

It is the deterministic counterpart to `plan-7-v2-code-review`. `plan-7` is the **inferential / eyeball** tier and stays exactly as-is; this skill surveys the **computational** tier. Both are legitimate (see *How this differs* below).

**Grounding** (harness-foundations):
- **Rule 3** — prefer deterministic validation over agent inference: "The agent can say it is done. The harness should decide whether that claim is supported by evidence."
- **Principle 16** — "Improving the harness means reducing friction and increasing deterministic back pressure."
- **Principle 33** — "Verification must cover experienced failure modes" — startup, integration, rendering, hydration, side effects, architecture drift, security boundaries — not just the failures that are easy to unit-test.
- **Pattern 18** — tier computational vs inferential controls; **run computational controls early and often**.

---

## 🟢 ADVISORY INVARIANT — read first, never violate

This skill is **best-effort and advisory**. It exists to *inform a conversation*, not to police one.

- It **NEVER blocks** anything and **NEVER flips a plan to DRAFT**.
- The certainty rating is **qualitative** (Strong / Partial / Weak). It emits **no numeric score, percentage, floor, or SLA**.
- It produces **one artifact** (`backpressure-coverage.md`) and **no persisted index / rollup / ledger** files. Cross-cutting views are recomputed at read time, never stored.
- The Recommended Phase 0 is a **recommendation**. The user (and `plan-3`) may take it or ignore it. It is never mandatory.

If a future change to this skill adds a threshold, a gate, a blocking behaviour, or a persisted index, that change is **wrong** — revert it.

---

## Sentinel check

If `docs/harness/.disabled` exists → **silently no-op**: do not run the survey, do not create or modify `backpressure-coverage.md`, do not log, do not prompt, do not error. The opt-out is absolute. (Mirrors `harness-3-observe`.)

---

```md
Inputs:
  SPEC_FILE  = `docs/plans/<ordinal>-<slug>/<slug>-spec.md`  (required)
  PLAN_DIR   = dirname(SPEC_FILE)
  OUT_FILE   = `${PLAN_DIR}/backpressure-coverage.md`  (sibling to research-dossier.md)
  Repo signals (read-only, all optional — probe recursively across the repo root AND every workspace/package root, never root-only):
    - workspace manifests: `pnpm-workspace.yaml`, `package.json#workspaces`, `Cargo.toml [workspace]`, `go.work`, `lerna.json`, `nx.json`
    - build/task files: `justfile`, `Makefile`, `package.json` scripts, `pyproject.toml`, `Cargo.toml`, `bin/dev`, `scripts/*`
    - test/e2e signatures: `**/playwright.config.*`, `**/cypress.config.*`, `**/vitest.*.config.*`, `**/jest.config.*`, `**/*.spec.*`, `**/*.e2e.*`, `connectOverCDP`
    - CI config (`.github/workflows/*`, `.gitlab-ci.yml`, etc.) — the de-facto PR proof gate
    - analyzer/architecture configs (`.dependency-cruiser.*`, `archunit`, Roslyn `.editorconfig`/`*.ruleset`, `codeql/`, JSON-schema files)
    - docs/governance (`engineering-harness.md` and legacy names) — CORROBORATION ONLY, never a precondition
  today {{TODAY}}.

## PHASE 0 — Setup

1. Sentinel: if `docs/harness/.disabled` exists → silent no-op, STOP.
2. Resolve SPEC_FILE (from --spec/--plan arg, the current plan folder, or an ordinal branch). If no spec exists → tell the user to run `/plan-1b-v3-specify-and-clarify` first and STOP. (This skill surveys against a spec; it does not invent one.)
3. Read the spec's `## Acceptance Criteria`, `## Target Domains`, and `## Risks & Assumptions`. These are the things the work must make true — the survey's subject.

## STEP 1 — Inventory existing deterministic sensors

Discover sensors by **surveying the filesystem for actual tooling**, not by reading what docs claim exists. Governance docs (`engineering-harness.md`, harness READMEs, recipe comments) are **corroboration only** — they are frequently absent or actively misleading, so they are never the source of truth and never a precondition for finding a sensor. Ground the inventory in files that exist on disk. (A backpressure skill discovering its own sensors by inference would contradict Rule 3 — so discovery here is deterministic by design.)

### 1a — Map the workspaces first (do NOT assume root)

Sensors commonly live one directory down in a sub-package, not at the repo root. Before probing, enumerate every workspace/package root:
- `pnpm-workspace.yaml`, `package.json#workspaces`, `lerna.json`, `nx.json` (JS/TS monorepos)
- `Cargo.toml [workspace]` (Rust), `go.work` (Go), `pyproject.toml` / `uv.workspace` (Python)
- Common harness locations even when no workspace manifest exists: `harness/`, `e2e/`, `tests/`, `test/`, `apps/*`, `packages/*`, `crates/*`

Run every probe below across **the root AND each discovered package root** — never root-only.

### 1b — Deterministic signature probes (glob, don't eyeball)

Run this signature checklist with recursive globs (`**/…`) across all roots from 1a. Each hit maps to a sensor class. Treat the list as **extensible and language-agnostic** — add signatures for stacks you encounter:

| Signature (recursive glob / file content) | Sensor class proven |
|---|---|
| `**/playwright.config.*`, `@playwright/test` in any `package.json` | real-browser DOM e2e |
| `connectOverCDP`, `:9222` in configs/fixtures | live-browser / CDP driving harness |
| `**/cypress.config.*`, `cypress/` dir | browser e2e |
| `**/*.spec.*`, `**/*.e2e.*` under `tests/` \| `e2e/` \| `test/` | e2e / integration suite |
| `jsdom`, `happy-dom`, `@testing-library/*` in vitest/jest config | component DOM tests |
| `**/vitest.*.config.*`, `**/jest.config.*` (all variants) | unit / component test entry points |
| `.dependency-cruiser.*`, ArchUnit, Roslyn `*.ruleset`, `codeql/` | architecture-fitness checks |
| `**/*.schema.json`, schema validators | data / contract integrity checks |
| build / test / lint / typecheck targets in `justfile` / `Makefile` / scripts | maintainability + behaviour gates |

**Enumerate ALL test entry points across ALL packages before classifying any dimension.** A loud-but-narrow signal — a root recipe named `test-e2e` commented "CLI only", or a `test-harness` wrapper that actually runs vitest — does NOT imply the corresponding browser/DOM sensor is absent. The real sensor may sit in another package under a differently-named wrapper. Confirm by glob, not by recipe name.

### 1c — Mine the named precedent (cheap, high-yield)

If the spec or `research-dossier.md` cites a **precedent feature** (a prior plan / component of the same shape), look at *how that precedent is tested* — its test files are a direct map of the available sensors. Following the precedent's own spec files often surfaces a nested harness immediately.

### 1d — Corroborate with docs + CI (optional, last)

Now read `engineering-harness.md` (or legacy), CI config (`.github/workflows/*` — the de-facto PR proof gate), and recipe comments to *enrich* what 1a–1c found: boot / health / validate / smoke / doctor commands, stated maturity. **If a doc disagrees with the filesystem, the filesystem wins.**

For each sensor found, capture: **name**, **command** (how to run it), the **dimension** it guards (Pattern 19: `maintainability` | `architecture-fitness` | `behaviour`), and **where it was found** (root or which package).

If **no signatures match after probing all roots**, record "no deterministic sensors found" *with the probe trail* (which §1b signatures were searched, across which roots) and expect certainty to trend **Weak** with a Recommended Phase 0. A missing governance doc is NOT itself evidence of absent sensors — when the doc is missing, the §1b sweep is the *only* ground truth, so run it thoroughly.

## STEP 2 — Derive this feature's experienced failure modes

From the spec's acceptance criteria, target domains, and risks, enumerate the concrete ways **this specific work** could be "green but wrong" (Principle 33). Do not limit to easy-to-unit-test failures. Consider: startup/boot, integration between components, rendering/hydration, side effects, **architecture drift** (boundary/dependency-direction violations), **contract breakage**, security-sensitive boundaries, and data integrity.

This is where the agent is encouraged to **get creative** about what *kind* of sensor each failure mode needs — anything from a one-line data-check script to a CodeQL query or a Roslyn analyzer, and everything in between.

## STEP 3 — Build the coverage matrix

One row per acceptance criterion / derived failure mode. For each, name the **deterministic sensor that would prove it** and classify:

- **Status** — `EXISTS` (a current sensor from Step 1 already proves it) | `BUILDABLE` (no sensor today, but one can be specified within plan scope) | `ABSENT` (cannot be proven deterministically — legitimately inferential/human, routed to plan-7 + human review, and that is fine).
- **Tier** (Pattern 18) — `computational` (deterministic check) | `inferential` (AI/eyeball review) | `human-judgement` (product/UX/taste decision).
- **Probe trail (REQUIRED for `ABSENT`)** — every `ABSENT` row must carry a one-line record of what was searched (the §1b signatures + which workspace roots), e.g. *"globbed `**/playwright.config.*`, `**/cypress.config.*`, `**/*.spec.*` under root + `harness/` + `packages/*` — no match"*. `ABSENT` is the most consequential verdict (it routes to manual gaps + a Phase 0), so it must never be asserted without evidence of having looked. An `ABSENT` row with no probe trail is a smell — re-run the §1b sweep before trusting it. (Mirrors `validate-v2`'s STANDALONE discipline. This is a *record*, not a gate — it adds no threshold and never blocks.)

A row being `ABSENT` / `inferential` / `human-judgement` is **not a failure** — some things genuinely cannot be proven by a machine. The matrix just makes the split explicit and honest.

## STEP 4 — Advisory verdict

### Certainty rating (qualitative — NO numbers)
Rate the deterministic coverage of the **behaviour + architecture** rows (maintainability gaps and inherently-inferential rows do not drag the rating down):
- **Strong** — every behaviour/architecture criterion has an `EXISTS` sensor.
- **Partial** — the behaviour/architecture gaps are `BUILDABLE` (sensors don't exist yet but are specifiable).
- **Weak** — material behaviour/architecture criteria are `ABSENT`, or no deterministic sensors were found at all.

State the rating with a **one-line rationale tied to the matrix** (e.g., "3 of 4 behaviour criteria have EXISTS sensors; the 4th is BUILDABLE → Partial").

### Recommended Phase 0 (conditional — routing trigger, NOT a threshold)
Include a **Recommended Phase 0: Establish Backpressure** table **iff** ≥1 behaviour/architecture criterion is `BUILDABLE` or `ABSENT` with no `EXISTS` sensor. **Omit** it entirely when all behaviour/architecture criteria are `EXISTS`, or when the only gaps are inferential / human-judgement / testing-doc rows.

(This is a *routing* decision about whether to print a table — not a quality bar, score, or pass/fail gate.)

Each Phase 0 row specifies a sensor to build: **what to build**, **what it proves** (which criterion/failure-mode), and a suggested **form** (data-check script / dependency-direction rule / ArchUnit / Roslyn analyzer / CodeQL query / smoke route / schema check).

## OUTPUT — write `${PLAN_DIR}/backpressure-coverage.md`

Overwrite if it exists (regeneration-safe). Use this template:

```markdown
# Backpressure Coverage — <feature>

**Spec**: [<slug>-spec.md](./<slug>-spec.md)
**Generated**: <today>
**Certainty**: Strong | Partial | Weak

> Advisory only — informs `plan-3`. Never blocks, never gates, no scores. (See harness-2-backpressure.)

## Existing Sensors (inventory)

| Sensor | Command | Dimension | Found in |
|--------|---------|-----------|----------|
| harness smoke | `just smoke` | behaviour | `harness/` |
| typecheck | `just typecheck` | maintainability | root |
| (none found) | — | — | — |

## Coverage Matrix

| Criterion / failure mode | Deterministic sensor | Status | Tier | Probe trail (required if ABSENT) |
|--------------------------|----------------------|--------|------|----------------------------------|
| <AC-1 / failure mode> | <sensor or —> | EXISTS / BUILDABLE / ABSENT | computational / inferential / human-judgement | <globs searched + roots, for ABSENT rows; — otherwise> |

## Certainty: <Strong|Partial|Weak>

<one-line rationale tied to the matrix>

## Recommended Phase 0: Establish Backpressure

<!-- Include this section ONLY if the routing trigger fires; otherwise omit the whole section. -->

| Sensor to build | Proves | Suggested form |
|-----------------|--------|----------------|
| <sensor> | <criterion / failure mode> | data-script / dep-rule / ArchUnit / Roslyn / CodeQL / smoke / schema |
```

## How this differs from plan-3 G6 and plan-7 (include a short note in the artifact if useful)

- **plan-3 Gate G6 (Testing Alignment)** checks that *test tasks exist* and acceptance criteria are *measurable* — it does not ask whether a deterministic **sensor covers the experienced failure modes**.
- **plan-7-v2-code-review** is the **inferential / eyeball** tier — human/AI judgement after the fact. Legitimate and unchanged.
- **harness-2-backpressure (this skill, alias `/plan-2d`)** surveys the **computational** tier *before* architecture: can the work be *proven deterministically*, and if not, should we build the sensor first?

## Graceful degradation

A missing `engineering-harness.md` is **not** evidence of missing sensors — undocumented repos are exactly where de-facto sensors are most likely present-but-undocumented. When the governance doc is absent, the STEP 1b signature sweep is the *only* ground truth, so run it thoroughly across all workspace roots (STEP 1a) before concluding anything. Only after that sweep comes back empty across every root do you report "no deterministic sensors found" (with the probe trail), classify the behaviour/architecture criteria honestly (mostly `BUILDABLE`/`ABSENT`), let certainty trend **Weak**, and recommend a Phase 0. Either way the survey is useful — it either finds the nested harness or tells the user the repo genuinely has weak backpressure for this work.
```

Next step:
- Review `backpressure-coverage.md`. If it recommends a Phase 0 you want, that recommendation is picked up automatically when you run **/plan-3-v3-architect** (it reads this artifact if present).
- Otherwise proceed straight to **/plan-3-v3-architect**.
- This skill is optional and idempotent — re-run any time the spec changes.
