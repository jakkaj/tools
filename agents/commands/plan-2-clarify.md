---
description: Resolve high-impact ambiguities (<=8 questions), capture answers in the spec, and update relevant sections immediately.
---

Please deep think / ultrathink as this is a complex task. 

# plan-2-clarify

Ask **<=8** high-impact questions (only those truly needed), write answers into the **spec**, and update affected sections immediately.

```md
User input:

$ARGUMENTS

Flow:
1) Determine PLAN_DIR from the spec path provided, then set FEATURE_SPEC = `${PLAN_DIR}/<slug>-spec.md` (spec co-located with plan).
2) Scan spec with taxonomy (Testing Strategy, Documentation Strategy, FRs, NFRs, data model, integrations, UX, edge cases, terminology).
3) Ask ONE question at a time (MC table 2-5 options or short answer <=5 words); cap at 8 total (only ask high-impact questions).
   - PRIORITIZE Testing Strategy question if not already defined (usually Q1 or Q2)
   - Ask for mock/stub preference immediately after the testing strategy unless already documented
   - Ask Documentation Strategy question early (usually Q2 or Q3) to guide phase planning
4) After each answer: append under `## Clarifications` -> `### Session YYYY-MM-DD`, then update the matching section(s) (Testing Strategy/Documentation Strategy/FRs/NFRs/data model/stories/edge cases). Save after each edit.
5) Stop when critical ambiguities resolved or cap reached. Emit coverage summary (Resolved/Deferred/Outstanding).

Testing Strategy Question Format:
```
Q: What testing approach best fits this feature's complexity and risk profile?

| Option | Approach | Best For | Test Coverage |
|--------|----------|----------|---------------|
| A | Full TDD | Complex logic, algorithms, APIs | Comprehensive unit/integration/e2e tests |
| B | TAD (Test-Assisted Development) | Features needing executable documentation | Tests as high-fidelity docs; iterative refinement |
| C | Lightweight | Simple operations, config changes | Core functionality validation only |
| D | Manual Only | One-time scripts, trivial changes | Document manual verification steps |
| E | Hybrid | Mixed complexity features | TDD for complex, TAD/lightweight for others |

Answer: [A/B/C/D/E]
Rationale: [1-2 sentences from user]
```

Mock Usage Question Format:
```
Q: How should mocks/stubs/fakes be used during implementation?

| Option | Policy | Typical Use |
|--------|--------|-------------|
| A | Avoid mocks entirely | Real data/fixtures only |
| B | Allow targeted mocks | Limited to external systems or slow dependencies |
| C | Allow liberal mocking | Any component may be mocked when beneficial |

Answer: [A/B/C]
Rationale: [1-2 sentences from user]
```

Documentation Strategy Question Format:
```
Q: Where should this feature's documentation live?

| Option | Location | Best For | Content Examples |
|--------|----------|----------|------------------|
| A | README.md only | Quick-start essentials, simple features | Setup steps, basic usage, common commands |
| B | docs/how/ only | Detailed guides, complex workflows | Architecture, detailed tutorials, troubleshooting |
| C | Hybrid (README + docs/how/) | Features needing both quick-start and depth | Overview in README, detailed guides in docs/how/ |
| D | No new documentation | Internal/trivial changes | Refactoring, minor fixes, internal utilities |

Answer: [A/B/C/D]
Rationale: [1-2 sentences from user]
If C (Hybrid): What goes in README vs docs/how/? [Brief split description]
```

Updates to Spec:
- Add/Update `## Testing Strategy` section with:
  - **Approach**: [Full TDD | TAD | Lightweight | Manual | Hybrid]
  - **Rationale**: [User's reasoning]
  - **Focus Areas**: [What needs thorough testing]
  - **Excluded**: [What doesn't need extensive testing]
  - **Mock Usage**: [Avoid mocks | Targeted mocks | Liberal mocks] + rationale
  - **TAD-Specific** (if TAD selected): Scratch→Promote workflow, Test Doc comment blocks required, promotion heuristic (Critical/Opaque/Regression/Edge)
- Add/Update `## Documentation Strategy` section with:
  - **Location**: [README.md only | docs/how/ only | Hybrid | None]
  - **Rationale**: [User's reasoning]
  - **Content Split** (if Hybrid): [What goes in README vs docs/how/]
  - **Target Audience**: [Who needs this documentation]
  - **Maintenance**: [When/how to update docs]

Rules:
- Only high-impact questions; no solutioning.
- Testing and documentation strategies influence downstream planning.
- Deterministic structure; preserve headings.

Output: Updated SPEC with `## Clarifications` for today + summary table; next = /architect.
```

Next step (when happy): Run **/plan-3-architect** to generate the phase-based plan.
