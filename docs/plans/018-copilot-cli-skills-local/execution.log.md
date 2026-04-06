# Execution Log — 018 Copilot CLI Skills for Local Install

## T001+T002: Rewrite copilot-cli local install + cleanup logic
**Status**: ✅ Complete
**File**: `install/agents.sh:662-720`
**Changes**:
- Rewrote target dir from `.github/agents` → `.github/skills`
- Embedded Python now creates `<name>/SKILL.md` per skill (directory-per-skill)
- Frontmatter: `name` + `description` only (dropped `tools: ["*"]`)
- Added migration: cleans old `.github/agents/*.agent.md` files
- Added cleanup of old `plan-*/` skill dirs for idempotent re-runs
- Skip list expanded: `README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`

**Evidence**: 23 skills installed, correct structure verified, migration cleans old agents dir.

## T003: Update summary output
**Status**: ✅ Complete
**File**: `install/agents.sh:733-736`
**Changes**: Updated find command and display to show `.github/skills/ (N skills)` instead of `.github/agents/ (N .agent.md files)`.

## T004: Update AGENTS.md
**Status**: ✅ Complete
**File**: `AGENTS.md:170, 192-193, 214-219`
**Changes**:
- Local path table: `.github/skills/<name>/SKILL.md`
- Example comment: "Install Copilot CLI skills" (was "agents")
- Copilot CLI Notes: rewritten for skills format

## Verification Results

| Test | Result |
|------|--------|
| Skills structure created | ✅ 23 `<name>/SKILL.md` files |
| Frontmatter format | ✅ `name` + `description`, no `tools` |
| Excluded files (README, GETTING-STARTED, changes, codebase) | ✅ 0 found |
| Idempotent re-run | ✅ Same 23 skills, no duplicates |
| Migration from old .agent.md | ✅ Old dir cleaned up |
| Combined targets (claude,copilot-cli) | ✅ Both installed correctly |
| Global install unchanged | ✅ Not touched |

## Discoveries

| # | Type | Finding |
|---|------|---------|
| D1 | gotcha | The `__COUNT__` output from Python leaks into bash stdout but doesn't affect the find-based count used for the success message |
| D2 | insight | `rmdir` with `2>/dev/null` gracefully handles non-empty dirs (user may have custom agents we shouldn't delete) |
