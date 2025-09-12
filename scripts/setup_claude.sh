#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
SOURCE_DIR="${REPO_ROOT}/.claude/commands"
TARGET_DIR="${HOME}/.claude/commands"

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
    echo "     Claude Commands Setup Script     "
    echo "======================================"
    echo ""
    
    # Check if source directory exists
    if [ ! -d "${SOURCE_DIR}" ]; then
        print_error "Source directory not found: ${SOURCE_DIR}"
        exit 1
    fi
    
    # Create target directory if it doesn't exist
    if [ ! -d "${TARGET_DIR}" ]; then
        mkdir -p "${TARGET_DIR}"
        print_success "Created directory: ${TARGET_DIR}"
    else
        print_status "Target directory already exists: ${TARGET_DIR}"
    fi
    
    # Count files to copy
    file_count=$(find "${SOURCE_DIR}" -maxdepth 1 -name "*.md" -type f | wc -l | tr -d ' ')
    
    if [ "${file_count}" -eq 0 ]; then
        print_error "No .md files found in ${SOURCE_DIR}"
        exit 1
    fi
    
    print_status "Found ${file_count} command file(s) to copy"
    echo ""
    
    # Copy each file with status
    copied=0
    updated=0
    unchanged=0
    
    for file in "${SOURCE_DIR}"/*.md; do
        if [ -f "${file}" ]; then
            filename=$(basename "${file}")
            target_file="${TARGET_DIR}/${filename}"
            
            # Check if file exists and compare
            if [ -f "${target_file}" ]; then
                if cmp -s "${file}" "${target_file}"; then
                    echo "  [-] ${filename} (unchanged)"
                    ((unchanged++))
                else
                    cp "${file}" "${target_file}"
                    echo "  [↻] ${filename} (updated)"
                    ((updated++))
                fi
            else
                cp "${file}" "${target_file}"
                echo "  [+] ${filename} (new)"
                ((copied++))
            fi
        fi
    done
    
    echo ""
    echo "======================================"
    print_success "Setup complete!"
    echo ""
    echo "Summary:"
    echo "  • New files: ${copied}"
    echo "  • Updated files: ${updated}"
    echo "  • Unchanged files: ${unchanged}"
    echo "  • Total files: ${file_count}"
    echo ""
    echo "Claude commands are now available at:"
    echo "  ${TARGET_DIR}"
    echo "======================================"
}

main "$@"