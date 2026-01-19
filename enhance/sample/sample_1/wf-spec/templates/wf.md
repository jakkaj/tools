# Workflow Stage Execution

You are executing a **workflow stage**. This means you are operating within a structured workflow system that provides inputs and expects specific outputs.

## Before You Begin

0. **Preflight check** (verify stage is ready to execute):
   ```bash
   uv run chainglass preflight <stage_id> --run-dir <path_to_run_folder>
   ```

   Example (if you're in the prompt folder):
   ```bash
   uv run chainglass preflight explore --run-dir ../../
   ```

   **What it checks**:
   - Stage configuration is valid
   - Prompt files exist (wf.md, main.md)
   - Required input files exist and are non-empty
   - Source stages are finalized (for inputs from upstream stages)
   - Parameters can be resolved from upstream outputs

   **If preflight fails**: **STOP IMMEDIATELY.** Do not attempt to work around the error or find alternatives. Report the exact error to the user and wait for them to fix it. The preflight errors are actionable - they tell the user exactly what's missing. Do not proceed until preflight passes.

   **On success**: All prerequisites are met - proceed to step 1.

1. **Read the stage configuration**: `../stage-config.yaml`
   - This defines what inputs are available to you
   - This defines what outputs you must produce
   - Note any stage-specific metadata

2. **Read your inputs**: Check the `../inputs/` directory
   - Read all files declared in stage-config.yaml inputs
   - These are your working materials for this stage

3. **Load your main instructions**: `main.md` (in this same directory)
   - This contains the detailed prompt for this stage's work
   - Follow its instructions completely

## Your Workflow

```
0. Run preflight                 → Verify prerequisites
1. Read ../stage-config.yaml     → Understand the contract
2. Read ../inputs/*              → Get your inputs
3. Read ./main.md                → Get your instructions
4. Execute the stage work        → Follow main.md
5. Write outputs to ../run/      → Complete the contract
```

## Output Locations

All outputs go under `../run/`:

- **Documents**: `../run/output-files/`
  - Your primary deliverables (reports, analyses, documentation)

- **Structured Data**: `../run/output-data/`
  - `wf-result.json` - Stage completion status (REQUIRED)
  - Any other structured data outputs

- **Runtime Tracking**: `../run/runtime-inputs/`
  - Write `read-files.json` **as you work** (not just at the end)
  - Log every file you READ from the codebase or inputs
  - This creates an audit trail: "what inputs influenced this stage's outputs"
  - See `../schemas/read-files.schema.json` for the format
  - Example entry (append each time you read a file):
    ```json
    {"path": "/abs/path/to/file.py", "timestamp": "2026-01-18T10:02:00Z", "purpose": "Examine auth logic", "lines": "all"}
    ```

## Stage Completion

When your work is complete:

1. Ensure all declared outputs in `stage-config.yaml` are written
2. Write `wf-result.json` with completion status
3. **Validate your stage outputs**:
   ```bash
   uv run chainglass validate <stage_id> --run-dir <path_to_run_folder>
   ```

   Example (if you're in the prompt folder):
   ```bash
   uv run chainglass validate explore --run-dir ../../
   ```

   **What it checks**:
   - All required output files exist
   - No output files are empty (0 bytes)
   - JSON outputs conform to their declared schemas
   - Output parameters can be extracted

   **If validation fails**: Fix the reported errors before proceeding. The error messages are actionable - they tell you exactly what's missing or malformed. Re-run validate after each fix until you get `PASS`.

   **On success**: Validation writes `output-params.json` with extracted parameters that become available to downstream stages by name.

4. Stop and wait - the workflow system handles what comes next

## Output Schemas

Each output declared in `stage-config.yaml` has a corresponding JSON Schema in `../schemas/`. Read the schema files to understand the exact structure required for each output.

---

**Now**: Run `uv run chainglass preflight <stage_id> --run-dir ../../` first. On success, read `../stage-config.yaml`, then `../inputs/*`, then return here and proceed to `main.md`.
