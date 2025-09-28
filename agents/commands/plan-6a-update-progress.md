---
description: Update plan progress with task status, flowspace node ID footnotes, and detailed task log entries.
---

# plan-6a-update-progress

Update the plan's progress tracking, footnotes ledger with flowspace node IDs, and maintain detailed task execution log.

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"
# --task "<Task ID>" (e.g., "2.3")
# --status "completed|in_progress|blocked"
# --changes "List of modified elements with their types"

## Phase 1: Resolve Paths & Load Current State

1) Determine paths:
   - PLAN = provided --plan path
   - PLAN_DIR = dirname(PLAN)
   - PHASE_DIR = PLAN_DIR/tasks/${PHASE_SLUG}
   - TASK_LOG = PHASE_DIR/execution.log.md

2) Load current state:
   - Read plan markdown to locate the phase and task table
   - Identify testing approach from table header (TDD, Lightweight, Manual, Hybrid)
   - Parse existing Change Footnotes Ledger
   - Read current task log (create if missing with proper header)
   - Determine next footnote number

## Phase 2: Update Task Status in Plan

Locate the task row in the phase's task table and update:

### Status Indicators:
- `[ ]` → `[x]` for completed
- `[ ]` → `[~]` for in_progress
- `[ ]` → `[!]` for blocked

### Log Column Update:
Add link to execution log for non-pending tasks:

```bash
# Generate anchor ID for the task
TASK_ANCHOR=$(echo "task-${TASK_ID}-${TASK_NAME}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
# Example: "Task 2.3: Implement validation" → "task-23-implement-validation"
```

Before:
| 2.3 | [ ] | Implement validation | Tests pass | - | |

After (completed):
| 2.3 | [x] | Implement validation | Tests pass | [📋](tasks/phase-2/execution.log.md#task-23-implement-validation) | Completed [^3] |

After (in_progress):
| 2.3 | [~] | Implement validation | Tests pass | [📋](tasks/phase-2/execution.log.md#task-23-implement-validation) | In progress [^3] |

After (blocked):
| 2.3 | [!] | Implement validation | Tests pass | [📋](tasks/phase-2/execution.log.md#task-23-implement-validation) | Blocked [^3] |

## Phase 3: Generate Flowspace Node ID Footnotes

Parse the --changes input to create properly formatted footnotes in the Change Footnotes Ledger.

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

## Phase 4: Update Task Execution Log

### Generate Anchor IDs:
```bash
# Phase anchor for plan deep link
PHASE_ANCHOR=$(echo "phase-${PHASE_NUM}-${PHASE_NAME}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
# Example: "Phase 2: Input Validation" → "phase-2-input-validation"

# Task table anchor based on testing approach
# Detect from table header: "### Tasks (TDD Approach)" → "tasks-tdd-approach"
# Or "### Tasks (Lightweight Approach)" → "tasks-lightweight-approach"
TABLE_ANCHOR=$(grep -B5 "| ${TASK_ID} |" plan.md | grep "^### Tasks" | sed 's/### Tasks (//;s/ Approach)//;s/ /-/g' | tr '[:upper:]' '[:lower:]')
TABLE_ANCHOR="tasks-${TABLE_ANCHOR}-approach"

# Task anchor for this log entry
TASK_ANCHOR=$(echo "task-${TASK_ID}-${TASK_NAME}" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
```

Append detailed entry to PHASE_DIR/execution.log.md:

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

2. Enhanced authentication service [^4]
   - `method:src/auth/service.py:AuthService.authenticate` - Added validation calls
   - `method:src/auth/service.py:AuthService.validate_token` - Token format validation

3. Updated configuration [^5]
   - `file:config/settings.py` - Added validation thresholds
   - `file:config/validators.json` - Validation rules configuration

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

### Performance Metrics:
- Average validation time: 0.02ms
- Memory overhead: < 1KB per validation
- Throughput: 50,000 validations/second

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

## Phase 5: Update Phase & Plan Progress

### Update Phase Status:
1. Count completed tasks in phase
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
3. **Task ID Format**: Must match pattern `N.M` where N=phase, M=task
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

### Integration with Other Commands:

**plan-6-implement-phase** should call this after each task:
```bash
/plan-6a-update-progress --phase "Phase 2: Input Validation" \
  --plan "/path/to/plan.md" \
  --task "2.3" \
  --status "completed" \
  --changes "function:validators.py:validate_user_input,method:AuthService.authenticate"
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