#!/usr/bin/env bash

# Install just - a modern command runner (alternative to make)
# Works on macOS and Linux
# https://github.com/casey/just

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

print_warning() {
    echo "[!] $1"
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

detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="macOS";;
        CYGWIN*|MINGW*|MSYS*) OS="Windows";;
        *)          OS="Unknown";;
    esac
}

detect_package_manager() {
    if [[ "$OS" == "macOS" ]]; then
        if command -v brew >/dev/null 2>&1; then
            PKG_MANAGER="brew"
        else
            PKG_MANAGER="none"
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            PKG_MANAGER="apt"
        elif command -v dnf >/dev/null 2>&1; then
            PKG_MANAGER="dnf"
        elif command -v yum >/dev/null 2>&1; then
            PKG_MANAGER="yum"
        elif command -v pacman >/dev/null 2>&1; then
            PKG_MANAGER="pacman"
        elif command -v zypper >/dev/null 2>&1; then
            PKG_MANAGER="zypper"
        elif command -v apk >/dev/null 2>&1; then
            PKG_MANAGER="apk"
        else
            PKG_MANAGER="none"
        fi
    fi
}

install_just_brew() {
    print_status "Installing just via Homebrew..."
    if brew install just; then
        print_success "just installed successfully via Homebrew"
        return 0
    else
        print_error "Failed to install just via Homebrew"
        return 1
    fi
}

install_just_apt() {
    print_status "Installing just via apt..."
    # Update package list first
    sudo apt-get update
    if sudo apt-get install -y just; then
        print_success "just installed successfully via apt"
        return 0
    else
        # Try alternative: just might not be in default repos
        print_warning "just not found in apt repositories, trying official installer..."
        return 1
    fi
}

install_just_dnf() {
    print_status "Installing just via dnf..."
    if sudo dnf install -y just; then
        print_success "just installed successfully via dnf"
        return 0
    else
        print_warning "just not found in dnf repositories, trying official installer..."
        return 1
    fi
}

install_just_pacman() {
    print_status "Installing just via pacman..."
    if sudo pacman -S --noconfirm just; then
        print_success "just installed successfully via pacman"
        return 0
    else
        print_warning "just not found in pacman repositories, trying official installer..."
        return 1
    fi
}

install_just_official() {
    print_status "Installing just via official installer script..."

    # Determine installation directory
    local install_dir="/usr/local/bin"
    if [[ ! -w "$install_dir" ]]; then
        print_status "Need sudo access to install to $install_dir"
        local use_sudo="sudo"
    else
        local use_sudo=""
    fi

    # Download and run the official installer
    if curl -sSf https://just.systems/install.sh | $use_sudo bash -s -- --to "$install_dir"; then
        print_success "just installed successfully via official installer"
        return 0
    else
        print_error "Failed to install just via official installer"
        return 1
    fi
}

install_just_cargo() {
    print_status "Installing just via cargo (this may take a while as it compiles from source)..."

    # Check if cargo is available
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Cargo not found. Please install Rust first."
        return 1
    fi

    if cargo install just; then
        print_success "just installed successfully via cargo"
        # Add cargo bin to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
            export PATH="$HOME/.cargo/bin:$PATH"
        fi
        return 0
    else
        print_error "Failed to install just via cargo"
        return 1
    fi
}

install_just() {
    detect_os
    detect_package_manager

    print_status "Detected OS: $OS"
    print_status "Package manager: $PKG_MANAGER"

    local installed=false

    case "$PKG_MANAGER" in
        brew)
            install_just_brew && installed=true
            ;;
        apt)
            install_just_apt && installed=true
            ;;
        dnf|yum)
            install_just_dnf && installed=true
            ;;
        pacman)
            install_just_pacman && installed=true
            ;;
        *)
            print_warning "No supported package manager found"
            ;;
    esac

    # If package manager installation failed or wasn't available, try official installer
    if [[ "$installed" == "false" ]]; then
        print_status "Attempting installation via official installer..."
        if ! install_just_official; then
            # Last resort: try cargo if available
            if command -v cargo >/dev/null 2>&1; then
                print_status "Official installer failed, trying cargo..."
                install_just_cargo && installed=true
            fi
        else
            installed=true
        fi
    fi

    if [[ "$installed" == "false" ]]; then
        print_error "Failed to install just. Please install manually."
        print_status "Visit https://github.com/casey/just for installation instructions"
        return 1
    fi

    return 0
}

verify_installation() {
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
        echo "  - Add the installation directory to your PATH"
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
        exit 1
    fi
}

# Only run main if script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi