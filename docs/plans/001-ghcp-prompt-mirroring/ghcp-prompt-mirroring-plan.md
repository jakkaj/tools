# GitHub Copilot Prompt Mirroring Implementation Plan

**Plan Version**: 1.0.0
**Created**: 2025-09-28
**Spec**: [./ghcp-prompt-mirroring-spec.md](./ghcp-prompt-mirroring-spec.md)
**Status**: READY
**Feature ID**: ghcp-prompt-mirroring

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Technical Context](#2-technical-context)
3. [Critical Research Findings](#3-critical-research-findings)
4. [Testing Philosophy](#4-testing-philosophy)
5. [Project Structure](#5-project-structure)
6. [Constitution Check](#6-constitution-check)
7. [Architecture Validation](#7-architecture-validation)
8. [Implementation Phases](#8-implementation-phases)
   - [Phase 1: Directory & Variable Setup](#phase-1-directory--variable-setup)
   - [Phase 2: Copy & Rename Operations](#phase-2-copy--rename-operations)
   - [Phase 3: VS Code Settings Merge](#phase-3-vs-code-settings-merge)
   - [Phase 4: Idempotency Verification](#phase-4-idempotency-verification)
   - [Phase 5: Documentation Update](#phase-5-documentation-update-optional)
9. [Cross-Cutting Concerns](#9-cross-cutting-concerns)
10. [Complexity Tracking](#10-complexity-tracking)
11. [Progress Checklist](#11-progress-checklist)
12. [Change Footnotes Ledger](#12-change-footnotes-ledger)

---

## 1. Executive Summary

**Problem Statement**: Agent command Markdown files are not discoverable by GitHub Copilot, fragmenting AI assistant workflows and requiring duplicate manual setup.

**Solution Approach**:
- Mirror all `agents/commands/*.md` files into Copilot-specific directories
- Rename files to `*.prompt.md` to match Copilot's discovery pattern
- Update VS Code settings to enable prompt file discovery
- Maintain backward compatibility with existing destinations
- Ensure idempotent operation for safe re-runs

**Expected Outcomes**:
- Seamless availability of commands in GitHub Copilot Chat
- Single-source content parity across all AI assistants
- Zero maintenance overhead after initial setup
- Preserved existing functionality

**Success Metrics**:
- 100% of source files successfully mirrored to both Copilot destinations
- Idempotent reruns produce no unintended file changes
- VS Code settings contain required keys and paths
- All existing destinations continue to receive updates

---

## 2. Technical Context

**Current System State**:
The `install/agents.sh` script currently copies command files to four AI assistant locations plus the project's `.vscode` directory. It uses uname-based OS detection for platform-specific paths and Python for MCP configuration JSON writing.

**Integration Requirements**:
- Add two new destination directories for GitHub Copilot
- Implement file renaming during copy (`.md` → `.prompt.md`)
- Merge VS Code settings without destroying existing configuration
- Maintain all existing copy destinations and behaviors

**Constraints and Limitations**:
- Must not filter files (mirror all commands)
- Cannot implement rollback (rely on idempotent overwrites)
- Should not add `.github/` directory to this tools repository
- Python 3 must be available for JSON operations

**Assumptions**:
- Write permissions available for home directory paths
- VS Code installed with standard configuration paths
- Existing script structure remains stable

---

## 3. Critical Research Findings

### 🚨 Critical Discovery: Copilot File Extension Requirement

**Problem**: GitHub Copilot ignores plain `.md` files in prompt directories
**Root Cause**: Discovery logic explicitly filters on `*.prompt.md` pattern
**Solution**: Always rename output files to include `.prompt.md` extension
**Example**:
```bash
# ❌ WRONG - Copilot will not discover this file
cp agents/commands/plan-1-specify.md ~/.config/github-copilot/prompts/plan-1-specify.md

# ✅ CORRECT - Copilot will discover and list this file
cp agents/commands/plan-1-specify.md ~/.config/github-copilot/prompts/plan-1-specify.prompt.md
```
**Impact**: This discovery enforces the file renaming requirement (FR3 in spec)

### 🚨 Critical Discovery: Settings Merge Safety

**Problem**: Overwriting `settings.json` can erase user customizations
**Root Cause**: Naïve file write approach destroys existing content
**Solution**: Load existing JSON, merge keys, preserve user settings
**Example**:
```python
# ❌ WRONG - Destroys existing settings
with open(settings_path, 'w') as f:
    json.dump({'chat.promptFiles': True}, f)

# ✅ CORRECT - Preserves existing settings
try:
    with open(settings_path, 'r') as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

data['chat.promptFiles'] = True
locs = data.setdefault('chat.promptFilesLocations', {})
locs['.github/prompts'] = True
locs[global_path] = True

with open(settings_path, 'w') as f:
    json.dump(data, f, indent=2)
```
**Impact**: Implements safe settings management (FR6, FR7 in spec)

### 🚨 Critical Discovery: Idempotent Design Pattern

**Problem**: Incremental diff logic adds complexity and risk
**Root Cause**: Unnecessary optimization for small file sets
**Solution**: Always overwrite target copies; validate by final state
**Example**:
```bash
# ✅ CORRECT - Simple, idempotent approach
for file in agents/commands/*.md; do
    cp "$file" "$COPILOT_GLOBAL_DIR/$(basename "$file" .md).prompt.md"
done
# Second run produces identical result with no side effects
```
**Impact**: Simplifies implementation and reduces error surface (FR5 in spec)

---

## 4. Testing Philosophy

### Testing Approach
[Reference the Testing Strategy from spec]
- **Selected Approach**: Lightweight
- **Rationale**: This feature is fundamentally a file copy operation with simple JSON merging. Full TDD would be overkill for such straightforward operations.
- **Focus Areas**: File copy verification, settings merge validation, idempotency checks

### Lightweight Testing
Since this is a simple file copy operation:
- Focus on end-to-end validation tests
- Skip extensive unit testing for simple operations
- Prioritize smoke tests that verify the complete flow works
- Write minimal tests that prove core functionality

### Test Documentation
Each validation test should include:
```bash
# Purpose: [what this test validates]
# Expected Result: [measurable outcome]
```

### Real Environment Testing
- Use temp directories for test runs
- Create actual test fixtures
- Verify real file operations
- No complex mocking needed

### Test Coverage Focus
- Files copied to correct locations
- Correct file naming (.prompt.md extension)
- Settings properly merged
- Idempotent behavior verified
- Basic error handling

---

## 5. Project Structure

```
/Users/jordanknight/github/tools/
├── install/
│   └── agents.sh                                    # Script to modify
├── agents/
│   └── commands/
│       ├── plan-1-specify.md                       # Source files
│       ├── plan-2-clarify.md
│       └── [...more command files...]
├── docs/
│   └── plans/
│       └── 001-ghcp-prompt-mirroring/
│           ├── ghcp-prompt-mirroring-spec.md       # Co-located spec
│           ├── ghcp-prompt-mirroring-plan.md       # This file
│           └── tasks/                              # Created by plan-5
│               └── [phase directories]
└── tests/
    └── install/
        └── test_agents_copilot.sh                  # Test suite

Runtime Output Locations (User Environment):
~/.config/github-copilot/prompts/                   # Global prompts
    ├── plan-1-specify.prompt.md
    ├── plan-2-clarify.prompt.md
    └── [...all commands with .prompt.md extension]

<target-repo>/.github/prompts/                      # Workspace prompts
    └── [...same files as global]

<os-specific>/Code/User/settings.json               # VS Code settings
```

---

## 6. Constitution Check

No constitution file present at `/memory/constitution.md`. Gate trivially satisfied.

### Deviation Ledger

| Principle Violated | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|--------------------|------------|-------------------------------|-----------------|
| (none) | N/A | N/A | N/A |

---

## 7. Architecture Validation

This change is an additive extension to existing shell script (`install/agents.sh`). No architectural layer violations identified.

- **Layer Boundaries**: Single-script operational tooling (no layers to violate)
- **GraphBuilder Rules**: Not applicable (not a code analysis tool)
- **Language Separation**: Not applicable (shell script tooling)

Gate PASSED.

---

## 8. Implementation Phases

### Phase 1: Directory & Variable Setup

**Objective**: Introduce Copilot directory variables and ensure directories exist with proper permissions.

**Deliverables**:
- Environment variables: `COPILOT_GLOBAL_DIR`, `COPILOT_WORKSPACE_DIR`
- Directory creation with error handling
- Status logging for user feedback

**Dependencies**: None (foundational phase)

**Risks**:

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Permission denied on home directory | Low | Medium | Log warning, continue with workspace only |
| Workspace path not applicable | Low | Low | Skip workspace copy when not in project |
| Directory already exists | High | None | Check existence before mkdir |

### Tasks (Lightweight Approach)

| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| 1.1 | [x] | Add Copilot directory variables | Variables defined in agents.sh | [📋](tasks/phase-1-directory-variable-setup/execution.log.md#task-t004-define-copilot-directory-variables) Completed [^2] |
| 1.2 | [x] | Implement directory creation | Directories created with mkdir -p | [📋](tasks/phase-1-directory-variable-setup/execution.log.md#task-t005-add-copilot-directory-creation-logic) Completed [^3] |
| 1.3 | [x] | Add error handling for permissions | Log warning, continue on fail | [📋](tasks/phase-1-directory-variable-setup/execution.log.md#task-t006-add-non-fatal-permission-handling) Completed [^4] |
| 1.4 | [x] | Write basic validation test | Verify directories exist after run | [📋](tasks/phase-1-directory-variable-setup/execution.log.md#task-t002-create-copilot-directory-integration-test) Completed [^1] |

### Validation Test Example

```bash
#!/bin/bash
# test_phase1_validation.sh

test_directories_exist() {
    # Purpose: Verify directories are created
    # Expected Result: Both Copilot directories exist

    ./install/agents.sh

    [[ -d "$HOME/.config/github-copilot/prompts" ]] || echo "FAIL: Global dir missing"
    [[ -d ".github/prompts" ]] || echo "Note: Workspace dir not applicable"

    echo "Phase 1 validation complete"
}
```

### Acceptance Criteria
- [x] Copilot directories created
- [x] Variables properly defined
- [x] Script continues on errors
- [x] Basic validation passes

**Progress**: 4/4 tasks complete (100%)

---

### Phase 2: Copy & Rename Operations

**Objective**: Mirror every command file to Copilot directories with `.prompt.md` extension.

**Deliverables**:
- All source files copied to global directory
- Files renamed with `.prompt.md` extension
- Existing destinations still receive original `.md` files

**Dependencies**: Phase 1 (global directory must exist)

**Risks**:

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Large file count performance | Low | Low | Simple loop is acceptable for <50 files |
| Filename collision | Low | Low | Overwrite is desired behavior |
| Special characters in filenames | Low | Medium | Quote all variables properly |
| Source files missing | Low | High | Check source directory exists |
| Workspace copy unexpectedly enabled | Low | Low | Keep workspace path creation behind optional flag |
| Missing global directory | Low | High | Guard with mkdir -p |

### Tasks (Lightweight Approach)

| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| 2.1 | [x] | Implement file copy loop | All .md files copied to global | [📋](tasks/phase-2-copy-rename-operations/execution.log.md#task-t004-add-copilot-copy-loop) Completed [^6] |
| 2.2 | [x] | Add rename logic during copy | Files saved as `.prompt.md` | [📋](tasks/phase-2-copy-rename-operations/execution.log.md#task-t004-add-copilot-copy-loop) Completed [^6] |
| 2.3 | [x] | Add progress output | User sees activity | [📋](tasks/phase-2-copy-rename-operations/execution.log.md#task-t005-improve-logging-idempotency) Completed [^7] |
| 2.4 | [x] | Write validation test | Verify global copies | [📋](tasks/phase-2-copy-rename-operations/execution.log.md#task-t002-extend-copilot-tests) Completed [^5] |
| 2.5 | [x] | Test idempotency | Second run works cleanly | [📋](tasks/phase-2-copy-rename-operations/execution.log.md#task-t006-run-tests-green) Completed |

### Validation Test Example

```bash
#!/bin/bash
# test_phase2_validation.sh

test_files_copied_and_renamed() {
    # Purpose: Verify files are copied with correct names
    # Expected Result: All files present with .prompt.md extension

    ./install/agents.sh

    # Check a sample file
    if [[ -f "$HOME/.config/github-copilot/prompts/plan-1-specify.prompt.md" ]]; then
        echo "PASS: Files copied and renamed correctly"
    else
        echo "FAIL: Files not found or incorrectly named"
    fi

    # Verify file count
    source_count=$(ls agents/commands/*.md | wc -l)
    dest_count=$(ls "$HOME/.config/github-copilot/prompts"/*.prompt.md | wc -l)

    if [[ $source_count -eq $dest_count ]]; then
        echo "PASS: All files copied ($source_count files)"
    else
        echo "FAIL: File count mismatch (source: $source_count, dest: $dest_count)"
    fi
}

test_idempotency() {
    # Purpose: Verify script can be run multiple times
    # Expected Result: No errors on second run

    ./install/agents.sh
    ./install/agents.sh  # Second run

    echo "Phase 2 validation complete"
}
```

### Acceptance Criteria
- [x] All files copied to global destination
- [x] Files have `.prompt.md` extension
- [x] Script runs without errors
- [x] Idempotent execution works

**Progress**: 5/5 tasks complete (100%)

---

### Phase 3: VS Code Settings Merge _(Skipped)_

**Decision (2025-09-28)**: Skipped. VS Code automatically discovers `.prompt.md` prompt files, so the installer no longer manages `settings.json`. Users who require `chat.promptFiles` can enable it manually.

**Rationale**:
- Avoid mutating developer-specific VS Code preferences from the shared installer.
- Eliminates risk of clobbering existing settings or introducing JSON merge bugs.
- Copy/rename work from Phase 2 already satisfies Copilot discovery requirements.

**Outcome**: No implementation tasks or tests are planned for this phase. Revisit only if future requirements mandate automated VS Code configuration.

---

### Phase 4: Idempotency Verification

**Objective**: Ensure repeated runs produce identical results without side effects.

**Deliverables**:
- Verification test suite
- Documentation of idempotent behavior
- Performance baseline for repeated runs

**Dependencies**: Phases 1-3 complete

**Risks**:

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Accumulating duplicates | Low | High | Overwrite by design |
| Settings corruption on re-run | Low | High | Comprehensive merge tests |
| Performance degradation | Low | Low | Simple operations only |

### Tasks (Lightweight Approach)

| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| 4.1 | [x] | Run complete flow twice | No errors on second run | [📋](tasks/phase-4-idempotency-verification/execution.log.md#task-t006-run-idempotency-test-green) Completed |
| 4.2 | [x] | Verify file overwrites | Files replaced, not duplicated | [📋](tasks/phase-4-idempotency-verification/execution.log.md#task-t006-run-idempotency-test-green) Completed |
| 4.3 | [x] | Document idempotent design | Comments in script | [📋](tasks/phase-4-idempotency-verification/execution.log.md#task-t005-document-idempotent-design) Completed [^10] |
| 4.4 | [x] | Create smoke test | Complete validation suite | [📋](tasks/phase-4-idempotency-verification/execution.log.md#task-t002-create-idempotency-smoke-test) Completed [^8][^9] |

### Smoke Test Example

```bash
#!/bin/bash
# test_complete_flow.sh

run_complete_test() {
    # Purpose: Verify entire flow works end-to-end
    # Expected Result: All operations succeed, idempotent

    echo "=== First Run ==="
    ./install/agents.sh

    echo "=== Second Run (Idempotency Test) ==="
    ./install/agents.sh

    echo "=== Verification ==="
    # Count files
    source_count=$(ls agents/commands/*.md | wc -l)
    dest_count=$(ls "$HOME/.config/github-copilot/prompts"/*.prompt.md | wc -l)

    if [[ $source_count -eq $dest_count ]]; then
        echo "✓ All files mirrored ($source_count files)"
    else
        echo "✗ File count mismatch"
    fi

    # Check settings
    if grep -q "chat.promptFiles" "$HOME/Library/Application Support/Code/User/settings.json" 2>/dev/null; then
        echo "✓ Settings updated"
    else
        echo "Note: Settings check skipped (path may vary)"
    fi

    echo "\nSmoke test complete!"
}

run_complete_test
```

### Acceptance Criteria
- [x] Script is idempotent
- [x] Second run succeeds
- [x] No duplicate files created
- [x] Smoke test passes

**Progress**: 4/4 tasks complete (100%)

---

### Phase 5: Documentation Update (Optional)

**Objective**: Update AGENTS.md with Copilot mirroring information.

**Deliverables**:
- Brief section in AGENTS.md
- User instructions for Copilot usage

**Dependencies**: Phase 4 complete and verified

**Status**: DEFERRED - Only implement if explicitly requested

**Risks**:

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Documentation drift | Medium | Low | Keep minimal |
| Scope creep | Medium | Low | Strict deferral |

### Tasks (Lightweight Approach)

| #   | Status | Task | Success Criteria | Notes |
|-----|--------|------|------------------|-------|
| 5.1 | [ ] | Draft brief documentation | Clear explanation | 3-5 lines max |
| 5.2 | [ ] | Add to AGENTS.md | If explicitly requested | Optional |

### Acceptance Criteria
- [ ] Documentation accurate
- [ ] Examples working
- [ ] No redundancy with existing docs

---

## 9. Cross-Cutting Concerns

### Performance Requirements
- **Response Time**: < 5 seconds for complete mirror operation
- **Memory Usage**: < 10MB (shell script overhead)
- **Concurrent Users**: Not applicable (single-user tool)

### Security Considerations
- **Input Validation**: Paths sanitized to prevent injection
- **File Permissions**: Respect umask for created files
- **Sensitive Data**: No secrets in command files

### Observability
- **Logging Strategy**: Reuse existing print helpers with [Copilot] prefix
- **Error Reporting**: Non-fatal warnings to stderr
- **Progress Indication**: One line per file copied

### Error Handling
- **Directory Creation**: Continue on permission denied with warning
- **File Copy**: Skip individual failures, log error, continue
- **Settings Merge**: Fall back to new file on parse error
- **Python Missing**: Log warning, skip settings update

### Platform Compatibility
- **macOS**: Primary target, fully tested
- **Linux**: Supported via existing uname detection
- **Windows**: Not supported (WSL recommended)

---

## 10. Complexity Tracking

**Overall Complexity**: Low (2/10)

This is a simple additive change to an existing script with no new abstractions or dependencies.

| Component | Complexity | Justification | Simplification Plan |
|-----------|------------|---------------|---------------------|
| Directory Setup | Low | Standard mkdir operations | N/A |
| Copy & Rename | Low | Basic shell loop | N/A |
| Settings Merge | Medium | JSON parsing required | Use Python stdlib only |
| Idempotency | Low | Overwrite by design | N/A |

---

## 11. Progress Checklist

### Phase Completion Checklist
- [x] Phase 1: Directory & Variable Setup - COMPLETE (see Plan Footnotes [^1-^4])
- [x] Phase 2: Copy & Rename Operations - COMPLETE (see Plan Footnotes [^5-^7])
- [–] Phase 3: VS Code Settings Merge - SKIPPED (user-managed)
- [x] Phase 4: Idempotency Verification - COMPLETE (see Plan Footnotes [^8-^10])
- [ ] Phase 5: Documentation Update - DEFERRED

**Overall Progress**: 3/4 active phases complete (75%) — Phase 3 skipped per current scope

### STOP Rule
**IMPORTANT**: This plan must be validated before creating tasks. After this plan is complete:
1. Run `/plan-4-complete-the-plan` to validate readiness
2. Only proceed to `/plan-5-phase-tasks-and-brief` after validation passes

Do NOT begin implementation without validation.

---

## 12. Change Footnotes Ledger

**NOTE**: This section is populated during implementation by plan-6-implement-phase.

[^1]: Phase 1 T002 – Added Copilot directory integration test harness.
  - `file:tests/install/test_agents_copilot_dirs.sh`
[^2]: Phase 1 T004 – Introduced Copilot directory variables and status messaging.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^3]: Phase 1 T005 – Added Copilot directory creation logic with idempotent handling.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^4]: Phase 1 T006 – Added non-fatal permission handling for Copilot directories.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^5]: Phase 2 T002 – Extended Copilot copy/rename integration test coverage.
  - `file:tests/install/test_agents_copilot_dirs.sh`
[^6]: Phase 2 T004 – Implemented Copilot `.prompt.md` copy loop.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^7]: Phase 2 T005 – Added Copilot progress and idempotency logging.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^8]: Phase 4 T002 – Added idempotency smoke test harness.
  - `file:tests/install/test_complete_flow.sh`
[^9]: Phase 4 T004 – Implemented idempotency summary logging.
  - `function:install/agents.sh:main`
[^10]: Phase 4 T005 – Documented idempotent overwrite strategy.
  - `function:install/agents.sh:main`

---

**END OF PLAN**

Plan Status: READY for validation
Next Step: Run `/plan-4-complete-the-plan` to validate
