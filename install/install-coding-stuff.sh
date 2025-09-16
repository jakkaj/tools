#!/usr/bin/env bash

# Install modern coding assistant tools:
# - Serena (coding-agent toolkit)
# - OpenCode (terminal coding agent)
# - Claude Code CLI
# - OpenAI Codex CLI
#
# Works on macOS and Linux

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

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

check_command() {
    command -v "$1" >/dev/null 2>&1
}

get_node_version() {
    if check_command node; then
        node -v | cut -d'v' -f2
    else
        echo "0.0.0"
    fi
}

version_gte() {
    # Check if version $1 >= version $2
    printf '%s\n%s' "$2" "$1" | sort -V | head -n1 | grep -q "^$2$"
}

# ============== Prerequisites ==============

check_prerequisites() {
    local missing_prereqs=()

    # Check Node.js >= 18
    if check_command node; then
        local node_version=$(get_node_version)
        if ! version_gte "$node_version" "18.0.0"; then
            print_warning "Node.js version $node_version found, but >= 18.0.0 required"
            missing_prereqs+=("node18")
        else
            print_success "Node.js $node_version found"
        fi
    else
        print_warning "Node.js not found (required for OpenCode, Claude Code, Codex)"
        missing_prereqs+=("node")
    fi

    # Check Python 3
    if check_command python3; then
        local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        print_success "Python $python_version found"
    else
        print_warning "Python 3 not found (required for Serena)"
        missing_prereqs+=("python3")
    fi

    # Check pipx (recommended for Serena)
    if ! check_command pipx; then
        print_warning "pipx not found (recommended for Serena installation)"
        missing_prereqs+=("pipx")
    else
        print_success "pipx found"
    fi

    # Check npm
    if ! check_command npm; then
        print_warning "npm not found (required for Node.js tools)"
        missing_prereqs+=("npm")
    else
        local npm_version=$(npm -v 2>/dev/null)
        print_success "npm $npm_version found"
    fi

    if [ ${#missing_prereqs[@]} -gt 0 ]; then
        echo ""
        print_status "Installing missing prerequisites..."
        for prereq in "${missing_prereqs[@]}"; do
            case "$prereq" in
                node|node18)
                    install_node
                    ;;
                python3)
                    install_python3
                    ;;
                pipx)
                    install_pipx
                    ;;
                npm)
                    install_npm
                    ;;
            esac
        done
    fi
}

install_node() {
    print_status "Installing Node.js..."

    if [[ "$PKG_MANAGER" == "brew" ]]; then
        brew install node
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        # Install Node.js 20.x from NodeSource
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$PKG_MANAGER" == "dnf" ]] || [[ "$PKG_MANAGER" == "yum" ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
        sudo $PKG_MANAGER install -y nodejs
    else
        # Fallback to fnm (Fast Node Manager)
        print_status "Installing Node.js via fnm..."
        curl -fsSL https://fnm.vercel.app/install | bash
        export PATH="$HOME/.local/share/fnm:$PATH"
        eval "$(fnm env)"
        fnm install 20
        fnm use 20
        fnm default 20
    fi
}

install_python3() {
    print_status "Installing Python 3..."

    if [[ "$PKG_MANAGER" == "brew" ]]; then
        brew install python3
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    elif [[ "$PKG_MANAGER" == "dnf" ]] || [[ "$PKG_MANAGER" == "yum" ]]; then
        sudo $PKG_MANAGER install -y python3 python3-pip
    elif [[ "$PKG_MANAGER" == "pacman" ]]; then
        sudo pacman -S --needed python python-pip
    else
        print_error "Cannot automatically install Python 3. Please install manually."
        exit 1
    fi
}

install_pipx() {
    print_status "Installing pipx..."

    if [[ "$PKG_MANAGER" == "apt" ]]; then
        # Use system package manager for Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y pipx
        pipx ensurepath
    elif [[ "$PKG_MANAGER" == "brew" ]]; then
        brew install pipx
        pipx ensurepath
    elif [[ "$PKG_MANAGER" == "dnf" ]] || [[ "$PKG_MANAGER" == "yum" ]]; then
        sudo $PKG_MANAGER install -y pipx
        pipx ensurepath
    elif [[ "$PKG_MANAGER" == "pacman" ]]; then
        sudo pacman -S --needed python-pipx
        pipx ensurepath
    else
        # Fallback to pip with --break-system-packages for modern systems
        if check_command python3; then
            print_warning "Using pip with --break-system-packages flag"
            python3 -m pip install --user --break-system-packages pipx
            python3 -m pipx ensurepath
        else
            print_error "Python 3 is required to install pipx"
            return 1
        fi
    fi

    # Add to current PATH
    export PATH="$HOME/.local/bin:$PATH"

    if check_command pipx; then
        print_success "pipx installed successfully"
    else
        print_warning "pipx installed but may require shell restart to be available in PATH"
    fi
}

install_npm() {
    print_status "npm should come with Node.js. Checking Node.js installation..."
    if ! check_command node; then
        install_node
    fi
}

# ============== Tool Installation Functions ==============

check_serena() {
    if check_command serena-cli; then
        local version=$(serena-cli --version 2>/dev/null || echo "unknown")
        print_success "Serena CLI is already installed (version: $version)"
        return 0
    fi
    return 1
}

install_serena() {
    print_status "Installing Serena CLI..."

    # Prefer pipx if available
    if check_command pipx; then
        print_status "Installing Serena via pipx..."
        # pipx returns non-zero if already installed, so handle that case
        pipx install serena-cli 2>&1 | tee /tmp/pipx-output.txt
        if grep -q "already seems to be installed" /tmp/pipx-output.txt; then
            print_success "Serena CLI already installed via pipx"
        elif grep -q "installed package serena-cli" /tmp/pipx-output.txt; then
            print_success "Serena CLI newly installed via pipx"
        else
            print_warning "pipx installation may have failed, trying pip..."
            python3 -m pip install --user --break-system-packages serena-cli 2>/dev/null || \
            python3 -m pip install --user serena-cli
        fi
    else
        print_status "Installing Serena via pip..."
        python3 -m pip install --user serena-cli
    fi

    # Add .local/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Verify installation
    if check_command serena-cli; then
        print_success "Serena CLI installation verified"
        print_status "Run 'serena-cli check-env' to verify environment"
    else
        print_error "Serena CLI installation failed"
        return 1
    fi
}

check_opencode() {
    # Check in standard PATH and also in ~/.opencode/bin
    if check_command opencode; then
        local version=$(opencode --version 2>/dev/null || echo "unknown")
        print_success "OpenCode is already installed (version: $version)"
        return 0
    elif [ -x "$HOME/.opencode/bin/opencode" ]; then
        local version=$("$HOME/.opencode/bin/opencode" --version 2>/dev/null || echo "unknown")
        print_success "OpenCode is already installed at ~/.opencode/bin (version: $version)"
        return 0
    fi
    return 1
}

install_opencode() {
    print_status "Installing OpenCode..."

    # Try curl installer first (recommended)
    if curl -fsSL https://opencode.ai/install 2>/dev/null | bash; then
        print_success "OpenCode installed via official installer"
    elif check_command npm; then
        print_status "Installer failed, trying npm..."
        if npm install -g opencode-ai; then
            print_success "OpenCode installed via npm"
        else
            print_error "OpenCode installation failed"
            return 1
        fi
    elif [[ "$PKG_MANAGER" == "brew" ]]; then
        print_status "Trying Homebrew installation..."
        if brew install sst/tap/opencode; then
            print_success "OpenCode installed via Homebrew"
        else
            print_error "OpenCode installation failed"
            return 1
        fi
    else
        print_error "Could not install OpenCode. Please install manually."
        return 1
    fi

    # Source .zshrc to get updated PATH if opencode was installed
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi

    # Verify installation
    if check_command opencode || [ -x "$HOME/.opencode/bin/opencode" ]; then
        print_success "OpenCode installation verified"
        print_status "Run 'opencode auth login' to authenticate"
    else
        print_error "OpenCode not found after installation"
        return 1
    fi
}

check_claude_code() {
    # Check in standard PATH and also common installation locations
    if check_command claude; then
        local version=$(claude --version 2>/dev/null || echo "unknown")
        print_success "Claude Code CLI is already installed (version: $version)"
        return 0
    elif [ -x "$HOME/.claude/bin/claude" ]; then
        local version=$("$HOME/.claude/bin/claude" --version 2>/dev/null || echo "unknown")
        print_success "Claude Code CLI is already installed at ~/.claude/bin (version: $version)"
        return 0
    fi
    return 1
}

install_claude_code() {
    print_status "Installing Claude Code CLI..."

    # Try npm first (most reliable)
    if check_command npm; then
        print_status "Installing Claude Code via npm..."
        if npm install -g @anthropic-ai/claude-code; then
            print_success "Claude Code CLI installed via npm"
        else
            print_warning "npm installation failed, trying native installer..."
            if curl -fsSL https://claude.ai/install.sh 2>/dev/null | bash; then
                print_success "Claude Code CLI installed via native installer"
            else
                print_error "Claude Code CLI installation failed"
                return 1
            fi
        fi
    else
        # Try native installer
        print_status "Installing Claude Code via native installer..."
        if curl -fsSL https://claude.ai/install.sh 2>/dev/null | bash; then
            print_success "Claude Code CLI installed"
        else
            print_error "Claude Code CLI installation failed"
            return 1
        fi
    fi

    # Verify installation
    if check_command claude; then
        print_success "Claude Code CLI installation verified"
        print_status "Run 'claude' to start and authenticate"
        print_status "Run 'claude doctor' for diagnostics"
    else
        print_error "Claude Code CLI not found after installation"
        return 1
    fi
}

check_codex() {
    if check_command codex; then
        local version=$(codex --version 2>/dev/null || echo "unknown")
        print_success "OpenAI Codex CLI is already installed (version: $version)"
        return 0
    fi
    return 1
}

install_codex() {
    print_status "Installing OpenAI Codex CLI..."

    # Check Node.js version for Codex (requires Node 20+)
    local node_version=$(get_node_version)
    if ! version_gte "$node_version" "20.0.0"; then
        print_warning "Codex requires Node.js >= 20, but found $node_version"
        print_status "Attempting installation anyway..."
    fi

    # Try npm first with local prefix to avoid permission issues
    if check_command npm; then
        print_status "Installing Codex via npm (locally)..."
        # Install to user's home directory to avoid permission issues
        npm config set prefix "$HOME/.npm-global"
        export PATH="$HOME/.npm-global/bin:$PATH"

        if npm install -g @openai/codex 2>/dev/null; then
            print_success "Codex CLI installed via npm to ~/.npm-global"
            # Add to shell config if not already there
            if ! grep -q ".npm-global/bin" "$HOME/.zshrc" 2>/dev/null; then
                echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.zshrc"
                print_status "Added ~/.npm-global/bin to PATH in .zshrc"
            fi
        else
            print_warning "npm installation failed"
            if [[ "$PKG_MANAGER" == "brew" ]]; then
                print_status "Trying Homebrew installation..."
                if brew install codex; then
                    print_success "Codex CLI installed via Homebrew"
                else
                    print_error "Codex CLI installation failed"
                    print_warning "Note: Codex requires Node.js >= 20. Consider upgrading Node.js."
                    return 1
                fi
            else
                print_error "Codex CLI installation failed"
                print_warning "Note: Codex requires Node.js >= 20. Consider upgrading Node.js."
                return 1
            fi
        fi
    elif [[ "$PKG_MANAGER" == "brew" ]]; then
        print_status "Installing Codex via Homebrew..."
        if brew install codex; then
            print_success "Codex CLI installed via Homebrew"
        else
            print_error "Codex CLI installation failed"
            return 1
        fi
    else
        print_error "Could not install Codex CLI. Please install Node.js/npm first."
        return 1
    fi

    # Verify installation
    if check_command codex; then
        print_success "Codex CLI installation verified"
        print_status "Run 'codex' to start and authenticate with ChatGPT plan or API key"
    else
        print_error "Codex CLI not found after installation"
        return 1
    fi
}

# ============== Main ==============

main() {
    # Parse command line arguments
    UPDATE_MODE=false
    for arg in "$@"; do
        case $arg in
            --update|-u)
                UPDATE_MODE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --update, -u    Update already installed tools to latest versions"
                echo "  --help, -h      Show this help message"
                echo ""
                exit 0
                ;;
        esac
    done

    echo ""
    echo "======================================"
    echo "   Coding Tools Installation Script   "
    echo "======================================"
    echo ""
    if [ "$UPDATE_MODE" = true ]; then
        echo "Mode: UPDATE (will update existing tools)"
    else
        echo "Mode: INSTALL (will skip already installed tools)"
    fi
    echo ""
    echo "This script will install/update:"
    echo "  • Serena CLI (coding-agent toolkit)"
    echo "  • OpenCode (terminal coding agent)"
    echo "  • Claude Code CLI"
    echo "  • OpenAI Codex CLI"
    echo ""

    detect_os
    detect_package_manager

    print_status "Detected OS: $OS"
    print_status "Package manager: $PKG_MANAGER"
    echo ""

    # Check and install prerequisites
    print_status "Checking prerequisites..."
    check_prerequisites
    echo ""

    # Install each tool
    local tools_installed=0
    local tools_failed=0

    echo "======================================"
    echo "Installing Coding Assistant Tools"
    echo "======================================"
    echo ""

    # Serena - TEMPORARILY COMMENTED OUT DUE TO INSTALLATION ISSUES
    # print_status "Checking Serena CLI..."
    # if ! check_serena; then
    #     if install_serena; then
    #         ((tools_installed++))
    #     else
    #         ((tools_failed++))
    #     fi
    # fi
    # echo ""

    # Continue with other tools even if there were issues

    # OpenCode
    print_status "Checking OpenCode..."
    if [ "$UPDATE_MODE" = true ]; then
        if check_opencode; then
            print_status "Updating OpenCode to latest version..."
            if install_opencode; then
                ((tools_installed++))
                print_success "OpenCode updated successfully"
            else
                ((tools_failed++))
            fi
        else
            if install_opencode; then
                ((tools_installed++))
            else
                ((tools_failed++))
            fi
        fi
    else
        if ! check_opencode; then
            if install_opencode; then
                ((tools_installed++))
            else
                ((tools_failed++))
            fi
        fi
    fi
    echo ""

    # Claude Code
    print_status "Checking Claude Code CLI..."
    if [ "$UPDATE_MODE" = true ]; then
        if check_claude_code; then
            print_status "Updating Claude Code CLI to latest version..."
            if install_claude_code; then
                ((tools_installed++))
                print_success "Claude Code CLI updated successfully"
            else
                ((tools_failed++))
            fi
        else
            if install_claude_code; then
                ((tools_installed++))
            else
                ((tools_failed++))
            fi
        fi
    else
        if ! check_claude_code; then
            if install_claude_code; then
                ((tools_installed++))
            else
                ((tools_failed++))
            fi
        fi
    fi
    echo ""

    # Codex
    print_status "Checking OpenAI Codex CLI..."
    if [ "$UPDATE_MODE" = true ]; then
        if check_codex; then
            print_status "Updating Codex CLI to latest version..."
            if install_codex; then
                ((tools_installed++))
                print_success "Codex CLI updated successfully"
            else
                ((tools_failed++))
            fi
        else
            if install_codex; then
                ((tools_installed++))
            else
                ((tools_failed++))
            fi
        fi
    else
        if ! check_codex; then
            if install_codex; then
                ((tools_installed++))
            else
                ((tools_failed++))
            fi
        fi
    fi
    echo ""

    # Summary
    echo "======================================"
    echo "          Installation Summary         "
    echo "======================================"
    echo ""

    if [ $tools_installed -gt 0 ]; then
        print_success "$tools_installed tool(s) installed successfully"
    fi

    if [ $tools_failed -gt 0 ]; then
        print_error "$tools_failed tool(s) failed to install"
    fi

    if [ $tools_installed -eq 0 ] && [ $tools_failed -eq 0 ]; then
        print_success "All tools are already installed and up to date!"
    fi

    echo ""
    echo "Next steps:"
    echo "  1. Authenticate tools that require login:"
    echo "     • opencode auth login"
    echo "     • claude (will guide through authentication)"
    echo "     • codex (will prompt for ChatGPT plan or API key)"
    echo ""
    echo "  2. Verify installations:"
    echo "     • serena-cli check-env"
    echo "     • opencode --version"
    echo "     • claude doctor"
    echo "     • codex --version"
    echo ""
    echo "  3. Optional: Configure Serena as MCP server for Claude/Codex"
    echo "     See: https://github.com/oraios/serena"
    echo ""
    echo "======================================"

    if [ $tools_failed -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Only run main if script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi