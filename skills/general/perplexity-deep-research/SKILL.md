---
name: perplexity-deep-research
description: |
  Run long, deep web research via the Perplexity API directly (bypassing the
  perplexity MCP server, which times out at ~5 minutes). Use this when a research
  question needs the slow `sonar-deep-research` model — multi-source investigation,
  literature sweeps, "find everything about X" — or any Perplexity call you expect
  to run longer than a few minutes. For quick factual lookups, the perplexity MCP is
  still fine; reach for this skill when the MCP times out or the job is deep.
---

# perplexity-deep-research

A tiny bundled CLI (`pplx_research.py`, Python stdlib only) that POSTs straight to
Perplexity's HTTP API with a long client-side timeout, so deep research jobs finish
instead of dying at the MCP's ~5-minute cap.

## When to use this vs the perplexity MCP

| Situation | Use |
|-----------|-----|
| Quick fact, summary, single question (seconds) | perplexity MCP (`perplexity_ask`) — simplest |
| Deep / multi-source research, expected > 5 min | **this skill** (`sonar-deep-research`) |
| MCP call timed out | **this skill** |

## Prerequisites

- `PERPLEXITY_API_KEY` in the environment (already present in this setup's env and
  every MCP config). The CLI reads it directly; no extra config.
- `python3` (stdlib only — nothing to install).

## Usage

The CLI (`pplx_research.py`) lives next to this file in the skill folder. Invoke it
with `python3`, pointing at the installed path (skills install to
`~/.agents/skills/perplexity-deep-research/`, symlinked into `~/.claude/skills/`):

```bash
# Deep research (default model = sonar-deep-research, default timeout = 1800s/30min)
python3 ~/.agents/skills/perplexity-deep-research/pplx_research.py "Survey the current state of X, with sources"

# Or cd into the skill folder first, then call it directly
cd ~/.agents/skills/perplexity-deep-research && python3 pplx_research.py "your deep research question here"

# Quick / cheap call with the fast model
python3 pplx_research.py --model sonar "what is the capital of France?"

# Give it even longer, and bias toward recent sources
python3 pplx_research.py --timeout 2400 --recency month "what changed recently in Y?"

# Raw JSON (for programmatic use)
python3 pplx_research.py --json "..."
```

### Options

| Flag | Default | Meaning |
|------|---------|---------|
| `prompt` (positional) | — | The research question |
| `--model` | `sonar-deep-research` | `sonar`, `sonar-pro`, or `sonar-deep-research` |
| `--timeout` | `1800` | Client timeout (seconds). This is the knob that beats the MCP's ~5-min cap. |
| `--system` | — | Optional system prompt |
| `--recency` | — | `hour` / `day` / `week` / `month` / `year` |
| `--json` | off | Print raw API response instead of formatted text |

## Output

Formatted mode prints the answer to stdout, then a `Citations:` list of source URLs.
Model + cost go to stderr (so stdout stays pipe-clean). Exit codes: `0` success,
`1` API/network error, `2` missing `PERPLEXITY_API_KEY`.

## Notes

- `sonar-reasoning` is **deprecated** (the API returns HTTP 400) — don't use it.
- `sonar-deep-research` costs more and takes minutes; use `sonar` for cheap/quick checks.
- This is a prototype: synchronous call + long timeout, no async polling, no retries.
