# GitHub Copilot CLI Support & FlowSpace MCP Integration

ℹ️ This specification incorporates findings from live research conducted in the current session (Perplexity deep research on Copilot CLI configuration).

## Research Context

**Key Findings from Session Research:**
- Copilot CLI (`@github/copilot` npm package) is **distinct** from VS Code Copilot extension
- Uses different config paths: `~/.copilot/` vs `~/.config/github-copilot/`
- MCP config format differs: `mcpServers` wrapper with `tools` field required
- Agents require YAML frontmatter (minimum: `name`, `description`)
- No simple prompt files - only agents or repo instructions
- FlowSpace MCP not currently in `agents/mcp/servers.json`

**Components Affected:**
- `install/agents.sh` - main installer script
- `agents/mcp/servers.json` - MCP server definitions
- `agents/commands/*.md` - command files (need conversion for Copilot CLI)
- New installer for FlowSpace prerequisite

**Critical Dependencies:**
- Node.js 22+ and npm 10+ for Copilot CLI
- `uv` tool for FlowSpace installation
- GitHub Copilot subscription for Copilot CLI usage

---

## Summary

**WHAT**: Extend the tools repository installer to support GitHub Copilot CLI as a first-class target alongside Claude Code, OpenCode, Codex, and VS Code. Additionally, add FlowSpace MCP server to all supported coding agents and ensure FlowSpace is installed as a prerequisite.

**WHY**:
- Copilot CLI is actively developed with agentic capabilities (agent mode, delegation, MCP support, session resumption)
- Users want consistent command/prompt availability across all their AI coding assistants
- FlowSpace provides valuable codebase intelligence that benefits all coding agents, not just one
- Current setup only supports VS Code Copilot extension prompts, missing the CLI tool entirely

---

## Goals

1. **FlowSpace Prerequisite Installation**: Automatically install FlowSpace (`fs2`) as a uv tool during setup, enabling MCP server availability for all agents
2. **FlowSpace MCP for All Agents**: Add FlowSpace MCP server configuration to `agents/mcp/servers.json` so all supported coding agents (Claude, OpenCode, Codex, VS Code, Copilot CLI) gain codebase intelligence
3. **Copilot CLI Agent Support**: Install command files as Copilot CLI agents with proper YAML frontmatter to `~/.copilot/agents/`
4. **Copilot CLI MCP Support**: Generate `~/.copilot/mcp-config.json` with correct format (mcpServers wrapper, tools array, type mappings)
5. **Idempotent Installation**: Support multiple runs without duplicates or corruption, following existing patterns
6. **Local Installation Option**: Extend `--commands-local` flag to support `copilot-cli` target for project-local agent installation

---

## Non-Goals

- **Copilot CLI Installation**: Will not install `@github/copilot` npm package itself (user responsibility, requires Node.js 22+)
- **GitHub Authentication**: Will not handle Copilot CLI login or authentication
- **VS Code Extension Changes**: Existing VS Code Copilot prompt support (`~/.config/github-copilot/prompts/`) remains unchanged
- **Custom Agent Personas**: Will not create specialized agents beyond converting existing commands
- **Repository-level Instructions**: Will not manage `.github/copilot-instructions.md` (project-specific)
- **Copilot CLI Configuration**: Will not manage `~/.copilot/config.json` (user preferences)

---

## Complexity

**Score**: CS-3 (medium)

**Breakdown**: S=1, I=1, D=0, N=1, F=0, T=1 (Total: 4 → CS-3)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Surface Area (S) | 1 | Multiple files: agents.sh, servers.json, possibly new fs2 installer |
| Integration (I) | 1 | One new external dep (fs2 install), Copilot CLI config format |
| Data/State (D) | 0 | No database/schema changes |
| Novelty (N) | 1 | Some ambiguity in YAML frontmatter requirements, type mappings |
| Non-Functional (F) | 0 | Standard reliability requirements |
| Testing/Rollout (T) | 1 | Integration tests for new paths, manual validation |

**Confidence**: 0.85

**Assumptions**:
- Copilot CLI configuration format is stable (based on current docs)
- YAML frontmatter with `name` + `description` is sufficient for basic agents
- FlowSpace `fs2 mcp` command works reliably as MCP server
- Users have `uv` tool installed (or setup will install it)

**Dependencies**:
- `uv` package manager must be available for FlowSpace installation
- Copilot CLI must be pre-installed by user for agent usage
- FlowSpace requires `fs2 init && fs2 scan` per-project (user responsibility)

**Risks**:
- Copilot CLI format may change (public preview status)
- YAML parsing edge cases in command file content
- FlowSpace installation may fail on some systems

**Suggested Phases**:
1. **Phase 1**: Add FlowSpace to servers.json (benefits all agents immediately)
2. **Phase 2**: Add FlowSpace installation script
3. **Phase 3**: Add Copilot CLI directory/file generation to agents.sh
4. **Phase 4**: Add Copilot CLI to local install option
5. **Phase 5**: Testing and documentation updates

---

## Acceptance Criteria

### AC1: FlowSpace MCP Server Available to All Agents
**Given** a user runs `./setup.sh` or `uvx jk-tools`
**When** the installation completes successfully
**Then** FlowSpace MCP server configuration exists in:
- `~/.claude.json` (mcpServers.flowspace)
- `~/.config/opencode/opencode.json` (mcp.flowspace)
- `~/.codex/config.toml` (mcp_servers.flowspace)
- `.vscode/mcp.json` (mcpServers.flowspace)
- `~/.copilot/mcp-config.json` (mcpServers.flowspace)

### AC2: FlowSpace Installation as Prerequisite
**Given** a user runs setup and FlowSpace is not installed
**When** the installer checks for prerequisites
**Then** FlowSpace is installed via `uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install`
**And** the `fs2` command becomes available in user's PATH

### AC3: Copilot CLI Agents Directory Created
**Given** a user runs the installer
**When** Copilot CLI support is enabled
**Then** directory `~/.copilot/agents/` exists
**And** contains one `.md` file per command in `agents/commands/`

### AC4: Copilot CLI Agent Files Have Valid YAML Frontmatter
**Given** command file `agents/commands/tad.md` exists
**When** converted to Copilot CLI agent
**Then** `~/.copilot/agents/tad.md` contains:
```yaml
---
name: "tad"
description: "[extracted from first heading or generated]"
tools:
  - "*"
---
```
**And** original command content follows the frontmatter

### AC5: Copilot CLI MCP Config Generated with Correct Format
**Given** `agents/mcp/servers.json` contains server definitions
**When** MCP config is generated for Copilot CLI
**Then** `~/.copilot/mcp-config.json` contains:
```json
{
  "mcpServers": {
    "perplexity": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@perplexity-ai/mcp-server"],
      "tools": ["*"],
      "env": {...}
    },
    "flowspace": {
      "type": "local",
      "command": "fs2",
      "args": ["mcp"],
      "tools": ["*"]
    }
  }
}
```
**Note**: Key differences from other formats:
- Wrapper key is `mcpServers` (not `servers`)
- Each server has `tools: ["*"]` array
- Type `stdio` maps to `local`

### AC6: Idempotent Installation
**Given** a user runs `./setup.sh` twice
**When** comparing output directories
**Then** no duplicate files or entries exist
**And** second run reports `[✓ Idempotent]` status

### AC7: Local Installation Supports Copilot CLI
**Given** a user runs `uvx jk-tools --commands-local copilot-cli`
**When** installation completes
**Then** directory `./.copilot/agents/` exists in current directory
**And** contains agent files with YAML frontmatter
**And** no MCP configuration is modified (local = commands only)

### AC8: Existing Installations Preserved
**Given** user has existing `~/.copilot/mcp-config.json` with custom servers
**When** installer runs
**Then** existing server configurations are preserved
**And** new servers (flowspace, perplexity) are added/updated
**And** backup is created with timestamp

---

## Risks & Assumptions

### Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Copilot CLI config format changes | High | Monitor GitHub docs, version-pin if needed |
| YAML frontmatter parsing issues | Medium | Use robust YAML generation, test edge cases |
| FlowSpace installation fails | Medium | Make FlowSpace optional with clear error message |
| User has conflicting ~/.copilot/agents | Low | Backup before overwrite, document behavior |
| Type mapping `stdio`→`local` incorrect | Medium | Validate against working config samples |

### Assumptions

1. Users installing Copilot CLI support have Node.js 22+ installed
2. Users have `uv` tool available (common in Python dev environments)
3. Copilot CLI's `mcpServers` format is stable through public preview
4. Minimal YAML frontmatter (`name`, `description`, `tools`) is sufficient
5. `fs2 mcp` works without additional configuration when fs2 is installed

---

## Open Questions

1. **[NEEDS CLARIFICATION: Agent Description Extraction]** - How should we generate the `description` field for agent YAML frontmatter? Options:
   - Extract from first markdown heading
   - Extract from first paragraph
   - Use filename as description
   - Hardcode generic descriptions

2. **[NEEDS CLARIFICATION: FlowSpace Required vs Optional]** - Should FlowSpace installation be:
   - Required (fail if not installable)
   - Optional with warning
   - Optional and silent

3. **[NEEDS CLARIFICATION: Copilot CLI Detection]** - Should we:
   - Always create `~/.copilot/` directories
   - Only create if `copilot` command exists
   - Ask user preference

4. **[NEEDS CLARIFICATION: MCP Server Merge Strategy]** - When user has existing `~/.copilot/mcp-config.json`:
   - Overwrite entire file (current approach for other CLIs)
   - Merge servers, preserving user additions
   - Backup and replace with option to restore

---

## ADR Seeds (Optional)

### ADR-001: Agent File Conversion Strategy

**Decision Drivers:**
- Copilot CLI requires YAML frontmatter; existing commands are plain markdown
- Must work for all ~20 command files consistently
- Description field needed but not present in source files

**Candidate Alternatives:**
- A: Auto-extract description from first heading/paragraph
- B: Use filename-based generic descriptions
- C: Maintain separate metadata file mapping commands to descriptions
- D: Add frontmatter to source files (breaking change for other CLIs)

**Stakeholders:** Repository maintainers, users of all supported CLIs

### ADR-002: FlowSpace as Cross-Agent MCP Server

**Decision Drivers:**
- FlowSpace provides codebase intelligence valuable to all agents
- Requires pre-installation step (`fs2 install`)
- Not all users may want/need FlowSpace

**Candidate Alternatives:**
- A: Required prerequisite (fail setup if not installable)
- B: Optional with prominent recommendation
- C: Separate installer script user can opt into
- D: Bundle FlowSpace config but don't auto-install binary

**Stakeholders:** All users, FlowSpace maintainers

---

## Configuration Format Reference

### Source Format (`agents/mcp/servers.json`)
```json
{
  "perplexity": {
    "type": "local",
    "enabled": true,
    "command": "npx",
    "args": ["-y", "@perplexity-ai/mcp-server"],
    "env": {...}
  }
}
```

### Target: Copilot CLI (`~/.copilot/mcp-config.json`)
```json
{
  "mcpServers": {
    "perplexity": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@perplexity-ai/mcp-server"],
      "tools": ["*"],
      "env": {...}
    }
  }
}
```

### Key Transformations
| Source | Copilot CLI Target |
|--------|-------------------|
| Root object | Wrap in `mcpServers` |
| `type: "stdio"` | `type: "local"` |
| `type: "local"` | `type: "local"` (unchanged) |
| `enabled: true` | Remove (not used) |
| (missing) | Add `tools: ["*"]` |

---

## Path Summary

| Target | Directory | File Format |
|--------|-----------|-------------|
| Copilot CLI Agents | `~/.copilot/agents/` | `*.md` with YAML frontmatter |
| Copilot CLI MCP | `~/.copilot/mcp-config.json` | JSON with `mcpServers` wrapper |
| Local Agents | `./.copilot/agents/` | Same as global |

---

**Spec Status**: Ready for clarification
**Created**: 2026-01-16
**Plan Directory**: `docs/plans/007-copilot-cli-support/`
