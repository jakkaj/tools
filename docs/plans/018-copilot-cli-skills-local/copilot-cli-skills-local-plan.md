# Copilot CLI Skills for Local Install — Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-04-06
**Spec**: docs/plans/018-copilot-cli-skills-local/copilot-cli-skills-local-spec.md
**Status**: COMPLETE
**Complexity**: CS-2 (small) — S=1, I=0, D=0, N=0, F=0, T=1

## Summary

Local `--commands-local copilot-cli` installs currently create `.github/agents/*.agent.md` files, which only surface via Copilot CLI's `/agent` picker menu — not as direct `/slash-commands`. This plan switches the local format to `.github/skills/<name>/SKILL.md` (directory-per-skill layout), which Copilot CLI auto-discovers as direct `/skill-name` slash commands.

Follow-up: Copilot CLI 1.0.36 also requires the same skills format for reliable global discovery, so global setup now installs personal skills to `~/.copilot/skills/<name>/SKILL.md` and cleans up old generated `~/.copilot/agents/*.agent.md` files.

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| installer | existing | modify | Rewrite copilot-cli local install block in `agents.sh` |
| documentation | existing | modify | Update AGENTS.md local path table and notes |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `/Users/jordanknight/github/tools/install/agents.sh` | installer | internal | Core install logic — copilot-cli local block (lines 662-699, 733-735) |
| `/Users/jordanknight/github/tools/AGENTS.md` | documentation | contract | Public docs — local path table (line 170), Copilot CLI notes (lines 216-219) |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Local `.agent.md` files don't get slash-command promotion — only `/agent` menu | Switch to skills format |
| 02 | High | Skills require `SKILL.md` inside a named subdirectory, not flat files | Embedded Python must `mkdir -p` per skill |
| 03 | Medium | Skills frontmatter needs `name` + `description` but NOT `tools: ["*"]` | Drop `tools` field from frontmatter |
| 04 | Low | Old `.github/agents/plan-*.agent.md` files may linger from previous installs | Add cleanup step |

## Implementation

**Objective**: Switch `--commands-local copilot-cli` output from `.github/agents/*.agent.md` to `.github/skills/<name>/SKILL.md` for direct slash-command invocation.
**Testing Approach**: Manual verification — run installer, confirm `.github/skills/` structure created with correct frontmatter.

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Rewrite copilot-cli local install block: change target dir from `.github/agents` to `.github/skills`, rewrite embedded Python to create `<stem>/SKILL.md` per command | installer | `/Users/jordanknight/github/tools/install/agents.sh:662-699` | `.github/skills/<name>/SKILL.md` created for each v2-command; frontmatter has `name` + `description` (no `tools`); body matches source | Per findings 01, 02, 03 |
| [x] | T002 | Update cleanup logic: change from `plan-[0-9]*.agent.md` pattern to removing `plan-[0-9]*/` skill directories; also clean old `.github/agents/plan-*.agent.md` for migration | installer | `/Users/jordanknight/github/tools/install/agents.sh:666` | Old plan-* skill dirs cleaned before re-install; old agent.md files cleaned on migration | Per finding 04 |
| [x] | T003 | Update summary output: change count/path display from `.github/agents/ (N .agent.md files)` to `.github/skills/ (N skills)` | installer | `/Users/jordanknight/github/tools/install/agents.sh:698-699, 733-735` | Summary shows correct skills count and path | |
| [x] | T004 | Update AGENTS.md: local path table row for Copilot CLI, and Copilot CLI Notes section | documentation | `/Users/jordanknight/github/tools/AGENTS.md:170, 214-219` | Docs reflect `.github/skills/<name>/SKILL.md` format and `/skill-name` invocation | |

### Acceptance Criteria

- [ ] `jk-tools-setup --commands-local copilot-cli` creates `.github/skills/<name>/SKILL.md` for each v2-command
- [ ] Each `SKILL.md` has YAML frontmatter with `name` (lowercase, hyphenated) and `description` (non-empty)
- [ ] Each `SKILL.md` body contains full markdown content (original frontmatter stripped)
- [ ] `README.md`, `GETTING-STARTED.md`, `changes.md`, `codebase.md` excluded from skill generation
- [ ] Re-running the command cleanly overwrites existing skills (idempotent)
- [ ] Combined targets work: `--commands-local claude,opencode,ghcp,copilot-cli`
- [ ] Old `.github/agents/plan-*.agent.md` cleaned up during install
- [ ] AGENTS.md reflects new `.github/skills/` path for local Copilot CLI
- [ ] Global install uses `~/.copilot/skills/<name>/SKILL.md`

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Copilot CLI skills format changes in future preview updates | Low | Medium | Keep transform logic isolated in single Python block for easy update |
| Older Copilot CLI versions may not support skills | Low | Low | Document minimum version; agents still work via `/agent` fallback |
