---
name: plan-2c-v2-workshop
description: Create detailed design documents for complex concepts identified in the spec's Workshop Opportunities, or any topic needing deep exploration. Domain-aware v2.
---
Please deep think / ultrathink as this is a complex task.

# plan-2c-workshop

Create a **detailed design document** that explores a complex concept in depth. Workshops are working reference documents - practical, concrete, and useful during implementation.

```md
User input:

$ARGUMENTS
# Expected formats:
# /plan-2c-workshop <plan> "<topic>"           # Workshop a specific topic
# /plan-2c-workshop <plan> --from-spec         # Pick from spec's Workshop Opportunities
# /plan-2c-workshop <plan> --list              # List existing workshops
#
# Examples:
# /plan-2c-workshop 003-workflow-service "CLI command flows"
# /plan-2c-workshop workflow-service "WorkUnit data model"
# /plan-2c-workshop 003-workflow-service --from-spec
```

## Purpose

Create detailed design explorations for concepts that benefit from thorough specification before architecture. These are **working reference documents** - something a developer, reviewer, stakeholder, or agent would actually keep open during implementation.

A workshop should improve value delivery by reducing the time, ambiguity, risk, or human attention required to move from intent to implementation-ready evidence.

## When to Use

- Concept has multiple valid implementation approaches
- External interfaces or contracts need detailed specification  
- Data structures will be referenced by multiple components
- CLI/UX flow has branching paths or complex state
- Storage format decisions affect future extensibility
- Schema changes have migration implications
- You need stakeholder alignment on design details

## Workshop Types & Suggested Formats

| Type | Best Formats | Example Content |
|------|--------------|-----------------|
| **CLI Flow** | ASCII box diagrams, terminal examples, command tables | Command syntax, output formats, error codes |
| **Data Model** | TypeScript types, JSON Schema, mermaid ER diagrams | Entity relationships, validation rules, examples |
| **API Contract** | OpenAPI snippets, request/response examples, sequence diagrams | Endpoints, payloads, error responses |
| **State Machine** | Mermaid state diagrams, transition tables | States, events, guards, actions |
| **Integration Pattern** | Sequence diagrams, interface definitions | Protocols, contracts, failure modes |
| **Storage Design** | File trees, YAML/JSON examples, migration paths | Directory structure, file formats, versioning |

**Format is flexible** - use whatever representation best clarifies the concept. Mix formats freely.

## Workshop Value Thesis

A workshop improves value delivery when it reduces the time and human attention required to move from ambiguous intent to implementation-ready evidence.

A workshop is working when a fresh human or agent can enter the topic, understand the relevant context, reach the target proof level, and leave behind evidence or encoded learning that makes the next loop cheaper.

Measure the workshop by its ability to produce verified useful decisions, reusable examples, explicit contracts, and validated learning per unit of human attention.

This deliberately avoids "we made a better document." Better at what? More detailed? Longer? Easier to admire? The stronger claim is that ambiguity, rediscovery, review burden, implementation risk, and coordination cost are becoming cheaper, safer, and more repeatable.

## Value Axis Selection

Each workshop should identify the value axes most relevant to the topic.

Value axes are not fixed roles or mandatory categories. They are lenses for explaining how the workshop makes future work cheaper, safer, clearer, or more repeatable.

The workshop agent should:

1. Select 3-5 value axes that best fit the topic
2. Prefer axes that explain concrete downstream value
3. Add custom axes when the suggested list does not fit
4. Avoid filling every axis mechanically
5. Use the selected axes to shape examples, evidence, validation, and success criteria

Suggested axes include:

| Axis | Use When The Workshop Needs To Improve... |
|------|-------------------------------------------|
| **Strategic Value** | Alignment with business, product, platform, or architectural goals |
| **Operator Usability** | How humans actually use the system during real work |
| **Implementation Readiness** | Whether developers or agents can build from the workshop |
| **Proof Quality** | Whether claims are backed by examples, tests, traces, schemas, or evidence |
| **Safety to Change** | Whether future changes can happen without hidden breakage |
| **Review Compression** | Whether reviewers can evaluate work faster and more objectively |
| **Onboarding / Accessibility** | Whether a fresh person or agent can understand the topic quickly |
| **Knowability** | Whether hidden system behavior has been made explicit |
| **Agent Readiness** | Whether an agent can act on the workshop with minimal clarification |
| **Learning Compounding** | Whether the workshop captures decisions so future loops avoid rediscovery |
| **Migration Safety** | Whether transition paths, compatibility, and rollback are clear |
| **Cross-Domain Coordination** | Whether domain boundaries, contracts, and handoffs are explicit |
| **Operational Reliability** | Whether failure modes, monitoring, recovery, and support paths are understood |
| **User Experience** | Whether user-visible flows, errors, feedback, and expectations are clear |
| **Cost / Attention Reduction** | Whether the workshop makes a future loop cheaper in human effort |

The agent may add, remove, rename, or combine axes when another framing better explains the workshop's value.

### Example Value Framings

These are examples only. The workshop agent should choose the framing that best fits the topic.

**Strategic-style framing**:
This workshop improves value delivery when it makes the planned system more accessible, more knowable, and safer to change.

**Operator-style framing**:
This workshop is working when a fresh human or agent can enter the topic, use the reference material, reach the target proof level, and leave behind evidence that makes the next loop cheaper.

**Measurement-style framing**:
Measure this workshop by its ability to produce verified useful decisions, examples, contracts, and learning per unit of human attention.

## Proof Levels

Each workshop should state its target proof level and current proof level.

| Proof Level | Meaning | Typical Evidence |
|-------------|---------|------------------|
| **Orientation** | Reader understands the topic and why it matters | Purpose, context, glossary, boundaries |
| **Decision Space** | Reader understands options and tradeoffs | Options table, constraints, pros/cons |
| **Preferred Direction** | Workshop recommends a design direction | Recommendation, rationale, rejected alternatives |
| **Contract Ready** | Interfaces, schemas, states, commands, or flows are specified | Types, schemas, examples, diagrams, error cases |
| **Implementation Ready** | Developer or agent can build from it with minimal clarification | Acceptance criteria, edge cases, validation rules, test scenarios |
| **Validated** | The design has been checked against implementation, tests, prototype output, or real usage | Test results, prototype output, review notes, migration evidence |


## Execution Flow

### 1) Parse Input & Resolve Plan

```python
# Pseudo-code
def resolve_plan(input):
    # If input looks like "003-slug" or full path
    if matches(r'^\d{3}-') or input.startswith('docs/plans/'):
        return find_plan_by_path(input)
    
    # Otherwise it's a slug - find matching plan
    for folder in list_folders('docs/plans/'):
        if folder.endswith(f'-{slugify(input)}'):
            return f'docs/plans/{folder}'
    
    error(f'Plan not found: {input}')
```

### 2) Handle Modes

**--list mode**: Show existing workshops
```
Workshops in docs/plans/003-workflow-service/:
  001-cli-command-flows.md (CLI Flow) - Created 2024-01-15
  002-workunit-data-model.md (Data Model) - Created 2024-01-16
  
Run: /plan-2c-v2-workshop 003-workflow-service "<topic>" to create new
```

**--from-spec mode**: Read spec's Workshop Opportunities and prompt user to select
```
Workshop Opportunities from spec:

| # | Topic | Type | Status |
|---|-------|------|--------|
| 1 | CLI command flows | CLI Flow | Not started |
| 2 | WorkUnit data model | Data Model | ✅ Complete |
| 3 | State transitions | State Machine | Not started |

Select topic number (or 'all' to create all): _
```

**Direct topic mode**: Create workshop for specified topic

### 3) Check for Existing Workshop & Determine Ordinal

- Scan `${PLAN_DIR}/workshops/` for existing files matching `NNN-*.md` pattern
- Determine next ordinal: highest NNN + 1 (zero-pad to 3 digits, start at 001)
- Check if a workshop with matching topic-slug already exists (any ordinal)
- If exists: Ask whether to update existing or create new
- If not exists: Create new with next ordinal
- WORKSHOP_FILE = `${PLAN_DIR}/workshops/${ORD}-${topic-slug}.md`

### 4) Gather Context

1. **Read the spec** (`${PLAN_DIR}/<slug>-spec.md`)
   - Extract Workshop Opportunity details if topic matches
   - Note key questions to answer
   - Understand feature context

2. **Read research dossier** (if exists)
   - Extract relevant findings for this topic
   - Note existing patterns and conventions

3. **Read related workshops** (if any)
   - Understand cross-references needed
   - Maintain consistency

4. **Load domain context** (if `docs/domains/registry.md` exists)
   - Read spec's `## Target Domains` to understand which domains are relevant
   - Read `docs/domains/domain-map.md` if it exists — understand how domains connect and what contracts flow between them
   - For domains this workshop topic relates to, read `docs/domains/<slug>/domain.md`
   - Note existing contracts and composition — the workshop design should respect domain boundaries
   - If the workshop is designing a new service/adapter/model, check which domain it belongs to
   - If the topic spans multiple domains, note the cross-domain contracts needed

5. **Identify the value frame**
   - Select 3-5 value axes that best fit the workshop topic
   - Define the target proof level and current proof level
   - Identify the downstream loop this workshop should make cheaper, safer, clearer, or more repeatable
   - Decide what evidence the workshop should produce: examples, schemas, diagrams, test scenarios, state tables, command outputs, decision tables, or other proof artifacts

### 5) Create Workshop Document

**Required Header**:
```markdown
# Workshop: [Topic Name]

**Type**: [CLI Flow | Data Model | API Contract | State Machine | Integration Pattern | Storage Design | Other]
**Plan**: [ordinal-slug]
**Spec**: [link to spec]
**Created**: [ISO-8601]
**Status**: Draft | Review | Approved

**Value Thesis**: [How this workshop makes validated work cheaper, safer, clearer, or more repeatable]
**Target Proof Level**: Orientation | Decision Space | Preferred Direction | Contract Ready | Implementation Ready | Validated
**Current Proof Level**: Orientation | Decision Space | Preferred Direction | Contract Ready | Implementation Ready | Validated

**Selected Value Axes**:
- **[Axis 1]**: [Why this axis matters for this workshop]
- **[Axis 2]**: [Why this axis matters for this workshop]
- **[Axis 3]**: [Why this axis matters for this workshop]

**Related Documents**:
- [Link to related workshop or external doc]

**Domain Context** (if domains exist):
- **Primary Domain**: [domain this workshop's topic belongs to]
- **Related Domains**: [domains that consume or are consumed by this topic]

---

## Purpose

[1-2 sentences: What does this workshop clarify? What decisions does it drive? What future loop should it make cheaper?]

## Fresh Entrant Outcome

A fresh human or agent should be able to use this workshop to reach **[target proof level]** with no additional context.

They should be able to:

- [Capability 1]
- [Capability 2]
- [Capability 3]

## Key Questions Addressed

- [Question 1 from spec or user input]
- [Question 2]
- [Question 3]

---
```

**Body Content** - Flexible based on type. Follow the vibe from examples.

Every workshop should include only the sections that help the topic reach its target proof level. The sections below are recommended, not mandatory. The agent should choose the shape that best explains the concept and produces useful evidence.

#### Shared Value Sections

```markdown
## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | [Proof level] | [Why this level is enough for the next loop] |
| Primary Value Axis | [Axis] | [How this workshop creates value] |
| Supporting Value Axes | [Axes] | [How they shape the workshop] |
| Downstream Loop Improved | [Implementation / Review / Testing / Migration / Onboarding / Agent execution / Other] | [What gets cheaper, safer, clearer, or more repeatable] |

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| [Evidence item] | [Section] | [Decision / contract / risk / edge case] | Missing / Draft / Ready / Validated |

## Decision Space

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| Option A | [Description] | [Pros] | [Cons] | Selected / Rejected / Open |
| Option B | [Description] | [Pros] | [Cons] | Selected / Rejected / Open |

## Attention Reduction

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Implementation | [What had to be inferred] | [What is now explicit] |
| Review | [What reviewers had to reconstruct] | [What reviewers can check directly] |
| Testing | [What testers had to invent] | [What scenarios or validation rules are provided] |
| Agent execution | [What required repeated clarification] | [What an agent can now do from the document] |

## Validation / Acceptance

This workshop reaches its target proof level when:

- [Validation condition 1]
- [Validation condition 2]
- [Validation condition 3]
```


#### CLI Flow Workshop Pattern
```markdown
## Overview

[Brief description of the CLI surface area]

## Command Summary

| Command | Purpose |
|---------|---------|
| `tool cmd1` | [What it does] |
| `tool cmd2` | [What it does] |

---

## [Command Name]

​```
$ tool command <args>

┌─────────────────────────────────────────────────────────────┐
│ STEP 1: [Description]                                       │
│   • [Detail]                                                 │
│   • [Detail]                                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ OUTPUT                                                      │
│                                                             │
│   [Actual output example]                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
​```

### [Command Name] (JSON output)

​```
$ tool command --json

{
  "field": "value",
  "nested": {
    "key": "value"
  }
}
​```

---

## Error Codes

| Code | Message | Cause |
|------|---------|-------|
| E001 | [Message] | [What triggers this] |
| E002 | [Message] | [What triggers this] |

---

## Quick Reference

​```bash
# Common operations
tool cmd1 arg1
tool cmd2 --flag value
​```
```

#### Data Model Workshop Pattern
```markdown
## Overview

[What this data model represents, how it fits in the system]

## Conceptual Model

​```mermaid
erDiagram
    ENTITY1 ||--o{ ENTITY2 : contains
    ENTITY2 {
        string id PK
        string name
        datetime created_at
    }
​```

## File Storage

​```
.tool/
└── data/
    ├── entity1/
    │   └── config.yaml
    └── entity2/
        ├── definition.yaml
        └── data/
            └── [outputs]
​```

## Schema Definitions

### Entity1 (config.yaml)

​```yaml
# Example
slug: my-entity
version: "1.0.0"
description: What this does

nested:
  - name: field1
    type: string
    required: true
​```

### TypeScript Types

​```typescript
interface Entity1 {
  slug: string;
  version: string;
  description?: string;
  nested: NestedField[];
}

interface NestedField {
  name: string;
  type: 'string' | 'number' | 'boolean';
  required: boolean;
}
​```

### JSON Schema

​```typescript
export const ENTITY1_SCHEMA = {
  $schema: 'https://json-schema.org/draft/2020-12/schema',
  type: 'object',
  required: ['slug', 'version'],
  properties: {
    slug: {
      type: 'string',
      pattern: '^[a-z][a-z0-9-]*$',
    },
    // ...
  },
} as const;
​```

## Validation Rules

1. **[Rule name]**: [Description]
2. **[Rule name]**: [Description]

## Open Questions

### Q1: [Question]?

**RESOLVED**: [Answer and rationale]

### Q2: [Question]?

**OPEN**: [Options being considered]
- Option A: [Description]
- Option B: [Description]
```

#### State Machine Workshop Pattern
```markdown
## Overview

[What state this tracks, why it matters]

## State Diagram

​```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> Ready: upstream_complete
    Ready --> Running: start
    Running --> Complete: success
    Running --> Failed: error
    Failed --> Ready: retry
​```

## States

| State | Description | Entry Condition | Valid Transitions |
|-------|-------------|-----------------|-------------------|
| Pending | Waiting for dependencies | Initial state | Ready |
| Ready | Can be started | All upstream complete | Running |
| Running | In progress | User starts | Complete, Failed |

## Transitions

| From | To | Trigger | Guard | Action |
|------|-----|---------|-------|--------|
| Pending | Ready | upstream_complete | all deps done | notify |
| Ready | Running | start | none | begin_work |

## Events

| Event | Payload | Triggered By |
|-------|---------|--------------|
| upstream_complete | {node_id} | Upstream node |
| start | {} | User command |
```

### 6) Output

**Save to**: `${PLAN_DIR}/workshops/${ORD}-${topic-slug}.md`

**Success message**:
```
✅ Workshop created: docs/plans/003-workflow-service/workshops/cli-command-flows.md

Type: CLI Flow
Target Proof Level: Implementation Ready
Selected Value Axes: Operator Usability, Review Compression, Agent Readiness
Key Questions Addressed: 3
Status: Draft

Related workshops in this plan:
  - workunit-data-model.md (Data Model)

Next steps:
  - Review and refine the workshop document
  - Mark as 'Approved' when design is finalized
  - Continue with /plan-2-clarify or /plan-3-architect
```

## Workshop Document Principles

1. **Practical & Concrete** - Show real examples, actual output, not abstract descriptions
2. **Multiple Representations** - Same concept as diagrams, tables, code - whatever aids understanding
3. **Show Don't Tell** - `$ command` with output, not "the command shows..."
4. **Decision Rationale** - "**Why this format**:" sections explaining choices
5. **Quick Reference** - Summary tables, cheatsheets for implementation
6. **Error Handling** - What can go wrong, error codes, recovery
7. **Open Questions** - Track with RESOLVED/OPEN status
8. **Progressive Examples** - Simple case first, then variations
9. **Working Reference Feel** - Something to keep open during implementation
10. **Value Axis Fit** - Select the axes that explain this workshop's concrete downstream value
11. **Proof Level Clarity** - State what level of confidence or validation the workshop is trying to reach
12. **Evidence Trail** - Leave behind diagrams, examples, schemas, test scenarios, tables, or other proof artifacts
13. **Fresh Entrant Test** - A new human or agent can enter the topic and act without reconstructing missing context

## Integration with Other Commands

### From plan-1b-specify
- Spec identifies Workshop Opportunities
- `/plan-2c-workshop --from-spec` picks from that list

### Into plan-3-architect
- Architect checks for `workshops/*.md` in plan folder
- Incorporates workshop decisions into phase planning
- Reduces discovery work for workshopped topics
- References workshop documents in relevant phases

### Standalone Use
- Can be run anytime during planning
- Topic doesn't need to be in spec's Workshop Opportunities
- Useful for ad-hoc deep dives

## Success Criteria

✅ **Answers key questions**: Workshop addresses the questions that prompted it
✅ **Value thesis stated**: Workshop explains how it makes validated work cheaper, safer, clearer, or more repeatable
✅ **Selected value axes fit the topic**: Axes are chosen deliberately, not filled mechanically
✅ **Proof level clear**: Target and current proof levels are explicit
✅ **Fresh entrant ready**: A new human or agent can understand the topic and act without reconstructing missing context
✅ **Concrete examples**: Real data, actual output, working code
✅ **Multiple formats**: Uses appropriate mix of diagrams, tables, code, prose
✅ **Decision clarity**: Design choices are explicit with rationale
✅ **Evidence produced**: Workshop leaves behind reusable examples, contracts, schemas, test scenarios, decision tables, or other proof artifacts
✅ **Attention reducing**: The next implementation, review, testing, migration, onboarding, or agent loop requires less clarification
✅ **Implementation ready when required**: Developer or agent can use this as reference during coding when the target proof level requires it
✅ **Consistent structure**: Header metadata present, related docs linked
✅ **Open questions tracked**: Unresolved items marked clearly

## Examples

### Example 1: CLI Flow Workshop
```bash
/plan-2c-workshop 003-workflow-service "CLI command flows"
```
Creates `docs/plans/003-workflow-service/workshops/cli-command-flows.md` with command examples, ASCII flow diagrams, output formats, error codes.

### Example 2: Data Model Workshop
```bash
/plan-2c-workshop workflow-service "WorkUnit data model"
```
Creates workshop with TypeScript types, JSON schemas, mermaid ER diagrams, file structure, validation rules.

### Example 3: From Spec Opportunities
```bash
/plan-2c-workshop 003-workflow-service --from-spec
```
Shows list of Workshop Opportunities from spec, user selects which to create.

### Example 4: List Existing
```bash
/plan-2c-workshop 003-workflow-service --list
```
Shows all workshops in the plan folder with their types and status.