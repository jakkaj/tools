---
phase: "Phase 2: Copy & Rename Operations"
slug: phase-2-copy-rename-operations
plan: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md
spec: /Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-spec.md
today: 2025-09-28
notes:
  template_notice: "templates/tasks-template.md referenced in plan commands is not present; structure reproduced manually."
---

## Tasks
| ID   | Task | Dependencies | [P] Guidance | Validation Checklist Coverage |
|------|------|--------------|--------------|-------------------------------|
| T001 | Review existing copy loops and destination handling in `/Users/jordanknight/github/tools/install/agents.sh` plus Phase 2 acceptance notes before modifying logic. | – | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Aligns with plan tasks 2.1–2.3; confirms success criteria and invariants before edits |
| T002 | Extend `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` to assert `.prompt.md` files appear in Copilot global directory and original `.md` copies persist elsewhere (expected RED). | T001 | Serial (shared `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh`) | Covers “All files copied”, “Files have .prompt.md extension”, “Existing destinations intact” |
| T003 | Execute updated test harness (`bash tests/install/test_agents_copilot_dirs.sh`) capturing failing output for evidence and verifying guardrails. | T002 | Serial (depends on new test expectations) | Confirms tests-first failure for copy/rename acceptance |
| T004 | Update `/Users/jordanknight/github/tools/install/agents.sh` to copy each source command into Copilot global path with `.prompt.md` renaming while preserving existing destinations. | T003 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Satisfies “All files copied”, “Files have .prompt.md extension”, retains FR4 destinations |
| T005 | Enhance progress logging and idempotent safeguards in `/Users/jordanknight/github/tools/install/agents.sh` for Copilot copies (per-plan task 2.3 & 2.5). | T004 | Serial (shared `/Users/jordanknight/github/tools/install/agents.sh`) | Addresses “User sees activity”, “Script runs without errors”, “Idempotent execution works” |
| T006 | Re-run `tests/install/test_agents_copilot_dirs.sh` within temporary HOME to confirm GREEN results and capture logs for `execution.log.md`. | T005 | `[P]` eligible (execution-only; no file edits) | Verifies all acceptance criteria and idempotent rerun behavior |

## Alignment Brief
**Objective Recap & Behavior Checklist**  
- Mirror all `agents/commands/*.md` files to the Copilot global directory using `.prompt.md` suffix.  
- Maintain existing destinations (Claude/OpenCode/Codex/VS Code) and overwrite semantics.  
- Provide progress output while ensuring loops remain idempotent and robust to special characters.  
- Acceptance criteria: global copies exist, renamed endings `.prompt.md`, script runs cleanly across reruns.

**Invariants & Guardrails**  
- No filtering or skipping of source files (FR3).  
- Quote paths to tolerate spaces or special characters; rely on existing `print_*` helpers.  
- Preserve existing copy destinations exactly (FR4).  
- Overwrite on rerun without prompting (FR5).  
- Avoid mocks; operate on real temp directories during tests, per repository testing philosophy.  
- BridgeContext reminder: keep changes shell-compatible across macOS/Linux; any future VS Code interactions must use bounded `vscode.RelativePattern` / `vscode.Uri` conventions (not directly touched this phase).

**Inputs To Read**  
- `/Users/jordanknight/github/tools/install/agents.sh` (copy loops & logging patterns).  
- `/Users/jordanknight/github/tools/agents/commands/` (source files to mirror).  
- `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-plan.md` (§Phase 2 details).  
- `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/ghcp-prompt-mirroring-spec.md` (FR3–FR5, NFR1–NFR3).  
- `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` (Phase 1 harness to extend).

**Test Plan (TDD, tests-as-docs, no mocks, real data)**  
1. `tests/install/test_agents_copilot_dirs.sh::test_copilot_prompts_copied_and_renamed`  
   - **Purpose**: Assert each `agents/commands/*.md` source produces `.prompt.md` copies in the Copilot global destination.  
   - **Fixture Setup**: Temporary HOME + workspace (as in Phase 1); snapshot source filenames.  
   - **Execution**: `HOME="$TMP_HOME" bash ./install/agents.sh`.  
   - **Expected Output**: Matching counts between source `.md` files and Copilot global `.prompt.md` copies; sample file existence (e.g., `plan-1-specify.prompt.md`).  
2. `tests/install/test_agents_copilot_dirs.sh::test_existing_destinations_preserved`  
   - **Purpose**: Ensure original `.md` copies for Claude/OpenCode/Codex/VS Code remain unchanged.  
   - **Fixture Setup**: Reuse temporary workspace; check `.md` counts in existing directories.  
   - **Expected Output**: Source count equals destination count for legacy paths.  
3. `tests/install/test_agents_copilot_dirs.sh::test_copilot_idempotent_rerun`  
   - **Purpose**: Confirm rerunning installer leaves contents stable and logs show “already exists” messaging.  
   - **Execution**: Run installer twice; diff directories or check timestamps unchanged; capture log snippet.  
   - **Expected Output**: Second run exit 0, no duplicate warnings beyond expected status.

**Implementation Outline (maps to Tasks/Tests)**  
1. T001 → Catalog current copy loop + logging for precise insert locations.  
2. T002 → Extend integration harness with new assertions (tests-first).  
3. T003 → Run harness to observe failing expectations; archive output.  
4. T004 → Introduce Copilot copy loop with `.prompt.md` renaming + quoting; reuse variable definitions from Phase 1.  
5. T005 → Add progress echoing (e.g., `[↻ Copilot]`) and ensure rerun semantics/no errors; update test log expectations if needed.  
6. T006 → Execute harness (GREEN), rerun for idempotency, capture passthrough logs for execution evidence.

**Commands To Run**  
- `bash tests/install/test_agents_copilot_dirs.sh`  
- `bash tests/install/test_agents_copilot_dirs.sh | tee /tmp/phase2-phase.log` (capture reference logs).  
- `shellcheck tests/install/test_agents_copilot_dirs.sh`  
- `git status --short` (sanity check before GO/NO-GO)  
- Optional: `rg "prompt.md" -n /Users/jordanknight/github/tools/install/agents.sh` after edits to verify coverage.

**Risks / Unknowns & Rollback Plan**  
- *Risk*: Quoting errors could mis-handle filenames with spaces → cover via tests using sample filenames and double quotes.  
- *Risk*: Temporary workspace cleanup failure could leave fixtures behind → ensure traps remove directories.  
- *Rollback*: `git restore install/agents.sh tests/install/test_agents_copilot_dirs.sh`; remove temporary log captures.

**Ready Check (await GO/NO-GO)**  
- [x] Test harness extension plan acknowledged (real temporary HOME/workspace).  
- [x] Agreement on logging format updates before implementation.  
- [x] `shellcheck` availability confirmed (installed via Homebrew).  
- [x] Acceptance criteria + test plan executed (see `execution.log.md`).

## Phase Footnote Stubs
| Task ID | Notes |
|---------|-------|
| T002 | Copilot global copy/rename assertions added to `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh`. [^5] |
| T004 | Copilot `.prompt.md` copy loop introduced in `/Users/jordanknight/github/tools/install/agents.sh`. [^6] |
| T005 | Copilot progress + idempotency logging updates in `/Users/jordanknight/github/tools/install/agents.sh`. [^7] |

[^5]: T002 – Extended integration harness for Copilot prompt verification.
  - `file:tests/install/test_agents_copilot_dirs.sh`
[^6]: T004 – Added Copilot copy loop and rename handling.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`
[^7]: T005 – Enhanced Copilot progress messaging and idempotent logging.
  - `file:install/agents.sh`
  - `function:install/agents.sh:main`

## Evidence Artifacts
- Phase execution log: `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/tasks/phase-2-copy-rename-operations/execution.log.md`.  
- Extended integration test harness: `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh`.  
- Shell lint output: `shellcheck tests/install/test_agents_copilot_dirs.sh` (success noted in execution log).  
- Optional run logs: place under `/Users/jordanknight/github/tools/docs/plans/001-ghcp-prompt-mirroring/tasks/phase-2-copy-rename-operations/` as needed.

```
docs/plans/001-ghcp-prompt-mirroring/
  ├── ghcp-prompt-mirroring-plan.md
  ├── ghcp-prompt-mirroring-spec.md
  └── tasks/
      ├── phase-1-directory-variable-setup/
      │   ├── tasks.md
      │   └── execution.log.md
      └── phase-2-copy-rename-operations/
          ├── tasks.md
          └── execution.log.md
```
