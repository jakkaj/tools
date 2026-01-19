#!/bin/bash
# 01-start-explore.sh - Compose workflow and output explore stage prompt
#
# Usage: ./01-start-explore.sh
#
# Creates a fresh run folder from sample_1/wf-spec and outputs the
# starter prompt with the correct path for the explore stage.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENHANCE_DIR="/Users/jordanknight/github/tools/enhance"
WF_SPEC="$ENHANCE_DIR/sample/sample_1/wf-spec"
OUTPUT_DIR="$ENHANCE_DIR/sample/sample_1/runs"

cd "$ENHANCE_DIR"

echo "=============================================="
echo "  Chainglass Manual Test - Start Explore"
echo "=============================================="
echo ""

# Run compose
echo "Running: chainglass compose $WF_SPEC -o $OUTPUT_DIR"
echo ""

OUTPUT=$(uv run chainglass compose "$WF_SPEC" -o "$OUTPUT_DIR" 2>&1)
echo "$OUTPUT"
echo ""

# Extract the run folder path from output
# Looking for line like "Created: /path/to/runs/run-2026-01-19-003"
RUN_DIR=$(echo "$OUTPUT" | grep -o "Created: [^ ]*" | sed 's/Created: //')

if [ -z "$RUN_DIR" ]; then
    echo "ERROR: Could not extract run folder path from compose output"
    exit 1
fi

# Make path absolute if relative
if [[ "$RUN_DIR" == ./* ]]; then
    RUN_DIR="$ENHANCE_DIR/${RUN_DIR#./}"
fi

PROMPT_PATH="$RUN_DIR/stages/explore/prompt/wf.md"
INPUT_FILE="$RUN_DIR/stages/explore/inputs/user-description.md"

# Copy sample user description to inputs
echo "Copying sample user description to inputs..."
cp "$SCRIPT_DIR/sample-user-description.md" "$INPUT_FILE"

echo "=============================================="
echo "  Run Created Successfully"
echo "=============================================="
echo ""
echo "RUN_DIR: $RUN_DIR"
echo ""

# Run preflight to verify
echo "Running preflight check..."
echo ""
uv run chainglass preflight explore --run-dir "$RUN_DIR"
echo ""
echo "=============================================="
echo "  STARTER PROMPT (copy below)"
echo "=============================================="
echo ""
cat << EOF
# Workflow Stage Execution

You are executing a workflow stage. Read the bootstrap instructions and follow them exactly.

**Start here**: \`$PROMPT_PATH\`

Read that file and follow its instructions. The file will guide you through:
1. Running preflight to validate inputs
2. Reading the stage configuration
3. Reading your inputs
4. Executing the stage work
5. Validating your outputs

Do not deviate from the workflow instructions. Complete each step before moving to the next.
EOF
echo ""
echo "=============================================="
echo ""
echo "After the agent completes explore, run:"
echo ""
echo "  ./02-transition-to-specify.sh $RUN_DIR"
echo ""
