# Harness-Aware V2 Command Pipeline

**Mode**: Simple

## Research Context

📚 This specification incorporates findings from research-dossier.md and workshop-001-agent-harness-dossier.md.

Key research findings informing this spec:
- The v2 command system uses a proven 10-step cross-cutting concern pattern (demonstrated by domains) that harness awareness should follow exactly (KF-02)
- `docs/project-rules/` is the canonical rules path; zero references to `docs/rules/` exist in any v2 command (KF-01)
- Rules are convention-discovered, not parameter-passed — commands auto-locate `docs/project-rules/*.md` (KF-06)
- The testing pipeline already partially implements harness concepts (evidence capture, testing strategy, coverage mapping) — harness extends these, not replaces them (KF-05)
- The harness dossier establishes three non-negotiable capabilities (Boot, Interact, Observe), seven design principles, a maturity model (L0–L4), and six patterns by software type

## Summary

Give AI agents the ability to autonomously validate their work by integrating **harness awareness** — the Boot → Interact → Observe → Validate feedback loop — as a cross-cutting concern throughout the v2 command pipeline. When a project has a harness, agents use it to iterate in 30-60 second cycles instead of asking humans to test. When no harness exists, the pipeline guides users toward building one as Phase 0. The harness is governed by a project-level rule file (`docs/project-rules/harness.md`) and enforced through the same pattern that makes domains work: file check → context load → clarify → architect → task → implement → review.

## Goals

- **Harness governance format**: Define the `docs/project-rules/harness.md` artifact with sections for Boot, Interact, Observe, maturity assessment, and history — following existing rule file conventions (version, USER CONTENT markers, section headers)
- **New harness utility prompt**: Create `harness-v2.md` that can either create a new harness.md (detecting project type and generating skeleton) or validate an existing one (health check, capability verification, maturity assessment)
- **Pipeline awareness in plan-1a**: Explore phase discovers harness status; if present, includes boot/interact/observe details in research dossier; if absent, suggests a workshop opportunity
- **Pipeline awareness in plan-2**: Clarify phase asks about harness readiness as a standard question; if no harness exists, asks whether building one should be Phase 0; user can override
- **Pipeline awareness in plan-3**: Architect phase creates "Build Harness" as Phase 0 when needed (unless user overrode); adds Harness Strategy section to plan output
- **Pipeline awareness in plan-5**: Tasks phase enforces Phase 0 harness construction; pre-implementation check verifies harness health; context brief includes harness details
- **Pipeline awareness in plan-6**: Implement phase validates harness health at the **start of every phase** (not just once); if unhealthy, stops and asks human (who can override); uses harness observe capabilities for evidence capture; updates harness.md history post-phase
- **Pipeline awareness in plan-7**: Code review fires up the harness and **actually validates the changes work** — boots the system, walks through the code changes interactively, captures evidence. This is a live gate, not just static review.
- **Graceful degradation**: Every integration point works without a harness — the pipeline never breaks, just notes the absence and offers guidance
- **Human override at every gate**: Humans can override any harness-related stop (no harness needed, continue despite unhealthy harness, skip Phase 0)

## Non-Goals

- **Not replacing the testing strategy system** — harness is HOW the agent validates; testing strategy (TDD/TAD/Lightweight/Manual) is WHAT gets validated. They're complementary.
- **Not creating a domain for harness** — harness is project-wide infrastructure (like constitution), not a business domain
- **Not building actual harnesses** — this feature adds *awareness* to the command pipeline; actual harness scripts (harness.mjs, justfile recipes) are per-project deliverables
- **Not modifying plan-0 (constitution)** — while constitution could detect harness maturity, that's a future enhancement; this spec focuses on the pipeline commands
- **Not modifying plan-8 (merge)** — merge is out of scope for harness awareness

## Target Domains

ℹ️ No domain registry exists for this repository. The following are logical areas affected by this feature.

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| v2-commands | existing | **modify** | Add harness awareness sections to 6 existing command prompts + create 1 new prompt |
| project-rules | **NEW** | **create** | Define the harness.md governance format as a new rule file type |

### New Domain Sketches

#### project-rules [NEW]
- **Purpose**: Project-wide governance artifacts that v2 commands auto-discover at `docs/project-rules/` — constitution, rules, idioms, architecture, and now harness
- **Boundary Owns**: Rule file format conventions, governance sections, USER CONTENT preservation markers, version tracking
- **Boundary Excludes**: Per-domain documentation (belongs in `docs/domains/`), procedure/bootstrap scripts (belong in project root or scripts/)

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2, I=0, D=0, N=1, F=0, T=1
  - Surface Area (S=2): 6 existing command files modified + 1 new file created, cross-cutting across the pipeline
  - Integration (I=0): Internal changes only — no external dependencies
  - Data/State (D=0): No schema or data migrations; pure markdown prompt changes
  - Novelty (N=1): Pattern is well-established (domains), but harness-specific decisions need clarification (exact question wording, Phase 0 mechanics)
  - Non-Functional (F=0): Standard prompt engineering, no performance or security concerns
  - Testing/Rollout (T=1): Changes need validation across multiple command files to ensure consistency; manual testing by running commands
- **Confidence**: 0.85
- **Assumptions**:
  - The domain cross-cutting pattern is the correct template (high confidence from research)
  - `docs/project-rules/harness.md` is the right location (confirmed by DC-08: zero references to `docs/rules/`)
  - Commands can be modified independently (each is a self-contained markdown prompt)
- **Dependencies**: None — this is a prompt-only change with no code dependencies
- **Risks**: Verbosity creep (adding harness sections to 5 commands increases their length); mitigated by keeping additions concise
- **Phases**: Simple mode — single inline implementation phase

## Acceptance Criteria

1. **AC-01**: A `docs/project-rules/harness.md` governance format is defined with sections for Boot, Interact, Observe, Maturity Assessment (L0–L4), History, and USER CONTENT markers — following existing rule file conventions from plan-0-v2-constitution
2. **AC-02**: A new `harness-v2.md` prompt exists in `agents/v2-commands/` that can: (a) detect whether `docs/project-rules/harness.md` exists, (b) in create mode: detect project type and generate a harness.md skeleton, (c) in validate mode: run health check, verify Boot/Interact/Observe capabilities, report maturity level
3. **AC-03**: `plan-1a-v2-explore.md` includes harness discovery — if harness.md exists, includes status/maturity/usage in dossier; if absent, notes it and suggests a workshop opportunity
4. **AC-04**: `plan-2-v2-clarify.md` includes a "Harness Readiness" standard question — if no harness, asks whether Phase 0 should build one; captures user answer (including override) in spec
5. **AC-05**: `plan-3-v2-architect.md` creates Phase 0 "Build Harness" when needed (from plan-2 answer) unless user overrode; adds Harness Strategy section to plan output
6. **AC-06**: `plan-5-v2-phase-tasks-and-brief.md` enforces Phase 0 harness construction when applicable; pre-implementation check verifies harness health; context brief includes harness boot/interact/observe details
7. **AC-07**: `plan-6-v2-implement-phase.md` validates harness health at the start of **every phase**; if unhealthy, stops and asks human (who can override); uses harness for evidence capture; updates harness.md § History post-phase
8. **AC-08**: `plan-7-v2-code-review.md` boots the harness and validates the phase's changes actually work — fires up the running system, exercises the code changes via the harness interaction methods, captures evidence. If harness unavailable, falls back to static review with a note.
9. **AC-09**: All 6 modified commands degrade gracefully when no harness.md exists — pipeline never breaks, just notes absence
10. **AC-10**: Human can override at every harness-related gate: "no harness needed", "continue despite unhealthy", "skip Phase 0"

## Risks & Assumptions

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Adding harness sections increases command verbosity | Medium | Medium | Keep additions concise (5-15 lines per command); use same patterns as domain integration |
| Users confused by harness vs testing strategy | Low | Medium | Plan-2 separates the question: "testing strategy = what to verify; harness = how agent verifies" |
| Harness.md governance format becomes too prescriptive | Low | Low | Include USER CONTENT markers for customization; keep required sections minimal |
| Modified commands diverge from each other in harness handling | Medium | Medium | Define consistent integration pattern once, apply uniformly |

## Open Questions

None — all resolved in clarification session 2026-03-06.

## Clarifications

### Session 2026-03-06

**Q1: Workflow Mode** → **Simple** — single-phase plan, lighter gates. Cross-cutting but all changes are markdown prompt edits.

**Q2: Testing Strategy** → **Manual Only** — review prompt text for correctness. No live testing (these are prompt engineering changes, not code).

**Q3: Harness file path** → **`docs/project-rules/harness.md`** — matches all 27 v2 commands that reference `docs/project-rules/` for rule files. Zero commands reference `docs/rules/`. User initially suggested `docs/rules/` but confirmed `docs/project-rules/` after seeing the evidence.

**Q4: Plan-7 code review** → **IN SCOPE** — Plan-7 should fire up the harness and actually validate the changes work. Booting the real system and walking through the code change is an important gate, not just static review. User reversed initial "future enhancement" decision.

**Q5: Plan-0 constitution** → **Future enhancement** — keep plan-0 out of scope. Harness maturity detection during constitution setup is a natural follow-up.

**Q6: Commands-lite pipeline** → **v2-commands only** — the lite pipeline doesn't use FlowSpace or domains; harness awareness relies on the domain-style cross-cutting pattern.

### Testing Strategy

- **Approach**: Manual Only
- **Rationale**: All deliverables are markdown prompt files — no unit-testable code. Validation is by reading and reviewing the prompts.
- **Focus Areas**: Consistent harness integration pattern across all 5 modified commands; graceful degradation wording; override UX consistency
- **Excluded**: Live testing against projects, automated validation

| Topic | Type | Why Workshop | Key Questions |
|-------|------|--------------|---------------|
| Harness Prompt Design | CLI Flow | The create/validate dual-mode prompt needs careful UX design — detection logic, output format, maturity assessment algorithm | How does project type detection work? What's the minimal viable harness.md? How does validate mode run health checks from a prompt? |
| Pre-Phase Validation Protocol | Integration Pattern | Plan-6's "validate harness at start of every phase" needs precise specification — what checks, what order, what failure modes, what the human override UX looks like | What's the health check sequence? How long to wait? What's "unhealthy" vs "slow"? How does override get logged? |
