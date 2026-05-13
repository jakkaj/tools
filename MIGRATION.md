# MIGRATION.md — Cleaning up after the skills layout change

If you previously ran `./setup.sh` from this repository (before the skills-layout migration), the script fanned the v2-commands out into your `$HOME` across five CLI-specific locations. That fan-out is gone now — `./setup.sh` only manages MCP server configs and dev tooling. The previously-installed files remain on disk; they are **stale but harmless**.

This note tells you what's stale, where it is, and how to optionally clean it up.

## What `./setup.sh` used to install

The old behavior copied every `agents/v2-commands/*.md` file into all of:

| Target | Path | File shape |
|---|---|---|
| Claude Code (global) | `~/.claude/commands/*.md` | Raw .md, one per skill |
| OpenCode (global) | `~/.config/opencode/command/*.md` | Raw .md |
| Codex CLI (global) | `~/.codex/prompts/*.md` | Raw .md |
| GitHub Copilot (VS Code, global) | `~/.config/github-copilot/prompts/*.prompt.md` | Renamed to `.prompt.md` |
| GitHub Copilot CLI (global) | `~/.copilot/skills/<slug>/SKILL.md` | Converted to skill format |

If your machine ran `./setup.sh` between mid-2025 and the migration, those paths contain stale copies of the v2-commands.

## What's now authoritative

The skills now live in this repo at `skills/<category>/<slug>/SKILL.md` and are distributed via `npx skills@latest add jakkaj/tools` (see [`INSTALL.md`](./INSTALL.md)).

The active install target for Claude Code, for example, is now `~/.claude/skills/<slug>/SKILL.md` (not `~/.claude/commands/<slug>.md`). The old `~/.claude/commands/` files will not be touched by your CLI when it scans for skills, but they may still show up if your CLI also scans the legacy commands directory.

## Optional cleanup

Cleanup is **optional**. Leaving the stale files in place will not break anything — they just add visual clutter and may cause your CLI to surface duplicate or conflicting suggestions.

If you want to clean up, run each of these one-liners. Each is idempotent and safe to re-run.

```bash
# 1. Claude Code (commands/)
rm -f ~/.claude/commands/*-v2.md ~/.claude/commands/plan-*.md ~/.claude/commands/validate-v2.md \
      ~/.claude/commands/htmlify-v2.md ~/.claude/commands/util-0-v2-handover.md \
      ~/.claude/commands/didyouknow-v2.md ~/.claude/commands/deepresearch-v2.md \
      ~/.claude/commands/flowspace-research-v2.md ~/.claude/commands/harness-is-the-product-v2.md \
      ~/.claude/commands/agent-harness-v2.md ~/.claude/commands/code-concept-search-v2.md

# 2. OpenCode
rm -f ~/.config/opencode/command/*-v2.md ~/.config/opencode/command/plan-*.md

# 3. Codex
rm -f ~/.codex/prompts/*-v2.md ~/.codex/prompts/plan-*.md

# 4. GitHub Copilot (VS Code)
rm -f ~/.config/github-copilot/prompts/*-v2.prompt.md ~/.config/github-copilot/prompts/plan-*.prompt.md

# 5. GitHub Copilot CLI (skills directory)
#    Remove only the v2-command-derived skill directories.
for slug in agent-harness-v2 code-concept-search-v2 deepresearch-v2 didyouknow-v2 \
            flowspace-research-v2 harness-is-the-product-v2 htmlify-v2 plan-0-v2-constitution \
            plan-1a-v2-explore plan-1b-v2-specify plan-2-v2-clarify plan-2b-v2-prep-issue \
            plan-2c-v2-workshop plan-3-v2-architect plan-3a-v2-adr plan-4-v2-complete-the-plan \
            plan-5-v2-phase-tasks-and-brief plan-5b-flightplan plan-6-v2-implement-phase \
            plan-6-v2-implement-phase-companion plan-6a-v2-update-progress plan-6b-worked-example \
            plan-7-v2-code-review plan-8-v2-merge plan-v2-extract-domain util-0-v2-handover \
            validate-v2; do
  rm -rf ~/.copilot/skills/"$slug"
done
```

## Re-installing in the new layout

After (or instead of) the cleanup, install the skills properly via `npx skills`:

```bash
# For Claude Code, globally
npx skills@latest add jakkaj/tools -a claude-code -g
```

See [`INSTALL.md`](./INSTALL.md) for the full pattern catalog (other CLIs, project-local installs, single-skill installs, etc.).

## Will future `./setup.sh` runs do anything to my skills?

No. `./setup.sh` now only:

1. Syncs source files to the in-repo `src/jk_tools/` distribution package (dev mode only).
2. Installs the Claude Code status line.
3. Hands off to `setup_manager.py`, which installs Rust, code2prompt, FlowSpace, Claude Code CLI, Codex CLI, GitHub Copilot CLI, and runs `install/agents.sh` — which now only configures MCP servers.

No skill files are written to `$HOME` by `./setup.sh` anymore.
