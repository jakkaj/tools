# GitHub Copilot CLI Support & FlowSpace MCP Integration - Implementation Plan

**Plan Version**: 1.0.0
**Created**: 2026-01-16
**Spec**: [./copilot-cli-support-spec.md](./copilot-cli-support-spec.md)
**Status**: READY

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technical Context](#technical-context)
3. [Design Decisions (Resolved Open Questions)](#design-decisions-resolved-open-questions)
4. [Critical Research Findings](#critical-research-findings)
5. [Testing Philosophy](#testing-philosophy)
6. [Implementation Phases](#implementation-phases)
   - [Phase 1: FlowSpace MCP Server Addition](#phase-1-flowspace-mcp-server-addition)
   - [Phase 2: Copilot CLI Infrastructure](#phase-2-copilot-cli-infrastructure)
   - [Phase 3: Agent File Generation](#phase-3-agent-file-generation)
   - [Phase 4: Copilot CLI MCP Configuration](#phase-4-copilot-cli-mcp-configuration)
   - [Phase 5: Local Installation Support](#phase-5-local-installation-support)
   - [Phase 6: Testing and Documentation](#phase-6-testing-and-documentation)
7. [Cross-Cutting Concerns](#cross-cutting-concerns)
8. [Complexity Tracking](#complexity-tracking)
9. [Progress Tracking](#progress-tracking)
10. [Change Footnotes Ledger](#change-footnotes-ledger)

---

## Executive Summary

**Problem**: The tools repository installer supports Claude Code, OpenCode, Codex, and VS Code Copilot (extension), but does NOT support GitHub Copilot CLI (`@github/copilot` npm package) which is a separate terminal-based tool with different configuration paths and formats. Additionally, FlowSpace MCP server (providing codebase intelligence) is not configured for any agents.

**Solution Approach**:
- Add FlowSpace MCP server to `agents/mcp/servers.json` (benefits all agents immediately)
- Add FlowSpace installation as optional prerequisite with graceful degradation
- Extend `install/agents.sh` to generate Copilot CLI agent files with YAML frontmatter
- Extend Python MCP generator to produce Copilot CLI format (`mcpServers` wrapper + `tools` array)
- Add `copilot-cli` target to `--commands-local` flag for project-local agent installation

**Expected Outcomes**:
- All 23 command files available as Copilot CLI agents in `~/.copilot/agents/`
- FlowSpace and Perplexity MCP servers available to all 5 supported CLIs
- Idempotent installation with backup and merge for existing user configs
- Local installation option for project-specific agents

**Success Metrics**:
- AC1-AC8 from spec all pass
- Integration tests validate all paths
- Manual validation with Copilot CLI confirms MCP tools and agents work

---

## Technical Context

### Current System State

| CLI | Config Location | Commands Location | MCP Config |
|-----|-----------------|-------------------|------------|
| Claude Code | `~/.claude.json` | `~/.claude/commands/` | `mcpServers` in config |
| OpenCode | `~/.config/opencode/` | `~/.config/opencode/command/` | `mcp` in opencode.json |
| Codex | `~/.codex/config.toml` | `~/.codex/prompts/` | `mcp_servers` in TOML |
| VS Code Copilot | `.vscode/mcp.json` | `~/.config/github-copilot/prompts/` | `mcpServers` |
| **Copilot CLI** | **`~/.copilot/`** | **`~/.copilot/agents/`** | **`~/.copilot/mcp-config.json`** |

### Integration Requirements

1. **FlowSpace MCP**: Requires `fs2` binary installed via `uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install`
2. **Copilot CLI Agents**: Require YAML frontmatter with `name`, `description`, `tools` fields
3. **Copilot CLI MCP**: Requires `mcpServers` wrapper with mandatory `tools: ["*"]` array per server

### Constraints and Limitations

- Copilot CLI is in **public preview** - format may change
- FlowSpace installation requires `uv` tool (graceful degradation if missing)
- Agent file conversion must preserve existing frontmatter while adding required fields
- MCP config must merge with user's existing servers, not overwrite

### Assumptions

1. Most command files (19/23) already have YAML frontmatter with `description` field
2. Users have `uv` available or can install it (common in Python environments)
3. Copilot CLI `mcpServers` format with `tools: ["*"]` is stable for public preview
4. `fs2 mcp` command works reliably when fs2 is installed

---

## Design Decisions (Resolved Open Questions)

The spec had 4 open questions. Here are the resolved design decisions:

### DD1: Agent Description Extraction

**Decision**: Use existing frontmatter where available; generate from filename for files without.

**Rationale**:
- 19/23 files already have `description` field in frontmatter
- 4 files without frontmatter (README.md, changes.md, codebase.md, GETTING-STARTED.md) are documentation, not commands
- Skip documentation files from Copilot CLI agent installation

**Implementation**:
- Parse existing YAML frontmatter with Python
- Skip files matching: `README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`
- For any remaining files without description, use: `"Command: {filename_stem}"`

### DD2: FlowSpace Required vs Optional

**Decision**: Optional with prominent warning and graceful degradation.

**Rationale**:
- Not all users need FlowSpace
- Installation depends on `uv` tool which may not be present
- Blocking setup on FlowSpace would frustrate users

**Implementation**:
- Check if `fs2` command exists in PATH
- If not, check if `uv` command exists
- If `uv` available: attempt installation, warn on failure, continue
- If `uv` not available: skip FlowSpace, log warning with installation instructions

### DD3: Copilot CLI Detection

**Decision**: Always create `~/.copilot/` directories (don't require CLI to be installed).

**Rationale**:
- Follows existing pattern (we create `~/.claude/commands/` without checking for Claude)
- User may install Copilot CLI after running setup
- Minimal cost to create empty directories

**Implementation**:
- Always create `~/.copilot/` and `~/.copilot/agents/` directories
- Write MCP config and agent files regardless of CLI installation status

### DD4: MCP Server Merge Strategy

**Decision**: Backup and merge, preserving user additions.

**Rationale**:
- Users may have added custom MCP servers via `/mcp add` command
- Overwriting would break their workflows
- Existing backup pattern in `agents.sh` provides safety

**Implementation**:
- Create timestamped backup of existing `~/.copilot/mcp-config.json`
- Load existing config, merge our servers (overwriting by server name)
- Preserve any user-added servers not in our source
- Validate merged JSON before writing

---

## Critical Research Findings

### 🚨 Critical Discovery 01: MCP Config Format Requires `tools` Array

**Impact**: Critical
**Sources**: [R1-02, I1-03] (risk analyst + implementation strategist)

**Problem**: Copilot CLI MCP config requires a `tools: ["*"]` array for each server. Without this field, no tools are exposed to the agent. This is unique to Copilot CLI - other CLIs don't require it.

**Root Cause**: Copilot CLI's security model requires explicit tool authorization.

**Solution**: Add `tools: ["*"]` to every server in the Copilot CLI config transformation.

**Example**:
```json
// ❌ WRONG - Missing tools field (works in Claude, fails in Copilot CLI)
{
  "mcpServers": {
    "perplexity": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@perplexity-ai/mcp-server"]
    }
  }
}

// ✅ CORRECT - Has tools field (required for Copilot CLI)
{
  "mcpServers": {
    "perplexity": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@perplexity-ai/mcp-server"],
      "tools": ["*"]
    }
  }
}
```

**Action Required**: Extend Python MCP generator to add `tools: ["*"]` for Copilot CLI output.
**Affects Phases**: Phase 4

---

### 🚨 Critical Discovery 02: 19/23 Files Already Have Frontmatter

**Impact**: Critical (Positive)
**Sources**: [I1-02] (implementation strategist)

**Problem**: Initially thought we'd need to generate YAML frontmatter for all files.

**Root Cause**: Most command files were already designed with frontmatter for other purposes.

**Solution**: Extract existing `description` field; only 4 documentation files need special handling.

**Files WITH frontmatter** (19 files):
- All `plan-*.md` files (14 files)
- `tad.md`, `deepresearch.md`, `didyouknow.md`, `substrateresearch.md`, `util-0-handover.md`

**Files WITHOUT frontmatter** (4 files - SKIP these):
- `README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`

**Action Required**: Skip documentation files; extract `description` from existing frontmatter for command files.
**Affects Phases**: Phase 3

---

### ⚠️ High Discovery 03: Copilot CLI Format Instability (Public Preview)

**Impact**: High
**Sources**: [R1-05] (risk analyst)

**Problem**: Copilot CLI is in public preview; format changes have occurred in recent versions (v0.0.340 changed env var syntax, v0.0.337 added server name validation).

**Root Cause**: Active development with frequent releases.

**Solution**:
- Use only stable, well-documented fields
- Add version detection for future-proofing
- Document supported version range

**Example**:
```bash
# Version detection (optional future enhancement)
copilot_version=$(copilot --version 2>/dev/null | head -1 || echo "unknown")
```

**Action Required**: Use defensive configuration generation; document supported Copilot CLI versions.
**Affects Phases**: Phase 4, Phase 6

---

### ⚠️ High Discovery 04: FlowSpace Addition is Independent

**Impact**: High (Positive - enables parallelization)
**Sources**: [I1-04] (implementation strategist)

**Problem**: Initially planned as sequential phases.

**Root Cause**: Analysis showed no dependencies between FlowSpace addition and Copilot CLI work.

**Solution**: Phase 1 (FlowSpace to servers.json) can ship immediately, benefiting all existing CLIs before Copilot CLI support is complete.

**Action Required**: Implement Phase 1 first; it's a quick win.
**Affects Phases**: Phase 1

---

### ⚠️ High Discovery 05: Existing Test Infrastructure Can Be Extended

**Impact**: High
**Sources**: [I1-06] (implementation strategist)

**Problem**: Need testing strategy for new functionality.

**Root Cause**: Existing tests already validate directory creation, file copying, and idempotency.

**Solution**: Extend existing tests:
- `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` - Add Copilot CLI assertions
- `/Users/jordanknight/github/tools/tests/install/test_complete_flow.sh` - Add idempotency checks

**Action Required**: Extend tests, don't create new test files.
**Affects Phases**: Phase 6

---

### Medium Discovery 06: Local Install Pattern Already Established

**Impact**: Medium
**Sources**: [I1-07] (implementation strategist)

**Problem**: How to implement `--commands-local copilot-cli` option.

**Root Cause**: Pattern already exists for claude, opencode, ghcp, codex.

**Solution**: Follow existing pattern with Copilot CLI-specific differences:
- Local path: `.copilot/agents/` (not `.copilot/commands/`)
- No file rename needed (keeps `.md` extension)
- Must prepend/merge YAML frontmatter

**Example**:
```bash
# Existing pattern (lines 515-568 of agents.sh)
if [[ "$cli_list" == *"copilot-cli"* ]]; then
    local copilot_cli_dir="${target_dir}/.copilot/agents"
    # ... generate agent files with frontmatter
fi
```

**Action Required**: Add `copilot-cli` case to `install_local_commands()` function.
**Affects Phases**: Phase 5

---

### Medium Discovery 07: Backup Pattern Already Exists

**Impact**: Medium
**Sources**: [R1-03, R1-07] (risk analyst)

**Problem**: How to handle existing user configs safely.

**Root Cause**: Python MCP generator already has `create_backup()` function.

**Solution**: Reuse existing backup pattern; add merge logic for Copilot CLI config.

**Example** (from agents.sh line 211-222):
```python
def create_backup(path: Path) -> None:
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    backup_path = path.with_suffix(f"{path.suffix}.backup-{timestamp}")
    shutil.copy2(path, backup_path)
    print(f"[Backup] Created backup: {backup_path}")
```

**Action Required**: Call `create_backup()` before modifying `~/.copilot/mcp-config.json`.
**Affects Phases**: Phase 4

---

### Medium Discovery 08: Cross-Platform Path Handling

**Impact**: Medium
**Sources**: [R1-08] (risk analyst)

**Problem**: Copilot CLI paths must work on macOS, Linux, and Windows (WSL).

**Root Cause**: Different platforms use different path conventions.

**Solution**:
- Use `${HOME}/.copilot/` (works on macOS, Linux, WSL)
- Respect `XDG_CONFIG_HOME` if set (Copilot CLI honors this)
- Existing platform detection in agents.sh covers this

**Example**:
```bash
# Copilot CLI path (respects XDG_CONFIG_HOME per docs)
COPILOT_CLI_DIR="${XDG_CONFIG_HOME:-$HOME}/.copilot"
```

**Action Required**: Add path variables with XDG_CONFIG_HOME fallback.
**Affects Phases**: Phase 2

---

## Testing Philosophy

### Testing Approach

**Selected Approach**: Lightweight (extending existing tests)

**Rationale**:
- Existing test infrastructure covers the patterns we're extending
- New functionality follows established patterns
- Focus on integration tests over unit tests for shell scripts

**Focus Areas**:
- Directory creation verification
- File content validation (YAML frontmatter, JSON structure)
- Idempotency verification
- Cross-CLI consistency

### Lightweight Testing

- Extend `tests/install/test_agents_copilot_dirs.sh` with Copilot CLI assertions
- Extend `tests/install/test_complete_flow.sh` with idempotency checks
- Add manual validation checklist for MCP server functionality

### Test Documentation

Each test assertion includes:
- Purpose: What behavior is being verified
- Quality Contribution: What bug class this prevents
- Acceptance Criteria: Measurable pass/fail condition

---

## Implementation Phases

### Phase 1: FlowSpace MCP Server Addition

**Objective**: Add FlowSpace MCP server to `agents/mcp/servers.json` so all existing CLIs gain codebase intelligence immediately.

**Deliverables**:
- Updated `agents/mcp/servers.json` with FlowSpace server definition
- All existing CLIs (Claude, OpenCode, Codex, VS Code) receive FlowSpace MCP

**Dependencies**: None (can ship immediately)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| FlowSpace not installed | Medium | Low | Server defined but won't work until fs2 installed |
| Config format issues | Low | Medium | Test with Claude first (known working format) |

### Tasks (Lightweight Approach)

| # | Status | Task | CS | Success Criteria | Log | Notes |
|---|--------|------|----|------------------|-----|-------|
| 1.1 | [x] | Add FlowSpace server definition to `agents/mcp/servers.json` | 1 | JSON valid, contains flowspace entry with type, command, args | ✓ | `/Users/jordanknight/github/tools/agents/mcp/servers.json` |
| 1.2 | [x] | Run `./setup.sh` to propagate to all CLIs | 1 | FlowSpace appears in ~/.claude.json, opencode.json, etc. | ✓ | Manual verification |
| 1.3 | [x] | Verify FlowSpace works in Claude Code | 1 | `tree()` tool available and functional | ✓ | Requires fs2 installed |

### FlowSpace Server Definition

```json
{
  "flowspace": {
    "type": "local",
    "enabled": true,
    "command": "fs2",
    "args": ["mcp"]
  }
}
```

### Acceptance Criteria
- [x] `agents/mcp/servers.json` contains `flowspace` entry
- [x] Running `./setup.sh` adds flowspace to all CLI configs
- [x] No existing server definitions are broken

---

### Phase 2: Copilot CLI Infrastructure

**Objective**: Add Copilot CLI directory variables and directory creation to `agents.sh`.

**Deliverables**:
- New directory variables: `COPILOT_CLI_DIR`, `COPILOT_CLI_AGENTS_DIR`, `COPILOT_CLI_MCP_CONFIG`
- Directory creation logic in `main()` function
- XDG_CONFIG_HOME support

**Dependencies**: None (infrastructure only)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Path conflicts with VS Code Copilot | Low | Medium | Different paths: ~/.copilot/ vs ~/.config/github-copilot/ |
| Permission issues | Low | Low | Use existing mkdir_with_retry() |

### Tasks (Lightweight Approach)

| # | Status | Task | CS | Success Criteria | Log | Notes |
|---|--------|------|----|------------------|-----|-------|
| 2.1 | [ ] | Add Copilot CLI directory variables after line 74 | 1 | Variables defined with XDG_CONFIG_HOME fallback | - | `/Users/jordanknight/github/tools/install/agents.sh` |
| 2.2 | [ ] | Add directory creation logic in main() after line 726 | 1 | Creates ~/.copilot/ and ~/.copilot/agents/ | - | Follow existing pattern |
| 2.3 | [ ] | Add status messages for Copilot CLI directories | 1 | Logs show directory creation/existence | - | Use print_status/print_success |

### Variable Definitions

```bash
# Add after line 74 (after COPILOT_GLOBAL_DIR)
COPILOT_CLI_DIR="${XDG_CONFIG_HOME:-$HOME}/.copilot"
COPILOT_CLI_AGENTS_DIR="${COPILOT_CLI_DIR}/agents"
COPILOT_CLI_MCP_CONFIG="${COPILOT_CLI_DIR}/mcp-config.json"
```

### Acceptance Criteria
- [ ] Variables defined and exported
- [ ] Running setup creates `~/.copilot/` directory
- [ ] Running setup creates `~/.copilot/agents/` directory
- [ ] XDG_CONFIG_HOME is respected if set

---

### Phase 3: Agent File Generation

**Objective**: Generate Copilot CLI agent files from command files, adding/merging YAML frontmatter.

**Deliverables**:
- Agent file generation logic for Copilot CLI
- YAML frontmatter handling (extract description, add name and tools)
- Skip logic for documentation files

**Dependencies**: Phase 2 (directory variables and creation)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| YAML parsing errors | Medium | Medium | Use Python yaml library, not regex |
| Frontmatter corruption | Low | High | Validate before writing |
| Special characters in names | Low | Low | Sanitize name from filename |

### Tasks (Lightweight Approach)

| # | Status | Task | CS | Success Criteria | Log | Notes |
|---|--------|------|----|------------------|-----|-------|
| 3.1 | [ ] | Create Python function to extract/generate frontmatter | 2 | Extracts description from existing, generates name from filename | - | Add to embedded Python |
| 3.2 | [ ] | Create Python function to generate agent file content | 2 | Produces valid YAML frontmatter + original content | - | Must handle edge cases |
| 3.3 | [ ] | Add file skip logic for documentation files | 1 | Skips README.md, GETTING-STARTED.md, changes.md, codebase.md | - | Pattern matching |
| 3.4 | [ ] | Add agent file copy loop in main() | 2 | Copies all command files to ~/.copilot/agents/ with frontmatter | - | Follow Claude pattern |
| 3.5 | [ ] | Add idempotency check and logging | 1 | Reports count match, logs [✓ Idempotent] on reruns | - | Follow existing pattern |

### Agent File Format

```yaml
---
name: "tad"
description: "Test-Assisted Development (TAD) workflow guide for LLM coding agents practicing \"tests as documentation\""
tools:
  - "*"
---

# Original content follows...
```

### Frontmatter Generation Logic

```python
def generate_copilot_agent(source_path: Path, dest_path: Path):
    """Generate Copilot CLI agent file from command file."""
    content = source_path.read_text(encoding='utf-8')

    # Skip documentation files
    if source_path.name in ['README.md', 'GETTING-STARTED.md', 'changes.md', 'codebase.md']:
        return None

    # Extract existing frontmatter if present
    existing_desc = extract_description(content)

    # Generate name from filename
    name = source_path.stem.lower().replace(' ', '-')

    # Build new frontmatter
    frontmatter = {
        'name': name,
        'description': existing_desc or f"Command: {name}",
        'tools': ['*']
    }

    # Remove existing frontmatter, prepend new
    content_without_fm = strip_frontmatter(content)
    new_content = f"---\n{yaml.dump(frontmatter, default_flow_style=False)}---\n\n{content_without_fm}"

    dest_path.write_text(new_content, encoding='utf-8')
```

### Acceptance Criteria
- [ ] All command files (except 4 docs) copied to `~/.copilot/agents/`
- [ ] Each agent file has valid YAML frontmatter with name, description, tools
- [ ] Original content preserved after frontmatter
- [ ] Documentation files (README, GETTING-STARTED, changes, codebase) skipped
- [ ] Idempotent: running twice produces same result

---

### Phase 4: Copilot CLI MCP Configuration

**Objective**: Extend Python MCP generator to produce `~/.copilot/mcp-config.json` with correct format.

**Deliverables**:
- Copilot CLI MCP config generation in Python script
- Backup and merge logic for existing user configs
- `tools: ["*"]` field added to all servers

**Dependencies**: Phase 2 (directory variables)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Overwriting user's custom servers | Medium | High | Merge, don't overwrite |
| Invalid JSON generation | Low | High | Validate before writing |
| Format changes in Copilot CLI | Medium | Medium | Use stable fields only |

### Tasks (Lightweight Approach)

| # | Status | Task | CS | Success Criteria | Log | Notes |
|---|--------|------|----|------------------|-----|-------|
| 4.1 | [ ] | Add Copilot CLI config path to Python script args | 1 | Script receives copilot_cli_config path | - | Line ~177 of agents.sh |
| 4.2 | [ ] | Add load/merge logic for existing Copilot CLI config | 2 | Preserves user-added servers | - | Similar to other CLIs |
| 4.3 | [ ] | Add `tools: ["*"]` transformation for Copilot CLI | 2 | Each server has tools array | - | Critical difference |
| 4.4 | [ ] | Add Copilot CLI config write with backup | 1 | Writes to ~/.copilot/mcp-config.json | - | Use create_backup() |
| 4.5 | [ ] | Add validation before write | 1 | JSON is valid and has expected structure | - | Prevent corruption |

### MCP Config Transformation

```python
# Copilot CLI specific transformation
copilot_cli_entry = {
    "type": "local",  # Map stdio -> local
    "command": config.get("command"),
    "args": config.get("args", []),
    "tools": ["*"],  # REQUIRED for Copilot CLI
}
if environment:
    copilot_cli_entry["env"] = environment

copilot_cli_servers[name] = copilot_cli_entry
```

### Acceptance Criteria
- [ ] `~/.copilot/mcp-config.json` created with `mcpServers` wrapper
- [ ] Each server has `tools: ["*"]` array
- [ ] Type `stdio` mapped to `local`
- [ ] Existing user servers preserved (merged)
- [ ] Backup created before modification
- [ ] FlowSpace and Perplexity both present

---

### Phase 5: Local Installation Support

**Objective**: Add `copilot-cli` option to `--commands-local` flag for project-local agent installation.

**Deliverables**:
- `copilot-cli` handler in `install_local_commands()` function
- Project-local `.copilot/agents/` directory creation
- Agent files with frontmatter (same as global)

**Dependencies**: Phase 3 (agent file generation logic)

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Conflict with global agents | Low | Low | Local takes precedence in Copilot CLI |
| Different frontmatter for local | Low | Medium | Use same generation logic |

### Tasks (Lightweight Approach)

| # | Status | Task | CS | Success Criteria | Log | Notes |
|---|--------|------|----|------------------|-----|-------|
| 5.1 | [ ] | Add `copilot-cli` case to install_local_commands() | 2 | Handles copilot-cli in CLI list | - | After line 568 |
| 5.2 | [ ] | Create local `.copilot/agents/` directory | 1 | Directory created in target_dir | - | Follow claude pattern |
| 5.3 | [ ] | Generate agent files to local directory | 2 | Same frontmatter logic as global | - | Reuse Phase 3 logic |
| 5.4 | [ ] | Add success message for local install | 1 | Reports files installed | - | Follow existing pattern |
| 5.5 | [ ] | Update help text to include copilot-cli | 1 | Documentation shows copilot-cli option | - | Line 8 of agents.sh |

### Local Install Pattern

```bash
# Add after line 568 (after ghcp case)
if [[ "$cli_list" == *"copilot-cli"* ]]; then
    local copilot_cli_dir="${target_dir}/.copilot/agents"
    mkdir_with_retry "${copilot_cli_dir}"
    print_status "Installing Copilot CLI agents to ${copilot_cli_dir}"

    for file in "${SOURCE_DIR}"/*.md; do
        if [ -f "${file}" ]; then
            filename=$(basename "${file}")
            # Skip documentation files
            if [[ "$filename" == "README.md" ]] || [[ "$filename" == "GETTING-STARTED.md" ]] || \
               [[ "$filename" == "changes.md" ]] || [[ "$filename" == "codebase.md" ]]; then
                continue
            fi
            # Generate agent file with frontmatter (Python call)
            # ...
        fi
    done

    print_success "Installed agents to ${copilot_cli_dir}"
    echo ""
fi
```

### Acceptance Criteria
- [ ] `--commands-local copilot-cli` creates `.copilot/agents/` in target directory
- [ ] Agent files have valid YAML frontmatter
- [ ] Documentation files skipped
- [ ] No MCP config modified (local = agents only)
- [ ] Help text includes copilot-cli option

---

### Phase 6: Testing and Documentation

**Objective**: Extend existing tests and update documentation for Copilot CLI support.

**Deliverables**:
- Extended test assertions for Copilot CLI paths
- Updated CLAUDE.md with Copilot CLI information
- Manual validation checklist

**Dependencies**: Phases 1-5 complete

**Risks**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Test failures on CI | Medium | Medium | Test locally first |
| Documentation drift | Low | Low | Update docs in same PR |

### Tasks (Lightweight Approach)

| # | Status | Task | CS | Success Criteria | Log | Notes |
|---|--------|------|----|------------------|-----|-------|
| 6.1 | [ ] | Extend test_agents_copilot_dirs.sh with CLI assertions | 2 | Tests verify ~/.copilot/agents/ and mcp-config.json | - | `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` |
| 6.2 | [ ] | Extend test_complete_flow.sh with idempotency check | 1 | Verifies Copilot CLI is idempotent | - | `/Users/jordanknight/github/tools/tests/install/test_complete_flow.sh` |
| 6.3 | [ ] | Update CLAUDE.md with Copilot CLI support info | 1 | Documents paths, format differences | - | `/Users/jordanknight/github/tools/CLAUDE.md` |
| 6.4 | [ ] | Update README.md with Copilot CLI option | 1 | Shows copilot-cli in --commands-local | - | `/Users/jordanknight/github/tools/README.md` |
| 6.5 | [ ] | Run full test suite and fix any failures | 2 | All tests pass | - | Manual execution |
| 6.6 | [ ] | Manual validation with Copilot CLI | 2 | MCP servers work, agents invocable | - | Requires Copilot CLI installed |

### Test Assertions to Add

```bash
# In test_agents_copilot_dirs.sh

# Verify Copilot CLI agents directory created
COPILOT_CLI_AGENTS_DIR="${TMP_HOME}/.copilot/agents"
if [ ! -d "${COPILOT_CLI_AGENTS_DIR}" ]; then
    echo "FAIL: Copilot CLI agents directory not created"
    exit 1
fi

# Verify agent files have frontmatter
for agent_file in "${COPILOT_CLI_AGENTS_DIR}"/*.md; do
    if ! head -1 "$agent_file" | grep -q "^---"; then
        echo "FAIL: $agent_file missing YAML frontmatter"
        exit 1
    fi
done

# Verify MCP config exists and has correct structure
COPILOT_CLI_MCP="${TMP_HOME}/.copilot/mcp-config.json"
if [ ! -f "${COPILOT_CLI_MCP}" ]; then
    echo "FAIL: Copilot CLI MCP config not created"
    exit 1
fi

# Verify mcpServers wrapper exists
if ! grep -q '"mcpServers"' "${COPILOT_CLI_MCP}"; then
    echo "FAIL: MCP config missing mcpServers wrapper"
    exit 1
fi

# Verify tools array exists
if ! grep -q '"tools"' "${COPILOT_CLI_MCP}"; then
    echo "FAIL: MCP config missing tools array"
    exit 1
fi
```

### Manual Validation Checklist

- [ ] Run `copilot` in terminal
- [ ] Type `/mcp` to list MCP servers
- [ ] Verify `perplexity` and `flowspace` appear
- [ ] Type `/agent` to list available agents
- [ ] Verify command agents appear (tad, plan-3-architect, etc.)
- [ ] Invoke `/agent tad` and verify agent responds
- [ ] Test FlowSpace tool: ask to explore codebase structure

### Acceptance Criteria
- [ ] `test_agents_copilot_dirs.sh` passes with new assertions
- [ ] `test_complete_flow.sh` verifies Copilot CLI idempotency
- [ ] CLAUDE.md documents Copilot CLI support
- [ ] README.md shows copilot-cli in help
- [ ] Manual validation confirms MCP and agents work

---

## Cross-Cutting Concerns

### Security Considerations

- **API Keys**: Perplexity API key passed via environment variable, never hardcoded
- **File Permissions**: Created files follow user's umask
- **Backup Safety**: Timestamped backups prevent accidental data loss

### Observability

- **Logging**: All operations logged with `[*]`, `[✓]`, `[✗]`, `[⚠]` prefixes
- **Idempotency Reporting**: `[✓ Idempotent]` message confirms clean reruns
- **Error Details**: Failures include path and suggested remediation

### Documentation

- **Location**: CLAUDE.md (primary), README.md (overview)
- **Content**: Paths, format differences, manual validation steps
- **Target Audience**: Developers setting up multi-CLI environments

---

## Complexity Tracking

| Component | CS | Label | Breakdown (S,I,D,N,F,T) | Justification | Mitigation |
|-----------|-----|-------|------------------------|---------------|------------|
| FlowSpace Addition | 1 | Trivial | S=0,I=0,D=0,N=0,F=0,T=1 | Single file change | None needed |
| Directory Infrastructure | 1 | Trivial | S=0,I=0,D=0,N=0,F=0,T=1 | Follow existing pattern | None needed |
| Agent File Generation | 3 | Medium | S=1,I=0,D=0,N=1,F=0,T=1 | YAML handling, edge cases | Test with all files |
| MCP Config Generation | 3 | Medium | S=1,I=1,D=0,N=1,F=0,T=0 | Different format, merge logic | Backup and validate |
| Local Install Support | 2 | Small | S=0,I=0,D=0,N=1,F=0,T=1 | Follow existing pattern | Reuse global logic |
| Testing & Docs | 2 | Small | S=1,I=0,D=0,N=0,F=0,T=1 | Extend existing tests | None needed |

**Overall**: CS-3 (medium) - Manageable complexity with clear patterns to follow.

---

## Progress Tracking

### Phase Completion Checklist

- [x] Phase 1: FlowSpace MCP Server Addition - COMPLETE
- [ ] Phase 2: Copilot CLI Infrastructure - NOT STARTED
- [ ] Phase 3: Agent File Generation - NOT STARTED
- [ ] Phase 4: Copilot CLI MCP Configuration - NOT STARTED
- [ ] Phase 5: Local Installation Support - NOT STARTED
- [ ] Phase 6: Testing and Documentation - NOT STARTED

### STOP Rule

**IMPORTANT**: This plan must be validated before creating detailed tasks. After reviewing this plan:
1. Run `/plan-4-complete-the-plan` to validate readiness
2. Only proceed to `/plan-5-phase-tasks-and-brief` after validation passes

---

## Change Footnotes Ledger

**NOTE**: This section will be populated during implementation by plan-6a-update-progress.

[^1]: [To be added during implementation via plan-6a]
[^2]: [To be added during implementation via plan-6a]
[^3]: [To be added during implementation via plan-6a]

---

**Plan Status**: READY
**Next Step**: Run `/plan-4-complete-the-plan` to validate readiness
