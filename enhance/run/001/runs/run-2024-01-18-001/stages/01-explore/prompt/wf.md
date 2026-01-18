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

## Required Output Templates

### wf-result.json (REQUIRED)

Write to `../run/output-data/wf-result.json`:

```json
{
  "status": "success | failure | partial",
  "completed_at": "ISO-8601 timestamp",
  "stage_id": "01-explore",
  "error": null,
  "metrics": {
    "findings_count": 0,
    "critical_findings": 0,
    "flowspace_used": true
  }
}
```

**Fields:**
| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `status` | Yes | enum | `success`, `failure`, or `partial` |
| `completed_at` | Yes | string | ISO-8601 timestamp |
| `stage_id` | Yes | string | Stage identifier from stage-config.json |
| `error` | Yes | string/null | Error message if status != success, else null |
| `metrics` | Yes | object | Stage-specific metrics (schema varies by stage) |

### findings.json (Stage-Specific)

Write to `../run/output-data/findings.json`:

```json
{
  "findings": [
    {
      "id": "IA-01",
      "category": "implementation | dependency | pattern | quality | interface | documentation | prior_learning",
      "impact": "critical | high | medium | low",
      "title": "Short title",
      "summary": "One-line summary",
      "node_id": "optional:path:name",
      "references": ["file:line", "file:line"]
    }
  ],
  "summary": {
    "total": 0,
    "by_impact": {"critical": 0, "high": 0, "medium": 0, "low": 0},
    "by_category": {}
  }
}
```

### manifest.json (Runtime Tracking)

Write to `../run/runtime-inputs/manifest.json`:

```json
{
  "files_read": [
    {"path": "relative/path", "read_at": "ISO-8601", "purpose": "description"}
  ],
  "codebase_files_examined": 0,
  "flowspace_queries": 0
}
```

---

**Now**: Read `../stage-config.json`, then `../inputs/user-description.md`, then return here and proceed to `main.md`.
