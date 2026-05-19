# SDD Tutorial Completion Summary

> SDD is the practice. HVE Core documents the workflow as RPI: Research -> Plan -> Implement -> Review. This tutorial says RPIV when making the validator layer explicit.

**Learner**: `{learner-slug}`
**Completed**: `{ISO-8601 timestamp}`
**Branch worked on**: `{branch name}`

## Learner Profile

- **Audience**: professional engineer learning SDD/RPIV 101
- **Pacing preference**: `{pacing_preference}`

## Chosen Task

- **Source**: `{byo|sandbox}`
- **Description**: `{Goal / Affected files / Done-when}`
- **Scope category**: green

## Artifacts Produced

| Phase | Artifact | Path | Verified Exists |
|-------|----------|------|-----------------|
| 4 | Research | `{path}` | `{yes|no}` |
| 5 | Plan | `{path}` | `{yes|no}` |
| 5 | Details | `{path}` | `{yes|no}` |
| 5 | Planning log | `{path-or-status}` | `{yes|no|not_produced}` |
| 6 | Changes | `{path}` | `{yes|no}` |
| 6 | Review | `{path}` | `{yes|no}` |

## Artifact Handoffs

- Research -> Plan: `{research_handoff_note}`
- Plan -> Implement: `{plan_handoff_note}`
- Changes -> Review: `{changes_handoff_note}`

## Artifact Insights

| Phase | Artifact | Tutor noticed | Why it matters |
|-------|----------|----------------|----------------|
| Research | `{research_path}` | `{research_insight}` | `{research_insight_why}` |
| Planning | `{plan_path}` | `{planning_insight}` | `{planning_insight_why}` |
| Implementation | `{changes_path}` | `{implementation_insight}` | `{implementation_insight_why}` |
| Review | `{review_path}` | `{review_insight}` | `{review_insight_why}` |

## Optional Next Paths

| Path | When to use it | Command |
|------|----------------|---------|
| Strict RPI/RPIV | You want to practice the phase-by-phase artifact handoff yourself. | `/task-research`, then `/task-plan`, `/task-implement`, `/task-review` |
| Adaptive single-agent RPI | The scope is clear and you want the orchestrator to self-classify. | `/rpi <task>` |
| Continue learning | You want another classroom loop on a fresh small task. | `/sdd-tutorial` |

## Verification Gaps

`{None, or the gap the tutorial recorded.}`

## Rollback Guidance

- Work is on branch `{branch}`.
- To abandon this branch, return to your main branch and delete this feature branch using your team's normal workflow.

## Engineering Fundamentals

| # | Fundamental | Status | Note |
|---|-------------|--------|------|
| 1 | Format | `{honoured|skipped|blocked-by-toolchain|not-applicable}` | `{note}` |
| 2 | Lint | `{...}` | `{...}` |
| 3 | Typecheck | `{...}` | `{...}` |
| 4 | Tests | `{...}` | `{...}` |
| 5 | Diff review | `{...}` | `{...}` |
| 6 | Commit message | `{...}` | `{...}` |
| 7 | Team process / CI | `{learner-reported|not-asked}` | `{note}` |

**Frame for next loop**: SDD's loop ran around your engineering fundamentals, not instead of them.
