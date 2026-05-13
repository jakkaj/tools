# External Research: CLI Install Paths + SKILL.md Spec Verification

**Generated**: 2026-05-13
**Method**: Perplexity Deep Research (Sonar Deep Research, reasoning_effort=high) **+ direct source-code verification** of `vercel-labs/skills` via `gh api`. Where Perplexity surfaced uncertainty, the relevant Vercel CLI source files were pulled and read.
**Status**: Major facts verified from canonical source. Two gaps remain (flagged below).

---

## Headline conclusions for the refactor

1. **`.agents/skills` is the cross-CLI project-local convention** — used by Vercel CLI's `universal` target and 8 of 13 named targets we care about (codex, cursor, gemini-cli, github-copilot, opencode, cline, warp, plus the catch-all). Claude Code is the notable exception (still uses `.claude/skills`). Roo uses `.roo/skills`, Kilo uses `.kilocode/skills`, Windsurf uses `.windsurf/skills`.
2. **The Vercel CLI doesn't validate SKILL.md frontmatter beyond presence of `name` and `description` as strings.** Length limits, character classes, and field whitelists are enforced (variably) by the *consuming* agents, not the CLI.
3. **The default install operation is symlink, not copy.** A canonical store under `~/.agents/skills/<name>/` holds the skill body, and agent-specific paths are *symlinks* to it. Falls back to copy on Windows or when symlink fails. This contradicts the assumption in our initial dossier.
4. **Source-repo discovery is recursive (max depth 5), not constrained to a top-level `skills/` directory.** Vercel CLI walks the repo and finds any `SKILL.md`, skipping `node_modules`, `.git`, `dist`, `build`, `__pycache__`.

---

## Part A — Vercel Labs `skills` CLI install paths (DEFINITIVE)

Read directly from `vercel-labs/skills` `src/agents.ts` and `src/types.ts` on 2026-05-13.

### Constants used in the config
```ts
home       = os.homedir()
configHome = xdg-basedir ?? join(home, '.config')          // ~/.config on Mac/Linux
codexHome  = process.env.CODEX_HOME?.trim()  || join(home, '.codex')
claudeHome = process.env.CLAUDE_CONFIG_DIR?.trim() || join(home, '.claude')
```

### Per-target paths (only targets relevant to our installer — full list is 54 platforms)

| Target flag (`-a ...`) | Project-local (`skillsDir`) | Global (`globalSkillsDir`) | Detect-installed check |
|---|---|---|---|
| `claude-code` | `.claude/skills` | `~/.claude/skills` (or `$CLAUDE_CONFIG_DIR/skills`) | `~/.claude` exists |
| `opencode` | `.agents/skills` | `~/.config/opencode/skills` (xdg-aware) | `~/.config/opencode` exists |
| `codex` | `.agents/skills` | `~/.codex/skills` (or `$CODEX_HOME/skills`) | `~/.codex` OR `/etc/codex` exists |
| `cursor` | `.agents/skills` | `~/.cursor/skills` | `~/.cursor` exists |
| `gemini-cli` | `.agents/skills` | `~/.gemini/skills` | `~/.gemini` exists |
| `github-copilot` | `.agents/skills` | `~/.copilot/skills` | `~/.copilot` exists |
| `cline` | `.agents/skills` | `~/.agents/skills` | `~/.cline` exists |
| `warp` | `.agents/skills` | `~/.agents/skills` | `~/.warp` exists |
| `windsurf` | `.windsurf/skills` | `~/.codeium/windsurf/skills` | `~/.codeium/windsurf` exists |
| `roo` | `.roo/skills` | `~/.roo/skills` | `~/.roo` exists |
| `kilo` | `.kilocode/skills` | `~/.kilocode/skills` | `~/.kilocode` exists |
| `aider-desk` | `.aider-desk/skills` | `~/.aider-desk/skills` | `~/.aider-desk` exists |
| `universal` | `.agents/skills` | `~/.config/agents/skills` | always false (catch-all) |

**Full target list** (from `AgentType` union in `src/types.ts`, 54 entries):
`aider-desk, amp, antigravity, augment, bob, claude-code, openclaw, cline, codearts-agent, codebuddy, codemaker, codestudio, codex, command-code, continue, cortex, crush, cursor, deepagents, devin, dexto, droid, firebender, forgecode, gemini-cli, github-copilot, goose, hermes-agent, iflow-cli, junie, kilo, kimi-cli, kiro-cli, kode, mcpjam, mistral-vibe, mux, neovate, opencode, openhands, pi, qoder, qwen-code, replit, roo, rovodev, tabnine-cli, trae, trae-cn, warp, windsurf, zencoder, pochi, adal, universal`

### Behavior questions answered

**Q1: Does the source repo require a top-level `skills/` directory?**
**No.** `src/skills.ts:findSkillDirs` walks the repo recursively to a max depth of 5, looking for any directory containing a `SKILL.md` file. Skip-list: `node_modules`, `.git`, `dist`, `build`, `__pycache__`. So `skills/foo/SKILL.md`, `agents/bar/SKILL.md`, and `mypath/baz/SKILL.md` would all be discovered identically. (Source: `vercel-labs/skills/src/skills.ts` lines defining `SKIP_DIRS` and `findSkillDirs`.)

**Q2: How does `skills update` / removal decide which skills to prune?**
A **local lockfile** (`skills-lock.json` in the project root, written by `src/local-lock.ts`) records every installed skill's `source`, `ref`, and `sourceType`. The `remove` command (`src/remove.ts`) scans the canonical install dir (`getCanonicalSkillsDir`) and matches skill folder names against the user's request — no diff against source, the lockfile is the authoritative manifest. `runInstallFromLock` rehydrates skills from the lockfile.

**Q3: Symlink, copy, or hardlink?**
**Default = symlink.** From `src/installer.ts`:
- `export type InstallMode = 'symlink' | 'copy';` (line 23)
- Default mode is `symlink` (line 241, `options.mode ?? 'symlink'`)
- Real skill body lives at the **canonical store** (`~/.agents/skills/<name>/` typically)
- Agent-specific install dirs (`~/.claude/skills/<name>/` etc.) are *symlinks* pointing to the canonical dir
- Windows uses `'junction'` symlink type (line 218: `platform() === 'win32' ? 'junction' : undefined`)
- Fallback to `copy` if symlink creation fails (broken `ELOOP`, permissions, etc.)

**Implication for our installer:** if we want to match Vercel CLI semantics, our installer should symlink (with copy fallback). **Decision (2026-05-13): we copy, not symlink, for Windows cross-platform reliability.** Symlinks on Windows require admin/developer-mode privileges or NTFS junctions (Vercel CLI uses junctions, but adds failure modes — `EPERM`, broken-junction edge cases, restricted file managers). Plain copy is universally safe across macOS, Linux, WSL, Git Bash, plain Windows. Disk cost is trivial (27 small Markdown files × N targets). This diverges deliberately from Vercel CLI's default.

---

## Part B — SKILL.md frontmatter spec

### What the Vercel CLI validates (DEFINITIVE, from `src/skills.ts:parseSkillMd` and `src/frontmatter.ts`)

```ts
// parseSkillMd rejects the file (returns null) UNLESS:
if (!data.name || !data.description) return null;
if (typeof data.name !== 'string' || typeof data.description !== 'string') return null;
```

That's the *entire* Vercel-CLI-side schema:
- `name`: **required, must be a string.** No regex check, no length check at the CLI level.
- `description`: **required, must be a string.** No length check at the CLI level.
- `metadata`: optional object. `metadata.internal === true` hides the skill from default installs (only included with `INSTALL_INTERNAL_SKILLS=1` env var or explicit `--skill` request).

Frontmatter parsing uses `parseYaml` from the `yaml` package; JS/eval-based engines are deliberately excluded for RCE safety.

The skill folder name is independent of `name` — `path: dirname(skillMdPath)` is recorded, but no equality check against `data.name` is enforced by the CLI. (However, **consuming agents may rely on folder name = skill slug**, so by convention they should match.)

### What consuming agents may enforce (partially verified)

From Perplexity's primary research + cited issues:

| Constraint | Source | Status |
|---|---|---|
| `description` max length: **1024 characters** | Codex CLI enforces this; `gstack` issue #263 cites the warning | Codex-specific; not universal |
| Claude Code validator field whitelist: `compatibility, description, license, metadata, name` | Hover tooltip in Claude Code per issue `anthropics/claude-code#25380` | Claude-Code-specific; other fields allowed but may be ignored |
| Skill names must be unique across discovery roots | OpenCode docs | Cross-cutting; enforcement is per-agent |

⚠️ **Verification gap**: an exact official Anthropic regex for `name:` (e.g. `/^[a-z][a-z0-9-]{1,49}$/`) is asserted by some secondary sources (firecrawl.dev, addyosmani/agent-skills) but was **NOT found** in any primary Anthropic doc reached by Perplexity. **Treat the kebab-case + ≤50-char convention as a soft norm, not a hard spec, until a primary Anthropic doc is checked manually.**

### Progressive disclosure (partially verified)

Perplexity references progressive disclosure (only `name` + `description` loaded at session start; body loaded on trigger) for SKILL.md-aware agents. Wider claim verified for Claude Code skills in Anthropic's engineering blog [3]; not confirmed in primary docs for OpenCode / Codex / Copilot CLI.

---

## Part C — Per-CLI native discovery paths (independent of Vercel CLI)

Where each tool **itself** looks for skills on disk:

| Tool | Global auto-scan path | Project-local auto-scan path | Primary citation |
|---|---|---|---|
| **Claude Code** | `~/.claude/skills/` (depth=1) | `.claude/skills/` (depth=1) | code.claude.com/docs/en/skills |
| **OpenCode** | `~/.config/opencode/skills/` | `.opencode/skills/` (also `.agents/skills/` via universal) | opencode.ai/docs/skills/ |
| **Codex CLI** | `~/.codex/skills/` (or `$CODEX_HOME/skills`) | `.agents/skills/` — **recursive scan** from cwd up through parents | developers.openai.com/codex/skills |
| **GitHub Copilot CLI** | `~/.copilot/skills/` (or `~/.agents/skills/`) | `.github/skills/` AND `.agents/skills/` | docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills |
| **Cursor** | `~/.cursor/skills/` | `.cursor/skills/` AND `.agents/skills/` (universal) | cursor.com/docs/skills |
| **Roo Code / Kilo / Cline ≥3.67** | `~/.agents/skills/` (also tool-specific dirs) | `.agents/skills/` | `vercel-labs/skills` PR #428 |

**Claude Code commands vs skills (per `code.claude.com/docs/en/claude-directory`):**
- `~/.claude/commands/<name>.md` — flat command file, lives in commands dir
- `~/.claude/skills/<name>/SKILL.md` — folder skill, lives in skills dir
- **Both** produce a `/<name>` slash command at the prompt
- Claude Code scans `~/.claude/skills/` **one level deep** (`<name>/SKILL.md`); deeper nesting breaks discovery
- The "commands have been merged into skills" claim from earlier subagent research **was NOT independently confirmed by the deep-research pass**. What is confirmed: both surfaces exist and both produce slash commands. Whether they're the same thing internally or two parallel mechanisms is unverified in primary docs.

⚠️ **Verification gap**: Cursor's docs page exists (`cursor.com/docs/skills`) but Perplexity did not surface the specific scan paths from it; rows above are inferred from the Vercel CLI's target config (where Cursor installs `.cursor/skills/`).

---

## What this changes in the migration plan

1. **Source layout decision: keep flat top-level `skills/<name>/SKILL.md`.** The Vercel CLI's recursive discovery means our layout is flexible, but a top-level `skills/` directory is the strongest signal of intent — and matches our actual goal (skills as the product). No need to invent something more clever.

2. **Canonical store at `~/.agents/skills/` (plain copy), with symlinks-for-fan-out where a second CLI needs the same content** — primarily `~/.claude/skills/` → `~/.agents/skills/` since Claude Code doesn't auto-scan `.agents/`. Symlink falls back to copy on Windows-without-permissions. Distinct content always copies fresh; the symlink exception applies only to redundant fan-out of identical SKILL.md sets.

3. **For project-local installs (`--commands-local`)**, default to `.agents/skills/` (universal cross-CLI). Optional per-agent flags can target `.claude/skills/`, `.opencode/skills/`, etc. for users who want only one tool's worth.

4. **VS Code project dir (`<repo>/.vscode/*.md`) and GitHub Copilot prompts (`~/.config/github-copilot/prompts/*.prompt.md`) targets become legacy.** Neither is a skills-aware path. Both can be **deprecated immediately** if we want — skills-aware paths give the same surfaces (`.github/skills/`, `~/.claude/skills/`, etc.) plus more. Alternatively keep them via a reverse `SKILL.md → flat .md` transform for one release for backward compat.

5. **Drop the `generate_copilot_cli_skills()` install-time transform** from `install/agents.sh`. With the source already in SKILL.md folder form, the installer just symlinks/copies the folder. The function's skip-list (`README.md, GETTING-STARTED.md, changes.md, codebase.md`) moves to migration-script-time concern (those files just don't migrate into the `skills/` tree).

6. **Frontmatter shape for our 27 migrating skills:**
   - `name:` field added (lowercased stem, e.g. `harness-is-the-product-v2`)
   - `description:` preserved as-is. Spot-check: longest current description in our set is ~165 chars — well under Codex's 1024-char ceiling and well under any plausible Anthropic ceiling.
   - No need for `model`, `tags`, `license` etc. on initial migration.
   - Folder name = `name:` value by convention (Vercel CLI doesn't enforce, but downstream agents may).

---

## Remaining verification gaps (do these before plan-3)

1. **Anthropic's official `name:` regex and `description:` max length** — not found in primary Anthropic docs by deep research. Either (a) accept the soft convention `/^[a-z][a-z0-9-]{1,50}$/` from secondary sources, or (b) WebFetch `code.claude.com/docs/en/skills` and `platform.claude.com/docs/en/agents-and-tools/agent-skills/overview` directly and pin the spec.
2. **Whether Claude Code "commands merged into skills" is true in May 2026** — earlier subagent claimed it; deep research did not confirm. If you're banking on slash-command parity, WebFetch the latest `code.claude.com/docs/en/claude-directory` page directly.

Both gaps are low-risk for the refactor as designed (our descriptions are short; both Claude paths work as slash commands today regardless of merge status). Worth resolving before final installer code lands.

---

## Citations

Direct source-code reads (definitive):
- `vercel-labs/skills`/`src/agents.ts` — full target config
- `vercel-labs/skills`/`src/types.ts` — full `AgentType` union, `AgentConfig` interface
- `vercel-labs/skills`/`src/skills.ts` — `parseSkillMd`, `findSkillDirs`, skip-dirs list
- `vercel-labs/skills`/`src/installer.ts` — install mode (symlink default), canonical store
- `vercel-labs/skills`/`src/install.ts` — `runInstallFromLock`, universal-only project install
- `vercel-labs/skills`/`src/frontmatter.ts` — YAML-only parser, RCE safety note
- `vercel-labs/skills`/`src/remove.ts` — lockfile-driven removal
- `vercel-labs/skills`/`src/local-lock.ts` — lockfile schema reference

Perplexity Deep Research citations (secondary):
[1] github.com/vercel-labs/skills/issues/222
[3] opencode.ai/docs/skills/
[4] cursor.com/docs/skills
[6] github.com/vercel-labs/skills
[8] code.claude.com/docs/en/skills
[11] github.com/orgs/community/discussions/183396 (GitHub Copilot CLI skills paths)
[12] github.com/anthropics/claude-code/issues/25380 (Claude Code frontmatter validator field list)
[13] github.com/garrytan/gstack/issues/263 (Codex 1024-char description limit)
[14] code.claude.com/docs/en/claude-directory
[15] github.com/vercel-labs/skills/pull/428/files (cross-tool `.agents/skills` convergence)
[19] developers.openai.com/codex/skills
[20] docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills

Pinned to commit: `main` branch of `vercel-labs/skills` as of 2026-05-13.
