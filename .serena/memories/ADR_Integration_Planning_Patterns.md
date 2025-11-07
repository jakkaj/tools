# ADR Integration Planning Command Patterns Analysis

## Overview
Analysis of the existing planning command structure (plan-1 through plan-7a) to understand patterns needed for ADR integration implementation.

---

## 1. COMMAND STRUCTURE & NAMING PATTERNS

### Command Files Location
- **Path**: `/Users/jordanknight/github/tools/agents/commands/`
- **Files**: YAML frontmatter + markdown task descriptions
- **Format**: Each command starts with `---\ndescription: ...\n---`
- **Entry Point**: Markdown sections with task flow in code blocks

### Command Hierarchy
```
plan-0-constitution.md         (Establish project rules)
├── plan-1-specify.md          (Create feature spec from natural language)
│   ├── plan-2-clarify.md      (Resolve spec ambiguities via Q&A)
│   │   ├── plan-3-architect.md (Generate phase-based implementation plan)
│   │   │   ├── plan-4-complete-the-plan.md (Validate plan completeness)
│   │   │   ├── plan-5-phase-tasks-and-brief.md (Generate task dossier for ONE phase)
│   │   │   │   ├── plan-5a-subtask-tasks-and-brief.md (Subtask dossier within phase)
│   │   │   │   ├── plan-6-implement-phase.md (Code implementation with TDD)
│   │   │   │   │   ├── plan-6a-update-progress.md (Update plan/dossier with progress)
│   │   │   │   │   └── plan-7-code-review.md (Read-only diff audit)
```

### Where ADR Integration Fits
- **New command location**: `/Users/jordanknight/github/tools/agents/commands/plan-3a-adr.md`
- **Trigger point**: After plan-3-architect completion (before plan-4 or parallel to plan-3)
- **Dependencies**: spec + plan context
- **Outputs**: ADR documents to `docs/adrs/<NNNN>-adr-slug.md`

---

## 2. SPEC STRUCTURE PATTERNS (plan-1-specify.md)

### File Locations
```
docs/plans/<ordinal>-<slug>/
├── <slug>-spec.md          # Co-located with plan
├── <slug>-plan.md          # Co-located with spec
└── tasks/
    ├── phase-1-XXX/
    │   ├── tasks.md
    │   └── execution.log.md
```

### Spec Sections (Canonical Order)
1. `# <Feature Title>`
2. `## Summary` - WHAT/WHY overview (2-3 sentences)
3. `## Goals` - bullet list of desired outcomes/user value
4. `## Non-Goals` - explicitly out-of-scope behavior
5. `## Acceptance Criteria` - numbered, testable scenarios
6. `## Risks & Assumptions` - risk/assumption matrix
7. `## Open Questions` - unresolved items
8. `## Clarifications` - Q&A session results (Section 2.4 pattern)
9. `## Testing Strategy` - Approach + Rationale + Focus Areas (from plan-2)
10. `## Documentation Strategy` - Location + Rationale (from plan-2)
11. **NEW: `## ADR Seeds` (optional)** - Decision drivers, alternatives, stakeholders (plan-2 question?)

### Spec Update Pattern (From plan-2-clarify.md)
- **Session format**: `### Session YYYY-MM-DD`
- **Question tracking**: Q1, Q2, Q3...QN (capped at 8)
- **Answer embedding**: Append question/answer under `## Clarifications` → `### Session DATE`
- **Spec updates**: After each Q&A, immediately update relevant spec sections
- **Question types**:
  - Testing Strategy (Q1 or Q2, prioritized)
  - Mock Usage (Q2 or Q3)
  - Documentation Strategy (Q2 or Q3)
  - Feature-specific questions (Q4+)

---

## 3. PLAN STRUCTURE PATTERNS (plan-3-architect.md)

### File Locations
```
docs/plans/<ordinal>-<slug>/
├── <slug>-plan.md          # Main plan document (co-located)
└── tasks/
    ├── phase-1-XXX/
    ├── phase-2-YYY/
    └── phase-N-ZZZ/
```

### Plan Sections (Canonical Order)
1. **Title Block & Metadata**
   ```markdown
   # [Feature Name] Implementation Plan
   **Plan Version**: 1.0.0
   **Created**: {{TODAY}}
   **Spec**: [link to ./<slug>-spec.md]
   **Status**: DRAFT | READY | IN_PROGRESS | COMPLETE
   ```

2. **Table of Contents** (MANDATORY)
3. **Executive Summary**
4. **Technical Context**
5. **Critical Research Findings** (Section 3)
   - Minimum 15-20 discoveries (after deduplication)
   - Ordered by impact: Critical → High → Medium → Low
   - Synthesized from 4 parallel subagents (S1-S4)
6. **Testing Philosophy** (Section 6)
   - Reference Testing Strategy from spec
   - Selected Approach + Rationale
   - Focus Areas + Excluded
7. **Implementation Phases** (Section 8)
   - Phase N: [Title]
   - Objective, Deliverables, Dependencies, Risks
   - Task table: `| # | Status | Task | Success Criteria | Log | Notes |`
8. **Cross-Cutting Concerns**
   - Security, Observability, Documentation
9. **Complexity Tracking**
10. **Progress Tracking Checklist** (Section 11)
11. **Change Footnotes Ledger** (Section 12)
    ```markdown
    [^N]: Task {plan-task-id} - {one-line summary}
      - `flowspace-node-id`
      - `flowspace-node-id`
    ```
12. **Appendix A: Anchor Naming Conventions**
13. **Appendix B: Graph Traversal Guide**

### Parallel Research Pattern (Critical for ADR!)
```markdown
**Strategy**: Launch 4 specialized research subagents (single message with 4 Task calls):
- Subagent 1: Codebase Pattern Analyst (S1-01...S1-08)
- Subagent 2: Technical Investigator (S2-01...S2-08)
- Subagent 3: Discovery Documenter (S3-01...S3-08)
- Subagent 4: Dependency Mapper (S4-01...S4-08)

After all complete:
1. Collect all discoveries (S1-01 through S4-08)
2. Deduplicate (merge overlapping findings)
3. Renumber sequentially (01, 02, 03...)
4. Order by impact: Critical → High → Medium → Low
5. Format with title, impact, sources, problem, solution, example, actions
```

### Plan Task Table Format
```markdown
| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| 1.1 | [ ] | Write tests for X | Tests cover Y, all fail initially | - | |
| 1.2 | [ ] | Implement X | All tests from 1.1 pass | - | |
```

---

## 4. DOSSIER/TASKS STRUCTURE PATTERNS (plan-5-phase-tasks-and-brief.md)

### File Locations
```
docs/plans/<ordinal>-<slug>/tasks/
├── phase-1-XXX/
│   ├── tasks.md                           # Phase dossier
│   ├── execution.log.md                   # Created by plan-6
│   ├── 001-subtask-YYY.md                 # (optional) Subtask dossier
│   └── 001-subtask-YYY.execution.log.md   # (optional) Subtask log
├── phase-2-YYY/
└── phase-N-ZZZ/
```

### Tasks.md Canonical Sections

1. **Phase Metadata**
   ```markdown
   # Phase N: [Title]
   **Dossier Version**: 1.0.0
   **Created**: {{TODAY}}
   **Spec**: [link to ../../<slug>-spec.md]
   **Plan**: [link to ../../<slug>-plan.md]
   ```

2. **Tasks Table** (CANONICAL COLUMN ORDER)
   ```markdown
   | Status | ID | Task | Type | Dependencies | Absolute Path(s) | Validation | Subtasks | Notes |
   |--------|----|----|------|-------------|------------------|-----------|----------|-------|
   | [ ] | T001 | [task] | Setup | – | /abs/path | [validation] | – | [Notes] |
   ```
   - **Status**: Checkbox column `[ ]`, `[~]` (in progress), `[x]` (complete)
   - **ID**: T001, T002... (serial); reference plan task in Notes
   - **Task**: Imperative, specific, includes absolute paths inline
   - **Type**: Setup/Test/Core/Integration/Doc/etc.
   - **Dependencies**: T001, T002 (task IDs) or "–"
   - **Absolute Path(s)**: REQUIRED—no relative paths
   - **Validation**: Measurable acceptance criteria
   - **Subtasks**: `001-subtask-XXX, 003-subtask-YYY` or "–"
   - **Notes**: [P] (parallel), footnote refs (added by plan-6), context

3. **Alignment Brief** Section
   - Prior Phases Review (if not Phase 1) → synthesized from parallel subagent reviews
     * Phase-by-phase summary (evolution)
     * Cumulative deliverables (organized by origin phase)
     * Complete dependency tree
     * Pattern evolution + architectural continuity
     * Recurring issues + cross-phase learnings
     * Reusable test infrastructure
     * Critical findings timeline
   - Objective recap + behavior checklist
   - **Non-Goals (Scope Boundaries)**: Explicitly what this phase is NOT doing
   - **Critical Findings Affecting This Phase**: Relevant discoveries + constraints + task mapping
   - Invariants & guardrails
   - Inputs to read (exact file paths)
   - **Visual alignment aids**: Mermaid flow diagram + Mermaid sequence diagram
   - Test Plan (enumerate named tests, rationale, fixtures, expected outputs)
   - Implementation outline (map steps 1:1 to tasks)
   - Commands to run (copy/paste): env setup, test runner, linters, type checks
   - Risks/unknowns (severity + mitigation)
   - **Ready Check** (checkboxes) → await explicit GO/NO-GO

4. **Phase Footnote Stubs** Section
   - Empty table shell initially:
     ```markdown
     ## Phase Footnote Stubs
     
     | Footnote | Task ID | Symbols |
     |----------|---------|---------|
     ```
   - plan-6a populates with `[^N]: Task T### - summary` + FlowSpace node IDs

5. **Evidence Artifacts** Section
   ```markdown
   ## Evidence Artifacts
   
   Implementation will produce:
   - `PHASE_DIR/execution.log.md` – detailed task log with evidence
   - Test outputs (if applicable)
   - Modified source files with embedded FlowSpace ID comments
   ```

6. **Directory Layout Sketch** (at end)
   ```
   docs/plans/2-feature-x/
     ├── feature-x-plan.md
     ├── feature-x-spec.md
     └── tasks/
         ├── phase-1-foundation/
         │   ├── tasks.md
         │   └── execution.log.md
         ├── phase-2-core/
         │   ├── tasks.md
         │   ├── execution.log.md
         │   └── 001-subtask-fixtures.md
   ```

### Task Expansion Pattern (From Spec Tasks)
- **Input**: plan-3's high-level task table (e.g., task "1.1")
- **Expansion**: Each plan-3 task may become multiple dossier tasks (T001, T002, T003...)
- **Application**: Critical findings inform task breakdown and add extra validation tasks
- **Mapping**:
  ```
  Plan task "1.1" → T001, T002, T003 (expanded)
  T001 (Setup), T002 (Core), T003 (Test per Critical Finding 01)
  ```

---

## 5. PARALLEL SUBAGENT PATTERNS

### Pattern 1: Research Subagents (plan-3-architect, PHASE 2)
```markdown
**Strategy**: Launch 4 subagents in SINGLE message with 4 Task calls:
1. Codebase Pattern Analyst → S1-01...S1-08 (patterns, conventions, integration)
2. Technical Investigator → S2-01...S2-08 (API limits, gotchas, constraints)
3. Discovery Documenter → S3-01...S3-08 (ambiguities, implications, edge cases)
4. Dependency Mapper → S4-01...S4-08 (module deps, boundaries, concerns)

**Output format** (per discovery):
### Discovery SX-YY: [Title]
**Category**: [Pattern | API Limit | Ambiguity | Dependency]
**Impact**: Critical | High | Medium | Low
**What**: [Concise description]
**Why It Matters**: [How it affects implementation]
**Example**:
\`\`\`[language]
// ❌ WRONG - [Why this violates]
[bad code]

// ✅ CORRECT - [Why this works]
[good code]
\`\`\`
**Action Required**: [What implementation must do]

**Synthesis phase**:
- Collect S1-01 through S4-08
- Deduplicate (note sources: "S1-03, S2-05")
- Renumber sequentially: 01, 02, 03...NN
- Order by impact (Critical first, then High, Medium, Low)
- Each final discovery references source subagents
```

### Pattern 2: Prior Phase Review Subagents (plan-5-phase-tasks-and-brief, step 1a)
```markdown
**Strategy**: Launch ONE subagent per prior phase in SINGLE message (parallel):
- Phase 1 Review
- Phase 2 Review
- Phase 3 Review
(skip if Phase 1)

**Per subagent template**:
"Review Phase X to understand complete implementation, learnings, impact...
**Read**:
- PLAN_DIR/tasks/phase-X-slug/tasks.md
- PLAN_DIR/tasks/phase-X-slug/execution.log.md
- PLAN § 8 Progress Tracking for Phase X
- PLAN § 12 Change Footnotes related to Phase X
- PLAN § 3 Critical Findings addressed in Phase X

**Report** (structured):
A. Deliverables Created (with absolute paths)
B. Lessons Learned (deviations, complexity, approaches)
C. Technical Discoveries (gotchas, limitations)
D. Dependencies Exported (signatures, APIs, data structures)
E. Critical Findings Applied (file:line refs)
F. Incomplete/Blocked Items
G. Test Infrastructure
H. Technical Debt
I. Architectural Decisions
J. Scope Changes
K. Key Log References"

**Synthesis**:
- Combine all phase reviews into comprehensive cross-phase narrative
- Phase-by-phase summary showing evolution
- Cumulative deliverables + dependencies
- Pattern evolution + architectural continuity
- Recurring issues + cross-phase learnings
```

### Pattern 3: Bidirectional Link Validators (plan-7-code-review, step 3a)
```markdown
**Strategy**: Launch 5 validators in SINGLE message (parallel):
1. Task↔Log Validator
2. Task↔Footnote Validator
3. Footnote↔File Validator
4. File↔Dossier Validator
5. Plan↔Dossier Cross-Validator

**Each validator** reports violations in structured JSON:
{
  "violations": [
    {"severity": "HIGH", "task_id": "T003", "issue": "...", "fix": "..."},
    ...
  ],
  "validated_count": N,
  "broken_links_count": M
}

**Synthesis**:
- Collect all 5 validator reports
- Deduplicate/prioritize violations
- Flag Critical + HIGH as blocking (with --strict)
- Suggest fixes/patches
```

---

## 6. FILE CREATION PATTERNS

### Pattern 1: Spec Creation (plan-1-specify.md)
```bash
# Determine slug and create directory
PLAN_DIR = docs/plans/<ordinal>-<slug>/
SPEC_FILE = ${PLAN_DIR}/<slug>-spec.md

# Create directory if needed
mkdir -p ${PLAN_DIR}

# Populate spec with canonical sections
# Use Write tool to create file with full content
```

### Pattern 2: Plan Creation (plan-3-architect.md)
```bash
# Uses same PLAN_DIR as spec
PLAN_FILE = ${PLAN_DIR}/<slug>-plan.md

# Create single comprehensive markdown file
# Include all sections (TOC, Executive Summary, Findings, Phases, Footnotes, etc.)
# Use absolute paths throughout
```

### Pattern 3: Phase Dossier Creation (plan-5-phase-tasks-and-brief.md)
```bash
# Determine phase slug from plan content
PHASE_SLUG = "phase-N-title" (kebab-case)
PHASE_DIR = ${PLAN_DIR}/tasks/${PHASE_SLUG}

# Create directory if needed
mkdir -p ${PHASE_DIR}

# Create single dossier file
TASKS_FILE = ${PHASE_DIR}/tasks.md

# Create empty execution.log.md shell (plan-6 will populate)
```

### Pattern 4: Subtask Dossier Creation (plan-5a-subtask-tasks-and-brief.md)
```bash
# Scan existing subtasks to determine next ordinal
EXISTING = ${PHASE_DIR}/[0-9][0-9][0-9]-subtask-*.md
ORDINAL = highest_number + 1 (zero-padded to 3 digits)

# Create subtask file
SUBTASK_SLUG = kebab-case(summary)
SUBTASK_FILE = ${PHASE_DIR}/${ORD}-subtask-${SUBTASK_SLUG}.md
SUBTASK_LOG = ${PHASE_DIR}/${ORD}-subtask-${SUBTASK_SLUG}.execution.log.md

# Content mirrors plan-5 layout, scoped to subtask
# Includes Parent Context section with rich linkage back
```

### Pattern 5: ADR Creation (plan-3a-adr.md) - NEEDED
```bash
# Determine ADR numbering
EXISTING_ADRS = find docs/adrs -name "[0-9][0-9][0-9][0-9]-adr-*.md"
NEXT_NUMBERING = max_number + 1 (zero-padded to 4 digits)

# Create ADR file
ADR_SLUG = kebab-case(decision-title)
ADR_FILE = docs/adrs/${NNNN}-adr-${ADR_SLUG}.md

# Cross-link
- Add backlink to spec: "Related ADRs: [ADR-NNNN](../adrs/NNNN-adr-slug.md)"
- Add backlink to plan (if exists): "Related ADRs: [ADR-NNNN](...)"
```

---

## 7. CROSS-REFERENCING PATTERNS

### Internal File Links
```markdown
# Spec → Plan
[View Plan](./adr-flow-integration-plan.md)
[View Spec](./<slug>-spec.md)

# Plan → Phases
[Phase 1](./tasks/phase-1-slug/)
[Phase 2: Details](#phase-2-title)

# Phase Dossier → Plan
[View Plan](../../<slug>-plan.md)
[Spec](../../<slug>-spec.md)
[Phase X in Plan](../../<slug>-plan.md#phase-x-title)

# Plan → Spec
[Spec Reference](./adr-flow-integration-spec.md)

# Footnote References (plan-6a updates)
[^1]: Task 2.3 - Added validation function
  - `function:src/validators.py:validate_email`
  - `method:src/auth.py:AuthService.authenticate`
```

### Task References
```markdown
# From dossier to plan task
[Task 2.3 in Plan](../../plan.md#task-23-implement-validation)

# From plan to dossier task
[T003 in Dossier](./tasks/phase-2-slug/tasks.md#task-t003)

# From log to task
[Dossier Task](../tasks.md#task-t003)
[Plan Task](../../plan.md#task-23-implement-validation)
```

### Anchor Naming Conventions (Appendix A in plan-3)
```markdown
## Anchor Naming Conventions

### Phase Anchors
Format: phase-{number}-{slug}
Example: phase-2-input-validation

### Task Anchors (Plan)
Format: task-{flattened-number}-{slug}
Example: task-23-implement-validation (task 2.3)

### Task Anchors (Dossier)
Format: task-{id}-{slug}
Example: task-t003-implement-validation

### Subtask Anchors
Format: {ordinal}-subtask-{slug}
Example: 003-subtask-bulk-import-fixtures

### Slugification Rules
1. Lowercase
2. Replace spaces with hyphens
3. Replace non-alphanumeric (except hyphens) with hyphens
4. Collapse multiple consecutive hyphens to single
5. Trim leading/trailing hyphens
```

---

## 8. EXECUTION LOG PATTERNS (plan-6a-update-progress.md)

### Log Entry Structure
```markdown
## Task 2.3: [Task Title]

**Dossier Task**: T003
**Plan Task**: 2.3
**Plan Reference**: [Phase 2: Input Validation](../../plan.md#phase-2-input-validation)
**Dossier Reference**: [View T003 in Dossier](./tasks.md#task-t003)
**Plan Task Entry**: [View Task 2.3 in Plan](../../plan.md#task-23-implement-validation)

**Status**: Complete/In Progress/Blocked
**Evidence**:
- [Evidence detail 1]
- [Evidence detail 2]

**Notes**:
[Implementation notes, decisions, discoveries]
```

### Footnote Updates (Atomic 3-Location Update)
```markdown
# Location 1: Dossier tasks.md (§ Tasks table)
| [ ] | T003 | [task] | ... | [^3] | ...

# Location 2: Plan plan.md (§ 8 Implementation Phases)
| 2.3 | [x] | [task] | [success] | log#task-23-impl | [^3] |

# Location 3a: Plan plan.md (§ 12 Change Footnotes Ledger)
[^3]: Task 2.3 - Added validation function
  - `function:src/validators.py:validate_email`
  - `method:src/auth/service.py:AuthService.authenticate`

# Location 3b: Dossier tasks.md (§ Phase Footnote Stubs)
| [^3] | T003 | validate_email, AuthService.authenticate |
```

---

## 9. KEY PATTERNS FOR ADR INTEGRATION

### 1. Discovery & Seeding
- **In spec (plan-1)**: Optional `## ADR Seeds` section capturing decision drivers, alternatives, stakeholders
- **In clarifications (plan-2)**: Optional Q7+ asking about ADR generation preference
- **In plan research (plan-3)**: Parallel subagents include "Architectural Decision Mapper" to identify key decisions

### 2. ADR Generation Command (plan-3a-adr.md)
- **Trigger**: After spec clarification (plan-2 complete) + before/parallel to plan-3
- **Input**: spec + plan (if exists) + decision drivers
- **Parallel subagents**:
  - Existing ADR Scanner (find all existing ADRs in docs/adrs/)
  - Doctrine Mapper (read architecture.md, constitution.md for constraints)
  - Decision Extractor (identify decisions from spec/clarifications)
  - Alternative Analyzer (enumerate alternatives from spec)
- **Output**: ADR document(s) in docs/adrs/ with sequential 4-digit numbering
- **Format**: Status, Decision Title, Context, Drivers, Alternatives, Consequences, Rationale, Constraints, Supersedes

### 3. Integration Points
- **plan-3-architect**: Detects existing ADRs, incorporates constraints into critical findings
- **plan-5-phase-tasks**: Maps ADR constraints to specific task IDs in Notes
- **plan-6a-update-progress**: Suggests ADR status changes (Proposed → Accepted) based on task progress
- **plan-7-code-review**: Validates that ADR constraints are respected in implementation

### 4. Cross-Linking
- Spec → Related ADRs: `[ADR-0001](../adrs/0001-adr-slug.md)`
- Plan → ADRs: `[ADR-0001 constraints apply to Phase 2](...)`
- Tasks → ADRs: `Per ADR-0001, [task description]` (noted in task descriptions)
- ADR → Spec/Plan: Backlinks in ADR document

---

## 10. VALIDATION & QUALITY GATES

### plan-4-complete-the-plan.md
- Validates plan completeness before proceeding to plan-5
- Checks:
  - All phases present and numbered
  - All tasks have success criteria
  - Test examples provided
  - TDD approach evident
  - Absolute paths used
  - Dependencies clearly stated

### plan-7-code-review.md
- Validates implementation matches approved dossier
- Parallel subagent validators (5):
  - Task↔Log bidirectional links
  - Task↔Footnote bidirectional links
  - Footnote↔File bidirectional links
  - File↔Dossier cross-validation
  - Plan↔Dossier cross-validation
- Severity levels: CRITICAL, HIGH, MEDIUM, LOW
- Suggests fixes/patches

---

## SUMMARY: Patterns to Apply for ADR Integration

1. **Spec Enhancement** (plan-1): Add optional `## ADR Seeds` section
2. **Clarification Extension** (plan-2): Optional Q7-Q8 about ADR decisions + status automation
3. **New Command** (plan-3a): ADR generation with parallel subagents for discovery + doctrine mapping
4. **Plan Awareness** (plan-3): Incorporate ADR constraints into Critical Findings
5. **Task Mapping** (plan-5): Reference ADR IDs in task Notes; map constraints to specific tasks
6. **Progress Tracking** (plan-6a): Semi-automated ADR status suggestions (Proposed → Accepted)
7. **Code Review** (plan-7): Validate ADR constraints are respected in implementation diffs
8. **Cross-Linking**: Bidirectional links spec ↔ plan ↔ ADRs; footnote-style tracking
