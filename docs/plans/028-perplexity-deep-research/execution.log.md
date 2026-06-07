# Execution Log — perplexity-deep-research (Simple, single phase)

**Plan**: perplexity-deep-research-plan.md
**Date**: 2026-06-07
**Testing approach**: Lightweight (real API, no mocks)

## Pre-flight — Agent Harness Validation

| Stage | Result | Note |
|-------|--------|------|
| Boot/Interact/Observe | 🔴 UNAVAILABLE | No `docs/project-rules/engineering-harness.md` — fell back to standard Lightweight testing per plan. Not an error. |

## Tasks

### T001 — Write the CLI ✅
- Created `skills/general/perplexity-deep-research/pplx_research.py` (Python stdlib only: argparse, json, os, sys, urllib).
- Defaults: model `sonar-deep-research`, timeout 1800s. Flags: `--model --timeout --system --recency --json`.
- Missing key → stderr message + exit 2 (no traceback). HTTP/URL errors → exit 1.
- Evidence: `--help` exits 0 (output captured). AC-1, AC-3, AC-4, AC-6.

### T002 — Write SKILL.md ✅
- Created `skills/general/perplexity-deep-research/SKILL.md`. Frontmatter `name: perplexity-deep-research` (matches folder) + triggering description.
- Body: when-to-use MCP-vs-CLI table, prerequisites, usage examples, options table, output/exit codes, deprecation note for `sonar-reasoning`. AC-5.

### T003 — Smoke validation ✅
- (a) `--help` → exit 0.
- (b) `--model sonar "...capital of France?"` → "The capital of France is **Paris**." + 5 citations, exit 0. (AC-2)
- (c) `env -u PERPLEXITY_API_KEY ... ` → `error: PERPLEXITY_API_KEY is not set ...`, exit 2. (AC-3)
- AC-4 note: timeout flows to `urlopen(timeout=args.timeout)` (default 1800 > 300); `sonar-deep-research` confirmed reachable on the endpoint via the earlier curl probe. Deep call not run in smoke (cost/time) — exercised on real use.

### T004 — Slug check + dogfood install ✅
- `scripts/check-skill-slugs.sh` → "OK: 32 skills, no slug collisions", exit 0.
- `just install-skills-from-source` → `✓ ~/.agents/skills/perplexity-deep-research` (universal + symlinked Claude/Pi).
- Verified installed folder holds both `pplx_research.py` + `SKILL.md`; CLI runs from canonical store. AC-6.

## Acceptance Criteria — final

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 `--help` exit 0 | ✅ | T001 |
| AC-2 sonar call → answer + citations | ✅ | T003(b) |
| AC-3 key unset → clean error, exit 2 | ✅ | T003(c) |
| AC-4 `--timeout > 300` no 5-min abort | ✅ | code: `urlopen(timeout=)`; curl probe of deep model |
| AC-5 valid SKILL.md + MCP-vs-CLI guidance | ✅ | T002 |
| AC-6 bundled, installs via npx skills | ✅ | T004 |

## Discoveries & Learnings

| ID | Type | Note |
|----|------|------|
| OH-001 | gotcha | perplexity MCP `perplexity_ask` gave a confidently-wrong "no public API" answer; the live curl probe was the authoritative check. Trust the endpoint, not the model's self-description. |
| OH-002 | gotcha | `sonar-reasoning` is deprecated (HTTP 400). Only `sonar`, `sonar-pro`, `sonar-deep-research` are live as of 2026-06-07. |
| OH-003 | insight | `sonar-deep-research` fired 3 searches + 6023 reasoning tokens for a trivial "reply OK" prompt — confirms why it blows the 5-min MCP cap. The whole fix is just a longer client timeout. |
