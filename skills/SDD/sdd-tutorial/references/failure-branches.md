# Failure Branches

The live skill handles these branches inline.

| ID | Condition | Response |
|----|-----------|----------|
| F-01 | Slash command unavailable | Refuse, point to `installation-check.md`, do not create state. |
| F-02 | RPI agent run fails or is interrupted | Ask for the error/output tail with concrete choices: `retry`, `paste error`, `narrow scope`, or `pause`. |
| F-03 | Artifact missing after dispatch | Offer concrete choices: `not run yet`, `failed`, `finished: <path>`, or `help me find it`. |
| F-04 | Repeated red or over-scoped task | Offer `scratch/chalk-prime-cli/` as the recommended safe toy scenario, plus `try another real task` or `pause`. |
| F-05 | No tests or run command exists | Explain the verification gap and offer concrete choices: `manual check`, `artifact-only with warning`, or `choose a task with tests`. |
| F-06 | Dirty git state before or during tutorial | Pause with teacherly copy: explain that SDD can continue if the changes are intentional, ask for explicit acknowledgement, or suggest commit/stash/discard before rerun. Do not create state until clean or acknowledged. |
| F-07 | Learner says "just do it for me" | Keep learner in control and offer two concrete paths: `give me the next command only` or `walk me through why`. |
| F-08 | Learner disappears mid-phase | On resume, detect stale timestamp, summarize where they were, and give the exact next command or choices. |
| F-09 | Resume state points to missing files | Offer concrete choices: `re-run last command`, `paste new path`, `continue with warning`, or `start fresh`. |
| F-10 | Protected branch | Block and offer `git checkout -b sdd-tutorial-workshop`, or let the learner choose a branch name. |
| F-11 | Red task category | Refuse the unsafe task, explain why in one sentence, then offer `narrow it`, `use scratch/chalk-prime-cli/`, or `pause`; logging only with consent. |
