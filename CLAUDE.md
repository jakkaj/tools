# CLAUDE.md — Contributor / Dev Guide

This file targets contributors and AI coding assistants working **on** this repository (editing skills, running dev tooling, debugging the sync flow). It is a near-mirror of [`AGENTS.md`](./AGENTS.md) (the AGENTS-convention name for the same role). For the public/user-facing skill catalog, see [`README_AGENTS.md`](./README_AGENTS.md). For install patterns, see [`INSTALL.md`](./INSTALL.md).

---

## What this repo is

A skills repository, plus a dev-tooling installer. The skills are the product:

- **Skills source-of-truth**: `skills/<category>/<slug>/SKILL.md` (top-level, mirrors `mattpocock/skills`).
- **Distribution**: via `npx skills@latest add jakkaj/tools` (Vercel Labs CLI). There is no in-repo skill installer.
- **Dev-tooling installer** (`./setup.sh`): installs Rust, code2prompt, FlowSpace, Claude Code CLI, Codex CLI, GitHub Copilot CLI, and configures MCP servers. Does **not** install skills.

## Layout

```
/
├── skills/                     # Source-of-truth for skills (SKILL.md per skill)
│   ├── SDD/                    # 27 spec-driven-development pipeline skills
│   ├── general/                # 1 skill (grill-me)
│   └── personal/               # 1 skill (shopping-hunter)
├── agents/                     # Installer infra only (legacy command sets removed — skills ship via npx)
│   ├── mcp/servers.json        # MCP server source-of-truth (read by install/agents.sh)
│   └── settings.local.json     # Shared agent settings
├── docs/
│   ├── plans/                  # Plan folders (NNN-slug/) produced by the SDD pipeline
│   └── skills-pipeline/        # Documentation for the SDD pipeline (README, getting-started, etc.)
├── install/                    # Per-tool installer scripts (rust.sh, agents.sh, ...)
├── scripts/                    # Utility scripts (sync-to-dist, migrate-skills, check-skill-slugs, ...)
├── src/jk_tools/               # Auto-synced distribution mirror — DO NOT EDIT
├── setup.sh                    # Entry-point dev-tooling installer
├── setup_manager.py            # Python orchestrator (rich progress, runs install/*.sh)
└── pyproject.toml              # Package metadata (jk-tools-setup CLI)
```

## Compounding Value System

The **Compounding Value System** is the harness loop: **Boot → Do Work → Observe → Retro**. Each skill names the loop stage it serves. The principle is encode-don't-document — every difficulty catalogued is a gift to your future self — and the loop exists so observed friction becomes encoded improvement instead of prose. Three layers:

1. **Philosophy** — *retired as a standalone skill (plan-024).* The 5 principles ("the harness is the product", "track compounding value", "encode, don't document", "measure", "agents are real users") are now encoded inline across the `skills/harness/` skill bodies + the repo [`README.md`](./README.md) — the "encode, don't document" rule applied to itself.
2. **Substrate** — the engineering harness governance doc `docs/project-rules/engineering-harness.md` (legacy `agent-harness.md` / `harness.md` still read as fallback, canonical-first). Provisioning this doc is a **separate engineering-harness setup effort** (not in this repo); `harness-1-boot` validates it at session start and reports `UNAVAILABLE` gracefully when absent.
3. **Loop skills** — [`skills/harness/`](./skills/harness/) — three re-entrant loop-stage skills:
   - `harness-1-boot` — *Boot.* VALIDATE (3-stage Boot/Interact/Observe health check) + STATUS (read-only maturity report)
   - `harness-2-observe` — *Observe.* silent producer; per-agent buffer; magic-wand reflex (≤1/5min calibrated)
   - `harness-3-retro` — *Retro.* `--drain` = session-end soft prompt `[s/t/p/e/d/a]` (default `[a]ll-save`); `--harvest` = curator (clusters + stale + top-10; runtime filters; `--json`; no on-disk indexes, terminal print)

All retros conform to the universal JSON Schema in [`docs/harness/schemas/`](./docs/harness/schemas/) — produced by minih, the harness loop, and any other system that adopts the contract. **minih keeps its own copy of these schemas**, so this is *this repo's* copy of a shared **shape** contract, not a file minih reads. That makes relocating it a purely local move — done here from the old `skills/compound/schemas/` to `docs/harness/schemas/` to retire the leftover `compound` directory name. The only cross-system rule is shape + `schema_version` agreement; don't change the schema's *meaning* without bumping the version and telling minih. `harness-3-retro` bundles a deploy copy at `skills/harness/harness-3-retro/references/retro.schema.json` so the contract travels with the skill; `just doctor-skills` flags drift between the two. Cross-system back-compat: `harness-3-retro --harvest` reads minih's legacy `docs/retros/*.md` block format until minih adopts the universal contract natively (RFC pending — see workshop 005 § Acceptance Criteria for the minih RFC).

**Vocabulary freeze (plan-024, 2026-05-28)**: the three loop-stage names — `harness-1-boot`, `harness-2-observe`, `harness-3-retro` — are the stable public surface and will not be renamed for **≥1 quarter**. This family churned through four names in five weeks (substrate/ledger drift → loop-stage names); the freeze prevents under-documented renames creeping back (the PL-05 vocabulary-fragility risk). New harness capability lands as new skills or new modes, not renames of these three.

**Opt-out**: `touch docs/harness/.disabled` silences every harness-loop skill (the auto-firing SDD skills check this sentinel before invoking).

**Ledger surface**: this repo's own `docs/harness/` is scaffolded (runtime buffers + per-agent retros + the `schemas/` contract) — see [`docs/harness/README.md`](./docs/harness/README.md).

**Depth**: see [`docs/plans/023-difficulty-ledger-skill/`](./docs/plans/023-difficulty-ledger-skill/) for the original spec + 6 workshops + implementation plan, and [`docs/plans/024-harness-nucleus/`](./docs/plans/024-harness-nucleus/) for the 6→3 loop-stage consolidation (the rename + retirement).

## Adding or editing a skill

1. **Pick (or create) a category** under `skills/`. Existing categories: `SDD/`, `general/`, `personal/`. A new category is fine — it's just a subdirectory.
2. **Create the skill folder** with the kebab-case slug as the folder name: `skills/<category>/<my-skill>/SKILL.md`.
3. **Write the frontmatter**. Two fields are required:

   ```yaml
   ---
   name: my-skill            # MUST match the leaf folder name
   description: |
     One or two sentences describing when this skill triggers and what it does.
     This is what an LLM reads to decide whether to invoke the skill.
   ---
   ```

   Optional fields supported by Anthropic SKILL.md: `model`, `tags`, `version`, `license`, `allowed-tools`, `icon`. The Vercel `npx skills` CLI tolerates extra fields.

4. **Body**: everything after the closing `---` is the skill content. Markdown-rendered by the host CLI.
5. **Verify slug uniqueness** — `npx skills` flattens by slug at install time, so collisions across categories silently overwrite. Run:

   ```bash
   scripts/check-skill-slugs.sh
   ```

   Exits 0 if no duplicates, 1 if any are found.

6. **Commit**. No further sync step is required — skills are read directly from `skills/` by the Vercel CLI.

## Editing existing v2 skills

The 27 SDD skills were migrated from the legacy v2 command set by `scripts/migrate-skills.py` (retained in `scripts/` for replay/audit). To edit a skill, just edit `skills/SDD/<slug>/SKILL.md` directly. Body is byte-identical to the legacy source; the frontmatter has been normalized to `name:` + `description:` only.

## Source / distribution sync

The `src/jk_tools/` tree is an auto-synced mirror used for Python packaging (the `jk-tools-setup` console script published from this repo). It is regenerated by `scripts/sync-to-dist.sh` whenever you run `./setup.sh` from a git checkout.

- **Edit**: source files in `agents/`, `scripts/`, `install/`, `setup_manager.py`.
- **Never edit**: anything under `src/jk_tools/`. Changes there will be overwritten on the next sync.
- **Trigger sync manually**: `./scripts/sync-to-dist.sh`.

The sync **no longer mirrors any skill content**. Skills are published directly from the top-level `skills/` tree via `npx skills`.

## Skills deployment architecture

`npx skills add` (called by `just install-skills*`) writes skills to a **canonical store** and **symlinks** per-CLI views into it. After running an install:

- **Canonical store**: `~/.agents/skills/<slug>/` — real directories; single source of truth on disk.
- **Symlinked views**: `~/.claude/skills/<slug>` and `~/.pi/skills/<slug>` are symlinks back to the canonical store (managed by `npx skills`).
- **Other CLIs**: Codex, OpenCode, GitHub Copilot read from `~/.agents/skills/` directly — no per-CLI symlink dir.

**Why symlinks not copies**: a copy would drift the moment one CLI's view was updated and another wasn't. Symlinks make drift impossible — every view tracks the canonical store.

**Known orphan path**: `~/.copilot/skills/`. Older versions of `npx skills` wrote skills there as real directories. If it exists today it's stale (the current install no longer targets it) and will cause **duplicate skill discovery entries with divergent content** as `~/.agents/skills/` evolves. Fix:

```bash
rm -rf ~/.copilot/skills                            # nuke (preferred — nothing reads it anymore)
# OR, if something still reads from that path:
ln -s ~/.agents/skills ~/.copilot/skills            # symlink to canonical
```

**Diagnosis**: `just doctor-skills` reports canonical-store size, validates expected symlinks, and flags any orphan real-dir skill stores at known legacy paths. Run it after any `npx skills` upgrade or if you see the same skill name surface twice in skill discovery.

**Stale/renamed-skill drift**: `npx skills add` only **adds/updates** — it never **prunes** a skill that was renamed or removed from source, so deleted skills linger in the deploy targets. `just skills-orphans` is a **read-only** report that diffs this repo's source `skills/` against every deploy target (`~/.agents/skills` canonical + per-CLI views + legacy paths) and lists slugs present in a target but absent from source, with a copy-pasteable `tidy:` `rm` line per target. It **deletes nothing** — you choose what to remove (legitimately hand-installed local-only skills like `pack-code` also surface, so only tidy what you recognise as stale). Run it after deleting/renaming a skill.

## Running the dev-tooling installer

```bash
./setup.sh                       # idempotent; safe to re-run
uvx --from . jk-tools-setup      # via uvx, modern mode (no clone needed)
uvx --from . jk-tools-setup -u   # update mode for tracked tools
```

The installer:

1. Syncs source files to the `src/jk_tools/` mirror (dev mode only).
2. Installs the Claude Code status line.
3. Runs `setup_manager.py`, which adds `scripts/` to PATH, makes scripts executable, and runs each script in `install/` in dependency order (just → rust → code2prompt → fs2 → agents.sh → claude-code → codex → copilot-cli → aliases).
4. `install/agents.sh` writes MCP server configs to Claude, OpenCode, Codex, VS Code, and Copilot CLI. It does **not** copy any skill files.

## Testing changes

- **Slug-collision check**: `scripts/check-skill-slugs.sh`
- **Body byte-diff** (after re-running migration): `python3 scripts/migrate-skills.py` (idempotent — `[skip] <slug>` on every entry if no source changes).
- **MCP smoke**: run `./setup.sh` in a sandbox and confirm MCP config files appear in `~/.claude.json`, `~/.codex/config.toml`, `~/.config/opencode/opencode.json`, etc.
- **Skills smoke** (against pushed branch): `npx skills@latest add jakkaj/tools --skill <slug> -a claude-code -g` and inspect `~/.claude/skills/<slug>/SKILL.md`.

## Plan folders

Non-trivial changes follow the SDD pipeline in `docs/plans/NNN-<slug>/`. Each plan folder typically contains:

- `<slug>-spec.md` — feature spec (WHAT/WHY)
- `<slug>-plan.md` — implementation plan (HOW)
- `<slug>.fltplan.md` — flight plan / executive overview
- `research-dossier.md` — pre-spec research (optional)
- `workshops/` — design workshops (optional)
- `execution.log.md` — implementation log

Ordinals are allocated via `scripts/plan-ordinal.py` (alias `jk-po`), which scans every git branch to avoid collisions.

## Deprecated directories

The legacy command sets `agents/commands/` (v1) and `agents/commands-lite/` (lite pipeline) have been **removed** — the active workflow is the v2 SDD pipeline in `skills/SDD/`, distributed via `npx skills add jakkaj/tools`. `agents/` now holds installer infra only (`mcp/servers.json`, `settings.local.json`).

## Pointers

- **Public skill catalog**: [`README_AGENTS.md`](./README_AGENTS.md)
- **In-repo agent guide (alt path)**: [`AGENTS.md`](./AGENTS.md) — kept in sync with this file for the AGENTS-convention name
- **Install patterns**: [`INSTALL.md`](./INSTALL.md)
- **Cleanup for previous setup.sh users**: [`MIGRATION.md`](./MIGRATION.md)
- **SDD pipeline reference**: [`docs/skills-pipeline/README.md`](./docs/skills-pipeline/README.md)
