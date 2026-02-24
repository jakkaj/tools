---
description: Update plan progress with task status and domain context. V2 standalone rewrite.
---

# plan-6a-v2-update-progress

Update plan and dossier progress tracking with task status. Adds domain context to change tracking.

```md
User input:

$ARGUMENTS
# Expected flags:
# --plan "<abs path to plan.md>"
# --task "<task ID, e.g., T001>"
# --status "completed|in_progress|blocked"
# --changes "file1.md,file2.sh" (files changed)
# --domain "<domain slug>" (optional — inferred from task table if not provided)
# Optional:
# --phase "<Phase N: Title>" (Full Mode)
# --subtask "<subtask-key>" (if updating subtask)
# --inline (Simple Mode — update inline task table in plan)

## Steps

1) Resolve paths:
   - PLAN, PLAN_DIR from --plan
   - If --inline: update task table within PLAN itself
   - If --phase: locate dossier at PLAN_DIR/tasks/${PHASE_SLUG}/tasks.md
   - If --subtask: locate subtask dossier

2) Parse --changes as a list of changed file paths.

3) Determine domain:
   - If --domain provided, use it
   - Otherwise, read task table and extract Domain column for the task
   - If no domain found, use "unknown"

4) Update task status:
   - In task table (dossier or inline): update Status column
     * `completed` → `[x]`
     * `in_progress` → `[~]`
     * `blocked` → `[!]`
   - Update Architecture Map nodes if present

5) Update progress tracking in PLAN:
   - Locate progress section
   - Update phase/task status

6) Record changes with domain context:
   - Log which domain(s) were affected and what changed
   - Note any new components added to domain composition
   - Note any contract changes
   - Flag if `docs/domains/domain-map.md` needs updating (new contracts, new edges, new domains)

7) Report what was updated.
```

This command is the **single source of truth** for progress updates. Always delegate progress tracking to this command rather than manually editing task tables.
