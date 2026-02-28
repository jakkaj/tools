---
description: Generate terse, industry-standard issue text from specs and plans for Azure DevOps, GitHub Issues, or any tracker. Domain-aware v2.
---

Please deep think / ultrathink as this is a complex task.

# plan-2b-v2-prep-issue

Generate concise, well-structured issue text from the feature specification and plan artifacts. This command creates terse, actionable issue content suitable for any issue tracker (GitHub, Azure DevOps, Jira, etc.).

**Purpose**: Extract clarity from complex specs. The issue is a signpost, not a replacement for the spec.

---

## 🚫 NO TIME ESTIMATES

Use **Complexity Score (CS 1-5)** only — no hours, days, or story points.

---

```md
User input:

$ARGUMENTS
# Optional flags:
# --phase N     # Generate Story/Task level issue for phase N (requires plan-5 output)
# --type TYPE   # Override auto-detected type: feature|story|task

## Workflow

1) **Resolve plan folder and artifacts**:
   - Parse user input for plan folder path or feature slug
   - PLAN_DIR = `docs/plans/<ordinal>-<slug>/`
   - Locate available artifacts:
     * SPEC_FILE = `${PLAN_DIR}/<slug>-spec.md` (REQUIRED)
     * PLAN_FILE = `${PLAN_DIR}/<slug>-plan.md` (optional)
     * TASKS_DIR = `${PLAN_DIR}/tasks/` (optional)
   - If SPEC_FILE not found: ERROR "Spec not found. Run /plan-1b-v2-specify first."

2) **Load domain context** (additive — skip if no domains):
   - If `docs/domains/registry.md` exists → read registered domains
   - If `docs/domains/domain-map.md` exists → read domain topology
   - Read `## Target Domains` from SPEC_FILE (if present) → DOMAIN_LIST
   - If PLAN_FILE exists → read `## Target Domains` and `## Domain Manifest` tables
   - For each domain in DOMAIN_LIST → read `docs/domains/<slug>/domain.md` for:
     * Concepts, contracts, dependencies
   - Identify CROSS_DOMAIN_DEPS: domains that depend on each other per domain map
   - HAS_DOMAINS = true if any domain info found, false otherwise

3) **Determine issue type** (auto-detect or use --type flag):
   - If --phase N provided AND `${TASKS_DIR}/phase-N-*/tasks.md` exists:
     * TYPE = story (or task if --type task)
     * PHASE_DOSSIER = the tasks.md file
   - Else if PLAN_FILE exists:
     * TYPE = feature (plan context available)
   - Else:
     * TYPE = feature (spec-only)

4) **Extract content from artifacts**:

   **From SPEC_FILE** (always read):
   - TITLE = H1 heading text
   - SUMMARY = ## Summary section (2-3 sentences)
   - GOALS = ## Goals section (bullet points)
   - NON_GOALS = ## Non-Goals section (bullet points)
   - AC = ## Acceptance Criteria section (numbered list)
   - COMPLEXITY = ## Complexity section (CS score and breakdown)
   - RISKS = ## Risks & Assumptions section (key risks only)
   - TARGET_DOMAINS = ## Target Domains section (if present)

   **From PLAN_FILE** (if exists and TYPE = feature):
   - CRITICAL_FINDINGS = top 3 from Key Findings section
   - PHASE_COUNT = number of Implementation Phases
   - ADR_REFS = any ADR references
   - DOMAIN_MANIFEST = ## Domain Manifest table (file → domain mapping)

   **From PHASE_DOSSIER** (if TYPE = story/task):
   - PHASE_TITLE = Phase heading
   - PHASE_OBJECTIVE = from context brief / Purpose
   - PHASE_TASKS = task count from tasks table
   - PHASE_AC = derive from task Success Criteria column (observable outcomes)
   - PHASE_DOMAIN = Domain column from task table (primary domain for this phase)

5) **Generate issue content**:

   **For TYPE = feature**:
   ```markdown
   # [TITLE]

   **Type**: Feature
   **Complexity**: [COMPLEXITY score] ([S,I,D,N,F,T breakdown])
   [If HAS_DOMAINS:]
   **Domain**: [primary domain from TARGET_DOMAINS, or "multiple — see Domain Impact"]

   ## Objective

   [SUMMARY - 2-3 sentences on WHAT and WHY]

   ## Acceptance Criteria

   [AC - numbered, testable criteria from spec]

   ## Goals

   [GOALS - bullet points]

   ## Non-Goals

   [NON_GOALS - bullet points, keep terse]

   ## Context

   [If PLAN_FILE exists: "[PHASE_COUNT] implementation phases planned. See plan for details."]
   [If CRITICAL_FINDINGS: Brief mention of top constraint/finding]
   [If ADR_REFS: "Key decisions documented in: [ADR links]"]

   [If HAS_DOMAINS AND CROSS_DOMAIN_DEPS:]
   ### Cross-Domain Dependencies

   [List domain pairs with dependency direction and contract type, one line each.
    Example: "`billing` → `auth` (consumes: user identity contract)"]

   [If HAS_DOMAINS:]
   ## Domain Impact

   | Domain | Status | Relationship | Changes |
   |--------|--------|-------------|---------|
   [From TARGET_DOMAINS table — one row per domain touched]

   [If DOMAIN_MANIFEST exists: "See plan Domain Manifest for full file mapping."]

   ## Key Risks

   [Top 2-3 risks from RISKS section, one line each]

   ## Labels

   [If HAS_DOMAINS: Suggest domain labels, e.g., `domain:auth`, `domain:billing`]
   [Always suggest type label: `type:feature`]
   [If COMPLEXITY: suggest complexity label, e.g., `complexity:cs-3`]

   ## References

   - Spec: `[relative path to SPEC_FILE]`
   [If PLAN_FILE exists:]
   - Plan: `[relative path to PLAN_FILE]`

   ---
   *Generated from spec. See referenced documents for implementation details.*
   ```

   **For TYPE = story**:
   ```markdown
   # [PHASE_TITLE]

   **Type**: Story
   **Parent**: [TITLE] (Feature)
   **Phase**: [N] of [PHASE_COUNT]
   [If HAS_DOMAINS:]
   **Domain**: [PHASE_DOMAIN — primary domain for this phase]

   ## Objective

   [PHASE_OBJECTIVE from context brief]

   ## Acceptance Criteria

   [PHASE_AC - derived from task success criteria, numbered]

   ## Scope

   - Tasks: [PHASE_TASKS count]
   - [Brief scope from phase deliverables]

   ## Non-Goals (This Phase)

   [From phase brief Non-Goals section if exists]

   [If HAS_DOMAINS AND phase touches multiple domains:]
   ## Cross-Domain Notes

   [Which other domains this phase touches and why — one line each]

   ## Labels

   [If HAS_DOMAINS: `domain:[PHASE_DOMAIN]`]
   `type:story`, `phase:[N]`

   ## References

   - Spec: `[relative path to SPEC_FILE]`
   - Plan: `[relative path to PLAN_FILE]`
   - Phase Dossier: `[relative path to PHASE_DOSSIER]`

   ---
   *Generated from phase dossier. See referenced documents for task details.*
   ```

   **For TYPE = task**:
   ```markdown
   # [Task description from tasks table]

   **Type**: Task
   **Parent**: [PHASE_TITLE] (Story)
   **Task ID**: [T00N]
   [If HAS_DOMAINS:]
   **Domain**: [domain from task table Domain column]

   ## Objective

   [Task description with context]

   ## Done When

   [Success criteria from tasks table]

   ## Dependencies

   [From Dependencies column, or "None"]
   [If HAS_DOMAINS and task depends on another domain's contract:]
   ⚠️ Cross-domain: depends on `[other-domain]` contract — coordinate changes.

   ## Labels

   [If HAS_DOMAINS: `domain:[task-domain]`]
   `type:task`

   ## References

   - Phase Dossier: `[relative path to PHASE_DOSSIER]`

   ---
   *Generated from task dossier.*
   ```

6) **Save issue file**:
   - Create `${PLAN_DIR}/issues/` directory if not exists
   - ISSUE_SLUG = generate from title
   - For feature: `${PLAN_DIR}/issues/feature-[ISSUE_SLUG].md`
   - For story: `${PLAN_DIR}/issues/story-phase-[N]-[ISSUE_SLUG].md`
   - For task: `${PLAN_DIR}/issues/task-[TASK_ID]-[ISSUE_SLUG].md`
   - Write generated content to file

7) **Present output**:
   - Display the generated issue content
   - Show the saved file path
   - Remind user: "Copy to your issue tracker or request additional issues."

## Gates

- SPEC_FILE must exist
- Generated content must be terse (signpost, not duplication)
- All paths in References must be relative (repo-portable)
- No platform-specific fields (neutral markdown)
- No time estimates — CS scores only

## Success Message

```
✅ Issue generated: [relative path to issue file]

Type: [feature|story|task]
Title: [TITLE]
Complexity: [CS score]
[If HAS_DOMAINS: "Domains: [list]"]
[If HAS_DOMAINS: "Suggested labels: [domain labels]"]

[Display generated issue content]

---
Copy the above to your issue tracker, or:
- Run again with --phase N for story-level issues
- Request additional issues for other phases
```

## Integration Notes

- Can run after /plan-1b-v2-specify (spec only → feature issue)
- Can run after /plan-3-v2-architect (with plan context → richer feature issue with domain impact)
- Can run after /plan-5-v2-phase-tasks-and-brief (with --phase N → domain-aware story issues)
- Multiple runs accumulate in issues/ folder (one file per issue)
- Domain awareness is additive — issues generate correctly without domains
```
