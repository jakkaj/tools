---
name: plan-2d-backpressure-survey
description: |
  Advisory deterministic-backpressure coverage survey. Runs AFTER the spec (plan-1b / plan-2c) and BEFORE the architect (plan-3). Inventories the deterministic sensors a repo already has (build / type / test / lint / smoke / boot / architecture checks, CodeQL / Roslyn / dependency-rules / data-scripts), derives the feature's experienced failure modes from the spec's acceptance criteria + target domains + risks, maps each criterion/failure-mode to a sensor (EXISTS / BUILDABLE / ABSENT × computational / inferential / human-judgement), emits a qualitative certainty rating (Strong / Partial / Weak), and — only when material behaviour/architecture gaps exist — recommends a "Phase 0: Establish Backpressure". Writes docs/plans/<ordinal>-<slug>/backpressure-coverage.md, which plan-3-v3-architect consumes. ADVISORY / best-effort only: never blocks, never flips a plan to DRAFT, no numeric thresholds, no persisted index. Honours docs/compound/.disabled.
---
Please deep think / ultrathink as this is a complex task.

# plan-2d-backpressure-survey

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

If `docs/compound/.disabled` exists → **silently no-op**: do not run the survey, do not create or modify `backpressure-coverage.md`, do not log, do not prompt, do not error. The opt-out is absolute. (Mirrors `harness-2-observe`.)

---

```md
Inputs:
  SPEC_FILE  = `docs/plans/<ordinal>-<slug>/<slug>-spec.md`  (required)
  PLAN_DIR   = dirname(SPEC_FILE)
  OUT_FILE   = `${PLAN_DIR}/backpressure-coverage.md`  (sibling to research-dossier.md)
  Repo signals (read-only, all optional):
    - `docs/project-rules/engineering-harness.md` (canonical) | legacy `agent-harness.md` / `harness.md`
    - `justfile`, `Makefile`, `package.json` scripts, `pyproject.toml`, `Cargo.toml`, `bin/dev`, `scripts/*`
    - CI config (`.github/workflows/*`, `.gitlab-ci.yml`, etc.)
    - analyzer/architecture configs (`.dependency-cruiser.*`, `archunit`, Roslyn `.editorconfig`/`*.ruleset`, `codeql/`, JSON-schema files)
  today {{TODAY}}.

## PHASE 0 — Setup

1. Sentinel: if `docs/compound/.disabled` exists → silent no-op, STOP.
2. Resolve SPEC_FILE (from --spec/--plan arg, the current plan folder, or an ordinal branch). If no spec exists → tell the user to run `/plan-1b-v3-specify-and-clarify` first and STOP. (This skill surveys against a spec; it does not invent one.)
3. Read the spec's `## Acceptance Criteria`, `## Target Domains`, and `## Risks & Assumptions`. These are the things the work must make true — the survey's subject.

## STEP 1 — Inventory existing deterministic sensors

Probe the repo (read-only) for sensors that already exist and what each can prove. Sources, in order:
- `engineering-harness.md` (or legacy) — boot / health / validate / smoke / doctor commands and stated maturity.
- `justfile` / `Makefile` / `package.json` scripts / language build files — build, test, lint, typecheck, run, seed targets.
- CI config — what runs on PR (the de-facto proof gate).
- analyzer/architecture configs — dependency rules, ArchUnit, Roslyn analyzers, CodeQL queries, JSON schemas.

For each sensor found, capture: **name**, **command** (how to run it), and the **dimension** it guards (Pattern 19): `maintainability` | `architecture-fitness` | `behaviour`.

If **no sensors are found**, that is itself a finding: record "no deterministic sensors found" and expect the certainty to trend **Weak** with a Recommended Phase 0.

## STEP 2 — Derive this feature's experienced failure modes

From the spec's acceptance criteria, target domains, and risks, enumerate the concrete ways **this specific work** could be "green but wrong" (Principle 33). Do not limit to easy-to-unit-test failures. Consider: startup/boot, integration between components, rendering/hydration, side effects, **architecture drift** (boundary/dependency-direction violations), **contract breakage**, security-sensitive boundaries, and data integrity.

This is where the agent is encouraged to **get creative** about what *kind* of sensor each failure mode needs — anything from a one-line data-check script to a CodeQL query or a Roslyn analyzer, and everything in between.

## STEP 3 — Build the coverage matrix

One row per acceptance criterion / derived failure mode. For each, name the **deterministic sensor that would prove it** and classify:

- **Status** — `EXISTS` (a current sensor from Step 1 already proves it) | `BUILDABLE` (no sensor today, but one can be specified within plan scope) | `ABSENT` (cannot be proven deterministically — legitimately inferential/human, routed to plan-7 + human review, and that is fine).
- **Tier** (Pattern 18) — `computational` (deterministic check) | `inferential` (AI/eyeball review) | `human-judgement` (product/UX/taste decision).

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

> Advisory only — informs `plan-3`. Never blocks, never gates, no scores. (See plan-2d-backpressure-survey.)

## Existing Sensors (inventory)

| Sensor | Command | Dimension |
|--------|---------|-----------|
| harness smoke | `just smoke` | behaviour |
| typecheck | `just typecheck` | maintainability |
| (none found) | — | — |

## Coverage Matrix

| Criterion / failure mode | Deterministic sensor | Status | Tier |
|--------------------------|----------------------|--------|------|
| <AC-1 / failure mode> | <sensor or —> | EXISTS / BUILDABLE / ABSENT | computational / inferential / human-judgement |

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
- **plan-2d (this skill)** surveys the **computational** tier *before* architecture: can the work be *proven deterministically*, and if not, should we build the sensor first?

## Graceful degradation

If there is no `engineering-harness.md` and no recognizable build/test tooling, do not error. Report "no deterministic sensors found" in the inventory, classify the behaviour/architecture criteria honestly (mostly `BUILDABLE`/`ABSENT`), let the certainty trend **Weak**, and recommend a Phase 0. The survey is still useful — it tells the user the repo has weak backpressure for this work.
```

Next step:
- Review `backpressure-coverage.md`. If it recommends a Phase 0 you want, that recommendation is picked up automatically when you run **/plan-3-v3-architect** (it reads this artifact if present).
- Otherwise proceed straight to **/plan-3-v3-architect**.
- This skill is optional and idempotent — re-run any time the spec changes.
