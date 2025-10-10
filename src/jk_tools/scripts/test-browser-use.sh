#!/usr/bin/env bash

# NAME
#   test-browser-use - Test mcp-browser-use CLI with example query
#
# SYNOPSIS
#   test-browser-use [QUERY]
#   test-browser-use --help
#
# DESCRIPTION
#   Demonstrates how to use the mcp-browser-use CLI tool for browser automation
#   with OpenRouter LLM models. Loads configuration from .env.test and executes
#   a browser agent task.
#
# PARAMETERS
#   QUERY    Optional search query (default: example Python docs search)
#
# OPTIONS
#   --help   Display this help message
#
# EXAMPLES
#   # Run with default query
#   test-browser-use
#
#   # Run with custom query
#   test-browser-use "Find the latest React documentation"
#
# REQUIREMENTS
#   - uvx (installed via uv)
#   - .env.test file with MCP_* environment variables
#   - Valid OpenRouter API key
#
# ENVIRONMENT VARIABLES
#   MCP_LLM_PROVIDER              LLM provider (e.g., "openrouter")
#   MCP_LLM_OPENROUTER_API_KEY    OpenRouter API key
#   MCP_LLM_MODEL_NAME            Model to use (e.g., "openai/gpt-5-mini")
#   MCP_BROWSER_HEADLESS          Run browser in headless mode (true/false)
#   MCP_AGENT_TOOL_USE_VISION     Enable vision capabilities (true/false)

set -euo pipefail

show_help() {
    sed -n '/^# NAME/,/^$/p' "$0" | sed 's/^# //g; s/^#//g'
}

if [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$SCRIPT_DIR")"
cd "$TOOLS_DIR"

if [[ ! -f .env.test ]]; then
    echo "Error: .env.test file not found in $TOOLS_DIR"
    echo "Please create .env.test with required MCP_* variables"
    exit 1
fi

source .env.test

QUERY="${1:-Search Google for 'Python documentation' and tell me the first result URL}"

echo "Running browser agent with query: $QUERY"
echo "Using model: ${MCP_LLM_MODEL_NAME:-not set}"
echo ""

uvx --from mcp-server-browser-use@latest \
  mcp-browser-cli -e .env.test run-browser-agent \
  "$QUERY"
