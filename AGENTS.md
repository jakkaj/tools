# Tools Repository

A centralized collection of utility scripts and tools for consistent development environments across machines.

## Purpose

This repository serves as a single source of truth for commonly used tools, scripts, and utilities that enhance productivity across different development environments. It provides a quick and reliable way to set up these tools on any Linux or macOS machine (including Windows with WSL/Git Bash).

## Quick Setup

```bash
git clone <repository-url> ~/github/tools
cd ~/github/tools
./setup.sh
source ~/.zshrc
```

## What It Does

- **Centralized Tool Management**: Keep all your custom scripts and tools in one version-controlled location
- **Cross-Platform Support**: Works seamlessly on Linux, macOS, and Windows (WSL/Git Bash)
- **Instant Availability**: Automatically adds tools to your PATH for immediate use
- **Idempotent Setup**: Safe to run the setup script multiple times without side effects
- **Portable Configuration**: Easy to clone and set up on new machines or environments

## Repository Structure

```
tools/
├── setup.sh           # Main setup script - configures PATH and permissions
├── scripts/           # Directory for executable tools and utilities
├── AGENTS.md          # This file
└── LICENSE            # Repository license
```

## Adding New Tools

1. Place your script or tool in the `scripts/` directory
2. Run `./setup.sh` to ensure proper permissions
3. The tool is immediately available in your PATH
4. Commit and push to share across your machines

## Benefits

- **Consistency**: Same tools available on all your development machines
- **Version Control**: Track changes and improvements to your tools over time
- **Quick Onboarding**: Set up a new machine with all your tools in seconds
- **No Manual PATH Management**: Automatic PATH configuration for all tools
- **Clean Separation**: Keeps custom tools separate from system utilities

## Usage

After setup, any script in the `scripts/` directory can be called directly from anywhere in your terminal without specifying the full path.

Example:
```bash
# Instead of: ~/github/tools/scripts/my-tool.sh
# You can use: my-tool.sh
```

## Maintenance

- Pull latest changes: `git pull`
- Add new tools: Copy to `scripts/` and run `./setup.sh`
- Update existing tools: Edit in place and commit changes
- Share across machines: Push to remote and pull on other machines