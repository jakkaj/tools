---
description: Trace each acceptance criterion through execution flows to verify every file needed is in the task table. Invoked as subagent by plan-5 (phase and subtask modes).
---

Please deep think / ultrathink as this is a nuanced analysis task.

# plan-5c-requirements-flow

Verify **requirements completeness** by tracing each acceptance criterion through the codebase's execution flows. For every AC, walk the full path — from user trigger to final effect — and confirm every file in that path appears in the task table. Flag gaps (files needed but missing from tasks) and orphans (files in tasks that serve no AC).

**Key Characteristics**:
- **Invoked as a subagent** by plan-5 (step 5b in phase mode, step S4 in subtask mode) — not run standalone
- **Requirement-up thinking** — flips perspective from "what does this task need?" to "what does this AC need end-to-end?"
- **Flow-walking** — reads the codebase like a human engineer: follows imports, traces call chains, checks event wiring
- **Gap detection** — the primary deliverable; ensures no file is forgotten
- **FlowSpace-first** with graceful fallback to Explore/Grep/Read

---

## Input (provided by calling command)

The parent command (plan-5, in either phase or subtask mode) passes:

```
PHASE_TITLE     = "Phase 2: Core Implementation" (or subtask summary)
PLAN_PATH       = "/abs/path/docs/plans/NNN-slug/slug-plan.md"
SPEC_PATH       = "/abs/path/docs/plans/NNN-slug/slug-spec.md"
ACCEPTANCE_CRITERIA = [list of ACs from spec, numbered]
TASK_TABLE_FILES = [list of all files from Absolute Path(s) column, deduplicated]
TASK_TABLE       = [the full task table with ID, Task, Absolute Path(s) columns]
```

---

## Execution Flow

### 1) Parse Acceptance Criteria

Read each AC and classify what kind of system behavior it describes:

```
For each AC:
  - What is the USER ACTION or SYSTEM EVENT that triggers this?
    (button click, API call, CLI command, cron job, file change, message received)
  - What is the EXPECTED OUTCOME?
    (data saved, response returned, UI updated, file created, notification sent)
  - What LAYERS does this cross?
    (UI only? UI + API? API + service + data? CLI + filesystem? Event + handler + notification?)
```

This classification determines how deep the flow trace needs to go. A pure UI change needs fewer layers than a full-stack feature.

### 2) FlowSpace Detection

```python
try:
    flowspace.tree(pattern=".", max_depth=1)
    FLOWSPACE_AVAILABLE = True
except:
    FLOWSPACE_AVAILABLE = False
```

### 3) Trace Each AC Through the Codebase

For each acceptance criterion, walk the execution flow end-to-end. This is the core of the command — the agent's reasoning IS the analysis.

**Phase A: Find the Entry Point**

Every AC starts somewhere. Find it:

- **UI trigger**: Search for form handlers, button onClick, event listeners that initiate the behavior
- **API trigger**: Search for route definitions, endpoint registrations (e.g., `app.post('/api/...')`, `@router.get(...)`)
- **CLI trigger**: Search for command registrations, argument parsers, main() dispatch
- **Event trigger**: Search for event listeners, message handlers, webhook receivers, cron registrations
- **Internal trigger**: Search for function calls from other components that initiate this flow

If FlowSpace available: `flowspace.search(pattern="<AC keyword>", mode="semantic")` to find entry points.
If not: Read route files, index files, main entry points. Follow the project's architectural conventions.

**Phase B: Follow the Call Chain Forward**

From the entry point, trace execution through each layer:

```
1. Read the entry point file
2. Identify what it calls (imports, function calls, method invocations)
3. For each call:
   a. Find the target file (follow the import)
   b. Read the target function/method
   c. Does it delegate further? Follow those calls too.
   d. Does it read/write data? Note the data layer files.
   e. Does it emit events? Note event handlers that would fire.
   f. Does it call external services? Note the client/adapter files.
4. Continue until you reach a terminal action:
   - Data written to storage
   - Response sent to caller
   - Event emitted (then trace event handlers too)
   - File written to disk
   - Notification dispatched
```

**Phase C: Trace the Return Path**

Data flows back up too — don't forget:

- **Response rendering**: Does a template or component need updating to show new data?
- **Error handling**: What happens on failure? Which files handle errors at each layer?
- **State updates**: Does the UI need to refresh, invalidate a cache, update local state?
- **Side effects**: Does success trigger other flows? (audit logging, metrics, notifications)

**Phase D: Collect the File List**

For this AC, you now have a list of every file in the execution flow that would need to change. Record:

```
AC[N]:
  - /abs/path/to/entry-point.ts     (trigger: route handler)
  - /abs/path/to/controller.ts      (delegation: validates and calls service)
  - /abs/path/to/service.ts         (business logic: core processing)
  - /abs/path/to/repository.ts      (data: storage interaction)
  - /abs/path/to/model.ts           (data: schema/type definition)
  - /abs/path/to/response.ts        (return: response formatting)
  - /abs/path/to/error-handler.ts   (return: error path handling)
```

### 4) Cross-Reference Against Task Table

For each file in each AC's flow:

```python
for ac in acceptance_criteria:
    for file in ac.flow_files:
        matching_tasks = [t for t in task_table if file in t.absolute_paths]
        if not matching_tasks:
            gaps.append({
                "ac": ac.id,
                "file": file,
                "role_in_flow": "what this file does for this AC",
                "why_needed": "why this file must change for the AC to work"
            })
        else:
            coverage.append({
                "ac": ac.id,
                "file": file,
                "tasks": [t.id for t in matching_tasks]
            })
```

### 5) Detect Orphan Files

Check the reverse direction — are there files in the task table that no AC needs?

```python
all_ac_files = set()
for ac in acceptance_criteria:
    all_ac_files.update(ac.flow_files)

for file in task_table_files:
    if file not in all_ac_files:
        orphans.append({
            "file": file,
            "tasks": [t.id for t in tasks_referencing(file)],
            "assessment": "utility | config | scope-creep | test-infrastructure"
        })
```

Orphans aren't necessarily wrong — utility files, test helpers, and config files often don't map directly to an AC. But flagging them lets the agent consciously assess whether they belong.

### 6) Assess Coverage Completeness

For each AC, determine status:

- **Complete**: Every file in the flow is covered by at least one task
- **Gap**: One or more files in the flow are missing from the task table
- **No Tasks**: No tasks reference any file in this AC's flow (the AC is entirely unaddressed)

---

## Output Format

Return three sections:

### Section 1: Coverage Matrix

```markdown
### Coverage Matrix
| AC | Description | Flow Summary | Files in Flow | Tasks | Status |
|----|-------------|-------------|---------------|-------|--------|
| AC1 | [AC text, abbreviated] | file1 → file2 → file3 | 3 | T001,T002,T003 | ✅ Complete |
| AC2 | [AC text, abbreviated] | file1 → file4 → file5 | 3 | T001 | ⚠️ Gap: file4, file5 |
| AC3 | [AC text, abbreviated] | file6 → file7 | 2 | — | ❌ No tasks |
```

- **Flow Summary**: Abbreviated chain showing key files (use basenames for readability)
- **Files in Flow**: Count of unique files needed for this AC
- **Tasks**: Task IDs that cover files in this AC's flow
- **Status**: ✅ Complete | ⚠️ Gap: [missing files] | ❌ No tasks

### Section 2: Gaps Found

For each gap, provide actionable detail:

```markdown
### Gaps Found

#### AC2: [AC description]
- **Missing file**: `/abs/path/to/file4.ts`
  - **Role in flow**: [What this file does in the execution path]
  - **Why needed**: [Why this file must change for AC2 to work end-to-end]
  - **Suggested action**: Add task to [specific change needed]

- **Missing file**: `/abs/path/to/file5.ts`
  - **Role in flow**: [What this file does]
  - **Why needed**: [Why it must change]
  - **Suggested action**: [What task to add]

#### AC3: [AC description]
- **Entirely unaddressed**: No tasks cover any part of this AC's flow
  - **Flow**: file6 (entry point) → file7 (handler)
  - **Suggested action**: Add tasks for [outline the work needed]
```

If no gaps found:
```markdown
### Gaps Found
No gaps — all acceptance criteria have complete file coverage in the task table.
```

### Section 3: Orphan Files (if any)

```markdown
### Orphan Files
Files in the task table that don't map to any acceptance criterion:

| File | Tasks | Assessment |
|------|-------|------------|
| /abs/path/utils/helper.ts | T005 | Utility — supports multiple ACs indirectly |
| /abs/path/config/settings.ts | T001 | Config — required for setup, no direct AC |
```

If no orphans:
```markdown
### Orphan Files
All task table files map to at least one acceptance criterion.
```

### Section 4: Flow Details (for gaps and complex paths only)

```markdown
### Flow Details

#### AC2: [AC description]
1. `/abs/path/to/file1.ts` — Route handler receives request (T001) ✅
2. `/abs/path/to/file4.ts` — Service processes business logic ❌ **GAP**
3. `/abs/path/to/file5.ts` — Repository saves to database ❌ **GAP**

#### AC3: [AC description]
1. `/abs/path/to/file6.ts` — Event listener for [trigger] ❌ **GAP**
2. `/abs/path/to/file7.ts` — Handler executes [action] ❌ **GAP**
```

Only include Flow Details for ACs with gaps or particularly complex multi-layer flows. Don't detail simple, fully-covered ACs — the Coverage Matrix suffices.

---

## Flow Tracing Guidelines

### Adapt to Project Architecture

Don't assume a specific stack. Read the project structure and adapt:

- **Web app**: Routes → Controllers → Services → Repositories → Models
- **CLI tool**: Commands → Handlers → Services → Filesystem
- **VS Code extension**: Commands/Events → Providers → Services → VS Code API
- **Agent commands**: Markdown instructions → Subagent prompts → Output templates
- **Library**: Public API → Internal modules → Utilities
- **Event-driven**: Publishers → Event bus → Subscribers → Handlers

### What Counts as "In the Flow"

A file is in the flow if the AC **cannot work without changes to it**:

- **Yes**: The route handler that receives the new request
- **Yes**: The service that implements the new business logic
- **Yes**: The UI component that displays the new data
- **Yes**: The error handler that must handle the new error type
- **Yes**: The config file that needs a new setting
- **Maybe**: A shared utility that already handles the needed case (check if it needs modification)
- **No**: A file that exists and works as-is without changes

The key question: "If I implement every task in the table but skip this file, would this AC work?" If no → it's in the flow and must be in a task.

### Common Gaps to Watch For

These are the most frequently missed files:

1. **Event/message wiring**: Backend handler exists but no frontend event triggers it
2. **Error paths**: Happy path implemented but error handling/display missing
3. **Configuration**: New feature needs config entries that aren't in any task
4. **Migration/schema**: Data model changes without database migration
5. **Tests**: Implementation tasks exist but no test tasks for new behavior
6. **UI state updates**: API returns new data but UI doesn't refresh/display it
7. **Middleware/interceptors**: New route needs auth/validation middleware registration
8. **Index/barrel files**: New module created but not exported from index
9. **Documentation**: User-facing changes without corresponding docs updates (only if spec requires docs)
10. **Rollback/cleanup**: New resources created without cleanup handlers

---

## FlowSpace-Enhanced Tracing

When FlowSpace is available, use it to accelerate flow discovery:

```python
# Find entry points for an AC
results = flowspace.search(
    pattern="<AC keyword or trigger>",
    mode="semantic",
    limit=10
)

# Trace dependencies from a node
node = flowspace.get_node(node_id=result["node_id"], detail="max")
# Read imports, calls, and relationships from node metadata

# Find all callers of a function (reverse trace)
callers = flowspace.search(
    pattern="<function_name>",
    mode="text",
    limit=20
)
```

Without FlowSpace, use standard tools:
- **Glob** to find files by pattern (routes, handlers, tests)
- **Grep** to find imports, function calls, event registrations
- **Read** to trace through specific files following the call chain

---

## Edge Cases

### AC Doesn't Touch Code
Some ACs are about documentation, configuration, or process. If an AC has no code flow:
```
| AC7 | README updated with new API | docs/README.md | 1 | T010 | ✅ Complete |
```

### AC Is Deferred / Out of Phase Scope
If an AC belongs to a future phase, note it but don't flag as a gap:
```
| AC5 | Rate limiting | Phase 4 scope | — | — | ⏭️ Deferred (Phase 4) |
```

### Multiple ACs Share the Same Flow
Common — several ACs may touch the same files. Show each AC separately in the matrix but note shared coverage in Flow Details.

### Subtask Scope (when invoked by plan-5 --subtask mode)
When tracing for a subtask, scope is narrower:
- Only trace ACs that the subtask is meant to address (from parent task context)
- Parent task files are included in the "already covered" set
- Gaps are relative to the subtask + parent, not the entire phase
