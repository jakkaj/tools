---
description: Validate plan completeness and execution readiness (read-only) before generating phase tasks.
---

# plan-4-complete-the-plan

Verify the plan's **readiness**: TOC, TDD order, tests-as-docs, **no mocks**, real data, absolute paths, acceptance criteria & rollback, and safe [P] parallelism. Read-only.

```md
---
description: Validate plan completeness & execution readiness (read-only). Do not write tasks or code here.
---

Inputs: PLAN_PATH, SPEC_PATH, rules at docs/rules/rules-idioms.md, optional constitution.

Checks:
- **TOC present**; plan uses absolute paths; no assumed prior context.
- TDD order: tests before implementation, tests as documentation; **no mocks**; use real repo data/fixtures.
- Acceptance criteria & rollback notes per phase.
- [P] only when tasks would touch **different files** (file-safety rule).

Output:
- Status = READY or NOT READY.
- If NOT READY: list concrete remediations (do not apply automatically).
- Next step: `/plan-5-phase-tasks-and-brief` for a chosen phase.
```

This enforces your completion doctrine before any execution begins.
