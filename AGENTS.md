# Tools Repository

A centralized collection of utility scripts and tools for consistent development environments across machines.

## Platform Support

- **macOS** (Intel and Apple Silicon)
- **Linux** (Ubuntu, Debian, Fedora, Arch, and other major distributions)
- **Windows** (via WSL or Git Bash)

## Purpose

This repository serves as a single source of truth for commonly used tools, scripts, and utilities that enhance productivity across different development environments. It provides a quick and reliable way to set up these tools on any supported platform with automatic installation of required dependencies.

## Quick Setup

```bash
git clone <repository-url> ~/github/tools
cd ~/github/tools
./setup.sh
source ~/.zshrc
```

## What It Does

- **Centralized Tool Management**: Keep all your custom scripts and tools in one version-controlled location
- **Automatic Tool Installation**: Installs required tools (Rust, code2prompt, etc.) automatically
- **Cross-Platform Support**: Works seamlessly on Linux, macOS, and Windows (WSL/Git Bash)
- **Instant Availability**: Automatically adds tools to your PATH for immediate use
- **Idempotent Setup**: Safe to run the setup script multiple times without side effects
- **Portable Configuration**: Easy to clone and set up on new machines or environments

## Repository Structure

```
tools/
├── setup.sh           # Main setup script - PATH, permissions, and tool installation
├── scripts/           # Executable tools and utilities
├── install/           # Tool installation scripts (one per tool)
│   ├── rust.sh        # Installs Rust and Cargo via rustup
│   ├── code2prompt.sh # Installs code2prompt via cargo
│   └── agents.sh      # Copies agent commands to ~/.claude/commands, ~/.config/opencode/command, and ~/.codex/prompts
├── agents/            # AI agent command configurations (Claude, OpenCode, Codex)
├── scratch/           # Temporary workspace (gitignored)
├── AGENTS.md          # This file - documentation
└── LICENSE            # Repository license
```

## Tool Installation

The setup script automatically checks for and installs required tools. Each tool has its own installation script in the `install/` directory.

### Currently Automated Tools

- **Rust & Cargo**: The Rust programming language and package manager
- **code2prompt**: CLI tool to convert codebases into LLM prompts
- **Agent Commands**: Custom commands for Claude, OpenCode, and Codex AI assistants

### Adding New Tools

To add a new tool to the repository:

1. **For scripts/utilities**: Place in `scripts/` directory
2. **For tools requiring installation**: Create an install script in `install/` directory
   - Name it `install/<toolname>.sh`
   - Follow the pattern of existing install scripts
   - Check if installed → Install if needed → Verify installation
3. Run `./setup.sh` to apply changes
4. Commit and push to share across your machines

### Tool Development Guidelines

When creating new tools, follow these conventions:

1. **Help System**:
   - Must support `--help` flag for detailed documentation
   - Should show help when called with no parameters (if safe to do so)
   - Include: NAME, SYNOPSIS, DESCRIPTION, PARAMETERS, OPTIONS, EXAMPLES
   - Format for both human and AI readability

2. **Naming**:
   - Use descriptive names with dashes (e.g., `analyze-dependencies.sh`)
   - Aliases will be auto-generated with `jk-` prefix

3. **Documentation**:
   - Include purpose and use cases
   - Provide real-world examples
   - List dependencies and requirements
   - Specify expected output format

4. **Integration**:
   - Make tools composable with Unix pipes
   - Use exit codes appropriately (0 for success, non-zero for errors)
   - Support common flags like `--help`, `--version`, `--verbose`

## Benefits

- **Consistency**: Same tools available on all your development machines
- **Version Control**: Track changes and improvements to your tools over time
- **Quick Onboarding**: Set up a new machine with all your tools in seconds
- **No Manual PATH Management**: Automatic PATH configuration for all tools
- **Clean Separation**: Keeps custom tools separate from system utilities

## Usage

After setup, any script in the `scripts/` directory can be called directly from anywhere in your terminal without specifying the full path.

### Discovering Available Tools

To see all available tools and their descriptions:
```bash
jk-tools        # List all tools with descriptions
jk-jt           # Short alias for jk-tools
jk-tools -v     # Verbose mode with full help text
```

### Getting Help

All tools follow a consistent help convention:
```bash
<tool-name> --help    # Get detailed help for any tool
jk-gcm --help         # Example: help for generate-codebase-md
```

### Tool Aliases

Tools with dashes in their names automatically get `jk-` prefixed aliases:
- `generate-codebase-md.sh` → `jk-gcm`
- `jk-tools.sh` → `jk-jt`
- Future tools follow the same pattern

### For AI Assistants / LLMs

When working with this repository, AI assistants should:

1. **Discover available tools**: Run `jk-tools` to see all available utilities
2. **Understand tool purpose**: Each tool has comprehensive help via `--help`
3. **Use aliases**: Prefer short aliases (e.g., `jk-gcm`) for efficiency
4. **Check requirements**: Tools list their dependencies in help text
5. **Use scratch directory**: Output temporary files to `./scratch/` to keep repo clean

Example workflow for an AI assistant:
```bash
# 1. Discover what tools are available
jk-tools

# 2. Get detailed help for a specific tool
jk-gcm --help

# 3. Use the tool with appropriate parameters
jk-gcm ./scratch/analysis ./src

# 4. Process the generated markdown
cat ./scratch/analysis/codebase.md
```

## Maintenance

- Pull latest changes: `git pull`
- Add new tools: Copy to `scripts/` and run `./setup.sh`
- Update existing tools: Edit in place and commit changes
- Share across machines: Push to remote and pull on other machines

## Scratch Directory (Ephemeral Workspace)

Use a top-level `scratch/` directory in this repository for temporary experiments, throwaway scripts, notes, or generated files you do **not** want tracked by Git.

### Why
- Keeps the repo clean of WIP and exploratory artifacts
- Avoids accidental commits of large or sensitive temporary files
- Provides an easy, predictable location for ad-hoc work

### Usage
```bash
mkdir -p scratch
cd scratch
# Create or copy experimental files here
```

You can freely create, modify, and delete anything inside `scratch/` without impacting version control. The path is ignored via `.gitignore`.

### Guidelines
- Never store the only copy of important work here—it's untracked
- Safe to wipe/recreate at any time
- Use subfolders if juggling multiple experiments
- If something becomes valuable, move it into a tracked location (e.g. `scripts/`) before committing

### Automation Tip
Add helpers or prototypes here first; once stable, promote them into `scripts/` and run `./setup.sh`.