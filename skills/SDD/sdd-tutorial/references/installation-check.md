# Installation Check

The tutorial needs the HVE Core RPI/RPIV flow installed before the hands-on phases can continue.

Official install guide: <https://microsoft.github.io/hve-core/docs/getting-started/install>

## Required commands

- `/task-research`
- `/task-plan`
- `/task-implement`
- `/task-review`

## Expected install surfaces

At least one of these should expose the commands to the learner's chat tool:

- `.github/agents/hve-core/`
- `.github/prompts/hve-core/`
- equivalent user-level agent/prompt locations

## Check

1. Check whether the four required commands resolve.
2. If not, inspect the expected install surfaces.
3. If they are missing, stop before creating tutorial state.

## Missing-command response

> HVE Core RPI/RPIV is not installed or not visible in this environment yet.
>
> Install/check guide: <https://microsoft.github.io/hve-core/docs/getting-started/install>
>
> Required commands before this tutorial can continue: `/task-research`, `/task-plan`, `/task-implement`, `/task-review`.
>
> Expected install surfaces: `.github/agents/hve-core/`, `.github/prompts/hve-core/`, or equivalent user-level agent/prompt locations exposed by your chat tool.
>
> I don't see those in this repo right now, so no tutorial state was created. Once the four commands resolve, rerun `/sdd-tutorial`.
