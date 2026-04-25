# Copilot CLI Skills for Local Install

📚 This specification incorporates findings from research-dossier.md

## Research Context

Research (plan-1a-explore) confirmed:
- Local `.agent.md` files only surface via `/agent` menu — no direct `/slash-command` invocation
- The **skills** format (`.github/skills/<name>/SKILL.md`) provides direct `/skill-name` slash-command invocation with auto-discovery
- Global agents (`~/.copilot/agents/*.agent.md`) already work for slash commands — no change needed there
- The transformation is structurally similar: same frontmatter fields, just directory-per-skill layout and fixed `SKILL.md` filename

## Summary

When users run `uvx --from git+https://github.com/jakkaj/tools jk-tools-setup --commands-local copilot-cli`, the installed commands should be invocable as direct `/plan-1a-v2-explore` style slash commands in Copilot CLI — not buried behind the `/agent` picker menu.

**WHAT**: Switch the `--commands-local copilot-cli` output format from flat `.github/agents/*.agent.md` files to `.github/skills/<name>/SKILL.md` directory-per-skill layout. This enables Copilot CLI's auto-discovery of skills as direct slash commands.

Follow-up: Copilot CLI 1.0.36 also requires this skills format for reliable global discovery, so default setup now installs personal skills to `~/.copilot/skills/<name>/SKILL.md` in addition to compatibility agent files under `~/.copilot/agents/`.

**WHY**: Teams sharing commands via git repos need the same direct `/command-name` invocation experience that global installs provide. Without this, project-local Copilot CLI commands require navigating the `/agent` menu — a friction point that makes the shared commands less discoverable and slower to use.

## Goals

- Users can run `jk-tools-setup --commands-local copilot-cli` and get direct `/plan-1a-v2-explore` slash-command invocation in Copilot CLI
- Commands installed locally are auto-discovered by Copilot CLI without restart workarounds
- The `copilot-cli` option works alongside other targets: `--commands-local claude,opencode,ghcp,copilot-cli`
- Teams can commit `.github/skills/` to git and share commands across all team members
- Idempotent re-runs cleanly overwrite existing skills without duplicates

## Non-Goals

- Historical note: this local-scope plan originally excluded global Copilot CLI install changes because `~/.copilot/agents/` worked at the time. That assumption was superseded by Copilot CLI 1.0.36, so global personal skills are now handled separately.
- Modifying the source command files in `agents/v2-commands/`
- Adding skills support for other CLI targets (Claude, OpenCode — they don't use this format)
- Building automated tests for `--commands-local` (desirable but separate scope)

## Target Domains

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| installer | existing | **modify** | Change copilot-cli local install output format in `install/agents.sh` |
| documentation | existing | **modify** | Update AGENTS.md with new local path and format |

ℹ️ No formal domain registry exists. Domains identified from codebase structure.

## Complexity

- **Score**: CS-2 (small)
- **Breakdown**: S=1, I=0, D=0, N=0, F=0, T=1
  - Surface Area (S=1): 2-3 files touched (`agents.sh`, `AGENTS.md`, possibly `setup_manager.py` help text)
  - Integration (I=0): Internal only, no external dependencies
  - Data/State (D=0): No schema or state changes
  - Novelty (N=0): Well-specified — skills format is documented, research confirmed the approach
  - Non-Functional (F=0): Standard — no perf/security/compliance concerns
  - Testing/Rollout (T=1): Manual verification needed; no existing test coverage for `--commands-local`
- **Confidence**: 0.90
- **Assumptions**:
  - Copilot CLI auto-discovers `.github/skills/` directories (confirmed by official docs)
  - `SKILL.md` requires `name` and `description` frontmatter fields (confirmed)
  - Global `.agent.md` install continues to provide slash-command behavior (confirmed by user)
- **Dependencies**: None — all tooling is internal
- **Risks**: Copilot CLI is in public preview; skills format may evolve
- **Phases**: Single phase — modify embedded Python in `agents.sh`, update docs

## Acceptance Criteria

1. Running `jk-tools-setup --commands-local copilot-cli` creates `.github/skills/<name>/SKILL.md` for each v2-command
2. Each `SKILL.md` has valid YAML frontmatter with `name` (lowercase, hyphenated) and `description` (non-empty)
3. Each `SKILL.md` body contains the full markdown instruction content from the source file (with original frontmatter stripped)
4. The directory structure is `skills/<stem>/SKILL.md` where `<stem>` matches the source filename without `.md`
5. `README.md`, `GETTING-STARTED.md`, `changes.md`, and `codebase.md` are excluded from skill generation
6. Re-running the command overwrites existing skills cleanly (idempotent)
7. The `copilot-cli` option works when combined with other targets: `--commands-local claude,opencode,ghcp,copilot-cli`
8. Old `.github/agents/plan-*.agent.md` files are cleaned up during install (migration)
9. AGENTS.md documentation reflects the new `.github/skills/` path for local Copilot CLI install
10. No changes to global Copilot CLI install behavior (`~/.copilot/agents/` remains as-is)

## Risks & Assumptions

- **Risk**: Copilot CLI skills format is newer and may change as the product exits preview
  - *Mitigation*: Keep transform logic isolated in a single embedded Python block for easy updates
- **Assumption**: Users on Copilot CLI versions that support skills (recent versions)
  - *Mitigation*: Document minimum Copilot CLI version if discoverable
- **Assumption**: `.github/skills/` is the standard project-local path for Copilot CLI skills
  - *Confirmed*: Official GitHub docs specify `.github/skills/`, `.claude/skills/`, or `.agents/skills/`

## Open Questions

1. Should we also install skills to `.agents/skills/` (generic path) in addition to `.github/skills/`? [NEEDS CLARIFICATION: probably not — `.github/skills/` is the canonical project path]
2. Should old `.github/agents/*.agent.md` files be removed entirely, or only the `plan-*` prefixed ones? [NEEDS CLARIFICATION: lean toward removing all agent.md files we created, leave user-created ones]

## Workshop Opportunities

*None identified* — the scope is well-defined and the format transformation is straightforward. No complex design decisions remain.
