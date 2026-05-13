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
# Just the harness skill, into Claude Code and Codex, globally
npx skills@latest add jakkaj/tools \
  --skill harness-is-the-product-v2 \
  -a claude-code -a codex -g

# Three planning skills into Claude Code + Copilot CLI, project-local
npx skills@latest add jakkaj/tools \
  --skill plan-1a-v2-explore --skill plan-1b-v2-specify --skill plan-3-v2-architect \
  -a claude-code -a github-copilot
```

> **Scope caveat**: `-g` is a single flag and applies to every `-a` in the same command. If you need *some* CLIs global and *others* project-local, run two commands.

### Just one skill (or a few)

Use `--skill <slug>` to scope the install to a single skill (repeat for several):

```bash
# Single skill, globally for Claude Code
npx skills@latest add jakkaj/tools --skill harness-is-the-product-v2 -a claude-code -g

# A few skills, project-local for Codex
npx skills@latest add jakkaj/tools --skill grill-me --skill plan-1a-v2-explore -a codex
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
├── SDD/           # 27 spec-driven-development pipeline skills
├── general/       # domain-generic skills
└── personal/      # personal / non-coding skills
```

Categories are organizational only. They do **not** affect install commands — `npx skills` discovers `SKILL.md` files recursively and flattens by slug at install time.

---

## Skill catalog

### `SDD/` — Spec-Driven Development (27 skills)

The active workflow for non-trivial feature work. Use these for any change large enough to benefit from explicit specification, clarification, architecture, and phase-based implementation. Each step produces an artifact that the next step consumes.

| Slug | One-line purpose |
|---|---|
| `plan-0-v2-constitution` | Establish or refresh the project constitution before planning begins. |
| `plan-1a-v2-explore` | Deep-dive research into existing codebase functionality before specification. |
| `plan-1b-v2-specify` | Create or update a feature spec from a natural-language description (WHAT/WHY only). |
| `plan-2-v2-clarify` | Resolve high-impact ambiguities (≤8 questions) and update the spec. |
| `plan-2b-v2-prep-issue` | Generate terse, industry-standard issue text for Azure DevOps / GitHub Issues. |
| `plan-2c-v2-workshop` | Create detailed design documents for complex concepts surfaced in the spec. |
| `plan-3-v2-architect` | Generate a domain-aware, lean implementation plan with phases and task tables. |
| `plan-3a-v2-adr` | Generate an Architectural Decision Record from the spec and clarifications. |
| `plan-4-v2-complete-the-plan` | Assess plan completeness before execution; readiness gate. |
| `plan-5-v2-phase-tasks-and-brief` | Generate a tasks dossier (tasks + context brief) for a phase. |
| `plan-5b-flightplan` | Generate a consumable Flight Plan (`.fltplan.md`) at phase or plan level. |
| `plan-6-v2-implement-phase` | Implement exactly one approved phase using the chosen testing approach. |
| `plan-6-v2-implement-phase-companion` | Implement a phase with a parallel code-review companion (Power-On-Mode). |
| `plan-6a-v2-update-progress` | Update plan progress atomically with task status and domain context. |
| `plan-6b-worked-example` | Generate a runnable worked example demonstrating a phase's implementation. |
| `plan-7-v2-code-review` | Read-only per-phase code review with domain compliance validation. |
| `plan-8-v2-merge` | Analyze upstream changes from `main` and generate a merge plan. |
| `plan-v2-extract-domain` | Collaboratively identify and formalize a codebase concept as a named domain. |
| `validate-v2` | Launch parallel subagents to validate produced work with structured lens coverage. |
| `agent-harness-v2` | Create or validate the agent harness for the current project. |
| `harness-is-the-product-v2` | Re-ground the session on the core philosophy — the harness is the product. |
| `code-concept-search-v2` | Find a concept in the codebase by walking through code like a human engineer. |
| `deepresearch-v2` | Craft structured research prompts for deep-research agents. |
| `didyouknow-v2` | Surface critical insights conversationally to build shared understanding. |
| `flowspace-research-v2` | FlowSpace-first codebase research with parallel subagent exploration. |
| `htmlify-v2` | Convert markdown, specs, plans, or findings into polished static HTML documents. |
| `util-0-v2-handover` | Generate a domain-aware handover document for LLM agent continuity. |

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

Two directories in this repository are retained for reference only and are **no longer maintained**:

- [`agents/commands/`](./agents/commands/) — the v1 command set. See [`agents/commands/DEPRECATED.md`](./agents/commands/DEPRECATED.md).
- [`agents/commands-lite/`](./agents/commands-lite/) — the lite-pipeline command set. See [`agents/commands-lite/DEPRECATED.md`](./agents/commands-lite/DEPRECATED.md).

Both directories are slated for deletion in a future cleanup pass. Do not add new content to either. The replacement is `skills/`.

---

## Contributing / dev guide

If you want to add a new skill, edit an existing one, run the dev tooling, or understand the source/distribution sync paradigm, see **[AGENTS.md](./AGENTS.md)** (or the equivalent **[CLAUDE.md](./CLAUDE.md)**).

If you previously ran `./setup.sh` and want to clean up stale skill files from your `$HOME`, see **[MIGRATION.md](./MIGRATION.md)**.
