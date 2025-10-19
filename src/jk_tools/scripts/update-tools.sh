#!/usr/bin/env bash
# NAME
#   jk-update-tools - Update jk-tools to latest version from GitHub
#
# SYNOPSIS
#   jk-update-tools
#   jk-update-tools --help
#
# DESCRIPTION
#   Updates the jk-tools package to the latest version from GitHub using uvx.
#   This pulls the latest code and reinstalls all commands and configurations.
#
#   Equivalent to running:
#     uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --update
#
# OPTIONS
#   --help, -h
#       Display this help message and exit
#
# EXAMPLES
#   # Update to latest version
#   jk-update-tools
#
#   # Show help
#   jk-update-tools --help
#
# EXIT STATUS
#   0   Success
#   1   Update failed
#
# NOTES
#   - Requires uvx to be installed (part of uv package manager)
#   - Updates commands in ~/.claude/commands, ~/.config/opencode/command, etc.
#   - Updates MCP configurations in ~/.claude.json and VS Code
#   - Preserves existing settings and configurations
#   - Safe to run multiple times

set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

show_help() {
    sed -n '/^# NAME/,/^$/p' "$0" | sed 's/^# \?//'
    exit 0
}

# Parse arguments
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  JK Tools Updater${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if uvx is available
if ! command -v uvx &> /dev/null; then
    echo -e "${RED}Error: uvx is not installed${NC}"
    echo ""
    echo "Please install uv package manager first:"
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo ""
    exit 1
fi

echo -e "${YELLOW}[*] Updating jk-tools from GitHub...${NC}"
echo ""

# Run the update command
if uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --update; then
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}[✓] Update complete!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo "All tools have been updated to the latest version."
    echo "Changes include:"
    echo "  - Agent commands (Claude, OpenCode, Codex, Copilot)"
    echo "  - MCP server configurations"
    echo "  - Installation scripts"
    echo ""
else
    echo ""
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}[✗] Update failed${NC}"
    echo -e "${RED}======================================${NC}"
    echo ""
    echo "The update command encountered an error."
    echo "Please check the output above for details."
    echo ""
    exit 1
fi
