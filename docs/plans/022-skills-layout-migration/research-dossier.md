# Research Report: Skills-Layout Migration (`agents/v2-commands/` → `skills/<name>/SKILL.md`)

**Generated**: 2026-05-12
**Last Updated**: 2026-05-13 (scope expanded — see § SCOPE UPDATE at top)
**Research Query**: "we need to use the correct skills layout. We are going to refactor our system to use the correct layout instead of agents / commands etc. Only migrate commands-v2 to the correct format."
**Mode**: Pre-Plan (plan-folder mode, auto-created `022-skills-layout-migration`)
**Location**: `docs/plans/022-skills-layout-migration/research-dossier.md`
**FlowSpace**: Available (local graph)
**Findings**: 24 total across 4 subagents

---

## SCOPE UPDATE (2026-05-13 — superseded; see also 2026-05-13 path correction below)

The original research framed this as a *layout migration* keeping `install/agents.sh`'s 7-target fan-out and just changing the source format. Subsequent decisions widened the scope to a **tidying refactor with categorized skill organization**:

1. **Skills live only at `skills/<category>/<slug>/SKILL.md`** at repo root. Top-level `skills/`, not `.agents/skills/` — exactly mirroring `github.com/mattpocock/skills/tree/main/skills`.
2. **Initial categories**:
   - `skills/SDD/` — 27 skills migrated from `agents/v2-commands/` (Spec-Driven Development pipeline)
   - `skills/general/` — domain-generic skills migrated from `other-skills/` (currently: `grill-me`)
   - `skills/personal/` — personal lifestyle skills migrated from `other-skills/` (currently: `shopping-hunter`)
3. **No fan-out**. No installer copies to `~/.claude/skills/`, `~/.codex/skills/`, etc.
4. **`install/agents.sh` loses its entire skill-deployment logic** (~700–800 of its 1078 lines): the 7-target install loop, `--commands-local`, `generate_copilot_cli_skills()`, plan-file cleanup. MCP config deployment stays.
5. **`agents/commands/` (v1, 27 files) and `agents/commands-lite/` (12 files) are deprecated.** Only `agents/v2-commands/` is promoted to skills. The legacy dirs get deprecation markers but are not deleted in this plan.
6. **`src/jk_tools/cli.py`'s `--commands-local` feature goes away.** `setup_manager.py` loses its agent-install code path.
7. **Distribution model**: users run `npx skills@latest add jakkaj/tools -a <their-cli>` themselves (Vercel CLI flattens category dirs on install). In-repo native auto-discovery is NOT supported — no CLI scans top-level `skills/` natively (Codex/Copilot/OpenCode/Cursor scan `.agents/skills/`, Claude Code scans `.claude/skills/`). This trade-off is accepted because the repo is a publish source, not a local skill provider.

**Category-level nuance**: category subdirs are for human browsing of the source repo. `npx skills` install flattens them — each skill installs to `<target_dir>/<slug>/SKILL.md` regardless of category. The `name:` frontmatter value matches the **leaf** folder name, not a category path.

Sections below were written assuming the old fan-out installer. Where they conflict with the scope above, the scope above wins. The verified Vercel CLI facts in `external-research/cli-paths-verification.md` remain accurate; their *implications for our installer* are now mostly N/A.

---

## Executive Summary

### What This Is
Refactor the canonical source layout of our 31 v2 agent skills from **flat files** at `agents/v2-commands/*.md` to **folder-per-skill** at `skills/<name>/SKILL.md` — aligning with the now-converged Anthropic / Vercel-Labs / Claude Code skills spec.

### Business Purpose
- Get our skills consumed by `npx skills@latest add jakkaj/tools` (Vercel CLI ecosystem) and Claude Code's native `~/.claude/skills/` autoloader — no transformation step.
- Stop carrying our own `flat → SKILL.md` Python transform inside the installer (the `generate_copilot_cli_skills()` function); the spec **is** what we ship.
- Unblock multi-file skills (per-skill `scripts/`, `references/`, `assets/`) — currently impossible with a flat layout.

### Key Insights
1. **Our installer already does the target transformation, just at the wrong layer.** `install/agents.sh` line 201 has `generate_copilot_cli_skills()` — a Python heredoc that turns each `agents/v2-commands/*.md` into `<dest>/<name>/SKILL.md` for Copilot CLI. Hoisting this transform to **source-time** is the whole refactor. ([IA-01, IA-04])
2. **2026 has converged on one format.** Claude Code, OpenCode, Codex, Copilot CLI, and Copilot IDE all natively read `skills/<name>/SKILL.md` with `name` + `description` frontmatter. Claude Code merged `commands/` and `skills/` semantics — `.claude/commands/foo.md` and `.claude/skills/foo/SKILL.md` both yield `/foo`. ([IC-01])
3. **Scope is narrow.** Only `agents/v2-commands/` (31 files) migrates. `agents/commands/` (27, v1 full pipeline), `agents/commands-lite/` (12, lite pipeline), `agents/mcp/`, and `agents/settings.local.json` stay untouched per user instruction. ([DC-01])
4. **No agent harness in this repo yet.** `setup.sh` + `justfile` provide the engineering harness substrate (boot present, OK). But `docs/project-rules/agent-harness.md` does not exist — agent harness for *this repo* is a Workshop Opportunity, not blocking. ([Harness check, Part 2])
5. **Backward compatibility has a sharp edge.** Existing user installs at `~/.claude/commands/*.md`, `~/.config/opencode/command/*.md`, `~/.codex/prompts/*.md`, `~/.config/github-copilot/prompts/*.prompt.md` will become orphans if we redirect targets to `~/.claude/skills/` etc. Prune logic exists for `plan-*.md` patterns; needs generalisation. ([DC-04])

### Quick Stats
- **Source files**: 31 in `agents/v2-commands/`; 27 installable after skip-list (`README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`)
- **Install targets today**: 7 (Claude global+local, OpenCode global+local, Codex global, Copilot prompts global, Copilot CLI skills global+local, VS Code project)
- **Code touching `v2-commands` path**: 5 files, 20 references (excluding auto-sync `src/jk_tools/` mirror and historical `docs/plans/`)
- **Tests**: 2 (`tests/install/test_agents_copilot_dirs.sh`, `test_complete_flow.sh`) — must update
- **Frontmatter today**: 1 field (`description:`); migration adds `name:` (derived from stem)
- **Domains**: N/A (this repo has no `docs/domains/` registry)
- **Prior learnings**: 3 directly relevant (plans 007, 018, 020 — see below)

---

## How It Currently Works

### The 7-Target Install Matrix

| # | Target | Install Path (global) | Format | Conversion |
|---|---|---|---|---|
| 1 | Claude Code | `~/.claude/commands/` | flat `.md` (copy) | none |
| 2 | OpenCode | `~/.config/opencode/command/` | flat `.md` (copy) | none |
| 3 | Codex CLI | `~/.codex/prompts/` | flat `.md` (copy) | none |
| 4 | VS Code project | `<repo>/.vscode/` | flat `.md` (copy) | none |
| 5 | GitHub Copilot (IDE) | `~/.config/github-copilot/prompts/` | flat `.prompt.md` (rename) | `.md`→`.prompt.md` |
| 6 | Copilot CLI (XDG) | `$XDG_CONFIG_HOME/.copilot/skills/` | `<name>/SKILL.md` | **`generate_copilot_cli_skills()`** ← the precedent |
| 7 | Copilot CLI (default) | `~/.copilot/skills/` | `<name>/SKILL.md` | same |

Local mode (`--commands-local`) supports Claude, OpenCode, Copilot prompts, Copilot CLI. **Codex local is unsupported** (upstream issue #4734).

### The Precedent — `generate_copilot_cli_skills()` (install/agents.sh:201–246)

A Python heredoc that:
1. Globs `<source>/*.md`, skips 4 meta files (`README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`)
2. Stems → lowercase, spaces → `-` → skill `name`
3. Parses YAML frontmatter, extracts `description:` (default `"Command: {name}"`)
4. Writes `<dest>/<name>/SKILL.md` with `name:` + `description:` frontmatter + body

This is exactly the Anthropic SKILL.md format. **If the *source* is already in this layout, this function disappears.**

### Hardcoded References to `v2-commands`

| File | Hits | Role |
|---|---|---|
| `install/agents.sh` | 9 | Path constant + install loops + cleanup + skills generator invocations |
| `setup_manager.py` | 3 | Python fallback installer (Windows) + path validation |
| `scripts/sync-to-dist.sh` | 6 | rsync source → `src/jk_tools/agents/v2-commands/` |
| `tests/install/test_complete_flow.sh` | 1 | Test fixture path |
| `tests/install/test_agents_copilot_dirs.sh` | 1 | Test source glob |
| `agents/v2-commands/plan-0-v2-constitution.md` | 1 | Self-reference (low-priority doc text) |

`src/jk_tools/agents/v2-commands/` is the auto-synced mirror — those references mirror the above and will update automatically when `sync-to-dist.sh` is fixed.

---

## Target Spec (Anthropic Skills + Vercel CLI)

### SKILL.md frontmatter

| Field | Required? | Constraint |
|---|---|---|
| `name` | required | `/^[a-z][a-z0-9-]{1,49}$/` (lowercase kebab, max 50 chars) — must match folder name |
| `description` | required | 1–2 sentence trigger; max ~200 tokens / ~800 chars. **Only this field is loaded at startup** — progressive disclosure |
| `model` | optional | model hint string/list |
| `tags` | optional | max 10, each <30 chars |
| `version` | optional | semver |
| `license` | optional | SPDX string |
| `allowed-tools` | optional | array of tool names |
| `icon` | optional | emoji or SVG path |

Today our 27 installable v2-commands all have `description:` only. **Lengths look fine** — sampled descriptions are under 200 chars. `name:` will be added during migration (derived from stem).

### Folder layout

```
skills/<skill-name>/
├── SKILL.md           # required (~5,000 token recommended cap)
├── scripts/           # optional helpers
├── references/        # optional deep-dive docs (loaded on demand)
└── assets/            # optional templates, schemas
```

### Discovery precedence (Claude Code, native)

1. `./.claude/skills/` (project)
2. `~/.claude/skills/` (user)
3. plugin/marketplace bundled

At session start Claude loads only `name + description` per skill (~30–50 tokens). Body + supporting files load only when the description matches a task.

### Vercel `skills` CLI

- Expects source repo to have a top-level `skills/` directory containing `skills/<name>/SKILL.md` folders
- `npx skills@latest add jakkaj/tools` clones repo, walks `skills/*/SKILL.md`, copies (not symlinks) to chosen target's skill dir
- Multi-target via `-a claude-code`, `-a opencode`, `-a codex`, `-a cursor`, `-a aider`
- `skills update` is diff-aware and **prunes orphans** in the install target

**⚠️ Verification gap**: agent C's report on exact Vercel install paths conflicts with agent B's report on per-CLI conventions (e.g., Codex target `~/.codex/skills/` vs `~/.agents/skills/`). Before writing the installer, **probe `npx skills@latest --help` and read `vercel-labs/skills/src/targets/` directly**. Some of the "2026 official" paths claimed by subagent B (e.g., Codex `~/.agents/skills/`, OpenCode `~/.config/opencode/skills/`) cite sources that should be verified at implementation time. Treat the matrix above as design-direction, not contract.

---

## Architecture & Design (Post-Migration)

### Source layout (DECIDED 2026-05-13)

Canonical source-of-truth: **`.agents/skills/<slug>/SKILL.md`** at repo root. Follows the cross-CLI community convention used by Vercel `npx skills`'s `universal` target and auto-scanned by Copilot CLI / Codex / OpenCode / Cursor / Gemini CLI / Cline / Warp.

```
.agents/skills/                             # canonical (community convention)
├── plan-0-v2-constitution/
│   └── SKILL.md
├── plan-1a-v2-explore/
│   └── SKILL.md
├── harness-is-the-product-v2/
│   └── SKILL.md
... (27 skills)
```

Skip-list files (`README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md`) do not migrate — they're docs, not skills. They stay at their current locations or move into `docs/`.

**Claude Code is the asymmetric case**: it does not auto-scan `.agents/skills/` — only `.claude/skills/` and `~/.claude/skills/`. Our `./setup.sh` installer must additionally copy the same skill set into `~/.claude/skills/` for Claude-Code-first users. Other CLIs find the in-repo `.agents/skills/` directly via their native scan paths.

### Distribution flow (post-migration — scope-updated 2026-05-13)

```
.agents/skills/<slug>/SKILL.md              # canonical source — repo only

# That's it. No installer step. No fan-out. Distribution paths:

Path 1 (user pulls):  npx skills@latest add jakkaj/tools -a <their-cli> [-g]
                      → Vercel CLI clones repo, discovers SKILL.md, installs to
                        whichever target the user picks.

Path 2 (user clones): User works inside a checkout of jakkaj/tools.
                      .agents/skills/ is auto-discovered by Codex, GitHub Copilot CLI,
                      OpenCode, Cursor, Gemini CLI, Cline, Warp (their native scan paths).
                      Claude Code requires manual config or path 1.
```

`install/agents.sh` no longer touches skills. `generate_copilot_cli_skills()` is deleted. The `src/jk_tools/agents/v2-commands/` distribution mirror is removed from sync.

### Two open architectural questions

**Q1: Keep flat-`.md` deploys for non-skill-aware targets?**
Some installs today (VS Code project `.vscode/*.md`, Copilot IDE prompts as `.prompt.md`) might *not* be skills-aware yet. Two options:
- (A) **Drop those targets** — only deploy where SKILL.md is native. Lose the slash-command surface in VS Code and the paperclip prompts in Copilot IDE.
- (B) **Keep them, derive flat .md at install time** — Reverse of today: synthesize `<name>.md` from `skills/<name>/SKILL.md` for legacy consumers. Easy (concat frontmatter→description block + body) but keeps installer complexity.

Recommend (B) for backward compatibility until adoption is universal. The transform is one-way and trivial.

**Q2: Drop the `-v2` suffix?**
Most v2 skills carry `-v2` in their name (e.g., `plan-1a-v2-explore`). Once flat v1 commands (`agents/commands/`) coexist with folder skills (`skills/`), the path itself disambiguates — `-v2` becomes redundant noise. But renaming `plan-1a-v2-explore` → `plan-1a-explore` breaks every existing user's `/plan-1a-v2-explore` invocation and every cross-skill reference in our prompts.
- **Cheap path**: keep `-v2` in skill names. Cosmetic only.
- **Right path**: rename + deprecation stubs (per Anthropic's `addyosmani/agent-skills` precedent) — skills CLI marketplace browses by slug, so `plan-1a-explore` is a cleaner public face.

Open. Defer until plan-1b.

---

## Modification Considerations

### ✅ Safe to Modify
- `agents/v2-commands/*.md` content — files are about to move anyway
- `scripts/sync-to-dist.sh` — clear sync logic, well-tested
- `tests/install/*` — purpose-built for installer regression

### ⚠️ Modify with Caution
- `install/agents.sh` (1078 lines) — orchestrates 7 install targets with idempotency + cleanup + local mode. Mistakes silently propagate to user machines on next `setup.sh`. **Risk**: an installer that prunes wrong paths could delete user-customized files. Mitigation: dry-run mode + test against test_complete_flow.sh before merging.
- `generate_copilot_cli_skills()` — likely deleted, but **only after every target reads SKILL.md natively**. If even one target still needs the transform, keep it as a fallback.

### 🚫 Danger Zones
- **Orphan file deletion in `~/`** — if we add a "prune flat .md on migration" pass, getting the pattern wrong wipes user files in `~/.claude/commands/`. Two safeguards: (1) prune **only** filenames that are in our skip-list-aware source manifest; (2) require explicit `--prune-legacy` flag rather than running on every `setup.sh`.
- **Rename collisions** if Q2 (drop `-v2`) is chosen — two skills with the same target slug.

### Extension Points
- The folder layout enables `references/` and `scripts/` per skill. Future cleanup: `plan-6-v2-implement-phase` is huge; could be split into `SKILL.md` + `references/companion-mode.md` + `references/retro-format.md`. **Not in scope for this migration** — but the new layout unlocks it.

---

## Prior Learnings (From Previous Implementations)

Three prior plans in `docs/plans/` did related work. **Read these before designing the migration.**

### 📚 PL-01: Plan 018 — Copilot CLI Skills for Local Install (2026-04-06)
**Source**: `docs/plans/018-copilot-cli-skills-local/`
**Type**: precedent / workaround

**What they did**: Switched local Copilot CLI from flat `.agent.md` files to `<name>/SKILL.md` folder format. Implemented `generate_copilot_cli_skills()` (the function we'd hoist). Decided on skip-list (4 files). Decided to *strip* unused frontmatter fields like `tools:`.

**Why this matters now**: This *is* our migration, just for one target. The same per-skill decisions (skip-list, skill-name derivation, frontmatter shape, cleanup of old `.agent.md` orphans) apply. **Read the plan in full** — it likely contains decisions we'd rediscover.

**Action for current work**: Reuse the skill-name derivation rule (lowercase stem, spaces→`-`). Reuse the 4-file skip-list. The Plan 018 cleanup-of-orphans approach (`cleanup_copilot_cli_agents()`) is the model for our cross-target orphan strategy.

### 📚 PL-02: Plan 007 — Copilot CLI Support (2026-01-16)
**Type**: integration precedent

**What they did**: Added Copilot CLI as a new install target. Pattern: edit `agents/mcp/servers.json` once, installer cascades to all CLIs.

**Why this matters now**: Same pattern applies here — edit source once, installer cascades to 5–7 targets. Idempotency and re-runnability are non-negotiable.

### 📚 PL-03: Plan 020 — V2 Command Cross-Pollination (2026-04-12)
**Type**: scope clarification

**What they did**: Decided which v2 commands belong in v1 too. Workshop-only plan, no implementation merged.

**Why this matters now**: Confirms `commands/`, `commands-lite/`, `v2-commands/` are distinct surfaces with intentional duplication in places. **Don't try to unify them as part of this migration.** Stay scoped to v2-commands → skills.

---

## Domain Context

This repo (`tools/`) has no `docs/domains/registry.md`. No domain system to update. The migration is single-domain (developer-tooling infrastructure) and doesn't touch business domains.

**Suggestion (optional follow-up)**: After migration, consider extracting two domains — **`skills-distribution`** (sync + 7-target installer + prune) and **`skills-authoring`** (SKILL.md format conventions + skip-list). They are separately evolvable and currently tangled inside `install/agents.sh`. Defer to a future plan.

---

## Critical Discoveries

### 🚨 Critical Finding 01: The transform already exists, just at the wrong layer
**Source**: IA-04 (`install/agents.sh:201–246`)
**What**: `generate_copilot_cli_skills()` is a working flat→SKILL.md transform. Today it runs at *install* time for one of seven targets. The refactor moves it to *authoring* time and applies to all targets.
**Required Action**: Hoist the transform. The function disappears from `install/agents.sh`. The skill name derivation, frontmatter rewrite, and skip-list become *one-shot* operations performed by a migration script that runs once on the existing 31 files. The installer then just copies.

### 🚨 Critical Finding 02: User-CLI path consensus is incomplete
**Source**: IC-02, IC-03 conflict
**What**: Subagent B (per-CLI compatibility, citing 2026 docs) and subagent C (Vercel CLI + Anthropic spec) disagree on three install paths:
- OpenCode global: `~/.config/opencode/skills/` (B) vs `~/.opencode/skills/` (C, Vercel)
- Codex global: `~/.agents/skills/` (B) vs `~/.codex/skills/` (C, Vercel)
- Copilot CLI global: `~/.copilot/skills/` (both) — but XDG-aware fallback unclear

**Required Action**: Before plan-3 finalises the install matrix, **run `npx skills@latest --help` and read `vercel-labs/skills/src/targets/` directly**, plus the latest each-CLI official docs. Treat conflicting claims as untrusted. List exact verified paths as a finalised contract before installer changes.

### 🚨 Critical Finding 03: Orphan strategy needs explicit scope
**Source**: DC-04, DC-07
**What**: Today's installer can deploy `<n>.md` to `~/.claude/commands/`. After migration, those files become orphans on every existing user machine — not deleted by the installer. The orphan rename we did in commits `9019f63` (the harness rename) already proved this: 4 files we removed needed manual `rm`.

**Required Action**: Add a **single, opt-in `--prune-legacy` pass** to `setup.sh` (or a one-time migration script) that:
- Reads the *current* installable manifest (31 stems from `skills/`)
- For each of the 5 flat-`.md` targets, removes files whose stem isn't in the manifest **and** matches our previous shipping pattern
- Logs everything it would delete; require `--apply` to actually delete
- Run-once or guarded by a marker file so it doesn't keep nuking user-authored content

---

## Recommendations

### If Modifying This System
1. Verify external paths before writing installer code (Critical Finding 02).
2. Run the migration in two phases, not one big-bang. **Phase A**: add `skills/` directory and `SKILL.md` files alongside the existing flat `agents/v2-commands/*.md`; teach installer to prefer `skills/` if present. **Phase B**: delete the legacy flat files. This makes every intermediate commit shippable.
3. Reuse `generate_copilot_cli_skills()`'s Python logic as a one-shot migration script for Phase A (run it once, commit the output, delete the function).
4. Keep `commands/`, `commands-lite/`, `mcp/`, `settings.local.json` untouched (user-stated scope).

### If Extending This System
1. Once on SKILL.md folders, large skills (e.g., `plan-6-v2-implement-phase.md`) can split body across `SKILL.md` + `references/`. Defer; do not pre-split.
2. Per-skill `allowed-tools`: useful candidate after migration — currently every skill implicitly has all tools.

### If Refactoring This System
1. After migration, extract the installer into smaller responsibilities (1078 LOC bash is past humane). Two domains hinted above. Defer.

---

## External Research Opportunities

### Research Opportunity 1: Verify Vercel `skills` CLI target paths and Anthropic SKILL.md frontmatter limits

**Why Needed**: Subagent B (per-CLI) and subagent C (spec) conflict on exact install paths for OpenCode/Codex and on description length cap (200 tokens vs 1024 chars). The migration's correctness hinges on matching official targets exactly.

**Impact on Plan**: Without confirmation we either fail to install or install to wrong dirs that look superficially correct.

**Source Findings**: IC-02, IC-03

**Ready-to-use prompt**:
```
/deepresearch "For each of these CLIs, give the EXACT install path used by `npx skills@latest add <repo>` in May 2026: Claude Code, OpenCode, Codex, Cursor, Aider, GitHub Copilot CLI, GitHub Copilot IDE. Verify by reading the source of github.com/vercel-labs/skills (src/targets/*.ts or equivalent) and the latest official docs for each CLI. Also confirm: (1) SKILL.md frontmatter 'description' max length — tokens or characters? cite Anthropic spec; (2) Whether Claude Code's discovery walks nested .claude/skills/ in monorepos; (3) Whether the Vercel skills CLI requires a top-level 'skills/' dir in the source repo, or if it accepts other paths. Return a single table per CLI with citations."
```

**Results location**: `docs/plans/022-skills-layout-migration/external-research/cli-paths-verification.md`

---

## Agent Harness Status

- **Engineering harness substrate (Part 1)**: ✅ Present — `setup.sh` + `justfile` at repo root. `./setup.sh` is a runnable boot command. No P0 blocker.
- **Agent harness governance (Part 2)**: ❌ No `docs/project-rules/agent-harness.md` (or legacy `harness.md`) in this repo. Agents working in this repo cannot autonomously Boot/Interact/Observe — they rely on humans.

**Workshop Opportunity**: Run `/agent-harness-v2 --create` against this repo to formalise the agent harness on top of the existing `setup.sh` substrate. **Not blocking** for the skills migration — but the migration itself touches `setup.sh` and would benefit from agent-validated install runs. Suggest scheduling after migration unless the user wants it as Phase 0.

---

## Appendix: File Inventory

### Core files this plan modifies

| File | Purpose | LOC | Modification |
|---|---|---|---|
| `install/agents.sh` | 7-target installer | 1078 | rewrite source glob, drop `generate_copilot_cli_skills()`, generalise prune |
| `setup_manager.py` | Python orchestrator + Windows fallback | 717 | update paths, glob `skills/*/SKILL.md` |
| `scripts/sync-to-dist.sh` | source → `src/jk_tools/` mirror | 135 | rsync `skills/` recursively |
| `tests/install/test_complete_flow.sh` | e2e installer test | ~150 | update fixture |
| `tests/install/test_agents_copilot_dirs.sh` | Copilot CLI structure test | 194 | update source glob, expand to all targets |
| `CLAUDE.md` (root) | dev docs | — | update "Source of Truth" + "Adding New Commands" sections |
| `AGENTS.md` (root) | public docs | — | mirror CLAUDE.md edits |
| `setup.sh` (root) | entry | 162 | minor — wire new paths |

### Stays put (per user scope)
- `agents/commands/*.md` (27 files) — v1 full pipeline
- `agents/commands-lite/*.md` (12 files) — lite pipeline
- `agents/mcp/servers.json` — MCP definitions
- `agents/settings.local.json` — agent settings

### New on disk after migration
- `skills/<name>/SKILL.md` × 27 (post-skip-list) — canonical source
- `src/jk_tools/skills/` — auto-synced mirror
- Optional: `skills/_deprecated/<old-slug>/SKILL.md` redirect stubs (if Q2 rename happens)

---

## Next Steps

**STOP. This is a research-only command.**

The research is complete. Recommended next actions for the user (in priority order):

1. **Resolve external research opportunity** (Critical Finding 02): Run the `/deepresearch` prompt above and save results to `docs/plans/022-skills-layout-migration/external-research/cli-paths-verification.md`. **Required before implementation** — installer paths must be canonical.
2. **Decide the two open questions** from `## Architecture & Design`:
   - Q1: Keep flat-`.md` deploys for legacy targets via reverse transform? (Suggest: yes, for one release.)
   - Q2: Drop the `-v2` suffix on rename? (Suggest: defer to plan-1b decision.)
3. **Run `/plan-1b-v2-specify "skills-layout migration"`** to produce the feature spec from this research.
4. **Optional but recommended**: Run `/plan-2c-v2-workshop 022-skills-layout-migration "SKILL.md frontmatter and naming"` — the rename + frontmatter shape question is exactly the kind of multi-decision design that benefits from a workshop document.

Per command contract: I am stopping here. No further commands executed, no code changes made.

---

**Research Complete**: 2026-05-12
**Report Location**: `docs/plans/022-skills-layout-migration/research-dossier.md`
