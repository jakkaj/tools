---
description: Create or update the feature specification from a natural language feature description, focusing on user value (WHAT/WHY) without implementation details.
---

Please deep think / ultrathink as this is a complex task. 

# plan-1-specify

Create or update the feature **spec** from a natural-language description (WHAT/WHY only; no tech choices). Mirrors your templates and script flow.

```md
User input:

$ARGUMENTS

1) Determine the feature slug from user input and create:
   - PLAN_DIR = `docs/plans/<ordinal>-<slug>/` (use next available ordinal)
   - SPEC_FILE = `${PLAN_DIR}/<slug>-spec.md` (spec co-located with plan)
2) Ensure PLAN_DIR exists (create if needed).
3) Load `templates/spec-template.md`; fill sections from the user description; **leave implementation details out**.
4) For unknowns, embed `[NEEDS CLARIFICATION: ...]` markers.
5) Write spec to SPEC_FILE and report branch + path.

Gates:
- Focus on user value; no stack/framework details.
- Mandatory sections present; acceptance scenarios are testable.
- If empty description, ERROR.

Output: SPEC_FILE ready for clarification.
```

Reference template structure and flow come from your `templates/spec-template.md`.

Next step (when happy): Run **/plan-2-clarify** for ≤5 high-impact questions.
