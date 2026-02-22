# Plan Domain System

**Mode**: Simple

ℹ️ Consider running `/plan-1a-explore` for deeper codebase understanding

📐 This specification incorporates findings from 3 completed workshops:
- `workshops/domain-system-design.md` — domain model, registry, lifecycle, extraction
- `workshops/v2-command-structure.md` — v2 command placement and inheritance model
- `workshops/lean-plan-task-design.md` — leaner plan-3 and plan-5 output design

## Summary

The plan workflow currently tracks files by **plan provenance** (PlanPak) but lacks a persistent concept of **business domain**. This causes concept reinvention across plans, files homed in wrong locations, and loss of boundary awareness over time. The domain system introduces first-class domains as the primary unit of code ownership — every source file belongs to a domain, every plan delivers into domains, and domains persist as living organizational units that accumulate capability across the codebase lifetime. This replaces PlanPak.

Alongside the domain system, the plan-3 (architect) and plan-5 (tasks) commands are redesigned to be leaner — providing strategic guardrails and context without removing implementor agency. Changes are delivered as v2 commands in a new `agents/v2-commands/` directory, leaving v1 commands untouched.

## Goals

- **First-class domains**: Introduce persistent, named business concept boundaries (`docs/domains/<slug>/domain.md`) that own code, contracts, composition, and history
- **Domain registry**: Single source of truth (`docs/domains/registry.md`) listing all domains with type, parent, status, and provenance
- **Anti-reinvention**: Three-layer defense (research → audit → review) that checks domain contracts before proposing new code
- **Bidirectional traceability**: File → domain → plan and plan → domain → file, with FlowSpace footnotes gaining domain context
- **Brownfield extraction**: New `/extract-domain` command for collaboratively identifying and formalizing existing code concepts as domains without moving files
- **Leaner planning**: Slim plan-3 output (~400-500 lines prompt, down from 1446) and plan-5 output (~300-400 lines, down from 942) that tell implementors *what* to build and *where*, not *how*
- **V2 command structure**: 8 files in `agents/v2-commands/` (7 v2 overrides + 1 new command) that inherit from v1 via REPLACES/ADDS/REMOVES/MODIFIES directives — no duplication of unchanged commands
- **Implementor agency**: Task tables slimmed from 10 columns to 7, research subagents reduced from 4 to 2, ceremony sections removed, prior-phase review via direct file reads instead of parallel subagents

## Non-Goals

- Full DDD implementation (no aggregates, entities, value objects as formal patterns — just domain boundaries and contracts)
- Retroactive migration of existing codebases (domains are adopted incrementally as plans touch code areas)
- Replacing the plan workflow itself (plans remain the unit of work; domains are the unit of meaning)
- Modifying any v1 commands in `agents/commands/` (all changes land in `agents/v2-commands/`)
- Prescribing test file locations (deferred to project conventions, same as PlanPak)
- Prescribing internal domain directory structure (domain owners decide `contracts/`, `adapters/`, `repositories/` layout)
- Moving source files during `/extract-domain` (extraction is documentation, not refactoring)

## Complexity

- **Score**: CS-3 (medium)
- **Breakdown**: S=2, I=0, D=0, N=1, F=0, T=1
- **Confidence**: 0.75
- **Assumptions**:
  - V2 commands are markdown prompt files, not executable code — lower risk than code changes
  - The inheritance model (REPLACES/ADDS/REMOVES) works in practice for LLM prompt composition
  - Domain system concepts are well-defined from workshops — low novelty remaining
- **Dependencies**: None external — all changes are within the tools repository
- **Risks**:
  - V2 prompt inheritance may not compose cleanly — LLMs may not reliably follow "inherit v1 except these overrides"
  - Domain system adds overhead to plan flow — if domains are too heavy, users skip them
  - Lean plan outputs may be too lean for complex features — need escape hatch to more detail
- **Phases**:
  - Phase 1: Domain system infrastructure (registry, domain.md template, extract-domain command)
  - Phase 2: V2 commands for spec and clarify (plan-1b-v2, plan-2-v2)
  - Phase 3: V2 commands for architect and tasks (plan-3-v2, plan-5-v2 — the big ones)
  - Phase 4: V2 commands for implement, progress, and review (plan-6-v2, plan-6a-v2, plan-7-v2)
  - Phase 5: Install/sync pipeline updates, README, documentation

## Acceptance Criteria

1. `docs/domains/registry.md` template exists and documents the domain registry format (types, statuses, parent relationships)
2. `docs/domains/<slug>/domain.md` template exists with locked-down required sections: Purpose, Boundary, Contracts, Composition, Source Location, History
3. Domain folders allow arbitrary additional files alongside domain.md for creative exploration
4. `/extract-domain` command exists in `agents/v2-commands/` and describes the collaborative brownfield extraction workflow
5. `agents/v2-commands/` directory contains exactly 8 files: plan-v2-extract-domain.md, plan-1b-v2-specify.md, plan-2-v2-clarify.md, plan-3-v2-architect.md, plan-5-v2-phase-tasks-and-brief.md, plan-6-v2-implement-phase.md, plan-6a-v2-update-progress.md, plan-7-v2-code-review.md
6. Each v2 command is a **complete standalone rewrite** — no references to v1, no inheritance directives, fully self-contained
7. V2 plan-3 prompt is ≤500 lines (down from 1446) with 2 research subagents (down from 4) and concise findings table format
8. V2 plan-5 task table has 7 columns (Status, ID, Task, Domain, Path(s), Done When, Notes) — down from 10
9. V2 plan-5 uses direct file reads for prior-phase context (4 bullets per phase) — no parallel subagents
10. V2 plan-5 auto-generates flight plans (plan-5b) by default; requirements flow (plan-5c) is optional
11. All PlanPak conditional blocks (`If PlanPak active...`) in v2 commands are replaced by domain equivalents
12. No files in `agents/commands/` are modified
13. `scripts/sync-to-dist.sh` syncs `agents/v2-commands/` to `src/jk_tools/agents/v2-commands/`
14. `install/agents.sh` installs v2-commands alongside v1 commands in all target directories

## Risks & Assumptions

**Risks**:
- **Domain overhead**: If creating/maintaining domain.md feels like busywork, adoption will fail. Mitigation: Keep minimum viable domain.md very small (slug + purpose + boundary). Composition and contracts fill in over time.
- **Lean plans too lean**: Complex features may need more context than the slim format provides. Mitigation: Workshops and plan-5c (requirements flow) remain available as optional deep-dives.
- **V1/V2 confusion**: Users may not know which to use. Mitigation: Clear README in v2-commands explaining when to use v2 vs v1.
- **Domain template discovery**: Templates (domain.md, registry.md) need to be findable by agents whether commands are installed locally or centrally. Discovery mechanism TBD during implementation.

**Assumptions**:
- Users are willing to identify and name domains collaboratively during planning
- The tools repository install pipeline can handle a second commands directory without breaking
- Infrastructure domains (`_platform` and children) follow the same rules as business domains
- Domain.md freeform markdown validated by plan-7 convention checking is sufficient (no schema enforcement needed)
- V2 commands are complete standalone rewrites, not layered overrides on v1

## Testing Strategy

- **Approach**: Manual
- **Rationale**: Deliverables are markdown prompt files and shell script changes — no executable code to test
- **Focus Areas**: Verify install pipeline correctly syncs and deploys v2-commands
- **Mock Usage**: N/A

## Documentation Strategy

- **Location**: README.md in v2-commands/ directory
- **Rationale**: V2 commands are self-documenting; README explains when to use v2 vs v1

## Clarifications

### Session 2026-02-22

**Q1: V1/V2 coexistence** — Don't decide now. Ship v2, revisit later based on usage.

**Q2: Shared reference docs** — No external reference files (tricky to ship). Remove TAD and Footnote concepts from v2 commands. Leave anchor conventions and graph traversal inline in the commands that need them.

**Q3: V2 command self-containedness** — V2 commands are **complete standalone rewrites**, not layered overrides. No REPLACES/ADDS/REMOVES directives, no references to v1. Each v2 command is fully self-contained.

**Q4: Install pipeline scope** — Yes, include sync-to-dist.sh and agents.sh updates in this plan.

**Q5: Domain template files** — Yes, ship domain.md and registry.md templates. Discovery mechanism (local vs central install) needs design during implementation — agents need to know where to find them regardless of install mode.

## ADR Seeds (Optional)

- **Decision Drivers**: Need persistent concept tracking across plans; PlanPak tracks provenance but not business meaning; plan outputs are too heavy and slow
- **Candidate Alternatives**:
  - A: Domain system with v2 commands (selected — workshops designed this)
  - B: Enhance PlanPak with domain metadata (rejected — PlanPak's organizing principle is wrong)
  - C: Full DDD with aggregates and bounded contexts (rejected — too heavy for prompt-based tooling)
- **Stakeholders**: Repository maintainer, plan workflow users

## Workshop Opportunities

All workshops for this feature have been completed:

| Topic | Type | Status | Document |
|-------|------|--------|----------|
| Domain System Design | Data Model + Integration Pattern | ✅ Complete | `workshops/domain-system-design.md` |
| V2 Command Structure | Integration Pattern | ✅ Complete | `workshops/v2-command-structure.md` |
| Lean Plan & Task Design | Integration Pattern | ✅ Complete | `workshops/lean-plan-task-design.md` |

No further workshops needed before architecture.
