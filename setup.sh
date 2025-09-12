#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="${SCRIPT_DIR}/scripts"
SHELL_CONFIG="${HOME}/.zshrc"
PATH_MARKER="# Added by tools repository setup"

detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="macOS";;
        CYGWIN*|MINGW*|MSYS*) OS="Windows";;
        *)          OS="Unknown";;
    esac
}

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

check_prerequisites() {
    if [ ! -d "${SCRIPTS_PATH}" ]; then
        print_error "Scripts directory not found at ${SCRIPTS_PATH}"
        exit 1
    fi
}

add_to_path() {
    local path_export="export PATH=\"${SCRIPTS_PATH}:\$PATH\""
    
    if [ -f "${SHELL_CONFIG}" ]; then
        if grep -q "${SCRIPTS_PATH}" "${SHELL_CONFIG}" 2>/dev/null; then
            print_status "Scripts directory already in ${SHELL_CONFIG}"
        else
            echo "" >> "${SHELL_CONFIG}"
            echo "${PATH_MARKER}" >> "${SHELL_CONFIG}"
            echo "${path_export}" >> "${SHELL_CONFIG}"
            print_success "Added scripts directory to ${SHELL_CONFIG}"
        fi
    else
        echo "${PATH_MARKER}" > "${SHELL_CONFIG}"
        echo "${path_export}" >> "${SHELL_CONFIG}"
        print_success "Created ${SHELL_CONFIG} and added scripts directory"
    fi
    
    # Only add to PATH if not already present
    if [[ ":${PATH}:" != *":${SCRIPTS_PATH}:"* ]]; then
        export PATH="${SCRIPTS_PATH}:${PATH}"
        print_success "Scripts directory added to current shell PATH"
    else
        print_status "Scripts directory already in current shell PATH"
    fi
}

make_scripts_executable() {
    local script_count=0
    
    if [ -d "${SCRIPTS_PATH}" ]; then
        for script in "${SCRIPTS_PATH}"/*; do
            if [ -f "${script}" ]; then
                chmod +x "${script}"
                script_count=$((script_count + 1))
            fi
        done
        
        if [ ${script_count} -gt 0 ]; then
            print_success "Made ${script_count} script(s) executable"
        else
            print_status "No scripts found to make executable"
        fi
    fi
}

setup_claude_commands() {
    echo ""
    print_status "Setting up Claude commands..."
    
    # Check if setup_claude.sh exists
    if [ -f "${SCRIPTS_PATH}/setup_claude.sh" ]; then
        # Make sure it's executable
        chmod +x "${SCRIPTS_PATH}/setup_claude.sh"
        
        # Run the setup_claude.sh script
        if "${SCRIPTS_PATH}/setup_claude.sh"; then
            print_success "Claude commands setup completed"
        else
            print_error "Failed to setup Claude commands"
        fi
    else
        print_status "No Claude command setup script found, skipping"
    fi
}

main() {
    echo "======================================"
    echo "     Tools Repository Setup Script    "
    echo "======================================"
    echo ""
    
    detect_os
    print_status "Detected OS: ${OS}"
    print_status "Repository path: ${SCRIPT_DIR}"
    print_status "Scripts path: ${SCRIPTS_PATH}"
    echo ""
    
    check_prerequisites
    
    add_to_path
    
    make_scripts_executable
    
    setup_claude_commands
    
    echo ""
    echo "======================================"
    print_success "Setup complete!"
    echo ""
    echo "To use the changes in your current shell:"
    echo "  source ~/.zshrc"
    echo ""
    echo "Or simply open a new terminal window."
    echo "======================================"
}

main "$@"