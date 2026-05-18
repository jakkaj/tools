# Preflight Checklist

The tutorial starts with a visible orientation turn, then runs checks. State is not written until all gating checks pass and the learner confirms the Phase 3 task micro-spec.

## Opening turn

> Welcome to `/sdd-tutorial`. I'll guide this like a classroom exercise: first a quick orientation, then safety checks for the repo, RPIV commands, branch, working tree, task category, and verification path. If those pass, we'll pick a small real task and work through Research, Plan, Implement, and Review together on your branch; you stay in control, and you do not have to push or merge anything to main.

## Checks

| # | Check | Required | Result |
|---|-------|----------|--------|
| 1 | Workspace open | Yes | Refuse if no repo/workspace is visible. |
| 2 | RPIV and tutorial-continuation commands available | Yes | Refuse if `/task-research`, `/task-plan`, `/task-implement`, `/task-review`, or `/sdd-tutorial-next` are unavailable. |
| 3 | Branch safety | Yes | Refuse on `main`, `master`, `production`, `prod`, or `release/*`. |
| 4 | Working-tree state | Yes | Continue only if clean or learner acknowledges intentional dirty state. |
| 5 | Task-category screen | Warn | Warn that red-category tasks will be refused. |
| 6 | Verification path | Warn | Warn if no test, run command, or manual check is available. |

## Protected branch copy

> You're on `<branch>` — that's a protected branch in most teams' workflow, and SDD will produce code changes I shouldn't risk landing there. Easiest fix: branch off it. Want to run `git checkout -b sdd-tutorial-workshop` now, or pick your own branch name?

## Dirty working tree copy

> I see existing changes in the working tree. SDD can still continue if those are intentional, but I don't want to mix tutorial work into someone else's edits.
>
> If these changes are yours and safe to keep while we practice, say "these are intentional". Otherwise, commit, stash, or discard them first, then rerun `/sdd-tutorial`. I won't create tutorial state until this is clear.

## Preflight pass copy

Use this after gating checks pass. Do not ask for the learner slug or create local tutorial state yet; the label is chosen after the learner confirms the problem. Describe the working-tree result accurately: say "working tree is clean" only when it is clean; if dirty changes were acknowledged, say "working tree changes are acknowledged as intentional."

> Good news: the repo is open, RPIV is available, you're on a safe branch, and the working tree is clean. I won't ask for the progress-folder label yet; it will be more meaningful once we pick the problem, so we can name it after what you're actually working on. Next we'll do a quick pacing calibration.
>
> If dirty changes were acknowledged, replace "working tree is clean" with "working tree changes are acknowledged as intentional."

## Learner folder copy

Use this after the learner confirms the Phase 3 micro-spec, before creating local tutorial state.

> Now we have the problem: `<short task summary>`. This is the right moment to name your local progress folder because the label can match what you're learning on.
>
> I suggest `<task-derived-slug>`. Press Enter to use that, or type another short label like `rpiv-docs-fix`, `first-sdd-loop`, or `workshop-task`.

Slug guidance:

- Suggest a slug derived from the confirmed task topic first.
- Otherwise suggest the current branch slug when it is safe and readable.
- Otherwise suggest the repo slug.
- If none are safe/readable, suggest `sdd-tutorial`.
- Accept blank, "yes", "use that", or similar confirmation as approval of the suggested slug.
- Normalize the final slug to lowercase kebab-case.
- Do not expose this as a storage-schema question; frame it as saving lesson progress locally.

## Slash-command failure copy

> I can't see the RPIV task skills or `/sdd-tutorial-next` yet, so the hands-on lesson would get stuck before Research or the first classroom return.
>
> The next useful move is to install the missing local skills. If RPIV task skills are missing, run or hand off to `install-hve-core-rpiv`; if `/sdd-tutorial-next` is missing in this repo, run `just install-agent-skills`. No tutorial state has been created yet.
>
> Required commands before this tutorial can continue: `/task-research`, `/task-plan`, `/task-implement`, `/task-review`, and `/sdd-tutorial-next`.
>
> Expected install surfaces: `.github/agents/hve-core/`, `.github/prompts/hve-core/`, `.agents/skills/task-*`, `.agents/skills/sdd-tutorial-next`, `.pi/skills/task-*`, or equivalent user-level locations exposed by your chat tool.
>
> After installation succeeds, restart or reload your coding agent so it discovers the new skills, then rerun `/sdd-tutorial`. If installer recovery fails, use <https://microsoft.github.io/hve-core/docs/getting-started/install> and rerun `/sdd-tutorial` once the commands resolve.
