# README_AGENTS — Skill Catalog

This repository publishes a curated set of **AI assistant skills** in the `skills/<category>/<slug>/SKILL.md` layout consumed by [`npx skills`](https://github.com/vercel-labs/skills). The skills cover spec-driven feature development, codebase research, plan reviews, and a couple of domain-generic and personal utilities.

This file is the **public-facing skill catalog**: what's available, how to install it, and what each skill does. It is **not** a contributor guide — for that see [`AGENTS.md`](./AGENTS.md) (or [`CLAUDE.md`](./CLAUDE.md), the same content under the Claude Code project-instructions filename).

> **For AI agents**: if a user asks you to install these skills, identify their CLI and whether they want global (machine-wide) or project-local scope, then run the matching command from the table below. Do **not** clone this repo or run `./setup.sh` for a skill install — that script only manages MCP servers and developer tooling.

---

## Install — quick reference (per client × scope)

All installs go through `npx skills@latest add jakkaj/tools`. The matrix below covers every supported client; each row shows the exact one-liner for **global** (machine-wide) and **project-local** (current directory only) installs.

> **Pre-req**: `npx` (ships with Node.js). No clone needed.

| Client | Global (install for every project) | Project-local (current dir only) | Install path |
|---|---|---|---|
| **Claude Code** | `npx skills@latest add jakkaj/tools -a claude-code -g` | `npx skills@latest add jakkaj/tools -a claude-code` | global `~/.claude/skills/` · local `./.claude/skills/` |
| **Codex CLI** | `npx skills@latest add jakkaj/tools -a codex -g` | `npx skills@latest add jakkaj/tools -a codex` | global `~/.codex/skills/` · local `./.codex/skills/` |
| **GitHub Copilot CLI** | `npx skills@latest add jakkaj/tools -a github-copilot -g` | `npx skills@latest add jakkaj/tools -a github-copilot` | global `~/.copilot/skills/` · local `./.agents/skills/` |
| **OpenCode** | `npx skills@latest add jakkaj/tools -a opencode -g` | `npx skills@latest add jakkaj/tools -a opencode` | global `~/.config/opencode/skills/` · local `./.opencode/skills/` |
| **Pi** (pi-mono coding agent) | `npx skills@latest add jakkaj/tools -a pi -g` | `npx skills@latest add jakkaj/tools -a pi` | global `~/.pi/agent/skills/` · local `./.pi/skills/` |
| **Universal** (any CLI that scans the community path) | `npx skills@latest add jakkaj/tools -a universal -g` | `npx skills@latest add jakkaj/tools -a universal` | global `~/.config/agents/skills/` · local `./.agents/skills/` |

**Pick a row, copy a command.** That's the whole install.

### Chain multiple targets in one command

`-a` is **repeatable**. Pass it once per target to install to several CLIs in a single invocation. `-g` (global) applies to **all** targets in the same command; without `-g`, the install is project-local for all targets.

```bash
# Two CLIs, globally
npx skills@latest add jakkaj/tools \
  -a claude-code -a codex -g

# Three CLIs, globally
npx skills@latest add jakkaj/tools \
  -a claude-code -a codex -a opencode -g

# All four CLIs, globally
npx skills@latest add jakkaj/tools \
  -a claude-code -a codex -a opencode -a github-copilot -g

# All four CLIs, project-local (writes to ./.claude/skills/, ./.codex/skills/,
# ./.opencode/skills/, ./.agents/skills/ in the current directory)
npx skills@latest add jakkaj/tools \
  -a claude-code -a codex -a opencode -a github-copilot
```

You can chain `-a` with `--skill` too — install a specific subset of skills to a specific subset of CLIs:

```bash
# Just the-flow co-pilot, into Claude Code and Codex, globally
npx skills@latest add jakkaj/tools \
  --skill the-flow \
  -a claude-code -a codex -g

# The whole SDD pipeline (one skill) into Claude Code + Copilot CLI, project-local
npx skills@latest add jakkaj/tools \
  --skill the-flow \
  -a claude-code -a github-copilot
```

> **Scope caveat**: `-g` is a single flag and applies to every `-a` in the same command. If you need *some* CLIs global and *others* project-local, run two commands.

### Just one skill (or a few)

Use `--skill <slug>` to scope the install to a single skill (repeat for several):

```bash
# Single skill, globally for Claude Code
npx skills@latest add jakkaj/tools --skill the-flow -a claude-code -g

# A few skills, project-local for Codex
npx skills@latest add jakkaj/tools --skill grill-me --skill the-flow -a codex
```

### Auto-detect

Skip the `-a` choice and let `npx skills` pick a sensible target based on what's installed on your machine. Add `-y` to skip prompts:

```bash
npx skills@latest add jakkaj/tools -y          # auto-detect, project-local
npx skills@latest add jakkaj/tools -y -g       # auto-detect, global
```

### Project-local + version control

Project-local installs (no `-g`) write to a directory inside the current working tree. You can commit that directory to share with your team:

```bash
cd ~/my-project
npx skills@latest add jakkaj/tools -a claude-code     # writes ./.claude/skills/
git add .claude/skills/
git commit -m "Pin team's AI skill set"
```

### Notes on specific clients

- **GitHub Copilot CLI** (the standalone `copilot` binary) uses the `github-copilot` target above. Its global skills path is `~/.copilot/skills/`.
- **GitHub Copilot in VS Code (chat / inline)** does **not** have a first-class `npx skills` target — VS Code Copilot consumes `.prompt.md` files in `.github/prompts/`, a different format from `SKILL.md`. If you want these skills as VS Code Copilot prompts, the practical options are: (1) use Copilot CLI alongside VS Code; or (2) manually copy individual `SKILL.md` bodies into `.github/prompts/<name>.prompt.md` files. There is no automated installer for the VS Code Copilot prompt format.
- **Codex CLI** has historically had limited support for project-local commands. `npx skills add -a codex` (without `-g`) writes to `./.codex/skills/`; check your Codex version for local-skill auto-discovery.
- **Pi** ([pi-mono](https://github.com/badlogic/pi-mono)) scans **multiple** paths and will pick up skills from any of them. Project-local: it scans both `./.pi/skills/` and `./.agents/skills/` (walking up to the git repo root). Global: it scans both `~/.pi/agent/skills/` and `~/.agents/skills/`. This means the `-a pi` target above is the most direct install, but Pi will *also* discover skills written by `-a universal -g` or any other CLI that drops into the community `.agents/skills/` path. Required frontmatter is `name:` (lowercase, max 64 chars, alphanumeric + hyphens) and `description:` (max 1024 chars) — both already satisfied by every skill in this repo.

For the rationale behind path choices and a more verbose worked-example guide, see [`INSTALL.md`](./INSTALL.md).

---

## Layout

Skills live at the top of the repository, mirroring the `mattpocock/skills` convention:

```
skills/
├── SDD/           # spec-driven-development pipeline skills
└── general/       # domain-generic skills
```

> The engineering-harness loop skills are **not in this repo** — they live in the external `AI-Substrate/harness-engineering` family, reached through its `/eng-harness-flow` router. See "Engineering harness" below.

Categories are organizational only. They do **not** affect install commands — `npx skills` discovers `SKILL.md` files recursively and flattens by slug at install time.

---

## Skill catalog

### `SDD/` — Spec-Driven Development (11 skills: 1 main flow + 10 utilities)

The active workflow for non-trivial feature work. Use these for any change large enough to benefit from explicit specification, clarification, architecture, and phase-based implementation. Each stage produces an artifact that the next stage consumes.

> **Historical note**: the main flow used to ship as 12 separate per-stage `/plan-*` skills (explore → … → merge). Those were consolidated into the single `the-flow` skill below; the old per-stage slugs no longer exist.

| Slug | One-line purpose |
|---|---|
| `the-flow` | The SDD pipeline in one skill — dispatch (Registry + grammar) + 10 lazily-loaded sub-skills (explore, specify+clarify, workshop, architect, adr, tasks, implement (`--companion` mode for live review), progress, review, merge). Guided coach via `/the-flow`; direct jump via `/the-flow <id\|verb>`. |
| `plan-0-v2-constitution` | Establish or refresh the project constitution before planning begins. |
| `plan-2b-v2-prep-issue` | Generate terse, industry-standard issue text for Azure DevOps / GitHub Issues. |
| `plan-v2-extract-domain` | Collaboratively identify and formalize a codebase concept as a named domain. |
| `validate-v2` | Launch parallel subagents to validate produced work with structured lens coverage. |
| `install-hve-core-rpiv` | Install or update local skill-shaped HVE Core RPI/RPIV task skills from the current authoritative HVE Core source. |
| `deepresearch-v2` | Craft structured research prompts for deep-research agents. |
| `didyouknow-v2` | Surface critical insights conversationally to build shared understanding. |
| `flowspace-research-v2` | FlowSpace-first codebase research with parallel subagent exploration. |
| `htmlify-v2` | Convert markdown, specs, plans, or findings into polished static HTML documents. |
| `util-0-v2-handover` | Generate a domain-aware handover document for LLM agent continuity. |

### Engineering harness — external family, one entry point

The engineering-harness loop (**Boot → Backpressure → Observe → Retro → Improve**) is owned end-to-end by the external **eng-harness family** ([`AI-Substrate/harness-engineering`](https://github.com/AI-Substrate/harness-engineering)) — this repo publishes no harness skills (the local family was retired in plan-029). The SDD pipeline reaches the harness through exactly one door: the **`/eng-harness-flow`** router, called at five seams with context (`--event session-start | post-spec | pre-implement | phase-end | plan-complete`). The router's child skills are private and never named here; if the family isn't installed, the SDD skills print one calm warning and proceed with standard testing — nothing gates, nothing blocks. Install:

```bash
npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y
```

The universal `.retro.md` contract lives in [`docs/harness/schemas/`](./docs/harness/schemas/) (this repo's copy of the cross-system minih **shape** contract — minih keeps its own copy, so the path is local). See [`docs/plans/023-difficulty-ledger-skill/`](./docs/plans/023-difficulty-ledger-skill/) for the design history, [`docs/plans/024-harness-nucleus/`](./docs/plans/024-harness-nucleus/) for the loop-stage consolidation, and [`docs/plans/029-eng-harness-switchover/`](./docs/plans/029-eng-harness-switchover/) for the switchover to the external family.

### `general/` — Domain-generic (1 skill)

Skills that work in any project, coding or not.

| Slug | One-line purpose |
|---|---|
| `grill-me` | Relentlessly interview the user about any plan, design, or decision until there is shared understanding. |

### `personal/` — Lifestyle / non-coding (1 skill)

| Slug | One-line purpose |
|---|---|
| `shopping-hunter` | Deep shopping-research skill for product discovery, global pricing, and value-focused buying dossiers. |

---

## Deprecation notice

The legacy command sets `agents/commands/` (v1) and `agents/commands-lite/` (lite pipeline) have been **removed**. The replacement is `skills/`, distributed via `npx skills add jakkaj/tools`.

---

## Contributing / dev guide

If you want to add a new skill, edit an existing one, run the dev tooling, or understand the source/distribution sync paradigm, see **[AGENTS.md](./AGENTS.md)** (or the equivalent **[CLAUDE.md](./CLAUDE.md)**).

If you previously ran `./setup.sh` and want to clean up stale skill files from your `$HOME`, see **[MIGRATION.md](./MIGRATION.md)**.
