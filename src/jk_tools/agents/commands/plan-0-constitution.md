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
     * Testing/verification expectations (unit, integration, acceptance, manual checks)
     * Tooling or automation requirements (linters, CI, coverage, static analysis)
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
