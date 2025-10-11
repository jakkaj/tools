---
description: Establish or refresh the project constitution and align the supporting norms documents before any planning phases begin.
---

Please deep think / ultrathink as this is a complex task. 

# plan-0-constitution (alias: phase-0-constitution)

````md
The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding (if not empty).

User input:

$ARGUMENTS

You are updating the project constitution at `/memory/constitution.md` **and** keeping the canonical doctrine files in sync:
- `docs/rules-idioms-architecture/rules.md`        (Rules – normative MUST/SHOULD statements)
- `docs/rules-idioms-architecture/idioms.md`        (Idioms – recurring patterns and examples)
- `docs/rules-idioms-architecture/architecture.md`  (Architecture – structure, boundaries, interaction contracts)

If any document uses placeholder tokens like `[ALL_CAPS_IDENTIFIER]`, your responsibility is to gather the values, fill or intentionally defer them, and keep all three files mutually consistent. Downstream templates or command prompts may reference these files; when they exist, update them last so they reflect the newly agreed doctrine.

--------------------------------
## Execution Flow (deterministic)
1) Resolve repository paths
   - If your environment supplies a repository metadata helper (e.g., a prerequisites script defined in command front matter), run it once and parse the returned JSON. Otherwise derive values from the current working directory.
   - Set constants:
     CONST = `/memory/constitution.md`
     RULES = `docs/rules-idioms-architecture/rules.md`
     IDIOMS = `docs/rules-idioms-architecture/idioms.md`
     ARCH  = `docs/rules-idioms-architecture/architecture.md`
     TMPL  = `templates/`  # Optional helper content if present
   - Ensure parent directories exist; create them atomically when missing.

2) Load (or seed) doctrine files
   - If CONST is missing, create the parent directory and seed an empty constitution skeleton before proceeding.
   - If RULES, IDIOMS, or ARCH are missing, create each file with a minimal section outline so subsequent runs remain deterministic.
   - After seeding, read every document and record `[ALL_CAPS]` placeholders, existing version numbers, headings, and gaps.

3) Gather project doctrine inputs
   - Prefer explicit values supplied in `$ARGUMENTS` (e.g., principles, testing strategy, governance cadence).
   - Augment from README, CONTRIBUTING, handbooks, or prior specs.
   - When information is unknown, write `TODO(<FIELD>): reason it is pending` so future maintainers know what to resolve.
   - Track current and new version numbers using semantic versioning:
     * MAJOR – breaking changes to principles or governance
     * MINOR – new principles/sections or materially expanded guidance
     * PATCH – clarifications or formatting adjustments

4) Draft **/memory/constitution.md**
   - Replace every placeholder. Standard sections:
     * Header with Title, Version, Ratification date, Last amended date
     * **Guiding Principles** – concise MUST/SHOULD statements with rationale
     * **Quality & Verification Strategy** – document how the team proves changes safe (tests, analysis, reviews). Highlight preferred tools per language when known; keep wording inclusive (examples are optional callouts).
     * **Delivery Practices** – planning cadence, documentation expectations, definition of done
     * **Governance** – amendment procedure, review cadence, compliance tracking
   - Prepend a **Sync Impact Report** HTML comment summarizing version bump, affected sections, outstanding TODOs, and whether supporting docs/templates were updated.

5) Align **Rules & Idioms**
   - Write `rules.md` with enforceable statements ("MUST", "SHOULD") covering:
     * Source control hygiene and branching
     * Coding standards, naming, formatting
     * **Testing/verification expectations** (detailed guidance below)
     * Tooling or automation requirements (linters, CI, coverage, static analysis)

   - **Testing Section Requirements** (expand with TAD philosophy):
     The testing section in `rules.md` MUST include comprehensive guidance on:

     **1. Testing Philosophy**
     - Tests as executable documentation (TAD principles)
     - Quality over coverage: tests must "pay rent" via comprehension value
     - When to write tests vs when to skip them
     - Smart application of TDD (test-first when it adds value, not dogmatically)

     **2. Test Quality Standards**
     - Every test MUST explain **why it exists** (business/bug/regression reason)
     - Every test MUST document the **contract** it asserts (plain-English invariants)
     - Every test MUST include **usage notes** (how to call the API, gotchas)
     - Every test MUST describe its **quality contribution** (what failures it catches)
     - Every test SHOULD include a **worked example** (inputs/outputs summary)
     - Tests MUST use clear naming (Given-When-Then or equivalent behavioral format)

     **3. Scratch → Promote Workflow** (TAD approach)
     - Probe tests MAY be written in `tests/scratch/` for fast exploration/iteration
     - `tests/scratch/` MUST be excluded from CI (via .gitignore or CI config)
     - Tests MUST be promoted from scratch/ only if they add durable value
     - **Promotion heuristic**: Keep if Critical path, Opaque behavior, Regression-prone, or Edge case
     - Promoted tests MUST move to `tests/unit/` or `tests/integration/`
     - Promoted tests MUST include complete Test Doc comment blocks (5 required fields)
     - Non-valuable scratch tests MUST be deleted (keep learning notes in PR/log)

     **4. Test-Driven Development (TDD) Guidance**
     - TDD (test-first) SHOULD be used for: complex logic, algorithms, APIs, critical paths
     - TDD MAY be skipped for: simple operations, config changes, trivial wrappers
     - When using TDD, follow RED-GREEN-REFACTOR cycles
     - Tests written first MUST document expected behavior clearly
     - Avoid dogmatic TDD; apply when it adds value to design process

     **5. Test Performance & Reliability**
     - Promoted tests MUST run in <300ms (per test)
     - Tests MUST NOT use network calls (use fixtures/mocks for external dependencies)
     - Tests MUST NOT use sleep/timers (use time mocking if needed)
     - Tests MUST be deterministic (no flaky tests tolerated in main suite)
     - Slow integration tests MAY exceed 300ms but MUST be clearly marked

     **6. Test Organization**
     - `tests/scratch/` – fast probes, excluded from CI, temporary exploration
     - `tests/unit/` – isolated component tests with Test Doc blocks
     - `tests/integration/` – multi-component tests with Test Doc blocks
     - `tests/e2e/` or `tests/acceptance/` – full-system tests (if applicable)
     - `tests/fixtures/` – shared test data, realistic examples preferred

     **7. Mock Usage Policy**
     - Follow project-specific mock policy (Avoid | Targeted | Liberal - set in plan-2-clarify)
     - When mocking, document WHY the real dependency isn't used
     - Prefer real data/fixtures over mocks when practical
     - Mocks SHOULD be simple and behavior-focused, not implementation-focused

     **8. Test Documentation Format**
     Include language-appropriate Test Doc block format examples:

     ```typescript
     test('given_iso_date_when_parsing_then_returns_normalized_cents', () => {
       /*
       Test Doc:
       - Why: Prevent regression from #482 where AUD rounding truncated cents
       - Contract: parseInvoice returns {totalCents:number, date:ZonedDate} with exact cent accuracy
       - Usage Notes: Supply currency code; parser defaults to strict mode (throws on unknown fields)
       - Quality Contribution: Catches rounding/locale drift and date-TZ bugs; documents required fields
       - Worked Example: "1,234.56 AUD" → totalCents=123456; "2025-10-11+10:00" → ZonedDate(Australia/Brisbane)
       */
       // Arrange-Act-Assert with clear phases
     });
     ```

     ```python
     def test_given_iso_date_when_parsing_then_returns_normalized_cents():
         """
         Test Doc:
         - Why: Regression guard for rounding bug (#482)
         - Contract: Returns total_cents:int and timezone-aware datetime with exact cents
         - Usage Notes: Pass currency='AUD'; strict=True raises on unknown fields
         - Quality Contribution: Prevents silent money loss; showcases canonical call pattern
         - Worked Example: "1,234.56 AUD" -> 123_456; "2025-10-11+10:00" -> aware datetime
         """
         # Arrange-Act-Assert with clear phases
     ```

   - Write `idioms.md` with illustrative patterns, directory conventions, and language-specific examples when relevant.
   - Keep references to the constitution explicit (e.g., link sections or quote identifiers). If any area is not yet defined, leave a TODO entry mirroring the constitution.

6) Maintain **architecture.md**
   - Capture the system's high-level structure: modules, services, layers, data flows, integration points.
   - Define boundaries and contracts (who may call whom, allowed dependencies, deployment targets).
   - Document technology-agnostic rules first; add stack-specific notes in dedicated subsections (e.g., "Example: Node service" / "Example: C# backend").
   - Track anti-patterns and reviewer checklists that should remain stable across implementations.

7) Propagate doctrine into helpers (if any)
   - For each file under `templates/` or `agents/commands/` that references the constitution or rules, ensure links remain correct and language stays stack-neutral.
   - Where downstream workflows expect gates (e.g., "confirm plan aligns with rules"), keep the gate but phrase it generically.
   - Do not invent new templates; update only those already present.

8) Validate before writing
   - No document retains unresolved `[PLACEHOLDER]` tokens.
   - Version bumps and dates follow ISO `YYYY-MM-DD`.
   - Principles and rules are actionable, not vague aspirations.
   - Architecture doc reflects the latest agreed structure without contradicting Rules or Constitution.
   - Templates/commands (when touched) remain idempotent and reference the canonical paths exactly.

9) Write files atomically
   - Overwrite CONST, RULES, IDIOMS, and ARCH with the updated content.
   - Apply the minimal set of edits needed for any templates or helper commands.
   - Preserve contributor-authored content outside the edited blocks.

10) Final summary (stdout)
   - Include new version, bump rationale, and list of updated paths.
   - Mention outstanding TODOs or follow-up owners if doctrine remains incomplete.
   - Provide a commit message suggestion such as `docs: refresh constitution and aligned doctrine files`.

--------------------------------
## Synchronized doctrine (authoritative excerpts to enforce)

The following **must** be enforced across Constitution -> Rules & Idioms -> Plan/Tasks/Implementation:

1) **Documented Quality Strategy**
   - Capture how the team proves software is safe to release (automated tests, manual smoke tests, static analysis, runtime monitors).
   - Encourage technology-specific examples, but keep the core policy portable across stacks.

2) **Repeatable Tooling & Environments**
   - Specify required automation (CI jobs, linters, formatters, build scripts) and how contributors run them locally.
   - Note any cross-platform considerations (macOS, Linux, Windows/WSL).

3) **Coding & Review Standards**
   - Define expectations for naming, style, documentation, and code review checklists.
   - State how decisions trace back to the constitution (e.g., principle IDs or links).

4) **Architecture Guardrails**
   - Describe boundaries between major components, allowed dependencies, and integration hooks.
   - Include anti-patterns reviewers should watch for and escalation paths when architecture evolves.

5) **Change Governance**
   - Clarify who approves doctrine updates, how often reviews occur, and what evidence is required for compliance.

--------------------------------
## Acceptance Criteria (for this command)
- `/memory/constitution.md` is fully populated, versioned, and includes a Sync Impact Report.
- `docs/rules-idioms-architecture/{rules.md, idioms.md, architecture.md}` exist (or are created) and reflect the same doctrine without contradictory guidance.
- No document retains unresolved placeholders; dates and versions adhere to the rules above.
- Any touched templates or command prompts reference the canonical doctrine paths and remain stack-neutral.
- Final summary surfaces version bump, updated paths, and outstanding TODO follow-ups.

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

Next step (when happy): Run **/plan-1-specify** to capture the feature specification.
