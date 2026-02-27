# Workshop: Domain Self-Documentation (Concepts as Internal SDK)

**Type**: Data Model + Integration Pattern
**Plan**: 016-domain-concepts
**Created**: 2026-02-27
**Status**: Draft

**Related Documents**:
- [domain-system-design.md](./domain-system-design.md) — domain model, registry, contracts
- [domain-map.md](./domain-map.md) — domain relationships and topology validation
- [plan-v2-extract-domain.md](../../../agents/v2-commands/plan-v2-extract-domain.md) — brownfield extraction
- [plan-6-v2-implement-phase.md](../../../agents/v2-commands/plan-6-v2-implement-phase.md) — implementation + domain updates

**Validated Against**: Real domain.md files from `chainglass-048/docs/domains/` (12 domains including _platform/events, _platform/state, file-browser)

---

## Purpose

Make every domain **self-documenting** — a mini internal SDK that publishes its concepts so other domains can discover, understand, and consume them without reading source code. Today domain.md captures *what* a domain IS (boundary, contracts table, composition). This workshop adds *what it OFFERS* — a concept catalog with entry points, narratives, and usage examples.

The design principle: **domains are well-documented Lego blocks**. Each block publishes what it does, how to use it, and how to plug it together with other blocks. This prevents concept reinvention, accelerates discovery, and gives coding agents a structured index to search before falling through to source code.

## Key Questions Addressed

- What goes in the new Concepts section and where does it sit in domain.md?
- What format serves rapid concept identification by both humans and agents?
- How do plan commands create and maintain concept documentation?
- How does this improve anti-reinvention and code-concept-search?

---

## 1. The Problem: Contracts Without Context

Looking at real domains like `_platform/events` (13 contracts) and `_platform/state` (12 contracts), the Contracts table tells you *that* `useFileChanges` exists. It does **not** tell you:

- When would I use this vs. building my own file watcher?
- What's the entry point — do I wrap my component in a provider first?
- What pattern does it follow — hook, service, event subscription?
- How does it relate to the other 12 contracts in this domain?

The Contracts table is a parts list. What's missing is the **concept guide** — grouping related contracts into capabilities and explaining what each capability does for a consumer.

### What Good Looks Like

A developer (or coding agent) searching for "how do I react to file changes in the browser" opens `_platform/events/domain.md`, sees the Concepts table right after Purpose, and finds:

```
| Concept | Entry Point | What It Does |
|---------|-------------|-------------|
| File change subscription | `useFileChanges` | Subscribe to real-time file changes by glob pattern |
```

Then reads the narrative section below:

> **File change subscription**: Components that need live file change events use `useFileChanges('src/**')`. Wrap your workspace page in `<FileChangeProvider>` first. The hook returns `{ changes, hasChanges, clearChanges }`.

**10 seconds to discovery. No source code reading required.**

---

## 2. The Concepts Section

### Placement in domain.md

```
# Domain: [Name]

**Slug** / **Type** / **Created** / **Status**

## Purpose                    ← Why this domain exists
## Concepts                   ← NEW: What this domain offers (consumer-facing)
## Boundary                   ← What it owns / doesn't own
## Contracts (Public Interface) ← Formal contract table
## Composition (Internal)     ← Internal lego blocks
## Source Location            ← Where files live
## Dependencies               ← What it needs / who needs it
## History                    ← Plan changelog
```

**Rationale**: Concepts immediately after Purpose. A consumer arrives asking "what does this domain offer?" — Purpose says *why* it exists, Concepts says *what it offers*. Boundary and Contracts are structural details that matter after you've identified the concept you need.

### Format: Table + Narrative

The Concepts section has two parts:

**Part 1: Scannable table** — every concept as a row for rapid discovery:

```markdown
## Concepts

| Concept | Entry Point | What It Does |
|---------|-------------|-------------|
| Central event routing | `ICentralEventNotifier` | Route domain events to SSE channels for browser delivery |
| File change subscription | `useFileChanges` | Subscribe to real-time file changes by glob pattern |
| SSE connection management | `useSSE` | Manage EventSource connections with auto-reconnect |
| Toast notifications | `toast()` | Show success/error/info toasts from any component |
| Domain event adapter | `DomainEventAdapter<T>` | Template for building server-side event adapters |
| File change hub | `FileChangeHub` | Client-side pattern-based event dispatcher |
```

**Part 2: Narrative per concept** — each concept gets a subsection with description and short code example:

```markdown
### Central event routing

Server-side domain events need to reach the browser in real-time. Instead of each domain building its own WebSocket/SSE plumbing, emit events through the central notifier and they arrive at browser hooks automatically.

​```typescript
import { ICentralEventNotifier } from '@domains/events';

// In your domain's event adapter:
notifier.emit('workflows', 'structure-changed', { workflowId, timestamp });
// Browser-side: useWorkspaceSSE('workflows') receives it
​```

### File change subscription

Components that need live file system updates subscribe by glob pattern. Wrap your page in `<FileChangeProvider>` to establish the SSE connection, then use `useFileChanges` in any descendant.

​```tsx
import { FileChangeProvider, useFileChanges } from '@domains/events';

// In a workspace page:
<FileChangeProvider workspaceSlug={slug}>
  <MyComponent />
</FileChangeProvider>

// In MyComponent:
const { changes, hasChanges, clearChanges } = useFileChanges('src/');
// changes: array of { path, type } since last clear
​```

### Toast notifications

One-line fire-and-forget notifications. Client-side only — server actions return a result, the client calls toast.

​```typescript
import { toast } from '@domains/events';

toast.success('File saved');
toast.error('Save failed: conflict detected');
​```
```

### Rules

1. **Every concept that a consumer might search for gets a row** — not just the "top 3." If the domain offers it, document it.
2. **Entry Point is the contract or function a consumer imports** — the starting point for using this concept.
3. **Code examples are short** — import + basic call. 3-5 lines. Show the happy path, not edge cases.
4. **Concepts group related contracts** — "File change subscription" groups `useFileChanges`, `FileChangeProvider`, and `FileChangeHub` under one concept. The Contracts table lists them individually; Concepts tells the story.
5. **Language matches the project** — use whatever language/framework the codebase uses. TypeScript/React examples for a Next.js project, Python for a Django project, etc.

---

## 3. Real-World Example: _platform/state

Here's what the Concepts section would look like for the existing `_platform/state` domain:

```markdown
## Concepts

| Concept | Entry Point | What It Does |
|---------|-------------|-------------|
| Read a single state value | `useGlobalState<T>` | Subscribe a React component to one state path |
| Read multiple state values | `useGlobalStateList` | Subscribe to all values matching a path pattern |
| Publish runtime state | `IStateService.publish()` | Set a value at a state path, notify subscribers |
| Register a domain | `IStateService.registerDomain()` | Declare what your domain publishes (name, properties, multi-instance) |
| Multi-instance state | Path addressing | Publish per-instance values like `worktree:abc123:dirtyFiles` |
| Pattern subscription | `createStateMatcher` | Match paths by wildcard (`domain:*:property` or `domain:**`) |
| Testing state | `FakeGlobalStateSystem` | Test double with inspection: getPublished(), wasPublishedWith() |

### Read a single state value

Components that need one runtime value from another domain subscribe by path. The hook re-renders only when that specific value changes.

​```tsx
import { useGlobalState } from '@domains/state';

function WorkflowStatus({ workflowId }: { workflowId: string }) {
  const status = useGlobalState<string>(`workflow:${workflowId}:status`, 'idle');
  return <Badge>{status}</Badge>;
}
​```

### Publish runtime state

Domains publish their runtime values so other domains can subscribe without importing publisher code. Register your domain first, then publish values to named paths.

​```typescript
import { IStateService } from '@domains/state';

// At domain initialization:
stateService.registerDomain({
  name: 'worktree',
  multiInstance: true,
  properties: ['dirtyFiles', 'activeFile', 'lastSaved']
});

// During runtime:
stateService.publish(`worktree:${worktreeId}:dirtyFiles`, 3);
​```

### Testing state

Use `FakeGlobalStateSystem` in tests — it implements the full `IStateService` interface with inspection methods.

​```typescript
import { FakeGlobalStateSystem } from '@domains/state';

const fake = new FakeGlobalStateSystem();
fake.publish('worktree:abc:dirtyFiles', 5);
expect(fake.wasPublishedWith('worktree:abc:dirtyFiles', 5)).toBe(true);
​```
```

---

## 4. Minimum Viable Concepts vs. Full Concepts

### Level 1 (Minimum — required when contracts exist)

```markdown
## Concepts

| Concept | Entry Point | What It Does |
|---------|-------------|-------------|
| [one row per concept] | [contract/function] | [one line] |
```

Just the table. Enough for an agent to scan and identify "this concept exists here." No narratives.

**~5-15 lines depending on number of concepts.**

### Level 2 (Working — grows during active development)

Table + narrative subsections with code examples for each concept.

**~30-100 lines depending on concept count.**

### Growth Rule

> Start at Level 1 (table only). Every plan that touches a domain's contracts should add narrative subsections for the concepts it changes. High-traffic domains naturally reach Level 2 as consumers ask questions that become documentation.

---

## 5. Command Integration

### Which Commands Create/Update Concepts

| Command | Creates? | Updates? | What It Does |
|---------|----------|----------|-------------|
| `/extract-domain` | ✅ L1 table | — | Generates Concepts table from discovered contracts. Groups related contracts into concepts. |
| `/plan-6-v2` | ✅ if new domain | ✅ if contracts change | Adds concepts for new contracts. Updates narratives for changed contracts. Adds code examples from actual implementation. |
| `/plan-6a-v2` | — | Flags needed | Notes "Concepts section update needed" when contract changes recorded. |
| `/plan-7-v2` | — | ❌ (validates) | Checks Concepts section exists for domains with contracts. Flags ⚠️ Review if missing. |
| `/plan-5-v2` | — | ❌ (reads) | References concept names in Context Brief domain dependencies. |

### 5a. extract-domain Changes

After Step 3 (Workshop with user), the agent has:
- Subagent 1 output: discovered files with roles
- Subagent 2 output: public interfaces with consumers
- User confirmation of boundary

**New Step 3.5: Identify Concepts**

Group discovered contracts into concepts:
- Related contracts that serve one consumer use case = one concept
- Name each concept as a verb phrase ("Subscribe to file changes", "Authenticate a user")
- Identify the primary entry point (the contract a consumer imports first)

**Step 4a (updated)**: Write domain.md with Concepts section between Purpose and Boundary.

### 5b. plan-6-v2 Changes

After implementation, add to the domain file update checklist:

```
4) After ALL tasks complete — update domain files:

   [existing a-g unchanged]

   h) **Update domain.md § Concepts** (if contracts changed or new domain):

      For NEW domains:
        - Create Level 1 Concepts table from implemented contracts
        - Group related contracts into named concepts
        - Add narrative + code example for each concept (base on actual implemented code)

      For CHANGED contracts:
        - Add new concepts to table if new capabilities introduced
        - Update existing concept narratives if entry points changed
        - Update code examples to match new signatures

      For UNCHANGED contracts: no Concepts updates needed.
```

### 5c. plan-6a-v2 Changes

When recording domain changes in progress updates:

```
6) Record changes with domain context:
   [existing bullets unchanged]
   
   - If contract changes recorded → flag "domain.md § Concepts update needed for <domain>"
```

### 5d. plan-5-v2 Changes

In the Context Brief, when listing domain dependencies, reference concept names:

```
**Domain dependencies** (contracts this phase consumes):
- `_platform/events`: File change subscription (useFileChanges) — live file updates in tree
- `_platform/state`: Read single state value (useGlobalState) — workflow status display
```

Using the concept name (not just the contract name) gives the implementor richer context.

### 5e. plan-7-v2 Changes

Add to the Domain Compliance Validator:

```
Existing 9-point checklist + new item:

10. **Concepts documentation**: Domains with contracts have a § Concepts section
    - Level 1 minimum: table with Concept, Entry Point, What It Does
    - New contracts added in this phase appear in the Concepts table
    - Severity: ⚠️ Review (not ❌ violation — documentation is advisory)
```

---

## 6. code-concept-search Integration

The biggest payoff: `/code-concept-search` gains a structured index to search before falling through to source code.

### Enhanced Search Order

```
1. Scan docs/domains/*/domain.md § Concepts tables
   → Match concept name, entry point, or "what it does" column
   → FOUND (high confidence — documented, named, with entry point)

2. Scan docs/domains/*/domain.md § Contracts tables  
   → Match contract name or description
   → FOUND (medium confidence — exists but may lack usage guidance)

3. Fall through to source code search (existing behavior)
   → FOUND (low confidence — might be internal, might be reusable)
```

### Example: Agent Searching for "file changes"

```
🔍 Searching for concept: "file changes"

📦 Domain Concept Match (high confidence):
  Domain: _platform/events
  Concept: File change subscription
  Entry Point: useFileChanges
  What It Does: Subscribe to real-time file changes by glob pattern

  Usage:
    import { useFileChanges } from '@domains/events';
    const { changes, hasChanges } = useFileChanges('src/');

  Assessment: REUSE — this capability exists and is documented.
```

**Without Concepts tables**: Agent searches source code, finds `useFileChanges.ts`, reads implementation, infers usage. Takes minutes.

**With Concepts tables**: Agent greps `## Concepts` sections across all domain.md files, finds the row in <1 second. Done.

---

## 7. Updated domain.md Template

The complete domain.md section order becomes:

```markdown
# Domain: [Name]

**Slug**: [kebab-case]
**Type**: business | infrastructure
**Created**: [ISO-8601]
**Created By**: [plan or extraction]
**Status**: active | deprecated | archived

## Purpose

[1-3 sentences: Why does this domain exist?]

## Concepts

[What this domain offers to consumers. Scannable table + narrative per concept.]

| Concept | Entry Point | What It Does |
|---------|-------------|-------------|
| [verb phrase] | [contract/function] | [one line description] |

### [Concept Name]

[2-3 sentences: When would a consumer use this? What's the pattern?]

​```[language]
import { EntryPoint } from '@domains/[slug]';
// 3-5 line usage example
​```

## Boundary

### Owns
- [concept list]

### Does NOT Own
- [boundary clarifications]

## Contracts (Public Interface)

| Contract | Type | Consumers | Description |
|----------|------|-----------|-------------|

## Composition (Internal)

| Component | Role | Depends On |
|-----------|------|------------|

## Source Location

Primary: `[path]`

| File | Role | Notes |
|------|------|-------|

## Dependencies

### This Domain Depends On
### Domains That Depend On This

## History

| Plan | What Changed | Date |
|------|-------------|------|
```

**Required sections** (plan-7 validates):
- Purpose
- Concepts (⚠️ Review if missing when contracts exist)
- Boundary (Owns + Does NOT Own)
- Contracts
- Composition
- Source Location
- History

---

## 8. Concepts vs. Contracts vs. Boundary: What Goes Where

| Information | Section | Why There |
|-------------|---------|-----------|
| "This domain offers file change subscriptions" | **Concepts** | Consumer discovery — what's available |
| "`useFileChanges` is a React hook consumed by file-browser" | **Contracts** | Structural tracking — formal interface list |
| "This domain owns the SSE pipeline, not business events" | **Boundary** | Ownership clarity — what's in/out |
| "FileChangeHub dispatches events to pattern subscribers" | **Composition** | Internal structure — how it works inside |
| "To subscribe, wrap in FileChangeProvider, then call useFileChanges" | **Concepts narrative** | Usage guidance — how to use it |

**The litmus test**: Concepts answers "what can I do with this domain?" Contracts answers "what are the formal interfaces?" Boundary answers "what does this domain own?"

---

## Resolved Questions

### Q1: Separate sdk.md or inline in domain.md?
**RESOLVED**: Inline in domain.md as a `## Concepts` section. Keeps one file per domain. The Concepts section is lightweight enough (table + narratives) that it doesn't bloat domain.md, and having everything in one place reduces maintenance.

### Q2: How many concepts to document?
**RESOLVED**: All concepts that a consumer might search for — not just a "top 3." If the domain offers it, document it.

### Q3: Should concepts include code examples?
**RESOLVED**: Yes — one short code block per concept showing the import + basic call. 3-5 lines, happy path only.

### Q4: Should code-concept-search use Concepts tables?
**RESOLVED**: Yes — scan all domain.md Concepts tables as the first search layer before falling through to source code. This makes concept discovery near-instant.

### Q5: Should plan-7 enforce Concepts?
**RESOLVED**: Required if contracts exist — flagged as ⚠️ Review if missing. Not a hard violation since documentation quality is advisory.

### Q6: What should extract-domain focus on?
**RESOLVED**: Concepts and entry points, not code signatures. The coding agent can discover implementation details easily; it needs to identify concepts rapidly.

---

## Summary: What Changes

| Artifact | Change | Impact |
|----------|--------|--------|
| domain.md template | Add `## Concepts` section after Purpose | Every domain becomes self-documenting with concept catalog |
| Section order | Purpose → **Concepts** → Boundary → Contracts → ... | Consumers find what they need immediately |
| `extract-domain` | Step 3.5: identify concepts; Step 4a: write Concepts section | Initial concept catalog created during extraction |
| `plan-5-v2` Context Brief | Reference concept names for domain dependencies | Implementors get named concepts, not just contract names |
| `plan-6-v2` post-implementation | Step h: update/create Concepts when contracts change | Concepts stay current as domain evolves |
| `plan-6a-v2` progress updates | Flag "Concepts update needed" on contract changes | No contract change goes undocumented |
| `plan-7-v2` code review | Checklist item 10: Concepts section exists if contracts exist | Documentation validated during review |
| `code-concept-search` | Search Concepts tables first, then Contracts, then source | Near-instant concept discovery across all domains |
| Anti-reinvention | All 3 layers strengthened by structured concept index | Features table = searchable capability catalog |
