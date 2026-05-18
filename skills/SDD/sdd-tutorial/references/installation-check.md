# Installation Check

The tutorial needs the HVE Core RPI/RPIV flow installed before the hands-on phases can continue.

Preferred local recovery skill: `install-hve-core-rpiv`

Official HVE Core install guide: <https://microsoft.github.io/hve-core/docs/getting-started/install>

## Required commands

- `/task-research`
- `/task-plan`
- `/task-implement`
- `/task-review`

## Expected install surfaces

At least one of these should expose the commands to the learner's chat tool:

- `.github/agents/hve-core/`
- `.github/prompts/hve-core/`
- `.agents/skills/task-research/`, `.agents/skills/task-plan/`, `.agents/skills/task-implement/`, `.agents/skills/task-review/`
- `.pi/skills/task-research/`, `.pi/skills/task-plan/`, `.pi/skills/task-implement/`, `.pi/skills/task-review/`
- equivalent user-level agent/prompt locations

## Check

1. Check whether the four required commands resolve.
2. If not, inspect the expected install surfaces.
3. If they are missing, stop before creating tutorial state.
4. Run or hand off to `install-hve-core-rpiv` when that skill is available.
5. After the installer succeeds, rerun or resume RPIV command preflight before creating tutorial state.

## Missing-command response

> HVE Core RPI/RPIV is not installed or not visible in this environment yet.
>
> I will run or hand off to `install-hve-core-rpiv` to install local skill-shaped RPIV commands from the current authoritative HVE Core source. No tutorial state has been created yet.
>
> Required commands before this tutorial can continue: `/task-research`, `/task-plan`, `/task-implement`, `/task-review`.
>
> Expected install surfaces: `.github/agents/hve-core/`, `.github/prompts/hve-core/`, `.agents/skills/task-*`, `.pi/skills/task-*`, or equivalent user-level locations exposed by your chat tool.
>
> After installation succeeds, I will rerun or resume preflight before creating tutorial state.

## Installer unavailable or failed

If `install-hve-core-rpiv` is unavailable or cannot complete:

> I could not complete the local RPIV skill install, so the tutorial is still blocked and no tutorial state was created.
>
> You can install HVE Core through the official guide instead: <https://microsoft.github.io/hve-core/docs/getting-started/install>
>
> Once `/task-research`, `/task-plan`, `/task-implement`, and `/task-review` resolve in this chat tool, rerun `/sdd-tutorial`.
