# Flight Plan Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-01-31
**Spec**: [./flight-plan-spec.md](./flight-plan-spec.md)
**Status**: DRAFT

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Implementation](#implementation)
4. [Change Footnotes Ledger](#change-footnotes-ledger)

## Executive Summary

Add a `## Flight Plan` section to the output of `/plan-5` and `/plan-5a`. This section audits every file the phase will touch: provenance (which plan created/modified it), duplication check (does a similar concept already exist?), and compliance check (do planned changes conform to ADRs, rules, idioms, and architecture?). A single subagent gathers all evidence using FlowSpace (preferred), Explore (fallback), or inline Grep/Read (final fallback). The Flight Plan is the pre-flight checklist — no implementation starts until every item is checked.

## Critical Research Findings (Concise)

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | High | plan-5 step 6 describes the tasks.md output structure — the Flight Plan section description must be inserted between `## Objectives & Scope` (line 383) and `## Architecture Map` (line 413) | Add `## Flight Plan` output description at line 412 in plan-5 |
| 02 | High | plan-5a step 4 describes the subtask dossier output — equivalent insertion point between `## Objectives & Scope` (line 316) and `## Architecture Map` (line 340) | Add `## Flight Plan` output description at line 339 in plan-5a |
| 03 | High | plan-5 step 5 transforms tasks (line 288-351); step 6 writes output (line 352+). New subagent step must go between them | Insert new step 5a (Flight Plan subagent) between step 5 and step 6 in plan-5 |
| 04 | High | plan-5a step 4 defines content (line 267-489); step 5 is safeguards (line 490). Subagent step goes after file list is known from step 4 | Insert new step 4a (Flight Plan subagent) between step 4 and step 5 in plan-5a |
| 05 | Medium | The sample output structure in the plan-5 preamble (lines 28-145) shows the sections in order — Flight Plan should appear in this sample too | Update sample output structure to include `## Flight Plan` |
| 06 | Medium | plan-5a sample output (lines 32-166) also needs the Flight Plan in the section list | Update plan-5a sample output structure to include `## Flight Plan` |
| 07 | Medium | Execution logs use backtick-quoted relative paths (e.g., `` `agents/commands/planpak.md` ``); subagent prompt must account for this | Subagent instructions include both absolute and relative path search patterns |
| 08 | Medium | PlanPak folders (`features/<ordinal>-<slug>/`) self-document their origin plan; subagent should check for this pattern first when PlanPak active | Subagent prompt includes PlanPak-aware provenance shortcut |
| 09 | Medium | flowspace-research.md (line 47-80) has the canonical FlowSpace detection pattern with graceful fallback | Reuse the same try/catch pattern for FlowSpace detection in subagent instructions |
| 10 | Low | README.md for agents/commands/ may need a note about the Flight Plan feature | Optional — can be deferred; the section is internal to plan-5/5a output |

## Implementation (Single Phase)

**Objective**: Add Flight Plan section to plan-5 and plan-5a command files with subagent instructions and output template

**Testing Approach**: Manual (run `./setup.sh`, verify deployment)
**Mock Usage**: N/A

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [ ] | T001 | Add Flight Plan subagent step to plan-5 | 2 | Core | -- | /home/jak/github/tools/agents/commands/plan-5-phase-tasks-and-brief.md | New step 5a exists between step 5 (line 288) and step 6 (line 352) with subagent launch instructions | See detailed instructions below |
| [ ] | T002 | Add Flight Plan output template to plan-5 tasks.md structure | 2 | Core | T001 | /home/jak/github/tools/agents/commands/plan-5-phase-tasks-and-brief.md | `## Flight Plan` section described between `## Objectives & Scope` and `## Architecture Map` in step 6 output spec | Lines 412-413 area |
| [ ] | T003 | Update plan-5 sample output to include Flight Plan | 1 | Core | T002 | /home/jak/github/tools/agents/commands/plan-5-phase-tasks-and-brief.md | Sample output structure (lines 28-145) shows `## Flight Plan` in section order | Between lines 76 and 78 in sample |
| [ ] | T004 | Add Flight Plan subagent step to plan-5a | 2 | Core | T001 | /home/jak/github/tools/agents/commands/plan-5a-subtask-tasks-and-brief.md | New step 4a exists between step 4 (line 267) and step 5 (line 490) with subagent launch instructions | Mirror plan-5 subagent, adapted for subtask scope |
| [ ] | T005 | Add Flight Plan output template to plan-5a subtask dossier structure | 2 | Core | T004 | /home/jak/github/tools/agents/commands/plan-5a-subtask-tasks-and-brief.md | `## Flight Plan` section described between `## Objectives & Scope` and `## Architecture Map` in step 4 output spec | Lines 339-340 area |
| [ ] | T006 | Update plan-5a sample output to include Flight Plan | 1 | Core | T005 | /home/jak/github/tools/agents/commands/plan-5a-subtask-tasks-and-brief.md | Sample output structure (lines 32-166) shows `## Flight Plan` in section order | Between lines 90 and 93 in sample |
| [ ] | T007 | Run setup.sh and verify deployment | 1 | Integ | T001-T006 | /home/jak/github/tools/setup.sh | 10/10 install success; both modified files synced to src/jk_tools/ and deployed | Manual verification |

### Detailed Task Instructions

#### T001: Flight Plan subagent step in plan-5

Insert a new step **5a)** between the existing step 5 (task expansion, ending around line 351) and step 6 (write tasks.md, starting at line 352).

**What to insert** (new step 5a):

```markdown
5a) **Launch Flight Plan subagent** to audit all files from the expanded task table:

   After step 5 completes, the full file list is known from the `Absolute Path(s)` column. Launch a single subagent to build the Flight Plan.

   **FlowSpace Detection**: Try `flowspace.tree(pattern=".", max_depth=1)` first.
   - If available: use `subagent_type="general-purpose"` with FlowSpace tool instructions
   - If unavailable: use `subagent_type="Explore"` (has Glob/Grep/Read access)

   **Subagent Prompt**:
   "Build a Flight Plan for [PHASE_TITLE] of plan [PLAN_PATH].

   Files to investigate (from task table Absolute Path(s) column):
   [LIST EVERY FILE FROM EXPANDED TASK TABLE]

   For EACH file, determine:

   1. **ACTION**: Is this file being Created (new) or Modified (exists)?
      - Check: Does the file exist on disk? (ls/stat or Glob)

   2. **PROVENANCE** (for Modified files):
      - Which plan created this file? Search:
        * `docs/plans/*/execution.log.md` for the file path (grep both absolute and relative forms, account for backtick wrapping)
        * `docs/plans/*-plan.md` task tables for the path in Absolute Path(s) columns
        * If PlanPak active: check if file lives in `features/<ordinal>-<slug>/` — the ordinal IS the origin plan
        * `git log --follow --diff-filter=A -- <filepath>` for creation commit
      - Which OTHER plans modified it?
        * Same sources as above — collect all plan references
        * `git log --oneline -- <filepath>` for commit history cross-referenced with plan commits

   3. **DUPLICATION CHECK** (for Created files only):
      - Search for similarly-named files: `Glob(**/*<basename-stem>*)`
      - Search for similar class/function names that the task plans to create: `Grep(class <Name>)`, `Grep(def <Name>)`, `Grep(function <Name>)`
      - If FlowSpace available: `flowspace.search(pattern='<concept>', mode='semantic')`
      - Report matches with file paths and one-line descriptions

   4. **COMPLIANCE CHECK** (for ALL files):
      - If `docs/adr/` exists: scan ADRs for constraints that affect this file's location, naming, or patterns
      - If `docs/project-rules/rules.md` exists: check planned changes against project rules
      - If `docs/project-rules/idioms.md` exists: check naming, patterns, and conventions
      - If `docs/project-rules/architecture.md` exists: check layer boundaries, dependency direction
      - If PlanPak active: verify file classification tag is correct per decision tree
      - Report any violations as: SEVERITY (HIGH/MEDIUM/LOW) | Rule/ADR violated | What's wrong | Suggested fix

   5. **RECOMMENDATION**: Based on findings, assign one of:
      - `keep-as-is` — File is well-placed, no conflicts, compliant
      - `reuse-existing` — Similar concept already exists; import/extend instead of recreate
      - `extract-to-shared` — File is plan-scoped but 3+ plans reference it (Rule of Three)
      - `consider-moving` — File is in an unexpected location for its usage pattern
      - `cross-plan-edit` — File belongs to another plan; edit in place, tag accordingly
      - `compliance-warning` — File placement or pattern violates a rule/ADR

   **Output format** — return TWO sections:

   SECTION 1: Summary table (one row per file):
   | File | Action | Origin | Modified By | Recommendation |
   |------|--------|--------|-------------|----------------|
   | /abs/path/file.ts | Create | New | — | keep-as-is |
   | /abs/path/other.py | Modify | Plan 003 (T002) | Plan 007 (T005) | cross-plan-edit |

   SECTION 2: Per-file detail (only for files with findings):
   ### /abs/path/file.ts
   **Duplication check**: Found similar `src/utils/existing-helper.ts:helperFunction` — consider reusing
   **Compliance**: No violations

   ### /abs/path/other.py
   **Provenance**: Created by Plan 003-auth (T002), also modified by Plan 007-copilot (T005)
   **Compliance**: HIGH — violates ADR-0003 (layer boundary); file is in service layer but imports from presentation

   SECTION 3: Compliance summary (only if violations found):
   ### Compliance Check
   | Severity | File | Rule/ADR | Violation | Suggested Fix |
   |----------|------|----------|-----------|---------------|
   | HIGH | /abs/path/other.py | ADR-0003 | Imports from presentation layer | Move import to adapter layer |
   "

   - **Capture subagent output** and include it verbatim in the `## Flight Plan` section of tasks.md
   - If subagent finds `reuse-existing` recommendations, flag these prominently — the task table may need adjustment
   - If compliance violations are HIGH severity, add a note in the Flight Plan that implementation should address these before proceeding
```

#### T002: Flight Plan output template in plan-5

In step 6 (the `Write a single combined artifact` section), insert a new bullet between the `## Objectives & Scope` description (ending around line 412) and the `## Architecture Map` description (starting at line 413).

**What to insert**:

```markdown
   - `## Flight Plan` section (generated by step 5a) containing the pre-implementation file audit:
     * **Summary Table**: One row per file with columns: File, Action, Origin, Modified By, Recommendation
     * **Per-File Detail**: Subsections for files with findings (duplication matches, provenance chain, compliance issues)
     * **Compliance Check**: Table of any ADR/rules/idioms/architecture violations with severity ratings
     * If step 5a subagent returned no findings: include section with note "No findings — all files are new or have clean provenance"
     * If `reuse-existing` recommendations found: add prominent callout that task table may need revision
     * If HIGH compliance violations found: add note that these must be addressed before implementation
```

#### T003: Update plan-5 sample output

In the sample output structure near the top of plan-5 (around lines 56-77), add `## Flight Plan` between `## Objectives & Scope` and `## Architecture Map`. Also add it to the `### Sample Output Structure` section.

**What to insert** (between the Objectives/Scope and Architecture sections in the sample):

```markdown
## Flight Plan

### Summary
| File | Action | Origin | Modified By | Recommendation |
|------|--------|--------|-------------|----------------|
| /abs/path/src/handlers/base.py | Modify | Pre-plan | — | keep-as-is |
| /abs/path/tests/test_api.py | Create | New | — | keep-as-is |
| /abs/path/src/api/endpoint.py | Create | New | — | keep-as-is |

### Compliance Check
No violations found.

---
```

#### T004: Flight Plan subagent step in plan-5a

Insert a new step **4a)** between step 4 (content expectations, ending around line 489) and step 5 (safeguards, starting at line 490). This mirrors the plan-5 subagent but is scoped to the subtask's file list.

**What to insert**: Same subagent structure as T001, but:
- References `${SUBTASK_FILE}` instead of `PHASE_DIR/tasks.md`
- File list comes from the ST### task table (step 4's content)
- Subagent prompt says "subtask" instead of "phase"
- Parent task files are included in the audit (they may be cross-plan edits)

#### T005: Flight Plan output template in plan-5a

In step 4 content expectations, insert `## Flight Plan` between `## Objectives & Scope` (around line 339) and `## Architecture Map` (around line 340). Same template as T002 but scoped to subtask.

#### T006: Update plan-5a sample output

In the sample output near the top of plan-5a (around lines 71-93), add `## Flight Plan` between `## Objectives & Scope` and `## Architecture Map`. Same pattern as T003.

#### T007: Run setup.sh

```bash
./setup.sh
```
Verify 10/10 success. Confirm both modified files synced to `src/jk_tools/agents/commands/` and deployed to `~/.claude/commands/`.

### Acceptance Criteria
- [x] AC1: plan-5 output describes `## Flight Plan` between Objectives and Architecture Map
- [x] AC2: plan-5a output describes `## Flight Plan` in equivalent position
- [x] AC3: Summary table has columns: File, Action, Origin, Modified By, Recommendation
- [x] AC4: Duplication check for Created files
- [x] AC5: Provenance for Modified files
- [x] AC6: Compliance Check subsection validates against ADRs/rules/idioms/architecture
- [x] AC7: Compliance violations reported with severity
- [x] AC8: Subagent launched with FlowSpace → Explore → inline fallback
- [x] AC9: PlanPak-aware provenance
- [x] AC10: setup.sh 10/10
- [x] AC11: Empty Flight Plan handled gracefully

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Subagent prompt too long for context | Low | Medium | Keep prompt under 60 lines; delegate detail to existing flowspace-research patterns |
| Insertion points shift if plan-5/5a are edited concurrently | Low | Medium | Use content anchors (section headings) not line numbers for insertion |

## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "/home/jak/github/tools/docs/plans/013-flight-plan/flight-plan-plan.md"`
- **Optional validation**: `/plan-4-complete-the-plan` (recommended given subagent prompt complexity)
