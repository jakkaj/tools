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
