#!/usr/bin/env bash

# Install GitHub Copilot CLI
# https://npm.im/@github/copilot
#
# Usage: copilot-cli.sh [OPTIONS]
#   --update, -u    Update to latest version

# set -e  # Disabled to allow proper error handling

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

print_status() {
    echo "[*] $1"
}

print_success() {
    echo -e "${GREEN}[✓]${RESET} $1"
}

print_error() {
    echo -e "${RED}[✗]${RESET} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[!]${RESET} $1"
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

get_version() {
    if check_command copilot; then
        copilot --version 2>/dev/null | head -1 || echo "unknown"
    else
        echo "not installed"
    fi
}

check_copilot() {
    if check_command copilot; then
        local version=$(get_version)
        print_success "GitHub Copilot CLI is already installed (version: $version)"
        return 0
    fi
    return 1
}

install_copilot() {
    print_status "Installing GitHub Copilot CLI..."

    # Check for npm
    if ! check_command npm; then
        print_error "npm is required but not found. Please install Node.js first."
        return 1
    fi

    # Use user-local install to avoid permission issues
    local npm_prefix="$HOME/.npm-global"
    mkdir -p "$npm_prefix"
    npm config set prefix "$npm_prefix"
    export PATH="$npm_prefix/bin:$PATH"

    print_status "Installing @github/copilot@prerelease via npm..."
    if npm install -g @github/copilot@prerelease >/dev/null 2>&1; then
        print_success "GitHub Copilot CLI installed via npm to $npm_prefix"

        # Add to shell config if not already there
        if [ -f "$HOME/.zshrc" ] && ! grep -q ".npm-global/bin" "$HOME/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.zshrc"
            print_status "Added ~/.npm-global/bin to PATH in .zshrc"
        elif [ -f "$HOME/.bashrc" ] && ! grep -q ".npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
            print_status "Added ~/.npm-global/bin to PATH in .bashrc"
        fi
    else
        print_error "GitHub Copilot CLI installation failed"
        return 1
    fi

    # Verify installation
    if check_command copilot || [ -x "$npm_prefix/bin/copilot" ]; then
        print_success "GitHub Copilot CLI installation verified"
        print_status "Run 'copilot auth' to authenticate with GitHub"
    else
        print_error "GitHub Copilot CLI not found after installation"
        return 1
    fi
}

main() {
    local UPDATE_MODE=false

    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --update|-u)
                UPDATE_MODE=true
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --update, -u    Update to latest version"
                echo "  --help, -h      Show this help message"
                exit 0
                ;;
        esac
    done

    echo "======================================"
    echo "  GitHub Copilot CLI Installation"
    echo "======================================"
    echo ""

    if [ "$UPDATE_MODE" = true ]; then
        print_status "Update mode: will reinstall to get latest version"
        install_copilot
    else
        if ! check_copilot; then
            install_copilot
        fi
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
