# Research Report: Flight Plan Section for plan-5 and plan-5a

**Generated**: 2026-01-31
**Research Query**: "Add a Flight Plan section to /plan-5 and /plan-5a that lists all files to be changed/created with provenance, duplication checks, and recommendations"
**Mode**: Pre-Plan
**Location**: docs/plans/013-flight-plan/research-dossier.md
**FlowSpace**: N/A (research phase)

## Executive Summary

### What It Does
The Flight Plan is a new section in the `tasks.md` dossier (output of plan-5 and plan-5a) that inventories every file the phase will touch — with provenance (which plan created it, which plans modified it), duplication checks (has this concept already been implemented?), and actionable recommendations (should this file move, should we extract shared code, etc.).

### Business Purpose
Prevents the "we already have that" problem where agents re-create functionality that exists elsewhere. Provides the implementing agent (plan-6) with full situational awareness about every file before it writes a single line.

### Key Insights
1. **Insertion point**: The Flight Plan goes between `## Objectives & Scope` and `## Architecture Map` in both plan-5 and plan-5a output
2. **Provenance discovery** uses a 3-tier strategy: FlowSpace (best) → Explore subagent (good) → inline Grep/Read (fallback)
3. **Duplication checks** must cover not just file names but method signatures and concept overlap
4. **PlanPak awareness** makes provenance easier (files in `features/<ordinal>-<slug>/` self-document their origin plan) but the Flight Plan must also work for Legacy file management

### Quick Stats
- **Files to modify**: 2 (plan-5-phase-tasks-and-brief.md, plan-5a-subtask-tasks-and-brief.md)
- **Section size**: ~60-80 lines added to each file (template + subagent instructions)
- **Subagent count**: 1 parallel subagent per file in the flight plan (FlowSpace-first with fallback)
- **PlanPak interaction**: Enhanced provenance when active, graceful degradation when Legacy

---

## How plan-5 and plan-5a Currently Work

### plan-5 Output Structure (tasks.md)
```
Phase metadata + links
## Executive Briefing
## Objectives & Scope
                         ← FLIGHT PLAN GOES HERE
## Architecture Map
  ### Component Diagram (Mermaid)
  ### Task-to-Component Mapping
## Tasks (canonical table)
## Alignment Brief
## Discoveries & Learnings
## Evidence Artifacts
```

### plan-5a Output Structure (subtask dossier)
```
Subtask metadata + parent links
## Parent Context
## Executive Briefing
## Objectives & Scope
                         ← FLIGHT PLAN GOES HERE
## Architecture Map
  ### Component Diagram (Mermaid)
  ### Task-to-Component Mapping
## Tasks (ST### table)
## Alignment Brief
## Discoveries & Learnings
## After Subtask Completion
## Evidence Artifacts
```

### Current File Reference Points
- **Task table**: `Absolute Path(s)` column lists every file per task
- **Architecture Map**: Mermaid diagram links tasks to files
- **Task-to-Component Mapping**: Table maps tasks to components and files
- **Alignment Brief**: Mentions inputs to read

### Gap
No section currently answers: "What is the history of this file? Has something like this already been built? Should this file be somewhere else?" The task table says *what* files to touch but not *why this file exists* or *what else touches it*.

---

## Flight Plan Section Design

### What Goes In It

For each file the phase will create or modify:

| Field | Purpose | Source |
|-------|---------|--------|
| **File** | Absolute path | From plan task table |
| **Action** | Create / Modify / Delete | Inferred from plan |
| **Origin Plan** | Which plan created this file | Subagent: scan execution logs, PlanPak manifests, git blame |
| **Also Modified By** | Other plans that touched this file | Subagent: scan execution logs |
| **Similar Concepts** | Existing files/methods with overlapping purpose | Subagent: search codebase |
| **Recommendation** | Move, extract shared, keep as-is, etc. | Subagent analysis |

### Provenance Discovery Strategy

```
Tier 1: FlowSpace MCP available?
  → flowspace.search() for file references across plans
  → flowspace.tree() to map file relationships
  → Fast, structured, semantic search for similar concepts

Tier 2: FlowSpace unavailable, use Explore subagent
  → Task subagent_type="Explore" with targeted queries
  → Grep execution logs for file paths
  → Grep plan manifests for file references
  → Good coverage, slightly slower

Tier 3: Inline fallback (no subagent overhead)
  → Direct Grep/Glob/Read calls
  → Scan docs/plans/*/execution.log.md for file paths
  → Scan docs/plans/*-plan.md task tables for Absolute Path(s) matches
  → Minimal but functional
```

### Duplication Check Strategy

For each **new** file the phase plans to create:
1. Search for files with similar names (fuzzy match)
2. Search for classes/functions with similar names to what will be created
3. Search for concepts (semantic if FlowSpace available, keyword otherwise)
4. Report any matches with file paths and brief descriptions

### Recommendations Engine

Based on provenance and duplication findings:
- **"Keep as-is"**: File is well-placed, no conflicts
- **"Extract to shared"**: File is in a plan-scoped location but 3+ plans reference it (Rule of Three)
- **"Reuse existing"**: A similar concept already exists — import instead of recreate
- **"Consider moving"**: File is in an unexpected location for its usage pattern
- **"Cross-plan edit"**: File belongs to another plan — edit in place, tag as cross-plan-edit

---

## Subagent Design

### Single Provenance Subagent (launched per phase, not per file)

The Flight Plan section uses **one subagent** that investigates all files at once. This is more efficient than per-file subagents because:
- Many files share the same execution logs
- One scan of `docs/plans/` covers all files
- Cross-file analysis reveals shared patterns

**Subagent prompt template** (for plan-5 step):

```
"Build a Flight Plan for Phase [N] of plan [PLAN_PATH].

Files to investigate:
[LIST OF FILES FROM PLAN TASK TABLE]

For each file, determine:
1. PROVENANCE: Which plan created this file? Scan:
   - docs/plans/*/execution.log.md for file path mentions
   - docs/plans/*-plan.md task tables (Absolute Path(s) column)
   - If PlanPak active: check features/<ordinal>-<slug>/ folder names
   - git log --follow --diff-filter=A -- <filepath> for creation commit
2. MODIFICATION HISTORY: Which other plans modified this file?
   - Same sources as provenance
   - git log --oneline -- <filepath> for commit history
3. DUPLICATION CHECK (for NEW files only):
   - Search for similarly-named files: Glob(**/*<similar>*)
   - Search for similar class/function names: Grep(class <Name>, def <Name>)
   - If FlowSpace available: semantic search for the concept
4. RECOMMENDATION: Based on findings, suggest one of:
   - keep-as-is | extract-to-shared | reuse-existing | consider-moving | cross-plan-edit

FlowSpace Detection:
- Try flowspace.tree(pattern='.', max_depth=1) first
- If available: use flowspace.search() for semantic concept matching
- If unavailable: use Glob/Grep/Read fallback

Output format:
For each file, return a structured block:
### <filepath>
- **Action**: Create | Modify
- **Origin**: Plan <NNN>-<slug> (T<XXX>) | New file | Pre-plan (existed before plans)
- **Modified by**: Plan <NNN> (T<XXX>), Plan <MMM> (T<YYY>) | None
- **Similar concepts found**: <filepath>:<class/function> — <brief description> | None
- **Recommendation**: <tag> — <one-line rationale>
"
```

---

## Integration with Existing Workflow

### How It Fits in plan-5 Execution

Current plan-5 steps:
```
1) Verify PLAN, create PHASE_DIR
1a) Subagent review of prior phases (if not Phase 1)
2) Read Critical Research Findings
2a) Read ADRs
3) Locate phase heading
4) Read plan-3's task table
5) Transform/expand tasks into canonical format
6) Write tasks.md
```

New step inserted:
```
1) Verify PLAN, create PHASE_DIR
1a) Subagent review of prior phases
2) Read Critical Research Findings
2a) Read ADRs
3) Locate phase heading
4) Read plan-3's task table
5) Transform/expand tasks into canonical format
5a) NEW: Launch Flight Plan subagent ← files are known after step 5
6) Write tasks.md (now includes Flight Plan section)
```

Step 5a launches the provenance subagent **after** the task table is formed (so file list is known) but **before** writing tasks.md (so findings can be included).

### How It Fits in plan-5a Execution

Similar insertion after step 4 (content expectations) when the subtask file list is known.

---

## Prior Learnings

### PL-01: PlanPak v1 Symlink Breakage
**Source**: docs/plans/012-planpak/ (rollback to bab7861)
**Type**: gotcha
**Relevance**: The Flight Plan must work with both PlanPak and Legacy file management. PlanPak folders (`features/<ordinal>-<slug>/`) make provenance trivial (the folder name IS the plan ordinal). Legacy mode requires scanning execution logs.

### PL-02: Execution Log File Path Format
**Source**: docs/plans/012-planpak/execution.log.md
**Type**: insight
**Relevance**: Execution logs use backtick-quoted relative paths (e.g., `` `agents/commands/planpak.md` ``). Grep patterns must account for backtick wrapping.

### PL-03: Plan Task Table Absolute Paths
**Source**: docs/plans/001-ghcp-prompt-mirroring/ through 012-planpak/
**Type**: insight
**Relevance**: Plan task tables use absolute paths in `Absolute Path(s)` column. These are the most reliable source for file → plan mapping.

---

## Recommendations

### If Implementing This Feature
1. Keep the Flight Plan section concise — a table + per-file subsections only when findings warrant detail
2. The subagent should be `subagent_type="Explore"` when FlowSpace is unavailable (it has access to Glob/Grep/Read)
3. For FlowSpace mode, use `subagent_type="general-purpose"` with explicit FlowSpace tool instructions
4. The Flight Plan should be generated even for Phase 1 (no prior phases) — it still catches duplication
5. PlanPak detection should use the same dual-signal check: spec header `File Management: PlanPak` OR T000 in plan

### Template Size
Keep the addition to each command file under 80 lines:
- ~15 lines for the output template (table + subsection format)
- ~40 lines for the subagent instructions
- ~15 lines for FlowSpace detection and fallback logic
- ~10 lines for integration notes

---

**Research Complete**: 2026-01-31
**Report Location**: docs/plans/013-flight-plan/research-dossier.md
