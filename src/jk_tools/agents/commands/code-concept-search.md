---
description: Find a concept in the codebase by walking through code like a human engineer — even when it's named differently than expected. Returns provenance, usage, and reuse assessment.
---

Please deep think / ultrathink as this is a nuanced search and exploration task.

# code-concept-search

Find a **concept** in the codebase — a pattern, a capability, a component, a method — even when the codebase names it something completely different from what you expect. Returns factual findings with provenance (which plan created it, who modified it, why it exists) so callers can make informed reuse decisions.

**Key Characteristics**:
- **IS the worker** (does NOT launch subagents)
- **FlowSpace-first** with multi-tier fallback
- **Walks the codebase like a human engineer** when FlowSpace is unavailable — reads, follows flows, reasons about what's related
- **Provenance-aware** — traces each finding back through plans, execution logs, and git history
- **Concise output** — all the facts, no filler

---

## Input Parameters

```
$ARGUMENTS
# Required:
#   <concept>            What to find (positional, required)
#
# Optional:
#   --scope <path>       Limit search to path (e.g., "src/services/")
#   --exclude <pattern>  Exclude paths matching pattern (e.g., "test,vendor")
#   --limit <N>          Max findings to return (default: 5)
#   --provenance         Include full plan provenance for each finding (default: true)
#   --no-provenance      Skip provenance lookup (faster, for quick checks)
#
# Examples:
#   /code-concept-search "rate limiter"
#   /code-concept-search "connectNode" --scope "src/graph/"
#   /code-concept-search "logger" --no-provenance
#   /code-concept-search "authentication middleware"
#   /code-concept-search "token bucket" --exclude "test,docs"
```

---

## Execution Flow

### 1) Understand the Concept

Before searching, reason about the concept to guide exploration:

```
Given concept: "<CONCEPT>"

Think:
- What KIND of thing is this? (class, function, pattern, service, utility, data structure)
- What DOMAIN does it belong to? (auth, graph, networking, UI, data processing, logging)
- What PROBLEM does it solve? (connecting things, caching, validating, transforming)
- What NAMES might it have? (not synonyms from a thesaurus — names a developer would actually use)
- What PATTERNS typically implement this? (middleware, decorator, factory, singleton, strategy)
- Where in a typical project would this LIVE? (services/, utils/, middleware/, core/, lib/)
```

This reasoning step is critical. It turns a keyword search into a directed exploration.

### 2) FlowSpace Detection

```python
try:
    flowspace.tree(pattern=".", max_depth=1)
    FLOWSPACE_AVAILABLE = True

    try:
        flowspace.search(pattern="test", mode="semantic", limit=1)
        SEMANTIC_AVAILABLE = True
    except:
        SEMANTIC_AVAILABLE = False

except:
    FLOWSPACE_AVAILABLE = False
    SEMANTIC_AVAILABLE = False
```

### 3) Search (Tiered)

Execute the appropriate search tier based on available tools. **Try each tier in order. Stop when you have sufficient results.**

---

#### Tier 1: FlowSpace Semantic Search (best)

**Prerequisite**: FLOWSPACE_AVAILABLE and SEMANTIC_AVAILABLE

```python
results = flowspace.search(
    pattern=concept,
    mode="semantic",
    limit=limit * 2,  # Over-fetch, filter later
    detail="max"
)

# Also search with decomposed terms if concept is multi-word
if " " in concept:
    for term in concept.split():
        more = flowspace.search(pattern=term, mode="semantic", limit=5)
        results.extend(more)

# Get full source for top results
for result in deduplicate(results)[:limit]:
    node = flowspace.get_node(node_id=result["node_id"], detail="max")
    findings.append(node)
```

Semantic search finds conceptually related code even when names differ completely. This is the only tier that can find "elementConnector" from a query of "connectNode" without decomposition.

---

#### Tier 2: FlowSpace Text + Tree (semantic unavailable)

**Prerequisite**: FLOWSPACE_AVAILABLE, not SEMANTIC_AVAILABLE

```python
# Search by the concept terms
results = flowspace.search(pattern=concept, mode="text", limit=limit * 3)

# Also search by decomposed terms
terms = decompose_concept(concept)  # "connectNode" → ["connect", "node"]
for term in terms:
    more = flowspace.search(pattern=term, mode="text", limit=10)
    results.extend(more)

# Use tree to find symbols in likely directories
likely_dirs = identify_likely_directories(concept)  # From step 1 reasoning
for dir in likely_dirs:
    tree_results = flowspace.tree(pattern=dir, max_depth=2, detail="max")
    # Scan tree output for related symbols
```

Better than raw grep because FlowSpace indexes symbols and understands code structure. But still string matching — won't find semantic synonyms.

---

#### Tier 3: Codebase Walk-Through (no FlowSpace)

**Prerequisite**: FLOWSPACE not available. This is the critical tier.

**Do NOT just grep for synonyms.** Walk the codebase like a human engineer would:

**Phase A: Orient — understand the project structure**
```
1. Read top-level directory listing (ls or Glob at root)
2. Identify relevant directories based on step 1 reasoning:
   - What domain does the concept belong to? Find that domain's directory.
   - Where would this kind of thing typically live? (services/, utils/, middleware/, core/)
3. Read any README, index, or __init__ files in candidate directories
4. Build a mental map of the project's architecture from what you see
```

**Phase B: Explore — follow the flow**
```
5. For each candidate directory:
   a. List its contents (Glob)
   b. Read filenames — do any suggest the concept? (not just exact match —
      a file called "throttle.py" IS a rate limiter)
   c. Read the most promising files — scan for classes, functions, patterns
      that DO what the concept DOES, regardless of what they're CALLED
   d. Follow imports — if you find something adjacent, trace where it comes
      from and what else uses it
   e. Read docstrings, comments, type signatures — these often describe the
      concept in plain English even when the code name is opaque

6. If the concept is workflow-related or architectural:
   a. Follow the request/data flow from entry point
   b. Read middleware chains, pipeline stages, event handlers
   c. Trace the execution path — the concept might be embedded in a larger
      flow rather than being a standalone component
```

**Phase C: Verify — confirm or rule out candidates**
```
7. For each candidate found:
   a. Read the full implementation (not just the signature)
   b. Does it actually do what the concept describes? (not just name similarity)
   c. Check its consumers — who calls it? This reveals its actual role.
   d. Check its scope — is it general-purpose or tightly coupled to one feature?

8. If nothing found after exploring obvious locations:
   a. Try broader Grep for the concept's VERB (what it does: "connect", "limit", "cache")
   b. Read the results in context — follow up on anything promising
   c. Check if the concept might be handled by an external library instead of custom code
```

**Phase D: Targeted Grep (last resort within Tier 3)**
```
9. If walk-through hasn't found it, fall back to targeted searches:
   a. Grep for class/function definitions with concept terms:
      - Decompose: "connectNode" → ["connect", "node"]
      - Grep: "class.*[Cc]onnect", "def.*connect", "function.*connect"
      - Grep: "class.*[Nn]ode", "class.*[Ll]ink", "class.*[Ww]ire"
   b. Grep for common implementation patterns:
      - "rate limiter" → grep for "token.bucket", "sliding.window", "throttl", "rate.limit"
      - "logger" → grep for "getLogger", "createLogger", "OutputChannel", "winston", "pino"
      - "cache" → grep for "TTL", "LRU", "invalidat", "memoiz"
   c. Search docs/ and comments for the concept in plain English
```

The key insight: **the agent's reasoning IS the search engine**. Grep is just one tool the agent uses while walking through code. The agent reads, thinks, follows leads, and makes judgments — exactly like a human engineer.

---

#### Tier 4: Confirm Not Found

If all tiers return nothing:
```
Report:
- Concept: "<CONCEPT>"
- Search mode: [which tiers were attempted]
- Directories explored: [list]
- Grep patterns tried: [list]
- Result: No matching concept found in codebase
- Assessment: Safe to create — no existing implementation to reuse or conflict with
```

This is a **valid and useful result**. Confirming absence is as valuable as finding presence.

---

### 4) Provenance Lookup (unless --no-provenance)

For each concept found, trace its history through the plan system:

```
For each finding:

1. ORIGIN PLAN:
   - Extract file path from the finding
   - Search docs/plans/*/execution.log.md for the file path
     (grep both absolute and relative forms; paths may be backtick-wrapped)
   - Search docs/plans/*-plan.md task tables for the path in Absolute Path(s) columns
   - If file lives in features/<ordinal>-<slug>/ (PlanPak): the ordinal IS the origin plan
   - Fallback: git log --follow --diff-filter=A -- <filepath> for creation commit

2. MODIFICATION HISTORY:
   - Same sources as origin, collect ALL plan references
   - git log --oneline -- <filepath> for commit history

3. WHY IT EXISTS:
   - Find the execution log entry for the task that created it
   - Extract the "What I Did" or "Changes Made" section
   - This gives the rationale — why was this built, what problem did it solve?

4. ORIGINAL INTENT:
   - Read the plan's spec (docs/plans/<ordinal>-<slug>/<slug>-spec.md) for the feature goals
   - Read the plan's task description that created this file — what was the task trying to achieve?
   - Read any relevant ADR that governed the design choice
   - Synthesize into a paragraph: what was the plan's intent for this code?
     What role was it meant to play? What constraints was it designed under?
   - This lets the caller check vibe alignment — "am I about to use this for
     something the original author never intended?"

5. CURRENT CONSUMERS:
   - Grep for imports/requires of the file or symbol
   - Count how many files use this concept
   - Note if usage is concentrated (one feature) or widespread (shared utility)
```

### 5) Generate Output

```markdown
## Concept Search: "<CONCEPT>"

**Query**: <original concept>
**Search mode**: <FlowSpace semantic | FlowSpace text | Codebase walk-through | Targeted grep>
**Scope**: <path filter or "全 codebase">
**Results**: <N> concept(s) found

---

### 1. <SymbolName> — <file:line>

**Match quality**: <Exact | Strong | Related | Weak>
**What it is**: <class | function | module | pattern | service>
**What it does**: <1-2 sentence factual description of what this code does>
**Signature**: `<function/class signature>`

**Provenance**:
- **Created by**: Plan <NNN>-<slug> (T<XXX>) | Pre-plan | Unknown
- **Modified by**: Plan <NNN> (T<XXX>), Plan <MMM> (T<YYY>) | None
- **Why it exists**: <1-2 sentences from execution log explaining the rationale>

**Original intent**: <Paragraph describing what the originating plan intended this
  code to do. What role does it play in the feature? What problem was it designed
  to solve? What constraints or design decisions shaped it? Sourced from the plan
  spec, task description, and any governing ADR. This is the "vibe check" — does
  your intended use align with why this was built?>

**Usage**: <N> files import/call this
**Scope**: <General-purpose utility | Feature-specific | Tightly coupled>

**Reuse assessment**: <1-2 sentences — is this appropriate for the caller's purpose?
  Factor in the original intent: if the caller's use diverges from the original
  design intent, flag that as a risk even if the code technically works. Consider:
  is it general enough? Is it in the right layer? Would extending it preserve or
  break the original intent?>

---

### 2. <SymbolName> — <file:line>
[Same structure...]

---

### No Further Matches

<If fewer than limit results: briefly note what was searched and why no more were found>
```

---

## Output Rules

- **Factual, not verbose**: Every sentence must convey a fact. No filler, no hedging, no "it appears that."
- **All findings ranked**: Best match first, weakest last
- **Match quality labels**:
  - **Exact**: Name matches the concept directly
  - **Strong**: Different name but clearly implements the same concept
  - **Related**: Adjacent concept — might be reusable with modification
  - **Weak**: Tangentially related — noted for awareness, not reuse
- **Provenance included by default**: Skip only with `--no-provenance`
- **Reuse assessment is opinionated**: The command should say "yes, reuse this" or "no, this is too coupled" — not "it depends"
- **Cap at limit results**: Default 5. Caller can increase if needed.

---

## Decomposition Helper

When breaking a concept into searchable terms:

```python
def decompose_concept(concept):
    """
    Break a concept into searchable components.

    "connectNode"  → ["connect", "node"]
    "rate limiter" → ["rate", "limiter"]
    "AuthService"  → ["auth", "service"]
    "token_bucket" → ["token", "bucket"]
    """
    # Split on spaces
    if " " in concept:
        return [w.lower() for w in concept.split() if len(w) > 2]

    # Split camelCase: "connectNode" → ["connect", "Node"]
    parts = re.findall(r'[A-Z]?[a-z]+|[A-Z]+(?=[A-Z]|$)', concept)

    # Split snake_case: "token_bucket" → ["token", "bucket"]
    if "_" in concept:
        parts = concept.split("_")

    return [p.lower() for p in parts if len(p) > 2]
```

This is used for targeted grep patterns, NOT as the primary search strategy. The primary strategy is the human-like walk-through.

---

## Integration Points

This command is designed to be called by:
- **Flight Plan subagent** (plan-5/5a step 5a/4a): duplication check for new files
- **plan-1a-explore**: codebase research subagents checking for existing implementations
- **Direct user invocation**: "does this thing already exist before I build it?"
- **plan-6**: mid-implementation discovery when agent encounters a concept that might exist elsewhere

When called as a subagent, the structured output format allows parent commands to parse findings programmatically.

---

## Examples

### Example 1: Specific method
```
/code-concept-search "connectNode"
```
Walks graph-related directories, finds `GraphBuilder.link()` and `NodeLinker.batch_connect()`.

### Example 2: Broad concept
```
/code-concept-search "rate limiter"
```
Checks middleware/, services/, utils/ for throttling patterns. Finds `TokenBucket` class in utils/throttle.py.

### Example 3: Scoped search
```
/code-concept-search "authentication middleware" --scope "src/api/"
```
Walks only src/api/, follows middleware chain, finds `AuthGuard` decorator.

### Example 4: Quick existence check
```
/code-concept-search "redis cache adapter" --no-provenance
```
Fast check — skips plan history lookup. Just reports if the concept exists and where.

### Example 5: Nothing found
```
/code-concept-search "GraphQL subscription handler"
```
Walks codebase, finds no GraphQL infrastructure. Reports: "No matching concept found. Safe to create."

### Example 6: Workflow walk-through
```
/code-concept-search "plan ordinal counter"
```
Finds scripts/ directory, reads plan-related scripts, follows the ordinal management flow through setup.sh → install/agents.sh → discovers plan-ordinal logic. Traces back to Plan 011-cross-branch-plan-ordinal.
