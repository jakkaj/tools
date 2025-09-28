---
phase: "Phase 1: Directory & Variable Setup"
slug: phase-1-directory-variable-setup
plan: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md
spec: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-spec.md
today: 2025-09-28
notes:
  prerequisite_script: "scripts/bash/check-prerequisites.sh --json (missing; see Ready Check)"
---

## Tasks
| ID   | Task | Dependencies | [P] Guidance | Validation Checklist Coverage |
|------|------|--------------|--------------|-------------------------------|
| T001 | Review existing directory creation + messaging logic in `/Users/jordanknight/github/tools/install/agents.sh` to determine safe insertion points for Copilot variables and outputs. | – | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Preps acceptance alignment for variables + logging before edits |
| T002 | Create failing integration test script at `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` (and enclosing directory) that runs the installer with a temporary `HOME`, asserting Copilot global/workspace paths exist. | T001 | `[P]` eligible (isolated new test asset) | Covers “Basic validation passes” & “Copilot directories created” (expected FAIL pre-impl) |
| T003 | Execute the new test (e.g., `bash tests/install/test_agents_copilot_dirs.sh`) to document the pre-implementation failure signal. Capture output for evidence later. | T002 | Serial (depends on test creation) | Confirms TDD gate for “Basic validation passes” |
| T004 | Define `COPILOT_GLOBAL_DIR` and `COPILOT_WORKSPACE_DIR` plus associated status printouts inside `/Users/jordanknight/github/tools/install/agents.sh`, preserving cross-platform logic. | T003 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Satisfies acceptance: “Variables properly defined” (FR1, FR2) |
| T005 | Implement `mkdir -p` creation + existence logs for the Copilot directories in `/Users/jordanknight/github/tools/install/agents.sh`, following existing messaging idioms. | T004 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Satisfies acceptance: “Copilot directories created” (FR1, FR2) |
| T006 | Add non-fatal permission/error handling around Copilot directory creation in `/Users/jordanknight/github/tools/install/agents.sh` with warnings that allow continuation. | T005 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Satisfies acceptance: “Script continues on errors” (NFR4) |
| T007 | Re-run `tests/install/test_agents_copilot_dirs.sh` with controlled `HOME` and workspace path to verify success; stage outputs for `execution.log.md` during Plan 6. | T006 | `[P]` eligible (execution only) | Verifies full acceptance checklist + idempotent rerun behavior |

## Alignment Brief
**Objective Recap & Behavior Checklist**  
- Mirror plan deliverables: introduce Copilot directory variables, ensure directories exist, and log status.  
- Acceptance criteria to meet: variables defined, directories created, errors handled gracefully, validation test passes.

**Invariants & Guardrails**  
- Preserve existing destinations/copy behavior—no regressions in Claude/OpenCode/Codex/VSC directories.  
- Maintain idempotent `mkdir -p` semantics; avoid destructive deletes.  
- Honor existing messaging style (`print_status`/`print_success`).  
- No mocked filesystems—use temporary real directories per rules; maintain cross-platform compatibility.  
- BridgeContext reminder: when VS Code integrations arrive, prefer bounded `vscode.RelativePattern`/`Uri` usage (not in scope this phase but keep future alignment).

**Inputs To Read**  
- `/Users/jordanknight/github/tools/install/agents.sh` (current directory + logging patterns).  
- `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md` (§Phase 1).  
- `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-spec.md` (FR1–FR4, NFR4).  
- Repository conventions in `AGENTS.md` for installer messaging tone.  
- (Template note) `templates/tasks-template.md` referenced in command docs is absent; maintain template parity manually.

**Test Plan (TDD, tests-as-docs, no mocks, real data)**  
1. `tests/install/test_agents_copilot_dirs.sh::test_copilot_directories_created`  
   - **Purpose**: Validate installer defines variables and creates Copilot directories under controlled `HOME`/workspace.  
   - **Fixture Setup**: `TMP_HOME=$(mktemp -d)`; `WORKSPACE=$(mktemp -d)`; link repo into workspace to simulate `.github`.  
   - **Execution**: `HOME="$TMP_HOME" REPO_ROOT="$WORKSPACE" bash ./install/agents.sh`.  
   - **Expected Output**: Non-zero exit from assertions if directories missing; success prints status messages containing Copilot paths.  
2. `tests/install/test_agents_copilot_dirs.sh::test_idempotent_rerun` (optional within same script)  
   - **Purpose**: Ensure rerunning installer does not fail when directories already exist.  
   - **Fixture Setup**: Reuse directories from prior test without cleanup.  
   - **Execution**: Re-run installer; check no duplicate errors; verify logs show “already exists”.  
   - **Expected Output**: Pass without additional warnings beyond info logs.

**Implementation Outline (maps to Tasks/Tests)**  
1. T001 → Annotate insertion points in `install/agents.sh`.  
2. T002 → Author integration test harness, ensuring shell exit codes propagate.  
3. T003 → Execute test to observe failing assertions; document actual vs expected outputs.  
4. T004 → Add variable definitions + printouts above directory creation block.  
5. T005 → Extend directory creation block for Copilot paths, mirroring existing pattern.  
6. T006 → Wrap `mkdir` calls with guarded error handling (`if ! mkdir -p ...; then print_error ...; continue`).  
7. T007 → Run test suite; confirm green; capture log snippets for later `execution.log.md`.

**Commands To Run**  
- `HOME=$(mktemp -d) WORKDIR=$(mktemp -d) bash tests/install/test_agents_copilot_dirs.sh`  
- `shellcheck tests/install/test_agents_copilot_dirs.sh` (keep scripts lint-clean).  
- `git status --short` (sanity before GO/NO-GO).  
- Note: Attempted `scripts/bash/check-prerequisites.sh --json` failed (file missing).

**Risks / Unknowns**  
- *Risk*: Test harness may modify actual `$HOME`; **Mitigation**: always export temporary `HOME` within script.  
- *Risk*: Permissions on real user config paths may differ; **Mitigation**: log warnings, allow continuation.  
- *Unknown*: Absent prerequisite script indicates tooling drift; confirm with maintainer before depending on it.

**Ready Check (await GO/NO-GO)**  
- [x] Manual override approved for missing `scripts/bash/check-prerequisites.sh` (documented in execution log).  
- [x] Workspace parents for `/Users/jordanknight/github/tools/tests/install/` created.  
- [x] Temporary HOME strategy validated through integration harness.  
- [x] Acceptance criteria + test plan executed (see `execution.log.md`).

## Phase Footnote Stubs
| Task ID | Notes |
|---------|-------|
| T002 | Copilot directory integration test at `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` ensures installer provisions global/workspace prompts. [^1] |
| T004 | Copilot directory variables and status messaging defined in `/Users/jordanknight/github/tools/install/agents.sh`. [^2] |
| T005 | Copilot directory creation logic added with idempotent handling in `/Users/jordanknight/github/tools/install/agents.sh`. [^3] |
| T006 | Copilot directory permission warning + continue-on-failure logic added in `/Users/jordanknight/github/tools/install/agents.sh`. [^4] |

[^1]: T002 – Added integration harness for Copilot directories.
  - `file:tests/install/test_agents_copilot_dirs.sh`
[^2]: T004 – Introduced Copilot directory variables and logging targets.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^3]: T005 – Added Copilot directory creation logic with `mkdir -p` idempotency.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^4]: T006 – Added non-fatal permission handling for Copilot directories.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`

## Evidence Artifacts
- Phase execution log: `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/tasks/phase-1-directory-variable-setup/execution.log.md`.
- Integration test harness: `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh`.
- Test run outputs: captured within `execution.log.md` (T003 failure, T007 success).

```
docs/plans/001-ghcp-prompt-mirroring/
  ├── ghcp-prompt-mirroring-plan.md
  ├── ghcp-prompt-mirroring-spec.md
  └── tasks/
      └── phase-1-directory-variable-setup/
          ├── tasks.md
          └── execution.log.md  # created by /plan-6
```
