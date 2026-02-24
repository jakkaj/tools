---
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

Create detailed design explorations for concepts that benefit from thorough specification before architecture. These are **working reference documents** - something a developer would actually keep open during implementation.

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

### 5) Create Workshop Document

**Required Header**:
```markdown
# Workshop: [Topic Name]

**Type**: [CLI Flow | Data Model | API Contract | State Machine | Integration Pattern | Storage Design | Other]
**Plan**: [ordinal-slug]
**Spec**: [link to spec]
**Created**: [ISO-8601]
**Status**: Draft | Review | Approved

**Related Documents**:
- [Link to related workshop or external doc]

**Domain Context** (if domains exist):
- **Primary Domain**: [domain this workshop's topic belongs to]
- **Related Domains**: [domains that consume or are consumed by this topic]

---

## Purpose

[1-2 sentences: What does this workshop clarify? What decisions does it drive?]

## Key Questions Addressed

- [Question 1 from spec or user input]
- [Question 2]
- [Question 3]

---
```

**Body Content** - Flexible based on type. Follow the vibe from examples:

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
✅ **Concrete examples**: Real data, actual output, working code
✅ **Multiple formats**: Uses appropriate mix of diagrams, tables, code, prose
✅ **Decision clarity**: Design choices are explicit with rationale
✅ **Implementation ready**: Developer can use this as reference during coding
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
