# JK Tools

Centralized setup and utility scripts for developer tooling across macOS, Linux, and Windows (WSL/Git Bash).

## Quick Start

### Modern Approach (uvx - Recommended)

Run directly from GitHub without cloning:

```bash
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup
```

Or from a local clone:

```bash
./setup.sh
```

If you have `uvx` installed, it will automatically use the modern execution mode.

### Traditional Approach (pip)

```bash
git clone https://github.com/jakkaj/tools.git
cd tools
./setup.sh
```

## What It Does

- Installs and configures developer tools (Rust, Just, code2prompt, Claude Code, Codex, OpenCode, etc.)
- Sets up agent commands and MCP server configurations for AI assistants
- Creates convenient aliases for scripts
- Manages PATH and shell configuration

## Features

- **Automatic tool installation**: Rust, cargo tools, AI CLI clients
- **Agent command sync**: Deploys slash commands to Claude, OpenCode, Codex, and VS Code
- **MCP server configuration**: Automatically configures Model Context Protocol servers
- **Cross-platform**: Works on macOS, Linux, and Windows (WSL/Git Bash)
- **Idempotent**: Safe to run multiple times
- **Update mode**: `jk-tools-setup --update` to update existing tools
- **Local command installation**: Install commands to project directories for version control

## Installing Commands Locally

Install AI CLI commands to your project directory without full setup:

```bash
# Install GitHub Copilot commands from GitHub
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local ghcp

# Install Claude commands
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local claude

# Install multiple CLI commands at once
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local claude,ghcp,opencode

# Install to specific directory
uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local ghcp --local-dir ~/my-project

# Force reinstall to get latest version
uvx --force-reinstall --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local ghcp
```

**What gets installed:**
- ✅ Command/prompt files ONLY
- ❌ NO MCP server configuration
- ❌ NO global setup
- ❌ NO other tools installation

**Supported CLIs:**
- `claude` → `.claude/commands/` (auto-discovered by Claude Code)
- `opencode` → `.opencode/command/` (auto-discovered by OpenCode)
- `ghcp` → `.github/prompts/*.prompt.md` (attach manually in IDE)
- `codex` → Not supported (use global installation only)

See [CLAUDE.md](CLAUDE.md) for full documentation.

## Development

```bash
# Install in editable mode
uv venv
source .venv/bin/activate
uv pip install -e .

# Run the CLI
jk-tools-setup --dev-mode .
```

## License

MIT
