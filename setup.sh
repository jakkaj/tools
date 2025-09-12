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


install_tools() {
    local INSTALL_PATH="${SCRIPT_DIR}/install"
    
    echo ""
    print_status "Checking and installing required tools..."
    
    # Source cargo environment if it exists (for tools installed via cargo)
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
    
    # Check if install directory exists
    if [ ! -d "${INSTALL_PATH}" ]; then
        print_status "No install directory found, skipping tool installation"
        return
    fi
    
    # Make all install scripts executable
    chmod +x "${INSTALL_PATH}"/*.sh 2>/dev/null || true
    chmod +x "${INSTALL_PATH}"/*.py 2>/dev/null || true
    
    # Install tools in specific order (dependencies first)
    local install_order=("rust.sh" "code2prompt.sh" "claude.sh" "aliases.py")
    local installed_count=0
    local skipped_count=0
    
    for installer in "${install_order[@]}"; do
        if [ -f "${INSTALL_PATH}/${installer}" ]; then
            # Remove extension to get tool name
            local tool_name="${installer%.*}"
            echo ""
            print_status "Checking ${tool_name}..."
            
            # Run the installer - it will check if already installed
            if "${INSTALL_PATH}/${installer}"; then
                ((installed_count++))
            else
                print_error "Failed to install ${tool_name}"
            fi
        fi
    done
    
    # Install any other tools not in the specific order
    for installer in "${INSTALL_PATH}"/*.sh "${INSTALL_PATH}"/*.py; do
        if [ -f "${installer}" ]; then
            local basename=$(basename "${installer}")
            
            # Skip if already processed in order
            if [[ " ${install_order[@]} " =~ " ${basename} " ]]; then
                continue
            fi
            
            # Remove extension to get tool name
            local tool_name="${basename%.*}"
            echo ""
            print_status "Checking ${tool_name}..."
            
            if "${installer}"; then
                ((installed_count++))
            else
                print_error "Failed to install ${tool_name}"
            fi
        fi
    done
    
    echo ""
    if [ ${installed_count} -gt 0 ] || [ ${skipped_count} -gt 0 ]; then
        print_success "Tool installation check complete"
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
    
    install_tools
    
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