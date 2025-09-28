---
description: Resolve high-impact ambiguities (<=5 questions), capture answers in the spec, and update relevant sections immediately.
---

Please deep think / ultrathink as this is a complex task. 

# plan-2-clarify

Ask **<=5** high-impact questions, write answers into the **spec**, and update affected sections immediately.

```md
User input:

$ARGUMENTS

Flow:
1) Determine PLAN_DIR from the spec path provided, then set FEATURE_SPEC = `${PLAN_DIR}/<slug>-spec.md` (spec co-located with plan).
2) Scan spec with taxonomy (Testing Strategy, FRs, NFRs, data model, integrations, UX, edge cases, terminology).
3) Ask ONE question at a time (MC table 2-5 options or short answer <=5 words); cap at 5 total.
   - PRIORITIZE Testing Strategy question if not already defined (usually Q1 or Q2)
4) After each answer: append under `## Clarifications` -> `### Session YYYY-MM-DD`, then update the matching section(s) (Testing Strategy/FRs/NFRs/data model/stories/edge cases). Save after each edit.
5) Stop when critical ambiguities resolved or cap reached. Emit coverage summary (Resolved/Deferred/Outstanding).

Testing Strategy Question Format:
```
Q: What testing approach best fits this feature's complexity and risk profile?

| Option | Approach | Best For | Test Coverage |
|--------|----------|----------|---------------|
| A | Full TDD | Complex logic, algorithms, APIs | Comprehensive unit/integration/e2e tests |
| B | Lightweight | Simple operations, config changes | Core functionality validation only |
| C | Manual Only | One-time scripts, trivial changes | Document manual verification steps |
| D | Hybrid | Mixed complexity features | TDD for complex, lightweight for simple |

Answer: [A/B/C/D]
Rationale: [1-2 sentences from user]
```

Updates to Spec:
- Add/Update `## Testing Strategy` section with:
  - **Approach**: [Full TDD | Lightweight | Manual | Hybrid]
  - **Rationale**: [User's reasoning]
  - **Focus Areas**: [What needs thorough testing]
  - **Excluded**: [What doesn't need extensive testing]

Rules:
- Only high-impact questions; no solutioning.
- Testing strategy influences downstream planning.
- Deterministic structure; preserve headings.

Output: Updated SPEC with `## Clarifications` for today + summary table; next = /architect.
```

Next step (when happy): Run **/plan-3-architect** to generate the phase-based plan.
