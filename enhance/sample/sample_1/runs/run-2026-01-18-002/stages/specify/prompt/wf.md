# Workflow Stage Execution

You are executing a **workflow stage**. This means you are operating within a structured workflow system that provides inputs and expects specific outputs.

## Before You Begin

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
3. Run `chainglass validate` on this stage
   - Validates all outputs exist and conform to schemas
   - If `output_parameters` are declared, extracts and writes `output-params.json`
   - These values become available to downstream stages by name
4. Stop and wait - the workflow system handles what comes next

## Output Schemas

Each output declared in `stage-config.yaml` has a corresponding JSON Schema in `../schemas/`. Read the schema files to understand the exact structure required for each output.

---

**Now**: Read `../stage-config.yaml`, then `../inputs/*`, then return here and proceed to `main.md`.
