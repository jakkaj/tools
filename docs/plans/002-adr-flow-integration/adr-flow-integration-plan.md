# ADR Flow Integration Implementation Plan

**Plan Version**: 1.0.0
**Created**: 2025-11-07
**Spec**: [View Spec](./adr-flow-integration-spec.md)
**Status**: DRAFT

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technical Context](#technical-context)
3. [Critical Research Findings](#critical-research-findings)
4. [Testing Philosophy](#testing-philosophy)
5. [Implementation Phase](#implementation-phase)
6. [Cross-Cutting Concerns](#cross-cutting-concerns)
7. [Progress Tracking](#progress-tracking)
8. [Change Footnotes Ledger](#change-footnotes-ledger)
9. [Appendix A: Anchor Naming Conventions](#appendix-a-anchor-naming-conventions)

## Executive Summary

**Problem Statement**: The planning workflow lacks a structured way to document architectural decisions, resulting in lost context and rationale for technical choices made during feature development.

**Solution Approach**:
- Create a new optional `/plan-3a-adr` command that generates ADR documents
- Enhance existing planning commands with ADR awareness
- Maintain backward compatibility with existing workflows

**Expected Outcomes**:
- Durable architectural decision documentation
- Improved traceability between decisions and implementation
- Machine-parseable ADR format for future automation

**Success Metrics**:
- ADR generation command functional
- Existing commands enhanced with ADR integration points
- No breaking changes to current workflows

## Technical Context

**Current System State**:
- Planning workflow consists of 10 commands (plan-0 through plan-7)
- Commands are markdown files in `agents/commands/` directory
- Specs and plans stored in `docs/plans/<ordinal>-<slug>/` structure
- No current ADR generation capability

**Integration Requirements**:
- Must integrate with existing planning command structure
- Must preserve backward compatibility
- Must follow existing file and anchor naming conventions
- Must use parallel subagent patterns for research tasks

**Constraints and Limitations**:
- Breaking change deployment approach (user confirmed)
- Lightweight testing only (no comprehensive test coverage)
- No separate documentation (command files serve as docs)

**Assumptions**:
- Users understand when to create ADRs
- Semi-automated status management is sufficient
- Warning-only duplicate detection is acceptable
- Numbering conflicts are rare enough to accept risk

## Critical Research Findings

### 🚨 Critical Discovery 01: Command File Structure Pattern
**Impact**: Critical
**Problem**: ADR command must match exact structure of existing planning commands
**Solution**: Follow the markdown frontmatter + body pattern with mode, description, and tools array
**Example**:
```markdown
---
mode: 'agent'
description: 'Generate an Architectural Decision Record...'
tools: ['changes', 'search/codebase', 'edit/editFiles', ...]
---
# plan-3a-adr
[command content]
```
**Action Required**: Create plan-3a-adr.md following this exact structure

### 🚨 Critical Discovery 02: Parallel Subagent Pattern Required
**Impact**: Critical
**Problem**: Single-threaded research is inefficient for ADR generation
**Solution**: Use 4 parallel subagents launched in single message
**Example**:
```javascript
// ❌ WRONG - Sequential calls
await Task({subagent_type: "general-purpose", prompt: "Find ADRs"});
await Task({subagent_type: "general-purpose", prompt: "Read doctrine"});

// ✅ CORRECT - Parallel calls
[
  Task({subagent_type: "general-purpose", prompt: "Find ADRs"}),
  Task({subagent_type: "general-purpose", prompt: "Read doctrine"}),
  Task({subagent_type: "general-purpose", prompt: "Extract decisions"}),
  Task({subagent_type: "general-purpose", prompt: "Analyze alternatives"})
]
```
**Action Required**: Implement parallel research pattern in plan-3a-adr

### 🟠 High Discovery 03: ADR Seeds Section Integration
**Impact**: High
**Problem**: plan-1-specify needs to capture ADR hints without solutioning
**Solution**: Add optional "ADR Seeds" section after "Open Questions"
**Example**:
```markdown
## ADR Seeds (Optional)

* Decision Drivers: [constraints/NFRs]
* Candidate Alternatives: [A, B, C summaries]
* Stakeholders: [roles/names]
```
**Action Required**: Update plan-1-specify.md to include this section

### 🟠 High Discovery 04: ADR Gate in plan-3-architect
**Impact**: High
**Problem**: Plans must be aware of existing ADRs to avoid conflicts
**Solution**: Add optional ADR gate in Phase 1 validation
**Example**:
```markdown
### GATE - ADR (Optional)
- If docs/adr/ contains relevant ADRs, import constraints
- Create ADR Ledger table tracking dependencies
- Recommend /plan-3a-adr if critical decisions lack ADRs
```
**Action Required**: Insert ADR gate into plan-3-architect Phase 1

### 🟡 Medium Discovery 05: File Numbering Convention
**Impact**: Medium
**Problem**: ADRs need sequential 4-digit numbering
**Solution**: Scan existing files, parse numbers, increment
**Example**:
```bash
# Find next number
EXISTING=$(ls docs/adr/adr-*.md 2>/dev/null | sed 's/.*adr-\([0-9]*\).*/\1/' | sort -n | tail -1)
NEXT=$(printf "%04d" $((${EXISTING:-0} + 1)))
```
**Action Required**: Implement auto-numbering logic

## Testing Philosophy

### Testing Approach
**Selected Approach**: Lightweight
**Rationale**: This is primarily a documentation generation feature that doesn't require extensive test coverage
**Focus Areas**:
- ADR file generation with correct formatting
- Sequential numbering logic
- Cross-linking between documents

### Mock Usage
**Policy**: Avoid mocks entirely
**Rationale**: Use real file operations only since this is document generation

## Implementation Phase

### Phase 1: ADR Flow Integration

**Objective**: Implement the complete ADR generation and integration functionality in a single deployment.

**Deliverables**:
- New `/plan-3a-adr` command file
- Updated `plan-1-specify` with ADR Seeds section
- Updated `plan-3-architect` with ADR awareness gate
- Updated `plan-5-phase-tasks-and-brief` with ADR constraint mapping

**Dependencies**: None (can be implemented immediately)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing workflows | Low | High | Thorough testing of modified commands |
| ADR numbering conflicts | Low | Low | Accept risk, handle manually |
| Commands sync failure | Low | Medium | Run setup.sh multiple times if needed |

### Tasks (Lightweight Approach)

| #   | Status | Task | Success Criteria | Log | Notes |
|-----|--------|------|------------------|-----|-------|
| 1.1 | [ ] | Create plan-3a-adr.md command file | File created with complete ADR generation logic | - | /Users/jordanknight/github/tools/agents/commands/plan-3a-adr.md |
| 1.2 | [ ] | Update plan-1-specify.md with ADR Seeds | Optional section added after "Open Questions" | - | /Users/jordanknight/github/tools/agents/commands/plan-1-specify.md |
| 1.3 | [ ] | Update plan-3-architect.md with ADR gate | ADR awareness gate added to Phase 1 | - | /Users/jordanknight/github/tools/agents/commands/plan-3-architect.md |
| 1.4 | [ ] | Update plan-5-phase-tasks-and-brief.md | ADR constraint ingestion added to Step 2 | - | /Users/jordanknight/github/tools/agents/commands/plan-5-phase-tasks-and-brief.md |
| 1.5 | [ ] | Sync files to distribution | Run sync-to-dist.sh to copy to src/jk_tools/ | - | /Users/jordanknight/github/tools/scripts/sync-to-dist.sh |
| 1.6 | [ ] | Run setup.sh to install commands | Commands deployed to all CLI tools | - | /Users/jordanknight/github/tools/setup.sh |
| 1.7 | [ ] | Test ADR generation with sample spec | ADR created with correct format and numbering | - | Create test spec, run plan-3a-adr |
| 1.8 | [ ] | Verify backward compatibility | Existing workflows work without ADRs | - | Run plan-1 through plan-3 without ADR usage |

### Implementation Details

**Task 1.1: Create plan-3a-adr.md**
- Copy template from scratch/adr.md user instructions
- Add markdown frontmatter with mode, description, tools
- Implement parallel subagent pattern for research
- Include duplicate detection with warning
- Add semi-automated status suggestion logic

**Task 1.2: Update plan-1-specify.md**
- Locate "Open Questions" section in template
- Insert ADR Seeds section after it
- Keep optional with clear markers
- Include decision drivers, alternatives, stakeholders fields

**Task 1.3: Update plan-3-architect.md**
- Find Phase 1: Initial Gates & Validation section
- Add "GATE - ADR (Optional)" after Constitution gate
- Include logic to scan docs/adr/ for existing ADRs
- Add ADR Ledger table format
- Insert recommendation for plan-3a-adr when needed

**Task 1.4: Update plan-5-phase-tasks-and-brief.md**
- Locate Step 2: Read Critical Research Findings
- Add ADR ingestion logic after reading findings
- Update Alignment Brief template with ADR Decision Constraints section
- Modify task Notes column to include ADR IDs
- Add ADR constraint check to Ready Check section

### Acceptance Criteria
- [ ] All command files created/updated successfully
- [ ] ADR generation produces correctly formatted files
- [ ] Sequential numbering works (0001, 0002, etc.)
- [ ] Cross-linking between ADRs, specs, and plans functional
- [ ] Duplicate detection shows warnings
- [ ] Commands synced to all CLI tools
- [ ] Backward compatibility maintained

## Cross-Cutting Concerns

### Security Considerations
- No security implications (documentation only)
- File operations use standard permissions

### Observability
- Command execution logged to console
- File creation confirmations displayed
- Warning messages for duplicates shown

### Documentation
- No separate documentation needed per spec
- Command markdown files are self-documenting
- Help text embedded in command descriptions

## Progress Tracking

### Phase Completion Checklist
- [ ] Phase 1: ADR Flow Integration - PENDING

### STOP Rule
**IMPORTANT**: This plan must be complete before creating tasks. After writing this plan:
1. Run `/plan-4-complete-the-plan` to validate readiness (optional given single phase)
2. Proceed directly to implementation given lightweight approach

## Change Footnotes Ledger

**NOTE**: This section will be populated during implementation by plan-6a-update-progress.

[^1]: [To be added during implementation via plan-6a]

## Appendix A: Anchor Naming Conventions

### ADR Anchors
**Format**: `adr-{number}-{slug}`
**Example**: `adr-0001-adopt-event-sourcing`

Generated from: ADR filename "adr-0001-adopt-event-sourcing.md"

### Slugification Rules for ADRs

**Algorithm**:
1. Convert to lowercase
2. Replace spaces with hyphens
3. Replace non-alphanumeric characters (except hyphens) with hyphens
4. Collapse multiple consecutive hyphens to single hyphen
5. Trim leading and trailing hyphens

**Examples**:
- "Adopt Event Sourcing" → `adopt-event-sourcing`
- "Use Redis for Caching" → `use-redis-for-caching`
- "Implement Circuit Breaker Pattern" → `implement-circuit-breaker-pattern`

---

✅ Plan created successfully:
- Location: /Users/jordanknight/github/tools/docs/plans/002-adr-flow-integration/adr-flow-integration-plan.md
- Phases: 1 (single phase as requested)
- Total tasks: 8
- Next step: Proceed directly to implementation or run /plan-4-complete-the-plan for validation