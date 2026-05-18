# Preflight Checklist

The tutorial starts with a visible orientation turn, then runs checks. State is not written until all gating checks pass.

## Opening turn

> Welcome to `/sdd-tutorial`. First I'll orient you, then I'll run a few quick safety checks: workspace, RPIV command availability, branch, working tree, task category, and verification path. If those pass, we'll calibrate pacing, pick a small real task, then work through Research, Plan, Implement, and Review together on your branch; you do not have to push or merge anything to main.

## Checks

| # | Check | Required | Result |
|---|-------|----------|--------|
| 1 | Workspace open | Yes | Refuse if no repo/workspace is visible. |
| 2 | RPIV commands available | Yes | Refuse if `/task-research`, `/task-plan`, `/task-implement`, or `/task-review` are unavailable. |
| 3 | Branch safety | Yes | Refuse on `main`, `master`, `production`, `prod`, or `release/*`. |
| 4 | Working-tree state | Yes | Continue only if clean or learner acknowledges intentional dirty state. |
| 5 | Task-category screen | Warn | Warn that red-category tasks will be refused. |
| 6 | Verification path | Warn | Warn if no test, run command, or manual check is available. |

## Protected branch copy

> You're on `<branch>` — that's a protected branch in most teams' workflow, and SDD will produce code changes I shouldn't risk landing there. Easiest fix: branch off it. Want to run `git checkout -b sdd-tutorial-<learner-slug>` now, or pick your own branch name?

## Slash-command failure copy

> HVE Core RPI/RPIV is not installed or not visible in this environment yet.
>
> I will run or hand off to `install-hve-core-rpiv` to install local skill-shaped RPIV commands from the current authoritative HVE Core source. No tutorial state has been created yet.
>
> Required commands before this tutorial can continue: `/task-research`, `/task-plan`, `/task-implement`, `/task-review`.
>
> Expected install surfaces: `.github/agents/hve-core/`, `.github/prompts/hve-core/`, `.agents/skills/task-*`, `.pi/skills/task-*`, or equivalent user-level locations exposed by your chat tool.
>
> After installation succeeds, I will rerun or resume preflight before creating tutorial state. If installer recovery fails, use <https://microsoft.github.io/hve-core/docs/getting-started/install> and rerun `/sdd-tutorial` once the commands resolve.
