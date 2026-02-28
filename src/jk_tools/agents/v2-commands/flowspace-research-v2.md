---
description: FlowSpace-first codebase research agent for parallel subagent exploration with structured output for parent orchestrator synthesis. Domain-aware v2.
---

Please deep think / ultrathink as this is a complex task.

# flowspace-research

A **FlowSpace-first research worker** designed to BE a parallel subagent—receiving a focused research query, using FlowSpace MCP tools optimally, and returning structured findings for parent orchestrator synthesis.

**Key Characteristics**:
- **IS the subagent** (does NOT launch subagents)
- **FlowSpace-first** with graceful fallback to traditional tools (Glob/Grep/Read)
- **Multi-graph aware** - searches across relevant graphs (local project, shared libs, vendor SDKs)
- **Domain-boundary aware** - loads `docs/domains/` registry, tags findings with domain origin, maps graphs to domains
- **Smart query detection** (path/symbol/concept)
- **Structured output** for easy synthesis by parent commands

---

## Input Parameters

```
$ARGUMENTS
# Required:
#   <query>              Research query (positional, required)
#
# Optional:
#   --scope <path>       Limit search to path (e.g., "src/auth/")
#   --exclude <pattern>  Exclude paths matching pattern (e.g., "test")
#   --limit <N>          Max findings to return (default: 10)
#   --mode <type>        Force query mode: path | symbol | concept | auto (default: auto)
#   --graph <name>       Query specific graph(s): "default", "shared-lib", "all", or comma-separated list
#                        Default: auto-select relevant graphs based on query
#
# Examples:
#   /flowspace-research "AuthService"
#   /flowspace-research "authentication flow" --scope "src/" --exclude "test"
#   /flowspace-research "src/services/" --mode path --limit 20
#   /flowspace-research "RedisCache" --graph "cache-lib"
#   /flowspace-research "config patterns" --graph "all"
```

---

## Execution Flow

### 1) FlowSpace Detection (with Graceful Fallback)

**Strategy**: Try FlowSpace first for enhanced exploration, fall back to traditional tools (Glob/Grep/Read) if unavailable.

```python
# Pseudo-code for detection
try:
    # Fast, minimal probe - tests MCP availability and graph existence
    result = flowspace.tree(pattern=".", max_depth=1)
    FLOWSPACE_AVAILABLE = True
    print("✅ FlowSpace MCP detected - using enhanced exploration")

    # Check semantic search availability (optional, for concept queries)
    try:
        flowspace.search(pattern="test", mode="semantic", limit=1)
        SEMANTIC_AVAILABLE = True
    except:
        SEMANTIC_AVAILABLE = False
        print("ℹ️ Semantic search unavailable (run 'fs2 scan --embed' to enable)")

except Exception as e:
    FLOWSPACE_AVAILABLE = False
    SEMANTIC_AVAILABLE = False
    # GRACEFUL FALLBACK: Continue with traditional tools
    print("""
    ℹ️ FlowSpace MCP not available - using traditional tools (Glob/Grep/Read)

    Note: For enhanced exploration with code intelligence, install FlowSpace:
      1. Install fs2: uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install
      2. Initialize: fs2 init
      3. Scan codebase: fs2 scan
    """)
    # CONTINUE with traditional tools - do not stop
```

**Fallback Behavior**: When FlowSpace is unavailable, the command uses Glob for file discovery, Grep for content search, and Read for file contents. Results are equivalent but may lack AI-generated summaries and semantic search capabilities.

---

### 1.5) Multi-Graph Discovery & Selection

**IMPORTANT**: The best answer may not be in the default graph. Always consider searching across relevant graphs.

```python
# Discover available graphs
available_graphs = flowspace.list_graphs()
print(f"📊 Available graphs: {available_graphs['count']}")

for graph in available_graphs["docs"]:
    status = "✓" if graph["available"] else "✗"
    print(f"   {status} {graph['name']}: {graph.get('description', 'No description')}")

# Classify graphs by locality
LOCAL_GRAPHS = []      # Have direct file access (Glob/Grep/Read works)
EXTERNAL_GRAPHS = []   # FlowSpace-only (no local file access)

for graph in available_graphs["docs"]:
    if graph["available"]:
        # Default graph is always local (current working directory)
        if graph["name"] == "default":
            LOCAL_GRAPHS.append(graph)
        # Graphs with paths inside current project are local
        elif is_path_local(graph["path"]):
            LOCAL_GRAPHS.append(graph)
        # External repos, vendor SDKs, shared libs are external
        else:
            EXTERNAL_GRAPHS.append(graph)
```

#### Graph Selection Strategy

```python
def select_relevant_graphs(query, available_graphs, explicit_graph=None):
    """
    Determine which graphs to query based on the query and context.

    Priority:
    1. Explicit --graph parameter (user override)
    2. Query-driven relevance matching
    3. Default graph as baseline
    """

    # User explicitly specified graph(s)
    if explicit_graph:
        if explicit_graph == "all":
            return [g for g in available_graphs["docs"] if g["available"]]
        elif "," in explicit_graph:
            names = [n.strip() for n in explicit_graph.split(",")]
            return [g for g in available_graphs["docs"] if g["name"] in names and g["available"]]
        else:
            return [g for g in available_graphs["docs"] if g["name"] == explicit_graph and g["available"]]

    # Auto-select based on query relevance
    selected = []

    # Always include default graph
    default_graph = next((g for g in available_graphs["docs"] if g["name"] == "default"), None)
    if default_graph and default_graph["available"]:
        selected.append(default_graph)

    # Check domain-to-graph mapping for targeted selection
    if DOMAIN_REGISTRY:
        graph_domain_map = map_graphs_to_domains(available_graphs, DOMAIN_REGISTRY)
        query_domains = infer_domains_from_query(query, DOMAIN_LOOKUP)
        for graph in available_graphs["docs"]:
            if graph["name"] in graph_domain_map and graph_domain_map[graph["name"]] in query_domains:
                if graph not in selected and graph["available"]:
                    selected.append(graph)
                    print(f"   📎 Including '{graph['name']}' (domain match: {graph_domain_map[graph['name']]})")

    # Check other graphs for relevance
    for graph in available_graphs["docs"]:
        if graph["name"] == "default":
            continue
        if not graph["available"]:
            continue

        # Match query against graph metadata
        relevance_score = compute_relevance(query, graph)
        if relevance_score > 0.3:  # Threshold for inclusion
            selected.append(graph)
            print(f"   📎 Including '{graph['name']}' (relevance: {relevance_score:.2f})")

    return selected

def compute_relevance(query, graph):
    """
    Score how relevant a graph is to the query.
    Uses graph name, description, and source_url.
    """
    query_lower = query.lower()
    score = 0.0

    # Check graph name
    if graph["name"].lower() in query_lower:
        score += 0.5

    # Check description keywords
    description = graph.get("description", "").lower()
    query_words = query_lower.split()
    for word in query_words:
        if len(word) > 3 and word in description:
            score += 0.2

    # Check source_url for org/repo hints
    source_url = graph.get("source_url", "").lower()
    for word in query_words:
        if len(word) > 3 and word in source_url:
            score += 0.1

    return min(score, 1.0)
```

#### Local vs External Graph Handling

**Critical Distinction**:

| Graph Type | FlowSpace Tools | Traditional Tools | File Access |
|------------|-----------------|-------------------|-------------|
| **Local** (default, in-project) | ✓ tree, search, get_node | ✓ Glob, Grep, Read | ✓ Direct |
| **External** (shared libs, vendor) | ✓ tree, search, get_node | ✗ NOT available | ✗ None |

```python
def query_graph(graph, query, query_type):
    """
    Query a graph with appropriate tools based on locality.
    """
    is_local = graph["name"] == "default" or is_path_local(graph["path"])

    if FLOWSPACE_AVAILABLE:
        # Use FlowSpace for all graphs
        return query_with_flowspace(query, query_type, graph_name=graph["name"])

    elif is_local:
        # Fallback to traditional tools for LOCAL graphs only
        print(f"ℹ️ Using traditional tools for local graph: {graph['name']}")
        return query_with_traditional_tools(query, query_type)

    else:
        # CANNOT query external graphs without FlowSpace
        print(f"⚠️ Cannot query external graph '{graph['name']}' without FlowSpace")
        print(f"   External graphs require FlowSpace MCP (no local file access)")
        return None
```

---

### 1.6) Domain Context Loading

Before executing research, check for an existing domain system to enrich findings with domain provenance.

```python
# Load domain registry if available
DOMAIN_REGISTRY = None
DOMAIN_MAP = None

if file_exists("docs/domains/registry.md"):
    DOMAIN_REGISTRY = read_file("docs/domains/registry.md")
    print("📂 Domain registry loaded — findings will be tagged with domain origin")

    if file_exists("docs/domains/domain-map.md"):
        DOMAIN_MAP = read_file("docs/domains/domain-map.md")

    # Build path → domain lookup from registry entries
    DOMAIN_LOOKUP = build_domain_path_lookup(DOMAIN_REGISTRY)
    # e.g. {"src/auth/": "auth", "src/billing/": "billing", "src/_platform/data-access/": "_platform/data-access"}
else:
    DOMAIN_LOOKUP = {}
    print("ℹ️ No domain registry — findings reported without domain tags")

def tag_finding_with_domain(finding):
    """Tag a finding with its owning domain based on file path."""
    file_path = finding.get("file") or finding.get("node", {}).get("file_path", "")
    for prefix, domain in DOMAIN_LOOKUP.items():
        if file_path.startswith(prefix):
            finding["domain"] = domain
            return
    finding["domain"] = None  # No domain match
```

#### Domain-to-Graph Mapping

When both domains and multiple graphs are available, map graphs to domains for targeted research:

```python
def map_graphs_to_domains(available_graphs, domain_registry):
    """
    Build graph → domain associations.
    External graphs often correspond to specific domains
    (e.g., 'auth-lib' graph → 'auth' domain).
    """
    graph_domain_map = {}
    for graph in available_graphs["docs"]:
        if not graph["available"]:
            continue
        # Match by graph name/description against domain slugs
        for domain_slug in extract_domain_slugs(domain_registry):
            if domain_slug in graph["name"].lower() or domain_slug in graph.get("description", "").lower():
                graph_domain_map[graph["name"]] = domain_slug
    return graph_domain_map
```

---

### 2) Query Type Detection

Automatically detect query type to select optimal FlowSpace tools:

```python
def detect_query_type(query):
    """
    3-stage heuristic pipeline for query classification.
    Returns: 'path' | 'symbol' | 'concept'
    """

    # Stage 1: PATH detection (highest priority)
    # Queries containing "/" are path patterns
    if "/" in query:
        return "path"

    # Queries with file extensions
    if re.match(r'.*\.(py|ts|js|md|json|yaml|yml|go|rs|java)$', query):
        return "path"

    # Stage 2: SYMBOL detection
    # CapitalCase (class names): AuthService, UserRepository, ConfigManager
    if re.match(r'^[A-Z][a-zA-Z0-9]*$', query):
        return "symbol"

    # snake_case with no spaces (function/method names): validate_user, get_config
    if re.match(r'^[a-z][a-z0-9_]*$', query) and len(query) < 40:
        return "symbol"

    # Prefixed queries: "class Calculator", "def validate_user", "function main"
    if re.match(r'^(class|def|function|method|interface|type)\s+', query, re.I):
        return "symbol"

    # Stage 3: CONCEPT detection (fallback)
    # Natural language with spaces, question words, or multiple words
    return "concept"

# Debug output for transparency
query_type = detect_query_type(query)
print(f"🔍 Query type detected: {query_type}")
print(f"   Query: \"{query}\"")
```

**Override**: Use `--mode <type>` to force a specific detection mode.

---

### 3) Exploration Workflow

Execute exploration based on detected query type, tool availability, and selected graphs.

**If FLOWSPACE_AVAILABLE**: Use FlowSpace tools (tree, search, get_node) across all selected graphs
**If NOT FLOWSPACE_AVAILABLE**: Use traditional tools (Glob, Grep, Read) for LOCAL graphs only

```python
# Main exploration loop - query each selected graph
all_findings = []

for graph in selected_graphs:
    print(f"🔍 Searching graph: {graph['name']}")

    findings = query_graph(graph, query, query_type)
    if findings:
        for finding in findings:
            finding["source_graph"] = graph["name"]  # Tag with source
            tag_finding_with_domain(finding)          # Tag with domain origin
        all_findings.extend(findings)

# Merge and deduplicate findings across graphs
merged_findings = merge_cross_graph_findings(all_findings, limit=limit)
```

---

#### 3.0) Traditional Tools Fallback Workflow

When FlowSpace is unavailable, use these equivalent patterns with Glob/Grep/Read:

##### PATH Queries (Traditional)

```python
# For queries like "src/auth/", "config.py"
if query.endswith("/"):
    # Folder exploration - list directory contents
    files = Glob(pattern=f"{query}**/*")
    # Read key files (README, index, main entry points)
    for file in prioritize_entry_points(files):
        content = Read(file_path=file)
        findings.append({"file": file, "content": content})
else:
    # Specific file/pattern match
    files = Glob(pattern=f"**/{query}")
    for file in files[:limit]:
        content = Read(file_path=file)
        findings.append({"file": file, "content": content})
```

##### SYMBOL Queries (Traditional)

```python
# For queries like "AuthService", "validate_user"
# Use Grep to find symbol definitions

# Search for class/function definitions
patterns = [
    f"class {query}",           # Python/JS class
    f"def {query}",             # Python function
    f"function {query}",        # JS function
    f"const {query}",           # JS const
    f"interface {query}",       # TypeScript interface
    f"type {query}",            # TypeScript type
]

for pattern in patterns:
    matches = Grep(
        pattern=pattern,
        output_mode="content",
        glob="*.{py,ts,js,tsx,jsx,go,rs,java}",
        context_lines=10  # Show surrounding context
    )
    if matches:
        findings.extend(parse_grep_results(matches))

# Also search for usages
usages = Grep(
    pattern=query,
    output_mode="files_with_matches",
    limit=limit * 2
)
```

##### CONCEPT Queries (Traditional)

```python
# For queries like "authentication flow", "error handling"
# Use Grep with broader text matching

# Split concept into keywords
keywords = extract_keywords(query)  # e.g., ["authentication", "flow"]

# Search for files containing keywords
for keyword in keywords:
    matches = Grep(
        pattern=keyword,
        output_mode="files_with_matches",
        glob="*.{py,ts,js,md,go,rs}"  # Include docs
    )
    keyword_files[keyword] = matches

# Prioritize files matching multiple keywords
ranked_files = rank_by_keyword_overlap(keyword_files)

# Read top files and extract relevant sections
for file in ranked_files[:limit]:
    content = Read(file_path=file)
    relevant_sections = extract_sections_matching(content, keywords)
    findings.append({
        "file": file,
        "sections": relevant_sections,
        "keyword_matches": count_matches(content, keywords)
    })
```

---

#### 3.1) FlowSpace Exploration Workflow

**Prerequisite**: FLOWSPACE_AVAILABLE == True

Execute exploration based on detected query type:

##### PATH Queries (FlowSpace)

For queries like `"src/auth/"`, `"config.py"`:

```python
# Use tree() with folder navigation pattern
# IMPORTANT: Trailing "/" for folder contents
# NOTE: Pass graph_name for multi-graph support
if query.endswith("/"):
    # Folder exploration - show contents
    results = flowspace.tree(
        pattern=query,
        max_depth=2,         # Show immediate children + one level
        detail="min",        # Fast, compact output
        format="text",       # Token-efficient
        graph_name=current_graph["name"]  # Multi-graph support
    )
else:
    # Specific file/pattern - find matching nodes
    results = flowspace.tree(
        pattern=query,
        max_depth=0,         # Unlimited - find all matches
        detail="max",        # Include AI summaries for understanding
        graph_name=current_graph["name"]  # Multi-graph support
    )

# Apply scope filtering if provided
if scope_filter:
    results = filter_by_scope(results, scope_filter)
```

##### SYMBOL Queries (FlowSpace)

For queries like `"AuthService"`, `"validate_user"`:

```python
# Use tree() for symbol discovery
# NOTE: Pass graph_name for multi-graph support
results = flowspace.tree(
    pattern=query,
    detail="max",            # Include AI summaries and signatures
    format="text",
    graph_name=current_graph["name"]  # Multi-graph support
)

# If tree returns matches, get full source for top results
if results["count"] > 0:
    # Extract node_ids from tree results
    # IMPORTANT: Node IDs are opaque - use verbatim, never reconstruct
    top_nodes = extract_node_ids(results, limit=limit)

    for node_id in top_nodes:
        node_detail = flowspace.get_node(
            node_id=node_id,
            detail="max",
            graph_name=current_graph["name"]  # Must use same graph!
        )
        if node_detail:
            findings.append(node_detail)
```

##### CONCEPT Queries (FlowSpace)

For queries like `"authentication flow"`, `"error handling patterns"`:

```python
# Use search() with semantic mode (preferred) or text fallback
# NOTE: Pass graph_name for multi-graph support
try:
    results = flowspace.search(
        pattern=query,
        mode="semantic",     # Conceptual similarity via embeddings
        limit=limit,
        detail="min",        # Fast initial discovery
        graph_name=current_graph["name"]  # Multi-graph support
    )
    search_mode_used = "semantic"
except Exception as e:
    if "Embeddings not found" in str(e):
        print(f"ℹ️ Semantic search unavailable in '{current_graph['name']}', using text matching")
        results = flowspace.search(
            pattern=query,
            mode="text",     # Substring matching fallback
            limit=limit * 2, # Increase limit since text is less precise
            detail="min",
            graph_name=current_graph["name"]  # Multi-graph support
        )
        search_mode_used = "text"
    else:
        raise

# Get detailed info for top results
top_results = results["results"][:limit]
for result in top_results:
    node_detail = flowspace.get_node(
        node_id=result["node_id"],
        detail="max",
        graph_name=current_graph["name"]  # Must use same graph!
    )
    findings.append({
        "score": result.get("score", 0),
        "node": node_detail,
        "source_graph": current_graph["name"]  # Track provenance
    })
```

---

### 4) Semantic Search with Fallback

**Always implement try-catch for semantic search**:

```python
def search_with_fallback(query, limit, include_patterns=None, exclude_patterns=None):
    """
    Attempt semantic search, fallback to text mode if embeddings unavailable.
    Returns: (results, mode_used)
    """

    search_params = {
        "pattern": query,
        "limit": limit,
        "detail": "min"
    }

    # Apply scope filters if provided
    if include_patterns:
        search_params["include"] = include_patterns
    if exclude_patterns:
        search_params["exclude"] = exclude_patterns

    # Try semantic first (best for concept queries)
    try:
        search_params["mode"] = "semantic"
        results = flowspace.search(**search_params)
        return results, "semantic"

    except Exception as e:
        if "Embeddings not found" in str(e) or "embeddings" in str(e).lower():
            # Graceful fallback to text mode
            print("""
            ℹ️ Semantic search unavailable (embeddings not configured)
               Switched to text matching for: "{query}"
               For better conceptual results: fs2 scan --embed (requires Azure/OpenAI API)
            """)
            search_params["mode"] = "text"
            search_params["limit"] = limit * 2  # Compensate for lower precision
            results = flowspace.search(**search_params)
            return results, "text"
        else:
            # Re-raise unexpected errors
            raise
```

---

### 5) Scope Filtering

Apply include/exclude filters to narrow results:

```python
def apply_scope_filters(include_patterns, exclude_patterns):
    """
    Filtering logic for FlowSpace search:
    - include: OR logic (match ANY include pattern)
    - exclude: AND logic (exclude ALL matching patterns)

    Example: --include "src/" --include "lib/" --exclude "test"
    Result: (matches src/ OR lib/) AND NOT (matches test)
    """

    # Include patterns use OR logic
    # If multiple includes: file must match at least ONE
    include_param = include_patterns if include_patterns else None

    # Exclude patterns use AND logic
    # If multiple excludes: file must NOT match ANY
    exclude_param = exclude_patterns if exclude_patterns else None

    return {
        "include": include_param,
        "exclude": exclude_param
    }

# Usage in search
filters = apply_scope_filters(
    include_patterns=["src/.*", "lib/.*"],
    exclude_patterns=["test.*", ".*_test\\.py", ".*\\.spec\\."]
)

results = flowspace.search(
    pattern=query,
    mode="semantic",
    limit=limit,
    **filters
)
```

---

### 6) Structured Output Generation

Generate output suitable for parent orchestrator synthesis:

```markdown
## Research Findings: [QUERY]

**Metadata**:
- Query: "[original query]"
- Query Type: [path | symbol | concept]
- Tool Mode: [FlowSpace | Traditional (Glob/Grep/Read)]
- Search Mode: [semantic | text | tree | grep]
- FlowSpace: [Available | Unavailable - using fallback]
- Graphs Queried: [list of graph names searched]
- Graphs Available: [total available] ([local count] local, [external count] external)
- Domains Loaded: [list of domain slugs from registry, or "None — no registry"]
- Results: [N] findings (limit: [M])
- Scope: [include patterns] | All
- Excluded: [exclude patterns] | None

---

### Summary

[2-3 sentence overview of what was found]

---

### Key Nodes Discovered

| # | Graph | Domain | Node ID | Type | Name | Lines | Purpose |
|---|-------|--------|---------|------|------|-------|---------|
| 1 | [graph_name] | [domain or —] | `[node_id]` | [class/callable/file] | [name] | [start-end] | [smart_content or snippet] |
| 2 | ... | ... | ... | ... | ... | ... | ... |

---

### Code Excerpts

#### Finding 1: [Name]
**Graph**: [graph_name] ([local|external])
**Domain**: [domain slug or "—" if unmatched]
**Node ID**: `[full node_id for follow-up get_node calls]`
**Location**: [file:start_line-end_line]
**Purpose**: [smart_content if available, else inferred purpose]

```[language]
[relevant code excerpt, max 20 lines]
```

#### Finding 2: [Name]
[...continue for top findings...]

---

### Relationships

**Depends On** (imports/calls discovered):
- [node_id or file:line reference]
- ...

**Depended On By** (consumers discovered):
- [node_id or file:line reference]
- ...

---

### Gaps & Questions

[Things that couldn't be determined from codebase exploration]

- [Question or gap 1]
- [Question or gap 2]

---

**Research Complete**: [timestamp]
```

---

## Examples

### Example 1: Symbol Query
```
/flowspace-research "AuthService"
```
Finds classes/functions named AuthService, returns detailed node info with code excerpts.

### Example 2: Concept Query with Scope
```
/flowspace-research "authentication and authorization flow" --scope "src/" --exclude "test"
```
Semantic search for auth-related code, limited to src/ directory, excluding tests.

### Example 3: Path Query
```
/flowspace-research "src/services/" --limit 20
```
Lists contents of src/services/ directory with structure overview.

### Example 4: Forced Mode
```
/flowspace-research "config" --mode concept --limit 5
```
Forces concept mode even though "config" looks like a symbol, useful for finding configuration-related code broadly.

### Example 5: Query Specific External Graph
```
/flowspace-research "RedisCache" --graph "cache-lib"
```
Searches only the `cache-lib` external graph for RedisCache implementation. Useful when you know which shared library contains the code.

### Example 6: Query All Available Graphs
```
/flowspace-research "authentication patterns" --graph "all"
```
Searches across ALL available graphs (default + all configured external graphs). Returns findings from multiple codebases, tagged by source graph.

### Example 7: Query Multiple Specific Graphs
```
/flowspace-research "ConfigService" --graph "default,shared-lib,vendor-sdk"
```
Searches specific graphs by name. Useful when you want to compare implementations across known repositories.

### Example 8: Auto-Select Relevant Graphs (Default)
```
/flowspace-research "caching strategy"
```
Without `--graph`, automatically selects relevant graphs based on query matching against graph names, descriptions, and source URLs. Always includes `default` graph, plus any external graphs deemed relevant.

### Example 9: Domain-Scoped Query
```
/flowspace-research "payment processing" --scope "src/billing/"
```
When `docs/domains/` exists, findings are tagged with their owning domain (e.g., `billing`). Useful for verifying code stays within domain boundaries.

### Example 10: Cross-Domain Dependency Discovery
```
/flowspace-research "auth token validation" --graph "all"
```
Searches all graphs and tags each finding with its domain origin. Reveals cross-domain dependencies (e.g., `billing` code calling into `auth` domain).

---

## Error Handling

### FlowSpace Not Available (Graceful Fallback)

```
ℹ️ FlowSpace MCP not available - using traditional tools (Glob/Grep/Read)

Research will continue with standard file search tools. Results may lack:
- AI-generated code summaries
- Semantic/conceptual search
- Structured node relationships

For enhanced exploration, install FlowSpace:
  1. Install fs2: uvx --from git+https://github.com/AI-Substrate/flow_squared fs2 install
  2. Initialize: fs2 init
  3. Scan codebase: fs2 scan
```

### Graph Not Indexed (Graceful Fallback)

```
ℹ️ FlowSpace graph not found - using traditional tools (Glob/Grep/Read)

The codebase hasn't been scanned by FlowSpace. Falling back to Glob/Grep/Read.

To enable FlowSpace for future searches:
  fs2 scan

For semantic search (concept queries):
  fs2 scan --embed
```

### No Results Found

```
ℹ️ No results found for query: "[query]"

Suggestions:
- Try a broader query
- Check spelling of symbol names (case-sensitive)
- Use --mode concept for natural language queries
- Verify --scope filter isn't too restrictive
```

### Semantic Search Unavailable

```
ℹ️ Semantic search unavailable (embeddings not configured)
   Switched to text matching for: "[query]"

For better conceptual results:
  fs2 scan --embed (requires Azure/OpenAI API configuration)
```

---

## FlowSpace Tool Reference

### list_graphs()
- **Purpose**: Discover all available graphs (local + external)
- **Returns**: Dict with `docs` (list of graphs) and `count`
- **Graph fields**:
  - `name`: Identifier (use with `graph_name` parameter)
  - `path`: Path to graph pickle file
  - `description`: Human-readable description
  - `source_url`: URL to source repository (optional)
  - `available`: Boolean - whether graph file exists and is loadable
- **Example**:
  ```python
  result = list_graphs()
  for graph in result["docs"]:
      print(f"{graph['name']}: {graph.get('description', 'No description')}")
  ```

### tree(pattern, max_depth, detail, format, graph_name)
- **Purpose**: Navigate codebase structure hierarchically
- **Pattern types**:
  - `"."` - All nodes
  - `"src/services/"` - Folder contents (trailing `/`)
  - `"AuthService"` - Symbol name match
  - `"*.py"` - Glob pattern
- **Detail**: `"min"` (fast) | `"max"` (includes AI summaries)
- **Format**: `"text"` (compact) | `"json"` (structured)
- **graph_name**: Target graph from `list_graphs()`. Default: local project graph.

### search(pattern, mode, limit, include, exclude, detail, graph_name)
- **Purpose**: Find code by content or meaning
- **Modes**:
  - `"text"` - Substring matching (always available)
  - `"regex"` - Regular expression (always available)
  - `"semantic"` - Conceptual similarity (requires embeddings)
  - `"auto"` - FlowSpace selects best mode
- **Filters**: `include`/`exclude` are regex patterns for paths
- **graph_name**: Target graph from `list_graphs()`. Default: local project graph.

### get_node(node_id, detail, graph_name)
- **Purpose**: Retrieve full source code for a specific node
- **node_id**: Opaque identifier from tree() or search() - use verbatim
- **graph_name**: **MUST match the graph where node_id was found!**
- **Returns**: CodeNode with content, signature, metadata, or null if not found

---

## Traditional Tools Reference (Fallback)

When FlowSpace is unavailable, these tools provide equivalent functionality:

### Glob(pattern, path)
- **Purpose**: Find files matching a pattern
- **Equivalent to**: `flowspace.tree()` for path queries
- **Pattern examples**:
  - `"**/*.py"` - All Python files
  - `"src/**/*"` - All files under src/
  - `"**/AuthService*"` - Files with AuthService in name
- **Returns**: List of matching file paths

### Grep(pattern, output_mode, glob, path)
- **Purpose**: Search file contents for patterns
- **Equivalent to**: `flowspace.search()` for symbol/concept queries
- **Key parameters**:
  - `pattern`: Regex or literal string to find
  - `output_mode`: `"content"` (with context) or `"files_with_matches"`
  - `glob`: File pattern filter (e.g., `"*.py"`)
  - `-C`: Context lines before/after match
- **Returns**: Matching lines with file locations

### Read(file_path, offset, limit)
- **Purpose**: Read file contents
- **Equivalent to**: `flowspace.get_node()` for retrieving source code
- **Returns**: File content with line numbers

### Mapping FlowSpace → Traditional

| FlowSpace | Traditional Equivalent |
|-----------|----------------------|
| `tree(pattern="src/")` | `Glob(pattern="src/**/*")` |
| `tree(pattern="AuthService")` | `Glob(pattern="**/*AuthService*")` + `Grep(pattern="class AuthService")` |
| `search(mode="text", pattern="auth")` | `Grep(pattern="auth", output_mode="files_with_matches")` |
| `search(mode="semantic", pattern="authentication")` | `Grep(pattern="auth\|login\|credential", ...)` (keyword expansion) |
| `get_node(node_id)` | `Read(file_path)` with line range extraction |

---

## Local vs External Graphs

### Understanding Graph Locality

**Local Graphs**: Graphs where the source files are directly accessible on the filesystem.
- The `default` graph is always local (current working directory)
- Graphs with paths inside your project directory are local
- **Both FlowSpace AND traditional tools work**

**External Graphs**: Graphs from other repositories, shared libraries, or vendor SDKs.
- Files are NOT on the local filesystem
- Configured via `other_graphs` in `.fs2/config.yaml`
- **ONLY FlowSpace tools work** (no Glob/Grep/Read access)

### Determining Locality

```python
def is_graph_local(graph):
    """
    Determine if a graph has local file access.
    """
    # Default graph is always local
    if graph["name"] == "default":
        return True

    # Check if graph path is within current working directory
    graph_path = Path(graph["path"]).resolve()
    cwd = Path.cwd().resolve()

    try:
        graph_path.relative_to(cwd)
        return True  # Path is inside cwd
    except ValueError:
        return False  # Path is outside cwd

    # Also check if source files exist locally
    # (graph might be in .fs2/graphs/ but source is external)
```

### Fallback Implications

| Scenario | FlowSpace Available | FlowSpace Unavailable |
|----------|---------------------|----------------------|
| **Local graph** | Use FlowSpace (preferred) | Use Glob/Grep/Read (fallback) |
| **External graph** | Use FlowSpace (required) | ⚠️ **CANNOT QUERY** - skip graph |

### Error Handling for External Graphs

```
⚠️ Cannot query external graph 'vendor-sdk' without FlowSpace

External graphs require FlowSpace MCP because their source files
are not on the local filesystem.

Options:
1. Install and configure FlowSpace MCP
2. Clone the external repository locally and add as local graph
3. Skip this graph and search only local graphs
```

---

## Best Practices for Parent Orchestrators

When invoking this command as a subagent:

1. **Use specific queries**: "AuthService" is better than "auth stuff"
2. **Set appropriate limits**: `--limit 5` for parallel subagents to keep context bounded
3. **Scope when possible**: `--scope "src/"` reduces noise
4. **Parse structured output**: Node IDs can be passed to subsequent get_node() calls
5. **Handle semantic fallback**: Results may be less precise if text mode was used
6. **Check Tool Mode in output**: The metadata shows whether FlowSpace or Traditional tools were used
7. **Expect equivalent results**: Both tool modes produce the same structured output format, but Traditional mode may lack AI summaries and semantic search

### Multi-Graph Best Practices

8. **Check "Graphs Queried" in output**: Shows which graphs were actually searched
9. **Use `--graph` for targeted searches**: When you know which library contains the code, specify it directly
10. **Review cross-graph findings**: Best answers may come from external graphs (shared libs, vendor SDKs)
11. **Note graph locality in findings**: External graph findings cannot be followed up with traditional tools
12. **Pass graph_name with node_id**: When using get_node() for follow-up, always include the source graph
