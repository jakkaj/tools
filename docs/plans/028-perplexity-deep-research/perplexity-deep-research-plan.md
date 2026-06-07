# perplexity-deep-research Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-06-07
**Spec**: [perplexity-deep-research-spec.md](./perplexity-deep-research-spec.md)
**Status**: READY

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS | No `[NEEDS CLARIFICATION]` markers remain |
| G2 | Constitution | N/A | No `docs/project-rules/constitution.md` |
| G3 | Architecture | N/A | No `docs/project-rules/architecture.md` |
| G4 | ADR Compliance | N/A | `docs/adr/` holds only README (no accepted ADRs) |
| G5 | Structure | PASS | All required sections present |
| G6 | Testing Alignment | PASS | Lightweight: T003 is the validation task; ACs are measurable |
| G7 | Domain Completeness | PASS | No formal domain registry; skill folder is the self-contained unit, all files in manifest |

## Summary

Build a `perplexity-deep-research` skill plus a tiny bundled Python CLI (`pplx_research.py`, stdlib only) that POSTs directly to `https://api.perplexity.ai/chat/completions` with a long client-side timeout, so `sonar-deep-research` jobs complete instead of dying at the perplexity MCP's ~5-minute cap. The CLI lives inside the skill folder so `npx skills add` ships it with `SKILL.md`. Single build phase; Lightweight testing against the real API.

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| skills catalog (`skills/general/`) | existing | modify | Add `perplexity-deep-research/` skill folder (SKILL.md + bundled CLI) |

No `docs/domains/` registry exists in this repo; the skill folder is the self-contained unit of change.

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `skills/general/perplexity-deep-research/SKILL.md` | skills catalog | internal | Skill definition (frontmatter + body) |
| `skills/general/perplexity-deep-research/pplx_research.py` | skills catalog | internal | Bundled CLI the skill shells out to |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Endpoint `https://api.perplexity.ai/chat/completions` works with `$PERPLEXITY_API_KEY` (Bearer); response answer at `choices[0].message.content`, sources at `citations[]` | CLI targets this exact shape |
| 02 | Critical | `sonar-deep-research` is the slow model that exceeds the MCP 5-min cap; direct HTTP with a long timeout is the fix | Default model `sonar-deep-research`, default `--timeout 1800` |
| 03 | High | `sonar-reasoning` is **deprecated** (HTTP 400); `sonar`/`sonar-pro`/`sonar-deep-research` are live | Don't reference deprecated models; `--model` flag lets callers override |
| 04 | High | Skills bundle resources that travel with `npx skills add` (e.g. `harness-3-retro` ships a schema) | Put CLI inside the skill folder, not in repo `scripts/` |
| 05 | Med | Smoke-testing the deep model costs money + minutes | Smoke tests use cheap `sonar`; deep model exercised only on real use |

## Implementation

**Objective**: Ship a working prototype skill + CLI that runs long Perplexity research calls directly via HTTP.
**Testing Approach**: Lightweight — smoke checks against the real API (Mock policy: real-only, no mocks).

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Write the CLI: argparse (`prompt` positional; `--model` default `sonar-deep-research`; `--timeout` default `1800`; `--system`, `--recency`, `--json` optional), read `$PERPLEXITY_API_KEY`, POST via `urllib.request`, print `content` then a `Citations:` list. Missing key → stderr message + exit 2 (no traceback). | skills catalog | `skills/general/perplexity-deep-research/pplx_research.py` | `--help` exits 0; stdlib-only (no pip imports) | AC-1,3,4,6 · per finding 01,02 |
| [x] | T002 | Write `SKILL.md`: frontmatter `name: perplexity-deep-research` + triggering `description`; body documents the CLI invocation, model choices, the long-timeout rationale, and **when to prefer the CLI over the perplexity MCP** (long/deep calls) vs MCP (quick asks). | skills catalog | `skills/general/perplexity-deep-research/SKILL.md` | Valid frontmatter; `name` matches folder; body shows a copy-paste command | AC-5 · per finding 03,04 |
| [x] | T003 | Smoke-validate: (a) `python3 pplx_research.py --help` → exit 0; (b) real `--model sonar "<short q>"` → non-empty answer + ≥1 citation, exit 0; (c) `env -u PERPLEXITY_API_KEY python3 pplx_research.py x` → clear error, exit 2. Capture output in execution log. | skills catalog | (run only) | All three checks pass; evidence logged | AC-1,2,3 · cheap `sonar` model |
| [x] | T004 | Dogfood install + slug check: `scripts/check-skill-slugs.sh` (no collision) then `just install-skills-from-source`; confirm skill + CLI land in `~/.agents/skills/perplexity-deep-research/`. | skills catalog | (install) | slug check exits 0; installed folder contains both files | AC-6 · CLAUDE.md install flow |

### Acceptance Criteria

- [ ] AC-1: `pplx_research.py --help` prints usage, exits 0.
- [ ] AC-2: CLI with `--model sonar` returns answer text + citation URLs, exit 0.
- [ ] AC-3: Key unset → clear error, non-zero exit, no traceback.
- [ ] AC-4: `--model sonar-deep-research` with `--timeout > 300` does not abort at 5 min.
- [ ] AC-5: `SKILL.md` frontmatter valid, `name` matches folder, description triggers on deep-research, documents CLI + MCP-vs-CLI guidance.
- [ ] AC-6: CLI bundled in skill folder; installs via `npx skills add` / `just install-skills-from-source`.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| API shape/model names drift | Low | Med | Verified live today; `--model` overridable |
| Long call hangs indefinitely | Low | Low | Bounded `--timeout` (default 1800s), not infinite |
| Key missing at runtime | Med | Low | T001/AC-3: clean error + exit 2 |
| `sonar-deep-research` cost | Med | Low | Smoke tests use `sonar`; deep model only on real use |
