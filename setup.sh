#!/usr/bin/env bash

# Tools Repository Setup Script
# This script now uses Python for better control and reporting

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/setup_manager.py"
REQUIREMENTS_FILE="${SCRIPT_DIR}/requirements.txt"

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

check_python() {
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif command -v python >/dev/null 2>&1; then
        # Check if it's Python 3
        if python --version 2>&1 | grep -q "Python 3"; then
            PYTHON_CMD="python"
        else
            print_error "Python 3 is required but not found"
            exit 1
        fi
    else
        print_error "Python 3 is required but not found"
        print_status "Please install Python 3 and try again"
        exit 1
    fi

    local python_version=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
    print_success "Found Python: $python_version"
}

check_pip() {
    if ! $PYTHON_CMD -m pip --version >/dev/null 2>&1; then
        print_status "pip not found, attempting to install..."

        # Try to install pip
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y python3-pip
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y python3-pip
        elif command -v brew >/dev/null 2>&1; then
            brew install python3
        else
            print_error "Could not install pip automatically"
            print_status "Please install pip manually and try again"
            exit 1
        fi
    fi

    print_success "pip is available"
}

install_requirements() {
    if [ -f "$REQUIREMENTS_FILE" ]; then
        print_status "Installing Python requirements..."

        # Check if rich is already installed
        if $PYTHON_CMD -c "import rich" 2>/dev/null; then
            print_success "Required Python packages already installed"
        else
            if $PYTHON_CMD -m pip install -r "$REQUIREMENTS_FILE" --user --quiet; then
                print_success "Python requirements installed successfully"
            else
                print_error "Failed to install Python requirements"
                print_status "Trying with elevated permissions..."
                if $PYTHON_CMD -m pip install -r "$REQUIREMENTS_FILE" --quiet; then
                    print_success "Python requirements installed successfully"
                else
                    print_error "Failed to install requirements. Please run: pip install rich"
                    exit 1
                fi
            fi
        fi
    else
        print_error "requirements.txt not found"
        exit 1
    fi
}

run_setup_manager() {
    print_status "Launching Python setup manager..."
    echo ""

    # Make the Python script executable
    chmod +x "$PYTHON_SCRIPT"

    # Run the Python setup manager with any arguments passed to this script
    $PYTHON_CMD "$PYTHON_SCRIPT" "$@"
}

main() {
    echo "======================================"
    echo "     Tools Repository Setup Script    "
    echo "======================================"
    echo ""

    # Check for Python
    check_python

    # Check for pip
    check_pip

    # Install requirements
    install_requirements

    echo ""

    # Run the Python setup manager
    run_setup_manager "$@"
}

# Pass all arguments to main
main "$@"