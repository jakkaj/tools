#!/usr/bin/env bash

set -e

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

show_help() {
  cat << EOF
NAME
    $SCRIPT_NAME - Discover and list all available jk-tools

SYNOPSIS
    $SCRIPT_NAME [--help] [--verbose]

DESCRIPTION
    Lists all available tools in the jk-tools collection with their descriptions,
    aliases, and usage information. Designed to help both humans and AI assistants
    discover and understand available tools.

OPTIONS
    --help, -h
        Display this help message and exit
    
    --verbose, -v
        Show detailed information including full help text for each tool

USAGE FOR AI ASSISTANTS
    To discover available tools and their purposes, run:
        jk-tools
    
    To get detailed help for a specific tool, run:
        <tool-name> --help
    
    All tools follow consistent conventions:
    - Accept --help flag for detailed documentation
    - Have jk- prefixed aliases for quick access
    - Are designed to be composable and scriptable

AUTHOR
    Part of the jk-tools collection

EOF
}

print_separator() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

get_tool_description() {
  local tool="$1"
  local desc=""
  
  # Try to extract description from the tool's help text
  if [[ -x "$tool" ]]; then
    # Try running with --help and extract the NAME section
    if desc=$("$tool" --help 2>/dev/null | grep -A1 "^NAME" | tail -1 | sed 's/^[[:space:]]*//'); then
      # Remove the tool name prefix if present
      desc=$(echo "$desc" | sed "s/^$(basename "$tool")[[:space:]]*-[[:space:]]*//")
      echo "$desc"
    else
      echo "No description available"
    fi
  else
    echo "Not executable"
  fi
}

get_tool_alias() {
  local tool_name="$1"
  local alias=""
  
  # Check if aliases file exists and extract alias for this tool
  if [[ -f "$HOME/.tools_aliases" ]]; then
    # Look for alias that points to this tool
    alias=$(grep -E "alias jk-.*='.*${tool_name}'" "$HOME/.tools_aliases" 2>/dev/null | \
            sed -n "s/^alias \(jk-[^=]*\)=.*/\1/p" | head -1)
  fi
  
  echo "${alias:-none}"
}

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      show_help
      exit 0
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# Main execution
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                          JK-TOOLS COLLECTION                                  ║"
echo "║                    Available Tools and Utilities                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo

# Count tools
TOOL_COUNT=$(find "$SCRIPT_DIR" -maxdepth 1 -type f -perm +111 2>/dev/null | wc -l | tr -d ' ')
echo "Found $TOOL_COUNT executable tool(s) in: $SCRIPT_DIR"
echo

print_separator

# List all executable files in the scripts directory
for tool in "$SCRIPT_DIR"/*; do
  if [[ -f "$tool" && -x "$tool" ]]; then
    tool_name=$(basename "$tool")
    
    # Skip this script itself
    if [[ "$tool_name" == "$SCRIPT_NAME" ]]; then
      continue
    fi
    
    echo
    echo "📦 TOOL: $tool_name"
    echo "   Path: $tool"
    
    # Get alias
    alias=$(get_tool_alias "$tool_name")
    if [[ "$alias" != "none" ]]; then
      echo "   Alias: $alias"
    fi
    
    # Get description
    desc=$(get_tool_description "$tool")
    echo "   Description: $desc"
    
    # Show usage hint
    echo "   Usage: $tool_name --help for detailed information"
    
    # In verbose mode, show the full help
    if [[ "$VERBOSE" == true ]]; then
      echo
      echo "   Full Help:"
      echo "   ─────────"
      if "$tool" --help 2>/dev/null; then
        "$tool" --help 2>/dev/null | sed 's/^/   /'
      else
        echo "   (Help not available - tool may not support --help flag)"
      fi
    fi
    
    echo
    print_separator
  fi
done

# If no tools found
if [[ $TOOL_COUNT -eq 1 ]]; then  # 1 because we skip jk-tools itself
  echo
  echo "ℹ️  No additional tools found."
  echo "   Add executable scripts to $SCRIPT_DIR to make them available."
  echo
  print_separator
fi

echo
echo "💡 TIPS FOR AI ASSISTANTS:"
echo "   • All tools accept --help for detailed documentation"
echo "   • Tools with dashes in names have jk- prefixed aliases"
echo "   • Tools are designed to be chainable in unix pipelines"
echo "   • Output directories should typically use ./scratch/ for temporary files"
echo
echo "📚 For more information: https://github.com/yourusername/tools"
echo