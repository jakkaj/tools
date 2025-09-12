#!/usr/bin/env bash

# Generate codebase markdown using code2prompt
# Usage: generate-codebase-md.sh <output-dir> [paths...]
#   output-dir: Required. Directory where codebase.md and changes.md will be created
#   paths: Optional. Files/directories to include (defaults to current directory)

set -Eeuo pipefail
IFS=$'\n\t'

# Show usage if no arguments
if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <output-dir> [paths...]" >&2
  echo "  output-dir: Directory for output files (required)" >&2
  echo "  paths: Files/directories to include (optional, defaults to .)" >&2
  exit 1
fi

# First argument is the output directory
OUTPUT_DIR="$1"
shift

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Output files
OUTPUT_FILE="$OUTPUT_DIR/codebase.md"
CHANGES_FILE="$OUTPUT_DIR/changes.md"

# Build include patterns from remaining arguments
INCLUDES_ARRAY=()
if [[ $# -eq 0 ]]; then
  # No paths specified, use current directory recursively
  INCLUDES_ARRAY=("**")
else
  # Process each path argument
  for arg in "$@"; do
    # Normalize path (remove trailing slashes and leading ./)
    path="${arg%/}"
    path="${path#./}"
    
    # If it's a directory and not a glob pattern, add /** for recursion
    if [[ -d "$path" && ! "$path" == *"*"* ]]; then
      INCLUDES_ARRAY+=("$path/**")
    else
      # File or glob pattern - use as-is
      INCLUDES_ARRAY+=("$path")
    fi
  done
fi

# Join include patterns with commas
include_patterns="$(IFS=, ; echo "${INCLUDES_ARRAY[*]}")"

echo "Generating codebase markdown..."
echo "Working directory: $(pwd)"
echo "Output directory: $OUTPUT_DIR"
echo "Include patterns: $include_patterns"

# Generate markdown using code2prompt
# Exclude common build artifacts and system files
code2prompt . \
  --include="$include_patterns" \
  --exclude="**/node_modules/**,**/build/**,**/.git/**,**/.DS_Store,**/*.pyc,**/__pycache__/**,**/dist/**,**/.next/**,**/.cache/**,**/target/**" \
  --output-file "$OUTPUT_FILE"

echo "✅ Generated codebase markdown: $OUTPUT_FILE"

# Generate git changes if in a git repository
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  {
    echo '# Changes since HEAD'
    echo
    echo '```diff'
    git --no-pager diff HEAD 2>/dev/null || echo "No changes"
    echo '```'
  } > "$CHANGES_FILE"
  echo "✅ Generated git changes: $CHANGES_FILE"
else
  echo "ℹ️  Not in a git repository, skipping changes file"
fi

echo
echo "Done! Files created in: $OUTPUT_DIR"