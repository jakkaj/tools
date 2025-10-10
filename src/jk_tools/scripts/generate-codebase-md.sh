#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# Script name for help text
SCRIPT_NAME="$(basename "$0")"

show_help() {
  cat << EOF
NAME
    $SCRIPT_NAME - Generate markdown documentation from codebases for LLM consumption

SYNOPSIS
    $SCRIPT_NAME <output-dir> [paths...]
    $SCRIPT_NAME --help

DESCRIPTION
    Converts a codebase into markdown format optimized for Large Language Model (LLM) 
    prompts. Uses code2prompt to generate a structured markdown file containing all 
    specified source code, along with a separate file tracking git changes.

    This tool is essential for:
    - Sharing entire codebases with AI assistants
    - Code review and analysis by LLMs
    - Documentation generation
    - Codebase exploration and understanding

PARAMETERS
    output-dir
        Required. Directory where output files will be created.
        Two files are generated:
        - codebase.md: Complete code listing in markdown
        - changes.md: Git diff since HEAD (if in a git repo)

    paths
        Optional. Files or directories to include.
        - Defaults to current directory (.) if not specified
        - Directories are processed recursively
        - Multiple paths can be specified
        - Supports glob patterns

OPTIONS
    --help
        Display this help message and exit

EXAMPLES
    # Generate markdown for current directory
    $SCRIPT_NAME ./output

    # Generate markdown for specific directories
    $SCRIPT_NAME ./docs ./src ./lib

    # Generate markdown for specific file types
    $SCRIPT_NAME ./output "*.py" "*.js"

    # Generate from another project
    cd ~/projects/myapp && $SCRIPT_NAME /tmp/myapp-docs

OUTPUT
    The tool creates two files in the specified output directory:
    
    1. codebase.md - Contains:
       - Project structure tree
       - Full source code of all included files
       - Syntax highlighting based on file extensions
    
    2. changes.md - Contains:
       - Git diff output showing uncommitted changes
       - Useful for code review contexts

REQUIREMENTS
    - code2prompt must be installed (install via: cargo install code2prompt)
    - For changes.md: must be run within a git repository

ALIAS
    jk-gcm - Shortened alias available after running setup

NOTES
    The following categories of files are automatically excluded to maximize signal-to-noise ratio:
    
    Build/Dependencies: node_modules, build, dist, target, .next
    Lock files: package-lock.json, yarn.lock, Cargo.lock, poetry.lock, go.sum, etc.
    IDE files: .idea, .vscode, *.swp
    Coverage: coverage/, .nyc_output/, *.lcov
    Compiled: *.min.js, *.min.css, *.map
    System: .git, .DS_Store, *.pyc, __pycache__, .cache, *.log

AUTHOR
    Part of the jk-tools collection
    Repository: https://github.com/yourusername/tools

EOF
}

# Show help if requested
if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  show_help
  exit 0
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

# Build comprehensive exclude patterns
# These patterns filter out generated artifacts and files that don't contain human-written code
EXCLUDE_PATTERNS=(
  # Version control
  "**/.git/**"
  
  # Build outputs and dependencies
  "**/node_modules/**"
  "**/build/**"
  "**/dist/**"
  "**/target/**"
  "**/.next/**"
  
  # Lock files (auto-generated dependency trees)
  "**/package-lock.json"
  "**/yarn.lock"
  "**/pnpm-lock.yaml"
  "**/Cargo.lock"
  "**/Gemfile.lock"
  "**/poetry.lock"
  "**/composer.lock"
  "**/Pipfile.lock"
  "**/go.sum"
  "**/pubspec.lock"
  
  # IDE and editor files
  "**/.idea/**"
  "**/.vscode/**"
  "**/*.swp"
  "**/*.swo"
  "**/~*"
  
  # Test coverage and artifacts
  "**/coverage/**"
  "**/.nyc_output/**"
  "**/htmlcov/**"
  "**/*.lcov"
  "**/.coverage"
  "**/.pytest_cache/**"
  "**/.phpunit.result.cache"
  
  # Compiled and minified files
  "**/*.min.js"
  "**/*.min.css"
  "**/*.map"
  
  # Python artifacts
  "**/*.pyc"
  "**/__pycache__/**"
  
  # Environment and logs
  "**/.env.local"
  "**/.env.*.local"
  "**/*.log"
  "**/logs/**"
  
  # Cache directories
  "**/.cache/**"
  
  # System files
  "**/.DS_Store"
  "**/Thumbs.db"
)

# Join exclude patterns with commas
exclude_patterns=$(IFS=, ; echo "${EXCLUDE_PATTERNS[*]}")

# Generate markdown using code2prompt
code2prompt . \
  --include="$include_patterns" \
  --exclude="$exclude_patterns" \
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