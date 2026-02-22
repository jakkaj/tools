---
description: Create or update the feature specification from a natural language feature description, focusing on user value (WHAT/WHY) without implementation details. Domain-aware v2.
---

Please deep think / ultrathink as this is a complex task.

# plan-1b-v2-specify

Create or update the feature **spec** from a natural-language description (WHAT/WHY only; no tech choices). Includes mandatory **Target Domains** section for domain-aware planning.

```md
User input:

$ARGUMENTS
# Optional flags:
# --simple    # Pre-set Mode: Simple (user can skip mode question in plan-2-v2-clarify)

1) Determine the feature slug from user input and check for existing plan folder:
   - Generate slug from feature description
   - Check if `docs/plans/*-<slug>/` already exists (created by plan-1a-explore)
   - If exists: Use existing folder and check for `research-dossier.md`
   - If not exists: Create new folder with next available ordinal
   - PLAN_DIR = `docs/plans/<ordinal>-<slug>/`
   - SPEC_FILE = `${PLAN_DIR}/<slug>-spec.md`

1a) Check for and incorporate existing research:
   - If `${PLAN_DIR}/research-dossier.md` exists:
     * Read the research dossier completely
     * Use research to inform complexity scoring and domain identification
     * Add note: "📚 This specification incorporates findings from research-dossier.md"
   - If no research exists:
     * Add note: "ℹ️ Consider running `/plan-1a-explore` for deeper codebase understanding"

1b) Check for existing domains:
   - If `docs/domains/registry.md` exists:
     * Read the registry to understand what domains already exist
     * For each domain, scan `docs/domains/<slug>/domain.md` for relevant contracts and composition
     * Use existing domains to inform the Target Domains section
   - If no domain registry exists:
     * Note that domains will be identified as part of this spec

1c) Check for workshop documents:
   - If `${PLAN_DIR}/workshops/*.md` exist:
     * Read all workshops — these are **authoritative design decisions**
     * Incorporate findings into relevant spec sections

2) Ensure PLAN_DIR exists (create only if not already present).

3) Populate SPEC_FILE with these sections (use Markdown headings):
   - `# <Feature Title>`
   - **Mode header** (if --simple flag provided):
     * Add `**Mode**: Simple` immediately after title
   - `## Research Context` (if research exists) – brief summary of key findings
   - `## Summary` – short WHAT/WHY overview
   - `## Goals` – bullet list of desired outcomes/user value
   - `## Non-Goals` – explicitly out-of-scope behavior
   - `## Target Domains` – **MANDATORY** domain mapping:

     ```markdown
     ## Target Domains

     | Domain | Status | Relationship | Role in This Feature |
     |--------|--------|-------------|---------------------|
     | auth | existing | **modify** | Extend with OAuth provider support |
     | notifications | **NEW** | **create** | Establish for email alert delivery |
     | _platform | existing | **consume** | Use logging and config contracts (no changes) |

     ### New Domain Sketches

     #### notifications [NEW]
     - **Purpose**: [1-3 sentences]
     - **Boundary Owns**: [concepts this domain is responsible for]
     - **Boundary Excludes**: [concepts explicitly NOT in this domain, with notes on where they belong]
     ```

     For each domain listed:
     - If `docs/domains/<slug>/domain.md` exists → mark as `existing`
     - If no domain.md exists → mark as `**NEW**` and provide a sketch
     - **Relationship**: `create` (new domain), `modify` (changing domain code/contracts), or `consume` (using contracts, no changes to domain)
     - Note what role this domain plays in the feature

   - `## Complexity` – initial complexity assessment using CS 1-5 system:
     * **Score**: CS-{1|2|3|4|5} ({trivial|small|medium|large|epic})
     * **Breakdown**: S={0-2}, I={0-2}, D={0-2}, N={0-2}, F={0-2}, T={0-2}
     * **Confidence**: {0.00-1.00}
     * **Assumptions**: [list]
     * **Dependencies**: [external dependencies or blockers]
     * **Risks**: [complexity-related risks]
     * **Phases**: [suggested high-level phases]

     CS rubric:
     - Surface Area (S): Files/modules touched (0=one, 1=multiple, 2=many/cross-cutting)
     - Integration (I): External deps (0=internal, 1=one external, 2=multiple/unstable)
     - Data/State (D): Schema/migrations (0=none, 1=minor, 2=non-trivial)
     - Novelty (N): Req clarity (0=well-specified, 1=some ambiguity, 2=unclear/discovery)
     - Non-Functional (F): Perf/security/compliance (0=standard, 1=moderate, 2=strict)
     - Testing/Rollout (T): Test depth/staging (0=unit only, 1=integration, 2=flags/staged)

     Total P = S+I+D+N+F+T → CS mapping: 0-2=CS-1, 3-4=CS-2, 5-7=CS-3, 8-9=CS-4, 10-12=CS-5

   - `## Acceptance Criteria` – numbered, testable scenarios framed as observable outcomes
   - `## Risks & Assumptions`
   - `## Open Questions`
   - `## Workshop Opportunities` – areas that benefit from detailed design exploration BEFORE architecture:

     | Topic | Type | Why Workshop | Key Questions |
     |-------|------|--------------|---------------|

     Types: `CLI Flow` | `Data Model` | `API Contract` | `State Machine` | `Integration Pattern` | `Storage Design` | `Other`

4) For unknowns, embed `[NEEDS CLARIFICATION: ...]` markers within the appropriate section.

5) Write spec to SPEC_FILE and report path.

Gates:
- Focus on user value; no stack/framework details.
- Mandatory sections present; acceptance scenarios are testable.
- Target Domains section present with at least one domain.
- If empty description, ERROR.

Output: SPEC_FILE ready for clarification.
```

Next steps:
- **If Workshop Opportunities identified**: Consider running **/plan-2c-workshop**
- **Otherwise**: Run **/plan-2-v2-clarify** for ≤8 high-impact questions
