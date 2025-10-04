#!/usr/bin/env bash

# Install Claude Code CLI
# Works on macOS and Linux

# set -e  # Disabled to allow proper error handling in main function

# Track install method to pick the right upgrade path
CLAUDE_INSTALL_METHOD=""
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

check_claude_code() {
    local update_flag="$1"
    local wants_update="$CLAUDE_UPDATE_REQUESTED"

    if [ "$update_flag" = "--update" ] || [ "$update_flag" = "-u" ]; then
        wants_update=1
    fi

    if command -v claude >/dev/null 2>&1; then
        local claude_path
        claude_path=$(command -v claude)
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")

        if command -v brew >/dev/null 2>&1 && brew list --versions claude-code >/dev/null 2>&1; then
            CLAUDE_INSTALL_METHOD="brew"
        elif [ "$claude_path" = "$HOME/.claude/bin/claude" ]; then
            CLAUDE_INSTALL_METHOD="official"
        else
            CLAUDE_INSTALL_METHOD="npm"
        fi

        print_success "Claude Code CLI is already installed (version: $version)"

        if [ "$wants_update" -eq 1 ]; then
            if [ "$CLAUDE_INSTALL_METHOD" = "brew" ]; then
                print_status "Homebrew installation detected; updating via brew..."
            else
                print_status "Updating to latest version..."
            fi
            return 1
        fi
        return 0
    fi

    if [ -x "$HOME/.claude/bin/claude" ]; then
        CLAUDE_INSTALL_METHOD="official"
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

    local installed=0
    local wants_update="$CLAUDE_UPDATE_REQUESTED"

    if [ "$CLAUDE_INSTALL_METHOD" = "brew" ] && command -v brew >/dev/null 2>&1; then
        if brew list --versions claude-code >/dev/null 2>&1; then
            if [ "$wants_update" -eq 1 ]; then
                print_status "Updating Claude Code via Homebrew..."
                if brew upgrade claude-code; then
                    print_success "Claude Code CLI upgraded via Homebrew"
                    installed=1
                elif brew reinstall claude-code; then
                    print_success "Claude Code CLI reinstalled via Homebrew"
                    installed=1
                else
                    print_error "Claude Code CLI Homebrew upgrade failed"
                    return 1
                fi
            else
                print_status "Reinstalling Claude Code via Homebrew..."
                if brew reinstall claude-code; then
                    print_success "Claude Code CLI reinstalled via Homebrew"
                    installed=1
                elif brew install claude-code; then
                    print_success "Claude Code CLI installed via Homebrew"
                    installed=1
                else
                    print_error "Claude Code CLI Homebrew reinstall failed"
                    return 1
                fi
            fi
        else
            print_status "Installing Claude Code via Homebrew..."
            if brew install claude-code; then
                print_success "Claude Code CLI installed via Homebrew"
                installed=1
            else
                print_error "Claude Code CLI Homebrew installation failed"
                return 1
            fi
        fi
    fi

    if [ "$installed" -eq 0 ]; then
        if command -v npm >/dev/null 2>&1; then
            print_status "Installing Claude Code via npm..."
            if npm install -g @anthropic-ai/claude-code; then
                print_success "Claude Code CLI installed via npm"
                CLAUDE_INSTALL_METHOD="npm"
                installed=1
            else
                print_error "Claude Code CLI npm installation failed"
                return 1
            fi
        elif command -v brew >/dev/null 2>&1; then
            print_status "Installing Claude Code via Homebrew..."
            if brew install claude-code; then
                print_success "Claude Code CLI installed via Homebrew"
                CLAUDE_INSTALL_METHOD="brew"
                installed=1
            else
                print_error "Claude Code CLI Homebrew installation failed"
                return 1
            fi
        else
            print_status "Trying official installer..."
            if curl -fsSL https://claude.ai/install.sh 2>/dev/null | bash; then
                print_success "Claude Code CLI installed via official installer"
                CLAUDE_INSTALL_METHOD="official"
                installed=1
            else
                print_error "Could not install Claude Code CLI. Please install Node.js/npm first."
                return 1
            fi
        fi
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
