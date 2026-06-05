---
name: harnessability-assessment
description: |
  Point this at a repo to get a best-effort **harnessability assessment** — pros/cons plus a score across two axes: **Operate-Today** (how easily an agent can be driven through the repo's engineering-harness loop as it stands) and **Adaptability** (how cheaply the codebase's composition could be changed to become more agent-friendly). Read-only. Fans out into parallel probes (front-door, runtime/state, sensor inventory, structural metrics, test-as-latent-harness, and an opt-in git temporal-coupling pass), then aggregates → verifies evidence → rolls up a qualitative banded scorecard. Treats the **test suite as a latent harness** — surfaces seed/restore/inject machinery already present and what to *promote* into operable commands. Advisory only: the score informs a conversation, it is never a gate. Emits a two-letter axis tuple (plus an optional lossy Index), a per-dimension matrix, a "Latent Harness" promote-don't-build catalogue, and ranked remediations. Use for onboarding to an unfamiliar repo, brownfield triage, or deciding how much harness work a codebase needs before agent engineering. Design rationale: docs/plans/028-harnessability-assessment/research-dossier.md.
---

# harnessability-assessment

Assess how **harnessable** a codebase is — how readily a human or agent can operate, observe, prove, and safely change it through an engineering harness. Harnessability is a **property of the codebase** (Böckeler): brownfield systems often must be changed before they can be operated through a harness, so this skill scores both *using it today* and *adapting it*.

> **This is the workability/modifiability lens** the two sibling skills don't cover. `harness-1-boot` proves the harness is healthy *right now*; `plan-2d-backpressure-survey` checks a *feature's* outcomes are deterministically provable. This skill is the **whole-repo, on-demand modifiability scorecard** — and, unlike those two (deliberately score-free), it **is** allowed to emit a graded score, because its job is comparison and triage. It keeps that honest (see Advisory Invariant).

---

## 🟢 ADVISORY INVARIANT — read first, never violate

- **Read-only.** This skill never edits, scaffolds, or runs mutating commands. Every probe only reads.
- **Best-effort / advisory.** The score **informs a conversation, it never gates anything.** No pass/fail line, no threshold-as-policy, no blocking.
- **Evidence-mandatory-per-band.** Every band must carry an evidence `file:line`. A band with no resolvable evidence is invalid → demote to `Unknown`.
- **Tuple first, single number last.** Headline is a two-letter axis tuple (`Operate-Today · Adaptability`). The optional Index is printed *alongside, never instead of* the tuple and per-dimension matrix, and is explicitly flagged lossy. Never collapse to one gameable number.
- **Undetectable ≠ Absent.** When a signal can't be detected (tool missing, language unsupported, `--deep` not run), score it `Unknown` and **exclude it from the denominator** — never punish a repo for the assessor's blind spot. Always print "scored N of M".

If a future edit adds a gate, a hard threshold, or a single blocking score — that change is wrong, revert it.

---

## Input

```
$ARGUMENTS
# Flags:
# --repo <path>     Repo root to assess (default: current working directory)
# --deep            Add the expensive git temporal-coupling probe (B2). Default off.
# --weight <a/b>    Override the Operate-Today/Adaptability Index weighting (default 50/50)
```

This skill is **explicitly user-invoked** (a diagnostic), so it runs on request. If `docs/harness/.disabled` exists it still runs when directly invoked, but notes the harness loop is opted out.

---

## The two axes

### Axis A — Operate-Today (can the harness loop run now?)

| # | Dimension | Detect read-only |
|---|-----------|------------------|
| A1 | Cold-start orientation | `README`, `AGENTS.md`/`CLAUDE.md`, `docs/`, governance doc |
| A2 | One-command boot + health (<60s) | composite boot in `justfile`/`Makefile`/`package.json`; `docker-compose`; healthchecks |
| A3 | Seed / fixture / reset state | `seed`/`reset`/`fixtures` targets; migration+seed scripts |
| A4 | Smoke / E2E surfaces | `smoke`/`e2e` targets; Playwright/Cypress; documented smoke routes |
| A5 | Observability / evidence paths | log/trace dirs; `--json` flags; screenshot/artifact paths |
| A6 | CLI front door | `bin/`/`harness` CLI; `just` recipes; non-interactive flags |
| A7 | Existing back pressure / CI sensors | CI workflows, pre-commit, type/lint/test config |
| A8 | Agent-readable guidance | `AGENTS.md`/`CLAUDE.md`, skill files, `docs/project-rules/` |

> Axis A detects the **same signal classes** `harness-1-boot` probes live at session start — but **statically, repo-scoped**: does the machinery *exist in the repo*, not does it boot *right now*. Reuse harness-1-boot's signal-readiness vocabulary; don't clone its live checks.

### Axis B — Adaptability (how cheaply can composition change?)

| # | Dimension | Detect read-only |
|---|-----------|------------------|
| B1 | Structural coupling (Ca/Ce, instability, abstractness) | import-graph via dependency-cruiser/JDepend/NDepend |
| B2 | Change / temporal coupling *(deep, high-leverage)* | mine `git log`: support/confidence; co-change independent of static structure |
| B3 | Cohesion (LCOM) | static-analysis where available |
| B4 | Seams & substitutability | interfaces/ports/adapters; DI wiring; hand fakes; test-double usage |
| B5a | Unit isolation *(gradient)* | do unit tests run offline with no live services? in-memory adapters? |
| B5b | **Real-dependency integration proof** *(gradient — high weight)* | migration+seed in test setup/teardown; txn-rollback / restore-from-snapshot fixtures; Testcontainers / ephemeral DB / `docker-compose.test`; `it`/`integration`/`dbtest` targets; factories building real persisted state |
| B6 | Module boundaries / architecture | dependency-direction rules (`.dependency-cruiser`, ArchUnit, Roslyn); domain docs |
| B7 | Complexity & size thresholds | are CC / max-len / max-args / file-length rules *enabled* in lint config? |
| B8 | Inner-loop speed | unit/integration lane split; watch mode; build caching |

> **The test suite is a latent harness — read the test *support* code, not the test count.** How a repo tests reveals the affordances the harness can weaponise: how it injects, mocks/fakes, seeds databases, restores state, makes tests *real*. B5a (mock-it-out) and B5b (seed-a-real-DB-and-prove) are **distinct** — do **not** let a mock-everything repo outscore one with rich seeded-real-DB integration tests (#33/#34). B5b is high weight.

---

## Scoring

**Per-dimension band** (qualitative-first; points only enable the rollup):

| Band | Meaning | Points |
|------|---------|--------|
| Strong | present and proven; rely on it today | 3 |
| Partial | present but incomplete/undocumented/unenforced | 2 |
| Weak | largely absent but buildable in normal scope | 1 |
| Absent | not present, would need real work | 0 |
| **Unknown** | undetectable (tool/lang/`--deep` gap, or technique present-but-unclassified) — **excluded from denominator** | — |

Every band MUST carry an evidence `file:line`. No evidence → `Unknown`.

**Axis rollup**: `Axis % = sum(points of scored dims) / (count(scored dims) × 3)`, then band:

| Grade | Axis % | Reading |
|-------|--------|---------|
| A | ≥ 85% | agent-ready / highly modifiable |
| B | 70–84% | good; a few targeted gaps |
| C | 50–69% | workable but friction-heavy |
| D | 30–49% | brownfield; adapt first |
| E | < 30% | hostile to agent operation as-is |

(These cut-points are an advisory reading aid layered over the per-dimension evidence — never a gate.)

**Headline**: the two-letter tuple `Operate-Today: <grade> · Adaptability: <grade>`, plus "scored N of M dimensions" per axis. Optionally the labelled, lossy `Harnessability Index = w_a·A% + w_b·B%` (default 50/50) — printed alongside, never instead of, the tuple + matrix.

---

## Execution — parallel probe fan-out

Run the assessment as a read-only fan-out. Launch the probes **in parallel** (one subagent each), then run three sequential stages. **Order matters** — the rollup must run last, over the post-verify set.

### Stage 1 — Probes (parallel, read-only)

Each probe owns a disjoint slice and receives `{ repo_root, owned_dimension_ids[], deep }`. It returns, for each owned dimension: `{ id, band, detected, risk?, evidence: "file:line — …", note? }`, plus `undetectable[]` (`{id, band: "Unknown", reason}`), plus (latent-harness probe only) `latent_harness[]` (`{technique, evidence, promote_to}`).

| Probe | Owns | Reads |
|-------|------|-------|
| front-door | A1, A6, A8 | README/AGENTS/CLAUDE, CLI/just help, docs, governance doc |
| runtime-state | A2, A3, A4, A5 | just/make/package scripts, compose, healthchecks, seed/reset/smoke, log/trace/`--json` |
| sensor-inventory | A7, B7 | CI workflows, pre-commit, lint/type/test/analyzer configs (incl. complexity rules) |
| structural | B1, B3, B6 | import-graph (dependency-cruiser/JDepend/NDepend), topology, dep-direction rules |
| latent-harness *(headline)* | B4, B5a, B5b, B8 + catalogue | **test support code only**: conftest/fixtures/factories/`tests/fakes/`/testcontainers/compose-test, unit-vs-integration split |
| temporal-coupling *(only if `--deep`)* | B2 | full `git log` history mining |

Five probes by default; `temporal-coupling` joins only under `--deep` (in fast mode B2 → `Unknown` "deep-only"). A probe that can't detect a dimension returns it as `Unknown` with a reason — never guesses `Absent`.

### Stage 2 — Aggregate & roster-reconcile (barrier)

Wait for **all** probes. Then, no scoring yet:
1. Merge every probe's `dimensions[]`, `undetectable[]`, `latent_harness[]`.
2. **Reconcile against the fixed roster**: iterate the known probe→owned-dimension map; for any probe that failed/returned nothing, or any owned dimension it omitted, mark that dimension `Unknown` / reason `probe failed` and add to `undetectable[]`. This turns a crashed probe from silent dimension-loss into a visible degraded reading.
3. Assemble the (still unverified) latent-harness catalogue.

After this stage every one of the 17 dimensions is present as either scored or `Unknown`.

### Stage 3 — Verify (adversarial, before rollup)

- Every band's evidence must resolve to a real `file:line` containing the claimed signal. If not → demote to `Unknown` (reason `evidence unresolved`).
- Every `latent_harness[]` entry's evidence must point at real test-support code that actually contains the technique. Unverifiable → **drop** (no hallucinated "promote" suggestions reach the user).
- When in doubt, **drop/demote** rather than trust. (Guards false positives only; the test-recognition false-negative gap is a known limitation — emit `Unknown`/"unclassified", don't fake `Absent`.)

### Stage 4 — Roll-up & emit

Over the **post-verify** set: partition scored vs Unknown, compute the degraded-mode denominator + axis grades + tuple + (optional) Index, render the matrix, partition pros/cons off the `risk` flag, merge the verified latent-harness catalogue, rank remediations.

---

## Output format

```
HARNESSABILITY ASSESSMENT — <repo>                         <date>
Rating:  Operate-Today: C (58%, scored 8 of 8)  ·  Adaptability: B (74%, scored 8 of 9)
         Index: 66% (C, 50/50)   [lossy — see tuple + matrix]

AXIS A — OPERATE-TODAY                  Band      Evidence
  A1 Cold-start orientation ........... Strong    README.md + AGENTS.md + docs/
  …
AXIS B — ADAPTABILITY                   Band      Evidence
  …
  B2 Change/temporal coupling ......... Unknown   deep-only (run with --deep)
  B5b Real-dependency integration ..... Partial   tests/conftest.py:14 — Testcontainers PG; no restore

LATENT HARNESS  (techniques the tests already contain — promote, don't rebuild)
  • Real Postgres via Testcontainers (tests/conftest.py:14) → promote to `harness boot --with-db`
  • Factory-built state (tests/factories/) ................ → promote to `harness seed`
  • (gap) no per-test restore/rollback found ............. → add txn-rollback fixture → `harness reset`

STRENGTHS:    <Strong dims, one line each>
WEAKNESSES:   <Weak/Absent/Partial-with-risk dims, worst first>
REMEDIATIONS: <3–5 highest-leverage; PROMOTE existing test machinery before net-new; each ties to "encode the fix, not the memory">
```

Then a one-paragraph verdict, e.g. *"High-potential / low-operate-today: rich real-integration tests but no promoted harness commands — verdict: promote, don't build."*

---

## Composition (no duplication)

- **`harness-1-boot`** — session-start *live* signal-readiness. This skill reads the same signal classes *statically, whole-repo, on demand*. Reuse its vocabulary.
- **`plan-2d-backpressure-survey`** — *feature-scoped* deterministic-provability at design time. This skill is *repo-scoped + structural*. Reuse its `EXISTS/BUILDABLE/ABSENT` Status language for Operate-Today evidence — but note band-`Absent` ("would need work") ≠ plan-2d `ABSENT` ("legitimately inferential/human").
- **`engineering-harness-setup`** *provisions* the governance doc + harness; this skill *diagnoses* read-only. "Run engineering-harness-setup" is a legitimate **remediation** when the boot surface is Absent — closing the Improve loop.

## What this skill does NOT do

- No edits, scaffolding, or mutating commands — read-only.
- No gate, no pass/fail, no single blocking number.
- No product-specific sensor implementation — it reports what exists and what to promote; it never builds the smoke test, seed script, or CodeQL query itself.

## References

- Design rationale + cited sources + scoring derivation: `docs/plans/028-harnessability-assessment/research-dossier.md`
- Harness foundations: agent vs engineering harness, back pressure, encode-don't-document, measure ease-of-entry/safety-of-change/speed-of-proof (substrate first-principles #6, #54, #33, #34, #16, #53).
</content>
