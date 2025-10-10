#!/usr/bin/env bash

# Install OpenCode - Terminal coding agent
# Works on macOS and Linux

set -e

OPENCODE_METHOD=""
OPENCODE_INSTALLED="no"
OPENCODE_UPDATE_REQUESTED="no"
OPENCODE_VERSION="unknown"
OPENCODE_BIN=""

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

detect_opencode_method() {
    OPENCODE_METHOD="unknown"

    if command -v npm >/dev/null 2>&1; then
        if npm ls -g opencode-ai --depth=0 >/dev/null 2>&1; then
            OPENCODE_METHOD="npm:opencode-ai"
            return
        fi
    fi

    if command -v brew >/dev/null 2>&1; then
        if brew list opencode >/dev/null 2>&1; then
            OPENCODE_METHOD="brew:opencode"
            return
        elif brew list sst/tap/opencode >/dev/null 2>&1; then
            OPENCODE_METHOD="brew:sst/tap/opencode"
            return
        fi
    fi

    if [ -n "$OPENCODE_BIN" ]; then
        case "$OPENCODE_BIN" in
            "$HOME/.opencode"* ) OPENCODE_METHOD="installer:official" ;;
        esac
    fi
}

check_opencode() {
    if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
        OPENCODE_UPDATE_REQUESTED="yes"
    fi

    OPENCODE_INSTALLED="no"
    OPENCODE_BIN=""
    OPENCODE_VERSION="unknown"
    OPENCODE_METHOD="unknown"

    if command -v opencode >/dev/null 2>&1; then
        OPENCODE_BIN=$(command -v opencode)
    elif [ -x "$HOME/.opencode/bin/opencode" ]; then
        OPENCODE_BIN="$HOME/.opencode/bin/opencode"
    fi

    if [ -n "$OPENCODE_BIN" ]; then
        OPENCODE_VERSION=$($OPENCODE_BIN --version 2>/dev/null || echo "unknown")
        OPENCODE_INSTALLED="yes"
        detect_opencode_method

        case "$OPENCODE_METHOD" in
            npm:*)
                print_success "OpenCode (npm) detected (version: $OPENCODE_VERSION)"
                ;;
            brew:*)
                print_success "OpenCode (Homebrew) detected (version: $OPENCODE_VERSION)"
                ;;
            installer:*)
                print_success "OpenCode detected at $OPENCODE_BIN (version: $OPENCODE_VERSION)"
                ;;
            *)
                print_success "OpenCode detected (version: $OPENCODE_VERSION)"
                ;;
        esac

        if [ "$OPENCODE_UPDATE_REQUESTED" = "no" ]; then
            OPENCODE_UPDATE_REQUESTED="auto"
        fi
    else
        OPENCODE_INSTALLED="no"
    fi

    if [ "$OPENCODE_UPDATE_REQUESTED" = "yes" ]; then
        print_status "Update requested; preparing to update OpenCode..."
    elif [ "$OPENCODE_UPDATE_REQUESTED" = "auto" ]; then
        print_status "Refreshing OpenCode to ensure latest version..."
    fi

    return 0
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

update_opencode() {
    if [ "$OPENCODE_INSTALLED" != "yes" ]; then
        return 1
    fi

    local update_bin="$OPENCODE_BIN"
    if [ -z "$update_bin" ] || [ ! -x "$update_bin" ]; then
        if command -v opencode >/dev/null 2>&1; then
            update_bin=$(command -v opencode)
        fi
    fi

    if [ -z "$update_bin" ]; then
        print_error "OpenCode binary not found for update"
        print_status "Attempting reinstall via official installer..."
        if install_opencode; then
            print_success "OpenCode reinstalled"
            return 0
        fi
        return 1
    fi

    if [ "$OPENCODE_UPDATE_REQUESTED" = "auto" ]; then
        print_status "Refreshing OpenCode via 'opencode update'..."
    else
        print_status "Updating OpenCode via 'opencode update'..."
    fi

    if "$update_bin" update; then
        print_success "OpenCode updated via CLI"
        return 0
    fi

    print_error "OpenCode CLI update command failed"
    print_status "Attempting reinstall via official installer..."

    if install_opencode; then
        print_success "OpenCode reinstalled"
        return 0
    fi

    return 1
}

main() {
    print_status "OpenCode Installation Script"

    # Detect current installation state (does not exit early)
    check_opencode "$@"

    if [ "$OPENCODE_INSTALLED" = "yes" ]; then
        if update_opencode; then
            exit 0
        fi
        print_status "Update failed; attempting fresh installation..."
    fi

    # Install OpenCode
    if install_opencode; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
