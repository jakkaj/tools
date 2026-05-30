# the-flow — Guided Co-Pilot for the SDD `plan-*` Pipeline

**Mode**: Simple
**Spec Version**: 1.0.0
**Created**: 2026-05-29
📚 Specification incorporates findings from `research-dossier.md`.

## Research Context

From `research-dossier.md` (18 findings), the three load-bearing conclusions:

1. **`the-flow` is narration + judgement, not new plumbing.** The `plan-*` pipeline already self-chains — every skill ends with a `Next step: Run /plan-X` line, and several auto-fire (`plan-3` → `plan-5b` + `validate-v2`; `plan-6` → `plan-6a`). `the-flow` adds the human-facing connective tissue and the optional-branch judgement, not the mechanical chain.
2. **`the-flow` is NOT `sdd-tutorial`.** `sdd-tutorial` teaches the RPIV / `task-*` family (`.copilot-tracking/`). `the-flow` drives the `plan-*` family (`docs/plans/`). Same *form* (re-entrant coach), different *content*.
3. **Compaction forces re-entrancy.** `the-flow` recommends `/compact` at seams; `/compact` is a CLI built-in that discards conversation context. So `the-flow` must carry durable on-disk state and resume from it — mirroring the proven `sdd-tutorial` ↔ `sdd-tutorial-next` + `state.yaml` pattern.

## Summary

`the-flow` is a guided co-pilot skill that walks a user through the existing SDD `plan-*` pipeline (`/plan-1a → 1b → [2c] → [2d] → 3 → 5 → 6 → 7 → 8`) — the flow drawn in `skills/SDD/sdd-tutorial/references/getting-started.md`. It opens by asking what the user wants to build (the input to `/plan-1a` or `/plan-1b`), then hand-holds them stage by stage like an expert sitting beside them: it narrates *why* each stage matters, points out one concrete insight from each artifact, surfaces the optional branches the terse pipeline only hints at (`/plan-2c` workshops, `/plan-2d` backpressure survey), suggests `/compact` at natural seams, and makes the background harness loop legible. It **drives by coaching** — it tells the user the exact command to type and resumes from durable state when they return, so it survives the very `/compact` it recommends.

## Goals

- Give a newcomer (human or agent) a single front-door into the `plan-*` pipeline that requires zero prior knowledge of which command comes next.
- Narrate each stage in coaching voice (Orient → Suggest → Invite), surfacing one concrete insight from each produced artifact.
- Surface the **optional** branches the raw pipeline under-advertises: `/plan-2c` (workshops, post-spec), `/plan-2d` (backpressure survey, pre-architect).
- Introduce **explicit `/compact` guidance at stage seams** — a context-hygiene affordance the pipeline lacks today.
- Make the harness loop legible: explain the `/plan-6` boot gate, the silent `harness-2-observe`, and the `harness-3-retro --drain`/`--harvest` prompts, and honour the `docs/compound/.disabled` opt-out.
- Be **re-entrant and durable**: resume cleanly after the user runs a command (and after `/compact`) by reading on-disk state.
- **Adopt a plan already in flight**: if invoked part-way through a cycle (e.g., spec + plan done, up to impl Phase 1) with no prior `the-flow` state, **back-fill** the state + flight-plan files from the existing artifacts as if it had been driving from the top, then continue from the user's actual position.

## Non-Goals

- **Not** reimplementing pipeline orchestration. `the-flow` never duplicates the auto-fires the plan skills already do; it only narrates and issues the next command.
- **Not** a teaching tutorial. It does not replace or duplicate `sdd-tutorial`/`sdd-tutorial-next` (different command family; different intent — real work, not a lesson).
- **Not** running code-changing or merge commands for the user. Like `sdd-tutorial`, it instructs; the user types the command.
- **Not** running `/compact` itself (it can't — it's a user-typed CLI built-in). It recommends it.
- **Not** a gate. It never blocks, scores, or enforces. Every suggestion (workshops, backpressure, compaction) is skippable. (Best-effort norm.)
- **Not** modifying any existing `plan-*` or `harness-*` skill. (Catalog/reference doc edits + an optional `getting-started.md` mention are the only touches outside the new skill.)
- **Not** building first-class CLI/tooling for flight plans (producing/validating/rendering `the-flow.json`) — **out of scope**; the skill hand-cranks the JSON + mermaid by inference for now. The JSON contract is tooling-ready so first-class tooling can take over later.
- **Not** running `minih` itself. the-flow narrates the companion/worker affordance and records agents in `agents[]`; `/plan-6-companion` owns the minih protocol.

## Target Domains

This repo has **no domain registry** — the skills themselves are the product (consistent with plans 022–025). Domain mapping is therefore informal (skill-file mapping), not a `docs/domains/` entry.

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| `skills/SDD/the-flow/` | **NEW** | **create** | The single re-entrant co-pilot skill — the entire deliverable. |
| `skills/SDD/` pipeline + `skills/harness/` | existing | **consume** | Referenced by name only (narration targets). **No edits.** |
| Catalog docs (`README_AGENTS.md`, `docs/skills-pipeline/README.md`, `getting-started.md`) | existing | **modify** | Add catalog rows + a map mention. |

### New "Domain" Sketch — `the-flow` skill

- **Purpose**: A conversational driver/narrator for the `plan-*` SDD pipeline; the spoken form of `getting-started.md`.
- **Owns**: the coach turn-loop, the durable resume-state contract, the per-stage narration scripts, the `/compact`-seam contract, and the harness/backpressure cue points.
- **Excludes**: the actual planning work (owned by `plan-*` skills), the harness loop itself (owned by `harness-*`), and the RPIV/teaching path (owned by `sdd-tutorial*`).

## Testing Strategy

- **Approach**: Lightweight.
- **Rationale**: the-flow is a markdown skill — there is no executable unit surface. Validation is structural + behavioural-by-walkthrough, the same path plan-2d/plan-025 used.
- **Focus Areas**:
  - `scripts/check-skill-slugs.sh` exits 0 (no slug collision; `the-flow`/`the-flow-next` unique).
  - Frontmatter `name:` matches leaf folder name for each new skill.
  - **Dry-run walkthrough** of the coach loop on a real plan folder, including a **re-entry-after-`/compact` simulation** (state read back → correct stage resumed → idempotent, no double-advance).
  - Catalog rows present (grep `the-flow` in both doc files + `getting-started.md`).
- **Excluded**: automated end-to-end execution of the whole `plan-*` pipeline (out of scope — we validate the narration/resume contract, not the downstream skills).
- **Mock Usage**: Avoid mocks entirely — dry-run against a real plan folder (dogfood on `026-the-flow` itself), no fabricated fixture.

## Documentation Strategy

- **Location**: Catalog + pipeline reference. Add a row to `README_AGENTS.md` and `docs/skills-pipeline/README.md`, and a mention in `getting-started.md` (the map `the-flow` voices).
- **Rationale**: Keeps the skill catalog the single source of truth; mirrors how `plan-2d` was documented (plan-025). No standalone `docs/how/` guide — the SKILL.md body + `getting-started.md` already carry the depth.

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=1, I=1, D=2, N=1, F=1, T=1 → P=7 → CS-3
- **Confidence**: 0.70
- **Note on Mode**: The user elected **Simple** mode deliberately. The deliverable is prose skill files, so a single well-structured phase is workable; the bulk of the complexity is in the *design* (the resume-state contract + the narration map), which the spec front-loads. The single phase will be design-dense rather than long.
- **Assumptions**: re-entrant-coach pattern adapted from `sdd-tutorial`; no changes to existing skills; no domain ceremony.
- **Dependencies**: existing `plan-*` + `harness-*` skills (referenced, not modified); `getting-started.md`; `coaching-voice.md`.
- **Risks**: see Risks & Assumptions.
- **Phases**: 1 (Simple mode).

## Acceptance Criteria

1. **AC-1** — A single `skills/SDD/the-flow/SKILL.md` exists with valid frontmatter (`name:` matches folder) and a description that unambiguously distinguishes it from `sdd-tutorial` (drives `plan-*`, not RPIV).
2. **AC-2** — The skill is **single + re-entrant**: one invocation (`/the-flow`) handles both fresh start and resume. On invocation it detects state presence — **absent → fresh start** (ask intent), **present → resume** from the recorded stage. The user types the same `/the-flow` to start and to resume after every command/compact.
3. **AC-3** — The skill opens (fresh start) by asking the user what they want to build and routes that input to `/plan-1a` or `/plan-1b` (with a stated rule for choosing which).
4. **AC-4** — The skill defines a **durable resume-state contract** (minimum fields: plan dir, slug, mode, current stage, pending command, last checkpoint) and a documented write method (temp-file + rename) — sufficient to resume after `/compact`.
5. **AC-5** — The skill is **idempotent on resume**: it reads state, discovers the new artifact, and advances exactly once; if no new artifact exists it re-prints the pending command without double-advancing. (Verified by the re-entry-after-`/compact` walkthrough.)
6. **AC-6** — The skill includes a **per-stage narration map** covering all pipeline seams (`1a, 1b, 2c, 2d, 3, 5, 6, 7, 8`), each with: an Orient line, one-artifact-insight pointer, the optional branch(es) to surface, and the next command to issue — in coaching voice (Orient → Suggest → Invite, one decision per turn, affordance contract).
7. **AC-7** — The skill issues **`/compact` suggestions at the canonical seams** (after `1a`, before `3` post-spec, before `6` post-plan, between phases), each phrased as optional and as "type `/compact` yourself, then re-run `/the-flow`".
8. **AC-8** — The skill surfaces harness affordances at the right seams (boot gate before `6`; observe is silent/mentioned; drain/harvest prompts explained) and **honours `docs/compound/.disabled`** (silently skips harness narration when present).
9. **AC-9** — The skill surfaces `/plan-2c` (post-spec) and `/plan-2d` (pre-architect) as optional branches, framing the `/plan-2d` verdict and any Phase 0 as **user-decided, never a gate**.
10. **AC-10** — The skill never runs code-changing/merge commands for the user and never blocks/scores/gates (stated as an explicit invariant in the body).
11. **AC-11** — `check-skill-slugs.sh` exits 0; catalog rows added to `README_AGENTS.md` + `docs/skills-pipeline/README.md`; `getting-started.md` mentions `the-flow`.
12. **AC-12** — **Host-identity progress rail**: every `the-flow` turn begins with a fixed one-line rail `[the-flow] ◆…◇` (◆=completed macro-milestone, ◇=remaining, joined by `─`; glyphs tunable) — marking the guide's voice (distinct from any `plan-*` output) **and** showing progress. 7 macro-milestones (Research·Spec·Plan·Tasks·Build·Review·Merge), recomputed to mode after `/plan-1b` (Simple trims), monotonic fill driven by `state.milestones_done`; optional/sub-steps get no diamond. A **status line** follows the diamonds in a distinct accent colour — `· now: <current> · next: <next>` — with **dynamic expansion** (single short next inline; ≥2 options or long → `now`/`next` on their own lines, options stacked, recommended first). Stated as a rule + applied to every narration block.
13. **AC-13** — **Verbatim ask logged on fresh start**: by default `the-flow` writes the user's original ask, unedited, to `docs/plans/<ord>-<slug>/original-ask.md` (and mirrors it to `state.intent`) when it creates the plan folder.
15. **AC-15** — **`the-flow.md` flight view**: the skill maintains `docs/plans/<ord>-<slug>/the-flow.md` — a **vertical** mermaid **generated from `the-flow.json`**, refreshed each turn: spine Research·Spec·Plan·[per-phase]·Merge + dashed excursions (deep-research, **each workshop as its own node**, backpressure, fix-loop); **verbatim 🗣 user-input bubbles** on every node the user spoke at; a **parallel-agents** rendering where a **companion wraps** the phases it covers (subgraph) and a **worker** is a side-node into its phase. The text rail (AC-12) is its one-line twin.
16. **AC-16** — **Flight-plan JSON DAG**: the skill maintains `docs/plans/<ord>-<slug>/the-flow.json` — the source-of-truth DAG (instances are called **flight plans**). Each node carries `id`(required)`/type/status/command/ran_at/user_input(verbatim)/note/artifacts[]/next[]/branch_of` plus optional `phase/iterations/tool`; a document-level **`agents[]`** tracks parallel minih agents (`id`(required)`, kind: companion|worker`, `slug`, `runtime`, `run_id`, `status`, `covers[]`, `render`, `driver`, `note`). **The normative field set is workshop 002 § JSON contract + the Node/Agent tables** — the shipped schema (AC-19) and any transcription MUST match it (the sample `references/sample-the-flow.json` is the conformance fixture). Status taxonomy `done|in_progress|blocked|known|assumed` drives mermaid colours; `assumed→known` when `/plan-3` locks phases. The skill **ships `references/flight-plan.template.{json,md}`** (worked example) so flight plans stay standardised. (First-class tooling to produce/render the JSON lands later — OOS now; hand-cranked by the skill.)
17. **AC-17** — **Companion & worker affordance**: at the build seam the-flow surfaces running work *alongside* the flow — default `code-review-companion` via `/plan-6-v2-implement-phase-companion` (supersedes `/plan-7`), plus the ability to attach other minih agents (companions or workers). the-flow **narrates + records them in `agents[]`** (companion→wrap, worker→side-node) but does **not** run minih itself; all optional (`--no-companion` fallback).
14. **AC-14** — **Optional branches are light mentions**: the ~6 non-spine branches (deep-research after `1a`, `/plan-3a` ADR, prework gate, the fix loop after `7`, domains, `/util-0-handover`) are surfaced as one-line optional mentions at the relevant seam — not first-class stages. The `awaiting-1a` deep-research mention names the user's tool of choice (online agent **or** coding harness).
18. **AC-18** — **Mid-plan adoption (late-join / back-fill)**: when `/the-flow` is invoked with **no active state** but the target plan folder **already holds artifacts** (any of `*-spec.md`, `*-plan.md`, `tasks/phase-*/`, reviews), the skill **reconstructs** the resume state + `original-ask.md` (best-effort, from the spec/research if the verbatim ask is unrecoverable) + `the-flow.json`/`the-flow.md` **from the artifacts present** — inferring `mode`, completed milestones, and the current stage by artifact existence — then resumes from the user's **actual** position (e.g., "Plan done, Phase 1 next") instead of forcing a fresh start, **presented as a confirmable suggestion** ("looks like Plan done, Phase 1 next — correct?"), never an assertion. Adoption never re-runs a stage or touches spec/plan/tasks/reviews; it only writes the the-flow bookkeeping files, and **never clobbers existing ones** (if `original-ask.md` exists it writes `original-ask.reconstructed.md`; it merges rather than overwrites a non-empty `the-flow.json`). Stated as a third entry path (fresh / resume / **adopt**) in the main loop, governed by an explicit **Adoption Contract** (folder resolution, artifact→stage inference table incl. partial-phase and spec-only cases, mode/rail handling, adopted-node field handling, and the safety write-rules) — see the plan's Adoption Contract section.
19. **AC-19** — **Skill ships the flight-plan schema + samples**: the skill ships, under `references/`, a **JSON Schema** for the flight-plan DAG (`flight-plan.schema.json`) encoding the **full** node field set (`id`(required)`/type/status/command/ran_at/user_input/note/artifacts[]/next[]/branch_of` + optional `phase/iterations/tool`) and document-level `agents[]` (`id`(required)`/kind/slug/runtime/run_id/status/covers[]/render/driver/note`) **exactly as enumerated in workshop 002 § JSON contract**, such that `references/sample-the-flow.json` validates against it (every required field present; no unknown-field rejection) — alongside the worked-example templates (`flight-plan.template.{json,md}`) and the `sample-the-flow.{json,md}` reference. The schema is **documentation/standardisation only**: hand-validated by the skill, no runtime validator (first-class tooling is OOS). This is a **deliberate pull-forward of workshop 002 Open-Q1** (which deferred only the *validator*, not the schema file); the schema file itself carries a `$comment` stating it is reference-only and mirrors the template.
20. **AC-20** — **Agent self-mirroring + re-entry reminder**: each narration turn instructs the **coding agent** running the session to (a) **mirror the flow in its own todo list** (one todo per upcoming pipeline stage / current phase, kept in sync with the rail) so the plan is legible in the agent's native task tracker, and (b) **re-invoke `/the-flow` after every `/compact`** (and on any fresh session) to reload durable state and resume. The `/compact` suggestion copy and the resume handshake both end with the explicit "after compacting, run `/the-flow` again" reminder, and the body states the todo-mirroring expectation as a standing instruction.

## Risks & Assumptions

| Risk | Mitigation |
|------|-----------|
| Confusion / collision with `sdd-tutorial` | Distinct slug, description, and an explicit "this drives `plan-*`, not RPIV" line in the body. Catalog row states the distinction. |
| Drift into reimplementing orchestration the plan skills already do | Non-Goal stated; narration map only *reads artifacts + re-frames the skill's own `Next step` line*; never duplicates auto-fires. |
| Re-entry double-advances or loses place after `/compact` | Idempotent re-entry contract (AC-4) + artifact-discovery-by-checkpoint (sdd-tutorial-next precedent); covered by the re-entry walkthrough. |
| Stale narration if pipeline skill names change | Reference skills by their current names; a future rename would touch the narration map (accepted — low frequency; vocab is frozen per plan-024). |
| Over-prompting `/compact` becomes annoying | Suggest only at the 3–4 canonical seams, always optional, never on every turn. |
| Scope creep into a `docs/how/` guide or hybrid drive model | Both deferred: hybrid (Option C) listed as a Workshop Opportunity; docs limited to catalog rows. |

## Open Questions

- **Skill structure** → RESOLVED (Round 2): **single re-entrant `the-flow`** that detects fresh-vs-resume from state presence. One file, one slug.
- **Drive model** (Option A re-entrant coach vs C hybrid) → defaulted to **A** per the dossier; C is a Workshop Opportunity, not a blocker.
- Agent harness: **N/A for building this feature** — `the-flow` is a prose skill with no running software to Boot/Interact/Observe. (Recorded, not asked.)

## Workshop Opportunities

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Drive model: re-entrant coach (A) vs hybrid (C) | Integration Pattern | Hybrid (drive within a segment, hand off at compaction seams) could feel smoother but adds a second mental model | When does it drive directly vs hand off? Is the smoother in-segment feel worth the complexity for a best-effort co-pilot? |
| The `/compact`-seam contract | CLI Flow | The exact resume handshake after `/compact` is the novel part | Precise message wording; how state is re-located on resume; what happens if the user skips `/compact`. |
| Per-stage narration scripts | CLI Flow | The voiced messages at each of the 9 seams are the heart of the UX | Exact Orient/Suggest/Invite copy per stage; how to pick the "one insight" from each artifact. |

> These are optional. The drive model is **recommended to default to Option A (re-entrant coach)** per the dossier; the others can be designed inline during implementation.

## Clarifications

### Session 2026-05-29

**Round 1 (front-loaded):**
- **Workflow Mode** → **Simple** (user election; CS-3 deliverable is prose, single design-dense phase is workable).
- **Testing Strategy** → **Lightweight** (slug check + frontmatter match + dry-run walkthrough incl. re-entry-after-compaction sim).
- **Mock Usage** → **Avoid mocks entirely** (dogfood on a real plan folder).
- **Documentation Strategy** → **Catalog + pipeline ref** (README_AGENTS + skills-pipeline README + getting-started.md mention).

**Recorded without asking:**
- **Agent harness** → N/A. `the-flow` is a prose skill; nothing to Boot/Interact/Observe for building it. No domain registry exists; skills are the product (informal mapping).

**Round 2:**
- **Skill structure** → **Single re-entrant `the-flow`**. One invocation handles fresh start (no state → ask intent) and resume (state present → advance from recorded stage). One file (`skills/SDD/the-flow/SKILL.md`), one slug. Rejected the `the-flow` + `the-flow-next` pair (proven via sdd-tutorial, but two files/slugs and the user must remember which to type). Rationale: KISS — same `/the-flow` to start and to resume after every command/`/compact`.
