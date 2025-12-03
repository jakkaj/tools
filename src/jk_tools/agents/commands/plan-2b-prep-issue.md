---
description: Generate terse, industry-standard issue text from specs and plans for Azure DevOps, GitHub Issues, or any tracker.
---

# plan-2b-prep-issue

Generate concise, well-structured issue text from the feature specification and plan artifacts. This command creates terse, actionable issue content suitable for any issue tracker (GitHub, Azure DevOps, Jira, etc.).

**Purpose**: Extract clarity from complex specs. The issue is a signpost, not a replacement for the spec.

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
   - If SPEC_FILE not found: ERROR "Spec not found. Run /plan-1b-specify first."

2) **Determine issue type** (auto-detect or use --type flag):
   - If --phase N provided AND `${TASKS_DIR}/phase-N-*/tasks.md` exists:
     * TYPE = story (or task if --type task)
     * PHASE_DOSSIER = the tasks.md file
   - Else if PLAN_FILE exists:
     * TYPE = feature (plan context available)
   - Else:
     * TYPE = feature (spec-only)

3) **Extract content from artifacts**:

   **From SPEC_FILE** (always read):
   - TITLE = H1 heading text
   - SUMMARY = ## Summary section (2-3 sentences)
   - GOALS = ## Goals section (bullet points)
   - NON_GOALS = ## Non-Goals section (bullet points)
   - AC = ## Acceptance Criteria section (numbered list)
   - COMPLEXITY = ## Complexity section (CS score and breakdown)
   - RISKS = ## Risks & Assumptions section (key risks only)

   **From PLAN_FILE** (if exists and TYPE = feature):
   - CRITICAL_FINDINGS = top 3 from Critical Research Findings section
   - PHASE_COUNT = number of Implementation Phases
   - ADR_REFS = any ADR references from ADR Ledger

   **From PHASE_DOSSIER** (if TYPE = story/task):
   - PHASE_TITLE = Phase heading
   - PHASE_OBJECTIVE = from Executive Briefing > Purpose
   - PHASE_TASKS = task count from tasks table
   - PHASE_AC = derive from task Validation column (observable outcomes)

4) **Generate issue content**:

   **For TYPE = feature**:
   ```markdown
   # [TITLE]

   **Type**: Feature
   **Complexity**: [COMPLEXITY score] ([S,I,D,N,F,T breakdown])

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

   ## Key Risks

   [Top 2-3 risks from RISKS section, one line each]

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

   ## Objective

   [PHASE_OBJECTIVE from Executive Briefing]

   ## Acceptance Criteria

   [PHASE_AC - derived from task validations, numbered]

   ## Scope

   - Tasks: [PHASE_TASKS count]
   - [Brief scope from phase deliverables]

   ## Non-Goals (This Phase)

   [From phase Alignment Brief Non-Goals section if exists]

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

   ## Objective

   [Task description with context]

   ## Done When

   [Validation criteria from tasks table]

   ## Dependencies

   [From Dependencies column, or "None"]

   ## References

   - Phase Dossier: `[relative path to PHASE_DOSSIER]`

   ---
   *Generated from task dossier.*
   ```

5) **Save issue file**:
   - Create `${PLAN_DIR}/issues/` directory if not exists
   - ISSUE_SLUG = generate from title
   - For feature: `${PLAN_DIR}/issues/feature-[ISSUE_SLUG].md`
   - For story: `${PLAN_DIR}/issues/story-phase-[N]-[ISSUE_SLUG].md`
   - For task: `${PLAN_DIR}/issues/task-[TASK_ID]-[ISSUE_SLUG].md`
   - Write generated content to file

6) **Present output**:
   - Display the generated issue content
   - Show the saved file path
   - Remind user: "Copy to your issue tracker or request additional issues."

## Gates

- SPEC_FILE must exist
- Generated content must be terse (signpost, not duplication)
- All paths in References must be relative (repo-portable)
- No platform-specific fields (neutral markdown)

## Success Message

```
✅ Issue generated: [relative path to issue file]

Type: [feature|story|task]
Title: [TITLE]
Complexity: [CS score]

[Display generated issue content]

---
Copy the above to your issue tracker, or:
- Run again with --phase N for story-level issues
- Request additional issues for other phases
```

## Integration Notes

- Can run after /plan-1b-specify (spec only → feature issue)
- Can run after /plan-3-architect (with plan context → richer feature issue)
- Can run after /plan-5-phase-tasks-and-brief (with --phase N → story issues)
- Multiple runs accumulate in issues/ folder (one file per issue)
```
