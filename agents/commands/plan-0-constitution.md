---
description: Create or update the project constitution and synchronize Rules & Idioms and Architecture docs up front, then propagate doctrine into templates and command prompts.
---

# plan-0-constitution (alias: phase-0-constitution)

````md
---
description: Create or update the project constitution and synchronize Rules & Idioms and Architecture docs up front. Then validate and propagate changes into dependent templates/commands.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding (if not empty).

User input:

$ARGUMENTS

You are updating the project constitution at `/memory/constitution.md` **and** synchronizing:
- `docs/rules-idioms-architecture/rules.md`        (Rules - normative MUST/SHOULD)
- `docs/rules-idioms-architecture/idioms.md`        (Idioms - common patterns & examples)
- `docs/rules-idioms-architecture/architecture.md`  (Architecture - boundaries & layering)

These files may be templates with placeholder tokens `[ALL_CAPS_IDENTIFIER]`. Your job is to (a) collect/derive concrete values, (b) fill templates precisely, and (c) propagate any amendments across `templates/` so downstream commands enforce the same rules.

--------------------------------
## Execution Flow (deterministic)
1) Resolve repository paths
   - Run `{SCRIPT}` once; parse JSON for repository root and any pre-existing docs.
   - Set:
     CONST = `/memory/constitution.md`
     RULES = `docs/rules-idioms-architecture/rules.md`
     IDIOMS = `docs/rules-idioms-architecture/idioms.md`
     ARCH  = `docs/rules-idioms-architecture/architecture.md`
     TMPL  = `templates/`                      # all templates & command prompts
   - If any path is missing, create parent directories atomically.

2) Load current templates/documents
   - Read CONST; collect all placeholder tokens `[ALL_CAPS]`.
   - Read RULES; if absent, seed from the in-repo sample with the Testing sections listed under "Synchronized doctrine" below (do not invent content).
   - Read ARCH; if absent, seed from the in-repo architecture sample with layer boundaries & GraphBuilder rules (see Synchronization Targets, below).

3) Collect/derive values for placeholders
   - If `$ARGUMENTS` supplies values, prefer them.
   - Otherwise, derive from README/docs or leave a `TODO(<FIELD>): explanation`.
   - Dates:
     * `RATIFICATION_DATE` = original adoption date (ask if unknown; else TODO)
     * `LAST_AMENDED_DATE` = today if changes; else keep previous
   - Version:
     * Compute `CONSTITUTION_VERSION` bump via SemVer:
       - MAJOR: breaking governance/principle redefinitions
       - MINOR: new principle/section or materially expanded guidance
       - PATCH: clarifications/typos/non-semantic edits
     * If ambiguous, state your reasoning in the Sync Impact Report before finalizing.

4) Draft **Constitution** (overwrite `/memory/constitution.md`)
   - Replace every placeholder; leave no unexplained tokens.
   - Structure:
     * Title, Version, Dates
     * **Principles** (non-negotiable MUST/SHOULD with rationale)
     * **Testing Doctrine** (normative excerpt; see "Synchronized doctrine")
     * Governance (amendment procedure, review cadence, compliance)
   - Write the **Sync Impact Report** as an HTML comment at file top:
     - old->new version, modified/added/removed sections
     - templates touched ([check] updated / [warn] pending)
     - deferred TODO placeholders

5) Synchronize **Rules & Idioms** (split)
   - **Rules** → `docs/rules-idioms-architecture/rules.md`
   - **Idioms** → `docs/rules-idioms-architecture/idioms.md`
   - Ensure (create/merge/update) these sections and rules verbatim-style where applicable:
     A) Test Configuration via `pytest.ini`; register markers; centralize pytest config
     B) Test Structure & Locations (`tests/`, `tests/howto/`, `tests/test-repos/`)
     C) Test Data Strategy - **real repos**, not mocks; use `tests.utils.pipeline_helpers.TestWorkspace` for pipeline data
     D) Test Quality Assertions - avoid happy-path; assert correctness/coverage with explicit expectations
     E) **Test Documentation blocks** in each test:
        - `Purpose:` what is proven
        - `Quality Contribution:` why this test improves system quality
        - `Acceptance Criteria:` measurable behaviors/assertions
     F) Multi-language test repositories guidance
     G) CLI/Tooling, Logging, DI, ConfigRegistry patterns
     - Normalize path references to *canonical* `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}`.
   - If pre-existing RULES conflict with the constitution, update RULES to comply and flag differences in the Impact Report.

6) Synchronize **Architecture** (`docs/rules-idioms-architecture/architecture.md`)
   - Materialize (or update) architecture with these non-negotiable boundaries:
     * **Layering (LFL -> Embedding -> LSL -> Condense -> Graph -> Query)** with strict separation of concerns
     * **GraphBuilder language-agnostic rule** - absolutely **no** language-specific resolution logic in GraphBuilder; all such logic lives in LSL enrichers
     * **Abstraction boundary** rules (no upward leakage, interface segregation)
     * **File/JSON naming contracts** (e.g., `calculator.py` -> `calculator.py.json`)
     * **Anti-patterns** and enforcement checklist for reviewers
   - Keep the mermaid diagrams and rule tables readable and stable.

7) Propagate into `templates/` (alignment and path rewrite)
   - Update these to reference canonical paths and doctrine:
     * `templates/plan-template.md` -> Constitution Check gates reference `/memory/constitution.md`
       and `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}`; STOP before tasks
     * `templates/spec-template.md` -> requires testable acceptance criteria and marks ambiguities clearly
     * `templates/tasks-template.md` -> TDD ordering; `[P]` only when tasks touch different files; absolute paths
     * `templates/commands/*.md` -> rewrite any `docs/rules...` paths to
       `docs/rules-idioms-architecture/...`; ensure every planning/validation command **gates** on:
       - TOC present
       - TDD with **tests as documentation**
       - **No mocks**; use real repo data/fixtures
       - Absolute paths; no assumed prior context
   - Do not change behavior semantics; only enforce doctrine and canonicalize paths.

8) Validation (hard gates before finishing)
   - Constitution:
     * No unexplained `[TOKENS]`
     * Version bump matches Impact Report
     * ISO dates `YYYY-MM-DD`
     * Principles declarative/testable; avoid vague "should" without rationale
   - Rules:
     * All Testing sections present (A-G above)
     * Examples show **test documentation** blocks and assert quality contribution
   - Architecture:
     * GraphBuilder rule present; LSL vs LFL separation explicit
     * Data-flow and naming conventions explicit
   - Templates/commands:
     * All refer to `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}`
     * All planning commands have TDD/no-mocks/real-data gates
     * Plan STOP rule intact (no tasks/code during plan)

9) Write files
   - Overwrite: CONST, RULES, ARCH
   - Apply minimal, surgical edits to templates/commands to correct paths/gates (idempotent).
   - Preserve manual additions between known markers where present.

10) Final summary (stdout)
   - New version and bump rationale
   - Paths updated
   - Files requiring manual follow-up (if any)
   - Suggested commit message:
     `docs: establish/align constitution vX.Y.Z + rules/architecture; gate templates on tests-as-docs (no mocks)`

--------------------------------
## Synchronized doctrine (authoritative excerpts to enforce)

The following **must** be enforced across Constitution -> Rules & Idioms -> Plan/Tasks/Implementation:

1) **Tests as Documentation (Executable Docs)**
   - Every test includes a docstring/comment block with:
     ```
     """
     Purpose: <what truth this test proves>
     Quality Contribution: <how this prevents a class of bugs or improves confidence>
     Acceptance Criteria: <assertions that must hold; measurable>
     """
   - Tests read as documentation: assertions demonstrate behavior, not generic truths.
   - Maintain compelling, end-to-end "howto" tests under `tests/howto/` for executable documentation.

2) **TDD & No Mocks (real data/fixtures)**
   - Write/adjust tests first (RED) -> implement minimal code (GREEN) -> refactor (CLEAN).
   - Prefer **real** repository data and real pipeline fixtures; use `tests.utils.pipeline_helpers.TestWorkspace` for substrate pipeline tests.
   - Only stub truly external/network dependencies.

3) **Test Quality Assertions**
   - Avoid "exists/len>0" patterns as proof; assert **specific** relationships/behaviors and minimum coverage thresholds where meaningful.

4) **Structure & Configuration**
   - Centralize pytest config in `pytest.ini` with registered markers.
   - Keep test directories structured and named consistently.
   - Provide multi-language test repositories under `tests/test-repos/` for integration coverage.

5) **Architecture Boundaries**
   - Enforce substrate layering (LFL/Embedding/LSL/Condense/Graph/Query).
   - **CRITICAL**: GraphBuilder remains language-agnostic; all language-specific resolution belongs in LSL enrichers.
   - Maintain naming contracts for LFL/condensed artifacts.

--------------------------------
## Acceptance Criteria (for this command)
- `/memory/constitution.md` contains no stray placeholders; version bumped with rationale; Governance section present.
- `docs/rules-idioms-architecture/rules.md` includes Testing sections A-G and **explicit test documentation blocks** and **quality contribution** guidance.
- `docs/rules-idioms-architecture/architecture.md` encodes layer boundaries, anti-patterns, GraphBuilder rule, and naming contracts.
- All `templates/` plan/spec/tasks/command prompts refer to **canonical** `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}` and gate on TDD, tests-as-docs, **no mocks**, real data.
- Final summary lists changes and suggested commit message.

--------------------------------
## Formatting & Style
- Use Markdown headings exactly as in templates; keep one blank line between sections; avoid trailing whitespace.
- Wrap rationale lines for readability (<100 chars where practical).
- Deterministic edits; idempotent if run twice without new inputs.
````

Canonical paths enforced by this command

- Constitution: `/memory/constitution.md`
- Rules: `docs/rules-idioms-architecture/rules.md`
- Idioms: `docs/rules-idioms-architecture/idioms.md`
- Architecture: `docs/rules-idioms-architecture/architecture.md`
- Templates directory: `templates/`

Run this command once per project (or whenever the guiding principles change) before executing planning or implementation phases.
