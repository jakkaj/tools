# Cross-Branch Plan Ordinal Counter Tool - Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-01-27
**Spec**: [./cross-branch-plan-ordinal-spec.md](./cross-branch-plan-ordinal-spec.md)
**Status**: COMPLETE

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Implementation](#implementation)
4. [Change Footnotes Ledger](#change-footnotes-ledger)

## Executive Summary

**Problem**: Plan creation commands (`/plan-1a-explore`, `/plan-1b-specify`) count folders only on the current branch's filesystem. When developers work on parallel feature branches, they get the same ordinal, causing merge conflicts.

**Solution**: Create a Python CLI tool (`plan-ordinal`) that uses `git ls-tree` to enumerate `docs/plans/NNN-*` folders across all local and remote branches, finds the maximum ordinal, and outputs the next available number (e.g., "011").

**Expected Outcome**: Zero ordinal collisions across branches; simple 3-digit output for integration into plan commands; follows existing tool conventions with `jk-po` alias.

## Critical Research Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | `git ls-tree --name-only <branch> docs/plans/` reads directory contents without checkout | Use this as primary branch scanning mechanism |
| 02 | Critical | Empty output (not error) when `docs/plans/` doesn't exist on a branch; exit code 0 | Handle empty results as valid "no plans" case |
| 03 | Critical | Exit code 128 when not in git repository | Catch and convert to user-friendly error message with exit 1 |
| 04 | High | `git rev-parse --show-toplevel` returns absolute repo root from any subdirectory | Use for directory-independent operation |
| 05 | High | Branch listing via `git branch -a --format='%(refname:short)'` includes symbolic refs like `origin` | Filter out non-branch refs before scanning |
| 06 | High | Remote branches appear with `origin/` prefix; same branch may exist both locally and remotely | Deduplicate by branch name to avoid double-counting |
| 07 | High | Repository uses `subprocess.run` with clean environment to prevent `BASH_ENV` interference | Copy clean_env pattern from setup_manager.py |
| 08 | High | Scripts use `#!/usr/bin/env python3` shebang for portability | Use this shebang, not hardcoded python path |
| 09 | Medium | Help text format: NAME, SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES, ALIAS sections | Follow exact format from existing tools |
| 10 | Medium | Alias `jk-po` auto-generated from `plan-ordinal` by install/aliases.py | No manual alias work needed; just name file correctly |
| 11 | Medium | Exit 0 for success, exit 1 for errors; errors to stderr | Use `sys.exit()` and `print(..., file=sys.stderr)` |
| 12 | Medium | JSON output should use `json.dumps()` to stdout | For `--json` flag output format |
| 13 | Low | Tool discovery via `jk-tools` extracts NAME section from `--help` | Ensure NAME section has clear one-line description |
| 14 | Low | README.md has no tool catalog; tools are dynamically discovered | Brief mention in README Features section sufficient |

## Implementation (Single Phase)

**Objective**: Create `plan-ordinal` Python CLI tool that scans all git branches and returns the next available plan ordinal.

**Testing Approach**: Manual Only (per spec)
**Mock Usage**: N/A (no mocks - real git operations)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T001 | Create plan-ordinal.py script with shebang and imports | 1 | Setup | -- | /home/jak/github/tools/scripts/plan-ordinal.py | File exists, is executable, has correct shebang | `#!/usr/bin/env python3` |
| [x] | T002 | Implement `get_repo_root()` function | 1 | Core | T001 | /home/jak/github/tools/scripts/plan-ordinal.py | Returns correct path from any subdirectory; returns None if not in git repo | Uses `git rev-parse --show-toplevel` |
| [x] | T003 | Implement `get_all_branches()` function | 2 | Core | T001 | /home/jak/github/tools/scripts/plan-ordinal.py | Returns deduplicated list of local and remote branches | Filter symbolic refs, handle `origin/` prefix |
| [x] | T004 | Implement `get_ordinals_from_branch(branch)` function | 2 | Core | T001 | /home/jak/github/tools/scripts/plan-ordinal.py | Returns list of integers from branch's `docs/plans/NNN-*` folders | Uses `git ls-tree`, extracts 3-digit prefix |
| [x] | T005 | Implement `get_all_ordinals()` main logic | 2 | Core | T002,T003,T004 | /home/jak/github/tools/scripts/plan-ordinal.py | Returns dict with `current`, `next`, `ordinals`, `by_branch` | Aggregates ordinals across all branches |
| [x] | T006 | Implement argument parsing (--help, --next, --current, --json) | 2 | Core | T001 | /home/jak/github/tools/scripts/plan-ordinal.py | All flags work correctly; --help shows formatted help | Use argparse with RawDescriptionHelpFormatter |
| [x] | T007 | Implement main() entry point with output formatting | 2 | Core | T005,T006 | /home/jak/github/tools/scripts/plan-ordinal.py | Outputs 3-digit ordinal (text) or JSON based on flags | Default: `--next`; format: "011" |
| [x] | T008 | Add error handling for non-git repo case | 1 | Core | T002,T007 | /home/jak/github/tools/scripts/plan-ordinal.py | Clear error message to stderr, exit code 1 | "Error: Not in a git repository" |
| [x] | T009 | Make script executable and run setup.sh | 1 | Config | T007 | /home/jak/github/tools/scripts/plan-ordinal.py | `chmod +x`; alias `jk-po` created in ~/.tools_aliases | Run `./setup.sh` to sync and create alias |
| [x] | T010 | Add brief entry to README.md | 1 | Docs | T009 | /home/jak/github/tools/README.md | README mentions plan-ordinal tool | Brief entry in Features section |
| [x] | T011 | Manual verification: test all acceptance criteria | 1 | Test | T009 | -- | All 10 acceptance criteria from spec pass | Run through manual verification steps |

### Acceptance Criteria
- [x] Running `plan-ordinal` in repo with plans 001-010 outputs `011` ✓ Verified
- [x] Tool detects plans across multiple branches (cross-branch detection) ✓ Tested on chainglass (8 branches)
- [x] Remote branch plans (origin/*) are detected ✓ origin/revert-2-004-config detected
- [x] Running in repo with no `docs/plans/` outputs `001` ✓ Verified (tools repo has no committed plans)
- [x] Running outside git repo outputs error and exits with code 1 ✓ Exit code 1, clear message
- [x] `plan-ordinal --help` displays formatted help with all sections ✓ NAME/SYNOPSIS/DESCRIPTION/OPTIONS/EXAMPLES
- [x] `plan-ordinal --json` outputs valid JSON: `{"next": 11}` ✓ Verified
- [x] `plan-ordinal --current` outputs highest existing ordinal ✓ Returns "010" / "012" correctly
- [x] Alias `jk-po` works after running setup.sh ✓ Created in ~/.tools_aliases
- [x] Tool works from any subdirectory in the repo ✓ Verified from scripts/ subdirectory

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Unfetched remotes miss plans | Medium | Medium | Document `git fetch` as prerequisite in --help |
| Large branch count causes slowness | Low | Low | Branch deduplication; accept for v1 |
| Concurrent invocation race condition | Low | Low | Accept; folder collision will be visible |

## Change Footnotes Ledger

[^1]: T001-T008 - Created plan-ordinal.py with all core functions
  - `file:scripts/plan-ordinal.py`
  - `function:scripts/plan-ordinal.py:get_repo_root`
  - `function:scripts/plan-ordinal.py:get_all_branches`
  - `function:scripts/plan-ordinal.py:get_ordinals_from_branch`
  - `function:scripts/plan-ordinal.py:get_all_ordinals`
  - `function:scripts/plan-ordinal.py:main`

[^2]: T009-T010 - Configuration and documentation
  - `file:README.md` (added Features entry)
  - `file:~/.tools_aliases` (jk-po alias added by setup.sh)

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "docs/plans/011-cross-branch-plan-ordinal"`
- **Optional validation**: `/plan-4-complete-the-plan` (recommended for verification)
- **Optional task expansion**: `/plan-5-phase-tasks-and-brief` (if you want a separate dossier)
