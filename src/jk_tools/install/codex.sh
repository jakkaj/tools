#!/usr/bin/env bash

# Install OpenAI Codex CLI
# Works on macOS and Linux

# set -e  # Disabled to allow proper error handling and prevent killing parent process

CODEX_METHOD=""
CODEX_INSTALLED="no"
CODEX_UPDATE_REQUESTED="no"
CODEX_VERSION="unknown"
CODEX_BIN=""

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

detect_codex_method() {
    CODEX_METHOD="unknown"

    if command -v npm >/dev/null 2>&1; then
        if npm ls -g "@openai/codex" --depth=0 >/dev/null 2>&1; then
            CODEX_METHOD="npm:@openai/codex"
            return
        fi
    fi

    if command -v brew >/dev/null 2>&1 && brew list codex >/dev/null 2>&1; then
        CODEX_METHOD="brew:codex"
        return
    fi

    if command -v pip3 >/dev/null 2>&1 && pip3 show openai-codex >/dev/null 2>&1; then
        CODEX_METHOD="pip:openai-codex"
        return
    fi

    if [ -n "$CODEX_BIN" ]; then
        case "$CODEX_BIN" in
            "$HOME/.codex"* ) CODEX_METHOD="installer:home" ;;
        esac
    fi
}

check_codex() {
    if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
        CODEX_UPDATE_REQUESTED="yes"
    fi

    CODEX_INSTALLED="no"
    CODEX_BIN=""
    CODEX_VERSION="unknown"
    CODEX_METHOD="unknown"

    if command -v codex >/dev/null 2>&1; then
        CODEX_BIN=$(command -v codex)
    elif [ -x "$HOME/.codex/bin/codex" ]; then
        CODEX_BIN="$HOME/.codex/bin/codex"
    fi

    if [ -n "$CODEX_BIN" ]; then
        CODEX_VERSION=$($CODEX_BIN --version 2>/dev/null || echo "unknown")
        CODEX_INSTALLED="yes"
        detect_codex_method

        case "$CODEX_METHOD" in
            npm:*)
                print_success "Codex CLI (npm: ${CODEX_METHOD#npm:}) detected (version: $CODEX_VERSION)"
                ;;
            brew:*)
                print_success "Codex CLI (Homebrew) detected (version: $CODEX_VERSION)"
                ;;
            pip:*)
                print_success "Codex CLI (pip) detected (version: $CODEX_VERSION)"
                ;;
            installer:*)
                print_success "Codex CLI detected at $CODEX_BIN (version: $CODEX_VERSION)"
                ;;
            *)
                print_success "Codex CLI detected (version: $CODEX_VERSION)"
                ;;
        esac

        if [ "$CODEX_UPDATE_REQUESTED" = "no" ]; then
            CODEX_UPDATE_REQUESTED="auto"
        fi
    else
        CODEX_INSTALLED="no"
    fi

    if [ "$CODEX_UPDATE_REQUESTED" = "yes" ]; then
        print_status "Update requested; preparing to update Codex CLI..."
    elif [ "$CODEX_UPDATE_REQUESTED" = "auto" ]; then
        print_status "Refreshing Codex CLI to ensure latest version..."
    fi

    return 0
}

install_codex() {
    print_status "Installing Codex CLI..."

    # Try npm first
    if command -v npm >/dev/null 2>&1; then
        print_status "Installing Codex via npm..."

        # Use user-local install (no sudo needed)
        # This avoids permission issues in containers and restricted environments
        local npm_prefix="$HOME/.npm-global"
        mkdir -p "$npm_prefix"

        print_status "Setting npm prefix to $npm_prefix..."
        npm config set prefix "$npm_prefix"
        export PATH="$npm_prefix/bin:$PATH"

        # Install Codex CLI
        if npm install -g @openai/codex 2>/dev/null; then
            print_success "Codex CLI installed via npm to $npm_prefix"

            # Add to shell config if not already there
            if [ -f "$HOME/.zshrc" ] && ! grep -q ".npm-global/bin" "$HOME/.zshrc" 2>/dev/null; then
                echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.zshrc"
                print_status "Added ~/.npm-global/bin to PATH in .zshrc"
            elif [ -f "$HOME/.bashrc" ] && ! grep -q ".npm-global/bin" "$HOME/.bashrc" 2>/dev/null; then
                echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
                print_status "Added ~/.npm-global/bin to PATH in .bashrc"
            fi
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
    local npm_prefix="$HOME/.npm-global"
    if command -v codex >/dev/null 2>&1 || [ -x "$HOME/.codex/bin/codex" ] || [ -x "$npm_prefix/bin/codex" ]; then
        print_success "Codex CLI installation verified"
        print_status "Run 'codex' to start and authenticate with ChatGPT plan or API key"
        return 0
    else
        print_error "Codex CLI not found after installation"
        return 1
    fi
}

update_codex() {
    if [ "$CODEX_INSTALLED" != "yes" ]; then
        return 1
    fi

    if [ "$CODEX_UPDATE_REQUESTED" = "auto" ]; then
        print_status "Refreshing Codex CLI (method: $CODEX_METHOD)..."
    else
        print_status "Updating Codex CLI (method: $CODEX_METHOD)..."
    fi

    case "$CODEX_METHOD" in
        npm:*)
            local pkg=${CODEX_METHOD#npm:}
            if ! command -v npm >/dev/null 2>&1; then
                print_error "npm not found; cannot update Codex npm package"
                return 1
            fi
            if npm update -g "$pkg" 2>/dev/null; then
                print_success "Codex CLI updated via npm ($pkg)"
                return 0
            else
                print_error "npm update for $pkg failed"
                return 1
            fi
            ;;
        brew:*)
            if ! command -v brew >/dev/null 2>&1; then
                print_error "Homebrew not found; cannot update Codex"
                return 1
            fi
            if brew upgrade codex || brew reinstall codex; then
                print_success "Codex CLI updated via Homebrew"
                return 0
            else
                print_error "Homebrew update for Codex failed"
                return 1
            fi
            ;;
        pip:*)
            if ! command -v pip3 >/dev/null 2>&1; then
                print_error "pip3 not found; cannot update Codex"
                return 1
            fi
            if pip3 install --user --upgrade openai-codex; then
                print_success "Codex CLI updated via pip"
                return 0
            else
                print_error "pip update for openai-codex failed"
                return 1
            fi
            ;;
        installer:*)
            print_status "Re-running installer for Codex CLI..."
            ;;
        *)
            print_status "Installation method unknown; attempting reinstall..."
            ;;
    esac

    # Fall back to reinstall if update method could not complete
    if install_codex; then
        print_success "Codex CLI reinstalled"
        return 0
    fi

    return 1
}

main() {
    print_status "OpenAI Codex CLI Installation Script"

    # Detect current installation state (does not exit early)
    check_codex "$@"

    if [ "$CODEX_INSTALLED" = "yes" ]; then
        if update_codex; then
            exit 0
        fi
        print_status "Update failed; attempting fresh installation..."
    fi

    # Install Codex
    if install_codex; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
