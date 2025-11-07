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
  constitution at `docs/rules/constitution.md` (if present),
  today {{TODAY}}.

## PHASE 1: Initial Gates & Validation

### GATE - Clarify
- If critical ambiguities remain in SPEC (marked with [NEEDS CLARIFICATION]), instruct running /plan-2-clarify first
- Verify `## Testing Strategy` section exists in spec with defined approach
- User can explicitly override with --skip-clarify flag

### GATE - Constitution
- Validate plan against docs/rules/constitution.md if present
- Document any necessary deviations in deviation ledger:

| Principle Violated | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|-------------------|------------|------------------------------|-----------------|

### GATE - Architecture
- Validate against `docs/rules-idioms-architecture/architecture.md`
- Check for layer-boundary violations (LFL/LSL/Graph/etc.)
- Verify language-agnostic GraphBuilder compliance
- Document any architectural exceptions with justification

### GATE - ADR (Optional)
- Scan `docs/adr/` for ADRs that reference this feature (match by slug/title or spec path)
- Build an ADR Ledger table:

| ADR | Status | Affects Phases | Notes |
|-----|--------|----------------|-------|

- If existing ADRs found, populate table with each ADR's ID (NNNN), status, affected phases, and key constraints
- If a critical design choice is being made in this plan and no ADR exists, recommend running `/plan-3a-adr` before finalizing
- Note: This gate is non-blocking; plan can proceed with or without ADRs

## PHASE 2: Research & Technical Discovery

**IMPORTANT**: Use **parallel research subagents** for comprehensive and efficient discovery.

**Strategy**: Launch 4 specialized research subagents (single message with 4 Task tool calls) to maximize discovery breadth and depth. Each subagent focuses on a specific domain, then results are synthesized into numbered discoveries.

### Parallel Research Architecture

**Subagent 1: Codebase Pattern Analyst**
"Discover existing patterns, conventions, and integration points.

**Research Areas**:
- Existing similar features/components and their implementation patterns
- Naming conventions (file naming, class naming, function naming)
- Directory structures and organization
- Design patterns in use (factory, singleton, observer, etc.)
- Integration points where new feature connects to existing systems
- Code conventions (error handling, logging, testing styles)

**Output**: 5-8 discoveries numbered S1-01 through S1-08 covering patterns, integration points, and conventions.

**Format per discovery**:
```markdown
### Discovery S1-01: [Title]
**Category**: Pattern | Integration | Convention
**Impact**: Critical | High | Medium | Low
**What**: [Concise description]
**Why It Matters**: [How this affects implementation]
**Example**:
​```[language]
// ❌ WRONG - [Why this violates pattern]
[counter-example]

// ✅ CORRECT - [Why this follows pattern]
[good example from codebase]
​```
**Action Required**: [What implementation must do]
```
"

**Subagent 2: Technical Investigator**
"Identify technical constraints, API limitations, and framework-specific gotchas.

**Research Areas**:
- API limitations (rate limits, quotas, restrictions, version compatibility)
- Framework gotchas (known bugs, common mistakes, performance bottlenecks)
- Technical constraints (memory/CPU limits, query limits, file system limitations)
- Security requirements (input validation, sanitization, CORS, CSP)

**Output**: 5-8 discoveries numbered S2-01 through S2-08 covering API limits, framework gotchas, and constraints.

**Format per discovery**:
```markdown
### Discovery S2-01: [Title]
**Category**: API Limit | Framework Gotcha | Constraint
**Impact**: Critical | High | Medium | Low
**Problem**: [What doesn't work as expected or limitation exists]
**Root Cause**: [Why this limitation exists]
**Solution**: [How to work around it]
**Example**:
​```[language]
// ❌ WRONG - [Why this fails due to limitation]
[bad code example]

// ✅ CORRECT - [Why this works around limitation]
[good code example]
​```
**References**: [Links to docs, GitHub issues, Stack Overflow]
```
"

**Subagent 3: Discovery Documenter**
"Analyze spec for ambiguities, implications, and edge cases.

**Research Areas**:
- Spec ambiguities (unclear or underspecified requirements)
- Implementation implications (performance, data migration, backward compatibility, security)
- Edge cases and error scenarios (empty/null input, concurrent access, network failures)

**Output**: 5-8 discoveries numbered S3-01 through S3-08 covering ambiguities, implications, and edge cases.

**Format per discovery**:
```markdown
### Discovery S3-01: [Title]
**Category**: Ambiguity | Implication | Edge Case
**Impact**: Critical | High | Medium | Low
**Spec Reference**: [Quote relevant spec section]
**Issue**: [What is unclear, implication, or edge case]
**Design Decision Required**: [What choice must be made]
**Recommendation**: [Suggested approach with rationale]
**Example**: [Scenario with code showing safe/unsafe approaches]
```
"

**Subagent 4: Dependency Mapper**
"Map module dependencies, architectural boundaries, and cross-cutting concerns.

**Research Areas**:
- Module dependencies (what feature depends on, what depends on it)
- Architectural boundaries (layers, domains, cross-boundary communication)
- Cross-cutting concerns (logging, error handling, auth, caching, metrics, config)

**Output**: 5-8 discoveries numbered S4-01 through S4-08 covering dependencies, boundaries, and cross-cutting concerns.

**Format per discovery**:
```markdown
### Discovery S4-01: [Title]
**Category**: Dependency | Boundary | Cross-Cutting Concern
**Impact**: Critical | High | Medium | Low
**What**: [Describe dependency/boundary/concern]
**Architectural Context**: [How this fits into system architecture]
**Design Constraint**: [What this means for implementation]
**Example**:
​```[language]
// ❌ VIOLATES BOUNDARY - [Why this breaks architectural rules]
[bad code example]

// ✅ RESPECTS BOUNDARY - [Why this follows architectural rules]
[good code example]
​```
**Reference**: [Link to architecture.md, constitution.md, dependency docs]
```
"

**Wait for All Researchers**: Block until all 4 subagents complete.

### Synthesis Phase

After all 4 subagents complete:
1. **Collect All Discoveries**: Gather S1-01 through S4-08 (approximately 24-32 discoveries)
2. **Deduplicate**: Merge overlapping findings (note sources: S1-03 + S2-05)
3. **Renumber Sequentially**: Assign final discovery numbers 01, 02, 03, ..., NN
   - Order by impact: Critical first, then High, then Medium, then Low
   - Within each tier, order by implementation phase relevance
4. **Format Final Discoveries**:

```markdown
### 🚨 Critical Discovery 01: [Title]
**Impact**: Critical
**Sources**: [S1-03, S2-05] (pattern analyst + technical investigator)
**Problem**: [What doesn't work as expected]
**Root Cause**: [Why this happens]
**Solution**: [How to work around it or design for it]
**Example**:
​```[language]
// ❌ WRONG - [Why this fails]
[bad code example]

// ✅ CORRECT - [Why this works]
[good code example]
​```
**Action Required**: [What implementation must do]
**Affects Phases**: [List phase numbers, e.g., Phase 3, Phase 5]
```

### Research Output Requirements
- Minimum 15-20 final discoveries (after deduplication)
- At least 3-5 Critical discoveries
- At least 5-8 High impact discoveries
- All discoveries include code examples
- All discoveries specify affected phases
- Deduplication log showing which subagent findings were merged
- Each final discovery references source subagent discoveries (e.g., "Sources: [S1-03, S4-02]")
- If spec ambiguity discovered, note whether /plan-2-clarify should be re-run

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
- **ADR references**: Link relevant ADR(s) in the plan's References & per-phase Acceptance Criteria if they constrain the work

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

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#### ⚠️ TEST EXECUTION REQUIREMENT (MANDATORY FOR TAD)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**TAD is not possible without executing tests repeatedly.**

Implementers MUST:
- **RUN** scratch tests after writing them (RED phase)
- **RUN** tests after each code change (GREEN phase)
- **RUN** tests after refactoring (verification)
- Provide test execution output as evidence
- Demonstrate 10-20+ RED→GREEN cycles per feature

```bash
# Example Python test execution
pytest tests/scratch/test_feature.py -v --tb=short

# Example TypeScript test execution
npm test tests/scratch/test-feature.test.ts
```

**Success criteria must include**: "Test runner output shows X RED→GREEN cycles"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Tests are executable documentation optimized for developer comprehension
- **Scratch → RUN → Promote workflow**:
  1. Write probe tests in tests/scratch/ to explore/iterate (fast, excluded from CI)
  2. **🔴🟢 RUN scratch tests repeatedly** in tight feedback loop (RED→GREEN cycle):
     * Write scratch test for small isolated behavior
     * **RUN test** (expect failure - RED) ← **EXECUTE WITH TEST RUNNER**
     * Write minimal code to pass test
     * **RUN test again** (expect success - GREEN) ← **EXECUTE WITH TEST RUNNER**
     * Refactor if needed, **re-run test**
     * REPEAT for next behavior
     * This high-fidelity loop validates isolated code WITHOUT running entire project
  3. Implement code iteratively, refining behavior after each test run
  4. When behavior stabilizes, promote valuable tests (typically 1-2 per feature, ~5-10% promotion rate) to tests/unit/ or tests/integration/
  5. Add Test Doc comment contract to each promoted test (required fields below)
  6. Delete scratch probes that don't add durable value (expect to delete 90-95%); keep learning notes in PR
- **Promotion heuristic (apply ruthlessly)**: Keep if Critical path, Opaque behavior, Regression-prone, or Edge case
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
| N.2 | [ ] | Write scratch probes for [component] | 10-15 probe tests exploring behavior | - | Fast iteration, no Test Doc blocks needed |
| N.3 | [ ] | **RUN-Implement-Fix loop** for [component] | **Test runner output shows 10-20 RED→GREEN cycles** | - | **MUST EXECUTE**: pytest/npm test commands run repeatedly, paste output as evidence |
| N.4 | [ ] | Complete implementation | Core functionality works, all scratch tests pass | - | Code refined through iterative testing |
| N.5 | [ ] | Promote valuable tests to tests/unit/ | 1-2 tests moved (~5-10% of scratch tests) with Test Doc blocks added | - | Apply heuristic ruthlessly: Critical path, Opaque behavior, Regression-prone, Edge case |
| N.6 | [ ] | Add Test Doc comment blocks | All promoted tests have Why/Contract/Usage/Quality/Example | - | Required 5 fields per promoted test |
| N.7 | [ ] | Delete non-valuable scratch tests | 90-95% of scratch tests deleted, only promoted tests remain in main suite | - | Keep learning notes in execution log/PR |
| N.8 | [ ] | Verify CI exclusion of scratch/ | CI config explicitly excludes tests/scratch/ | - | |

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
- [ ] ADR constraints respected (list ADR-NNNN IDs where applicable)

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

**NOTE**: This section will be populated during implementation by plan-6a-update-progress.

**Footnote Numbering Authority**: plan-6a-update-progress is the **single source of truth** for footnote numbering across the entire plan.

**Allocation Strategy**:
- plan-6a reads the current ledger and determines the next available footnote number
- Footnote numbers are sequential and shared across all phases and subtasks (e.g., [^1], [^2], [^3]...)
- Each invocation of plan-6a increments the counter and updates BOTH ledgers (plan and dossier) atomically
- Footnotes are never manually assigned; always delegated to plan-6a for consistency

**Format**:
```markdown
[^N]: Task {plan-task-id} - {one-line summary}
  - `{flowspace-node-id}`
  - `{flowspace-node-id}`
```

**Example Template**:
```markdown
## Change Footnotes Ledger

[^1]: Task 2.3 - Added validation function
  - `function:src/validators/input_validator.py:validate_user_input`
  - `function:src/validators/input_validator.py:sanitize_input`

[^2]: Task 2.3 - Updated authentication flow
  - `method:src/auth/service.py:AuthService.authenticate`
  - `method:src/auth/service.py:AuthService.validate_token`

[^3]: Task 2.4 - Configuration changes
  - `file:config/settings.py`
  - `file:config/validators.json`
```

**Initial State** (before implementation begins):
```markdown
## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]
[^2]: [To be added during implementation via plan-6a]
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

---

## Appendix A: Anchor Naming Conventions

All deep links in the FlowSpace provenance graph use kebab-case anchors for consistency and reliability.

### Phase Anchors
**Format**: `phase-{number}-{slug}`
**Example**: `phase-2-input-validation`

Generated from: "Phase 2: Input Validation"

### Task Anchors (Plan)
**Format**: `task-{number}-{slug}` (use plan task number like "23" for task 2.3)
**Example**: `task-23-implement-validation`

Generated from: Task 2.3 with name "Implement validation"
Note: Use the flattened number (2.3 → 23) for uniqueness

### Task Anchors (Dossier)
**Format**: `task-{id}-{slug}` (use T-ID like "t003")
**Example**: `task-t003-implement-validation`

Generated from: Dossier task T003 with name "Implement validation"
Note: Includes "t" prefix to distinguish from plan task anchors

### Table Anchors
**Format**: `tasks-{approach}-approach` (based on testing approach)
**Examples**:
- `tasks-full-tdd-approach`
- `tasks-tad-approach`
- `tasks-lightweight-approach`
- `tasks-manual-approach`
- `tasks-hybrid-approach`

Generated from: Testing approach specified in plan § 6 Testing Strategy

### Subtask Anchors
**Format**: `{ordinal}-subtask-{slug}`
**Example**: `003-subtask-bulk-import-fixtures`

Generated from: Subtask ordinal (003) + slugified name

### Slugification Rules

**Algorithm** (used by plan-5, plan-5a, plan-6a):
1. Convert to lowercase
2. Replace spaces with hyphens
3. Replace non-alphanumeric characters (except hyphens) with hyphens
4. Collapse multiple consecutive hyphens to single hyphen
5. Trim leading and trailing hyphens

**Command**:
```bash
ANCHOR=$(echo "${INPUT}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
```

**Examples**:
- "Phase 2: Input Validation" → `phase-2-input-validation`
- "Task 2.3: Implement Validation" → `task-23-implement-validation` (plan) or `task-t003-implement-validation` (dossier)
- "Full TDD Approach" → `tasks-full-tdd-approach`
- "003-subtask-bulk import_fixtures!" → `003-subtask-bulk-import-fixtures`

### Anchor Stability

**IMPORTANT**: Once anchors are created and referenced, they should not change. Modifying task names or phase titles should NOT break existing deep links.

**Best Practice**: If a task name must change after implementation begins:
1. Keep the original anchor unchanged
2. Update only the visible heading text
3. Verify all deep links still resolve correctly

---

## Appendix B: Graph Traversal Guide

The FlowSpace planning system creates a **bidirectional provenance graph** connecting tasks, logs, files, and footnotes. This guide shows how to navigate the graph in all directions.

### Graph Node Types

1. **Plan Tasks** - Tasks in plan.md § 8 (numbered 2.3, 4.1, etc.)
2. **Dossier Tasks** - Tasks in `tasks/phase-N/tasks.md` (numbered T001, T002, ST001, etc.)
3. **Execution Log Entries** - In `tasks/phase-N/execution.log.md`
4. **Modified Files** - Source code, docs, configs with embedded FlowSpace IDs
5. **Footnotes** - In plan.md § 11 and dossier § Phase Footnote Stubs

### Navigation Patterns

#### From Task → Everything

**Starting Point**: Dossier task T003 in `tasks/phase-2/tasks.md`

1. **Find execution log entries**:
   - Look in Notes column for: `log#task-23-implement-validation`
   - Open: `tasks/phase-2/execution.log.md#task-23-implement-validation`
   - View implementation notes, test results, timing, and decisions

2. **Find modified files**:
   - Look in Absolute Path(s) column: `/abs/path/to/validators.py, /abs/path/to/auth.py`
   - Look in Notes column for footnote: `[^3]`
   - Jump to footnote ledger (bottom of tasks.md or plan.md § 11)
   - Read FlowSpace node IDs:
     * `function:src/validators.py:validate_email`
     * `method:src/auth/service.py:AuthService.authenticate`
   - Open files and navigate to specific symbols

3. **Find plan task**:
   - Look in Notes column for: "Supports plan task 2.3"
   - Open: `../../plan.md#task-23-implement-validation`
   - View plan-level task details and acceptance criteria

4. **Find subtasks** (if any):
   - Look in Subtasks column: `001-subtask-fixtures, 003-subtask-bulk`
   - Open: `tasks/phase-2/001-subtask-fixtures.md`
   - View subtask dossier and ST### tasks

#### From File → Tasks

**Starting Point**: Source file `src/validators.py`

1. **Find embedded FlowSpace ID comments**:
   ```python
   # FlowSpace: [^3] [^7] [^12] function:src/validators.py:validate_email
   def validate_email(email: str) -> bool:
       ...
   ```
   - Note footnote numbers: `[^3]`, `[^7]`, `[^12]`
   - These represent all tasks that ever modified this function

2. **Look up footnotes in plan**:
   - Open: `plan.md` § 11 Change Footnotes Ledger
   - Find: `[^3]: Task 2.3 - Added validation function`
   - Find: `[^7]: Task 3.2 - Enhanced email validation`
   - Find: `[^12]: Task 4.1 - Added internationalization support`

3. **Navigate to tasks**:
   - From footnote, note task IDs: "2.3", "3.2", "4.1"
   - Open plan tasks: `plan.md#task-23`, `plan.md#task-32`, `plan.md#task-41`
   - Or navigate to dossier tasks via plan task links

**Result**: Complete modification history showing which tasks touched this file and why

#### From Execution Log → Task → Files

**Starting Point**: Log entry in `execution.log.md`

1. **Read log metadata**:
   ```markdown
   ## Task 2.3: Implement validation
   **Dossier Task**: T003
   **Plan Task**: 2.3
   **Plan Reference**: [Phase 2: Input Validation](../../plan.md#phase-2-input-validation)
   **Dossier Reference**: [View T003 in Dossier](./tasks.md#task-t003)
   **Plan Task Entry**: [View Task 2.3 in Plan](../../plan.md#task-23-implement-validation)
   ```

2. **Navigate to tasks**:
   - Click dossier link → `tasks.md#task-t003`
   - Click plan link → `plan.md#task-23-implement-validation`
   - View task details, dependencies, validation criteria

3. **From task, find modified files**:
   - Check Absolute Path(s) column for direct file paths
   - Check Notes column for footnote: `[^3]`
   - Look up `[^3]` in footnote ledger
   - Get FlowSpace node IDs for specific symbols
   - Open files and navigate to symbols

#### From Footnote → Everything

**Starting Point**: Footnote `[^3]` in plan.md § 11

1. **Read footnote content**:
   ```markdown
   [^3]: Task 2.3 - Added validation function
     - `function:src/validators/input_validator.py:validate_user_input`
     - `function:src/validators/input_validator.py:sanitize_input`
     - `function:src/validators/input_validator.py:validate_email_format`
   ```

2. **Navigate to task**:
   - Note task ID: "2.3"
   - Open: `plan.md#task-23-implement-validation`
   - View task acceptance criteria and status

3. **Navigate to files**:
   - Extract file path from FlowSpace IDs: `src/validators/input_validator.py`
   - Open file
   - Search for embedded FlowSpace ID comments with `[^3]`
   - Navigate to specific functions

4. **Navigate to execution log**:
   - From task, find log reference: `log#task-23-implement-validation`
   - Open: `tasks/phase-2/execution.log.md#task-23-implement-validation`
   - View implementation details and test results

#### From Subtask → Parent Task

**Starting Point**: Subtask dossier `tasks/phase-2/001-subtask-fixtures.md`

1. **Read Parent Context section**:
   ```markdown
   ## Parent Context
   **Parent Task(s):** [T003: Implement validation](../tasks.md#task-t003)
   **Plan Task(s):** [2.3: Implement validation](../../plan.md#task-23-implement-validation)
   **Why This Subtask:** Test fixtures needed before implementing validation...
   ```

2. **Navigate to parent**:
   - Click parent dossier link → `tasks.md#task-t003`
   - Click plan task link → `plan.md#task-23-implement-validation`
   - View parent task context

3. **Check resumption status**:
   - In plan.md, find Subtasks Registry
   - Locate row for `001-subtask-fixtures`
   - Check Status: `[x] Complete` or `[ ] Pending`

#### From Parent Task → Subtasks

**Starting Point**: Dossier task T003 in `tasks/phase-2/tasks.md`

1. **Check Subtasks column**:
   - Look for: `001-subtask-fixtures, 003-subtask-bulk`
   - Note: comma-separated list of subtask IDs

2. **Navigate to subtask dossiers**:
   - Open: `tasks/phase-2/001-subtask-fixtures.md`
   - Open: `tasks/phase-2/003-subtask-bulk.md`
   - View subtask tasks (ST### format) and alignment brief

3. **Check subtask status in registry**:
   - Open: `plan.md` § Subtasks Registry
   - Find rows for subtasks
   - Check completion status

### Common Traversal Scenarios

**Scenario 1: "Which tasks modified this file?"**
- Open file → Find FlowSpace ID comments → Extract footnote numbers → Look up in plan § 11 → Get task IDs

**Scenario 2: "What did task 2.3 actually change?"**
- Open plan.md#task-23 → Check footnote in Notes → Look up in § 11 → Get FlowSpace node IDs → Open files

**Scenario 3: "Why was this function added?"**
- Open file → Find FlowSpace ID with footnote → Look up footnote → Get task ID → Open log entry → Read "Why" and rationale

**Scenario 4: "What's the history of this class?"**
- Open file → Find FlowSpace ID with multiple footnotes (e.g., `[^3] [^7] [^12]`) → Look up each footnote → Get chronological task list

**Scenario 5: "Is this subtask blocking the parent task?"**
- Open parent task → Check Subtasks column → Open subtask → Check status → Review Subtasks Registry

### Graph Integrity

All edges are **bidirectional**. If you can go from A→B, you can also go from B→A:
- Task ↔ Log (via log#anchor references and task metadata in logs)
- Task ↔ File (via footnotes and embedded FlowSpace IDs)
- Task ↔ Footnote (via Notes column and footnote task references)
- Plan Task ↔ Dossier Task (via "Supports plan task X.Y" and task correlation)
- Parent Task ↔ Subtask (via Subtasks column and Parent Context section)

**Validation**: Run `/plan-7-code-review` to verify all bidirectional links are intact and synchronized.

```

Next step (when happy): Run **/plan-4-complete-the-plan** to validate readiness.
