# SDD Tutorial Lesson Plan

> SDD is the practice. HVE Core documents the workflow as RPI: Research -> Plan -> Implement -> Review. This tutorial says RPIV when making the validator layer explicit.

<!-- TUTORIAL-MANAGED -->
## Current State

- Learner slug: `{learner-slug}`
- Current phase: `{current_phase}`
- Current module: `{derived_module}`
- Branch: `{branch}`
- Audience: professional engineer learning SDD/RPIV 101
- Pacing: `{pacing_preference}`
- Pending work-terminal command: `{pending_work_terminal_command}`
- Last classroom checkpoint: `{last_classroom_checkpoint_at}`

## Classroom / Work Terminal Pattern

- **Classroom terminal**: `/sdd-tutorial` and `/sdd-tutorial-next` explain, update this lesson plan, and give one next command.
- **Work terminal**: `/task-research`, `/task-plan`, `/task-implement`, and `/task-review` do the RPIV work.
- After each work-terminal command finishes, return to the classroom terminal and run `/sdd-tutorial-next`.
- Review this file after each classroom step: the learning guide shows what each phase is teaching, and the artifact insights show concrete things the tutor noticed in your own artifacts.

## Module Map

| Module | Status | Purpose | Artifact |
|--------|--------|---------|----------|
| 1. Project setup | `{status}` | Safety, tutor stance, glossary, two-terminal pattern | Preflight + lesson state |
| 2. Task selection + Research | `{status}` | Turn a small real task into repo-grounded knowledge and alignment | Micro-spec + research artifact |
| 3. Planning | `{status}` | Convert research into strategy and implementation contract | Plan + details artifacts |
| 4. Implementation | `{status}` | Execute the plan into a concrete diff | Changes artifact + code diff |
| 5. Review + handoff | `{status}` | Validate against evidence and route rework or completion | Review artifact + completion summary |
<!-- /TUTORIAL-MANAGED -->

<!-- TUTORIAL-MANAGED -->
## Module Learning Guide

Use this section as the syllabus map. The module map says where you are; this guide says what each step is teaching you.

| Module | What this teaches | What to inspect |
|--------|-------------------|-----------------|
| 1. Project setup | How the classroom/work-terminal split keeps the lesson safe and learner-controlled. | Branch, working tree state, RPIV command availability, lesson state path. |
| 2. Task selection + Research | Research is context engineering and alignment before strategy or code. | Research artifact: relevant files, constraints/risks/questions, recommended task framing. |
| 3. Planning | Plan turns evidence into an implementation contract. | Plan/details artifacts: implementation steps, validation approach, assumptions/boundaries. |
| 4. Implementation | Implement follows the plan into an inspectable diff. | Git diff/status, changes artifact, tests/checks run or skipped. |
| 5. Review + handoff | Review validates the chain and routes completion or rework. | Review artifact: verdict, major findings, rework target phase if any. |
<!-- /TUTORIAL-MANAGED -->

<!-- LEARNER-OWNED -->
## My Notes

Add your own notes here. The tutorial must preserve this section verbatim.
<!-- /LEARNER-OWNED -->

<!-- TUTORIAL-MANAGED -->
## Artifact Paths

| Artifact | Path | Verified |
|----------|------|----------|
| Research | `{research_path}` | `{verified}` |
| Plan | `{plan_path}` | `{verified}` |
| Details | `{details_path}` | `{verified}` |
| Planning log | `{planning_log_path}` | `{verified_or_status}` |
| Changes | `{changes_path}` | `{verified}` |
| Review | `{review_path}` | `{verified}` |

Planning log status uses `worked_task.plan_validator_log.status` such as `not_yet_attempted`, `passed`, or `failed`; other `Verified` values are booleans.
<!-- /TUTORIAL-MANAGED -->

<!-- TUTORIAL-MANAGED -->
## Artifact Insights

| Phase | Artifact | Tutor noticed | Why it matters |
|-------|----------|----------------|----------------|
| Research | `{research_path}` | `{research_insight}` | `{research_insight_why}` |
| Planning | `{plan_path}` | `{planning_insight}` | `{planning_insight_why}` |
| Implementation | `{changes_path}` | `{implementation_insight}` | `{implementation_insight_why}` |
| Review | `{review_path}` | `{review_insight}` | `{review_insight_why}` |
<!-- /TUTORIAL-MANAGED -->

<!-- LEARNER-OWNED -->
## Learner Notes

Use this section however you like. The tutor will not overwrite it.
<!-- /LEARNER-OWNED -->
