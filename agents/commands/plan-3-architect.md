---
description: Perform planning and architecture, generating a phase-based plan with success criteria while enforcing clarification and constitution gates before implementation.
---

# plan-3-architect

Produce the **plan/design** (phases with acceptance criteria), run **Clarify Gate**, perform **Constitution Check**, lock project structure, and **STOP** before tasks or code.

```md
---
description: Planning & architecture. Create a single phase-based plan with success criteria; stop before tasks or implementation.
---

Inputs: FEATURE_SPEC, PLAN_PATH (absolute), rules at docs/rules/rules-idioms.md, today {{TODAY}}.

GATE - Clarify:
- If critical ambiguities remain in SPEC, instruct running /clarify first (or explicit user override).

GATE - Constitution:
- Validate plan against /memory/constitution.md if present; log deviations:
  | Violation | Why Needed | Simpler Alternative Rejected |

Project Type & Structure:
- Select (single | web | mobile); show **actual** directory tree; use absolute repo-root paths thereafter.

Deliverable (write to PLAN_PATH):
- Title block; **TOC**; Executive Summary; Technical Context; Constitution Check + Deviation ledger; Project Structure;
- **Phases** (numbered): objective, dependencies, risks, **TDD tests to write first**, non-happy-path checks, acceptance criteria;
- Cross-cutting concerns; Complexity tracking (if deviations); Progress checklist with **STOP** rule: *Do not create tasks; hand off to /complete-the-plan*.

Style & Rules:
- Conform to docs/rules/rules-idioms.md (TDD, tests-as-documentation, **no mocks**, real repo data). :contentReference[oaicite:6]{index=6}
- Include mermaid diagrams if clarifying.
```

The path normalization and "plan before code" gates align with your architect command and rules scaffolding.
