# Skills-Layout Migration

**Mode**: Simple
**Status**: DRAFT
**Created**: 2026-05-13
**Plan Folder**: `docs/plans/022-skills-layout-migration/`
**Related Research**: `research-dossier.md`, `external-research/cli-paths-verification.md`

📚 This specification incorporates findings from `research-dossier.md` and the verified Vercel CLI source-code review in `external-research/cli-paths-verification.md`. It also incorporates four live design decisions made during the research phase (recorded in memory under plan 022).

---

## Research Context

The research pass established four facts that frame this spec:

1. **The wider ecosystem has converged on `SKILL.md/<folder>` skills format.** Anthropic, Vercel Labs (`npx skills`), Claude Code, OpenCode, Codex, GitHub Copilot CLI, and Cursor all natively read this format.
2. **Our installer already does the target transformation** (`generate_copilot_cli_skills()` in `install/agents.sh:201`) — but at install-time, for one of seven targets. Hoisting to source-time eliminates the function.
3. **A top-level `skills/` directory with category subfolders mirrors `mattpocock/skills`** (which uses `engineering/`, `personal/`, `productivity/`, etc.). `npx skills` flattens categories on install — they exist for human browsing only.
4. **Top-level `skills/` is NOT a native auto-scan path for any CLI.** Codex / GitHub Copilot CLI / OpenCode / Cursor all scan `.agents/skills/` natively when working in a project; Claude Code scans `.claude/skills/`. None scan `skills/`. We accept this trade-off because the primary distribution path is `npx skills@latest add jakkaj/tools` (recursive walk; finds SKILL.md anywhere) — this repo is a *publish source*, not a local skill provider for users working inside a clone.

---

## Summary

Migrate the canonical source-of-truth for project skills from flat-file `agents/v2-commands/*.md` (31 files) to the community-standard categorized SKILL.md folder layout at `skills/<category>/<slug>/SKILL.md`. Simultaneously gut the multi-CLI install-fan-out logic from `install/agents.sh` (~700–800 lines), deprecate the legacy v1 and lite command sets, and rely on `npx skills` for user-side distribution. The result is a smaller, single-purpose repo where the skills *are* the product and the installer carries no skill-specific code.

---

## Goals

- **Single source of truth** for skills at `skills/<category>/<slug>/SKILL.md` in this repo, with category folders following the `mattpocock/skills` convention (`SDD/`, `general/`, `personal/`).
- **Eliminate skill fan-out logic** from `install/agents.sh`, `setup_manager.py`, `src/jk_tools/cli.py`, and `scripts/sync-to-dist.sh`. Setup script becomes a developer-tools installer + MCP-config deployer only.
- **Migrate 27 installable v2-commands** from `agents/v2-commands/*.md` into `skills/SDD/<slug>/SKILL.md` with `name:` and `description:` frontmatter, lossless body preservation.
- **Migrate 2 personal/general skills** from `other-skills/` (`grill-me.md` → `skills/general/grill-me/SKILL.md`, `shopping-hunter.md` → `skills/personal/shopping-hunter/SKILL.md`) and remove the `other-skills/` directory.
- **Deprecate `agents/commands/` (27 files) and `agents/commands-lite/` (12 files)** with a `DEPRECATED.md` marker at each root. Files stay in repo for a deprecation window; deletion is out of scope for this plan.
- **Publish an agent-readable install reference** at the repo root (`INSTALL.md`) covering every supported `npx skills` invocation pattern (global vs project-local × Claude Code / Codex / Copilot CLI / OpenCode / multi-target / universal / single-skill / auto-detect). This is a first-class deliverable, not a paragraph in the README — designed so an LLM agent can be pointed at it and construct the right install command for any user's stated preferences.
- **Refresh top-level documentation as a unit** — `CLAUDE.md`, `AGENTS.md`, `README.md`, `INSTALL.md`, `MIGRATION.md`. Each has a clear, non-overlapping role: README is the entry door, AGENTS.md is the public agent-facing project guide, CLAUDE.md is the dev-facing contributor guide, INSTALL.md is the install reference, MIGRATION.md is the one-time existing-user note. All four describe the new layout, the `npx skills`-based distribution model, and the deprecation of legacy paths. No stale references to `agents/v2-commands/`, `--commands-local`, or the 5-target install matrix remain.
- **Net code reduction**: at least 700 lines deleted from `install/agents.sh`, full removal of `generate_copilot_cli_skills()`, full removal of the `--commands-local` Python CLI flag and its tests.

---

## Non-Goals

- **No deletion of `agents/commands/` or `agents/commands-lite/`** in this plan. Deprecation markers only. Deletion is a future plan after a deprecation window.
- **No rename of skill slugs**. Skills keep their `-v2` suffix where present (`plan-1a-v2-explore`, `harness-is-the-product-v2`, etc.). Slug renames are a separate cosmetic change that would break user invocations and cross-skill references.
- **No support for multi-CLI install via `./setup.sh`**. Users wanting global installs run `npx skills@latest add jakkaj/tools -a <their-cli> [-g]` themselves.
- **No auto-prune of stale legacy files in user `$HOME`** (e.g. `~/.claude/commands/*.md` left over from previous `./setup.sh` runs). Users clean up their own home dirs; a one-line cleanup hint goes in the migration note.
- **No change to MCP server config deployment**. `agents/mcp/servers.json` → VS Code / Claude / OpenCode / Codex / VS Code project config remains exactly as today. MCP is not a skill.
- **No change to dev-tool installers** (Rust, code2prompt, fs2, just, claude-code, opencode, codex, copilot-cli, claude-statusline). These live in `install/*.sh` and continue to be called by `setup.sh`.
- **No `src/jk_tools/skills/` package mirror**. Skills are GitHub-distributed via `npx skills`; the Python package keeps shipping installers and MCP config only. `scripts/sync-to-dist.sh` drops its `agents/v2-commands/` mirror logic.
- **No agent harness governance doc** (`docs/project-rules/agent-harness.md`) created. That's a separate workshop opportunity unrelated to layout migration.
- **No broader repo tidy-up.** Out of scope: reorganizing `scripts/`, `install/`, or `src/jk_tools/`; removing unused tools or aliases; reworking the dev-tools installer matrix; converting any other doc to a new format. The user has flagged a follow-up cleanup pass after this migration; that is its own plan.

---

## Target Domains

This repo has no `docs/domains/registry.md`, so the table below uses **conceptual** domains — these are not formal `docs/domains/<slug>/domain.md` artifacts but useful framings for the affected surfaces. No formal domain.md files are created as part of this plan (they could be a follow-up).

| Domain | Status | Relationship | Role in This Feature |
|---|---|---|---|
| `skills-authoring` | **NEW (conceptual)** | **create** | Establish the canonical source layout, frontmatter contract, categorization heuristic, and slug rules for skills in `skills/<category>/<slug>/SKILL.md` |
| `skills-distribution` | existing (conceptual) | **modify** | Shrink dramatically — remove the 7-target install loop, the SKILL.md generator, `--commands-local` mode, and dist-mirror sync of v2-commands. Keep MCP and dev-tool installers untouched |
| `legacy-commands` | existing (conceptual) | **modify** | Add deprecation markers to `agents/commands/` and `agents/commands-lite/`. Do not delete |
| `package-cli` | existing (conceptual) | **modify** | Remove `--commands-local` flag from `src/jk_tools/cli.py`. Remove agent-install code path from `setup_manager.py`. Keep dev-tool entrypoints |
| `repo-docs` | existing (conceptual) | **modify** | Update `CLAUDE.md`, `AGENTS.md`, `README.md`, `GETTING-STARTED.md` to describe the new layout, drop references to the legacy fan-out installer, and add a user migration note |

### New Domain Sketches

#### `skills-authoring` [NEW conceptual]
- **Purpose**: Define how skills are authored and laid out in the repo. Owns the source-tree shape, the `SKILL.md` frontmatter contract, category conventions, and slug rules.
- **Boundary Owns**: top-level `skills/` tree structure; per-skill `SKILL.md` content + frontmatter; category subfolders (`SDD/`, `general/`, `personal/`); slug-to-folder-name correspondence; skill body migration rules (preserve verbatim, add `name:` field).
- **Boundary Excludes**:
  - Distribution / install mechanics → `skills-distribution`
  - Legacy command organization → `legacy-commands`
  - Format/spec evolution (e.g. adding `tags:`, `model:`) → future plan

---

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2 (many files: installer, dist sync, cli.py, setup_manager, 27+2 source migrations, deprecation markers, 5 top-level docs), I=1 (one external dep: `npx skills` CLI, stable), D=1 (filesystem layout change; no schema/migration), N=0 (well-specified after research + conversation), F=0 (no perf/security/compliance), T=1 (existing tests need updating or deletion; light integration verification of `npx skills install`)
- **Total P**: 5 → CS-3 (medium)
- **Confidence**: 0.92 (raised from 0.88 — adding `INSTALL.md` as an explicit deliverable removes the residual ambiguity about how distribution is documented)
- **Assumptions**:
  - `vercel-labs/skills` behavior on `main` as of 2026-05-13 holds (verified directly from source).
  - All 27 v2 `description:` fields fit under Codex's enforced 1024-char limit. Verified: longest is 262 chars.
  - All v2 file stems satisfy the conventional `name:` slug rule (`/^[a-z][a-z0-9-]{1,50}$/`). Verified: all 29 installable stems pass, only `README` and `GETTING-STARTED` fail (already in skip-list, not migrating).
  - `setup.sh` users who previously got auto-installed commands accept manual cleanup of their `$HOME` CLI dirs — no auto-prune is in scope.
- **Dependencies**: None blocking. `npx skills` ecosystem is established; no new tools to install.
- **Risks**: see § Risks & Assumptions.
- **Mode**: Simple — single implementation pass, no phase boundaries. Plan-3 will generate the inline 7-column task table (`Status | ID | Task | Domain | Path(s) | Done When | Notes`). The implementation is naturally ordered (source moves → installer cleanup → deprecation → docs → verify), but it's one cohesive change set, not a multi-phase delivery.

### Implementation Workstreams (informational — plan-3 produces the task table)

These are sequencing hints for plan-3's inline task table generation, not phase boundaries:

1. **Source migration** (mechanical): Move 27 v2-commands → `skills/SDD/`, move 2 from `other-skills/` → `general/` + `personal/`. Add `name:` frontmatter. Verify lossless body. Delete `agents/v2-commands/` and `other-skills/`. Move the 4 skip-list docs (`README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`) into `docs/skills-pipeline/` or similar.
2. **Installer cleanup**: Remove skill-fan-out logic from `install/agents.sh`, `setup_manager.py`, `src/jk_tools/cli.py`, `scripts/sync-to-dist.sh`. Update or delete `tests/install/test_agents_copilot_dirs.sh` and `tests/install/test_complete_flow.sh`. MCP-config deployment preserved.
3. **Deprecation markers**: Add `DEPRECATED.md` to `agents/commands/` and `agents/commands-lite/` with explanation and pointer to `skills/`.
4. **Documentation refresh** (the *largest* workstream in terms of polish):
   - Write `INSTALL.md` at repo root — the agent-readable install reference (see AC #15)
   - Write `MIGRATION.md` at repo root — for existing-`./setup.sh` users (see AC #14)
   - Update `README.md` — point at `INSTALL.md` and `AGENTS.md`; drop "Quick Setup" `./setup.sh` skills claims
   - Update `AGENTS.md` — the public agent-facing project guide; ensure it accurately describes the new `skills/` layout
   - Update `CLAUDE.md` — the dev-facing contributor guide; document how to add/edit a skill in the new layout
5. **Verification**: Manual sanity check of `npx skills add jakkaj/tools` from a clean clone, `./setup.sh` runs without errors and writes no skill files, slug-collision lint, byte-diff check on migrated SKILL.md bodies.

---

## Acceptance Criteria

Each criterion is independently verifiable. A future PR / plan review can check each by running a one-line command or eyeballing a file.

1. **Source layout**: `skills/SDD/` contains exactly 27 subdirectories. Each subdirectory contains exactly one file named `SKILL.md`. Verifiable: `find skills/SDD -mindepth 2 -maxdepth 2 -type f -name SKILL.md | wc -l` → `27`.
2. **General + personal**: `skills/general/grill-me/SKILL.md` and `skills/personal/shopping-hunter/SKILL.md` both exist with their frontmatter intact (`name:` matches folder slug; `description:` preserved from source).
3. **Frontmatter shape**: Every migrated SKILL.md has a `name:` field whose value matches the leaf directory name, and a `description:` field that is a non-empty string. Verifiable: a one-line `awk` or `grep` over the tree.
4. **Body preservation**: The body of each migrated SKILL.md (everything after the `---` frontmatter close) is byte-identical to the body of the source `.md` file (modulo trailing newline normalization). Verifiable by diff.
5. **Source removal**: `agents/v2-commands/` no longer exists. `other-skills/` no longer exists.
6. **Deprecation markers**: `agents/commands/DEPRECATED.md` and `agents/commands-lite/DEPRECATED.md` exist, each containing: a one-paragraph deprecation explanation, a pointer at `skills/`, and a note that deletion is planned in a future cleanup.
7. **Installer pruned**: `install/agents.sh` no longer contains the strings `V2_SOURCE_DIR`, `generate_copilot_cli_skills`, `cleanup_plan_commands`, `cleanup_copilot_cli_agents`, `--commands-local`, `COPILOT_CLI_SKILLS_DIR`. The MCP-config deployment logic (`generate_mcp_configs` etc.) is preserved verbatim. Net file size reduction ≥700 lines.
8. **Python CLI pruned**: `src/jk_tools/cli.py` no longer exposes the `--commands-local` flag. `setup_manager.py` no longer contains the agent-install code path.
9. **Sync pruned**: `scripts/sync-to-dist.sh` no longer mirrors `agents/v2-commands/` to `src/jk_tools/agents/v2-commands/`. The `src/jk_tools/agents/v2-commands/` mirror directory is removed.
10. **Tests in sync with reality**: `tests/install/test_agents_copilot_dirs.sh` is either deleted or rewritten such that it does not reference `v2-commands` or `generate_copilot_cli_skills`. `tests/install/test_complete_flow.sh` runs `./setup.sh` end-to-end without errors.
11. **No-fan-out behavior**: Running `./setup.sh` on a clean macOS, Linux, or WSL machine completes successfully and does not create any of: `~/.claude/commands/*.md`, `~/.config/opencode/command/*.md`, `~/.codex/prompts/*.md`, `~/.config/github-copilot/prompts/*.prompt.md`, or `~/.copilot/skills/*/SKILL.md`. (It DOES create MCP config files — that's expected and out of scope.)
12. **External-CLI distribution works**: `npx skills@latest add jakkaj/tools --skill harness-is-the-product-v2 -a claude-code -g` (run from outside this repo, against the merged main) installs `~/.claude/skills/harness-is-the-product-v2/SKILL.md` with valid frontmatter and body.
13. **Docs in sync**: `CLAUDE.md`, `AGENTS.md`, `README.md` no longer describe `agents/v2-commands/`, `--commands-local`, or the 5-target install matrix. They DO describe the top-level `skills/<category>/` layout, the `npx skills`-based distribution model, and the deprecation of `agents/commands/` and `agents/commands-lite/`. No stale references survive (verifiable: a grep for "v2-commands", "commands-local", or "generate_copilot_cli_skills" in these three docs returns zero hits).
14. **Existing-user migration note**: A `MIGRATION.md` at repo root explains what previously got installed to user `$HOME`, what's now stale, and the one-line cleanup the user can optionally run.
15. **Install reference (`INSTALL.md` at repo root)**: A standalone, agent-readable installation reference covering at minimum these patterns: (a) install everything globally for Claude Code, (b) globally for Codex CLI, (c) globally for GitHub Copilot CLI, (d) globally for OpenCode, (e) install for multiple CLIs in one command, (f) install just one skill via `--skill`, (g) install project-locally (current-dir scope), (h) auto-detect (`-y`), (i) universal cross-CLI install (`-a universal`). Each pattern includes the exact `npx skills@latest add jakkaj/tools …` command. The doc also lists the three categories (`SDD/`, `general/`, `personal/`) and a 1-line summary of each. Opens with an "if an LLM agent is reading this" preamble so an agent can be pointed at it and produce a correct install command from a user's stated preferences. No `./setup.sh`-based install claims appear.
16. **AGENTS.md at repo root is up-to-date**: `AGENTS.md` exists at repo root and accurately describes (a) the top-level `skills/` layout, (b) the three categories and what's in each, (c) how to invoke skills via the user's CLI of choice (pointer to `INSTALL.md`), (d) the deprecation of `agents/commands/` and `agents/commands-lite/`. Stays as the public agent-facing project guide — does not duplicate CLAUDE.md's contributor instructions.
17. **README.md at repo root is up-to-date**: README's "Quick Setup" section no longer claims `./setup.sh` installs skills. It points users at `INSTALL.md` for skill installs and continues to document dev-tool setup (Rust, code2prompt, fs2, etc.) which `setup.sh` still handles.

---

## Risks & Assumptions

### Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Existing user installs in `~/.claude/commands/`, `~/.codex/prompts/`, etc. become silent stale data after migration — confusing or wrong-version skills surface | High | Medium | `MIGRATION.md` with explicit cleanup commands. Out of scope to auto-prune (per Non-Goals) |
| R2 | Top-level `skills/` is not auto-scanned by any CLI (Codex/Copilot/OpenCode/Cursor scan `.agents/skills/`; Claude Code scans `.claude/skills/`) — users working inside a clone of this repo do NOT get auto-discovery; they must `npx skills install` or copy manually | Accepted | Low | `MIGRATION.md` explains the model: this repo is a publish source, not a local skill provider. Decision was deliberate trade-off for `mattpocock/skills` convention alignment |
| R3 | `npx skills` slug-collision on flatten: if two categories ever share a leaf slug, the install target collides | Low (no current overlap; verified 29 unique stems) | Medium | Linter step in phase 5: assert flattened slug set has no dupes |
| R4 | Removing `--commands-local` breaks any downstream tooling or docs that called `uvx jk-tools-setup --commands-local <cli>` | Low (no known external consumers; this is a personal tools repo) | Low | Note in `MIGRATION.md` |
| R5 | Removing test assertions in `tests/install/test_agents_copilot_dirs.sh` leaves a gap in installer regression coverage | Medium | Low | Replace with a smaller test asserting `setup.sh` does NOT write skills, plus a smoke test for MCP-only deployment |
| R6 | Body migration introduces accidental whitespace/encoding drift across 27+2 files | Medium | Low | Phase 1 uses a deterministic migration script (or single `git mv` per file followed by frontmatter insertion); phase 5 diff-verifies bodies |

### Assumptions

- `vercel-labs/skills` `npx skills add owner/repo` will discover SKILL.md files under `skills/<category>/<slug>/SKILL.md` via its recursive walk (verified from `src/skills.ts:findSkillDirs`, max depth 5; our nesting is depth 3 from repo root).
- The `name:` field value matches the leaf folder name. The Vercel CLI doesn't enforce this, but downstream consumers may.
- `npx skills` will install each discovered skill to a flat `<install-target>/<slug>/SKILL.md`, dropping the category dir. This is verified behavior.
- Users with mixed CLIs (e.g. Claude Code primary, OpenCode occasionally) accept running `npx skills add ... -a <cli>` once per CLI they want installed to. No multi-CLI single-invocation install replaces what `./setup.sh` did before.
- The deprecation window for `agents/commands/` and `agents/commands-lite/` is "indefinite for now" — no calendar deadline is set in this spec.

---

## Open Questions

| # | Question | Recommended Resolution | Defer To |
|---|---|---|---|
| Q1 | Should the `-v2` suffix be dropped from skill slugs (e.g. `plan-1a-v2-explore` → `plan-1a-explore`)? | **No** — defer to a future cosmetic cleanup; renaming breaks every existing user's `/plan-1a-v2-explore` invocation and cross-skill references | Future plan |
| Q2 | What happens to the 4 skip-list files in `agents/v2-commands/` (`README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`)? | Move into `docs/skills-pipeline/` (or similar `docs/` subfolder) as project documentation. Do not migrate to `skills/` (not skills) | Phase 4 of this plan |
| Q3 | Do we ship skills via the Python package distribution (`src/jk_tools/skills/`)? | **No** — GitHub-only distribution via `npx skills`. The Python package keeps shipping installers + MCP config | Locked |
| Q4 | What text goes in `DEPRECATED.md` for `commands/` and `commands-lite/`? | Workshop opportunity #2 (see below) — short doc, but worth getting right | Workshop or phase 3 |
| Q5 | Does `MIGRATION.md` get a calendar / version pin? | **No** — it's a one-time note for users upgrading from the previous installer model. Date it but don't gate it | Phase 4 |
| Q6 | (Removed) — in-repo auto-discovery is now N/A because top-level `skills/` is not natively scanned by any CLI. The deliberate trade-off is documented in R2 | — | N/A |

---

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|---|---|---|---|
| Deprecation markers + migration note copy | Other (docs / process) | The `DEPRECATED.md` files + `MIGRATION.md` are user-facing communication. Worth drafting carefully so existing users don't get confused or annoyed | What's the retention window? What's the cleanup one-liner? What's the rationale paragraph? Where do we link from? |
| Frontmatter normalization for migrated SKILL.md files | Data Model | The 27 v2 commands have only `description:` today. Migration adds `name:`. Should we also add `version:`, `tags:`, `allowed-tools:`, or `model:` to align with broader ecosystem? | Which optional fields are worth populating now vs. left for future? Are there per-skill `allowed-tools` restrictions we'd lock in? Do we date / version skills? |

Both workshops are optional. Workshop #1 can run in parallel with phases 1–3. Workshop #2 can defer to a separate plan if minimal frontmatter (`name` + `description`) is good enough for initial migration.

---

## Clarifications

### Session 2026-05-13

**Q1 — Workflow Mode: Simple ✅** (settled before clarify started; spec header set).

**Q2 — Testing Strategy: B (Lightweight) ✅**
Verify outcomes (file counts, frontmatter shape, `setup.sh` exit code, `npx skills` smoke), not internals. No TDD. Manual smoke tests captured in verification tasks.

**Q3 — `INSTALL.md` placement: A (repo root only) ✅**
Single canonical location at repo root, consistent with `MIGRATION.md`. No `skills/README.md` stub.

**Q4 — Skip-list doc disposition: A ✅**
Move `agents/v2-commands/{README.md, GETTING-STARTED.md, changes.md, codebase.md}` into `docs/skills-pipeline/`, retitled to drop "V2" framing. Preserves the pipeline-overview content as project docs.

**Q5 — Documentation split: A (use the recommended division) ✅**
- `README.md` — light refresh, links out
- `AGENTS.md` — substantial rewrite, public agent-facing project guide
- `CLAUDE.md` — substantial rewrite, dev-facing contributor guide
- `INSTALL.md` — NEW, end-user + LLM install pattern catalog
- `MIGRATION.md` — NEW, retained permanently

**Q6 — `setup.sh` user-facing copy: A ✅**
Print one-line note when `setup.sh` finishes: "Skills are now installed separately — see INSTALL.md".

**Q7 — `DEPRECATED.md` content: A (short stub) ✅**
`DEPRECATED.md` is a short stub pointing to `skills/`. No history-and-mapping doc, no workshop.

All defaults locked. No outstanding clarifications block plan-3.

## Next Steps

- **Recommended**: `/plan-2-v2-clarify` — resolve the handful of remaining doc-shape and migration-mechanics questions before architecture.
- **After clarification**: `/plan-3-v2-architect` — Simple-mode plan generation produces the inline 7-column task table.
- **Optional**: `/plan-2c-v2-workshop` for `INSTALL.md` content workshopping if the pattern table needs more design work than seems likely.
