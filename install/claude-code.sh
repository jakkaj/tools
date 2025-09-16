#!/usr/bin/env bash

# Install Claude Code CLI
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

check_claude_code() {
    # Check in standard PATH
    if command -v claude >/dev/null 2>&1; then
        local version=$(claude --version 2>/dev/null || echo "unknown")
        print_success "Claude Code CLI is already installed (version: $version)"

        # Check for update flag
        if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
            print_status "Updating to latest version..."
            return 1  # Force reinstall
        fi
        return 0
    fi

    # Check in home directory installation
    if [ -x "$HOME/.claude/bin/claude" ]; then
        local version=$("$HOME/.claude/bin/claude" --version 2>/dev/null || echo "unknown")
        print_success "Claude Code CLI is already installed at ~/.claude/bin (version: $version)"

        # Check for update flag
        if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
            print_status "Updating to latest version..."
            return 1  # Force reinstall
        fi
        return 0
    fi

    return 1
}

install_claude_code() {
    print_status "Installing Claude Code CLI..."

    # Try npm first (most reliable)
    if command -v npm >/dev/null 2>&1; then
        print_status "Installing Claude Code via npm..."
        if npm install -g @anthropic-ai/claude-code; then
            print_success "Claude Code CLI installed via npm"
        else
            print_error "Claude Code CLI npm installation failed"
            return 1
        fi
    elif command -v brew >/dev/null 2>&1; then
        print_status "Installing Claude Code via Homebrew..."
        if brew install claude-code; then
            print_success "Claude Code CLI installed via Homebrew"
        else
            print_error "Claude Code CLI Homebrew installation failed"
            return 1
        fi
    else
        # Try curl installer as fallback
        print_status "Trying official installer..."
        if curl -fsSL https://claude.ai/install.sh 2>/dev/null | bash; then
            print_success "Claude Code CLI installed via official installer"
        else
            print_error "Could not install Claude Code CLI. Please install Node.js/npm first."
            return 1
        fi
    fi

    # Source .zshrc to get updated PATH
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi

    # Verify installation
    if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.claude/bin/claude" ]; then
        print_success "Claude Code CLI installation verified"
        print_status "Run 'claude login' to authenticate"
        return 0
    else
        print_error "Claude Code CLI not found after installation"
        return 1
    fi
}

main() {
    print_status "Claude Code CLI Installation Script"

    # Check if already installed
    if check_claude_code "$@"; then
        exit 0
    fi

    # Install Claude Code
    if install_claude_code; then
        exit 0
    else
        exit 1
    fi
}

main "$@"