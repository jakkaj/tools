#!/usr/bin/env bash

# Install OpenCode - Terminal coding agent
# Works on macOS and Linux

set -e

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

check_opencode() {
    # Check in standard PATH
    if command -v opencode >/dev/null 2>&1; then
        local version=$(opencode --version 2>/dev/null || echo "unknown")
        print_success "OpenCode is already installed (version: $version)"

        # Check for update flag
        if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
            print_status "Updating to latest version..."
            return 1  # Force reinstall
        fi
        return 0
    fi

    # Check in home directory installation
    if [ -x "$HOME/.opencode/bin/opencode" ]; then
        local version=$("$HOME/.opencode/bin/opencode" --version 2>/dev/null || echo "unknown")
        print_success "OpenCode is already installed at ~/.opencode/bin (version: $version)"

        # Check for update flag
        if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
            print_status "Updating to latest version..."
            return 1  # Force reinstall
        fi
        return 0
    fi

    return 1
}

install_opencode() {
    print_status "Installing OpenCode..."

    # Try curl installer first (recommended)
    if curl -fsSL https://opencode.ai/install 2>/dev/null | bash; then
        print_success "OpenCode installed via official installer"
    elif command -v npm >/dev/null 2>&1; then
        print_status "Installer failed, trying npm..."
        if npm install -g opencode-ai; then
            print_success "OpenCode installed via npm"
        else
            print_error "OpenCode installation via npm failed"
            return 1
        fi
    elif command -v brew >/dev/null 2>&1; then
        print_status "Trying Homebrew installation..."
        if brew install sst/tap/opencode; then
            print_success "OpenCode installed via Homebrew"
        else
            print_error "OpenCode installation via Homebrew failed"
            return 1
        fi
    else
        print_error "Could not install OpenCode. Please install Node.js/npm first."
        return 1
    fi

    # Source .zshrc to get updated PATH if opencode was installed
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi

    # Verify installation
    if command -v opencode >/dev/null 2>&1 || [ -x "$HOME/.opencode/bin/opencode" ]; then
        print_success "OpenCode installation verified"
        print_status "Run 'opencode auth login' to authenticate"
        return 0
    else
        print_error "OpenCode not found after installation"
        return 1
    fi
}

main() {
    print_status "OpenCode Installation Script"

    # Check if already installed
    if check_opencode "$@"; then
        exit 0
    fi

    # Install OpenCode
    if install_opencode; then
        exit 0
    else
        exit 1
    fi
}

main "$@"