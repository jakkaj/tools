# Preflight Checklist

The tutorial starts with a visible orientation turn, then runs checks. State is not written until all gating checks pass.

## Opening turn

> Welcome to `/sdd-tutorial`. I'll guide this like a classroom exercise: first a quick orientation, then safety checks for the repo, RPIV commands, branch, working tree, task category, and verification path. If those pass, we'll pick a small real task and work through Research, Plan, Implement, and Review together on your branch; you stay in control, and you do not have to push or merge anything to main.

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

## Learner folder copy

Use this after gating checks pass, before creating local tutorial state.

> Good news: the repo, RPIV commands, branch, and working tree all look ready. Before we start the lesson, I need one small local label for your tutorial progress folder under `.copilot-tracking/sdd-tutorial/`.
>
> I suggest `<suggested-slug>` because it matches this branch. You can press Enter to use that, or type another short label like `jordan-rpiv`, `workshop-run`, or `first-sdd-loop`.

Slug guidance:

- Suggest the current branch slug first when it is safe and readable.
- Otherwise suggest the repo slug.
- If neither is safe/readable, suggest `sdd-tutorial`.
- Accept blank, "yes", "use that", or similar confirmation as approval of the suggested slug.
- Normalize the final slug to lowercase kebab-case.
- Do not expose this as a storage-schema question; frame it as saving lesson progress locally.

## Slash-command failure copy

> I can't see the RPIV task skills yet, so the hands-on lesson would get stuck before Research.
>
> The next useful move is to run or hand off to `install-hve-core-rpiv`, which installs local skill-shaped RPIV commands from the current authoritative HVE Core source. No tutorial state has been created yet.
>
> Required commands before this tutorial can continue: `/task-research`, `/task-plan`, `/task-implement`, `/task-review`.
>
> Expected install surfaces: `.github/agents/hve-core/`, `.github/prompts/hve-core/`, `.agents/skills/task-*`, `.pi/skills/task-*`, or equivalent user-level locations exposed by your chat tool.
>
> After installation succeeds, restart or reload your coding agent so it discovers the new skills, then rerun `/sdd-tutorial`. If installer recovery fails, use <https://microsoft.github.io/hve-core/docs/getting-started/install> and rerun `/sdd-tutorial` once the commands resolve.
