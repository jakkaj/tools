# Workshop: Harness Terminology Disambiguation

**Type**: Terminology & Skill Architecture
**Plan**: 017-harness-integration
**Spec**: [harness-integration-spec.md](../harness-integration-spec.md)
**Created**: 2026-05-10
**Status**: Draft

**Value Thesis**: This workshop makes the prompt system safer to read and edit by separating two distinct concepts that currently share one word ("harness"). Future agents and humans can identify which harness any skill operates on without re-deriving the meaning, which compresses review, reduces drift across sibling skills, and prevents the "encode the fix" instruction from landing in the wrong place.

**Target Proof Level**: Implementation Ready
**Current Proof Level**: Contract Ready (decisions specified; per-file edits enumerated; migration path drafted)

**Selected Value Axes**:
- **Knowability** — the conflation currently hides which harness each skill operates on; the fixes make it explicit at the surface (skill name, file name, header line).
- **Agent Readiness** — an agent reading any v2 skill should know which harness "harness" refers to without consulting other skills or this workshop.
- **Cross-Domain Coordination** — engineering harness and agent harness are distinct domains with a contract between them (agent harness depends on engineering harness substrate). Workshop makes that contract explicit.
- **Review Compression** — reviewers of future prompt PRs can verify "which harness?" against a single glossary instead of re-deriving from prose.
- **Migration Safety** *(supporting)* — existing projects already have `docs/project-rules/harness.md`. The renaming path must not break them.

**Related Documents**:
- [001-agent-harness-dossier.md](./001-agent-harness-dossier.md) — first-principles agent harness concept
- [002-harness-prompt-design.md](./002-harness-prompt-design.md) — original harness-v2 skill design (pre-disambiguation)
- [003-pre-phase-validation-protocol.md](./003-pre-phase-validation-protocol.md) — plan-6 harness validation flow
- `agents/v2-commands/harness-v2.md` — the skill that produces the governance artifact (root of conflation propagation)
- `agents/v2-commands/harness-is-the-product-v2.md` — the philosophy skill (Principle 1 = engineering, Principle 2 = agent)

**Domain Context**:
- **Primary Domain**: prompt system / v2-commands skill set
- **Related Domains**: harness-integration (this plan), v2-command-cross-pollination (plan 020) — terminology decisions here propagate to both

---

## Purpose

Resolve the "harness" word collision across the v2-commands skill set. Today the term is overloaded: in some places it means **engineering harness** (recipes, build, test infrastructure), in others **agent harness** (Boot/Interact/Observe feedback loop, governance doc, minih runtime). One central skill (`harness-v2.md`) and one central artifact (`docs/project-rules/harness.md`) silently anchor the entire system to one meaning while presenting a generic name. This workshop produces the glossary, the architectural decision, and the per-file edit recipes needed to disambiguate without breaking existing projects.

## Fresh Entrant Outcome

A fresh human or agent should be able to use this workshop to reach **Implementation Ready** with no additional context.

They should be able to:

- Define "engineering harness" and "agent harness" precisely and correctly.
- Identify, for any v2 skill, which harness it operates on.
- Apply the recommended edits to each affected file without re-running the audit.
- Migrate an existing project's `docs/project-rules/harness.md` to the new naming with no skill regression.
- Write new v2 skills that reference harnesses without re-introducing the conflation.

## Key Questions Addressed

- What does "harness" mean across the v2 prompt system today?
- Where does it conflate, and which conflations are load-bearing vs cosmetic?
- Why is `harness-v2.md` the most consequential file to fix (not the most internally inconsistent one)?
- Should the term split, stay unified, or one of the two get renamed entirely?
- What is the smallest set of concrete edits that disambiguates without churn?
- How do existing projects with `docs/project-rules/harness.md` migrate without breaking?
- How do we prevent future skills from regressing?

---

## Glossary: The Two Harnesses

### Engineering Harness

**Definition**: The dev-loop infrastructure that lets *anyone* — developer, CI, agent — actually run, test, build, and exercise the software. It is owned by the codebase itself.

**Examples**:
- `justfile` / `Makefile` recipes
- Build scripts (`pnpm build`, `cargo build`, `uv sync`)
- Seed/fixture scripts (`scripts/seed-db.sh`)
- Test runners (`pytest`, `playwright test`)
- Dev server boot (`pnpm dev`, `just serve`, `docker compose up`)
- Environment setup (`.env.example`, devcontainer.json)
- CLI tooling exposed for human/agent use

**Audience**: developers, CI, agents (as a substrate they depend on).

**Owned by**: source tree. Lives in `scripts/`, `justfile`, `Makefile`, `package.json scripts`, etc.

**Failure mode if missing**: nothing runs. No dev loop. No CI. No agent feedback loop possible.

### Agent Harness

**Definition**: The agent-facing feedback loop layered *on top of* the engineering harness. It tells an agent how to Boot the system, Interact with it, Observe its output, and Validate the result, in 30–60 second cycles, without human intervention.

**Examples**:
- `docs/project-rules/harness.md` (today's governance file)
- Boot command + health check endpoint
- Auth strategy (persistent profile, token file, API key)
- Evidence directory (`scratch/evidence/`)
- Bootstrap doc explaining the loop to a new agent
- minih companion runtime, retro ledger, MH-XXX/OH-XXX difficulty IDs
- Skills like `harness-v2`, `plan-6-v2-implement-phase-companion`

**Audience**: agents primarily; humans secondarily (when reviewing what the agent saw).

**Owned by**: `docs/project-rules/agent-harness.md` (proposed; today: `harness.md`) plus runtime tooling (minih).

**Failure mode if missing**: agents cannot autonomously iterate. Each loop requires human babysitting.

### The Layering Contract

**Agent harness depends on engineering harness.** Boot needs a runnable boot command. Observe needs structured output the engineering harness produces. Interact needs a callable surface (HTTP API, CLI, etc.) the engineering harness exposes.

You can have engineering harness without agent harness (humans run the dev loop manually, no automated agent feedback). You **cannot** have agent harness without engineering harness — at minimum, the boot command must exist and work.

This is why `harness-v2.md`'s implicit assumption ("there is a boot command somewhere") is load-bearing: when it isn't true, agent harness creation must trigger engineering harness creation as a prerequisite. Today the skill is silent on that case.

---

## The Conflation (Catalog by Severity)

Rated by **propagation impact** — how far the confusion spreads when this file is read or this skill is run.

### Severity 1: Root Propagator

**`agents/v2-commands/harness-v2.md`** — *the most consequential file in the system to disambiguate*.

Why root: this skill produces `docs/project-rules/harness.md`, which every downstream skill (`plan-1a`, `plan-3`, `plan-5`, `plan-6`, `plan-6-companion`) reads. Three failures compound here:

1. **Skill name lacks "agent"** — `harness-v2`, not `agent-harness-v2`. A reader scanning the skill list sees the generic name and assumes coverage of "harness" generally. Internal text correctly says "agent harness" — but the entry point doesn't.
2. **Generated artifact uses generic filename** — `docs/project-rules/harness.md`. The header inside says `# Agent Harness` (correct), but the path is generic. Anyone looking for "harness rules" finds only the agent side and may assume that *is* the entire harness story.
3. **Engineering harness is silently assumed.** The Boot section records a boot command but never asks "what if no boot command exists?" Subagent 2 looks for `justfile`, `Makefile`, `docker-compose.yml` — but if they're absent, the skill has no fallback. Engineering harness gaps surface as "validation failed" instead of "engineering harness must be designed first."

This is why the audit's "internally clean" verdict was misleading. The internal language is consistent (always "agent harness"), but the *external surface* (skill name, filename) and the *unstated dependency* (engineering harness substrate) propagate confusion to every downstream reader.

### Severity 2: Definitional Conflict

**`agents/v2-commands/harness-is-the-product-v2.md`** — Principle 1 defines harness as engineering ("CLI tools, build scripts, test harnesses, `just`/`make` recipes, seed scripts, environment setup"). Principle 2 talks about minih's `retrospective.difficulties` ledger, which is purely agent harness. Same word, opposite meanings, two principles apart, never disambiguated.

The "5-minute zero-to-working" test (Step 2, Principle 1) doesn't say what "working" means — running dev loop (engineering) or oriented productive agent (agent)? Both are valid; the skill picks neither.

The "encode, don't document" instruction (Principle 3) is silent on whether the encoding lives in a recipe (engineering) or a skill/prompt edit (agent). The very ambiguity that started this thread.

### Severity 3: Conflation by Omission

**`agents/v2-commands/plan-3-v2-architect.md`** — "Phase 0: Build Harness" (lines 47, 179) and "## Harness Strategy" (186–201) silently mean *agent harness only*. The architect skill never raises engineering harness as a planning concern, so a plan generated through this skill assumes engineering harness already exists and never designs it.

### Severity 4: Local Ambiguity (cosmetic)

- **`plan-6-v2-implement-phase-companion.md:245-246`** — "update `docs/project-rules/harness.md`" + "Use harness observe capabilities" — which harness, which observe?
- **`plan-6-v2-implement-phase.md:~130`** — same `harness.md § History` ambiguity.

### Clean (no edit needed)

- `harness-v2.md` *internal language* is correct — every body reference says "agent harness." The problem is the surface, not the body.
- `plan-1a-v2-explore.md`, `plan-2-v2-clarify.md`, `plan-5-v2-phase-tasks-and-brief.md`, `plan-7-v2-code-review.md` — all consistently agent harness, no drift inside the prose. (Will need a one-token path update if the governance file gets renamed.)

---

## Value Frame

| Field | Selection | Why It Matters |
|-------|-----------|----------------|
| Target Proof Level | Implementation Ready | The user wants to apply fixes immediately; workshop must produce edit recipes, not just direction. |
| Primary Value Axis | Knowability | Today the meaning of "harness" is hidden in skill body; we want it visible at the entry point (name, path, header). |
| Supporting Value Axes | Agent Readiness, Cross-Domain Coordination, Review Compression, Migration Safety | Agents must read each skill standalone and know which harness applies. Reviewers must verify against a glossary, not re-derive. Migration must not break existing projects. |
| Downstream Loop Improved | Future v2-skill authoring; per-project `harness.md` interpretation; reading any plan that references "Phase 0: Build Harness" | What was implicit becomes explicit; what required cross-skill triangulation becomes one-skill-readable. |

---

## Decision Space

Five orthogonal decisions. Each has options; preferred selection in **bold**.

### A. Terminology Strategy

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **A1: Always two-word** | "agent harness" / "engineering harness" — bare "harness" only as umbrella in glossary contexts. | Minimal disruption. Preserves existing vocabulary. The qualifier is a one-token cost per occurrence. | Mildly verbose. Authors must remember. | **Selected** |
| A2: Rename agent → "agent loop" or "feedback loop" | Drops the word from the agent side entirely. | Eliminates ambiguity by not sharing the word. | Breaks every existing reference. Loses connection to `harness-is-the-product-v2` framing. | Rejected — too disruptive. |
| A3: Rename engineering → "dev loop" / "infrastructure" | Drops the word from the engineering side. | Same as A2, opposite direction. | Loses Principle 1's "harness is the product" rhetorical anchor. | Rejected. |
| A4: Single umbrella | Define "harness" as everything in the dev loop (both subsumed); drop the distinction. | One concept, no qualifier. | Hides the layering contract (agent harness depends on engineering harness). Conflation by design. | Rejected — the layering matters. |

### B. Skill Renaming

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **B1: Rename `harness-v2.md` → `agent-harness-v2.md`** | Skill that creates the agent harness gets the matching name. Slash command becomes `/agent-harness-v2`. | Surface matches scope. Clears the way for a future `engineering-harness-v2` if demand emerges. | Every reference to `/harness-v2` in other skills needs updating (~6 files). Users with muscle memory must re-learn. | **Selected** |
| B2: Leave skill name; fix only internal language | No rename. | Zero disruption. | The most consequential ambiguity (skill name) persists. | Rejected. |
| B3: Add `engineering-harness-v2.md` as new sibling now | Two skills, one per harness. | Symmetry. | YAGNI — engineering harness varies enormously per project, hard to generalize. Existing per-project `justfile`s already serve. | Rejected for now. Defer until clear demand. |

### C. Governance File Renaming

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **C1: `docs/project-rules/harness.md` → `docs/project-rules/agent-harness.md`** with backward-compatible read | New projects use new name. Skill checks new name first, falls back to old name if found. | Filename matches contents. Existing projects keep working. Migration is opportunistic. | Skill code (the harness-v2 skill itself) needs the fallback logic. Plan skills (`plan-1a`, `plan-3`, etc.) need updated paths. | **Selected** |
| C2: Keep filename, header already says `# Agent Harness` | Status quo. | Zero migration cost. | Path remains generic. Anyone discovering the file by name still gets the wrong frame. | Rejected. |
| C3: Single `harness.md` with two H2 sections | Both harnesses in one doc. | One file to read for full picture. | Mixes substrate (engineering) and overlay (agent) — different audiences, different lifecycles. Breaks the layering. | Rejected. |

### D. `harness-is-the-product-v2.md` Restructure

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **D1: Two-section restructure** | Add a glossary preamble naming both harnesses. Tag each Principle (E)/(A)/(both). Clarify the 5-minute test as "5 minutes to working dev loop AND 5 minutes to oriented productive agent." Clarify "encode" as a decision tree (recipe vs skill edit). | Both harnesses get first-class treatment. Reader knows which principle applies where. | More text. Existing readers must re-orient. | **Selected** |
| D2: Drop engineering flavor, make agent-only | Strip Principle 1's engineering examples. | Simpler. | Loses the original framing's strength. Engineering harness IS the product too. | Rejected. |
| D3: Rename to `the-harnesses-are-the-product-v2` | Plural. | Cute, signals the disambiguation. | Renaming for cosmetic effect. The content fix matters more than the title. | Rejected. |

### E. plan-3 "Phase 0: Build Harness"

| Option | Description | Pros | Cons | Decision |
|--------|-------------|------|------|----------|
| **E1: Rename to "Phase 0: Build Agent Harness" + prerequisite check** | Phase name reflects what it actually builds. Add a prerequisite block: "If no engineering harness (boot command, test runner, dev script) exists, plan-1a must surface this as a blocker before this phase begins." | Honest naming. Surfaces the engineering-harness-missing case as a research finding, not a Phase 0 silent failure. | Plan-1a needs a small new check. | **Selected** |
| E2: Split into "Phase 0a: Engineering Harness" + "Phase 0b: Agent Harness" | Both harnesses get a phase. | Symmetric. | Engineering harness is too project-specific to generalize into a phase template. Better to leave it to `justfile`/`Makefile` design per project. | Rejected — engineering harness phase would be too thin to be useful. |
| E3: Keep name; add disambiguation paragraph only | Minimal change. | Cheap. | Doesn't fix the silent failure when engineering harness is missing. | Rejected. |

---

## Preferred Direction (consolidated)

1. **A1** — Always use "agent harness" or "engineering harness" in body text. Bare "harness" only in glossary or umbrella contexts.
2. **B1** — Rename `harness-v2.md` → `agent-harness-v2.md`. Update all references.
3. **C1** — Rename governance file `harness.md` → `agent-harness.md`. Skill reads new name first, falls back to old name. New projects only get the new name.
4. **D1** — Restructure `harness-is-the-product-v2.md`: glossary preamble, principle tags, decision-tree clarifications.
5. **E1** — Rename "Phase 0: Build Harness" → "Phase 0: Build Agent Harness". Add engineering-harness-prerequisite check to plan-1a.

Cumulative cost: ~9 files touched, ~60 line edits, 2 file renames, 1 backward-compat fallback added.

---

## Per-File Fix Recipes

Ordered smallest-cost first. Each can be applied independently. Renames (R1, R2) are larger commitments and bundled together as the second commit.

### Group 1: Tiny prose fixes (apply first, no rename, no behavior change)

#### F1. `agents/v2-commands/plan-6-v2-implement-phase-companion.md`

Lines 245–246, change:

```diff
- update `docs/project-rules/harness.md` with what changed
- Use harness observe capabilities for evidence capture
+ update the agent harness governance doc (`docs/project-rules/agent-harness.md`, fall back to `harness.md`) with what changed
+ Use the agent harness Boot/Interact/Observe capabilities for evidence capture
```

#### F2. `agents/v2-commands/plan-6-v2-implement-phase.md`

Same edit at the matching `harness.md § History` line (~130).

#### F3. `agents/v2-commands/harness-is-the-product-v2.md` (D1 prose, no restructure yet)

Add 4-line glossary preamble after the H2 header (line ~7):

```markdown
> **Two harnesses, one principle.** This skill applies to both:
> - **Engineering harness** = recipes, build, test, seed, env — the dev loop substrate.
> - **Agent harness** = Boot/Interact/Observe loop, governance doc, minih runtime — the agent-facing overlay built ON TOP of the engineering harness.
> Throughout this skill, principles tagged `(E)` apply to engineering harness, `(A)` to agent harness, `(both)` to both.
```

Tag Principle 1 `(E)`, Principle 2 `(A)`, Principle 3 `(both)`, Principle 4 `(both)`, Principle 5 `(A)`.

Clarify the 5-minute test (Principle 1):

```diff
- The test: If a brand new agent session started right now with zero context, could it get from zero to working in under 5 minutes using only automated recipes?
+ The test (engineering harness): If a developer or CI runner started with zero context, could they get the dev loop running and tests green in under 5 minutes using only automated recipes?
+ The test (agent harness): If a brand new agent session started right now with zero context, could it Boot, Interact, Observe, and produce evidence within 60 seconds using only `docs/project-rules/agent-harness.md`?
```

Clarify "encode the fix" (Principle 3) — add decision tree:

```markdown
**Where does the encoded fix live?**
- Build / test / dev-loop friction → engineering harness (recipe in `justfile`/`Makefile`, seed script, env fix).
- Agent-side friction (skill confusion, missing context, prompt regression, retro ledger gap) → agent harness (skill/prompt edit, preamble update, minih difficulty entry, governance doc clarification).
- Cross-cutting → fix in both, link them.
```

### Group 2: Renames (apply as one bundled commit)

#### R1. Skill rename: `harness-v2.md` → `agent-harness-v2.md`

```bash
git mv agents/v2-commands/harness-v2.md agents/v2-commands/agent-harness-v2.md
```

Update all references:

```
agents/v2-commands/plan-1a-v2-explore.md       — search "harness-v2" → "agent-harness-v2"
agents/v2-commands/plan-3-v2-architect.md      — same
agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md — same
agents/v2-commands/plan-6-v2-implement-phase.md — same
agents/v2-commands/plan-6-v2-implement-phase-companion.md — same
agents/v2-commands/README.md                   — update table row
agents/v2-commands/GETTING-STARTED.md          — update onboarding mentions
```

Inside the renamed file:
- Title `# harness-v2` → `# agent-harness-v2`
- Update self-references in usage examples (`/harness-v2` → `/agent-harness-v2`)
- Step 6 report text

#### R2. Governance file rename + backward-compat read

Inside `agent-harness-v2.md` Step 0 (Mode Detection), update the file existence check:

```diff
- Check: docs/project-rules/harness.md exists?
+ Check: docs/project-rules/agent-harness.md exists?
+   (fallback: docs/project-rules/harness.md — log a one-line migration suggestion)
```

In Step 4 (Generate harness.md), write to `docs/project-rules/agent-harness.md`. Keep the `# Agent Harness` H1 header (already correct).

In every skill that reads `docs/project-rules/harness.md`, change to:

```python
# pseudo-spec for the read
path = "docs/project-rules/agent-harness.md"
if not exists(path):
    path = "docs/project-rules/harness.md"  # legacy fallback
    # surface a one-line note: "consider renaming to agent-harness.md"
```

Files that read this artifact:
- `plan-1a-v2-explore.md` (~lines 219-228)
- `plan-3-v2-architect.md` (~lines 45-46, 179, 186-201)
- `plan-5-v2-phase-tasks-and-brief.md`
- `plan-6-v2-implement-phase.md` (~lines 101-131)
- `plan-6-v2-implement-phase-companion.md` (~lines 216-246)
- `plan-2-v2-clarify.md` (if it references harness.md — check)
- `plan-7-v2-code-review.md` (if it references harness.md — check)

### Group 3: Architectural edits (apply after renames stabilize)

#### A1. `plan-3-v2-architect.md` Phase 0 rename + prerequisite

```diff
- ## Phase 0: Build Harness
+ ## Phase 0: Build Agent Harness
+
+ **Prerequisite (engineering harness):** This phase assumes a working engineering harness — at minimum a boot command (e.g. `just dev`, `pnpm dev`, `docker compose up`) that returns a healthy state in under 60 seconds. If plan-1a research surfaced that no engineering harness exists or the existing one is inadequate (no boot command, no health signal, no structured output), that gap must be resolved before Phase 0 begins. Surface it as a P0 finding in the plan; do not attempt to design the agent harness on top of an absent substrate.
```

Rename the section "## Harness Strategy" → "## Agent Harness Strategy" with parallel guidance:

```diff
- ## Harness Strategy
+ ## Agent Harness Strategy
+
+ (Engineering harness strategy is project-specific — define recipes/scripts/test infrastructure in the project's `justfile`, `Makefile`, or equivalent. This section addresses the agent-facing layer only.)
```

#### A2. `plan-1a-v2-explore.md` engineering-harness check

In the harness research section (~lines 219-228), expand the check:

```diff
- Check: does docs/project-rules/harness.md exist?
+ Two-part harness check:
+ 1. Engineering harness substrate: does a boot command exist? (Look for `justfile`, `Makefile`, `package.json scripts.dev`, `docker-compose.yml`, etc.) Does it run? Does it produce a health signal?
+ 2. Agent harness governance: does `docs/project-rules/agent-harness.md` (or legacy `harness.md`) exist?
+
+ If (1) is missing or broken, surface as a P0 research finding — agent harness work is blocked until engineering harness is adequate.
+ If (1) is present but (2) is missing, recommend running `/agent-harness-v2 --create` during Phase 0.
+ If both exist, validate maturity level via `/agent-harness-v2 --status`.
```

---

## Migration Strategy (existing projects)

The risk: existing projects already have `docs/project-rules/harness.md`. Renaming the skill's expected path to `agent-harness.md` would break them on first run.

The mitigation (already specified in R2): **fallback read order**.

```
Read order: agent-harness.md → harness.md (legacy)
Write target (new artifacts): agent-harness.md
Migration suggestion: emitted as one-line note when legacy path is read; not a failure.
```

For projects that want explicit migration:

```bash
git mv docs/project-rules/harness.md docs/project-rules/agent-harness.md
# update any project-local references (README, AGENTS.md, etc.)
```

The `/agent-harness-v2 --status` command can include a one-line "📁 Legacy filename detected — consider `git mv harness.md agent-harness.md`" advisory when it falls back. No automatic rename — that would touch the user's git state.

After 6 months or when feels right: drop the fallback, require the new name. (Not part of this workshop's scope; record as future work.)

---

## Evidence Ledger

| Evidence | Location | Supports | Status |
|----------|----------|----------|--------|
| Conflation audit catalog | "The Conflation" section above | Severity 1–4 ratings, file-by-file findings | Ready (sourced from Explore agent audit, validated against re-read of harness-v2.md) |
| Two-harness glossary | "Glossary" section above | Naming decisions A1, B1, C1 | Ready |
| Layering contract statement | Glossary § "The Layering Contract" | E1 prerequisite check, plan-1a engineering-harness research | Ready |
| Per-file edit diffs | "Per-File Fix Recipes" section | Implementation Ready proof level — fixes can be applied directly | Ready |
| Migration fallback spec | "Migration Strategy" section | C1 backward-compat read | Draft (pseudocode shown; concrete bash check to be inlined when R2 lands) |
| Anti-pattern list (below) | "Anti-Patterns" section | Prevent regression in future skills | Draft |

---

## Attention Reduction (before / after)

| Future Loop | Before Workshop | After Workshop |
|-------------|-----------------|----------------|
| Reading any v2 skill that mentions "harness" | Reader had to triangulate across `harness-v2`, `harness-is-the-product-v2`, and skill body to guess which harness applied. | Each skill names which harness explicitly. Glossary preamble in `harness-is-the-product-v2` resolves ambiguous cases. |
| Authoring a new v2 skill | Author copied existing prose, propagating ambiguous "harness" references unconsciously. | Author has glossary + naming convention + decision tree to follow. |
| Creating harness governance for a new project | Output went to generic `harness.md` filename; readers thought it covered both. | Output goes to `agent-harness.md`; filename matches contents. Engineering harness gap surfaced separately by plan-1a. |
| Reviewing a prompt PR | Reviewer had to re-derive whether a "harness" reference was correct in context. | Reviewer checks against the glossary and severity catalog. |
| Agent reading `plan-3` Phase 0 | Agent built only the agent harness, never asked about engineering substrate; failures surfaced later as "boot command broken." | Agent checks engineering-harness substrate via plan-1a; Phase 0 builds agent harness only when substrate is adequate. |
| Encoding a "fix" per `harness-is-the-product-v2` Principle 3 | Author guessed whether fix went into a `justfile` recipe or a skill edit. | Decision tree in Principle 3 picks the right home. |

---

## Validation / Acceptance

This workshop reaches its target proof level when:

- [ ] **Glossary test**: A fresh reader can recite the difference between engineering harness and agent harness, and the layering contract, after reading the Glossary section once.
- [ ] **Per-file recipe test**: An agent applying Group 1 (F1–F3) edits produces the expected diffs without consulting any other workshop or skill.
- [ ] **Rename safety test**: Group 2 (R1–R2) edits land on a project that has the legacy `harness.md` artifact and the project still passes `/agent-harness-v2 --validate` on next run.
- [ ] **Phase 0 prerequisite test**: A plan-1a run on a project with no `justfile`/`Makefile`/`package.json scripts.dev` surfaces engineering harness inadequacy as a P0 finding before plan-3 begins Phase 0.
- [ ] **Decision tree test**: Given a sample friction ("test runner is flaky") an author follows Principle 3's decision tree to "engineering harness fix"; given another ("agent forgot to read the preamble") follows it to "agent harness fix."
- [ ] **No regression test**: Grep for bare "harness" (without `agent` or `engineering` qualifier) in `agents/v2-commands/*.md` returns only glossary contexts and `harness-is-the-product-v2.md` umbrella references — no operational uses.

---

## Open Questions

### Q1: Do we ever introduce `engineering-harness-v2.md` as a sibling skill?

**OPEN**: Engineering harness varies enormously per project (`pnpm` vs `cargo` vs `uv`, `docker compose` vs raw, monorepo vs single package). A generic skill would either be too thin to add value or too opinionated to fit.

Possible triggers for introducing it later:
- ≥3 projects observed where Phase 0 stalls on missing engineering harness.
- A clear pattern emerges (e.g. "all our projects use just + uv").
- A prompt is needed to design `justfile` recipes for agent-readability (single-command boot, structured-output preferred).

**Recommendation**: Defer. Revisit if/when the prerequisite check (A2) flags engineering-harness gaps frequently enough to need a prompt-driven solution.

### Q2: How long do we maintain the `harness.md` legacy fallback?

**OPEN**: The fallback (R2) is necessary for migration safety, but it shouldn't live forever — every legacy fallback adds skill complexity and dilutes the "one canonical name" benefit.

Possible policies:
- 6 months from R2 land date.
- Until N projects have migrated (e.g. all known projects using these skills).
- Until a flag day announced in `harness-is-the-product-v2`.

**Recommendation**: 6 months, plus an explicit deprecation note in the skill's Step 6 report when the fallback fires. Drop the fallback in a separate workshop that audits real-world usage first.

### Q3: Should `harness-is-the-product-v2.md` itself be renamed?

**OPEN**: The "harnesses are the product" point is now plural. Renaming to `harnesses-are-the-product-v2` is grammatically truer but cosmetically expensive.

**Recommendation**: Leave the name. The glossary preamble (D1) resolves the singular/plural mismatch in the body. Skill rename for cosmetic reasons isn't worth the reference churn.

### Q4: Do we need a `docs/project-rules/engineering-harness.md` companion artifact?

**OPEN**: Symmetric to `agent-harness.md`. Could document the project's `justfile` recipes, test runner, env setup as a single reference.

**Recommendation**: No, for now. Engineering harness already has self-documenting artifacts (`justfile`, `package.json scripts`, `README.md`, `AGENTS.md`). A duplicate doc would rot. Revisit only if Q1 produces an `engineering-harness-v2` skill that needs an output artifact.

### Q5: What about retro ledger and minih references that say "harness improves itself"?

**OPEN**: Lines like `plan-6-v2-implement-phase-companion.md:433` ("that's how the harness improves itself") are technically agent-harness-only but are written umbrella-style.

**Recommendation**: Tag-by-tag fix during Group 1 edits — change to "the agent harness improves itself" or rephrase to "this skill self-improves via the retro ledger." Add to F1's diff list when applying.

---

## Anti-Patterns to Avoid Going Forward

When writing or editing v2 skills:

- **"Just say harness"** — never. Always qualify with `agent` or `engineering`. The qualifier is one token; the ambiguity is forever.
- **"Generic governance filenames"** — `harness.md`, `rules.md`, `config.md` in `docs/project-rules/` invite the same conflation. Prefer `agent-harness.md`, `coding-rules.md`, `lint-config.md`.
- **"Skill name implies broader scope than skill covers"** — if a skill creates only the agent harness, name it `agent-harness-v2`, not `harness-v2`. The name IS the contract.
- **"Implicit prerequisite assumption"** — if a skill depends on engineering harness existing (a boot command, a test runner), say so in the skill's preamble. Don't let "validation failed" be the user's first signal that the prerequisite is missing.
- **"Encode the fix" without a target** — always specify whether a fix lives in a recipe, a skill edit, a preamble entry, or a retro ledger. Decision tree (Principle 3) picks the home.
- **"Cross-skill triangulation"** — a reader of one skill should not need to read three others to interpret a key term. Each skill carries enough context (or a one-line glossary link) to stand alone.

---

## Application Order (recommended commit sequence)

1. **Commit 1 — Group 1 prose fixes** (F1, F2, F3 + Q5 cleanup). No renames, no behavior changes. Low risk, immediate clarity gain.
2. **Commit 2 — Group 2 renames** (R1, R2 bundled). Skill rename + governance file rename + fallback read logic + all reference updates. Single atomic commit so users don't see a half-renamed state.
3. **Commit 3 — Group 3 architectural** (A1 plan-3 Phase 0 + A2 plan-1a engineering-harness check). Touches plan flow, deserves its own commit and PR-style review.

After all three commits, run the No-Regression test from "Validation / Acceptance" to confirm bare "harness" appears only in glossary contexts.

---

## Cross-References

- `agents/v2-commands/harness-v2.md` (to be renamed → `agent-harness-v2.md`)
- `agents/v2-commands/harness-is-the-product-v2.md` (D1 restructure)
- `agents/v2-commands/plan-1a-v2-explore.md` (A2 engineering-harness check)
- `agents/v2-commands/plan-3-v2-architect.md` (A1 Phase 0 rename)
- `agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md` (R1+R2 reference updates)
- `agents/v2-commands/plan-6-v2-implement-phase.md` (F2, R1+R2)
- `agents/v2-commands/plan-6-v2-implement-phase-companion.md` (F1, R1+R2)
- `agents/v2-commands/README.md`, `GETTING-STARTED.md` (R1 skill name update)
- This plan's spec: [harness-integration-spec.md](../harness-integration-spec.md)
- Sibling workshops 001, 002, 003 in `docs/plans/017-harness-integration/workshops/`
