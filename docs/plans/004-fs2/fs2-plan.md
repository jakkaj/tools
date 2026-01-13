# Update FlowSpace/fs2 API Integration Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-01-03
**Spec**: [./fs2-spec.md](./fs2-spec.md)
**Status**: COMPLETE

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Critical Research Findings](#critical-research-findings)
3. [Implementation](#implementation)
4. [Change Footnotes Ledger](#change-footnotes-ledger)

---

## Executive Summary

**Problem**: The FlowSpace MCP detection code in `plan-1a-explore.md` references non-existent API methods (`get_status`, `search_nodes`), causing detection to always fail even when FlowSpace is available. Users also receive no guidance on how to install FlowSpace when it's not detected.

**Solution**: Update the detection code to use the correct fs2 MCP API (`tree`), add installation guidance in the fallback message, and update subagent prompts with actual API usage patterns.

**Expected Outcome**: FlowSpace detection works correctly, enabling enhanced codebase exploration when fs2 MCP is available, with clear installation guidance when it's not.

---

## Critical Research Findings (Concise)

*Source: research-dossier.md (comprehensive research already performed)*

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | Detection uses `flowspace.get_status()` which doesn't exist | Replace with `flowspace.tree()` call |
| 02 | Critical | Detection uses `flowspace.search_nodes()` which doesn't exist | Remove - tree() alone is sufficient for detection |
| 03 | High | No installation guidance when FlowSpace unavailable | Add install command and README link to fallback |
| 04 | Medium | Subagent prompts say "as documented by FlowSpace" but no docs exist | Update prompts with actual API patterns |
| 05 | Medium | Line 90-91 references non-existent FlowSpace documentation | Replace with inline API usage guidance |
| 06 | Low | `substrateresearch.md` mentions `search_nodes` generically | Update to use `search` (optional, minor) |
| 07 | Info | Other commands (plan-3, plan-5, plan-6a, plan-7, plan-8) use FlowSpace correctly | No changes needed - node ID format is correct |
| 08 | Info | Correct API: `tree(pattern, max_depth, detail)` | Use for detection and navigation |
| 09 | Info | Correct API: `search(pattern, mode, limit, include, exclude)` | Use for finding code |
| 10 | Info | Correct API: `get_node(node_id, detail, save_to_file)` | Use for retrieving source |

---

## Implementation (Single Phase)

**Objective**: Fix FlowSpace detection and API references in agent commands to use correct fs2 MCP API.

**Testing Approach**: Manual verification (from spec)
**Mock Usage**: N/A (documentation changes only)

### Tasks

| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Notes |
|--------|-----|------|----|------|--------------|------------------|------------|-------|
| [x] | T000 | **Probe FlowSpace API** - Experiment with current fs2 MCP tools | 2 | Discovery | -- | -- | Document actual behavior of tree, search, get_node; check for new commands | See detailed probing instructions below |
| [x] | T001 | Replace detection code block (lines 77-88) | 1 | Core | T000 | /Users/jordanknight/github/tools/agents/commands/plan-1a-explore.md | Detection uses `tree(pattern=".", max_depth=1)` | Use T000 findings to confirm correct API |
| [x] | T002 | Add installation guidance in fallback (after line 87) | 1 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/plan-1a-explore.md | Fallback includes: install command, config note, README link | 3 print statements added |
| [x] | T003 | Replace FlowSpace docs reference (lines 90-91) | 1 | Core | T001 | /Users/jordanknight/github/tools/agents/commands/plan-1a-explore.md | Guidance references actual API (tree, search, get_node) | Remove "look up documentation" instruction |
| [x] | T004 | Update subagent prompts "as documented by FlowSpace" references | 2 | Core | T003 | /Users/jordanknight/github/tools/agents/commands/plan-1a-explore.md | Prompts include concrete API examples | Multiple locations: ~lines 104, 145, 161, 177, 193, 209 |
| [x] | T005 | **Add runtime FlowSpace discovery** to plan-1a-explore.md | 2 | Core | T003 | /Users/jordanknight/github/tools/agents/commands/plan-1a-explore.md | Command instructs agents to probe FlowSpace at runtime | See detailed instructions below |
| [x] | T006 | Update `substrateresearch.md` search_nodes reference (optional) | 1 | Minor | -- | /Users/jordanknight/github/tools/agents/commands/substrateresearch.md | Line 16 says `search` instead of `search_nodes` | Low priority - vague reference |
| [x] | T007 | Sync changes to distribution directory | 1 | Sync | T001-T006 | /Users/jordanknight/github/tools/src/jk_tools/agents/commands/ | Run `./scripts/sync-to-dist.sh` | Source → dist sync |
| [x] | T008 | Manual verification: test FlowSpace detection | 1 | Test | T007 | -- | FlowSpace detected when running plan-1a-explore | Verify "✅ FlowSpace MCP detected" message appears |

### Detailed Task Specifications

#### T000: Probe FlowSpace API (Discovery Phase)

**Purpose**: Before making any changes, experiment with the current FlowSpace API to understand actual behavior and discover any new features.

**Probing Approach**:

1. **Test each tool with minimal parameters** - What's required vs optional?
2. **Test with `detail="max"`** - What extra fields are available?
3. **Try different modes** - What search modes exist (text, regex, semantic)?
4. **Check for new tools** - Are there tools beyond tree, search, get_node?
5. **Note useful fields** - What metadata helps with code understanding?

**Key concepts to discover**:
- How does `tree()` organize code hierarchically?
- What search modes does `search()` support?
- What detail levels does `get_node()` offer?
- Are there AI-generated summaries or other enrichments?
- What node ID formats are used?

**Document findings** in execution log before proceeding.

---

#### T001: Replace Detection Code Block

**Location**: `/Users/jordanknight/github/tools/agents/commands/plan-1a-explore.md` lines 77-88

**Current** (BROKEN):
```python
# Pseudo-code for detection
try:
    # Try calling a FlowSpace tool
    flowspace.get_status() or        # <-- DOESN'T EXIST
    flowspace.search_nodes("test")   # <-- DOESN'T EXIST
    FLOWSPACE_AVAILABLE = True
    print("✅ FlowSpace MCP detected - using enhanced exploration")
except:
    FLOWSPACE_AVAILABLE = False
    print("ℹ️ FlowSpace not available - using standard tools")
```

**Replace with**:
```python
# Pseudo-code for detection
try:
    # Try calling tree() with minimal params - fast and reliable
    flowspace.tree(pattern=".", max_depth=1)
    FLOWSPACE_AVAILABLE = True
    print("✅ FlowSpace MCP detected - using enhanced exploration")
except:
    FLOWSPACE_AVAILABLE = False
    print("ℹ️ FlowSpace not available - using standard tools")
    print("To install: uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install")
    print("Then run: fs2 init && fs2 scan (requires user configuration)")
    print("See: https://github.com/AI-Substrate/flow_squared/blob/main/README.md")
```

#### T003: Replace FlowSpace Docs Reference

**Location**: Lines 90-91

**Current**:
```markdown
If FlowSpace is available, first query:
"Use FlowSpace MCP to look up documentation on how to search properly with FlowSpace for comprehensive codebase exploration."
```

**Replace with**:
```markdown
If FlowSpace is available, use these tools for enhanced exploration:
- `tree(pattern, max_depth, detail)` - Navigate codebase structure hierarchically
- `search(pattern, mode, limit, include, exclude)` - Find code by text, regex, or semantic meaning
- `get_node(node_id, detail)` - Retrieve full source code for a specific node

**Recommended workflow**:
1. Start with `tree(pattern=".", max_depth=1)` to see top-level structure
2. Use `search(pattern="concept", mode="semantic")` for conceptual discovery
3. Use `get_node(node_id)` to read full source after finding relevant nodes
```

#### T004: Update Subagent Prompts

**Locations**: Lines containing "Use FlowSpace MCP tools as documented by FlowSpace"

**Pattern to find**: `Use FlowSpace MCP tools as documented by FlowSpace`

**Replace with**:
```markdown
Use FlowSpace MCP tools:
- `tree(pattern="ClassName")` to find specific classes/functions
- `search(pattern="concept", mode="semantic")` for conceptual search
- `get_node(node_id)` to retrieve full source code
```

---

#### T005: Add Runtime FlowSpace Discovery to plan-1a-explore.md

**Purpose**: The plan-1a-explore command should instruct agents to probe FlowSpace at runtime to discover current API capabilities, since FlowSpace may have been updated since the command was written.

**Location**: After the detection code block (after line ~88), add a new section.

**Concept to add**:

Add a "### 2a) FlowSpace API Discovery (Runtime)" section that instructs the agent to:

1. **Probe each FlowSpace tool** with minimal then maximal parameters
2. **Discover available features** - what fields, modes, and options exist?
3. **Check for new tools** - are there capabilities beyond tree/search/get_node?
4. **Note useful metadata** - AI summaries, language detection, relevance scores, etc.
5. **Use discovered capabilities** in the exploration that follows

**Key message**: FlowSpace is actively developed. The agent should discover what's available at runtime rather than relying on static documentation that may be outdated.

**Why this matters**: Ensures agents always use the best available FlowSpace capabilities, even if the command was written before new features were added.

---

### Acceptance Criteria

- [x] Detection code calls `flowspace.tree()` instead of non-existent methods
- [x] Fallback message includes installation command: `uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install`
- [x] Fallback message notes that `fs2 init && fs2 scan` requires user configuration
- [x] Fallback message links to README: `https://github.com/AI-Substrate/flow_squared/blob/main/README.md`
- [x] No references to `get_status` or `search_nodes` remain in plan-1a-explore.md
- [x] Subagent prompts include concrete API examples
- [x] **Runtime discovery section added** - plan-1a-explore instructs agents to probe FlowSpace API
- [x] Changes synced to `src/jk_tools/agents/commands/`
- [x] Manual test confirms FlowSpace detection works when fs2 MCP available

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| fs2 API changes after this update | Low | Low | API is stable; detection method is simple |
| Edit breaks markdown formatting | Low | Medium | Verify file renders correctly after edit |
| Sync script fails | Low | Low | Run manually if automated sync fails |

---

## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]
[^2]: [To be added during implementation via plan-6a]

---

**Next steps:**
- **Ready to implement**: `/plan-6-implement-phase --plan "docs/plans/004-fs2/fs2-plan.md"`
- **Optional validation**: `/plan-4-complete-the-plan` (recommended but CS-1 is straightforward)
