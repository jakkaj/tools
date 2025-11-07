# Planning Workflow Commands Analysis

## Overview
The tools repository implements a sophisticated, sequential planning and implementation workflow for managing complex technical projects. The workflow is anchored by a series of numbered slash commands (plan-0 through plan-7) that guide projects from constitution through implementation, code review, and progress tracking.

## Planning Workflow Sequence (Critical Path)

### Phase 0: Constitution (`/plan-0-constitution`)
- **Purpose**: Establish or refresh the project constitution and align supporting doctrine files
- **Key Outputs**: 
  - `docs/rules/constitution.md` - Main project constitution with versions, principles, quality strategy, delivery practices, governance
  - `docs/rules-idioms-architecture/rules.md` - Enforceable MUST/SHOULD statements, testing requirements
  - `docs/rules-idioms-architecture/idioms.md` - Patterns, directory conventions, language-specific examples
  - `docs/rules-idioms-architecture/architecture.md` - System structure, boundaries, contracts, anti-patterns
- **Use Parallel Subagents**: Yes (4 parallel subagents for doctrine loading, context gathering, template scanning, version analysis)
- **Next Step**: /plan-1-specify

### Phase 1: Specification (`/plan-1-specify`)
- **Purpose**: Create feature spec from natural language, focusing on WHAT/WHY (not tech choices)
- **Key Outputs**: 
  - `docs/plans/<ordinal>-<slug>/<slug>-spec.md`
  - Sections: Title, Summary, Goals, Non-Goals, Acceptance Criteria, Risks & Assumptions, Open Questions
- **Gates**: Focus on user value, no stack/framework details, mandatory sections, testable acceptance scenarios
- **Next Step**: /plan-2-clarify

### Phase 2: Clarification (`/plan-2-clarify`)
- **Purpose**: Resolve high-impact ambiguities (≤8 questions), update spec with answers
- **Key Features**:
  - ONE question at a time with MC table (2-5 options) or short answers
  - **Prioritize Testing Strategy question** (Q1 or Q2) - options: Full TDD, TAD, Lightweight, Manual, Hybrid
  - **Mock Usage question** immediately after testing strategy
  - **Documentation Strategy question** early (Q2 or Q3) - options: README only, docs/how/ only, Hybrid, None
  - Updates spec with new Clarifications section and matching sections (Testing Strategy, Documentation Strategy, etc.)
- **Key Output Additions to Spec**:
  - Testing Strategy: Approach, Rationale, Focus Areas, Excluded, Mock Usage, TAD-Specific notes
  - Documentation Strategy: Location, Rationale, Content Split (if Hybrid), Target Audience, Maintenance
- **Next Step**: /plan-3-architect

### Phase 3: Architecture & Planning (`/plan-3-architect`)
- **Purpose**: Generate comprehensive, phase-based implementation plan with TDD/TAD structure and acceptance criteria
- **Complex Process**:
  - **GATE 1 - Clarify**: Check for [NEEDS CLARIFICATION] markers; offer --skip-clarify override
  - **GATE 2 - Constitution**: Validate against docs/rules/constitution.md; document deviations with justification
  - **GATE 3 - Architecture**: Validate against docs/rules-idioms-architecture/architecture.md; check layer boundaries
  - **Phase 2 Research**: Use 4 parallel subagents (Codebase Pattern Analyst, Technical Investigator, Discovery Documenter, Dependency Mapper) to identify 15-20+ critical discoveries ordered by impact
  - **Phase 3 Structure**: Generate project type, directory tree with absolute paths
  - **Phase 4 Generation**: Adapt testing strategy from spec (Full TDD, TAD, Lightweight, Manual, or Hybrid)
    - **Full TDD**: Tests first, implementation after
    - **TAD (Test-Assisted Development)**: tests/scratch/ exploration → RUN → promote valuable tests with Test Doc blocks (5 required fields)
    - **Lightweight**: Reduced test tasks, core validation only
    - **Manual**: Manual verification checklists instead of automated tests
    - **Hybrid**: Mix of approaches per phase
  - **Documentation Adaptation**: Based on spec strategy choice:
    - README only: Single phase updating root README
    - docs/how/ only: Numbered files in docs/how/<feature>/ directories (1-overview.md, 2-usage.md, 3-api.md)
    - Hybrid: Both README and docs/how/ with clear split
    - None: Skip documentation phases
- **Key Outputs**:
  - `docs/plans/<ordinal>-<slug>/<slug>-plan.md`
  - Includes: Title block, TOC, Executive Summary, Technical Context, Critical Research Findings, Testing Philosophy, Project Structure, Implementation Phases (with numbered tasks), Cross-Cutting Concerns, Complexity Tracking, Progress Tracking, Change Footnotes Ledger
  - Appendices: Anchor Naming Conventions, Graph Traversal Guide
- **Next Step**: /plan-4-complete-the-plan

### Phase 4: Plan Completeness Check (`/plan-4-complete-the-plan`)
- **Purpose**: Verify plan readiness before execution (read-only validation, no changes)
- **Use 4 Parallel Validators**:
  - Structure Validator: TOC, absolute paths, self-contained, heading hierarchy
  - Testing Validator: TDD order, tests-as-docs quality, mock policy match, test examples
  - Completeness Validator: Acceptance criteria, numbered tasks, dependencies, risks, critical findings, command lines
  - Doctrine Validator: Rules/idioms/architecture/constitution alignment, deviation ledger
- **Output Options**: READY, NOT READY, or NOT READY (USER OVERRIDE)
- **Can Override**: Users may proceed despite issues with documented risk acknowledgment
- **Next Step**: /plan-5-phase-tasks-and-brief

### Phase 5: Phase Tasks Dossier (`/plan-5-phase-tasks-and-brief`)
- **Purpose**: Generate detailed tasks.md dossier for ONE phase at a time + alignment brief (stop before implementation)
- **Process**:
  - **Parallel Subagent Review** (if not Phase 1): Review all prior phases with Task tool calls to understand deliverables, lessons learned, technical discoveries, dependencies, critical findings applied
  - **Synthesize Cross-Phase Insights**: Cumulative deliverables, dependencies, pattern evolution, recurring issues, foundation for current phase
  - **Read Critical Research Findings** from plan (step 2)
  - **Transform plan-3 tasks** into detailed T### sequence with expansion
  - **Apply Critical Findings**: Reference specific discoveries, may require additional tasks/validation tests
- **Canonical Tasks Format**:
  - Columns: Status (checkbox), ID (T001...), Task, Type (Setup/Test/Core/Integration/Doc), Dependencies, Absolute Path(s) (REQUIRED), Validation, Subtasks, Notes
  - All absolute paths required; includes critical findings references
- **Key Outputs**:
  - `docs/plans/<ordinal>-<slug>/tasks/phase-N-<slug>/tasks.md` (combined tasks + alignment brief)
  - `docs/plans/<ordinal>-<slug>/tasks/phase-N-<slug>/execution.log.md` (created but empty initially)
  - Alignment brief: objective, checklist, critical findings, deliverables, approach notes
  - Mermaid diagrams (flow + sequence) for complex phases
- **Next Step**: /plan-6-implement-phase (or /plan-5a for subtasks)

### Phase 5a: Subtask Dossier (`/plan-5a-subtask-tasks-and-brief`)
- **Purpose**: Generate subtask dossier when a request needs planning within an approved phase
- **Process**: Similar to plan-5 but scoped to subtask, with parent context linkage
- **Key Outputs**:
  - `docs/plans/<ordinal>-<slug>/tasks/phase-N-<slug>/<ordinal>-subtask-<slug>.md`
  - Parent Context section with links back to parent phase and plan
  - ST### task IDs instead of T###
  - Updated parent tasks.md Subtasks column with `001-subtask-fixtures, 003-subtask-bulk` entries
  - Updates Subtasks Registry in plan.md

### Phase 6: Implementation (`/plan-6-implement-phase`)
- **Purpose**: Execute one phase using testing approach from plan (TDD/TAD/Lightweight/Manual)
- **Key Evidence**:
  - Test runner output (RED→GREEN cycles for TAD)
  - Implementation code
  - Log entries in execution.log.md
- **Note**: Uses `/plan-6a-update-progress` to sync task status, footnotes, log entries

### Phase 6a: Progress Updates (`/plan-6a-update-progress`)
- **Purpose**: Update plan progress with task status, flowspace node IDs, and detailed execution logs
- **Critical**: Updates THREE locations atomically:
  1. Dossier task table (tasks.md or subtask file) - Status column + footnote
  2. Parent plan task table (plan.md § 8) - Status + Log + Notes columns + footnote
  3. Both footnote ledgers (plan.md § 12 + dossier § Phase Footnote Stubs)
- **Footnote System**:
  - Footnotes use sequential numbering [^1], [^2], etc.
  - Each footnote maps to modified file/function with FlowSpace node IDs
  - Examples: `function:src/validators.py:validate_email`, `method:AuthService.authenticate`
- **Execution Log Structure**:
  - Task anchors (kebab-case)
  - Backlinks to plan task, dossier task
  - Implementation details, test results, timing
- **Uses Parallel Subagents**: Yes (3 readers for plan, dossier, log state)

### Phase 7: Code Review (`/plan-7-code-review`)
- **Purpose**: Per-phase diff audit (read-only) verifying doctrine compliance and task alignment
- **Uses Parallel Validation**: 5 subagent validators for graph integrity (Task↔Log, Task↔Footnote, File↔Task, Dossier↔Plan, Subtask↔Parent)
- **Key Validation**:
  - Bidirectional link integrity
  - Scope guard (phase files only, with justifications)
  - Testing approach compliance
  - Mock usage consistency
  - Doctrine alignment
- **Output**: Structured review report (JSON findings with severity, fix suggestions) - NO CODE CHANGES

## Documentation Strategy Integration

### When Spec Requires README Only
- Single documentation phase with table tasks updating root README.md
- Content: What is feature, Installation/setup, Basic usage example, Link to detailed docs

### When Spec Requires docs/how/ Only
- Documentation phase with discovery, placement decision, file strategy steps
- Create docs/how/<feature>/ directory structure (numbered files: 1-overview.md, 2-usage.md, 3-api.md)
- Survey existing docs/how/ to decide: create new feature dir OR use existing
- Clear file paths and content outlines

### When Spec Requires Hybrid
- Multiple documentation phases (one for README, one(s) for docs/how/)
- Maintain clear split: overview + quick-start in README, detailed guides in docs/how/
- Explicit in plan which phase covers which

## ADR (Architectural Decision Record) Pattern Found

Located in `/Users/jordanknight/github/tools/scratch/adr.md` - An VS Code command template for ADR generation:
- **Status**: Proposed, Accepted, Rejected, Superseded, Deprecated
- **Structure**: Context, Decision, Consequences (Positive/Negative), Alternatives Considered, Implementation Notes, References
- **Coded Format**: POS-001, NEG-002, ALT-003, IMP-004, REF-005 for semantic parsing
- **Storage**: `/docs/adr/` directory with naming convention `adr-NNNN-[title-slug].md`
- **Current Status**: Template exists but NOT YET integrated into main planning workflow

## Key Directory Structure

```
tools/
├── agents/commands/          # SOURCE OF TRUTH for all planning commands
│   ├── plan-0-constitution.md
│   ├── plan-1-specify.md
│   ├── plan-2-clarify.md
│   ├── plan-3-architect.md
│   ├── plan-4-complete-the-plan.md
│   ├── plan-5-phase-tasks-and-brief.md
│   ├── plan-5a-subtask-tasks-and-brief.md
│   ├── plan-6-implement-phase.md (brief reference)
│   ├── plan-6a-update-progress.md
│   ├── plan-7-code-review.md
│   ├── substrateresearch.md
│   ├── tad.md (Test-Assisted Development)
│   ├── didyouknow.md
│   ├── deepresearch.md
│   ├── codebase.md
│   ├── changes.md
│   └── (others)
├── .vscode/                  # VS Code bridge - mirrors agents/commands
│   ├── plan-0-constitution.md
│   ├── plan-1-specify.md
│   ├── architect.md (enhanced version)
│   └── (mirrors of all commands)
├── docs/
│   ├── plans/                # Executed plans
│   │   └── 001-ghcp-prompt-mirroring/
│   │       ├── ghcp-prompt-mirroring-spec.md
│   │       ├── ghcp-prompt-mirroring-plan.md
│   │       └── tasks/
│   │           ├── phase-1-directory-variable-setup/
│   │           │   ├── tasks.md
│   │           │   └── execution.log.md
│   │           ├── phase-2-copy-rename-operations/
│   │           ├── phase-3-vs-code-settings-merge/
│   │           └── phase-4-idempotency-verification/
│   └── specs/                # Specification storage (currently empty)
├── scratch/
│   └── adr.md               # ADR command template (NOT in main workflow yet)
└── (source code directories)
```

## Key Integration Points

1. **Specification Storage**: Colocated with plans in `docs/plans/<ordinal>-<slug>/`
2. **Doctrine Files**: Referenced by multiple commands
   - Constitution: `docs/rules/constitution.md`
   - Rules: `docs/rules-idioms-architecture/rules.md`
   - Idioms: `docs/rules-idioms-architecture/idioms.md`
   - Architecture: `docs/rules-idioms-architecture/architecture.md`
3. **Testing Strategy**: Determined in plan-2, drives plan-3 generation, impacts all task design
4. **Documentation Strategy**: Determined in plan-2, drives phase generation in plan-3
5. **Parallel Subagents**: Used in plan-0, plan-3, plan-5, plan-5a, plan-6a, plan-7 for efficiency
6. **FlowSpace Provenance Graph**: Footnotes [^N] link tasks → files → functions, bidirectional navigation

## Critical Findings System

- Discovered during plan-3 research (4 parallel subagents)
- Minimum 15-20 findings after deduplication, ordered by impact
- Code examples showing wrong/right patterns
- Referenced in phase tasks when applicable
- Helps task design and validation strategy

## Testing Strategy Impacts

**Full TDD Approach**:
- Test tasks precede implementation tasks in every phase
- Comprehensive test coverage before code

**TAD (Test-Assisted Development)**:
- Scratch test exploration in tests/scratch/
- RUN commands with RED→GREEN cycles (evidence required)
- Test promotion with Test Doc blocks (5 required fields: Why, Contract, Usage Notes, Quality Contribution, Worked Example)
- Promotion heuristic: Critical path, Opaque behavior, Regression-prone, Edge case
- 90-95% deletion rate expected for scratch tests

**Lightweight**:
- Core functionality validation only
- Skip unit tests for simple operations
- Focus on integration/smoke tests

**Manual Only**:
- Replace test tasks with manual verification checklists
- Document steps, execute validation

**Hybrid**:
- Mark each phase with its approach (TDD/TAD/Lightweight)

## NOT YET INTEGRATED

1. **ADR Workflow**: Template exists but no /plan-ADR command or integration point
2. **Specification Storage**: docs/specs/ directory exists but unused
3. **Rules/Idioms/Architecture Files**: Referenced but not shown to exist in current state
4. **Project Constitution**: Referenced frequently but not shown to exist

## Integration Opportunities for ADR Flow

1. **Post-Planning ADR Step**: After plan-3 architecture, before plan-4 validation
   - Capture major decisions made during planning
   - Generate /plan-3-adr or standalone ADR creation command
   
2. **Critical Findings as Decisions**: Map discoveries to ADRs
   - ADR per critical finding (or group related findings)
   - Link ADRs in plan's Critical Research Findings section

3. **Decision Registry**: Create docs/adr/ with index
   - Link from constitution, rules, architecture docs
   - Status tracking (Proposed → Accepted → Implemented)

4. **Subtask Decision Tracking**: /plan-5a could flag decisions
   - Subtasks may require architectural decisions
   - Can spawn ADR creation flow

5. **Code Review Integration**: /plan-7 validates decisions
   - Check that implemented code follows ADR decisions
   - Flag deviations from accepted ADRs
