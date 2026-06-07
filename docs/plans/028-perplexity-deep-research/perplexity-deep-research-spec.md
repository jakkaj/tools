# perplexity-deep-research — Feature Spec

**Mode**: Simple
**Created**: 2026-06-07
**Plan folder**: `docs/plans/028-perplexity-deep-research/`

ℹ️ Research was gathered inline by `/the-flow` (external API facts, not a codebase dossier) — see `original-ask.md`.

## Research Context

The bundled perplexity MCP server (`@perplexity-ai/mcp-server`) reliably **times out at ~5 minutes**. Perplexity's `sonar-deep-research` model routinely runs longer than that (it fans out multiple web searches + thousands of reasoning tokens per call), so deep-research requests fail through the MCP path.

Live-verified facts (2026-06-07):
- **Endpoint**: `https://api.perplexity.ai/chat/completions` (OpenAI-shaped: `{model, messages, ...}`).
- **Auth**: `Authorization: Bearer $PERPLEXITY_API_KEY` — the key is in the env var and every MCP config.
- **Models**: `sonar` ✅, `sonar-pro` ✅, `sonar-deep-research` ✅ (the slow one). `sonar-reasoning` is **deprecated** (HTTP 400).
- **Response**: `choices[0].message.content` holds the answer; `citations[]` holds source URLs; `usage{}` reports cost.

The fix is small: call the HTTP endpoint directly with a long client-side timeout, bypassing the MCP wrapper's clock.

## Summary

Add a `perplexity-deep-research` skill plus a tiny bundled CLI that POSTs directly to the Perplexity chat-completions API with a generous timeout, so long `sonar-deep-research` jobs complete instead of dying at the MCP 5-minute cap. The skill tells the agent when and how to shell out to the CLI; the CLI does the raw HTTP work.

## Goals

- A small CLI (zero pip deps, Python stdlib only) that takes a prompt and returns Perplexity's answer + citations, with a configurable long timeout (default ~30 min).
- A `SKILL.md` that triggers when an agent needs deep web research and routes it to the CLI instead of the timeout-prone MCP.
- Bundle the CLI inside the skill folder so `npx skills add` ships it alongside `SKILL.md`.
- Use the existing `$PERPLEXITY_API_KEY` — no new secret management.

## Non-Goals

- No async/polling job API (Perplexity's direct endpoint is synchronous; a long timeout is enough).
- No replacement of the perplexity MCP for quick `sonar`/`sonar-pro` asks — the MCP stays fine for fast calls.
- No streaming, no caching, no retry/backoff framework (prototype scope).
- No new installer wiring; the CLI travels with the skill.

## Target Domains

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| skills catalog (`skills/general/`) | existing | **modify** | Add new `perplexity-deep-research/` skill folder (SKILL.md + bundled CLI) |

No formal `docs/domains/` registry exists in this repo; the skill folder is the self-contained unit of change.

## Testing Strategy

- **Approach**: Lightweight.
- **Rationale**: It's a prototype; the whole value is one real HTTP call. A couple of smoke checks prove it end-to-end.
- **Focus Areas**: (1) CLI runs and prints help; (2) a real call to `sonar` returns non-empty content + citations; (3) the long-timeout flag is honoured (no premature abort).
- **Excluded**: mocked-HTTP unit suites, error-injection matrices, CI integration.
- **Mock Usage**: None — real API only (Mock policy A→ "real data only"). Smoke runs hit the live endpoint with the real key (costs a few cents).

## Documentation Strategy

- **Location**: Skill body only — `SKILL.md` carries usage. No separate README/docs/how page.
- **Rationale**: Prototype; the skill is the doc.

## Complexity

- **Score**: CS-2 (small)
- **Breakdown**: S=1, I=1, D=0, N=1, F=1, T=0  → P=4 → CS-2
- **Confidence**: 0.85
- **Assumptions**: Perplexity API stays OpenAI-shaped; `$PERPLEXITY_API_KEY` is present at runtime; `python3` is available.
- **Dependencies**: Perplexity HTTP API; Python 3 stdlib (`urllib`, `json`, `argparse`).
- **Risks**: see below.
- **Phases**: 1 (single build phase).

## Acceptance Criteria

1. `python3 <skill>/pplx_research.py --help` prints usage and exits 0.
2. Running the CLI with a prompt and `--model sonar` returns the assistant's answer text followed by a list of citation URLs, exit 0.
3. The CLI reads the key from `$PERPLEXITY_API_KEY`; with the key unset it exits non-zero with a clear error (no traceback dump).
4. The CLI accepts `--model sonar-deep-research` and a `--timeout` greater than 300s, and does **not** abort at 5 minutes (the failure mode being fixed).
5. `SKILL.md` has valid frontmatter (`name: perplexity-deep-research` matching the folder) and a `description` that triggers on deep-research needs, and documents the CLI invocation + when to prefer it over the MCP.
6. The CLI is bundled inside the skill folder so it installs via `npx skills add`.

## Risks & Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| API shape/model names drift | Low | Med | Models verified live today; `--model` is a flag so callers can override |
| Long-running call still hangs forever | Low | Low | `--timeout` is explicit and bounded (default ~30 min), not infinite |
| Key missing at runtime | Med | Low | AC-3: clear error, non-zero exit, no traceback |
| `sonar-deep-research` cost per call | Med | Low | Smoke tests use cheap `sonar`; deep model only on real use |

## Open Questions

None blocking. (Default timeout value + default model are design choices settled in the plan: default model `sonar-deep-research`, default timeout 1800s.)

## Workshop Opportunities

None — the design is small and already pinned by the research. Straight to `/plan-3`.

## Clarifications

### Session 2026-06-07
- **Mode**: Simple (via `--simple`).
- **Testing Strategy**: Lightweight — smoke checks only.
- **Mock Usage**: A — real API only, no mocks.
- **Documentation Strategy**: Skill body only.
