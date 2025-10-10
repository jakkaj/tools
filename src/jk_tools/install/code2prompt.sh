#!/usr/bin/env bash

# Install code2prompt via cargo
# Requires Rust/Cargo to be installed first

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

check_code2prompt_installed() {
    if command -v code2prompt >/dev/null 2>&1; then
        local version=$(code2prompt --version 2>/dev/null | head -1)
        print_success "code2prompt is already installed: $version"
        return 0
    else
        return 1
    fi
}

ensure_rust_installed() {
    # Source cargo environment if it exists
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
    
    # Check if cargo is available
    if ! command -v cargo >/dev/null 2>&1; then
        print_status "Cargo not found. Installing Rust first..."
        
        # Run the rust installation script
        if [ -f "${SCRIPT_DIR}/rust.sh" ]; then
            bash "${SCRIPT_DIR}/rust.sh"
            
            # Source cargo environment after installation
            if [ -f "$HOME/.cargo/env" ]; then
                source "$HOME/.cargo/env"
            else
                print_error "Failed to load Rust environment after installation"
                exit 1
            fi
        else
            print_error "rust.sh not found in ${SCRIPT_DIR}"
            print_error "Please install Rust manually first: https://rustup.rs"
            exit 1
        fi
    else
        local cargo_version=$(cargo --version 2>/dev/null | cut -d' ' -f2)
        print_success "Cargo is available (version $cargo_version)"
    fi
}

install_code2prompt() {
    print_status "Installing code2prompt via cargo..."
    print_status "This may take a few minutes as it compiles from source..."
    
    # Install code2prompt using cargo
    if cargo install code2prompt; then
        print_success "code2prompt installed successfully"
    else
        print_error "Failed to install code2prompt"
        exit 1
    fi
}

verify_installation() {
    # Source cargo environment to ensure PATH is updated
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
    
    if command -v code2prompt >/dev/null 2>&1; then
        local version=$(code2prompt --version 2>/dev/null | head -1)
        print_success "code2prompt installation verified: $version"
        return 0
    else
        print_error "code2prompt not found in PATH after installation"
        echo "  You may need to add ~/.cargo/bin to your PATH"
        echo "  Try running: source \$HOME/.cargo/env"
        return 1
    fi
}

main() {
    echo "======================================"
    echo "    code2prompt Installation Script   "
    echo "======================================"
    echo ""
    
    # Check if already installed
    if check_code2prompt_installed; then
        echo ""
        echo "No installation needed."
        exit 0
    fi
    
    print_status "code2prompt not found, proceeding with installation..."
    echo ""
    
    # Ensure Rust/Cargo is installed
    ensure_rust_installed
    echo ""
    
    # Install code2prompt
    install_code2prompt
    echo ""
    
    # Verify installation
    if verify_installation; then
        echo ""
        echo "======================================"
        print_success "code2prompt installation complete!"
        echo ""
        echo "You can now use code2prompt. Try:"
        echo "  code2prompt --help"
        echo "======================================"
        exit 0
    else
        exit 1
    fi
}

main "$@"