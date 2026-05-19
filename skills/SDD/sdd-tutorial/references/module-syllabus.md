# SDD Tutorial Module Syllabus

Use this syllabus to teach the RPIV loop. The tutor is not a command dispatcher and not a checklist proctor: every phase boundary should read the artifact, surface one concrete thing the learner should notice, explain why it matters, and then give the next step.

Keep the classroom rule: one work-terminal command per command turn. "Did you notice..." is a teaching pointer, not a question that waits for an answer.

## Teaching handoff pattern

Use this one-turn pattern after a work-terminal artifact is discovered:

1. **Debrief**: Explain what the completed phase was for in 1-3 practical sentences.
2. **Artifact insight**: Read the artifact and point out one specific important detail. Prefer concrete references such as a file path, recommendation, validation command, risk, finding, or routing decision.
3. **Why it matters**: Explain why that detail matters to SDD/RPIV.
4. **Connect**: Explain why the next phase exists.
5. **Command**: Give exactly one next work-terminal command and stop.

Do not ask generic reflection questions. Do not make the learner inspect everything. Pick one useful teaching point from the artifact and make the phase feel concrete.

## Module 1 — Project setup

**Learning objective**: The learner understands that the tutorial has two workspaces: the classroom terminal for guidance and the work terminal for RPIV commands.

**Teach**: Setup is about safety and orientation. We confirm the branch, working tree, RPIV commands, and lesson state before code so the learner can practice without accidentally shipping or mixing work.

**Good insight examples**:

- "Notice we did not name the lesson folder until after choosing the task. That keeps the local state meaningful instead of using a generic label."
- "Notice the branch check happened before any state was written. That matters because this tutorial can lead to real code changes."

## Module 2 — Task selection + Research

**Learning objective**: The learner understands Research as context engineering and alignment, not pre-coding.

**Before Research command**:

- Explain that Research turns a vague task into repo-grounded evidence.
- Tell the learner that good Research should identify relevant files, constraints, risks, and questions.
- Emphasize that no implementation happens yet.

**After Research artifact exists — artifact insight options**:

Read the research artifact and point out one of:

- A relevant file or entry point it found.
- A constraint or risk it identified.
- A recommended slice or task framing.
- A question it resolved or left open.

**Connect to Plan**:

- Planning is where the research stops being background reading and becomes an implementation contract.
- The plan should use the research artifact as evidence for what to change, what not to touch, and how to verify the result.
- The learner should keep the research artifact open or pass its path to Plan so the planner is anchored to evidence.

**Example teaching point**: "Did you notice Research named `scratch/chalk-prime-cli/` as the safe work area? That matters because the implementation can be real code while still avoiding product files."

## Module 3 — Planning

**Learning objective**: The learner understands Plan as the strategy and contract that keeps Implement from improvising.

**After Plan/details artifacts exist — artifact insight options**:

Read the plan/details artifacts and point out one of:

- A specific implementation step that follows from the research.
- A validation command or acceptance check.
- A boundary or "do not touch" constraint.
- A risk or assumption that should shape implementation.

**Connect to Implement**:

- Implement is the first phase where code should change.
- The plan is the guardrail: if implementation needs to diverge, that is a signal to explain the divergence or loop back.
- The learner should keep the plan visible while running Implement.

**Example teaching point**: "Did you notice the plan separates the CLI UI from the prime-number logic? That matters because Review can check correctness separately from presentation polish."

## Module 4 — Implementation

**Learning objective**: The learner understands Implementation as plan execution plus an inspectable changes artifact.

**After changes artifact/diff exists — artifact insight options**:

Read the changes artifact and inspect `git status --short`; point out one of:

- A changed file that maps back to the plan.
- A test/check that was run or skipped.
- A difference between planned work and actual diff.
- A small risk in the diff that Review should verify.

**Connect to Review**:

- Review is the validation layer. It checks the implementation against the research, plan, and actual diff so the loop can catch gaps before the learner trusts the result.
- This is where SDD becomes safer than "agent wrote code and we hoped"; the review can route back to Research, Plan, or Implement with evidence.

**Example teaching point**: "Did you notice the changes artifact says which command was run to verify the CLI? That matters because Review has something concrete to check instead of trusting that the code looks plausible."

## Module 5 - Review + handoff

**Learning objective**: The learner understands Review as validation and routing, not a ceremonial final step.

**After review artifact exists — artifact insight options**:

Read the review artifact and point out one of:

- The verdict/status.
- A critical or major finding.
- A routing decision back to Research, Plan, or Implement.
- A concrete reason the work can be accepted.

**If Review is complete**:

- Explain that the loop has produced evidence, strategy, code, and validation.
- Offer a short recap rather than a generic reflection prompt.

**If Review needs rework**:

- Explain that looping is success, not failure: the validator found the cheapest place to repair the chain.
- Connect the specific review outcome to the next command:
  - `needs_rework`: Implement repairs the diff against review evidence.
  - `research_gap`: Research repairs missing or weak evidence.
  - `plan_gap`: Plan repairs the implementation contract.
  - `blocked`: pause or retry only after the learner chooses.

**Example teaching point**: "Did you notice Review routed this back to Plan instead of Implement? That matters because the strategy contract was incomplete, so more coding would only compound the wrong assumption."
