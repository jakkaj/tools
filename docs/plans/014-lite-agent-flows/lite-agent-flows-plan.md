# Lite Agent Command Pipeline Extraction — Implementation Plan

**Plan Version**: 1.0.0
**Created**: 2026-02-20
**Spec**: [./lite-agent-flows-spec.md](./lite-agent-flows-spec.md)
**Research**: [./research-dossier.md](./research-dossier.md)
**Workshops**:
- [Plan-6 Inline Progress Tracking](./workshops/plan-6-inline-progress-tracking.md)
- [Plan-3 Research Subagent Rewrite](./workshops/plan-3-research-subagent-rewrite.md)
- [Lite Pipeline Flow & Architecture](./workshops/lite-pipeline-flow-architecture.md)
**Status**: DRAFT
**Mode**: Full
**File Management**: PlanPak

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technical Context](#technical-context)
3. [Critical Research Findings](#critical-research-findings)
4. [File Placement Manifest](#file-placement-manifest)
5. [Testing Philosophy](#testing-philosophy)
6. [Phase 1: Infrastructure & Easy Extractions](#phase-1-infrastructure--easy-extractions)
7. [Phase 2: Hard Command Rewrites](#phase-2-hard-command-rewrites)
8. [Phase 3: Lite Documentation](#phase-3-lite-documentation)
9. [Phase 4: Verification & Sync](#phase-4-verification--sync)
10. [Cross-Cutting Concerns](#cross-cutting-concerns)
11. [Complexity Tracking](#complexity-tracking)
12. [Progress Tracking](#progress-tracking)

---

## Executive Summary

Extract 10 agent command files from `agents/commands/` into a new `agents/commands-lite/` directory, stripping all non-pure concepts (FlowSpace MCP, PlanPak, plan-ordinal, footnotes, constitution gates, and all 14 excluded command references). Produce 2 new documentation files (README.md, GETTING-STARTED.md). The full pipeline remains completely untouched. The lite directory is standalone — not synced, not installed, not distributed.

**Approach**: Copy each source file → systematically strip non-pure content → verify zero contamination via grep checks.

## Technical Context

### Current System State
- 24 command files in `agents/commands/` (full pipeline)
- Source/distribution paradigm: `agents/` → `src/jk_tools/` via `scripts/sync-to-dist.sh`
- Sync script uses rsync with `--include="*.md" --exclude="*"` — **blocks subdirectory traversal**
- Installer (`install/agents.sh`) uses `find -maxdepth 1` — only installs top-level files

### Integration Requirements
- No changes to `scripts/sync-to-dist.sh` — lite directory is outside the sync scope
- No changes to `install/agents.sh` — lite commands are never installed
- No changes to `setup.sh` — nothing to sync or install

### Constraints
- Zero modifications to existing `agents/commands/*.md` files
- All 12 lite files must be self-contained (no imports from full pipeline)
- Every lite command's "Next step" must reference only lite commands

### PlanPak: Feature Folder

All plan-scoped deliverables live in `agents/commands-lite/`:

```
agents/commands-lite/              ← Feature folder (plan-scoped, NOT synced/installed)
├── deepresearch.md                ← Phase 1 (copy)
├── didyouknow.md                  ← Phase 1 (minor edits)
├── plan-1b-specify.md             ← Phase 1 (minor edits)
├── plan-2c-workshop.md            ← Phase 1 (minor edits)
├── plan-5b-flightplan.md          ← Phase 1 (minor edits)
├── plan-1a-explore.md             ← Phase 1 (moderate edits)
├── plan-5-phase-tasks-and-brief.md ← Phase 1 (moderate edits)
├── plan-3-architect.md            ← Phase 2 (major rewrite)
├── plan-6-implement-phase.md      ← Phase 2 (major rewrite)
├── plan-7-code-review.md          ← Phase 2 (major rewrite)
├── README.md                      ← Phase 3 (new)
└── GETTING-STARTED.md             ← Phase 3 (new)
```

**Not synced. Not installed.** This directory is a standalone alternative command set. Users who want it copy files manually to their CLI's command directory. The sync pipeline (`sync-to-dist.sh`) and installer (`agents.sh`) ignore it entirely.

---

## Critical Research Findings

| # | Impact | Finding | Action | Affects |
|---|--------|---------|--------|---------|
| 01 | Critical | plan-6 has mandatory plan-6a auto-run (lines 460-496) — hard dependency | Replace with 3-step inline progress tracking (workshop design) | Phase 2 |
| 02 | Critical | plan-3 subagents invoke /flowspace-research (lines 182-302) — 4 prompts | Rewrite all 4 with grep/glob/view per workshop templates | Phase 2 |
| 03 | Critical | plan-3 Graph Traversal Guide (lines 1184-1440, 256 lines) is pure FlowSpace | Delete Appendix B entirely; keep Appendix A anchor spec (~68 lines, retitled) | Phase 2 |
| 04 | ~~High~~ | ~~sync-to-dist.sh blocks subdirectory traversal~~ | N/A — lite directory moved outside sync scope | N/A |
| 05 | High | plan-6 Architecture Map + Task-to-Component are non-lite in 4-location update | Replace 4-location mandatory with 3-step (checkbox, log anchor, exec log) | Phase 2 |
| 06 | High | plan-3 subagent fallbacks (lines 188, 230, 271, 304) are 1-line stubs | Expand to 3-4 concrete grep/glob/view commands each | Phase 2 |
| 07 | High | PlanPak tendrils in plan-3 (~15 refs), plan-5 (~10), plan-6 (~5), plan-7 (~10) | Systematic grep-and-strip for planpak\|PlanPak\|T000\|File Placement | Phase 1-2 |
| 08 | High | Footnote system permeates plan-3 templates, plan-7 validators | Strip ALL footnote refs — no `[^N]`, no Change Footnotes Ledger | Phase 2 |
| 09 | Medium | plan-7 TAD Validator (lines 459-549, ~90 lines) and PlanPak Validator (lines 973-1012) | Delete both self-contained subagent blocks + update synthesis | Phase 2 |
| 10 | Medium | plan-7 flow list (lines 1603-1610) hardcodes plan-0, plan-2, plan-4 | Replace with lite flow: 1b→3→5→6→7 | Phase 2 |
| 11 | Medium | plan-3 Simple Mode template references plan-4, plan-6a | Update next-step to plan-5/plan-6 directly, remove footnote template | Phase 2 |
| 12 | Low | plan-1b next step → plan-2-clarify | Change to plan-3-architect | Phase 1 |
| 13 | Low | plan-2c next step → "plan-2-clarify or plan-3-architect" | Change to plan-3-architect only | Phase 1 |
| 14 | Low | didyouknow CS score challenge (lines 56-59) | Generalize to "complexity estimates" | Phase 1 |

---

## File Placement Manifest

| File | Classification | Location | Rationale |
|------|---------------|----------|-----------|
| All 10 command `.md` files | plan-scoped | `agents/commands-lite/` | Standalone alternative set — not synced or installed |
| `README.md` | plan-scoped | `agents/commands-lite/` | Lite-specific documentation |
| `GETTING-STARTED.md` | plan-scoped | `agents/commands-lite/` | Lite-specific quick-start |

---

## Testing Philosophy

### Testing Approach
- **Selected Approach**: Lightweight (grep-based verification)
- **Rationale**: Deliverables are markdown files. "Tests" are grep commands that verify zero contamination.
- **Focus Areas**: AC3-AC6, AC15 from spec (all grep-verifiable zero-match checks)

### Verification Commands (used in Phase 4)
```bash
# AC3: No FlowSpace references
grep -riE 'flowspace|FlowSpace|fs2|flow_squared|flowspace-tree|flowspace-search|flowspace-get_node|flowspace-research' agents/commands-lite/*.md

# AC4: No PlanPak references
grep -riE 'planpak|plan-pack|PlanPak|features/<' agents/commands-lite/*.md

# AC5: No plan-ordinal references
grep -riE 'plan-ordinal|jk-po' agents/commands-lite/*.md

# AC6: No excluded command invocations
grep -riE '/plan-0-constitution|/plan-2-clarify|/plan-2b-prep-issue|/plan-3a-adr|/plan-4-complete-the-plan|/plan-5c-requirements-flow|/plan-6a-update-progress|/plan-6b-worked-example|/plan-8-merge|/planpak|/tad|/util-0-handover|/code-concept-search|/flowspace-research' agents/commands-lite/*.md

# AC15: No footnotes
grep -riE 'footnote|Footnote|\[\^|Change Footnotes Ledger' agents/commands-lite/*.md
```

All 5 commands must return **zero matches** for the phase to pass.

---

## Phase 1: Infrastructure & Easy Extractions

**Objective**: Fix sync pipeline, create lite directory, extract 7 commands that need zero-to-moderate edits.

**Deliverables**:
- `agents/commands-lite/` directory with 7 command files

**Dependencies**: None (foundational phase)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Missing a non-pure reference in "easy" files | Medium | Low | Phase 4 grep checks catch stragglers |

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T001 | Create `agents/commands-lite/` directory | 1 | Setup | -- | /home/jak/github/tools/agents/commands-lite/ | Directory exists | mkdir |
| [x] | T002 | Extract deepresearch.md (pure copy, zero edits) | 1 | Core | T001 | /home/jak/github/tools/agents/commands-lite/deepresearch.md | Identical to source | cp agents/commands/deepresearch.md agents/commands-lite/ |
| [x] | T003 | Extract didyouknow.md (2 minor edits) | 1 | Core | T001 | /home/jak/github/tools/agents/commands-lite/didyouknow.md | No CS rubric "from constitution" refs; integration section generalized | Lines 56-59: generalize CS challenge; lines 170-176: simplify integration refs |
| [x] | T004 | Extract plan-2c-workshop.md (2 edits) | 1 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-2c-workshop.md | No plan-2-clarify refs | Line 378: change to "plan-3-architect" only; lines 393-408: simplify integration section |
| [x] | T005 | Extract plan-1b-specify.md (5 edits) | 2 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-1b-specify.md | No plan-2-clarify refs; no --simple flag; next step → plan-3 | Lines 16, 60: remove --simple/plan-2-clarify; line 78: inline CS rubric; line 136: next step → plan-3 |
| [x] | T006 | Extract plan-5b-flightplan.md (minor edits) | 1 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-5b-flightplan.md | No PlanPak refs; no constitution ref | Lines 159, 215-283: strip PlanPak; line 181: remove "See constitution rubric" |
| [x] | T007 | Extract plan-1a-explore.md (moderate edits — strip FlowSpace dual-mode) | 3 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-1a-explore.md | No FlowSpace refs; no plan-ordinal; no plan-2-clarify; standard mode is only mode | 924→667 lines; removed FlowSpace detection, FlowSpace subagents, plan-ordinal, plan-2-clarify section |
| [x] | T008 | Extract plan-5-phase-tasks-and-brief.md (moderate edits) | 2 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-5-phase-tasks-and-brief.md | No FlowSpace; no plan-5c subagent; no PlanPak; no /code-concept-search | 942→835 lines; stripped PlanPak, plan-5c, code-concept-search, FlowSpace, footnotes |

### Acceptance Criteria
- [ ] `agents/commands-lite/` contains 7 `.md` files
- [ ] No FlowSpace references in 7 files (grep check)
- [ ] No PlanPak references in 7 files (grep check)
- [ ] No plan-ordinal references in 7 files (grep check)
- [ ] No excluded command invocations in 7 files (grep check)
- [ ] Zero modifications to any file in `agents/commands/` (full pipeline untouched)

---

## Phase 2: Hard Command Rewrites

**Objective**: Extract and rewrite plan-3-architect, plan-6-implement-phase, and plan-7-code-review — the three commands with deep non-pure coupling.

**Deliverables**:
- `agents/commands-lite/plan-3-architect.md` (~800 lines, down from 1446)
- `agents/commands-lite/plan-6-implement-phase.md` (~380 lines, down from 502)
- `agents/commands-lite/plan-7-code-review.md` (~1100 lines, down from 1614)

**Dependencies**: Phase 1 complete (directory exists)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| plan-3 subagent rewrite loses research quality | Medium | High | Model on plan-1a Standard Mode pattern; use workshop templates |
| plan-7 review rubric incomplete after stripping validators | Medium | Medium | Keep core logic (diff analysis, test coverage, architecture alignment) |
| plan-6 inline progress tracking doesn't match plan-7 expectations | Medium | High | Verify plan-7 lite reads same format plan-6 lite writes (3-step model) |
| Accidentally remove needed logic in large files | Medium | Medium | Diff against source after extraction to verify only intended changes |

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T010 | Copy & edit plan-3-architect.md | 3 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-3-architect.md | All grep checks pass; no FlowSpace/PlanPak/footnote/excluded-cmd refs | 1446→1025 lines; all 10 checklist items done |
| [x] | T011 | Copy & edit plan-6-implement-phase.md | 3 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-6-implement-phase.md | All grep checks pass; no plan-6a/footnote/PlanPak/Full-Mode refs | 502→315 lines; 3-step inline progress, Simple Mode only |
| [x] | T012 | Copy & edit plan-7-code-review.md | 3 | Core | T001 | /home/jak/github/tools/agents/commands-lite/plan-7-code-review.md | All grep checks pass; no TAD/PlanPak validators, no FlowSpace/footnote refs | 1614→1175 lines; validators trimmed, flow list updated |
| [x] | T013 | Cross-verify plan-6 output ↔ plan-7 input contract | 2 | Test | T011,T012 | Both plan-6 and plan-7 lite files | plan-7 reads: task checkbox [x], log#anchor in Notes, execution.log.md entries. plan-6 writes: exactly those 3 things. | ✅ Compatible |

### Acceptance Criteria
- [ ] All 3 hard files extracted and cleaned
- [ ] plan-3 uses grep/glob/view subagents (no /flowspace-research)
- [ ] plan-3 next step → plan-5 (no plan-4)
- [ ] plan-6 has inline 3-step progress (no plan-6a)
- [ ] plan-6 has no footnotes
- [ ] plan-7 has no TAD/PlanPak validators
- [ ] plan-7 flow list matches lite pipeline
- [ ] plan-6 output format matches plan-7 input expectations

---

## Phase 3: Lite Documentation

**Objective**: Create lite-specific README.md and GETTING-STARTED.md with simplified Mermaid diagrams and 10-command reference.

**Deliverables**:
- `agents/commands-lite/README.md` (~400 lines)
- `agents/commands-lite/GETTING-STARTED.md` (~200 lines)

**Dependencies**: Phase 1 + Phase 2 complete (all 10 commands finalized)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Diagrams reference non-lite concepts | Low | Low | Phase 4 grep checks |
| Docs describe behavior that doesn't match command files | Medium | Medium | Cross-reference each doc section against actual command content |

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T033 | Create lite README.md with flow diagram, 10-command reference, CS rubric | 3 | Docs | T009,T031 | /home/jak/github/tools/agents/commands-lite/README.md | Mermaid shows only lite 10; all command sections match actual command descriptions | 470 lines |
| [x] | T034 | Create lite GETTING-STARTED.md with quick-start walkthrough | 2 | Docs | T033 | /home/jak/github/tools/agents/commands-lite/GETTING-STARTED.md | Big Picture mermaid, example walkthrough, quick reference table — all lite only | 185 lines |

### Acceptance Criteria
- [ ] README.md exists with Mermaid flow diagram (10 nodes only)
- [ ] GETTING-STARTED.md exists with example walkthrough (lite commands only)
- [ ] No references to excluded commands in either doc
- [ ] No FlowSpace/PlanPak/footnote references

---

## Phase 4: Verification & Sync

**Objective**: Run all AC grep checks, verify sync pipeline works, confirm zero modifications to full pipeline.

**Deliverables**:
- All 15 ACs from spec verified
- `./setup.sh` successful (sync to dist)
- Verification evidence in execution log

**Dependencies**: Phase 1 + 2 + 3 complete

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T035 | Run AC3-AC6, AC15 grep checks (5 zero-match commands) | 1 | Test | T034 | All files in agents/commands-lite/ | All 5 grep commands return empty (0 matches) | ✅ All zero |
| [x] | T036 | Verify AC7: every lite command's Next Step references only lite commands | 2 | Test | T034 | All 10 command files | All referenced commands exist in lite set | ✅ Verified |
| [x] | T037 | Verify AC1: exactly 12 files in commands-lite/ | 1 | Test | T034 | /home/jak/github/tools/agents/commands-lite/ | `ls agents/commands-lite/*.md \| wc -l` = 12 | ✅ 12 files |
| [x] | T038 | Verify AC2: zero modifications to full pipeline | 1 | Test | T034 | /home/jak/github/tools/agents/commands/ | `git diff agents/commands/*.md` returns empty | ✅ No changes |
| [x] | T039 | Verify AC13: all 10 commands have valid YAML frontmatter | 1 | Test | T034 | All 10 command files | Each file starts with `---` + `description:` + `---` | ✅ All 10 commands valid |

### Acceptance Criteria
- [ ] All 15 spec ACs pass
- [ ] `git diff agents/commands/*.md` is empty

---

## Cross-Cutting Concerns

### Naming Convention
Lite command files use **identical filenames** to full pipeline commands. The `lite/` subdirectory provides namespace separation. This preserves `/plan-3` slash-command compatibility if a CLI tool is configured to read from the lite directory.

### CS Rubric (Inlined)
The lite pipeline inlines a simplified CS rubric in plan-3 and plan-1b (no constitution.md dependency):
```
Complexity Score (CS 1-5):
Factors: Surface Area + Integration + Data/State + Novelty + NFR + Testing (0-2 each)
- CS-1 (0-2): Trivial — single file, no deps
- CS-2 (3-4): Small — few files, familiar code
- CS-3 (5-7): Medium — multiple modules, integration tests
- CS-4+ → Consider using the Full pipeline
```

### Testing Strategy (Absorbed into plan-3)
Lite plan-3 asks 2-3 inline questions during its entry gate:
1. **Testing approach**: Standard / Lightweight / None
2. **Mock usage**: Targeted mocks / No mocks

No TDD/TAD/Hybrid complexity. These are written into the plan header.

### Distribution
- Source of truth: `agents/commands-lite/`
- **Not synced. Not installed. Not distributed.** This is a standalone alternative command set. Users who want lite commands copy files manually to their CLI's command directory.

---

## Complexity Tracking

| Component | CS | Breakdown | Justification | Mitigation |
|-----------|-----|-----------|---------------|------------|
| plan-3-architect rewrite | 3 | S=1,I=1,D=0,N=1,F=0,T=0 | 1446→~800 lines; 4 subagent prompts need rewrite; multiple gate removals | Workshop provides complete subagent templates; systematic grep-and-strip |
| plan-7-code-review strip | 3 | S=2,I=0,D=0,N=0,F=0,T=1 | 1614→~1100 lines; 2 validator subagents deleted; synthesis updated | Validators are self-contained blocks; careful synthesis merge list update |
| plan-6-implement rewrite | 3 | S=1,I=1,D=0,N=1,F=0,T=0 | 502→~380 lines; plan-6a delegation removed; 3-step progress designed | Workshop provides exact 3-step format; plan-7 contract verified |
| plan-1a-explore strip | 2 | S=1,I=0,D=0,N=0,F=0,T=1 | 924→~500 lines; dual FlowSpace/Standard mode → Standard only | Standard mode already exists; just delete FlowSpace sections |

---

## Progress Tracking

### Phase Completion Checklist
- [x] Phase 1: Infrastructure & Easy Extractions - COMPLETE
- [x] Phase 2: Hard Command Rewrites - COMPLETE
- [x] Phase 3: Lite Documentation - COMPLETE
- [x] Phase 4: Verification & Sync - COMPLETE

Overall Progress: 4/4 phases (100%)

---

Next step (when happy): Run **/plan-5-phase-tasks-and-brief --phase "Phase 1: Infrastructure & Easy Extractions" --plan "/home/jak/github/tools/docs/plans/014-lite-agent-flows/lite-agent-flows-plan.md"**
