# Research Report: Copilot CLI Skills for Local Install

**Generated**: 2026-04-06T02:46:00Z
**Research Query**: "Add copilot-cli skills support to --commands-local so /slash-command invocation works in project-local installs"
**Mode**: Pre-Plan
**Location**: docs/plans/018-copilot-cli-skills-local/research-dossier.md
**FlowSpace**: Available
**Findings**: 28

## Executive Summary

### What It Does
The `--commands-local` feature in `jk-tools-setup` installs AI assistant command files into project-local directories so teams can share them via git. It currently supports Claude, OpenCode, GitHub Copilot (VS Code), and Copilot CLI — but Copilot CLI local uses the `.agent.md` format which only exposes commands via the `/agent` menu, not as direct `/slash-commands`.

### Business Purpose
Users want `uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local copilot-cli` to install commands that work as `/plan-1a-v2-explore` directly in Copilot CLI. The fix: install as **skills** (`.github/skills/<name>/SKILL.md`) instead of agents (`.github/agents/*.agent.md`). Follow-up for Copilot CLI 1.0.36: global installs also use personal skills at `~/.copilot/skills/<name>/SKILL.md`.

### Key Insights
1. **Local `.agent.md` files don't get slash-command promotion** — only `/agent` → pick from list. Global agents previously worked but are superseded by personal skills for Copilot CLI 1.0.36+.
2. **Skills format gives direct `/skill-name` invocation** — both locally and globally, with auto-discovery.
3. **The transformation is straightforward** — same frontmatter fields (`name`, `description`), just different directory structure (flat → directory-per-skill) and filename (`.agent.md` → `SKILL.md`).

### Quick Stats
- **Files to change**: 2-3 (`install/agents.sh`, `setup_manager.py` CLI help text, `AGENTS.md` docs)
- **Existing copilot-cli local support**: Yes, but uses agent format
- **Test coverage for --commands-local**: None (gap identified)
- **Prior learnings**: Plan 007 established the copilot-cli agent pattern

## How It Currently Works

### Entry Points

| Entry Point | Type | Location | Purpose |
|------------|------|----------|---------|
| `jk-tools-setup` CLI | Command | `src/jk_tools/cli.py:57-83` | Parse `--commands-local` arg |
| `SetupManager.run()` | Method | `setup_manager.py:483-507` | Route to local-only install |
| `install_local_commands()` | Function | `install/agents.sh:574-740` | Write files per CLI target |

### Core Execution Flow

1. **User runs**: `uvx jk-tools-setup --commands-local copilot-cli`
2. **cli.py:57-83**: Parses args, sets `manager.commands_local = "copilot-cli"`
3. **setup_manager.py:483-507**: Detects local mode, runs only `agents.sh`
4. **setup_manager.py:302-314**: Passes `--python`, `--commands-local copilot-cli`, `--local-dir <cwd>`
5. **agents.sh:48-63**: Parses `--commands-local` into `COMMANDS_LOCAL`
6. **agents.sh:742-746**: Routes to `install_local_commands()`
7. **agents.sh:662-699**: Copilot CLI handler:
   - Creates `.github/agents/`
   - Runs embedded Python to transform v2-commands → `.agent.md`
   - Strips existing frontmatter, adds `name`, `description`, `tools: ["*"]`

### Current Copilot CLI Local Output
```
.github/agents/
├── plan-0-v2-constitution.agent.md
├── plan-1a-v2-explore.agent.md
├── deepresearch-v2.agent.md
└── ... (all v2-commands as .agent.md)
```

### What We Need Instead (Skills Format)
```
.github/skills/
├── plan-0-v2-constitution/
│   └── SKILL.md
├── plan-1a-v2-explore/
│   └── SKILL.md
├── deepresearch-v2/
│   └── SKILL.md
└── ...
```

## Architecture & Design

### Each CLI Target Pattern

| CLI | Local Path | File Pattern | Frontmatter | Transform |
|-----|-----------|--------------|-------------|-----------|
| Claude | `.claude/commands/` | `*.md` (as-is) | None needed | Raw copy |
| OpenCode | `.opencode/command/` | `*.md` (as-is) | None needed | Raw copy |
| GitHub Copilot VS Code | `.github/prompts/` | `*.prompt.md` | None needed | Rename only |
| Copilot CLI (current) | `.github/agents/` | `*.agent.md` | `name`, `description`, `tools` | Python transform |
| **Copilot CLI (target)** | **`.github/skills/`** | **`<name>/SKILL.md`** | **`name`, `description`** | **Python transform + mkdir** |

### SKILL.md Format Required

```yaml
---
name: plan-1a-v2-explore
description: Deep-dive research into existing codebase functionality...
---

(markdown body — same content as source .md)
```

Key differences from `.agent.md`:
- **No `tools: ["*"]`** field (skills don't restrict tools the same way; use `allowed-tools` if needed)
- **File must be named `SKILL.md`** (not a custom filename)
- **Lives inside a named subdirectory** (not flat in a directory)

## Dependencies & Integration

### What Changes

| File | Change | Impact |
|------|--------|--------|
| `install/agents.sh:662-699` | Replace `.github/agents/` logic with `.github/skills/` logic | Core change |
| `install/agents.sh:666` | Change cleanup pattern from `plan-*.agent.md` to `plan-*/SKILL.md` | Cleanup |
| `install/agents.sh:670-695` | Rewrite embedded Python to create subdirs + SKILL.md | Transform |
| `install/agents.sh:698-699` | Update count/success message | Cosmetic |
| `install/agents.sh:733-735` | Update summary output for skills | Cosmetic |
| `AGENTS.md` | Update docs to reflect skills format for local | Docs |
| `setup_manager.py:575` | Help text already includes copilot-cli ✅ | None |

### What Stays the Same
- **Global install target semantics** — v2 commands remain globally available, now through `~/.copilot/skills/<name>/SKILL.md`
- **CLI parsing** — `copilot-cli` is already a valid option
- **Source files** — `agents/v2-commands/*.md` unchanged
- **Other CLI targets** — Claude, OpenCode, ghcp unchanged

## Quality & Testing

### Current Test Coverage
- **Python unit tests**: `tests/test_coding_tools_installer.py` — covers installer primitives, NOT `--commands-local`
- **Shell smoke tests**: `tests/install/test_agents_copilot_dirs.sh` — covers global install, NOT local
- **Idempotency test**: `tests/install/test_complete_flow.sh` — global only
- **Gap**: No tests for `--commands-local` at all, no tests for copilot-cli local

### Test Strategy for This Change
- Verify skills directories created: `.github/skills/<name>/SKILL.md` for each v2-command
- Verify SKILL.md frontmatter has `name` and `description`
- Verify body content matches source (minus original frontmatter)
- Verify cleanup of old `.github/agents/*.agent.md` (migration)
- Verify idempotent re-run

## Prior Learnings (From Previous Implementations)

### 📚 Prior Learning PL-01: Copilot CLI Requires Specific Frontmatter
**Source**: docs/plans/007-copilot-cli-support/copilot-cli-support-plan.md
**Original Type**: decision
**Why This Matters**: Skills use `name` + `description` (both required). No `tools` field needed for skills. The existing Python transform already extracts these — just needs to stop adding `tools: ["*"]`.

### 📚 Prior Learning PL-02: File Extension Discovery Is Format-Specific
**Source**: docs/plans/001-ghcp-prompt-mirroring
**Original Type**: gotcha
**Why This Matters**: Just as `.prompt.md` is required for VS Code Copilot discovery, `SKILL.md` (exact name) is required for Copilot CLI skill discovery. The file MUST be named `SKILL.md`, not anything else.

### 📚 Prior Learning PL-03: Copilot CLI Format May Change
**Source**: docs/plans/007-copilot-cli-support/copilot-cli-support-plan.md:219-239
**Original Type**: insight
**Why This Matters**: Copilot CLI is in public preview. The skills format is newer than agents. We should keep the transform logic clean and isolated so it's easy to update.

### 📚 Prior Learning PL-04: Idempotent Overwrite Pattern
**Source**: docs/plans/001-ghcp-prompt-mirroring
**Original Type**: decision
**Why This Matters**: The established pattern is idempotent overwrite (no rollback/filtering). The skills installer should follow this — clean old skills, write new ones.

## Modification Considerations

### ✅ Safe to Modify
- `install/agents.sh:662-699` — the copilot-cli local block is self-contained
- Embedded Python script — isolated transform logic
- AGENTS.md docs — documentation only

### ⚠️ Modify with Caution
- Cleanup logic — need to handle migration from old `.github/agents/*.agent.md` to new `.github/skills/*/SKILL.md`
- Should we keep creating `.github/agents/` for backward compat? Probably not — clean break.

### Extension Points
- The embedded Python pattern (inline Python in bash) is well-established — follow it for consistency
- The `V2_SOURCE_DIR` variable provides the source path — reuse it

## Critical Discoveries

### 🚨 Critical Finding 01: Skills Need Directory-Per-Skill Structure
**Impact**: Critical
**What**: Unlike agents (flat files), each skill needs its own subdirectory. `plan-1a-v2-explore` → `.github/skills/plan-1a-v2-explore/SKILL.md`
**Required Action**: The embedded Python must `mkdir -p` per skill before writing

### 🚨 Critical Finding 02: Cleanup Must Handle Both Old and New Formats
**Impact**: High
**What**: Users upgrading from agent-based local install will have `.github/agents/*.agent.md`. The new installer should optionally clean those up.
**Required Action**: Add cleanup of old `.github/agents/plan-*.agent.md` when switching to skills

### 🚨 Critical Finding 03: Global Install Should Use Skills
**Impact**: High
**What**: This research originally found global `~/.copilot/agents/*.agent.md` sufficient, but Copilot CLI 1.0.36 no longer reliably surfaces that path. Global installs should use `~/.copilot/skills/<name>/SKILL.md`.
**Required Action**: Generate personal skills globally and clean up old generated `.agent.md` files.

## Recommendations

### Implementation Approach
1. **Modify `install/agents.sh:662-699`** — replace agent-writing Python with skill-writing Python
2. **Add migration cleanup** — remove old `.github/agents/plan-*.agent.md` if they exist
3. **Update docs** — AGENTS.md table showing `.github/skills/` for local copilot-cli
4. **Use skills globally** — `~/.copilot/skills/<name>/SKILL.md` is the reliable Copilot CLI 1.0.36+ format

### Key Design Decisions
- **Skills for local and global Copilot CLI** — `.github/skills` for projects, `~/.copilot/skills` for personal/global installs
- **No `tools` field in SKILL.md** — skills don't use the same tools restriction model
- **Consider `allowed-tools: shell`** — if you want skills to run bash without confirmation
- **Directory cleanup** — use `rm -rf .github/skills/plan-*` pattern for idempotent cleanup

## Next Steps

- **Run `/plan-1b-specify`** to create the feature specification
- Then **`/plan-3-architect`** for implementation plan

---

**Research Complete**: 2026-04-06T02:50:00Z
**Report Location**: docs/plans/018-copilot-cli-skills-local/research-dossier.md
