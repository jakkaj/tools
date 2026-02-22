---
description: Resolve high-impact ambiguities (<=8 questions), capture answers in the spec, and update relevant sections immediately. Domain-aware v2.
---

Please deep think / ultrathink as this is a complex task.

# plan-2-v2-clarify

Ask **≤8** high-impact questions (only those truly needed), write answers into the **spec**, and update affected sections immediately. Includes Domain Review for boundary validation.

```md
User input:

$ARGUMENTS

Flow:
1) Determine PLAN_DIR from the spec path provided, then set FEATURE_SPEC = `${PLAN_DIR}/<slug>-spec.md`.
2) Scan spec with taxonomy (Testing Strategy, Documentation Strategy, Target Domains, FRs, NFRs, data model, integrations, UX, edge cases, terminology).
3) Ask ONE question at a time using the ask_user tool (MC 2-5 options or short answer); cap at 8 total.
   - **Q1 MUST be Workflow Mode selection** (Simple vs Full) — see format below
   - PRIORITIZE Testing Strategy question next if not already defined (usually Q2)
   - Ask for mock/stub preference immediately after testing strategy
   - Ask Documentation Strategy question early
   - Ask Domain Review question when Target Domains section exists
4) After each answer: append under `## Clarifications` → `### Session YYYY-MM-DD`, then update the matching section(s). Save after each edit.
5) Stop when critical ambiguities resolved or cap reached. Emit coverage summary.

## Standard Questions

### Q1: Workflow Mode (MUST be first)

| Option | Mode | Best For | What Changes |
|--------|------|----------|--------------|
| A | Simple | CS-1/CS-2 tasks, single phase, quick path | Single-phase plan, inline tasks, plan-4/plan-5 optional |
| B | Full | CS-3+ features, multiple phases | Multi-phase plan, required dossiers, all gates |

**If Simple Mode**: Update spec header with `**Mode**: Simple`, testing defaults to Lightweight.
**If Full Mode**: Update spec header with `**Mode**: Full`, all gates required.

### Testing Strategy

| Option | Approach | Best For |
|--------|----------|----------|
| A | Full TDD | Complex logic, algorithms, APIs |
| B | Lightweight | Simple operations, config changes |
| C | Manual Only | One-time scripts, trivial changes |
| D | Hybrid | Mixed complexity — TDD for complex, lightweight for simple |

Updates to spec: Add `## Testing Strategy` with Approach, Rationale, Focus Areas, Excluded.

### Mock Usage

| Option | Policy |
|--------|--------|
| A | Avoid mocks entirely — real data/fixtures only |
| B | Allow targeted mocks — limited to external systems |
| C | Allow liberal mocking — wherever beneficial |

### Documentation Strategy

| Option | Location | Best For |
|--------|----------|----------|
| A | README.md only | Quick-start essentials |
| B | docs/how/ only | Detailed guides |
| C | Hybrid (README + docs/how/) | Both quick-start and depth |
| D | No new documentation | Internal/trivial changes |

### Domain Review

Present the Target Domains from the spec:

```
The spec identifies these target domains:

| Domain | Status | Role |
|--------|--------|------|
| [from spec] | [existing/NEW] | [from spec] |

Questions:
```

Ask the user to confirm using ask_user:

**For NEW domains**:
- Does the boundary look right?
- Should any part be absorbed into an existing domain instead?
- Are the contracts clear enough to proceed?

**For existing domains**:
- Will changes respect existing contracts?
- Any contract-breaking changes needed? (flag for ADR)

**After Domain Review**: Update spec `## Target Domains` section with user's adjustments. If user identified new domain boundaries or merged domains, update the table and sketches accordingly.

### Additional Questions (as needed)

Draw from these categories based on spec gaps:
- **Data model**: Entity relationships, schemas, storage
- **FRs**: Feature requirements needing clarification
- **NFRs**: Performance, security, accessibility requirements
- **Integrations**: External system dependencies
- **Edge cases**: Boundary conditions, error scenarios
- **Terminology**: Domain-specific terms needing definition

## Updates to Spec

After each answer, update the appropriate spec section:
- `## Testing Strategy` — Approach, Rationale, Focus Areas, Mock Usage
- `## Documentation Strategy` — Location, Rationale
- `## Target Domains` — Adjusted boundaries, merged/split domains
- `## Clarifications` → `### Session YYYY-MM-DD` — Q&A record
- Other sections as appropriate (Goals, Non-Goals, ACs, Risks)

## Gates

- At least Q1 (Workflow Mode) answered
- Target Domains reviewed (if section exists in spec)
- No critical `[NEEDS CLARIFICATION]` markers remaining in spec

Output: Updated SPEC_FILE with clarifications applied.
```

Next step: Run **/plan-3-v2-architect** to generate the implementation plan.
