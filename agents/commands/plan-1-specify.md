---
description: Create or update the feature specification from a natural language feature description, focusing on user value (WHAT/WHY) without implementation details.
---

Please deep think / ultrathink as this is a complex task. 

# plan-1-specify

Create or update the feature **spec** from a natural-language description (WHAT/WHY only; no tech choices). Follow the canonical spec structure described below.

```md
User input:

$ARGUMENTS

1) Determine the feature slug from user input and create:
   - PLAN_DIR = `docs/plans/<ordinal>-<slug>/` (use next available ordinal)
   - SPEC_FILE = `${PLAN_DIR}/<slug>-spec.md` (spec co-located with plan)
2) Ensure PLAN_DIR exists (create if needed).
3) Populate SPEC_FILE with these sections (use Markdown headings):
   - `# <Feature Title>`
   - `## Summary` – short WHAT/WHY overview
   - `## Goals` – bullet list of desired outcomes/user value
   - `## Non-Goals` – explicitly out-of-scope behavior
   - `## Complexity` – initial complexity assessment using CS 1-5 system:
     * **Score**: CS-{1|2|3|4|5} ({trivial|small|medium|large|epic})
     * **Breakdown**: S={0-2}, I={0-2}, D={0-2}, N={0-2}, F={0-2}, T={0-2}
     * **Confidence**: {0.00-1.00} (agent's confidence in the score)
     * **Assumptions**: [list of assumptions made during scoring]
     * **Dependencies**: [external dependencies or blockers]
     * **Risks**: [complexity-related risks]
     * **Phases**: [suggested high-level phases; for CS ≥ 4 must include flags + rollout + rollback]

     Use the CS rubric from constitution:
     - Surface Area (S): Files/modules touched (0=one, 1=multiple, 2=many/cross-cutting)
     - Integration (I): External deps (0=internal, 1=one external, 2=multiple/unstable)
     - Data/State (D): Schema/migrations (0=none, 1=minor, 2=non-trivial)
     - Novelty (N): Req clarity (0=well-specified, 1=some ambiguity, 2=unclear/discovery)
     - Non-Functional (F): Perf/security/compliance (0=standard, 1=moderate, 2=strict)
     - Testing/Rollout (T): Test depth/staging (0=unit only, 1=integration, 2=flags/staged)

     Total P = S+I+D+N+F+T → CS mapping: 0-2=CS-1, 3-4=CS-2, 5-7=CS-3, 8-9=CS-4, 10-12=CS-5
   - `## Acceptance Criteria` – numbered, testable scenarios framed as observable outcomes
   - `## Risks & Assumptions`
   - `## Open Questions`
   - `## ADR Seeds (Optional)` – capture decision context without solutioning:
     * Decision Drivers: [constraints/NFRs that push an architectural choice]
     * Candidate Alternatives: [A, B, C (one-line summaries)]
     * Stakeholders: [roles/names if known]
   If `templates/spec-template.md` exists, you may reference it for wording, but this command must succeed without it.
4) For unknowns, embed `[NEEDS CLARIFICATION: ...]` markers within the appropriate section.
5) Write spec to SPEC_FILE and report branch + path.

Gates:
- Focus on user value; no stack/framework details.
- Mandatory sections present; acceptance scenarios are testable.
- If empty description, ERROR.

Output: SPEC_FILE ready for clarification.
```

The section order above defines the canonical spec structure referenced by downstream planning phases.

Next step (when happy): Run **/plan-2-clarify** for ≤5 high-impact questions.
