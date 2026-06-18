# the-flow Elegance Layer Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-06-18
**Status**: READY
**Spec source**: unified (this file)

## Business Specification

### Research Context
📚 Incorporates findings from `research-dossier.md` (the Ponytail→elegance translation + a Perplexity Evidence addendum on what reliably cuts LLM **output** verbosity). Decisions settled in this session's grill are recorded in `original-ask.md` § Decisions.

### Summary
Make the-flow **emit less** without losing safety or guidance. Add a small, evidence-backed **elegance layer**: one referenced artifact-doctrine, plus in-place narration changes in `coach.md` that cut output *by construction* (default-omit, pull-based summons, lean exemplars) rather than by adding more "be terse" pleas. Targets **output tokens only** — the flow's on-disk size stays.

### Goals
- Reduce the flow's **emitted output** (narration + generated plans/tasks/logs) at every seam.
- Lead with the levers that actually work (default-omit + summons + few-shot), per the evidence.
- Keep one referenced doctrine home (DRY) — no copy-pasted blocks, no parallel sections.

### Non-Goals
- Shrinking the flow's own on-disk markdown (input is cheap — **separate later pass**).
- Any enforcement gate / score / threshold (stays best-effort).
- Restructuring flow-architecture / Registry / Graph / flight-plan rendering.
- Touching harness seams or utility skills.
- Adding more imperative "be terse" rules (that's the tier-4 failure mode).
- **Artifact-side worked exemplars** (a full lean-vs-verbose plan/task-table sample) — deferred; stages get the one-line build-contract rule only. The narration few-shot (T005) is the sole worked example this pass.
- **`1a explore` / `7 review` / `8 merge` per-stage lines** — unchanged; covered by the coach-level narration rules, not per-stage build-contract lines.

### Target Domains
| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| the-flow (skill tree) | existing | **modify** | The only surface edited: `coach.md`, `00-routing.md`, four stage modules |

_This repo has **no** `docs/domains/` registry — the the-flow skill tree is the whole surface; "domain" here is nominal._

### Testing Strategy
- **Approach**: Manual / best-effort. **No automated tests, no acceptance proof** (per the grill decision — Jordan is the feedback loop).
- **Verification (manual)**: re-read each edited file's diff; run `scripts/check-flow-architecture.sh` (must stay green); confirm no must-see/safety line removed; redeploy and eyeball one rendered seam.
- **Excluded**: token-count metrics (noisy/model-dependent per the evidence).

### Documentation Strategy
- **Location**: None (D). The edits are self-documenting in the skill files; `research-dossier.md` + this plan are the record.

### Complexity
- **Score**: CS-2 (small)
- **Breakdown**: S=1, I=0, D=0, N=1, F=0, T=1 → 3
- **Confidence**: 0.80
- **Assumptions**: edits are additive prose/structure in existing files; no behavioural code.
- **Dependencies**: none (the `fewest-phases` principle is already live, commit `12271f4`).
- **Risks**: see § Risks & Assumptions.
- **Phases**: 1 (Simple).

### Acceptance Criteria
- **AC-01**: `00-routing.md` § Shared conventions carries one **Artifact Elegance** block (the seven-function line test + "tables/schemas/diffs over prose" + "fewest phases") as the single referenced home.
- **AC-02**: `coach.md` carries per-facet budgets (drop-when-empty partly pre-exists at Seam Digest `:118`); the "nothing flagged — clean" phrasing in **The Flag beat** (`:145`) is **removed** (silence = clean), with the ⚠️ `*(omit if clean)*` guards left intact.
- **AC-03**: `coach.md` summon list includes `options`, `why`, `details`, `warnings` alongside the existing `recap`.
- **AC-04**: `coach.md` "why this matters" is **gated** (first-exposure / resume-ambiguity / non-obvious / on request) — not narrated every seam.
- **AC-05**: `coach.md` contains exactly **one** worked lean-vs-verbose Seam Digest example, lean variant **last**.
- **AC-06**: each of `20-plan`, `25-workshop`, `50-phase-tasks`, `60-implement` carries **one** build-contract elegance line citing the shared doctrine; `60-implement` additionally carries a one-line **execution-log** lean rule (log facts/evidence, not monologue).
- **AC-07**: no must-see/safety content removed; `check-flow` passes; **no new global imperative "be terse" rule** added, and existing tier-4 lines (e.g. `coach.md:119`) left **unchanged/not reinforced** — verified **per-file**, not only at the lint target.

### Risks & Assumptions
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| New rules ignored too (tier-4 trap) | Med | Med | Lead with tier-1/2 (default-omit + summons + examples), not imperatives |
| Summons/default-omit hide needed info | Low | High | Safety floor — must-see fields (gates, `PROCEED`, paths, `⚠️ GAP`) always shown |
| Doctrine bloats flow files (input) | High | Low | Accepted (input cheap); single referenced home caps the spread |
| Dogfood mismatch (installed prompts still old mid-build) | Med | Low | Apply principles by hand; redeploy at merge |

### Open Questions
None blocking.

### Workshop Opportunities
| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| (none) | — | The design is settled by the dossier + evidence ranking | — |

### Clarifications
#### Session 2026-06-18
- **Mode** → Simple (`--simple`).
- **Testing** → Manual/best-effort; no test, no proof (human feedback loop).
- **Mock** → Avoid entirely (no code).
- **Docs** → None (internal skill-file change).
- _(Round 1 answers pre-filled from the grill session — not re-asked. Scope/non-goals/lever-ranking settled in `original-ask.md` § Decisions.)_

## Planning Seam
_Refinement opportunities still open — recorded as evidence; the flow surfaces and offers these, none gate:_
- Open Workshop Opportunities: none — design settled.

| Artifact | Present? | Effect on the plan |
|----------|----------|--------------------|
| research-dossier.md | y | Key Findings + the lever ranking that orders the tasks |
| workshops/*.md | n | — |

## Implementation Plan

### Gate Matrix
| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No `[NEEDS CLARIFICATION]` markers |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` |
| G4 | ADR Compliance | N/A | `docs/adr/` holds only README — no accepted ADRs |
| G5 | Structure | PASS | All required sections present |
| G6 | Testing Alignment | PASS | Manual strategy; verification steps defined; ACs observable |
| G7 | Domain Completeness | PASS | No domain registry; single nominal domain mapped + manifest covers all files |

### Summary
One Simple-mode phase: add a referenced artifact-elegance doctrine, then make the narration cut output by construction (budgets, drop-when-empty, no clean line, gated why, summons, one few-shot example), then add a one-line build-contract framing to four stage modules. Verify with `check-flow` + a manual diff read; redeploy at merge.

### Domain Manifest
| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/SDD/the-flow/references/00-routing.md` | the-flow | internal | Shared-conventions home for the artifact doctrine |
| `skills/SDD/the-flow/references/coach.md` | the-flow | internal | Narration voice — the bulk of the change |
| `skills/SDD/the-flow/references/stages/20-plan.md` | the-flow | internal | Build-contract line |
| `skills/SDD/the-flow/references/stages/25-workshop.md` | the-flow | internal | Build-contract line |
| `skills/SDD/the-flow/references/stages/50-phase-tasks.md` | the-flow | internal | Build-contract line |
| `skills/SDD/the-flow/references/stages/60-implement.md` | the-flow | internal | Build-contract line (+ execution-log) |

### Key Findings
| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Existing soft "be terse / every line earns its place" rules are **tier-4** (weakest) — RLHF verbosity bias + instruction-overload bury global brevity pleas | Add **no** more imperatives; lead with structure + examples |
| 02 | High | **Default-omit + pull-based** is tier-1 — cuts output by construction (concision as binary gates) | Summons + drop-when-empty + no-clean-line + gated-why |
| 03 | High | **Few-shot lean exemplars** (tier-2) override priors; put the lean one **last** | One worked lean-vs-verbose Seam Digest example |
| 04 | High | Doctrine must live in **one referenced home** (DRY); copying it = the dossier's own rung-3 violation | `00-routing` § Shared conventions is the home; stages cite it |
| 05 | Critical | **Safety floor** — default-omit applies to decorative prose only, never must-see fields | Explicit carve-out in the doctrine + coach |

### Implementation

**Objective**: Add the elegance layer to the-flow's source so it emits less, leading with default-omit + summons + exemplars.
**Testing Approach**: Manual/best-effort — `check-flow` green + diff read + one redeployed seam eyeballed; no automated tests.

#### Tasks
| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Add **Artifact Elegance** doctrine to § Shared conventions (seven-function line test + tables-over-prose + fewest-phases + safety-floor carve-out) — the single referenced home | the-flow | `references/00-routing.md` | Block present; self-contained; no command literals (lint-safe) | AC-01 · KF-04/05 |
| [x] | T002 | Add per-facet budgets (Just-did 1–2, Watch-out 0–3, Next 1, Optional 0–1) to the Seam Digest (drop-when-empty already at `:118`); **remove only** the "nothing flagged — clean" phrasing in **The Flag beat** (`coach.md:145`), leaving the ⚠️ `*(omit if clean)*` guards intact | the-flow | `references/coach.md` | Budgets present; line-145 clean phrasing gone; omit-guards untouched | AC-02 · KF-02 |
| [x] | T003 | Add summons `options`/`why`/`details`/`warnings` beside `recap` (pull-based depth) | the-flow | `references/coach.md` | All five summons documented in one place | AC-03 · KF-02 |
| [x] | T004 | Gate "why this matters" to first-exposure / resume-ambiguity / non-obvious / on request (not every seam) | the-flow | `references/coach.md` | Gating rule present; default-on every-seam removed | AC-04 · KF-02 |
| [x] | T005 | Add **one** worked lean-vs-verbose Seam Digest example, lean variant last | the-flow | `references/coach.md` | Single example pair present, lean last | AC-05 · KF-03 |
| [x] | T006 | Add one build-contract line citing the home — exact form `` `references/00-routing.md` § Shared conventions `` (root-relative) — to each stage module; **60-implement also** gets a one-line execution-log lean rule. **L1-safe**: no `stage N`, no `stages/<x>.md`, no successor/flow-command tokens | the-flow | `references/stages/{20-plan,25-workshop,50-phase-tasks,60-implement}.md` | One citing line per file (25-workshop & 60-implement gain their first citation); 60-implement has the exec-log rule; check-flow green | AC-06 · KF-04 |
| [x] | T007 | Verify: `scripts/check-flow-architecture.sh` green; **per-file** diff-read confirms no must-see/safety line removed, no new global imperative added, and existing tier-4 lines (`coach.md:119`) unchanged/not reinforced; (redeploy at merge) | the-flow | `skills/SDD/the-flow/**` | check-flow clean; per-file diff read passes | AC-07 · KF-01 |
| [x] | T008 | **Artifact-side follow-up** (partial close of the deferred Non-Goal, from the `20260618T001257.md` handover — trimmed to the no-gates subset): close `10-explore`'s missing elegance citation + reframe its dossier as a curated decision aid; swap **output-facing** bloat incentives only (`10-explore` "comprehensive document/criterion"; `25-workshop` "detailed design document/in depth/thorough") leaving internal-research depth intact; add **Link, don't copy** to `§ Artifact Elegance` (one home, no new file). Wrote ethos workshop `workshops/001-think-deep-emit-lean-ethos.md`. **Dropped from the handover**: §10 test/regression suite + §3 hard line-budget table (against best-effort/no-gates). | the-flow | `references/00-routing.md` · `references/stages/{10-explore,25-workshop}.md` | check-flow green; output bloat gone, internal "comprehensive" (subagent research) intentionally kept; doctrine stays single-home | KF-04/05 |

#### Implementation Anchors (from validate-v2 — precise edit sites)
- **T001** → new `### Artifact Elegance` h3 peer under `## Shared conventions` (`00-routing.md:190`).
- **T002** → remove the "Silent when clean" phrasing in **The Flag beat** (`coach.md:145`); Seam Digest already drops empty facets (`:118`).
- **T003** → add the four summons beside `**Summon — `recap`.**` (`coach.md:123`).
- **T004** → "why matters" is default-on today (`coach.md:5` + Insight scripts); add the gating rule in § Narration scripts near the Flag-beat (~`:142`).
- **T006** → cite exactly `` `references/00-routing.md` § Shared conventions `` (matches `20-plan.md:24,140`); `25-workshop` & `60-implement` have no citation yet.
- **Lint**: baseline check-flow green; additions carry no `/the-flow` literal (L3 safe) and no sub-skill-leak tokens (L1 safe).

### Acceptance Coverage Map
| AC | Covered by | Verified in |
|----|-----------|-------------|
| AC-01 | T001 | Block exists in 00-routing |
| AC-02 | T002 | coach.md diff |
| AC-03 | T003 | coach.md diff |
| AC-04 | T004 | coach.md diff |
| AC-05 | T005 | coach.md diff |
| AC-06 | T006 | 4 stage-module diffs |
| AC-07 | T007 | check-flow + diff read |

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| New rules ignored too | Med | Med | Lead tier-1/2 (structure+examples), not imperatives (KF-01) |
| Default-omit hides needed info | Low | High | Safety floor — must-see fields always shown (KF-05) |
| Flow files grow (input) | High | Low | Accepted (input cheap); one referenced home |
