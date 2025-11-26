#!/usr/bin/env bash

# Install just - a modern command runner (alternative to make)
# Works on macOS and Linux
# https://github.com/casey/just
#
# Uses the official just installer script - no Rust/Cargo required

# set -e  # Disabled to allow proper error handling and prevent killing parent process

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

check_just_installed() {
    if command -v just >/dev/null 2>&1; then
        local version=$(just --version 2>/dev/null | head -1)
        print_success "just is already installed: $version"
        return 0
    else
        return 1
    fi
}

ensure_local_bin_in_path() {
    local local_bin="$HOME/.local/bin"

    # Add to current session PATH if not already there
    if [[ ":$PATH:" != *":$local_bin:"* ]]; then
        export PATH="$local_bin:$PATH"
    fi

    # Check if it's in shell config files
    local shell_rc=""
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
    fi

    if [[ -n "$shell_rc" ]] && [[ -f "$shell_rc" ]]; then
        if ! grep -q "$local_bin" "$shell_rc" 2>/dev/null; then
            print_status "Adding $local_bin to PATH in $shell_rc"
            echo "" >> "$shell_rc"
            echo "# Added by just installer" >> "$shell_rc"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_rc"
        fi
    fi
}

install_just() {
    print_status "Installing just via official installer script..."

    # Create ~/.local/bin if it doesn't exist
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"

    # Download and run the official installer to ~/.local/bin (no sudo required)
    if curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$install_dir"; then
        print_success "just installed successfully to $install_dir"

        # Ensure ~/.local/bin is in PATH
        ensure_local_bin_in_path

        return 0
    else
        print_error "Failed to install just via official installer"
        return 1
    fi
}

verify_installation() {
    # Ensure PATH includes ~/.local/bin for verification
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if command -v just >/dev/null 2>&1; then
        local version=$(just --version 2>/dev/null | head -1)
        print_success "just installation verified: $version"
        echo ""
        echo "You can now use just to run commands from justfiles."
        echo "Example usage:"
        echo "  just          # List available recipes"
        echo "  just <recipe> # Run a specific recipe"
        return 0
    else
        print_error "just not found in PATH after installation"
        echo "You may need to:"
        echo "  - Restart your shell"
        echo "  - Run: source ~/.zshrc  (or ~/.bashrc)"
        return 1
    fi
}

main() {
    echo "======================================"
    echo "       just Installation Script       "
    echo "======================================"
    echo ""

    # Check if already installed
    if check_just_installed; then
        echo ""
        echo "No installation needed."
        exit 0
    fi

    print_status "just not found, proceeding with installation..."
    echo ""

    # Install just
    if install_just; then
        echo ""
        # Verify installation
        if verify_installation; then
            echo ""
            echo "======================================"
            print_success "just installation complete!"
            echo "======================================"
            exit 0
        else
            exit 1
        fi
    else
        print_error "Failed to install just. Please install manually."
        print_status "Visit https://github.com/casey/just for installation instructions"
        exit 1
    fi
}

# Only run main if script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi