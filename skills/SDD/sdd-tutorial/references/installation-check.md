# Installation Check

The tutorial needs the HVE Core RPI/RPIV flow installed before the hands-on phases can continue.

Preferred local recovery skill: `install-hve-core-rpiv`

Official HVE Core install guide: <https://microsoft.github.io/hve-core/docs/getting-started/install>

## Required commands

- `/task-research`
- `/task-plan`
- `/task-implement`
- `/task-review`
- `/sdd-tutorial-next`

## Expected install surfaces

At least one of these should expose the commands to the learner's chat tool:

- `.github/agents/hve-core/`
- `.github/prompts/hve-core/`
- `.agents/skills/task-research/`, `.agents/skills/task-plan/`, `.agents/skills/task-implement/`, `.agents/skills/task-review/`, `.agents/skills/sdd-tutorial-next/`
- `.pi/skills/task-research/`, `.pi/skills/task-plan/`, `.pi/skills/task-implement/`, `.pi/skills/task-review/`
- equivalent user-level agent/prompt locations

## Check

1. Check whether the five required commands resolve.
2. If RPIV task commands are missing, inspect the expected HVE Core install surfaces.
3. If a repo-local `just install-agent-skills` recipe exists, inspect the recipe name/intent and run `just install-agent-skills` yourself before asking the learner to do anything. This is setup recovery, not RPIV work-terminal execution.
4. After the just recipe finishes, re-check the five required commands.
5. If required commands are still missing, stop before creating tutorial state.
6. Run or hand off to `install-hve-core-rpiv` when RPIV task skills are still missing and that installer skill is available.
7. After installation succeeds, rerun or resume command preflight before creating tutorial state.

## Missing-command response

> HVE Core RPI/RPIV is not installed or not visible in this environment yet.
>
> I will try the repo-local setup recovery first: if `just install-agent-skills` exists here, I will run it now and re-check the required commands. If RPIV task skills are still missing after that, I will run or hand off to `install-hve-core-rpiv` to install local skill-shaped RPIV commands from the current authoritative HVE Core source. No tutorial state has been created yet.
>
> Required commands before this tutorial can continue: `/task-research`, `/task-plan`, `/task-implement`, `/task-review`, and `/sdd-tutorial-next`.
>
> Expected install surfaces: `.github/agents/hve-core/`, `.github/prompts/hve-core/`, `.agents/skills/task-*`, `.agents/skills/sdd-tutorial-next`, `.pi/skills/task-*`, or equivalent user-level locations exposed by your chat tool.
>
> After installation succeeds, I will rerun or resume preflight before creating tutorial state.

## Installer unavailable or failed

If `install-hve-core-rpiv` is unavailable or cannot complete:

> I could not complete the local RPIV skill install, so the tutorial is still blocked and no tutorial state was created.
>
> You can install HVE Core through the official guide instead: <https://microsoft.github.io/hve-core/docs/getting-started/install>
>
> Once `/task-research`, `/task-plan`, `/task-implement`, `/task-review`, and `/sdd-tutorial-next` resolve in this chat tool, rerun `/sdd-tutorial`.
