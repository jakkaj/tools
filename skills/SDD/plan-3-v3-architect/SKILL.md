---
name: plan-3-v3-architect
description: |
  Generate a lean, domain-aware implementation plan with self-validating fail-fast gates baked in. Runs Clarify / Constitution / Architecture / ADR / Structure / Testing Alignment / Domain Completeness gates inline during generation. Emits the plan with `**Status**: READY` (all gates pass) or `**Status**: DRAFT — UNRESOLVED GAPS` + inline `⚠️ GAP:` markers + a final `## Unresolved Gaps` table (any gate fails) so the user sees exactly what's wrong in context. Replaces plan-3-v2-architect AND plan-4-v2-complete-the-plan — the inline gates supersede the old plan-4 readiness check. After writing the plan it auto-runs the deep thesis-aware validator (`validate-v2`) on the result, every time.
---
Please deep think / ultrathink as this is a complex task.

# plan-3-v3-architect

Generate a **lean, domain-aware implementation plan** with phases, task tables, acceptance criteria, AND **self-validating fail-fast gates** baked in. Replaces both the legacy `plan-3-v2-architect` and the bolt-on `plan-4-v2-complete-the-plan` validator — gates run inline and the plan emits in one of two states:

- **`**Status**: READY`** — all gates passed; plan is consumable by `/plan-5`.
- **`**Status**: DRAFT — UNRESOLVED GAPS`** — one or more gates failed. The plan is **still written** (the user has context to fix) but is annotated with inline `⚠️ GAP: <reason>` markers at each violation site, plus a final `## Unresolved Gaps` summary table.

The plan is always written. The user is never blocked from seeing it. But the status header + inline gap markers + summary table make it impossible to silently consume a broken plan downstream.

---

## 🚫 NO TIME ESTIMATES

Use **Complexity Score (CS 1-5)** only:
- CS-1 (trivial): 0-2 points | CS-2 (small): 3-4 | CS-3 (medium): 5-7 | CS-4 (large): 8-9 | CS-5 (epic): 10-12
- Factors (each 0-2): Surface Area, Integration, Data/State, Novelty, Non-Functional, Testing/Rollout

---

```md
Inputs:
  FEATURE_SPEC = `docs/plans/<ordinal>-<slug>/<slug>-spec.md`,
  PLAN_PATH    = `docs/plans/<ordinal>-<slug>/<slug>-plan.md`,
  rules at `docs/project-rules/{rules.md, idioms.md, architecture.md, constitution.md}` (if present),
  ADRs at `docs/adr/*.md` (if present),
  today {{TODAY}}.

## PHASE 0: Detect Mode & Load Context

**Mode Detection**:
- Check spec for `**Mode**: Simple` or `**Mode**: Full`
- Simple → single-phase plan with inline tasks
- Full → multi-phase plan

**Domain Loading**:
- Read `## Target Domains` from spec → capture as `SPEC_DOMAINS` (the set every gate downstream compares against)
- If `docs/domains/registry.md` exists → read all registered domains
- If `docs/domains/domain-map.md` exists → read the architecture diagram (topology + contract flows)
- For each existing spec-listed domain → read `docs/domains/<slug>/domain.md` (note: concepts, contracts, composition, dependencies)
- For each NEW domain → note the sketch from spec (Purpose, Boundary Owns/Excludes)

**Agent Harness Loading**:
- If `docs/project-rules/engineering-harness.md` (canonical) — or legacy `agent-harness.md` / `harness.md`, read in that order — exists → read maturity level, boot command, health check, interaction methods
- Check spec `## Clarifications` for agent harness decisions
- If agent harness needed but doesn't exist → plan MUST include Phase 0: Build Agent Harness (unless user overrode in plan-1b/plan-2)

**ADR Loading** (NEW in v3):
- If `docs/adr/` exists → read all `docs/adr/*.md`
- Filter to `Status: Accepted` → capture as `ACCEPTED_ADRS`
- For each, note the constraint it imposes (what it requires / what it forbids)

## PHASE 1: Pre-Generation Gates

Each gate produces a PASS / FAIL / N/A verdict. FAILs do **not** block emission — they become inline `⚠️ GAP:` markers + entries in the final `## Unresolved Gaps` table + flip the plan's `**Status**` to `DRAFT — UNRESOLVED GAPS`.

### Gate G1 — Clarify
- If critical `[NEEDS CLARIFICATION]` markers remain in spec → **FAIL** with list of markers
- User can override with `--skip-clarify` → PASS with override note

### Gate G2 — Constitution (if `docs/project-rules/constitution.md` exists; else N/A)
- For each principle in the constitution, evaluate whether the planned approach violates it
- If any HIGH-impact violation has no entry in the Deviation Ledger → **FAIL**
- Deviation Ledger format (mandatory if violating):

| Principle Violated | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|-------------------|------------|------------------------------|-----------------|

### Gate G3 — Architecture (if `docs/project-rules/architecture.md` exists; else N/A)
- Check planned files/domains against layer boundaries and dependency rules
- Any violation without a documented exception → **FAIL**

### Gate G4 — ADR Compliance (if `ACCEPTED_ADRS` non-empty; else N/A)
- For each Accepted ADR: does the plan contradict its decision?
- Contradiction with no mitigation → **FAIL** with ADR reference (e.g. `ADR-007: requires X, plan does Y`)

## PHASE 2: Research

### Check for Existing Research

If `${PLAN_DIR}/research-dossier.md` exists:
- Read fully; extract critical findings
- Reduce to 1 research subagent (implementation-focused only)
- Reference findings throughout plan

If `${PLAN_DIR}/workshops/*.md` exist:
- Read all workshops — these are **authoritative design decisions**
- Do NOT contradict workshop decisions
- Skip research for workshopped topics

If `${PLAN_DIR}/backpressure-coverage.md` exists (from `/plan-2d-backpressure-survey`):
- Read it. Note its qualitative Certainty and its **Recommended Phase 0: Establish Backpressure** table (if present).
- Treat a Recommended Phase 0 as an **optional, user-decided** input to phase design (see § Phase Design Principles) — NOT a gate. Absence of this artifact changes nothing (no error, no Status change).

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
2. Spec ambiguities that affect implementation
3. Cross-domain dependencies needing coordination
4. Contract-breaking changes to existing domains

Output: 4–6 findings, Critical and High impact only.
Format per finding: Title | Impact | The risk | Mitigation"

**Wait for both. Merge into Key Findings table.**

## PHASE 3: Generate Plan

### Output Contract (MUST satisfy — these are the things G5/Structure validates)

The plan **MUST** contain these sections, in this order:

1. `# [Feature Name] Implementation Plan` (title)
2. Metadata block with: `Plan Version`, `Created`, `Spec` link, `**Status**` (READY or DRAFT — UNRESOLVED GAPS)
3. `## Gate Matrix` (inserted by Phase 4 — see below)
4. `## Summary` (3–5 sentences: problem, approach, expected outcome)
5. `## Target Domains` table — every domain in `SPEC_DOMAINS` MUST appear with status, relationship, role
6. `## Domain Manifest` table — every file mentioned in any phase task table MUST appear with domain + classification
7. `## Key Findings` table (from Phase 2 research)
8. `## Phases` containing `### Phase Index` table followed by per-phase blocks
9. `## Acceptance Criteria` (testable, derived from spec)
10. `## Risks` table
11. `## Agent Harness Strategy` (if harness relevant — else omit cleanly)
12. `## Unresolved Gaps` (only if Status is `DRAFT — UNRESOLVED GAPS`; else omit)

Any required section that cannot be populated correctly → still emit the heading with inline `⚠️ GAP: <reason — see Unresolved Gaps table>` marker. **Never silently omit a required section.**

### Plan Output Format

```markdown
# [Feature Name] Implementation Plan

**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link to spec]
**Status**: READY | DRAFT — UNRESOLVED GAPS

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS / FAIL | <details if FAIL> |
| G2 | Constitution | PASS / FAIL / N/A | <details if FAIL> |
| G3 | Architecture | PASS / FAIL / N/A | <details if FAIL> |
| G4 | ADR Compliance | PASS / FAIL / N/A | <ADR refs if FAIL> |
| G5 | Structure | PASS / FAIL | <missing sections if FAIL> |
| G6 | Testing Alignment | PASS / FAIL | <offending phases if FAIL> |
| G7 | Domain Completeness | PASS / FAIL | <missing items if FAIL> |

## Summary

[3–5 sentences]

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| ... | existing/NEW | modify/create/consume | ... |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|

Classification: `contract` (public interface), `internal` (domain-internal), `cross-domain` (editing another domain's files)

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | ... | ... |
| 02 | High | ... | ... |

## Phases

### Phase Index

| Phase | Title | Primary Domain | Objective (1 line) | Depends On |
|-------|-------|---------------|-------------------|------------|
| 0 | Build Agent Harness | — | [if applicable] | None |
| 1 | ... | ... | ... | ... |
| N | ... | ... | ... | Phase N-1 |

[Then each phase in detail using Per-Phase Format below]

## Acceptance Criteria

- [ ] [Testable criterion from spec]
- [ ] [Testable criterion from spec]

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

## Agent Harness Strategy
[if harness relevant — see below]

## Unresolved Gaps
[only if Status is DRAFT — UNRESOLVED GAPS — see Phase 4]
```

### Phase Design Principles

- Each phase should primarily target **ONE domain**. Multi-domain phases are permitted but each domain-touch is a separate task group.
- Domain creation phases come BEFORE domain extension phases.
- Composition/wiring phases come LAST.
- **If agent harness is needed and doesn't exist**: Phase 0 is "Build Agent Harness". Phase 0 creates `docs/project-rules/engineering-harness.md` (canonical name) and implements Boot + Interact + Observe capabilities. Target maturity: L2 minimum. If user overrode in plan-2/plan-1b, skip Phase 0 and note override.
  - **Engineering harness prerequisite**: agent harness sits on top of a working engineering harness substrate (justfile/Makefile/dev script with a boot command healthy <60s, plus a test runner). If plan-1a research surfaced no engineering harness exists, surface as a Critical Key Finding. Engineering harness design is per-project and not modeled as a phase here.
- **If `${PLAN_DIR}/backpressure-coverage.md` recommends a Phase 0** (from `/plan-2d-backpressure-survey`): include an **optional** "Phase 0: Establish Backpressure" whose tasks build the sensors named in that artifact's Recommended Phase 0 table (data-check scripts, dependency/architecture rules, smoke routes, CodeQL/Roslyn queries, schema checks). This is **advisory** — include it when the survey recommends it and the user wants the deterministic provability; **never gate on it and never flip Status to DRAFT for its absence**. If both this and the agent-harness Phase 0 apply, they may be one combined Phase 0 or sequential (harness substrate first).
- For each NEW domain, first phase includes domain setup task:
  - Create `docs/domains/<slug>/domain.md` (use format from `/extract-domain`)
  - Create source directory
  - Update `docs/domains/registry.md`
  - Update `docs/domains/domain-map.md` — add new domain node with exposed contracts + dependency edges

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

### Agent Harness Strategy (if harness relevant)

```markdown
## Agent Harness Strategy
- **Current Maturity**: L[N]
- **Target Maturity**: L[N] (by end of Phase [N])
- **Boot Command**: [command]
- **Health Check**: [command]
- **Interaction Model**: [HTTP API | Terminal | Browser | JSON-RPC]
- **Evidence Capture**: [JSON responses | screenshots | terminal output]
- **Pre-Phase Validation**: Required at start of every phase (Boot → Interact → Observe)
```

If no harness and user overrode: "Agent Harness: Not applicable (user override — [reason from plan-2])."

### Simple Mode

When `Mode: Simple`, generate a streamlined single-phase plan:

```markdown
# [Feature Name] Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link]
**Status**: READY | DRAFT — UNRESOLVED GAPS

## Gate Matrix
[as above]

## Summary
[2–3 sentences]

## Target Domains
[From spec]

## Domain Manifest
[File → Domain mapping]

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|

## Implementation

**Objective**: [One sentence]
**Testing Approach**: [From spec]

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | T001 | ... | ... | /abs/path | ... | |

### Acceptance Criteria
- [ ] ...

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

## Unresolved Gaps
[only if Status is DRAFT — UNRESOLVED GAPS]
```

Simple Mode tasks use the 7-column format directly (no plan-5 expansion needed).

## PHASE 4: Self-Validation Gate Matrix & Emit

Before writing the plan file, run the post-generation gates (G5–G7), build the full Gate Matrix, and determine the Status.

### Gate G5 — Structure
- All required sections from the Output Contract present and populated? **FAIL** lists missing sections.
- Phase task tables present with success criteria? **FAIL** lists offending phases.
- Heading hierarchy correct (no skipped levels, no orphaned subsections)? **FAIL** describes the break.
- Cross-references resolve (e.g., "Per finding 01" — finding 01 actually exists)? **FAIL** lists broken refs.

### Gate G6 — Testing Alignment
- Read spec's `## Testing Strategy`. What approach? (Full TDD / Lightweight / Manual / Hybrid)
- If TDD: in every phase task table, do test tasks appear before implementation tasks? **FAIL** lists offending phases.
- If Lightweight: at least one basic validation task per phase? **FAIL** lists phases without one.
- If Manual: verification steps described per phase? **FAIL** lists phases without them.
- Acceptance criteria measurable (not vague — "works correctly" fails; "returns 200 on /health with `status: ok`" passes)? **FAIL** lists vague criteria.
- Mock usage intent matches spec preference (if specified)? **FAIL** describes mismatch.

### Gate G7 — Domain Completeness
- Is every domain in `SPEC_DOMAINS` present in the plan's Target Domains table with status + relationship + role? **FAIL** lists missing.
- For each NEW domain: does some phase have a domain setup task (create `domain.md`, source dir, registry entry, domain-map update)? **FAIL** lists NEW domains without setup tasks.
- Domain Manifest covers every file referenced in phase task tables? **FAIL** lists uncovered files.
- For each existing domain referenced in the plan: does the domain actually exist in registry? **FAIL** lists unknown domains.
- Domain Manifest classifications are consistent (`contract` / `internal` / `cross-domain`)? **FAIL** lists inconsistencies.
- If domain map exists: are new domains and edges consistent with topology (no circular business-domain deps; consumed-relationship domains have contracts identified)? **FAIL** describes the topology issue.
- NEW domains with contracts have `§ Concepts` planned (concepts identified during implementation per plan tasks)? **FAIL** lists missing.

### Determine Status

- All gates (G1–G7) PASS or N/A → `**Status**: READY`
- Any gate FAIL → `**Status**: DRAFT — UNRESOLVED GAPS`

### Emit Plan

1. Build the Gate Matrix table with each gate's verdict + one-line note.
2. For each FAIL: embed an inline `⚠️ GAP: <one-line reason — see Unresolved Gaps>` marker at the violation site in the plan body.
3. If any FAIL: append `## Unresolved Gaps` at the end of the plan:

   ```markdown
   ## Unresolved Gaps

   | Gate | Severity | Where in plan | What to fix |
   |------|----------|---------------|-------------|
   | G6 | HIGH | Phase 2 task table | Re-order: tests must precede impl per spec's TDD strategy |
   | G7 | HIGH | Target Domains table | Add `notifications` domain (in spec, missing from plan) |
   ```

4. Create parent directory if needed: `docs/plans/<ordinal>-<slug>/`
5. Write plan to: `docs/plans/<ordinal>-<slug>/<slug>-plan.md`
6. Report to terminal:

```
✅ Plan written: [path]
Status: READY | DRAFT — UNRESOLVED GAPS
Phases: [count]
Tasks: [count]
Domains: [count existing + count new]
Gate Matrix: [N PASS / M FAIL / K N/A]

(Deep validation via /validate-v2 auto-runs next — always, READY or DRAFT.)

[If READY]
Next step: Run /plan-5-v2-phase-tasks-and-brief

[If DRAFT — UNRESOLVED GAPS]
Unresolved gaps listed at end of plan. Common fixes:
  - G1 Clarify FAIL → run /plan-2-v2-clarify on the spec
  - G2/G3 Constitution/Architecture FAIL → add deviation ledger entry OR rework approach
  - G4 ADR FAIL → run /plan-3a-v2-adr to add mitigation, or update plan to comply
  - G5 Structure / G6 Testing / G7 Domain FAIL → edit plan inline, then re-run /plan-3-v3-architect (idempotent)
Re-run /plan-3-v3-architect after fixing to re-check gates.
```

### Auto-Generate Plan-Level Flight Plan

After writing the plan, auto-call `/plan-5b-flightplan --plan "${PLAN_PATH}"` (no `--phase` flag = plan-level mode). The flight plan reflects the current Status. If a flight plan already exists from plan-1b, it is enriched — Flight Log preserved.

### Auto-Run Deep Validation

After the flight plan is generated, **always** auto-call the thesis-aware validator on the freshly written plan, regardless of Status:

```
/validate-v2 --artifact "${PLAN_PATH}"
```

This runs whether the plan emitted `Status: READY` or `Status: DRAFT — UNRESOLVED GAPS`. The inline G1–G7 gates are lightweight structural checks done during generation; `validate-v2` is the heavier multi-agent thesis/forward-compatibility review — they are complementary, not redundant. The validator's findings are applied or surfaced per its own flow; a DRAFT plan's already-known gaps will simply be reconfirmed alongside any deeper issues the validator finds.
```

Next step (when `Status: READY`): Run **/plan-5-v2-phase-tasks-and-brief** (deep validation has already run automatically)
Next step (when `Status: DRAFT — UNRESOLVED GAPS`): Address the gaps (see report above + validator findings), then re-run **/plan-3-v3-architect** to re-validate.
