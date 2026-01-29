# PlanPak Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-01-29
**Spec**: [./planpak-spec.md](./planpak-spec.md)
**Status**: COMPLETE

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Implementation](#implementation)
4. [Change Footnotes Ledger](#change-footnotes-ledger)

## Executive Summary

PlanPak adds opt-in plan-based file organization to the agent command workflow. When enabled, source files are grouped by the plan that introduced them in flat `features/<ordinal>-<slug>/` folders, while cross-cutting code and library splits remain in traditional locations. This plan modifies 7 existing command files, creates 1 new standalone command, and updates the README — all as bounded markdown section additions following the established Simple/Full mode conditional pattern.

## Critical Research Findings (Concise)

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Existing Simple/Full conditional branching in plan-3 (line 44), plan-6 (line 150), plan-6a (line 75), plan-7 (line 28) is the proven pattern | Follow same conditional guard pattern for all PlanPak additions |
| 02 | Critical | v1 rollback lesson: symlinks break compilers; real files only | No symlinks in v2 — PlanPak is purely about file *placement*, not linking |
| 03 | Critical | plan-7 scope guard (step 3, line 69) flags out-of-scope files as HIGH violations; cross-plan edits would trigger false positives | Add PlanPak exemption: cross-plan-edit files are legitimate if classified in File Placement Manifest |
| 04 | High | plan-2-clarify has 4 existing question templates (Q1-Q4) with consistent MC table format | New File Management question follows exact same format, inserted after Documentation Strategy |
| 05 | High | plan-3 PHASE 0 reads spec header for Mode; same pattern works for File Management detection | Add `**File Management**: PlanPak` detection alongside Mode detection in PHASE 0 |
| 06 | High | plan-5 task table has mandatory `Absolute Path(s)` column and `Notes` column | PlanPak uses these existing columns — paths point to `features/` folders, Notes gets classification tag |
| 07 | High | plan-6 has 5 implementation rules in Step 2 (Contract); PlanPak adds 5 conditional rules | Keep PlanPak rules in a clearly separated conditional block after existing rules |
| 08 | High | Command files are large (plan-3: ~1400 lines, plan-7: ~1500 lines); additions must be concise | Keep each PlanPak section under 40 lines; delegate detail to standalone planpak.md |
| 09 | High | plan-6a's 3-location atomic update works on plan artifacts (docs/plans/), not source paths | Minimal PlanPak changes needed in plan-6a — classification tag in Notes is the main addition |
| 10 | Medium | Dual detection (spec header + T000 task) prevents false negatives | Use `**File Management**: PlanPak` as primary signal; T000 presence as secondary confirmation |
| 11 | Medium | README has Mermaid flow diagrams that need updating | Update as final task after all command files are modified and validated |
| 12 | Medium | All edits sync to `src/jk_tools/` via setup.sh | Run setup.sh as final verification step |
| 13 | Medium | Rollback across 7+ files is harder than v1's single-file additions | Make all changes in one commit for clean git revert |

## Implementation (Single Phase)

**Objective**: Add PlanPak sections to all 8 command files + README, deploy via setup.sh

**Testing Approach**: Manual (run `./setup.sh`, verify 10/10 deployment)
**Mock Usage**: N/A

### File Placement Manifest

| File | Classification | What Changes |
|------|---------------|-------------|
| `agents/commands/planpak.md` | **NEW** | Standalone PlanPak command — full concept reference |
| `agents/commands/plan-2-clarify.md` | cross-cutting | Add File Management question template + spec update instructions |
| `agents/commands/plan-3-architect.md` | cross-cutting | Add PlanPak detection in PHASE 0, directory template in PHASE 3, T000 task + File Placement Manifest in PHASE 4, PlanPak variant in Simple Mode section |
| `agents/commands/plan-5-phase-tasks-and-brief.md` | cross-cutting | Add PlanPak task generation rules in Step 5, placement rules in Alignment Brief |
| `agents/commands/plan-6-implement-phase.md` | cross-cutting | Add PlanPak detection in Step 1, 5 placement rules in Step 2 |
| `agents/commands/plan-6a-update-progress.md` | cross-cutting | Add classification tag guidance in Step C1 Notes column |
| `agents/commands/plan-7-code-review.md` | cross-cutting | Add PlanPak Compliance Validator subagent in Step 4, scope guard exemption in Step 3 |
| `agents/commands/README.md` | cross-cutting | Add planpak to command list, flow diagram, directory structure |

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T001 | Create standalone planpak.md command | 3 | Core | -- | /home/jak/github/tools/agents/commands/planpak.md | File exists with frontmatter, full concept reference, rules, decision tree, detection logic, quick reference card | NEW file |
| [x] | T002 | Add File Management question to plan-2-clarify | 2 | Core | -- | /home/jak/github/tools/agents/commands/plan-2-clarify.md | MC table question exists after Documentation Strategy; spec update instructions include `**File Management**` field | cross-cutting |
| [x] | T003 | Add PlanPak sections to plan-3-architect | 3 | Core | T002 | /home/jak/github/tools/agents/commands/plan-3-architect.md | PHASE 0 detects File Management; PHASE 3 has PlanPak directory template; PHASE 4 has File Placement Manifest section + T000 task; Simple Mode section has PlanPak variant | cross-cutting |
| [x] | T004 | Add PlanPak task generation to plan-5 | 2 | Core | T003 | /home/jak/github/tools/agents/commands/plan-5-phase-tasks-and-brief.md | Step 5 enforces features/ paths for plan-scoped files; Alignment Brief includes placement rules | cross-cutting |
| [x] | T005 | Add PlanPak implementation rules to plan-6 | 2 | Core | T003 | /home/jak/github/tools/agents/commands/plan-6-implement-phase.md | Step 1 detects PlanPak; Step 2 has 5 conditional placement rules | cross-cutting |
| [x] | T006 | Add PlanPak guidance to plan-6a | 1 | Core | T005 | /home/jak/github/tools/agents/commands/plan-6a-update-progress.md | Step C1 includes classification tag in Notes column guidance | cross-cutting |
| [x] | T007 | Add PlanPak Compliance Validator to plan-7 | 3 | Core | T005 | /home/jak/github/tools/agents/commands/plan-7-code-review.md | Step 3 scope guard has PlanPak exemption; Step 4 has PlanPak Compliance Validator subagent with 6 checks | cross-cutting |
| [x] | T008 | Update README with PlanPak documentation | 1 | Doc | T001 | /home/jak/github/tools/agents/commands/README.md | PlanPak listed in command table; flow diagram updated; directory structure shows features/ | cross-cutting |
| [x] | T009 | Run setup.sh and verify deployment | 1 | Integ | T001-T008 | /home/jak/github/tools/setup.sh | 10/10 install success; all modified files synced to src/jk_tools/ and deployed to ~/.claude/commands/ etc. | Manual verification |

### Acceptance Criteria
- [x] `planpak.md` exists as self-contained standalone command
- [x] `/plan-2-clarify` presents File Management question (PlanPak vs Legacy)
- [x] `/plan-3-architect` detects PlanPak, produces File Placement Manifest, includes T000
- [x] `/plan-5-phase-tasks-and-brief` enforces features/ paths when PlanPak active
- [x] `/plan-6-implement-phase` follows 5 PlanPak placement rules when active
- [x] `/plan-7-code-review` validates PlanPak compliance with dedicated subagent
- [x] Legacy behavior unchanged when PlanPak not selected
- [x] `./setup.sh` deploys successfully (10/10)

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| PlanPak sections break existing Simple/Full conditional flow | Med | High | All additions in clearly separated conditional blocks; never interleave with existing mode logic |
| plan-7 scope guard rejects legitimate cross-plan edits | High | High | Explicit PlanPak exemption for files classified as cross-plan-edit in manifest |
| Command files become too long for agent context | Low | Med | Keep each addition under 40 lines; delegate detail to planpak.md |
| Rollback difficulty across 8 files | Med | Med | Single commit for clean git revert; tag pre-planpak already created |

## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "/home/jak/github/tools/docs/plans/012-planpak/planpak-plan.md"`
- **Optional validation**: `/plan-4-complete-the-plan` (recommended given CS-3)
