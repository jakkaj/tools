---
description: Perform planning and architecture, generating a phase-based plan with success criteria while enforcing clarification and constitution gates before implementation.
---

# plan-3-architect

Produce the **plan/design** (phases with acceptance criteria), run **Clarify Gate**, perform **Constitution Check**, lock project structure, and **STOP** before tasks or code.

```md
Inputs: FEATURE_SPEC,
  PLAN_PATH (absolute; MUST match `docs/plans/<ordinal>-<slug>/<slug>-plan.md`),
  rules at `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}`,
  today {{TODAY}}.

GATE - Clarify:
- If critical ambiguities remain in SPEC, instruct running /clarify first (or explicit user override).

GATE - Constitution:
- Validate plan against /memory/constitution.md if present; log deviations:
  | Violation | Why Needed | Simpler Alternative Rejected |

GATE - Architecture:
- Validate against `docs/rules-idioms-architecture/architecture.md`; list layer-boundary or
  GraphBuilder language-agnostic violations with remedies.

Project Type & Structure:
- Select (single | web | mobile); show **actual** directory tree; use absolute repo-root paths thereafter.

Deliverable (write to PLAN_PATH; ensure parent `docs/plans/<ordinal>-<slug>/` exists):
- Title block; **TOC**; Executive Summary; Technical Context; Constitution Check + Deviation ledger; Project Structure;
- **Phases** (numbered): objective, dependencies, risks, **TDD tests to write first**, non-happy-path checks, acceptance criteria;
- Cross-cutting concerns; Complexity tracking (if deviations); Progress checklist with **STOP** rule: *Do not create tasks; hand off to /complete-the-plan*.
- **Change Footnotes Ledger** (empty section ready for Phase 6 updates):
  "During implementation, add footnote tags from task Notes and append details here per `AGENTS.md`."  [link references required]

Style & Rules:
- Conform to `docs/rules-idioms-architecture/{rules.md, idioms.md}` (TDD, tests-as-documentation, **no mocks**, real repo data). :contentReference[oaicite:6]{index=6}
- Include mermaid diagrams if clarifying.
```

The path normalization and "plan before code" gates align with your architect command and rules scaffolding.

Next step (when happy): Run **/plan-4-complete-the-plan** to gate readiness.
