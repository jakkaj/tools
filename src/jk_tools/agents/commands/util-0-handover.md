---
description: Generate a comprehensive handover document for LLM agent continuity.
---

Please deep think / ultrathink as this is a complex task.

# util-0-handover

Generate a **comprehensive handover document** that enables another LLM coding agent (or the same agent after session interruption) to resume work with full context, understanding, and decision history. This command captures complete project state, execution history, and bidirectional navigation through the FlowSpace graph.

```md
User input:

$ARGUMENTS
# Expected flags:
# --plan "<path>"              # Required - path to current plan document
# --file "<path>"              # Optional - output file path (default: console)
# --format "markdown|brief"    # Optional - output format (default: markdown)
# --phase "<Phase N: Title>"   # Optional - specific phase context (default: current/latest)

**IMPORTANT**: This command uses **parallel subagent loading** for comprehensive state capture.

**Strategy**: Launch 3 state readers simultaneously (single message with 3 Task tool calls) to gather complete project context, then synthesize into handover document.

**Phase A: Parallel State Loading**

**Subagent 1 - Plan Reader**:
"Load complete plan state and metadata for handover.

**Read**: `${PLAN_PATH}` (entire plan document)

**Extract**:
- Plan metadata (ordinal, slug, dates, status)
- § 3 Critical Research Findings (all 15-20+ discoveries)
- § 6 Testing Philosophy and approach
- § 8 Progress Tracking (phase tables with task statuses)
- § 12 Change Footnotes (complete ledger with [^N] mappings)
- ADR Ledger if present (constraints and decisions)
- Phase-specific acceptance criteria
- Risk assessments and mitigation strategies

**Report** (JSON format):
```json
{
  \"plan_metadata\": {\"ordinal\": \"002\", \"slug\": \"feature-x\", \"status\": \"In Progress\"},
  \"critical_findings\": [{\"id\": \"01\", \"title\": \"...\", \"impact\": \"...\", \"solution\": \"...\"}],
  \"testing_approach\": \"TAD|TDD|Lightweight|Manual|Hybrid\",
  \"phase_progress\": {\"Phase 1\": \"100%\", \"Phase 2\": \"45%\"},
  \"footnotes\": [{\"id\": \"1\", \"task\": \"T001\", \"file\": \"/path/to/file\", \"line\": \"42\"}],
  \"adr_constraints\": [{\"adr\": \"0001\", \"constraint\": \"...\", \"affects\": \"Phase 2\"}],
  \"current_phase\": \"Phase 2: Core Implementation\",
  \"next_footnote_number\": 15
}
```
"

**Subagent 2 - Dossier Reader**:
"Load complete task dossier state for current phase.

**Read**:
- `${PLAN_DIR}/tasks/${PHASE_SLUG}/tasks.md` (complete dossier)
- Any subtask dossiers referenced in Subtasks column
- Phase Footnote Stubs section

**Extract**:
- Complete task table with all 9 columns
- Task statuses: [ ] pending, [~] in-progress, [x] complete, [!] blocked
- Dependencies graph (task IDs and relationships)
- Absolute paths for all affected files
- Validation criteria for each task
- Subtask spawning patterns
- Notes column decisions and references
- Phase footnote stubs (if any)
- Alignment brief with visual aids (Mermaid diagrams)

**Report** (JSON format):
```json
{
  \"tasks\": [
    {\"id\": \"T001\", \"status\": \"[x]\", \"task\": \"...\", \"type\": \"Setup\",
     \"dependencies\": \"--\", \"paths\": [\"/abs/path\"], \"validation\": \"...\",
     \"subtasks\": \"--\", \"notes\": \"[P] eligible\"}
  ],
  \"in_progress_tasks\": [\"T005\", \"T006\"],
  \"blocked_tasks\": [{\"id\": \"T008\", \"reason\": \"Awaiting API access\"}],
  \"completion_percentage\": 45,
  \"critical_dependencies\": {\"T010\": [\"T007\", \"T009\"]},
  \"phase_objective\": \"...\",
  \"non_goals\": [\"Performance optimization\", \"Legacy migration\"]
}
```
"

**Subagent 3 - Log Reader**:
"Load complete execution history and evidence.

**Read**:
- `${PLAN_DIR}/tasks/${PHASE_SLUG}/execution.log.md` (if exists)
- Any test output files referenced
- Evidence artifacts listed

**Extract**:
- All execution log entries with timestamps
- Task anchors (e.g., `#task-t001-setup`)
- Test execution evidence (RED→GREEN cycles)
- Implementation decisions and rationale
- Technical discoveries and gotchas
- File modifications with diffs
- Error resolutions and workarounds
- Performance metrics if captured
- Integration test results

**Report** (JSON format):
```json
{
  \"log_exists\": true,
  \"total_entries\": 42,
  \"task_anchors\": {\"T001\": \"#task-t001-setup\", \"T002\": \"#task-t002-test\"},
  \"test_evidence\": [
    {\"task\": \"T002\", \"test\": \"test_validation\", \"cycle\": \"RED→GREEN\", \"iterations\": 3}
  ],
  \"technical_discoveries\": [
    {\"task\": \"T003\", \"discovery\": \"API rate limit\", \"workaround\": \"Exponential backoff\"}
  ],
  \"file_modifications\": [
    {\"file\": \"/src/validator.py\", \"task\": \"T004\", \"lines_changed\": \"+45/-12\"}
  ],
  \"blockers_resolved\": [{\"blocker\": \"Missing dependency\", \"resolution\": \"Added to requirements.txt\"}]
}
```
"

**Wait for All Subagents**: Block until all 3 state readers complete.

**Phase B: Cross-Phase Context** (if not Phase 1)

If current phase > 1, gather cumulative context from all prior phases:

**Subagent 4 - Prior Phase Analyzer**:
"Analyze all prior phases for cumulative context.

**Read** (for each prior phase):
- `${PLAN_DIR}/tasks/${PRIOR_PHASE_SLUG}/tasks.md`
- `${PLAN_DIR}/tasks/${PRIOR_PHASE_SLUG}/execution.log.md`
- Relevant sections from main plan

**Extract**:
- Deliverables created (files, modules, APIs)
- Architectural patterns established
- Test infrastructure (fixtures, mocks, helpers)
- Technical debt accumulated
- Lessons learned and anti-patterns
- Reusable components

**Report**: Comprehensive prior phase summary with cross-phase insights
"

**Phase C: Synthesize Handover Document**

After all subagents complete, generate the handover with these 7 sections:

## 1. Session Metadata

```markdown
# Agent Handover Document

**Generated**: {{TIMESTAMP}}
**From Agent**: {{CURRENT_AGENT_ID}}
**To Agent**: {{TARGET_AGENT_ID or "Any"}}
**Session Duration**: {{DURATION}}

## Project Context
- **Plan**: `{{PLAN_PATH}}`
- **Current Phase**: {{PHASE_NAME}}
- **Feature**: {{FEATURE_SLUG}}
- **Overall Progress**: {{PERCENTAGE}}%

## Last Activity
- **Last Completed Task**: {{TASK_ID}} - {{TASK_DESCRIPTION}}
- **Last Log Entry**: {{TIMESTAMP}} - {{SUMMARY}}
- **Next Immediate Task**: {{NEXT_TASK_ID}} - {{NEXT_TASK_DESCRIPTION}}
```

## 2. Project State Snapshot

```markdown
## Project State Snapshot

### Constitution & Doctrine
- **Constitution Status**: {{ALIGNED|DEVIATION_NOTED}}
- **Rules Compliance**: {{COMPLIANT|ISSUES: [...]}}
- **Idioms Adherence**: {{FOLLOWING|EXCEPTIONS: [...]}}
- **Architecture Alignment**: {{CONSISTENT|DEVIATIONS: [...]}}

### Critical Findings (Ordered by Impact)
{{FOR EACH CRITICAL_FINDING}}
🚨 **Critical Discovery {{ID}}**: {{TITLE}}
- **Problem**: {{PROBLEM}}
- **Root Cause**: {{CAUSE}}
- **Solution**: {{SOLUTION}}
- **Impact**: {{IMPACT}}
- **Addressed in Tasks**: {{TASK_IDS}}
{{END FOR}}

### Active ADRs
{{IF ADRs EXIST}}
| ADR | Title | Status | Constraint | Affects |
|-----|-------|--------|-----------|---------|
{{FOR EACH ADR}}
| {{ID}} | {{TITLE}} | {{STATUS}} | {{CONSTRAINT}} | {{PHASES}} |
{{END FOR}}
{{ELSE}}
No ADRs currently active for this feature.
{{END IF}}

### Technical Constraints
{{FOR EACH CONSTRAINT}}
- **{{CONSTRAINT_NAME}}**: {{DESCRIPTION}} (from {{SOURCE}})
{{END FOR}}
```

## 3. Phase Progress & Status

```markdown
## Phase Progress & Status

### Current Phase: {{PHASE_NAME}}

**Completion**: {{X}}/{{Y}} tasks ({{Z}}%)

### Task Table
| Status | ID | Task | Type | Dependencies | Absolute Path(s) | Validation | Subtasks | Notes |
|--------|-----|------|------|-------------|------------------|------------|----------|-------|
{{FOR EACH TASK}}
| {{STATUS}} | {{ID}} | {{TASK}} | {{TYPE}} | {{DEPS}} | {{PATHS}} | {{VALIDATION}} | {{SUBTASKS}} | {{NOTES}} |
{{END FOR}}

### Status Summary
- ✅ **Completed**: {{COMPLETED_TASKS}}
- 🔄 **In Progress**: {{IN_PROGRESS_TASKS}}
- ⏸️ **Pending**: {{PENDING_TASKS}}
- 🚫 **Blocked**: {{BLOCKED_TASKS}}

### Critical Dependencies for Next Tasks
{{FOR EACH CRITICAL_DEP}}
- **{{TASK_ID}}** depends on: {{DEPENDENCY_LIST}}
  - Rationale: {{WHY_CRITICAL}}
{{END FOR}}

### Blockers & Mitigation
{{FOR EACH BLOCKER}}
❌ **{{BLOCKER_ID}}**: {{DESCRIPTION}}
  - Blocking: {{AFFECTED_TASKS}}
  - Mitigation: {{MITIGATION_STRATEGY}}
  - ETA: {{ESTIMATED_RESOLUTION}}
{{END FOR}}
```

## 4. Execution Context

```markdown
## Execution Context

### Execution Log Summary
- **Total Entries**: {{COUNT}}
- **Log Location**: `{{LOG_PATH}}`
- **Last Updated**: {{TIMESTAMP}}

### Key Decisions & Rationale
{{FOR EACH DECISION}}
**Task {{TASK_ID}}**: {{DECISION}}
- **Rationale**: {{WHY}}
- **Alternatives Considered**: {{ALTERNATIVES}}
- **Impact**: {{IMPACT}}
- **Log Reference**: [View in log]({{LOG_PATH}}#{{ANCHOR}})
{{END FOR}}

### Test Execution Evidence
{{IF TAD_APPROACH}}
#### TAD Cycles (RED→GREEN)
{{FOR EACH TEST_CYCLE}}
**{{TEST_NAME}}** (Task {{TASK_ID}}):
- Initial State: 🔴 RED - {{FAILURE_REASON}}
- Iterations: {{COUNT}}
- Final State: 🟢 GREEN - {{SUCCESS_CRITERIA_MET}}
- Evidence: `{{TEST_OUTPUT_PATH}}`
{{END FOR}}
{{END IF}}

### Implementation Patterns Established
{{FOR EACH PATTERN}}
- **{{PATTERN_NAME}}**: {{DESCRIPTION}}
  - Used in: {{FILE_LIST}}
  - Rationale: {{WHY_THIS_PATTERN}}
{{END FOR}}

### Mock Usage Patterns
- **Policy**: {{AVOID|TARGETED|LIBERAL}}
- **Mocks Created**: {{MOCK_LIST}}
- **Real Data Used**: {{REAL_DATA_SOURCES}}
```

## 5. FlowSpace Graph State

```markdown
## FlowSpace Graph State (Bidirectional Navigation)

### Footnote Ledger
| [^N] | Task | File | Line/Function | Node ID |
|------|------|------|---------------|---------|
{{FOR EACH FOOTNOTE}}
| [^{{N}}] | {{TASK_ID}} | {{FILE}} | {{LINE}} | {{NODE_ID}} |
{{END FOR}}

### Task→File Mappings
{{FOR EACH TASK_WITH_FILES}}
**{{TASK_ID}}**: {{TASK_DESCRIPTION}}
  → Modified Files:
  {{FOR EACH FILE}}
  - `{{FILE_PATH}}` ({{LINES_CHANGED}}) [^{{FOOTNOTE_REF}}]
  {{END FOR}}
{{END FOR}}

### File→Task Reverse Mappings
{{FOR EACH FILE}}
**`{{FILE_PATH}}`**:
  ← Modified by Tasks:
  {{FOR EACH TASK}}
  - {{TASK_ID}}: {{CHANGE_DESCRIPTION}} [^{{FOOTNOTE_REF}}]
  {{END FOR}}
{{END FOR}}

### Log Anchor References
{{FOR EACH TASK}}
- {{TASK_ID}}: [{{LOG_PATH}}#task-{{TASK_ID_LOWER}}]({{LOG_PATH}}#task-{{TASK_ID_LOWER}})
{{END FOR}}
```

## 6. Gotchas & Learnings

```markdown
## Gotchas & Learnings

### Deviations from Plan
{{FOR EACH DEVIATION}}
**{{TASK_ID}}**: {{PLANNED}} → {{ACTUAL}}
- **Reason**: {{WHY_DEVIATED}}
- **Impact**: {{IMPACT_ASSESSMENT}}
- **Approved By**: {{APPROVAL_REFERENCE}}
{{END FOR}}

### Technical Discoveries
{{FOR EACH DISCOVERY}}
🔍 **Discovery**: {{TITLE}}
- **Context**: Found during {{TASK_ID}}
- **Issue**: {{PROBLEM_DESCRIPTION}}
- **Solution**: {{RESOLUTION}}
- **Future Impact**: {{WHAT_TO_WATCH_FOR}}
{{END FOR}}

### Testing Challenges & Solutions
{{FOR EACH CHALLENGE}}
**Challenge**: {{DESCRIPTION}}
- **Encountered In**: {{TASK_ID}}
- **Initial Approach**: {{FAILED_APPROACH}}
- **Successful Approach**: {{WORKING_SOLUTION}}
- **Reusable Pattern**: {{YES_NO_DESCRIPTION}}
{{END FOR}}

### Patterns to Maintain
✅ **DO Continue**:
{{FOR EACH GOOD_PATTERN}}
- {{PATTERN}}: {{WHY_GOOD}}
{{END FOR}}

### Anti-patterns to Avoid
❌ **DON'T Repeat**:
{{FOR EACH BAD_PATTERN}}
- {{ANTI_PATTERN}}: {{WHY_BAD}} (Alternative: {{BETTER_APPROACH}})
{{END FOR}}
```

## 7. Next Actions

```markdown
## Next Actions (Priority Order)

### Immediate Next Task
**Task {{NEXT_TASK_ID}}**: {{TASK_DESCRIPTION}}
- **Type**: {{TASK_TYPE}}
- **Dependencies**: {{DEPENDENCY_STATUS}}
- **Validation Criteria**: {{SUCCESS_CRITERIA}}
- **Estimated Effort**: {{TIME_ESTIMATE}}

### Command to Resume Work
```bash
# Resume implementation for current phase
/plan-6-implement-phase --phase "{{CURRENT_PHASE}}" --plan "{{PLAN_PATH}}"

# Or continue specific task
/plan-6-implement-phase --phase "{{CURRENT_PHASE}}" --plan "{{PLAN_PATH}}" --task "{{NEXT_TASK_ID}}"
```

### Pre-flight Checklist
Before starting {{NEXT_TASK_ID}}, verify:
- [ ] Dependencies {{DEPENDENCY_LIST}} are complete
- [ ] Tests for dependencies are passing
- [ ] No blocking issues in {{BLOCKER_CHECK}}
- [ ] Review notes in task table for {{NEXT_TASK_ID}}
- [ ] Check if ADR constraints apply ({{ADR_CHECK}})

### Upcoming Tasks (Next 5)
1. {{TASK_1_ID}}: {{TASK_1_DESC}} ({{TASK_1_DEPS}})
2. {{TASK_2_ID}}: {{TASK_2_DESC}} ({{TASK_2_DEPS}})
3. {{TASK_3_ID}}: {{TASK_3_DESC}} ({{TASK_3_DEPS}})
4. {{TASK_4_ID}}: {{TASK_4_DESC}} ({{TASK_4_DEPS}})
5. {{TASK_5_ID}}: {{TASK_5_DESC}} ({{TASK_5_DEPS}})

### Phase Completion Criteria
To complete {{CURRENT_PHASE}}:
{{FOR EACH CRITERION}}
- [ ] {{CRITERION}}
{{END FOR}}
```

## 8. Prior Phases Summary (if applicable)

```markdown
{{IF PRIOR_PHASES}}
## Prior Phases Summary

### Phase Evolution
{{FOR EACH PRIOR_PHASE}}
**{{PHASE_NAME}}** ({{COMPLETION}}% complete):
- **Deliverables**: {{DELIVERABLE_LIST}}
- **Key Decisions**: {{DECISION_SUMMARY}}
- **Reusable Assets**: {{ASSET_LIST}}
{{END FOR}}

### Cumulative Technical Debt
{{FOR EACH DEBT_ITEM}}
- **{{DEBT_ID}}**: {{DESCRIPTION}} (from {{PHASE}})
  - Impact: {{IMPACT}}
  - Priority: {{HIGH|MEDIUM|LOW}}
{{END FOR}}

### Cross-Phase Dependencies
```mermaid
graph TD
{{FOR EACH DEPENDENCY}}
    {{FROM_PHASE}} --> {{TO_PHASE}}
{{END FOR}}
```
{{END IF}}
```

**File Output Logic**:

```bash
# Parse arguments
PLAN_PATH=$(extract_flag "--plan")
FILE_PATH=$(extract_flag "--file")  # Optional
FORMAT=$(extract_flag "--format" "markdown")  # Default: markdown
PHASE=$(extract_flag "--phase")  # Optional, defaults to current/latest

# Validate plan exists
if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ Error: Plan not found at $PLAN_PATH"
  exit 1
fi

# Generate handover content
HANDOVER_CONTENT=$(synthesize_from_subagent_reports)

# Output handling
if [ -n "$FILE_PATH" ]; then
  # File output requested
  mkdir -p $(dirname "$FILE_PATH")
  echo "$HANDOVER_CONTENT" > "$FILE_PATH"
  echo "✅ Handover document written to: $FILE_PATH"
  echo "📋 Use this file to onboard the next agent with full context"
else
  # Console output (default)
  echo "$HANDOVER_CONTENT"
fi
```

**Validation Requirements**:
- All 7 sections must be present
- Bidirectional links must be valid
- Task statuses must be current
- Footnote references must resolve
- Log anchors must exist if referenced
- File paths must be absolute

**Success Criteria**:
- Handover captures complete state
- Another agent can resume without context loss
- All decisions and learnings preserved
- Testing evidence included
- Next actions clearly defined
```

Next step: The receiving agent uses this handover to understand context and executes the suggested resume command.