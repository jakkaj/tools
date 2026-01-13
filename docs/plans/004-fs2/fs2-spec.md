# Update FlowSpace/fs2 API Integration in Agent Commands

**Mode**: Simple

---

## Research Context

This specification incorporates findings from `research-dossier.md`.

- **Components affected**: `agents/commands/plan-1a-explore.md` (primary), minor reference in `substrateresearch.md`
- **Critical dependencies**: fs2 MCP server must be available for FlowSpace features
- **Modification risks**: Low - isolated pseudo-code blocks, no downstream dependencies on specific API names
- **Link**: See `research-dossier.md` for full analysis

---

## Summary

**WHAT**: Update the FlowSpace MCP detection code and API references in agent commands to use the correct, existing fs2 API methods (`tree`, `search`, `get_node`) instead of non-existent methods (`get_status`, `search_nodes`).

**WHY**: The current detection code in `plan-1a-explore.md` references API methods that don't exist, causing FlowSpace detection to always fail. This forces agents to fall back to standard tools even when FlowSpace is available, degrading codebase exploration capabilities. Additionally, users without FlowSpace receive no guidance on how to install it.

---

## Goals

1. **Fix FlowSpace detection** so it correctly identifies when fs2 MCP is available
2. **Provide installation guidance** when FlowSpace is not detected, helping users enable enhanced exploration
3. **Update API references** to use correct method names that actually exist in the fs2 MCP server
4. **Improve subagent effectiveness** by providing concrete API usage examples instead of references to non-existent documentation

---

## Non-Goals

- **Not changing the FlowSpace node ID format** - The `category:path:symbol` format is correct and used consistently across multiple commands
- **Not modifying other commands** that use FlowSpace correctly (plan-3, plan-5, plan-6a, plan-7, plan-8)
- **Not adding new FlowSpace features** - This is purely a fix to make existing intended functionality work
- **Not requiring FlowSpace** - Commands must continue to work without FlowSpace using standard tools as fallback

---

## Complexity

- **Score**: CS-1 (trivial)
- **Breakdown**: S=1, I=0, D=0, N=0, F=0, T=0
  - S=1: Changes primarily in one file (plan-1a-explore.md), minor touch in substrateresearch.md
  - I=0: Internal markdown documentation changes only
  - D=0: No data or state changes
  - N=0: Well-specified from research - exact lines and replacements identified
  - F=0: No performance or security implications
  - T=0: Manual verification that detection works is sufficient
- **Confidence**: 0.95
- **Assumptions**:
  - The fs2 MCP API (tree, search, get_node) remains stable
  - The `tree(pattern=".", max_depth=1)` call is reliable for detection
- **Dependencies**:
  - fs2 MCP server for testing (already available in environment)
- **Risks**:
  - None significant - worst case is detection still fails and fallback continues to work
- **Phases**:
  - Single phase: Update detection code, add installation guidance, update API references

---

## Acceptance Criteria

1. **Detection works when FlowSpace available**
   - When fs2 MCP server is configured, agents executing plan-1a-explore correctly detect FlowSpace and use enhanced exploration

2. **Detection gracefully fails when FlowSpace unavailable**
   - When fs2 MCP is not available, detection fails gracefully and provides installation instructions

3. **Installation guidance is actionable**
   - The fallback message includes the exact command: `uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install`
   - Directs user to complete setup manually: `fs2 init && fs2 scan` (requires user configuration)
   - Links to: https://github.com/AI-Substrate/flow_squared/blob/main/README.md for MCP server setup

4. **API references are accurate**
   - No references to `get_status` or `search_nodes` remain in agent commands
   - All FlowSpace tool references match the actual API: `tree`, `search`, `get_node`

5. **Subagent prompts include usable guidance**
   - Subagent prompts reference actual API patterns instead of "as documented by FlowSpace"

6. **Backward compatibility maintained**
   - Commands continue to work without FlowSpace using standard tools (Glob, Grep, Read)

---

## Risks & Assumptions

### Risks
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| fs2 API changes in future | Low | Low | Document API version; detection is simple |
| Installation command changes | Low | Low | GitHub URL is stable; update if needed |

### Assumptions
- The fs2 MCP server exposes `tree`, `search`, and `get_node` tools as documented
- `tree(pattern=".", max_depth=1)` is a fast, reliable way to test availability
- Users have access to `uvx` for installation (standard Python tooling)

---

## Open Questions

None - research phase resolved all questions about the correct API.

---

## ADR Seeds (Optional)

**Decision Drivers**:
- Detection must be fast (minimal overhead when FlowSpace unavailable)
- Detection must be reliable (no false positives/negatives)
- Installation guidance must be actionable

**Candidate Alternatives**:
- A: Use `tree()` for detection (RECOMMENDED - fast, returns immediately)
- B: Use `search()` for detection (slower, requires pattern)
- C: Check for MCP server configuration (would require filesystem access)

**Stakeholders**: Agent command authors, AI assistants using these commands

---

## Next Steps

When ready: Run `/plan-2-clarify` for any remaining questions, or proceed directly to implementation given the simplicity (CS-1).
