# Workflow Stage Execution

You are executing a **workflow stage**. This means you are operating within a structured workflow system that provides inputs and expects specific outputs.

## Before You Begin

1. **Read the stage configuration**: `../stage-config.json`
   - This defines what inputs are available to you
   - This defines what outputs you must produce
   - Note any stage-specific metadata

2. **Read your inputs**: Check the `../inputs/` directory
   - `user-description.md` - The research query/topic you will investigate
   - Any other files declared in stage-config.json

3. **Load your main instructions**: `main.md` (in this same directory)
   - This contains the detailed prompt for this stage's work
   - Follow its instructions completely

## Your Workflow

```
1. Read ../stage-config.json     → Understand the contract
2. Read ../inputs/*.md           → Get your inputs
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
  - Record what files you actually read during execution

## Stage Completion

When your work is complete:

1. Ensure all declared outputs in `stage-config.json` are written
2. Write `wf-result.json` with completion status
3. Stop and wait - the workflow system handles what comes next

## Output Schemas

Each output declared in `stage-config.json` has a corresponding JSON Schema in `../schemas/`:

| Output | Schema |
|--------|--------|
| `wf-result.json` | `../schemas/wf-result.schema.json` |
| `findings.json` | `../schemas/findings.schema.json` |
| `manifest.json` | `../schemas/manifest.schema.json` |

Read the schema files to understand the exact structure required for each output.

---

**Now**: Read `../stage-config.json`, then `../inputs/user-description.md`, then return here and proceed to `main.md`.
