# Harness-Aware V2 Command Pipeline — Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: 2026-03-06
**Spec**: [harness-integration-spec.md](./harness-integration-spec.md)
**Status**: DRAFT

## Summary

Add harness awareness (Boot → Interact → Observe feedback loop) as a cross-cutting concern to the v2 command pipeline. This means modifying 6 existing command prompts, creating 1 new harness utility prompt, and defining the `docs/project-rules/harness.md` governance format. The integration follows the proven domain cross-cutting pattern: file check → context load → output section → graceful degradation. All changes are markdown prompt edits — no code.

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| v2-commands | existing | **modify** | Add harness sections to 6 command prompts + create 1 new |
| project-rules | **NEW** | **create** | Define harness.md governance format |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|
| `agents/v2-commands/harness-v2.md` | v2-commands | contract | New utility prompt — create/validate harness |
| `agents/v2-commands/plan-1a-v2-explore.md` | v2-commands | internal | Add harness discovery to research |
| `agents/v2-commands/plan-2-v2-clarify.md` | v2-commands | internal | Add harness readiness question |
| `agents/v2-commands/plan-3-v2-architect.md` | v2-commands | internal | Add Phase 0 harness + Harness Strategy section |
| `agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md` | v2-commands | internal | Add Phase 0 enforcement + pre-impl harness check |
| `agents/v2-commands/plan-6-v2-implement-phase.md` | v2-commands | internal | Add pre-phase harness validation protocol |
| `agents/v2-commands/plan-7-v2-code-review.md` | v2-commands | internal | Add harness live validation during review |

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | **Plan-7 is "read-only" but spec asks it to fire up harness** — this is NOT a conflict. "Read-only" means no code modifications. Running the harness to observe/validate is pure observation, consistent with review. Harness boot + interact + observe = evidence gathering, not code editing. | Implement as a review subagent that boots harness, exercises changes, captures evidence. Frame as "live validation" not "interactive modification". |
| 02 | High | **No harness/health-check/bootstrap concepts exist in any v2 command** — grep confirms zero references. This is genuinely new; no reinvention risk. | Proceed with clean integration at identified insertion points. |
| 03 | High | **6 files need consistent harness wording** — copy-paste divergence risk across independent edits. Files range from 127 lines (plan-2) to 800+ lines (plan-1a). | Write each command's harness section from a single template pattern. Keep additions concise (10-20 lines per command). |
| 04 | High | **Sync: agents/v2-commands/ is source of truth** — sync-to-dist.sh copies to src/jk_tools/. Edit source only; run sync after. V1 commands (agents/commands/) are NOT modified. | Edit in agents/v2-commands/ only. Run `./scripts/sync-to-dist.sh` after all edits. |
| 05 | High | **Workshop decisions are authoritative** — Workshop 002 (harness prompt design) specifies CREATE/VALIDATE dual-mode flow with 6 steps. Workshop 003 (pre-phase validation) specifies 3-stage Boot→Interact→Observe with 70s timeout. | Honor workshop designs exactly. Do not contradict. |
| 06 | Medium | **Plan-5 pre-implementation audit hook exists** — § F4 "Quick codebase check" runs before task generation. Natural insertion point for harness health verification. | Add harness health check to existing pre-implementation check, not as a separate step. |

## Implementation

**Objective**: Add harness awareness to the v2 command pipeline following the domain cross-cutting pattern.
**Testing Approach**: Manual Only — review prompt text for correctness and consistency.

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | T001 | Define harness.md governance format template | project-rules | `agents/v2-commands/harness-v2.md` (embedded as reference) | Template includes: Boot, Interact, Observe, Maturity Assessment (L0-L4), Validation Checklist, History, USER CONTENT markers | Per workshop 002 |
| [ ] | T002 | Create `harness-v2.md` utility prompt | v2-commands | `agents/v2-commands/harness-v2.md` | Dual-mode CREATE/VALIDATE prompt with: project type detection (6 types), 4 parallel discovery subagents, harness.md generation, health check validation, maturity assessment, optional bootstrap script generation | Per workshop 002 §Steps 1-6 |
| [ ] | T003 | Add harness discovery to plan-1a-v2-explore | v2-commands | `agents/v2-commands/plan-1a-v2-explore.md` | After context loading: check `docs/project-rules/harness.md`. If present → include maturity/boot/interact/observe in dossier. If absent → note "No harness found" and suggest workshop opportunity. ~10-15 lines added. | AC-03 |
| [ ] | T004 | Add harness readiness question to plan-2-v2-clarify | v2-commands | `agents/v2-commands/plan-2-v2-clarify.md` | New standard question: "Harness Readiness". If no harness → ask "Should building one be Phase 0?". Choices: Yes / No / Override. Capture answer in spec § Clarifications. ~10-15 lines added. | AC-04 |
| [ ] | T005 | Add Phase 0 harness + Harness Strategy to plan-3-v2-architect | v2-commands | `agents/v2-commands/plan-3-v2-architect.md` | If harness needed (from plan-2) and doesn't exist → generate Phase 0 "Build Harness" before feature phases. Add `## Harness Strategy` section to plan output (maturity target, boot cmd, health URL, interaction model). User override respected. ~15-20 lines added. | AC-05 |
| [ ] | T006 | Add Phase 0 enforcement + pre-impl harness check to plan-5 | v2-commands | `agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md` | Pre-implementation check verifies harness health if harness.md exists. Context Brief includes harness boot/interact/observe details. If Phase 0 = Build Harness, generate harness-specific task table. ~15-20 lines added. | AC-06 |
| [ ] | T007 | Add pre-phase harness validation to plan-6-v2-implement | v2-commands | `agents/v2-commands/plan-6-v2-implement-phase.md` | Per workshop 003: 3-stage validation (Boot→Interact→Observe) at start of EVERY phase. 70s max. Check-if-running before re-boot. If unhealthy → ask human (retry/skip/abort). Log to execution.log.md. Update harness.md § History post-phase. ~20-25 lines added. | AC-07 |
| [ ] | T008 | Add live harness validation to plan-7-v2-code-review | v2-commands | `agents/v2-commands/plan-7-v2-code-review.md` | New review subagent: "Harness Validator". Boots harness, exercises the phase's changes via interaction methods, captures evidence (responses, screenshots). Reports: changes work / changes break harness / harness unavailable. Falls back to static review if no harness. ~15-20 lines added. | AC-08 |
| [ ] | T009 | Run sync-to-dist.sh | v2-commands | `scripts/sync-to-dist.sh` | `src/jk_tools/agents/v2-commands/` mirrors all changes from `agents/v2-commands/` | Per finding 04 |

### Task Dependency Order

```
T001 (format) ──→ T002 (harness prompt) ──→ T003-T008 (pipeline commands, parallel)
                                                          │
                                                          ▼
                                                      T009 (sync)
```

T001 defines the harness.md format that T002 generates and T003-T008 reference. T003-T008 can be done in parallel (independent files). T009 runs last.

### Harness Integration Pattern (uniform across all commands)

Every command follows this pattern for harness awareness:

```
1. CHECK:  Does `docs/project-rules/harness.md` exist?
2. LOAD:   If yes → read Boot/Interact/Observe/Maturity sections
3. ACT:    Command-specific action (discover/ask/plan/check/validate/review)
4. OUTPUT: Include harness info in command's output artifact
5. DEGRADE: If no → note absence, proceed normally, suggest next steps
```

| Command | CHECK | ACT | OUTPUT | DEGRADE |
|---------|-------|-----|--------|---------|
| plan-1a | read harness.md | include in research | dossier § Harness Status | "No harness found — suggest workshop" |
| plan-2 | check existence | ask Harness Readiness Q | spec § Clarifications | "Harness not configured — ask user" |
| plan-3 | check existence + plan-2 answer | generate Phase 0 if needed | plan § Harness Strategy | "User overrode — skip Phase 0" |
| plan-5 | read harness.md | pre-impl health check | context brief § Harness | "No harness — skip health check" |
| plan-6 | read harness.md | 3-stage validation per phase | execution.log § Validation | "No harness — manual validation" |
| plan-7 | read harness.md | boot + exercise + evidence | review § Live Validation | "No harness — static review only" |

### Acceptance Criteria

- [ ] AC-01: harness.md governance format defined (Boot, Interact, Observe, Maturity L0-L4, History, USER CONTENT markers)
- [ ] AC-02: harness-v2.md prompt exists with CREATE + VALIDATE modes
- [ ] AC-03: plan-1a discovers harness status; suggests workshop if absent
- [ ] AC-04: plan-2 asks Harness Readiness question; captures override
- [ ] AC-05: plan-3 creates Phase 0 "Build Harness" when needed
- [ ] AC-06: plan-5 enforces Phase 0; pre-impl checks harness health
- [ ] AC-07: plan-6 validates harness at start of every phase; human override available
- [ ] AC-08: plan-7 boots harness and live-validates changes; falls back to static
- [ ] AC-09: All 6 modified commands degrade gracefully when no harness.md exists
- [ ] AC-10: Human can override at every harness-related gate

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Harness sections diverge in wording across 6 commands | Medium | Medium | Use the uniform integration pattern table above as copy-from source |
| plan-7 live validation is misunderstood as code modification | Low | Medium | Frame as "evidence gathering" — boot, observe, capture, report. Read-only. |
| harness-v2.md becomes too long (workshop 002 is comprehensive) | Medium | Low | Keep prompt under 300 lines; reference workshop for detailed patterns |
| Sync to src/jk_tools/ forgotten after edits | Low | High | T009 is explicit final task; verify with diff |
