---
description: Create or update the feature specification from a natural language feature description, focusing on user value (WHAT/WHY) without implementation details.
---

Please deep think / ultrathink as this is a complex task. 

# plan-1b-specify

Create or update the feature **spec** from a natural-language description (WHAT/WHY only; no tech choices). Follow the canonical spec structure described below.

```md
User input:

$ARGUMENTS
# Optional flag:
# --simple    # Pre-set Mode: Simple (user can skip mode question in plan-2-clarify)

1) Determine the feature slug from user input and check for existing plan folder:
   - Generate slug from feature description
   - Check if `docs/plans/*-<slug>/` already exists (created by plan-1a-explore)
   - If exists: Use existing folder and check for `research-dossier.md`
   - If not exists: Create new folder with next available ordinal
   - PLAN_DIR = `docs/plans/<ordinal>-<slug>/`
   - SPEC_FILE = `${PLAN_DIR}/<slug>-spec.md` (spec co-located with plan)

1a) Check for and incorporate existing research:
   - If `${PLAN_DIR}/research-dossier.md` exists:
     * Read the research dossier completely
     * Note critical findings and modification considerations
     * Use research to inform complexity scoring
     * Reference key discoveries in relevant spec sections
     * Check for "## External Research Opportunities" section
     * Add note: "📚 This specification incorporates findings from research-dossier.md"
   - If no research exists:
     * Add note: "ℹ️ Consider running `/plan-1a-explore` for deeper codebase understanding"
   - Also check `docs/research/` for recent (< 24 hours) research on similar topics

1b) Check for external research results:
   - If `${PLAN_DIR}/external-research/` directory exists:
     * Read all .md files within (these contain /deepresearch results)
     * Incorporate findings into relevant spec sections (Goals, Risks, Complexity, etc.)
     * Track which files were incorporated
   - Compare external research results against opportunities in research-dossier.md:
     * UNRESOLVED_OPPORTUNITIES = opportunities listed but no matching external-research/*.md file
   - **Soft Warning** (if UNRESOLVED_OPPORTUNITIES > 0):
     * Add warning at top of spec after mode header:
       ```
       ⚠️ **Unresolved Research Opportunities**
       The following external research topics were identified in research-dossier.md but not addressed:
       - [Topic 1]: [Brief description]
       - [Topic 2]: [Brief description]
       Consider running `/deepresearch` prompts before finalizing architecture.
       ```

2) Ensure PLAN_DIR exists (create only if not already present).
3) Populate SPEC_FILE with these sections (use Markdown headings):
   - `# <Feature Title>`
   - **Mode header** (if --simple flag provided):
     * Add `**Mode**: Simple` immediately after title
     * This pre-sets mode so plan-2-clarify can skip Q1 (mode selection)
   - `## Research Context` (if research exists) – brief summary of key findings:
     * Components affected: [from research]
     * Critical dependencies: [from research]
     * Modification risks: [from research]
     * Link: See `research-dossier.md` for full analysis
   - `## Summary` – short WHAT/WHY overview
   - `## Goals` – bullet list of desired outcomes/user value (informed by research if available)
   - `## Non-Goals` – explicitly out-of-scope behavior (informed by research boundaries)
   - `## Complexity` – initial complexity assessment using CS 1-5 system (research-informed):
     * **Score**: CS-{1|2|3|4|5} ({trivial|small|medium|large|epic})
     * **Breakdown**: S={0-2}, I={0-2}, D={0-2}, N={0-2}, F={0-2}, T={0-2}
     * **Confidence**: {0.00-1.00} (agent's confidence in the score)
     * **Assumptions**: [list of assumptions made during scoring]
     * **Dependencies**: [external dependencies or blockers]
     * **Risks**: [complexity-related risks]
     * **Phases**: [suggested high-level phases; for CS ≥ 4 must include flags + rollout + rollback]

     Use the CS rubric from constitution:
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
   - `## ADR Seeds (Optional)` – capture decision context without solutioning:
     * Decision Drivers: [constraints/NFRs that push an architectural choice]
     * Candidate Alternatives: [A, B, C (one-line summaries)]
     * Stakeholders: [roles/names if known]
   - `## External Research` (if external-research/*.md files exist):
     * **Incorporated**: [List of external-research/*.md files used]
     * **Key Findings**: [Summary of external research insights that informed this spec]
     * **Applied To**: [Which spec sections benefited from external research]
   - `## Unresolved Research` (if UNRESOLVED_OPPORTUNITIES > 0):
     * **Topics**: [List from research-dossier.md External Research Opportunities not yet addressed]
     * **Impact**: [How this uncertainty affects the spec]
     * **Recommendation**: Consider addressing before architecture phase (plan-3)
   If `templates/spec-template.md` exists, you may reference it for wording, but this command must succeed without it.
4) For unknowns, embed `[NEEDS CLARIFICATION: ...]` markers within the appropriate section.
5) Write spec to SPEC_FILE and report branch + path.

Gates:
- Focus on user value; no stack/framework details.
- Mandatory sections present; acceptance scenarios are testable.
- If empty description, ERROR.

Output: SPEC_FILE ready for clarification.
```

The section order above defines the canonical spec structure referenced by downstream planning phases.

Next step (when happy): Run **/plan-2-clarify** for ≤5 high-impact questions.
