---
description: Pre-implementation alignment brief for a single approved plan phase; produces test-first mini-plan, risks, commands, and a GO/NO-GO checklist before any code changes.
---

# Pre-Implementation Alignment & Walkthrough (Single Phase)

You are my implementation partner. We are about to implement exactly ONE phase of an approved plan. 
Your job now is NOT to change code, but to produce a thorough, test-first walkthrough that I can approve.

CONTEXT
- Plan file (path): {{PLAN_FILE}}
- Phase to implement (exact heading): {{PHASE_NAME}}
- Repo root path: {{REPO_ROOT}}
- Branch to work on: {{BRANCH}}
- Execution environment / runner (e.g., local, CI job, devcontainer): {{ENV}}
- Constraints (performance/SLO, security, compatibility, migration windows): {{CONSTRAINTS}}
- Out of scope for this phase: {{OUT_OF_SCOPE}}

NON-NEGOTIABLE RULES (mirror project rules/idioms)
- Follow the plan structure produced by my "architect" mode; your output should keep that vocabulary and phase/task numbering. :contentReference[oaicite:3]{index=3}
- Conform to "complete-the-plan" requirements: up-front TOC, explicit phase outline, TDD, tests-as-documentation, no mocks, real repo data/fixtures; be explicit with no assumed prior context. If the plan file is missing any of these, STOP and list fixes I must run first. :contentReference[oaicite:4]{index=4}
- Tests come first, must prove behavior (not just happy paths), and must read as documentation via precise assertions. :contentReference[oaicite:5]{index=5}
- Prefer repository-native patterns and proven practices from prior phases (e.g., language/test runner conventions, debug adapter use, bounded file searches, request-scoped context) where applicable. :contentReference[oaicite:6]{index=6}

DELIVERABLE — PHASE IMPLEMENTATION BRIEF
(Produce the sections below. Do not modify code yet.)

1) Objective Recap
   - Restate {{PHASE_NAME}} in one paragraph and a 3–7 bullet checklist of behaviors we will deliver.
   - Call out any cross-phase dependencies.

2) Invariants & Guardrails Checklist
   - List the must-not-break invariants, external contracts, and migration/rollback constraints.
   - Note performance or memory budgets if relevant.

3) Source-of-Truth Inputs to Read
   - Exact files, docs, or modules you will inspect before coding (link by path).
   - If repo conventions exist (e.g., tests/utils/pipeline_helpers.py or tests/README patterns), state how they will be used for *real-data* tests. If absent, name the repository-specific equivalent you will use. :contentReference[oaicite:7]{index=7}

4) Test Plan (TDD, tests-as-docs, no mocks)
   - Enumerate test cases BEFORE implementation: success, edge, failure, concurrency/race, configuration, I/O, and negative paths.
   - For each test: name, rationale (“what truth does this prove?”), inputs/fixtures, expected observable outputs, and why this prevents regressions.
   - Specify the exact runner and tooling per stack (e.g., for VS Code extension host: Mocha; for Python: pytest), and why that choice aligns with repo constraints. :contentReference[oaicite:8]{index=8}
   - Identify any *real* fixtures/data to use and where they live.

5) Step-by-Step Implementation Plan (no code yet)
   - Ordered, minimal steps mapping 1:1 to the tests.
   - For each step: files to touch, APIs to call, and how the change satisfies a specific test.
   - Include any critical patterns required by this stack (e.g., Python testing via `module: 'pytest'` instead of direct `program` runs; bounded searches with RelativePattern; async context scoping) when relevant. :contentReference[oaicite:9]{index=9}

6) Commands to Run (copy/paste)
   - Shell commands to set up env, run tests (watch and one-shot), linters, type checks, and benchmarks.
   - Include any editor/runner flags (e.g., `--no-cov` when breakpoints would be swallowed by coverage). :contentReference[oaicite:10]{index=10}

7) Risks, Unknowns, and Decision Log
   - List assumptions, open questions, and their resolution paths.
   - Provide fallbacks/feature flags if a dependency is missing.
   - Define a simple rollback plan (files to revert, toggles to flip).

8) Acceptance Criteria & Evidence
   - Map each acceptance criterion to specific tests and observable CLI/editor output.
   - Define what artifacts you will produce as proof (e.g., patch/diff, test output snippet, screenshots of debug stop-line).

9) Ready Check (GO/NO-GO)
   - A short checklist I can tick:
     [ ] Tests clearly precede code
     [ ] Real data/fixtures named
     [ ] Risks + rollback clear
     [ ] Commands are reproducible
   - Await my explicit **GO** before making changes.

STYLE
- Be concise and operational. Use the repo’s terminology from the plan.
- No code edits, no speculative refactors, no background execution. This is an alignment brief only.
