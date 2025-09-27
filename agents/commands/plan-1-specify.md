---
description: Create or update the feature specification from a natural language feature description, focusing on user value (WHAT/WHY) without implementation details.
---

# plan-1-specify

Create or update the feature **spec** from a natural-language description (WHAT/WHY only; no tech choices). Mirrors your templates and script flow.

```md
---
scripts:
  sh: scripts/bash/create-new-feature.sh --json "{ARGS}"
  ps: scripts/powershell/create-new-feature.ps1 -Json "{ARGS}"
---

User input:

$ARGUMENTS

1) Run {SCRIPT} once from repo root; parse JSON for BRANCH_NAME and SPEC_FILE (absolute paths only).
2) Load `templates/spec-template.md`; fill sections from the user description; **leave implementation details out**.
3) For unknowns, embed `[NEEDS CLARIFICATION: ...]` markers.
4) Write spec to SPEC_FILE and report branch + path.

Gates:
- Focus on user value; no stack/framework details.
- Mandatory sections present; acceptance scenarios are testable.
- If empty description, ERROR.

Output: SPEC_FILE ready for clarification.
```

Reference template structure and flow come from your `templates/spec-template.md`.

Next step (when happy): Run **/plan-2-clarify** for ≤5 high-impact questions.
