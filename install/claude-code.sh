#!/usr/bin/env bash

# Install Claude Code CLI via npm
# Works on macOS and Linux

# set -e  # Disabled to allow proper error handling in main function

CLAUDE_UPDATE_REQUESTED=0

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

check_and_remove_brew_install() {
    # Check if Claude was installed via Homebrew and remove it
    if command -v brew >/dev/null 2>&1 && brew list --versions claude-code >/dev/null 2>&1; then
        print_status "Detected Homebrew installation of Claude Code"
        print_status "Removing Homebrew version to install via npm..."
        if brew uninstall claude-code; then
            print_success "Removed Homebrew installation"
            return 0
        else
            print_error "Failed to remove Homebrew installation"
            return 1
        fi
    fi
    return 0
}

check_claude_code() {
    local update_flag="$1"
    local wants_update="$CLAUDE_UPDATE_REQUESTED"

    if [ "$update_flag" = "--update" ] || [ "$update_flag" = "-u" ]; then
        wants_update=1
    fi

    # Check for Homebrew installation and remove it
    if ! check_and_remove_brew_install; then
        return 1
    fi

    if command -v claude >/dev/null 2>&1; then
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        print_success "Claude Code CLI is already installed (version: $version)"

        if [ "$wants_update" -eq 1 ]; then
            print_status "Updating to latest version..."
            return 1
        fi
        return 0
    fi

    if [ -x "$HOME/.claude/bin/claude" ]; then
        local version
        version=$("$HOME/.claude/bin/claude" --version 2>/dev/null || echo "unknown")
        print_success "Claude Code CLI is already installed at ~/.claude/bin (version: $version)"

        if [ "$wants_update" -eq 1 ]; then
            print_status "Updating to latest version..."
            return 1
        fi
        return 0
    fi

    return 1
}

install_claude_code() {
    print_status "Installing Claude Code CLI..."

    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm is required but not found. Please install Node.js/npm first."
        return 1
    fi

    print_status "Installing Claude Code via npm..."
    if npm install -g @anthropic-ai/claude-code; then
        print_success "Claude Code CLI installed via npm"
    else
        print_error "Claude Code CLI npm installation failed"
        return 1
    fi

    if [ -f "$HOME/.zshrc" ]; then
        # Reload environment to pick up new PATH entries
        source "$HOME/.zshrc" 2>/dev/null || true
    fi

    if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.claude/bin/claude" ]; then
        print_success "Claude Code CLI installation verified"
        print_status "Run 'claude login' to authenticate"
        return 0
    fi

    print_error "Claude Code CLI not found after installation"
    return 1
}

main() {
    print_status "Claude Code CLI Installation Script"

    for arg in "$@"; do
        if [ "$arg" = "--update" ] || [ "$arg" = "-u" ]; then
            CLAUDE_UPDATE_REQUESTED=1
            break
        fi
    done

    # Check if already installed and up to date (don't exit on update request)
    if check_claude_code "$@" 2>/dev/null; then
        # check_claude_code returned 0, meaning no update needed
        exit 0
    fi

    # Either not installed or update requested - proceed with installation
    if install_claude_code; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
