# Stage 20 — specify
*(absorbed from `plan-1b-v3-specify-and-clarify`; loaded lazily via `/the-flow 1b specify` or `/the-flow specify` — dispatch: `../../SKILL.md`)*

**Purpose**: Create or update the feature spec AND resolve high-impact ambiguities in one pass — questions front-loaded before the sketch. Also hosts the mid-plan clarification re-entry (§ Re-entry, end of this module).
**Entry conditions**: A feature description (plan folder auto-created, or reused if `/the-flow 1a explore` already made one). § Re-entry instead requires an existing spec.
**Inputs**: Feature description (`$ARGUMENTS`) · `--simple` (pre-set Mode: Simple). Optional artifacts: `${PLAN_DIR}/research-dossier.md`, `docs/domains/registry.md`, `${PLAN_DIR}/workshops/*.md`. § Re-entry input: path to an existing spec, or a plan slug.
**Output contract**: `${PLAN_DIR}/<slug>-spec.md` with all clarifications applied and the `## Clarifications` log populated; terminal Next-steps block (workshop / post-spec harness seam / architect). § Re-entry: new `### Session YYYY-MM-DD` block + one-line coverage summary.
**Next routing**: `/the-flow 2c workshop` (module `references/stages/25-workshop.md`) if Workshop Opportunities were identified; recommended pre-architect seam `/eng-harness-flow --event post-spec --spec "<SPEC_FILE>"` (router-installed only); then `/the-flow 3 architect` (module `references/stages/30-architect.md`).

---

## Procedure

Create or update the feature **spec** AND resolve high-impact ambiguities in **one pass**. Front-loads the host-independent questions BEFORE the spec sketch so the resulting document arrives already-clarified, then only asks a second batch for genuinely sketch-dependent topics.

This stage replaces the legacy two-skill specify → clarify hop. Mid-plan clarification re-entry is preserved as the **§ Re-entry** section at the end of this module.

```md
User input:

$ARGUMENTS

# Optional flags:
# --simple    # Pre-set Mode: Simple (skip the Workflow Mode question in Round 1)
```

## Tool-capability detection (read first)

Before either question round, decide how to prompt:

- **Batched host** (e.g., Claude Code's `AskUserQuestion` accepts a `questions[]` array of 1–4): submit each round as ONE batched call so the user answers everything in a single interaction.
- **Sequential host** (only single-question `ask_user` available): submit questions one at a time within the round, preserving the same logical grouping and the overall ≤8 cap.

Default to batched. Fall back without ceremony — do not announce capability detection unless it fails mid-flow.

---

## Phase 0 — Setup

1. Determine feature slug from user input and check for existing plan folder:
   - Generate slug from feature description
   - If `docs/plans/*-<slug>/` already exists (created by `/the-flow 1a explore`) → use it
   - Else → create new folder with next available ordinal
   - `PLAN_DIR = docs/plans/<ordinal>-<slug>/`
   - `SPEC_FILE = ${PLAN_DIR}/<slug>-spec.md`

2. Check for and incorporate existing research:
   - If `${PLAN_DIR}/research-dossier.md` exists → read fully; use to inform complexity, domains, and question framing. Add note to spec: "📚 Specification incorporates findings from research-dossier.md"
   - Else → add note: "ℹ️ Consider running `/the-flow 1a explore` for deeper codebase understanding"

3. Check for existing domains:
   - Load domain context per `references/00-routing.md` § Domain context loading
   - If no domain registry exists → note that domains will be identified as part of this spec

4. Check for workshop documents:
   - If `${PLAN_DIR}/workshops/*.md` exist → read all; they are **authoritative design decisions** and must not be contradicted

5. Harness context: owned entirely by the external eng-harness family via the **`/eng-harness-flow`** router (children never called directly) — no governance file checks or readiness questions in this skill. The post-spec seam fires in Next steps after the spec is written.

---

## Phase 1 — Round 1: Front-loaded questions (BEFORE spec sketch)

These questions are answerable without reading the spec — ask them first so the sketch can use the answers as inputs rather than embedding `[NEEDS CLARIFICATION]` markers and re-asking later.

**Compose Round 1** (up to 4 questions in one batched prompt):

1. **Workflow Mode** — *skip if `--simple` flag was passed*
2. **Testing Strategy**
3. **Mock Usage**
4. **Documentation Strategy**

Submit as ONE batched call on batched hosts; sequentially on sequential hosts.

If `--simple` was passed, Round 1 shrinks to 3 questions (Testing/Mock/Docs) and `Mode: Simple` is recorded directly.

See **Standard Questions** below for the answer tables.

---

## Phase 2 — Generate spec sketch (using Round 1 answers)

Populate `SPEC_FILE` with these sections (Markdown headings):

- `# <Feature Title>`
- `**Mode**: Simple | Full` (from Round 1 / `--simple`)
- `## Research Context` (if research exists) — brief summary of key findings
- `## Summary` — short WHAT/WHY overview
- `## Goals` — bullet list of desired outcomes/user value
- `## Non-Goals` — explicitly out-of-scope behavior
- `## Target Domains` — **MANDATORY** domain mapping:

  ```markdown
  ## Target Domains

  | Domain | Status | Relationship | Role in This Feature |
  |--------|--------|-------------|---------------------|
  | auth | existing | **modify** | Extend with OAuth provider support |
  | notifications | **NEW** | **create** | Establish for email alert delivery |
  | _platform | existing | **consume** | Use logging and config contracts (no changes) |

  ### New Domain Sketches

  #### notifications [NEW]
  - **Purpose**: [1-3 sentences]
  - **Boundary Owns**: [concepts this domain is responsible for]
  - **Boundary Excludes**: [concepts explicitly NOT in this domain, with notes on where they belong]
  ```

  For each domain: `existing` (domain.md exists) or `**NEW**` (provide a sketch). Relationship is `create` / `modify` / `consume`.

- `## Testing Strategy` — populated from Round 1 (Approach, Rationale, Focus Areas, Excluded, Mock Usage)
- `## Documentation Strategy` — populated from Round 1 (Location, Rationale)
- `## Complexity` — CS 1-5 assessment:
  - **Score**: CS-{1|2|3|4|5} ({trivial|small|medium|large|epic})
  - **Breakdown**: S={0-2}, I={0-2}, D={0-2}, N={0-2}, F={0-2}, T={0-2}
  - **Confidence**: {0.00-1.00}
  - **Assumptions**, **Dependencies**, **Risks**, **Phases**

  > Complexity: CS 1–5 only — no time estimates (rubric: `references/00-routing.md` § Shared conventions).

- `## Acceptance Criteria` — numbered, testable scenarios framed as observable outcomes
- `## Risks & Assumptions`
- `## Open Questions`
- `## Workshop Opportunities` — areas that benefit from detailed design exploration BEFORE architecture:

  | Topic | Type | Why Workshop | Key Questions |
  |-------|------|--------------|---------------|

  Types: `CLI Flow` | `Data Model` | `API Contract` | `State Machine` | `Integration Pattern` | `Storage Design` | `Other`

- `## Clarifications` → `### Session YYYY-MM-DD` — record Round 1 Q&A

For genuinely topic-specific unknowns the sketch can't resolve (e.g., a data-model field that needs user input), embed `[NEEDS CLARIFICATION: …]` markers — these become candidates for Round 2.

Save the spec.

---

## Phase 3 — Round 2: Sketch-dependent questions (conditional)

Only fires if at least one of these is true:
- Target Domains contains NEW or contested entries → ask **Domain Review**
- The sketch left ≥1 critical `[NEEDS CLARIFICATION]` marker → ask up to 2 topic-specific questions

**Compose Round 2** (up to 4 questions in one batched prompt). Skip Round 2 entirely if none of the conditions hold.

Submit as ONE batched call on batched hosts; sequentially on sequential hosts.

**Total cap across Round 1 + Round 2 = 8 questions.** If Round 1 used 4 and Round 2 needs 5+, drop the lowest-priority Round 2 items.

After Round 2:
- Append Q&A to the same `### Session YYYY-MM-DD` block in `## Clarifications`
- Update affected sections immediately (`## Target Domains` for boundary adjustments, topic-specific markers replaced with resolved values)
- Save the spec

---

## Standard Questions

### Workflow Mode (Round 1, Q1 unless `--simple`)

**Default to Simple.** Simple is the recommended option for all but the genuinely complex work — present it first, marked `(recommended)`. Only steer toward Full when the work is clearly large/epic (CS-4/CS-5) **or** structurally demands it (multiple domains, several real phases, or required cross-cutting gates). When in doubt, pick Simple — it's cheaper to escalate a Simple plan to Full later than to carry Full ceremony on work that didn't need it.

| Option | Mode | Best For | What Changes |
|--------|------|----------|--------------|
| A | Simple **(recommended default)** | CS-1 through CS-3, single domain, one-to-few phases — the common case | Single-phase plan, inline tasks, phase-tasks stage (`/the-flow 5 tasks`) optional |
| B | Full | CS-4/CS-5, **or** genuinely multi-domain / multi-phase work that needs all gates | Multi-phase plan, required dossiers, all gates |

Recommend **A (Simple)** unless the CS score is 4+ or the spec sketch already shows multiple target domains / several phases. Don't reach for Full just because the work is unfamiliar — unfamiliarity is a research/workshop signal, not a mode signal.

**If Simple Mode**: spec header gets `**Mode**: Simple`; testing defaults to Lightweight.
**If Full Mode**: spec header gets `**Mode**: Full`; all gates required.

### Testing Strategy (Round 1)

| Option | Approach | Best For |
|--------|----------|----------|
| A | Full TDD | Complex logic, algorithms, APIs |
| B | Lightweight | Simple operations, config changes |
| C | Manual Only | One-time scripts, trivial changes |
| D | Hybrid | Mixed complexity — TDD for complex, lightweight for simple |

Updates to spec: `## Testing Strategy` with Approach, Rationale, Focus Areas, Excluded.

### Mock Usage (Round 1)

| Option | Policy |
|--------|--------|
| A | Avoid mocks entirely — real data/fixtures only |
| B | Allow targeted mocks — limited to external systems |
| C | Allow liberal mocking — wherever beneficial |

### Documentation Strategy (Round 1)

| Option | Location | Best For |
|--------|----------|----------|
| A | README.md only | Quick-start essentials |
| B | docs/how/ only | Detailed guides |
| C | Hybrid (README + docs/how/) | Both quick-start and depth |
| D | No new documentation | Internal/trivial changes |

### Domain Review (Round 2, conditional)

Fires only if Target Domains contains NEW or contested entries. Read `docs/domains/domain-map.md` first if present, then present:

```
The spec identifies these target domains:

| Domain | Status | Role |
|--------|--------|------|
| [from spec] | [existing/NEW] | [from spec] |
```

**For NEW domains** ask: does the boundary look right? should any part be absorbed into an existing domain? are contracts clear enough to proceed? how does it connect on the domain map (contracts in/out)?

**For existing domains** ask: will changes respect existing contracts? any contract-breaking changes (flag for ADR)? topology concerns (circular deps, high fan-in)?

After: update spec `## Target Domains` with user's adjustments.

### Topic-specific (Round 2, conditional)

Draw from these categories based on `[NEEDS CLARIFICATION]` markers in the sketch:
- **Data model**: entity relationships, schemas, storage
- **FRs**: feature requirements needing clarification
- **NFRs**: performance, security, accessibility
- **Integrations**: external system dependencies
- **Edge cases**: boundary conditions, error scenarios
- **Terminology**: domain-specific terms needing definition

---

## Gates

- At least Round 1 completed (or `--simple` provided + 3 Round 1 answers)
- Target Domains section present with at least one domain
- No critical `[NEEDS CLARIFICATION]` markers remaining after Round 2
- Mandatory sections present; acceptance criteria are testable
- Empty description → ERROR
- Focus on user value; no stack/framework details

## Output

`SPEC_FILE` written with all clarifications applied, `## Clarifications` log populated.

Next steps:
- **If Workshop Opportunities identified**: Consider running **`/the-flow 2c workshop`** (module `references/stages/25-workshop.md`)
- **Before architecture (recommended) — fire the post-spec harness seam**: `/eng-harness-flow --event post-spec --spec "<SPEC_FILE>"` — when a harness exists the router surfaces the backpressure check (can the planned work be *proven by deterministic sensors* vs eyeballed?) and produces `backpressure-coverage.md` in the plan dir for `/the-flow 3 architect` to consume. Router not installed (probe `test -f ~/.agents/skills/eng-harness-flow/SKILL.md`, fallback `~/.claude/skills/eng-harness-flow/SKILL.md`)? If the flow already warned, skip silently; otherwise print the one-time warning verbatim:

  > ⚠️ No engineering harness detected — the eng-harness skills aren't installed. Continuing without one: standard testing applies, nothing else changes. (To add the harness loop: `npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`.)

  Advisory; never blocks. Never call the router's child skills directly — children are private and may move.
- **Otherwise**: Run **`/the-flow 3 architect`** (module `references/stages/30-architect.md`) to generate the implementation plan
- **To add clarifications later** (mid-plan or post-architect): use the **§ Re-entry** section of this module to open a new `### Session` block

---

## Re-entry: mid-plan clarifications *(absorbed from plan-2-v2-clarify)*

This is the **mid-plan re-entry point** for clarifications. The original "create-spec-then-interrogate-spec" two-skill flow has been collapsed into the main body of this module (above), which front-loads questions before the spec is sketched.

Use this re-entry ONLY when:
- A spec already exists (created by this stage, or by a legacy specify skill)
- The architect (stage 30), workshop (stage 25), or implementation (stage 60) surfaced new ambiguities
- The user wants to add a clarification round mid-stream without regenerating the spec

For new specs, use the main body of this module (`/the-flow 1b specify`) instead.

```md
User input:

$ARGUMENTS

# Expects: path to an existing spec, or a plan slug.
```

### Tool-capability detection

- **Batched host** (e.g., Claude Code's `AskUserQuestion`): submit the round as ONE batched call (up to 4 questions).
- **Sequential host**: submit one at a time, preserving the cap.

### Flow

1. Resolve `PLAN_DIR` from the spec path provided; set `FEATURE_SPEC = ${PLAN_DIR}/<slug>-spec.md`.
2. Scan the existing spec for unresolved gaps:
   - `[NEEDS CLARIFICATION: …]` markers
   - Missing or thin Testing Strategy / Documentation Strategy / Target Domains
   - Open Questions section entries
   - Domain Review needed (Target Domains contains new/contested entries not yet reviewed)
   - Agent Harness decision missing
3. Choose **up to 4 highest-impact questions** from the gap list. Skip questions already answered in earlier `### Session` blocks.
4. Submit as ONE batched prompt (batched host) or sequentially (fallback). Cap = 4.
5. Append answers to `## Clarifications` → `### Session YYYY-MM-DD` (new block — do not modify earlier sessions).
6. Update affected spec sections immediately (Target Domains, Testing Strategy, Documentation Strategy, ACs, Risks, etc.). Save.
7. Emit a one-line coverage summary: "Resolved N/M open gaps. Remaining: …".

### Question catalogue (draw from these, only if relevant)

See **Standard Questions** (above in this module) for the full answer tables. Categories:

- **Workflow Mode** — only if Mode is unset (rare for re-entry)
- **Testing Strategy** — only if `## Testing Strategy` is missing
- **Mock Usage** — only if testing exists but mock policy is unset
- **Documentation Strategy** — only if `## Documentation Strategy` is missing
- **Domain Review** — only if Target Domains has unreviewed NEW/contested entries
- **Agent Harness Readiness** — only if harness decision not recorded
- **Topic-specific** — drawn from `[NEEDS CLARIFICATION]` markers (data model, FRs, NFRs, integrations, edge cases, terminology)

### Gates

- Spec file must exist; ERROR if not found
- At least one unresolved gap identified; if none, exit silently with "No clarifications needed."
- Cap of 4 questions per invocation (run again for further rounds)
- No critical `[NEEDS CLARIFICATION]` markers remaining after the session (or surface the survivors in the coverage summary)

### Output

Updated `SPEC_FILE` with a new `### Session YYYY-MM-DD` block and any section updates the answers triggered.

Next: `/the-flow 3 architect` (module `references/stages/30-architect.md`) if architect hasn't run, or re-run the downstream stage that surfaced the ambiguity.
