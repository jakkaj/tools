# INSTALL.md — Skill Installation Reference

> **For AI agents reading this**: this file is the canonical install reference for the skills in this repository. If a user asks you to install one or more of these skills, identify which CLI tool they use (Claude Code, Codex CLI, GitHub Copilot CLI, OpenCode, etc.) and whether they want a global install (available everywhere) or project-local install (current directory only), then run the corresponding `npx skills@latest add jakkaj/tools …` command from the catalog below. Do **not** clone the repository or run `./setup.sh` to install skills — that script only manages MCP servers and developer tooling.

This repository publishes its skills in the `skills/<category>/<slug>/SKILL.md` layout consumed by [`npx skills@latest`](https://www.npmjs.com/package/skills) (Vercel Labs). All installs go through that CLI; there is no repo-specific installer.

---

## Skill Categories

Skills are grouped by purpose. Categories are organizational only — they do **not** affect install commands.

| Category | What's in it | Count |
|---|---|---|
| `SDD/` | The spec-driven-development (SDD) pipeline — domain-aware plan, specify, clarify, architect, workshop, implement, review skills. The active workflow for non-trivial features. | 29 |
| `general/` | Domain-generic skills that work in any project (e.g. `grill-me` — relentlessly interrogates plans/designs until shared understanding). | 1 |
| `personal/` | Personal / lifestyle / non-coding skills (e.g. `shopping-hunter` — product research and pricing dossiers). | 1 |

A full listing of every skill is in [`README_AGENTS.md`](./README_AGENTS.md).

---

## Canonical Install Patterns

Each pattern is a one-liner. Substitute `<slug>` with a skill name (e.g. `harness-is-the-product-v2`, `grill-me`).

### (a) Install everything globally for Claude Code

```bash
npx skills@latest add jakkaj/tools -a claude-code -g
```

Installs every skill in this repo to `~/.claude/skills/`. Available in every Claude Code session, on any project.

### (b) Install everything globally for Codex CLI

```bash
npx skills@latest add jakkaj/tools -a codex -g
```

Target: `~/.codex/skills/`.

### (c) Install everything globally for GitHub Copilot CLI

```bash
npx skills@latest add jakkaj/tools -a github-copilot -g
```

Target: `~/.copilot/skills/`.

### (d) Install everything globally for OpenCode

```bash
npx skills@latest add jakkaj/tools -a opencode -g
```

Target: `~/.config/opencode/skills/`.

### (d2) Install everything globally for Pi (pi-mono)

```bash
npx skills@latest add jakkaj/tools -a pi -g
```

Target: `~/.pi/agent/skills/`. Note: Pi also scans `~/.agents/skills/`, so a `-a universal -g` install would be discovered too. The Pi coding agent is at [github.com/badlogic/pi-mono](https://github.com/badlogic/pi-mono).

### (e) Install for multiple CLIs in one command

Pass `-a` multiple times to fan out to several targets:

```bash
npx skills@latest add jakkaj/tools -a claude-code -a codex -a opencode -g
```

### (f) Install just one skill via `--skill`

Use `--skill <slug>` to scope the install to a single skill rather than the full set:

```bash
npx skills@latest add jakkaj/tools --skill harness-is-the-product-v2 -a claude-code -g
```

Repeat `--skill` to install a subset:

```bash
npx skills@latest add jakkaj/tools --skill grill-me --skill plan-1a-v2-explore -a claude-code -g
```

### (g) Install project-locally (current directory)

Drop the `-g` flag to install into the current working directory's CLI-specific local path (e.g. `./.claude/skills/` for Claude Code):

```bash
npx skills@latest add jakkaj/tools -a claude-code
```

Useful when a project wants a committed, project-pinned set of skills. The destination depends on the CLI — see the [Vercel `skills` CLI README](https://github.com/vercel-labs/skills) for the per-target local path.

### (h) Auto-detect (`-y`)

Let the CLI pick a sensible target based on what it sees installed on the machine, and skip confirmation prompts:

```bash
npx skills@latest add jakkaj/tools -y
```

Good for one-line "just install everything for me" flows.

### (i) Universal cross-CLI install (`-a universal`)

Install once into the cross-CLI community location (`.agents/skills/` for project-local, or `~/.config/agents/skills/` for global) so any CLI that scans the universal path picks them up:

```bash
npx skills@latest add jakkaj/tools -a universal -g
```

Note: Claude Code does **not** scan the universal path — for Claude Code, use `-a claude-code` explicitly.

---

## Worked Examples

**"I'm a Claude Code user and want all the SDD planning skills available globally."**

```bash
npx skills@latest add jakkaj/tools -a claude-code -g
```

**"I want just `grill-me` available in Codex, no other skills."**

```bash
npx skills@latest add jakkaj/tools --skill grill-me -a codex -g
```

**"My team uses Claude Code; we want the skills checked into this repo."**

```bash
cd ~/my-project && npx skills@latest add jakkaj/tools -a claude-code
# commit ./.claude/skills/ to git
```

**"I have multiple CLIs and want one command to set them all up."**

```bash
npx skills@latest add jakkaj/tools -a claude-code -a codex -a opencode -a github-copilot -g
```

---

## What this repository's `./setup.sh` does and does not do

- `./setup.sh` installs **developer tooling** (Rust, code2prompt, FlowSpace, Claude Code CLI, Codex CLI, GitHub Copilot CLI) and configures **MCP servers** across those CLIs. It does **not** install skills.
- If you cloned this repo to contribute, run `./setup.sh` for the dev environment, then use the `npx skills add` commands above to actually install the skills.
- If you want only the skills and not the dev tooling, you don't need to clone the repo at all — just run `npx skills@latest add jakkaj/tools …`.

See [`MIGRATION.md`](./MIGRATION.md) if you previously installed skills via `./setup.sh` and want to clean up the stale files in your `$HOME`.
