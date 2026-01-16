#!/usr/bin/env bash

# Install FlowSpace (fs2) - Code intelligence tool for AI agents
#
# fs2 provides MCP server capabilities for enhanced codebase exploration.
# It enables semantic search, code tree navigation, and AI-assisted code understanding.
#
# Usage: fs2.sh [OPTIONS]
#   --update      Update to latest version
#   --verbose     Show detailed output
#   --help        Show this help message

# set -e  # Disabled to allow proper error handling

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

# Parse arguments
UPDATE_MODE=false
VERBOSE=false

for arg in "$@"; do
    case $arg in
        --update|-u)
            UPDATE_MODE=true
            ;;
        --verbose|-v)
            VERBOSE=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --update, -u    Update fs2 to latest version"
            echo "  --verbose, -v   Show detailed output"
            echo "  --help, -h      Show this help message"
            echo ""
            exit 0
            ;;
    esac
done

print_status() {
    echo "[*] $1"
}

print_success() {
    echo -e "${GREEN}[✓]${RESET} $1"
}

print_error() {
    echo -e "${RED}[✗]${RESET} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[!]${RESET} $1"
}

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BOLD}[VERBOSE]${RESET} $1"
    fi
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

get_fs2_version() {
    if check_command fs2; then
        fs2 --version 2>/dev/null | head -1 || echo "unknown"
    else
        echo "not installed"
    fi
}

install_uv() {
    print_status "Installing uv (required for fs2 installation)..."

    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        # Add to current PATH
        export PATH="$HOME/.local/bin:$PATH"
        print_success "uv installed successfully"
        return 0
    else
        print_error "Failed to install uv"
        return 1
    fi
}

install_fs2() {
    local version_before=$(get_fs2_version)
    print_verbose "Version before: $version_before"

    # Check if uv/uvx is available
    if ! check_command uvx; then
        if check_command uv; then
            print_verbose "uv found, uvx should be available"
        else
            print_warning "uv/uvx not found, installing..."
            if ! install_uv; then
                return 1
            fi
        fi
    fi

    # Ensure PATH includes ~/.local/bin and ~/.cargo/bin
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    print_status "Installing FlowSpace (fs2)..."
    print_verbose "Running: uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install"

    local install_output
    local install_exit_code

    if [ "$VERBOSE" = true ]; then
        uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install
        install_exit_code=$?
    else
        install_output=$(uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install 2>&1)
        install_exit_code=$?
    fi

    if [ $install_exit_code -eq 0 ]; then
        # Verify installation
        # The fs2 install command puts the binary in ~/.local/bin
        export PATH="$HOME/.local/bin:$PATH"

        if check_command fs2; then
            local version_after=$(get_fs2_version)
            print_success "FlowSpace (fs2) installed successfully"
            print_status "Version: $version_after"

            print_status ""
            print_status "Next steps:"
            print_status "  1. Navigate to your project directory"
            print_status "  2. Run: fs2 init"
            print_status "  3. Run: fs2 scan"
            print_status "  4. (Optional) For semantic search: fs2 scan --embed"
            print_status ""
            print_status "The FlowSpace MCP server will be available as 'fs2 mcp'"
            return 0
        else
            print_warning "fs2 command not found in PATH after installation"
            print_status "You may need to add ~/.local/bin to your PATH:"
            print_status "  export PATH=\"\$HOME/.local/bin:\$PATH\""

            # Check if it exists but not in PATH
            if [ -x "$HOME/.local/bin/fs2" ]; then
                print_success "fs2 binary found at ~/.local/bin/fs2"
                return 0
            fi
            return 1
        fi
    else
        print_error "Failed to install fs2"
        if [ "$VERBOSE" = true ] || [ -n "$install_output" ]; then
            echo "$install_output"
        fi
        return 1
    fi
}

update_fs2() {
    local version_before=$(get_fs2_version)
    print_status "Current version: $version_before"
    print_status "Updating FlowSpace (fs2)..."

    # Force reinstall to get latest version
    print_verbose "Running: uvx --reinstall --from git+https://github.com/AI-Substrate/flow_squared fs2 install"

    if [ "$VERBOSE" = true ]; then
        uv tool upgrade fs2 2>/dev/null || \
        uvx --reinstall --from git+https://github.com/AI-Substrate/flow_squared fs2 install
    else
        uv tool upgrade fs2 2>/dev/null || \
        uvx --reinstall --from git+https://github.com/AI-Substrate/flow_squared fs2 install >/dev/null 2>&1
    fi

    local version_after=$(get_fs2_version)

    if [ "$version_before" != "$version_after" ]; then
        print_success "fs2 updated: $version_before -> $version_after"
    else
        print_success "fs2 is already at the latest version: $version_after"
    fi
}

check_fs2() {
    if check_command fs2; then
        local version=$(get_fs2_version)
        print_success "FlowSpace (fs2) is already installed (version: $version)"
        return 0
    fi
    return 1
}

main() {
    echo ""
    echo "======================================"
    echo "    FlowSpace (fs2) Installation      "
    echo "======================================"
    echo ""

    if [ "$UPDATE_MODE" = true ]; then
        if check_fs2; then
            update_fs2
        else
            print_warning "fs2 not installed, performing fresh installation..."
            install_fs2
        fi
    else
        if check_fs2; then
            print_status "To update, run with --update flag"
        else
            install_fs2
        fi
    fi
}

main "$@"
