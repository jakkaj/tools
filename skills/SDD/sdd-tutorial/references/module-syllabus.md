# SDD Tutorial Module Syllabus

Use this syllabus to teach the RPIV loop. The tutor is not a command dispatcher: every phase boundary should help the learner understand what just happened, how to read the artifact, and why the next phase exists.

Keep the classroom rule: one question or one work-terminal command per turn, not both.

## Teaching handoff pattern

Use a two-turn pattern at phase boundaries:

1. **Debrief + inspect + reflect** after a work-terminal artifact is discovered.
   - Debrief what the completed phase was for in 2-4 practical sentences.
   - Point the learner at 2-3 concrete parts of the artifact to skim now.
   - Ask the module reflection/self-assessment question and stop.
2. **Connect + command** after the learner answers or says `skip`.
   - Connect the completed phase to the next phase in 2-3 practical sentences.
   - Give exactly one next work-terminal command and stop.

Do not explain future paste instructions or ask the learner to remember later steps. The next `/sdd-tutorial-next` invocation teaches the next artifact when it exists.

## Module 1 — Project setup

**Learning objective**: The learner understands that the tutorial has two workspaces: the classroom terminal for guidance and the work terminal for RPIV commands.

**Teach**: Setup is about safety and orientation. We confirm the branch, working tree, RPIV commands, and lesson state before code so the learner can practice without accidentally shipping or mixing work.

**Learner should notice**:

- Which branch they are on.
- Whether the working tree is clean or intentionally dirty.
- Where the local lesson state and lesson plan will live.

## Module 2 — Task selection + Research

**Learning objective**: The learner understands Research as context engineering and alignment, not pre-coding.

**Before Research command**:

- Explain that Research turns a vague task into repo-grounded evidence.
- Tell the learner that good Research should identify relevant files, constraints, risks, and questions.
- Emphasize that no implementation happens yet.

**After Research artifact exists — debrief + inspect**:

- Research is the evidence base for the rest of the loop. Its value is not just "a file exists"; it gives the human and agent a shared picture of the repo before strategy or code.
- Ask the learner to open the research artifact and skim:
  - Relevant files or entry points it found.
  - Constraints, risks, or open questions.
  - The recommended slice or next-step framing.

**Reflection prompt**: What did Research clarify or change about the task? Reply with one sentence, `skip` to keep moving, or `show example` if you want a model answer first.

**Connect to Plan after reflection**:

- Planning is where the research stops being background reading and becomes an implementation contract.
- The plan should use the research artifact as evidence for what to change, what not to touch, and how to verify the result.
- The learner should keep the research artifact open or pass its path to Plan so the planner is anchored to evidence.

## Module 3 — Planning

**Learning objective**: The learner understands Plan as the strategy and contract that keeps Implement from improvising.

**After Plan/details artifacts exist — debrief + inspect**:

- Plan converts evidence into a buildable route. It should describe the intended change, the order of work, the files involved, validation, and the risks that need attention.
- Ask the learner to open the plan/details artifacts and skim:
  - The implementation steps and whether they follow the research.
  - The acceptance/validation approach.
  - Any risks, assumptions, or "do not touch" boundaries.

**Reflection prompt**: What part of the plan feels most important to keep the implementor honest? Reply with one sentence, `skip` to keep moving, or `show example` if you want a model answer first.

**Connect to Implement after reflection**:

- Implement is the first phase where code should change. It should follow the plan rather than inventing a new strategy mid-flight.
- The plan is the guardrail: if implementation needs to diverge, that is a signal to explain the divergence or loop back.
- The learner should keep the plan visible while running Implement.

## Module 4 — Implementation

**Learning objective**: The learner understands Implementation as plan execution plus an inspectable changes artifact.

**After changes artifact/diff exists — debrief + inspect**:

- Implement turns the plan into a concrete diff. The educational value is seeing whether the code change actually follows the strategy, not just whether files changed.
- Ask the learner to skim:
  - The changed files in `git status` or the diff.
  - The changes artifact summary.
  - Any tests/checks that were run or skipped.

**Reflection prompt**: What risk, question, or surprise did you notice in the diff? Reply with one sentence, `skip` to keep moving, or `show example` if you want a model answer first.

**Connect to Review after reflection**:

- Review is the validation layer. It checks the implementation against the research, plan, and actual diff so the loop can catch gaps before the learner trusts the result.
- This is where SDD becomes safer than "agent wrote code and we hoped"; the review can route back to Research, Plan, or Implement with evidence.
- The learner should keep the research, plan, and changes artifacts handy for Review.

## Module 5 — Review + reflection

**Learning objective**: The learner understands Review as validation and routing, not a ceremonial final step.

**After review artifact exists — debrief + inspect**:

- Review decides whether the loop is complete or whether evidence says we should repair an earlier phase.
- Ask the learner to skim:
  - The verdict/status.
  - Any critical or major findings.
  - Which phase the review says should handle rework, if any.

**If Review is complete**:

- Explain that the loop has produced evidence, strategy, code, and validation.
- Ask the final reflection question with `show example` and `skip reflection` affordances.

**If Review needs rework**:

- Explain that looping is success, not failure: the validator found the cheapest place to repair the chain.
- Connect the specific review outcome to the next command:
  - `needs_rework`: Implement repairs the diff against review evidence.
  - `research_gap`: Research repairs missing or weak evidence.
  - `plan_gap`: Plan repairs the implementation contract.
  - `blocked`: pause or retry only after the learner chooses.

## Model answers for `show example`

- **Research**: "Research clarified which files matter and showed the task is safe because it stays inside `scratch/`."
- **Planning**: "The validation section matters most because it tells the implementor how we will know the change worked."
- **Implementation**: "The main risk is whether the prime-number logic is correct, not just whether the CLI looks nice."
- **Final reflection**: "Research builds evidence, Plan turns evidence into a contract, Implement follows that contract into code, and Review checks the result against the earlier artifacts."
