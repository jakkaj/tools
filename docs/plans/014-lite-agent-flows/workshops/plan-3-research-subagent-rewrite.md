# Workshop: Plan-3 Research Subagent Rewrite

**Type**: Integration Pattern
**Plan**: 014-lite-agent-flows
**Spec**: [lite-agent-flows-spec.md](../lite-agent-flows-spec.md)
**Created**: 2026-02-20T05:05:00Z
**Status**: Draft

**Related Documents**:
- [Research Dossier — GAP 2](../research-dossier.md) (plan-3→flowspace-research critical gap)
- Full plan-3: `agents/commands/plan-3-architect.md` (lines 167-302: current subagents)
- Full plan-1a: `agents/commands/plan-1a-explore.md` (lines 407-500: Standard Mode pattern to reuse)

---

## Purpose

Design the research subagent prompts for lite `plan-3-architect.md` that replace the `/flowspace-research` invocations with standard tools (grep, glob, view). The rewrite must preserve research quality while using only universally available codebase exploration tools.

## Key Questions Addressed

- Q1: What research quality is acceptable for lite?
- Q2: Can we reuse plan-1a's Standard Mode subagent pattern?
- Q3: How many subagents should lite plan-3 use?
- Q4: Should lite subagents do sequential or parallel exploration?

---

## Current State: Full Plan-3 Research Subagents

### Architecture (4 Parallel Subagents)

```
┌──────────────────────────────────────────────────────┐
│              plan-3-architect (orchestrator)          │
│                                                      │
│  Read spec → Launch 4 parallel research subagents    │
└──────┬───────────┬───────────┬───────────┬───────────┘
       │           │           │           │
       ▼           ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ S1:      │ │ S2:      │ │ S3:      │ │ S4:      │
│ Codebase │ │ Technical│ │ Discovery│ │ Dep      │
│ Pattern  │ │ Investi- │ │ Documen- │ │ Mapper   │
│ Analyst  │ │ gator    │ │ ter      │ │          │
├──────────┤ ├──────────┤ ├──────────┤ ├──────────┤
│ Phase 1: │ │ Phase 1: │ │ Phase 1: │ │ Phase 1: │
│ /flow-   │ │ /flow-   │ │ /flow-   │ │ /flow-   │
│ space-   │ │ space-   │ │ space-   │ │ space-   │
│ research │ │ research │ │ research │ │ research │
├──────────┤ ├──────────┤ ├──────────┤ ├──────────┤
│ Phase 2: │ │ Phase 2: │ │ Phase 2: │ │ Phase 2: │
│ Analysis │ │ Analysis │ │ Analysis │ │ Analysis │
│ framework│ │ framework│ │ framework│ │ framework│
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```

### Current Subagent Details

| # | Name | Purpose | FlowSpace Queries | Fallback Tools |
|---|------|---------|-------------------|---------------|
| S1 | Codebase Pattern Analyst | Conventions, integration points, existing patterns | Domain-specific pattern search | Glob + Grep for patterns |
| S2 | Technical Investigator | API limits, framework constraints, gotchas | Error handling & constraint search | Grep for validation/error patterns |
| S3 | Discovery Documenter | Spec ambiguities, implications, edge cases | Edge case & error pattern search | Grep for error handling patterns |
| S4 | Dependency Mapper | Dependencies, boundaries, cross-cutting concerns | Import & architecture search | Grep for imports & boundaries |

### Output Format (per subagent)

Each produces 8-15 numbered findings:

```markdown
### S1-01: [Finding Title]
**Category**: Pattern | Constraint | Risk | Dependency
**Impact**: High | Medium | Low
**Evidence**: file:path:line

**What**: [Description of the finding]
**Why it matters**: [Impact on implementation]
**Example**: [Code snippet or reference]
**Action**: [What to do about it]
```

---

## Plan-1a Standard Mode Pattern (The Template)

Plan-1a-explore already has a proven non-FlowSpace research pattern (lines 407-500). It uses 7 subagents with standard tools:

```
┌──────────────────────────────────────────────────────┐
│          plan-1a-explore Standard Mode                │
│                                                      │
│  7 parallel subagents, each using:                   │
│    • Glob — find relevant files by pattern           │
│    • Grep — search for content patterns              │
│    • View/Read — examine key files in detail         │
│                                                      │
│  Each subagent:                                      │
│    1. Targets specific search locations/keywords     │
│    2. Flags knowledge gaps for /deepresearch         │
│    3. Produces 8-15 findings with file:line refs     │
│    4. Deduplicates and prioritizes by impact         │
└──────────────────────────────────────────────────────┘
```

### Key Pattern Elements

1. **Structured search targets**: Each subagent has specific file patterns and keywords
2. **External research detection**: Flag gaps code can't answer → ready-to-use `/deepresearch` prompts
3. **Volume + diversity**: Multiple perspectives on the same codebase produce comprehensive coverage
4. **Synthesis layer**: After all subagents complete, findings are deduplicated and prioritized

---

## Proposed Design: Lite Plan-3 Research Subagents

### Architecture: 4 Parallel Subagents (Same Roles, Standard Tools)

```
┌──────────────────────────────────────────────────────┐
│         lite plan-3-architect (orchestrator)          │
│                                                      │
│  Read spec → Launch 4 parallel research subagents    │
│  (same roles as full, standard tools only)           │
└──────┬───────────┬───────────┬───────────┬───────────┘
       │           │           │           │
       ▼           ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ S1:      │ │ S2:      │ │ S3:      │ │ S4:      │
│ Codebase │ │ Technical│ │ Discovery│ │ Dep      │
│ Pattern  │ │ Investi- │ │ Documen- │ │ Mapper   │
│ Analyst  │ │ gator    │ │ ter      │ │          │
├──────────┤ ├──────────┤ ├──────────┤ ├──────────┤
│ Tools:   │ │ Tools:   │ │ Tools:   │ │ Tools:   │
│ • glob   │ │ • grep   │ │ • grep   │ │ • grep   │
│ • grep   │ │ • view   │ │ • view   │ │ • glob   │
│ • view   │ │ • glob   │ │ • glob   │ │ • view   │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
```

### Subagent Prompt Templates

#### S1: Codebase Pattern Analyst

```markdown
Map the implementation patterns relevant to [FEATURE_TOPIC].

**Use standard tools:**
- Glob to find source files matching the feature domain
- Grep to search for naming conventions, existing patterns, similar implementations
- View to examine key files and understand code structure

**Tasks:**
1. Find files related to the feature domain (glob for relevant extensions/paths)
2. Identify coding conventions (naming, error handling, logging patterns)
3. Locate existing similar features or integration points
4. Map the file organization pattern (where new code should live)
5. Note any existing tests and testing patterns

**Output**: 8-12 findings (S1-01 through S1-12) with file:line references.
Each finding: Category, Impact, Evidence, What, Why, Action.
```

#### S2: Technical Investigator

```markdown
Identify technical constraints and risks for implementing [FEATURE_TOPIC].

**Use standard tools:**
- Grep to search for error handling, validation, configuration patterns
- View to read key configuration files, API definitions, schema files
- Glob to find test files, CI configs, dependency manifests

**Tasks:**
1. Check dependency versions and constraints (package.json, requirements.txt, etc.)
2. Find API boundaries, rate limits, authentication patterns
3. Identify framework-specific gotchas (version-specific behaviors)
4. Review error handling patterns and expected error formats
5. Check for environment-specific configuration requirements

**Output**: 6-10 findings (S2-01 through S2-10) with file:line references.
Each finding: Category, Impact, Evidence, What, Why, Action.
```

#### S3: Discovery Documenter

```markdown
Analyze the spec for [FEATURE_TOPIC] and identify implementation gaps.

**Use standard tools:**
- Grep to find existing handling of edge cases mentioned in spec
- View to read related test files and understand expected behavior
- Glob to find documentation, READMEs, and architecture notes

**Tasks:**
1. For each acceptance criterion, check if similar logic already exists
2. Identify edge cases the spec doesn't explicitly cover
3. Find validation rules and data constraints in existing code
4. Check for existing error messages and user-facing strings
5. Note any spec assumptions that conflict with actual code

**Output**: 6-10 findings (S3-01 through S3-10) with file:line references.
Each finding: Category, Impact, Evidence, What, Why, Action.
```

#### S4: Dependency Mapper

```markdown
Map the dependency graph and architectural boundaries for [FEATURE_TOPIC].

**Use standard tools:**
- Grep to trace import statements, function calls, and module references
- Glob to find all files in target directories
- View to understand module interfaces and public APIs

**Tasks:**
1. Map imports: what does the target code import? What imports it?
2. Identify shared state (databases, caches, config, global variables)
3. Find cross-cutting concerns (auth, logging, metrics, middleware)
4. Check for circular dependencies or tight coupling
5. Map the test dependency graph (what test utilities exist)

**Output**: 6-10 findings (S4-01 through S4-10) with file:line references.
Each finding: Category, Impact, Evidence, What, Why, Action.
```

### Synthesis Step (After All 4 Complete)

```markdown
## Research Synthesis

After all 4 subagents report:

1. **Deduplicate**: Merge findings that describe the same thing from different angles
2. **Prioritize**: Sort by impact (High > Medium > Low)
3. **Group**: Organize into categories:
   - Architecture Decisions (inform plan structure)
   - Implementation Constraints (inform task details)
   - Testing Requirements (inform validation criteria)
   - Risks & Mitigations (inform risk section)
4. **External Gaps**: Collect any "needs external research" flags →
   suggest /deepresearch to user if significant gaps found
5. **Feed into plan generation**: Use prioritized findings as input
   to phase planning, task decomposition, and acceptance criteria
```

---

## Comparison: Full vs Lite Research

| Aspect | Full (FlowSpace) | Lite (Standard Tools) |
|--------|-------------------|----------------------|
| **Tool** | `/flowspace-research` → semantic search, tree nav, node retrieval | grep, glob, view |
| **Search quality** | Semantic (finds conceptually related code) | Lexical (finds exact text matches) |
| **Coverage** | Can discover non-obvious connections | Finds what you know to search for |
| **Speed** | Fast (pre-indexed graph) | Fast (ripgrep is very fast) |
| **Setup required** | fs2 scan + embeddings | None |
| **Subagent count** | 4 | 4 (same) |
| **Findings per agent** | 8-15 | 6-12 (slightly lower — lexical search misses some) |
| **Total findings** | 32-60 | 24-48 |
| **False positives** | Low (semantic understanding) | Medium (grep matches irrelevant code) |

### Quality Mitigation Strategies

The lite version compensates for lack of semantic search with:

1. **Targeted glob patterns**: Each subagent specifies file patterns relevant to its domain (e.g., `**/*.test.*`, `**/config.*`, `**/middleware.*`)
2. **Multi-keyword grep**: Instead of one semantic query, use 3-5 targeted greps per research question
3. **View for context**: Read entire key files rather than relying on snippet extraction
4. **Cross-subagent diversity**: 4 different perspectives ensure breadth even if individual depth is lower
5. **External research escalation**: When grep can't answer a question, flag it for `/deepresearch` rather than guessing

---

## What Gets Removed from Full Plan-3

### Lines to Strip (FlowSpace-specific)

| Line Range | Content | Action |
|------------|---------|--------|
| 167-175 | "FlowSpace Evidence Gathering (Hybrid Approach)" heading + intro | Replace with "Research Evidence Gathering" |
| 182-186 | S1 Phase 1: `/flowspace-research` invocation | Replace with grep/glob/view instructions |
| 188 | S1 fallback: "Use Glob to find similar files" | Promote to primary approach |
| 224-228 | S2 Phase 1: `/flowspace-research` invocation | Replace with grep/glob/view instructions |
| 230 | S2 fallback | Promote to primary |
| 265-269 | S3 Phase 1: `/flowspace-research` invocation | Replace with grep/glob/view instructions |
| 271 | S3 fallback | Promote to primary |
| 298-302 | S4 Phase 1: `/flowspace-research` invocation | Replace with grep/glob/view instructions |
| 304 | S4 fallback | Promote to primary |
| 812-813 | `{flowspace-node-id}` footnote format | Remove |
| 1184-1440 | FlowSpace Graph Traversal Guide appendix (~256 lines) | Remove entirely |

### Net Change

- **Remove**: ~280 lines of FlowSpace-specific content
- **Add**: ~60 lines of expanded grep/glob/view instructions per subagent
- **Net reduction**: ~220 lines from plan-3

---

## Resolved Questions

### Q1: What research quality is acceptable for lite?

**RESOLVED**: 24-48 findings (vs 32-60 full) is acceptable. The lite pipeline targets CS-1 to CS-3 features where the codebase surface area is smaller and lexical search is usually sufficient. For CS-4+ features requiring semantic code understanding, users should use the full pipeline.

### Q2: Can we reuse plan-1a's Standard Mode subagent pattern?

**RESOLVED**: Yes, partially. The core pattern is identical:
- Glob to find files → Grep to search content → View to read details → Produce numbered findings

The difference is **focus**: plan-1a subagents research "what exists" (exploratory), while plan-3 subagents research "what we need to build" (implementation-focused). The tool usage pattern transfers directly; the task instructions need plan-3-specific objectives (constraints, dependencies, architecture boundaries).

### Q3: How many subagents should lite plan-3 use?

**RESOLVED**: 4 subagents (same as full). The roles are well-decomposed:
- Pattern Analyst = "how does the code work?"
- Technical Investigator = "what could go wrong?"
- Discovery Documenter = "what's missing from the spec?"
- Dependency Mapper = "what connects to what?"

Fewer subagents would lose a perspective. More would add overhead without proportional value for CS-1-3 features.

### Q4: Should lite subagents do sequential or parallel exploration?

**RESOLVED**: **Parallel**. The 4 subagents are independent — no subagent needs another's output. Parallel execution is:
- Faster (wall-clock time)
- Already the pattern in both plan-1a Standard Mode and full plan-3
- Well-supported by agent infrastructure (task tool with multiple agents)

---

## Implementation Notes for Lite Plan-3

When extracting plan-3-architect for lite:

1. **Lines 167-302**: Replace the entire "FlowSpace Evidence Gathering" section with the 4 subagent templates above. The section heading becomes "Research Evidence Gathering".

2. **Each subagent prompt**: The existing fallback instructions (lines 188, 230, 271, 304) are already written for grep/glob/view. Promote these to the primary instructions and expand with the structured templates above.

3. **Synthesis step**: Keep the existing synthesis logic (dedup, prioritize, group). Just remove FlowSpace-specific references.

4. **Graph Traversal Guide** (lines 1184-1440): Remove entirely. This appendix teaches agents how to navigate FlowSpace node IDs — irrelevant without FlowSpace.

5. **Output format**: Keep the same S1-01, S2-01, etc. numbered finding format. Only change is the "Evidence" field uses `file:path:line` instead of FlowSpace node references.

### Prompt Insertion Point

The lite subagent prompts replace lines 167-302 in plan-3. The surrounding structure stays:

```
[Lines 1-166: Entry gate, spec reading, context gathering — KEEP]
[Lines 167-302: REPLACE with lite subagent prompts above]
[Lines 303-400: PlanPak + testing strategy — STRIP PlanPak, simplify testing]
[Lines 401+: Plan generation — KEEP with modifications per other workshop]
```
