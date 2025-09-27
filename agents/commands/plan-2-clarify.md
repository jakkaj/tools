---
description: Resolve high-impact ambiguities (<=5 questions), capture answers in the spec, and update relevant sections immediately.
---

# plan-2-clarify

Ask **<=5** high-impact questions, write answers into the **spec**, and update affected sections immediately.

```md
---
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

User input:

$ARGUMENTS

Flow:
1) Run {SCRIPT}; obtain FEATURE_SPEC (absolute).
2) Scan spec with taxonomy (FRs, NFRs, data model, integrations, UX, edge cases, terminology).
3) Ask ONE question at a time (MC table 2-5 options or short answer <=5 words); cap at 5 total.
4) After each answer: append under `## Clarifications` -> `### Session YYYY-MM-DD`, then update the matching section(s) (FRs/NFRs/data model/stories/edge cases). Save after each edit.
5) Stop when critical ambiguities resolved or cap reached. Emit coverage summary (Resolved/Deferred/Outstanding).

Rules:
- Only high-impact questions; no solutioning.
- Deterministic structure; preserve headings.

Output: Updated SPEC with `## Clarifications` for today + summary table; next = /architect.
```

Next step (when happy): Run **/plan-3-architect** to generate the phase-based plan.
