---
phase: "Phase 3: VS Code Settings Merge"
slug: phase-3-vs-code-settings-merge
plan: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md
spec: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-spec.md
today: 2025-09-28
notes:
  template_notice: "templates/tasks-template.md referenced by commands is absent; structure mirrored manually."
---

## Tasks
| ID   | Task | Dependencies | [P] Guidance | Validation Checklist Coverage |
|------|------|--------------|--------------|-------------------------------|
| T001 | Review existing VS Code configuration logic inside `/Users/jordanknight/github/tools/install/agents.sh` (Python merge block, directory setup) and Phase 3 requirements before changes. | – | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Aligns success criteria 3.1–3.3; confirms required keys and error handling expectations |
| T002 | Author failing integration test script at `/Users/jordanknight/github/tools/tests/install/test_vscode_settings_merge.sh` to execute installer with temp `HOME`, seeding sample `settings.json` variants (valid, missing, invalid) and asserting Copilot keys/locations (expected RED). | T001 | `[P]` eligible (new file) | Covers “Settings contain required keys”, “Existing settings preserved”, “Invalid JSON handled” |
| T003 | Run `bash tests/install/test_vscode_settings_merge.sh` capturing failing output to verify guardrails before implementation. | T002 | Serial (depends on new test) | Confirms tests-first failure for settings merge acceptance |
| T004 | Update `/Users/jordanknight/github/tools/install/agents.sh` Python merge to inject `chat.promptFiles=true` and merge `chat.promptFilesLocations` with global/workspace entries without removing existing values. | T003 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Satisfies “Settings contain required keys” (Plan tasks 3.1–3.2, FR6) |
| T005 | Enhance error handling in `/Users/jordanknight/github/tools/install/agents.sh` to recover from missing or invalid `settings.json`, including backup + fresh file creation and warnings when Python unavailable. | T004 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Covers “Existing settings preserved”, “Handles missing Python gracefully” (Plan task 3.3, FR7) |
| T006 | Expand integration test to include preservation asserts + rerun scenario, then re-execute `tests/install/test_vscode_settings_merge.sh` (GREEN) capturing evidence for `execution.log.md`. | T005 | `[P]` eligible (execution + test updates) | Verifies “Basic validation passes” and idempotent behavior (Plan tasks 3.4–3.5) |

## Alignment Brief
**Objective Recap & Behavior Checklist**  
- Merge Copilot configuration into VS Code settings (`chat.promptFiles`, locations map) without overwriting user preferences.  
- Ensure installer tolerates missing/invalid settings files, logs warnings, and continues.  
- Confirm Python dependency gracefully handled (warn + skip if absent).  
- Acceptance criteria: required keys present, existing settings preserved, script resilient to error scenarios, validation tests pass.

**Invariants & Guardrails**  
- Reuse Python stdlib only; no external deps.  
- Preserve formatting by writing JSON with trailing newline (match repo conventions).  
- Never remove unrelated keys from settings; only merge required values.  
- Use real temp directories (no mocks) per repository testing philosophy.  
- For BridgeContext compliance, ensure any VS Code path handling remains cross-platform safe (macOS + Linux).  
- Logging must use existing `print_status`/`print_success`/`print_error` helpers for consistency.

**Inputs To Read**  
- `/Users/jordanknight/github/tools/install/agents.sh` (Python merge segment + directory logic).  
- `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md` (§Phase 3).  
- `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-spec.md` (FR6–FR9, NFR2–NFR4).  
- `AGENTS.md` messaging patterns (for user-facing logs).  
- Existing Phase 1/2 execution logs to maintain temp HOME conventions.

**Test Plan (TDD, tests-as-docs, no mocks, real data)**  
1. `tests/install/test_vscode_settings_merge.sh::test_settings_merge_with_existing_preferences`  
   - **Purpose**: Verify installer merges Copilot keys while preserving preexisting settings (e.g., `"editor.fontSize": 14`).  
   - **Fixture Setup**: Temp HOME + VS Code user dir seeded with JSON containing user keys.  
   - **Expected Output**: Resulting settings include original keys plus Copilot entries.  
2. `tests/install/test_vscode_settings_merge.sh::test_creates_settings_when_missing_or_invalid`  
   - **Purpose**: Ensure installer handles missing file and invalid JSON by creating fresh config with required keys and backing up invalid data.  
   - **Fixture Setup**: Start with absent file, then invalid JSON scenario.  
   - **Expected Output**: New valid settings file with Copilot keys, `.bak` backup logged.  
3. `tests/install/test_vscode_settings_merge.sh::test_python_absent_emits_warning`  
   - **Purpose**: Simulate missing `python3` (mask path) to confirm installer logs warning and skips settings update gracefully.  
   - **Expected Output**: Non-zero? (Script continues) but warns; test ensures log message present and run completes.

**Implementation Outline (maps to Tasks/Tests)**  
1. T001 → Analyze existing Python helper functions and plan acceptance criteria.  
2. T002 → Build integration test harness covering existing/preserved settings, missing files, invalid JSON, python absence.  
3. T003 → Execute harness to capture RED failure state.  
4. T004 → Modify Python merge logic to set `chat.promptFiles` and update `chat.promptFilesLocations` for global/workspace directories.  
5. T005 → Add error handling: create file when missing, backup invalid JSON, skip gracefully if python unavailable (with log).  
6. T006 → Re-run tests (GREEN), ensure rerun scenario passes & logs recorded for evidence.

**Commands To Run**  
- `bash tests/install/test_vscode_settings_merge.sh`  
- `bash tests/install/test_vscode_settings_merge.sh | tee /tmp/phase3-settings.log` (capture evidence).  
- `shellcheck tests/install/test_vscode_settings_merge.sh`  
- `git status --short`

**Risks / Unknowns**  
- *Risk*: Platform-specific VS Code paths differ (e.g., Codium) → test should abstract via env variables when feasible.  
- *Risk*: Simulating missing Python may impact other tests; ensure environment reset per test case.  
- *Unknown*: Handling Windows paths out of scope; document if coverage limited.

**Ready Check (await GO/NO-GO)**  
- [ ] Temp HOME/VS Code path strategy approved for tests.  
- [ ] Logging updates & warning messages reviewed.  
- [ ] `python3` availability/skip behavior agreed with stakeholders.  
- [ ] Acceptance criteria + test plan acknowledged.

## Phase Footnote Stubs
| Task ID | Notes |
|---------|-------|
| T002 | New VS Code settings integration test at `/Users/jordanknight/github/tools/tests/install/test_vscode_settings_merge.sh`. [^8] |
| T004 | Copilot settings merge implementation in `/Users/jordanknight/github/tools/install/agents.sh`. [^9] |
| T005 | Error-handling and warnings for VS Code settings in `/Users/jordanknight/github/tools/install/agents.sh`. [^10] |

[^8]: Placeholder – Phase 6 will document Flowspace node IDs for the VS Code settings test harness.
[^9]: Placeholder – Phase 6 will record node IDs for the Copilot settings merge logic in `install/agents.sh`.
[^10]: Placeholder – Phase 6 will record node IDs for error-handling/warning logic in `install/agents.sh`.

## Evidence Artifacts
- Phase execution log: `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/tasks/phase-3-vs-code-settings-merge/execution.log.md` (to be created during implementation).  
- Integration test harness: `/Users/jordanknight/github/tools/tests/install/test_vscode_settings_merge.sh`.  
- captured logs (e.g., `/tmp/phase3-settings.log`) or backups stored under this phase directory when produced.

```
docs/plans/001-ghcp-prompt-mirroring/
  ├── ghcp-prompt-mirroring-plan.md
  ├── ghcp-prompt-mirroring-spec.md
  └── tasks/
      ├── phase-1-directory-variable-setup/
      │   ├── tasks.md
      │   └── execution.log.md
      ├── phase-2-copy-rename-operations/
      │   ├── tasks.md
      │   └── execution.log.md
      └── phase-3-vs-code-settings-merge/
          ├── tasks.md
          └── execution.log.md  # to be created by /plan-6
```
