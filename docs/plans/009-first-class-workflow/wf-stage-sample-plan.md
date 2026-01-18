# Workflow Stage Sample Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2025-01-18
**Spec**: [./wf-stage-sample-spec.md](./wf-stage-sample-spec.md)
**Status**: COMPLETE

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Implementation](#implementation)
4. [Change Footnotes Ledger](#change-footnotes-ledger)

## Executive Summary

**Problem**: We need to validate the workflow schema design before building automation.

**Solution**: Create a static folder structure that mimics what the WF system would generate for the `01-explore` stage, with real sample files that a coding agent can execute against.

**Expected Outcome**: A testable `enhance/sample/sample_1/` directory where we can manually point an agent at `prompt/wf.md` and verify it produces reasonable outputs.

## Critical Research Findings (Concise)

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | High | Schema defined in workflow-schema-simple.md | Follow exact folder structure from that doc |
| 02 | High | /plan-1a-explore.md is 830 lines with command-specific logic | Transform per detailed diff below |
| 03 | Medium | stage-config.json needs input/output declarations | Include realistic JSON showing expected contract |
| 04 | Medium | wf.md must bootstrap agent understanding | Keep it short - point to stage-config.json and main.md |
| 05 | Low | Output files need sample content | Use realistic but minimal examples |

---

## Prompt Transformation: /plan-1a-explore.md → main.md

### Summary

Transform the 830-line command prompt into a ~400-line standalone stage prompt by:
- **REMOVING** command infrastructure (argument parsing, plan folder management, output routing)
- **KEEPING** core research logic (subagents, synthesis, report template)
- **ADDING** WF stage context (read inputs/, write to run/output-files/)

### REMOVE (Command-Specific Infrastructure)

| Lines | Section | Why Remove |
|-------|---------|------------|
| 1-6 | YAML frontmatter + ultrathink | WF system handles this |
| 11-21 | `$ARGUMENTS` block | Inputs come from `inputs/user-description.md` |
| 28-44 | `## Behavior` (console vs file) | Always outputs to `run/output-files/` |
| 34-71 | `### 1) Parse Input` + `### 1a) Plan Folder Management` | WF system provides inputs, handles outputs |
| 718-743 | `### 6) Output Research` | WF system handles output routing |
| 745-760 | `## CRITICAL: STOP AND WAIT` | WF system handles stage completion |
| 762-772 | `## Error Handling` | Simplify - keep only research errors |
| 787-830 | `## Integration with Other Commands` + `## Examples` | Command-specific, not relevant |

### KEEP (Core Research Logic)

| Lines | Section | Notes |
|-------|---------|-------|
| 73-113 | `### 2) FlowSpace MCP Detection` | Keep - still useful for enhanced exploration |
| 102-113 | `### 2a) FlowSpace API Discovery` | Keep - runtime capability detection |
| 115-377 | `### 3) Launch Parallel Research Subagents` | **CORE** - keep all 7 subagent prompts |
| 380-400 | `### 4) Synthesize Research Findings` | **CORE** - keep synthesis logic |
| 402-716 | `### 5) Generate Research Report` | **CORE** - keep full report template |
| 775-785 | `## Success Criteria` | Keep as quality checklist |

### MODIFY (Adapt for Stage Context)

| Original | Change To |
|----------|-----------|
| "User input: $ARGUMENTS" | "Read research query from: `inputs/user-description.md`" |
| "[RESEARCH_TOPIC]" placeholder | "Read from `inputs/user-description.md`" |
| "Output to console or plan folder" | "Write to `run/output-files/research-dossier.md`" |
| "Creates research-dossier.md" | "Creates `run/output-files/research-dossier.md`" |
| Section headers "## Purpose" | Add "This stage..." context |

### ADD (WF Stage Infrastructure)

**Add at top (new section):**
```markdown
# 01-explore Stage: Codebase Research

## Stage Context

You are executing a workflow stage. Before proceeding:

1. **Read stage configuration**: `../stage-config.json`
   - Understand declared inputs and expected outputs
   - Note any stage-specific parameters

2. **Read your input**: `../inputs/user-description.md`
   - This contains the research query/topic
   - This is your [RESEARCH_TOPIC]

3. **Your outputs go to**:
   - `../run/output-files/research-dossier.md` - Main research report
   - `../run/output-data/wf-result.json` - Stage completion status
   - `../run/output-data/findings.json` - Structured findings data
```

**Add at end (new section):**
```markdown
## Stage Completion

When research is complete:

1. **Write research-dossier.md** to `../run/output-files/`
2. **Write wf-result.json** to `../run/output-data/`:
   ```json
   {
     "status": "success",
     "completed_at": "[ISO-8601 timestamp]",
     "findings_count": [N],
     "critical_findings": [N],
     "flowspace_used": true|false
   }
   ```
3. **Write findings.json** to `../run/output-data/`:
   ```json
   {
     "findings": [
       {"id": "IA-01", "category": "implementation", "impact": "critical", "title": "...", "summary": "..."},
       ...
     ],
     "summary": {
       "total": N,
       "by_impact": {"critical": N, "high": N, "medium": N, "low": N}
     }
   }
   ```

Stage is complete. WF system will handle next steps.
```

### Line-by-Line Transformation Summary

| Original Lines | Action | Result Lines (approx) |
|----------------|--------|----------------------|
| 1-6 | DELETE | - |
| 7-10 | MODIFY | New header + stage context (~20 lines) |
| 11-71 | DELETE | - |
| 73-113 | KEEP | Same |
| 115-377 | KEEP | Same (subagents) |
| 380-400 | KEEP | Same (synthesis) |
| 402-716 | KEEP | Same (report template) |
| 718-760 | DELETE + ADD | Stage completion section (~30 lines) |
| 762-785 | MODIFY | Simplified error handling + success criteria |
| 787-830 | DELETE | - |

**Estimated result**: ~450 lines (down from 830)

## Implementation (Single Phase)

**Objective**: Create the complete folder structure and sample files for the 01-explore stage.

**Testing Approach**: Manual - point an agent at wf.md and verify it understands the structure
**Mock Usage**: N/A

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T001 | Create base directory structure | 1 | Setup | -- | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/ | All folders exist | Create full tree including inputs/, prompt/, run/output-files/, run/output-data/, run/runtime-inputs/ |
| [x] | T002 | Create wf-run.json | 1 | Core | T001 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/wf-run.json | Valid JSON, empty object for now | `{}` placeholder |
| [x] | T003 | Create stage-config.json | 2 | Core | T001 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/stage-config.json | Valid JSON with inputs/outputs declared | Define expected inputs and outputs |
| [x] | T004 | Create user-description.md input | 1 | Core | T001 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/inputs/user-description.md | Contains sample feature description | Realistic sample: "research how the auth system works" |
| [x] | T005 | Create prompt/wf.md entry point | 2 | Core | T003 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/prompt/wf.md | Agent can understand WF context | Bootstrap prompt pointing to stage-config and main.md |
| [x] | T006 | Create prompt/main.md | 2 | Core | T005 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/prompt/main.md | Refactored /plan-1a-explore prompt | Follow transformation spec above: REMOVE command infra, KEEP research logic, ADD stage context |
| [x] | T007 | Create sample output files | 1 | Core | T001 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/run/output-files/research-dossier.md | Shows expected output structure | Sample/placeholder showing format |
| [x] | T008 | Create sample output data | 1 | Core | T001 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/run/output-data/wf-result.json, findings.json | Valid JSON showing schema | Sample structured data |
| [x] | T009 | Create runtime-inputs manifest | 1 | Core | T001 | /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2024-01-18-001/stages/01-explore/run/runtime-inputs/manifest.json | Valid JSON | Empty array placeholder |

### Acceptance Criteria
- [x] All folders exist per spec appendix
- [x] All JSON files are valid
- [x] prompt/wf.md clearly instructs agent to read stage-config.json then main.md
- [x] prompt/main.md is a standalone prompt (no $ARGUMENTS or conversation context)
- [x] Sample outputs show expected structure

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Prompt loses functionality when refactored | Medium | Medium | Keep core research instructions, remove orchestration complexity |
| Sample data too trivial | Low | Low | Use realistic "auth system research" example |

## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "docs/plans/009-first-class-workflow/wf-stage-sample-plan.md"`
- **Optional validation**: `/plan-4-complete-the-plan` (not needed for CS-2)
