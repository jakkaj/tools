# Domain Self-Documentation (Concepts as Internal SDK)

**Mode**: Simple

ℹ️ Consider running `/plan-1a-explore` for deeper codebase understanding

📐 This specification incorporates findings from 1 completed workshop:
- `workshops/domain-sdk-documentation.md` — concept catalog design, command integration, code-concept-search enhancement

## Summary

Domains currently document *what they are* (boundary, contracts, composition) but not *what they offer* to consumers. A developer or coding agent encountering a domain must read source code to understand its capabilities, entry points, and usage patterns. This feature adds a mandatory `## Concepts` section to `domain.md` — a scannable table of capabilities plus narrative usage guides — turning every domain into a self-documenting internal SDK. The Concepts section becomes a structured index that `/code-concept-search` scans first, making concept discovery near-instant and dramatically strengthening the anti-reinvention defense.

## Goals

- **Self-documenting domains**: Every domain publishes a concept catalog (scannable table + narrative per concept with code examples) so consumers can discover and use capabilities without reading source code
- **Rapid concept discovery**: Coding agents identify "does this concept exist?" in seconds by scanning Concepts tables across all domains, before falling through to source code search
- **Anti-reinvention strengthened**: All three layers (research → audit → review) gain a structured capability index, making duplicate implementation obvious
- **Living documentation**: Concepts are created during domain extraction (`extract-domain`) and maintained during implementation (`plan-6-v2`) — they stay current as domains evolve
- **Consistent entry points**: Each concept names its entry point (the contract/function a consumer imports first), eliminating the "where do I start?" problem

## Non-Goals

- Auto-generating Concepts from source code (hand-written skeleton, maintained by commands — same rationale as domain-map.md)
- Documenting internal implementation details (Concepts is consumer-facing; internals stay in Composition and code comments)
- Replacing the Contracts table (Concepts groups related contracts into capabilities; Contracts remains the formal interface list)
- Full API reference with every parameter/return type (agents discover implementation details easily; Concepts focuses on what exists and how to start using it)
- Modifying any v1 commands in `agents/commands/` (all changes land in `agents/v2-commands/`)

## Target Domains

| Domain | Status | Relationship | Role in This Feature |
|--------|--------|-------------|---------------------|
| v2-commands (plan system) | existing | **modify** | Update 8 v2 command prompts to create/maintain/validate Concepts section |
| code-concept-search | existing | **create v2** | New v2 rewrite with Concepts table scanning as first search layer |
| domain templates | existing | **modify** | Update domain.md template with Concepts section and new section order |

*Note: The "domains" here are agent command files in `agents/v2-commands/` and `agents/commands/`, not application domains. This feature changes the plan toolchain itself.*

### Affected V2 Commands

| Command File | Change Type | What Changes |
|-------------|-------------|-------------|
| `plan-v2-extract-domain.md` | Modify | Add Step 3.5 (identify concepts), update Step 4a (write Concepts section in domain.md) |
| `plan-3-v2-architect.md` | Modify | Phase 0 domain loading reads § Concepts; research subagents check Concepts tables for anti-reinvention |
| `plan-5-v2-phase-tasks-and-brief.md` | Modify | Context Brief references concept names for domain dependencies |
| `plan-6-v2-implement-phase.md` | Modify | Add step h to post-implementation checklist (update/create Concepts when contracts change) |
| `plan-6a-v2-update-progress.md` | Modify | Flag "Concepts update needed" when contract changes recorded |
| `plan-7-v2-code-review.md` | Modify | Add checklist item 10: Concepts section exists if contracts exist (⚠️ Review) |
| `didyouknow-v2.md` | Modify | Surface Concepts-related insights (missing concepts, stale concepts, concept reuse opportunities) |
| `plan-4-v2-complete-the-plan.md` | Modify | Domain Completeness Validator checks that domains with contracts have § Concepts |

### New V2 Command

| Command File | Change Type | What Changes |
|-------------|-------------|-------------|
| `code-concept-search-v2.md` | **New** | V2 rewrite of code-concept-search with Concepts table scanning as first search layer |

## Complexity

- **Score**: CS-2 (small)
- **Breakdown**: S=1, I=0, D=0, N=0, F=0, T=1
  - S=1: Multiple files touched (9 command files) but all are markdown prompts, not executable code
  - I=0: Internal only — no external dependencies
  - D=0: No data/state changes — markdown template additions
  - N=0: Well-specified from workshop with all design decisions resolved
  - F=0: Standard — no perf/security/compliance concerns
  - T=1: Manual testing — verify command prompts produce correct output
- **Confidence**: 0.90
- **Assumptions**:
  - V2 commands are markdown prompt files — changes are low-risk text edits
  - Workshop resolved all design decisions (section placement, format, enforcement level, code examples)
  - domain.md template is embedded inline in `plan-v2-extract-domain.md` — updating the template is a single file edit
- **Dependencies**: Plan 015 (domain system) must be complete (it is — all 12 tasks done ✅)
- **Risks**:
  - Concepts section adds maintenance burden — mitigated by keeping Level 1 (table only) as minimum; narratives grow organically
  - LLM agents may not consistently populate Concepts during implementation — mitigated by plan-7 validation flagging missing sections
- **Phases**:
  - Phase 1: Update domain.md template + extract-domain command (the foundation)
  - Phase 2: Update plan-5, plan-6, plan-6a, plan-7 commands (the workflow integration)
  - Phase 3: Update code-concept-search (the discovery payoff)

## Acceptance Criteria

1. `plan-v2-extract-domain.md` domain.md template includes `## Concepts` section between Purpose and Boundary, with table format (Concept | Entry Point | What It Does) and narrative subsection placeholders
2. `plan-v2-extract-domain.md` includes Step 3.5 that groups discovered contracts into named concepts and identifies primary entry points
3. Domain.md section order is: Purpose → Concepts → Boundary → Contracts → Composition → Source Location → Dependencies → History
4. `plan-3-v2-architect.md` Phase 0 domain loading reads `§ Concepts` from each domain.md; research subagents check Concepts tables to detect existing capabilities before proposing new code
5. `plan-5-v2-phase-tasks-and-brief.md` Context Brief references concept names (not just contract names) when listing domain dependencies
6. `plan-6-v2-implement-phase.md` post-implementation checklist includes step h: update/create `## Concepts` when contracts change or new domain created
7. `plan-6a-v2-update-progress.md` flags "domain.md § Concepts update needed" when contract changes are recorded
8. `plan-7-v2-code-review.md` Domain Compliance Validator includes item 10: domains with contracts have a `## Concepts` section (⚠️ Review severity, not ❌ violation)
9. `code-concept-search-v2.md` in `agents/v2-commands/` search order is: (1) scan `docs/domains/*/domain.md` § Concepts tables, (2) scan § Contracts tables, (3) fall through to source code
10. Concept narratives include a short code example (3-5 lines: import + basic call) per concept
11. All concepts that a consumer might search for get a row — not limited to "top 3"
12. No files in `agents/commands/` are modified — `code-concept-search` gets a v2 rewrite in `agents/v2-commands/code-concept-search-v2.md`

## Risks & Assumptions

**Risks**:
- **Concepts maintenance burden**: If writing concepts feels like busywork, teams skip it. Mitigation: Level 1 is just a table (5-15 lines). Narratives are optional initially and grow as consumers ask questions.
- **Stale concepts**: Concepts may drift from actual implementation. Mitigation: plan-7 validates existence; plan-6 updates concepts when contracts change; code-concept-search cross-references concepts against actual code.
- **Overly verbose concepts**: Some domains may produce very long Concepts sections. Mitigation: No maximum enforced; the table stays scannable regardless of narrative length below it.

**Assumptions**:
- Coding agents can reliably populate a Concepts table by grouping contracts discovered during extraction — this is pattern recognition, not novel reasoning
- The 3-column table format (Concept | Entry Point | What It Does) is sufficient for agent scanning — no need for additional metadata columns
- Workshop decisions are final — no further clarification needed on format, placement, or enforcement level
- `code-concept-search.md` lives in `agents/commands/` (v1) — a new v2 rewrite will be created in `agents/v2-commands/` to add Concepts table scanning; v1 remains untouched

## Open Questions

None — all design decisions resolved in workshop `domain-sdk-documentation.md`.

## Testing Strategy

- **Approach**: Manual
- **Rationale**: All deliverables are markdown prompt files — no executable code to test
- **Focus Areas**: Verify each command file contains the correct Concepts-related instructions and that section ordering in the domain.md template is correct
- **Mock Usage**: N/A
- **Excluded**: Automated testing — not applicable for prompt files

## Documentation Strategy

- **Location**: No new documentation
- **Rationale**: The command files are self-documenting; the workshop (`workshops/domain-sdk-documentation.md`) serves as the design record

## Workshop Opportunities

All workshops for this feature have been completed:

| Topic | Type | Status | Document |
|-------|------|--------|----------|
| Domain Self-Documentation | Data Model + Integration Pattern | ✅ Complete | `workshops/domain-sdk-documentation.md` |

No further workshops needed before architecture.

## Clarifications

### Session 2026-02-27

**Q1: Workflow Mode** — **Simple**. CS-2 feature, single phase feasible, quick path.

**Q2: Testing Strategy** — **Manual only**. All deliverables are markdown prompt files — nothing executable to test.

**Q3: Documentation Strategy** — **No new documentation**. The command files are self-documenting; the workshop serves as design record.

**Q4: code-concept-search.md location** — **Create a v2 rewrite** (`code-concept-search-v2.md` in `agents/v2-commands/`). Keeps v1 untouched, consistent with the "no v1 modifications" principle.

**Q5: plan-3-v2 scope** — **Yes, include plan-3-v2-architect.md**. Phase 0 domain loading should read § Concepts; research subagents should check Concepts tables for anti-reinvention.

**Q6: Domain Review** — **Confirmed**. Target domains (v2-commands, code-concept-search v2, domain templates) are correct. All meta-domains — command files, not application domains.

**Q7: didyouknow-v2 and plan-4-v2 scope** — **Yes, include both**. `didyouknow-v2.md` should surface Concepts-related insights; `plan-4-v2-complete-the-plan.md` should validate Concepts completeness in its domain health check.
