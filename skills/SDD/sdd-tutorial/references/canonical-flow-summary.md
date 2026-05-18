# Canonical Flow Summary

This summary aligns the tutorial with HVE Core's Docusaurus docs under `docs/rpi/`.

HVE Core names the workflow **RPI**. The tutorial may say **RPIV** only when making the validator layer visible.

## Learner-visible loop

```text
Uncertainty -> Knowledge -> Strategy -> Working Code -> Validated Code
```

The learner types:

1. `/task-research <topic>`
2. `/task-plan <research-path>` or `/task-plan` with the research file open
3. `/task-implement`
4. `/task-review` or `/task-review <scope>`

Between every phase: carry the artifact forward by opening it or explicitly referencing its path in the next command.

## Artifact chain

| Phase | Artifact |
|-------|----------|
| Research | `.copilot-tracking/research/<date>-<topic>-research.md` |
| Plan | `.copilot-tracking/plans/<topic>-plan.instructions.md` |
| Plan details | `.copilot-tracking/details/<topic>-details.md` |
| Implement | `.copilot-tracking/changes/<date>-<topic>-changes.md` plus code changes |
| Review | `.copilot-tracking/reviews/<date>-<topic>-review.md` |

## Validator layer

- V#1: `plan-validator` inside Plan.
- V#2: `rpi-validator` inside Review.
- V#3: `implementation-validator` inside Review.

The tutorial explains validators but never invokes them directly.

## HVE Core details the tutorial should reflect

- Research is constrained not to implement; this makes it optimize for verified truth with file/line evidence.
- Plan validates that research exists, creates coordinated plan + details files, and acts as the implementation contract.
- Implement follows the plan and supports stop controls; prefer phase-stop review during teaching.
- Review validates against research, plan, and changes; Critical/Major findings should route back to Implement, Research, or Plan before completion.
- Handoff buttons and Save/checkpoint are useful UI/session aids, but the tutorial's core path remains explicit slash commands plus artifact handoffs.
