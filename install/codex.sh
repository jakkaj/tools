#!/usr/bin/env bash

# Install OpenAI Codex CLI
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

check_codex() {
    # Check in standard PATH
    if command -v codex >/dev/null 2>&1; then
        local version=$(codex --version 2>/dev/null || echo "unknown")
        print_success "Codex CLI is already installed (version: $version)"

        # Check for update flag
        if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
            print_status "Updating to latest version..."
            return 1  # Force reinstall
        fi
        return 0
    fi

    # Check in home directory installation
    if [ -x "$HOME/.codex/bin/codex" ]; then
        local version=$("$HOME/.codex/bin/codex" --version 2>/dev/null || echo "unknown")
        print_success "Codex CLI is already installed at ~/.codex/bin (version: $version)"

        # Check for update flag
        if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
            print_status "Updating to latest version..."
            return 1  # Force reinstall
        fi
        return 0
    fi

    return 1
}

install_codex() {
    print_status "Installing Codex CLI..."

    # Try npm first
    if command -v npm >/dev/null 2>&1; then
        print_status "Installing Codex via npm..."
        # Try the most common package names for Codex CLI
        if npm install -g @openai/codex-cli 2>/dev/null; then
            print_success "Codex CLI installed via npm"
        elif npm install -g openai-codex 2>/dev/null; then
            print_success "Codex CLI installed via npm"
        elif npm install -g codex-cli 2>/dev/null; then
            print_success "Codex CLI installed via npm"
        else
            print_status "npm installation failed, trying alternative methods..."

            # Try pip if available (some Codex tools are Python-based)
            if command -v pip3 >/dev/null 2>&1; then
                print_status "Trying pip installation..."
                if pip3 install --user openai-codex 2>/dev/null; then
                    print_success "Codex CLI installed via pip"
                    return 0
                fi
            fi

            print_error "Codex CLI npm installation failed"
            return 1
        fi
    elif command -v brew >/dev/null 2>&1; then
        print_status "Installing Codex via Homebrew..."
        if brew install codex; then
            print_success "Codex CLI installed via Homebrew"
        else
            print_error "Codex CLI Homebrew installation failed"
            return 1
        fi
    else
        print_error "Could not install Codex CLI. Please install Node.js/npm first."
        return 1
    fi

    # Source .zshrc to get updated PATH
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi

    # Verify installation
    if command -v codex >/dev/null 2>&1 || [ -x "$HOME/.codex/bin/codex" ]; then
        print_success "Codex CLI installation verified"
        print_status "Run 'codex' to start and authenticate with ChatGPT plan or API key"
        return 0
    else
        print_error "Codex CLI not found after installation"
        return 1
    fi
}

main() {
    print_status "OpenAI Codex CLI Installation Script"

    # Check if already installed
    if check_codex "$@"; then
        exit 0
    fi

    # Install Codex
    if install_codex; then
        exit 0
    else
        exit 1
    fi
}

main "$@"