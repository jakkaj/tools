# plan

> Sub-skill — part of a verb library. Knows nothing about any flow:
> no stage ids, no successor/predecessor names, no flow commands.
> Composition is the bundling flow's job.

**Verb**: plan
**Purpose**: Produce **one** canonical planning document in a single atomic pass — always both halves: a `## Business Specification` (WHAT/WHY, front-loaded clarifications resolved) on top, and a `## Implementation Plan` (HOW — phases, task tables, acceptance criteria, self-validating gates G1–G7) below. The questions are asked up front; the whole document is written from the answers in one run. Idempotent — re-run after a refinement (e.g. a workshop) or a clarification and it regenerates **both** halves together. Also hosts the mid-plan clarification re-entry (§ Re-entry, end of this module).
**Consumes**: feature description (argument; plan folder auto-created, or reused if a research pass already made one) · `${PLAN_DIR}/research-dossier.md` (optional) · `${PLAN_DIR}/workshops/*.md` (optional, authoritative) · repo doctrine `docs/project-rules/*`, `docs/adr/*.md`, `docs/domains/*` (optional). § Re-entry instead consumes the existing planning document (path or plan slug).
**Flags**: `"<intent>"` · `--simple` (pre-set Mode: Simple, skip the Workflow Mode question) · `--skip-clarify` (G1 override)
**Produces**: `${PLAN_DIR}/<slug>-plan.md` — one document with the frozen top-metadata block, `## Business Specification`, `## Planning Seam`, and `## Implementation Plan` (Gate Matrix G1–G7 + single `**Status**` header; inline `⚠️ GAP:` markers + a final `## Unresolved Gaps` table on any gate FAIL). Terminal report: plan path · Status · phase/task/domain counts · gate tally. § Re-entry: new `### Session YYYY-MM-DD` block under `## Clarifications` + a re-run that regenerates both halves.
**Side effects**: **always** auto-runs `/validate-v2 --artifact "${PLAN_PATH}"` (utility skill, not a flow stage), at the end of the one pass, READY or DRAFT.

---

## Procedure

Write **one** planning document for the feature in a **single atomic pass**. The verb front-loads the host-independent questions, sketches the business specification from the answers, then — in the **same run** — runs the planning gates + research and appends the implementation plan, and finally auto-runs the validator. **Always both halves, never one at a time** — there is no business-only or implementation-only mode and no flag to split the pass.

This verb replaces the legacy two-stage *specify → architect* hop and the older *specify → clarify* pair. Mid-plan clarification re-entry is preserved as the **§ Re-entry** section at the end of this module; it too ends by re-running this verb, which regenerates both halves.

> The module knows only: "this verb asks the questions, writes the business half, then derives the implementation half from it, in one pass, into one file." It knows nothing about stages, routing, or what runs before/after — that is the bundling flow's job.

> Complexity: CS 1–5 only — no time estimates (rubric: `references/00-routing.md` § Shared conventions).

```md
User input:

$ARGUMENTS

# Optional flags:
# --simple         # Pre-set Mode: Simple (skip the Workflow Mode question in Round 1)
# --skip-clarify   # Override gate G1 if critical [NEEDS CLARIFICATION] markers remain
```

## Tool-capability detection (read first)

Before either question round, decide how to prompt:

- **Batched host** (e.g., Claude Code's `AskUserQuestion` accepts a `questions[]` array of 1–4): submit each round as ONE batched call so the user answers everything in a single interaction.
- **Sequential host** (only single-question `ask_user` available): submit questions one at a time within the round, preserving the same logical grouping and the overall ≤8 cap.

Default to batched. Fall back without ceremony — do not announce capability detection unless it fails mid-flow.

---

# PART A — Business Specification (questions → the WHAT/WHY half)

## A0 — Setup

1. Determine feature slug from user input and check for existing plan folder:
   - Generate slug from feature description
   - If `docs/plans/*-<slug>/` already exists (created by a prior research pass) → use it
   - Else → create new folder with next available ordinal
   - `PLAN_DIR = docs/plans/<ordinal>-<slug>/`
   - `PLAN_PATH = ${PLAN_DIR}/<slug>-plan.md` (the single output document)

2. Check for and incorporate existing research:
   - If `${PLAN_DIR}/research-dossier.md` exists → read fully; use to inform complexity, domains, and question framing. Add a note to the business half: "📚 Incorporates findings from research-dossier.md"
   - Else → add a note: "ℹ️ Consider a deeper research pass (the explore verb) for codebase understanding"

3. Check for existing domains:
   - Load domain context per `references/00-routing.md` § Domain context loading
   - If no domain registry exists → note that domains will be identified as part of this document

4. Check for workshop documents:
   - If `${PLAN_DIR}/workshops/*.md` exist → read all; they are **authoritative design decisions** and must not be contradicted (by either half)

5. Legacy business source (AC-07 fallback): if a sibling `${PLAN_DIR}/<slug>-spec.md` exists (a legacy split folder) and no unified document yet, read it as the business source and fold its content into the `## Business Specification` half of the new document — do not require a standalone spec file going forward.

---

## A1 — Round 1: Front-loaded questions (BEFORE the sketch)

These questions are answerable without reading the document — ask them first so the sketch uses the answers as inputs rather than embedding `[NEEDS CLARIFICATION]` markers and re-asking later.

**Compose Round 1** (up to 4 questions in one batched prompt):

1. **Workflow Mode** — *skip if `--simple` flag was passed*
2. **Testing Strategy**
3. **Mock Usage**
4. **Documentation Strategy**

Submit as ONE batched call on batched hosts; sequentially on sequential hosts.

If `--simple` was passed, Round 1 shrinks to 3 questions (Testing/Mock/Docs) and `Mode: Simple` is recorded directly.

See **Standard Questions** below for the answer tables. **Mode is decided here, once, and drives both halves** (Simple → a single-phase implementation half with inline tasks; Full → a multi-phase implementation half).

---

## A2 — Write the top metadata + `## Business Specification` (using Round 1 answers)

Open `PLAN_PATH` with the **frozen top-metadata block** (single status — there is no Business/Implementation split, no STALE):

```markdown
# <Feature Title>
**Mode**: Simple | Full
**Plan Version**: 1.0.0
**Created**: <ISO date>
**Status**: READY | DRAFT — UNRESOLVED GAPS
**Spec source**: unified (this file)
```

Then write the `## Business Specification` half with these subsections:

- `### Research Context` (if research exists) — brief summary of key findings
- `### Summary` — short WHAT/WHY overview
- `### Goals` — bullet list of desired outcomes/user value
- `### Non-Goals` — explicitly out-of-scope behavior
- `### Target Domains` — **MANDATORY** domain mapping (this is the canonical domain set every Part B gate compares against):

  ```markdown
  ### Target Domains

  | Domain | Status | Relationship | Role in This Feature |
  |--------|--------|-------------|---------------------|
  | auth | existing | **modify** | Extend with OAuth provider support |
  | notifications | **NEW** | **create** | Establish for email alert delivery |
  | _platform | existing | **consume** | Use logging and config contracts (no changes) |

  #### New Domain Sketches

  ##### notifications [NEW]
  - **Purpose**: [1-3 sentences]
  - **Boundary Owns**: [concepts this domain is responsible for]
  - **Boundary Excludes**: [concepts explicitly NOT in this domain, with notes on where they belong]
  ```

  For each domain: `existing` (domain.md exists) or `**NEW**` (provide a sketch). Relationship is `create` / `modify` / `consume`.

- `### Testing Strategy` — populated from Round 1 (Approach, Rationale, Focus Areas, Excluded, Mock Usage)
- `### Documentation Strategy` — populated from Round 1 (Location, Rationale)
- `### Complexity` — CS 1-5 assessment:
  - **Score**: CS-{1|2|3|4|5} ({trivial|small|medium|large|epic})
  - **Breakdown**: S={0-2}, I={0-2}, D={0-2}, N={0-2}, F={0-2}, T={0-2}
  - **Confidence**: {0.00-1.00}
  - **Assumptions**, **Dependencies**, **Risks**, **Phases**

  CS rubric (each factor 0-2): **S**urface Area, **I**ntegration, **D**ata/State, **N**ovelty, Non-**F**unctional, **T**esting/Rollout. Sum → CS band (`references/00-routing.md` § Shared conventions).

- `### Acceptance Criteria` — numbered, testable scenarios framed as observable outcomes
- `### Risks & Assumptions`
- `### Open Questions`
- `### Workshop Opportunities` — areas that benefit from detailed design exploration before the phases are locked:

  | Topic | Type | Why Workshop | Key Questions |
  |-------|------|--------------|---------------|

  Types: `CLI Flow` | `Data Model` | `API Contract` | `State Machine` | `Integration Pattern` | `Storage Design` | `Other`

- `### Clarifications` → `#### Session YYYY-MM-DD` — record Round 1 Q&A

For genuinely topic-specific unknowns the sketch can't resolve (e.g., a data-model field that needs user input), embed `[NEEDS CLARIFICATION: …]` markers — these become candidates for Round 2.

---

## A3 — Round 2: Sketch-dependent questions (conditional)

Only fires if at least one of these is true:
- Target Domains contains NEW or contested entries → ask **Domain Review**
- The sketch left ≥1 critical `[NEEDS CLARIFICATION]` marker → ask up to 2 topic-specific questions

**Compose Round 2** (up to 4 questions in one batched prompt). Skip Round 2 entirely if none of the conditions hold.

**Total cap across Round 1 + Round 2 = 8 questions.** If Round 1 used 4 and Round 2 needs 5+, drop the lowest-priority Round 2 items.

After Round 2:
- Append Q&A to the same `#### Session YYYY-MM-DD` block in `### Clarifications`
- Update affected business subsections immediately (`### Target Domains` for boundary adjustments, topic-specific markers replaced with resolved values)

The business half is now complete. **Do not stop here** — the same pass continues into Part B.

---

## A4 — Write the `## Planning Seam` record

Between the two halves, write a `## Planning Seam` section — a **record** (not an instruction set) of what informed this document and which refinement opportunities remain open before a heavier re-plan. It records evidence and openings; it does **not** tell the reader what to run — surfacing and offering the actionable refinements (workshops, compaction) is the bundling flow's job, not this artifact's, so write no commands here. It is a record, not a divider between passes (the pass is atomic):

```markdown
## Planning Seam
_Refinement opportunities still open — recorded as evidence; the flow surfaces and offers these, none gate:_
- Open Workshop Opportunities: <names from § Workshop Opportunities, or "none — all resolved">

| Artifact | Present? | Effect on the plan |
|----------|----------|--------------------|
| research-dossier.md | y/n | informs Key Findings |
| workshops/*.md | y/n | authoritative design decisions |
```

Fill the table and the open-opportunities line from the artifacts consumed in A0. This is a passive record: it names what could still refine the plan, but the flow (Graph + coach) owns offering those steps and this verb owns regenerating **both** halves when one is folded in.

---

# PART B — Implementation Plan (derive the HOW half from Part A, same pass)

Generate a **lean, domain-aware implementation plan** with phases, task tables, acceptance criteria, AND **self-validating fail-fast gates** baked in. Gates run inline and the document's single `**Status**` resolves to one of two states:

- **`**Status**: READY`** — all gates passed; the document is ready for downstream consumption (Full → phase-task expansion; Simple → directly via its inline tasks).
- **`**Status**: DRAFT — UNRESOLVED GAPS`** — one or more gates failed. The document is **still written** (the user has context to fix) but annotated with inline `⚠️ GAP: <reason>` markers at each violation site, plus a final `## Unresolved Gaps` summary table.

The document is always written. The user is never blocked from seeing it. The status header + inline gap markers + summary table make it impossible to silently consume a broken plan downstream.

## B0: Mode & context (already loaded in Part A)

- **Mode** is already decided (Round 1 / `--simple`) and written to the top-metadata block: Simple → single-phase plan with inline tasks; Full → multi-phase plan.
- **Domains**: `### Target Domains` from the business half is `SPEC_DOMAINS` (the set every gate compares against). Domain context was loaded in A0.
- **ADRs**: if `docs/adr/` exists → read all `docs/adr/*.md`; filter to `Status: Accepted` → `ACCEPTED_ADRS`; note each constraint (what it requires / forbids).

## B1: Pre-Generation Gates

Each gate produces a PASS / FAIL / N/A verdict. FAILs do **not** block emission — they become inline `⚠️ GAP:` markers + entries in the final `## Unresolved Gaps` table + flip the document's `**Status**` to `DRAFT — UNRESOLVED GAPS`.

### Gate G1 — Clarify
- If critical `[NEEDS CLARIFICATION]` markers remain in the business half → **FAIL** with the list of markers
- User can override with `--skip-clarify` → PASS with override note

### Gate G2 — Constitution (if `docs/project-rules/constitution.md` exists; else N/A)
- For each principle, evaluate whether the planned approach violates it
- Any HIGH-impact violation with no entry in the Deviation Ledger → **FAIL**
- Deviation Ledger format (mandatory if violating):

| Principle Violated | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|-------------------|------------|------------------------------|-----------------|

### Gate G3 — Architecture (if `docs/project-rules/architecture.md` exists; else N/A)
- Check planned files/domains against layer boundaries and dependency rules
- Any violation without a documented exception → **FAIL**

### Gate G4 — ADR Compliance (if `ACCEPTED_ADRS` non-empty; else N/A)
- For each Accepted ADR: does the plan contradict its decision?
- Contradiction with no mitigation → **FAIL** with ADR reference (e.g. `ADR-007: requires X, plan does Y`)

## B2: Research

### Use existing research first

If `${PLAN_DIR}/research-dossier.md` exists → read fully; extract critical findings; reduce to 1 implementation-focused research subagent; reference findings throughout.

If `${PLAN_DIR}/workshops/*.md` exist → read all; they are **authoritative design decisions**; do NOT contradict them; skip research for workshopped topics.

### Research Subagents (2 parallel)

**Subagent 1 — Domain & Pattern Scout**:
"What exists that this plan needs to know about?

Check:
1. `docs/domains/` — existing domain contracts and composition
2. Codebase patterns relevant to this feature
3. Integration points where new code connects to existing code
4. **Anti-reinvention**: Does any planned capability already exist? Scan `§ Concepts` tables across domains — concept matches are higher confidence than code-level matches.

For each proposed new component, check domain contracts and concepts:
- EXISTING → reuse (report contract and location)
- EXTEND → add to existing domain (report what to extend)
- NEW → create fresh (confirm no duplication)

Output: 4–6 findings, Critical and High impact only.
Format per finding: Title | Impact | What exists | What to do about it"

**Subagent 2 — Risk & Constraint Finder**:
"What could go wrong or surprise the implementor?

Check:
1. API limitations, framework gotchas
2. Specification ambiguities that affect implementation
3. Cross-domain dependencies needing coordination
4. Contract-breaking changes to existing domains

Output: 4–6 findings, Critical and High impact only.
Format per finding: Title | Impact | The risk | Mitigation"

**Wait for both. Merge into the Key Findings table.**

## B3: Generate the `## Implementation Plan`

### Output Contract (MUST satisfy — what G5/Structure validates)

The document **MUST** contain these sections, in this order. The top-metadata block, `## Business Specification`, and `## Planning Seam` are already written (Part A); Part B appends:

1. `## Implementation Plan` (the heading that marks the HOW half — load-bearing for routing)
2. `### Gate Matrix` (built in B4)
3. `### Summary` (3–5 sentences: problem, approach, expected outcome)
4. `### Domain Manifest` table — every file mentioned in any phase task table MUST appear with domain + classification
5. `### Key Findings` table (from B2 research)
6. `### Phases` containing `#### Phase Index` table followed by per-phase blocks — **or**, in Simple Mode, `### Implementation` with one inline task table
7. `### Acceptance Coverage Map` (tasks → AC ids from the business half)
8. `### Risks` table
9. `### Unresolved Gaps` (only if Status is `DRAFT — UNRESOLVED GAPS`; else omit)

> `### Target Domains` lives in the business half (it is `SPEC_DOMAINS`) — Part B does not restate it; gate G7 reads it there.

Any required section that cannot be populated correctly → still emit the heading with an inline `⚠️ GAP: <reason — see Unresolved Gaps table>` marker. **Never silently omit a required section.**

### Implementation Plan format (Full Mode)

```markdown
## Implementation Plan

### Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS / FAIL | <details if FAIL> |
| G2 | Constitution | PASS / FAIL / N/A | <details if FAIL> |
| G3 | Architecture | PASS / FAIL / N/A | <details if FAIL> |
| G4 | ADR Compliance | PASS / FAIL / N/A | <ADR refs if FAIL> |
| G5 | Structure | PASS / FAIL | <missing sections if FAIL> |
| G6 | Testing Alignment | PASS / FAIL | <offending phases if FAIL> |
| G7 | Domain Completeness | PASS / FAIL | <missing items if FAIL> |

### Summary
[3–5 sentences]

### Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|

Classification: `contract` (public interface), `internal` (domain-internal), `cross-domain` (editing another domain's files)

### Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | ... | ... |
| 02 | High | ... | ... |

### Phases

#### Phase Index

| Phase | Title | Primary Domain | Objective (1 line) | Depends On |
|-------|-------|---------------|-------------------|------------|
| 1 | ... | ... | ... | ... |
| N | ... | ... | ... | Phase N-1 |

[Then each phase in detail using the Per-Phase Format below]

### Acceptance Coverage Map

| AC | Covered by | Verified in |
|----|-----------|-------------|
| AC-01 | <task ids> | <task / criterion> |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

### Unresolved Gaps
[only if Status is DRAFT — UNRESOLVED GAPS — see B4]
```

### Phase Design Principles

- Each phase should primarily target **ONE domain**. Multi-domain phases are permitted but each domain-touch is a separate task group.
- Domain creation phases come BEFORE domain extension phases.
- Composition/wiring phases come LAST.
- **No "build the dev tooling" phase**: if research surfaced that no working dev substrate exists (no build, no test runner), surface it as a Critical Key Finding — don't invent a phase to stand tooling up; the plan uses the standard testing approach throughout.
- For each NEW domain, the first phase includes a domain setup task:
  - Create `docs/domains/<slug>/domain.md` (use the format from `/extract-domain`)
  - Create the source directory
  - Update `docs/domains/registry.md`
  - Update `docs/domains/domain-map.md` — add the new domain node with exposed contracts + dependency edges

### Per-Phase Format

#### Phase N: [Title]

**Objective**: [One sentence]
**Domain**: [Primary domain]
**Delivers**: [Bullet list of concrete deliverables]
**Depends on**: [Prior phases or "None"]
**Key risks**: [1–2 sentences, or "None"]

| # | Task | Domain | Success Criteria | Notes |
|---|------|--------|-----------------|-------|
| N.1 | [What to build] | [domain] | [How you know it works] | |
| N.2 | [What to build] | [domain] | [How you know it works] | Per finding 01 |

### Simple Mode

When `Mode: Simple`, the implementation half is a streamlined single phase: replace `### Phases` with one `### Implementation` block carrying an inline 7-column task table (no phase-task expansion needed):

```markdown
## Implementation Plan

### Gate Matrix
[as above]

### Summary
[2–3 sentences]

### Domain Manifest
[File → Domain mapping]

### Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|

### Implementation

**Objective**: [One sentence]
**Testing Approach**: [From the business half's Testing Strategy]

#### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | T001 | ... | ... | /abs/path | ... | |

### Acceptance Coverage Map
| AC | Covered by | Verified in |
|----|-----------|-------------|

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

### Unresolved Gaps
[only if Status is DRAFT — UNRESOLVED GAPS]
```

## B4: Self-Validation Gate Matrix & Emit

Before finalizing the document, run the post-generation gates (G5–G7), build the full Gate Matrix, and determine the single Status.

### Gate G5 — Structure
- All required sections from the Output Contract present and populated (top-metadata block, `## Business Specification`, `## Planning Seam`, `## Implementation Plan` + its subsections)? **FAIL** lists missing sections.
- Phase task tables present with success criteria? **FAIL** lists offending phases.
- Heading hierarchy correct (no skipped levels, no orphaned subsections)? **FAIL** describes the break.
- Cross-references resolve (e.g., "Per finding 01" — finding 01 exists; Acceptance Coverage Map AC ids exist in the business half)? **FAIL** lists broken refs.

### Gate G6 — Testing Alignment
- Read the business half's `### Testing Strategy`. What approach? (Full TDD / Lightweight / Manual / Hybrid)
- If TDD: in every phase task table, do test tasks appear before implementation tasks? **FAIL** lists offending phases.
- If Lightweight: at least one basic validation task per phase? **FAIL** lists phases without one.
- If Manual: verification steps described per phase? **FAIL** lists phases without them.
- Acceptance criteria measurable (not vague — "works correctly" fails; "returns 200 on /health with `status: ok`" passes)? **FAIL** lists vague criteria.
- Mock usage intent matches the stated preference (if specified)? **FAIL** describes mismatch.

### Gate G7 — Domain Completeness
- Is every domain in `SPEC_DOMAINS` (the business half's `### Target Domains`) present with status + relationship + role? **FAIL** lists missing.
- For each NEW domain: does some phase have a domain setup task (create `domain.md`, source dir, registry entry, domain-map update)? **FAIL** lists NEW domains without setup tasks.
- Domain Manifest covers every file referenced in phase task tables? **FAIL** lists uncovered files.
- For each existing domain referenced: does it actually exist in the registry? **FAIL** lists unknown domains.
- Domain Manifest classifications consistent (`contract` / `internal` / `cross-domain`)? **FAIL** lists inconsistencies.
- If a domain map exists: are new domains and edges consistent with topology (no circular business-domain deps; consumed-relationship domains have contracts identified)? **FAIL** describes the topology issue.
- NEW domains with contracts have `§ Concepts` planned? **FAIL** lists missing.

### Determine Status (single)

- All gates (G1–G7) PASS or N/A → `**Status**: READY`
- Any gate FAIL → `**Status**: DRAFT — UNRESOLVED GAPS`

### Emit

1. Build the Gate Matrix table with each gate's verdict + one-line note.
2. For each FAIL: embed an inline `⚠️ GAP: <one-line reason — see Unresolved Gaps>` marker at the violation site.
3. If any FAIL: append `## Unresolved Gaps` at the end of the document:

   ```markdown
   ## Unresolved Gaps

   | Gate | Severity | Where in plan | What to fix |
   |------|----------|---------------|-------------|
   | G6 | HIGH | Phase 2 task table | Re-order: tests must precede impl per TDD strategy |
   | G7 | HIGH | Target Domains table | Add `notifications` domain (in the business half, missing from the manifest) |
   ```

4. Save the complete document to `PLAN_PATH` (create `docs/plans/<ordinal>-<slug>/` if needed).
5. Report to terminal:

```
✅ Plan written: [PLAN_PATH]
Status: READY | DRAFT — UNRESOLVED GAPS
Mode: Simple | Full
Phases: [count]   Tasks: [count]   Domains: [count existing + count new]
Gate Matrix: [N PASS / M FAIL / K N/A]

(Deep validation via /validate-v2 auto-runs next — always, READY or DRAFT.)

[If DRAFT — UNRESOLVED GAPS]
Unresolved gaps listed at the end of the document. Common fixes:
  - G1 Clarify FAIL → this module's § Re-entry (mid-plan clarifications), then re-run
  - G2/G3 Constitution/Architecture FAIL → add a deviation ledger entry OR rework approach
  - G4 ADR FAIL → the adr verb (add mitigation), or update the plan to comply
  - G5 Structure / G6 Testing / G7 Domain FAIL → edit inline, then re-run this verb (idempotent — regenerates both halves)
```

### Auto-Run Deep Validation

After the document is written, **always** auto-call the thesis-aware validator on it, regardless of Status:

```
/validate-v2 --artifact "${PLAN_PATH}"
```

This runs whether the document emitted `Status: READY` or `Status: DRAFT — UNRESOLVED GAPS`. The inline G1–G7 gates are lightweight structural checks done during generation; `validate-v2` is the heavier multi-agent thesis/forward-compatibility review — complementary, not redundant. The validator's findings are applied or surfaced per its own flow.

---

## Standard Questions

### Workflow Mode (Round 1, Q1 unless `--simple`)

**Default to Simple.** Simple is the recommended option for all but the genuinely complex work — present it first, marked `(recommended)`. Only steer toward Full when the work is clearly large/epic (CS-4/CS-5) **or** structurally demands it (multiple domains, several real phases, or required cross-cutting gates). When in doubt, pick Simple — it's cheaper to escalate a Simple plan to Full later than to carry Full ceremony on work that didn't need it.

| Option | Mode | Best For | What Changes |
|--------|------|----------|--------------|
| A | Simple **(recommended default)** | CS-1 through CS-3, single domain, one-to-few phases — the common case | Single-phase implementation half, inline tasks, the phase-task expansion (tasks verb) optional |
| B | Full | CS-4/CS-5, **or** genuinely multi-domain / multi-phase work that needs all gates | Multi-phase implementation half, required dossiers, all gates |

Recommend **A (Simple)** unless the CS score is 4+ or the sketch already shows multiple target domains / several phases. Don't reach for Full just because the work is unfamiliar — unfamiliarity is a research/workshop signal, not a mode signal.

**If Simple Mode**: top-metadata gets `**Mode**: Simple`; testing defaults to Lightweight.
**If Full Mode**: top-metadata gets `**Mode**: Full`; all gates required.

### Testing Strategy (Round 1)

| Option | Approach | Best For |
|--------|----------|----------|
| A | Full TDD | Complex logic, algorithms, APIs |
| B | Lightweight | Simple operations, config changes |
| C | Manual Only | One-time scripts, trivial changes |
| D | Hybrid | Mixed complexity — TDD for complex, lightweight for simple |

Updates: `### Testing Strategy` with Approach, Rationale, Focus Areas, Excluded.

### Mock Usage (Round 1)

| Option | Policy |
|--------|--------|
| A | Avoid mocks entirely — real data/fixtures only |
| B | Allow targeted mocks — limited to external systems |
| C | Allow liberal mocking — wherever beneficial |

### Documentation Strategy (Round 1)

| Option | Location | Best For |
|--------|----------|----------|
| A | README.md only | Quick-start essentials |
| B | docs/how/ only | Detailed guides |
| C | Hybrid (README + docs/how/) | Both quick-start and depth |
| D | No new documentation | Internal/trivial changes |

### Domain Review (Round 2, conditional)

Fires only if Target Domains contains NEW or contested entries. Read `docs/domains/domain-map.md` first if present, then present:

```
The document identifies these target domains:

| Domain | Status | Role |
|--------|--------|------|
| [from the business half] | [existing/NEW] | [from the business half] |
```

**For NEW domains** ask: does the boundary look right? should any part be absorbed into an existing domain? are contracts clear enough to proceed? how does it connect on the domain map (contracts in/out)?

**For existing domains** ask: will changes respect existing contracts? any contract-breaking changes (flag for ADR)? topology concerns (circular deps, high fan-in)?

After: update `### Target Domains` with the user's adjustments.

### Topic-specific (Round 2, conditional)

Draw from these categories based on `[NEEDS CLARIFICATION]` markers in the sketch:
- **Data model**: entity relationships, schemas, storage
- **FRs**: feature requirements needing clarification
- **NFRs**: performance, security, accessibility
- **Integrations**: external system dependencies
- **Edge cases**: boundary conditions, error scenarios
- **Terminology**: domain-specific terms needing definition

---

## Gates (whole pass)

- At least Round 1 completed (or `--simple` provided + 3 Round 1 answers)
- `### Target Domains` present with at least one domain
- No critical `[NEEDS CLARIFICATION]` markers remaining after Round 2 (or G1 FAIL / `--skip-clarify`)
- Both halves present: `## Business Specification`, `## Planning Seam`, `## Implementation Plan` — mandatory sections populated; acceptance criteria are testable
- Empty description → ERROR
- Focus on user value in the business half; the implementation half carries the build detail

## Output

`PLAN_PATH` written as one document — top-metadata + `## Business Specification` (clarifications applied) + `## Planning Seam` + `## Implementation Plan` (Gate Matrix + single Status) — with `/validate-v2` already auto-run. What comes after — workshops, the tasks/implement work — is the bundling flow's call.

---

## Re-entry: mid-plan clarifications *(absorbed from the legacy clarify skill)*

This is the **mid-plan re-entry point** for clarifications. The original "create-then-interrogate" two-skill flow is collapsed into the main body above, which front-loads questions before the sketch.

Use this re-entry ONLY when:
- A planning document already exists (created by this verb, or a legacy spec from the old split flow)
- A downstream verb (workshop, implement) surfaced new ambiguities
- The user wants to add a clarification round mid-stream

For a new document, use the main body of this module instead.

```md
User input:

$ARGUMENTS

# Expects: path to an existing planning document (or legacy spec), or a plan slug.
```

### Flow

1. Resolve `PLAN_DIR` from the path provided; set `PLAN_PATH = ${PLAN_DIR}/<slug>-plan.md` (or a legacy `<slug>-spec.md` business source if that is what exists).
2. Scan the existing business half for unresolved gaps:
   - `[NEEDS CLARIFICATION: …]` markers
   - Missing or thin Testing Strategy / Documentation Strategy / Target Domains
   - Open Questions entries
   - Domain Review needed (Target Domains has new/contested entries not yet reviewed)
3. Choose **up to 4 highest-impact questions** from the gap list. Skip questions already answered in earlier `#### Session` blocks.
4. Submit as ONE batched prompt (batched host) or sequentially (fallback). Cap = 4.
5. Append answers to `### Clarifications` → `#### Session YYYY-MM-DD` (new block — never modify earlier sessions).
6. Update affected business subsections immediately (Target Domains, Testing Strategy, Documentation Strategy, ACs, Risks, etc.).
7. **Re-run this verb** so it regenerates **both** halves with the clarifications folded in — `/validate-v2` re-runs and the single `**Status**` recomputes. Because the pass is atomic, the implementation half can never lag the business half (no STALE intermediate).
8. Emit a one-line coverage summary: "Resolved N/M open gaps. Remaining: …".

### Gates

- Document must exist; ERROR if not found
- At least one unresolved gap identified; if none, exit silently with "No clarifications needed."
- Cap of 4 questions per invocation (run again for further rounds)
- No critical `[NEEDS CLARIFICATION]` markers remaining after the session (or surface the survivors in the coverage summary)

### Output

Updated `PLAN_PATH` with a new `#### Session YYYY-MM-DD` block, the section updates the answers triggered, and (on re-run) both halves regenerated.

## Exit

Print the output-contract summary (✅ block: what was produced, where, key fields — deep validation has already run automatically). Then STOP. Do not name a next stage. If invoked standalone, end with exactly: "Routing is the flow's job — run the parent flow bare to continue."
