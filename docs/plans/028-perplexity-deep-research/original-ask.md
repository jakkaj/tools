# Original ask — perplexity-deep-research
**Captured**: 2026-06-07T02:11:20Z  ·  **By**: /the-flow

> we need a new skill. perplexity mcp times out at 5 minutes always. we need a skill that goes direct to pereplxty api with the key and does the work using more custom means. need a little cli in here that it can use to do it. very simple please. keys are availbel in the mcp conigs and env vars... loko up what model perplexity has etc. you can use perplexity mcp to do the research. use the-flow skill please. build a littl prototype.

## Research already gathered (by /the-flow before spec)
- **Endpoint**: `https://api.perplexity.ai/chat/completions` (OpenAI-shaped chat completions)
- **API key**: `$PERPLEXITY_API_KEY` — present in env and in every MCP config (`~/.claude.json`, `~/.codex/config.toml`, opencode, repo `agents/mcp/servers.json` references it as `${PERPLEXITY_API_KEY}`)
- **Models (live-tested 2026-06-07)**: `sonar` ✅, `sonar-pro` ✅, `sonar-deep-research` ✅ (the slow research model — fires multiple searches + thousands of reasoning tokens; this is what exceeds the MCP 5-min timeout). `sonar-reasoning` is **deprecated** (HTTP 400).
- **Why MCP times out**: the `@perplexity-ai/mcp-server` wrapper caps the call; `sonar-deep-research` routinely runs >5 min. A direct HTTP call with a long client timeout sidesteps the wrapper.
