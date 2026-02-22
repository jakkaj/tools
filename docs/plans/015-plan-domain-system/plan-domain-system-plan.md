# Plan Domain System — Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-02-22
**Spec**: [plan-domain-system-spec.md](./plan-domain-system-spec.md)
**Status**: COMPLETE

**Workshops**:
- [domain-system-design.md](./workshops/domain-system-design.md) — Domain model, registry, lifecycle, extraction
- [v2-command-structure.md](./workshops/v2-command-structure.md) — V2 command placement and structure
- [lean-plan-task-design.md](./workshops/lean-plan-task-design.md) — Lean plan-3 and plan-5 output design

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Key Findings](#key-findings)
3. [Implementation](#implementation)
4. [Progress Tracking](#progress-tracking)

## Executive Summary

The plan workflow lacks persistent business-domain awareness, causing concept reinvention and misplaced files across plans. This plan delivers a **domain system** — first-class domain definitions (`docs/domains/`) that own code, contracts, and composition — and **8 v2 agent commands** (`agents/v2-commands/`) that are complete standalone rewrites incorporating domain awareness and leaner output. It also updates the install/sync pipeline to ship v2 commands alongside v1.

All deliverables are markdown prompt files and shell script edits. No executable code is being written. V1 commands in `agents/commands/` are untouched.

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Workshops contain authoritative design decisions for all 8 v2 commands — domain model, task table format, research subagent count, output sections | Follow workshop designs exactly; they are the spec |
| 02 | Critical | V2 commands are complete standalone rewrites per clarification Q3 — no inheritance from v1 | Write each v2 command as fully self-contained prompt, no references to v1 |
| 03 | High | `scripts/sync-to-dist.sh` uses rsync with `--include="*.md"` pattern per directory — adding v2-commands requires a new `mkdir -p` + `rsync` block | Add after existing agents/commands sync (around line 59) |
| 04 | High | `install/agents.sh` global loop (line ~921) iterates `${SOURCE_DIR}/*.md` — need a second loop for v2-commands or extend SOURCE_DIR | Add parallel loop for v2-commands with same target directories |
| 05 | High | Domain templates (domain.md, registry.md) need to be discoverable by agents — install pipeline only handles `*.md` files from known directories | Ship templates in `agents/v2-commands/` directory as `_template-domain.md` and `_template-registry.md` (underscore prefix = template convention, installed alongside commands) |
| 06 | High | No `docs/project-rules/` exists in this repo — constitution and architecture gates are N/A | Skip constitution/architecture gates |
| 07 | Medium | V2 plan-3 must be ≤500 lines (spec AC7) — current v1 is 1446 lines. Lean workshop defines exact sections to keep vs cut | Use lean workshop §3 as the blueprint |
| 08 | Medium | V2 plan-5 task table has 7 columns per spec AC8 — workshop §4-5 defines exact column layout and what was cut | Use lean workshop §4-5 as the blueprint |
| 09 | Medium | Remove TAD and Footnote concepts from v2 commands per clarification Q2 | Strip all TAD workflow details, scratch→promote, Test Doc blocks, and FlowSpace footnote embedding from v2 commands |
| 10 | Medium | `templates/` directory exists at repo root but only contains `AGENTS.md` — not a good template location | Use `agents/v2-commands/` for templates instead |

## Implementation

**Objective**: Deliver 8 v2 command files, 2 domain template files, install/sync pipeline updates, and a README — all as a single phase of markdown and shell script work.

**Testing Approach**: Manual — verify install pipeline syncs and deploys correctly.

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T001 | Create v2-commands directory and README | 1 | Setup | — | /home/jak/github/tools/agents/v2-commands/README.md | Directory exists, README explains v2 vs v1 | |
| [x] | T002 | Write `plan-v2-extract-domain.md` — includes domain.md + registry.md templates inline | 2 | Core | T001 | /home/jak/github/tools/agents/v2-commands/plan-v2-extract-domain.md | Describes collaborative brownfield extraction, contains full domain.md and registry.md templates inline | Per workshop §4 Extraction + template-discovery workshop |
| [x] | T003 | Write `plan-1b-v2-specify.md` | 2 | Core | T001 | /home/jak/github/tools/agents/v2-commands/plan-1b-v2-specify.md | Standalone rewrite with `## Target Domains` section, ~150-180 lines | Per workshop v2-command §4 |
| [x] | T004 | Write `plan-2-v2-clarify.md` | 1 | Core | T003 | /home/jak/github/tools/agents/v2-commands/plan-2-v2-clarify.md | Domain Review question replaces PlanPak question, ~120-150 lines | Per workshop v2-command §4 |
| [x] | T005 | Write `plan-3-v2-architect.md` — biggest deliverable | 3 | Core | T003, T004 | /home/jak/github/tools/agents/v2-commands/plan-3-v2-architect.md | ≤500 lines, 2 research subagents, concise findings table, domain manifest, references domain.md format from extract-domain | Per lean workshop §3 |
| [x] | T006 | Write `plan-5-v2-phase-tasks-and-brief.md` | 3 | Core | T005 | /home/jak/github/tools/agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md | 7-column task table, 5-section prior-phase review, simplified audit, Context Brief with diagrams, flight plan auto-gen, ~300-400 lines | Per lean workshop §4 |
| [x] | T007 | Write `plan-6-v2-implement-phase.md` | 2 | Core | T005, T006 | /home/jak/github/tools/agents/v2-commands/plan-6-v2-implement-phase.md | Domain placement rules, post-impl domain.md updates, no PlanPak/TAD/Footnote concepts | Per workshop v2-command §4 |
| [x] | T008 | Write `plan-6a-v2-update-progress.md` | 1 | Core | T007 | /home/jak/github/tools/agents/v2-commands/plan-6a-v2-update-progress.md | Domain context in progress tracking, no TAD/Footnote concepts, ~150-200 lines | Per workshop v2-command §4 |
| [x] | T009 | Write `plan-7-v2-code-review.md` | 2 | Core | T007 | /home/jak/github/tools/agents/v2-commands/plan-7-v2-code-review.md | Domain Compliance Validator replaces PlanPak validator, anti-reinvention check | Per workshop v2-command §4 |
| [x] | T010 | Update `scripts/sync-to-dist.sh` — add v2-commands sync | 1 | Pipeline | T001 | /home/jak/github/tools/scripts/sync-to-dist.sh | `rsync` block for `agents/v2-commands/` → `src/jk_tools/agents/v2-commands/` | Add after line ~59 |
| [x] | T011 | Update `install/agents.sh` — add v2-commands installation | 2 | Pipeline | T001 | /home/jak/github/tools/install/agents.sh | V2 commands install to same targets as v1 (Claude, OpenCode, Codex, Copilot, Copilot CLI) | Add parallel loop after existing global install loop |
| [x] | T012 | Verify end-to-end: run `./setup.sh` and confirm v2-commands deploy | 1 | Verify | T010, T011 | /home/jak/github/tools/setup.sh | V2 commands appear in `~/.claude/commands/`, `src/jk_tools/agents/v2-commands/` | Manual verification |

### Acceptance Criteria

- [ ] AC1: `agents/v2-commands/` contains exactly 9 files (README + 7 v2 commands + extract-domain)
- [ ] AC2: Each v2 command is fully self-contained — no references to v1 commands
- [ ] AC3: `plan-3-v2-architect.md` is ≤500 lines
- [ ] AC4: `plan-5-v2-phase-tasks-and-brief.md` uses 7-column task table
- [ ] AC5: No files in `agents/commands/` are modified
- [ ] AC6: `./setup.sh` successfully syncs and installs v2-commands
- [ ] AC7: Domain templates (domain.md, registry.md) are embedded inline in `plan-v2-extract-domain.md`, not as separate files
- [ ] AC8: No TAD or Footnote concepts in any v2 command
- [ ] AC9: All PlanPak references in v2 commands replaced with domain equivalents

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| V2 plan-3 hard to fit in 500 lines | Medium | Medium | Workshop already defines exactly what to keep/cut — follow it |
| Template discovery mechanism unclear | Medium | Medium | Use `_template-` prefix convention in v2-commands dir; document in README |
| Install pipeline changes break existing commands | Low | High | Test with `./setup.sh` before committing |

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "/home/jak/github/tools/docs/plans/015-plan-domain-system/plan-domain-system-plan.md"`
- **Optional validation**: `/plan-4-complete-the-plan` (recommended to verify completeness)

## Progress Tracking

- [x] Implementation — 12 tasks, CS-3 overall — COMPLETE
