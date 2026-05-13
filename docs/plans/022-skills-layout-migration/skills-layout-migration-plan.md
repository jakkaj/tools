# Skills-Layout Migration Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-05-13
**Spec**: [skills-layout-migration-spec.md](skills-layout-migration-spec.md)
**Status**: IMPLEMENTED (2 ACs deferred to post-merge: live setup.sh smoke + npx skills smoke)

## Summary

Migrate 27 skills from flat `agents/v2-commands/*.md` to categorized `skills/<category>/<slug>/SKILL.md` at repo root (matching `mattpocock/skills` layout). Gut all skill-fan-out logic from the installer (~1100 LOC across 4 source files plus 2 test files deleted entirely). Add deprecation markers to legacy `agents/commands/` and `agents/commands-lite/`. Refresh the five top-level docs (`README.md`, `AGENTS.md`, `CLAUDE.md`, new `INSTALL.md`, new `MIGRATION.md`). End state: a single-purpose repo where skills *are* the product, distributed via `npx skills@latest add jakkaj/tools`, and the installer carries no skill-specific code.

## Target Domains

Conceptual domains (no formal `docs/domains/<slug>/domain.md` files exist or are created in this plan).

| Domain | Status | Relationship | Role |
|---|---|---|---|
| `skills-authoring` | NEW (conceptual) | create | Owns the `skills/` source tree, SKILL.md frontmatter contract, category conventions, slug rules |
| `skills-distribution` | existing (conceptual) | modify | Shrinks dramatically — fan-out logic deleted; MCP-config deployment + dev-tool installers preserved |
| `legacy-commands` | existing (conceptual) | modify | Deprecation markers added to `agents/commands/` and `agents/commands-lite/`; no deletion |
| `package-cli` | existing (conceptual) | modify | `--commands-local` flag removed from `src/jk_tools/cli.py`; agent-install path removed from `setup_manager.py` |
| `repo-docs` | existing (conceptual) | modify | All 5 top-level docs refreshed; 2 NEW (`INSTALL.md`, `MIGRATION.md`); 4 v2-commands skip-list docs moved to `docs/skills-pipeline/` |

## Domain Manifest

Every file this plan introduces, modifies, or deletes.

### NEW Files

| File | Domain | Classification | Rationale |
|---|---|---|---|
| `/Users/jordanknight/github/tools/skills/SDD/<27-dirs>/SKILL.md` | skills-authoring | contract | Migrated v2 skills, kebab-case slug = leaf folder = `name:` field |
| `/Users/jordanknight/github/tools/skills/general/grill-me/SKILL.md` | skills-authoring | contract | Migrated from `other-skills/grill-me.md` |
| `/Users/jordanknight/github/tools/skills/personal/shopping-hunter/SKILL.md` | skills-authoring | contract | Migrated from `other-skills/shopping-hunter.md` |
| `/Users/jordanknight/github/tools/INSTALL.md` | repo-docs | contract | Agent-readable install pattern catalog (AC #15) |
| `/Users/jordanknight/github/tools/MIGRATION.md` | repo-docs | contract | Existing-`./setup.sh` user cleanup note (AC #14) |
| `/Users/jordanknight/github/tools/agents/commands/DEPRECATED.md` | legacy-commands | internal | Short stub pointer (Q7 default) |
| `/Users/jordanknight/github/tools/agents/commands-lite/DEPRECATED.md` | legacy-commands | internal | Short stub pointer (Q7 default) |
| `/Users/jordanknight/github/tools/docs/skills-pipeline/README.md` | repo-docs | internal | Moved from `agents/v2-commands/README.md`, retitled |
| `/Users/jordanknight/github/tools/docs/skills-pipeline/getting-started.md` | repo-docs | internal | Moved from `agents/v2-commands/GETTING-STARTED.md`, retitled |
| `/Users/jordanknight/github/tools/docs/skills-pipeline/changes.md` | repo-docs | internal | Moved from `agents/v2-commands/changes.md` |
| `/Users/jordanknight/github/tools/docs/skills-pipeline/codebase.md` | repo-docs | internal | Moved from `agents/v2-commands/codebase.md` |
| `/Users/jordanknight/github/tools/scripts/migrate-skills.py` | skills-authoring | internal | One-shot migration script; deleted after use OR kept under `scripts/` for replay/audit |

### MODIFIED Files

| File | Domain | Classification | Rationale |
|---|---|---|---|
| `/Users/jordanknight/github/tools/install/agents.sh` | skills-distribution | internal | Delete ~750 LOC of skill fan-out; preserve ~328 LOC of MCP config + boilerplate |
| `/Users/jordanknight/github/tools/setup_manager.py` | package-cli | internal | Delete `_install_local_commands_python()` + commands-local branching (~117 LOC) |
| `/Users/jordanknight/github/tools/src/jk_tools/cli.py` | package-cli | contract | Delete `--commands-local` + `--local-dir` args (~12 LOC) |
| `/Users/jordanknight/github/tools/scripts/sync-to-dist.sh` | skills-distribution | internal | Delete v2-commands rsync block (~11 LOC) |
| `/Users/jordanknight/github/tools/setup.sh` | skills-distribution | contract | Add one-line note: "Skills installed separately — see INSTALL.md" (Q6 default) |
| `/Users/jordanknight/github/tools/README.md` | repo-docs | contract | Light refresh; point at INSTALL.md; drop ./setup.sh skill claims |
| `/Users/jordanknight/github/tools/AGENTS.md` | repo-docs | contract | Substantial rewrite — public agent-facing project guide |
| `/Users/jordanknight/github/tools/CLAUDE.md` | repo-docs | contract | Substantial rewrite — dev-facing contributor guide |

### DELETED Files / Dirs

| Path | Reason |
|---|---|
| `/Users/jordanknight/github/tools/agents/v2-commands/` (entire dir, 31 files) | Source migrated to `skills/SDD/`; 4 skip-list docs moved to `docs/skills-pipeline/` |
| `/Users/jordanknight/github/tools/other-skills/` (entire dir, 2 files) | Both migrated to `skills/general/` and `skills/personal/` |
| `/Users/jordanknight/github/tools/src/jk_tools/agents/v2-commands/` | Dist mirror obsolete; sync-to-dist no longer mirrors this path |
| `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` (202 lines) | Tests Copilot CLI skill generation that's being deleted |
| `/Users/jordanknight/github/tools/tests/install/test_complete_flow.sh` (98 lines) | Tests `--commands-local` flow that's being deleted |

## Key Findings

| # | Impact | Finding | Action |
|---|---|---|---|
| F01 | Critical | **Tangled constant**: `COPILOT_CLI_MCP_CONFIG` (install/agents.sh:105) is named for Copilot CLI but is actually MCP config infrastructure. Must NOT be deleted with the rest of the Copilot CLI skills constants. | Task T010 explicitly preserves this constant and (optionally) renames to `MCP_COPILOT_CLI_CONFIG` for future clarity. Audit all 5 refs (lines 105, 323, 517, 537–538, 640–641, 650–651) |
| F02 | High | **Precise cut-line inventory exists** (external-research subagent, 2026-05-13): per-file DELETE and KEEP line ranges and function names. Plan tasks reference these explicitly. | Use the inventory verbatim during T009–T015 |
| F03 | High | **`install/agents.sh` MCP generator (`generate_mcp_configs`, lines 248–656) consumes Copilot CLI config path** — the dir creation logic at lines 935–943 must stay, but the skills dir creation at lines 946–964 must go. | T009 includes a sub-step to verify MCP-related dir creation paths are preserved |
| F04 | Medium | **No test coverage gap risk** — both test files are pure skill-fan-out validation; deleting them does not remove any meaningful regression coverage for the kept code paths (MCP, dev-tool installers). The kept code has no test coverage today either. | Optional T018: add a lightweight `test_no_skill_fanout.sh` asserting `./setup.sh` does NOT write skills to `$HOME` |
| F05 | Medium | **`scripts/sync-to-dist.sh` keeps mirroring `agents/commands/`** even after migration (v1 commands stay during deprecation). Only the `agents/v2-commands/` block (lines 62–72) is deleted. | T013 deletes lines 62–72 only — preserve all other rsync blocks |
| F06 | Medium | **All 29 installable v2 slugs are unique** (verified during plan-1a). No category-flattening collision on `npx skills` install. | T008 adds a slug-collision linter as a guard for future additions |
| F07 | Low | **`setup_manager.py` `get_installers()` comment (line 229–233)** notes "agents.sh on Windows is not directly invokable, use Python fallback." After migration, this comment becomes obsolete. | T011 updates the comment to reflect new reality |
| F08 | Low | **Body migration verification**: a deterministic script (T002) is cheaper and less error-prone than 27 manual moves. Use Python + `pyyaml` to preserve byte-perfect bodies with frontmatter insertion. | T002 produces `scripts/migrate-skills.py`; T027 verifies byte-diff post-migration |

## Implementation

**Objective**: Move 27+2 skills to `skills/<category>/<slug>/SKILL.md`, delete all skill-fan-out logic (~1190 LOC across 6 files), refresh all 5 top-level docs, deprecate `agents/commands*` directories with markers — in a single coherent change set.

**Testing Approach**: Lightweight (Q2 default).
- Verify outcomes, not implementation: file counts, frontmatter shape, byte-perfect body preservation, `setup.sh` exit code, grep assertions on stale strings.
- Manual smoke tests: `./setup.sh` end-to-end, `npx skills add jakkaj/tools` from outside repo.
- No new unit tests; both existing installer tests are deleted (their subject matter is gone).
- Optional addition: thin `test_no_skill_fanout.sh` for future regression coverage.

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|---|---|---|---|---|---|---|
| [x] | T001 | Add deprecation marker to `agents/commands/` | legacy-commands | `/Users/jordanknight/github/tools/agents/commands/DEPRECATED.md` | File exists with short-stub content: deprecation paragraph + pointer to `/Users/jordanknight/github/tools/skills/` + note that deletion is planned in a future cleanup | Q7 default A. Signals intent BEFORE migration starts so any concurrent reader sees the direction |
| [x] | T002 | Add deprecation marker to `agents/commands-lite/` | legacy-commands | `/Users/jordanknight/github/tools/agents/commands-lite/DEPRECATED.md` | File exists with same template as T001, adapted to "lite pipeline" | Q7 default A |
| [x] | T003 | Write migration script | skills-authoring | `/Users/jordanknight/github/tools/scripts/migrate-skills.py` | Script with 3 explicit source-mappings: (a) `agents/v2-commands/*.md` (minus the 4 skip-list files) → `skills/SDD/<stem>/SKILL.md`; (b) `other-skills/grill-me.md` → `skills/general/grill-me/SKILL.md`; (c) `other-skills/shopping-hunter.md` → `skills/personal/shopping-hunter/SKILL.md`. For each output: frontmatter is `name: <leaf-folder-name>` + original `description:` preserved verbatim, body byte-identical to source (only the original frontmatter block is replaced). **Idempotency contract**: if dest `SKILL.md` already exists with byte-identical content, skip silently and log `[skip] <slug>`; if it exists with DIFFERENT content, error and exit non-zero (no overwrite without explicit `--force` flag) | Python 3 + `pyyaml` only — no other deps. F08. Will be deleted in T028 OR kept under `scripts/` if user wants replay/audit |
| [x] | T004 | Execute migration script (dry-run first) | skills-authoring | `/Users/jordanknight/github/tools/skills/{SDD,general,personal}/` | Step 1 (dry-run): `python scripts/migrate-skills.py --dry-run` — output lists exactly 29 source→dest pairs and exits 0. Step 2 (apply): `python scripts/migrate-skills.py` — creates 27 dirs under `SDD/`, 1 under `general/`, 1 under `personal/`, each containing exactly one `SKILL.md`. Idempotent re-run: `python scripts/migrate-skills.py` a second time prints 29 `[skip]` lines and exits 0 | F08. Sequenced before T006/T007 source-deletion |
| [x] | T005 | Move 4 skip-list docs to `docs/skills-pipeline/` | repo-docs | `/Users/jordanknight/github/tools/docs/skills-pipeline/{README.md, getting-started.md, changes.md, codebase.md}` | Files exist at new location; original `README.md` retitled (drop "V2") and renamed-to-lowercase where useful; `GETTING-STARTED.md` → `getting-started.md` to match docs/ kebab-case convention | Q4 default A |
| [x] | T006 | Delete `agents/v2-commands/` | skills-authoring | `/Users/jordanknight/github/tools/agents/v2-commands/` | Directory does not exist; `git status` shows the 31-file removal cleanly | Sequenced after T004 + T005 so no source content is lost |
| [x] | T007 | Delete `other-skills/` | skills-authoring | `/Users/jordanknight/github/tools/other-skills/` | Directory does not exist | Sequenced after T004 |
| [x] | T008 | Slug-collision linter | skills-authoring | `/Users/jordanknight/github/tools/scripts/check-skill-slugs.sh` (new) | Script: `find skills -mindepth 3 -maxdepth 3 -name SKILL.md -printf '%h\n' \| xargs -n1 basename \| sort \| uniq -d` returns empty. Wrap in a shell script that exits 0 (no dupes) or 1 (dupes found, prints them). **Sequencing**: run immediately after T004 (before T006/T007 source-deletion, so failure can be fixed before legacy files are gone) | F06 |
| [x] | T009 | `install/agents.sh` — delete skill fan-out | skills-distribution | `/Users/jordanknight/github/tools/install/agents.sh` | Lines 27, 50–62 (`--commands-local` parse), 100 (V2_SOURCE_DIR), 104 (`COPILOT_CLI_SKILLS_DIR`), 108–113 (Copilot skills XDG vars), 143–162 (`cleanup_plan_commands`), 164–199 (`cleanup_copilot_cli_agents`), 201–246 (`generate_copilot_cli_skills` heredoc), 658–819 (`install_local_commands`), 822–826 (commands-local branch), 946–964 (Copilot CLI skills dirs), 966–1049 (copy loop + idempotency + skill gen) all deleted. Lines 105 (`COPILOT_CLI_MCP_CONFIG` — see F01), 248–656 (`generate_mcp_configs`), 935–943 (Copilot global dir creation for MCP), 1050–1062 (MCP config call + error handling) PRESERVED. **Done-When grep assertion**: `grep -cE 'V2_SOURCE_DIR\|install_local_commands\|generate_copilot_cli_skills\|cleanup_plan_commands\|cleanup_copilot_cli_agents\|--commands-local\|COPILOT_CLI_SKILLS_DIR' install/agents.sh` returns **0** AND `grep -c 'generate_mcp_configs\|COPILOT_CLI_MCP_CONFIG' install/agents.sh` returns ≥**6** (preservation evidence). Net LOC: ~750 deleted, ~328 kept | F01, F02, F03. The largest single task — execute carefully with the cut-line inventory open |
| [ ] | T010 | Optionally rename `COPILOT_CLI_MCP_CONFIG` constant for clarity | skills-distribution | `/Users/jordanknight/github/tools/install/agents.sh` | Constant renamed to `MCP_COPILOT_CLI_CONFIG`; all 5 refs updated (lines 105, 323, 517, 537–538, 640–641, 650–651) | F01. Defer if it complicates T009; not required for correctness |
| [x] | T011 | `setup_manager.py` — delete agent-install code path | package-cli | `/Users/jordanknight/github/tools/setup_manager.py` | Delete line 75 (attr), lines 310–314 (commands-local arg forwarding), lines 360–461 (`_install_local_commands_python`), lines 465–474 (local-mode branching). Refactor `install_tools()` and `run()` to remove the local-mode special case. Update comment at line 229–233 (F07). Total ~117 LOC delete | F02 |
| [x] | T012 | `src/jk_tools/cli.py` — delete `--commands-local` flag | package-cli | `/Users/jordanknight/github/tools/src/jk_tools/cli.py` | Delete lines 48–52 (`--commands-local` arg), 54–60 (`--local-dir` arg), 79–82 (assignments). Update help text. All other flags untouched. **Sequencing**: run AFTER T011 — `setup_manager.py` forwards these args to the CLI, deleting the args before the forwarder is gone would break the cli.py → manager handoff | F02. Depends on T011 |
| [x] | T013 | `scripts/sync-to-dist.sh` — delete v2-commands rsync block | skills-distribution | `/Users/jordanknight/github/tools/scripts/sync-to-dist.sh` | Lines 62–72 deleted (the `if [ -d "${REPO_ROOT}/agents/v2-commands" ]` block). All other rsync blocks (agents/commands, agents/mcp, agents/settings.local.json, scripts/, install/, setup_manager.py, .vscode/plan-*.md) PRESERVED. Method: manual edit OR `sed -i.bak '62,72d' scripts/sync-to-dist.sh` (then delete `.bak`). Verify with `git diff scripts/sync-to-dist.sh` — should show only the 11-line deletion | F05 |
| [x] | T014 | Delete `src/jk_tools/agents/v2-commands/` dist mirror | skills-distribution | `/Users/jordanknight/github/tools/src/jk_tools/agents/v2-commands/` | Directory does not exist; `git status` shows clean removal | Sequenced after T013 (sync no longer recreates it) |
| [x] | T015 | `setup.sh` — add skills-note one-liner | skills-distribution | `/Users/jordanknight/github/tools/setup.sh` | A `printf` or `echo` line near the end of `setup.sh` prints: "Skills are installed separately — see INSTALL.md for `npx skills add jakkaj/tools` patterns." (or similar). Visible in normal `./setup.sh` output | Q6 default A. Single line, no logic |
| [x] | T016 | Delete `tests/install/test_agents_copilot_dirs.sh` | skills-distribution | `/Users/jordanknight/github/tools/tests/install/test_agents_copilot_dirs.sh` | File does not exist | F04. Pure skill-fan-out test; nothing to preserve |
| [x] | T017 | Delete `tests/install/test_complete_flow.sh` | skills-distribution | `/Users/jordanknight/github/tools/tests/install/test_complete_flow.sh` | File does not exist | F04 |
| [ ] | T018 | (Optional) Add lightweight no-fan-out test | skills-distribution | `/Users/jordanknight/github/tools/tests/install/test_no_skill_fanout.sh` (new) | Test: sets `HOME` to a sandbox, runs `setup.sh`, asserts that `$HOME/.claude/commands/`, `$HOME/.config/opencode/command/`, `$HOME/.codex/prompts/`, `$HOME/.config/github-copilot/prompts/`, `$HOME/.copilot/skills/` all contain ZERO files matching v2-command slugs. Asserts MCP config files DO appear | F04. Not strictly required; gives future regression coverage. Skip if pressed for time |
| [x] | T019 | Write `INSTALL.md` at repo root | repo-docs | `/Users/jordanknight/github/tools/INSTALL.md` | File exists with: (a) "for agents" preamble ("if an LLM is reading this, identify the user's CLI and scope, then run one of the commands below"), (b) all 9 canonical patterns from spec AC #15 with exact `npx skills@latest add jakkaj/tools …` commands, (c) the 3 categories with 1-line descriptions of what's in each | Spec AC #15. The largest doc workstream — be specific and exhaustive |
| [x] | T020 | Write `MIGRATION.md` at repo root | repo-docs | `/Users/jordanknight/github/tools/MIGRATION.md` | File exists with: (a) what `./setup.sh` previously installed and where, (b) which of those files are now stale, (c) optional one-liner cleanup commands for each target dir, (d) note that cleanup is OPTIONAL — leaving stale files won't break anything, just adds clutter | Spec AC #14. Retained permanently (Q5 default) |
| [x] | T021 | Refresh `README.md` | repo-docs | `/Users/jordanknight/github/tools/README.md` | Update "Quick Setup" section: `./setup.sh` no longer mentions skill installs; references `INSTALL.md` for skill installation. "Repository Structure" section: `agents/v2-commands/` removed; `skills/` added with category breakdown. No stale `v2-commands` references remain | Spec AC #17 + AC #13 |
| [x] | T022 | Rewrite `AGENTS.md` (substantial) | repo-docs | `/Users/jordanknight/github/tools/AGENTS.md` | Rewrite as the public agent-facing project guide. **Required sections** (in this order): (1) Project purpose — what this repo is, in 2–3 sentences; (2) `skills/<category>/` layout — the top-level tree, what each category means; (3) The 3-category index — `SDD/` (with 1-line summary + count), `general/` (with 1-line summary + count), `personal/` (with 1-line summary + count); (4) "How to install" — single short paragraph pointing at `INSTALL.md` with example `npx skills add jakkaj/tools -a claude-code -g`; (5) Deprecation notice re: `agents/commands/` + `agents/commands-lite/` with pointer to `DEPRECATED.md`; (6) Pointer to `CLAUDE.md` for contributors. ~150–250 lines. **Forbidden**: any contributor / "how to add a new skill" instructions (those live in CLAUDE.md). No `./setup.sh` install claims for skills | Spec AC #16. Q5 default A |
| [x] | T023 | Rewrite `CLAUDE.md` (substantial) | repo-docs | `/Users/jordanknight/github/tools/CLAUDE.md` | Rewrite as the dev-facing contributor guide. Sections: source-of-truth layout (`skills/<category>/<slug>/SKILL.md`), how to add a new skill, frontmatter contract (`name:` + `description:`), how the install/sync flow works after the cleanup, how to run the migration script (if kept) | Spec AC #13. Q5 default A |
| [~] | T024 | Verify `./setup.sh` smoke test | skills-distribution | (clean sandbox: fresh Linux container, OR a temp `HOME=$(mktemp -d)` override on the dev machine) | Environment: a fresh Docker container (`debian:bookworm`/`ubuntu:24.04`) OR a sandbox `HOME` directory created via `HOME=$(mktemp -d) ./setup.sh`. Assertions: (1) `./setup.sh` exits 0; (2) MCP config files appear in `$HOME/.claude.json` etc.; (3) `find $HOME/.claude/commands $HOME/.config/opencode/command $HOME/.codex/prompts $HOME/.config/github-copilot/prompts $HOME/.copilot/skills -maxdepth 2 -name '*.md' -o -name 'SKILL.md' 2>/dev/null \| wc -l` returns **0**; (4) T015's "Skills are installed separately — see INSTALL.md" line appears in stdout | Spec AC #11. Record stdout in plan log. Sandbox method is preferred for speed; container method is the gold standard |
| [~] | T025 | Verify `npx skills add` smoke test | skills-authoring | (any directory outside this repo, e.g. `$(mktemp -d)`) | From outside the repo, against the branch where T001–T023 have landed: `npx skills@latest add jakkaj/tools --skill harness-is-the-product-v2 -a claude-code -g` exits 0. Then: `cat ~/.claude/skills/harness-is-the-product-v2/SKILL.md` shows valid frontmatter (`name: harness-is-the-product-v2` + non-empty `description:`) and non-empty body. **Pre-step**: requires T001–T023 to be on a pushed branch — execute T025 after CI is green | Spec AC #12 |
| [x] | T026 | Grep stale-string verification on top-level docs | repo-docs | `/Users/jordanknight/github/tools/{README.md,AGENTS.md,CLAUDE.md}` | `grep -E '(v2-commands\|commands-local\|generate_copilot_cli_skills)' README.md AGENTS.md CLAUDE.md` returns ZERO hits. **Sequencing**: depends on T021, T022, T023 (the three doc rewrites). Run after all three are committed | Spec AC #13 — last clause |
| [x] | T027 | Body byte-diff verification on migrated SKILL.md | skills-authoring | `/Users/jordanknight/github/tools/skills/{SDD,general,personal}/*/SKILL.md` | For each migrated SKILL.md: extract body (after second `---`), compare to source `.md` body. ≤1 trailing newline difference allowed. All 29 pass | Spec AC #4. Run as part of T004 or as a post-step |
| [x] | T028 | Final acceptance check against spec | (cross-cutting) | (spec document) | Walk all 17 acceptance criteria in the spec. Each marked ✅ or ❌ with evidence (file path, command output, line count, etc.). If any ❌, fix and re-run prior tasks | Spec § Acceptance Criteria |

**Total**: 28 tasks (T018 optional; effective minimum 27).

### Acceptance Criteria

Mirrors spec § Acceptance Criteria — 17 items. Summarized here as a single checklist for plan-level verification. Detailed wording in the spec.

- [x] AC #1 — `skills/SDD/` contains exactly 27 dirs, each with exactly one `SKILL.md` ✅ verified `find ... | wc -l` = 27
- [x] AC #2 — `skills/general/grill-me/SKILL.md` and `skills/personal/shopping-hunter/SKILL.md` exist with intact frontmatter ✅
- [x] AC #3 — Every migrated SKILL.md has `name:` matching folder slug and non-empty `description:` ✅ 29/29 PASS
- [x] AC #4 — Body byte-diff vs source = identical (T027) ✅ migration script verification: 29/29 OK
- [x] AC #5 — `agents/v2-commands/` and `other-skills/` removed ✅
- [x] AC #6 — `agents/commands/DEPRECATED.md` + `agents/commands-lite/DEPRECATED.md` exist ✅
- [x] AC #7 — `install/agents.sh` no longer contains the listed deletion targets; MCP logic preserved ✅ grep returns 0 hits for fan-out; **partial deviation**: net LOC reduction is −489 (1078→589), not −700. Gross deletions ≥750 LOC; rewrite adds ~260 LOC of slim boilerplate. Strict net-700 target is unreachable while preserving `generate_mcp_configs` verbatim per F03 (the function alone is 409 LOC). Spec intent (gut all skill fan-out) fully met.
- [x] AC #8 — `src/jk_tools/cli.py` no longer exposes `--commands-local`; `setup_manager.py` no longer has agent-install path ✅
- [x] AC #9 — `scripts/sync-to-dist.sh` no longer mirrors v2-commands; dist mirror dir removed ✅
- [x] AC #10 — Test files deleted or rewritten without v2-commands references ✅ both files deleted
- [~] AC #11 — `./setup.sh` smoke test passes; no skill files created in `$HOME` (T024) **DEFERRED** — live smoke test postponed; static equivalent verified: bash syntax OK, only file-writes are MCP config JSON/TOML + timestamped backups (no skill paths)
- [~] AC #12 — `npx skills add jakkaj/tools` smoke test passes (T025) **DEFERRED** — requires changes pushed to remote
- [x] AC #13 — `README.md`, `AGENTS.md`, `CLAUDE.md` refreshed; grep returns 0 stale strings (T026) ✅
- [x] AC #14 — `MIGRATION.md` exists at repo root ✅
- [x] AC #15 — `INSTALL.md` exists with 9 patterns + 3 category index + LLM preamble ✅
- [x] AC #16 — `AGENTS.md` accurately describes new layout (T022) ✅
- [x] AC #17 — `README.md` "Quick Setup" no longer claims `./setup.sh` installs skills (T021) ✅

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| R1 — Accidental deletion of MCP-related code in `install/agents.sh` during T009 | Medium | High | F01: tangled `COPILOT_CLI_MCP_CONFIG` constant explicitly preserved in T009. Cut-line inventory in F02 is line-precise. T024 smoke test verifies MCP config still written. T010 rename for future clarity |
| R2 — Migration script (T003) introduces whitespace drift in body | Low | Low | T027 byte-diff verification catches it. Python + `pyyaml` is deterministic |
| R3 — Skip-list doc move (T005) loses content / breaks links | Low | Low | `git mv` preserves history. Internal links checked manually; no other docs reference these 4 files by path (verified during plan-1a) |
| R4 — `npx skills add` smoke test (T025) fails because Vercel CLI doesn't handle our category nesting | Low (depth 3, walk limit is 5) | Medium | Cut a 30-second probe BEFORE T009 to mitigate — `cd /tmp && npx skills@latest add jakkaj/tools --skill harness-is-the-product-v2 -a claude-code -g --dry-run` from the merged branch. If failure, flatten or add manifest. (Note: requires merging T001–T008 to a temporary branch first; can defer to T025) |
| R5 — Existing user `$HOME` installs become stale and confusing | High | Medium | `MIGRATION.md` (T020) addresses. Out of scope to auto-prune. Documented in spec § Risks |
| R6 — Test deletions (T016, T017) leave a gap in regression coverage | Medium | Low | F04: tests were testing deleted code; the kept code has no test coverage today either. Optional T018 partially mitigates |
| R7 — Doc rewrites (T022, T023) diverge from actual repo state during the implementation pass (e.g., AGENTS.md describes things before they're done) | Medium | Low | Sequence T022/T023 LATE in the task order — after T009–T015 land. T026 grep verification is the final gate |

## Validation Trail

### Plan-4 readiness gate (2026-05-13): **READY**

| Validator | Status | HIGH | MEDIUM | LOW |
|---|---|---|---|---|
| Structure | PASS | 0 | 0 | 0 |
| Testing Alignment | PASS | 0 | 0 | 0 |
| Domain Completeness | PASS | 0 | 0 | 0 |
| Doctrine | N/A | — | — | — |
| ADR | N/A | — | — | — |

### Validate-v2 multi-lens validation (2026-05-13): **APPROVED (with fixes applied)**

| Lens | Status | HIGH | MEDIUM | LOW | Notes |
|---|---|---|---|---|---|
| Correctness + Thesis Alignment | PASS | 0 | 0 | 0 | All 17 ACs mapped to tasks; all 6 clarifications honored; all 9 Non-Goals respected; every task advances the spec's outcome statement |
| Cut-Line Risk (MCP preservation) | PASS | 0 | 0 | 0 | F01 verified by reading source: `COPILOT_CLI_MCP_CONFIG` and `generate_mcp_configs` confirmed safe; no tangled references between DELETE and KEEP regions |
| Implementability (initial pass) | ISSUES | 3 | 2 | 3 | All 8 fixes applied inline — see § Fix Log below |

### Fix Log (validate-v2 implementability — 2026-05-13)

| # | Original Issue | Fix Applied | Tasks Updated |
|---|---|---|---|
| 1 | T003 idempotency contract unclear | Added explicit policy: skip if byte-identical, error if different, no overwrite without `--force` | T003 |
| 2 | T009 Done When lacked verification method | Added grep assertion that returns 0 hits for deleted strings AND ≥6 hits for preserved MCP strings | T009 |
| 3 | T024 "clean test environment" ambiguous | Defined as fresh container OR `HOME=$(mktemp -d)` sandbox with concrete `find` assertion | T024 |
| 4 | T008 sequencing implicit | Made explicit: "run immediately after T004, before T006/T007 source-deletion" | T008 |
| 5 | T012 sequencing implicit | Made explicit: "depends on T011 — manager forwards args to CLI" | T012 |
| 6 | T026 sequencing implicit | Made explicit: "depends on T021, T022, T023" | T026 |
| 7 | T022 AGENTS/CLAUDE boundary not operationalized | Added 6 required sections + "forbidden" list (no contributor instructions) | T022 |
| 8 | T004 + T013 tool/command not named | Added explicit commands (`python scripts/migrate-skills.py --dry-run`, `sed -i.bak '62,72d'`) | T004, T013 |

## Validation (Plan-Level Self-Check)

Before declaring this plan ready:

- [x] All tasks have explicit success criteria (Done When column populated)
- [x] All tasks have absolute paths in the Path(s) column
- [x] Domain manifest covers every NEW, MODIFIED, and DELETED file
- [x] Target domains from spec are all addressed in the task table
- [x] Key findings reference affected tasks (F01→T009/T010, F02→T009/T011/T012/T013, F03→T009, F04→T016/T017/T018, F05→T013, F06→T008, F07→T011, F08→T003/T027)
- [x] No time language present (CS only)
- [x] Risks have mitigations

### Next Steps

- Simple Mode → optionally run `/plan-4-complete-the-plan` for an independent readiness gate
- Then implement: `/plan-6-v2-implement-phase --plan "/Users/jordanknight/github/tools/docs/plans/022-skills-layout-migration/skills-layout-migration-plan.md"`

✅ **Plan created**
- Location: `/Users/jordanknight/github/tools/docs/plans/022-skills-layout-migration/skills-layout-migration-plan.md`
- Mode: Simple (single phase, inline task table)
- Tasks: 28 (T018 optional)
- Domains: 5 conceptual (all touched)
- Findings: 8 (1 Critical, 2 High, 3 Medium, 2 Low)
- Risks: 7 ranked
