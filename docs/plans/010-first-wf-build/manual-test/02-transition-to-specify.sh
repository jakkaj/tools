#!/bin/bash
# 02-transition-to-specify.sh - Finalize explore and prepare specify stage
#
# Usage: ./02-transition-to-specify.sh <RUN_DIR>
#
# Performs the between-stage transition:
# 1. Finalize explore (extract output params)
# 2. Prepare specify (copy inputs from explore)
# 3. Preflight specify (courtesy check)
# 4. Output starter prompt for specify

set -e

if [ -z "$1" ]; then
    echo "Usage: ./02-transition-to-specify.sh <RUN_DIR>"
    echo ""
    echo "Example:"
    echo "  ./02-transition-to-specify.sh /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2026-01-19-003"
    exit 1
fi

RUN_DIR="$1"
ENHANCE_DIR="/Users/jordanknight/github/tools/enhance"

cd "$ENHANCE_DIR"

echo "=============================================="
echo "  Chainglass Manual Test - Transition to Specify"
echo "=============================================="
echo ""
echo "RUN_DIR: $RUN_DIR"
echo ""

# Step 1: Finalize explore
echo "----------------------------------------------"
echo "  Step 1: Finalize Explore Stage"
echo "----------------------------------------------"
echo ""
echo "Running: chainglass finalize explore --run-dir $RUN_DIR"
echo ""

if ! uv run chainglass finalize explore --run-dir "$RUN_DIR"; then
    echo ""
    echo "ERROR: Finalize failed. Ensure explore stage outputs are valid."
    echo "Try running: chainglass validate explore --run-dir $RUN_DIR"
    exit 1
fi

echo ""
echo "Explore finalized. Output parameters extracted."
echo ""

# Show extracted parameters
echo "Extracted parameters:"
cat "$RUN_DIR/stages/explore/run/output-data/output-params.json" | head -20
echo ""

# Step 2: Prepare specify
echo "----------------------------------------------"
echo "  Step 2: Prepare Specify Stage"
echo "----------------------------------------------"
echo ""
echo "Running: chainglass prepare-wf-stage specify --run-dir $RUN_DIR"
echo ""

if ! uv run chainglass prepare-wf-stage specify --run-dir "$RUN_DIR"; then
    echo ""
    echo "ERROR: Prepare failed."
    exit 1
fi

echo ""
echo "Inputs copied to specify stage."
echo ""

# Show what was copied
echo "Inputs available to specify:"
ls -la "$RUN_DIR/stages/specify/inputs/" 2>/dev/null || echo "(no inputs directory)"
echo ""

# Step 3: Preflight specify (courtesy check)
echo "----------------------------------------------"
echo "  Step 3: Preflight Specify Stage"
echo "----------------------------------------------"
echo ""
echo "Running: chainglass preflight specify --run-dir $RUN_DIR"
echo ""

if ! uv run chainglass preflight specify --run-dir "$RUN_DIR"; then
    echo ""
    echo "WARNING: Preflight failed. Check the errors above."
    echo "The agent will see these same errors and should fix them."
    echo ""
fi

PROMPT_PATH="$RUN_DIR/stages/specify/prompt/wf.md"

echo ""
echo "=============================================="
echo "  STARTER PROMPT FOR SPECIFY (copy below)"
echo "=============================================="
echo ""
cat << EOF
# Workflow Stage Execution

You are executing a workflow stage. Read the bootstrap instructions and follow them exactly.

**Start here**: \`$PROMPT_PATH\`

Read that file and follow its instructions. The file will guide you through:
1. Running preflight to validate inputs
2. Reading the stage configuration
3. Reading your inputs (including research-dossier.md from explore)
4. Executing the stage work
5. Validating your outputs

Do not deviate from the workflow instructions. Complete each step before moving to the next.
EOF
echo ""
echo "=============================================="
echo ""
echo "After the agent completes specify, examine the outputs:"
echo ""
echo "  # Workflow state"
echo "  cat $RUN_DIR/wf-run.json"
echo ""
echo "  # Specify outputs"
echo "  cat $RUN_DIR/stages/specify/run/output-data/wf-result.json"
echo "  cat $RUN_DIR/stages/specify/run/output-files/feature-spec.md"
echo ""
echo "  # Full tree"
echo "  tree $RUN_DIR"
echo ""
