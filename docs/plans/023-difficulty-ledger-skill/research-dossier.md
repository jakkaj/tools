# Research Report: Self-Improving Difficulty-Ledger / Magic-Wand Skill

**Generated**: 2026-05-16
**Research Query**: "Extract a new self-improving skill that codifies difficulty ledgers + magic wands + retros as a first-class, repo-wide concern (not bound to minih). Reminds agents to create a ledger if missing, encode fixes back into the engineering harness/justfile/AGENTS.md, log entries during work, and bubble suggestions up to the user at session end so the user can choose to convert any entry into a fix-task or full plan."
**Mode**: Pre-Plan
**Location**: `docs/plans/023-difficulty-ledger-skill/research-dossier.md`
**FlowSpace**: Not used — meta/design research on this repo's own skills, not a production codebase
**Findings**: 18 (across 4 focus areas)

---

## Executive Summary

### What this skill would be

A **session-scoped, write-then-bubble-up skill** that turns every agent session — planning, coding, reviewing, refactoring, debugging — into a contributor to a portable, repo-wide **difficulty ledger** at `docs/retros/`. Difficulties, magic-wands, and "gifts to future self" (encoded fixes) are captured as the agent works, then surfaced as a single **end-of-session suggestion summary** with one-keystroke routes to either ignore, save, or escalate to a fix-task / full plan.

The skill is **portable** — it works inside Claude Code, Codex CLI, Copilot CLI, Pi, OpenCode, or any future CLI that consumes Anthropic SKILL.md. It interoperates with minih's auto-harvest (writing to the same `docs/retros/` directory) but does **not require minih** at runtime.

### Business purpose

Three structural problems this addresses:

1. **The compounding-velocity premise of `harness-is-the-product-v2` is currently broken.** The philosophy says "every difficulty catalogued is a gift to future sessions," but in practice, no skill outside `plan-6a-v2-update-progress` writes to `docs/retros/`, and no skill *anywhere* reads from it. The ledger is a write-only journal nobody opens.
2. **Minih is not the only runtime.** Minih's auto-harvest only fires inside `minih run`. The vast majority of agent sessions in this repo (and in users' own projects after `npx skills add`) happen in plain Claude Code, Codex, Pi, etc. — those sessions currently emit zero ledger entries. The 28 non-6a skills have no on-ramp for the ledger.
3. **AGENTS.md is silent on the self-improvement loop.** A user installing these skills into a brand-new project gets the SDD pipeline but no governance pointing at *why* difficulties matter or *how* the ledger sustains the maturity curve. The philosophy is documented in one philosophy skill (`harness-is-the-product-v2`); the operating contract is documented nowhere.

### Key insights

1. **The ledger needs both a portable schema AND interop with minih.** The same `docs/retros/<scope>.md` directory is shared. The new skill writes one entry shape; minih writes another (slightly richer). Both must be readable by the same downstream consumers and by `minih difficulties` aggregation where present.
2. **The "bubble up at end" interaction pattern is the load-bearing UX choice.** Mid-session blocking would create friction the skill is supposed to *eliminate*. The skill should write silently to a session buffer and present a single decision menu when the agent is about to hand back control.
3. **Encoding suggestions are the highest-leverage outputs.** The user's framing — "we should then encode it properly, so then it's a gift to our future selves" — means every difficulty entry should be paired with a candidate **encoded form**: a justfile recipe, a CLAUDE.md/AGENTS.md snippet, a script, a SKILL.md edit, a fixture. Difficulty without encoding suggestion = noise.

### Quick stats

- **Components affected**: 1 new skill + 5 existing skills (governance updates) + 1 new directory (`docs/retros/`) + AGENTS.md additions
- **Dependencies**: Standard tools only (Read/Write/Bash); optional minih interop where minih is present
- **Test coverage**: N/A (skill = markdown; correctness verified by behavioral observation, not unit tests)
- **Complexity**: CS-3 (medium) — surface area is small but the schema, interop, and bubble-up UX need workshopping
- **Prior learnings**: 4 directly relevant (PL-01 to PL-04 below)
- **Domains**: This repo doesn't use the formal `docs/domains/` system. The new skill belongs alongside `harness-is-the-product-v2` and `agent-harness-v2` in `skills/SDD/` (or possibly a new `skills/general/` entry if framed as universal). Categorization deferred to spec.

---

## How It Currently Works (the gap, mapped)

### Existing producers of "difficulty-shaped" data

| Producer | Format | Destination | Triggered when |
|---|---|---|---|
| `plan-6a-v2-update-progress` Step 8 | `OH-XXX` IDs in retro JSON: `magicWand`, `magicWandTarget`, `difficulties[]`, `workedWell` | `docs/retros/<plan-slug>.md` (paired entry) AND phase tasks.md `### Orchestrator Retrospective` subsection | `--retrospective` flag passed on the **last task of a phase** by `plan-6` |
| `plan-6a-v2-update-progress` Step 9 | Companion farewell envelope: `MH-XXX` IDs, same shape | `docs/retros/<plan-slug>.md` (paired alongside orchestrator) | `--companion-run-id` flag passed by `plan-6-companion` |
| `plan-6-v2-implement-phase` (during impl) | Free-form rows in `## Discoveries & Learnings` table | `tasks.md` or plan inline | "When you encounter: something unexpected, needed research, hit a trouble spot, gotcha, decision, debt, insight" |
| Minih runtime (auto-harvest) | Full retrospective JSON | `docs/retros/<agent-slug>.md` per run; `docs/retros/<plan-id>.md` if `MINIH_PLAN_ID` env var set | After every minih run completes |

### Existing consumers

| Consumer | Reads from | Reads what |
|---|---|---|
| `plan-1a-v2-explore` Subagent 7 ("Prior Learnings Scout") | `docs/plans/*/tasks/*/tasks.md`, `docs/plans/*/*.md`, `docs/plans/*/tasks/*/execution.log.md` | `## Discoveries & Learnings` tables — the **older** convention, **NOT** `docs/retros/` |
| Human via `minih difficulties` CLI | Minih run dirs | Aggregated difficulties across runs |

### The hole

**Nothing reads `docs/retros/`.** The directory was added by the harness-integration plan (017) and the plan-6a retro-harvest (post-017). Both paired-entry writers (orchestrator + companion) land here. Minih's auto-harvest also lands here. But:

- `plan-1b-v2-specify` doesn't read it before drafting goals
- `plan-2-v2-clarify` doesn't read it before asking clarifications
- `plan-3-v2-architect` doesn't read it before phase design
- `plan-5-v2-phase-tasks-and-brief` doesn't inject ledger entries into context briefs
- `plan-7-v2-code-review` doesn't cross-check phases against open OH-/MH- entries
- `agent-harness-v2` doesn't seed its template's `## History` table with ledger entries
- AGENTS.md doesn't even mention the ledger exists
- **Most importantly**: no skill exists that lets a *non-minih* session contribute to the ledger at all

This is the gap the new skill fills. It's specifically the **producer** for non-minih sessions plus the **bubble-up UX** that turns silent journaling into actionable user choices.

---

## Architecture & Design (proposed)

### Skill shape

**Working name**: `gifts-v2` — short for "gifts to your future self," the load-bearing metaphor from `harness-is-the-product-v2` Principle 2.

Alternate names to consider (deferred to spec): `difficulty-ledger-v2`, `encode-difficulties-v2`, `self-improve-v2`, `retro-buffer-v2`, `magic-wand-v2`. The user's vibe ("gifts to future self") favors `gifts-v2`. Final naming should be workshopped or polled.

### Three modes of operation

1. **`init` mode** — first-run setup
   - Scaffold `docs/retros/` if missing
   - Write `docs/retros/README.md` (the convention guide)
   - Write/touch `docs/retros/_session-buffer.md` (the in-session scratch)
   - Inject (or suggest injecting) a "Self-Improvement Loop" section into `AGENTS.md` / `CLAUDE.md`
   - Inject (or suggest injecting) `just retro` recipes into `justfile` if one exists
   - Detect if the project uses minih → if yes, link convention to minih's harvest path; if no, skip minih references

2. **`log` mode** — write a single entry (called by other skills or user mid-session)
   - Append a YAML-fenced entry to `docs/retros/_session-buffer.md`
   - Auto-number (DL-001, DL-002, …) within the session
   - Silent — no prompt to user, no blocking
   - Returns the entry ID for the calling skill to reference in its own output

3. **`bubble` mode** — end-of-session summary (auto-invoked or user-called)
   - Read `docs/retros/_session-buffer.md`
   - Present a single, scannable summary to the user with per-entry actions:
     - `[s]ave` to permanent ledger (`docs/retros/<scope>.md`) and continue
     - `[t]ask` → emit a `/plan-5-v2-phase-tasks-and-brief --fix "<entry>"` invocation suggestion
     - `[p]lan` → emit a `/plan-1b-v2-specify` invocation suggestion seeded from the entry
     - `[e]ncode` → emit a candidate justfile/AGENTS.md/SKILL.md edit
     - `[d]ismiss` → drop the entry
     - `[a]ll save` → save everything as-is, no escalations
   - After user's choice, clear the buffer

### Schema (portable, non-minih)

```yaml
# Each entry in docs/retros/_session-buffer.md or docs/retros/<scope>.md
---
id: DL-001                      # auto-assigned within scope (DL = Difficulty Ledger)
ts: 2026-05-16T14:32Z
type: difficulty | magic-wand | gift | insight
source:                         # what was happening when this surfaced
  skill: <slug or "ad-hoc">
  task: <task-id or null>
  plan: <plan-slug or null>
category: build | config | data | test | debug | knowledge | tooling | docs | agent-harness | engineering-harness | coordination | skill-design | other
severity: blocker | high | medium | low    # difficulty only; null for magic-wand/gift/insight
target: agent-harness | engineering-harness | project | docs | coordination | tooling | skills    # magic-wand only
description: |
  What hurt, or what's wished, or what was encoded.
workaround: |                   # difficulty only
  How you got around it in the moment.
suggested-encoding:             # the "gift" suggestion — what should it become?
  kind: justfile-recipe | agents-md-snippet | claude-md-snippet | script | skill-edit | fixture | doc-page | adr
  target-file: <path>           # where the encoding would live
  sketch: |
    Concrete sketch of the recipe/snippet/script body.
status: open | suggested | encoded | wontfix
resolved-by: <commit | PR | plan-NNN | null>
---
```

**Why YAML-in-markdown**: human-skimmable in raw form, machine-parseable, and `npx skills`-portable (no schema validator dependency). Matches the conventions in this repo (plan frontmatter, SKILL.md frontmatter).

**Interop with minih**: minih's `retrospective.difficulties[]` JSON has fields `id` (MH-XXX), `category`, `description`, `workaround`, `severity`. The new schema is a strict superset — minih entries can be transcoded into the portable shape losslessly. minih's `magicWand` + `magicWandTarget` map to `type: magic-wand` + `target` cleanly. A separate `gifts-v2 import-minih` mode (deferred to spec) could convert minih's harvest into portable entries.

### File layout

```
docs/retros/
├── README.md                     # convention guide; links AGENTS.md, names the loop
├── _session-buffer.md            # transient — current session's entries; bubble-up reads then clears
├── _LEDGER.md                    # auto-rebuilt index/dashboard (open count by category, top magic-wands, etc.)
├── <plan-slug>.md                # per-plan entries (existing: written by plan-6a; new skill appends here too if a plan is active)
├── <agent-slug>.md               # per-minih-agent entries (existing: minih auto-harvest)
└── sessions/
    └── <date>-<branch>.md        # per-session entries when no plan is active (ad-hoc work, debugging, exploration)
```

`_session-buffer.md` is the **only file that the bubble-up flow reads**. Everything else is permanent ledger destinations chosen at bubble-up time based on session context (active plan? branch? ad-hoc?).

### AGENTS.md additions (proposed)

A new section after the existing "Tool Development Guidelines":

```markdown
## Self-Improvement Loop (the difficulty ledger)

This repo treats every agent session as a chance to improve the dev infrastructure. When you (the agent) hit friction, encounter a workaround, or wish for a better tool, **log it as a ledger entry** — the `gifts-v2` skill provides a one-line `log` mode for this. At session end, run `gifts-v2 bubble` to present everything you logged to the user with one-keystroke options to save, escalate to a fix-task, escalate to a full plan, or convert into encoded knowledge (a justfile recipe, an AGENTS.md addition, a SKILL.md edit).

The ledger lives at `docs/retros/`. The convention guide is `docs/retros/README.md`. The schema is in `skills/SDD/gifts-v2/SKILL.md`.

**Categories**: build, config, data, test, debug, knowledge, tooling, docs, agent-harness, engineering-harness, coordination, skill-design, other.

**The principle**: encode, don't document. Every entry should propose an encoded form (a recipe, a script, a fixture) so the next agent never hits the same friction.
```

### justfile additions (proposed)

```just
# Log a difficulty / magic-wand / gift to the session buffer
retro-log description:
    @echo "(use the gifts-v2 skill — this is a placeholder pointing at the canonical entry path)"

# Surface session entries for user decisions
retro:
    @echo "Run /gifts-v2 bubble in your agent CLI to surface session entries."

# Re-render the ledger dashboard
retro-index:
    @echo "(generates docs/retros/_LEDGER.md from per-scope files)"
```

(Whether `just` recipes can directly invoke a skill is open — most likely the recipes are documentation pointers since `just` is shell-side and the skill is agent-side. Workshop opportunity.)

---

## Findings (focused, single-pass)

### IA-01: Ledger writes already concentrate at one chokepoint

`plan-6a-v2-update-progress` Step 8 + Step 9 are the only orchestrated writers to `docs/retros/<plan-slug>.md` today. Both writes happen at **phase end only**, only when called by `plan-6` or `plan-6-companion`. There is no producer for **planning-phase friction** (e.g. "the spec was ambiguous in section X"), **review-phase friction** (e.g. "I had to re-read the plan three times to find the AC list"), or **ad-hoc session friction** (e.g. "the test runner doesn't print line numbers in stack traces"). The new skill fills this entire upstream funnel.

### IA-02: `## Discoveries & Learnings` is the legacy convention; `docs/retros/` is the new convention; nothing reconciles them

`plan-1a-v2-explore` Subagent 7 reads the **old** `## Discoveries & Learnings` tables embedded in `tasks.md` / plan files. `plan-6a` writes to the **new** `docs/retros/<plan-slug>.md` *and* mirrors a `### Orchestrator Retrospective` subsection back into the relevant phase `tasks.md`. The two patterns coexist with no reconciliation: prior-learnings reads find the old tables, but the new ledger is invisible to it. Spec should decide whether the new skill writes to BOTH locations (for backwards compat) or whether `plan-1a` Subagent 7 is updated to also read `docs/retros/`. Recommended: the new skill writes only to `docs/retros/`, and `plan-1a` Subagent 7 is updated as part of the same plan to read both paths.

### IA-03: Minih ledger discipline is well-documented; ours is not

Minih's `AGENTS_README.md` § "The Difficulty Ledger" is a clear, single-page operating contract: who maintains it (the calling agent or human, not minih itself); the pipeline (agents report → human curates → preamble updates → next agent reads); the suggested categories; the principle ("encode, don't document"); and the explicit consumer pattern ("the next plan's first task can be: address the top 3 magicWand items from the last 10 runs"). Our equivalent contract lives in scattered fragments across `harness-is-the-product-v2` Principle 2 (philosophy), `plan-6a` Step 8 (mechanism), and `plan-1a` Subagent 7 (read path) — and they don't reference each other. The new skill's `init` mode should write a single-page operating contract to `docs/retros/README.md` modeled on minih's.

### DC-01: Bubble-up UX has no precedent in our skill set

No existing SDD skill uses an end-of-session "summary + per-item action menu" pattern. The closest analog is `plan-1a-v2-explore` § "External Research Opportunities" which generates ready-to-use `/deepresearch` prompts — but those are inline in the report, not interactive. The new skill needs to invent its own UX convention. Recommended: a single markdown block printed at session end with `[s/t/p/e/d/a]` per entry, similar to `git rebase -i` line-prefix conventions. **This is a primary workshop topic.**

### DC-02: Cross-skill invocation is loose

When `plan-1a` recommends "Run `/plan-1b-v2-specify` next," it's just a printed string — the user types the slash command. Same for `plan-7` recommending fix dossiers. The new skill's bubble-up will work the same way: emit copy-pasteable command lines. No tighter coupling needed (and probably undesirable — keeps the skill portable across CLIs).

### DC-03: `plan-6a` already imports the right vocabulary

`plan-6a` Step 8 already enforces the `agent-harness | engineering-harness` distinction in `magicWandTarget`. The new skill should use the *same* enum so entries from any source line up. Reuse the categories rather than re-inventing them.

### PS-01: "Bubble at end, never block mid-flow" is the load-bearing UX choice

Direct user quote: "bubble them up to the user at the end so it doesn't always have to ask about them." This locks down the interaction model: writes are silent, summaries are batched. No mid-session prompts. Implementation pattern: append-only buffer file + read-then-clear at end. This is similar to how `plan-6` defers retro JSON construction to the very end of phase implementation (Step 6 of plan-6) rather than asking after each task.

### PS-02: "Suggestions, not mandates" is the second load-bearing UX choice

Direct user quote: "However, it's just suggestions. We make suggestions in the difficulty ledger and then bubble them up to the user at the end so it doesn't always have to ask about them. And then the user can choose if they want to do a fixed task or a plan or something to implement said efficiency gain." Means: the skill never auto-creates a plan, never auto-edits the justfile, never auto-modifies AGENTS.md. It **proposes** edits and emits invocations the user can run. This is critical for trust — agents that silently rewrite governance docs lose user trust fast.

### PS-03: "Encode, don't document" requires an `suggested-encoding` field on every entry

The `harness-is-the-product-v2` Principle 3 — and minih's "Encode, Don't Document" section — both insist that a fix should become a recipe/command/check, not a wiki page. The schema enforces this by making `suggested-encoding` the most prominent field in every entry. An entry without an encoding suggestion is incomplete. The bubble-up flow's `[e]ncode` action turns the suggestion into a draft edit the user can review.

### QT-01: No tests exist for "did the agent log entries?"

Skills produce markdown; we don't unit-test them. The behavioral test for this skill is observational: did the agent log entries during the session that wouldn't have been logged before? Recommended: a worked-example dogfooding section in the skill itself ("Sample session showing 3 entries logged + bubble-up output"), and after first use, audit `docs/retros/_session-buffer.md` and `docs/retros/<scope>.md` to confirm entries actually landed.

### IC-01: Schema must round-trip with minih's JSON

If a user wants to feed minih's `retrospective.difficulties[]` into the same ledger (and they will), the schema needs `kind: minih-imported` provenance plus a clean field-mapping. This is non-trivial because minih's `magicWand` is a single string, not the full {target, sketch, encoding} bundle the new skill produces. Mapping rule: minih `magicWand` → portable `type: magic-wand` with `description: <minih.magicWand>`, `target: <minih.magicWandTarget mapped>`, `suggested-encoding: null` (the importer can't synthesize one — leave for human curation). **This is a workshop topic.**

### IC-02: Auto-numbering needs a scheme that doesn't collide with minih (MH-XXX) or plan-6a (OH-XXX)

Proposed prefix: **DL-XXX** (Difficulty Ledger). Per-scope counter (one counter per `<scope>.md` file, not global). Resets within `_session-buffer.md` (DL-001, DL-002, … ) on every session. When entries are saved into a scope file at bubble-up time, they get re-numbered into that scope's namespace. Or: each scope file uses its own prefix, e.g. `<plan-slug>:DL-007`. Workshop topic.

### DE-01: One related prior plan: 017-harness-integration

Plan 017 introduced the harness-integration concepts that landed plan-6a Step 8 + Step 9. Should be read as background for spec/plan, but does not block this work — 017 is committed and stable. The new skill is the **next layer** on top of 017's mechanism: 017 built the destination directory and the writer; this skill builds the universal producer + reader-trigger.

### DE-02: AGENTS.md and CLAUDE.md are mirrors

Per the existing convention, AGENTS.md and CLAUDE.md are kept in sync (one is the AGENTS-convention name, the other the Claude-convention name; same content). The new skill's `init` mode must update **both**. Same for `README_AGENTS.md` if the user-facing skill catalog should mention it.

### PL-01: "Bare 'harness' was a recurring confusion → resolved by tagging (E)/(A)" 📚

**Source**: This conversation's prior turns (commit `36a9ade`).
**Original Type**: workaround → resolved decision
**What it was**: Multiple skills used bare "harness" terminology, conflating engineering and agent harness concepts.
**Resolution**: Disambiguated via `(E)`/`(A)`/`(both)` tags in `harness-is-the-product-v2`, explicit "agent harness" + "engineering harness" naming everywhere else, and a `magicWandTarget` enum that rejects bare "harness".
**Why this matters now**: The new skill MUST use the disambiguated vocabulary from day one. The schema's `category` and `target` enums above already do this. The `init` mode's AGENTS.md insertion must continue the convention (no bare "harness" — always qualified).
**Action**: Schema enums are correct as drafted. Add a note to the spec: "Vocabulary discipline — every reference to a harness must be qualified (engineering or agent). This was a previously-resolved confusion; do not regress it."

### PL-02: "Pipeline skills correctly lean agent-harness; philosophy correctly leans engineering" 📚

**Source**: Same as PL-01.
**Original Type**: insight (validated decision)
**What it was**: We rebalanced `harness-is-the-product-v2` so the philosophy is engineering-led with one dedicated agent-harness principle, while the pipeline skills (plan-1a/2/3/5/6/7) remain agent-harness-focused at execution touchpoints because that's the layer they operate at.
**Why this matters now**: The new skill is a *philosophy-and-mechanism* skill, not a pipeline skill. Per the rebalance, its philosophy framing should lean engineering — the difficulty ledger is primarily about encoding fixes into the engineering harness (justfile, recipes, scripts, AGENTS.md). The agent-harness angle is one category among many. Don't let the skill become an agent-harness skill in disguise.
**Action**: Frame the skill's purpose statement around "encode every difficulty into the engineering harness," with the agent-harness category as one of several.

### PL-03: "Auto-harvest writes are valuable but invisible if no one reads them" 📚

**Source**: This conversation's prior turn (the "difficulty ledger coverage" diagnosis).
**Original Type**: insight (gap diagnosis)
**What it was**: Minih and plan-6a both auto-write to `docs/retros/`, but no SDD skill reads from there. The compounding promise breaks at the read end.
**Why this matters now**: The new skill *is* the producer for non-minih sessions, but if the read-side gap isn't also closed, this just adds more silent writes. Spec should bundle: (a) the new skill, AND (b) reader-side updates to plan-1a Subagent 7 (read `docs/retros/` not just `## Discoveries`), plan-1b/3/5/7 (read top-N entries before drafting), agent-harness-v2 template (seed Known Difficulties from ledger).
**Action**: Spec must include both producer and reader-side changes. Recommend Full Mode plan with the new skill as Phase 1 and the reader updates as Phase 2.

### PL-04: "Workshops first, then schema-lock" 📚

**Source**: User's literal directive in this turn ("I think we need to do some workshops").
**Original Type**: decision (process)
**Why this matters now**: The schema, the bubble-up UX, the AGENTS.md insertion, and the minih-interop mapping are all design decisions with multiple valid answers. Locking them prematurely is risk.
**Action**: Don't write the spec until at least one workshop has run. The follow-up turn will run `/plan-2c-v2-workshop` against the "vibe" of the self-improvement concept.

---

## Modification Considerations

### ✅ Safe to add (zero blast radius)

- New `docs/retros/README.md` — there's nothing there today
- New `docs/retros/sessions/` subdirectory — new namespace, no collisions
- New `gifts-v2` skill folder under `skills/SDD/` (or `skills/general/`) — additive, npx-skills will pick it up automatically
- AGENTS.md / CLAUDE.md insertion — additive section, no edits to existing content

### ⚠️ Modify with caution (touches working machinery)

- `plan-6a-v2-update-progress` — if we want plan-6a to *also* call the new skill's `log` mode for orchestrator-side friction, that's a coupling. Cleaner to leave plan-6a alone for v1 (it already has its own retro path) and revisit in a later plan if the duplicate-source problem becomes acute.
- `plan-1a-v2-explore` Subagent 7 — updating its read paths to include `docs/retros/` is small but it changes a producer→consumer contract. Test the prior-learnings output after the change.

### 🚫 Danger zones (don't touch in v1)

- Minih runtime — out of scope; we interop with its outputs but don't modify it
- `docs/retros/<plan-slug>.md` files written by plan-6a's pre-existing logic — spec should treat these as read-only artifacts; only the new skill's own entries are mutable

### Extension points

- `kind: <new-encoding-type>` is open-ended — future skills can add `kind: dockerfile-recipe`, `kind: github-action`, etc. Schema is forward-compatible.
- `category` enum is open with `other` as escape hatch — same reasoning.
- Bubble-up actions can grow — `[w]orkshop` to spawn a `/plan-2c-v2-workshop` for a complex entry, `[a]dr` to spawn `/plan-3a-v2-adr` for an architectural one, etc.

---

## Prior Learnings (From Previous Implementations)

See PL-01 through PL-04 above (consolidated into Findings section because all four were surfaced in this conversation rather than from `## Discoveries & Learnings` table mining; they are recent in-session discoveries, not deep history).

A formal `## Discoveries & Learnings` mine across `docs/plans/` was scoped but skipped — the topic is novel enough that the conversation-level priors are the load-bearing inputs. If the spec wants deeper backfill, run `plan-1a-v2-explore` Subagent 7 separately on this topic.

### Prior Learnings Summary

| ID | Type | Source | Key Insight | Action |
|----|------|--------|-------------|--------|
| PL-01 | workaround→decision | conv. prior turn | Engineering vs agent harness vocabulary must stay disambiguated | Use qualified terms in schema/AGENTS.md inserts |
| PL-02 | insight | conv. prior turn | Philosophy leans engineering; pipelines lean agent-harness | Frame new skill engineering-led |
| PL-03 | insight (gap) | conv. prior turn | Producers exist; readers don't | Bundle reader-side updates into the same plan |
| PL-04 | decision (process) | user directive | Workshop before locking schema/UX | Run `/plan-2c-v2-workshop` next |

---

## Domain Context

This repo does **not** use the formal `docs/domains/` system (no `docs/domains/registry.md`). The new skill belongs in `skills/SDD/` (alongside `harness-is-the-product-v2` and `agent-harness-v2`, which it conceptually extends) **or** in `skills/general/` (if framed as universal — "applies to any project, not just SDD pipeline work"). Recommended: `skills/general/gifts-v2/SKILL.md` because the difficulty ledger is genuinely cross-cutting — it's not about spec-driven development, it's about every kind of work. Final placement is a spec-time decision.

---

## Critical Discoveries

### 🚨 Critical Finding 01: The bubble-up UX is the make-or-break design choice

**Impact**: Critical
**What**: If the bubble-up summary is too verbose, users will dismiss it without reading and entries will pile up unread. If it's too sparse, users won't know what they're choosing between. If it blocks at every entry, it violates the user's "don't always ask" mandate. If it doesn't surface candidate encodings, it's just a wishlist.
**Why it matters**: This skill's value is entirely a function of how often the bubble-up actually produces user actions. A bubble-up that gets `[a]ll save` 100% of the time is a journal, not a self-improvement loop.
**Required action**: Workshop the bubble-up UX *before* writing the spec. Use the `/plan-2c-v2-workshop` skill; "Operator Usability" is the primary value axis.

### 🚨 Critical Finding 02: Reader-side updates must ship in the same plan as the new skill

**Impact**: Critical
**What**: Per PL-03, adding more producers without closing the read-side gap just adds noise. The plan must bundle: (a) the new skill (producer + bubble-up), (b) updates to `plan-1a-v2-explore` Subagent 7 to read `docs/retros/`, (c) optionally updates to `plan-3-v2-architect` and `plan-7-v2-code-review` to read the ledger before/during their work.
**Why it matters**: Without (b), the new entries are written to a directory nobody reads. The compounding promise stays broken.
**Required action**: Spec scope must include reader-side updates. Plan should be Full Mode with multiple phases.

### 🚨 Critical Finding 03: The schema needs to round-trip with minih *and* be writable by hand

**Impact**: High
**What**: Two competing pressures. Minih emits structured JSON; humans want simple markdown. The schema chosen here is YAML-fenced markdown — a compromise that works for both but requires a workshop pass to confirm it's not too clunky for either.
**Why it matters**: If the schema is too JSON-like, agents writing entries by hand will get it wrong. If it's too freeform, machine consumers (minih's `difficulties` aggregation, future ledger dashboards) can't parse it.
**Required action**: Workshop the schema with concrete examples covering both write paths.

---

## External Research Opportunities

None — the problem domain is internal to this repo and fully covered by minih's `AGENTS_README.md` (already read in this conversation) and our own skills (already mapped). No external best-practices research needed before specification.

---

## Recommendations

### If proceeding with this skill

1. **Run a workshop next** (the user's explicit directive) — use `/plan-2c-v2-workshop` against the "vibe" of self-improvement: the bubble-up UX, the encoding-suggestion pattern, the AGENTS.md voice, the way it should feel during a session. Value axes: Operator Usability, Implementation Readiness, Onboarding/Accessibility, Cost/Attention Reduction.
2. **Write the spec in Full Mode** — this is a multi-phase plan (skill itself + reader updates + AGENTS.md/justfile inserts), not a Simple Mode one-shot.
3. **Sequence the phases**: Phase 1 = the new skill (producer + bubble-up + scaffold), Phase 2 = `docs/retros/README.md` + AGENTS.md/CLAUDE.md additions, Phase 3 = reader-side updates to existing skills.
4. **Defer minih import to a follow-up plan** — keep v1 scope on the portable producer + bubble-up. Minih interop (`gifts-v2 import-minih`) is a clean separable plan once the portable schema is locked.

### If not proceeding (alternative)

If the user decides this is overkill, the minimum viable alternative is just (b) from PL-03: update `plan-1a-v2-explore` Subagent 7 to read `docs/retros/` in addition to `## Discoveries & Learnings`. That alone closes part of the read-side gap and turns plan-6a's existing writes into useful inputs for future plans. But it doesn't help non-plan sessions, doesn't surface magic-wands at session end, and doesn't drive the encode-don't-document loop.

---

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| **Self-improvement vibe** (the "feel" of the skill in a session) | Other / Operator Usability | The user's explicit ask. The interaction model is novel and the philosophy is the load-bearing thing — locking it before vibing it is risk. | How does it feel mid-session? How does the bubble-up actually present? What does success look like one week / one month after install? How do we keep it from becoming nag-ware? |
| Bubble-up UX (action menu, prompts, output format) | CLI Flow | No precedent in our skill set; high blast radius if wrong. | Per-item prompt vs single batched prompt? Default action? How are encoding suggestions presented? Mobile / narrow-terminal friendly? |
| Schema lock-in (YAML fields, enums, minih round-trip) | Data Model | High inertia once written; consumers will depend on it. | Are 14 categories too many? Should `target` be merged with `category`? How does minih import work concretely? |
| AGENTS.md voice & placement | Other / Documentation | Where it lands and how it reads sets the tone for the whole self-improvement loop. | How long should the section be? Does it go before or after dev guidelines? Tutorial or contract? |
| Reader contract for plan-1a / plan-3 / plan-7 | API Contract | Determines how readers query the ledger. | Read top-N? Filter by category? By scope? How recent is "recent"? |

---

## Appendix: File Inventory

### Files this plan will create

| File | Purpose |
|------|---------|
| `skills/general/gifts-v2/SKILL.md` (or `skills/SDD/`) | The new skill |
| `docs/retros/README.md` | Convention guide |
| `docs/retros/_session-buffer.md` | Per-session scratch (gitignored or committed empty) |
| `docs/retros/_LEDGER.md` | Auto-rebuilt dashboard |
| `docs/retros/sessions/` | Per-session permanent entries (when no plan active) |

### Files this plan will modify

| File | Change |
|------|--------|
| `AGENTS.md` | Add "Self-Improvement Loop" section |
| `CLAUDE.md` | Mirror of AGENTS.md change |
| `README_AGENTS.md` | Add `gifts-v2` to skill catalog |
| `justfile` | Add `retro` recipe(s) (likely doc-pointers) |
| `skills/SDD/plan-1a-v2-explore/SKILL.md` | Subagent 7 reads `docs/retros/` too |
| `skills/SDD/plan-3-v2-architect/SKILL.md` | Read top-N magic-wands before phase design (optional, scope decision) |
| `skills/SDD/plan-7-v2-code-review/SKILL.md` | Cross-check phase against open ledger entries (optional, scope decision) |
| `skills/SDD/agent-harness-v2/SKILL.md` | Template seeds `## Known Difficulties` from ledger (optional, scope decision) |

### Files this plan will not touch

- Minih runtime
- Existing `docs/retros/<plan-slug>.md` files written by plan-6a (read-only artifacts)
- Any production code (this repo has none — it's a skills repo)

---

## Next Steps

**User's explicit directive**: After this dossier, run `/plan-2c-v2-workshop` to workshop the **vibe** of the self-improvement concept — how it feels in a session, how the bubble-up presents, how we keep it from becoming friction itself. This precedes spec.

After the workshop:
- `/plan-1b-v2-specify` (Full Mode) to draft the spec
- `/plan-2-v2-clarify` if any [NEEDS CLARIFICATION] markers land in the spec
- Additional workshops as needed (schema, reader contract)
- `/plan-3-v2-architect` for the phase design

---

**Research Complete**: 2026-05-16
**Report Location**: `docs/plans/023-difficulty-ledger-skill/research-dossier.md`
