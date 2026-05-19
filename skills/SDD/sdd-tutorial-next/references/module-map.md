# SDD Tutorial Module Map

Use these modules for the classroom flow. The module is derived from `state.yaml`; do not persist a second module field as a competing source of truth.

| Module | State signal | Purpose | Work-terminal command |
|--------|--------------|---------|-----------------------|
| 1. Project setup | `progress.current_phase` is `preflight`, `0`, `1`, or `2` | Establish safety, tutor stance, glossary, and the two-terminal classroom/work pattern. | None |
| 2. Task selection + Research | `progress.current_phase` is `3` or `4`, or pending work phase is `research` | Choose a small real task, then turn uncertainty into repo-grounded knowledge and shared human/agent alignment. | `/task-research <topic>` |
| 3. Planning | pending work phase is `plan` | Convert research into an implementation contract, strategy, details, and validation expectations. | `/task-plan <research-path>` |
| 4. Implementation | pending work phase is `implement` | Execute the plan into working code and a concrete changes artifact while preserving the implementation contract. | `/task-implement` |
| 5. Review + handoff | pending work phase is `review` or `progress.current_phase` is `7` | Validate code against research, plan, and diff evidence; route rework or complete the lesson. | `/task-review` |

## Phase value prompts

Use one of these one-sentence explanations after a phase completes:

- **Research**: Research is context engineering plus alignment: it collects repo evidence and gives the human a chance to confirm what problem we are really solving before strategy or code.
- **Plan**: Plan turns evidence into a strategy and implementation contract, so Implement can follow a checked path instead of improvising.
- **Implement**: Implement converts the plan into a diff and changes artifact, making the abstract strategy inspectable in real code.
- **Review**: Review is the validation layer: it checks code against research, plan, and implementation quality, then routes rework to the right earlier phase when needed.

## Classroom rule

The classroom terminal gives exactly one next work-terminal command, then stops. The learner runs the command in a second terminal. When it finishes, they return to the classroom terminal and run `/sdd-tutorial-next`.
