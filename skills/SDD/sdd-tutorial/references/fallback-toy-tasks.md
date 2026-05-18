# Fallback Toy Tasks

Offer these only when the learner has no safe task, proposes one red task, or cannot narrow a yellow task after two attempts.

Prefer F0 first when the learner cannot think of something. It lives under the repo's gitignored `scratch/` folder, so it is safe for classroom practice without committing toy code. The other tasks are language-neutral options for learners who prefer to practice on tracked repo content. Every task avoids secrets/auth/payment/deployments and has one done-when condition.

## F0 — Scratch Chalk Prime CLI

Use this copy when offering it:

> No problem — we can use the gitignored `scratch/` folder for a safe toy exercise. A good default is `scratch/chalk-prime-cli/`: create a small Node CLI that uses `chalk` to list every prime number under 1000 in a polished, pleasant terminal UI. It gives us enough real code to research, plan, implement, and review without touching product files.

**Goal**: Create a simple Node CLI in `scratch/chalk-prime-cli/` that uses `chalk` to display all prime numbers under 1000 in a nice-looking terminal UI.
**File scope**: `scratch/chalk-prime-cli/` only.
**Done when**: Running the CLI prints every prime number under 1000, does not print non-primes, and uses `chalk` formatting for a readable UI.
**Skills exercised**: sandbox scoping, dependency awareness, small algorithm implementation, terminal UX, verification.

## F1 — README Try It Section

**Goal**: Add a short README section showing the smallest command a contributor can run.
**File scope**: `README.md`.
**Done when**: A "Try it" or equivalent section exists and contains commands the learner has run locally.
**Skills exercised**: research entry point, docs, acceptance wording.

## F2 — Small Pure Utility

**Goal**: Add or improve a tiny pure function that transforms a value without external services.
**File scope**: one utility file plus an existing test file if the repo has tests.
**Done when**: The function behaviour is documented by one local check or test.
**Skills exercised**: code reading, small implementation, verification.

## F3 — Error Message Clarification

**Goal**: Improve one confusing local error message without changing control flow.
**File scope**: one source file plus optional test/doc.
**Done when**: The same condition produces clearer text and existing behaviour is otherwise unchanged.
**Skills exercised**: tracing, narrow diff, regression thinking.

## F4 — EditorConfig or Formatting Note

**Goal**: Add a tiny contributor-facing formatting note or `.editorconfig` if the repo lacks one.
**File scope**: one config or docs file.
**Done when**: The repo documents one formatting convention a contributor can follow.
**Skills exercised**: convention discovery, low-risk config, docs.

## F5 — Existing Test Name Cleanup

**Goal**: Rename one unclear test case or assertion description without changing behaviour.
**File scope**: one existing test file.
**Done when**: The test still passes or the learner can show why no test runner exists.
**Skills exercised**: test reading, safe refactor, verification.

## F6 — Comment-to-Doc Promotion

**Goal**: Move one important explanation from an inline comment into nearby docs or README.
**File scope**: one source file and one docs file.
**Done when**: The explanation is findable by a new contributor without changing code behaviour.
**Skills exercised**: knowledge extraction, docs, diff review.

## F7 — CLI Help Text Polish

**Goal**: Improve one command/help string or usage example for an existing entry point.
**File scope**: one source or docs file, plus optional test.
**Done when**: The command/help text describes the existing behaviour more clearly.
**Skills exercised**: entry-point research, user framing, verification.

## Tag coverage

| Tag | Covered by |
|-----|------------|
| docs | F1, F4, F6 |
| scratch | F0 |
| cli | F0, F7 |
| node | F0 |
| pure-code | F0, F2, F3 |
| tests | F2, F5 |
| config | F4, F7 |
| contributor-experience | F1, F6, F7 |
