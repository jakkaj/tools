---
description: Assess plan completeness before execution; offers an optional readiness gate.
---

Please deep think / ultrathink as this is a complex task. 

# plan-4-complete-the-plan

Verify the plan's **readiness**: TOC, TDD order, tests-as-docs, **no mocks**, real data, absolute paths, acceptance criteria & rollback, and safe [P] parallelism. This command stays read-only and provides a recommendation—teams may proceed once the plan is READY **or** after explicitly accepting any gaps.

```md
Inputs: PLAN_PATH, SPEC_PATH (co-located as `<plan-dir>/<slug>-spec.md>`), rules at `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}`, optional constitution.

Checks:
- **TOC present**; plan uses absolute paths; no assumed prior context.
- TDD order: tests before implementation, tests as documentation; **no mocks**; use real repo data/fixtures.
- Acceptance criteria per phase.
- [P] only when tasks would touch **different files** (file-safety rule).

Output:
- Status = READY, NOT READY, or NOT READY (USER OVERRIDE).
- If NOT READY: list concrete remediations (do not apply automatically).
- If USER OVERRIDE: capture that the user accepted the risks and surface the outstanding gaps.
- Next step (when happy): Run **/plan-5-phase-tasks-and-brief** for the chosen phase.
```

**Override guidance**: When the audit flags issues, present the findings and confirm whether the user wants to continue despite them. If they approve an override, note their acceptance, respect the documented risks, and proceed to `/plan-5-phase-tasks-and-brief`.

This supports your completion doctrine while letting you tailor the rigor to the project's stakes.

Next step (when happy): Run **/plan-5-phase-tasks-and-brief** once the plan is READY or the user has accepted the gaps.
