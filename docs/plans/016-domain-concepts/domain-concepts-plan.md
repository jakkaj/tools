# Domain Self-Documentation (Concepts as Internal SDK) — Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-02-27
**Spec**: [domain-concepts-spec.md](./domain-concepts-spec.md)
**Status**: COMPLETE

## Summary

Domains document *what they are* but not *what they offer*. This plan adds a `## Concepts` section to `domain.md` — a scannable table plus narrative per concept — making every domain a self-documenting internal SDK. Nine command files are updated: 8 existing v2 commands gain Concepts awareness, and 1 new v2 command (`code-concept-search-v2.md`) is created with domain Concepts tables as its first search layer. All deliverables are markdown prompt file edits.

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| v2-commands (plan system) | existing | modify | 8 v2 command prompts gain Concepts awareness |
| code-concept-search | existing | create v2 | New `code-concept-search-v2.md` with Concepts-first search |
| domain templates | existing | modify | domain.md template updated (embedded in extract-domain) |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `agents/v2-commands/plan-v2-extract-domain.md` | v2-commands | internal | Template + extraction workflow changes |
| `agents/v2-commands/plan-3-v2-architect.md` | v2-commands | internal | Domain loading + research subagent changes |
| `agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md` | v2-commands | internal | Context Brief concept name references |
| `agents/v2-commands/plan-6-v2-implement-phase.md` | v2-commands | internal | Post-implementation Concepts update step |
| `agents/v2-commands/plan-6a-v2-update-progress.md` | v2-commands | internal | Concepts update flag on contract changes |
| `agents/v2-commands/plan-7-v2-code-review.md` | v2-commands | internal | Domain Compliance checklist item 10 |
| `agents/v2-commands/didyouknow-v2.md` | v2-commands | internal | Concepts coherence lens |
| `agents/v2-commands/plan-4-v2-complete-the-plan.md` | v2-commands | internal | Domain Completeness Concepts check |
| `agents/v2-commands/code-concept-search-v2.md` | code-concept-search | internal | **New file** — v2 rewrite with Concepts-first search |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | `plan-v2-extract-domain.md` has the domain.md template inline (lines 117-176) with section order: Purpose → Boundary → Contracts → Composition → Source Location → Dependencies → History. Concepts section must be inserted between Purpose and Boundary, and the required-sections list (lines 178-184) must be updated. | Insert `## Concepts` section + table template after Purpose in template; add to required sections list |
| 02 | Critical | `code-concept-search.md` (v1, 414 lines) has a 4-tier search strategy: Semantic → Text → Walk-Through → Not Found. No domain references exist. The v2 rewrite needs a new Tier 0 (Concepts table scan) before all existing tiers. | Create v2 with Tier 0 Concepts scan + existing tiers as fallback |
| 03 | High | `plan-3-v2-architect.md` Phase 0 domain loading reads contracts, composition, dependencies from domain.md but NOT concepts. The Domain & Pattern Scout subagent checks anti-reinvention at domain level but not concept level. | Add `§ Concepts` to domain loading; add concept-level check to scout |
| 04 | High | `plan-6-v2-implement-phase.md` post-implementation checklist has items a-g (History → Composition → Contracts → Dependencies → Source Location → Registry → Domain Map). Item h for Concepts must follow g. | Append item h after g |
| 05 | High | `plan-7-v2-code-review.md` Domain Compliance Validator has 9 checks. Item 10 (Concepts) adds ⚠️ Review severity, not ❌ violation — consistent with advisory documentation checks. | Append check 10 after check 9 |
| 06 | Medium | `didyouknow-v2.md` has a "Domain Boundaries" lens (line ~69) and "Domain Health" lens (line ~87). Concepts coherence fits naturally as a sub-lens. | Add Concepts coherence bullets to Domain Boundaries lens |
| 07 | Medium | `plan-4-v2-complete-the-plan.md` Domain Completeness Validator (lines 77-85) checks domain setup tasks, registry refs, manifest coverage. Concepts check fits as a new bullet. | Add Concepts completeness bullet |
| 08 | Medium | `plan-6a-v2-update-progress.md` Step 6 has 4 bullets for domain context. Concepts flag fits as 5th bullet. | Append bullet to step 6 |

## Implementation

**Objective**: Add Concepts awareness to all 9 target files so domains become self-documenting internal SDKs.
**Testing Approach**: Manual — verify prompt text is correct and section ordering matches spec.

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [x] | T001 | Update domain.md template in extract-domain: insert `## Concepts` section (table + narrative placeholder) between Purpose and Boundary; update required-sections list; add Step 3.5 (identify concepts from discovered contracts) | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/plan-v2-extract-domain.md` | Template has Concepts section after Purpose; Step 3.5 exists; required sections list includes Concepts; section order matches AC3 | Per finding 01 |
| [x] | T002 | Update plan-3-v2-architect: add `§ Concepts` to Phase 0 domain loading reads; update Domain & Pattern Scout subagent to check Concepts tables for anti-reinvention | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/plan-3-v2-architect.md` | Phase 0 reads Concepts; scout checks concept-level duplication | Per finding 03 |
| [x] | T003 | Update plan-5-v2 Context Brief: reference concept names (not just contract names) when listing domain dependencies | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md` | Domain dependencies section uses format `domain: Concept Name (EntryPoint) — what we use it for` | AC5 |
| [x] | T004 | Update plan-6-v2 post-implementation: add step h — update/create `## Concepts` when contracts change or new domain created | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/plan-6-v2-implement-phase.md` | Step h exists after g; covers new domains (create Concepts), changed contracts (update Concepts), code examples from actual implementation | Per finding 04 |
| [x] | T005 | Update plan-6a-v2 progress tracking: add "Concepts update needed" flag when contract changes recorded | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/plan-6a-v2-update-progress.md` | Step 6 has bullet flagging Concepts update on contract changes | Per finding 08 |
| [x] | T006 | Update plan-7-v2 Domain Compliance Validator: add checklist item 10 — domains with contracts have `§ Concepts` (⚠️ Review severity) | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/plan-7-v2-code-review.md` | Check 10 exists after check 9; ⚠️ Review not ❌ violation; validates L1 minimum (table exists) | Per finding 05 |
| [x] | T007 | Update didyouknow-v2: add Concepts coherence lens to Domain Boundaries section | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/didyouknow-v2.md` | Domain Boundaries lens includes concept coherence, missing concepts, stale concepts, reuse opportunities | Per finding 06 |
| [x] | T008 | Update plan-4-v2 Domain Completeness Validator: add check that NEW domains with contracts have `§ Concepts` section planned | v2-commands | `/Users/jordanknight/github/tools/agents/v2-commands/plan-4-v2-complete-the-plan.md` | Completeness validator includes Concepts check | Per finding 07 |
| [x] | T009 | Create `code-concept-search-v2.md`: v2 rewrite of code-concept-search with Tier 0 (scan `docs/domains/*/domain.md` § Concepts tables) before existing tiers; scan § Contracts tables as Tier 0.5; then existing Tier 1-4 as fallback | code-concept-search | `/Users/jordanknight/github/tools/agents/v2-commands/code-concept-search-v2.md` | New file exists; Tier 0 scans Concepts tables first; Tier 0.5 scans Contracts; Tiers 1-4 preserved; output labels Concepts matches as highest confidence | Per finding 02 |

### Acceptance Criteria

- [x] AC1: `plan-v2-extract-domain.md` template has `## Concepts` between Purpose and Boundary (T001)
- [x] AC2: `plan-v2-extract-domain.md` has Step 3.5 grouping contracts into concepts (T001)
- [x] AC3: Domain.md section order: Purpose → Concepts → Boundary → Contracts → Composition → Source Location → Dependencies → History (T001)
- [x] AC4: `plan-3-v2-architect.md` Phase 0 reads § Concepts; scout checks Concepts tables (T002)
- [x] AC5: `plan-5-v2` Context Brief uses concept names for domain dependencies (T003)
- [x] AC6: `plan-6-v2` has step h for Concepts updates (T004)
- [x] AC7: `plan-6a-v2` flags Concepts update on contract changes (T005)
- [x] AC8: `plan-7-v2` has check 10 for Concepts (⚠️ Review) (T006)
- [x] AC9: `code-concept-search-v2.md` exists with Concepts-first search order (T009)
- [x] AC10: Concept narratives include code examples (3-5 lines) (T001 template)
- [x] AC11: All concepts get a row, not limited to "top 3" (T001 template instructions)
- [x] AC12: No files in `agents/commands/` modified (all tasks)

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Concepts maintenance burden leads to skipping | Medium | Medium | Level 1 (table only) is minimum; narratives grow organically |
| LLM agents inconsistently populate Concepts | Medium | Low | plan-7 validation flags missing sections as ⚠️ Review |
| code-concept-search-v2 prompt too long (v1 is 414 lines) | Low | Low | Keep Tier 0 addition lean (~30 lines); rest is copy+adapt from v1 |
