#!/usr/bin/env bash

# Sync Source Files to Distribution Package
#
# This script synchronizes all development source files from the root directories
# to their distribution package locations in src/jk_tools/.
#
# IMPORTANT: The source/distribution paradigm:
#   - ROOT directories (agents/, scripts/, install/, etc.) are the SOURCE OF TRUTH
#   - src/jk_tools/ is the DISTRIBUTION COPY for packaging
#   - Developers should ONLY edit root files, NEVER src/jk_tools/ directly
#   - This script ensures distribution always matches source
#
# Called by: setup.sh (automatically) or manually for development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_ROOT="${REPO_ROOT}/src/jk_tools"

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

main() {
    echo "======================================"
    echo "  Source → Distribution Sync Script   "
    echo "======================================"
    echo ""

    print_status "Repository root: ${REPO_ROOT}"
    print_status "Distribution root: ${DIST_ROOT}"
    echo ""

    # Ensure distribution directories exist
    mkdir -p "${DIST_ROOT}/agents/commands"
    mkdir -p "${DIST_ROOT}/agents/mcp"
    mkdir -p "${DIST_ROOT}/scripts"
    mkdir -p "${DIST_ROOT}/install"
    mkdir -p "${DIST_ROOT}/.vscode"

    # 1. Sync agents/commands (all .md files)
    print_status "Syncing agents/commands/*.md..."
    rsync -av --delete \
        --include="*.md" \
        --exclude="*" \
        "${REPO_ROOT}/agents/commands/" \
        "${DIST_ROOT}/agents/commands/"
    count=$(find "${DIST_ROOT}/agents/commands" -name "*.md" -type f | wc -l | tr -d ' ')
    print_success "Synced ${count} command files"

    # 2. Sync agents/mcp
    print_status "Syncing agents/mcp/..."
    rsync -av --delete \
        "${REPO_ROOT}/agents/mcp/" \
        "${DIST_ROOT}/agents/mcp/"
    print_success "Synced MCP configuration"

    # 3. Sync agents/settings.local.json
    print_status "Syncing agents/settings.local.json..."
    cp "${REPO_ROOT}/agents/settings.local.json" "${DIST_ROOT}/agents/settings.local.json"
    print_success "Synced settings file"

    # 4. Sync scripts (all files)
    print_status "Syncing scripts/..."
    rsync -av --delete \
        "${REPO_ROOT}/scripts/" \
        "${DIST_ROOT}/scripts/"
    count=$(find "${DIST_ROOT}/scripts" -type f | wc -l | tr -d ' ')
    print_success "Synced ${count} script files"

    # 5. Sync install (all files)
    print_status "Syncing install/..."
    rsync -av --delete \
        "${REPO_ROOT}/install/" \
        "${DIST_ROOT}/install/"
    count=$(find "${DIST_ROOT}/install" -type f | wc -l | tr -d ' ')
    print_success "Synced ${count} install files"

    # 6. Sync setup_manager.py
    print_status "Syncing setup_manager.py..."
    cp "${REPO_ROOT}/setup_manager.py" "${DIST_ROOT}/setup_manager.py"
    print_success "Synced setup manager"

    # 7. Sync .vscode planning commands only (exclude project-specific files)
    print_status "Syncing .vscode planning commands..."
    rsync -av \
        --include="plan-*.md" \
        --include="tad.md" \
        --include="didyouknow.md" \
        --include="deepresearch.md" \
        --include="substrateresearch.md" \
        --exclude="*" \
        "${REPO_ROOT}/.vscode/" \
        "${DIST_ROOT}/.vscode/"
    count=$(find "${DIST_ROOT}/.vscode" -name "*.md" -type f | wc -l | tr -d ' ')
    print_success "Synced ${count} VS Code command files"

    echo ""
    echo "======================================"
    print_success "Sync complete!"
    echo ""
    echo "All source files have been synced to distribution package."
    echo "Distribution location: ${DIST_ROOT}"
    echo "======================================"
}

main "$@"
