# Feature Specification: GitHub Copilot Agent Command Mirroring

Spec Version: 1.0.0  
Date: 2025-09-28  
Status: Clarified / Ready for Architecture  
Feature ID: ghcp-prompt-mirroring

## Executive Summary
Currently agent command markdown files (`agents/commands/*.md`) are mirrored to multiple AI assistant homes (Claude, OpenCode, Codex, VS Code project). They are not discoverable by GitHub Copilot Chat because Copilot only loads prompt files ending in `.prompt.md` located in its configured prompt search paths. This feature adds automated mirroring of all agent command files into the Copilot per-user prompt directory with the correct file extension. Simplicity and idempotence drive the design: no filtering, no rollback, overwrite existing.

## Problem Statement
Developers using GitHub Copilot cannot access the curated agent command prompts maintained for other assistants, leading to fractured experience and duplicated manual effort.

## Goals (WHAT)
- Mirror every existing and future `agents/commands/*.md` file into the Copilot-recognized global directory with `.prompt.md` suffix.
- Ensure visibility across repositories via the global prompt directory without additional manual steps.
- Enable VS Code configuration automatically while preserving existing user settings. *(Deferred; users may configure manually.)*
- Maintain backward compatibility with current destinations.

## Non-Goals (Explicitly Out of Scope)
- Prompt content changes or refactors.
- Selective filtering or ignoring specific commands.
- Rollback / uninstall mechanism (idempotent reruns suffice).
- Telemetry, analytics, or usage tracking.
- Performance optimizations beyond straightforward copying.

## User Stories
### Story 1: Copilot User
As a developer in VS Code using Copilot Chat, I want all agent commands available as slash prompts so I can reuse established workflows.
Acceptance:
- After running installer, typing `/plan-1-specify` (example) in Copilot Chat shows corresponding prompt content.

### Story 2: Multi-Repository Developer
As a developer switching repositories frequently, I want a global prompt library so I have consistent prompts everywhere without repeating setup per repo.
Acceptance:
- All prompts appear across repos after one install run.

### Story 3: Onboarding Contributor
As a new contributor cloning a project, I want repository prompts version-controlled and auto-discoverable so I get immediate productivity.
Acceptance:
- Copilot global prompt directory contains repository prompts after script run.

## Functional Requirements (FR)
| ID | Requirement |
|----|-------------|
| FR1 | Define global directory: `~/.config/github-copilot/prompts/` (create if missing). |
| FR2 | (Retired 2025-09-28) Workspace copies are no longer created; installer must not write to `<repo>/.github/prompts/`. |
| FR3 | For each `agents/commands/<name>.md`, copy to the Copilot global destination as `<name>.prompt.md`. |
| FR4 | Preserve original copies to existing destinations (Claude, OpenCode, Codex, `.vscode`). |
| FR5 | Overwrite existing prompt files on rerun (idempotent). |
| FR6 | (Deferred) VS Code settings merge removed; users manage `chat.promptFiles` manually. |
| FR7 | Provide console summary including Copilot prompt counts. |
| FR8 | Exit successfully even if VS Code settings directory absent (log warning, continue). |

## Non-Functional Requirements (NFR)
| ID | Requirement |
|----|-------------|
| NFR1 | Idempotent: Multiple runs produce identical resultant files (apart from timestamps/messages). |
| NFR2 | Simplicity: Single script modification; no new external dependencies beyond existing Python 3 usage. |
| NFR3 | Cross-Platform: macOS + Linux + WSL path handling via existing uname logic. |
| NFR4 | Safety: Failures on individual file copies log and continue; only catastrophic initialization errors abort. |
| NFR5 | Maintainability: All logic localized to `install/agents.sh`; no new scripts introduced. |

## Assumptions
- Python 3 available (already relied upon elsewhere in script).
- User has write permissions to home configuration directories.
- GitHub Copilot extension handles `.prompt.md` files per current public preview behavior.

## Constraints
- Must not commit `.github/prompts/` within the tools repository itself.
- Must not introduce configuration flags for this first iteration.

## Testing Strategy

**Approach**: Lightweight
**Rationale**: This feature is fundamentally a file copy operation with simple JSON merging. Full TDD would be overkill for such straightforward operations. Basic validation tests are sufficient.
**Focus Areas**:
- Verify files are copied to correct locations with correct names
- Confirm VS Code settings are properly merged
- Validate idempotent behavior
**Excluded**:
- Unit tests for individual functions
- Extensive mock-based testing
- Performance benchmarks

## Clarifications (Session 2025-09-28)
| # | Topic | Decision | Impact |
|---|-------|----------|--------|
| 1 | Command filtering | Mirror all | Simplifies logic (FR3/FR5) |
| 2 | Global path configurability | Hardcoded path | Reduces complexity (FR1) |
| 3 | Rollback | None (idempotent) | No uninstall branch needed (NFR1) |
| 4 | Settings merge strategy | Merge & add paths | Preserves user config (FR6) |
| 5 | Repo `.github/prompts` presence | Skipped | Workspace copies removed; rely on global directory (FR2 retired) |
| 6 | Testing approach | Lightweight | Simple operations don't need TDD (see Testing Strategy) |

## Edge Cases
- Existing prompt file present with outdated content -> overwritten.
- Invalid JSON in settings -> replaced with new valid file containing required keys.
- Missing Python -> settings update skipped with warning; copying still succeeds.
- No source `.md` files -> script logs zero count and exits success.

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Copilot path convention changes | Low | Medium | Encapsulate variables; future update simple. |
| User settings concurrency (VS Code writing file simultaneously) | Low | Low | Atomic write via Python replace pattern; accept retry requirement manually. |
| Permission issues in home config | Low | Medium | Log explicit error; user resolves permissions. |

## Success Metrics
- 100% of source command files produce `.prompt.md` outputs in the Copilot global prompt directory.
- Rerun diff on output directories is empty.
- Verified presence of required keys in settings file.

## Out of Scope Follow-Ups (Potential Future Enhancements)
- Environment variable override for global path.
- Selective directory inclusion / exclude patterns.
- Telemetry on prompt usage.
- Automated documentation updates.

---

This specification intentionally excludes implementation details of copying mechanics, focusing strictly on desired outcomes (WHAT) and rationale (WHY).
