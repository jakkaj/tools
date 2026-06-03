# Tools Repository — AGENTS.md (in-repo contributor / agent guide)

This is the guide for **AI coding assistants and contributors working in this repository** (editing skills, running dev tooling, debugging the sync flow). It is kept in sync with [`CLAUDE.md`](./CLAUDE.md) (same role, Claude-convention filename).

For the **public-facing skill catalog** (used by agents/users who just want to install or invoke the skills), see [`README_AGENTS.md`](./README_AGENTS.md). For **install patterns**, see [`INSTALL.md`](./INSTALL.md).

The repo's primary deliverable is the `skills/<category>/<slug>/SKILL.md` tree, distributed via `npx skills@latest add jakkaj/tools`. The Python/bash machinery (`setup.sh`, `setup_manager.py`, `install/*.sh`) installs **developer tooling and MCP configs** — it does **not** install skills.

A centralized collection of utility scripts and tools for consistent development environments across machines.

## Platform Support

- **macOS** (Intel and Apple Silicon)
- **Linux** (Ubuntu, Debian, Fedora, Arch, and other major distributions)
- **Windows** (via WSL or Git Bash)

## Purpose

This repository serves as a single source of truth for commonly used tools, scripts, and utilities that enhance productivity across different development environments. It provides a quick and reliable way to set up these tools on any supported platform with automatic installation of required dependencies.

## Quick Setup

```bash
git clone <repository-url> ~/github/tools
cd ~/github/tools
./setup.sh
source ~/.zshrc
```

## What It Does

- **Centralized Tool Management**: Keep all your custom scripts and tools in one version-controlled location
- **Automatic Tool Installation**: Installs required tools (Rust, code2prompt, etc.) automatically
- **Cross-Platform Support**: Works seamlessly on Linux, macOS, and Windows (WSL/Git Bash)
- **Instant Availability**: Automatically adds tools to your PATH for immediate use
- **Idempotent Setup**: Safe to run the setup script multiple times without side effects
- **Portable Configuration**: Easy to clone and set up on new machines or environments

## Repository Structure

```
tools/
├── setup.sh           # Dev-tooling installer entrypoint (PATH, MCP, Rust, code2prompt, …)
├── skills/            # SOURCE OF TRUTH for skills (published via `npx skills`)
│   ├── SDD/           #   29 spec-driven-development pipeline skills
│   ├── general/       #   domain-generic skills (grill-me)
│   └── personal/      #   personal / non-coding skills (shopping-hunter)
├── scripts/           # Executable tools and utilities (SOURCE OF TRUTH)
│   ├── sync-to-dist.sh    # Syncs source files to src/jk_tools/ for packaging
│   ├── migrate-skills.py  # One-shot migrator from legacy v2 layout (retained for replay)
│   └── check-skill-slugs.sh # Slug-collision linter
├── install/           # Tool installation scripts (SOURCE OF TRUTH)
│   ├── rust.sh        # Installs Rust and Cargo via rustup
│   ├── code2prompt.sh # Installs code2prompt via cargo
│   └── agents.sh      # Configures MCP servers (no longer fans skills out)
├── agents/            # Installer infra only (SOURCE OF TRUTH for MCP)
│   ├── mcp/           # MCP server definitions (used by install/agents.sh)
│   └── settings.local.json # Shared agent settings
├── docs/
│   ├── plans/             # NNN-slug/ folders produced by the SDD pipeline
│   └── skills-pipeline/   # README + getting-started for the SDD pipeline
├── src/jk_tools/      # Distribution mirror (AUTO-SYNCED — DO NOT EDIT)
│   ├── agents/        # Mirrored from agents/
│   ├── scripts/       # Mirrored from scripts/
│   ├── install/       # Mirrored from install/
│   ├── setup_manager.py # Mirrored from root
│   ├── __init__.py    # Package-only file
│   └── cli.py         # Package-only entry point
├── scratch/           # Temporary workspace (gitignored)
├── README.md          # User-facing entrypoint
├── README_AGENTS.md   # Public skill catalog (what's available, how to install)
├── AGENTS.md          # This file — in-repo contributor / agent guide
├── CLAUDE.md          # Same role as AGENTS.md, Claude-convention filename
├── INSTALL.md         # `npx skills` install pattern catalog
├── MIGRATION.md       # Cleanup recipe for previous `./setup.sh` users
└── LICENSE            # Repository license
```

> **Note**: `skills/` is the canonical source for what users install. The legacy sources `agents/v2-commands/`, `other-skills/`, `agents/commands/`, and `agents/commands-lite/` have all been removed — skills ship via `npx skills add jakkaj/tools`.

## Compounding Value System

The **Compounding Value System** is the harness loop: **Boot → Backpressure Check → Do Work and Observe → Retro and Magic Wand → Improve**. The three `skills/harness/` skills serve the recurring stages — Boot (`harness-1-boot`), the Observe half of Do Work and Observe (`harness-2-observe`), and Retro and Magic Wand (`harness-3-retro`); Backpressure Check is the optional `plan-2d-backpressure-survey`, and Improve is encoding the selected fix back into the repo/tooling. The principle is encode-don't-document — every difficulty catalogued is a gift to your future self — and the loop exists so observed friction becomes encoded improvement instead of prose. Three layers:

1. **Philosophy** — *retired as a standalone skill (plan-024).* The 5 principles ("the harness is the product", "track compounding value", "encode, don't document", "measure", "agents are real users") are now encoded inline across the `skills/harness/` skill bodies + the repo [`README.md`](./README.md) — the "encode, don't document" rule applied to itself.
2. **Substrate** — the engineering harness governance doc `docs/project-rules/engineering-harness.md` (legacy `agent-harness.md` / `harness.md` still read as fallback, canonical-first). Provisioning this doc is a **separate engineering-harness setup effort** (not in this repo); `harness-1-boot` validates it at session start and reports `UNAVAILABLE` gracefully when absent.
3. **Loop skills** — [`skills/harness/`](./skills/harness/) — three re-entrant loop-stage skills:
   - `harness-1-boot` — *Boot.* VALIDATE (3-stage Boot/Interact/Observe health check) + STATUS (read-only maturity report)
   - `harness-2-observe` — *Observe.* silent producer; per-agent buffer; magic-wand reflex (≤1/5min calibrated)
   - `harness-3-retro` — *Retro.* `--drain` = session-end soft prompt `[s/t/p/e/d/a]` (default `[a]ll-save`); `--harvest` = curator (clusters + stale + top-10; runtime filters; `--json`; no on-disk indexes, terminal print)

All retros conform to the universal JSON Schema in [`docs/harness/schemas/`](./docs/harness/schemas/) — produced by minih, the harness loop, and any other system that adopts the contract. **minih keeps its own copy of these schemas**, so this is *this repo's* copy of a shared **shape** contract, not a file minih reads. That makes relocating it a purely local move — done here from the old `skills/compound/schemas/` to `docs/harness/schemas/` to retire the leftover `compound` directory name. The only cross-system rule is shape + `schema_version` agreement; don't change the schema's *meaning* without bumping the version and telling minih. `harness-3-retro` bundles a deploy copy at `skills/harness/harness-3-retro/references/retro.schema.json` so the contract travels with the skill; `just doctor-skills` flags drift between the two. Cross-system back-compat: `harness-3-retro --harvest` reads minih's legacy `docs/retros/*.md` block format until minih adopts the universal contract natively (RFC pending — see workshop 005 § Acceptance Criteria for the minih RFC).

**Vocabulary freeze (plan-024, 2026-05-28)**: the three loop-stage names — `harness-1-boot`, `harness-2-observe`, `harness-3-retro` — are the stable public surface and will not be renamed for **≥1 quarter**. This family churned through four names in five weeks; the freeze prevents under-documented renames creeping back (the PL-05 vocabulary-fragility risk). New harness capability lands as new skills or new modes, not renames of these three.

**Opt-out**: `touch docs/harness/.disabled` silences every harness-loop skill (the auto-firing SDD skills check this sentinel before invoking).

**Ledger surface**: this repo's own `docs/harness/` is scaffolded (runtime buffers + per-agent retros + the `schemas/` contract) — see [`docs/harness/README.md`](./docs/harness/README.md).

**Depth**: see [`docs/plans/023-difficulty-ledger-skill/`](./docs/plans/023-difficulty-ledger-skill/) for the original spec + 6 workshops + implementation plan, and [`docs/plans/024-harness-nucleus/`](./docs/plans/024-harness-nucleus/) for the 6→3 loop-stage consolidation (the rename + retirement).

## Tool Installation

The setup script automatically checks for and installs required tools. Each tool has its own installation script in the `install/` directory.

### Currently Automated Tools

- **Rust & Cargo**: The Rust programming language and package manager
- **code2prompt**: CLI tool to convert codebases into LLM prompts
- **FlowSpace (fs2)**: code intelligence MCP server
- **Just, Claude Code CLI, Codex CLI, GitHub Copilot CLI**: per-CLI installers
- **Agent MCP Config**: Shared Serena/Perplexity/FlowSpace MCP server config deployed to Codex CLI, Claude CLI, OpenCode CLI, Copilot CLI, and VS Code (global + project files)

> Skills are **not** installed by these scripts. They are distributed via `npx skills@latest add jakkaj/tools` — see [`INSTALL.md`](./INSTALL.md).

### VS Code MCP Configuration

- Global config: `~/Library/Application Support/Code/User/mcp.json` on macOS, `~/.config/Code/User/mcp.json` on Linux
- Project config: `./.vscode/mcp.json` (auto-generated by the installer)
- Remote environments still require updating the remote user config via VS Code's "MCP: Open Remote User Configuration" command

## Source/Distribution Paradigm

**IMPORTANT**: This repository uses a source/distribution model for packaging.

### Source of Truth (Edit These)
- `agents/` - Agent commands, MCP configs, settings
- `scripts/` - Utility scripts
- `install/` - Installation scripts
- `setup_manager.py` - Setup manager
- `.vscode/` - VS Code planning commands

### Distribution Copy (Never Edit)
- `src/jk_tools/` - Auto-synced mirror for Python package distribution
- This directory is automatically synchronized by `./setup.sh`
- **DO NOT** edit files in `src/jk_tools/` - they will be overwritten

### How Syncing Works

When you run `./setup.sh`, it:
1. **Syncs source → distribution** using `scripts/sync-to-dist.sh`
2. Copies source files from root directories to `src/jk_tools/`
3. Then installs developer tooling and configures MCP servers (no skill fan-out anymore)

**No manual sync needed!** Just edit the source files and run `./setup.sh`.

### What Gets Synced

✅ **Automatically synced:**
- `agents/mcp/` → `src/jk_tools/agents/mcp/`
- `agents/settings.local.json` → `src/jk_tools/agents/settings.local.json`
- `agents/settings.local.json` → `src/jk_tools/agents/`
- `scripts/` → `src/jk_tools/scripts/`
- `install/` → `src/jk_tools/install/`
- `setup_manager.py` → `src/jk_tools/setup_manager.py`
- `.vscode/plan-*.md` and other planning commands → `src/jk_tools/.vscode/`

❌ **Not synced (live source, published directly):**
- `skills/` — top-level skills tree. Consumed by `npx skills` at install time, never mirrored.

❌ **Not synced (package-only):**
- `src/jk_tools/__init__.py`
- `src/jk_tools/cli.py`

❌ **Not synced (project-specific):**
- `.vscode/settings.json`
- `.vscode/mcp.json`

### Adding or Editing a Skill

Skills are the primary deliverable. Source-of-truth: `skills/<category>/<slug>/SKILL.md`.

1. **Pick (or create) a category** under `skills/`. Existing: `SDD/`, `general/`, `personal/`. A new top-level category is fine — it's just a subdirectory.
2. **Create the skill folder** with a kebab-case slug as the folder name:
   ```bash
   mkdir -p skills/<category>/<my-skill>
   ```
3. **Write `SKILL.md`** with the required frontmatter:
   ```yaml
   ---
   name: my-skill            # MUST match the leaf folder name
   description: |
     One or two sentences describing when this skill triggers and what it does.
     This is what an LLM reads to decide whether to invoke the skill.
   ---
   ```
   Optional Anthropic-recognized fields: `model`, `tags`, `version`, `license`, `allowed-tools`, `icon`. The Vercel `npx skills` CLI tolerates extra fields.
4. **Body**: everything after the closing `---`. Markdown-rendered by the host CLI.
5. **Verify slug uniqueness** — `npx skills` flattens by slug at install time, so collisions across categories silently overwrite:
   ```bash
   scripts/check-skill-slugs.sh   # exits 0 if no dupes
   ```
6. **Commit**. Skills are read directly from `skills/` by `npx skills` — no sync step needed for them.

### Installing the skills

There is **no longer a `--commands-local` flag** or any setup.sh-driven skill fan-out. All installs go through `npx skills@latest`:

```bash
# All skills, globally for Claude Code
npx skills@latest add jakkaj/tools -a claude-code -g

# One skill only
npx skills@latest add jakkaj/tools --skill harness-1-boot -a claude-code -g

# Project-local (drop the -g)
cd ~/my-project && npx skills@latest add jakkaj/tools -a claude-code
```

The full 9-pattern catalog (other CLIs, universal, auto-detect, multi-CLI) is in [`INSTALL.md`](./INSTALL.md). The user-facing skill index is in [`README_AGENTS.md`](./README_AGENTS.md).

If you previously ran `./setup.sh` and want to clean up the stale skill copies in `$HOME` from the old fan-out behavior, see [`MIGRATION.md`](./MIGRATION.md).

### Editing existing v2 skills

The 27 SDD skills were migrated from the legacy `agents/v2-commands/*.md` set by `scripts/migrate-skills.py` (retained in `scripts/` for replay/audit). To edit a skill, just edit `skills/SDD/<slug>/SKILL.md` directly. The body is byte-identical to the legacy source; the frontmatter has been normalized to `name:` + `description:` only.

### Deprecated command directories

The legacy `agents/commands/` (v1) and `agents/commands-lite/` (lite pipeline) command sets have been **removed**. The active workflow is the v2 SDD pipeline in `skills/SDD/`, shipped via `npx skills add jakkaj/tools`.

### Adding New Tools

To add a new tool to the repository:

1. **For scripts/utilities**: Place in `scripts/` directory
2. **For tools requiring installation**: Create an install script in `install/` directory
   - Name it `install/<toolname>.sh`
   - Follow the pattern of existing install scripts
   - Check if installed → Install if needed → Verify installation
3. Run `./setup.sh` to apply changes (syncs and installs)
4. Commit and push to share across your machines

### Tool Development Guidelines

When creating new tools, follow these conventions:

1. **Help System**:
   - Must support `--help` flag for detailed documentation
   - Should show help when called with no parameters (if safe to do so)
   - Include: NAME, SYNOPSIS, DESCRIPTION, PARAMETERS, OPTIONS, EXAMPLES
   - Format for both human and AI readability

2. **Naming**:
   - Use descriptive names with dashes (e.g., `analyze-dependencies.sh`)
   - Aliases will be auto-generated with `jk-` prefix

3. **Documentation**:
   - Include purpose and use cases
   - Provide real-world examples
   - List dependencies and requirements
   - Specify expected output format

4. **Integration**:
   - Make tools composable with Unix pipes
   - Use exit codes appropriately (0 for success, non-zero for errors)
   - Support common flags like `--help`, `--version`, `--verbose`

## Benefits

- **Consistency**: Same tools available on all your development machines
- **Version Control**: Track changes and improvements to your tools over time
- **Quick Onboarding**: Set up a new machine with all your tools in seconds
- **No Manual PATH Management**: Automatic PATH configuration for all tools
- **Clean Separation**: Keeps custom tools separate from system utilities

## Usage

After setup, any script in the `scripts/` directory can be called directly from anywhere in your terminal without specifying the full path.

### Discovering Available Tools

To see all available tools and their descriptions:
```bash
jk-tools        # List all tools with descriptions
jk-jt           # Short alias for jk-tools
jk-tools -v     # Verbose mode with full help text
```

### Getting Help

All tools follow a consistent help convention:
```bash
<tool-name> --help    # Get detailed help for any tool
jk-gcm --help         # Example: help for generate-codebase-md
```

### Tool Aliases

Tools with dashes in their names automatically get `jk-` prefixed aliases:
- `generate-codebase-md.sh` → `jk-gcm`
- `jk-tools.sh` → `jk-jt`
- Future tools follow the same pattern

### For AI Assistants / LLMs

When working with this repository, AI assistants should:

1. **Discover available tools**: Run `jk-tools` to see all available utilities
2. **Understand tool purpose**: Each tool has comprehensive help via `--help`
3. **Use aliases**: Prefer short aliases (e.g., `jk-gcm`) for efficiency
4. **Check requirements**: Tools list their dependencies in help text
5. **Use scratch directory**: Output temporary files to `./scratch/` to keep repo clean
6. **Git commands - READ ONLY**: You may use any git command to read repository state (e.g., `git status`, `git diff`, `git log`, `git show`), but **NEVER** modify git state (no `git add`, `git commit`, `git push`, `git checkout`, etc.) unless explicitly requested by the user

Example workflow for an AI assistant:
```bash
# 1. Discover what tools are available
jk-tools

# 2. Get detailed help for a specific tool
jk-gcm --help

# 3. Use the tool with appropriate parameters
jk-gcm ./scratch/analysis ./src

# 4. Process the generated markdown
cat ./scratch/analysis/codebase.md
```

## Legacy Command Sets (Removed)

The v1 `agents/commands/` and lite `agents/commands-lite/` command sets have been **deleted** — they predated `npx skills`. The active workflow is the v2 SDD pipeline in `skills/SDD/`, distributed via `npx skills add jakkaj/tools`.

## Maintenance

### Daily Workflow
- **Edit source files**: Only edit files in source-of-truth directories (`skills/`, `agents/`, `scripts/`, `install/`)
- **Never edit** `src/jk_tools/` — it's auto-synced
- **Run setup**: `./setup.sh` syncs source → distribution and runs dev-tool installers; it does **not** install skills

### Syncing
- **Automatic**: `./setup.sh` syncs source → distribution automatically
- **Manual sync only**: `./scripts/sync-to-dist.sh` (if needed without install)
- **No manual copying needed**: Everything is handled automatically

### Version Control
- Pull latest changes: `git pull`
- Add new tools: Copy to `scripts/` and run `./setup.sh`
- Update existing tools: Edit in place and commit changes
- Share across machines: Push to remote and pull on other machines
- **Commit both**: Source files AND synced `src/jk_tools/` files

### Skills deployment architecture
`npx skills add` writes to `~/.agents/skills/` (canonical) and symlinks `~/.claude/skills/` + `~/.pi/skills/` into it. Other CLIs (Codex, OpenCode, Copilot) read `~/.agents/skills/` directly. The legacy `~/.copilot/skills/` path is an orphan from older `npx skills` versions — if present as a real directory it causes duplicate-with-stale skill discovery. Run `just doctor-skills` to detect and get the fix command. `npx skills add` never **prunes** renamed/removed skills, so deleted skills linger in deploy targets — `just skills-orphans` is a read-only report of slugs present in a target but absent from source `skills/`, with copy-pasteable `tidy:` commands (deletes nothing; you choose). Full notes: [`CLAUDE.md § Skills deployment architecture`](./CLAUDE.md#skills-deployment-architecture).

## Scratch Directory (Ephemeral Workspace)

Use a top-level `scratch/` directory in this repository for temporary experiments, throwaway scripts, notes, or generated files you do **not** want tracked by Git.

### Why
- Keeps the repo clean of WIP and exploratory artifacts
- Avoids accidental commits of large or sensitive temporary files
- Provides an easy, predictable location for ad-hoc work

### Usage
```bash
mkdir -p scratch
cd scratch
# Create or copy experimental files here
```

You can freely create, modify, and delete anything inside `scratch/` without impacting version control. The path is ignored via `.gitignore`.

### Guidelines
- Never store the only copy of important work here—it's untracked
- Safe to wipe/recreate at any time
- Use subfolders if juggling multiple experiments
- If something becomes valuable, move it into a tracked location (e.g. `scripts/`) before committing

### Automation Tip
Add helpers or prototypes here first; once stable, promote them into `scripts/` and run `./setup.sh`.
