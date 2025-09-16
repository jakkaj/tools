#!/usr/bin/env bash

# Install agent commands by copying them to ~/.claude/commands, ~/.config/opencode/command, and ~/.codex/prompts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
SOURCE_DIR="${REPO_ROOT}/agents/commands"
TARGET_DIR="${HOME}/.claude/commands"
OPENCODE_DIR="${HOME}/.config/opencode/command"
CODEX_DIR="${HOME}/.codex/prompts"

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
    echo "     Agent Commands Setup Script      "
    echo "======================================"
    echo ""
    
    # Check if source directory exists
    if [ ! -d "${SOURCE_DIR}" ]; then
        print_error "Source directory not found: ${SOURCE_DIR}"
        exit 1
    fi
    
    # Create target directories if they don't exist
    if [ ! -d "${TARGET_DIR}" ]; then
        mkdir -p "${TARGET_DIR}"
        print_success "Created directory: ${TARGET_DIR}"
    else
        print_status "Target directory already exists: ${TARGET_DIR}"
    fi

    if [ ! -d "${OPENCODE_DIR}" ]; then
        mkdir -p "${OPENCODE_DIR}"
        print_success "Created directory: ${OPENCODE_DIR}"
    else
        print_status "OpenCode directory already exists: ${OPENCODE_DIR}"
    fi

    if [ ! -d "${CODEX_DIR}" ]; then
        mkdir -p "${CODEX_DIR}"
        print_success "Created directory: ${CODEX_DIR}"
    else
        print_status "Codex directory already exists: ${CODEX_DIR}"
    fi
    
    # Count files to copy
    file_count=$(find "${SOURCE_DIR}" -maxdepth 1 -name "*.md" -type f | wc -l | tr -d ' ')

    if [ "${file_count}" -eq 0 ]; then
        print_error "No .md files found in ${SOURCE_DIR}"
        exit 1
    fi

    print_status "Found ${file_count} command file(s) to copy"
    echo ""
    
    for file in "${SOURCE_DIR}"/*.md; do
        if [ -f "${file}" ]; then
            filename=$(basename "${file}")
            target_file="${TARGET_DIR}/${filename}"
            opencode_file="${OPENCODE_DIR}/${filename}"
            codex_file="${CODEX_DIR}/${filename}"

            # Copy to all three directories
            cp "${file}" "${target_file}"
            cp "${file}" "${opencode_file}"
            cp "${file}" "${codex_file}"
            echo "  [↻] ${filename} (copied to all locations)"
        fi
    done
    
    echo ""
    echo "======================================"
    print_success "Setup complete!"
    echo ""
    echo "Copied ${file_count} agent command file(s) to:"
    echo "  ${TARGET_DIR}"
    echo "  ${OPENCODE_DIR}"
    echo "  ${CODEX_DIR}"
    echo "======================================"
}

main "$@"