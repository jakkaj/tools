#!/usr/bin/env bash

# Helper script to generate goodbar codebase markdown using code2prompt
# Default behavior: include lib/, test/, and justfile
# Optional: pass 1..N file paths as arguments to only include those files

set -Eeuo pipefail
IFS=$'\n\t'

# Get the script directory (scripts/) and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_FILE="$PROJECT_ROOT/scratch/goodbar-codebase.md"
CHANGES_FILE="$PROJECT_ROOT/scratch/goodbar-changes.md"

cd "$PROJECT_ROOT"

# Determine include patterns
FULL_CODEBASE=false
if [[ $# -gt 0 ]]; then
  # Build comma-separated include patterns relative to project root
  INCLUDES_ARRAY=()
  for arg in "$@"; do
    # Special case: if argument is "." or "./" treat as full codebase generation
    if [[ "$arg" == "." || "$arg" == "./" ]]; then
      # Trigger full codebase generation
      FULL_CODEBASE=true
      break
    fi
    # Convert absolute paths under project root to relative
    if [[ "$arg" = /* ]]; then
      if [[ "$arg" == "$PROJECT_ROOT/"* ]]; then
        rel="${arg#"$PROJECT_ROOT/"}"
      else
        echo "Warning: Skipping path outside project root: $arg" >&2
        continue
      fi
    else
      rel="$arg"
    fi
    # Normalize leading ./ and trailing /
    rel="${rel#./}"
    rel="${rel%/}"
    
    # Skip empty strings after normalization
    if [[ -n "$rel" ]]; then
      # Check if this is a directory that needs glob expansion
      if [[ -d "$PROJECT_ROOT/$rel" && ! "$rel" == *"*"* ]]; then
        # It's a directory and not already a glob pattern - add /** for recursion
        INCLUDES_ARRAY+=("$rel/**")
      else
        # It's a file, glob pattern, or non-existent path - keep as-is
        INCLUDES_ARRAY+=("$rel")
      fi
    fi
  done
  
  # If we have arguments but they were "." or "./", do full generation
  if [[ "$FULL_CODEBASE" == true || ${#INCLUDES_ARRAY[@]} -eq 0 ]]; then
    FULL_CODEBASE=true
  fi
else
  FULL_CODEBASE=true
fi

# Generate based on mode
if [[ "$FULL_CODEBASE" == false ]]; then
  echo "Generating goodbar codebase markdown (partial) for specific files..."
  echo "Project root: $PROJECT_ROOT"
  echo "Output file: $OUTPUT_FILE"
  echo "Changes file: $CHANGES_FILE"
  # Join include patterns with commas
  include_patterns="$(IFS=, ; echo "${INCLUDES_ARRAY[*]}")"

  # Generate markdown for specified files only
  code2prompt . \
    --include="$include_patterns" \
    --exclude="**/build/**,**/.dart_tool/**,**/*.g.dart,**/*.freezed.dart,**/*.gen.dart" \
    --output-file "$OUTPUT_FILE"

  echo "✅ Generated (partial) codebase markdown at: $OUTPUT_FILE"
  echo "📄 Files included: ${INCLUDES_ARRAY[*]}"

  # Generate git changes (always show all changes, not filtered)
  {
    echo '# Changes since HEAD'
    echo
    echo '```diff'
    git --no-pager diff HEAD
    echo '```'
  } > "$CHANGES_FILE"

  echo "✅ Generated git changes markdown at: $CHANGES_FILE"
else
  echo "Generating goodbar codebase markdown (full)..."
  echo "Project root: $PROJECT_ROOT"
  echo "Output file: $OUTPUT_FILE"
  echo "Changes file: $CHANGES_FILE"

  # Use code2prompt to generate markdown with lib, test, and justfile
  # Include Dart files from lib/ and test/ directories, plus justfile
  # Exclude generated/build artifacts
  code2prompt . \
    --include="lib/**/*.dart,test/**/*.dart,justfile" \
    --exclude="**/build/**,**/.dart_tool/**,**/*.g.dart,**/*.freezed.dart,**/*.gen.dart" \
    --output-file "$OUTPUT_FILE"

  echo "✅ Generated codebase markdown at: $OUTPUT_FILE"
  echo "📁 Included directories/files: lib/, test/, justfile"
  echo "🚫 Excluded: build artifacts, generated files"

  # Generate combined staged + unstaged changes since HEAD into a markdown file
  {
    echo '# Changes since HEAD'
    echo
    echo '```diff'
    git --no-pager diff HEAD
    echo '```'
  } > "$CHANGES_FILE"

  echo "✅ Generated git changes markdown at: $CHANGES_FILE"
fi
