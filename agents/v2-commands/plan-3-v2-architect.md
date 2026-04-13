---
description: Generate a domain-aware, lean implementation plan with phases, task tables, and concise research findings. V2 standalone rewrite.
---

Please deep think / ultrathink as this is a complex task.

# plan-3-v2-architect

Generate a **lean, domain-aware implementation plan** with phases, task tables, and acceptance criteria. Produces the master plan document that guides all subsequent implementation.

---

## 🚫 NO TIME ESTIMATES

Use **Complexity Score (CS 1-5)** only:
- CS-1 (trivial): 0-2 points | CS-2 (small): 3-4 | CS-3 (medium): 5-7 | CS-4 (large): 8-9 | CS-5 (epic): 10-12
- Factors (each 0-2): Surface Area, Integration, Data/State, Novelty, Non-Functional, Testing/Rollout

---

```md
Inputs:
  FEATURE_SPEC = `docs/plans/<ordinal>-<slug>/<slug>-spec.md`,
  PLAN_PATH = `docs/plans/<ordinal>-<slug>/<slug>-plan.md`,
  rules at `docs/project-rules/{rules.md, idioms.md, architecture.md}` (if present),
  constitution at `docs/project-rules/constitution.md` (if present),
  today {{TODAY}}.

## PHASE 0: Detect Mode & Load Domains

**Mode Detection**:
- Check spec for `**Mode**: Simple` or `**Mode**: Full`
- Simple → Single-phase plan with inline tasks
- Full → Multi-phase plan

**Domain Loading**:
- Read `## Target Domains` from spec → list of existing and NEW domains
- If `docs/domains/registry.md` exists → read all registered domains
- If `docs/domains/domain-map.md` exists → read the domain architecture diagram to understand current relationships and contract flows
- For each existing domain in spec's target list → read `docs/domains/<slug>/domain.md`
  * Note: concepts (what the domain offers — § Concepts table), contracts (what's available to use), composition (what exists), dependencies
- For each NEW domain → note the sketch from spec (Purpose, Boundary Owns/Excludes)

**Harness Loading**:
- If `docs/project-rules/harness.md` exists → read maturity level, boot command, health check, interaction methods
- Check spec `## Clarifications` for harness decisions (from plan-2): "Build harness as Phase 0" / "Continue without" / "Not needed"
- If harness needed but doesn't exist → plan MUST include Phase 0: Build Harness (unless user overrode)

## PHASE 1: Gates

### GATE - Clarify
- If critical `[NEEDS CLARIFICATION]` markers remain in spec, instruct running /plan-2-v2-clarify first
- User can override with --skip-clarify

### GATE - Constitution (if present)
- Validate plan against docs/project-rules/constitution.md
- Document deviations:

| Principle Violated | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|-------------------|------------|------------------------------|-----------------|

### GATE - Architecture (if present)
- Validate against `docs/project-rules/architecture.md`
- Check for layer-boundary violations
- Document exceptions with justification

## PHASE 2: Research

### Check for Existing Research

If `${PLAN_DIR}/research-dossier.md` exists:
- Read completely, extract critical findings
- Reduce to 1 research subagent (implementation-focused only)
- Reference findings throughout plan

If `${PLAN_DIR}/workshops/*.md` exist:
- Read all workshops — these are **authoritative design decisions**
- Do NOT contradict workshop decisions
- Skip research for workshopped topics

### Research Subagents (2, not 4)

Launch **2 parallel subagents**:

**Subagent 1: Domain & Pattern Scout**
"What exists that this plan needs to know about?

Check:
1. `docs/domains/` — existing domain contracts and composition
2. Codebase patterns relevant to this feature
3. Integration points where new code connects to existing code
4. **Anti-reinvention**: Does any capability being planned already exist in a domain?
   Check `§ Concepts` tables across all domains — scan for concept names, entry points, and descriptions that match planned capabilities. A concept match is higher confidence than a code-level match.

For each proposed new component, check domain contracts and concepts:
- EXISTING → reuse (report contract and location)
- EXTEND → add to existing domain (report what to extend)
- NEW → create fresh (confirm no duplication)

Output: 4-6 findings, Critical and High impact only.
Format per finding: Title | Impact | What exists | What to do about it"

**Subagent 2: Risk & Constraint Finder**
"What could go wrong or surprise the implementor?

Check:
1. API limitations, framework gotchas
2. Spec ambiguities that affect implementation
3. Cross-domain dependencies needing coordination
4. Contract-breaking changes to existing domains

Output: 4-6 findings, Critical and High impact only.
Format per finding: Title | Impact | The risk | Mitigation"

**Wait for both. Merge into Key Findings table.**

## PHASE 3: Generate Plan

### Plan Output Format

```markdown
# [Feature Name] Implementation Plan

**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link to spec]
**Status**: DRAFT

## Summary

[3-5 sentences: Problem, approach, expected outcome]

## Target Domains

[From spec — domains this plan touches or depends on]

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| ... | ... | modify/create/consume | ... |

## Domain Manifest

[Every file this plan introduces or modifies, mapped to its domain]

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

[Generate this index AFTER designing all phases — it is the quick-reference summary at the top]

| Phase | Title | Primary Domain | Objective (1 line) | Depends On |
|-------|-------|---------------|-------------------|------------|
| 0 | Build Harness | — | [if applicable] | None |
| 1 | ... | ... | ... | ... |
| N | ... | ... | ... | Phase N-1 |

---

[Then generate each phase in detail below, following these principles:]

### Phase Design Principles

- Each phase should primarily target **ONE domain**
- Multi-domain phases are permitted but each domain-touch is a separate task group
- Domain creation phases come BEFORE domain extension phases
- Composition/wiring phases (connecting domains) come LAST
- **If harness is needed and doesn't exist**: Phase 0 is "Build Harness" — this is the prerequisite that enables agent autonomy for all subsequent phases. Phase 0 creates `docs/project-rules/harness.md` and implements Boot + Interact + Observe capabilities. Target maturity: L2 minimum (auto boot + API interaction). If user overrode harness in plan-2, skip Phase 0 and note override in plan.
- For each NEW domain, first phase includes domain setup task:
  * Create `docs/domains/<slug>/domain.md` (use format from /extract-domain)
  * Create source directory
  * Update `docs/domains/registry.md`
  * Update `docs/domains/domain-map.md` — add new domain node with exposed contracts and dependency edges

### Harness Strategy (include in plan output if harness is relevant)

If harness exists or Phase 0 builds one, add this section to the plan:

```markdown
## Harness Strategy
- **Current Maturity**: L[N]
- **Target Maturity**: L[N] (by end of Phase [N])
- **Boot Command**: [command]
- **Health Check**: [command]
- **Interaction Model**: [HTTP API | Terminal | Browser | JSON-RPC]
- **Evidence Capture**: [JSON responses | screenshots | terminal output]
- **Pre-Phase Validation**: Required at start of every phase (Boot → Interact → Observe)
```

If no harness and user overrode, note: "Harness: Not applicable (user override — [reason from plan-2])."

### Per-Phase Format

#### Phase N: [Title]

**Objective**: [One sentence]
**Domain**: [Primary domain this phase targets]
**Delivers**: [Bullet list of concrete deliverables]
**Depends on**: [Prior phases or "None"]
**Key risks**: [1-2 sentences, or "None"]

| # | Task | Domain | Success Criteria | Notes |
|---|------|--------|-----------------|-------|
| N.1 | [What to build] | [domain] | [How you know it works] | |
| N.2 | [What to build] | [domain] | [How you know it works] | Per finding 01 |

### Acceptance Criteria

- [ ] [Testable criterion from spec]
- [ ] [Testable criterion from spec]

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
```

### Simple Mode

When `Mode: Simple`, generate a streamlined single-phase plan:

```markdown
# [Feature Name] Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link]
**Status**: DRAFT

## Summary
[2-3 sentences]

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
```

Simple Mode tasks use the 7-column format directly (no plan-5 expansion needed).

**Next steps (Simple Mode)**:
- Ready to implement: `/plan-6-v2-implement-phase --plan "<path>"`
- Optional: `/plan-4-complete-the-plan` for validation

**Next steps (Full Mode)**:
- Run `/plan-4-complete-the-plan` to validate
- Then `/plan-5-v2-phase-tasks-and-brief` per phase

## PHASE 4: Validation

Before writing the plan, verify:
- [ ] All phases have task tables
- [ ] Each task has success criteria
- [ ] Domain manifest covers all files
- [ ] Target domains from spec are all addressed
- [ ] Key findings reference affected phases
- [ ] No time language present (CS 1-5 only)
- [ ] Absolute paths used throughout

### Output

1. Create parent directory if needed: `docs/plans/<ordinal>-<slug>/`
2. Write plan to: `docs/plans/<ordinal>-<slug>/<slug>-plan.md`

```
✅ Plan created:
- Location: [path]
- Phases: [count]
- Tasks: [count]
- Domains: [count existing + count new]
- Next step: [based on mode]
```
```

Next step (Full Mode): Run **/plan-4-complete-the-plan** to validate readiness.
Next step (Simple Mode): Run **/plan-6-v2-implement-phase --plan "<PLAN_PATH>"**

### Auto-Generate Plan-Level Flight Plan

After writing the plan, auto-call `/plan-5b-flightplan --plan "${PLAN_PATH}"` (no --phase flag = plan-level mode).

This regenerates `${PLAN_DIR}/<slug>.fltplan.md` with full phase data, architecture vision, and journey map. Status becomes "Ready". If a flight plan already exists from plan-1b, it is enriched — the Flight Log section is preserved.
