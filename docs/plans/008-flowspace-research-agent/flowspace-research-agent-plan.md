# FlowSpace Research Agent Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-01-16
**Spec**: [./flowspace-research-agent-spec.md](./flowspace-research-agent-spec.md)
**Status**: COMPLETE

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Implementation](#implementation)
4. [Change Footnotes Ledger](#change-footnotes-ledger)

---

## Executive Summary

**Problem**: Parent orchestrator commands (plan-1a-explore, plan-3-architect) embed research logic in subagent prompts, leading to inconsistent FlowSpace usage patterns and no reusable research worker. The current subagent prompts mention FlowSpace but don't encode optimal usage patterns documented in fs2's agent guidance.

**Solution**: Create a standalone `/flowspace-research` command designed to BE a parallel subagent worker—receiving a focused research query, using FlowSpace MCP tools optimally, and returning structured findings for parent synthesis. FlowSpace-first design with clear fallback guidance when unavailable.

**Expected Outcome**: A reusable, well-tested research worker command that:
- Detects FlowSpace availability at startup (fail-fast, not silent fallback)
- Uses smart query type detection (path/symbol/concept)
- Returns structured output suitable for parent orchestrator synthesis
- Documents FlowSpace patterns for consistent usage across all commands

---

## Critical Research Findings (Concise)

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | **Dual Execution Path Required** (S1-02): Commands must implement FlowSpace detection with graceful fallback to standard tools | Implement try/probe detection at startup using `tree(pattern=".", max_depth=1)` |
| 02 | Critical | **Variable JSON Return Structures** (S2-01): tree() returns `{format, content/tree}`, search() returns `{meta, results}`, get_node() returns CodeNode or null | Implement conditional parsing per tool with format detection |
| 03 | Critical | **Semantic Search Prerequisites** (S2-03): `search(mode="semantic")` requires `fs2 scan --embed`; fails with "Embeddings not found" otherwise | Implement try-catch with automatic fallback to text mode + user warning |
| 04 | Critical | **Fail-Fast Not Silent Fallback** (S3-03): When FlowSpace unavailable, inform user and stop rather than degrading silently | Show actionable error with setup guidance, don't silently fall back to Grep |
| 05 | High | **YAML Frontmatter Convention** (S1-01): All commands require YAML frontmatter with description field for CLI discovery | Include concise description (80-120 chars) in frontmatter |
| 06 | High | **Query Type Auto-Detection** (S3-02): Distinguish path/symbol/concept queries using heuristic pipeline | Implement 3-stage detection: path (has `/`), symbol (CapitalCase), concept (natural language) |
| 07 | High | **Pattern Syntax Overloading** (S2-02): `tree(pattern=)` accepts folder paths, globs, node_ids with different semantics | Use folder paths with trailing `/`, explicit mode selection for search() |
| 08 | High | **Node ID Stability** (S2-05): Node IDs are opaque tokens, stable within session, case-sensitive | Pass node_ids verbatim between tools, never reconstruct manually |
| 09 | High | **Detail Parameter Trade-off** (S2-04): `detail="max"` includes AI summaries but costs more | Default to `detail="min"`, use `detail="max"` only for top findings |
| 10 | High | **Output Format Pattern** (S1-08): Structured output with metadata header, executive summary, detailed findings | Include query, mode, FlowSpace status, results_count in output header |
| 11 | High | **Source/Distribution Paradigm** (S4-01): Commands live in agents/commands/ (source), sync to src/jk_tools/ automatically | Create file in agents/commands/flowspace-research.md, run ./setup.sh to deploy |
| 12 | High | **Multi-CLI Deployment** (S4-02): Commands deployed to 5 CLI targets (Claude, OpenCode, Codex, Copilot, Copilot CLI) | Single .md file format, no binary assets, supports both global and local install |
| 13 | Medium | **Semantic Mode Degradation** (S3-04): When semantic unavailable, auto-downgrade to text mode with user notice | Add message: "ℹ️ Semantic search unavailable, switched to text matching" |
| 14 | Medium | **Scope Filtering Behavior** (S3-06): include/exclude are path patterns with OR logic for includes, AND for excludes | Document: `--include "src/" --exclude "test"` → (src/) AND NOT (test) |
| 15 | Medium | **Prior Learnings Mining** (S1-07): Can mine `## Discoveries & Learnings` from prior plans for institutional knowledge | Include prior learnings search in research workflow |
| 16 | Medium | **Pagination Pattern** (S2-06): search() has limit/offset; detect final page when `len(results) < limit` | Default limit=20, implement pagination for exhaustive discovery |
| 17 | Medium | **MCP Configuration Dependency** (S4-07): FlowSpace MCP configured via servers.json, requires fs2 in PATH | Document prerequisite: `fs2 init && fs2 scan` before use |

---

## Implementation (Single Phase)

**Objective**: Create the `/flowspace-research` command as a markdown file in `agents/commands/` with complete FlowSpace integration, query type detection, and structured output.

**Testing Approach**: Manual verification (command is markdown prompt, not executable code)
**Mock Usage**: N/A (no mocks needed for markdown command file)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T001 | Create command file with YAML frontmatter | 1 | Setup | -- | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | File exists with description in frontmatter | Description: 115 chars |
| [x] | T002 | Implement FlowSpace detection section | 2 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | Detection uses tree(pattern=".", max_depth=1), fail-fast on unavailable | Per S1-02, S3-03 |
| [x] | T003 | Implement query type detection heuristics | 2 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | 3-stage pipeline: path → symbol → concept with clear logic | Per S3-02 |
| [x] | T004 | Implement FlowSpace exploration workflow | 3 | Core | T002, T003 | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | Covers tree(), search(), get_node() with optimal patterns | Per S2-01 through S2-08 |
| [x] | T005 | Implement semantic search with fallback | 2 | Core | T004 | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | Try semantic, catch error, fallback to text with warning | Per S2-03, S3-04 |
| [x] | T006 | Implement structured output format | 2 | Core | T004 | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | Output includes metadata, summary, key nodes, code excerpts, gaps | Per S1-08 |
| [x] | T007 | Implement include/exclude scope filtering | 2 | Core | T004 | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | Document OR logic for includes, AND for excludes | Per S3-06 |
| [x] | T008 | Add parameter documentation and examples | 1 | Docs | T001-T007 | /Users/jordanknight/github/tools/agents/commands/flowspace-research.md | Clear usage examples, parameter descriptions | Per S1-04 |
| [x] | T009 | Run setup.sh to sync and deploy | 1 | Deploy | T001-T008 | /Users/jordanknight/github/tools/setup.sh | Command appears in ~/.claude/commands/, other CLI targets | Per S4-01, S4-02 |
| [x] | T010 | Manual verification with FlowSpace available | 2 | Test | T009 | -- | Run /flowspace-research on indexed codebase, verify output structure | Test happy path |
| [x] | T011 | Manual verification with FlowSpace unavailable | 1 | Test | T009 | -- | Run on codebase without fs2 scan, verify fail-fast error message | Test error path |

### Command Structure Outline

```markdown
---
description: A FlowSpace-first research command for parallel subagent codebase exploration with structured output for parent orchestrator synthesis.
---

# flowspace-research

[Purpose statement]

## Input Parameters
- `$ARGUMENTS` - Research query (required)
- `--scope <path>` - Limit search to path (optional)
- `--exclude <pattern>` - Exclude paths matching pattern (optional)
- `--limit <N>` - Max findings to return, default 10 (optional)

## Execution Flow

### 1) FlowSpace Detection (Fail-Fast)
[Detection logic with try/probe pattern]

### 2) Query Type Detection
[3-stage heuristic: path → symbol → concept]

### 3) FlowSpace Exploration Workflow
[Progressive exploration: orientation → targeted search → deep dive]

### 4) Semantic Search with Fallback
[Try semantic mode, catch error, fallback to text with warning]

### 5) Structured Output Generation
[Metadata header, summary, key nodes, code excerpts, gaps]

## Output Format
[Complete output template]

## Examples
[Usage examples for each query type]

## Error Handling
[Common errors and recovery guidance]
```

### Acceptance Criteria

- [x] Command file exists at `/Users/jordanknight/github/tools/agents/commands/flowspace-research.md`
- [x] YAML frontmatter includes concise description (80-120 chars)
- [x] FlowSpace detection uses `tree(pattern=".", max_depth=1)` probe pattern
- [x] Fail-fast error message when FlowSpace unavailable (not silent fallback)
- [x] Query type detection distinguishes path/symbol/concept queries
- [x] FlowSpace tools used with optimal patterns (folder `/` suffix, detail levels, search modes)
- [x] Semantic search includes try-catch with text mode fallback and user warning
- [x] Output format includes: metadata header, summary, key nodes table, code excerpts, gaps
- [x] Include/exclude filtering documented with correct logic (OR includes, AND excludes)
- [x] Command deployed to all CLI targets after `./setup.sh`
- [x] Manual test passes with FlowSpace available (structured output returned)
- [x] Manual test passes with FlowSpace unavailable (helpful error message shown)

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| FlowSpace API changes | Low | Medium | Pin to documented tool signatures from fs2 docs; reference docs_get("agents") |
| Query type detection misclassifies | Medium | Low | Include debug output showing detected type; user can override with explicit flags |
| Output too large for parent synthesis | Low | Medium | Enforce default --limit 10; document recommended limits for subagent use |
| Semantic search unavailable commonly | Medium | Low | Clear fallback with warning; document embeddings prerequisite |

---

## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]
[^2]: [To be added during implementation via plan-6a]

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "/Users/jordanknight/github/tools/docs/plans/008-flowspace-research-agent/flowspace-research-agent-plan.md"`
- **Optional validation**: `/plan-4-complete-the-plan` (recommended for final review)
