#!/usr/bin/env bash

# Install Rust and Cargo via rustup
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

check_rust_installed() {
    if command -v cargo >/dev/null 2>&1 && command -v rustc >/dev/null 2>&1; then
        local cargo_version=$(cargo --version 2>/dev/null | cut -d' ' -f2)
        local rustc_version=$(rustc --version 2>/dev/null | cut -d' ' -f2)
        print_success "Rust is already installed (cargo: $cargo_version, rustc: $rustc_version)"
        return 0
    else
        return 1
    fi
}

install_prerequisites() {
    local os_type="$(uname -s)"
    
    case "$os_type" in
        Darwin*)
            # macOS - Install Apple toolchain (compiler & linker)
            print_status "Checking for Xcode Command Line Tools..."
            if ! xcode-select -p >/dev/null 2>&1; then
                print_status "Installing Xcode Command Line Tools..."
                xcode-select --install
                # Wait for user to complete installation
                print_status "Please complete the Xcode Command Line Tools installation in the popup window."
                print_status "Press Enter when installation is complete..."
                read -r
            else
                print_success "Xcode Command Line Tools already installed"
            fi
            ;;
        Linux*)
            # Linux - Install build tools
            if command -v apt-get >/dev/null 2>&1; then
                print_status "Installing build tools for Debian/Ubuntu..."
                sudo apt update
                sudo apt install -y build-essential curl
            elif command -v dnf >/dev/null 2>&1; then
                print_status "Installing build tools for Fedora..."
                sudo dnf install -y gcc gcc-c++ make curl
            elif command -v yum >/dev/null 2>&1; then
                print_status "Installing build tools for RHEL/CentOS..."
                sudo yum install -y gcc gcc-c++ make curl
            elif command -v pacman >/dev/null 2>&1; then
                print_status "Installing build tools for Arch..."
                sudo pacman -S --needed base-devel curl
            elif command -v zypper >/dev/null 2>&1; then
                print_status "Installing build tools for openSUSE..."
                sudo zypper install -y gcc gcc-c++ make curl
            elif command -v apk >/dev/null 2>&1; then
                print_status "Installing build tools for Alpine..."
                sudo apk add build-base curl
            else
                print_status "Could not detect package manager."
                print_status "Please ensure GCC/Clang and curl are installed according to your distribution's documentation."
                print_status "Press Enter to continue..."
                read -r
            fi
            ;;
        *)
            print_error "Unsupported OS: $os_type"
            exit 1
            ;;
    esac
}

install_rust() {
    print_status "Installing Rust via rustup..."
    
    # Download and run rustup installer
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Source cargo environment
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
        print_success "Rust environment loaded"
    else
        print_error "Could not find Rust environment file"
        exit 1
    fi
}

verify_installation() {
    if command -v cargo >/dev/null 2>&1 && command -v rustc >/dev/null 2>&1; then
        local cargo_version=$(cargo --version 2>/dev/null)
        local rustc_version=$(rustc --version 2>/dev/null)
        print_success "Rust installation verified!"
        echo "  - $cargo_version"
        echo "  - $rustc_version"
        return 0
    else
        print_error "Rust installation failed - cargo or rustc not found in PATH"
        echo "  Try running: source \$HOME/.cargo/env"
        return 1
    fi
}

main() {
    echo "======================================"
    echo "       Rust Installation Script       "
    echo "======================================"
    echo ""
    
    # Check if already installed
    if check_rust_installed; then
        echo ""
        echo "No installation needed."
        exit 0
    fi
    
    print_status "Rust not found, proceeding with installation..."
    echo ""
    
    # Install prerequisites
    install_prerequisites
    
    # Install Rust
    install_rust
    
    # Verify installation
    echo ""
    if verify_installation; then
        echo ""
        echo "======================================"
        print_success "Rust installation complete!"
        echo ""
        echo "Note: You may need to run the following to use Rust in your current shell:"
        echo "  source \$HOME/.cargo/env"
        echo "======================================"
        exit 0
    else
        exit 1
    fi
}

main "$@"