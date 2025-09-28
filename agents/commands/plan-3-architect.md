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
   Format discoveries as:
   ```
   ### 🚨 Critical Discovery: [Title]
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

### Research Output Requirements
- Document at least 3-5 critical findings that affect implementation
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
Read the `## Testing Strategy` section from the spec and adapt plan generation accordingly:

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
- **Selected Approach**: [Full TDD | Lightweight | Manual | Hybrid]
- **Rationale**: [From spec]
- **Focus Areas**: [From spec]

### Test-Driven Development (if applicable)
[Include if Full TDD or Hybrid selected]
- Write tests FIRST (RED)
- Implement minimal code (GREEN)
- Refactor for quality (REFACTOR)

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

### No Mocks Policy (when applicable)
- Use real data and fixtures
- Use test databases/repos
- Only stub external network calls
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
| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| N.1 | [ ] | Write comprehensive tests for [component] | Tests cover: [scenarios], all fail initially | |
| N.2 | [ ] | Implement [component] to pass tests | All tests from N.1 pass | |
| N.3 | [ ] | Write integration tests for [feature] | Tests document expected behavior | |
| N.4 | [ ] | Integrate [component] with [system] | Integration tests pass | |
| N.5 | [ ] | Refactor for [quality aspect] | Code meets idioms, tests still pass | |

For **Lightweight** approach:
| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| N.1 | [ ] | Implement [component] | Basic functionality works | |
| N.2 | [ ] | Write validation test | Core behavior verified | |
| N.3 | [ ] | Run smoke test | End-to-end flow works | |

For **Manual Only** approach:
| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| N.1 | [ ] | Implement [component] | Functionality complete | |
| N.2 | [ ] | Document manual test steps | Clear verification process | |
| N.3 | [ ] | Execute manual validation | All checks pass | |

For **Hybrid** approach:
[Mark each phase as Full TDD or Lightweight based on complexity]

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
- [ ] No mocks used (only real data/fixtures)
- [ ] Performance benchmarks met
- [ ] Documentation updated

#### 8. Cross-Cutting Concerns

### Performance Requirements
- Response time: < Xms
- Memory usage: < XMB
- Concurrent users: X

### Security Considerations
- Input validation strategy
- Authentication/authorization requirements
- Sensitive data handling

### Observability
- Logging strategy
- Metrics to capture
- Error tracking approach

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
- [ ] No mocks policy stated
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

| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| 1.1 | [ ] | Write comprehensive tests for BridgeContext | Tests cover: version check, getWorkspace, getConfiguration, error cases | Create BridgeContext.test.ts |
| 1.2 | [ ] | Write tests for BridgeContext factory | Tests cover: singleton behavior, lifecycle, context injection | Create factory.test.ts |
| 1.3 | [ ] | Create BridgeContext TypeScript interface | Interface compiles, exports properly | Define in types.ts |
| 1.4 | [ ] | Implement BridgeContext to pass tests | All tests from 1.1 pass | Thin wrappers around VS Code APIs |
| 1.5 | [ ] | Implement factory to pass tests | All tests from 1.2 pass | Singleton pattern |
| 1.6 | [ ] | Write tests for logger service | Tests cover: log levels, output channel, formatting | Integrate with BridgeContext.test.ts |
| 1.7 | [ ] | Implement logger service | Logger uses OutputChannel, all tests pass | Use VS Code OutputChannel API |
| 1.8 | [ ] | Create index exports and validate | Can import from 'core/bridge-context' | Clean module exports |

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