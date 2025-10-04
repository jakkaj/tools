#!/usr/bin/env bash

# Install browser-use MCP server dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
ENV_FILE="${REPO_ROOT}/.env"
ENV_SAMPLE="${REPO_ROOT}/.env.sample"

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
    echo "[!] $1" >&2
}

main() {
    print_status "Checking mcp-browser-use dependencies..."
    
    # Check if uv is available
    if ! command -v uv &> /dev/null; then
        print_error "uv is not installed. Please install uv first:"
        print_error "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
    
    print_success "uv is available"
    
    # Check if uvx is available
    if ! command -v uvx &> /dev/null; then
        print_error "uvx is not available. Please ensure uv is properly installed:"
        print_error "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
    
    print_success "uvx is available"
    
    # Check if .env file exists
    if [ ! -f "${ENV_FILE}" ]; then
        print_warning ".env file not found at ${ENV_FILE}"
        if [ -f "${ENV_SAMPLE}" ]; then
            print_warning "Please copy ${ENV_SAMPLE} to ${ENV_FILE} and fill in your MCP_LLM_OPENROUTER_API_KEY"
            print_warning "  cp ${ENV_SAMPLE} ${ENV_FILE}"
        else
            print_warning "Please create ${ENV_FILE} and add your MCP_LLM_OPENROUTER_API_KEY"
        fi
        print_warning "Get your API key from: https://openrouter.ai/keys"
        return 1
    fi
    
    # Check if MCP_LLM_OPENROUTER_API_KEY is set
    source "${ENV_FILE}"
    if [ -z "${MCP_LLM_OPENROUTER_API_KEY}" ] || [ "${MCP_LLM_OPENROUTER_API_KEY}" = "your_openrouter_api_key_here" ]; then
        print_warning "MCP_LLM_OPENROUTER_API_KEY is not set or is still the default value in ${ENV_FILE}"
        print_warning "Please update ${ENV_FILE} with your actual OpenRouter API key"
        print_warning "Get your API key from: https://openrouter.ai/keys"
        return 1
    fi
    
    print_success "OpenRouter API key found in .env"
    
    # Check and install Playwright browsers
    print_status "Checking Playwright browsers..."
    if uvx --from mcp-server-browser-use@latest python -m playwright install --help &> /dev/null; then
        print_status "Installing Playwright browsers (this may take a few minutes)..."
        if uvx --from mcp-server-browser-use@latest python -m playwright install; then
            print_success "Playwright browsers installed successfully"
        else
            print_warning "Failed to install Playwright browsers - you may need to run this manually:"
            print_warning "  uvx --from mcp-server-browser-use@latest python -m playwright install"
        fi
    else
        print_warning "Could not verify Playwright installation"
    fi
    
    print_success "mcp-browser-use setup complete"
    print_status "MCP configuration will be updated by agents.sh"
    
    return 0
}

main "$@"
