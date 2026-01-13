# Research Report: FlowSpace/fs2 Integration in Agent Commands

**Generated**: 2026-01-02
**Research Query**: "FlowSpace detection and API update for agents/commands"
**Mode**: Plan-Associated
**Location**: docs/plans/004-fs2/research-dossier.md
**FlowSpace**: Available

---

## Executive Summary

### What This Is About
The `agents/commands/` files contain instructions for using FlowSpace MCP to enhance codebase exploration. However, the detection code references **non-existent API methods** that need updating to match the current fs2 MCP API.

### Key Insights
1. **FlowSpace IS available** in this environment and working correctly
2. **Detection code in `plan-1a-explore.md` uses wrong API names** that don't exist
3. **Official fs2 documentation** has been provided and should be embedded/referenced
4. Other commands (plan-6a, plan-7, plan-8, plan-3) use FlowSpace correctly for node ID tracking

### Quick Stats
- **Files with FlowSpace references**: 10 files in agents/commands/
- **Files needing updates**: 1 (plan-1a-explore.md) - CRITICAL
- **Files using FlowSpace correctly**: 9 (node ID format for provenance)
- **Complexity**: Low - straightforward API name fixes

---

## How FlowSpace Currently Works

### Available MCP Tools (Confirmed via Testing)

The fs2 MCP server provides exactly **3 tools**:

| Tool | Purpose | Key Parameters |
|------|---------|----------------|
| `flowspace.tree()` | Navigate codebase structure | `pattern`, `max_depth`, `detail` |
| `flowspace.search()` | Find code by text/regex/semantic | `pattern`, `mode`, `limit`, `include`, `exclude` |
| `flowspace.get_node()` | Get full source code for a node | `node_id`, `detail`, `save_to_file` |

### Tools That DO NOT Exist (But Are Referenced)

| Referenced Tool | Status | Used In |
|-----------------|--------|---------|
| `flowspace.get_status()` | **DOES NOT EXIST** | plan-1a-explore.md:81 |
| `flowspace.search_nodes()` | **DOES NOT EXIST** | plan-1a-explore.md:82 |

---

## Architecture & Design

### Current Detection Code (BROKEN)

Location: `agents/commands/plan-1a-explore.md` lines 77-91

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

### Corrected Detection Code

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

### FlowSpace Node ID Usage (Correct - No Changes Needed)

Multiple commands correctly use FlowSpace node IDs for provenance tracking:

```markdown
# Example from plan-6a-update-progress.md
# FlowSpace: [^3] function:src/validators.py:validate_email
```

This format (`category:path:symbol`) is correct and matches the `node_id` format returned by `tree()` and `search()`.

---

## fs2 MCP API Reference (Official)

### Tool 1: `tree` - Explore Codebase Structure

**Purpose**: Navigate the hierarchical structure of an indexed codebase.

**When to Use**:
- Starting exploration of an unfamiliar codebase
- Finding classes, functions, or files by name pattern
- Understanding the containment hierarchy (files → classes → methods)
- Getting an overview before drilling into specifics

**Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pattern` | string | `"."` | Filter: `"."` for all, `"ClassName"` for substring, `"*.py"` for glob |
| `max_depth` | int | `0` | `0` = unlimited, `1` = root only, `2` = roots + children |
| `detail` | string | `"min"` | `"min"` = compact, `"max"` = includes signatures and AI summaries |

**Returns**: List of tree nodes with `node_id` (use with `get_node`), `name`, `category`, `start_line`, `end_line`, `children`.

---

### Tool 2: `get_node` - Retrieve Complete Source Code

**Purpose**: Get the full source code and metadata for a specific code element.

**When to Use**:
- After finding a `node_id` from `tree` or `search` results
- When you need to read the actual implementation
- To save node data to a file for later analysis

**Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `node_id` | string | required | Unique identifier from `tree` or `search` |
| `save_to_file` | string | `null` | Optional path to save as JSON (under cwd only) |
| `detail` | string | `"min"` | `"min"` = 7 fields, `"max"` = 12 fields |

**Returns**: CodeNode dict with `content` (full source), `signature`, `start_line`, `end_line`, etc. Returns `null` if not found.

---

### Tool 3: `search` - Find Code by Content or Meaning

**Purpose**: Search for code by text, regex pattern, or semantic meaning.

**When to Use**:
- Finding code that contains specific text
- Searching with regex patterns (e.g., `"def test_.*"`)
- Conceptual discovery (e.g., "error handling logic") with semantic mode
- Filtering results to specific paths

**Parameters**:
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pattern` | string | required | Search pattern (text, regex, or natural language) |
| `mode` | string | `"auto"` | `"text"`, `"regex"`, `"semantic"`, or `"auto"` |
| `limit` | int | `20` | Maximum results (1-100) |
| `offset` | int | `0` | Skip results for pagination |
| `include` | list | `null` | Regex patterns for paths to include |
| `exclude` | list | `null` | Regex patterns for paths to exclude |
| `detail` | string | `"min"` | `"min"` = 9 fields, `"max"` = 13 fields |

**Returns**: Envelope with `meta` (total, pagination, folder distribution) and `results` (node_id, score, snippet).

**Search Modes**:
- `text`: Substring matching (case-insensitive)
- `regex`: Regular expression pattern matching
- `semantic`: Conceptual similarity via embeddings (requires `fs2 scan --embed`)
- `auto`: Automatically selects best mode based on pattern

---

## Dependencies & Integration

### What Commands Reference FlowSpace

| File | Usage | Status |
|------|-------|--------|
| `plan-1a-explore.md` | Detection + exploration prompts | **NEEDS UPDATE** |
| `plan-3-architect.md` | FlowSpace provenance graph docs | OK |
| `plan-5-phase-tasks-and-brief.md` | Node ID format | OK |
| `plan-6a-update-progress.md` | Embedding FlowSpace IDs in source | OK |
| `plan-7-code-review.md` | Validates FlowSpace node IDs | OK |
| `plan-8-merge.md` | FlowSpace ID reconciliation | OK |
| `README.md` | FlowSpace tracking docs | OK |
| `substrateresearch.md` | References search_nodes (vague) | Minor |

### External Dependencies

| Dependency | Required For | How to Install |
|------------|--------------|----------------|
| fs2 CLI | Indexing codebase | `uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install` |
| fs2 scan | tree/get_node/search | `fs2 init && fs2 scan` |
| fs2 scan --embed | Semantic search | `fs2 scan --embed` |
| MCP server | Agent access to fs2 | Follow GitHub README for MCP setup |

---

## Modification Considerations

### Safe to Modify

1. **`plan-1a-explore.md` detection code (lines 77-91)**
   - Well-isolated pseudo-code block
   - Clear replacement needed
   - No downstream dependencies on specific tool names

2. **`plan-1a-explore.md` subagent prompts (lines 99-310)**
   - Currently say "use FlowSpace MCP tools as documented by FlowSpace"
   - Can be updated to include specific API examples
   - Each subagent section is independent

### Modify with Caution

1. **FlowSpace node ID format references**
   - Format `category:path:symbol` is used consistently
   - Changing format would break provenance tracking
   - Current format matches actual API - no change needed

---

## Critical Discoveries

### Finding 01: Detection Uses Non-Existent API

**Impact**: Critical
**Location**: `agents/commands/plan-1a-explore.md:81-82`
**What**: The detection code calls `flowspace.get_status()` and `flowspace.search_nodes()` which don't exist
**Why It Matters**: FlowSpace detection will always fail, causing fallback to standard tools even when FlowSpace is available
**Required Action**: Replace with `flowspace.tree(pattern=".", max_depth=1)` call

### Finding 02: No Installation Guidance When FlowSpace Missing

**Impact**: Medium
**Location**: `agents/commands/plan-1a-explore.md:86-87`
**What**: When FlowSpace is not detected, there's no guidance on how to install it
**Why It Matters**: Users may not know FlowSpace exists or how to enable it
**Required Action**: Add installation instructions in the fallback message

### Finding 03: Subagent Prompts Reference Non-Existent Documentation

**Impact**: Low-Medium
**Location**: `agents/commands/plan-1a-explore.md:90-91, 104, 145, etc.`
**What**: Prompts say "Use FlowSpace MCP tools as documented by FlowSpace" but no such docs exist
**Why It Matters**: Subagents may not know how to use FlowSpace effectively
**Required Action**: Embed or reference the official API documentation

---

## Recommendations

### If Modifying This System

1. **Update detection code first** - This is the critical fix
2. **Add installation instructions** - Help users enable FlowSpace
3. **Embed API reference** - Either inline or as a reference file
4. **Test the updated detection** - Verify it works in practice

### Implementation Approach

**Option A: Minimal Fix (Recommended for speed)**
- Update only lines 77-91 with correct detection
- Add installation guidance in fallback

**Option B: Comprehensive Update**
- Fix detection code
- Create `agents/commands/fs2-mcp-reference.md` with full API docs
- Update all subagent prompts to reference it
- Add fs2 prereqs to README.md

### Suggested Changes

```markdown
## Changes to plan-1a-explore.md

### Line 81-82: Replace detection tools
- OLD: flowspace.get_status()
- OLD: flowspace.search_nodes("test")
- NEW: flowspace.tree(pattern=".", max_depth=1)

### Lines 86-87: Add installation guidance
- ADD: print("To install: uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install")
- ADD: print("Then run: fs2 init && fs2 scan (requires user configuration)")
- ADD: print("See: https://github.com/AI-Substrate/flow_squared for MCP server setup")

### Lines 90-91: Replace vague docs reference
- OLD: "Use FlowSpace MCP to look up documentation..."
- NEW: Include actual API usage patterns (tree, search, get_node)
```

---

## Appendix: File Inventory

### Core Files Needing Changes

| File | Lines | Purpose | Change Needed |
|------|-------|---------|---------------|
| `agents/commands/plan-1a-explore.md` | 791 | Research command with FlowSpace integration | Fix detection, add API docs |

### Files Using FlowSpace Correctly (No Changes)

| File | Lines | Purpose |
|------|-------|---------|
| `agents/commands/plan-6a-update-progress.md` | 1233 | Progress tracking with FlowSpace node IDs |
| `agents/commands/plan-7-code-review.md` | 1270 | Code review validating FlowSpace IDs |
| `agents/commands/plan-8-merge.md` | 994 | Merge planning with FlowSpace reconciliation |
| `agents/commands/plan-3-architect.md` | 1316 | Architecture with FlowSpace provenance |
| `agents/commands/README.md` | 1055 | Documentation of FlowSpace tracking |

---

## Next Steps

1. **Run `/plan-1b-specify`** to create a specification for the updates
2. **Or proceed directly** to update `plan-1a-explore.md` with the fixes

---

**Research Complete**: 2026-01-02
**Report Location**: docs/plans/004-fs2/research-dossier.md
