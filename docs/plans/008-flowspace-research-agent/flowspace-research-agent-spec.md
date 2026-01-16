# FlowSpace Research Agent Command

**Mode**: [NEEDS CLARIFICATION: Simple or Full mode for implementation?]

> This specification incorporates findings from the workshop discussion on FlowSpace tooling patterns and the review of existing `substrateresearch.md` and `plan-1a-explore.md` commands.

---

## Summary

**WHAT**: A new agent command (`/flowspace-research` or similar) optimized to serve as a **parallel subagent worker** for codebase research tasks. Unlike `plan-1a-explore.md` which orchestrates multiple subagents, this command IS the subagent—designed to receive a focused research query, use FlowSpace MCP tools optimally, and return structured findings for synthesis by a parent orchestrator.

**WHY**:
1. **Reusability**: Parent commands (plan-1a-explore, plan-3-architect, etc.) currently embed research logic in their subagent prompts. A standalone command enables consistent, well-tested research behavior across all orchestrators.
2. **FlowSpace Optimization**: The current subagent prompts mention FlowSpace but don't encode the optimal usage patterns documented in fs2's agent guidance (folder navigation, detail levels, search modes, include/exclude filters).
3. **Parallel Execution**: Designed from the ground up to run efficiently alongside other instances, with clear input/output contracts.
4. **Graceful Degradation**: Built-in fallback to standard tools (Glob/Grep/Read) when FlowSpace is unavailable, ensuring the command works in any environment.

---

## Goals

1. **Single-Purpose Research Worker**: Accept a focused query, perform systematic codebase exploration, return structured findings
2. **FlowSpace-First**: Leverage all FlowSpace MCP capabilities (tree, search, get_node, docs_list, docs_get) with optimal patterns
3. **Smart Search Strategy**: Automatically select the right search approach based on query characteristics (exact term → text, pattern → regex, concept → semantic)
4. **Graceful Fallback**: Seamlessly degrade to Glob/Grep/Read when FlowSpace is unavailable
5. **Structured Output**: Return findings in a consistent format that parent orchestrators can easily synthesize
6. **Efficient Parallel Execution**: Designed to run alongside 5-7 other instances without redundant work
7. **Configurable Scope**: Support include/exclude filters to focus research on relevant code areas

---

## Non-Goals

1. **Not an Orchestrator**: Does NOT launch subagents; it IS the subagent
2. **No File Creation**: Does not write research reports to disk (parent orchestrator handles persistence)
3. **No Planning**: Pure research/exploration; no implementation planning or recommendations
4. **No External Research**: Does not call `/deepresearch` or web search; stays within the codebase
5. **Not a Replacement for plan-1a-explore**: Complements it by being the worker it invokes
6. **No Interactive Clarification**: Accepts input, returns output; no mid-execution questions

---

## Complexity

**Score**: CS-2 (small)

**Breakdown**:
| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Surface Area (S) | 1 | Single new file in agents/commands/, touches no existing code |
| Integration (I) | 1 | Depends on FlowSpace MCP (external), but well-documented |
| Data/State (D) | 0 | No schema, no persistence, stateless execution |
| Novelty (N) | 1 | Clear requirements from workshop, some ambiguity on exact invocation syntax |
| Non-Functional (F) | 0 | No special perf/security/compliance requirements |
| Testing/Rollout (T) | 1 | Need integration testing with FlowSpace, but no staged rollout |

**Total**: P = 1+1+0+1+0+1 = **4** → **CS-2**

**Confidence**: 0.85

**Assumptions**:
- FlowSpace MCP tools behave as documented
- Parent orchestrators will handle synthesis of multiple subagent outputs
- No need for persistent state between invocations
- Standard tools (Glob/Grep/Read) are always available as fallback

**Dependencies**:
- FlowSpace MCP server (optional but preferred)
- Existing command infrastructure in agents/commands/

**Risks**:
- FlowSpace API may evolve, requiring command updates
- Semantic search requires embeddings (`fs2 scan --embed`); may not always be available

**Phases**:
1. **Phase 1**: Core command with search strategy and FlowSpace integration
2. **Phase 2**: Testing and refinement based on usage in plan-1a-explore

---

## Acceptance Criteria

### AC-1: FlowSpace Detection
**Given** the command is invoked
**When** FlowSpace MCP is available
**Then** the agent uses FlowSpace tools (tree, search, get_node)
**And** logs "FlowSpace detected - using enhanced exploration"

### AC-2: Graceful Fallback
**Given** the command is invoked
**When** FlowSpace MCP is NOT available
**Then** the agent falls back to standard tools (Glob, Grep, Read)
**And** logs "FlowSpace unavailable - using standard tools"

### AC-3: Search Mode Selection
**Given** a research query is provided
**When** the query contains path separators (e.g., "src/services/")
**Then** the agent uses `tree(pattern="src/services/")` folder navigation

**Given** a research query is provided
**When** the query looks like a symbol name (e.g., "AuthService", "class Calculator")
**Then** the agent uses `tree(pattern="AuthService")` symbol search

**Given** a research query is provided
**When** the query is conceptual (e.g., "authentication flow", "error handling")
**Then** the agent attempts `search(mode="semantic")` first, falls back to `search(mode="text")`

### AC-4: Structured Output
**Given** the agent completes research
**When** findings are returned
**Then** output includes:
  - Summary (2-3 sentences)
  - Key Nodes table (node_id, type, purpose, lines)
  - Code excerpts for top findings
  - Relationships (depends on, depended by)
  - Gaps/questions that couldn't be answered

### AC-5: Scope Filtering
**Given** include/exclude parameters are provided
**When** searching with FlowSpace
**Then** `search()` calls use `include` and `exclude` regex patterns
**And** irrelevant results (tests, generated code) are filtered out

### AC-6: Progressive Exploration
**Given** the agent starts research
**When** exploring the codebase
**Then** it follows the pattern: Orientation → Targeted Search → Deep Dive → Synthesis
**And** uses appropriate `max_depth` and `detail` levels at each phase

### AC-7: Result Limits
**Given** the agent finds many matching nodes
**When** returning findings
**Then** it returns at most 10 key findings (configurable)
**And** prioritizes by relevance score or structural importance

### AC-8: Parallel-Safe Design
**Given** multiple instances run in parallel
**When** each receives a different research focus
**Then** each operates independently without interference
**And** outputs can be easily combined by parent orchestrator

---

## Risks & Assumptions

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| FlowSpace API changes | Low | Medium | Pin to documented tool signatures; add version checking |
| Semantic search unavailable (no embeddings) | Medium | Low | Graceful fallback to text mode with warning |
| Query ambiguity | Medium | Low | Smart mode selection heuristics; document expected query formats |
| Output too verbose for parent synthesis | Low | Medium | Enforce structured output format; limit findings count |

### Assumptions

1. **FlowSpace Stability**: The MCP tools (tree, search, get_node) work as documented in fs2
2. **Tool Availability**: Standard tools (Glob, Grep, Read) are always available as fallback
3. **Parent Responsibility**: The orchestrator handles output synthesis, file writing, and user communication
4. **Stateless Execution**: Each invocation is independent; no need to maintain state between calls
5. **Single Codebase**: Research targets the current working directory's codebase (no multi-repo)

---

## Open Questions

1. **Command Name**: What should the command be called?
   - `/flowspace-research`
   - `/fs-research`
   - `/codebase-research`
   - `/research-agent`
   - [NEEDS CLARIFICATION]

2. **Invocation Syntax**: What parameters should it accept?
   - Required: `query` (the research focus)
   - Optional: `--scope` (path filter), `--exclude` (exclusion pattern), `--limit` (max findings)
   - [NEEDS CLARIFICATION: exact syntax]

3. **Specialization vs Generalization**: Should this be one general-purpose agent, or should we create specialized variants?
   - Option A: Single general-purpose `/flowspace-research` command
   - Option B: Multiple specialized commands (`/fs-deps`, `/fs-patterns`, `/fs-tests`)
   - [NEEDS CLARIFICATION]

4. **Depth Limits**: How deep should the agent follow references before stopping?
   - Suggested: Max 3 levels of "follow the reference" to prevent infinite exploration
   - [NEEDS CLARIFICATION]

5. **Semantic Search Handling**: When embeddings aren't available, should the agent:
   - A) Warn and use text mode (recommended)
   - B) Fail and ask user to run `fs2 scan --embed`
   - C) Silently fall back
   - [NEEDS CLARIFICATION]

6. **Integration with plan-1a-explore**: Should the 7 subagent prompts in plan-1a-explore be updated to invoke this command, or should they remain self-contained?
   - [NEEDS CLARIFICATION]

---

## ADR Seeds (Optional)

### Decision Drivers
- Need consistent, well-tested research behavior across multiple orchestrator commands
- FlowSpace MCP provides powerful code intelligence but has specific usage patterns
- Parallel execution requires clear input/output contracts
- Must work in environments without FlowSpace (graceful degradation)

### Candidate Alternatives
- **A**: Single general-purpose command with query-type detection
- **B**: Multiple specialized commands for different research aspects
- **C**: Library/module approach (not a command, but shared code)

### Stakeholders
- Command users (AI agents invoking as subagent)
- Command maintainers (updating FlowSpace patterns)
- Orchestrator commands (plan-1a-explore, plan-3-architect, etc.)

---

## Related Context

### Existing Commands Reviewed
- `agents/commands/substrateresearch.md` (72 lines) - Legacy, generic MCP refs, no FlowSpace
- `agents/commands/plan-1a-explore.md` (831 lines) - Current orchestrator, already FlowSpace-aware

### FlowSpace Documentation Reviewed
- `agents` - AI Agent Guidance (best practices for fs2 tools)
- `mcp-server-guide` - MCP Server Guide (tool parameters and setup)
- `cli` - CLI Reference (all commands)
- `configuration-guide` - Complete Configuration (LLM/embedding setup)
- `scanning` - Scanning Guide (node types, graph format)

### Key FlowSpace Patterns to Encode
1. Folder navigation with trailing `/`
2. Progressive depth exploration (`max_depth` parameter)
3. Detail levels (`min` vs `max`)
4. Search mode selection (text/regex/semantic/auto)
5. Include/exclude filtering
6. Node ID format: `category:path:symbol`

---

**Spec Created**: 2026-01-16
**Plan Directory**: `docs/plans/008-flowspace-research-agent/`
**Next Step**: Run `/plan-2-clarify` for high-impact questions
