# Workshop: Universal Retro Contract — JSON Schema, Cross-System

**Type**: Data Model
**Plan**: 023-difficulty-ledger-skill
**Spec**: [difficulty-ledger-skill-spec.md](../difficulty-ledger-skill-spec.md)
**Created**: 2026-05-16
**Status**: Draft

**Value Thesis**: A retro is a first-class concept already used by three independent systems — `minih` (every agent run emits one), `compound` (the ledger consumes them), and `jakkaj/tools` scripts + skills (ad-hoc retros from various places). Today each system invents its own shape: minih's `retrospective.json` flat schema, compound's planned YAML-fenced-markdown typed-entries shape, plan-6a's farewell-envelope harvest. **One unified contract** — JSON Schema as the formal definition, markdown-with-YAML-frontmatter as the wire format, system-specific extensions in a namespaced `system.*` field — makes the three systems compatible without breaking any of them. Without this workshop, every cross-system call sites translates ad-hoc, mappings drift, and any new consumer has to learn three shapes. With it, there is one contract; everyone reads the same thing; minih becomes a first-class compound producer rather than a special-cased read-source.

**Target Proof Level**: Contract Ready
**Current Proof Level**: Decision Space → Contract Ready (workshop output)

**Selected Value Axes**:
- **Cross-Domain Coordination**: three systems (`compound`, `minih`, `jakkaj/tools` other skills) need to interoperate; the schema IS the inter-system contract — without it, every call site translates ad-hoc
- **Safety to Change**: a versioned schema with explicit extension points lets each system evolve without forcing a synchronized release; system-specific fields live in namespaces, so minih can add fields without compound caring (and vice versa)
- **Implementation Readiness**: plan-3-architect needs an executable schema to feed plan-5 task design — this workshop emits a literal `retro.schema.json` file that plan-3 references
- **Knowability**: today, "what's in a retro" depends on which file you're looking at — minih's report.json, compound's `<plan-slug>.md`, plan-6a's farewell envelope. After this workshop, "what's in a retro" is one document with one schema
- **Migration Safety**: minih's existing `retrospective.json` has live consumers; the universal contract MUST round-trip cleanly to/from minih's existing shape so adoption can be incremental (dual-write phase, then drop legacy)

**Related Documents**:
- [Workshop 002 — End-to-end flow](./002-end-to-end-flow.md) — defines lifecycle states (open → suggested → encoded → verified → wontfix → dismissed → stale); this workshop locks the schema for those states as a system-specific namespace
- [Workshop 003 — Compound system map](./003-compound-system-map.md) — integration surfaces table assumes a schema exists; this workshop writes it
- [Workshop 004 — SDD ↔ compound integration](./004-sdd-pipeline-compound-integration.md) — per-skill integration matrix uses compound-1-track entries; this workshop defines what an entry IS
- Minih `retrospective.json` schema: `/Users/jordanknight/substrate/minih/src/schemas/retrospective.json` (current minih shape — input to round-trip mapping)
- Spec § Non-Goals: "Not a minih importer in v1" — this workshop EXPANDS that line; importer is now in v1 via the universal schema (mapping rules in § Round-Trip Mappings)

**Domain Context** (no formal `docs/domains/` registry in this repo):
- **Primary scope**: schema contract that crosses three systems
- **Owned by**: jakkaj/tools (initial home — see D3); migrating to a shared `@ai-substrate/retro-schema` package in v2 (deferred)

---

## Purpose

Define a single, versioned, machine-readable contract for what a "retrospective" (retro) IS, such that the three independent systems currently producing or consuming retro-shaped artifacts — `minih`, `compound`, `jakkaj/tools` ad-hoc scripts/skills — speak the same language. The contract is expressed as JSON Schema (formal); the wire format is markdown-with-YAML-frontmatter (human-readable, machine-parseable); system-specific concerns live in namespaced extensions (`system.minih`, `system.compound`) so neither system has to know about the other's lifecycle.

## Fresh Entrant Outcome

A fresh implementer (or `plan-3-v2-architect`, or a minih maintainer reading the cross-coordination RFC) should be able to use this workshop to reach **Contract Ready** with no additional context.

They should be able to:

- Read the JSON Schema and know exactly what fields a retro contains, which are required, which are optional
- Map an existing minih `retrospective.json` to a universal retro deterministically (and back)
- Map a compound `_session-buffer.md` entry to a universal retro entry deterministically
- Add a new system-specific field by extending the `system.<name>` namespace without breaking either compound or minih readers
- Write a valid retro file by hand using the wire-format example, and have a JSON Schema validator accept it
- Reference any retro entry globally via the `<retro_id>:<entry_id>` scheme

## Key Questions Addressed

1. **What IS a retro?** The full field surface (worked-well? confusion? magic-wand? difficulties? gifts? insights? coordination? improvement-suggestions?)
2. JSON Schema vs YAML-in-markdown vs hybrid — which format do we lock?
3. Required-vs-optional split — what's the minimum-viable retro? The minimum-viable entry?
4. How do system-specific fields land without forking the schema?
5. How does minih's existing `retrospective.{workedWell, confusing, magicWand, magicWandTarget, difficulties[], improvementSuggestions, coordination}` map to the universal shape?
6. How does compound's farewell-envelope harvest map?
7. ID scheme — per-retro local IDs (DL-001) + globally unique combined IDs (`<retro_id>:DL-001`)?
8. Versioning — how do we evolve the schema without breaking either side?
9. Where does the canonical schema live (this repo? minih? a shared package?)
10. What's the migration path for minih's current `retrospective.json` consumers?

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | **Contract Ready** | plan-3 needs to consume an actual machine-readable schema; minih RFC needs a concrete shape to react to |
| Primary Value Axis | **Cross-Domain Coordination** | Three systems with overlapping concepts need one canonical contract |
| Supporting Value Axes | **Safety to Change, Implementation Readiness, Knowability, Migration Safety** | Each axis shapes a different decision: change-safety → versioning + namespaces; impl-readiness → executable schema; knowability → unified "what is a retro"; migration → minih round-trip |
| Downstream Loop Improved | **Integration (compound ↔ minih ↔ jakkaj/tools) + Implementation (plan-3 → schema-aware tasks)** | Replaces ad-hoc translation at every call site with one shared contract |

---

## The Three Systems Today

Before designing the unified contract, ground in the current state — what each system writes and what it expects.

### System 1: minih

**Produces**: every agent run emits one `retrospective` object at completion, written to:
- `agents/<slug>/runs/<ts>/output/report.json` (the raw structured output)
- `docs/retros/<slug>.md` (auto-harvested markdown ledger — append-only)
- `docs/retros/<planId>.md` (per-plan ledger, when `MINIH_PLAN_ID` env var is set)

**Schema** (from `/Users/jordanknight/substrate/minih/src/schemas/retrospective.json`):

```typescript
interface MinihRetrospective {
  workedWell: string;          // required, minLength: 10
  confusing: string;           // required, minLength: 10
  magicWand: string;           // required, minLength: 20
  magicWandTarget?: "project" | "minih" | "coordination";
  difficulties?: Array<{
    id?: string;
    category: string;
    description: string;
    workaround?: string;
    severity: "blocking" | "degrading" | "annoying";
  }>;
  improvementSuggestions?: string[];
  coordination?: string;
}
```

**Wire format**: JSON inside `report.json`, plus an auto-rendered markdown block in the ledger:

```markdown
## 2026-05-16T07:30:00.000Z — my-agent / 2026-05-16T07-30-00-000Z

- runId: 2026-05-16T07-30-00-000Z
- runDir: /path/to/agents/my-agent/runs/2026-05-16T07-30-00-000Z
- planId: plan-023
- summary: Scanned 12 files, found 3 potential issues...
- **magicWand** (target: minih): A MINIH_SCAN_PATHS env var would save me from guessing.
- difficulties:
  - [blocking] build: npm install failed
  - [degrading] config: Had to guess which env vars were required (workaround: read package.json scripts)
```

**Consumers**: minih CLI itself (`minih harvest <slug>`), humans reading the ledger.

### System 2: compound (planned, v1)

**Produces**: every supported CLI agent calls `compound-1-track` silently during work; entries land in `docs/compound/_session-buffer.md`; at session end, `compound-2-bubble` routes them into permanent scope files.

**Schema** (planned for this workshop to lock — currently sketched in spec):

```yaml
id: DL-103
ts: 2026-05-16T07:30:00Z
source: agent-self     # user | agent-self
type: difficulty       # difficulty | magic-wand | gift | insight
category: tooling
target: project
description: grep on src/ took 47s
workaround: …
suggested-encoding: justfile recipe
status: open           # open | suggested | encoded | wontfix | dismissed | escalated | stale
```

**Wire format**: YAML-fenced-markdown — each entry is a YAML block inside a `<plan-slug>.md` or `sessions/<date>-<branch>.md` file.

**Consumers**: `compound-2-bubble`, `compound-3-harvest`, `plan-1a` Subagent 7, `engineering-harness-v2` template seed.

### System 3: jakkaj/tools other skills (ad-hoc)

**Produces**: `plan-6a-v2-update-progress` Step 9 harvests the companion's farewell envelope (which IS a minih retrospective object) and writes it to `docs/retros/<plan-slug>.md` (currently — will become `docs/compound/<plan-slug>.md` after the path migration).

**Schema**: borrowed from minih's `retrospective` shape verbatim (companion mode uses minih runtime).

**Wire format**: append-only markdown, similar to minih's auto-harvested ledger.

**Consumers**: humans, eventually `compound-3-harvest`.

### Concept overlap matrix

| Concept | minih field | compound `kind` | jakkaj/tools (plan-6a) |
|---------|-------------|----------------|------------------------|
| Things that worked | `workedWell` (string) | `gift` | (via minih farewell) |
| Things that didn't | `difficulties[]` (array, structured) | `difficulty` | (via minih farewell) |
| Wishful improvements | `magicWand` (single string + target) | `magic-wand` | (via minih farewell) |
| Meta observations | — | `insight` | — |
| Multi-agent handoff issues | `coordination` (string) | — | — |
| Misunderstandings | `confusing` (string) | — | — |
| Directive improvement suggestions | `improvementSuggestions[]` (string array) | — | — |
| Lifecycle status | — | `status` | — |
| Encoding hint | — | `suggested-encoding` | — |

**The asymmetry**: minih has 7 concept fields but only 1 lifecycle field (the entry IS the entry, no status). Compound has 4 concept kinds + 5 lifecycle states. Jakkaj/tools borrows minih's shape.

The unified contract must cover ALL of minih's 7 concepts (so minih adopters lose nothing) AND compound's 5 lifecycle states (so compound's curation flow works) — without forcing minih to know about lifecycle or compound to know about coordination/confusing nuance.

**Resolution preview**: kinds = union of all (7 entry types), lifecycle = namespaced under `system.compound.status`.

---

## Decision Space

### D1 — Structural model: envelope-with-fields vs typed-entries

Two architectural shapes for "what is a retro":

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **A** | **Single object, flat fields** (matches minih today): one retro = one object with `workedWell`, `confusing`, `magicWand`, `difficulties[]`, … each filled or null | Minimal change for minih; one decision per concept | Each "thing" can only be one of each kind per retro (only one magicWand per run); difficulties get nested awkwardness; compound's entry-lifecycle has nowhere to live | **Rejected** |
| **B** | **Envelope with typed entries[]**: one retro = an envelope (id, agent, timestamps, summary) + an `entries[]` array; each entry is typed (`kind: difficulty | magic-wand | gift | …`); entries have their own IDs and optional fields | Matches compound's entry-lifecycle model; multiple of any kind per retro; entries are addressable; system extensions per-entry are clean | Breaks minih's current shape; requires migration | **Selected** |
| **C** | **Hybrid: flat-fields outer + entries[] inner** — flat compatibility fields for minih's existing concepts, plus an entries[] for compound-style typed atoms | Compatible with both today | Two ways to express the same thing → confusion + double-bookkeeping → drift | Rejected |

**Why B is selected**:
- The entry-lifecycle is the load-bearing feature of compound (`status: open → encoded → wontfix → …` per entry). Flat fields can't carry per-entry lifecycle without nesting hacks.
- Multiple-of-any-kind matters in real sessions: an agent often observes 2-3 difficulties + 1 magic-wand + 1 gift in the same run. Flat fields force the agent to concatenate or pick one.
- Round-trip from minih's flat fields → entries[] is mechanical (one entry per concept; difficulties[] splits to many entries with `kind: difficulty`). Round-trip back is aggregation (group entries by kind, concatenate text). Documented in § Round-Trip Mappings below.
- Per-entry `system.compound` namespace cleanly holds lifecycle without polluting the universal shape.

### D2 — Wire format

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **A** | Pure JSON (`.retro.json`) | Machine-friendly; trivial to validate against JSON Schema | Humans can't read or edit easily | Rejected |
| **B** | YAML (`.retro.yaml`) | More human-friendly than JSON | Comments are odd-feeling; no free-text body | Rejected |
| **C** | Markdown-with-YAML-frontmatter (`.retro.md`) — frontmatter is the structured contract, body is optional free-text reflection | Both human-readable AND machine-parseable; aligns with compound's current direction; matches Anthropic SKILL.md pattern that already permeates this repo | Slightly more complex to parse than pure JSON | **Selected** |
| **D** | Dual write — JSON canonical, MD rendered view | Best of both | Two files per retro; sync risk | Rejected |

**Why C is selected**:
- The repo already uses YAML-frontmatter-in-markdown as the canonical format for skills (`SKILL.md`). Retros adopt the same pattern → consistency.
- A free-text body section is genuinely useful (agents can paste a verbose paragraph reflection alongside the structured entries).
- JSON Schema validates the frontmatter YAML directly (YAML is a strict superset of JSON).
- Minih's current markdown auto-harvest already approximates this pattern; the migration is mostly "lift the metadata into frontmatter."

### D3 — Where the canonical schema lives

| Option | Description | When | Decision |
|--------|-------------|------|----------|
| **A** | `jakkaj/tools/skills/compound/schemas/retro.schema.json` (compound owns it) | v1 | **Selected for v1** |
| **B** | `AI-Substrate/minih/schemas/retro.schema.json` (minih owns it; was there first) | — | Rejected (minih's `retrospective.json` schema is its current shape; the universal shape is a NEW contract — initial home is compound) |
| **C** | Shared `@ai-substrate/retro-schema` npm package; both repos `npm install` | v2 | **Selected for v2** (deferred; extract once stable) |
| **D** | Vendored copy in both repos; sync via PRs | — | Rejected (drift risk) |

**Why A→C**: ship in compound first; once the schema stabilizes (after ~1 month of dogfood), extract to a shared package. Until extraction, minih vendors a copy with a known commit reference.

### D4 — Required vs optional fields

**Minimum-viable retro** (the smallest valid document):

```yaml
schema_version: "1.0"
retro_id: "2026-05-16T07:30:00Z-myagent-a8f3"
agent: my-agent
started_at: "2026-05-16T07:30:00Z"
```

That's 4 fields. Everything else is optional. A retro with zero entries is **valid** — it means "the agent ran but observed nothing worth logging." Important for low-friction runs.

**Minimum-viable entry** (the smallest valid entry inside `entries[]`):

```yaml
- id: DL-001
  kind: difficulty
  description: grep on src/ took 47s
```

That's 3 fields. `target`, `severity`, `workaround`, `suggested_encoding`, `references`, `system.*` are all optional.

**Why minimum-viable matters**: the schema must accept a retro the agent dashes off in 5 seconds at end-of-run. Forcing fields = anti-vibe 2 (bureaucratic ceremony). Per the [best-effort framing](../../../.claude/projects/-Users-jordanknight-github-tools/memory/feedback_compound_best_effort.md), required fields are kept minimal.

### D5 — Entry `kind` enum

The union of all three systems' concept surfaces:

| `kind` value | Origin | Description | Required sibling fields |
|--------------|--------|-------------|-------------------------|
| `difficulty` | minih, compound | Something that didn't work; friction encountered | `severity` recommended; `workaround` optional |
| `magic-wand` | minih, compound | Wishful improvement — "if I had a magic wand right now" | `target` recommended |
| `gift` | compound (minih's `workedWell` maps to this) | Something that worked unexpectedly well — a gift to your future self | — |
| `insight` | compound | A meta-observation that's neither a difficulty nor a gift | — |
| `coordination` | minih | A multi-agent or handoff issue | — |
| `improvement-suggestion` | minih (`improvementSuggestions[]`) | A directive suggestion (vs `magic-wand` which is wistful) | — |
| `confusion` | minih (`confusing`) | A misunderstanding or unclear point | — |

**Rationale for enum exhaustiveness**: keep all seven. They're semantically distinct:
- `magic-wand` is wistful ("I wish X existed")
- `improvement-suggestion` is directive ("you should add X")
- `confusion` is observation ("I didn't understand X")
- `insight` is reflection ("I noticed X is true")
- `gift` is celebration ("X just worked")
- `difficulty` is friction ("X didn't work")
- `coordination` is multi-agent ("X went wrong between agents")

Collapsing any of these loses real semantic distinction. Future kinds can be added in v1.x (additive change; doesn't break existing).

### D6 — Identity scheme

**Retro ID** (`retro_id`):

Pattern: `<ISO timestamp>-<agent-slug>-<short hash>`
Example: `2026-05-16T07:30:00Z-myagent-a8f3`

- ISO timestamp: when the retro was created (typically run start)
- Agent slug: kebab-case agent identifier
- Short hash: 4-8 hex chars derived from random or content hash; disambiguates concurrent runs

Sortable lexically (timestamp prefix). Unique across systems (agent slug + hash).

**Entry ID** (per-retro local):

Pattern: `<prefix>-<3-digit number>` (zero-padded)
Examples: `DL-001`, `DL-002`, `MW-001`, `GFT-001`, `INS-001`

Recommended prefixes by kind:
- `DL` — difficulty
- `MW` — magic-wand
- `GFT` — gift
- `INS` — insight
- `COORD` — coordination
- `SUGG` — improvement-suggestion
- `CONF` — confusion

Prefixes are conventional, not enforced — the schema only requires `^[A-Z]+-\d{3,}$`. Producers may choose their own scheme. Per-retro numbering resets at 001 for each kind.

**Global reference** (cross-retro pointers):

Pattern: `<retro_id>:<entry_id>`
Example: `2026-05-16T07:30:00Z-myagent-a8f3:DL-002`

Used in `references[]` arrays, in compound-3-harvest's status mutations, and in any tool that needs to address a specific entry from outside its retro.

### D7 — System-specific extensions (namespace pattern)

System-specific fields live under `system.<system-name>`:

```yaml
entries:
  - id: DL-001
    kind: difficulty
    description: grep on src/ took 47s
    severity: degrading
    system:
      compound:
        status: encoded
        resolved_by: scratch/encode-DL-001.diff
      minih:
        run_dir: /path/to/agents/x/runs/y
```

Reader behavior:
- **Compound** reads `system.compound.*`; ignores `system.minih.*`
- **Minih** reads `system.minih.*`; ignores `system.compound.*`
- **A third system** could add `system.zod` (or whatever) without either of them caring

Schema enforcement:
- The universal schema declares `system: { type: object, additionalProperties: { type: object } }` — i.e., any string key maps to any object. Validator doesn't enforce inner shape.
- Each system can publish its own sub-schema (`system.compound.schema.json`) that strictly validates its namespace.

**Why namespace pattern**: adding a new field to one system NEVER breaks another. The contract surface ONLY includes universal concepts; system-specific concepts are explicitly out-of-band.

### D8 — Versioning

Schema versioning follows **SemVer** in the `schema_version` field:

- **Major** (1.0 → 2.0): breaking change to required field, removed enum value, changed field type. Readers MUST reject unknown majors with a clear error.
- **Minor** (1.0 → 1.1): additive change — new optional field, new enum value, new sibling. Readers MUST accept unknown minors (forward-compat).
- **Patch** (1.0 → 1.0.1): documentation-only or clarification.

Producers MUST emit `schema_version`. Readers MUST validate `schema_version` and reject anything below their minimum supported version.

Initial release: `schema_version: "1.0"`.

### D9 — Round-trip fidelity from minih's existing `retrospective.json`

Mapping is **lossless and deterministic** in both directions:

**Minih → Universal** (per concept):

```typescript
function minihToUniversal(minih: MinihRetrospective, meta: RunMeta): Retro {
  const entries: Entry[] = [];
  let dlCounter = 1, mwCounter = 1, gftCounter = 1, coordCounter = 1, suggCounter = 1, confCounter = 1;

  // workedWell (string, required) → one gift entry
  if (minih.workedWell?.trim()) {
    entries.push({
      id: `GFT-${pad(gftCounter++)}`,
      kind: "gift",
      description: minih.workedWell,
    });
  }
  // confusing (string, required) → one confusion entry
  if (minih.confusing?.trim()) {
    entries.push({
      id: `CONF-${pad(confCounter++)}`,
      kind: "confusion",
      description: minih.confusing,
    });
  }
  // magicWand (string, required) + magicWandTarget → one magic-wand entry
  if (minih.magicWand?.trim()) {
    entries.push({
      id: `MW-${pad(mwCounter++)}`,
      kind: "magic-wand",
      target: minih.magicWandTarget ?? "project",
      description: minih.magicWand,
    });
  }
  // difficulties[] → many difficulty entries
  for (const d of minih.difficulties ?? []) {
    entries.push({
      id: d.id ?? `DL-${pad(dlCounter++)}`,
      kind: "difficulty",
      target: d.category,
      severity: d.severity,
      description: d.description,
      workaround: d.workaround,
    });
  }
  // improvementSuggestions[] → many improvement-suggestion entries
  for (const s of minih.improvementSuggestions ?? []) {
    entries.push({
      id: `SUGG-${pad(suggCounter++)}`,
      kind: "improvement-suggestion",
      description: s,
    });
  }
  // coordination → one coordination entry
  if (minih.coordination?.trim()) {
    entries.push({
      id: `COORD-${pad(coordCounter++)}`,
      kind: "coordination",
      description: minih.coordination,
    });
  }

  return {
    schema_version: "1.0",
    retro_id: `${meta.startedAt}-${meta.agentSlug}-${shortHash(meta.runId)}`,
    agent: meta.agentSlug,
    run_id: meta.runId,
    plan_id: meta.planId,
    started_at: meta.startedAt,
    ended_at: meta.endedAt,
    entries,
    system: {
      minih: {
        run_dir: meta.runDir,
      },
    },
  };
}
```

**Universal → Minih** (aggregate entries back to flat fields):

```typescript
function universalToMinih(retro: Retro): MinihRetrospective {
  const byKind = groupBy(retro.entries ?? [], (e) => e.kind);

  return {
    workedWell: (byKind.gift ?? []).map((e) => e.description).join("\n\n") || "(none reported)",
    confusing: (byKind.confusion ?? []).map((e) => e.description).join("\n\n") || "(none reported)",
    magicWand: (byKind["magic-wand"]?.[0]?.description) ?? "(none reported)",
    magicWandTarget: byKind["magic-wand"]?.[0]?.target as "project" | "minih" | "coordination" | undefined,
    difficulties: (byKind.difficulty ?? []).map((e) => ({
      id: e.id,
      category: e.target ?? "general",
      severity: e.severity ?? "annoying",
      description: e.description,
      workaround: e.workaround,
    })),
    improvementSuggestions: (byKind["improvement-suggestion"] ?? []).map((e) => e.description),
    coordination: byKind.coordination?.[0]?.description,
  };
}
```

**Round-trip guarantee**: `universalToMinih(minihToUniversal(m)) ≈ m` — modulo (a) the "(none reported)" placeholder filling minih's required minLength fields when the universal retro has no entry of that kind, and (b) multiple `magic-wand` or `coordination` entries collapsing into the first one (minih only allows one). These two edge cases are acceptable losses; they only matter when retros have more than one of those kinds, which is rare. Documented as Known Limitations.

### D10 — Multiple retros: file layout (deferred to next workshop)

This workshop locks the **schema** of a single retro. The **file layout** — how multiple retros are organized on disk (per-run isolation, date directories, index files, etc.) — is the topic of the next workshop (the user's stated "workshop the folder structure" ask). Pointer added to § Open Questions.

---

## Recommended Direction (Summary)

The unified contract:

1. **Structural model**: envelope-with-typed-entries (D1-B)
2. **Wire format**: markdown-with-YAML-frontmatter, file extension `.retro.md` (D2-C)
3. **Canonical schema location**: `jakkaj/tools/skills/compound/schemas/retro.schema.json` (v1) → shared `@ai-substrate/retro-schema` package (v2) (D3)
4. **Minimum viable retro**: 4 required fields (`schema_version`, `retro_id`, `agent`, `started_at`) + optional `entries[]` (D4)
5. **Entry kinds**: seven distinct kinds covering all three systems' concept surfaces (D5)
6. **Identity**: retro_id pattern `<ISO>-<agent>-<hash>`; entry IDs scoped to retro; global refs `<retro_id>:<entry_id>` (D6)
7. **Extensions**: namespaced under `system.<name>`; readers ignore unknown namespaces (D7)
8. **Versioning**: SemVer in `schema_version`; major = breaking (reject), minor = additive (accept) (D8)
9. **Round-trip mapping**: deterministic from/to minih's existing `retrospective.json`; known limitations (D9)

---

## JSON Schema (the contract)

Save as `skills/compound/schemas/retro.schema.json` (v1 home):

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/jakkaj/tools/blob/main/skills/compound/schemas/retro.schema.json",
  "title": "Retro",
  "description": "A universal retrospective — produced by minih agents, compound skills, and other agentic workflows. One retro per run/session.",
  "type": "object",
  "required": ["schema_version", "retro_id", "agent", "started_at"],
  "additionalProperties": false,
  "properties": {
    "schema_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+(\\.\\d+)?$",
      "description": "SemVer of the retro schema this document conforms to. Readers MUST reject unknown major versions."
    },
    "retro_id": {
      "type": "string",
      "pattern": "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?Z-[a-z][a-z0-9-]*-[a-f0-9]{4,8}$",
      "description": "Unique retro identifier: <ISO 8601 UTC timestamp>-<agent-slug>-<short hex hash>. Example: 2026-05-16T07:30:00Z-myagent-a8f3"
    },
    "agent": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9-]*$",
      "maxLength": 64,
      "description": "Slug of the agent that produced this retro. Lowercase kebab-case."
    },
    "run_id": {
      "type": "string",
      "description": "Producer-specific run identifier. Minih uses ISO timestamp format with hyphens. Optional."
    },
    "plan_id": {
      "type": ["string", "null"],
      "description": "Optional plan/session identifier this retro belongs to. Used for grouping across runs."
    },
    "started_at": { "type": "string", "format": "date-time" },
    "ended_at": { "type": "string", "format": "date-time" },
    "duration_ms": { "type": "integer", "minimum": 0 },
    "summary": {
      "type": "string",
      "maxLength": 2000,
      "description": "One-paragraph summary of what the agent did this run. Optional."
    },
    "entries": {
      "type": "array",
      "default": [],
      "items": { "$ref": "#/$defs/Entry" }
    },
    "system": {
      "type": "object",
      "description": "Namespaced system-specific top-level extensions. Readers ignore unknown namespaces.",
      "additionalProperties": { "type": "object" }
    }
  },
  "$defs": {
    "Entry": {
      "type": "object",
      "required": ["id", "kind", "description"],
      "additionalProperties": false,
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^[A-Z]+-\\d{3,}$",
          "description": "Short entry ID, scoped within this retro. Convention: <PREFIX>-<3+ digit number>. Recommended prefixes: DL (difficulty), MW (magic-wand), GFT (gift), INS (insight), COORD (coordination), SUGG (improvement-suggestion), CONF (confusion)."
        },
        "kind": {
          "type": "string",
          "enum": [
            "difficulty",
            "magic-wand",
            "gift",
            "insight",
            "coordination",
            "improvement-suggestion",
            "confusion"
          ],
          "description": "Semantic kind of this entry. Determines which sibling fields are meaningful."
        },
        "description": {
          "type": "string",
          "minLength": 10,
          "maxLength": 2000,
          "description": "Free-text description of the entry. Required."
        },
        "target": {
          "type": "string",
          "maxLength": 64,
          "description": "What the entry is about. Conventional values: project | tooling | plan | skill | doc | infra | minih | coordination. Custom values allowed."
        },
        "severity": {
          "type": "string",
          "enum": ["blocking", "degrading", "annoying"],
          "description": "Recommended for kind=difficulty; meaningless for other kinds."
        },
        "workaround": {
          "type": "string",
          "maxLength": 1000,
          "description": "Optional. What you did to get past the issue (typically for kind=difficulty)."
        },
        "suggested_encoding": {
          "type": "string",
          "maxLength": 200,
          "description": "Optional hint for compound's encoding flow. Free-text. Examples: 'justfile recipe', 'plan-1b plan', 'docs/how article', 'SKILL.md edit'."
        },
        "references": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^[^:]+:[A-Z]+-\\d{3,}$",
            "description": "Global reference to another entry: <retro_id>:<entry_id>"
          },
          "description": "Optional. Cross-retro entry pointers."
        },
        "system": {
          "type": "object",
          "description": "Namespaced per-entry system-specific extensions. Readers ignore unknown namespaces.",
          "additionalProperties": { "type": "object" }
        }
      }
    }
  }
}
```

### Compound's namespace sub-schema

Save as `skills/compound/schemas/system.compound.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/jakkaj/tools/blob/main/skills/compound/schemas/system.compound.schema.json",
  "title": "Compound system extensions",
  "description": "Per-entry compound lifecycle metadata, written under entry.system.compound",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "status": {
      "type": "string",
      "enum": ["open", "suggested", "encoded", "wontfix", "dismissed", "escalated", "stale"],
      "default": "open",
      "description": "Lifecycle state of this entry. Transitions handled by compound-2-bubble + compound-3-harvest."
    },
    "resolved_by": {
      "type": "string",
      "description": "Path to scratch/ diff, commit hash, or PR URL that encodes the fix. Set when status moves to encoded."
    },
    "first_seen_at": { "type": "string", "format": "date-time" },
    "last_harvested_at": { "type": "string", "format": "date-time" },
    "harvest_count": { "type": "integer", "minimum": 0 },
    "source": {
      "type": "string",
      "enum": ["user", "agent-self"],
      "description": "Compound producer-side annotation: did the user mutter the friction, or did the agent observe it itself? Compound-only field; minih retros default to source=agent-self when imported."
    }
  }
}
```

### Minih's namespace sub-schema

Save as `skills/compound/schemas/system.minih.schema.json` (vendored from minih):

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/jakkaj/tools/blob/main/skills/compound/schemas/system.minih.schema.json",
  "title": "Minih system extensions",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "run_dir": {
      "type": "string",
      "description": "Path to minih run directory (agents/<slug>/runs/<runId>/)"
    },
    "events_count": { "type": "integer", "minimum": 0 },
    "status": {
      "type": "string",
      "enum": ["success", "degraded", "timeout", "crash"],
      "description": "Minih run completion status. Different concept from compound's status — this is RUN status, not ENTRY status."
    }
  }
}
```

---

## Wire Format Examples

### Example 1: Full retro (a typical minih agent run)

`docs/compound/<agent>/2026-05-16T07-30-00Z-myagent-a8f3.retro.md`:

```markdown
---
schema_version: "1.0"
retro_id: "2026-05-16T07:30:00Z-myagent-a8f3"
agent: my-agent
run_id: "2026-05-16T07-30-00-000Z"
plan_id: "plan-023"
started_at: "2026-05-16T07:30:00Z"
ended_at: "2026-05-16T07:42:15Z"
duration_ms: 735000
summary: "Scanned 12 files in src/; found 3 potential issues; encoded 1 fix as a justfile recipe."

entries:
  - id: GFT-001
    kind: gift
    description: "The justfile recipe `just dev` boots the harness in 3 seconds — way faster than I expected."

  - id: CONF-001
    kind: confusion
    description: "Wasn't sure whether `MINIH_PLAN_ID` was supposed to be the spec ordinal or the plan-slug; tried both."

  - id: MW-001
    kind: magic-wand
    target: minih
    description: "An MINIH_SCAN_PATHS env var listing which directories to scan would save me from guessing at startup."

  - id: DL-001
    kind: difficulty
    target: build
    severity: blocking
    description: "npm install failed due to a missing peer dependency."
    workaround: "Manually installed @types/node@20 before retrying."

  - id: DL-002
    kind: difficulty
    target: config
    severity: degrading
    description: "Had to guess which env vars were required at startup."
    workaround: "Read package.json scripts to infer."

  - id: SUGG-001
    kind: improvement-suggestion
    description: "Document the env var contract in AGENTS.md so agents don't have to infer it."

system:
  minih:
    run_dir: "/Users/jordanknight/substrate/minih/agents/my-agent/runs/2026-05-16T07-30-00-000Z"
    events_count: 47
    status: success
---

## Reflection (free-text body, optional)

This run went smoothly overall — the gift entry above is genuine; `just dev` is unusually fast. The blocking difficulty (DL-001) cost ~10 minutes; would be nice to have a preflight check.
```

### Example 2: Minimum-viable retro (zero entries — silent run)

`docs/compound/<agent>/2026-05-16T08-00-00Z-quickagent-b7c2.retro.md`:

```markdown
---
schema_version: "1.0"
retro_id: "2026-05-16T08:00:00Z-quickagent-b7c2"
agent: quickagent
started_at: "2026-05-16T08:00:00Z"
---
```

Valid. Means "the agent ran but observed nothing worth logging." Stays small.

### Example 3: Compound-side entry with full lifecycle metadata

A compound-1-track entry mid-lifecycle (after the user picked `[e]ncode` and the diff was applied):

```yaml
- id: DL-103
  kind: difficulty
  target: tooling
  severity: annoying
  description: "grep on src/ took 47s — should use ripgrep."
  workaround: "Used `grep -r -I` to skip binaries; still slow."
  suggested_encoding: "justfile recipe"
  system:
    compound:
      status: encoded
      resolved_by: "scratch/encode-DL-103.diff (applied as commit 8a3f9c1)"
      first_seen_at: "2026-05-14T11:22:00Z"
      last_harvested_at: "2026-05-16T07:42:00Z"
      harvest_count: 2
      source: agent-self
```

---

## Round-Trip Mappings

### Minih's existing `retrospective.json` → Universal

See § Decision D9 for the deterministic mapping logic.

**Concrete example** — minih's report.json `retrospective` block:

```json
{
  "workedWell": "The justfile recipe `just dev` boots the harness in 3 seconds.",
  "confusing": "Wasn't sure whether MINIH_PLAN_ID was supposed to be the spec ordinal or the plan-slug.",
  "magicWand": "An MINIH_SCAN_PATHS env var listing which directories to scan would save me from guessing.",
  "magicWandTarget": "minih",
  "difficulties": [
    { "category": "build", "severity": "blocking", "description": "npm install failed due to missing peer dep.", "workaround": "Installed @types/node@20 manually." },
    { "category": "config", "severity": "degrading", "description": "Had to guess which env vars were required.", "workaround": "Read package.json scripts." }
  ],
  "improvementSuggestions": [
    "Document the env var contract in AGENTS.md so agents don't have to infer it."
  ],
  "coordination": null
}
```

→ Universal retro (Example 1 above). Deterministic.

### Compound farewell envelope (from plan-6-companion) → Universal

The companion's farewell envelope IS a minih retrospective (the companion runs on minih). Mapping is the same as minih → universal above. plan-6a Step 9 runs the mapping function and writes the universal `.retro.md` file.

### Compound `_session-buffer.md` entry → Universal

`compound-1-track` writes entries directly in universal entry shape (the schema is the source of truth from day 1). At session end, `compound-2-bubble` reads the buffer, wraps the entries in a retro envelope, and writes one `.retro.md` file per saved scope:

```markdown
---
schema_version: "1.0"
retro_id: "2026-05-16T09:15:00Z-claude-code-c9d4"
agent: claude-code
plan_id: "023-difficulty-ledger-skill"
started_at: "2026-05-16T08:30:00Z"
ended_at: "2026-05-16T09:15:00Z"
summary: "compound-2-bubble session-end save"
entries:
  - id: DL-103
    kind: difficulty
    ...
  - id: MW-007
    kind: magic-wand
    ...
system:
  compound:
    bubble_action: "all-save"
    scope_file: "docs/compound/<plan-slug>.md"
---
```

---

## UX Walkthroughs

### Walkthrough A: Minih writes a retro using the universal contract

```
$ MINIH_PLAN_ID=plan-023 minih run my-agent

[minih runs my-agent; agent does work; agent emits retrospective at end]
[minih's runner serializes the retrospective to universal shape]

[Files written]:
  agents/my-agent/runs/2026-05-16T07-30-00-000Z/output/report.json    (raw)
  agents/my-agent/runs/2026-05-16T07-30-00-000Z/output/retro.retro.md (universal, Example 1 above)
  docs/compound/<my-agent>/2026-05-16T07-30-00Z-myagent-a8f3.retro.md (auto-harvested)
  docs/compound/<plan-023>/2026-05-16T07-30-00Z-myagent-a8f3.retro.md (auto-harvested per-plan)

[stdout]:
✅ Run complete. Retrospective saved to docs/compound/my-agent/2026-05-16T07-30-00Z-myagent-a8f3.retro.md
   6 entries: 1 gift, 1 confusion, 1 magic-wand, 2 difficulties, 1 improvement-suggestion
```

### Walkthrough B: compound-3-harvest reads minih's retros + compound's own entries

```
$ /compound-3-harvest

[reads]:
  docs/compound/**/*.retro.md   (all retro files across all agents, plans, sessions)
  docs/retros/*.md              (legacy minih markdown ledger — back-compat read)

[parses each file; validates frontmatter against retro.schema.json]
[merges all entries into one in-memory view; deduplicates by retro_id:entry_id]
[clusters by kind + target; flags stale; presents top-10]

[stdout]:
🌾 Harvest summary (27 entries across 8 retros from 3 agents)
   Top clusters:
   1. [tooling] grep/search slowness (4 entries across 3 retros)  [r/w/s]
   2. [pipeline] missing example patterns (3 entries)  [r/w/s]
   ...
[s/t/p/e/d/a/r/w/s]: ▮
```

### Walkthrough C: jakkaj/tools script writes a retro

A grep-replacement util in `scripts/` that ran a long-running scan and wants to log friction:

```typescript
import { writeRetro } from "@ai-substrate/retro-schema";

await writeRetro({
  agent: "scan-util",
  started_at: scanStart.toISOString(),
  ended_at: scanEnd.toISOString(),
  summary: `Scanned ${fileCount} files; found ${matchCount} matches.`,
  entries: [
    {
      id: "DL-001",
      kind: "difficulty",
      target: "tooling",
      severity: "degrading",
      description: `Scan took ${duration}ms across ${fileCount} files; should use parallel workers.`,
      suggested_encoding: "scripts/scan-util refactor",
    },
  ],
});
// → writes docs/compound/scan-util/<retro-id>.retro.md
```

### Walkthrough D: Schema-version skew

Future retro file has `schema_version: "2.0"` (a hypothetical major bump):

```
$ /compound-3-harvest

[reads docs/compound/myagent/2026-09-01T12-00-00Z-myagent-future.retro.md]
[parses frontmatter: schema_version: "2.0"]
[compound-3-harvest knows about 1.x only]

[stdout]:
⚠️  Skipped 1 retro with unsupported schema_version "2.0" (current reader supports 1.x):
   docs/compound/myagent/2026-09-01T12-00-00Z-myagent-future.retro.md
   To upgrade: bump compound to v2.x or wait for the back-compat reader.
```

Forward-compat (minor versions) is silent — `1.1` is read fine by a `1.0` reader; unknown fields ignored.

---

## Edge Cases

### EC1 — Retro with zero entries

Valid. Means "agent ran but observed nothing." Stays in the ledger but harvest skips it (no entries to cluster). No prompt to the user. Disk cost: ~10 lines per file; cheap.

### EC2 — Retro with malformed entry (missing required field)

Validator rejects the WHOLE retro. Reader logs the file path + the validation error and moves on. Strict — better to skip a malformed retro than to read it half-parsed.

### EC3 — Round-trip loses data (universal → minih → universal)

Per D9 § Known Limitations:
- Multiple magic-wand entries collapse to first one (minih only allows one)
- Multiple coordination entries collapse to first one
- Multiple confusion entries collapse to first one
- gift entries with `system.compound.status` lose the status field

For lossless storage, always store the universal form. Convert to minih shape only at minih boundary if needed.

### EC4 — Unknown `kind` value

The `kind` enum is closed in v1. An unknown kind = validation failure = whole retro rejected. To add a new kind (e.g., `regression`), bump to `schema_version: 1.1` and update consumers.

### EC5 — Custom `target` value

`target` is OPEN (free-text, max 64 chars). Custom values are fine. Conventional values (`project`, `tooling`, `plan`, `skill`, `doc`, `infra`, `minih`, `coordination`) are documented but not enforced. Producers and consumers should converge over time; harvest-time clustering will surface common patterns.

### EC6 — System namespace collision

Two systems both write to `system.compound`. The LAST writer wins (file is mutated in place by `compound-3-harvest` for lifecycle updates). Not actually a problem — only compound writes `system.compound`; minih only writes `system.minih`. The namespace pattern PREVENTS collision.

### EC7 — Retro file path collision (two retros, same retro_id)

Theoretically possible if two agents generate the same hash at the same nanosecond. The schema's retro_id pattern uses a 4-8 char hex hash; collision probability at 4 chars is ~1/65536 per second. Reader behavior: log warning + skip the second one (file overwrite would be data loss). Producers SHOULD use ≥6 char hashes for high-frequency agents.

### EC8 — Retro file path layout (per-run isolation — DEFERRED)

This workshop locks the schema of a single retro. The directory structure for multiple retros — per-agent, per-plan, per-session, per-date subdirectories, `_index.json` rollups — is the topic of the **next workshop** (the user's stated "workshop the folder structure" ask). All examples in this workshop assume a placeholder layout (`docs/compound/<agent>/<retro-id>.retro.md`). The actual layout will be locked in workshop 006.

---

## Migration Path: Minih's current `retrospective.json` → Universal

Three-phase migration:

| Phase | What changes | Risk | Status |
|-------|-------------|------|--------|
| **P1: Dual-write** | Minih continues to emit `retrospective` in `report.json` AND emits a sibling `retro.retro.md` (universal) in the same `runs/<ts>/output/` dir. Auto-harvest also writes the universal `.retro.md` to `docs/compound/` in addition to existing `docs/retros/` markdown ledger | Low — additive only | v1 (this plan) |
| **P2: Compound canonical** | Compound stops reading `docs/retros/` (back-compat path) once all consumers can read `docs/compound/`. Minih continues dual-write. | Low — flip a switch | v1.1 (post-dogfood) |
| **P3: Minih drops legacy** | Minih removes `retrospective` from `report.json`; only emits universal `.retro.md`. Coordinate via the RFC issue in `AI-Substrate/minih`. | Medium — coordinated release | v2 (after schema stabilizes) |

**During P1**: minih writes BOTH formats; readers can use either. No flag day. Zero downtime.

---

## Open Questions

### Q1 — Should `description` allow markdown?

**OPEN**. JSON Schema can declare format hints but doesn't enforce markdown. Options:
- **A**: plain text only (current schema)
- **B**: markdown allowed (renderers handle it)

**Tentative**: B. Plain text is too restrictive — agents naturally use backticks and bullet points in difficulty descriptions. Renderers can downgrade to plain text if needed. Defer to dogfood revisit.

### Q2 — Should `severity` extend to non-`difficulty` kinds?

**OPEN**. Currently `severity` is "recommended for kind=difficulty; meaningless for other kinds". But a `magic-wand` could have an importance level. A `gift` could have a delight level.

**Tentative**: keep severity restricted to `difficulty` in v1. Avoid premature complexity. Revisit if dogfood surfaces need.

### Q3 — How does the schema interact with the `docs/compound/.disabled` sentinel?

**OPEN — not a schema concern**. The sentinel gates production + consumption of retros; the schema itself doesn't care. Documented in compound-1-track's skill body.

### Q4 — File layout — folder structure for storing multiple retros

**OPEN — DEFERRED to next workshop**. This workshop locks the schema of a single retro; the layout (per-run isolation, date dirs, index files, etc.) is workshop 006.

### Q5 — Should `retro_id` include the agent-slug AND the run-id?

**OPEN**. Current pattern: `<ISO timestamp>-<agent-slug>-<hash>`. Alternative: `<agent-slug>/<run-id>` (path-like). The current pattern is sortable lexically by time; the alternative is more readable.

**Tentative**: keep current pattern. Lexical sortability is more valuable than readability for IDs (which are rarely typed by humans).

### Q6 — Where do non-agentic retros live?

**OPEN**. A retro from a `scripts/` shell utility (Walkthrough C) — does it use `agent: scan-util` (treating the script as an agent), or do we add a separate `producer` field?

**Tentative**: treat scripts as agents (`agent: <script-slug>`). The schema doesn't distinguish — anything that produces a retro is, for retro purposes, an agent. Avoids schema bloat.

### Q7 — Should `entries[].id` be globally unique within a file?

**OPEN**. Currently scoped to retro. If two retros in the same file (which shouldn't happen — one retro per file is the convention) both had `DL-001`, the global reference `<retro_id>:DL-001` still disambiguates.

**Tentative**: file-level uniqueness not enforced; rely on the file-per-retro convention.

---

## Acceptance Criteria for plan-3-v2-architect

When plan-3 consumes this workshop, it should produce tasks for:

- [ ] **Write `skills/compound/schemas/retro.schema.json`** — verbatim from § JSON Schema in this workshop
- [ ] **Write `skills/compound/schemas/system.compound.schema.json`** — verbatim from § Compound's namespace sub-schema
- [ ] **Write `skills/compound/schemas/system.minih.schema.json`** — verbatim from § Minih's namespace sub-schema
- [ ] **`compound-1-track`'s SKILL.md** documents the universal entry shape; agent emits valid entries directly
- [ ] **`compound-2-bubble`'s SKILL.md** wraps buffer entries in a retro envelope on save; writes one `.retro.md` per scope routing
- [ ] **`compound-3-harvest`'s SKILL.md** reads `docs/compound/**/*.retro.md`, validates each retro's frontmatter against retro.schema.json, skips malformed retros with a warning
- [ ] **`compound-3-harvest` back-compat path**: also reads `docs/retros/*.md` (minih's legacy markdown ledger) by parsing the existing block-format until P2 migration completes
- [ ] **`plan-6a-v2-update-progress` Step 9 update**: harvests minih's farewell envelope by running `minihToUniversal()` mapping (§ D9); writes a `.retro.md` file using the universal schema (path TBD by workshop 006)
- [ ] **Helper library (TypeScript)**: implement `minihToUniversal()` and `universalToMinih()` round-trip functions in `skills/compound/lib/retro.ts` (or extract to a shared package later)
- [ ] **Test fixtures**: include 5+ example retros covering full / minimum / each kind / round-trip / schema-version skew in `skills/compound/schemas/fixtures/`

---

## Acceptance Criteria for the minih RFC

The deferred GitHub issue against `AI-Substrate/minih` should:

- [ ] Reference this workshop as the schema-of-record
- [ ] Propose Phase 1 (dual-write) timing
- [ ] Include the round-trip mapping (§ D9) so minih maintainers can verify lossless-ness
- [ ] Invite minih maintainers to comment on the `system.minih.*` namespace sub-schema (their territory)
- [ ] Note that the folder-layout workshop (workshop 006, queued next) will produce a concrete proposal for the per-run isolation the user wants

---

## Validation / Acceptance

This workshop reaches its target proof level when:

- [x] JSON Schema is complete and self-validating (all properties typed, all enums exhaustive, all required fields explicit)
- [x] Three wire-format examples cover: full retro, minimum-viable retro, compound-side lifecycle metadata
- [x] Round-trip mappings (minih ↔ universal) are deterministic with documented known limitations
- [x] System namespace pattern is shown working (compound's status; minih's run_dir)
- [x] Identity scheme is concrete (retro_id pattern + entry_id pattern + global reference format)
- [x] Versioning policy is explicit (SemVer; major = breaking; minor = additive; reader behavior on skew)
- [x] Concept overlap matrix shows all 7 kinds with origin and meaning
- [x] Migration path for minih has three explicit phases with risk levels
- [x] 7 open questions tracked with tentative answers; nothing critical blocking
- [x] plan-3 acceptance criteria list is consumable verbatim (9 tasks)
- [x] minih RFC acceptance criteria list is ready
- [ ] **Reviewed by user** (this is the next step — user reads + approves OR sends back)
- [ ] **Reviewed by minih maintainers** (happens after RFC issue lands)

---

## Attention Reduction

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Implementation (plan-3) | "Schema is YAML-fenced markdown" — exact field shape undefined; minih round-trip "deferred to follow-up plan" | Verbatim JSON Schema; verbatim round-trip mappings; verbatim test fixtures specified |
| Cross-system coordination | Every cross-system call site translates ad-hoc; mappings drift; new consumers learn 3 shapes | One schema; one wire format; mapping helpers in a shared lib; new consumers learn one shape |
| Review | Reviewer would have to reason about whether each system's reads/writes were consistent | Per-file frontmatter validation against retro.schema.json is mechanical |
| Testing | Producers and consumers each had to invent their own test data | Schema-driven test fixtures; validators can generate edge cases automatically |
| Onboarding | New contributor would see compound, minih, plan-6a as three retro shapes; have to learn each | One workshop. One schema. Three systems use it. |
| Agent execution | Agent had to know which fields each system expected | Agent emits universal entries; readers handle their own namespaces |
| Schema evolution | No versioning policy = breakage on any change | SemVer + reader behavior on skew is explicit; minor versions are forward-compat |

---

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| Concept overlap matrix (3 systems × 9 concepts) | § "Concept overlap matrix" | Decision context — what concepts must the unified schema cover | Ready |
| Decision space (D1–D10) | § "Decision Space" | Each integration choice with selected option + rationale | Ready |
| JSON Schema for `Retro` | § "JSON Schema (the contract)" | The literal machine-readable contract | Ready |
| JSON Schema for `system.compound` extensions | § "Compound's namespace sub-schema" | Compound's lifecycle metadata contract | Ready |
| JSON Schema for `system.minih` extensions | § "Minih's namespace sub-schema" | Minih's run-metadata contract | Ready |
| Wire format Examples 1–3 | § "Wire Format Examples" | Concrete .retro.md files to validate against | Ready |
| Round-trip mapping (TypeScript pseudocode) | § "D9" + "Round-Trip Mappings" | Deterministic mapping helpers for plan-3 to implement | Ready |
| Four walkthroughs (minih write, compound harvest, jakkaj/tools script, schema skew) | § "UX Walkthroughs" | End-to-end usage scenarios per system | Ready |
| Eight edge cases (EC1–EC8) | § "Edge Cases" | Reader/writer behavior under unusual conditions | Ready |
| Three-phase migration path for minih | § "Migration Path" | Risk-graded rollout sequence | Ready |
| 9-item plan-3 acceptance criteria list | § "Acceptance Criteria for plan-3" | Direct consumption surface for plan-3 | Ready |
| 5-item minih RFC acceptance criteria list | § "Acceptance Criteria for the minih RFC" | What the GitHub issue must include | Ready |
| 7 open questions with tentative answers | § "Open Questions" | Soft items for post-dogfood revisit | Draft |

---

## Decision Space — Summary Reference

For quick lookup during plan-3 / minih RFC consumption:

| Decision | Selection | Rationale (one-line) |
|----------|-----------|---------------------|
| D1 — Structural model | **B** (envelope + typed entries[]) | Compound's per-entry lifecycle needs typed atoms; minih round-trip is mechanical |
| D2 — Wire format | **C** (markdown + YAML frontmatter, `.retro.md`) | Human-readable + machine-parseable; matches SKILL.md convention |
| D3 — Schema location | **A (v1) → C (v2)** | Ship in compound; extract to shared package once stable |
| D4 — Required vs optional | **4 required retro fields; 3 required entry fields** | Best-effort framing — required = minimum-viable, nothing more |
| D5 — Entry kind enum | **7 kinds** (difficulty, magic-wand, gift, insight, coordination, improvement-suggestion, confusion) | Union of all three systems; each semantically distinct |
| D6 — Identity scheme | **retro_id: `<ISO>-<agent>-<hash>`; entry_id: `<PREFIX>-<NNN>`; global ref: `<retro_id>:<entry_id>`** | Sortable lexically; entry IDs scoped to retro; globally addressable |
| D7 — System extensions | **`system.<name>` namespace; readers ignore unknown** | Adding fields to one system NEVER breaks another |
| D8 — Versioning | **SemVer; major = reject unknown; minor = accept (forward-compat)** | Standard policy; explicit reader behavior |
| D9 — Minih round-trip | **Deterministic both ways; documented limitations** | Multiple magic-wand / coordination / confusion entries collapse to first |
| D10 — File layout | **DEFERRED to workshop 006** | Folder structure is a separate decision space |

---

**Workshop Status**: Draft → ready for user review.

**Next steps**:
1. User reviews; either approves or sends back for refinement
2. Once approved: run `/plan-2c-v2-workshop 023-difficulty-ledger-skill "compound folder layout — per-run isolation"` to lock the file/directory structure (uses the schema this workshop defines)
3. After folder workshop lands: post the minih RFC GitHub issue (references both workshops)
4. plan-3-v2-architect consumes this workshop + the folder workshop + workshop 004 (SDD integration) to produce the implementation task list
