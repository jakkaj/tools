---
description: Perform planning and architecture, generating a phase-based plan with success criteria while enforcing clarification and constitution gates before implementation.
---

Please deep think / ultrathink as this is a complex task.

# plan-3-architect

Generate a **comprehensive, phase-based implementation plan** with detailed tasks, TDD structure, and acceptance criteria. This command produces the master plan document that will guide all subsequent implementation phases.

```md
Inputs:
  FEATURE_SPEC = `docs/plans/<ordinal>-<slug>/<slug>-spec.md` (co-located with plan),
  PLAN_PATH (absolute; MUST match `docs/plans/<ordinal>-<slug>/<slug>-plan.md`),
  rules at `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}`,
  constitution at `/memory/constitution.md` (if present),
  today {{TODAY}}.

## PHASE 1: Initial Gates & Validation

### GATE - Clarify
- If critical ambiguities remain in SPEC (marked with [NEEDS CLARIFICATION]), instruct running /plan-2-clarify first
- Verify `## Testing Strategy` section exists in spec with defined approach
- User can explicitly override with --skip-clarify flag

### GATE - Constitution
- Validate plan against /memory/constitution.md if present
- Document any necessary deviations in deviation ledger:

| Principle Violated | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|-------------------|------------|------------------------------|-----------------|

### GATE - Architecture
- Validate against `docs/rules-idioms-architecture/architecture.md`
- Check for layer-boundary violations (LFL/LSL/Graph/etc.)
- Verify language-agnostic GraphBuilder compliance
- Document any architectural exceptions with justification

## PHASE 2: Research & Technical Discovery

### Required Research Activities
1. **Codebase Analysis**
   - Search for existing patterns and conventions
   - Identify integration points and dependencies
   - Document current implementation approaches

2. **Technical Investigation**
   - Identify critical technical challenges
   - Research API limitations and gotchas
   - Document framework-specific requirements

3. **Discovery Documentation**
   Format discoveries as numbered entries (01, 02, 03...) for easy reference:
   ```
   ### 🚨 Critical Discovery 01: [Title]
   **Problem**: [What doesn't work as expected]
   **Root Cause**: [Why it happens]
   **Solution**: [How to work around it]
   **Example**:
   ```[language]
   // ❌ WRONG - [Why this fails]
   [bad code example]

   // ✅ CORRECT - [Why this works]
   [good code example]
   ```
   ```

   Number discoveries sequentially (01, 02, 03...) to enable precise references in phase tasks (e.g., "per Critical Discovery 02").

### Research Output Requirements
- Document at least 3-5 critical findings that affect implementation
- Number each discovery sequentially for traceability
- Include code examples for each finding
- Specify impact on architecture/design decisions

## PHASE 3: Project Structure & Setup

### Project Type Selection
- Determine project type: (single | web | mobile | library | cli | service)
- Generate **actual** directory tree showing all relevant paths
- Use absolute repo-root paths throughout the plan

### Directory Structure Template
```
/path/to/repo/
├── src/
│   ├── [component directories]
│   └── [feature modules]
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── docs/
│   └── plans/
│       └── <ordinal>-<slug>/
│           ├── <slug>-plan.md (this file)
│           └── tasks/
│               └── [phase directories will be created by plan-5]
└── [configuration files]
```

## PHASE 4: Plan Document Generation

### Testing Strategy Adaptation
Read the `## Testing Strategy` section from the spec and adapt plan generation accordingly. Capture both the testing approach and the mock usage preference; reflect both throughout the plan.

**Approach-Specific Guidance:**
- **Full TDD**: Generate comprehensive test-first tasks for all phases (current template)
- **TAD (Test-Assisted Development)**: Generate tasks with Scratch→Promote workflow:
  * Create scratch test exploration tasks (tests/scratch/ directory)
  * Implementation tasks interleaved with test refinement
  * Test promotion tasks with Test Doc comment block requirements
  * Every promoted test must include Test Doc block (Why/Contract/Usage Notes/Quality Contribution/Worked Example)
  * Focus on tests that "pay rent" via comprehension value
  * Name tests "Given...When...Then..." format
  * Keep tests/scratch/ out of CI; promoted tests should be reasonably fast and reliable
- **Lightweight**: Reduce test tasks to core validation only
- **Manual Only**: Replace test tasks with manual verification checklists
- **Hybrid**: Mark phases with approach annotations (TDD/TAD/Lightweight per phase)

### Documentation Strategy Adaptation
Read the `## Documentation Strategy` section from the spec and generate appropriate documentation phases based on the location choice:

- **README.md only**: Create single documentation phase updating root README.md with quick-start content
- **docs/how/ only**: Create documentation phase(s) for detailed guides under docs/how/
  - Structure: `docs/how/<feature-name>/N-topic.md` (numbered files within feature directory)
  - **Intelligent file placement**:
    1. Survey existing `docs/how/` directories to identify relevant feature areas
    2. Decide: create new `docs/how/<new-feature>/` OR use existing `docs/how/<existing-feature>/`
    3. Determine file strategy: create new numbered file OR append to existing file if content is small/related
    4. Use sequential numbering (1-overview.md, 2-usage.md, 3-api.md, etc.)
- **Hybrid**: Create multiple documentation phases:
  - Phase for README.md updates (quick-start, overview, essential commands)
  - Phase for docs/how/ content following structure above
  - Ensure content split matches spec guidance
- **None**: Skip documentation phases (note in plan why docs are not needed)

Documentation phases should include:
- **Discovery step**: List existing docs/how/ feature directories and their content
- **Placement decision**: Document whether creating new feature dir or using existing, with rationale
- **File strategy**: Specify whether creating new files or updating existing ones
- Clear file paths (absolute: /path/to/repo/README.md or /path/to/repo/docs/how/<feature>/N-topic.md)
- Content outlines (what sections/topics to cover)
- Target audience considerations
- Maintenance/update expectations

- **Full TDD**: Generate comprehensive test-first tasks for all phases (current template)
- **Lightweight**:
  - Reduce test tasks to core validation only
  - Skip unit test tasks for simple operations
  - Focus on integration/smoke tests
- **Manual Only**:
  - Replace test tasks with "Document manual validation steps"
  - Include manual test checklist in acceptance criteria
- **Hybrid**:
  - Mark complex phases for full TDD
  - Mark simple phases for lightweight testing
  - Clearly indicate testing approach per phase

### Required Sections (in order)

#### 1. Title Block & Metadata
```markdown
# [Feature Name] Implementation Plan

**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link to ./<slug>-spec.md]
**Status**: DRAFT | READY | IN_PROGRESS | COMPLETE
```

#### 2. Table of Contents (MANDATORY)
- Must include all major sections
- Link to each phase
- Include appendices

#### 3. Executive Summary
- Problem statement (2-3 sentences)
- Solution approach (bullet points)
- Expected outcomes
- Success metrics

#### 4. Technical Context
- Current system state
- Integration requirements
- Constraints and limitations
- Assumptions

#### 5. Critical Research Findings
- Include all discoveries from Phase 2
- Order by impact (highest first)
- Cross-reference to affected phases

#### 6. Testing Philosophy
```markdown
### Testing Approach
[Reference the Testing Strategy from spec]
- **Selected Approach**: [Full TDD | TAD | Lightweight | Manual | Hybrid]
- **Rationale**: [From spec]
- **Focus Areas**: [From spec]

### Test-Driven Development (if applicable)
[Include if Full TDD or Hybrid selected]
- Write tests FIRST (RED)
- Implement minimal code (GREEN)
- Refactor for quality (REFACTOR)

### Test-Assisted Development (TAD) (if applicable)
[Include if TAD selected]
- Tests are executable documentation optimized for developer comprehension
- **Scratch → Promote workflow**:
  1. Write probe tests in tests/scratch/ to explore/iterate (fast, excluded from CI)
  2. Implement code iteratively, refining behavior with scratch probes
  3. When behavior stabilizes, promote valuable tests to tests/unit/ or tests/integration/
  4. Add Test Doc comment contract to each promoted test (required fields below)
  5. Delete scratch probes that don't add durable value; keep learning notes in PR
- **Promotion heuristic**: Keep if Critical path, Opaque behavior, Regression-prone, or Edge case
- **Test naming format**: "Given...When...Then..." (e.g., `test_given_iso_date_when_parsing_then_returns_normalized_cents`)
- **Test Doc comment block** (required for every promoted test):
  ```
  /*
  Test Doc:
  - Why: <business/bug/regression reason in 1–2 lines>
  - Contract: <plain-English invariant(s) this test asserts>
  - Usage Notes: <how a developer should call/configure the API; gotchas>
  - Quality Contribution: <what failure this will catch; link to issue/PR/spec>
  - Worked Example: <inputs/outputs summarized for scanning>
  */
  ```
- **Quality principles**: Tests must explain why they exist, what contract they lock in, and how to use the code
- **CI requirements**: Exclude tests/scratch/ from CI; promoted tests must be deterministic without network/sleep/flakes (performance requirements specified in spec when needed)

### Lightweight Testing (if applicable)
[Include if Lightweight or Hybrid selected]
- Focus on core functionality validation
- Skip extensive unit testing for simple operations
- Prioritize integration and smoke tests

### Test Documentation (when tests are written)
Every test must include:
"""
Purpose: [what truth this test proves]
Quality Contribution: [how this prevents bugs]
Acceptance Criteria: [measurable assertions]
"""

### Mock Usage (align with spec)
- If spec says "Avoid mocks": use real data/fixtures; only stub truly external calls (network/SaaS)
- If spec says "Targeted mocks": permit mocks for explicitly slow/external dependencies; document rationale per phase
- If spec says "Liberal mocks": allow mocks/stubs wherever they improve clarity or speed; ensure acceptance criteria still cover end-to-end behavior
```

#### 7. Implementation Phases

For EACH phase, generate:

### Phase N: [Descriptive Title]

**Objective**: [Single sentence goal]

**Deliverables**:
- [Concrete deliverable 1]
- [Concrete deliverable 2]

**Dependencies**:
- Phase X must be complete (if applicable)
- External systems available
- Test data prepared

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk description] | Low/Med/High | Low/Med/High | [Mitigation strategy] |

### Tasks (Adapt based on Testing Strategy)

For **Full TDD** approach:
| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| N.1 | [ ] | Write comprehensive tests for [component] | Tests cover: [scenarios], all fail initially | - | |
| N.2 | [ ] | Implement [component] to pass tests | All tests from N.1 pass | - | |
| N.3 | [ ] | Write integration tests for [feature] | Tests document expected behavior | - | |
| N.4 | [ ] | Integrate [component] with [system] | Integration tests pass | - | |
| N.5 | [ ] | Refactor for [quality aspect] | Code meets idioms, tests still pass | - | |

For **TAD (Test-Assisted Development)** approach:
| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| N.1 | [ ] | Create tests/scratch/ directory | Directory exists, excluded from CI config | - | Ensure .gitignore or CI config excludes tests/scratch/ |
| N.2 | [ ] | Write scratch probes for [component] | 3-5 probe tests exploring behavior | - | Fast iteration, no Test Doc blocks needed |
| N.3 | [ ] | Implement [component] iteratively | Core functionality works, refined with probes | - | Interleave code and scratch test updates |
| N.4 | [ ] | Promote valuable tests to tests/unit/ | 2-3 tests moved with Test Doc blocks added | - | Apply heuristic: Critical path, Opaque behavior, Regression-prone, Edge case |
| N.5 | [ ] | Add Test Doc comment blocks | All promoted tests have Why/Contract/Usage/Quality/Example | - | Required 5 fields per promoted test |
| N.6 | [ ] | Delete non-valuable scratch tests | Only promoted tests remain in main suite | - | Keep learning notes in execution log/PR |
| N.7 | [ ] | Verify CI exclusion of scratch/ | CI config explicitly excludes tests/scratch/ | - | |

For **Lightweight** approach:
| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| N.1 | [ ] | Implement [component] | Basic functionality works | - | |
| N.2 | [ ] | Write validation test | Core behavior verified | - | |
| N.3 | [ ] | Run smoke test | End-to-end flow works | - | |

For **Manual Only** approach:
| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| N.1 | [ ] | Implement [component] | Functionality complete | - | |
| N.2 | [ ] | Document manual test steps | Clear verification process | - | |
| N.3 | [ ] | Execute manual validation | All checks pass | - | |

For **Hybrid** approach:
[Mark each phase as Full TDD, TAD, or Lightweight based on complexity and documentation needs]

### Test Examples (Write First!)

```[language]
describe('[Component]', () => {
    test('should [specific behavior]', () => {
        """
        Purpose: Proves [component] correctly handles [scenario]
        Quality Contribution: Prevents [type of bug]
        Acceptance Criteria:
        - [Assertion 1]
        - [Assertion 2]
        """

        // Arrange
        const input = [test data];

        // Act
        const result = component.method(input);

        // Assert
        expect(result.property).toBe(expectedValue);
        expect(result.state).toMatch(pattern);
    });

    test('should handle [edge case]', () => {
        """
        Purpose: Ensures system remains stable when [condition]
        Quality Contribution: Prevents crashes in production
        Acceptance Criteria: Graceful error handling
        """

        // Test implementation
    });
});
```

### Non-Happy-Path Coverage
- [ ] Null/undefined inputs handled
- [ ] Concurrent access scenarios tested
- [ ] Error propagation verified
- [ ] Resource cleanup confirmed

### Acceptance Criteria
- [ ] All tests passing (100% of phase tests)
- [ ] Test coverage > 80% for new code
- [ ] Mock usage conforms to spec preference (document deviations)
- [ ] Documentation updated

#### 8. Cross-Cutting Concerns

### Security Considerations
- Input validation strategy
- Authentication/authorization requirements
- Sensitive data handling

### Observability
- Logging strategy
- Metrics to capture
- Error tracking approach

### Documentation
- Documentation location (per Documentation Strategy from spec)
- Content structure and organization
- Update/maintenance schedule
- Target audience and accessibility

#### 9. Complexity Tracking

If Constitution/Architecture deviations exist:

| Component | Complexity | Justification | Simplification Plan |
|-----------|------------|---------------|-------------------|
| [Component] | High | [Why needed] | [Future refactor approach] |

#### 10. Progress Tracking

### Phase Completion Checklist
- [ ] Phase 1: [Title] - [Status]
- [ ] Phase 2: [Title] - [Status]
- [ ] Phase 3: [Title] - [Status]
- [ ] Phase 4: [Title] - [Status]
- [ ] Phase 5: [Title] - [Status]

### STOP Rule
**IMPORTANT**: This plan must be complete before creating tasks. After writing this plan:
1. Run `/plan-4-complete-the-plan` to validate readiness
2. Only proceed to `/plan-5-phase-tasks-and-brief` after validation passes

#### 11. Change Footnotes Ledger

**NOTE**: This section will be populated during implementation by plan-6.

```markdown
## Change Footnotes Ledger

During implementation, footnote tags from task Notes will be added here with details per AGENTS.md:

[^1]: [To be added during implementation]
[^2]: [To be added during implementation]
...
```

## PHASE 5: Validation & Output

### Pre-Write Validation Checklist
- [ ] TOC includes all sections
- [ ] All phases have numbered tasks
- [ ] Each task has clear success criteria
- [ ] Test examples provided for each phase
- [ ] TDD approach evident (tests before implementation)
- [ ] Mock usage policy mirrors spec
- [ ] Absolute paths used throughout
- [ ] Dependencies clearly stated
- [ ] Risks identified with mitigations
- [ ] Acceptance criteria measurable
- [ ] Cross-cutting concerns addressed
- [ ] Constitution/Architecture gates passed

### Output Requirements
1. Create parent directory if needed: `docs/plans/<ordinal>-<slug>/`
2. Write plan to: `docs/plans/<ordinal>-<slug>/<slug>-plan.md`
3. Ensure plan is self-contained (no assumed context)
4. Include all code examples inline
5. Use mermaid diagrams where helpful

### Success Message Template
```
✅ Plan created successfully:
- Location: [absolute path to plan]
- Phases: [count]
- Total tasks: [count]
- Next step: Run /plan-4-complete-the-plan to validate
```

## Example Phase (For Reference)

Note: This example shows Full TDD approach. Adapt based on Testing Strategy from spec.

### Phase 1: Core BridgeContext Infrastructure

**Objective**: Create the foundational BridgeContext interface and basic service structure using TDD.

**Deliverables**:
- BridgeContext interface with VS Code API wrappers
- Factory pattern implementation
- Logger service using OutputChannel
- Comprehensive test coverage

**Dependencies**: None (foundational phase)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| VS Code API changes | Low | High | Pin VS Code engine version |
| Test isolation issues | Medium | Medium | Use test fixtures |

### Tasks (TDD Approach)

| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| 1.1 | [ ] | Write comprehensive tests for BridgeContext | Tests cover: version check, getWorkspace, getConfiguration, error cases | - | Create BridgeContext.test.ts |
| 1.2 | [ ] | Write tests for BridgeContext factory | Tests cover: singleton behavior, lifecycle, context injection | - | Create factory.test.ts |
| 1.3 | [ ] | Create BridgeContext TypeScript interface | Interface compiles, exports properly | - | Define in types.ts |
| 1.4 | [ ] | Implement BridgeContext to pass tests | All tests from 1.1 pass | - | Thin wrappers around VS Code APIs |
| 1.5 | [ ] | Implement factory to pass tests | All tests from 1.2 pass | - | Singleton pattern |
| 1.6 | [ ] | Write tests for logger service | Tests cover: log levels, output channel, formatting | - | Integrate with BridgeContext.test.ts |
| 1.7 | [ ] | Implement logger service | Logger uses OutputChannel, all tests pass | - | Use VS Code OutputChannel API |
| 1.8 | [ ] | Create index exports and validate | Can import from 'core/bridge-context' | - | Clean module exports |

### Test Examples (Write First!)

```typescript
import * as assert from 'assert';
import * as vscode from 'vscode';
import { BridgeContext } from '../../../extension/src/core/bridge-context';

suite('BridgeContext using VS Code APIs', () => {
    let context: BridgeContext;

    setup(async () => {
        """
        Purpose: Ensure clean test state for each test
        Quality Contribution: Prevents test interdependencies
        Acceptance Criteria: Fresh context for each test
        """
        const ext = vscode.extensions.getExtension('your.extension.id')!;
        await ext.activate();
        context = new BridgeContext(ext.exports.getContext());
    });

    test('should return current version', () => {
        """
        Purpose: Proves version property is accessible and correct
        Quality Contribution: Enables version-specific behavior
        Acceptance Criteria:
        - Returns string version
        - Matches package.json version
        - Property is readonly
        """

        assert.strictEqual(typeof context.version, 'string');
        assert.strictEqual(context.version, '1.0.0');
        assert.throws(() => {
            (context as any).version = '2.0.0';
        });
    });

    test('should handle missing workspace gracefully', () => {
        """
        Purpose: Ensures stability when no workspace is open
        Quality Contribution: Prevents crashes in extension activation
        Acceptance Criteria: Returns undefined, no exceptions
        """

        const workspace = context.getWorkspace();
        if (!vscode.workspace.workspaceFolders) {
            assert.strictEqual(workspace, undefined);
        }
    });
});
```

### Non-Happy-Path Coverage
- [ ] Null context handling
- [ ] Disposed extension context
- [ ] Missing VS Code APIs (older versions)
- [ ] Concurrent initialization attempts

### Acceptance Criteria
- [ ] All tests passing (18 tests)
- [ ] No mocks used (real VS Code APIs)
- [ ] Test coverage > 90%
- [ ] Clean module exports
- [ ] TypeScript strict mode passes

## Example Documentation Phase (For Reference)

Note: This example shows a Hybrid documentation approach (README + docs/how/). Adapt based on Documentation Strategy from spec.

### Phase N: Documentation

**Objective**: Document the BridgeContext feature for users and maintainers following hybrid approach (essentials in README, details in docs/how/bridge-context/).

**Deliverables**:
- Updated README.md with quick-start guide
- Detailed guides in docs/how/bridge-context/ (numbered structure)

**Dependencies**: All implementation phases complete, tests passing

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Documentation drift | Medium | Medium | Include doc updates in phase acceptance criteria |
| Unclear examples | Low | Medium | Use real code snippets from implementation |

### Discovery & Placement Decision

**Existing docs/how/ structure**:
```
docs/how/
├── testing/
│   ├── 1-overview.md
│   └── 2-tdd-workflow.md
└── architecture/
    └── 1-overview.md
```

**Decision**: Create new `docs/how/bridge-context/` directory (no existing relevant feature area)

**File strategy**: Create new numbered files (1-overview.md, 2-usage.md, 3-api.md)

### Tasks (Lightweight Approach for Documentation)

| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| N.1 | [ ] | Survey existing docs/how/ directories | Documented existing structure, identified no conflicts | - | Discovery step |
| N.2 | [ ] | Update README.md with BridgeContext quick-start | Installation, basic usage, link to docs/how/bridge-context/ | - | /path/to/repo/README.md |
| N.3 | [ ] | Create docs/how/bridge-context/1-overview.md | Introduction, motivation, architecture diagram complete | - | /path/to/repo/docs/how/bridge-context/1-overview.md |
| N.4 | [ ] | Create docs/how/bridge-context/2-usage.md | Step-by-step usage guide with code examples | - | /path/to/repo/docs/how/bridge-context/2-usage.md |
| N.5 | [ ] | Create docs/how/bridge-context/3-api.md | All public APIs documented with examples | - | /path/to/repo/docs/how/bridge-context/3-api.md |
| N.6 | [ ] | Review documentation for clarity and completeness | Peer review passed, no broken links | - | All docs reviewed |

### Content Outlines

**README.md section** (Hybrid: quick-start only):
- What is BridgeContext (1-2 sentences)
- Installation/setup (quick steps)
- Basic usage example (minimal code snippet)
- Link to detailed docs: `docs/how/bridge-context/`

**docs/how/bridge-context/1-overview.md**:
- Introduction and motivation
- Architecture diagram
- Key concepts
- When to use BridgeContext

**docs/how/bridge-context/2-usage.md**:
- Installation and configuration
- Common use cases with examples
- Code snippets (tested)
- Troubleshooting section

**docs/how/bridge-context/3-api.md**:
- API reference for all public interfaces
- Parameter descriptions and types
- Return types
- Code examples for each method

### Acceptance Criteria
- [ ] README.md updated with quick-start section
- [ ] All docs/how/bridge-context/ files created and complete
- [ ] Code examples tested and working
- [ ] No broken links (internal or external)
- [ ] Peer review completed
- [ ] Target audience can follow guides successfully
- [ ] Numbered file structure follows convention

## Style & Formatting Rules

- Use Markdown headings hierarchically (# > ## > ### > ####)
- Keep one blank line between sections
- Wrap lines at ~100 chars for readability
- Use tables for structured data
- Include language hints in code blocks
- Number all phases and tasks consistently
- Use checkboxes for status tracking
- Provide absolute paths (no relative paths)
```

Next step (when happy): Run **/plan-4-complete-the-plan** to validate readiness.
