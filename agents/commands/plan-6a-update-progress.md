---
description: Update plan progress with task status, flowspace node ID footnotes, and detailed task log entries.
---

# plan-6a-update-progress

Update the plan's progress tracking, footnotes ledger with flowspace node IDs, and maintain detailed task execution log for either the primary phase dossier or a scoped subtask dossier. **Always follow this order:** (1) capture the execution log entry, (2) update the dossier (`tasks.md` or subtask file), (3) sync the main plan checklist and footnotes so every location stays in lockstep.

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"
# --task "<Task ID>"           # plan table ID (e.g., "2.3") or subtask ID (e.g., "ST002")
# --status "completed|in_progress|blocked"
# --changes "List of modified elements with their types"
# Optional flag:
# --subtask "<ORD-subtask-slug>"  # target subtask dossier (e.g., "003-subtask-bulk-import-fixtures")

## Phase 1: Resolve Paths & Load Current State

1) Determine paths:
   - PLAN = provided --plan path.
   - PLAN_DIR = dirname(PLAN).
   - PHASE_HEADING = `--phase` value; slugify to get `PHASE_SLUG` exactly as plan-5/plan-5a (e.g., "Phase 4: Data Flows" → `phase-4-data-flows`). If `--phase` is omitted, infer the slug by locating the unique tasks directory that contains `tasks.md` or the requested `--subtask`; halt if more than one candidate exists.
   - PHASE_DIR = `${PLAN_DIR}/tasks/${PHASE_SLUG}`.
   - TARGET_DOC = `${PHASE_DIR}/tasks.md` (phase dossier by default).
   - TASK_LOG = `${PHASE_DIR}/execution.log.md`.
   - When `--subtask` is provided:
     * SUBTASK_KEY = flag value (e.g., `003-subtask-bulk-import-fixtures`).
     * TARGET_DOC  = `${PHASE_DIR}/${SUBTASK_KEY}.md`.
     * TASK_LOG    = `${PHASE_DIR}/${SUBTASK_KEY}.execution.log.md`.
   - Abort if `TARGET_DOC` does not exist; subtask updates require the plan-5a artifact.

2) Load current state:
   - Read plan markdown to locate the phase heading and plan task table (plan-3 output).
   - Identify testing approach from the plan table header (TDD, Lightweight, Manual, Hybrid) for anchor naming.
   - Parse the Change Footnotes Ledger to capture existing numbering.
   - Read `TARGET_DOC` and find the `## Tasks` table:
     * Phase dossiers contain IDs `T###`.
     * Subtask dossiers contain IDs `ST###`.
   - If `TASK_LOG` is missing, initialize it with `# Execution Log` and note whether it is phase- or subtask-scoped.
   - Determine the next footnote number based on the plan ledger (shared across phase and subtask work).

## Phase 2: Capture Execution Log Entry

Always log the work before adjusting task tables so every location can deep link to the same evidence.

### Phase dossier logging (no `--subtask`):
```bash
# Phase anchor for plan deep link
PHASE_ANCHOR=$(echo "phase-${PHASE_NUM}-${PHASE_NAME}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

# Task table anchor based on testing approach
TABLE_ANCHOR=$(grep -B5 "| ${TASK_ID} |" plan.md | grep "^### Tasks" | sed 's/### Tasks (//;s/ Approach)//;s/ /-/g' | tr '[:upper:]' '[:lower:]')
TABLE_ANCHOR="tasks-${TABLE_ANCHOR}-approach"

# Task anchor for the log entry and plan links
TASK_ANCHOR=$(echo "task-${TASK_ID}-${TASK_NAME}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
```

Append the full TDD cycle to `${PHASE_DIR}/execution.log.md` (newest at bottom):

```markdown
## Task 2.3: Implement validation
**Plan Reference**: [Phase 2: Input Validation](../../${PLAN_NAME}#${PHASE_ANCHOR})
**Task Table Entry**: [View Task 2.3 in Plan](../../${PLAN_NAME}#${TABLE_ANCHOR})
**Status**: Completed
**Started**: 2025-09-28 13:45:00
**Completed**: 2025-09-28 14:30:00
**Duration**: 45 minutes
**Developer**: AI Agent

### Changes Made:
1. Added input validation module [^3]
   - `function:src/validators/input_validator.py:validate_user_input` - Main validation entry point
   - `function:src/validators/input_validator.py:sanitize_input` - Input sanitization helper
   - `function:src/validators/input_validator.py:validate_email_format` - RFC 5322 email validation

### Test Results:
```bash
$ pytest src/validators/test_input_validator.py -v
========================= test session starts =========================
test_validate_user_input_valid .......................... PASSED
test_validate_user_input_invalid ........................ PASSED
test_validate_email_format .............................. PASSED
test_sanitize_input_xss ................................. PASSED
test_rate_limiting ...................................... PASSED

========================= 5 passed in 0.34s ==========================
```

### Type Checking:
```bash
$ python -m mypy src/validators/input_validator.py
Success: no issues found in 1 source file
```

### Implementation Notes:
- Follows RFC 5322 for email validation standards
- Implements rate limiting (100 requests/minute per IP)
- XSS protection via input sanitization
- All validators are pure functions (no side effects)

### Blockers/Issues:
None

### Next Steps:
- Task 2.4: Integration tests for validation pipeline

---
```

### Subtask logging (`--subtask` provided):
```bash
# Subtask anchor mirrors the file stem (e.g., "003-subtask-bulk-import-fixtures")
SUBTASK_ANCHOR=$(echo "${SUBTASK_KEY}" | tr '[:upper:]' '[:lower:]')

# Task anchor uses ST ID and summary
TASK_ANCHOR=$(echo "task-${TASK_ID}-${TASK_NAME}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
```

Append entries to `${PHASE_DIR}/${SUBTASK_KEY}.execution.log.md`:

```markdown
## ST002: Create sanitized fixtures
**Plan Reference**: [Phase 2: Input Validation](../../${PLAN_NAME}#${PHASE_ANCHOR})
**Parent Dossier**: [View ST002](./${SUBTASK_KEY}.md#${TASK_ANCHOR})
**Status**: In Progress
**Started**: 2025-10-02 09:10:00
**Updated**: 2025-10-02 10:05:00
**Developer**: AI Agent

### Changes Made:
1. Stubbed fixture generator [^8]
   - `function:src/tools/fixtures.py:load_sample_payloads`

### Tests:
```bash
$ pytest tests/fixtures/test_generators.py::test_incomplete_fixture -k "xfail"
========================= 1 failed as expected =========================
```

### Notes:
- Waiting on upstream schema update before finalizing fixtures.

---
```

Ensure the log entry includes the same task anchor you will reference in the dossier and plan tables.

Backlink checklist:
- `Plan Reference` should point to the phase section inside `PLAN` (using `PHASE_ANCHOR`).
- `Task Table Entry` (phases) or `Parent Dossier` (subtasks) must link to the exact row in `TARGET_DOC` via `TASK_ANCHOR`.
- Mention the execution log anchor (e.g., `log#task-23-implement-validation`) so other surfaces can reference it verbatim.

## Phase 3: Update Dossier Tasks Table (`TARGET_DOC`)

With the evidence logged, update the relevant table to mirror the task status.

### 3A. Phase dossier (`tasks.md`):
1. Locate the `T###` row linked to the plan task.
2. Update the `Status` glyph (`[x]`, `[~]`, `[!]`).
3. Confirm `Notes` references the plan task and append/refresh the footnote tag (`[^N]`) that will map to the upcoming footnote entry.
4. Mention the execution log anchor in `Notes` if space allows (e.g., `Log: #task-23-implement-validation`).

Before:
| [ ] | T003 | Implement validation | Core | T001 | /abs/path | Tests pass | Supports plan task 2.3 |

After:
| [x] | T003 | Implement validation | Core | T001 | /abs/path | Tests pass | Supports plan task 2.3 · log#task-23-implement-validation [^3] |

### 3B. Subtask dossier (`ORD-subtask-*.md`):
1. Interpret `--task` as `ST###` and update only `TARGET_DOC`.
2. Adjust `Status` glyph.
3. Keep parent linkage in `Notes` (e.g., `Supports T003 / plan task 2.3`). Append/refresh the shared footnote tag and reference the execution log anchor.

Example:

Before:
| [ ] | ST002 | Create sanitized fixtures | Core | ST001 | /abs/path | Fixtures generated | Supports T003 |

After (in progress):
| [~] | ST002 | Create sanitized fixtures | Core | ST001 | /abs/path | Fixtures generated | Supports T003 · log#task-st002-create-sanitized-fixtures [^8] |

Do **not** touch the main plan table yet; that occurs after footnotes are recorded.

## Phase 4: Generate Flowspace Node ID Footnotes

Parse the --changes input to create properly formatted footnotes in the Change Footnotes Ledger. Update the corresponding `Notes` cell in `TARGET_DOC` so the footnote tag (`[^N]`) matches the ledger entry—use the next available number, regardless of whether the row is `T###` or `ST###`. Include links to the execution log anchor when helpful (e.g., `Log: #task-23-implement-validation`).

### Flowspace Node ID Format Rules:

**Classes:**
`class:<file_path>:<ClassName>`
Example: `class:src/auth/service.py:AuthService`

**Methods (include class name):**
`method:<file_path>:<ClassName.method_name>`
Example: `method:src/auth/service.py:AuthService.authenticate`

**Functions (standalone):**
`function:<file_path>:<function_name>`
Example: `function:src/utils/validators.py:validate_email`

**Files (for general changes):**
`file:<file_path>`
Example: `file:config/settings.py`

### Footnote Entry Format:

Append to Change Footnotes Ledger section:
```markdown
[^3]: Task 2.3 - Added validation function
  - `function:src/validators/input_validator.py:validate_user_input`
  - `function:src/validators/input_validator.py:sanitize_input`

[^4]: Task 2.3 - Updated authentication flow
  - `method:src/auth/service.py:AuthService.authenticate`
  - `method:src/auth/service.py:AuthService.validate_token`

[^5]: Task 2.3 - Configuration changes
  - `file:config/settings.py`
  - `file:config/validators.json`
```

### Special Cases:

**Test files:**
`function:tests/test_validators.py:test_email_validation`

**Nested classes:**
`class:src/core/managers.py:TaskManager.InnerValidator`

**Dynamic imports:**
`dynamic:validators:src/core/imports.py`

**External dependencies:**
`external:requests:post` (if documenting external API usage)

## Phase 5: Update Phase & Plan Progress

If you are updating only a subtask dossier (`--subtask` provided), defer this phase until the parent plan task reflects the new status (rerun without `--subtask`).

### Sync the plan task row:
1. Locate the plan table row `N.M` that the dossier task supports.
2. Update the status glyph in the plan table to match the dossier (`[x]`, `[~]`, `[!]`).
3. Update the `Log` column with a deep link to the execution log anchor captured in Phase 2:
   ```markdown
   [📋](tasks/${PHASE_SLUG}/execution.log.md#${TASK_ANCHOR})
   ```
   For subtask-driven work, point to `${SUBTASK_KEY}.execution.log.md`.
4. In the `Notes` column, summarize the outcome and include the footnote tag plus the log anchor reference (e.g., `Completed · log#task-23-implement-validation [^3]`).
5. Double-check that the checkbox reflects the new state and that the `[📋]` link opens the exact execution log anchor.

Before:
| 2.3 | [ ] | Implement validation | Tests pass | - | |

After:
| 2.3 | [x] | Implement validation | Tests pass | [📋](tasks/phase-2/execution.log.md#task-23-implement-validation) | Completed · log#task-23-implement-validation [^3] |

### Update Phase Status:
1. Count completed tasks in phase.
2. Update phase checklist in plan:
   ```markdown
   ### Phase 2: Input Validation
   - [x] Task 2.1: Design validation interface
   - [x] Task 2.2: Write validation tests
   - [x] Task 2.3: Implement validation
   - [ ] Task 2.4: Integration tests
   Progress: 3/4 tasks (75%)
   ```

### Update Overall Progress:
In Progress Checklist section:
```markdown
## 11. Progress Checklist

### Phase Completion Status
- [x] Phase 1: Setup - COMPLETE
- [~] Phase 2: Input Validation - IN PROGRESS (75%)
- [ ] Phase 3: Authentication - PENDING
- [ ] Phase 4: Testing - PENDING

Overall Progress: 1.75/4 phases (44%)
```

## Phase 6: Validation & Quality Checks

### Validation Rules:
1. **Footnote Numbering**: Ensure sequential, no duplicates
2. **Flowspace Format**: Validate node ID syntax:
   ```regex
   ^(class|method|function|file|dynamic|external|builtin):[^:]+:[^:]+$
   OR
   ^file:[^:]+$
   ```
3. **Task ID Format**: Must match pattern `N.M` (plan table) **or** `ST\d{3}` (subtask dossier)
4. **Status Values**: Only `completed`, `in_progress`, or `blocked`
5. **File Paths**: Verify referenced files exist (warning if not)

### Error Handling:

**Invalid Task ID:**
```
ERROR: Task 2.9 not found in Phase 2
Available tasks: 2.1, 2.2, 2.3, 2.4
```

**Invalid Flowspace Format:**
```
ERROR: Invalid node ID format: "validate_user_input"
Correct format: function:src/validators/input_validator.py:validate_user_input
```

**Footnote Collision:**
```
WARNING: Footnote [^3] already exists, renumbering to [^7]
```

## Phase 7: Output & Commit Suggestion

### Success Output:
```
✅ Progress Updated Successfully

Plan: /Users/jordanknight/github/tools/docs/plans/001-validation/validation-plan.md
Phase: Phase 2: Input Validation
Task: 2.3 - Implement validation
Status: completed

Links Created:
- Plan → Log: Added [📋] link in task table pointing to execution.log.md#task-23-implement-validation
- Log → Plan: Added Plan Reference link pointing back to plan.md#phase-2-input-validation

Footnotes Added:
- [^3]: Task 2.3 - Added validation function (2 functions)
- [^4]: Task 2.3 - Updated authentication flow (2 methods)
- [^5]: Task 2.3 - Configuration changes (2 files)

Flowspace Node IDs Generated (6 total):
- function:src/validators/input_validator.py:validate_user_input
- function:src/validators/input_validator.py:sanitize_input
- method:src/auth/service.py:AuthService.authenticate
- method:src/auth/service.py:AuthService.validate_token
- file:config/settings.py
- file:config/validators.json

Task Log Updated: .../tasks/phase-2/execution.log.md

Phase Progress: 3/4 tasks complete (75%)
Overall Progress: 44% complete

Suggested Commit:
git add -A
git commit -m "docs: update progress for Phase 2 Task 2.3

- Mark task 2.3 as completed
- Add flowspace node ID footnotes [^3-5]
- Update execution log with test results and metrics
- Phase 2 now 75% complete"

Next: Continue with Task 2.4 or run /plan-7-code-review if phase complete
```

For subtask updates, mirror the same structure but swap task identifiers (e.g., `Task: ST002 - Create sanitized fixtures`), point `Task Log Updated` to `${SUBTASK_KEY}.execution.log.md`, and include the parent plan task reference in the summary.

### Integration with Other Commands:

**plan-6-implement-phase** should call this after each task:
```bash
/plan-6a-update-progress --phase "Phase 2: Input Validation" \
  --plan "/path/to/plan.md" \
  --task "2.3" \
  --status "completed" \
  --changes "function:validators.py:validate_user_input,method:AuthService.authenticate"
```

For subtask execution:
```bash
/plan-6a-update-progress --phase "Phase 2: Input Validation" \
  --plan "/path/to/plan.md" \
  --subtask "003-subtask-bulk-import-fixtures" \
  --task "ST002" \
  --status "in_progress" \
  --changes "file:docs/fixtures/bulk-import-fixtures.md"
```

**plan-7-code-review** expects:
- All footnotes properly formatted
- Task log complete for the phase
- Progress accurately reflected

## Best Practices:

1. **Run after EACH task** - Don't batch updates
2. **Include ALL changes** - Even small helper functions
3. **Use correct node types** - method vs function matters
4. **Add context in log** - Future you will thank you
5. **Verify before commit** - Check footnote links work
6. **Test deep links** - Ensure both directions navigate correctly
7. **Use consistent anchors** - Follow the kebab-case convention

## Troubleshooting:

**Q: Footnote numbers seem wrong?**
A: Check for manual edits. This command assumes sequential numbering.

**Q: Can I update multiple tasks at once?**
A: No, run once per task for accurate tracking.

**Q: What if I forgot to track a change?**
A: Add it in the next task's update with a note.

**Q: How to handle refactoring?**
A: Use "method:file:Class.method" even if just moving code.
```

Next step: Use during /plan-6-implement-phase execution
