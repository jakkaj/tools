# Manual End-to-End Workflow Test

**Purpose**: Validate the complete chainglass workflow system by executing a 2-stage workflow (explore → specify) with a real coding agent.

**Workflow Under Test**: `sample_1` (Codebase Research → Feature Specification)

---

## Prerequisites

```bash
cd /Users/jordanknight/github/tools/enhance
```

Ensure chainglass CLI is installed:
```bash
uv run chainglass --version
```

---

## Phase 1: Explore Stage

### Step 1.1: Compose the Workflow

Run the compose script to create a fresh run folder:

```bash
./docs/plans/010-first-wf-build/manual-test/01-start-explore.sh
```

**Expected Output**:
- Creates `sample/sample_1/runs/run-YYYY-MM-DD-NNN/`
- Outputs the starter prompt with the exact path

**Save the RUN_DIR path** - you'll need it for all subsequent commands.

---

### Step 1.2: Run Preflight (Expected FAIL)

The agent's first action from the starter prompt will be to run preflight:

```bash
chainglass preflight explore --run-dir <RUN_DIR>
```

**Expected Result**: `FAIL` - Missing `inputs/user-description.md`

```
Preflight failed:
  INPUT_EXISTS: inputs/user-description.md
    Action: Create this file with: User-provided research query or feature description
Result: FAIL (3 passed, 1 errors)
```

**This is intentional** - we're testing that preflight catches missing inputs.

---

### Step 1.3: Create the Required Input (Manual Fix)

Create the user description file:

```bash
cat > <RUN_DIR>/stages/explore/inputs/user-description.md << 'EOF'
Research the chainglass CLI workflow system. Focus on:

1. How the compose command creates run folders from wf-spec
2. How preflight validates inputs before stage execution
3. How validate checks outputs after stage execution
4. How finalize extracts output parameters for downstream stages

Provide findings about the validation patterns and data flow.
EOF
```

---

### Step 1.4: Run Preflight Again (Expected PASS)

```bash
chainglass preflight explore --run-dir <RUN_DIR>
```

**Expected Result**: `PASS`

```
Preflight: explore
Checks passed:
  stage-config.yaml
  prompt/wf.md
  prompt/main.md
  inputs/user-description.md (user-description.md)
Result: PASS (4 checks, 0 errors)
```

---

### Step 1.5: Execute the Stage (Agent Work)

Give the starter prompt to the coding agent. The agent will:

1. Run preflight (now passes)
2. Read stage-config.yaml
3. Read inputs/user-description.md
4. Read prompt/main.md
5. Execute the research task
6. Write outputs to run/output-files/ and run/output-data/
7. Run validate to check outputs

**Agent Prompt** (copy from script output or use):
```
Read the file at <RUN_DIR>/stages/explore/prompt/wf.md and follow its instructions.
```

---

### Step 1.6: Validate Outputs (Agent Action)

The agent should run validate as its final step:

```bash
chainglass validate explore --run-dir <RUN_DIR>
```

**Expected Result**: `PASS` with all outputs present and valid

---

## Phase 2: Specify Stage

### Step 2.1: Transition to Specify

After the agent completes explore, run the transition script:

```bash
./docs/plans/010-first-wf-build/manual-test/02-transition-to-specify.sh <RUN_DIR>
```

**What This Does**:
1. `finalize explore` - Extracts output parameters, writes output-params.json
2. `prepare-wf-stage specify` - Copies inputs from explore outputs
3. `preflight specify` - Courtesy check (should PASS)
4. Outputs the prompt for specify stage

---

### Step 2.2: Execute Specify Stage (Agent Work)

Give the specify prompt to the coding agent. The agent will:

1. Run preflight (should pass - inputs were copied)
2. Read stage-config.yaml
3. Read inputs (including research-dossier.md from explore)
4. Read prompt/main.md
5. Write the feature specification
6. Run validate

---

### Step 2.3: Validate Specify Outputs

```bash
chainglass validate specify --run-dir <RUN_DIR>
```

**Expected Result**: `PASS`

---

## Post-Test Forensic Analysis

After both stages complete successfully, examine:

### Run Folder Structure
```bash
tree <RUN_DIR>
```

### Stage Outputs
```bash
# Explore outputs
cat <RUN_DIR>/stages/explore/run/output-data/wf-result.json
cat <RUN_DIR>/stages/explore/run/output-data/output-params.json
cat <RUN_DIR>/stages/explore/run/output-files/research-dossier.md

# Specify outputs
cat <RUN_DIR>/stages/specify/run/output-data/wf-result.json
cat <RUN_DIR>/stages/specify/run/output-files/feature-spec.md
```

### Input Provenance
```bash
# Check what the agent read during explore
cat <RUN_DIR>/stages/explore/run/runtime-inputs/read-files.json

# Check inputs copied to specify
ls -la <RUN_DIR>/stages/specify/inputs/
```

### Workflow State
```bash
cat <RUN_DIR>/wf-run.json
```

---

## Test Scenarios

### Happy Path (Default)
1. Compose → Preflight fails → Fix input → Preflight passes → Execute → Validate → Finalize → Prepare next → Execute → Validate

### Error Scenarios to Test

**Missing Input**:
- Don't create user-description.md
- Preflight should fail with actionable error

**Invalid JSON Output**:
- Have agent write malformed JSON
- Validate should fail with schema error

**Unfinalized Source Stage**:
- Try to run specify preflight before finalizing explore
- Should fail with "Source stage not finalized" error

**Path Traversal Attempt**:
- Manually edit stage-config.yaml with `source: "../../../etc/passwd"`
- Preflight should fail with path_security error

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `chainglass compose <wf-spec> -o <output>` | Create run folder |
| `chainglass preflight <stage> -r <run-dir>` | Validate inputs |
| `chainglass validate <stage> -r <run-dir>` | Validate outputs |
| `chainglass finalize <stage> -r <run-dir>` | Extract params, mark complete |
| `chainglass prepare-wf-stage <stage> -r <run-dir>` | Copy inputs from prior stages |
