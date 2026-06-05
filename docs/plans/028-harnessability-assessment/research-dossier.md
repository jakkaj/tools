# Research Dossier — Harnessability Assessment Skill

**Status**: Pre-spec research (design exploration)
**Created**: 2026-06-04
**Purpose**: Define what a full **harnessability-assessment** skill would look like — a skill you point at a repo that returns pros/cons plus a **harnessability score** across two axes (Operate-Today, Adaptability).
**Method**: deep-research workflow (23 sources fetched, 110 claims extracted, 25 adversarially verified at 3-vote, 25/25 confirmed) reconciled against the local harness-engineering substrate (`/Users/jordanknight/substrate/harness-engineering/harness-foundations/`).

> **What this document is.** A grounded design proposal, not a built skill and not a spec. The *concepts* (harnessability, back pressure, coupling/cohesion, seams, hermetic testing, SQALE bands) are cited from primary/peer-reviewed sources. The *invented parts* (the two-axis split, the bands, the rollup formula) are this skill's own proposed rubric, defended on first-principles grounds — **not** presented as cited fact. Where that line falls is marked explicitly.

---

## 1. Executive summary

### Two harnesses, don't conflate them

- **Agent harness** — the runtime that drives the model (Claude Code, Copilot, Codex, Cursor, pi). Makes the *model* operable.
- **Engineering harness** — the project-side loop that helps an agent work *on your codebase*: **Boot → Backpressure Check → Do Work and Observe → Retro and Magic Wand → Improve**. Makes the *product* operable. ([substrate `simple-mode.md`]; first-principles #1, #2)

The agent harness can *drive* the engineering harness but cannot *replace* it — only the project-side harness can prove the actual software behaves correctly (first-principles #3).

### Back pressure

**Back pressure** is the deterministic signal that tells an agent how it is *truly* doing rather than what it *infers*: build failures, type errors, tests, lint, runtime/smoke checks, boot probes, architecture checks, CodeQL/analyzers, schema/data checks ([substrate `simple-mode.md`]; Banay, *Don't waste your back pressure* — https://banay.me/dont-waste-your-backpressure/). Böckeler frames the harness as *"a system of guides and sensors that increase the probability of good agent outputs and enable self-correction before issues reach human eyes"* (https://martinfowler.com/articles/sensors-for-coding-agents.html). Note the hedged *"increase the probability of"* — consistent with the substrate's best-effort/advisory spirit; sensors are not guarantees.

A **Backpressure Check** is *not* the back pressure itself — it is an advisory, LLM-assisted survey of whether the scoped work has *enough* deterministic sensors. The proof still comes from the sensors, never from the LLM saying it looks good (first-principles #10).

### Harnessability — the property this skill scores

> **Harnessability is a property of the codebase** (first-principles #6, citing Böckeler, https://martinfowler.com/articles/harness-engineering.html). "Some products, especially brownfield systems, must be changed before they can be operated effectively through a harness."

The load-bearing rationale (verified, high confidence): *"Internal quality problems affect AI agents in similar ways that they affect human developers. An agent working in a tangled codebase might look in the wrong place for an existing implementation, create inconsistencies because it has not noticed a duplicate, or be forced to load more context than a task should require."* (https://martinfowler.com/articles/sensors-for-coding-agents.html). Agents have bounded context windows; poor modularity *pollutes* that context. **Modifiability is a core component of harnessability** — it is the Adaptability axis (B); Operate-Today (A) is the other half. (Substrate #6 says harnessability is a property of the codebase requiring change before operation; it does not collapse the whole property to modifiability — this dossier keeps both axes.)

This produces the two axes the skill scores:

- **Axis A — Operate-Today**: can a fresh agent be driven through this repo's engineering-harness loop *as it stands today*? (ease of entry, speed of proof — first-principles #54)
- **Axis B — Adaptability**: how *cheaply* could the codebase's composition be changed to become more agent-friendly? (safety of change — first-principles #54)

The substrate explicitly says to *"measure ease of entry, safety of change, speed of proof, and compounding"* (first-principles #54) and to *"measure facts separately from interpretation"* (#53) — these directly justify the two-axis split and the evidence-then-classification scoring style below.

---

## 2. The two-axis model

Each dimension below states: **what it measures · why it matters for agents · how to detect it read-only · the metric/evidence behind it.**

### Axis A — Operate-Today (can the harness loop run now?)

| # | Dimension | What it measures | Why it matters for agents | Read-only detection | Evidence / source |
|---|-----------|------------------|---------------------------|---------------------|-------------------|
| A1 | **Cold-start orientation** | Can a fresh agent answer *what is this / how to run / how to verify / where does work stand* from repo contents alone? | Every session is a fresh dev onboarding; missing orientation = inferred (paid-for) context | `README`, `AGENTS.md`/`CLAUDE.md`, `docs/`, a governance doc (`engineering-harness.md`) | substrate first-principles #11a, #39; `simple-mode.md` |
| A2 | **One-command boot + health (<60s)** | Is there a composite boot that builds/starts/waits-for-ready and proves it with a health/smoke route? | Boot is the *first proof*; agents burn 25+ min inferring how to run things otherwise | `justfile`/`Makefile`/`package.json` scripts for `dev`/`boot`/`up`; `docker-compose`; healthcheck endpoints | first-principles #11, #11c, #12 |
| A3 | **Seed / fixture / reset state** | Can the system be put in a known, meaningful state and reset idempotently? | A system that boots but is empty is still hard to explore/validate; repeated runs are normal | `seed`/`reset`/`fixtures` targets; migration + seed scripts; factory/fixture dirs | first-principles #23, #37 |
| A4 | **Smoke / E2E surfaces** | Are there deterministic routes/commands that exercise *real* user behaviour end-to-end? | E2E pressure makes agents prove real workflows, not locally-plausible code | `smoke`/`e2e` targets; Playwright/Cypress configs; documented smoke routes | first-principles #13, #33, #34 |
| A5 | **Observability / evidence paths** | Can behaviour be made portable — logs, traces, screenshots, DB checks, structured responses? | "Done" must be backed by evidence, not agent confidence | log/trace dirs; `--json` output flags; screenshot/artifact paths | first-principles #14, #28, #40 |
| A6 | **CLI front door** | Is there one obvious, discoverable, agent-operable surface (verbs, `--help`, exit codes, parseable output)? | Agents are very good at CLIs; the paved path must beat the shortcut | a `bin/`/`harness` CLI; `just` recipes as façade; non-interactive flags | first-principles #4, #19, #20, #21; Directive 6 |
| A7 | **Existing deterministic back pressure / CI sensors** | What does the repo *already* prove deterministically on every change? | This is back pressure already paid for; the richer it is, the less the agent infers | CI workflows (`.github/workflows`), pre-commit hooks, type/lint/test config | Böckeler *sensors-for-coding-agents*; first-principles #16, #27 |
| A8 | **Agent-readable guidance** | Versioned, map-not-manual instructions for boot/run/observe/validate/improve | Knowledge not in the repo is invisible to the agent | `AGENTS.md`/`CLAUDE.md`, skill files, `docs/project-rules/` | first-principles #24, #38, #39 |

### Axis B — Adaptability (how cheaply can composition be changed?)

This axis is where the established software-design metrics live. SonarQube's standard set **deliberately excludes** coupling/cohesion (deprecated ~v5.2) (https://docs.sonarsource.com/sonarqube-server/user-guide/code-metrics/metrics-definition) — so these must be sourced from dependency-graph tools (dependency-cruiser / JDepend / NDepend) and **VCS mining**, not from a Sonar score.

> **The test suite is a latent harness — read the test *support* code, not the test count.** The single richest read-only signal of a codebase's adaptability is *how its tests already operate the system*: how they inject, mock/fake, seed databases, restore state, and make tests "real". That machinery (`conftest.py`, fixtures, factories, base test classes, test helpers, `testcontainers`/compose-test setup, `tests/fakes/`) is prior art for harnessability — someone already solved boot/seed/substitute/prove, and the harness's job is to **weaponise those techniques, not reinvent them** (#4 the harness can wrap existing tools rather than reimplement them — the precise warrant for "promote, don't reinvent"; #25 dogfood the supported surface; Directive 4 / #18 encode-the-fix-not-the-memory; #23 seed data is product surface). So the Adaptability probe greps the test harness, not the assertions — what seams exist there reveals what an agent can lift into an operable surface. This is also why hermetic isolation (B5a) and real-dependency proof (B5b) are scored as **two distinct dimensions**, not one: they are opposite philosophies (mock-it-out vs seed-a-real-DB-and-prove), both legitimate, and the skill must not silently reward the former over the latter.

| # | Dimension | What it measures | Why it matters for agents | Read-only detection | Evidence / source |
|---|-----------|------------------|---------------------------|---------------------|-------------------|
| B1 | **Structural coupling** | Afferent (Ca) / efferent (Ce) coupling, instability `I = Ce/(Ca+Ce)`, abstractness, distance from main sequence | High coupling = large blast radius; an agent change ripples unpredictably | import-graph fan-in/fan-out via dependency-cruiser/JDepend/NDepend; module dependency counts | Martin package metrics (https://en.wikipedia.org/wiki/Software_package_metrics) |
| B2 | **Change / temporal coupling** *(highest-leverage)* | Artifacts that co-change in git history independent of static structure | Exposes hidden dependencies static analysis **cannot see**; directly measures real blast radius | mine VCS history: association-rule **support** (count of co-revisions) + **confidence** (P(B changes \| A changes)); CodeScene's three mechanisms (same commit / same author in timeframe / same ticket) | D'Ambros/Lanza/Robbes (https://www.ime.usp.br/~gerosa/papers/changecoupling.pdf); CodeScene (https://docs.enterprise.codescene.io/versions/3.2.9/guides/technical/temporal-coupling.html); IEEE 5328803 |
| B3 | **Cohesion** | LCOM — do a module's parts belong together? | Low cohesion forces an agent to load more context per task | LCOM via static-analysis tools where available (language-dependent) | Martin metrics; substrate #6 rationale |
| B4 | **Seams & substitutability** | Can behaviour be replaced *without editing in place*? Are there interfaces/ports + DI wiring + test doubles? | Seams are *the* property that makes code testable in isolation — and thus safely changeable | presence of interfaces/ports/adapters; DI container/wiring; hand-written fakes; test-double usage in tests | Feathers' "seam" (https://www.informit.com/articles/article.aspx?p=359417&seqNum=2); Fowler *TestDouble* (https://martinfowler.com/bliki/TestDouble.html), *MocksArentStubs* (https://martinfowler.com/articles/mocksArentStubs.html); Android test-doubles (https://developer.android.com/training/testing/fundamentals/test-doubles) |
| B5a | **Unit isolation** *(gradient)* | Can a unit run without standing up Postgres/Redis/live APIs, offline? | Fast, reliable inner loop = the agent can self-correct cheaply before involving a human | does `pytest`/`npm test` run offline with no external services? in-memory adapters / hand fakes? | Android (hermetic test def); Fowler *TestDouble* |
| B5b | **Real-dependency integration proof** *(gradient — high weight)* | Does the repo seed/restore a **real** DB or service and assert real behaviour against it? | The strongest deterministic back pressure there is — catches the "green but wrong" failures (#33: startup, integration, side effects) that mocked units miss; #34 E2E pressure makes agents prove real workflows | migration+**seed** wired into test **setup/teardown** (not just dev seed); **txn-rollback / restore-from-snapshot** fixtures; Testcontainers / ephemeral DB / `docker-compose.test`; dedicated `it`/`integration`/`dbtest` targets; factories building real persisted state | Testcontainers (https://testcontainers.com/guides/introducing-testcontainers/); Pact (https://docs.pact.io/); substrate #33, #34, #16 |
| B6 | **Module boundaries / architecture clarity** | Are there enforced boundaries (hexagonal / ports-and-adapters / clean architecture)? | Clear boundaries shrink the context an agent must hold and the blast radius of a change | dependency-direction rules (`.dependency-cruiser`, ArchUnit, Roslyn); directory topology; domain docs | hexagonal architecture (https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)) |
| B7 | **Complexity & size thresholds** | Cyclomatic complexity, function length, file length, max function args | Böckeler names these as the AI failure modes that are *"the most low-hanging fruit for static analysis"* — and notes they're **not on by default** | lint config: are these specific rules *enabled*? compute CC where feasible | Böckeler *sensors-for-coding-agents*; Maintainability Index (cite at authoring) |
| B8 | **Inner-loop speed** | Time from edit → feedback (unit lane separate from slow integration lane) | Loop time is a first-class metric; slow loops cap how often an agent can self-correct | test split (unit vs integration targets); watch mode; build caching config | first-principles #17 |

> **B5a/B5b caveat (verified):** Testcontainers needs a Docker runtime and Pact doesn't replace *all* integration testing — so both are scored as a **gradient**, never a binary "hermetic ✓". Note B5a and B5b can *both* be Strong: a healthy repo isolates units cheaply **and** has real seeded-DB integration tests; the skill rewards the combination, and treats a mock-everything repo with no B5b as a real adaptability gap, not a clean pass.

---

## 3. Proposed scoring system *(this is the invention — defended, not cited)*

The substrate forbids vanity metrics: *measure facts separately from interpretation* (#53), *measure encoded improvement, not activity volume* (#49), *keep it low ceremony* (#51). SonarQube's single configurable A–E number is the cautionary prior art — *gameable* (Goodhart) once it becomes a target (https://axify.io/blog/goodhart-law; https://www.infoq.com/articles/dora-metrics-anti-patterns/). So the design rule is: **evidence first, bands second, single number last and clearly labelled as lossy.**

### 3.1 Per-dimension rubric — qualitative bands

Each of the 17 dimensions (8 Operate-Today + 9 Adaptability) is scored on a 4-band scale (qualitative-first; the parenthetical points exist *only* to enable an optional rollup):

| Band | Meaning | Points |
|------|---------|--------|
| **Strong** | Sensor/property present and proven; an agent can rely on it today | 3 |
| **Partial** | Present but incomplete, undocumented, or unenforced | 2 |
| **Weak** | Largely absent but *buildable* within normal scope | 1 |
| **Absent** | Not present and would need real work to add | 0 |

Every band MUST carry **evidence** (the file/command/metric that justifies it) — a band with no evidence is invalid. This is the #53 "facts separate from interpretation" rule made mechanical.

### 3.2 Axis rollup → letter grade

Sum the dimension points per axis, normalise to a percentage of the axis maximum (A: 8 dims × 3 = 24; **B: 9 dims × 3 = 27** — note B5a and B5b are two separately-scored dimensions, so Axis B has 9 rows, not 8), then band into a letter grade. The band cut-lines below are **invented** (not cited): they borrow SonarQube's fixed-threshold *style* — but SonarQube's A–E Maintainability Rating bands a technical-debt *ratio*, **not** a percentage-of-max (https://docs.sonarsource.com/sonarqube-server/user-guide/code-metrics/metrics-definition), so the specific 85/70/50/30 cut-points here are this rubric's own proposal, not prior art. They are an **advisory reading aid layered over the mandatory per-dimension evidence — never a pass/fail line and never wired to a gate** (see §6 Q4):

| Grade | Axis score | Reading |
|-------|-----------|---------|
| **A** | ≥ 85% | Agent-ready / highly modifiable |
| **B** | 70–84% | Good; a few targeted gaps |
| **C** | 50–69% | Workable but friction-heavy |
| **D** | 30–49% | Brownfield; needs adaptation first |
| **E** | < 30% | Hostile to agent operation as-is |

### 3.3 Overall harnessability rating — the two-tuple, not one number

The headline is a **two-letter tuple**, e.g. `Operate-Today: C · Adaptability: B` — deliberately **not** collapsed to a single grade, because the two axes answer different questions and averaging them hides the actionable story (a `B / E` repo and a `E / B` repo need opposite remediations but would average identically).

**If** a single comparable number is required (the user asked for one), provide it as an explicit, labelled weighted blend with a stated default and let it be overridden:

```
Harnessability Index = 0.5 · OperateToday% + 0.5 · Adaptability%   (default, equal weight)
```

…printed *alongside* the tuple and the per-dimension table, never instead of them. The 50/50 default is **arguable, not derived** (see Open Questions §6) — equal weight says "a repo unusable today blocks all work" and "brownfield value compounds from modifiability" are equally important until evidence says otherwise.

### 3.4 Example output matrix

```
HARNESSABILITY ASSESSMENT — <repo>                         2026-06-04
Rating:  Operate-Today: C (58%)  ·  Adaptability: B (75%)  ·  Index: 66% (C)

AXIS A — OPERATE-TODAY                                 Band      Evidence
  A1 Cold-start orientation .................. Strong   README + AGENTS.md + docs/
  A2 One-command boot + health (<60s) ....... Weak     no boot recipe; manual 3-step start
  A3 Seed / fixture / reset ................. Partial  seed script, no reset
  A4 Smoke / E2E surfaces ................... Absent   no smoke/e2e targets found
  A5 Observability / evidence .............. Partial  logs only; no --json, no traces
  A6 CLI front door ........................ Strong   `just` recipes, non-interactive
  A7 Existing back pressure / CI ........... Strong   typecheck+lint+test in CI
  A8 Agent-readable guidance ............... Partial  AGENTS.md present, stale in parts

AXIS B — ADAPTABILITY                                  Band      Evidence
  B1 Structural coupling ................... Strong   median instability 0.3 (dep-cruiser)
  B2 Change / temporal coupling ............ Partial  2 unexpected couples (git mine)
  B3 Cohesion .............................. Strong   no LCOM hotspots
  B4 Seams & substitutability .............. Strong   ports/adapters + hand fakes
  B5a Unit isolation (gradient) ............ Strong   units run offline, no live services
  B5b Real-dependency integration proof .... Partial  Testcontainers PG in 1 suite; no seed/restore
  B6 Module boundaries ..................... Strong   dependency-cruiser rules enforced
  B7 Complexity & size thresholds .......... Weak     CC rule not enabled in eslint
  B8 Inner-loop speed ...................... Partial  no unit/integ split; 40s test run

LATENT HARNESS  (techniques the tests already contain — lift, don't rebuild)
  • Real Postgres via Testcontainers (tests/conftest.py)  → promote to `harness boot --with-db`
  • Repo interfaces + hand fakes (tests/fakes/)           → seams an agent can inject at
  • Factory-built state (tests/factories/)                → promote to `harness seed`
  • (gap) no per-test restore/rollback found              → add txn-rollback fixture → `harness reset`
```

---

## 4. Pros/cons + remediation output

Below the matrix the skill prints four sections, ranked by leverage:

- **Strengths** — every `Strong` dimension, one line each ("rely on this").
- **Weaknesses** — every `Weak`/`Absent`/`Partial-with-risk` dimension, worst first.
- **Latent harness** — the techniques the **test support code already contains** that the harness can *lift into an operable surface*, each with a "promote to" target (see the `LATENT HARNESS` block in §3.4). This is the highest-ROI output of the skill: it turns "the tests already seed/restore/inject" into concrete, cheap *promotion* work rather than construction. A repo can be **high-potential / low-operate-today** — rich real-integration tests but no `harness seed`/`boot` — and the verdict is "promote, don't build". Detection is read-only over `conftest.py`/fixtures/factories/`tests/fakes/`/testcontainers configs, never over assertion bodies.
- **Highest-leverage remediations** — the 3–5 changes that would raise the *most* bands, each tied to **"encode the fix, not the memory"** (Directive 4; first-principles #18). Prefer **promotion of existing test machinery** over net-new construction. Each remediation specifies the *executable* artifact to add, not a doc to write:

| Gap | Remediation (executable) | Raises | Effort |
|-----|--------------------------|--------|--------|
| A2 Weak | add `just boot` composite (build→start→wait→healthcheck) | A2 → Strong | S |
| A4 Absent | add one smoke route + `just smoke` | A4 → Partial, A5 → Partial | M |
| A3/B5b Partial | **promote** the Testcontainers setup in `tests/conftest.py` to `harness boot --with-db` + factory seed to `harness seed` | A2, A3, B5b ↑ | S (promotion) |
| B7 Weak | enable eslint complexity/max-len/max-params rules | B7 → Strong | S |

Remediations are **recommendations** — best-effort, never gates. The skill informs a conversation; the human chooses what to encode (first-principles #50).

---

## 5. Composition with the existing skills (no duplication)

The clean seam (from Open Questions, now resolved as the proposed boundary):

| Skill | Scope | When | Output |
|-------|-------|------|--------|
| `harness-1-boot` | **Session-start signal-readiness** — is the harness healthy *right now*? | every session | live Boot/Interact/Observe verdict + 6 signal dimensions |
| `plan-2d-backpressure-survey` | **Feature-scoped** deterministic-provability at design time | after spec, before architect | per-criterion EXISTS/BUILDABLE/ABSENT matrix for *this feature* |
| **`harnessability-assessment`** (new) | **Whole-repo modifiability/workability scorecard** on demand | ad hoc / onboarding / brownfield triage | two-axis graded matrix + remediations |

Key non-overlaps:
- **Adaptability axis (B) is entirely absent** from both existing skills (the "third axis" / workability gap) — that's the clean, uncontested new ground.
- **Axis A overlaps harness-1-boot's signal-readiness *by design* — and must consume, not re-invent, its vocabulary.** harness-1-boot Step 4 already enumerates six signal dimensions (runtime inspectability, smoke paths, architecture/static checks, security/dependency/schema checks, evidence paths, back-pressure gaps); Operate-Today's A2/A4/A5/A7 detect the *same signal classes*. The distinction is **temporal scope, not subject**: harness-1-boot probes them **live at session start** (does it boot/respond/observe *right now*?); this skill reads them **statically, repo-scoped, on demand** (does the machinery *exist in the repo*?). To avoid a near-clone, the spec should have Axis A **cite/reuse harness-1-boot's signal-readiness dimension names** the way it pledges to reuse plan-2d's vocabulary below — same names, static read.
- plan-2d is **feature-scoped and per-criterion**; this skill is **repo-scoped and structural**. The new skill SHOULD reuse plan-2d's `EXISTS/BUILDABLE/ABSENT` Status language for its Operate-Today evidence — **but mind two collisions to resolve in the spec**: (1) the band scale's `Absent` ("not present, would need real work") is **not** plan-2d's `ABSENT` ("cannot be proven deterministically — legitimately inferential/human"); a dimension can be band-`Strong` yet sensor-`ABSENT`. Keep them as two columns, not one. (2) plan-2d pairs Status with a **Tier** axis (computational/inferential/human-judgement) — decide explicitly whether this skill adopts Tier or omits it.
- **engineering-harness-setup provisions; this skill diagnoses.** A1/A8 *read* `docs/project-rules/engineering-harness.md`, which the separate engineering-harness-setup effort *creates*. This skill never scaffolds it — but "run engineering-harness-setup" is a legitimate **remediation output** when the governance doc / boot surface is Absent, which closes the Improve loop back to provisioning.
- Unlike both (which are deliberately score-free), this skill **is** allowed to emit a graded score — because its job is *comparison and triage* ("which repo / which area is most agent-hostile?"), which needs a comparable rating. It keeps honesty via §3's evidence-first, tuple-not-number discipline.

---

## 6. Open questions / risks / validate-before-building

1. **Axis weighting.** Is 50/50 right, or should Operate-Today dominate (a repo unusable today blocks *all* work) or Adaptability dominate (brownfield value compounds from modifiability)? No source settles it — needs a stated, override-able default. *(Recommend: ship 50/50, expose `--weight`.)*
2. **Read-only architecture detection across languages.** How reliably can DI/IoC and hexagonal/ports-and-adapters be detected *without executing code* — import-graph fan-in/fan-out, interface density, framework signatures? Risk of false positives. Needs a per-language detector capability map + honest "not-detectable-here" fallback.
3. **Git-mining cost (B2).** Change/temporal coupling requires mining full history — potentially slow on large repos. *(Recommend: fast-path scores static signals only; B2 is an opt-in `--deep` pass.)*
4. **Goodhart / gaming.** Any published score becomes a target and decays into theatre (https://axify.io/blog/goodhart-law). Mitigation: evidence is mandatory per band; report facts separately from grades (#53); never wire the score to a gate.
5. **Metric-source gap.** SonarQube excludes coupling/cohesion; the skill must integrate dependency-cruiser/JDepend/NDepend + VCS mining for Axis B — confirm those are available (or degrade gracefully) before relying on B1/B3.
6. **Vendor-source caveat.** CodeScene/SonarQube docs are vendor primaries (authoritative for their own mechanisms, commercially motivated); they're corroborated here by peer-reviewed work (IEEE 5328803, Gall 1998, the change-coupling chapter) — keep the peer-reviewed citations when authoring.
7. **Field velocity.** Harness-engineering / sensors framing is fast-moving (2025–2026); the *design-quality* metrics (coupling, cohesion, test doubles, seams, hermetic testing, SQALE) are decades-stable and low-risk. Re-check the harness-engineering citations periodically.
8. **Latent-harness detection reliability (B5b + the test-support probe).** How reliably can the skill recognise seed/restore/inject techniques across heterogeneous test frameworks read-only — txn-rollback fixtures, Testcontainers, factory-built state, hand fakes — without executing the suite? Risk of both false negatives (bespoke harness code it doesn't recognise) and false positives (a fixture named `seed_` that doesn't). Needs a per-framework signature map + an honest "test machinery present but technique unclassified" fallback rather than a confident miss. **Treat this + Q2 as must-resolve-before-build** — they gate the skill's headline (latent-harness) output, not optional polish.
9. **Undetectable-dimension rollup contract (degraded mode).** When a dimension can't be detected (tool absent — e.g. no dependency-cruiser; language unsupported; git-mining skipped), how is it scored? Counting it `Absent` (0) **punishes the repo for the *assessor's* blind spot** (a false negative that corrupts the grade); the alternative is marking it `Unknown` and **excluding it from the rollup denominator** (so a 7-of-9-detectable Axis B is scored out of 21, not 27). **Undetectable ≠ Absent.** The §3.2 fixed maxima (24 / 27) quietly assume full detectability — the spec must define the degraded-mode denominator and surface "scored N of M dimensions" in the output so a partial assessment never masquerades as complete (#53 facts-separate-from-interpretation; "no silent caps").

---

## 7. Parallel execution architecture (how the skill fans out)

A whole-repo harnessability assessment is embarrassingly parallel: the 17 dimensions are independent, **read-only** probes. This section specifies the fan-out so the eventual skill (or a `Workflow` script driving it) is buildable. It is design, not yet a spec — the contracts below are the proposal a `/plan-1b` author refines.

### 7.1 Principles

- **Split by *probe modality*, not by axis.** Group dimensions by *what each must read or run*, so every subagent loads minimal context and uses one tool family (the "multi-modal sweep" pattern). Splitting by axis (A vs B) is too coarse (2 uneven agents, each forced to load every tool).
- **Read-only → no isolation cost.** Probes never write, so they need **no worktrees** and cannot conflict. Pure fan-out.
- **Disjoint dimension assignment.** Each dimension is owned by exactly one probe — no two probes score the same dimension, so synthesis never has to reconcile a contested band (boundary cases are flagged by verify, §7.6).
- **Cost-tiered.** The expensive probes (git-history mining, cross-language structural metrics) are isolated behind an opt-in `--deep` pass so the default sweep stays fast (honours §6 Q3).
- **Determinism.** A fixed probe roster + fixed assignment = reproducible runs (first-principles #43). No probe count varies by repo; only `detected | undetectable` varies.

### 7.2 Probe roster

| Probe agent | Owns | Reads / tooling | Tier |
|-------------|------|-----------------|------|
| **front-door** | A1, A6, A8 | `README`, `AGENTS.md`/`CLAUDE.md`, CLI/`justfile` help, `docs/`, governance doc | fast |
| **runtime-state** | A2, A3, A4, A5 | `justfile`/`Makefile`/`package.json` scripts, `docker-compose*`, healthchecks, seed/reset/smoke scripts, log/trace/`--json` surfaces | fast |
| **sensor-inventory** | A7, B7 | CI workflows, pre-commit, lint/type/test/analyzer configs (incl. complexity/max-len/max-args rules) | fast |
| **structural** | B1, B3, B6 | import-graph (dependency-cruiser/JDepend/NDepend), module topology, dependency-direction rules | medium |
| **latent-harness** *(headline)* | B4, B5a, B5b, B8 + the promote catalogue | test **support** code only: `conftest.py`, fixtures, factories, `tests/fakes/`, base test classes, testcontainers/compose-test, unit/integration split | medium |
| **temporal-coupling** *(deep)* | B2 | full `git log` history mining (support/confidence; CodeScene's 3 mechanisms) | **expensive — opt-in `--deep`** |

Six probes. The first five are the default sweep; `temporal-coupling` joins only under `--deep`. Cross-language structural metrics (B1/B3/B6) also degrade to `undetectable` when no dependency-graph tool exists rather than blocking.

> **The latent-harness probe is the headline, but its *recognition coverage* is an open blocker (§6 Q2/Q8).** Verify (§7.6) guards only against **false positives** (hallucinated fixtures it drops); it does **not** close **false negatives** — bespoke harness code in an unfamiliar framework that the probe fails to recognise. Such code must be emitted as `band: Unknown` with reason `technique present but unclassified` (not silently `Absent`), so a blind spot reads as a blind spot. The per-framework signature map that raises recognition coverage is §6 Q8, must-resolve-before-build.

### 7.3 Fast path vs deep path

- **Default (`5 probes`)**: returns a full graded tuple in one parallel sweep — every dimension except B2 scored from static reads. B2 reports `undetectable (deep-only)`, excluded from the denominator (§7.5).
- **`--deep` (`6 probes`)**: adds temporal-coupling git-mining; B2 becomes scorable. Use on demand / for a brownfield triage, not every run.

The grade is **honest in both modes** because the degraded-mode denominator (§7.5) reports "scored N of M" — a fast run never masquerades as a complete one.

### 7.4 Probe output contract

**Input contract** — each probe receives `{ repo_root, owned_dimension_ids[], deep: bool }`. The disjoint-assignment guarantee (§7.1) is thus a *passed input* (the IDs the probe owns), not a convention the caller reconstructs — and the fixed roster→IDs map is what aggregate uses to detect a missing probe (§7.5).

**Output contract** — every probe returns the **same shape** so aggregate can merge without per-probe special-casing. Each scored dimension carries a band **and** its evidence (evidence-mandatory-per-band, §3.1 — a band with no evidence is invalid). The `band` enum is §3.1's four values (`Strong|Partial|Weak|Absent`, points 3/2/1/0) **plus** `Unknown` — the sentinel for "detected machinery but technique unclassified" (§7.2) and for verify-demotions (§7.6); `Unknown` is excluded from the denominator, never scored 0:

```json
{
  "probe": "latent-harness",
  "dimensions": [
    { "id": "B5b", "band": "Partial", "detected": true, "risk": true,
      "evidence": "tests/conftest.py:14 — Testcontainers Postgres; no per-test restore found",
      "note": "seed via factories; reset gap" }
  ],
  "latent_harness": [
    { "technique": "Testcontainers Postgres", "evidence": "tests/conftest.py:14",
      "promote_to": "harness boot --with-db" }
  ],
  "undetectable": [
    { "id": "B1", "band": "Unknown", "reason": "no dependency-graph tool present for this language" }
  ]
}
```

The optional **`risk: true`** flag lets a probe mark a `Partial` that carries real risk, so roll-up partitions pros/cons (§7.7) *mechanically* — "Partial-with-risk → weakness" — instead of parsing the free-text `note`. `latent_harness[]` is populated only by the latent-harness probe. `undetectable[]` lets roll-up compute the denominator correctly (§7.7) and surface blind spots instead of scoring them `Absent`.

> **Critical ordering invariant (caught in validation).** The degraded-mode denominator (§7.7) is computed from the set of `scored` dimensions — and **two events can still change that set after the probes return**: a *failed probe* (its dimensions never arrive) and a *verify demotion* (an unverifiable band moves to `undetectable`). Therefore the rollup math **must run last**, over the *post-reconcile, post-verify* set. The stages below are ordered to guarantee that: aggregate+reconcile → verify → **roll-up**. Computing the grade before verify (the naive `synthesize → verify`) produces a stale grade and a stale "scored N of M" line — do not do it.

### 7.5 Aggregate & roster-reconcile stage (barrier)

A **single stage that needs ALL probe output at once** (a barrier) — it cannot start until every probe returns. It does **no detection and no scoring**; it only assembles a clean, complete evidence set:

1. **Merge** every probe's `dimensions[]`, `latent_harness[]`, and `undetectable[]`.
2. **Roster reconciliation (handles failed probes).** `parallel()` maps a throwing probe to `null`. Iterate the **fixed roster→owned-dimension map** (§7.1/§7.4 guarantee it is fixed): for any probe slot that returned `null` *or* omitted a dimension it owns, mark every such dimension `band: Unknown`, `reason: probe failed`, and place it in `undetectable[]`. This converts a crashed probe from **silent dimension loss** (the run shrinking M without saying so) into a **visible** degraded-mode reading.
3. **Build the merged latent-harness catalogue** (unverified at this point — verify prunes it next).

Output of this stage: a roster-complete set where every one of the 17 dimensions is present as either `scored` or `undetectable`. No grade yet.

### 7.6 Adversarial verify stage

The latent-harness catalogue ("promote X → `harness seed`") is the **most hallucination-prone** output — an agent will happily invent a plausible fixture that isn't there. A cheap verify agent runs **on the aggregated set, before any rollup**, and mechanically enforces the evidence rule:

- **Every band's `evidence` must resolve to a real `file:line`.** Any band whose evidence file doesn't exist (or doesn't contain the claimed signal) is **demoted to `Unknown` and moved to `undetectable[]`** (reason `evidence unresolved`) — it cannot silently inflate or deflate the grade.
- **Every `latent_harness[]` entry's `evidence` must point at real test-support code that actually contains the technique.** Unverifiable entries are dropped from the catalogue (no hallucinated "promote" suggestions reach the user).
- **Cross-probe sanity.** If any dimension somehow appears in two probes (should be impossible given disjoint assignment), verify flags the collision rather than picking one.

Verify is adversarial-by-default: when in doubt it **drops/demotes** rather than trusts (the mechanical form of #53). Note this guards **false positives** only; the latent-harness probe's **false-negative** recognition gap is the separate §6 Q8 blocker (see §7.2).

### 7.7 Roll-up & emit stage

Runs **after** verify, over the final reconciled+verified set — so every number reflects exactly what survived:

1. **Per-axis partition** into `scored` (band ∈ {Strong,Partial,Weak,Absent}) and `undetectable` (band = Unknown).
2. **Degraded-mode denominator.** Axis % = `sum(points of scored) / (count(scored) × 3)`. Undetectable dims are **excluded from the denominator, not scored 0** (§6 Q9 — undetectable ≠ Absent). Always print **"scored N of M dimensions"** per axis.
3. **Letter grade** (§3.2), **two-letter tuple** (headline), optional labelled **Index** (§3.3) — tuple first, Index last and flagged lossy.
4. **Matrix** (§3.4); **pros/cons** — Strong → strengths, and Weak / Absent / `risk:true` Partial → weaknesses (partitioned mechanically off the `risk` flag, §7.4, not prose); **merged+verified latent-harness catalogue**; **ranked remediations** (promotion-before-construction).

Roll-up performs **no detection of its own** — every number is traceable to a surviving probe evidence string.

### 7.8 Execution shape

```
parallel( front-door, runtime-state, sensor-inventory, structural, latent-harness [, temporal-coupling] )
   → BARRIER (all probe results collected)
   → aggregate+reconcile  (merge; null/failed probe → its dims = Unknown/undetectable; build catalogue)
   → verify               (resolve every evidence ref; demote unresolved bands; drop hallucinated catalogue entries)
   → roll-up              (denominator over the POST-verify set; grade, tuple, Index, matrix, pros/cons, remediations)
   → emit report
```

`parallel → barrier → aggregate → verify → roll-up`. A barrier (not a `pipeline`) is correct because roll-up needs the **complete** post-verify set to compute the denominator — the textbook case that justifies a barrier. Directly expressible as a `Workflow` script (probes in one `parallel()`, then three sequential single-agent stages). The eventual SKILL.md can drive subagents inline or shell out to such a workflow; the §7.4 contract is identical either way.

### 7.9 Cost & determinism notes

- **Fast path** ≈ 5 cheap read-only probes in parallel → wall-clock ≈ slowest single probe, not the sum.
- **Deep path** adds one expensive git-mining probe; isolating it means a `--deep` run costs more but the default never pays for it.
- **What IS deterministic**: the probe roster, the dimension assignment, and the denominator *structure* — same repo + same flags → same probe set and the same "scored N of M" framing. **What is NOT**: the **band *values*** are LLM-judgement (a probe may call a dimension Partial one run, Strong the next); verify pins the *evidence* (file:line must resolve) but not the classification. Reproducibility is therefore strong for *structure*, best-effort for *band values* — do not over-claim it. Where a band is a mechanical function of a concrete detected signal (e.g. "complexity rule enabled in eslint config: yes/no"), the spec should have the probe derive it deterministically rather than judge it.

---

## Appendix — verified source list

**Primary / peer-reviewed**
- Böckeler, *Harness engineering for coding agent users* — https://martinfowler.com/articles/harness-engineering.html
- Böckeler, *Sensors for coding agents* — https://martinfowler.com/articles/sensors-for-coding-agents.html
- Banay, *Don't waste your back pressure* — https://banay.me/dont-waste-your-backpressure/
- D'Ambros, Lanza, Robbes, *On the Relationship Between Change Coupling and Software Defects* — https://www.ime.usp.br/~gerosa/papers/changecoupling.pdf ; IEEE ICSM 2009 "On the Relationship Between Change Coupling and Software Defects" (IEEE Xplore doc 5328803, https://ieeexplore.ieee.org/document/5328803)
- Fowler, *Mocks Aren't Stubs* — https://martinfowler.com/articles/mocksArentStubs.html ; *Test Double* — https://martinfowler.com/bliki/TestDouble.html
- Feathers, *Working Effectively with Legacy Code* (seams) — https://www.informit.com/articles/article.aspx?p=359417&seqNum=2
- Android testing fundamentals (test doubles, hermetic) — https://developer.android.com/training/testing/fundamentals/test-doubles
- Testcontainers — https://testcontainers.com/guides/introducing-testcontainers/ ; Pact — https://docs.pact.io/
- SonarQube metric definitions (SQALE / Maintainability Rating) — https://docs.sonarsource.com/sonarqube-server/user-guide/code-metrics/metrics-definition
- OpenSSF Scorecard (prior-art scorecard shape) — https://github.com/ossf/scorecard

**Secondary / practitioner**
- Software package metrics (Martin: Ca, Ce, instability, abstractness, distance) — https://en.wikipedia.org/wiki/Software_package_metrics
- Hexagonal architecture — https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)
- CodeScene temporal coupling — https://docs.enterprise.codescene.io/versions/3.2.9/guides/technical/temporal-coupling.html
- DORA anti-patterns — https://www.infoq.com/articles/dora-metrics-anti-patterns/ ; Goodhart's law — https://axify.io/blog/goodhart-law ; Fitness functions — https://www.infoq.com/articles/fitness-functions-architecture/

**Local substrate (authoritative)**
- `/Users/jordanknight/substrate/harness-engineering/harness-foundations/{simple-mode,first-principles,directives,patterns-that-work,super-simple-mode}.md`

---

## Validation Record (2026-06-05)

### Validation Thesis

**Raison d'être**: The two existing harness skills measure runnability (`harness-1-boot`) and provability (`plan-2d`) but not modifiability/workability; this dossier designs a third skill scoring harnessability across Operate-Today + Adaptability to fill that gap.

**Value claim**: A future `/plan-1b` author can build a spec for a skill that points at a repo → pros/cons + honest score answering (A) usable-today and (B) adaptability, without reinventing the two skills or breaking best-effort.

**Artifact promise**: The two-axis model, per-dimension detection heuristics, the invention-flagged scoring rubric, the latent-harness output, and the §5 composition boundary are buildable into a spec.

**Intended beneficiaries**: the user (build-or-not decision), a future spec/skill author, agents working on brownfield repos.

**Proof target**: Decision (pre-spec design exploration).

**Evidence standard**: cited URLs for factual metric/prior-art claims; rubric explicitly flagged as invention; quotable alignment with substrate; clean non-duplication boundary.

**Thesis source**: user requests across the conversation + substrate first-principles #6/#54/#33/#34 + the two existing skills (grounded, not inferred).

**Thesis verdict**: Advanced.

**Main thesis risk**: Cross-language latent-harness detection (the headline output) and the undetectable-dimension rollup contract are unresolved — now routed to §6 as must-resolve-before-build blockers.

---

| Agent | Lenses Covered | Issues | Verdict |
|-------|---------------|--------|---------|
| Accuracy & Evidence | Evidence Sufficiency, Proof-Level Fit, Concept Documentation, Hidden Assumptions | 1 HIGH + 1 MED fixed, 2 LOW (1 fixed) | ⚠️ → ✅ |
| Substrate Fidelity | Domain Boundaries, System Behavior, Hidden Assumptions, Concept Documentation | 3 LOW fixed, 2 confirmations | ✅ |
| Thesis Alignment | Thesis Alignment, Evidence quality | 2 LOW (1 fixed, 1 noted) | ✅ |
| Forward-Compatibility | Forward-Compatibility, Integration & Ripple | 3 MED fixed, 2 LOW fixed | ⚠️ → ✅ |

### Forward-Compatibility Matrix

| Consumer | Requirement | Failure Mode | Verdict | Evidence |
|----------|-------------|--------------|---------|----------|
| `028-*-spec.md` (future /plan-1b) | buildable two-axis model + heuristics + rubric + open questions | shape mismatch | ✅ (post-fix) | §2/§3 buildable; vocab collision + degraded-mode gap now resolved in §5/§6 |
| eventual `harnessability-assessment` SKILL.md | read-only detection signals, output format, best-effort posture | test boundary | ✅-with-gap | output format worked (§3.4/§4); cross-lang latent-harness detection routed to §6 Q2/Q8 as must-resolve |
| `skills/harness/harness-1-boot/SKILL.md` | must NOT duplicate session-start signal-readiness | contract drift | ✅ (post-fix) | §5 now states Axis A = static repo-scoped read of the *same* signal classes boot probes live; reuse its vocabulary |
| `skills/SDD/plan-2d-backpressure-survey/SKILL.md` | must NOT duplicate feature survey; reuse EXISTS/BUILDABLE/ABSENT | shape mismatch | ✅ (post-fix) | §5 now flags band-`Absent` ≠ plan-2d `ABSENT` and the Tier decision |

**Thesis alignment**: Value claim advanced at the Decision proof level; the modifiability-gap raison d'être, the high-weight real-integration (B5b) signal, and the latent-harness output are all faithfully held; main residual risk is cross-language detection, now an explicit must-resolve blocker.

**Outcome alignment**: The Outcome — "point this skill at a repo and have it tell me pros and cons … give me a harnessability score … A how easy it would be to use it … today … and B how adaptable it would be" — is advanced by the dossier: its two-axis Operate-Today/Adaptability split, banded scorecard, pros/cons + latent-harness remediations, and explicit Index map cleanly onto every clause, with remaining gaps being spec-resolvable refinements rather than structural defeaters.

**Standalone?**: No — downstream consumers (future spec, eventual skill, two existing skills) named and engaged.

Overall: ⚠️ VALIDATED WITH FIXES

---

## Validation Record 2 — §7 Parallel execution architecture (2026-06-05)

Second validation pass, run on the newly-added §7 before any implementation (per "run validation before implementation"). 3 agents: internal-consistency/coverage, orchestration-soundness, thesis+forward-compat.

| Finding | Severity | Status |
|---------|----------|--------|
| Verify ran *after* the rollup → grade/tuple/"N of M" computed over a set verify then mutated (stale grade) | **HIGH** | Fixed — pipeline reordered to aggregate+reconcile → verify → **roll-up** (§7.5–7.8); ordering invariant called out |
| A failed/`null` probe silently dropped its 3–4 owned dimensions from both `scored` and `undetectable` → run masquerades as complete | **HIGH** | Fixed — §7.5 roster-reconciliation maps every owned dim of a null probe to `Unknown`/undetectable |
| "Partial-with-risk" consumed by synthesis but no structured field in the probe contract | MEDIUM | Fixed — added optional `risk: true` flag (§7.4) |
| §7 didn't re-flag latent-harness *false-negative* recognition gap; verify only guards false positives | MEDIUM | Fixed — §7.2 caveat + `Unknown`/"unclassified" fallback; ties to §6 Q8 |
| Probe *input* contract unspecified (repo_root / owned IDs / deep flag) | MEDIUM | Fixed — input contract added to §7.4 |
| band enum/points split across §3.1 and §7.4; `Unknown` 5th value undocumented | LOW | Fixed — §7.4 states enum = §3.1 four + `Unknown` sentinel |
| §7.8 over-claimed determinism for LLM-judged band values | LOW | Fixed — §7.9 scopes determinism to structure, not band values |

**Confirmed sound (no change)**: 17-dimension coverage is complete + disjoint across the 6 probes (verified by two agents); the barrier-before-rollup is the textbook-justified case; best-effort posture and the latent-harness/B5b headline are preserved; proof level stays Decision (a sketch, not implementation).

Overall: ⚠️ VALIDATED WITH FIXES — §7 is now internally consistent and buildable; the two HIGH orchestration bugs were design-level and are resolved before they could reach code.
</content>
</invoke>
