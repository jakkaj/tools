# JK Tools

Centralized setup and utility scripts for developer tooling across macOS, Linux, and Windows (WSL/Git Bash).

## Quick Start

### Modern Approach (uvx - Recommended)

Run directly from GitHub without cloning:

```bash
uvx --from git+https://github.com/yourusername/tools jk-tools-setup
```

Or from a local clone:

```bash
./setup.sh
```

If you have `uvx` installed, it will automatically use the modern execution mode.

### Traditional Approach (pip)

```bash
git clone https://github.com/yourusername/tools.git
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
