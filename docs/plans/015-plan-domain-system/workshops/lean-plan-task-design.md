# Workshop: Lean Plan & Task Design

**Type**: Integration Pattern
**Plan**: 015-plan-domain-system
**Created**: 2026-02-22
**Status**: Draft

**Related Documents**:
- [v2-command-structure.md](./v2-command-structure.md) — where these changes land
- [domain-system-design.md](./domain-system-design.md) — the domain system driving this redesign
- [plan-3-architect (v1)](../../../../agents/commands/plan-3-architect.md) — 1446 lines, current
- [plan-5-phase-tasks-and-brief (v1)](../../../../agents/commands/plan-5-phase-tasks-and-brief.md) — 942 lines, current

---

## Purpose

Redesign the plan-3 (architect) and plan-5 (tasks) outputs to be **leaner, faster, and more respectful of implementor agency**. The current commands over-specify, take too long to generate, and produce artifacts so detailed that the implementor becomes a typist rather than a problem-solver.

## Key Questions Addressed

- What does the implementor actually need vs. what's just ceremony?
- Where is the line between "enough guardrails" and "removed agency"?
- What can we cut without losing safety?
- How should plan-3 and plan-5 divide responsibilities?

---

## 1. The Problem

### V1 by the Numbers

| Metric | plan-3 (architect) | plan-5 (tasks & brief) |
|--------|-------------------|----------------------|
| **Prompt size** | 1446 lines | 942 lines |
| **Research** | 4 parallel subagents, 15-20+ discoveries | Parallel review of ALL prior phases (A-K per phase) |
| **Pre-implementation audit** | — | Dedicated subagent |
| **Requirements flow** | — | Dedicated subagent |
| **Output sections** | 11+ required sections | 10+ required sections |
| **Task table columns** | 7 columns | 10 columns |
| **Subagent mentions** | 19 | 27 |
| **Heaviest section** | PHASE 4: Plan generation (424 lines) | Phase mode core (520 lines) |
| **Examples/templates** | 183 lines of example phases | 200+ lines of sample output |

### What Goes Wrong

**Over-specification**: Plan-3 prescribes test examples, non-happy-path checklists, test documentation templates, mock usage policies, TAD workflow details — all before a single line of code is written. The implementor already knows TDD. They need to know *what* to build, not *how* to write a test.

**Redundant research layers**: Research happens in plan-1a (7 subagents), plan-3 (4 subagents), and plan-5 (N subagents reviewing prior phases). Three layers of discovery for the same codebase.

**Ceremony over substance**: The plan-5 Architecture Map (Mermaid diagram), Task-to-Component Mapping table, and detailed Alignment Brief with flow + sequence diagrams add visual weight but rarely change the implementor's actual approach.

**Agency removal**: When a task says `| T003 | Implement API endpoint | Core | T002 | /abs/path/src/api/endpoint.py | Test passes, returns 200 | — | Per Critical Disc 01 |` — the implementor has nothing left to decide. They're executing instructions, not engineering.

**Time cost**: Generating all this takes significant LLM time and tokens. A plan-3 run can take 5-10 minutes. Plan-5 per phase adds another 3-5 minutes. For a 4-phase plan, that's 25-30 minutes of generation before implementation starts.

---

## 2. Design Philosophy: Guardrails, Not Rails

### The Spectrum

```
Too little                                           Too much
   ←─────────────────────────────────────────────────────→
   
"Build auth"     "Build auth service     "Build auth service
                  in src/auth/ using      in src/auth/auth-
                  the existing pattern     service.ts, implement
                  from billing domain.     method authenticate()
                  Watch out for the        taking UserCredential,
                  OAuth token expiry       returning AuthResult,
                  issue (see finding       using try/catch with
                  03)."                    AuthError class from
                                           line 47 of errors.ts,
                                           call OAuthAdapter.
                                           verify() first..."
                  
   ❌ No context    ✅ SWEET SPOT           ❌ No agency
```

### What the Implementor Actually Needs

| Need | Why | Example |
|------|-----|---------|
| **What to build** | Goal clarity | "Auth service with OAuth support" |
| **Where it lives** | Domain context | "domain:auth, src/auth/" |
| **What already exists** | Prevent reinvention | "Existing AuthService has login/logout — extend it" |
| **Known hazards** | Prevent wasted time | "OAuth tokens expire silently — see finding 03" |
| **Acceptance criteria** | Definition of done | "User can authenticate via Google OAuth" |
| **Dependencies** | Ordering | "Needs TokenService from Phase 1" |

### What the Implementor Does NOT Need

| Over-specification | Why it hurts |
|-------------------|-------------|
| Prescribed file names | Implementor knows naming conventions |
| Test examples with code | Implementor knows how to write tests |
| Mermaid diagrams of task flow | Visual noise — tasks are already in a table |
| Mock usage policies | Already in spec's testing strategy |
| Non-happy-path checklists | Implementor discovers edge cases during TDD |
| 10-column task tables | Half the columns are noise at planning time |
| Detailed alignment brief with sequence diagrams | The plan already describes the architecture |

---

## 3. V2 Plan-3: Architect (Lean)

### What Changes

| V1 Section | V2 Treatment | Rationale |
|-----------|-------------|-----------|
| PHASE 0: Detect mode | **Keep** (+ domain detection) | Needed for routing |
| PHASE 1: Gates | **Keep** (simplify) | Safety mechanism |
| PHASE 2: Research (282 lines, 4 subagents) | **Slim to 2 subagents** | Over-discovery. 2 focused subagents produce 8-12 findings. Quality over quantity. |
| PHASE 3: Project structure | **Replace with domain manifest** | Domain system handles this |
| PHASE 4: Plan generation (424 lines) | **Major trim** | Cut testing philosophy (belongs in spec), cut examples, cut non-happy-path checklists |
| PHASE 5: Validation | **Keep** | Quick sanity check |
| Example phases (183 lines) | **Remove** | Template examples are read once, never again |
| Simple Mode (112 lines) | **Keep, simplify** | Useful shortcut |
| Appendix A: Anchors (72 lines) | **Remove from plan-3, move to shared reference** | Not plan-3's job |
| Appendix B: Graph traversal (192 lines) | **Remove from plan-3, move to shared reference** | Not plan-3's job |
| Testing philosophy (90+ lines) | **Remove** | Already captured in spec's Testing Strategy. Plan just references it. |
| Documentation strategy (40+ lines) | **Remove** | Already in spec. Plan references it. |

### V2 Research: 2 Subagents, Not 4

V1 launches 4 subagents producing 15-20+ findings. This is overkill — most findings are medium/low impact and rarely referenced during implementation.

**V2 approach: 2 subagents, 8-12 findings total**

**Subagent 1: Domain & Pattern Scout**
```
"What exists that this plan needs to know about?

Check:
1. docs/domains/ — existing domains, contracts, composition
2. Codebase patterns relevant to this feature
3. Integration points where new code connects to existing

Output: 4-6 findings. Only Critical and High impact.
Format: Title | Impact | What exists | What to do about it"
```

**Subagent 2: Risk & Constraint Finder**
```
"What could go wrong or surprise the implementor?

Check:
1. API limitations, framework gotchas
2. Spec ambiguities that affect implementation
3. Cross-domain dependencies that need coordination

Output: 4-6 findings. Only Critical and High impact.
Format: Title | Impact | The risk | Mitigation"
```

**Why 2 not 4**: The v1 "Discovery Documenter" and "Dependency Mapper" subagents overlap heavily with the other two. Merging them produces the same actionable findings with less noise.

**Critical change**: Findings are presented as a **concise table**, not multi-paragraph formatted blocks with code examples. The implementor can dig deeper if needed.

### V2 Plan Output Format

```markdown
# [Feature Name] Implementation Plan

**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link]
**Status**: DRAFT

## Summary

[3-5 sentences: Problem, approach, expected outcome]

## Target Domains

[Carried forward from spec — which domains this plan touches]

| Domain | Status | Role |
|--------|--------|------|
| auth | existing | Extend with OAuth |
| notifications | NEW | Establish for alerts |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| ... | ... | ... | ... |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | OAuth tokens expire silently after 1hr | Implement refresh flow before auth calls |
| 02 | High | Existing AuthService uses singleton pattern | Extend, don't replace |
| ... | ... | ... | ... |

## Phases

### Phase 1: [Title]

**Objective**: [One sentence]
**Domain**: [Primary domain]
**Delivers**: [Concrete deliverables — bullet list]
**Depends on**: [Prior phases or nothing]
**Key risks**: [1-2 sentence, or "None"]

| # | Task | Domain | Success Criteria | Notes |
|---|------|--------|-----------------|-------|
| 1.1 | [What to build] | auth | [How you know it works] | |
| 1.2 | [What to build] | auth | [How you know it works] | Per finding 01 |

### Phase 2: [Title]
...

## Acceptance Criteria

- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]

## Change Footnotes Ledger

[^1]: [To be added during implementation via plan-6a]
```

### What's Gone

- ❌ Testing philosophy section (90+ lines → reference spec)
- ❌ Documentation strategy section (40+ lines → reference spec)
- ❌ Test examples with code (60+ lines)
- ❌ Non-happy-path checklists
- ❌ Cross-cutting concerns template (security, observability, documentation subsections)
- ❌ File Placement Manifest / PlanPak blocks → replaced by Domain Manifest
- ❌ Example phases (183 lines)
- ❌ Appendix A: Anchor conventions (72 lines → shared reference doc)
- ❌ Appendix B: Graph traversal (192 lines → shared reference doc)
- ❌ Detailed discovery format with code examples → concise table
- ❌ Complexity tracking table (CS scores are on tasks, not a separate section)
- ❌ Mock usage subsection

### What's Left

- ✅ Summary (short)
- ✅ Target Domains (from spec)
- ✅ Domain Manifest (what goes where)
- ✅ Key Findings (concise table, not verbose blocks)
- ✅ Phases with task tables (5 columns, not 7)
- ✅ Acceptance Criteria
- ✅ Change Footnotes Ledger (for plan-6a)
- ✅ Gates (clarify, constitution, architecture — but streamlined)

### Estimated V2 plan-3 prompt size: ~400-500 lines (down from 1446)
### Estimated output size: ~60-80% smaller per plan

---

## 4. V2 Plan-5: Tasks & Brief (Lean)

### The Core Question: Does Plan-5 Still Need to Exist?

With a leaner plan-3 that already has task tables per phase, plan-5's job shrinks considerably. But there's still value in:

1. **Pre-implementation audit** — checking what exists before modifying
2. **Prior phase context** — knowing what earlier phases delivered
3. **Expanded task detail** — plan-3 tasks are high-level, plan-5 adds implementation specifics

**Decision**: Plan-5 stays, but becomes a **focused expansion** rather than a comprehensive dossier.

### What Changes

| V1 Section | V2 Treatment | Rationale |
|-----------|-------------|-----------|
| Prior phase review (parallel subagents, A-K per phase) | **Keep subagents, slim to 5-6 sections** | Subagents run in parallel (fast). Reduce from 11 sections (A-K) + cross-phase synthesis to 5 focused sections: Deliverables, Dependencies Exported, Gotchas & Debt, Incomplete Items, Patterns to Follow. Drop: Lessons Learned, Critical Findings Applied, Scope Changes, Key Log References, and heavy cross-phase synthesis narrative. |
| Pre-Implementation Audit (dedicated subagent) | **Keep but simplify** | Still valuable — check for duplication and existing code. But simpler output format. |
| Requirements Flow (dedicated subagent) | **Make optional** | Only run if plan has complex multi-file ACs. For most phases, the task table from plan-3 is sufficient. |
| Executive Briefing | **Keep but shorter** | Purpose + What We're Building. Drop "User Value" and "Example" subsections. |
| Objectives & Scope | **Merge into Executive Briefing** | Goals and Non-Goals are useful, don't need their own section. |
| Architecture Map (Mermaid + mapping table) | **Keep** | Diagrams are easy to read and valuable for understanding component relationships. |
| Task table (10 columns) | **Slim to 6-7 columns** | Drop Subtasks column (rare), merge CS into Notes when relevant |
| Alignment Brief (flow + sequence diagrams, test plan, commands) | **Replace with Context Brief** | Short list: relevant findings, domain constraints, things to watch out for. Keep Mermaid diagrams for flow visualization. |
| Phase Footnote Stubs | **Remove** | plan-6a creates these — plan-5 doesn't need empty shells |
| Evidence Artifacts | **Remove** | Implementor knows where to log |
| Discoveries & Learnings | **Keep** (empty table) | Useful during implementation |
| Subtask mode (147 lines) | **Keep, simplify** | Useful but can be more concise |

### V2 Prior Phase Context

**V1**: Launch N parallel subagents, each producing an 11-section (A-K) review. Synthesize across phases. Massive.

**V2**: Same parallel subagents, but **5 focused sections** instead of 11 + synthesis:

```markdown
## Prior Phase Context

### Phase 1: Core Infrastructure (COMPLETE)

**Deliverables**: AuthService, UserRepository, base test fixtures
- src/auth/auth-service.ts, src/auth/repositories/user-repo.ts, tests/helpers/mock-user.ts

**Dependencies Exported**: (available for this phase to use)
- `AuthService.authenticate(credentials): AuthResult`
- `UserRepository.findByEmail(email): User | null`
- `createMockUser()` test helper

**Gotchas & Debt**:
- Token refresh has a 5-second race window — needs mutex (logged as tech debt)
- UserRepository doesn't handle connection timeouts yet

**Incomplete Items**: None — all tasks complete

**Patterns to Follow**:
- Repository pattern with async/await throughout
- Error types extend BaseAuthError
```

**5 sections per phase, parallel subagents**. Keeps the thorough context gathering but drops: Lessons Learned, Critical Findings Applied, Scope Changes, Key Log References, and the heavy cross-phase synthesis narrative.

### V2 Pre-Implementation Audit (Simplified)

**V1**: Dedicated subagent with 5-point investigation per file (action, provenance, duplication check via code-concept-search, compliance check, recommendation).

**V2**: Quick check focused on the two things that actually matter:

```markdown
## Pre-Implementation Check

| File | Exists? | Domain Check | Notes |
|------|---------|-------------|-------|
| src/auth/adapters/oauth-adapter.ts | Yes — extend | ✅ domain:auth | Created in Phase 2 |
| src/notifications/notify-service.ts | No — create | ✅ domain:notifications | New domain |
| src/auth/contracts/i-auth.ts | Yes — extend | ✅ domain:auth | Contract change — review consumers |

**Duplication check**: /code-concept-search "notification sending" → No existing implementation found.
```

No per-file 5-point investigation. Just: does it exist, is it in the right domain, anything surprising?

### V2 Tasks Output Format

```markdown
# Phase 3: Notification Service – Tasks

**Plan**: [link to plan]
**Spec**: [link to spec]
**Domain**: notifications (primary), auth (contract extension)
**Date**: {{TODAY}}

## Purpose

Establish the notifications domain with core email delivery capability.
Build NotificationService and EmailAdapter. Extend auth contracts
to emit AuthEvents that notifications can subscribe to.

### Goals
- ✅ NotificationService with send() capability
- ✅ EmailAdapter wrapping SendGrid SDK
- ✅ AuthEvents contract for login/logout events

### Non-Goals
- ❌ Push notifications (Phase 5)
- ❌ Notification preferences UI
- ❌ Message templating engine

## Prior Phase Context

[4 bullets per completed phase — see format above]

## Pre-Implementation Check

[Quick table — see format above]

## Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | T001 | Create notifications domain scaffold | notifications | docs/domains/notifications/, src/notifications/ | domain.md exists, registered | |
| [ ] | T002 | Implement NotificationService | notifications | src/notifications/notify-service.ts | Can send email via adapter | |
| [ ] | T003 | Implement EmailAdapter | notifications | src/notifications/adapters/email-adapter.ts | SendGrid integration works | |
| [ ] | T004 | Add AuthEvents to auth contracts | auth | src/auth/contracts/auth-events.ts | Events emitted on login/logout | Contract change |
| [ ] | T005 | Wire notifications to auth events | notifications | src/notifications/notify-service.ts | Welcome email sent on signup | Cross-domain |

## Context Brief

**Key findings from plan**:
- Finding 01: SendGrid rate limits at 100/sec — batch if needed
- Finding 03: Auth events must be async to not block login flow

**Domain constraints**:
- notifications imports from auth contracts only (not internals)
- auth must not import from notifications

**Reusable from prior phases**:
- `createMockUser()` helper from Phase 1 test fixtures
- OAuth test fixtures from Phase 2

## Discoveries & Learnings

_Populated during implementation._

| Date | Task | Type | Discovery | Resolution | References |
|------|------|------|-----------|------------|------------|
```

### What's Gone from Plan-5

- ❌ Prior phase review 11 sections (A-K) → slimmed to 5 focused sections
- ❌ Cross-phase synthesis narrative → dropped (subagent outputs are sufficient)
- ❌ Requirements Flow subagent (optional, not default)
- ❌ Alignment Brief verbose prose → Context Brief (bullets + diagrams)
- ❌ Phase Footnote Stubs
- ❌ Evidence Artifacts section
- ❌ Test plan enumeration → implementor decides testing approach
- ❌ Step-by-step implementation outline → implementor has agency
- ❌ Commands to run section → implementor knows their tools
- ❌ Ready Check checkboxes → trust the implementor

### What's Left

- ✅ Purpose + Goals + Non-Goals (merged, concise)
- ✅ Prior Phase Context (5 sections per phase, parallel subagents kept)
- ✅ Pre-Implementation Check (simple table)
- ✅ Architecture Map (Mermaid diagrams + component mapping)
- ✅ Tasks (7 columns — Status, ID, Task, Domain, Path(s), Done When, Notes)
- ✅ Context Brief (findings, domain constraints, reusable stuff — with Mermaid flow/sequence diagrams)
- ✅ Discoveries & Learnings (empty table for implementation)
- ✅ Subtask mode (simplified)
- ✅ Flight plan auto-generation (plan-5b stays default)

### Estimated V2 plan-5 prompt size: ~300-400 lines (down from 942)
### Estimated output size: ~50-60% smaller per phase dossier

---

## 5. Task Table: V1 vs V2

### V1 (10 columns)

```
| Status | ID | Task | CS | Type | Dependencies | Absolute Path(s) | Validation | Subtasks | Notes |
```

### V2 (7 columns)

```
| Status | ID | Task | Domain | Path(s) | Done When | Notes |
```

### What Was Cut and Why

| Dropped Column | Why |
|---------------|-----|
| `CS` (Complexity Score) | Per-task CS scores are noise. Overall phase complexity is in the plan. If a task is complex, say so in Notes. |
| `Type` (Setup/Test/Core/etc.) | The task description already makes this obvious. "Write test for X" doesn't need a Type column. |
| `Dependencies` | Represented by task ordering. If T003 must follow T002, they're listed in order. Complex dependencies noted in Notes. |
| `Subtasks` | Rarely used. When needed, noted in Notes. |

### What Was Changed

| Column | V1 | V2 | Why |
|--------|----|----|-----|
| `Absolute Path(s)` | `Absolute Path(s)` | `Path(s)` | Still absolute, shorter header. Drop the word "Absolute" — it's always absolute. |
| `Validation` | `Validation` | `Done When` | Plain language. "Test passes" not "Validation: test suite passes with expected output format matching schema" |
| (none) | (none) | `Domain` | New — every task declares its domain |

---

## 6. The Agency Principle

### What "Implementor Agency" Means

The implementor (human or agent running plan-6) is a **competent engineer**, not a code typist. They know how to:

- Write tests (don't prescribe test structure)
- Name files (don't prescribe filenames)
- Handle errors (don't list every edge case)
- Use their tools (don't list commands to run)
- Make tactical decisions (don't prescribe every function signature)

### What the Plan SHOULD Provide

**Strategic context** that the implementor can't easily discover on their own:

- What business goal this serves
- What already exists in the codebase that's relevant
- What hazards/gotchas previous work uncovered
- What domain boundaries to respect
- What "done" looks like (acceptance criteria)
- What order things should be built in

### What the Plan Should NOT Provide

**Tactical detail** that the implementor is better positioned to decide:

- Exact file names and function signatures
- Test code examples
- Mermaid diagrams of task flow
- Non-happy-path checklists
- Mock usage instructions
- Step-by-step implementation outlines

### The Litmus Test

> **Before adding a section to a plan, ask: "Would a competent engineer doing this work already know this?"**
>
> If yes → don't include it.
> If no → include it, briefly.

---

## 7. Shared Reference Documents

Several pieces cut from plan-3 and plan-5 are still useful — they just don't belong in every plan output. Move them to shared reference docs:

```
docs/plans/
└── _reference/                    # Shared reference material
    ├── anchor-conventions.md      # From plan-3 Appendix A (72 lines)
    ├── graph-traversal.md         # From plan-3 Appendix B (192 lines)
    └── testing-patterns.md        # TAD workflow, Test Doc blocks, etc.
```

These are **read once, referenced forever** — not regenerated in every plan.

---

## 8. Generation Time Impact

### Estimated Savings

| Step | V1 Time | V2 Time | Savings |
|------|---------|---------|---------|
| plan-3 research | 4 subagents × ~60s | 2 subagents × ~60s | ~50% |
| plan-3 output | ~2-3 min (large doc) | ~1 min (lean doc) | ~60% |
| plan-5 prior review | N subagents × ~60s | Direct file read ~15s | ~75% |
| plan-5 pre-impl audit | 1 subagent × ~60s | Inline check ~20s | ~65% |
| plan-5 req flow | 1 subagent × ~60s | Optional / skip | ~100% |
| plan-5 output | ~2-3 min (large dossier) | ~1 min (lean tasks) | ~60% |

**Rough estimate**: A 4-phase plan goes from ~25-30 min total generation to ~10-12 min. The implementor starts building sooner with clearer (not longer) instructions.

---

## 9. Summary: V1 → V2 Comparison

| Aspect | V1 | V2 |
|--------|----|----|
| **Plan-3 prompt** | 1446 lines | ~400-500 lines |
| **Plan-5 prompt** | 942 lines | ~300-400 lines |
| **Research subagents** | 4 (plan-3) + N (plan-5 prior review) + 2 (plan-5 audit/flow) | 2 (plan-3) + 0 (plan-5 reads files directly) |
| **Findings format** | Multi-paragraph with code examples | Concise table: Finding → Action |
| **Task table** | 10 columns | 7 columns |
| **Plan output** | 11+ sections, ~3-5 pages | 6 sections, ~1-2 pages |
| **Tasks output** | 10+ sections, ~2-3 pages per phase | 6 sections, ~1 page per phase |
| **Mermaid diagrams** | Architecture map + task flow | None (optional in workshops if needed) |
| **Testing guidance** | 90+ lines in plan | "See spec § Testing Strategy" |
| **Implementor role** | Execute prescribed steps | Engineer within guardrails |

---

## Open Questions

### Q1: Should plan-5 require Requirements Flow tracing?

**RESOLVED**: Make it optional. Only run when the plan has complex multi-file acceptance criteria where gaps are likely. For most phases, the task table is sufficient.

### Q2: Should the Context Brief include diagrams?

**RESOLVED**: No. If the architecture needs visual explanation, that's what workshops are for. The context brief is bullets — fast to generate, fast to read.

### Q3: Should prior phase review use subagents or direct file reads?

**RESOLVED**: Direct file reads. The implementor agent reads tasks.md and execution.log from prior phases and writes 4-bullet summaries. No subagent overhead.

### Q4: What happens to plan-5b (flight plan) and plan-5c (requirements flow)?

**RESOLVED**: Split decision:
- **plan-5b (flight plan)**: Stays **auto-generated by default** — flight plans are lightweight, easy to read, and provide a great at-a-glance summary. plan-5 continues to invoke plan-5b after writing tasks.md.
- **plan-5c (requirements flow)**: Becomes **optional addon** — only runs when explicitly flagged (e.g., complex multi-file ACs where gap detection is worthwhile). Not auto-invoked by plan-5 anymore.

### Q5: How lean is too lean? When does the implementor need MORE context?

This is the key tension. Safeguards:
- **Domain system** provides persistent context (domain.md always available)
- **Key findings** in plan call out the non-obvious stuff
- **Workshops** exist for deep dives when needed
- **Implementor can always read the spec** for full requirements
- **If implementation fails**, the feedback is "plan-5 didn't flag X" → add it as a finding pattern, not a mandatory section
