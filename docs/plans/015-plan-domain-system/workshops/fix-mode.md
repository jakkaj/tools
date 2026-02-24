# Workshop: Fix Mode for plan-5-v2

**Type**: CLI Flow + Integration Pattern
**Plan**: 015-plan-domain-system
**Created**: 2026-02-24
**Status**: Draft

**Domain Context**:
- **Primary Domain**: Plan workflow commands
- **Related Domains**: All v2 commands (consume fix artifacts)

---

## Purpose

Design a lightweight **fix mode** for plan-5-v2 that enables small, tracked fixes without the overhead of full plan creation. Fixes are smaller than subtasks — they're for things like "rename this variable across 3 files" or "add error handling to the API endpoint" — work that needs doing, tracking, and reviewing, but not a full spec→plan→phase cycle.

## Key Questions Addressed

- What's the difference between a fix, a subtask, and a phase?
- What artifacts does a fix produce?
- How are fixes tracked for posterity?
- How does fix mode interact with domains?
- Can fixes be reviewed?
- Where do fixes live in the file tree?

---

## 1. Fix vs Subtask vs Phase

| | Fix | Subtask | Phase |
|---|---|---|---|
| **Size** | 1-5 tasks, ~30 min work | 3-10 tasks, focused breakdown | 5-20 tasks, major deliverable |
| **Trigger** | Bug, small enhancement, review fix-task | Task blocked, needs deeper breakdown | Plan milestone |
| **Parent** | Plan (or standalone) | Phase task | Plan |
| **Needs spec?** | No | No (inherits from phase) | Yes |
| **Needs plan-3?** | No | No (inherits from plan) | Yes |
| **Flight plan?** | Yes (mini) | Yes | Yes |
| **Execution log?** | Yes | Yes | Yes |
| **Code review?** | Yes (can run plan-7-v2) | Yes | Yes |
| **Domain aware?** | Yes | Yes | Yes |

### When to Use Fix Mode

- Bug fix that touches 1-3 files
- Small enhancement within an existing domain
- Addressing review findings (fix-tasks.md from plan-7-v2)
- Quick refactor with clear scope
- Config change that needs tracking
- Documentation fix with domain context

### When NOT to Use Fix Mode

- Work needs its own acceptance criteria → use a plan
- Touches 5+ domains → use a plan
- Requires research/discovery → use plan-1a + plan
- Changes domain contracts → use a phase (contract changes are high-risk)

---

## 2. Fix Artifacts

```
docs/plans/<ordinal>-<slug>/
  └── fixes/
      ├── FX001-fix-auth-timeout.md          # Fix dossier
      ├── FX001-fix-auth-timeout.fltplan.md   # Mini flight plan
      ├── FX001-fix-auth-timeout.log.md       # Execution log
      ├── FX002-add-billing-validation.md
      ├── FX002-add-billing-validation.fltplan.md
      └── FX002-add-billing-validation.log.md
```

Or standalone (no parent plan):
```
docs/fixes/
  ├── FX001-fix-auth-timeout.md
  ├── FX001-fix-auth-timeout.fltplan.md
  └── FX001-fix-auth-timeout.log.md
```

### Fix Dossier (the main artifact)

```markdown
# Fix FX001: Fix Auth Token Timeout

**Created**: 2026-02-24
**Status**: Proposed | Approved | In Progress | Complete
**Plan**: [link to parent plan, or "Standalone"]
**Source**: [what prompted this — review finding, bug report, user request]
**Domain(s)**: auth (modify), _platform (consume)

---

## Problem

[2-3 sentences: What's broken or missing? Why does it matter?]

## Proposed Fix

[2-5 sentences: What will be changed and how? Enough for the user to
approve or reject before implementation starts.]

## Domain Impact

| Domain | Relationship | What Changes |
|--------|-------------|-------------|
| auth | modify | Add timeout config to TokenService |
| _platform | consume | Use IConfig for timeout value |

## Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | FX001-1 | Add timeout config | auth | /abs/path/src/auth/token-service.ts | Timeout configurable | |
| [ ] | FX001-2 | Add config entry | _platform | /abs/path/config/auth.yaml | Default timeout = 30s | |
| [ ] | FX001-3 | Add test for timeout | auth | /abs/path/tests/auth/token-timeout.test.ts | Test verifies timeout behavior | |

## Workshops Consumed

[If any workshops informed this fix — link them]
- None

## Acceptance

- [ ] Token requests timeout after configured duration
- [ ] Default timeout is 30 seconds
- [ ] Existing tests still pass

## Discoveries & Learnings

_Populated during implementation._

| Date | Task | Type | Discovery | Resolution |
|------|------|------|-----------|------------|
```

### Mini Flight Plan

```markdown
# Flight Plan: Fix FX001 — Fix Auth Token Timeout

**Fix**: [link to fix dossier]
**Status**: Ready

## What → Why

**Problem**: Auth tokens never timeout, causing stale sessions.
**Fix**: Add configurable timeout to TokenService using _platform IConfig.

## Domain Context

| Domain | Relationship | What Changes |
|--------|-------------|-------------|
| auth | modify | TokenService timeout |
| _platform | consume | IConfig |

## Stages

- [ ] Add timeout config to TokenService
- [ ] Add config entry with default
- [ ] Add timeout test

## Acceptance

- [ ] Timeout works with configured duration
- [ ] Default 30s
- [ ] Existing tests pass
```

### Execution Log

Same format as phase execution logs — per-task entries with evidence.

---

## 3. Invocation

```bash
# Fix within a plan
/plan-5-v2 --fix "Fix auth token timeout" --plan "/abs/path/plan.md"

# Fix from review findings
/plan-5-v2 --fix "Address review findings" --plan "/abs/path/plan.md" --from-review "/abs/path/reviews/fix-tasks.md"

# Standalone fix (no parent plan)
/plan-5-v2 --fix "Fix auth token timeout"

# List existing fixes
/plan-5-v2 --fix --list --plan "/abs/path/plan.md"
```

---

## 4. Fix Mode Flow

```
F1) Resolve paths:
    - If --plan: FIX_DIR = PLAN_DIR/fixes/
    - If standalone: FIX_DIR = docs/fixes/ (create if missing)
    - FIX_ORD = next available FX### ordinal
    - FIX_SLUG = kebab-case summary
    - FIX_FILE = ${FIX_DIR}/FX${ORD}-${FIX_SLUG}.md

F2) If --from-review: load fix-tasks.md and present to user
    - Show fix tasks from review
    - User selects which to address (may group related fixes)

F3) Load domain context:
    - Read docs/domains/registry.md and domain-map.md (if exist)
    - Identify which domains this fix touches
    - Read relevant domain.md for contracts and composition
    - Check if fix affects domain contracts (flag as higher risk)

F4) Quick codebase check:
    - Read the files that will be changed
    - Verify they exist and belong to expected domains
    - NO full pre-implementation audit (too heavy for a fix)
    - NO prior-phase review (fixes are self-contained)

F5) Workshop consumption:
    - If --plan exists, check PLAN_DIR/workshops/ for relevant workshops
    - If workshop exists for the domain/topic, note it in fix dossier
    - Workshops inform the fix approach but aren't required

F6) Write fix dossier (FIX_FILE):
    - Problem, Proposed Fix, Domain Impact, Tasks, Acceptance
    - User reviews the PROPOSAL before implementation

F7) Generate mini flight plan:
    - ${FIX_DIR}/FX${ORD}-${FIX_SLUG}.fltplan.md
    - What→Why, Domain Context, Stages, Acceptance

F8) Create empty execution log:
    - ${FIX_DIR}/FX${ORD}-${FIX_SLUG}.log.md

F9) Register fix:
    - If parent plan exists: add to plan's Fixes section (create if missing)
    - Format:
      | ID | Created | Summary | Domain(s) | Status | Source |
      |----|---------|---------|-----------|--------|--------|

STOP: Output fix dossier. Wait for user APPROVE before implementation.
```

---

## 5. Implementation & Review

After user approves:

```bash
# Implement the fix
/plan-6-v2 --fix "FX001" --plan "/abs/path/plan.md"
# or standalone:
/plan-6-v2 --fix "FX001"

# Review the fix
/plan-7-v2 --fix "FX001" --plan "/abs/path/plan.md"
```

plan-6-v2 implementation:
- Reads the fix dossier
- Follows same domain placement rules as phase implementation
- Updates execution log per task
- Updates domain.md and domain-map.md if needed
- Updates fix status to Complete

plan-7-v2 review:
- Reads fix dossier instead of phase dossier
- Same subagents (scoped to fix's files)
- Lighter output (no cross-phase regression since fixes are self-contained)
- Still validates domain compliance

---

## 6. Tracking & Posterity

### In the Parent Plan

```markdown
## Fixes

| ID | Created | Summary | Domain(s) | Status | Source |
|----|---------|---------|-----------|--------|--------|
| FX001 | 2026-02-24 | Fix auth token timeout | auth, _platform | ✅ Complete | Bug report |
| FX002 | 2026-02-25 | Add billing validation | billing | 🔄 In Progress | Review FT-003 |
```

### In the Domain

Fix completion updates domain.md § History:
```markdown
| FX001 | Fixed token timeout in TokenService | 2026-02-24 |
```

### Discoverability

Fixes are discoverable via:
- Parent plan's Fixes section
- Domain.md § History entries (prefixed with FX###)
- `fixes/` directory listing
- Execution logs for audit trail

---

## 7. Key Design Decisions

### Why not just use subtask mode?

Subtasks are scoped to a phase — they need a parent task, they live inside a phase directory, and they assume the full plan/phase infrastructure exists. Fixes are lighter:
- Can be standalone (no plan needed)
- Don't need a parent task
- Have their own directory (`fixes/`)
- Have a simpler proposal→approve→implement→review flow
- Can consume review fix-tasks directly

### Why require approval before implementation?

The fix dossier shows the **proposed** change before any code is touched. This lets the user:
- Reject the approach and suggest alternatives
- Adjust scope (add/remove tasks)
- Confirm domain impact is acceptable
- Ensure the fix doesn't secretly become a feature

### Why track fixes separately from plan tasks?

Fixes are often cross-cutting or late-arriving. Shoehorning them into existing phase task tables:
- Breaks task numbering continuity
- Confuses the phase's execution log
- Makes code review scope unclear
- Loses the "what prompted this fix" context

---

## Resolved Questions

### Q1: Should fixes have their own ordinal sequence?

**RESOLVED**: Yes — FX001, FX002, etc. Separate from T### (tasks) and ST### (subtasks). The FX prefix makes fixes instantly identifiable in logs, domain history, and plan tracking.

### Q2: Can a fix touch multiple domains?

**RESOLVED**: Yes, but each domain touch should be a separate task within the fix. If the fix touches 5+ domains, it's probably not a fix — it's a phase.

### Q3: Should fixes get their own code review?

**RESOLVED**: Yes — plan-7-v2 supports `--fix` flag. Same subagents, scoped to the fix's files. Domain compliance is still validated.
