---
description: Establish or refresh the project constitution and align the supporting norms documents before any planning phases begin. Re-entrant command that preserves user customizations during updates.
---

Please deep think / ultrathink as this is a complex task.

# plan-0-constitution (alias: phase-0-constitution)

**Re-entrancy Support**: This command is now re-entrant and will intelligently preserve user customizations when updating existing constitution files. Mark your custom content with `<!-- USER CONTENT START -->` and `<!-- USER CONTENT END -->` for guaranteed preservation across updates.

````md
The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding (if not empty).

User input:

$ARGUMENTS

You are updating the project doctrine files in `docs/project-rules/`:
- `docs/project-rules/constitution.md`  (Constitution – guiding principles and governance)
- `docs/project-rules/rules.md`         (Rules – normative MUST/SHOULD statements)
- `docs/project-rules/idioms.md`        (Idioms – recurring patterns and examples)
- `docs/project-rules/architecture.md`  (Architecture – structure, boundaries, interaction contracts)

If any document uses placeholder tokens like `[ALL_CAPS_IDENTIFIER]`, your responsibility is to gather the values, fill or intentionally defer them, and keep all three files mutually consistent. Downstream templates or command prompts may reference these files; when they exist, update them last so they reflect the newly agreed doctrine.

--------------------------------
## Execution Flow (deterministic)
1) Resolve repository paths and detect mode
   - If your environment supplies a repository metadata helper (e.g., a prerequisites script defined in command front matter), run it once and parse the returned JSON. Otherwise derive values from the current working directory.
   - Set constants:
     CONST = `docs/project-rules/constitution.md`
     RULES = `docs/project-rules/rules.md`
     IDIOMS = `docs/project-rules/idioms.md`
     ARCH  = `docs/project-rules/architecture.md`
     TMPL  = `templates/`  # Optional helper content if present
   - Ensure parent directories exist; create them atomically when missing.

   **Re-entrancy Detection**:
   - Check if any of CONST, RULES, IDIOMS, ARCH already exist
   - If ANY exist: **UPDATE MODE** - Will preserve user customizations
   - If NONE exist: **CREATE MODE** - Will create fresh documents
   - Display mode to user: "🔄 Updating existing constitution..." or "✨ Creating new constitution..."

2) Launch parallel context gatherers

**IMPORTANT**: Use **parallel subagent gatherers** for faster doctrine loading.

**Strategy**: Launch 4 parallel subagents (single message with 4 Task tool calls) to gather doctrine context concurrently.

**Subagent 1: Doctrine Loader (Re-entrancy Aware)**
"Load existing doctrine files and categorize content for preservation.

**Tasks**:
- For each of CONST, RULES, IDIOMS, ARCH:
  * If file exists:
    - Read fully and extract version number, [PLACEHOLDER] tokens, section headings, TODOs
    - Identify sections marked with `<!-- USER CONTENT START -->` and `<!-- USER CONTENT END -->`
    - Categorize each section as: 'generated' (safe to update), 'custom' (must preserve), or 'mixed' (needs merge)
    - Extract any filled placeholder values that replaced `[ALL_CAPS_TOKENS]`
    - Note custom sections not in standard template
  * If missing: Note for creation with minimal outline

**Categorization Rules**:
- Content between USER CONTENT markers = 'custom'
- Standard template sections without modifications = 'generated'
- Standard sections with significant user additions = 'mixed'
- Entirely new user-added sections = 'custom'

**Output**: JSON with {file_path, exists, version, placeholders[], headings[], todos[],
  sections[{name, type, content, preserve}], custom_additions[], filled_values{}}

**Return**: Results for all 4 files with preservation metadata."

**Subagent 2: Context Gatherer**
"Gather project governance and quality inputs from documentation.

**Priority order**: $ARGUMENTS > README.md > CONTRIBUTING.md > other handbooks

**Extract**:
- Guiding principles and values
- Quality/verification strategy and testing philosophy
- Delivery practices and governance rules
- Record source for each value (argument, README, etc.)

**Output**: JSON with {principles[], quality_strategy, delivery_practices, governance, sources{}}
Flag unknowns as 'UNKNOWN: <reason>' for TODO handling."

**Subagent 3: Template Scanner**
"Inventory templates and commands that reference doctrine.

**Scan**:
- agents/commands/*.md for references to constitution, rules, idioms, architecture
- templates/ directory for similar references

**Output**: JSON with {file_path, references_to[], link_format, expected_paths[]}
Note any hardcoded paths or placeholders that need updating."

**Subagent 4: Version Analyzer**
"Determine semantic version bump.

**Given**:
- Current versions from Subagent 1
- Changes from Subagent 2 ($ARGUMENTS and context)

**Apply rules**:
- MAJOR: Breaking changes to principles or governance
- MINOR: New principles/sections or materially expanded guidance
- PATCH: Clarifications or formatting adjustments

**Output**: JSON with {current_version, new_version, bump_type, rationale}
Include amendment date as ISO 8601."

**Wait for All Gatherers**: Block until all 4 subagents complete.

3) Synthesize gathered context and prepare merge strategy
   - Merge outputs from all 4 subagents into unified doctrine view
   - Conflict resolution: $ARGUMENTS > explicit docs > inferred > UNKNOWN
   - Build complete placeholder mapping: [TOKEN] → {value, source, confidence}
   - Validate version bump against actual changes detected
   - Create TODO list for any UNKNOWN values: "TODO(<FIELD>): <reason pending>"

   **Re-entrancy Merge Strategy** (if UPDATE MODE):
   - For each file, prepare merge plan:
     * Sections marked 'custom' → PRESERVE entirely
     * Sections marked 'generated' → UPDATE with new content
     * Sections marked 'mixed' → MERGE: Keep user additions, update framework
   - Preserve all filled placeholder values from existing files
   - Keep user-added sections not in template
   - Maintain existing TODOs that are still unresolved
   - Track what will change for user confirmation

   - Prepare inputs for Step 4 constitution drafting:
     * All placeholder values (filled or deferred, preferring existing)
     * Validated principles and practices (merging existing with new)
     * Quality strategy with tools/approaches
     * Template dependency map for Step 7 propagation
     * Final version number and Sync Impact Report data
     * Merge strategy per file with preservation instructions

4) Draft **docs/project-rules/constitution.md** (re-entrancy aware)
   **For CREATE MODE**:
   - Replace every placeholder. Standard sections:
     * Header with Title, Version, Ratification date, Last amended date
     * **Guiding Principles** – concise MUST/SHOULD statements with rationale
     * **Quality & Verification Strategy** – document how the team proves changes safe (tests, analysis, reviews). Highlight preferred tools per language when known; keep wording inclusive (examples are optional callouts).
     * **Delivery Practices** – planning cadence, documentation expectations, definition of done
     * **Governance** – amendment procedure, review cadence, compliance tracking

   **For UPDATE MODE**:
   - Preserve all sections marked as 'custom' from Step 3 analysis
   - Update 'generated' sections with new framework content
   - For 'mixed' sections: Keep user additions, update framework parts
   - Maintain filled placeholder values from existing file
   - Add new standard sections if missing, mark with `<!-- NEWLY ADDED -->`
   - Keep user's custom sections even if not in template
   - Update version number appropriately (PATCH for clarifications, MINOR for new sections, MAJOR for breaking changes)

   - Prepend a **Sync Impact Report** HTML comment summarizing:
     * Mode: CREATE or UPDATE
     * Version bump: old → new with rationale
     * Sections preserved vs updated
     * Custom content retained
     * New sections added
     * Outstanding TODOs
     * Supporting docs/templates update status

5) Align **Rules & Idioms** (re-entrancy aware)
   **For UPDATE MODE**:
   - Apply same preservation strategy as constitution
   - Keep user's custom rules and examples
   - Update framework rules while preserving additions
   - Merge testing section carefully to keep project-specific policies

   - Write/update `rules.md` with enforceable statements ("MUST", "SHOULD") covering:
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

     **5. Test Reliability & Quality**
     - Tests MUST NOT use network calls (use fixtures/mocks for external dependencies)
     - Tests MUST NOT use sleep/timers (use time mocking if needed)
     - Tests MUST be deterministic (no flaky tests tolerated in main suite)
     - Tests SHOULD be reasonably fast to maintain quick feedback loops
     - Performance requirements (timing, resource limits) will be specified in the spec when needed

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

     **9. Complexity-First Estimation Policy (REQUIRED)**

     The constitution MUST enforce a **no-time policy** for all estimates and planning:

     - **Prohibition**: Never output or imply time, duration, or ETA in any form (hours, minutes, days, "quick", "fast", "soon", deadlines, etc.)
     - **Replacement**: All effort quantification MUST use the **Complexity Score (CS 1-5)** system
     - **Scoring rubric**: Compute points (0-2 each) for 6 factors, sum to CS:
       * **Surface Area (S)**: Files/modules touched; breadth of change (0=one file, 1=multiple files, 2=many files/cross-cutting)
       * **Integration Breadth (I)**: External libs/services/APIs/tooling (0=internal only, 1=one external, 2=multiple externals/unstable API)
       * **Data & State (D)**: Schema changes, migrations, concurrency (0=none, 1=minor tweaks, 2=non-trivial migration/concurrency)
       * **Novelty & Ambiguity (N)**: Requirements clarity, research needed (0=well-specified, 1=some ambiguity, 2=unclear specs/significant discovery)
       * **Non-Functional Constraints (F)**: Performance, security, compliance (0=standard gates, 1=moderate constraints, 2=strict/critical constraints)
       * **Testing & Rollout (T)**: Test depth, flags, staged rollout (0=unit only, 1=integration/e2e, 2=flags/staged rollout/backward compat)
     - **Mapping**: Total points P (0-12) maps to CS:
       * CS-1 (0-2): Trivial - isolated tweak, no new deps, unit test touchups
       * CS-2 (3-4): Small - few files, familiar code, maybe one internal integration
       * CS-3 (5-7): Medium - multiple modules, small migration or stable external API, integration tests
       * CS-4 (8-9): Large - cross-component, new dependency/service, meaningful migration, rollout plan
       * CS-5 (10-12): Epic - architectural change/new service, high uncertainty, phased rollout with flags

     **Mandatory output fields** wherever planning or reporting occurs:
     ```json
     {
       "complexity": {
         "score": 3,
         "label": "medium",
         "breakdown": {"surface": 1, "integration": 1, "data_state": 1, "novelty": 1, "nfr": 0, "testing_rollout": 1},
         "confidence": 0.75
       },
       "assumptions": ["Spec is final"],
       "dependencies": ["Payments service schema v2"],
       "risks": ["Downstream consumer expectations"],
       "phases": ["Design notes", "Implementation", "Tests", "Flagged rollout"]
     }
     ```

     **Enforcement rules**:
     - For CS ≥ 4, MUST include staged rollout, feature flags, and rollback plan in phases
     - Prefer complexity idioms: "scope", "risk", "breadth", "unknowns" over any time language
     - If uncertainty is high, ask clarifying questions and reflect in Novelty (N) + lower confidence
     - Self-check: If time words appear in drafts, replace with complexity reasoning or remove

     **Calibration examples** (include in idioms.md):
     - Rename a constant used in one file: S=0, I=0, D=0, N=0, F=0, T=0 → **CS-1 (trivial)**
     - Add new endpoint using existing service: S=1, I=1, D=1, N=1, F=0, T=1 → P=5 → **CS-3 (medium)**
     - Introduce new service with schema migration and staged rollout: S=2, I=2, D=2, N=2, F=1, T=2 → P=11 → **CS-5 (epic)**

   - Write `idioms.md` with illustrative patterns, directory conventions, and language-specific examples when relevant.
   - Keep references to the constitution explicit (e.g., link sections or quote identifiers). If any area is not yet defined, leave a TODO entry mirroring the constitution.

6) Maintain **architecture.md** (re-entrancy aware)
   **For UPDATE MODE**:
   - Preserve user's architectural decisions and custom diagrams
   - Update framework structure while keeping project-specific sections
   - Maintain technology stack choices and integration details
   - Keep custom anti-patterns and project-specific checklists

   - Capture/update the system's high-level structure: modules, services, layers, data flows, integration points.
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

   **For UPDATE MODE - User Confirmation**:
   - Display summary of proposed changes:
     * "Will preserve: X custom sections, Y user values"
     * "Will update: Z framework sections"
     * "Will add: N new sections"
   - Show diff preview of significant changes
   - Ask: "Proceed with update? (backups will be created)"
   - If user declines, abort with no changes

9) Write files with intelligent merge
   **For CREATE MODE**:
   - Write CONST, RULES, IDIOMS, and ARCH with fresh content
   - Mark sections that users can customize with `<!-- USER CONTENT START -->` and `<!-- USER CONTENT END -->`

   **For UPDATE MODE**:
   - For each file, apply merge strategy from Step 3:
     * Preserve sections marked 'custom' completely
     * Update sections marked 'generated' with new content
     * Intelligently merge 'mixed' sections (keep user content, update framework)
   - Add protective markers around user content for future runs
   - Validate no user content was lost in the merge
   - Create backup of original files before writing (stored in `.constitution-backup/`)

   **For both modes**:
   - Apply the minimal set of edits needed for any templates or helper commands
   - Preserve contributor-authored content outside the edited blocks
   - Ensure all files remain internally consistent

10) Final summary (stdout)
   **For CREATE MODE**:
   - Report: "✨ Created new constitution and doctrine files"
   - Include version 1.0.0 and creation date
   - List all created files

   **For UPDATE MODE**:
   - Report: "🔄 Updated constitution and doctrine files"
   - Show version change: old → new with bump rationale
   - List what was preserved vs updated:
     * "Preserved: N custom sections, M filled values"
     * "Updated: X framework sections"
     * "Added: Y new sections"
   - If backups created, note location: `.constitution-backup/`

   **For both modes**:
   - List all modified paths with change type
   - Mention outstanding TODOs or follow-up owners if doctrine remains incomplete
   - Provide appropriate commit message:
     * CREATE: `docs: establish project constitution and doctrine files`
     * UPDATE: `docs: update constitution v{old} → v{new} while preserving customizations`

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
- `docs/project-rules/constitution.md` is fully populated, versioned, and includes a Sync Impact Report.
- `docs/project-rules/{rules.md, idioms.md, architecture.md}` exist (or are created/updated) and reflect the same doctrine without contradictory guidance.
- **For UPDATE MODE**: All user customizations are preserved, no content is lost.
- **For CREATE MODE**: Files include protective markers for future customizations.
- Backups are created before updates (stored in `.constitution-backup/` with timestamp).
- No document retains unresolved placeholders; dates and versions adhere to the rules above.
- Any touched templates or command prompts reference the canonical doctrine paths and remain stack-neutral.
- Final summary surfaces version bump, updated paths, preserved content metrics, and outstanding TODO follow-ups.
- User is shown preview and asked for confirmation before applying updates in UPDATE MODE.

--------------------------------
## Formatting & Style
- Use Markdown headings exactly as in templates; keep one blank line between sections; avoid trailing whitespace.
- Wrap rationale lines for readability (<100 chars where practical).
- Deterministic edits; idempotent if run twice without new inputs.
````

Canonical paths enforced by this command

- Constitution: `docs/project-rules/constitution.md`
- Rules: `docs/project-rules/rules.md`
- Idioms: `docs/project-rules/idioms.md`
- Architecture: `docs/project-rules/architecture.md`
- Templates directory: `templates/`

Run this command once per project (or whenever the guiding principles change) before executing planning or implementation phases.

Next step (when happy): Run **/plan-1a-explore** for research or **/plan-1b-specify** to capture the feature specification.
