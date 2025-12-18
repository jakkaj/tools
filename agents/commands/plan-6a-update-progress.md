---
description: Update plan progress with task status, flowspace node ID footnotes, and detailed task log entries.
---

# plan-6a-update-progress

**You execute this using subagents** - Update the plan's progress tracking, footnotes ledger with flowspace node IDs, and maintain detailed task execution log for either the primary phase dossier or a scoped subtask dossier.

## ⚠️ CRITICAL: You Must Launch the Subagents Yourself

**This slash command expands a prompt - it does NOT auto-launch subagents.**

When you invoke `/plan-6a-update-progress`:
1. The SlashCommand tool expands this markdown into your context
2. **YOU must launch the Task tool calls described below**
3. **YOU execute this work BY USING subagents** (not waiting for auto-execution)
4. The command does NOT run automatically

**Do not wait - YOU must invoke the Task tools yourself.**

## ⚠️ CRITICAL: This Command Updates THREE Locations

**Every time you run this command, you MUST update ALL THREE:**

1. ✅ **Dossier task table** (`tasks/phase-N/tasks.md` or subtask file) - Status column + footnote
2. ✅ **Parent plan task table** (`plan.md` § 8) - Status + Log + Notes columns + footnote
3. ✅ **Both footnote ledgers** (`plan.md` § 12 + dossier § Phase Footnote Stubs)

**Missing ANY of these = INCOMPLETE execution**

Flaky updates happen when agents skip #2 (plan.md updates) or #3 (footnotes). This command enforces atomic updates with validation checkpoints after each step.

**Execution Flow:** Evidence → Atomic 3-Location Update → Validation

## Command Structure (4 Phases)

This command is structured to prevent the common failure mode of forgetting to update plan.md:

- **Phase A**: Resolve Paths & Load Current State
  - Determine all file paths (plan.md, tasks.md or subtask file, execution log)
  - Load current state from all three locations to understand what needs updating
  - Identify next footnote number

- **Phase B**: Capture Execution Log Entry (Evidence First)
  - Write detailed execution log entry with task anchor
  - Create backlinks to plan and dossier
  - Checkpoint: Verify log written before proceeding

- **Phase C**: Atomic 3-Location Update + Diagram ⚠️ **ALL STEPS REQUIRED**
  - **Step C1**: Update dossier task table (tasks.md or subtask file)
  - **Step C2**: Update plan task table (plan.md § 8) ← Often forgotten!
  - **Step C3**: Update BOTH footnote ledgers (plan.md § 12 + dossier stubs) + progress checklist
  - **Step C4**: Update Architecture Map diagram (if exists) — task/file node colors
  - Each step has a checkpoint to verify completion

- **Phase D**: Validation & Output
  - **Step D1**: Pre-output verification checklist (7 items)
  - **Step D2**: Quality validation rules
  - **Step D3**: Success output confirming all 3 locations updated

```md
User input:

$ARGUMENTS
# Expected flags:
# --phase "<Phase N: Title>"   # Required for Full Mode, ignored for Simple Mode
# --plan "<abs path to docs/plans/<ordinal>-<slug>/<slug>-plan.md>"
# --task "<Task ID>"           # plan table ID (e.g., "T001") or subtask ID (e.g., "ST002")
# --status "completed|in_progress|blocked"
# --changes "List of modified elements with their types"
# Optional flags:
# --subtask "<ORD-subtask-slug>"  # target subtask dossier (e.g., "003-subtask-bulk-import-fixtures")
# --inline                        # Simple Mode: update inline task table in plan (no separate dossier)

## PHASE A: Resolve Paths & Load Current State

### Step A1: Determine Paths

Resolve all file paths before starting updates:

- **PLAN** = provided --plan path
- **PLAN_DIR** = dirname(PLAN)
- **INLINE_MODE** = true if `--inline` flag provided (Simple Mode)

**If INLINE_MODE = true (Simple Mode):**
- **TARGET_DOC** = PLAN itself (the plan file contains the inline task table)
- **TASK_LOG** = `${PLAN_DIR}/execution.log.md` (sibling to plan)
- **PHASE_DIR** = PLAN_DIR (no separate phase directory)
- Task IDs use `T###` format (from inline `### Tasks` table under `## Implementation`)
- Skip PHASE_HEADING/PHASE_SLUG resolution (single phase)
- Updates go to:
  1. Inline task table in PLAN (§ Implementation > ### Tasks)
  2. Change Footnotes Ledger in PLAN (§ Change Footnotes Ledger)
  3. No separate dossier (plan is the single source of truth)

**If INLINE_MODE = false (Full Mode):**
- **PHASE_HEADING** = `--phase` value; slugify to get `PHASE_SLUG` exactly as plan-5/plan-5a (e.g., "Phase 4: Data Flows" → `phase-4-data-flows`)
  - If `--phase` omitted: infer slug by locating the unique tasks directory containing `tasks.md` or requested `--subtask`
  - Halt if ambiguous (multiple candidates exist)
- **PHASE_DIR** = `${PLAN_DIR}/tasks/${PHASE_SLUG}`

**Determine target documents (Full Mode only):**
- If `--subtask` NOT provided (phase execution):
  * **TARGET_DOC** = `${PHASE_DIR}/tasks.md` (phase dossier)
  * **TASK_LOG** = `${PHASE_DIR}/execution.log.md`
  * Task IDs use `T###` format

- If `--subtask` provided (subtask execution):
  * **SUBTASK_KEY** = flag value (e.g., `003-subtask-bulk-import-fixtures`)
  * **TARGET_DOC** = `${PHASE_DIR}/${SUBTASK_KEY}.md` (subtask dossier)
  * **TASK_LOG** = `${PHASE_DIR}/${SUBTASK_KEY}.execution.log.md`
  * Task IDs use `ST###` format

**Validation:**
- Abort if `TARGET_DOC` does not exist (for Full Mode) or PLAN does not exist
- For INLINE_MODE: verify `## Implementation (Single Phase)` section exists in PLAN

### Step A2: Load Current State (Parallel Readers)

⚡ **YOU LAUNCH SUBAGENTS IN THIS STEP**

**IMPORTANT - YOU MUST LAUNCH**: Use **parallel subagent readers** for faster state loading.

**Strategy**: **YOU** launch 3 parallel readers (single message with 3 Task tool calls) to load state from all three locations concurrently.

**Subagent A1: Plan Reader**
"Load plan-level state and metadata.

**Read**: `${PLAN}` (plan.md)

**Extract**:
- Phase heading and plan task table (§ 8)
- Testing approach from table header (TDD/TAD/Lightweight/Manual/Hybrid)
- Parse `## Change Footnotes Ledger` (§ 12) - all existing footnotes
- Determine next footnote number (max number + 1)

**Report** (JSON):
```json
{
  \"testing_approach\": \"Full TDD|TAD|Lightweight|Manual|Hybrid\",
  \"existing_footnotes\": [\"[^1]\", \"[^2]\", \"[^3]\"],
  \"next_footnote\": 4,
  \"phase_metadata\": {\"number\": 2, \"name\": \"Input Validation\", \"slug\": \"phase-2-input-validation\"}
}
```
"

**Subagent A2: Dossier Reader**
"Load dossier-level task state.

**Read**: `${TARGET_DOC}` (tasks.md or subtask file)

**Extract**:
- `## Tasks` table with all rows
- Task ID format (T### for phase, ST### for subtask)
- Parse `## Phase Footnote Stubs` section - all existing stubs
- Current task statuses and dependencies

**Report** (JSON):
```json
{
  \"task_id_format\": \"T###|ST###\",
  \"tasks\": [{\"id\": \"T003\", \"status\": \"[ ]\", \"paths\": [\"/abs/path\"]}, ...],
  \"footnote_stubs\": [\"[^1]\", \"[^2]\", \"[^3]\"]
}
```
"

**Subagent A3: Log Reader**
"Load execution history and anchors.

**Read**: `${TASK_LOG}` (execution.log.md)

**Extract**:
- If missing: note need to create with `# Execution Log` header
- Parse existing log entries (newest at bottom)
- Extract all task anchors currently in use
- Note whether phase-scoped or subtask-scoped

**Report** (JSON):
```json
{
  \"log_exists\": true/false,
  \"existing_anchors\": [\"task-21-setup\", \"task-22-configure\"],
  \"scope\": \"phase|subtask\"
}
```
"

**Wait for the 3 subagents YOU just launched**: Block until all 3 subagents complete.

**Synthesize State**:
After all readers complete:
1. Combine state from plan, dossier, log
2. Verify footnote numbers consistent (plan matches dossier)
3. Determine next footnote number (from A1)
4. Store unified state for Phase C updates

✋ **CHECKPOINT**: Confirm all three parallel readers completed and state merged before proceeding.

## PHASE B: Capture Execution Log Entry (Evidence First)

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
**Dossier Task**: T003
**Plan Task**: 2.3
**Plan Reference**: [Phase 2: Input Validation](../../${PLAN_NAME}#${PHASE_ANCHOR})
**Dossier Reference**: [View T003 in Dossier](./tasks.md#task-t003)
**Plan Task Entry**: [View Task 2.3 in Plan](../../${PLAN_NAME}#${TABLE_ANCHOR})
**Status**: Completed
**Complexity Reaffirmed**: CS-3 (medium)
  - Actual breakdown: S=1 (few files), I=0 (internal), D=0 (no schema), N=1 (some discovery), F=1 (validation constraints), T=2 (integration tests)
  - Notes: Complexity aligned with initial estimate; validation edge cases required extra iteration
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

### Footnotes Created:
- [^3]: Validation functions (3 functions)
- [^4]: Authentication flow updates (2 methods)
- [^5]: Configuration changes (2 files)

**Total FlowSpace IDs**: 7

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
**Dossier Task**: ST002
**Parent Task**: T003 (Plan Task 2.3)
**Plan Reference**: [Phase 2: Input Validation](../../${PLAN_NAME}#${PHASE_ANCHOR})
**Subtask Dossier**: [View ST002](./${SUBTASK_KEY}.md#${TASK_ANCHOR})
**Parent Dossier**: [View T003](./tasks.md#task-t003)
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

✋ **CHECKPOINT**: Confirm execution log entry written to TASK_LOG before proceeding to updates.

## PHASE C: Atomic 3-Location Update (REQUIRED - ALL STEPS)

⚡ **YOU LAUNCH SUBAGENTS IN THIS PHASE**

**This phase is MANDATORY and updates all three locations atomically.**

You MUST complete ALL four steps below for every task update. Missing any step = incomplete execution.

**IMPORTANT - YOU MUST LAUNCH**: After Phase B completes, **YOU** launch 3 parallel updater subagents (single message with 3 Task tool calls) to update all locations concurrently.

**Strategy**: Launch 3 updaters in parallel - each handles one step independently.

**Subagent C1: Dossier/Inline Task Updater**
"Update the task table (dossier or inline).

**Location:** `${TARGET_DOC}`
- Full Mode: `tasks.md` or subtask file
- Simple Mode (INLINE_MODE): PLAN itself (`## Implementation (Single Phase)` > `### Tasks`)

**Task**: Update the relevant task row to mirror the new status:

#### For Simple Mode (INLINE_MODE = true):

1. Locate the `T###` row in the inline tasks table under `## Implementation (Single Phase)` > `### Tasks`
2. Update the `Status` glyph:
   - `[ ]` = pending (not started)
   - `[~]` = in_progress (currently working)
   - `[x]` = completed (done)
   - `[!]` = blocked (cannot proceed)
3. Update `Notes` column:
   - Add log anchor reference: `log#task-t001-setup`
   - Add footnote tag: `[^N]` (using next available number from Step A2)

**Example transformation (Simple Mode):**

Before:
```markdown
| [ ] | T001 | Setup configuration | 2 | Setup | -- | /abs/path | Config created | |
```

After:
```markdown
| [x] | T001 | Setup configuration | 2 | Setup | -- | /abs/path | Config created | log#task-t001-setup [^1] |
```

**Note**: In Simple Mode, there is NO separate dossier - the plan's inline task table IS the task source. Skip Subagent C2 (Plan Updater) since there's only one table to update.

#### For Full Mode - Phase Dossier (`tasks.md`):

1. Locate the `T###` row in the dossier tasks table
2. Update the `Status` glyph:
   - `[ ]` = pending (not started)
   - `[~]` = in_progress (currently working)
   - `[x]` = completed (done)
   - `[!]` = blocked (cannot proceed)
3. Update `Notes` column:
   - Keep existing plan task reference (e.g., "Supports plan task 2.3")
   - Add log anchor reference: `log#task-23-implement-validation`
   - Add footnote tag: `[^N]` (using next available number from Step A2)

**Example transformation:**

Before:
```markdown
| [ ] | T003 | Implement validation | Core | T001 | /abs/path | Tests pass | Supports plan task 2.3 |
```

After:
```markdown
| [x] | T003 | Implement validation | Core | T001 | /abs/path | Tests pass | Supports plan task 2.3 · log#task-23-implement-validation [^3] |
```

#### For Full Mode - Subtask Dossier (`ORD-subtask-*.md`):

1. Locate the `ST###` row in the subtask tasks table
2. Update the `Status` glyph (same as above)
3. Update `Notes` column:
   - Keep parent task reference (e.g., "Supports T003 / plan task 2.3")
   - Add log anchor reference: `log#task-st002-create-sanitized-fixtures`
   - Add footnote tag: `[^N]`

**Example transformation:**

Before:
```markdown
| [ ] | ST002 | Create sanitized fixtures | Core | ST001 | /abs/path | Fixtures generated | Supports T003 |
```

After:
```markdown
| [~] | ST002 | Create sanitized fixtures | Core | ST001 | /abs/path | Fixtures generated | Supports T003 · log#task-st002-create-sanitized-fixtures [^8] |
```

**Report** (confirmation):
`Task table updated: ${TASK_ID} status set to ${STATUS}, footnote [^${N}] added`
"

---

**Subagent C2: Plan Updater** (Full Mode Only)
"Update the parent plan task table.

**SKIP THIS SUBAGENT IF INLINE_MODE = true** (Simple Mode already updated the plan's inline task table in C1)

**Location:** `${PLAN}` (the main `plan.md` file)

**CRITICAL:** This step is often forgotten in Full Mode. You MUST update the plan.md task table.

Find the plan task table (usually in § 8 Implementation Phases) and update the corresponding row:

1. **Locate the plan task row** (e.g., `| 2.3 | ...`)
   - Use the `--task` value provided (e.g., "2.3")
   - For subtask updates, use the parent plan task that the subtask supports

2. **Update Status column**:
   - Change checkbox from `[ ]` to match dossier status:
     * `[x]` = completed
     * `[~]` = in_progress
     * `[!]` = blocked

3. **Update Log column**:
   - Add deep link to execution log anchor:
   ```markdown
   [📋](tasks/${PHASE_SLUG}/execution.log.md#${TASK_ANCHOR})
   ```
   - For subtask work, point to subtask log:
   ```markdown
   [📋](tasks/${PHASE_SLUG}/${SUBTASK_KEY}.execution.log.md#${TASK_ANCHOR})
   ```

4. **Update Notes column**:
   - Add status summary (e.g., "Completed", "In progress")
   - Add log anchor reference: `log#task-23-implement-validation`
   - Add footnote tag: `[^N]` (same number as Step C1)

**Example transformation:**

Before:
```markdown
| 2.3 | [ ] | Implement validation | Tests pass | - | |
```

After:
```markdown
| 2.3 | [x] | Implement validation | Tests pass | [📋](tasks/phase-2/execution.log.md#task-23-implement-validation) | Completed · log#task-23-implement-validation [^3] |
```

**CRITICAL - Embedded Task Tables:**

If the plan uses **embedded task tables** (tasks within phase sections, not separate tasks.md files), you MUST update ALL columns:
- **Status**: Change `[ ]` to `[x]`/`[~]`/`[!]`
- **Log**: Add `[📋](path)` link
- **Notes**: Add summary + footnote `[^N]`

Do not leave any column with `-` or empty when marking complete.

**Report** (confirmation):
`Plan task table updated: task ${PLAN_TASK_ID} status set to ${STATUS}, log link added, footnote [^${N}] added`
"

---

**Subagent C3: Footnote & Progress Updater**
"Update footnote ledger(s) AND the progress checklist.

**Locations (varies by mode):**

**Full Mode:**
1. `${PLAN}` § 12 Change Footnotes Ledger
2. `${TARGET_DOC}` § Phase Footnote Stubs
3. `${PLAN}` § 11 Progress Checklist (if present)

**Simple Mode (INLINE_MODE = true):**
1. `${PLAN}` § Change Footnotes Ledger (only ONE ledger - plan is the single source)
2. No dossier stubs to update
3. Update `### Acceptance Criteria` checkboxes in `## Implementation (Single Phase)` section

**CRITICAL (Full Mode):** You must update BOTH footnote ledgers with the same `[^N]` number.
**CRITICAL (Simple Mode):** Only ONE ledger exists - update it in the plan.

Parse the `--changes` input to create properly formatted footnotes using the next available footnote number from Step A2.

#### Flowspace Node ID Format Rules:

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

#### Footnote Entry Format:

**Step 1: Append to PLAN § 12 Change Footnotes Ledger:**
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

**Step 2: Append to TARGET_DOC § Phase Footnote Stubs:**

Use the same format and same `[^N]` numbers as in the plan ledger.

#### Special Cases:

**Test files:**
`function:tests/test_validators.py:test_email_validation`

**Nested classes:**
`class:src/core/managers.py:TaskManager.InnerValidator`

**Dynamic imports:**
`dynamic:validators:src/core/imports.py`

**External dependencies:**
`external:requests:post` (if documenting external API usage)

✋ **CHECKPOINT C3**: Confirm BOTH footnote ledgers updated with matching `[^N]` entries.

---

### Step C3a: Embed FlowSpace IDs in Source Files (Recommended)

**Purpose**: Enable **File → Task** bidirectional graph traversal by embedding FlowSpace IDs as comments in modified source files.

This step completes the bidirectional linkage:
- **Task → File**: Already established via footnote ledger (Step C3)
- **File → Task**: Established by embedding FlowSpace ID comments in source code

**When to embed**:
- After updating footnote ledgers (Step C3)
- For all files referenced in `--changes` flag
- Any time you modify a class, method, function, or file

**Format by Language**:

#### Python
```python
# FlowSpace: [^3] function:src/validators.py:validate_email
def validate_email(email: str) -> bool:
    """Validate email format per RFC 5322."""
    ...

# FlowSpace: [^4] class:src/auth/service.py:AuthService
class AuthService:
    """Authentication service with token validation."""

    # FlowSpace: [^4] method:src/auth/service.py:AuthService.authenticate
    def authenticate(self, credentials: dict) -> Token:
        """Authenticate user and return token."""
        ...
```

#### TypeScript/JavaScript
```typescript
// FlowSpace: [^3] function:src/validators.ts:validateEmail
export function validateEmail(email: string): boolean {
    ...
}

// FlowSpace: [^4] class:src/auth/service.ts:AuthService
export class AuthService {
    // FlowSpace: [^4] method:src/auth/service.ts:AuthService.authenticate
    authenticate(credentials: Credentials): Token {
        ...
    }
}
```

#### Java
```java
// FlowSpace: [^4] class:src/main/java/com/app/auth/AuthService.java:AuthService
public class AuthService {
    // FlowSpace: [^4] method:src/main/java/com/app/auth/AuthService.java:AuthService.authenticate
    public Token authenticate(Credentials credentials) {
        ...
    }
}
```

#### Rust
```rust
// FlowSpace: [^3] function:src/validators.rs:validate_email
pub fn validate_email(email: &str) -> bool {
    ...
}
```

**Placement Rules**:

1. **Functions/Methods**: Immediately before the function/method definition (after docstring/JSDoc if present)
2. **Classes**: Immediately before class declaration
3. **File-level changes**: At top of file (after imports, before first symbol)

**Multiple Footnotes (Chronological)**:

If a symbol was modified across multiple tasks, append footnotes chronologically:

```python
# FlowSpace: [^3] [^7] [^12] function:src/utils.py:parse_date
def parse_date(date_str: str) -> datetime:
    """Parse date string - modified in tasks 2.3, 3.2, 4.1."""
    ...
```

This shows the complete modification history: task 2.3 created it, task 3.2 modified it, task 4.1 modified it again.

**Graph Traversal Benefit**:

With embedded FlowSpace IDs, you can:

1. **From file → Find all tasks that ever modified it**:
   - Open `src/validators.py`
   - See `# FlowSpace: [^3] [^7]`
   - Look up `[^3]` in plan.md § 12 → "Task 2.3"
   - Look up `[^7]` in plan.md § 12 → "Task 3.2"

2. **From task → Find all files it modified**:
   - Already established via footnote ledger in Step C3

3. **Complete bidirectional graph**:
   - Task ↔ File (via footnotes)
   - Task ↔ Log (via anchor references)
   - File ↔ Log (via task as intermediary)

**Implementation Notes**:

- Embedding is **recommended but not required** for this command to succeed
- If skipped, File → Task traversal requires searching footnote ledgers manually
- Future enhancement: `--embed-ids` flag to automate embedding via code editing tools

✋ **Checkpoint C3a** (optional): If embedding FlowSpace IDs, verify comments added to all modified files.

---

#### Update Phase Progress Checklist

**Location:** `${PLAN}` § 11 Progress Checklist

After completing a task, update the phase completion percentage:

1. Count completed tasks in the phase:
   - Check the dossier tasks table (TARGET_DOC) for completed `T###` or `ST###` rows
   - Or count from embedded task table in plan if tasks are not separate

2. Update the phase checklist in PLAN § 11:

**Example:**

Before:
```markdown
## 11. Progress Checklist

### Phase Completion Status
- [x] Phase 1: Setup - COMPLETE
- [~] Phase 2: Input Validation - IN PROGRESS (50%)
- [ ] Phase 3: Authentication - PENDING
- [ ] Phase 4: Testing - PENDING

Overall Progress: 1.5/4 phases (38%)
```

After (task 2.3 completed, now 3/4 tasks done):
```markdown
## 11. Progress Checklist

### Phase Completion Status
- [x] Phase 1: Setup - COMPLETE
- [~] Phase 2: Input Validation - IN PROGRESS (75%)
- [ ] Phase 3: Authentication - PENDING
- [ ] Phase 4: Testing - PENDING

Overall Progress: 1.75/4 phases (44%)
```

3. If ALL phase tasks are complete, change phase status:
   - `[~]` → `[x]`
   - "IN PROGRESS (100%)" → "COMPLETE"
   - Recalculate overall progress

**Report** (confirmation):
`Footnotes added to both ledgers: [^${N}] with ${COUNT} FlowSpace IDs. Progress checklist updated: phase at ${PERCENTAGE}%`
"

**Wait for the 3 updater subagents YOU just launched**: Block until all 3 subagents complete (C1: Dossier, C2: Plan, C3: Footnotes+Progress).

✋ **CHECKPOINT C**: Confirm ALL THREE locations updated (dossier table, plan table, both footnote ledgers + progress checklist) before proceeding to diagram update.

---

### Step C4: Update Architecture Map Diagram

**Subagent C4: Architecture Map Updater** (if Architecture Map exists in TARGET_DOC)
"Update the Architecture Map diagram to reflect task status changes.

**Location:** `## Architecture Map` section in `${TARGET_DOC}` (or PLAN for Simple Mode)

**Skip if**: No `## Architecture Map` section exists in the document.

**Task**: Find and update Mermaid node styling for the completed/in-progress/blocked task:

#### Status → Diagram Class Mapping:

| --status value | Mermaid Class | Color | Node Label Update |
|----------------|---------------|-------|-------------------|
| `in_progress` | `:::inprogress` | Orange #FF9800 | (no change) |
| `completed` | `:::completed` | Green #4CAF50 | Add ` ✓` to label |
| `blocked` | `:::blocked` | Red #F44336 | Add ` ⚠` to label |

#### Update Steps:

1. **Find the task node** in the Mermaid diagram:
   - Search for node with ID matching `${TASK_ID}` (e.g., `T003` or `ST002`)
   - Pattern: `T003[\"T003: Task description\"]:::pending`

2. **Update the node class**:
   - Change `:::pending` → `:::inprogress` (if --status in_progress)
   - Change `:::pending` or `:::inprogress` → `:::completed` (if --status completed)
   - Change any class → `:::blocked` (if --status blocked)

3. **Update node label** (for completed/blocked):
   - Completed: `T003[\"T003: Task description\"]` → `T003[\"T003: Task description ✓\"]`
   - Blocked: `T003[\"T003: Task description\"]` → `T003[\"T003: Task description ⚠\"]`

4. **Update file nodes touched by this task**:
   - Parse `--changes` flag for file paths
   - Find corresponding file nodes (F1, F2, etc.)
   - Update their class to match task status (all file nodes update together)

5. **Update Task-to-Component Mapping table**:
   - Find row for `${TASK_ID}`
   - Update Status column:
     * `⬜ Pending` → `🟧 In Progress` (if --status in_progress)
     * `⬜ Pending` or `🟧 In Progress` → `✅ Complete` (if --status completed)
     * Any → `🔴 Blocked` (if --status blocked)
   - Update Comment column with brief status note:
     * In Progress: what's currently being worked on
     * Completed: brief summary of what was done
     * Blocked: reason for the block

#### Example Transformation:

**Before** (task T003 starting):
```mermaid
    T003[\"T003: Implement endpoint\"]:::pending
    F3[\"/src/api/endpoint.py\"]:::pending
```

**After** (--status in_progress):
```mermaid
    T003[\"T003: Implement endpoint\"]:::inprogress
    F3[\"/src/api/endpoint.py\"]:::pending
```

**After** (--status completed):
```mermaid
    T003[\"T003: Implement endpoint ✓\"]:::completed
    F3[\"/src/api/endpoint.py ✓\"]:::completed
```

**Report** (confirmation):
`Architecture Map updated: ${TASK_ID} ${OLD_STATUS} → ${NEW_STATUS} (${COLOR}). File nodes updated: ${FILE_COUNT}`
"

✋ **CHECKPOINT C4**: If Architecture Map exists, confirm diagram nodes updated to match task status.

---

## PHASE D: Validation & Output

### Step D1: Pre-Output Verification (Parallel Validators)

⚡ **YOU LAUNCH SUBAGENTS IN THIS STEP**

**IMPORTANT - YOU MUST LAUNCH**: Use **parallel subagent validators** for comprehensive verification.

**REQUIRED:** Before displaying success message, **YOU** launch 3 parallel validators to verify ALL updates were completed correctly.

**Strategy**: **YOU** launch 3 validators (single message with 3 Task tool calls) to check different aspects concurrently.

**Subagent D1: Footnote Validator**
"Verify footnote synchronization and format.

**Read**:
- `${PLAN}` § 12 (Change Footnotes Ledger)
- `${TARGET_DOC}` § Phase Footnote Stubs

**Check**:
- Same `[^N]` numbers in all 4 locations: plan table, dossier table, plan ledger, dossier stubs
- Footnotes are sequential (no gaps)
- No duplicate numbers
- FlowSpace node ID format valid (class|method|function|file:path:symbol)

**Report** (JSON):
```json
{
  \"violations\": [
    {\"severity\": \"CRITICAL\", \"issue\": \"Footnote [^5] in plan but missing in dossier\", \"fix\": \"Add to dossier stubs\"},
    ...
  ],
  \"synchronized\": true/false
}
```
"

**Subagent D2: Link Validator**
"Verify all deep links resolve correctly.

**Read**:
- `${PLAN}` (Log column links)
- `${TARGET_DOC}` (Notes column log anchors)
- `${TASK_LOG}` (actual anchors)

**Check**:
- Plan Log column `[📋]` links point to existing log anchors
- Dossier Notes `log#anchors` match actual log entry headings
- All cross-references resolvable

**Report** (JSON):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH\", \"issue\": \"Plan task 2.3 Log link points to #task-23-validation but log anchor is #task-23-implement-validation\", \"fix\": \"Fix anchor mismatch\"},
    ...
  ],
  \"all_links_valid\": true/false
}
```
"

**Subagent D3: Status Validator**
"Verify status consistency across locations.

**Read**:
- `${PLAN}` § 8 (plan task statuses)
- `${TARGET_DOC}` (dossier task statuses)
- `${PLAN}` § 11 (progress checklist)

**Check**:
- Plan task status matches dossier task status
- Progress checklist percentages accurate
- Phase completion state consistent
- Execution log entry exists for updated task

**Report** (JSON):
```json
{
  \"violations\": [
    {\"severity\": \"CRITICAL\", \"plan_task\": \"2.3\", \"plan_status\": \"[x]\", \"dossier_task\": \"T003\", \"dossier_status\": \"[ ]\", \"issue\": \"Status mismatch\", \"fix\": \"Sync statuses\"},
    ...
  ],
  \"synchronized\": true/false
}
```
"

**Subagent D4: Diagram Validator** (if Architecture Map exists)
"Verify Architecture Map diagram status matches task table status.

**Skip if**: No `## Architecture Map` section exists in TARGET_DOC.

**Read**:
- `${TARGET_DOC}` § Architecture Map (Mermaid diagram)
- `${TARGET_DOC}` § Tasks (task table statuses)
- `${TARGET_DOC}` § Task-to-Component Mapping table

**Check**:
- Task table status matches diagram node class:
  * `[x]` in table → `:::completed` in diagram
  * `[~]` in table → `:::inprogress` in diagram
  * `[!]` in table → `:::blocked` in diagram
  * `[ ]` in table → `:::pending` in diagram
- Task-to-Component Mapping Status column matches diagram:
  * `✅ Complete` → `:::completed`
  * `🟧 In Progress` → `:::inprogress`
  * `🔴 Blocked` → `:::blocked`
  * `⬜ Pending` → `:::pending`
- Completed tasks have ✓ in their node label
- Blocked tasks have ⚠ in their node label

**Report** (JSON):
```json
{
  \"violations\": [
    {\"severity\": \"HIGH\", \"task\": \"T003\", \"table_status\": \"[x]\", \"diagram_class\": \":::inprogress\", \"issue\": \"Diagram not updated\", \"fix\": \"Change T003 node to :::completed\"},
    {\"severity\": \"MEDIUM\", \"task\": \"T003\", \"issue\": \"Completed task missing ✓ in label\", \"fix\": \"Add ✓ to node label\"},
    ...
  ],
  \"diagram_synchronized\": true/false
}
```
"

**Wait for the 4 validator subagents YOU just launched**: Block until all 4 subagents complete (D1-D3 always, D4 if diagram exists).

**Synthesize Validation Results**:
After all validators complete:
1. Collect all violations from D1, D2, D3, D4
2. Determine overall status:
   - If **ZERO violations**: Proceed to Step D3 (Success Output)
   - If **ANY violations**: Display detailed error report and ABORT

**Error Output Format** (if violations found):
```
❌ Validation Failed - Progress Update Incomplete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 Validation Violations Detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Footnote Violations:
- [!] Footnote [^3] missing from dossier stubs
- [!] Footnote numbers not synchronized

Link Violations:
- [!] Broken link: [📋](tasks/phase-2/execution.log.md#wrong-anchor)

Status Violations:
- [!] Plan shows [x] but dossier shows [~] for task 2.3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GO BACK and complete Phase C steps that were missed.
```

✋ **STOP**: Do not proceed to Step D3 until ALL validators report ZERO violations.

---

### Step D2: Quality Validation Rules

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

---

### Step D3: Success Output

Display comprehensive update confirmation showing all three locations were modified:

```
✅ Progress Updated Successfully - 3 Locations Confirmed

Plan: /Users/jordanknight/github/tools/docs/plans/001-validation/validation-plan.md
Phase: Phase 2: Input Validation
Task: 2.3 - Implement validation
Status: completed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Locations Updated (All 3 Required)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ✅ Dossier Task Table Updated
   File: tasks/phase-2/tasks.md
   Row: T003 status changed to [x]
   Notes: Added log anchor + footnote [^3]

2. ✅ Plan Task Table Updated
   File: validation-plan.md § 8
   Row: 2.3 status changed to [x]
   Log: Added [📋] link to execution.log.md#task-23-implement-validation
   Notes: Added summary + footnote [^3]

3. ✅ Footnotes Updated (Both Ledgers)
   - Plan § 12: Added [^3], [^4], [^5]
   - Dossier stubs: Added [^3], [^4], [^5]
   - All numbers match and synchronized

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Execution Log & Evidence
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task Log: tasks/phase-2/execution.log.md#task-23-implement-validation
Anchor: task-23-implement-validation
Complexity Reaffirmed: CS-3 (medium - aligned with initial estimate)
Evidence: Test output, type check results captured

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 Footnotes Added
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[^3]: Task 2.3 - Added validation function (2 functions)
[^4]: Task 2.3 - Updated authentication flow (2 methods)
[^5]: Task 2.3 - Configuration changes (2 files)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Flowspace Node IDs Generated (6 total)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- function:src/validators/input_validator.py:validate_user_input
- function:src/validators/input_validator.py:sanitize_input
- method:src/auth/service.py:AuthService.authenticate
- method:src/auth/service.py:AuthService.validate_token
- file:config/settings.py
- file:config/validators.json

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Progress Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase Progress: 3/4 tasks complete (75%)
Overall Progress: 1.75/4 phases (44%)
Status: Phase 2 still IN PROGRESS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💾 Suggested Commit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

git add -A
git commit -m "docs: update progress for Phase 2 Task 2.3

- Mark task 2.3 as completed in both dossier and plan
- Add flowspace node ID footnotes [^3-5] to both ledgers
- Update execution log with test results and metrics
- Sync Status/Log/Notes columns in plan task table
- Phase 2 now 75% complete (3/4 tasks)"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next: Continue with Task 2.4 or run /plan-7-code-review if phase complete
```

For subtask updates, mirror the same structure but swap task identifiers (e.g., `Task: ST002 - Create sanitized fixtures`), point `Task Log Updated` to `${SUBTASK_KEY}.execution.log.md`, and include the parent plan task reference in the summary.

### Subtask Completion Output:

When marking the LAST ST### task as complete, add parent resumption section to the success output:

```
✅ Progress Updated Successfully

Plan: /path/to/plan.md
Phase: Phase 2: Input Validation
Subtask: 001-subtask-bulk-import-fixtures
Task: ST003 - Final fixture validation
Status: completed

[... standard links/footnotes/node IDs sections ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Parent Task Resumption
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Subtask: 001-subtask-bulk-import-fixtures
Parent Task: T003 - Implement validation module
Plan Task: 2.3 - Implement validation

Status: All ST### tasks complete ✓

Actions taken:
- ✓ Updated parent execution log with subtask completion
- ✓ Parent task unblocked (if was blocked)
- ✓ Subtasks Registry updated in plan (marked complete)

Resume parent work:
/plan-6-implement-phase --phase "Phase 2: Input Validation" \
  --plan "/path/to/plan.md"

Parent links:
- Parent Dossier: tasks/phase-2/tasks.md#task-t003
- Parent Plan: ../../plan.md#task-23

Suggested Commit:
git add -A
git commit -m "docs: complete subtask 001-subtask-bulk-import-fixtures

- All ST### tasks completed
- Parent task T003 can resume
- See subtask execution log for details"

Next: Resume parent task T003 using command above
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

---

## Best Practices

### Critical Rules (Avoid Flaky Updates):

1. **ALWAYS update all 3 locations** - Never skip plan.md or footnote ledgers
2. **Follow Phase C atomically** - Complete C1, C2, C3, C4 in order with checkpoints
3. **Verify before outputting** - Run Phase D Step D1 checklist before success message
4. **Run after EACH task** - Don't batch updates; one task = one command execution
5. **Same footnote number everywhere** - `[^N]` must match in dossier, plan, both ledgers

### Quality Guidelines:

1. **Include ALL changes** - Even small helper functions get flowspace node IDs
2. **Use correct node types** - `method` vs `function` matters for traceability
3. **Add context in log** - Future developers will thank you
4. **Test deep links** - Verify `[📋]` links open the correct execution log anchor
5. **Use consistent anchors** - Follow kebab-case convention (e.g., `task-23-implement-validation`)

---

## Troubleshooting

### Common Failure Modes:

**❌ PROBLEM: Agent forgot to update plan.md**
- **Symptom**: Dossier updated but plan task table still shows `[ ]` or missing `[📋]` link
- **Root Cause**: Skipped Phase C Step C2
- **Fix**: Always follow the atomic update flow (C1 → C2 → C3 → C4); use checkpoints
- **Prevention**: Run Phase D Step D1 verification checklist before outputting

**❌ PROBLEM: Footnotes don't match between locations**
- **Symptom**: plan.md has `[^3]` but tasks.md has `[^5]` for the same task
- **Root Cause**: Didn't sync footnote numbers in Step C3
- **Fix**: Use the SAME `[^N]` number determined in Phase A Step A2 everywhere
- **Prevention**: Checkpoint C3 explicitly verifies both ledgers have matching numbers

**❌ PROBLEM: Progress checklist not updated**
- **Symptom**: Plan shows "50%" but should be "75%" after completing task
- **Root Cause**: Skipped Phase C Step C4
- **Fix**: Always count completed tasks and update § 11 Progress Checklist
- **Prevention**: Step C4 has its own checkpoint before moving to Phase D

### FAQ:

**Q: Footnote numbers seem wrong or duplicated?**
A: Check for manual edits that bypassed this command. Load state in Phase A Step A2 to find next available number.

**Q: Can I update multiple tasks at once?**
A: No, run this command once per task for accurate tracking and atomic updates.

**Q: What if I forgot to track a change?**
A: Add it in the next task's update with a note in the execution log explaining the oversight.

**Q: How to handle refactoring across multiple files?**
A: Use flowspace node IDs for each affected method/function (e.g., `method:file:Class.method`) even if just moving code.

**Q: What if the plan uses embedded tasks (no separate tasks.md)?**
A: Follow the same Phase C flow but update the embedded task table in plan.md § 8 twice: once in C1 (as the "dossier") and again in C2 (as the "plan"). Ensure ALL columns (Status/Log/Notes) are updated.

**Q: How do I know if I successfully updated all 3 locations?**
A: Run the Phase D Step D1 verification checklist. If any item is unchecked, go back and complete it.
```

Next step: Use during /plan-6-implement-phase execution
