# Workshop: Compound Folder Layout — Per-Run Isolation by Date

**Type**: Storage Design
**Plan**: 023-difficulty-ledger-skill
**Spec**: [difficulty-ledger-skill-spec.md](../difficulty-ledger-skill-spec.md)
**Created**: 2026-05-17
**Status**: Draft

**Value Thesis**: Workshop 005 locked WHAT a retro is (one universal schema, one `.retro.md` per run). This workshop locks WHERE retros live on disk. The current minih convention — one big appended `docs/retros/<slug>.md` per agent — gets messy fast (single-file append-only growth, no per-run addressability, no per-date browsability, no easy pruning, no clean git history per run). The user's stated requirement: `agent / retro / date` style hierarchy so runs are individually addressable and the tree is human-browsable. Without this workshop, compound-2-bubble / compound-3-harvest / minih's auto-harvest each invent their own path policy and the tree drifts. With it, there is one canonical layout, agent-first primary storage + auto-rebuilt plan-indexes for cross-cutting views, and a clean migration story from the current mess.

**Target Proof Level**: Implementation Ready
**Current Proof Level**: Decision Space → Implementation Ready (workshop output)

**Selected Value Axes**:
- **Operator Usability**: the user has to be able to `cd docs/compound/agents/claude-code/2026-05-17/` and ls the runs from one day — that's the literal ergonomic goal
- **Implementation Readiness**: plan-3 needs the exact paths, exact filename pattern, exact index format — this workshop produces them
- **Migration Safety**: existing `docs/retros/*.md` content needs to land cleanly in the new layout without data loss; minih's hardcoded path keeps writing during P1
- **Cross-Domain Coordination**: compound writers, compound readers, minih's auto-harvest, plan-1a Subagent 7, engineering-harness.md template seed all need to agree on paths
- **Cost / Attention Reduction**: indexes (`_LEDGER.md`, `_PLAN.md`, `_AGENT.md`) let the user see "what's open" / "what's in this plan" / "what did this agent produce" without grepping the whole tree

**Related Documents**:
- [Workshop 005 — Universal retro contract](./005-universal-retro-contract.md) — defines the file format (`.retro.md`) and the retro_id pattern this layout uses for filenames
- [Workshop 002 — End-to-end flow](./002-end-to-end-flow.md) — D4 (plan-aware destination logic) is refined here: plan-grouping moves from per-file to auto-rebuilt index
- [Workshop 003 — Compound system map](./003-compound-system-map.md) — § File layout sketch is superseded by this workshop
- [Workshop 004 — SDD integration](./004-sdd-pipeline-compound-integration.md) — compound-2-bubble's destination logic uses paths from this workshop
- Minih's hardcoded path: `/Users/jordanknight/substrate/minih/src/runner/runner.ts` (`buildLedgerDir` returns `docs/retros`) — back-compat read path until P3 migration
- Spec § Q5.3 (auto-move on first compound-0-setup) — refined here: the move becomes a SPLIT (one minih file → many per-run files in the new layout)

---

## Purpose

Lock the on-disk directory structure of `docs/compound/`: where each retro file lives, where the transient buffer lives, where the opt-out sentinel lives, and what gets sliced by agent vs by plan vs by date. **Per KISS revision: no on-disk index/rollup files — `compound-3-harvest` computes cross-cutting views at read time and prints them to the terminal.** Produces a tree diagram, a path resolver function, a runtime-view specification, and a one-time migration recipe from `docs/retros/<slug>.md`.

## Fresh Entrant Outcome

A fresh implementer (or `plan-3-v2-architect`, or a minih maintainer reading the cross-coordination RFC) should be able to use this workshop to reach **Implementation Ready** with no additional context.

They should be able to:

- Read the tree diagram and know exactly where any retro file lives given (agent, date, retro_id)
- Implement `resolvePath(retro)` deterministically
- Implement `rebuildIndexes(root)` for `_LEDGER.md`, `_AGENT.md`, `_DAY.md`, `_PLAN.md`, `_AGENTS.md`, `_PLANS.md`
- Run the one-time migration recipe to split existing `docs/retros/<slug>.md` files into the new per-run layout
- Know where minih continues to write (back-compat) and where compound's reader still picks those up

## Key Questions Addressed

1. Top-level slicing — agent-first, plan-first, date-first, or hybrid?
2. Where does the date live — in directory path or in filename?
3. Where does the `_session-buffer.md` live — root, per-agent, per-session?
4. Are there on-disk index/rollup files, or are cross-cutting views computed at read time?
5. Should `sessions/` be a separate directory (per the original spec sketch) or subsumed?
6. How are old retros pruned/archived? Hard policy or manual?
7. How does the layout coexist with minih's hardcoded `docs/retros/` writes?
8. How are agent slugs sanitized (collisions with `:`/`/` in agent names)?
9. Migration from current `docs/retros/<slug>.md` (one big appended file) — split now or read-both?

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | **Implementation Ready** | plan-3 needs literal paths and a deterministic resolver function |
| Primary Value Axis | **Operator Usability** | The user's literal ask: I should be able to `cd docs/compound/agents/<agent>/<date>/` and see the day's runs |
| Supporting Value Axes | **Implementation Readiness, Migration Safety, Cross-Domain Coordination, Cost / Attention Reduction** | Each shapes a different part of the design: implementation → resolver; migration → split recipe; coordination → minih back-compat; cost → indexes |
| Downstream Loop Improved | **Implementation (plan-3) + Operator daily use** | Plan-3 gets literal paths; daily use gets a browsable tree + at-a-glance indexes |

---

## The Current State (Why We're Refactoring)

Minih today writes to:

```
docs/retros/
├── my-agent.md           # ONE BIG APPENDED FILE per agent
├── plan-6-companion.md   # — grows indefinitely
└── plan-023.md           # ONE BIG APPENDED FILE per planId (when MINIH_PLAN_ID set)
```

Each `<slug>.md` file accumulates `## <ISO timestamp> — <slug> / <runId>` blocks forever. Problems:

1. **No per-run addressability** — to reference one retro you have to scroll/grep inside a 200KB markdown file
2. **No browsability** — `ls docs/retros/` shows N files (where N = agent count); nothing about WHEN they ran
3. **Awkward git history** — every retro commit touches the same big file; per-retro blame is impossible
4. **No clean pruning** — to drop old retros you have to edit-in-place inside the big file
5. **No cross-cutting views** — "show me all retros for plan 023" requires opening BOTH `docs/retros/plan-023.md` AND filtering `docs/retros/<all-agents>.md`
6. **Single-format constraint** — the auto-harvested markdown is the only addressable form; the per-run `report.json` is buried inside `agents/<slug>/runs/<runId>/output/`

The user's quote: "It should be agent slash retro slash date or something like that." This workshop honors that intent and adds the index layer for cross-cutting queries.

---

## Decision Space

### D1 — Top-level slicing: agent-first, plan-first, or hybrid?

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **A** | **Agent-first**: `compound/agents/<slug>/<date>/<retro>.retro.md` | Matches user's literal ask; agent producing the retro is a natural grouping; cross-CLI ergonomic (each CLI's retros live together) | Plan-grouping requires scanning + filtering | Partial |
| **B** | **Plan-first**: `compound/plans/<plan>/<date>/<agent>-<retro>.retro.md` | Easy "all retros for this plan" query | Retros without a plan have no natural home; agent-grouping requires scanning | Rejected — no-plan retros are common (e.g. solo `/plan-6`, casual sessions) |
| **C** | **Date-first**: `compound/retros/<date>/<agent>-<retro>.retro.md` | Single flat date stream; sortable | Loses agent and plan grouping; both require scanning | Rejected |
| **D** | **Agent-first + plan-second via symlinks**: store under agents/; create symlinks in plans/ | Both views first-class | Symlinks are git-flaky on Windows; duplicate state | Rejected |
| **E** | **Agent-first canonical + plan-second via auto-rebuilt index files** (link-only, no symlinks) | Plan view convenient on disk | Indexes are derived state; drift + git noise + ceremony | Rejected (initially selected; reversed in revision per KISS principle) |
| **F** | **Agent-first canonical + plan-second via runtime filter on `frontmatter.plan_id`** (no on-disk index; view computed by `compound-3-harvest` at read time, printed to terminal) | Honors user's ask; one source of truth; no derived state; predictable; zero ceremony | "What's in this plan?" requires running the skill | **Selected** |

**Why F**: agent-first matches the user's literal ergonomic ask AND the cross-CLI reality (each CLI agent groups its own runs). Plan view comes from `compound-3-harvest` filtering retros by `frontmatter.plan_id` at invocation time — printed to the terminal as part of harvest output. NO on-disk index files. This is the KISS choice: source-of-truth retros on disk; everything else is a runtime view.

**Why E was rejected on revision**: Persisting index files creates four problems the system doesn't need — drift between index and source, git diff noise on every harvest, agent maintenance burden, and bureaucratic ceremony (12 maintenance files per 3 retros). The view exists for the moment the user runs harvest; it doesn't need to exist when they aren't looking.

### D2 — Date in directory vs in filename?

| Option | Pattern | Pros | Cons | Decision |
|--------|---------|------|------|----------|
| **A** | Date in dir, time+hash in filename: `agents/<slug>/2026-05-17/T07-30-00Z-a8f3.retro.md` | Browsable by day; filename concise; sortable by time within day | Two-level navigation | **Selected** |
| **B** | Full ISO in filename, no date dir: `agents/<slug>/2026-05-17T07-30-00Z-a8f3.retro.md` | One-level navigation | Filenames get long; days don't group visually; pruning per-day harder | Rejected |
| **C** | Date-day in dir, full ISO in filename: `agents/<slug>/2026-05-17/2026-05-17T07-30-00Z-a8f3.retro.md` | Filename self-describing | Redundant — date appears twice | Rejected |

**Why A**: date directories give daily grouping for free (`ls 2026-05-17/` = the day's runs). The `T<time>-<hash>` filename is short, sortable, unambiguous. Filename DROPS the leading date because the directory carries it.

**Filename pattern**: `T<HH-MM-SS>Z-<hash>.retro.md` (UTC). Hash is the 4-8 char suffix from `retro_id`. Examples:
- `T07-30-00Z-a8f3.retro.md`
- `T14-22-15Z-b9c4.retro.md`

### D3 — Buffer file location

`_session-buffer.md` is the transient buffer that `compound-1-track` writes to during a session and `compound-2-bubble` drains at session end.

| Option | Pattern | Pros | Cons | Decision |
|--------|---------|------|------|----------|
| **A** | Single root file: `compound/_session-buffer.md` | Simple | Two concurrent agents (e.g. main session + a sub-shelled agent) trample each other | Rejected |
| **B** | Per-agent: `compound/_buffers/<agent>.session-buffer.md` | No concurrency issue; per-agent semantics match the storage layout | Slightly more paths to track | **Selected** |
| **C** | Per-session UUID: `compound/_buffers/<session-uuid>.session-buffer.md` | Maximum isolation | "Session" detection is hard; orphaned buffer files accumulate | Rejected |

**Why B**: per-agent matches the per-agent storage layout. Two concurrent agents → two buffer files → no trampling. Agent name comes from whatever CLI is calling compound-1-track (claude-code, codex, github-copilot, opencode, pi, etc., or a specific agent slug like "my-agent" when invoked via minih).

Buffer files live under `_buffers/` (underscore prefix groups them visually; signals "internal/transient"). On compound-2-bubble drain, the buffer file is reset to empty (kept; not deleted — preserves directory structure).

### D4 — Index files: none (KISS revision)

**Decision: NO on-disk index files.** Earlier drafts proposed six (`_LEDGER.md`, `_AGENTS.md`, `_AGENT.md`, `_DAY.md`, `_PLANS.md`, `_PLAN.md`); this was reversed during review per the KISS / information-over-ceremony principle.

All cross-cutting views are **computed at read time** by `compound-3-harvest` and printed to the terminal:

- "All open entries across the tree" → harvest scans `agents/**/*.retro.md`, filters `system.compound.status: open`, clusters by kind+target, prints
- "All retros for plan-023" → harvest scans, filters `frontmatter.plan_id == "023-..."`, prints
- "All retros from agent claude-code this week" → harvest scans, filters `frontmatter.agent == "claude-code"` and date dir within window, prints
- "Stale entries" → harvest scans, filters by age threshold, prints

For ad-hoc browsing without the skill:
- "What ran today?" → `ls docs/compound/agents/*/2026-05-18/` (shell-level)
- "What did claude-code do this week?" → `ls docs/compound/agents/claude-code/`
- "What's in this retro?" → `cat docs/compound/agents/<agent>/<date>/<retro>.retro.md`

The tree IS the source of truth and IS the browse surface. No derived state on disk.

### D5 — `sessions/` directory: keep or subsume?

The original spec (and workshops 002/003) mention a separate `compound/sessions/<date>-<branch>.md` for retros that don't map to a plan. With per-agent + per-date layout, every retro lives under `agents/<slug>/<date>/...` anyway — there's no separate session concept on disk.

| Option | Decision |
|--------|----------|
| **A** | Keep `sessions/` as a separate dir for "no-plan" retros | Rejected — duplicates the agent/date storage with no extra value |
| **B** | Subsume `sessions/` into `agents/<slug>/<date>/` (a retro with `plan_id: null` lives here too; only difference vs plan'd retros is the frontmatter) | **Selected** |

**Why B**: the per-agent + per-date storage IS the session view. A retro is a retro regardless of plan; the plan attribution is metadata, not a path concern. Drops the redundant `sessions/` dir.

**Spec update needed**: AC#9 and the spec's compound-2-bubble Boundary Owns reference `sessions/<date>-<branch>.md` — both need updating to remove that path and reference the agent-first layout. (Tracked in § Acceptance Criteria for plan-3.)

### D6 — Pruning / archival

| Option | Description | Decision |
|--------|-------------|----------|
| **A** | Hard policy: auto-delete retros >90 days old | Rejected — best-effort; user controls their data |
| **B** | Hard policy: auto-archive >90 days into `_archive/<year>/` | Rejected — same issue |
| **C** | **Manual via `/compound-3-harvest --prune --older-than 90d` (dry-run by default, `--apply` to actually delete or archive)** | **Selected** |
| **D** | Never prune | Rejected — directories grow unboundedly |

**Why C**: matches the best-effort framing. User-driven, dry-run-first, explicit `--apply` to write. The flag is documented in `compound-3-harvest`'s SKILL.md but not wired to auto-fire.

### D7 — Minih interaction: leave alone, wrap, or migrate

Minih's hardcoded path (`docs/retros/`) is the elephant. Three options:

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **A** | Leave minih unchanged; compound-3-harvest back-compat-reads `docs/retros/*.md` on every harvest | No minih change; immediate compatibility | Two locations; users still see the messy `docs/retros/` tree | **Selected for v1** |
| **B** | Wrap every minih invocation with `--ledger-dir docs/compound/agents/<slug>/<date>/` | Single canonical location | Requires wrapping every minih call (justfile recipes, scripts, plan-6-companion); minih's auto-harvest defaults break | Rejected for v1 |
| **C** | Minih adopts the universal format + new layout natively (workshop 005 P3 migration) | Cleanest end state | Requires minih PR + release coordination | **Selected for v2** |

**Why A→C**: ship A in v1 (zero minih change; compound reads from both locations); coordinate C via the GitHub issue on `AI-Substrate/minih` (planned for v2). Wrapping minih invocations (B) is rejected because it requires changes everywhere minih is invoked.

### D8 — Agent slug sanitization

Agent names can contain characters that confuse filesystems:
- `claude-code` (safe)
- `plan-6-companion` (safe)
- `minih:my-agent` (colon — most filesystems handle, but Windows historically dislikes)
- `agent/v2` (slash — directory separator!)
- Names with spaces (`my agent`)

| Option | Description | Decision |
|--------|-------------|----------|
| **A** | Slugify aggressively: replace `[^a-z0-9-]` with `-`; lowercase | Selected |
| **B** | Reject non-slug agent names with a validation error | Rejected — too strict |
| **C** | Preserve original; let filesystem decide | Rejected — fragile cross-platform |

**Why A**: slugify on the way IN. Original agent name preserved in frontmatter (`agent: <original>`). Directory uses the slug. Collision resolution: append a hash if two different agents slug to the same value (rare — `claude-code` and `Claude-Code` would both slug to `claude-code`; the second would become `claude-code-2`).

Examples after slugify:
- `claude-code` → `claude-code`
- `Claude-Code` → `claude-code`
- `minih:my-agent` → `minih-my-agent`
- `agent/v2` → `agent-v2`
- `my agent` → `my-agent`

### D9 — Migration from `docs/retros/<slug>.md` (one big appended file)

`compound-0-setup` runs the migration. The OLD spec Q5.3 said "auto-move docs/retros/ → docs/compound/" which is too coarse — minih's existing files are one-big-appended-markdown per agent, but the NEW layout wants per-run files. So the migration is a **split**, not a move.

| Option | Description | Decision |
|--------|-------------|----------|
| **A** | Move whole files: `docs/retros/<slug>.md` → `docs/compound/agents/<slug>/_LEGACY.md`; new retros go to per-run layout | Partial — preserves data; doesn't split |
| **B** | **Split: parse each `## <ISO>` block in `docs/retros/<slug>.md`; create one per-run file per block at `docs/compound/agents/<slug>/<date>/T<time>-<hash>.retro.md`; use the block's runId for the file hash; convert minih block format → universal `.retro.md`** | **Selected** |
| **C** | Don't migrate; leave old files alone; new writes go to new layout; compound-3-harvest back-compat-reads old files forever | Rejected — leaves the mess in place forever |

**Why B**: matches the user's stated goal ("not just all in one big markdown file per agent like it is at the moment, which is quite messy"). The split is mechanical (parse minih's well-known block format; convert each block to a universal retro using the `minihToUniversal()` mapping from workshop 005). One-time operation; leaves a breadcrumb at `docs/retros/.split-to-compound` pointing at the new locations.

**During the split**:
- Each block becomes one `.retro.md` file
- File path derived from the block's timestamp + runId
- Universal schema applied (frontmatter has `schema_version: "1.0"`)
- `system.minih.run_dir` preserved from the block
- Original `docs/retros/*.md` files KEPT (renamed to `*.legacy.md`) until the user manually deletes — reversible

---

## Recommended Direction: The Layout

### Canonical Tree

```
docs/compound/
├── README.md                                       convention guide (compound-0-setup creates)
├── .disabled                                       (optional) opt-out sentinel — presence makes compound silent
├── _buffers/                                       transient per-agent session buffers
│   ├── README.md                                   explains buffer semantics (compound-0-setup creates)
│   ├── .gitignore                                  *.session-buffer.md (transient; not committed)
│   ├── claude-code.session-buffer.md               (drained by compound-2-bubble)
│   ├── plan-6-companion.session-buffer.md
│   └── codex.session-buffer.md                     (one per active CLI agent)
└── agents/                                         primary per-agent storage — the ONLY source of truth
    ├── claude-code/
    │   ├── 2026-05-17/
    │   │   ├── T07-30-00Z-a8f3.retro.md
    │   │   ├── T08-45-00Z-b9c4.retro.md
    │   │   └── T14-22-15Z-c1d5.retro.md
    │   └── 2026-05-18/
    │       └── T10-15-00Z-d2e6.retro.md
    ├── plan-6-companion/
    │   └── 2026-05-17/
    │       └── T09-15-00Z-e3f7.retro.md
    └── minih-my-agent/                             (sanitized from "minih:my-agent")
        └── 2026-05-17/
            └── T11-00-00Z-f4a8.retro.md
```

**That's it.** Three top-level entries (`README.md`, `_buffers/`, `agents/`) plus the optional `.disabled` sentinel. No index files. No `plans/` directory. Every other view is computed by `compound-3-harvest` at read time and printed to terminal.

**Coexistence with minih's `docs/retros/`** (during v1, before P3 migration):

```
docs/retros/                          minih's legacy path; still written-to by minih's auto-harvest
├── my-agent.md                       minih continues appending here
├── plan-023.md                       (when MINIH_PLAN_ID=plan-023 set at run-time)
└── .split-to-compound                breadcrumb after compound-0-setup runs migration
```

`compound-3-harvest` reads BOTH `docs/compound/agents/**/*.retro.md` AND `docs/retros/*.md` (back-compat block parser).

### Path Resolver Function

```typescript
function resolvePath(retro: Retro, root: string = "docs/compound"): string {
  const agentSlug = slugify(retro.agent);
  const date = retro.started_at.slice(0, 10);           // "2026-05-17"
  const time = retro.started_at.slice(11, 19).replaceAll(":", "-");  // "07-30-00"
  const hash = retro.retro_id.split("-").pop();         // "a8f3" (last segment)

  return `${root}/agents/${agentSlug}/${date}/T${time}Z-${hash}.retro.md`;
}

function slugify(agent: string): string {
  return agent.toLowerCase().replace(/[^a-z0-9-]/g, "-").replace(/-+/g, "-").replace(/^-|-$/g, "");
}
```

Deterministic from any valid retro. No I/O. Reverse-derivable: given a path, you can extract the agent slug + date + time + hash.

### Runtime Views (what `compound-3-harvest` prints)

No on-disk index files. The skill computes and prints the cross-cutting views when invoked:

**Default invocation `/compound-3-harvest`** — full dashboard:

```
🌾 Compound harvest — 2026-05-18T15:30:00Z

📚 Scanned 27 retros across 3 agents (claude-code, plan-6-companion, minih-my-agent)
   Date range: 2026-04-10 → 2026-05-18
   Total entries: 47 (28 open, 17 encoded, 2 wontfix)

📊 Open clusters (top 10 by recurrence > severity > age):
   1. [tooling] grep/search slowness — 4 entries (claude-code: 3, plan-6-companion: 1)  [r/w/s]
   2. [pipeline] missing example patterns — 3 entries  [r/w/s]
   3. [config] env var contract guessing — 2 entries  [r/w/s]
   ...

⏰ Stale (>4 weeks open): 3 entries
   - DL-061 (2026-04-10): "spec template § Domain Manifest unclear"  [r/w/s]
   ...

✅ Recently encoded (last 7 days): 6 entries — see scratch/encode-*.diff for the diffs

[s/t/p/e/d/a/r/w/s]: ▮
```

**Scoped invocations**:

```
/compound-3-harvest --plan 023-difficulty-ledger-skill
→ same dashboard, but filtered to retros where frontmatter.plan_id == "023-difficulty-ledger-skill"

/compound-3-harvest --agent claude-code
→ filtered to retros where frontmatter.agent == "claude-code"

/compound-3-harvest --since 2026-05-15
→ filtered to retros where directory date >= 2026-05-15

/compound-3-harvest --kind magic-wand
→ filtered to entries where entry.kind == "magic-wand"
```

Combinable: `/compound-3-harvest --plan 023-difficulty-ledger-skill --since 2026-05-15 --kind difficulty`.

**Shell-level ad-hoc browse** (no skill needed):

```
$ ls docs/compound/agents/*/2026-05-18/                # what ran today
$ ls docs/compound/agents/claude-code/                  # claude-code's date dirs
$ cat docs/compound/agents/claude-code/2026-05-18/*.retro.md  # cat them
$ grep -l "plan_id: 023-" docs/compound/agents/*/*/*.retro.md  # find all plan-023 retros
```

The tree IS the dashboard.

---

## UX Walkthroughs

### Walkthrough A: Minih agent finishes a run; auto-harvest writes universal retro

```
$ MINIH_PLAN_ID=023-difficulty-ledger-skill minih run my-agent

[my-agent runs; emits retrospective at end via report.json]
[minih's runner (P1 dual-write phase) ALSO writes universal retro]

[Files written]:
  agents/my-agent/runs/2026-05-17T11-00-00-000Z/output/report.json
  agents/my-agent/runs/2026-05-17T11-00-00-000Z/output/retro.retro.md
  docs/retros/my-agent.md                                              (legacy append; minih unchanged)
  docs/retros/023-difficulty-ledger-skill.md                          (legacy per-plan append)
  docs/compound/agents/minih-my-agent/2026-05-17/T11-00-00Z-f4a8.retro.md  (NEW universal path)

[stdout]:
✅ Run complete. Retro at docs/compound/agents/minih-my-agent/2026-05-17/T11-00-00Z-f4a8.retro.md
   Legacy paths also written: docs/retros/my-agent.md, docs/retros/023-difficulty-ledger-skill.md
```

### Walkthrough B: User runs `/compound-3-harvest`

```
$ /compound-3-harvest

[Read pass]:
  agents/**/*.retro.md         (canonical universal format)
  docs/retros/*.md             (legacy block format; parsed via back-compat reader)

[Found 27 retros total (19 universal, 8 legacy-format)]
[Deduplicated by retro_id (legacy entries match their universal counterparts after migration)]
[Curated: 47 entries; 28 open, 17 encoded, 2 wontfix]

[No index files written — view computed in memory and printed below]

[stdout]:
🌾 Compound harvest — 2026-05-18T15:30:00Z
   Scanned 27 retros across 3 agents.
   Total entries: 47 (28 open, 17 encoded, 2 wontfix).

   Top open clusters:
   1. [tooling] grep/search slowness — 4 entries [r/w/s]
   ...

   Stale (>4 weeks open): 3 entries
   Recently encoded (last 7 days): 6 entries

[s/t/p/e/d/a/r/w/s]: ▮
```

### Walkthrough C: User runs migration on a fresh-from-compound-0-setup repo

```
$ /compound-0-setup

📁 Creating docs/compound/ directory structure...
  ✅ docs/compound/README.md
  ✅ docs/compound/_buffers/README.md
  ✅ docs/compound/agents/.gitkeep
  ✅ docs/compound/plans/.gitkeep

🔍 Detected docs/retros/ — running one-time split migration...
  📄 Parsing docs/retros/my-agent.md (12 blocks)
    ✅ Split → docs/compound/agents/my-agent/2026-04-10/T08-15-00Z-3b2c.retro.md
    ✅ Split → docs/compound/agents/my-agent/2026-04-12/T14-30-00Z-9a8e.retro.md
    ...
  📄 Parsing docs/retros/plan-023.md (5 blocks)
    ✅ Split → docs/compound/agents/<respective agent>/...  (each block routed to its origin agent)

  📋 Migration summary: 47 blocks → 47 .retro.md files across 5 agent dirs and 12 date dirs

  📌 Renaming docs/retros/*.md → docs/retros/*.legacy.md (reversible)
  📌 Writing breadcrumb: docs/retros/.split-to-compound

⚠️ Staged diffs for the user to review:
  - scratch/compound-setup-AGENTS.md.diff
  - scratch/compound-setup-CLAUDE.md.diff
  - scratch/compound-setup-README_AGENTS.md.diff
  - scratch/compound-setup-justfile.diff

✅ Compound system bootstrapped. Review staged diffs and `git apply` to land.
```

### Walkthrough D: Browsing the tree manually

```
$ ls docs/compound/agents/claude-code/2026-05-17/
T07-30-00Z-a8f3.retro.md
T08-45-00Z-b9c4.retro.md
T14-22-15Z-c1d5.retro.md

$ cat docs/compound/agents/claude-code/2026-05-17/T07-30-00Z-a8f3.retro.md
[universal .retro.md with YAML frontmatter; entries; free-text body]

$ ls docs/compound/agents/*/2026-05-17/                # everything that ran today
docs/compound/agents/claude-code/2026-05-17/T07-30-00Z-a8f3.retro.md
docs/compound/agents/claude-code/2026-05-17/T08-45-00Z-b9c4.retro.md
docs/compound/agents/claude-code/2026-05-17/T14-22-15Z-c1d5.retro.md
docs/compound/agents/plan-6-companion/2026-05-17/T09-15-00Z-e3f7.retro.md

$ grep -l 'plan_id: "023-' docs/compound/agents/*/*/*.retro.md  # all plan-023 retros
docs/compound/agents/claude-code/2026-05-17/T07-30-00Z-a8f3.retro.md
docs/compound/agents/claude-code/2026-05-17/T14-22-15Z-c1d5.retro.md
docs/compound/agents/plan-6-companion/2026-05-17/T09-15-00Z-e3f7.retro.md
```

The tree IS browsable directly with `ls`, `cat`, and `grep`. For curated/clustered views, run `/compound-3-harvest` (with optional `--plan` / `--agent` / `--since` filters).

---

## Edge Cases

### EC1 — Multiple concurrent agents in one repo

Per-agent buffer files (D3-B) prevent buffer-write collision. Each agent's retros land under its own `agents/<slug>/<date>/` dir — no cross-agent collision.

### EC2 — Date directory crosses midnight UTC

`started_at` is the authoritative source. A retro that begins at 23:58 UTC and ends at 00:05 UTC the next day lives under the start date's directory. No splitting. Consistent.

### EC3 — Hash collision

`retro_id`'s hash is 4-8 hex chars. At 4 chars: 1/65536 collision per second. The file resolver appends `-2`, `-3`, etc. to the filename on collision: `T07-30-00Z-a8f3-2.retro.md`. Producers SHOULD use ≥6 chars for high-frequency agents (workshop 005 § EC7).

### EC4 — Empty day (no retros)

No directory created. `ls agents/<slug>/` shows only days that had activity. Sparse tree.

### EC5 — Agent slug collision after slugify

Two agents `claude-code` and `Claude-Code` both slug to `claude-code`. Resolver appends `-2`: second agent lives at `agents/claude-code-2/`. Original agent name preserved in `frontmatter.agent`. Rare.

### EC6 — Plan slug missing in frontmatter

Retro with `plan_id: null` doesn't appear in any `_PLAN.md`. Still appears in `_AGENT.md` and `_DAY.md` and `_LEDGER.md`. Fine.

### EC7 — User deletes a retro file manually

Compound is read-mostly. Deletion is fine. On next `/compound-3-harvest`, the deleted retro disappears from all indexes. No referential-integrity drama.

### EC8 — `.disabled` sentinel toggling mid-week

If sentinel appears: all compound writes silently no-op (compound-1-track / compound-2-bubble / compound-3-harvest). Existing files remain on disk; indexes don't update. If sentinel disappears: compound resumes; next harvest rebuilds indexes including any new retros minih added (auto-harvest) during the disabled period.

### EC9 — Minih writes to `docs/retros/` after migration

Expected during P1. compound-3-harvest reads BOTH locations (`docs/compound/agents/**/*.retro.md` + `docs/retros/*.md`). The back-compat reader parses minih's append-only block format on-the-fly; the per-block files are NOT re-split into the new layout on every harvest (would create duplicates). Only `compound-0-setup`'s one-time migration splits.

### EC10 — Two retros with same start time (different agents)

Different `agent` slugs → different `agents/<slug>/<date>/` dirs → no collision.

### EC11 — Plan-slug change mid-life (`plan-023-foo` renamed to `plan-023-bar`)

`_PLAN.md` indexes are auto-rebuilt from `frontmatter.plan_id` — if the user updates all the retro frontmatter via search/replace, the next harvest moves the entries to the new plan dir's index. If the user only renames the directory `docs/plans/<old>` → `docs/plans/<new>`, the index points get stale until next harvest rebuilds.

---

## Migration Recipe (one-time, during `/compound-0-setup`)

```typescript
async function migrateDocsRetros(repoRoot: string): Promise<MigrationReport> {
  const retrosDir = path.join(repoRoot, "docs/retros");
  if (!await exists(retrosDir)) return { skipped: true, reason: "no docs/retros/" };

  if (await exists(path.join(retrosDir, ".split-to-compound"))) {
    return { skipped: true, reason: "already migrated (breadcrumb present)" };
  }

  const files = await glob("*.md", { cwd: retrosDir });
  let totalBlocks = 0;
  let written: string[] = [];

  for (const file of files) {
    const content = await readFile(path.join(retrosDir, file));
    const blocks = parseMinihBlocks(content);   // splits on /^## \d{4}-\d{2}-\d{2}T/m
    for (const block of blocks) {
      const minihRetro = blockToMinihRetro(block);   // legacy block → MinihRetrospective
      const universal = minihToUniversal(minihRetro, blockMeta(block));   // from workshop 005
      const path = resolvePath(universal, "docs/compound");   // from § Path Resolver above
      await writeFile(path, renderRetroMd(universal));
      written.push(path);
      totalBlocks++;
    }
    // Rename original to .legacy.md for reversibility
    await renameFile(
      path.join(retrosDir, file),
      path.join(retrosDir, file.replace(/\.md$/, ".legacy.md"))
    );
  }

  // Breadcrumb
  await writeFile(
    path.join(retrosDir, ".split-to-compound"),
    `Migrated ${totalBlocks} blocks → docs/compound/agents/.../*.retro.md on ${new Date().toISOString()}\n`
    + `Originals renamed to *.legacy.md (kept for reversal; safe to delete).\n`
  );

  return { ok: true, blocks: totalBlocks, written };
}
```

Reversible — user can `git mv *.legacy.md *.md` and `git rm .split-to-compound` if they want to roll back.

---

## Open Questions

### Q1 — Should `_index` files be auto-committed?

**RESOLVED — obsolete**. The KISS revision (D4) dropped all on-disk index files. Cross-cutting views are computed at read time by `compound-3-harvest` and printed to terminal. There's nothing to commit.

### Q2 — How does `compound-3-harvest` handle dual-source dedup?

**OPEN**. Once minih dual-writes (workshop 005 P1), each retro exists at TWO locations:
- `docs/retros/<agent>.md` (block-format inside minih's append-only file)
- `docs/compound/agents/<agent>/<date>/T<time>-<hash>.retro.md` (universal format)

Both have the same `retro_id`. The harvest reader must dedup.

**Tentative**: dedup by `retro_id`. The universal file wins (richer schema). The legacy block is skipped if a matching universal file exists. Simple.

### Q3 — When does `compound-0-setup` re-check / re-migrate?

**OPEN**. On re-invocation, the breadcrumb tells compound-0-setup migration already ran. But what if NEW minih files appeared in `docs/retros/` since the migration? Re-split them?

**Tentative**: yes, idempotent re-split — `compound-0-setup --migrate` scans `docs/retros/*.md` for blocks not yet in `docs/compound/agents/.../`, splits only those. Default behavior on re-invocation is to suggest the migration; user runs with `--migrate` to apply.

### Q4 — Should `_buffers/` be `.gitignore`d?

**OPEN**. Buffer files are transient — drained by compound-2-bubble. Committing the buffer mid-write is noise.

**Tentative**: yes, `_buffers/*.session-buffer.md` is gitignored. The `_buffers/README.md` is committed. Add a `.gitignore` entry in `compound/_buffers/.gitignore` (local; doesn't pollute the root .gitignore).

### Q5 — Per-CLI-session UUIDs vs per-agent buffer?

**OPEN**. Per-agent buffer (D3-B) is selected. But two simultaneous Claude Code sessions on the same repo would share the buffer.

**Tentative**: per-agent + PID-suffix in the buffer filename for true isolation: `claude-code-pid-12345.session-buffer.md`. Drained buffers are cleaned up at session end. Adds complexity; defer unless dogfood shows it matters.

### Q6 — How does the layout work in monorepos with multiple `docs/compound/` candidates?

**OPEN**. compound-0-setup runs at one location. If a repo has nested projects each wanting their own ledger?

**Tentative**: out of scope for v1. Each compound install is scoped to a single repo. Nested ledgers can be re-explored if dogfood surfaces need.

### Q7 — `.legacy.md` files — keep forever?

**OPEN**. After the split migration, originals are renamed to `.legacy.md`. They sit there indefinitely.

**Tentative**: leave them. They're small (markdown), reversible, and don't affect compound's reads. User can `git rm docs/retros/*.legacy.md` after confidence in the migration (≥1 month dogfood).

---

## Acceptance Criteria for plan-3-v2-architect

When plan-3 consumes this workshop, it should produce tasks for:

- [ ] **Implement `resolvePath()` helper** in `skills/compound/lib/paths.ts` per § Path Resolver Function
- [ ] **Implement `slugify()` helper** per D8
- [ ] **`compound-0-setup` SKILL.md**: creates the canonical tree per § Canonical Tree; creates `README.md` files at root and in `_buffers/`; runs the migration recipe per § Migration Recipe; writes breadcrumb at `docs/retros/.split-to-compound`
- [ ] **`compound-1-track` SKILL.md**: writes to `docs/compound/_buffers/<agent>.session-buffer.md` (per-agent path; auto-creates if missing)
- [ ] **`compound-2-bubble` SKILL.md**: drains buffer; writes one `.retro.md` per save action via `resolvePath()`; updates frontmatter `plan_id` from cwd/branch detection. NO index file writes.
- [ ] **`compound-3-harvest` SKILL.md**: reads `docs/compound/agents/**/*.retro.md` AND `docs/retros/*.md` (back-compat); validates each retro against `retro.schema.json`; dedups by `retro_id`; computes cross-cutting views (clusters, stale, recently-encoded) in memory; **prints to terminal — writes nothing to disk** (no index files); supports `--plan <slug>` / `--agent <slug>` / `--since <date>` / `--kind <kind>` runtime filters; supports `--prune --older-than 90d --apply` (dry-run by default) for archival
- [ ] **Spec updates**: remove `docs/compound/sessions/<date>-<branch>.md` mentions (D5 subsumes); remove any `_LEDGER.md` mentions (D4 KISS revision); update AC#9 to reference `docs/compound/agents/<slug>/<date>/T<time>Z-<hash>.retro.md`; update spec § Q5.3 to reference the split (not move); update spec § Target Domains `docs/compound/` row to reference per-agent + per-date layout with no index files; AC#13 wording should describe in-memory view (not index file)
- [ ] **`docs/compound/_buffers/.gitignore`**: contains `*.session-buffer.md` per Q4 tentative
- [ ] **Test fixtures**: include a sample `docs/retros/my-agent.md` (legacy format, 5 blocks) + the expected split output (5 `.retro.md` files in correct paths) in `skills/compound/lib/fixtures/`

---

## Validation / Acceptance

This workshop reaches its target proof level when:

- [x] Canonical tree diagram covers every file/directory compound writes/reads
- [x] `resolvePath()` function is deterministic; given any valid retro, the path is computable with no I/O
- [x] Runtime views (what `compound-3-harvest` prints) have concrete terminal-output examples — no on-disk index files per KISS revision
- [x] Migration recipe is mechanical (parse blocks → call workshop 005 mapping → write per-run files)
- [x] Coexistence story with minih's `docs/retros/` is explicit (back-compat read; dual-source dedup; user-visible during P1)
- [x] At least four worked walkthroughs cover: minih write, compound harvest, migration, manual browsing
- [x] Edge cases include slug collisions, hash collisions, empty days, sentinel toggle, plan-slug change, dual-source dedup
- [x] Acceptance criteria list is 10 surgical tasks plan-3 can consume
- [ ] Reviewed by user (next step — approve OR send back)

---

## Attention Reduction

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Implementation (plan-3) | Spec says "docs/compound/" with vague sub-paths (`<plan-slug>.md`, `sessions/<date>-<branch>.md`, `<agent-slug>.md`) — no resolver, no view design, no migration recipe | Verbatim minimal tree (just `agents/<slug>/<date>/<retro>.retro.md` + buffer + README); verbatim resolver; runtime-view filters; reversible migration recipe — no index files to maintain |
| Daily operator use | One big appended `<slug>.md` per agent; grep to find a run; no per-day view; no per-plan view; awkward git history | Browsable tree; `_DAY.md` for day-view; `_PLAN.md` for plan-view; `_LEDGER.md` for global open-entry view; clean git history per retro |
| Harvest performance | Reads N files (one per agent), parses N append-only docs, indexes from scratch | Reads M small files (one per run); pre-built indexes; incremental rebuild on bubble drains |
| Migration confidence | Spec Q5.3 said "auto-move docs/retros/ → docs/compound/" — coarse-grained, leaves files lumped | Split recipe; reversible; breadcrumb; dual-source coexistence during P1 |
| Agent execution | Producers had to figure out which destination path to use (plan? session?) | One resolver function; frontmatter carries plan attribution; producers just call `resolvePath(retro)` |
| Onboarding | New contributor would see compound as "ledger files in docs/compound/" with no clear layout | New contributor reads § Canonical Tree and immediately knows where everything lives |
| Pruning | No story | Manual `--prune --older-than 90d` with dry-run-first |

---

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| Current-state critique (6 problems with minih's one-big-file) | § "The Current State" | Decision context — why we're refactoring | Ready |
| Decision space (D1–D9) | § "Decision Space" | Each layout choice with selected option + rationale | Ready |
| Canonical tree diagram | § "Canonical Tree" | The literal directory structure | Ready |
| `resolvePath()` + `slugify()` TypeScript pseudocode | § "Path Resolver Function" | Deterministic resolver for plan-3 to implement | Ready |
| Runtime view examples (harvest terminal output, with `--plan` / `--agent` / `--since` / `--kind` filters) | § "Runtime Views (what compound-3-harvest prints)" | The transient terminal output that replaces on-disk indexes per KISS revision | Ready |
| Migration recipe (TypeScript) | § "Migration Recipe" | One-time split logic; reversible; breadcrumb | Ready |
| Four walkthroughs (minih write / harvest / migration / browse) | § "UX Walkthroughs" | End-to-end usage scenarios | Ready |
| Eleven edge cases (EC1–EC11) | § "Edge Cases" | Behavior under unusual conditions | Ready |
| 7 open questions with tentative answers | § "Open Questions" | Soft items for post-dogfood revisit | Draft |
| 10-item plan-3 acceptance criteria list | § "Acceptance Criteria for plan-3" | Direct consumption surface for plan-3 | Ready |

---

## Decision Space — Summary Reference

| Decision | Selection | Rationale (one-line) |
|----------|-----------|---------------------|
| D1 — Top-level slicing | **F** (agent-first primary + plan-second via runtime filter on `frontmatter.plan_id`; no on-disk indexes) | Honors user's literal ask; plan view via runtime filter — predictable, source-of-truth on disk, zero ceremony |
| D2 — Date placement | **A** (date in dir; `T<time>Z-<hash>.retro.md` in filename) | Daily grouping for free; short filenames; sortable |
| D3 — Buffer location | **B** (per-agent under `_buffers/<agent>.session-buffer.md`) | No concurrency issue; matches storage layout |
| D4 — Index files | **None** (KISS revision) | Source-of-truth retros only on disk; cross-cutting views computed by `compound-3-harvest` at read time and printed to terminal |
| D5 — `sessions/` directory | **B** (subsume into per-agent + per-date) | Removes redundancy; one storage path |
| D6 — Pruning | **C** (manual `--prune --older-than 90d` with dry-run-first) | Best-effort; user-driven |
| D7 — Minih interaction | **A in v1** (leave alone; back-compat-read `docs/retros/`) → **C in v2** (minih adopts universal natively) | Zero minih change for v1; coordinated v2 via RFC issue |
| D8 — Agent slug sanitization | **A** (slugify on the way in; original preserved in frontmatter; collisions get `-N` suffix) | Cross-platform safe |
| D9 — Migration | **B** (split, not move; reversible; `.legacy.md` rename + breadcrumb) | Lifts old data into new layout with no loss |

---

**Workshop Status**: Draft → ready for user review.

**Next steps**:
1. User reviews; either approves or sends back for refinement
2. Once approved: the three remaining queued workshops (bubble-up CLI flow, AGENTS.md voice, harvest companion behavior) are independent — can run in any order before `/plan-3-v2-architect`
3. Once all workshops land: post the minih RFC GitHub issue (now has concrete folder-layout proposal to share) — references workshop 005 (schema) + workshop 006 (layout)
4. Then: `/plan-3-v2-architect` consumes workshops 002, 003, 004, 005, 006 (and the remaining 3 once done) → Group E task list with surgical precision
