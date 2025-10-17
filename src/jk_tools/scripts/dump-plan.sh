#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# Script name for help text
SCRIPT_NAME="$(basename "$0")"

show_help() {
  cat << EOF
NAME
    $SCRIPT_NAME - Dump plan directory for LLM handoff (flat structure + markdown)

SYNOPSIS
    $SCRIPT_NAME <source-dir> [output-dir] [options]
    $SCRIPT_NAME --help

DESCRIPTION
    Prepares plan directories for easy handoff to LLM coding agents by:
    1. Flattening the directory tree into a single-level structure
    2. Generating codebase.md and changes.md via jk-gcm (if available)
    3. Creating an easy-to-upload package of all plan files

    Files maintain their identity through path-based naming (subdirectory
    paths are converted to dash-separated prefixes).

    PRIMARY USE CASE:
    AI assistants can dump plan directories into a flat structure that's
    ready to select all files and upload to an LLM coding agent. This
    eliminates nested directories and provides markdown summaries.

    This tool is also useful for:
    - Preparing any directory tree for LLM consumption
    - Creating flat snapshots of nested project structures
    - Consolidating related files for sharing

PARAMETERS
    source-dir
        Required. Directory to dump/flatten (processes recursively).
        Can be absolute or relative path.
        Examples: ./docs/plans/feature-x, ./src, ~/project

    output-dir
        Optional. Where to write flattened files.
        Defaults to:
        - scratch/dumps/<source-dir-name>/ if scratch/ exists
        - /tmp/dump-<source-dir-name>/ otherwise

OPTIONS
    --no-gcm
        Skip running jk-gcm on the output directory.
        By default, jk-gcm is run to generate codebase.md and changes.md.

    --help
        Display this help message and exit

EXAMPLES
    # Dump a plan directory for LLM handoff (typical AI usage)
    $SCRIPT_NAME ./docs/plans/8-debug-script-bake-in

    # Dump to a specific output directory
    $SCRIPT_NAME ./docs/plans/feature-x ./output/handoff

    # Dump without generating markdown files
    $SCRIPT_NAME ./docs/plans/feature-x --no-gcm

    # Dump any directory tree
    $SCRIPT_NAME ./src/components

OUTPUT
    Files are copied with path-based flattening:
    - source/foo.txt          → foo.txt
    - source/sub/bar.md       → sub-bar.md
    - source/a/b/c/file.json  → a-b-c-file.json

    If jk-gcm is available and not disabled:
    - codebase.md: Complete flattened directory in markdown
    - changes.md: Git diff if source is in a git repo

    Result: A flat directory ready for "select all → upload to LLM agent"

FILENAME CONFLICTS
    Conflicts are resolved by appending numeric suffixes:
    - First occurrence:  filename.txt
    - Second occurrence: filename-2.txt
    - Third occurrence:  filename-3.txt

REQUIREMENTS
    - bash (any recent version)
    - Standard Unix tools (cp, mkdir, find)
    - Optional: jk-gcm (for markdown generation)

ALIAS
    jk-dp - Shortened alias available after running setup

NOTES
    - Source directory is not modified
    - Output directory is cleared if it already exists
    - Preserves file modification times
    - Symbolic links are followed and copied as regular files
    - Perfect for AI-to-AI handoffs: dump → select all → upload

AUTHOR
    Part of the jk-tools collection
    Repository: https://github.com/yourusername/tools

EOF
}

# Show help if requested or no arguments
if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  show_help
  exit 0
fi

# Parse arguments
SOURCE_DIR=""
OUTPUT_DIR=""
RUN_GCM=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-gcm)
      RUN_GCM=false
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      if [[ -z "$SOURCE_DIR" ]]; then
        SOURCE_DIR="$1"
      elif [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$1"
      else
        echo "Error: Unexpected argument: $1" >&2
        echo "Run '$SCRIPT_NAME --help' for usage information" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Validate source directory
if [[ -z "$SOURCE_DIR" ]]; then
  echo "Error: source-dir is required" >&2
  echo "Run '$SCRIPT_NAME --help' for usage information" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Source directory does not exist: $SOURCE_DIR" >&2
  exit 1
fi

# Convert to absolute path
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
SOURCE_NAME="$(basename "$SOURCE_DIR")"

# Determine output directory if not specified
if [[ -z "$OUTPUT_DIR" ]]; then
  if [[ -d "scratch/dumps" ]]; then
    OUTPUT_DIR="scratch/dumps/$SOURCE_NAME"
  else
    OUTPUT_DIR="/tmp/dump-$SOURCE_NAME"
  fi
fi

# Create output directory (clear if exists)
if [[ -d "$OUTPUT_DIR" ]]; then
  echo "🧹 Clearing existing output directory: $OUTPUT_DIR"
  rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

echo "════════════════════════════════════════"
echo "  Directory Flattening Tool"
echo "════════════════════════════════════════"
echo "Source:      $SOURCE_DIR"
echo "Output:      $OUTPUT_DIR"
echo "Run jk-gcm:  $RUN_GCM"
echo ""

# Find all files in source directory
echo "📂 Scanning source directory..."
file_count=0

# Create a temporary file to track filename counts (bash 3 compatible)
counts_file=$(mktemp)
trap "rm -f $counts_file" EXIT

# Process files
while IFS= read -r -d '' source_file; do
  # Get relative path from source directory
  rel_path="${source_file#$SOURCE_DIR/}"

  # If file is at root of source, use original name
  if [[ "$rel_path" != *"/"* ]]; then
    flat_name="$(basename "$source_file")"
  else
    # Convert path to dash-separated name
    dir_part="$(dirname "$rel_path")"
    file_part="$(basename "$rel_path")"

    # Replace slashes with dashes
    path_prefix="${dir_part//\//-}"
    flat_name="${path_prefix}-${file_part}"
  fi

  # Handle filename conflicts using temp file
  if grep -q "^${flat_name}$" "$counts_file" 2>/dev/null; then
    # Conflict detected - count existing occurrences
    count=$(grep -c "^${flat_name}$" "$counts_file")
    count=$((count + 1))

    # Insert suffix before extension
    if [[ "$flat_name" == *.* ]]; then
      base="${flat_name%.*}"
      ext="${flat_name##*.}"
      flat_name="${base}-${count}.${ext}"
    else
      flat_name="${flat_name}-${count}"
    fi
  fi

  # Record this filename
  echo "$flat_name" >> "$counts_file"

  # Copy file
  cp -p "$source_file" "$OUTPUT_DIR/$flat_name"
  echo "  Copied: $rel_path → $flat_name"
  ((file_count++))
done < <(find "$SOURCE_DIR" -type f -print0)

echo ""
echo "✅ Copied $file_count file(s)"

# Run jk-gcm if enabled and available
if [[ "$RUN_GCM" == true ]]; then
  if command -v jk-gcm &> /dev/null; then
    echo ""
    echo "📝 Running jk-gcm on output directory..."
    jk-gcm "$OUTPUT_DIR"
  else
    echo ""
    echo "ℹ️  jk-gcm not found - skipping markdown generation"
    echo "   (Install via setup.sh to enable this feature)"
  fi
fi

echo ""
echo "════════════════════════════════════════"
echo "✅ Flattening complete!"
echo ""
echo "📁 Output directory: $OUTPUT_DIR"
echo "📄 Files copied:     $file_count"
echo "════════════════════════════════════════"
