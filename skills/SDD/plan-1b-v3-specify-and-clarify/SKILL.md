---
name: plan-1b-v3-specify-and-clarify
description: |
  Create a feature spec AND resolve high-impact ambiguities in a single skill. Front-loads questions: asks host-independent questions (Mode/Testing/Mock/Docs) in ONE batched prompt BEFORE writing the spec, generates the sketch with those answers already applied, then asks a conditional second batch only for sketch-dependent gaps (Domain Review, Agent Harness, topic-specific markers). Cap ≤8 total. Uses batched prompting where the host supports it (e.g., Claude Code's AskUserQuestion), falls back to sequential one-at-a-time on hosts that don't. Replaces the old plan-1b → plan-2 two-skill hop.
---
Please deep think / ultrathink as this is a complex task.

# plan-1b-v3-specify-and-clarify

Create or update the feature **spec** AND resolve high-impact ambiguities in **one pass**. Front-loads the host-independent questions BEFORE the spec sketch so the resulting document arrives already-clarified, then only asks a second batch for genuinely sketch-dependent topics.

This skill replaces the legacy `plan-1b-v2-specify` + `plan-2-v2-clarify` pair. The old `plan-2-v2-clarify` is preserved as a soft-deprecated re-entry point for adding clarifications to an existing spec mid-plan.

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
   - If `docs/plans/*-<slug>/` already exists (created by `/plan-1a-explore`) → use it
   - Else → create new folder with next available ordinal
   - `PLAN_DIR = docs/plans/<ordinal>-<slug>/`
   - `SPEC_FILE = ${PLAN_DIR}/<slug>-spec.md`

2. Check for and incorporate existing research:
   - If `${PLAN_DIR}/research-dossier.md` exists → read fully; use to inform complexity, domains, and question framing. Add note to spec: "📚 Specification incorporates findings from research-dossier.md"
   - Else → add note: "ℹ️ Consider running `/plan-1a-explore` for deeper codebase understanding"

3. Check for existing domains:
   - If `docs/domains/registry.md` exists → read it; read `docs/domains/domain-map.md` if present; for each domain scan `docs/domains/<slug>/domain.md` for relevant contracts/composition
   - Else → note that domains will be identified as part of this spec

4. Check for workshop documents:
   - If `${PLAN_DIR}/workshops/*.md` exist → read all; they are **authoritative design decisions** and must not be contradicted

5. Check for agent harness:
   - Note whether `docs/project-rules/engineering-harness.md` (or legacy `agent-harness.md` / `harness.md`) exists and its maturity level if so

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

  CS rubric — S=Surface Area, I=Integration, D=Data/State, N=Novelty, F=Non-Functional, T=Testing/Rollout (each 0-2). Total P → CS: 0-2=CS-1, 3-4=CS-2, 5-7=CS-3, 8-9=CS-4, 10-12=CS-5.

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
- Agent harness state is unclear or doesn't exist → ask **Agent Harness Readiness**
- The sketch left ≥1 critical `[NEEDS CLARIFICATION]` marker → ask up to 2 topic-specific questions

**Compose Round 2** (up to 4 questions in one batched prompt). Skip Round 2 entirely if none of the conditions hold.

Submit as ONE batched call on batched hosts; sequentially on sequential hosts.

**Total cap across Round 1 + Round 2 = 8 questions.** If Round 1 used 4 and Round 2 needs 5+, drop the lowest-priority Round 2 items.

After Round 2:
- Append Q&A to the same `### Session YYYY-MM-DD` block in `## Clarifications`
- Update affected sections immediately (`## Target Domains` for boundary adjustments, agent-harness decision recorded for `plan-3-v2-architect`, topic-specific markers replaced with resolved values)
- Save the spec

---

## Phase 4 — Generate Flight Plan

Auto-call `/plan-5b-flightplan --plan "${SPEC_FILE}"` (no `--phase` flag = plan-level mode). Status starts as "Specifying"; enriched when `/plan-3` runs.

---

## Standard Questions

### Workflow Mode (Round 1, Q1 unless `--simple`)

| Option | Mode | Best For | What Changes |
|--------|------|----------|--------------|
| A | Simple | CS-1/CS-2 tasks, single phase, quick path | Single-phase plan, inline tasks, plan-4/plan-5 optional |
| B | Full | CS-3+ features, multiple phases | Multi-phase plan, required dossiers, all gates |

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

### Agent Harness Readiness (Round 2, conditional)

**If harness exists**: report current maturity (L0–L4) and ask "Is L[N] sufficient for this feature, or does it need updating?"

**If no harness**: ask "This project has no agent harness (Boot → Interact → Observe feedback loop). Without one, the agent validates via unit tests and manual verification only. Note: this is the agent-side feedback layer — it sits on top of the project's engineering harness (justfile/Makefile/dev script) and assumes that substrate already works." Options: "Build agent harness as Phase 0 (Recommended)" / "Continue without agent harness" / "Feature doesn't need an agent harness".

After: capture in `## Clarifications`. If "Build as Phase 0" chosen, note for `plan-3-v2-architect`. If overridden, document the override reason.

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

`SPEC_FILE` written with all clarifications applied, `## Clarifications` log populated, Flight Plan generated at plan root.
```

Next steps:
- **If Workshop Opportunities identified**: Consider running **/plan-2c-workshop**
- **Otherwise**: Run **/plan-3-v2-architect** to generate the implementation plan
- **To add clarifications later** (mid-plan or post-architect): Run **/plan-2-v2-clarify** to open a new `### Session` block
